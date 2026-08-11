package org.bepass.oblivion.vpn

import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket

object SocksProbe {
    private const val CONNECT_TIMEOUT_MS = 4000
    private const val READ_TIMEOUT_MS = 4000

    private const val PROBE_HOST = "connectivity.cloudflareclient.com"
    private const val PROBE_PORT = 80
    private const val PROBE_PATH = "/cdn-cgi/trace"

    fun reachable(socksPort: Int): Boolean {
        return runCatching { performProbe(socksPort) }.getOrDefault(false)
    }

    private fun performProbe(socksPort: Int): Boolean {
        Socket().use { socket ->
            socket.tcpNoDelay = true
            socket.soTimeout = READ_TIMEOUT_MS
            socket.connect(InetSocketAddress("127.0.0.1", socksPort), CONNECT_TIMEOUT_MS)

            val output = socket.getOutputStream()
            val input = socket.getInputStream()

            if (!handshake(output, input)) return false
            if (!connectThrough(output, input, PROBE_HOST, PROBE_PORT)) return false

            val request = buildString {
                append("GET $PROBE_PATH HTTP/1.1\r\n")
                append("Host: $PROBE_HOST\r\n")
                append("User-Agent: Oblivion\r\n")
                append("Connection: close\r\n\r\n")
            }
            output.write(request.toByteArray())
            output.flush()

            val head = ByteArray(64)
            val read = input.read(head)
            if (read <= 0) return false

            val statusLine = String(head, 0, read)
            return statusLine.contains(" 200")
        }
    }

    private fun handshake(output: OutputStream, input: InputStream): Boolean {
        output.write(byteArrayOf(0x05, 0x01, 0x00))
        output.flush()

        val reply = ByteArray(2)
        if (!input.readFully(reply)) return false
        return reply[0] == 0x05.toByte() && reply[1] == 0x00.toByte()
    }

    private fun connectThrough(
        output: OutputStream,
        input: InputStream,
        host: String,
        port: Int,
    ): Boolean {
        val hostBytes = host.toByteArray()
        if (hostBytes.size > 255) return false

        val request = ByteArray(7 + hostBytes.size)
        request[0] = 0x05
        request[1] = 0x01
        request[2] = 0x00
        request[3] = 0x03
        request[4] = hostBytes.size.toByte()
        hostBytes.copyInto(request, 5)
        request[5 + hostBytes.size] = ((port shr 8) and 0xFF).toByte()
        request[6 + hostBytes.size] = (port and 0xFF).toByte()

        output.write(request)
        output.flush()

        val head = ByteArray(4)
        if (!input.readFully(head)) return false
        if (head[1] != 0x00.toByte()) return false

        val trailing = when (head[3]) {
            0x01.toByte() -> 4 + 2
            0x04.toByte() -> 16 + 2
            0x03.toByte() -> {
                val lengthByte = ByteArray(1)
                if (!input.readFully(lengthByte)) return false
                (lengthByte[0].toInt() and 0xFF) + 2
            }
            else -> return false
        }

        return input.readFully(ByteArray(trailing))
    }

    private fun InputStream.readFully(buffer: ByteArray): Boolean {
        var offset = 0
        while (offset < buffer.size) {
            val read = try {
                read(buffer, offset, buffer.size - offset)
            } catch (_: IOException) {
                return false
            }
            if (read < 0) return false
            offset += read
        }
        return true
    }
}
