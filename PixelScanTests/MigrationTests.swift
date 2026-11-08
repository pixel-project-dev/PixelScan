import XCTest
@testable import PixelScan

final class MigrationTests: XCTestCase {
    func testProductIdentityUsesTheNewNames() {
        XCTAssertEqual(ProductIdentity.name, "PixelScan")
        XCTAssertEqual(ProductIdentity.bundleIdentifier, "email.hennige.pixelscan")
        XCTAssertEqual(ProductIdentity.supportFolderName, "PixelScan")
        XCTAssertEqual(ProductIdentity.legacySupportFolderName, "Samsung Scan")
        XCTAssertNotEqual(ProductIdentity.supportFolderName, ProductIdentity.legacySupportFolderName)
        XCTAssertEqual(ProductIdentity.marketingVersion, "1.3.2")
        XCTAssertEqual(ProductIdentity.buildNumber, "6")
    }

    func testReleaseBundleMatchesTheShippedIdentity() throws {
        let bundle = try XCTUnwrap(Bundle(identifier: ProductIdentity.bundleIdentifier))
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "PixelScan")
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, "1.3.2")
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String, "6")
        XCTAssertEqual(bundle.bundleURL.lastPathComponent, "PixelScan.app")
    }

    func testMigrationCopiesLibraryProfilesAndSaneConfigWithoutDeletingTheSource() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let library = ScannerLibrary(
            scanners: [ScannerConfiguration(name: "Office", host: "192.0.2.20", port: 9400, backendID: "xerox_mfp")],
            profiles: ScanProfile.defaults,
            selectedScannerID: nil,
            selectedProfileID: BuiltInProfile.multipage,
            settings: .document,
            scanimageOverridePath: "/opt/homebrew/bin/scanimage",
            setupCompleted: true
        )
        var stored = library
        stored.selectedScannerID = stored.scanners[0].id
        let sourceStore = LibraryStore(layout: AppStorageLayout(root: fixture.source))
        try sourceStore.saveLibrary(stored)
        try FileManager.default.createDirectory(at: fixture.source.appendingPathComponent("sane.d"), withIntermediateDirectories: true)
        try "tcp 192.0.2.20 9400\n".write(to: fixture.source.appendingPathComponent("sane.d/xerox_mfp.conf"), atomically: true, encoding: .utf8)
        try Data("page".utf8).write(to: fixture.source.appendingPathComponent("pages/page-001.png"))
        let sourceLibrary = try Data(contentsOf: fixture.source.appendingPathComponent("library.json"))

        let report = LegacyLibraryMigration.migrate(from: fixture.source, to: fixture.destination)
        XCTAssertNil(report.failure)
        XCTAssertTrue(report.sourcePreserved)
        XCTAssertTrue(report.copied.contains("library.json"))
        XCTAssertTrue(report.copied.contains("sane.d"))
        XCTAssertTrue(report.copied.contains("pages"))
        XCTAssertEqual(try Data(contentsOf: fixture.source.appendingPathComponent("library.json")), sourceLibrary)

        let restored = LibraryStore(layout: AppStorageLayout(root: fixture.destination)).loadLibrary()
        XCTAssertEqual(restored.scanners.count, 1)
        XCTAssertEqual(restored.scanners[0].host, "192.0.2.20")
        XCTAssertEqual(restored.scanners[0].port, 9400)
        XCTAssertEqual(restored.scanners[0].backendID, "xerox_mfp")
        XCTAssertEqual(restored.profiles.count, ScanProfile.defaults.count)
        XCTAssertEqual(restored.selectedProfileID, BuiltInProfile.multipage)
        XCTAssertEqual(restored.scanimageOverridePath, "/opt/homebrew/bin/scanimage")
        let sane = try String(contentsOf: fixture.destination.appendingPathComponent("sane.d/xerox_mfp.conf"), encoding: .utf8)
        XCTAssertTrue(sane.contains("tcp 192.0.2.20 9400"))
    }

    func testMigrationIsRepeatableAndDoesNotDuplicateOrOverwrite() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try Data("{\"scanners\":[]}".utf8).write(to: fixture.source.appendingPathComponent("library.json"))
        let first = LegacyLibraryMigration.migrate(from: fixture.source, to: fixture.destination)
        XCTAssertEqual(first.copied, ["library.json"])
        try Data("{\"scanners\":[{\"id\":\"changed\"}]}".utf8).write(to: fixture.source.appendingPathComponent("library.json"))
        let second = LegacyLibraryMigration.migrate(from: fixture.source, to: fixture.destination)
        XCTAssertEqual(second.copied, [])
        XCTAssertTrue(second.skipped.contains("library.json"))
        XCTAssertTrue(second.sourcePreserved)
        let destination = try String(contentsOf: fixture.destination.appendingPathComponent("library.json"), encoding: .utf8)
        XCTAssertEqual(destination, "{\"scanners\":[]}")
        let source = try String(contentsOf: fixture.source.appendingPathComponent("library.json"), encoding: .utf8)
        XCTAssertTrue(source.contains("changed"))
    }

    func testMigrationFillsAnEmptyDestinationDirectoryAndKeepsExistingFiles() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try FileManager.default.createDirectory(at: fixture.source.appendingPathComponent("sane.d"), withIntermediateDirectories: true)
        try "tcp 192.0.2.21 9400\n".write(to: fixture.source.appendingPathComponent("sane.d/xerox_mfp.conf"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: fixture.destination.appendingPathComponent("sane.d"), withIntermediateDirectories: true)
        try Data("keep".utf8).write(to: fixture.destination.appendingPathComponent("library.json"))

        let report = LegacyLibraryMigration.migrate(from: fixture.source, to: fixture.destination)
        XCTAssertNil(report.failure)
        XCTAssertTrue(report.copied.contains("sane.d"))
        XCTAssertTrue(report.missing.contains("library.json"))
        XCTAssertFalse(report.copied.contains("library.json"))
        XCTAssertEqual(try String(contentsOf: fixture.destination.appendingPathComponent("library.json"), encoding: .utf8), "keep")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.destination.appendingPathComponent("sane.d/xerox_mfp.conf").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.source.appendingPathComponent("sane.d/xerox_mfp.conf").path))
    }

    func testUnreadableSourceIsReportedAndPreserved() throws {
        let fixture = try makeFixture()
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: fixture.source.appendingPathComponent("library.json").path)
            try? FileManager.default.removeItem(at: fixture.root)
        }
        let library = fixture.source.appendingPathComponent("library.json")
        try Data("secret".utf8).write(to: library)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: library.path)
        let report = LegacyLibraryMigration.migrate(from: fixture.source, to: fixture.destination)
        XCTAssertNotNil(report.failure)
        XCTAssertTrue(report.sourcePreserved)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.destination.appendingPathComponent("library.json").path))
    }

    func testMissingLegacyFolderDoesNothing() {
        let destination = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("pixelscan-missing-\(UUID().uuidString)", isDirectory: true)
        let source = destination.appendingPathComponent("does-not-exist")
        let report = LegacyLibraryMigration.migrate(from: source, to: destination)
        XCTAssertEqual(report.copied, [])
        XCTAssertNil(report.failure)
        XCTAssertTrue(report.sourcePreserved)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    private func makeFixture() throws -> (root: URL, source: URL, destination: URL) {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("pixelscan-migration-\(UUID().uuidString)", isDirectory: true)
        let source = root.appendingPathComponent("Samsung Scan", isDirectory: true)
        let destination = root.appendingPathComponent("PixelScan", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        return (root, source, destination)
    }
}
