package org.bepass.oblivion.vpn

import android.content.Context
import java.io.File

object PsiphonBinary {
    private const val BINARY_NAME = "libpsiphon.so"

    fun binary(context: Context): File =
        File(context.applicationInfo.nativeLibraryDir, BINARY_NAME)

    fun path(context: Context): String? {
        val candidate = binary(context)
        return if (candidate.canExecute()) candidate.absolutePath else null
    }

    fun version(context: Context): String {
        val candidate = binary(context)
        if (!candidate.canExecute()) return "unavailable"

        return runCatching {
            val process = ProcessBuilder(candidate.absolutePath, "-v")
                .redirectErrorStream(true)
                .start()
            val output = process.inputStream.bufferedReader().readText().trim()
            process.waitFor()
            output.lineSequence()
                .map(String::trim)
                .firstOrNull { it.startsWith("Revision:") }
                ?.removePrefix("Revision:")
                ?.trim()
                ?.takeIf(String::isNotEmpty)
                ?.let { "psiphon $it" }
                ?: "psiphon (unavailable revision)"
        }.getOrElse { "unavailable" }
    }
}
