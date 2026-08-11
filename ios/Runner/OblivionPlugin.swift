import Flutter
import Foundation
import NetworkExtension

final class OblivionPlugin: NSObject {
    private static let methodChannelName = "org.bepass.oblivion/tunnel"
    private static let statusChannelName = "org.bepass.oblivion/tunnel_status"
    private static let logChannelName = "org.bepass.oblivion/tunnel_logs"

    private static let tunnelBundleId = "org.bepass.oblivion.tunnel"

    private let methodChannel: FlutterMethodChannel
    private let statusChannel: FlutterEventChannel
    private let logChannel: FlutterEventChannel

    private let statusStreamer = StreamRelay()
    private let logStreamer = StreamRelay()

    private var manager: NETunnelProviderManager?
    private var connectedAt: Date?
    private var statusObserver: NSObjectProtocol?
    private var logTimer: Timer?
    private var lastLogOffset = 0

    init(messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: Self.methodChannelName,
            binaryMessenger: messenger
        )
        statusChannel = FlutterEventChannel(
            name: Self.statusChannelName,
            binaryMessenger: messenger
        )
        logChannel = FlutterEventChannel(
            name: Self.logChannelName,
            binaryMessenger: messenger
        )
        super.init()
    }

    func attach() {
        methodChannel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result)
        }
        statusChannel.setStreamHandler(statusStreamer)
        logChannel.setStreamHandler(logStreamer)

        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.publishStatus()
        }

        loadManager { [weak self] _ in
            self?.publishStatus()
        }
        startLogPump()
    }

    func detach() {
        methodChannel.setMethodCallHandler(nil)
        statusChannel.setStreamHandler(nil)
        logChannel.setStreamHandler(nil)

        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
        statusObserver = nil
        logTimer?.invalidate()
        logTimer = nil
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "prepare":
            prepare(result: result)
        case "connect":
            connect(arguments: call.arguments, result: result)
        case "disconnect":
            disconnect(result: result)
        case "status":
            result(currentSnapshot())
        case "readLogs":
            result(TunnelLogStore.shared.readAll())
        case "clearLogs":
            TunnelLogStore.shared.clear()
            lastLogOffset = 0
            result(nil)
        case "coreVersion":
            result(AetherCoreBridge.version())
        case "installedApps":
            result([] as [[String: Any]])
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func prepare(result: @escaping FlutterResult) {
        loadManager { manager in
            guard let manager else {
                result(false)
                return
            }

            manager.saveToPreferences { error in
                if let error {
                    TunnelLogStore.shared.append(
                        "[-] failed to save the tunnel profile: \(error.localizedDescription)"
                    )
                    result(false)
                    return
                }
                result(true)
            }
        }
    }

    private func connect(arguments: Any?, result: @escaping FlutterResult) {
        guard
            let payload = arguments as? [String: Any],
            let settings = payload["settings"] as? [String: Any]
        else {
            result(FlutterError(
                code: "bad_args",
                message: "settings payload is required",
                details: nil
            ))
            return
        }

        let coreArguments = payload["arguments"] as? [String] ?? []

        loadManager { [weak self] manager in
            guard let self, let manager else {
                result(FlutterError(
                    code: "no_manager",
                    message: "unable to load the tunnel profile",
                    details: nil
                ))
                return
            }

            self.applyConfiguration(
                to: manager,
                settings: settings,
                coreArguments: coreArguments
            )

            manager.saveToPreferences { error in
                if let error {
                    result(FlutterError(
                        code: "save_failed",
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }

                manager.loadFromPreferences { _ in
                    do {
                        try manager.connection.startVPNTunnel(
                            options: ["settings": NSDictionary(dictionary: settings)]
                        )
                        result(nil)
                    } catch {
                        result(FlutterError(
                            code: "start_failed",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }
        }
    }

    private func disconnect(result: @escaping FlutterResult) {
        loadManager { manager in
            manager?.connection.stopVPNTunnel()
            result(nil)
        }
    }

    private func applyConfiguration(
        to manager: NETunnelProviderManager,
        settings: [String: Any],
        coreArguments: [String]
    ) {
        let proto = (manager.protocolConfiguration as? NETunnelProviderProtocol)
            ?? NETunnelProviderProtocol()

        proto.providerBundleIdentifier = Self.tunnelBundleId
        proto.serverAddress = (settings["endpoint"] as? String)
            .flatMap { $0.isEmpty ? nil : $0 } ?? "Cloudflare"

        var providerConfiguration = settings
        providerConfiguration["coreArguments"] = coreArguments
        proto.providerConfiguration = providerConfiguration

        manager.protocolConfiguration = proto
        manager.localizedDescription = "Oblivion"
        manager.isEnabled = true
    }

    private func loadManager(completion: @escaping (NETunnelProviderManager?) -> Void) {
        if let manager {
            completion(manager)
            return
        }

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error {
                TunnelLogStore.shared.append(
                    "[-] failed to read tunnel profiles: \(error.localizedDescription)"
                )
                completion(nil)
                return
            }

            let resolved = managers?.first ?? NETunnelProviderManager()
            self?.manager = resolved
            completion(resolved)
        }
    }

    private func stageName(for status: NEVPNStatus) -> String {
        switch status {
        case .invalid, .disconnected:
            return "disconnected"
        case .connecting, .reasserting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnecting:
            return "disconnecting"
        @unknown default:
            return "disconnected"
        }
    }

    private func currentSnapshot() -> [String: Any?] {
        let status = manager?.connection.status ?? .disconnected

        if status == .connected, connectedAt == nil {
            connectedAt = manager?.connection.connectedDate ?? Date()
        }
        if status != .connected {
            connectedAt = nil
        }

        return [
            "stage": stageName(for: status),
            "stats": [
                "txPackets": 0,
                "txBytes": 0,
                "rxPackets": 0,
                "rxBytes": 0,
            ],
            "gateway": (manager?.protocolConfiguration as? NETunnelProviderProtocol)?
                .serverAddress,
            "connectedAt": Int((connectedAt?.timeIntervalSince1970 ?? 0) * 1000),
            "message": nil,
        ]
    }

    private func publishStatus() {
        statusStreamer.send(currentSnapshot())
    }

    private func startLogPump() {
        logTimer?.invalidate()
        logTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let full = TunnelLogStore.shared.readAll()
            guard full.count > self.lastLogOffset else { return }

            let start = full.index(full.startIndex, offsetBy: self.lastLogOffset)
            let chunk = String(full[start...])
            self.lastLogOffset = full.count
            if !chunk.isEmpty {
                self.logStreamer.send(chunk)
            }
        }
    }
}

final class StreamRelay: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    func send(_ value: Any) {
        guard let sink else { return }
        DispatchQueue.main.async { sink(value) }
    }
}
