package org.bepass.oblivion

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.io.ByteArrayOutputStream
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.bepass.oblivion.vpn.AetherCore
import org.bepass.oblivion.vpn.AetherVpnService
import org.bepass.oblivion.vpn.TunnelBus
import org.bepass.oblivion.vpn.TunnelConfig
import org.bepass.oblivion.vpn.TunnelSnapshot

class OblivionPlugin(
    private val activity: Activity,
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val context: Context get() = activity.applicationContext
    private val main = Handler(Looper.getMainLooper())

    private val methodChannel = MethodChannel(messenger, CHANNEL_METHODS)
    private val statusChannel = EventChannel(messenger, CHANNEL_STATUS)
    private val logChannel = EventChannel(messenger, CHANNEL_LOGS)

    private var statusSink: EventChannel.EventSink? = null
    private var logSink: EventChannel.EventSink? = null

    private var pendingPermission: MethodChannel.Result? = null
    private var pendingNotifications: MethodChannel.Result? = null

    private val statusListener: (TunnelSnapshot) -> Unit = { snapshot ->
        main.post { statusSink?.success(snapshot.toMap()) }
    }

    private val logListener: (String) -> Unit = { line ->
        main.post { logSink?.success(line) }
    }

    fun attach() {
        methodChannel.setMethodCallHandler(this)

        statusChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                statusSink = events
                TunnelBus.addStatusListener(statusListener)
            }

            override fun onCancel(arguments: Any?) {
                TunnelBus.removeStatusListener(statusListener)
                statusSink = null
            }
        })

        logChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                logSink = events
                TunnelBus.addLogListener(logListener)
            }

            override fun onCancel(arguments: Any?) {
                TunnelBus.removeLogListener(logListener)
                logSink = null
            }
        })
    }

    fun detach() {
        methodChannel.setMethodCallHandler(null)
        statusChannel.setStreamHandler(null)
        logChannel.setStreamHandler(null)
        TunnelBus.removeStatusListener(statusListener)
        TunnelBus.removeLogListener(logListener)
        statusSink = null
        logSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> handlePrepare(result)
            "connect" -> handleConnect(call, result)
            "disconnect" -> {
                AetherVpnService.stop(context)
                result.success(null)
            }
            "status" -> result.success(TunnelBus.snapshot.toMap())
            "submitLoginCode" -> {
                val code = call.argument<String>("code").orEmpty()
                result.success(TunnelBus.submitCode(code))
            }
            "requestNotifications" -> handleNotificationPermission(result)
            "readLogs" -> result.success(TunnelBus.readLogs(context))
            "clearLogs" -> {
                TunnelBus.clearLogs(context)
                result.success(null)
            }
            "coreVersion" -> result.success(
                AetherCore(context, onLog = {}, onExit = {}).version(),
            )
            "installedApps" -> handleInstalledApps(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        val granted = context.checkSelfPermission(NOTIFICATION_PERMISSION) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success(true)
            return
        }

        if (pendingNotifications != null) {
            result.success(false)
            return
        }

        pendingNotifications = result
        activity.requestPermissions(
            arrayOf(NOTIFICATION_PERMISSION),
            REQUEST_NOTIFICATIONS,
        )
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_NOTIFICATIONS) return false
        val result = pendingNotifications ?: return true
        pendingNotifications = null
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        result.success(granted)
        return true
    }

    private fun handlePrepare(result: MethodChannel.Result) {
        val intent = VpnService.prepare(context)
        if (intent == null) {
            result.success(true)
            return
        }

        pendingPermission = result
        activity.startActivityForResult(intent, REQUEST_VPN_PERMISSION)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_VPN_PERMISSION) return false
        val result = pendingPermission ?: return true
        pendingPermission = null
        result.success(resultCode == Activity.RESULT_OK)
        return true
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleConnect(call: MethodCall, result: MethodChannel.Result) {
        val settings = call.argument<Map<String, Any?>>("settings")
        val arguments = call.argument<List<String>>("arguments") ?: emptyList()

        if (settings == null) {
            result.error("bad_args", "settings payload is required", null)
            return
        }

        val config = TunnelConfig.fromMap(settings, arguments)
        AetherVpnService.start(context, config)
        result.success(null)
    }

    private fun handleInstalledApps(call: MethodCall, result: MethodChannel.Result) {
        val includeSystem = call.argument<Boolean>("includeSystem") ?: false
        val manager = context.packageManager

        val apps = manager.getInstalledApplications(PackageManager.GET_META_DATA)
            .asSequence()
            .filter { info -> info.packageName != context.packageName }
            .filter { info ->
                val isSystem = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                if (includeSystem) true else !isSystem || hasLauncher(manager, info)
            }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "label" to manager.getApplicationLabel(info).toString(),
                    "isSystem" to ((info.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                    "icon" to encodeIcon(manager.getApplicationIcon(info)),
                )
            }
            .toList()

        result.success(apps)
    }

    private fun hasLauncher(manager: PackageManager, info: ApplicationInfo): Boolean {
        return manager.getLaunchIntentForPackage(info.packageName) != null
    }

    private fun encodeIcon(drawable: Drawable): ByteArray? {
        val size = ICON_SIZE_PX
        return runCatching {
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)

            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                bitmap.recycle()
                stream.toByteArray()
            }
        }.getOrNull()
    }

    companion object {
        private const val CHANNEL_METHODS = "org.bepass.oblivion/tunnel"
        private const val CHANNEL_STATUS = "org.bepass.oblivion/tunnel_status"
        private const val CHANNEL_LOGS = "org.bepass.oblivion/tunnel_logs"

        private const val REQUEST_VPN_PERMISSION = 9001
        private const val REQUEST_NOTIFICATIONS = 9002
        private const val NOTIFICATION_PERMISSION =
            "android.permission.POST_NOTIFICATIONS"
        private const val ICON_SIZE_PX = 96
    }
}
