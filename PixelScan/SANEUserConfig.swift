import Foundation

enum SANEUserConfig {
    static func prepare(directory: URL, systemDirectory: URL?, scanners: [ScannerConfiguration]) throws -> URL {
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        let systemDLL = systemDirectory?.appendingPathComponent("dll.conf")
        let systemText = systemDLL.flatMap { try? String(contentsOf: $0, encoding: .utf8) }
        let dllText = SANEConfigText.enabling("xerox_mfp", in: systemText ?? "")
        try dllText.write(to: directory.appendingPathComponent("dll.conf"), atomically: true, encoding: .utf8)

        if let systemDirectory, manager.fileExists(atPath: systemDirectory.path) {
            let names = (try? manager.contentsOfDirectory(atPath: systemDirectory.path)) ?? []
            for name in names where name != "xerox_mfp.conf" && name != "dll.conf" {
                let link = directory.appendingPathComponent(name)
                if manager.fileExists(atPath: link.path) { continue }
                try? manager.createSymbolicLink(
                    at: link,
                    withDestinationURL: systemDirectory.appendingPathComponent(name)
                )
            }
        }

        let text = configurationText(scanners: scanners)
        let configuration = directory.appendingPathComponent("xerox_mfp.conf")
        if let existing = try? String(contentsOf: configuration, encoding: .utf8), existing != text {
            try? existing.write(
                to: directory.appendingPathComponent("xerox_mfp.conf.previous"),
                atomically: true,
                encoding: .utf8
            )
        }
        try text.write(to: configuration, atomically: true, encoding: .utf8)
        return directory
    }

    static func configurationText(scanners: [ScannerConfiguration]) -> String {
        var lines = ["# PixelScan keeps this scanner list for the current user. System files are not changed."]
        var seen = Set<String>()
        let relevant = scanners
            .filter { $0.backendID == DeviceAddress.samsungNetwork }
            .sorted { lhs, rhs in
                lhs.host == rhs.host ? lhs.port < rhs.port : lhs.host < rhs.host
            }
        for scanner in relevant {
            let host = scanner.host.trimmingCharacters(in: .whitespacesAndNewlines)
            guard DeviceName.isValidHost(host), (1...65535).contains(scanner.port) else { continue }
            let line = "tcp \(host) \(scanner.port)"
            if seen.insert(line).inserted {
                lines.append(line)
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func mentions(host: String, port: Int, in text: String) -> Bool {
        let needle = "tcp \(host) \(port)"
        return text.components(separatedBy: .newlines).contains { line in
            line.trimmingCharacters(in: .whitespaces) == needle
        }
    }
}
