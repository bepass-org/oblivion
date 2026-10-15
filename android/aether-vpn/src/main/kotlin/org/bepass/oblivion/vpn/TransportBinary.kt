package org.bepass.oblivion.vpn

import android.content.Context
import java.io.File

object TransportBinary {
    private const val BINARY_NAME = "liblyrebird.so"

    private val TRANSPORTS = listOf(
        "obfs4",
        "snowflake",
        "webtunnel",
        "meek_lite",
        "obfs3",
        "scramblesuit",
    )

    fun binary(context: Context): File =
        File(context.applicationInfo.nativeLibraryDir, BINARY_NAME)

    fun path(context: Context): String? {
        val candidate = binary(context)
        return if (candidate.canExecute()) candidate.absolutePath else null
    }

    fun environment(context: Context): String? =
        path(context)?.let { path -> TRANSPORTS.joinToString(";") { "$it=$path" } }
}
