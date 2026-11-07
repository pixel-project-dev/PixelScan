import XCTest
@testable import PixelScan

final class LiveScannerTests: XCTestCase {
    private var config: [String: String] {
        var values: [String: String] = [:]
        for (key, value) in ProcessInfo.processInfo.environment where key.hasPrefix("PIXELSCAN_") || key.hasPrefix("SAMSUNG_SCAN_") {
            if !value.isEmpty && !value.hasPrefix("$(") {
                values[key] = value
            }
        }
        for path in ["/tmp/pixelscan-live.env", "/tmp/samsung-scan-live.env"] {
            guard let text = try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8) else { continue }
            for line in text.split(separator: "\n") {
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2, !parts[1].isEmpty, values[parts[0]] == nil {
                    values[parts[0]] = parts[1]
                }
            }
        }
        return values
    }

    private func setting(_ name: String) -> String {
        config["PIXELSCAN_\(name)"] ?? config["SAMSUNG_SCAN_\(name)"] ?? ""
    }

    private var host: String { setting("HOST") }
    private var port: Int { Int(setting("PORT")) ?? 9400 }

    func testLiveProbeAndOptionalScan() async throws {
        guard setting("LIVE") == "1" else {
            throw XCTSkip("Set PIXELSCAN_LIVE=1 and PIXELSCAN_HOST to run the hardware test.")
        }
        guard DeviceName.isValidHost(host) else {
            XCTFail("PIXELSCAN_HOST is missing or invalid")
            return
        }
        let installation = SANEInstallation.locate(overridePath: nil)
        let executable = try XCTUnwrap(installation.scanimageURL)
        let version = await SANEInstallation.version(of: executable)
        Self.note("version=\(version ?? "nil")")
        XCTAssertNotNil(version)

        let tcp = await TCPProbe.check(host: host, port: port, timeout: 4)
        Self.note("tcp=\(tcp)")
        let deviceName = try DeviceName.make(host: host, port: port)
        let driver = ScanimageDriver(installation: installation)
        let probed = await driver.probe(deviceName: deviceName)
        Self.note("probe=\(probed)")
        let capabilities = try probed.get()
        XCTAssertTrue(capabilities.sources.contains("Flatbed"))
        XCTAssertTrue(capabilities.sources.contains("ADF"))
        XCTAssertTrue(capabilities.resolutions.contains(300))
        XCTAssertFalse(capabilities.supportsDuplex)

        guard setting("SCAN") == "1" else { return }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("PixelScan-live-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let resolution = capabilities.resolutions.contains(75) ? 75 : (capabilities.resolutions.min() ?? 75)
        let request = ScanRequest(
            deviceName: deviceName,
            source: "Flatbed",
            resolution: resolution,
            mode: capabilities.modes.contains("Gray") ? "Gray" : capabilities.modes[0],
            area: ScanAreaMM(left: 0, top: 0, width: 40, height: 40),
            outputDirectory: directory,
            batch: false,
            capabilities: capabilities
        )
        let outcome = await driver.scan(request: request) { _ in }
        Self.note("scan files=\(outcome.files.count) warning=\(String(describing: outcome.warning))")
        XCTAssertNil(outcome.warning)
        XCTAssertEqual(outcome.files.count, 1)
        XCTAssertTrue(ScanimageDriver.isImage(outcome.files[0]))
    }

    private static func note(_ message: String) {
        let url = URL(fileURLWithPath: "/tmp/samsung-scan-live-status.txt")
        let line = message + "\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path), let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: url)
            }
        }
    }
}
