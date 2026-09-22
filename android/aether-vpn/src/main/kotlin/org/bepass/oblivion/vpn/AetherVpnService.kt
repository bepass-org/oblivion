package org.bepass.oblivion.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import org.json.JSONObject

class AetherVpnService : VpnService() {

    private var tunInterface: ParcelFileDescriptor? = null
    private var core: AetherCore? = null
    private var config: TunnelConfig? = null

    private var validator: ScheduledExecutorService? = null
    private var statsPoller: ScheduledExecutorService? = null
    private var hevLogTail: ScheduledExecutorService? = null

    private val control = Executors.newSingleThreadExecutor()
    private val stopping = AtomicBoolean(false)
    private val latestStartId = AtomicInteger(0)

    private var connectedAtMillis = 0L

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        TunnelBus.bindService(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        latestStartId.set(startId)

        when (intent?.action) {
            ACTION_START -> {
                val payload = intent.getBundleExtra(EXTRA_CONFIG)
                if (payload == null) {
                    startForegroundNotification(TunnelStage.CONNECTING)
                    requestStop(TunnelStage.FAILED, "missing tunnel configuration")
                    return START_NOT_STICKY
                }

                val target = TunnelBundle.decode(payload)
                publish(TunnelStage.CONNECTING, null)
                startForegroundNotification(TunnelStage.CONNECTING)
                control.execute { startTunnel(target) }
            }
            ACTION_STOP -> requestStop(TunnelStage.DISCONNECTED, null)
            else -> {
                stopForegroundCompat()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onRevoke() {
        TunnelBus.log(logSource(), "[-] vpn permission revoked by the system")
        requestStop(TunnelStage.DISCONNECTED, "revoked")
        super.onRevoke()
    }

    override fun onDestroy() {
        control.execute { teardown() }
        control.shutdown()
        TunnelBus.unbindService(this)
        super.onDestroy()
    }

    private fun startTunnel(target: TunnelConfig) {
        teardown()
        stopping.set(false)
        config = target
        connectedAtMillis = 0L

        startAetherTunnel(target)
    }

    private fun startAetherTunnel(target: TunnelConfig) {
        val runner = AetherCore(
            context = applicationContext,
            onLog = { line -> TunnelBus.log(line) },
            onExit = { code ->
                if (code != 0) {
                    requestStop(TunnelStage.FAILED, "core exited with code $code")
                }
            },
        )
        core = runner
        TunnelBus.bindCodeSink(runner::submitLine)
        runner.start(target.coreArguments, coreEnvironment(target))
        if (!runner.isRunning) return

        scheduleValidation(target)
    }

    private fun coreEnvironment(target: TunnelConfig): Map<String, String> {
        val environment = mutableMapOf(
            "AETHER_SOCKS" to "${target.aetherBindHost}:${target.aetherSocksPort}",
            "AETHER_HTTP_PROXY" to "${target.aetherBindHost}:${target.aetherHttpProxyPort}",
            "AETHER_PROTOCOL" to target.protocol,
            "AETHER_SCAN" to target.scanMode,
            "AETHER_NOIZE" to target.noizeProfile,
            "AETHER_IP" to target.ipVersion,
            "AETHER_LOG_LEVEL" to target.logLevel,
            "AETHER_QUICK_RECONNECT" to if (target.quickReconnect) "1" else "0",
        )

        if (target.usesMasque && target.transport == "h2") {
            environment["AETHER_MASQUE_HTTP2"] = "1"
            if (target.fragment) environment["AETHER_MASQUE_H2_FRAGMENT"] = "1"
        }
        if (target.usesMasque && target.innerMtu > 0) {
            environment["AETHER_MASQUE_MTU"] = target.innerMtu.toString()
        }
        if (target.usesGool) {
            if (target.wiwOuterPeer.isNotEmpty()) {
                environment["AETHER_WIW_OUTER_PEER"] = target.wiwOuterPeer
            }
            if (target.wiwInnerPeer.isNotEmpty()) {
                environment["AETHER_WIW_INNER_PEER"] = target.wiwInnerPeer
            }
            if (!target.wiwPinned) environment["AETHER_WIW_PEERS"] = "auto"
        } else if (target.endpoint.isNotBlank()) {
            environment["AETHER_PEER"] = target.endpoint
        }
        if (target.runsPsiphon) {
            environment["AETHER_PSIPHON"] = if (target.psiphonOnly) "only" else "chain"
            environment["AETHER_PSIPHON_BIND"] = target.psiphonBindAddress
            environment["AETHER_PSIPHON_MODE"] = target.psiphonCoreMode
            if (target.psiphonCountry.isNotBlank()) {
                environment["AETHER_PSIPHON_REGION"] = target.psiphonCountry
            }
            if (target.psiphonCdnIps.isNotBlank()) {
                environment["AETHER_PSIPHON_CDN_IPS"] = target.psiphonCdnIps
            }
            if (target.psiphonCdnSni.isNotBlank()) {
                environment["AETHER_PSIPHON_CDN_SNI"] = target.psiphonCdnSni
            }
            environment["AETHER_PSIPHON_DIR"] = File(filesDir, PSIPHON_DATA_DIR).absolutePath
            psiphonBinary()?.let { environment["AETHER_PSIPHON_BIN"] = it }
            psiphonOverlay(target)?.let { environment["AETHER_PSIPHON_CONFIG"] = it }
        }

        if (target.usesTor) {
            environment["AETHER_TOR"] = target.torWire
            if (target.torWire != "only") {
                environment["AETHER_TOR_BIND"] = target.aetherTorAddress
            }
            if (target.torRelays.isNotBlank()) {
                environment["AETHER_TOR_RELAYS"] = target.torRelays
            }
        }

        if (target.exitLoc.isNotBlank()) {
            environment["AETHER_EXIT_LOC"] = target.exitLoc
        }

        if (target.perfProfile.isNotBlank()) {
            environment["AETHER_PERF_PROFILE"] = target.perfProfile
        }
        if (target.routeBlock.isNotBlank()) {
            environment["AETHER_ROUTE_BLOCK"] = target.routeBlock
        }
        if (target.routeDirect.isNotBlank()) {
            environment["AETHER_ROUTE_DIRECT"] = target.routeDirect
        }

        if (target.usesZeroTrust) {
            environment["AETHER_TEAM"] = target.team
            if (target.accessToken.isNotBlank()) {
                environment["AETHER_ACCESS_TOKEN"] = target.accessToken
            } else if (target.hasServiceToken) {
                environment["AETHER_ACCESS_CLIENT_ID"] = target.accessId
                environment["AETHER_ACCESS_CLIENT_SECRET"] = target.accessSecret
            }
            if (target.gatewayProxy) environment["AETHER_GATEWAY"] = "1"
        }

        return environment
    }

    private fun logSource(): String = CORE_AETHER

    private fun psiphonBinary(): String? = PsiphonBinary.path(applicationContext)

    private fun psiphonOverlay(target: TunnelConfig): String? = runCatching {
        val overlay = JSONObject()
            .put("DNSResolverAlternateServers", JSONArray(target.dnsServers))
        val directory = File(filesDir, PSIPHON_DATA_DIR).apply { mkdirs() }
        File(directory, PSIPHON_OVERLAY_NAME).apply { writeText(overlay.toString()) }.absolutePath
    }.getOrElse { error ->
        Log.w(TAG, "psiphon overlay not written", error)
        null
    }

    private fun activeCoreIsRunning(): Boolean = core?.isRunning == true

    private fun scheduleValidation(target: TunnelConfig) {
        val scheduler = Executors.newSingleThreadScheduledExecutor()
        validator = scheduler

        val usesPsiphon = target.psiphonOnly
        val budgetMs = when {
            usesPsiphon -> PSIPHON_VALIDATION_BUDGET_MS
            target.usesChain ->
                validationBudgetMs(target.scanMode) + PSIPHON_VALIDATION_BUDGET_MS
            else -> validationBudgetMs(target.scanMode)
        }
        val deadline = System.currentTimeMillis() + budgetMs
        var announcedValidating = false
        val budgetSeconds = budgetMs / 1000

        TunnelBus.log(
            logSource(),
            if (usesPsiphon) {
                "[*] waiting up to ${budgetSeconds}s for the tunnel"
            } else {
                "[*] waiting up to ${budgetSeconds}s for the tunnel on scan mode ${target.scanMode}"
            },
        )

        scheduler.scheduleWithFixedDelay({
            if (!activeCoreIsRunning()) {
                requestStop(TunnelStage.FAILED, "the core stopped before the tunnel came up")
                return@scheduleWithFixedDelay
            }

            if (System.currentTimeMillis() > deadline) {
                requestStop(
                    TunnelStage.FAILED,
                    if (usesPsiphon) {
                        "no working tunnel after ${budgetSeconds}s"
                    } else {
                        "no working tunnel after ${budgetSeconds}s on scan mode ${target.scanMode}"
                    },
                )
                return@scheduleWithFixedDelay
            }

            if (!announcedValidating) {
                announcedValidating = true
                publish(TunnelStage.VALIDATING, null)
            }

            if (!SocksProbe.reachable(target.aetherSocksPort)) return@scheduleWithFixedDelay

            if (target.usesChain) {
                if (!SocksProbe.reachable(target.socksPort)) return@scheduleWithFixedDelay
                TunnelBus.log(
                    CORE_PSIPHON,
                    "[+] the chain is up: traffic goes through aether, then psiphon",
                )
            }

            TunnelBus.log(logSource(), "[+] socks5 proxy answered a real request")
            if (target.proxyOnly) {
                onTunnelReady(target)
            } else if (establishTun(target)) {
                onTunnelReady(target)
            } else {
                requestStop(TunnelStage.FAILED, "failed to establish the tun interface")
            }
        }, 0, VALIDATION_INTERVAL_MS, TimeUnit.MILLISECONDS)
    }

    private fun onTunnelReady(target: TunnelConfig) {
        validator?.shutdownNow()
        validator = null

        connectedAtMillis = System.currentTimeMillis()
        publish(TunnelStage.CONNECTED, null)
        startForegroundNotification(TunnelStage.CONNECTED)

        if (!target.proxyOnly) startStatsPolling()
    }

    private fun establishTun(target: TunnelConfig): Boolean {
        val builder = Builder()
            .setSession(SESSION_NAME)
            .setMtu(target.mtu)
            .addAddress(TunnelConfig.TUN_IPV4, TunnelConfig.TUN_IPV4_PREFIX)
            .addAddress(TunnelConfig.TUN_IPV6, TunnelConfig.TUN_IPV6_PREFIX)
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0)

        for (resolver in target.dnsServers) {
            runCatching { builder.addDnsServer(resolver) }
        }

        if (target.allowSelected) {
            if (!applyAllowList(builder, target)) return false
        } else {
            runCatching { builder.addDisallowedApplication(packageName) }
            if (target.bypassSelected) applyBypassList(builder, target)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        val descriptor = runCatching { builder.establish() }.getOrNull()
        if (descriptor == null) {
            TunnelBus.log(logSource(), "[-] the system refused to create the tun interface")
            return false
        }
        tunInterface = descriptor

        val hevLog = File(cacheDir, HEV_LOG_NAME)
        runCatching { hevLog.writeText("") }

        val configFile = File(cacheDir, HEV_CONFIG_NAME).apply {
            writeText(target.hevYaml(hevLog.absolutePath))
        }

        val started = runCatching {
            TProxyService.start(configFile.absolutePath, descriptor.fd)
        }.getOrElse { error ->
            TunnelBus.log(logSource(), "[-] hev tunnel failed to start: ${error.message}")
            false
        }

        if (!started) {
            runCatching { descriptor.close() }
            tunInterface = null
            return false
        }

        startHevLogTail(hevLog)
        TunnelBus.log(logSource(), "[+] tun interface up, routing through 127.0.0.1:${target.socksPort}")
        return true
    }

    private fun applyBypassList(builder: Builder, target: TunnelConfig): Boolean {
        var kept = 0
        for (bypassed in target.bypassedApps) {
            if (bypassed == packageName) continue
            try {
                builder.addDisallowedApplication(bypassed)
                kept++
            } catch (_: PackageManager.NameNotFoundException) {
                TunnelBus.log(logSource(), "[-] split tunnel skipped missing package $bypassed")
            }
        }
        TunnelBus.log(logSource(), "[+] split tunnel: $kept apps stay off the tunnel")
        return true
    }

    private fun applyAllowList(builder: Builder, target: TunnelConfig): Boolean {
        var kept = 0
        for (allowed in target.bypassedApps) {
            if (allowed == packageName) continue
            try {
                builder.addAllowedApplication(allowed)
                kept++
            } catch (_: PackageManager.NameNotFoundException) {
                TunnelBus.log(logSource(), "[-] split tunnel skipped missing package $allowed")
            }
        }

        if (kept == 0) {
            requestStop(
                TunnelStage.FAILED,
                "split tunnel is set to carry only the apps you pick, but none of them are installed",
            )
            return false
        }

        TunnelBus.log(logSource(), "[+] split tunnel: only $kept apps go through the tunnel")
        return true
    }

    private fun startHevLogTail(target: File) {
        val scheduler = Executors.newSingleThreadScheduledExecutor()
        hevLogTail = scheduler
        var offset = 0L

        scheduler.scheduleWithFixedDelay({
            runCatching {
                if (!target.exists()) return@runCatching
                val length = target.length()
                if (length < offset) offset = 0L
                if (length <= offset) return@runCatching

                target.inputStream().use { stream ->
                    stream.skip(offset)
                    val chunk = stream.readBytes()
                    offset += chunk.size

                    val lines = chunk.decodeToString()
                        .lineSequence()
                        .filter { it.isNotBlank() }
                        .toList()

                    if (lines.size > HEV_LOG_BURST) {
                        TunnelBus.log(
                            "hevtun",
                            "[!] skipped ${lines.size - HEV_LOG_BURST} noisy lines",
                        )
                    }
                    for (line in lines.takeLast(HEV_LOG_BURST)) {
                        TunnelBus.log("hevtun", line)
                    }
                }
            }
        }, HEV_LOG_INTERVAL_MS, HEV_LOG_INTERVAL_MS, TimeUnit.MILLISECONDS)
    }

    private fun startStatsPolling() {
        val scheduler = Executors.newSingleThreadScheduledExecutor()
        statsPoller = scheduler
        scheduler.scheduleWithFixedDelay({
            if (stopping.get() || !TProxyService.isRunning()) {
                return@scheduleWithFixedDelay
            }
            publish(TunnelStage.CONNECTED, null)
        }, STATS_INTERVAL_MS, STATS_INTERVAL_MS, TimeUnit.MILLISECONDS)
    }

    private fun requestStop(stage: TunnelStage, message: String?) {
        if (!stopping.compareAndSet(false, true)) {
            TunnelBus.publish(TunnelBus.snapshot)
            return
        }

        publish(TunnelStage.DISCONNECTING, message)
        runCatching { control.execute { stopTunnel(stage, message) } }
            .onFailure {
                stopping.set(false)
                publish(stage, message)
            }
    }

    private fun stopTunnel(stage: TunnelStage, message: String?) {
        stopping.set(true)
        if (stage == TunnelStage.FAILED && message != null) {
            TunnelBus.log(logSource(), "[-] $message")
        }
        teardown()
        publish(stage, message)
        stopForegroundCompat()
        stopSelf(latestStartId.get())
    }

    private fun teardown() {
        validator?.shutdownNow()
        validator = null
        statsPoller?.shutdownNow()
        statsPoller = null
        hevLogTail?.shutdownNow()
        hevLogTail = null

        runCatching { TProxyService.stop() }
        TunnelBus.bindCodeSink(null)
        core?.stop()
        core = null

        tunInterface?.let { descriptor ->
            runCatching { descriptor.close() }
        }
        tunInterface = null

        connectedAtMillis = 0L
    }

    private fun publish(stage: TunnelStage, message: String?) {
        val stats = if (stage == TunnelStage.CONNECTED) {
            TProxyService.stats()
        } else {
            TunnelStats.EMPTY
        }

        TunnelBus.publish(
            TunnelSnapshot(
                stage = stage,
                stats = stats,
                gateway = config?.endpoint?.takeIf { it.isNotBlank() },
                connectedAtMillis = if (stage == TunnelStage.CONNECTED) connectedAtMillis else 0L,
                message = message,
            ),
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.tunnel_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.tunnel_channel_description)
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        manager.createNotificationChannel(channel)
    }

    private fun appLabel(): String =
        runCatching { applicationInfo.loadLabel(packageManager).toString() }
            .getOrDefault("VPN")

    private fun startForegroundNotification(stage: TunnelStage) {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = launch?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
        val stopIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, AetherVpnService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val connected = stage == TunnelStage.CONNECTED
        val title = when (connected) {
            true -> getString(R.string.tunnel_state_connected)
            false -> getString(R.string.tunnel_state_connecting)
        }

        val body = config?.let { active ->
            when (connected) {
                true -> getString(
                    R.string.tunnel_proxy_at,
                    "${active.bindHost}:${active.socksPort}",
                )
                false -> active.protocol.uppercase()
            }
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setSubText(appLabel())
            .setSmallIcon(R.drawable.ic_tunnel_notification)
            .setColor(BRAND_COLOR)
            .setColorized(connected)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(connected)
            .setUsesChronometer(connected)
            .setWhen(if (connected && connectedAtMillis > 0L) connectedAtMillis else 0L)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .apply {
                if (body != null) setContentText(body)
                if (contentIntent != null) setContentIntent(contentIntent)
            }
            .addAction(
                R.drawable.ic_tunnel_notification,
                getString(R.string.tunnel_action_disconnect),
                stopIntent,
            )
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    companion object {
        private const val TAG = "OblivionVpn"

        const val ACTION_START = "org.bepass.oblivion.vpn.START"
        const val ACTION_STOP = "org.bepass.oblivion.vpn.STOP"
        const val EXTRA_CONFIG = "config"

        private const val CHANNEL_ID = "oblivion_tunnel"
        private const val NOTIFICATION_ID = 1
        private const val BRAND_COLOR = 0xFFFFA200.toInt()
        private const val SESSION_NAME = "Oblivion"
        private const val HEV_CONFIG_NAME = "hev-tunnel.yml"
        private const val HEV_LOG_NAME = "hev-tunnel.log"
        private const val CORE_AETHER = "aether"
        private const val CORE_PSIPHON = "psiphon"
        private const val PSIPHON_DATA_DIR = "psiphon"
        private const val PSIPHON_OVERLAY_NAME = "oblivion-psiphon.json"
        private const val PSIPHON_VALIDATION_BUDGET_MS = 180_000L


        private const val POST_SCAN_HEADROOM_MS = 60_000L

        private fun validationBudgetMs(scanMode: String): Long {
            val scanBudget = when (scanMode.trim().lowercase()) {
                "turbo", "fast" -> 45_000L
                "thorough", "deep", "pro" -> 300_000L
                "stealth", "quiet" -> 180_000L
                "ironclad", "real", "verify", "guaranteed" -> 180_000L
                else -> 120_000L
            }
            return scanBudget + POST_SCAN_HEADROOM_MS
        }
        private const val VALIDATION_INTERVAL_MS = 1_000L
        private const val STATS_INTERVAL_MS = 1_000L
        private const val HEV_LOG_INTERVAL_MS = 500L
        private const val HEV_LOG_BURST = 40

        fun start(context: Context, config: TunnelConfig) {
            val intent = Intent(context, AetherVpnService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_CONFIG, TunnelBundle.encode(config))
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, AetherVpnService::class.java)
                .setAction(ACTION_STOP)
            runCatching { context.startService(intent) }
                .onFailure { Log.d(TAG, "stop request ignored: ${it.message}") }
        }
    }
}
