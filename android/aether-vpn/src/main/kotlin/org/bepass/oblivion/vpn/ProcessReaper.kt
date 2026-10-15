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
    private val VERSION_FLAGS = setOf("-v", "-version", "--version")

    class Running(
        val pid: Int,
        val program: String,
        val parent: Int?,
        val environment: Map<String, String>?,
        val arguments: List<String> = emptyList(),
    )

    fun owner(): String = Process.myPid().toString()

    fun clearLeftovers(core: String, helpers: Set<String>, listener: String?): List<String> {
        val running = scan(helpers + core)
        val cores = running.filter { it.program == core }
        val stale = cores.filter { isSession(it) || isStale(it, listener, ::isRunning) }
        stale.forEach { Process.killProcess(it.pid) }
        awaitGone(stale.map { it.pid })
        val live = cores.map { it.pid }.toSet() - stale.map { it.pid }.toSet()
        val notes = stale.map { "[!] ended a core left running by an earlier session (pid ${it.pid})" }
        return notes + endOrphans(running.filter { it.program in helpers }, live)
    }

    fun isSession(core: Running): Boolean = core.environment?.containsKey(LISTENER_VARIABLE) == true

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
            when (val parent = helper.parent) {
                null -> true
                in liveCores -> false
                self -> !isVersionProbe(helper)
                else -> true
            }
        }.map { it.pid }

    fun isVersionProbe(helper: Running): Boolean =
        helper.arguments.size == 2 && helper.arguments[1] in VERSION_FLAGS

    fun parentOf(stat: String): Int? {
        val close = stat.lastIndexOf(')')
        if (close < 0) return null
        return stat.substring(close + 1).trim().split(' ').getOrNull(1)?.toIntOrNull()
    }

    fun stateOf(stat: String): Char? {
        val close = stat.lastIndexOf(')')
        if (close < 0) return null
        return stat.substring(close + 1).trim().firstOrNull()
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
        awaitGone(orphans)
        val stubborn = orphans.filter(::isRunning)
        stubborn.forEach { Process.killProcess(it) }
        awaitGone(stubborn)
        return listOf("[!] ended ${orphans.size} helper process(es) a stopped core left behind")
    }

    private fun awaitGone(pids: List<Int>) {
        if (pids.isEmpty()) return
        val deadline = System.currentTimeMillis() + EXIT_WAIT_MS
        while (System.currentTimeMillis() < deadline && pids.any(::isRunning)) {
            Thread.sleep(POLL_MS)
        }
    }

    private fun isRunning(pid: Int): Boolean {
        val stat = runCatching { File(proc, "$pid/stat").readText() }.getOrNull() ?: return false
        return stateOf(stat) != 'Z'
    }

    private fun scan(names: Set<String>): List<Running> {
        val self = Process.myPid()
        val uid = Process.myUid()
        return proc.listFiles().orEmpty().mapNotNull { entry ->
            val pid = entry.name.toIntOrNull() ?: return@mapNotNull null
            if (pid == self) return@mapNotNull null
            val owned = runCatching { Os.stat(entry.path).st_uid == uid }.getOrDefault(false)
            if (!owned) return@mapNotNull null
            val arguments = read(File(entry, "cmdline"))?.let(::words) ?: return@mapNotNull null
            val name = File(arguments.firstOrNull() ?: return@mapNotNull null).name
            if (name !in names) return@mapNotNull null
            val stat = runCatching { File(entry, "stat").readText() }.getOrNull()
            if (stat != null && stateOf(stat) == 'Z') return@mapNotNull null
            Running(
                pid = pid,
                program = name,
                parent = stat?.let(::parentOf),
                environment = read(File(entry, "environ"))?.let(::words)?.let(::variables),
                arguments = arguments,
            )
        }
    }

    private fun read(file: File): ByteArray? = runCatching { file.readBytes() }.getOrNull()
}
