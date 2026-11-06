import Foundation
import ImageIO
import UniformTypeIdentifiers

final class ScanimageDriver: @unchecked Sendable {
    private let installation: SANEInstallation
    private let stateLock = NSLock()
    private var runner: ProcessRunner?

    init(installation: SANEInstallation) {
        self.installation = installation
    }

    func cancel() {
        stateLock.lock()
        let current = runner
        stateLock.unlock()
        current?.cancel()
    }

    func probe(deviceName: String) async -> Result<ScannerCapabilities, ScanFailure> {
        guard let executable = installation.scanimageURL else {
            return .failure(.backendMissing)
        }
        let runner = ProcessRunner()
        store(runner)
        defer { clear(runner) }
        let result = await Self.runProbe(runner: runner, executable: executable, deviceName: deviceName)
        if result.cancelled {
            return .failure(.unreachable)
        }
        if result.failedToLaunch {
            return .failure(.backendMissing)
        }
        if result.exitCode != 0 || result.cancelled {
            let mapped = ScanErrorMapper.map(
                exitCode: result.exitCode,
                stderr: result.stderr,
                stdout: result.stdout,
                cancelled: result.cancelled,
                pageCount: 0,
                failedToLaunch: false
            )
            let detail = (result.stderr + "\n" + result.stdout)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let mapped {
                switch mapped {
                case .deviceError, .incomplete:
                    break
                default:
                    return .failure(mapped)
                }
            }
            if detail.isEmpty {
                return .failure(mapped ?? .deviceError("exit \(result.exitCode)"))
            }
            return .failure(.deviceError(String(detail.prefix(500))))
        }
        let capabilities = CapabilityParser.parse(result.stdout + "\n" + result.stderr)
        guard !capabilities.resolutions.isEmpty, !capabilities.sources.isEmpty, !capabilities.modes.isEmpty else {
            return .failure(.couldNotReadOptions)
        }
        return .success(capabilities)
    }

    func scan(
        request: ScanRequest,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async -> ScanOutcome {
        guard let executable = installation.scanimageURL else {
            return ScanOutcome(files: [], warning: .backendMissing)
        }
        let arguments: [String]
        do {
            arguments = try ScanCommandBuilder.scanArguments(for: request)
        } catch let failure as ScanFailure {
            return ScanOutcome(files: [], warning: failure)
        } catch {
            return ScanOutcome(files: [], warning: .deviceError(error.localizedDescription))
        }
        let runner = ProcessRunner()
        store(runner)
        defer { clear(runner) }
        let result = await runner.run(executable: executable, arguments: arguments) { chunk in
            if let fraction = ProgressParser.fraction(in: chunk) {
                onProgress(fraction)
            }
        }
        let files = Self.validImages(in: request.outputDirectory)
        let warning = ScanErrorMapper.map(
            exitCode: result.exitCode,
            stderr: result.stderr,
            stdout: result.stdout,
            cancelled: result.cancelled,
            pageCount: files.count,
            failedToLaunch: result.failedToLaunch
        )
        return ScanOutcome(files: files, warning: warning)
    }

    private static func runProbe(runner: ProcessRunner, executable: URL, deviceName: String) async -> ProcessResult {
        await withTaskGroup(of: ProcessResult?.self) { group in
            group.addTask {
                await runner.run(
                    executable: executable,
                    arguments: ScanCommandBuilder.probeArguments(deviceName: deviceName)
                )
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                runner.cancel()
                return nil
            }
            var finished: ProcessResult?
            for await value in group {
                if let value {
                    finished = value
                    break
                }
            }
            group.cancelAll()
            return finished ?? ProcessResult(exitCode: -1, stdout: "", stderr: "", cancelled: true)
        }
    }

    static func validImages(in directory: URL) -> [URL] {
        let manager = FileManager.default
        guard let names = try? manager.contentsOfDirectory(atPath: directory.path) else { return [] }
        return names.sorted().compactMap { name in
            let url = directory.appendingPathComponent(name)
            guard isImage(url) else { return nil }
            return url
        }
    }

    static func isImage(_ url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return false }
        return CGImageSourceGetCount(source) > 0 && CGImageSourceCreateImageAtIndex(source, 0, nil) != nil
    }

    private func store(_ runner: ProcessRunner) {
        stateLock.lock()
        self.runner = runner
        stateLock.unlock()
    }

    private func clear(_ runner: ProcessRunner) {
        stateLock.lock()
        if self.runner === runner {
            self.runner = nil
        }
        stateLock.unlock()
    }
}
