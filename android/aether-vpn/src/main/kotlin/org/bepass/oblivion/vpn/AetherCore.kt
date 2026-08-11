package org.bepass.oblivion.vpn

import android.content.Context
import android.util.Log
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.File
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

class AetherCore(
    private val context: Context,
    private val onLog: (String) -> Unit,
    private val onExit: (Int) -> Unit,
) {
    private val running = AtomicBoolean(false)
    private var process: Process? = null
    private var readerThread: Thread? = null
    private var input: BufferedWriter? = null

    val isRunning: Boolean get() = running.get()

    fun binary(): File {
        val nativeDir = File(context.applicationInfo.nativeLibraryDir)
        return File(nativeDir, BINARY_NAME)
    }

    fun version(): String {
        val binary = binary()
        if (!binary.canExecute()) return "unavailable"

        return runCatching {
            val process = ProcessBuilder(binary.absolutePath, "--version")
                .redirectErrorStream(true)
                .start()
            val output = process.inputStream.bufferedReader().readText().trim()
            process.waitFor()
            output.ifEmpty { "unknown" }
        }.getOrElse { "unavailable" }
    }

    @Synchronized
    fun start(arguments: List<String>, environment: Map<String, String>) {
        if (running.get()) stop()

        val binary = binary()
        if (!binary.exists()) {
            onLog("[aether] [-] aether core binary is missing at ${binary.absolutePath}")
            onExit(-1)
            return
        }

        val workDir = File(context.filesDir, WORK_DIR).apply { mkdirs() }
        val command = mutableListOf(binary.absolutePath).apply { addAll(arguments) }

        val builder = ProcessBuilder(command)
            .directory(workDir)
            .redirectErrorStream(true)

        builder.environment().apply {
            put("HOME", workDir.absolutePath)
            put("TMPDIR", context.cacheDir.absolutePath)
            put("AETHER_CONFIG", File(workDir, "aether.toml").absolutePath)
            put("AETHER_WG_CONFIG", File(workDir, "aether-wg.toml").absolutePath)
            put("AETHER_MASQUE_CONFIG", File(workDir, "aether-masque.toml").absolutePath)
            putAll(environment)
        }

        val started = runCatching { builder.start() }.getOrElse { error ->
            onLog("[aether] [-] failed to launch aether core: ${error.message}")
            onExit(-1)
            return
        }

        process = started
        input = BufferedWriter(OutputStreamWriter(started.outputStream))
        running.set(true)
        onLog("[aether] [+] aether core started: ${arguments.joinToString(" ")}")

        readerThread = thread(name = "aether-core-log", isDaemon = true) {
            drainOutput(started)
        }
    }

    private fun drainOutput(target: Process) {
        try {
            BufferedReader(InputStreamReader(target.inputStream)).use { reader ->
                while (true) {
                    val line = reader.readLine() ?: break
                    if (line.isNotBlank()) onLog("[aether] ${line.trimEnd()}")
                }
            }
        } catch (error: IOException) {
            Log.d(TAG, "core output closed: ${error.message}")
        }

        val exitCode = runCatching { target.waitFor() }.getOrDefault(-1)
        val wasRunning = running.getAndSet(false)
        if (wasRunning) {
            onLog("[aether] [-] aether core exited with code $exitCode")
            onExit(exitCode)
        }
    }

    @Synchronized
    fun submitLine(line: String): Boolean {
        val writer = input ?: return false
        if (!running.get()) return false

        return runCatching {
            writer.write(line)
            writer.newLine()
            writer.flush()
            true
        }.getOrElse { error ->
            onLog("[aether] [-] could not reach the core: ${error.message}")
            false
        }
    }

    @Synchronized
    fun stop() {
        val target = process ?: return
        running.set(false)
        process = null

        runCatching { input?.close() }
        input = null

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
        private const val TAG = "AetherCore"
        private const val BINARY_NAME = "libaether.so"
        private const val WORK_DIR = "aether"
        private const val GRACEFUL_SHUTDOWN_MS = 1500L
    }
}
