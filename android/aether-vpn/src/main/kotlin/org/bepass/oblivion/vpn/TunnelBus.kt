package org.bepass.oblivion.vpn

import android.content.Context
import java.io.File
import java.util.concurrent.CopyOnWriteArrayList

object TunnelBus {
    private const val LOG_FILE = "tunnel.log"
    private const val LOG_LIMIT_BYTES = 512 * 1024

    private val statusListeners = CopyOnWriteArrayList<(TunnelSnapshot) -> Unit>()
    private val logListeners = CopyOnWriteArrayList<(String) -> Unit>()

    @Volatile
    private var latest: TunnelSnapshot = TunnelSnapshot.DISCONNECTED

    @Volatile
    private var logFile: File? = null

    @Volatile
    private var codeSink: ((String) -> Boolean)? = null

    val snapshot: TunnelSnapshot get() = latest

    fun bindCodeSink(sink: ((String) -> Boolean)?) {
        codeSink = sink
    }

    fun submitCode(code: String): Boolean {
        val trimmed = code.trim()
        if (trimmed.isEmpty()) return false
        val sink = codeSink ?: return false
        return runCatching { sink(trimmed) }.getOrDefault(false)
    }

    fun bindService(context: Context) {
        if (logFile == null) {
            logFile = File(context.filesDir, LOG_FILE)
        }
    }

    fun unbindService(context: Context) {
        logFile?.let { bindService(context) }
    }

    fun addStatusListener(listener: (TunnelSnapshot) -> Unit) {
        statusListeners.add(listener)
        listener(latest)
    }

    fun removeStatusListener(listener: (TunnelSnapshot) -> Unit) {
        statusListeners.remove(listener)
    }

    fun addLogListener(listener: (String) -> Unit) {
        logListeners.add(listener)
    }

    fun removeLogListener(listener: (String) -> Unit) {
        logListeners.remove(listener)
    }

    fun publish(snapshot: TunnelSnapshot) {
        latest = snapshot
        for (listener in statusListeners) {
            runCatching { listener(snapshot) }
        }
    }

    fun log(source: String, line: String) {
        val trimmed = line.trimEnd()
        if (trimmed.isEmpty()) return
        log("[$source] $trimmed")
    }

    fun log(line: String) {
        for (listener in logListeners) {
            runCatching { listener(line) }
        }
        appendToFile(line)
    }

    private fun appendToFile(line: String) {
        val target = logFile ?: return
        runCatching {
            if (target.exists() && target.length() > LOG_LIMIT_BYTES) {
                val tail = target.readLines().takeLast(1200)
                target.writeText(tail.joinToString("\n", postfix = "\n"))
            }
            target.appendText("$line\n")
        }
    }

    fun readLogs(context: Context): String {
        bindService(context)
        val target = logFile ?: return ""
        if (!target.exists()) return ""
        return runCatching { target.readText() }.getOrDefault("")
    }

    fun clearLogs(context: Context) {
        bindService(context)
        val target = logFile ?: return
        runCatching { target.writeText("") }
    }

    fun reset() {
        latest = TunnelSnapshot.DISCONNECTED
        publish(latest)
    }
}
