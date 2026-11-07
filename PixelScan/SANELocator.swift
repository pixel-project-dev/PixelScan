import Foundation

struct SANEInstallation: Equatable, Sendable {
    var scanimageURL: URL?
    var version: String?
    var dllConfigURL: URL?
    var xeroxBackendEnabled: Bool?
    var homebrewURL: URL?
    var executableArchitectures: [String] = []
    var enabledBackends: [String] = []
    var installedLibraries: [String] = []
    var prefixPath: String?

    var isUsable: Bool { scanimageURL != nil }

    var architectureWarning: String? {
        MachOArchitecture.warning(
            executableArchitectures: executableArchitectures,
            processArchitecture: MachOArchitecture.process
        )
    }

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
        let dllText = dll.flatMap { try? String(contentsOf: $0, encoding: .utf8) }
        let enabledNames = dllText.map(SANEConfigText.enabledBackends(in:)) ?? []
        let enabled = dllText.map { SANEConfigText.enabledBackends(in: $0).contains("xerox_mfp") }
        let prefix = scanimage?.deletingLastPathComponent().deletingLastPathComponent()
        let libraries = prefix.map { libraryNames(in: $0.appendingPathComponent("lib/sane")) } ?? []
        let brew = [
            URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
            URL(fileURLWithPath: "/usr/local/bin/brew")
        ].first { FileManager.default.isExecutableFile(atPath: $0.path) }
        return SANEInstallation(
            scanimageURL: scanimage,
            version: nil,
            dllConfigURL: dll,
            xeroxBackendEnabled: enabled,
            homebrewURL: brew,
            executableArchitectures: scanimage.map(MachOArchitecture.names(at:)) ?? [],
            enabledBackends: enabledNames,
            installedLibraries: libraries,
            prefixPath: prefix?.path
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
        try enableBackend("xerox_mfp", at: url)
    }

    static func enableBackend(_ backend: String, at url: URL) throws {
        guard SANEConfigText.writableBackends.contains(backend) else { return }
        let text = try String(contentsOf: url, encoding: .utf8)
        let rewritten = SANEConfigText.enabling(backend, in: text)
        guard rewritten != text else { return }
        try rewritten.write(to: url, atomically: true, encoding: .utf8)
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

    private static func libraryNames(in directory: URL) -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return SANEConfigText.libraryNames(in: names).sorted()
    }
}
