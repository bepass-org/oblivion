import Foundation

enum AetherReply {
    @discardableResult
    static func decode(_ pointer: UnsafeMutablePointer<CChar>?) -> [String: Any] {
        guard let pointer else {
            return ["ok": false, "error": "the core returned nothing"]
        }
        let text = String(cString: pointer)
        aether_string_free(pointer)

        guard
            let data = text.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data),
            let fields = object as? [String: Any]
        else {
            return ["ok": false, "error": "the core reply was not json: \(text)"]
        }
        return fields
    }

    static func failure(_ fields: [String: Any]) -> String? {
        if (fields["ok"] as? Bool) == true { return nil }
        return fields["error"] as? String ?? "the core reported an unknown failure"
    }
}

final class AetherCoreBridge {
    private let workingDirectory: URL
    private var job: UInt64?

    init(workingDirectory: URL) {
        self.workingDirectory = workingDirectory
    }

    static func version() -> String {
        let fields = AetherReply.decode(aether_version())
        return fields["version"] as? String ?? "unavailable"
    }

    var isRunning: Bool {
        job != nil
    }

    func start(arguments: [String], environment: [String: String]) throws {
        guard job == nil else { return }

        for (key, value) in environment {
            setenv(key, value, 1)
        }
        setenv("HOME", workingDirectory.path, 1)
        setenv(
            "AETHER_CONFIG",
            workingDirectory.appendingPathComponent("aether.toml").path,
            1
        )
        setenv(
            "AETHER_MASQUE_CONFIG",
            workingDirectory.appendingPathComponent("aether-masque.toml").path,
            1
        )
        setenv(
            "AETHER_WG_CONFIG",
            workingDirectory.appendingPathComponent("aether-wg.toml").path,
            1
        )

        FileManager.default.changeCurrentDirectoryPath(workingDirectory.path)

        let payload = try JSONSerialization.data(withJSONObject: arguments)
        let fields = String(data: payload, encoding: .utf8)!.withCString { pointer in
            AetherReply.decode(aether_core_start(pointer))
        }

        if let error = AetherReply.failure(fields) {
            throw TunnelError.coreLaunchFailed(error)
        }
        guard let started = (fields["job"] as? NSNumber)?.uint64Value else {
            throw TunnelError.coreLaunchFailed("the core did not return a job handle")
        }

        job = started
        TunnelLogStore.shared.append(
            "aether",
            "[+] aether core started: \(arguments.joined(separator: " "))"
        )
    }

    func exitReason() -> String? {
        guard let job else { return nil }

        let fields = AetherReply.decode(aether_job_poll(job))
        guard (fields["state"] as? String) == "done" else { return nil }

        let result = fields["result"] as? [String: Any] ?? [:]
        if let error = AetherReply.failure(result) {
            return error
        }
        return result["state"] as? String ?? "closed"
    }

    func stop() {
        guard let job else { return }
        self.job = nil

        AetherReply.decode(aether_job_cancel(job))
        AetherReply.decode(aether_job_free(job))
        TunnelLogStore.shared.append("aether", "[-] aether core stopped")
    }
}
