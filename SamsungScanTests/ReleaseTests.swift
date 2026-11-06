import XCTest
@testable import SamsungScan

final class ReleaseTests: XCTestCase {
    func testUserConfigurationListsOnlySamsungScannersOnce() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("samsung-scan-config-\(UUID().uuidString)", isDirectory: true)
        let system = root.appendingPathComponent("system", isDirectory: true)
        let user = root.appendingPathComponent("user", isDirectory: true)
        try FileManager.default.createDirectory(at: system, withIntermediateDirectories: true)
        let original = "#xerox_mfp\nnet\n"
        try original.write(to: system.appendingPathComponent("dll.conf"), atomically: true, encoding: .utf8)
        try "tcp 203.0.113.9 9400\n".write(to: system.appendingPathComponent("xerox_mfp.conf"), atomically: true, encoding: .utf8)
        let scanners = [
            ScannerConfiguration(name: "Office", host: "192.0.2.10", port: 9400, backendID: "xerox_mfp"),
            ScannerConfiguration(name: "Duplicate", host: "192.0.2.10", port: 9400, backendID: "xerox_mfp"),
            ScannerConfiguration(name: "Web", host: "192.0.2.11", port: 80, backendID: "escl"),
            ScannerConfiguration(name: "Bad", host: "192.0.2.10;id", port: 9400, backendID: "xerox_mfp")
        ]
        _ = try SANEUserConfig.prepare(directory: user, systemDirectory: system, scanners: scanners)
        let written = try String(contentsOf: user.appendingPathComponent("xerox_mfp.conf"), encoding: .utf8)
        XCTAssertEqual(written.components(separatedBy: "tcp 192.0.2.10 9400").count - 1, 1)
        XCTAssertFalse(written.contains("192.0.2.11"))
        XCTAssertFalse(written.contains(";"))
        let dll = try String(contentsOf: user.appendingPathComponent("dll.conf"), encoding: .utf8)
        XCTAssertTrue(SANEConfigText.enabledBackends(in: dll).contains("xerox_mfp"))
        let systemAfter = try String(contentsOf: system.appendingPathComponent("dll.conf"), encoding: .utf8)
        XCTAssertEqual(systemAfter, original)
        let systemScanners = try String(contentsOf: system.appendingPathComponent("xerox_mfp.conf"), encoding: .utf8)
        XCTAssertFalse(systemScanners.contains("192.0.2.10"))
        XCTAssertTrue(SANEUserConfig.mentions(host: "203.0.113.9", port: 9400, in: systemScanners))
        try? FileManager.default.removeItem(at: root)
    }

    func testVersion11LibraryStillLoads() throws {
        let json = """
        {"scanners":[{"id":"10000000-0000-0000-0000-000000000010","name":"Office","host":"192.0.2.10","port":9400,"createdAt":"2026-01-01T00:00:00Z","backendID":"xerox_mfp","secureConnection":false}],"profiles":[],"settings":{"source":"Flatbed","resolution":300,"mode":"Gray","paper":"a4","exportFormat":"pdf","ocr":false,"removeBlankPages":false,"append":true,"pdfCompression":"balanced","jpegQuality":0.85},"setupCompleted":true}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let library = try decoder.decode(ScannerLibrary.self, from: json)
        XCTAssertEqual(library.scanners.first?.backendID, "xerox_mfp")
        XCTAssertTrue(library.setupCompleted)
        XCTAssertEqual(library.settings.resolution, 300)
    }

    func testMissingScanimageIsReportedByTheProbe() async {
        let report = await SandboxProbe.perform(installation: SANEInstallation())
        XCTAssertFalse(report.scanimageFound)
        XCTAssertFalse(report.scanimageStarted)
        XCTAssertTrue(report.wroteTemporaryFile)
    }

    func testEnablingABackendDoesNotRewriteOtherLines() {
        let text = SANEConfigText.enabling("xerox_mfp", in: "#xerox_mfp\nnet\n# escl\n")
        XCTAssertTrue(SANEConfigText.enabledBackends(in: text).contains("xerox_mfp"))
        XCTAssertTrue(text.contains("net"))
        XCTAssertTrue(text.contains("# escl"))
    }
}
