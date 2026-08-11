package org.bepass.oblivion.vpn

object TProxyService {
    init {
        System.loadLibrary("hev-socks5-tunnel")
    }

    @JvmStatic
    external fun TProxyStartService(configPath: String, fd: Int): Boolean

    @JvmStatic
    external fun TProxyStopService(): Boolean

    @JvmStatic
    external fun TProxyIsRunning(): Boolean

    @JvmStatic
    external fun TProxyGetStats(): LongArray

    fun start(configPath: String, fd: Int): Boolean = TProxyStartService(configPath, fd)

    fun stop(): Boolean = TProxyStopService()

    fun isRunning(): Boolean = TProxyIsRunning()

    fun stats(): TunnelStats {
        val raw = runCatching { TProxyGetStats() }.getOrNull()
        if (raw == null || raw.size < 4) return TunnelStats.EMPTY
        return TunnelStats(
            txPackets = raw[0],
            txBytes = raw[1],
            rxPackets = raw[2],
            rxBytes = raw[3],
        )
    }
}

data class TunnelStats(
    val txPackets: Long,
    val txBytes: Long,
    val rxPackets: Long,
    val rxBytes: Long,
) {
    fun toMap(): Map<String, Any> = mapOf(
        "txPackets" to txPackets,
        "txBytes" to txBytes,
        "rxPackets" to rxPackets,
        "rxBytes" to rxBytes,
    )

    companion object {
        val EMPTY = TunnelStats(0, 0, 0, 0)
    }
}
