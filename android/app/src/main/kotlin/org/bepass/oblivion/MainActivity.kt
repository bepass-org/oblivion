package org.bepass.oblivion

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import org.bepass.oblivion.vpn.TunnelBus

class MainActivity : FlutterActivity() {

    private var plugin: OblivionPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        TunnelBus.bindService(applicationContext)

        plugin = OblivionPlugin(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        ).also { it.attach() }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (plugin?.onActivityResult(requestCode, resultCode) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (plugin?.onRequestPermissionsResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        plugin?.detach()
        plugin = null
        super.onDestroy()
    }
}
