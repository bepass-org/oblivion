package org.bepass.oblivion.vpn

import android.content.Context
import android.net.VpnService
import ca.psiphon.PsiphonTunnel
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import org.json.JSONObject
import psi.Psi

class PsiphonTunnelWrapper(
    private val service: VpnService,
    private val configJson: String,
    private val onLog: (String) -> Unit,
    private val onStopped: (String?) -> Unit,
    private val onSocksPort: (Int) -> Unit = {},
) {
    private val active = AtomicBoolean(false)
    private val socksPort = AtomicInteger(0)
    private var tunnel: PsiphonTunnel? = null

    val isRunning: Boolean get() = active.get()

    val listeningSocksPort: Int get() = socksPort.get()

    private val host = object : PsiphonTunnel.HostService {
        override fun getContext(): Context = service

        override fun getPsiphonConfig(): String = configJson

        override fun bindToDevice(fileDescriptor: Long) {
            if (!service.protect(fileDescriptor.toInt())) {
                throw IllegalStateException("VpnService.protect failed for fd $fileDescriptor")
            }
        }

        override fun onDiagnosticMessage(message: String) {
            onLog("[psiphon] [*] $message")
        }

        override fun onListeningSocksProxyPort(port: Int) {
            socksPort.set(port)
            onSocksPort(port)
            onLog("[psiphon] [+] socks proxy listening on $port")
        }

        override fun onSocksProxyPortInUse(port: Int) {
            fail("the socks port $port is already in use")
        }

        override fun onHttpProxyPortInUse(port: Int) {
            fail("the http proxy port $port is already in use")
        }

        override fun onConnecting() {
            onLog("[psiphon] [*] establishing a tunnel")
        }

        override fun onConnected() {
            onLog("[psiphon] [+] tunnel established")
        }

        override fun onConnectedServerRegion(region: String) {
            onLog("[psiphon] [+] connected through $region")
        }

        override fun onClientRegion(region: String) {
            onLog("[psiphon] [*] client region reported as $region")
        }

        override fun onUntunneledAddress(address: String) {
            onLog("[psiphon] [*] $address stays outside the tunnel")
        }

        override fun onUpstreamProxyError(message: String) {
            fail("upstream proxy error: $message")
        }

        override fun onInproxyMustUpgrade() {
            fail("this build is too old for the selected conduit mode")
        }

        override fun onExiting() {
            if (active.compareAndSet(true, false)) {
                onLog("[psiphon] [-] psiphon core is exiting")
                onStopped(null)
            }
        }
    }

    @Synchronized
    fun start() {
        if (active.get()) stop()
        socksPort.set(0)

        val started = runCatching {
            val instance = PsiphonTunnel.newPsiphonTunnel(host)
            tunnel = instance
            instance.setVpnMode(true)
            active.set(true)
            instance.startTunneling("")
        }

        started.onFailure { error ->
            active.set(false)
            tunnel = null
            onLog("[psiphon] [-] psiphon core failed to start: ${error.message}")
            onStopped(error.message ?: "psiphon core failed to start")
            return
        }

        onLog("[psiphon] [+] psiphon core started")
    }

    @Synchronized
    fun stop() {
        val instance = tunnel ?: return
        active.set(false)
        tunnel = null
        socksPort.set(0)
        runCatching { instance.stop() }
    }

    private fun fail(message: String) {
        if (active.compareAndSet(true, false)) {
            onLog("[psiphon] [-] $message")
            onStopped(message)
        }
    }

    companion object {
        fun version(): String {
            val info = runCatching { JSONObject(Psi.getBuildInfo()) }.getOrNull()
                ?: return UNAVAILABLE

            val revision = info.optString("buildRev").trim()
            return if (revision.isEmpty()) {
                "psiphon ($UNAVAILABLE revision)"
            } else {
                "psiphon $revision"
            }
        }

        private const val UNAVAILABLE = "unavailable"
    }
}
