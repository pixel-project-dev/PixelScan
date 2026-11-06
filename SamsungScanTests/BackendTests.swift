import XCTest
@testable import SamsungScan

final class BackendTests: XCTestCase {
    func testSamsungNetworkDeviceNameStaysStable() throws {
        XCTAssertEqual(
            try DeviceAddress.make(backendID: "xerox_mfp", host: "192.0.2.10", port: 9400),
            "xerox_mfp:tcp 192.0.2.10 9400"
        )
        XCTAssertEqual(try DeviceName.make(host: "192.0.2.10", port: 9400), "xerox_mfp:tcp 192.0.2.10 9400")
    }

    func testWebAndCanonNamesAreExplicit() throws {
        XCTAssertEqual(
            try DeviceAddress.make(backendID: "escl", host: "scanner.local", port: 80, secure: false),
            "escl:http://scanner.local:80"
        )
        XCTAssertEqual(
            try DeviceAddress.make(backendID: "escl", host: "scanner.local", port: 443, secure: true),
            "escl:https://scanner.local:443"
        )
        XCTAssertEqual(
            try DeviceAddress.make(backendID: "pixma", host: "192.0.2.20", port: 8612),
            "pixma:bjnp://192.0.2.20:8612"
        )
        XCTAssertThrowsError(try DeviceAddress.make(backendID: "net", host: "192.0.2.20", port: 6566))
        XCTAssertThrowsError(try DeviceAddress.make(backendID: "xerox_mfp", host: "192.0.2.20;id", port: 9400))
    }

    func testDiscoveryDoesNotTreatPrintingAsScanning() {
        XCTAssertFalse(DiscoveryPolicy.shouldSuggest(serviceType: "_ipp._tcp", scanPortOpen: false))
        XCTAssertTrue(DiscoveryPolicy.shouldSuggest(serviceType: "_ipp._tcp", scanPortOpen: true))
        XCTAssertTrue(DiscoveryPolicy.shouldSuggest(serviceType: "_uscan._tcp", scanPortOpen: false))
        XCTAssertTrue(DiscoveryPolicy.shouldSuggest(serviceType: "_uscans._tcp", scanPortOpen: false))
        XCTAssertEqual(DiscoveryPolicy.backendHint(serviceType: "_uscan._tcp", scanPortOpen: false), "escl")
        XCTAssertEqual(DiscoveryPolicy.backendHint(serviceType: "_ipp._tcp", scanPortOpen: true), "xerox_mfp")
        XCTAssertEqual(DiscoveryPolicy.suggestedPort(serviceType: "_uscan._tcp", servicePort: 8080, scanPortOpen: false), 8080)
        XCTAssertEqual(DiscoveryPolicy.role(for: "_ipp._tcp"), .printer)
    }

    func testOldScannerConfigurationMigratesToSamsungNetwork() throws {
        let json = """
        {"id":"10000000-0000-0000-0000-000000000010","name":"Office","host":"192.0.2.10","port":9400,"createdAt":"2026-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let scanner = try decoder.decode(ScannerConfiguration.self, from: json)
        XCTAssertEqual(scanner.backendID, "xerox_mfp")
        XCTAssertFalse(scanner.secureConnection)
        XCTAssertEqual(scanner.host, "192.0.2.10")
    }

    func testLibraryWithScannersSkipsRepeatedSetup() throws {
        let json = """
        {"scanners":[{"id":"10000000-0000-0000-0000-000000000010","name":"Office","host":"192.0.2.10","port":9400,"createdAt":"2026-01-01T00:00:00Z"}],"profiles":[],"settings":{"source":"Flatbed","resolution":300,"mode":"Gray","paper":"a4","exportFormat":"pdf","ocr":false,"removeBlankPages":false,"append":true,"pdfCompression":"balanced","jpegQuality":0.85}}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let library = try decoder.decode(ScannerLibrary.self, from: json)
        XCTAssertTrue(library.setupCompleted)
        XCTAssertEqual(library.scanners.first?.backendID, "xerox_mfp")
    }

