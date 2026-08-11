package org.bepass.oblivion.vpn

enum class TunnelStage(val wire: String) {
    DISCONNECTED("disconnected"),
    CONNECTING("connecting"),
    VALIDATING("validating"),
    CONNECTED("connected"),
    DISCONNECTING("disconnecting"),
    FAILED("failed");

    val isIdle: Boolean get() = this == DISCONNECTED || this == FAILED
}

data class TunnelSnapshot(
    val stage: TunnelStage,
    val stats: TunnelStats,
    val gateway: String?,
    val connectedAtMillis: Long,
    val message: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "stage" to stage.wire,
        "stats" to stats.toMap(),
        "gateway" to gateway,
        "connectedAt" to connectedAtMillis,
        "message" to message,
    )

    companion object {
        val DISCONNECTED = TunnelSnapshot(
            stage = TunnelStage.DISCONNECTED,
            stats = TunnelStats.EMPTY,
            gateway = null,
            connectedAtMillis = 0L,
            message = null,
        )
    }
}
