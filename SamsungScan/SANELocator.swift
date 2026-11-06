import Foundation

struct SANEInstallation: Equatable, Sendable {
    var scanimageURL: URL?
    var version: String?
    var dllConfigURL: URL?
    var xeroxBackendEnabled: Bool?
    var homebrewURL: URL?

    var isUsable: Bool { scanimageURL != nil }

    static func locate(overridePath: String?) -> SANEInstallation {
        let override = overridePath.flatMap { path -> URL? in
            let url = URL(fileURLWithPath: path)
            return FileManager.default.isExecutableFile(atPath: url.path) ? url : nil
        }
        let candidates = [
            override,
            URL(fileURLWithPath: "/opt/homebrew/bin/scanimage"),
            URL(fileURLWithPath: "/usr/local/bin/scanimage")
        ] + pathCandidates()
        let scanimage = candidates.compactMap { $0 }.first { FileManager.default.isExecutableFile(atPath: $0.path) }
        let dll = scanimage.flatMap(dllConfig(nextTo:))
        let enabled = dll.flatMap(xeroxEnabled(in:))
        let brew = [
            URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
            URL(fileURLWithPath: "/usr/local/bin/brew")
        ].first { FileManager.default.isExecutableFile(atPath: $0.path) }
        return SANEInstallation(
            scanimageURL: scanimage,
            version: nil,
            dllConfigURL: dll,
            xeroxBackendEnabled: enabled,
            homebrewURL: brew
        )
    }

    static func version(of executable: URL) async -> String? {
        let runner = ProcessRunner()
        let result = await runner.run(executable: executable, arguments: ["-V"])
        let text = (result.stdout + "\n" + result.stderr)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.localizedCaseInsensitiveContains("sane-backends") }
        return text
    }

    static func enableXeroxBackend(at url: URL) throws {
        var text = try String(contentsOf: url, encoding: .utf8)
        let lines = text.components(separatedBy: .newlines)
        var changed = false
        let rewritten = lines.map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "#xerox_mfp" || trimmed == "# xerox_mfp" {
                changed = true
                return "xerox_mfp"
            }
            return line
        }
        text = rewritten.joined(separator: "\n")
        if !rewritten.contains(where: { $0.trimmingCharacters(in: .whitespaces) == "xerox_mfp" }) {
            if !text.hasSuffix("\n") { text += "\n" }
            text += "xerox_mfp\n"
            changed = true
        }
        guard changed else { return }
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func pathCandidates() -> [URL] {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        return path.split(separator: ":").map { part in
            URL(fileURLWithPath: String(part)).appendingPathComponent("scanimage")
        }
    }

    private static func dllConfig(nextTo executable: URL) -> URL? {
        let prefix = executable.deletingLastPathComponent().deletingLastPathComponent()
        let candidate = prefix.appendingPathComponent("etc/sane.d/dll.conf")
        if FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        let fallbacks = [
            URL(fileURLWithPath: "/opt/homebrew/etc/sane.d/dll.conf"),
            URL(fileURLWithPath: "/usr/local/etc/sane.d/dll.conf")
        ]
        return fallbacks.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func xeroxEnabled(in url: URL) -> Bool {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return text.components(separatedBy: .newlines).contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed == "xerox_mfp" && !trimmed.hasPrefix("#")
        }
    }
}
