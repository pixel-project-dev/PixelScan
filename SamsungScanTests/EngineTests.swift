import XCTest
@testable import SamsungScan

final class EngineTests: XCTestCase {
    func testRejectsShellMetacharactersInHost() {
        let hostile = [
            "192.168.1.1; rm -rf /",
            "192.168.1.1 && whoami",
            "$(whoami)",
            "`id`",
            "192.168.1.1\nrm",
            "192.168.1.1|id",
            "-rf",
            "192.168.1.1/../etc",
            "192.168.001.1",
            "",
            "scanner name"
        ]
        for host in hostile {
            XCTAssertThrowsError(try DeviceName.make(host: host, port: 9400), host)
        }
        XCTAssertThrowsError(try DeviceName.make(host: "192.168.1.20", port: 0))
        XCTAssertThrowsError(try DeviceName.make(host: "192.168.1.20", port: 70_000))
    }

    func testBuildsDeviceNameWithoutShell() throws {
        XCTAssertEqual(try DeviceName.make(host: "192.0.2.10", port: 9400), "xerox_mfp:tcp 192.0.2.10 9400")
        XCTAssertEqual(try DeviceName.make(host: "office-scanner.local", port: 9400), "xerox_mfp:tcp office-scanner.local 9400")
    }

    func testParsesKnownXeroxOptions() {
        let capabilities = CapabilityParser.parse(Fixtures.xeroxMFP)
        XCTAssertEqual(capabilities.resolutions, [75, 100, 150, 200, 300, 600])
        XCTAssertEqual(capabilities.modes, ["Lineart", "Halftone", "Gray", "Color"])
        XCTAssertEqual(capabilities.sources, ["Flatbed", "ADF", "Auto"])
        XCTAssertTrue(capabilities.supportsJPEGCompression)
        XCTAssertFalse(capabilities.supportsDuplex)
        XCTAssertNil(capabilities.duplexSource)
        XCTAssertEqual(capabilities.maxWidthMM, 215.9, accuracy: 0.001)
        XCTAssertEqual(capabilities.maxHeightMM, 297.18, accuracy: 0.001)
    }

    func testParsesDuplexOnlyWhenReported() {
        let capabilities = CapabilityParser.parse(Fixtures.duplex)
        XCTAssertEqual(capabilities.duplexSource, "ADF Duplex")
        XCTAssertTrue(capabilities.supportsDuplex)
    }

    func testScanArgumentsAreAnArray() throws {
        let capabilities = CapabilityParser.parse(Fixtures.xeroxMFP)
        let directory = URL(fileURLWithPath: "/tmp/Samsung Scan/inbox", isDirectory: true)
        let request = ScanRequest(
            deviceName: try DeviceName.make(host: "10.0.0.8", port: 9400),
            source: "ADF",
            resolution: 300,
            mode: "Gray",
            area: PaperFormat.a4.area(maxWidth: capabilities.maxWidthMM, maxHeight: capabilities.maxHeightMM),
            outputDirectory: directory,
            batch: true,
            capabilities: capabilities
        )
        let arguments = try ScanCommandBuilder.scanArguments(for: request)
        XCTAssertFalse(arguments.contains("/bin/sh"))
        XCTAssertFalse(arguments.contains("-c"))
        XCTAssertEqual(arguments[0], "-d")
        XCTAssertEqual(arguments[1], "xerox_mfp:tcp 10.0.0.8 9400")
        XCTAssertTrue(arguments.contains("--source=ADF"))
        XCTAssertTrue(arguments.contains("--resolution=300"))
        XCTAssertTrue(arguments.contains("--mode=Gray"))
        XCTAssertTrue(arguments.contains("--batch=\(directory.path)/page-%03d.png"))
        XCTAssertFalse(arguments.contains { $0.contains(";") || $0.contains("&&") || $0.contains("`") })
    }

    func testRejectsUnsupportedScanOption() {
        let capabilities = CapabilityParser.parse(Fixtures.xeroxMFP)
        let request = ScanRequest(
            deviceName: "xerox_mfp:tcp 10.0.0.8 9400",
            source: "ADF Duplex",
            resolution: 300,
            mode: "Color",
            area: ScanAreaMM(left: 0, top: 0, width: 210, height: 297),
            outputDirectory: URL(fileURLWithPath: "/tmp"),
            batch: true,
            capabilities: capabilities
        )
        XCTAssertThrowsError(try ScanCommandBuilder.scanArguments(for: request))
    }

    func testPaperClampsToDevice() {
        let area = PaperFormat.legal.area(maxWidth: 215.9, maxHeight: 297.18)
        XCTAssertEqual(area.width, 215.9, accuracy: 0.001)
        XCTAssertEqual(area.height, 297.18, accuracy: 0.001)
        let a4 = PaperFormat.a4.area(maxWidth: 215.9, maxHeight: 297.18)
        XCTAssertEqual(a4.width, 210, accuracy: 0.001)
        XCTAssertEqual(a4.height, 297, accuracy: 0.001)
    }

    func testErrorMappingKeepsSuccessfulADFEndQuiet() {
        let warning = ScanErrorMapper.map(
            exitCode: 7,
            stderr: "sane_start: Document feeder out of documents",
            stdout: "",
            cancelled: false,
            pageCount: 3,
            failedToLaunch: false
        )
        XCTAssertNil(warning)
    }

