import Foundation

@main
enum LiveCheck {
    static func main() async {
        do {
            try await run()
        } catch {
            fputs("\(error)\n", stderr)
            exit(1)
        }
    }

    static func run() async throws {
        var config: [String: String] = [:]
        for path in ["/tmp/pixelscan-live.env", "/tmp/samsung-scan-live.env"] {
            let text = (try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)) ?? ""
            for line in text.split(separator: "\n") {
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2, config[parts[0]] == nil { config[parts[0]] = parts[1] }
            }
        }
        func setting(_ name: String) -> String {
            config["PIXELSCAN_\(name)"] ?? config["SAMSUNG_SCAN_\(name)"] ?? ""
        }
        let host = setting("HOST")
        guard setting("LIVE") == "1", DeviceName.isValidHost(host) else {
            fputs("live config missing\n", stderr)
            exit(2)
        }
        let port = Int(setting("PORT")) ?? 9400
        let installation = SANEInstallation.locate(overridePath: nil)
        guard let executable = installation.scanimageURL else {
            fputs("scanimage missing\n", stderr)
            exit(3)
        }
        let version = await SANEInstallation.version(of: executable)
        print("version \(version ?? "nil")")
        let deviceName = try DeviceName.make(host: host, port: port)
        let driver = ScanimageDriver(installation: installation)
        let probed = await driver.probe(deviceName: deviceName)
        let capabilities = try probed.get()
        print("sources \(capabilities.sources.joined(separator: ",")) duplex \(capabilities.supportsDuplex)")
        guard capabilities.sources.contains("Flatbed"),
              capabilities.sources.contains("ADF"),
              capabilities.resolutions.contains(300),
              capabilities.supportsDuplex == false else {
            fputs("unexpected capabilities\n", stderr)
            exit(4)
        }
        guard setting("SCAN") == "1" else { return }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("PixelScan-live-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let resolution = capabilities.resolutions.contains(75) ? 75 : capabilities.resolutions[0]
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
        let outcome = await driver.scan(request: request) { fraction in
            print(String(format: "progress %.0f", fraction * 100))
        }
        if let warning = outcome.warning {
            fputs("warning \(warning)\n", stderr)
            exit(5)
        }
        guard outcome.files.count == 1, ScanimageDriver.isImage(outcome.files[0]) else {
            fputs("no image\n", stderr)
            exit(6)
        }
        print("image \(outcome.files[0].path)")
    }
}
