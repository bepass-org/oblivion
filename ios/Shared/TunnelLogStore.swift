import Foundation

final class TunnelLogStore {
    static let shared = TunnelStoreFactory.make()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "org.bepass.oblivion.logs")
    private let limitBytes = 512 * 1024

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func append(_ source: String, _ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        append("[\(source)] \(trimmed)")
    }

    func append(_ line: String) {
        queue.async { [weak self] in
            guard let self else { return }

            let entry = line.hasSuffix("\n") ? line : line + "\n"
            guard let data = entry.data(using: .utf8) else { return }

            if let handle = try? FileHandle(forWritingTo: self.fileURL) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            } else {
                try? data.write(to: self.fileURL)
            }

            self.trimIfNeeded()
        }
    }

    func readAll() -> String {
        queue.sync {
            (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
        }
    }

    func clear() {
        queue.async { [weak self] in
            guard let self else { return }
            try? Data().write(to: self.fileURL)
        }
    }

    private func trimIfNeeded() {
        guard
            let attributes = try? FileManager.default.attributesOfItem(
                atPath: fileURL.path
            ),
            let size = attributes[.size] as? Int,
            size > limitBytes,
            let contents = try? String(contentsOf: fileURL, encoding: .utf8)
        else { return }

        let tail = contents.split(separator: "\n").suffix(1200).joined(separator: "\n")
        try? (tail + "\n").data(using: .utf8)?.write(to: fileURL)
    }
}

enum TunnelStoreFactory {
    static let appGroupId = "group.org.bepass.oblivion"

    static func make() -> TunnelLogStore {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        let url = container.appendingPathComponent("tunnel.log")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        return TunnelLogStore(fileURL: url)
    }

    static func workingDirectory() -> URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        let dir = container.appendingPathComponent("aether", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
        return dir
    }
}
