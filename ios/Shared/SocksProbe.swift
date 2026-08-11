import Darwin
import Foundation

enum SocksProbe {
    static func reachable(port: Int, timeout: TimeInterval = 2) -> Bool {
        let handle = socket(AF_INET, SOCK_STREAM, 0)
        guard handle >= 0 else { return false }
        defer { close(handle) }

        var send = timeval(
            tv_sec: Int(timeout),
            tv_usec: Int32((timeout - Double(Int(timeout))) * 1_000_000)
        )
        setsockopt(handle, SOL_SOCKET, SO_SNDTIMEO, &send, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO, &send, socklen_t(MemoryLayout<timeval>.size))

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(UInt16(port).bigEndian)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")

        let connected = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { generic in
                Darwin.connect(handle, generic, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard connected == 0 else { return false }

        var greeting: [UInt8] = [0x05, 0x01, 0x00]
        let written = greeting.withUnsafeBytes { bytes in
            Darwin.send(handle, bytes.baseAddress, bytes.count, 0)
        }
        guard written == greeting.count else { return false }

        var answer = [UInt8](repeating: 0, count: 2)
        let read = answer.withUnsafeMutableBytes { bytes in
            recv(handle, bytes.baseAddress, bytes.count, 0)
        }
        return read == 2 && answer[0] == 0x05
    }
}