    func testErrorMapping() {
        XCTAssertEqual(mapped("Document feeder jammed", pages: 2), .paperJam)
        XCTAssertEqual(mapped("Document feeder out of documents", pages: 0), .adfEmpty)
        XCTAssertEqual(mapped("Device busy", pages: 0), .busy)
        XCTAssertEqual(mapped("multi-feed detected", pages: 1), .multiFeed)
        XCTAssertEqual(mapped("Connection timed out", pages: 1), .networkInterrupted)
        XCTAssertEqual(
            ScanErrorMapper.map(exitCode: 15, stderr: "", stdout: "", cancelled: true, pageCount: 1, failedToLaunch: false),
            .cancelled
        )
        XCTAssertEqual(
            ScanErrorMapper.map(exitCode: -1, stderr: "missing", stdout: "", cancelled: false, pageCount: 0, failedToLaunch: true),
            .backendMissing
        )
    }

    func testProgressParserReadsLastValue() {
        XCTAssertEqual(ProgressParser.fraction(in: "Progress:  5.0%\rProgress: 42.5%\r") ?? -1, 0.425, accuracy: 0.0001)
        XCTAssertNil(ProgressParser.fraction(in: "no progress"))
    }

    func testPageReorderRotateAndCrop() {
        var document = PageDocument(pages: [
            EditablePage(fileName: "a.png", source: "Flatbed", resolution: 300),
            EditablePage(fileName: "b.png", source: "ADF", resolution: 300),
            EditablePage(fileName: "c.png", source: "ADF", resolution: 300)
        ])
        let first = document.pages[0].id
        document.pages[0].crop = NormalizedRect(x: 0, y: 0, width: 0.5, height: 0.25)
        document.move(first, to: 2)
        XCTAssertEqual(document.pages.map(\.fileName), ["b.png", "c.png", "a.png"])
        document.rotate(id: first, clockwise: true)
        let rotated = document.pages.first { $0.id == first }
        XCTAssertEqual(rotated?.rotation, 90)
        XCTAssertEqual(rotated?.crop?.x ?? -1, 0.75, accuracy: 0.001)
        XCTAssertEqual(rotated?.crop?.y ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(rotated?.crop?.width ?? -1, 0.25, accuracy: 0.001)
        XCTAssertEqual(rotated?.crop?.height ?? -1, 0.5, accuracy: 0.001)
        document.remove(id: first)
        XCTAssertEqual(document.pages.count, 2)
    }

    func testLibraryRoundTripAndProfiles() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = LibraryStore(layout: AppStorageLayout(root: directory))
        var library = ScannerLibrary.makeDefault()
        library.scanners = [ScannerConfiguration(name: "Office", host: "10.1.1.8", port: 9400)]
        library.selectedScannerID = library.scanners[0].id
        try store.saveLibrary(library)
        let loaded = store.loadLibrary()
        XCTAssertEqual(loaded.scanners.first?.host, "10.1.1.8")
        XCTAssertEqual(loaded.profiles.count, 4)
        XCTAssertEqual(loaded.profiles.first { $0.id == BuiltInProfile.ocr }?.ocr, true)
        XCTAssertEqual(loaded.profiles.first { $0.id == BuiltInProfile.photo }?.resolution, 600)
        XCTAssertEqual(loaded.profiles.first { $0.id == BuiltInProfile.multipage }?.source, "ADF")
        XCTAssertEqual(loaded.profiles.first { $0.id == BuiltInProfile.document }?.mode, "Gray")
    }

    func testEchoProcessAndCancel() async {
        let echo = ProcessRunner()
        let echoed = await echo.run(executable: URL(fileURLWithPath: "/bin/echo"), arguments: ["samsung-scan"])
        XCTAssertEqual(echoed.exitCode, 0)
        XCTAssertTrue(echoed.stdout.contains("samsung-scan"))
        XCTAssertFalse(echoed.failedToLaunch)

        let sleeper = ProcessRunner()
        let task = Task { await sleeper.run(executable: URL(fileURLWithPath: "/bin/sleep"), arguments: ["30"]) }
        try? await Task.sleep(nanoseconds: 200_000_000)
        sleeper.cancel()
        let cancelled = await task.value
        XCTAssertTrue(cancelled.cancelled)
        XCTAssertNotEqual(cancelled.exitCode, 0)
    }

    private func mapped(_ stderr: String, pages: Int) -> ScanFailure? {
        ScanErrorMapper.map(exitCode: 1, stderr: stderr, stdout: "", cancelled: false, pageCount: pages, failedToLaunch: false)
    }
}

enum Fixtures {
    static let xeroxMFP = """
    All options specific to device `xerox_mfp:tcp 10.0.0.5 9400':
      Standard:
        --resolution 75|100|150|200|300|600dpi [150]
            Sets the resolution of the scanned image.
        --mode Lineart|Halftone|Gray|Color [Color]
            Selects the scan mode (e.g., lineart, monochrome, or color).
        --highlight 30..70% (in steps of 10) [inactive]
            Select minimum-brightness to get a white point
        --source Flatbed|ADF|Auto [Flatbed]
            Selects the scan source (such as a document-feeder).
        --jpeg[=(yes|no)] [yes] [advanced]
            JPEG Image Compression
      Geometry:
        -l 0..215.9mm (in steps of 1) [0]
            Top-left x position of scan area.
        -t 0..297.18mm (in steps of 1) [0]
            Top-left y position of scan area.
        -x 0..215.9mm (in steps of 1) [215.9]
            Width of scan-area.
        -y 0..297.18mm (in steps of 1) [297.18]
            Height of scan-area.
    """

    static let duplex = """
        --source Flatbed|ADF|ADF Duplex [Flatbed]
        --duplex[=(yes|no)] [no]
        -x 0..210mm [210]
        -y 0..297mm [297]
    """
}
