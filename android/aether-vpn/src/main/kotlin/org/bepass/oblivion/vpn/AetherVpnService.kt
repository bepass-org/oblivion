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
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class AetherVpnService : VpnService() {

    private var tunInterface: ParcelFileDescriptor? = null
    private var core: AetherCore? = null
    private var psiphon: PsiphonTunnelWrapper? = null
    private var config: TunnelConfig? = null

    private var validator: ScheduledExecutorService? = null
    private var statsPoller: ScheduledExecutorService? = null
    private var hevLogTail: ScheduledExecutorService? = null

    private val control = Executors.newSingleThreadExecutor()

    private var connectedAtMillis = 0L

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        TunnelBus.bindService(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val payload = intent.getBundleExtra(EXTRA_CONFIG)
                if (payload == null) {
                    stopTunnel(TunnelStage.FAILED, "missing tunnel configuration")
                    return START_NOT_STICKY
                }
                startTunnel(TunnelBundle.decode(payload))
            }
            ACTION_STOP -> stopTunnel(TunnelStage.DISCONNECTED, null)
        }
        return START_STICKY
    }

    override fun onRevoke() {
        TunnelBus.log(logSource(), "[-] vpn permission revoked by the system")
        stopTunnel(TunnelStage.DISCONNECTED, "revoked")
        super.onRevoke()
    }

    override fun onDestroy() {
        teardown()
        control.shutdown()
        TunnelBus.unbindService(this)
        super.onDestroy()
    }

    private fun startTunnel(target: TunnelConfig) {
        teardown()
        config = target
        connectedAtMillis = 0L

        publish(TunnelStage.CONNECTING, null)
        startForegroundNotification(TunnelStage.CONNECTING)

        if (target.core == CORE_PSIPHON) {
            startPsiphonTunnel(target)
        } else {
            startAetherTunnel(target)
        }
    }

    private fun startAetherTunnel(target: TunnelConfig) {
        val runner = AetherCore(
            context = applicationContext,
            onLog = { line -> TunnelBus.log(line) },
            onExit = { code ->
                if (code != 0) {
                    stopTunnel(TunnelStage.FAILED, "core exited with code $code")
                }
            },
        )
        core = runner
        TunnelBus.bindCodeSink(runner::submitLine)
        runner.start(target.coreArguments, coreEnvironment(target))
        if (!runner.isRunning) return

        scheduleValidation(target)
    }

    private fun startPsiphonTunnel(target: TunnelConfig) {
        val dataDir = File(filesDir, PSIPHON_DATA_DIR)
        if (!dataDir.exists() && !dataDir.mkdirs()) {
            stopTunnel(TunnelStage.FAILED, "could not prepare the psiphon data directory")
            return
        }

        val configJson = runCatching { PsiphonConfig.build(target, dataDir) }.getOrElse { error ->
            stopTunnel(TunnelStage.FAILED, "could not build the psiphon config: ${error.message}")
            return
        }

        val psiphonRunner = PsiphonTunnelWrapper(
            service = this,
            configJson = configJson,
            onLog = { line -> TunnelBus.log(line) },
            onStopped = { reason ->
                control.execute {
                    stopTunnel(
                        TunnelStage.FAILED,
                        reason ?: "the psiphon core stopped before the tunnel came up",
                    )
                }
            },
        )
        psiphon = psiphonRunner
        psiphonRunner.start()
        if (!psiphonRunner.isRunning) return

        scheduleValidation(target)
    }

    private fun coreEnvironment(target: TunnelConfig): Map<String, String> {
        val environment = mutableMapOf(
            "AETHER_SOCKS" to "${target.bindHost}:${target.socksPort}",
            "AETHER_HTTP_PROXY" to "${target.bindHost}:${target.httpProxyPort}",
            "AETHER_PROTOCOL" to target.protocol,
            "AETHER_SCAN" to target.scanMode,
            "AETHER_NOIZE" to target.noizeProfile,
            "AETHER_IP" to target.ipVersion,
            "AETHER_LOG_LEVEL" to target.logLevel,
            "AETHER_QUICK_RECONNECT" to if (target.quickReconnect) "1" else "0",
        )

        if (target.protocol == "masque" && target.transport == "h2") {
            environment["AETHER_MASQUE_HTTP2"] = "1"
            if (target.fragment) environment["AETHER_MASQUE_H2_FRAGMENT"] = "1"
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

    private fun logSource(): String =
        config?.core?.trim()?.takeIf { it.isNotEmpty() } ?: CORE_AETHER

    private fun activeCoreIsRunning(): Boolean = when {
        psiphon != null -> psiphon?.isRunning == true
        else -> core?.isRunning == true
    }

    private fun scheduleValidation(target: TunnelConfig) {
        val scheduler = Executors.newSingleThreadScheduledExecutor()
        validator = scheduler

        val usesPsiphon = target.core == CORE_PSIPHON
        val budgetMs = if (usesPsiphon) {
            PSIPHON_VALIDATION_BUDGET_MS
        } else {
            validationBudgetMs(target.scanMode)
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
                stopTunnel(TunnelStage.FAILED, "the core stopped before the tunnel came up")
                return@scheduleWithFixedDelay
            }

            if (System.currentTimeMillis() > deadline) {
                stopTunnel(
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

            if (!SocksProbe.reachable(target.socksPort)) return@scheduleWithFixedDelay

            TunnelBus.log(logSource(), "[+] socks5 proxy answered a real request")
            if (target.proxyOnly) {
                onTunnelReady(target)
            } else if (establishTun(target)) {
                onTunnelReady(target)
            } else {
                stopTunnel(TunnelStage.FAILED, "failed to establish the tun interface")
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

        runCatching { builder.addDisallowedApplication(packageName) }

        if (target.bypassSelected) {
            for (bypassed in target.bypassedApps) {
                if (bypassed == packageName) continue
                try {
                    builder.addDisallowedApplication(bypassed)
                } catch (_: PackageManager.NameNotFoundException) {
                    TunnelBus.log(logSource(), "[-] split tunnel skipped missing package $bypassed")
                }
            }
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
                    chunk.decodeToString()
                        .lineSequence()
                        .filter { it.isNotBlank() }
                        .forEach { TunnelBus.log("hevtun", it) }
                }
            }
        }, HEV_LOG_INTERVAL_MS, HEV_LOG_INTERVAL_MS, TimeUnit.MILLISECONDS)
    }

    private fun startStatsPolling() {
        val scheduler = Executors.newSingleThreadScheduledExecutor()
        statsPoller = scheduler
        scheduler.scheduleWithFixedDelay({
            if (!TProxyService.isRunning()) return@scheduleWithFixedDelay
            publish(TunnelStage.CONNECTED, null)
        }, STATS_INTERVAL_MS, STATS_INTERVAL_MS, TimeUnit.MILLISECONDS)
    }

    private fun stopTunnel(stage: TunnelStage, message: String?) {
        if (stage == TunnelStage.FAILED && message != null) {
            TunnelBus.log(logSource(), "[-] $message")
        }
        publish(TunnelStage.DISCONNECTING, message)
        teardown()
        publish(stage, message)
        stopForegroundCompat()
        stopSelf()
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
        psiphon?.stop()
        psiphon = null

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
