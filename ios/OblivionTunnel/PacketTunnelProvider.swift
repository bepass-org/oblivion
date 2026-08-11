import Foundation
import HevSocks5Tunnel
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    private static let tunIpv4 = "198.18.0.1"
    private static let tunIpv6 = "fc00::1"
    private static let tunMtu = 8500

    private var core: AetherCoreBridge?
    private var hevThread: Thread?
    private var validationTask: Task<Void, Never>?

    override func startTunnel(options: [String: NSObject]?) async throws {
        let settings = resolveSettings(options: options)
        let socksPort = (settings["socksPort"] as? NSNumber)?.intValue ?? 1819
        let proxyOnly = (settings["proxyOnly"] as? NSNumber)?.boolValue ?? false
        let coreArguments = settings["coreArguments"] as? [String] ?? []

        TunnelLogStore.shared.append("aether", "[*] starting the aether core")

        let bridge = AetherCoreBridge(
            workingDirectory: TunnelStoreFactory.workingDirectory()
        )
        core = bridge
        try bridge.start(arguments: coreArguments, environment: coreEnvironment(settings))

        try await waitForProxy(port: socksPort)
        TunnelLogStore.shared.append("aether", "[+] socks5 proxy answered a real request")

        guard !proxyOnly else {
            TunnelLogStore.shared.append("aether", "[+] running in proxy only mode")
            return
        }

        try await applyTunnelSettings(socksPort: socksPort)
        startHev(socksPort: socksPort, logLevel: settings["logLevel"] as? String ?? "info")
        TunnelLogStore.shared.append("aether", "[+] tun interface up, routing into 127.0.0.1:\(socksPort)")
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        TunnelLogStore.shared.append("aether", "[-] stopping the tunnel: \(reason.rawValue)")

        validationTask?.cancel()
        validationTask = nil

        hev_socks5_tunnel_quit()
        hevThread = nil

        core?.stop()
        core = nil
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        var txPackets = 0
        var txBytes = 0
        var rxPackets = 0
        var rxBytes = 0
        hev_socks5_tunnel_stats(&txPackets, &txBytes, &rxPackets, &rxBytes)

        let payload: [String: Any] = [
            "txPackets": txPackets,
            "txBytes": txBytes,
            "rxPackets": rxPackets,
            "rxBytes": rxBytes,
        ]
        return try? JSONSerialization.data(withJSONObject: payload)
    }

    private func resolveSettings(options: [String: NSObject]?) -> [String: Any] {
        if let inline = options?["settings"] as? [String: Any] {
            return inline
        }
        let proto = protocolConfiguration as? NETunnelProviderProtocol
        return proto?.providerConfiguration ?? [:]
    }

    private func coreEnvironment(_ settings: [String: Any]) -> [String: String] {
        let socksPort = (settings["socksPort"] as? NSNumber)?.intValue ?? 1819
        let allowLan = (settings["allowLan"] as? NSNumber)?.boolValue ?? false
        let host = allowLan ? "0.0.0.0" : "127.0.0.1"

        var environment: [String: String] = [
            "AETHER_SOCKS": "\(host):\(socksPort)",
            "AETHER_PROTOCOL": settings["protocol"] as? String ?? "masque",
            "AETHER_SCAN": settings["scanMode"] as? String ?? "balanced",
            "AETHER_NOIZE": settings["obfuscation"] as? String ?? "balanced",
            "AETHER_IP": settings["ipVersion"] as? String ?? "v4",
            "AETHER_LOG_LEVEL": settings["logLevel"] as? String ?? "info",
        ]

        let protocolName = settings["protocol"] as? String ?? "masque"
        let transport = settings["transport"] as? String ?? "h3"
        if protocolName == "masque", transport == "h2" {
            environment["AETHER_MASQUE_HTTP2"] = "1"
            if (settings["fragment"] as? NSNumber)?.boolValue ?? false {
                environment["AETHER_MASQUE_H2_FRAGMENT"] = "1"
            }
        }

        if let endpoint = settings["endpoint"] as? String, !endpoint.isEmpty {
            environment["AETHER_PEER"] = endpoint
        }
        if let perf = settings["perfProfile"] as? String, !perf.isEmpty {
            environment["AETHER_PERF_PROFILE"] = perf
        }

        return environment
    }

    private func waitForProxy(port: Int) async throws {
        let deadline = Date().addingTimeInterval(90)

        while Date() < deadline {
            if Task.isCancelled { throw TunnelError.cancelled }
            if SocksProbe.reachable(port: port) { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        throw TunnelError.validationTimeout
    }

    private func applyTunnelSettings(socksPort: Int) async throws {
        let settings = NEPacketTunnelNetworkSettings(
            tunnelRemoteAddress: Self.tunIpv4
        )
        settings.mtu = NSNumber(value: Self.tunMtu)

        let ipv4 = NEIPv4Settings(addresses: [Self.tunIpv4], subnetMasks: ["255.255.255.252"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4

        let ipv6 = NEIPv6Settings(addresses: [Self.tunIpv6], networkPrefixLengths: [126])
        ipv6.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6

        let dns = NEDNSSettings(servers: ["1.1.1.1", "1.0.0.1"])
        dns.matchDomains = [""]
        settings.dnsSettings = dns

        try await setTunnelNetworkSettings(settings)
    }

    private func startHev(socksPort: Int, logLevel: String) {
        let config = """
        tunnel:
          mtu: \(Self.tunMtu)
        socks5:
          port: \(socksPort)
          address: 127.0.0.1
          udp: 'udp'
        misc:
          task-stack-size: 24576
          tcp-buffer-size: 4096
          max-session-count: 1200
          log-level: '\(hevLogLevel(logLevel))'
        """

        let thread = Thread { [weak self] in
            guard let self else { return }
            let fd = self.tunnelFileDescriptor
            guard fd >= 0 else {
                TunnelLogStore.shared.append("aether", "[-] unable to resolve the tun descriptor")
                return
            }

            config.withCString { pointer in
                let length = UInt32(strlen(pointer))
                pointer.withMemoryRebound(
                    to: UInt8.self,
                    capacity: Int(length)
                ) { bytes in
                    _ = hev_socks5_tunnel_main_from_str(bytes, length, fd)
                }
            }
        }
        thread.name = "org.bepass.oblivion.hev"
        thread.stackSize = 1024 * 1024
        hevThread = thread
        thread.start()
    }

    private func hevLogLevel(_ level: String) -> String {
        switch level {
        case "trace", "debug": return "debug"
        case "info": return "info"
        case "warn": return "warn"
        default: return "error"
        }
    }

    private var tunnelFileDescriptor: Int32 {
        var buffer = [CChar](repeating: 0, count: Int(IFNAMSIZ))

        for fd in 0...1024 {
            var length = socklen_t(buffer.count)
            let result = withUnsafeMutablePointer(to: &buffer[0]) { pointer in
                getsockopt(Int32(fd), 2, 2, pointer, &length)
            }
            if result == 0, String(cString: buffer).hasPrefix("utun") {
                return Int32(fd)
            }
        }
        return -1
    }
}

enum TunnelError: Error {
    case cancelled
    case validationTimeout
    case coreLaunchFailed(String)
}