    func testCompatibilityDatabaseKeepsClaimsSeparate() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "compatibility", withExtension: "json"))
        let document = try CompatibilityDatabase.load(data: Data(contentsOf: url))
        XCTAssertEqual(document.schema, 1)
        let tested = document.devices.filter { $0.status == .tested }
        XCTAssertEqual(tested.map(\.id), ["samsung-sl-c2670fw"])
        XCTAssertEqual(tested.first?.backend, "xerox_mfp")
        XCTAssertEqual(tested.first?.defaultPort, 9400)
        XCTAssertEqual(tested.first?.flatbed, true)
        XCTAssertEqual(tested.first?.adf, true)
        XCTAssertEqual(tested.first?.duplex, false)
        let usb = document.devices.first { $0.model == "SCX-4200 Series" }
        XCTAssertEqual(usb?.status, .backendSupportConfirmed)
        XCTAssertNil(usb?.networkProtocol)
        XCTAssertFalse(document.devices.contains { $0.status == .tested && $0.model != "ProXpress SL-C2670FW" })
        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(raw.contains("192.168."))
        let found = CompatibilityDatabase.search(document, query: "C2670")
        XCTAssertEqual(found.first?.status, .tested)
    }

    func testDLLAndLibraryParsing() {
        let text = """
        #xerox_mfp
        net
        escl
        # comment
        pixma
        """
        XCTAssertEqual(SANEConfigText.enabledBackends(in: text), ["net", "escl", "pixma"])
        XCTAssertEqual(
            SANEConfigText.libraryNames(in: ["libsane-xerox_mfp.so", "libsane-xerox_mfp.1.so", "libsane-escl.so", "libsane.dll"]),
            ["xerox_mfp", "escl"]
        )
        XCTAssertFalse(BackendAvailability.libraryIsPresent("escl", installedLibraries: ["xerox_mfp", "pixma", "net"]))
        XCTAssertTrue(BackendAvailability.libraryIsPresent("xerox_mfp", installedLibraries: ["xerox_mfp"]))
    }

    func testArchitectureMismatchAndMachO() {
        XCTAssertNil(MachOArchitecture.warning(executableArchitectures: ["arm64"], processArchitecture: "arm64"))
        XCTAssertNotNil(MachOArchitecture.warning(executableArchitectures: ["arm64"], processArchitecture: "x86_64"))
        var header = Data([0xCF, 0xFA, 0xED, 0xFE, 0x0C, 0x00, 0x00, 0x01])
        header.append(Data(repeating: 0, count: 24))
        XCTAssertEqual(MachOArchitecture.names(in: header), ["arm64"])
        var fat = Data([0xCA, 0xFE, 0xBA, 0xBE, 0x00, 0x00, 0x00, 0x02])
        fat.append(contentsOf: [0x01, 0x00, 0x00, 0x07])
        fat.append(Data(repeating: 0, count: 16))
        fat.append(contentsOf: [0x01, 0x00, 0x00, 0x0C])
        fat.append(Data(repeating: 0, count: 16))
        XCTAssertEqual(MachOArchitecture.names(in: fat), ["x86_64", "arm64"])
    }

    func testLocalNetworkOpenFailureIsDistinct() {
        let failure = ScanErrorMapper.map(
            exitCode: 1,
            stderr: "scanimage: open of device xerox_mfp:tcp 192.0.2.10 9400 failed: Invalid argument",
            stdout: "",
            cancelled: false,
            pageCount: 0,
            failedToLaunch: false
        )
        XCTAssertEqual(failure, .localNetwork)
    }

    func testSwitchingConnectionMethodKeepsACustomPort() {
        var scanner = ScannerConfiguration(name: "Office", host: "192.0.2.10", port: 9401, backendID: "xerox_mfp")
        let previous = DeviceAddress.defaultPort(for: scanner.backendID, secure: false)
        if scanner.port == previous {
            scanner.port = DeviceAddress.defaultPort(for: "escl", secure: false)
        }
        scanner.backendID = "escl"
        XCTAssertEqual(scanner.port, 9401)
        var standard = ScannerConfiguration(name: "Office", host: "192.0.2.10", port: 9400)
        if standard.port == DeviceAddress.defaultPort(for: standard.backendID, secure: false) {
            standard.port = DeviceAddress.defaultPort(for: "escl", secure: false)
        }
        XCTAssertEqual(standard.port, 80)
    }
}
