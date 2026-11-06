import Foundation

struct SandboxProbeReport: Equatable, Sendable {
    var sandboxed: Bool
    var scanimageFound: Bool
    var scanimageStarted: Bool
    var version: String?
    var launchDetail: String?
    var wroteTemporaryFile: Bool

    var text: String {
        [
            "sandboxed=\(sandboxed)",
            "scanimageFound=\(scanimageFound)",
            "scanimageStarted=\(scanimageStarted)",
            "version=\(version ?? "")",
            "launchDetail=\(launchDetail ?? "")",
            "wroteTemporaryFile=\(wroteTemporaryFile)"
        ].joined(separator: "\n")
    }
}

enum SandboxProbe {
    static func perform(installation: SANEInstallation) async -> SandboxProbeReport {
        let sandboxed = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
        guard let executable = installation.scanimageURL else {
            return SandboxProbeReport(
                sandboxed: sandboxed,
                scanimageFound: false,
                scanimageStarted: false,
                version: nil,
                launchDetail: "missing",
                wroteTemporaryFile: writeProbe()
            )
        }
        let result = await ProcessRunner().run(executable: executable, arguments: ["-V"])
        let version = (result.stdout + "\n" + result.stderr)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.localizedCaseInsensitiveContains("sane-backends") }
        let detail = result.failedToLaunch ? result.stderr : nil
        return SandboxProbeReport(
            sandboxed: sandboxed,
            scanimageFound: true,
            scanimageStarted: !result.failedToLaunch && result.exitCode == 0,
            version: version,
            launchDetail: detail,
            wroteTemporaryFile: writeProbe()
        )
    }

    private static func writeProbe() -> Bool {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("samsung-scan-write-probe.txt")
        do {
            try Data("ok".utf8).write(to: url, options: .atomic)
            try? FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
}
