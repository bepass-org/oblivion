package org.bepass.oblivion.vpn

import android.os.Process
import android.system.Os
import android.system.OsConstants
import java.io.File

object ProcessReaper {
    const val OWNER_VARIABLE = "OBLIVION_CORE_OWNER"

    private const val LISTENER_VARIABLE = "AETHER_SOCKS"
    private const val EXIT_WAIT_MS = 1500L
    private const val POLL_MS = 50L
    private val proc = File("/proc")

    class Running(
        val pid: Int,
        val program: String,
        val parent: Int?,
        val environment: Map<String, String>?,
    )

    fun owner(): String = Process.myPid().toString()

    fun clearLeftovers(core: String, helpers: Set<String>, listener: String?): List<String> {
        val running = scan(helpers + core)
        val cores = running.filter { it.program == core }
        val stale = cores.filter { isStale(it, listener, ::isRunning) }
        stale.forEach { Process.killProcess(it.pid) }
        val live = cores.map { it.pid }.toSet() - stale.map { it.pid }.toSet()
        val notes = stale.map { "[!] ended a core left running by an earlier session (pid ${it.pid})" }
        return notes + endOrphans(running.filter { it.program in helpers }, live)
    }

    fun clearOrphans(core: String, helpers: Set<String>): List<String> {
        val running = scan(helpers + core)
        val live = running.filter { it.program == core }.map { it.pid }.toSet()
        return endOrphans(running.filter { it.program in helpers }, live)
    }

    fun isStale(core: Running, listener: String?, alive: (Int) -> Boolean): Boolean {
        val environment = core.environment ?: return false
        val owner = environment[OWNER_VARIABLE]?.toIntOrNull()
        if (owner != null && !alive(owner)) return true
        return listener != null && environment[LISTENER_VARIABLE] == listener
    }

    fun orphans(helpers: List<Running>, liveCores: Set<Int>, self: Int): List<Int> =
        helpers.filter { helper ->
            val parent = helper.parent
            parent == null || (parent != self && parent !in liveCores)
        }.map { it.pid }

    fun parentOf(stat: String): Int? {
        val close = stat.lastIndexOf(')')
        if (close < 0) return null
        return stat.substring(close + 1).trim().split(' ').getOrNull(1)?.toIntOrNull()
    }

    fun words(raw: ByteArray): List<String> =
        String(raw, Charsets.UTF_8).split('\u0000').dropLastWhile(String::isEmpty)

    fun variables(words: List<String>): Map<String, String> =
        words.mapNotNull { word ->
            val split = word.indexOf('=')
            if (split <= 0) null else word.substring(0, split) to word.substring(split + 1)
        }.toMap()

    private fun endOrphans(helpers: List<Running>, liveCores: Set<Int>): List<String> {
        val orphans = orphans(helpers, liveCores, Process.myPid())
        if (orphans.isEmpty()) return emptyList()
        orphans.forEach { runCatching { Process.sendSignal(it, OsConstants.SIGTERM) } }
        val deadline = System.currentTimeMillis() + EXIT_WAIT_MS
        while (System.currentTimeMillis() < deadline && orphans.any(::isRunning)) {
            Thread.sleep(POLL_MS)
        }
        orphans.filter(::isRunning).forEach { Process.killProcess(it) }
        return listOf("[!] ended ${orphans.size} helper process(es) a stopped core left behind")
    }

    private fun isRunning(pid: Int): Boolean = File(proc, pid.toString()).isDirectory

    private fun scan(names: Set<String>): List<Running> {
        val self = Process.myPid()
        val uid = Process.myUid()
        return proc.listFiles().orEmpty().mapNotNull { entry ->
            val pid = entry.name.toIntOrNull() ?: return@mapNotNull null
            if (pid == self) return@mapNotNull null
            val owned = runCatching { Os.stat(entry.path).st_uid == uid }.getOrDefault(false)
            if (!owned) return@mapNotNull null
            val program = read(File(entry, "cmdline"))?.let(::words)?.firstOrNull()
                ?: return@mapNotNull null
            val name = File(program).name
            if (name !in names) return@mapNotNull null
            Running(
                pid = pid,
                program = name,
                parent = runCatching { File(entry, "stat").readText() }.getOrNull()?.let(::parentOf),
                environment = read(File(entry, "environ"))?.let(::words)?.let(::variables),
            )
        }
    }

    private fun read(file: File): ByteArray? = runCatching { file.readBytes() }.getOrNull()
}
