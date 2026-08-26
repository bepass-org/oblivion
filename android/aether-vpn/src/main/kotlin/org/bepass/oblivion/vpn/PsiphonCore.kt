package org.bepass.oblivion.vpn

import android.content.Context
import android.util.Log
import java.io.BufferedReader
import java.io.File
import java.io.IOException
import java.io.InputStreamReader
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread
import org.json.JSONObject

class PsiphonCore(
    private val context: Context,
    private val onLog: (String) -> Unit,
    private val onExit: (Int) -> Unit,
    private val onSocksPort: (Int) -> Unit = {},
    private val onTunnels: (Int) -> Unit = {},
    private val onRouteBypass: (String) -> Unit = {},
) {
    private val running = AtomicBoolean(false)
    private var process: Process? = null
    private var readerThread: Thread? = null

    val isRunning: Boolean get() = running.get()

    fun binary(): File {
        val nativeDir = File(context.applicationInfo.nativeLibraryDir)
        return File(nativeDir, BINARY_NAME)
    }

    fun version(): String {
        val binary = binary()
        if (!binary.canExecute()) return "unavailable"

        return runCatching {
            val process = ProcessBuilder(binary.absolutePath, "-v")
                .redirectErrorStream(true)
                .start()
            val output = process.inputStream.bufferedReader().readText().trim()
            process.waitFor()
            output.lineSequence().firstOrNull()?.trim().orEmpty().ifEmpty { "unknown" }
        }.getOrElse { "unavailable" }
    }

    fun workDirectory(): File = File(context.filesDir, WORK_DIR).apply { mkdirs() }

    fun configFile(): File = File(workDirectory(), CONFIG_NAME)

    @Synchronized
    fun start(config: String) {
        if (running.get()) stop()

        val binary = binary()
        if (!binary.exists()) {
            onLog("[psiphon] [-] psiphon core binary is missing at ${binary.absolutePath}")
            onExit(-1)
            return
        }

        val workDir = workDirectory()
        val configFile = configFile()

        val written = runCatching { configFile.writeText(config) }
        if (written.isFailure) {
            onLog("[psiphon] [-] could not write the config: ${written.exceptionOrNull()?.message}")
            onExit(-1)
            return
        }

        val command = listOf(
            binary.absolutePath,
            "-config",
            configFile.absolutePath,
            "-dataRootDirectory",
            workDir.absolutePath,
        )

        val builder = ProcessBuilder(command)
            .directory(workDir)
            .redirectErrorStream(true)

        builder.environment().apply {
            put("HOME", workDir.absolutePath)
            put("TMPDIR", context.cacheDir.absolutePath)
        }

        val started = runCatching { builder.start() }.getOrElse { error ->
            onLog("[psiphon] [-] failed to launch psiphon core: ${error.message}")
            onExit(-1)
            return
        }

        process = started
        running.set(true)
        onLog("[psiphon] [+] psiphon core started")

        readerThread = thread(name = "psiphon-core-log", isDaemon = true) {
            drainOutput(started)
        }
    }

    private fun drainOutput(target: Process) {
        try {
            BufferedReader(InputStreamReader(target.inputStream)).use { reader ->
                while (true) {
                    val line = reader.readLine() ?: break
                    if (line.isNotBlank()) handleLine(line.trimEnd())
                }
            }
        } catch (error: IOException) {
            Log.d(TAG, "core output closed: ${error.message}")
        }

        val exitCode = runCatching { target.waitFor() }.getOrDefault(-1)
        val wasRunning = running.getAndSet(false)
        if (wasRunning) {
            onLog("[psiphon] [-] psiphon core exited with code $exitCode")
            onExit(exitCode)
        }
    }

    private fun handleLine(line: String) {
        if (!line.startsWith("{")) {
            onLog("[psiphon] $line")
            return
        }

        val notice = runCatching { JSONObject(line) }.getOrNull()
        if (notice == null) {
            onLog("[psiphon] $line")
            return
        }

        val kind = notice.optString("noticeType")
        val data = notice.optJSONObject("data")

        when (kind) {
            "ListeningSocksProxyPort" -> {
                val port = data?.optInt("port") ?: 0
                if (port > 0) {
                    onSocksPort(port)
                    onLog("[psiphon] [+] socks proxy listening on $port")
                }
            }

            "Tunnels" -> {
                val count = data?.optInt("count") ?: 0
                onTunnels(count)
                onLog(
                    if (count > 0) {
                        "[psiphon] [+] $count tunnel(s) established"
                    } else {
                        "[psiphon] [!] no tunnels are established"
                    },
                )
            }

            "ConnectedServerRegion" -> {
                val region = data?.optString("serverRegion").orEmpty()
                if (region.isNotEmpty()) {
                    onLog("[psiphon] [+] connected through $region")
                }
            }

            "ConnectedServer" -> {
                val address = data?.optString("routeBypassIPAddress").orEmpty()
                if (address.isNotEmpty()) {
                    onRouteBypass(address)
                    onLog("[psiphon] [+] server $address must stay outside the tunnel")
                }
            }

            "EstablishTunnelTimeout" ->
                onLog("[psiphon] [-] psiphon could not establish a tunnel in time")

            "SocksProxyPortInUse" ->
                onLog("[psiphon] [-] the socks port ${data?.optInt("port")} is already in use")

            "HttpProxyPortInUse" ->
                onLog("[psiphon] [-] the http proxy port ${data?.optInt("port")} is already in use")

            "Error", "Alert" ->
                onLog("[psiphon] [-] ${data?.optString("message").orEmpty()}")

            "Info", "Warning" -> {
                val message = data?.optString("message").orEmpty()
                if (message.isNotEmpty()) onLog("[psiphon] [*] $message")
            }
        }
    }

    @Synchronized
    fun stop() {
        val target = process ?: return
        running.set(false)
        process = null

        runCatching { target.destroy() }
        if (!target.waitForTimeout(GRACEFUL_SHUTDOWN_MS)) {
            runCatching { target.destroyForcibly() }
        }

        readerThread?.interrupt()
        readerThread = null
    }

    private fun Process.waitForTimeout(millis: Long): Boolean {
        val deadline = System.currentTimeMillis() + millis
        while (System.currentTimeMillis() < deadline) {
            if (!isAlive) return true
            Thread.sleep(30)
        }
        return !isAlive
    }

    companion object {
        private const val TAG = "PsiphonCore"
        private const val BINARY_NAME = "libpsiphon.so"
        private const val WORK_DIR = "psiphon"
        private const val CONFIG_NAME = "psiphon.config"
        private const val GRACEFUL_SHUTDOWN_MS = 1500L
    }
}
