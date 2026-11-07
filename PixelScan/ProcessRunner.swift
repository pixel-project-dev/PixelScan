import Darwin
import Foundation

struct ProcessResult: Equatable, Sendable {
    var exitCode: Int32
    var stdout: String
    var stderr: String
    var cancelled: Bool
    var failedToLaunch: Bool = false
}

final class LockedData: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    func string() -> String {
        lock.lock()
        let copy = data
        lock.unlock()
        return String(data: copy, encoding: .utf8) ?? String(decoding: copy, as: UTF8.self)
    }
}

final class ProcessRunner: @unchecked Sendable {
    private let process = Process()
    private let stateLock = NSLock()
    private var cancelled = false
    private var started = false

    var isCancelled: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return cancelled
    }

    func cancel() {
        stateLock.lock()
        cancelled = true
        let running = started && process.isRunning
        let pid = process.processIdentifier
        stateLock.unlock()
        guard running, pid > 0 else { return }
        process.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            if self.process.isRunning {
                kill(pid, SIGKILL)
            }
        }
    }

    func run(
        executable: URL,
        arguments: [String],
        configDirectory: URL? = nil,
        onStderr: @escaping @Sendable (String) -> Void = { _ in }
    ) async -> ProcessResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.runBlocking(
                    executable: executable,
                    arguments: arguments,
                    configDirectory: configDirectory,
                    onStderr: onStderr
                )
                continuation.resume(returning: result)
            }
        }
    }

    private func runBlocking(
        executable: URL,
        arguments: [String],
        configDirectory: URL?,
        onStderr: @escaping @Sendable (String) -> Void
    ) -> ProcessResult {
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = childEnvironment(configDirectory: configDirectory)
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice

        let stdout = LockedData()
        let stderr = LockedData()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            self.readLoop(handle: outPipe.fileHandleForReading, into: stdout, onText: nil)
            group.leave()
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            self.readLoop(handle: errPipe.fileHandleForReading, into: stderr) { text in
                onStderr(text)
            }
            group.leave()
        }

        do {
            try process.run()
            try outPipe.fileHandleForWriting.close()
            try errPipe.fileHandleForWriting.close()
            stateLock.lock()
            started = true
            let shouldStop = cancelled
            stateLock.unlock()
            if shouldStop {
                process.terminate()
            }
            process.waitUntilExit()
            group.wait()
            return ProcessResult(
                exitCode: process.terminationStatus,
                stdout: stdout.string(),
                stderr: stderr.string(),
                cancelled: isCancelled
            )
        } catch {
            process.terminate()
            outPipe.fileHandleForReading.readabilityHandler = nil
            closePipes(outPipe, errPipe)
            group.wait()
            return ProcessResult(
                exitCode: -1,
                stdout: "",
                stderr: error.localizedDescription,
                cancelled: false,
                failedToLaunch: true
            )
        }
    }

    private func readLoop(handle: FileHandle, into buffer: LockedData, onText: ((String) -> Void)?) {
        while true {
            let chunk = handle.availableData
            if chunk.isEmpty { break }
            buffer.append(chunk)
            if let onText, let text = String(data: chunk, encoding: .utf8), !text.isEmpty {
                onText(text)
            }
        }
    }

    private func childEnvironment(configDirectory: URL?) -> [String: String] {
        let source = ProcessInfo.processInfo.environment
        var environment: [String: String] = [:]
        let keep = ["PATH", "HOME", "USER", "LOGNAME", "TMPDIR", "LANG", "LC_ALL", "LC_CTYPE"]
        for key in keep {
            if let value = source[key], !value.isEmpty {
                environment[key] = value
            }
        }
        if let configDirectory {
            environment["SANE_CONFIG_DIR"] = configDirectory.path
        } else if let config = source["SANE_CONFIG_DIR"],
                  FileManager.default.fileExists(atPath: config) {
            environment["SANE_CONFIG_DIR"] = config
        }
        if environment["PATH"] == nil {
            environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        }
        return environment
    }

    private func closePipes(_ outPipe: Pipe, _ errPipe: Pipe) {
        try? outPipe.fileHandleForWriting.close()
        try? errPipe.fileHandleForWriting.close()
    }
}
