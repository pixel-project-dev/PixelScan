import Foundation

struct AppStorageLayout: Equatable {
    var root: URL

    var libraryFile: URL { root.appendingPathComponent("library.json") }
    var sessionFile: URL { root.appendingPathComponent("session.json") }
    var sessionPages: URL { root.appendingPathComponent("pages", isDirectory: true) }
    var inbox: URL { root.appendingPathComponent("inbox", isDirectory: true) }
    var logFile: URL { root.appendingPathComponent("scan.log") }
    var saneDirectory: URL { root.appendingPathComponent("sane.d", isDirectory: true) }

    static func live() -> AppStorageLayout {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return AppStorageLayout(root: base.appendingPathComponent("Samsung Scan", isDirectory: true))
    }

    func prepare() throws {
        let manager = FileManager.default
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        try manager.createDirectory(at: sessionPages, withIntermediateDirectories: true)
        try manager.createDirectory(at: inbox, withIntermediateDirectories: true)
    }
}

struct ScannerLibrary: Codable, Equatable {
    var scanners: [ScannerConfiguration]
    var profiles: [ScanProfile]
    var selectedScannerID: UUID?
    var selectedProfileID: UUID?
    var settings: ScanSettings
    var scanimageOverridePath: String?
    var setupCompleted: Bool

    static func makeDefault() -> ScannerLibrary {
        ScannerLibrary(
            scanners: [],
            profiles: ScanProfile.defaults,
            selectedScannerID: nil,
            selectedProfileID: BuiltInProfile.document,
            settings: .document,
            scanimageOverridePath: nil,
            setupCompleted: false
        )
    }

    init(
        scanners: [ScannerConfiguration],
        profiles: [ScanProfile],
        selectedScannerID: UUID?,
        selectedProfileID: UUID?,
        settings: ScanSettings,
        scanimageOverridePath: String?,
        setupCompleted: Bool
    ) {
        self.scanners = scanners
        self.profiles = profiles
        self.selectedScannerID = selectedScannerID
        self.selectedProfileID = selectedProfileID
        self.settings = settings
        self.scanimageOverridePath = scanimageOverridePath
        self.setupCompleted = setupCompleted
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scanners, forKey: .scanners)
        try container.encode(profiles, forKey: .profiles)
        try container.encodeIfPresent(selectedScannerID, forKey: .selectedScannerID)
        try container.encodeIfPresent(selectedProfileID, forKey: .selectedProfileID)
        try container.encode(settings, forKey: .settings)
        try container.encodeIfPresent(scanimageOverridePath, forKey: .scanimageOverridePath)
        try container.encode(setupCompleted, forKey: .setupCompleted)
    }

    enum CodingKeys: String, CodingKey {
        case scanners, profiles, selectedScannerID, selectedProfileID, settings, scanimageOverridePath, setupCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scanners = try container.decodeIfPresent([ScannerConfiguration].self, forKey: .scanners) ?? []
        profiles = try container.decodeIfPresent([ScanProfile].self, forKey: .profiles) ?? []
        selectedScannerID = try container.decodeIfPresent(UUID.self, forKey: .selectedScannerID)
        selectedProfileID = try container.decodeIfPresent(UUID.self, forKey: .selectedProfileID)
        settings = try container.decodeIfPresent(ScanSettings.self, forKey: .settings) ?? .document
        scanimageOverridePath = try container.decodeIfPresent(String.self, forKey: .scanimageOverridePath)
        setupCompleted = try container.decodeIfPresent(Bool.self, forKey: .setupCompleted) ?? !scanners.isEmpty
    }

    var selectedScanner: ScannerConfiguration? {
        scanners.first { $0.id == selectedScannerID }
    }
}

extension ScanProfile {
    static var defaults: [ScanProfile] {
        [
            ScanProfile(
                id: BuiltInProfile.document,
                localizationKey: "Document",
                customName: "Document",
                source: "Flatbed",
                resolution: 300,
                mode: "Gray",
                paper: .a4,
                exportFormat: .pdf,
                ocr: false,
                removeBlankPages: false
            ),
            ScanProfile(
                id: BuiltInProfile.photo,
                localizationKey: "Photo",
                customName: "Photo",
                source: "Flatbed",
                resolution: 600,
                mode: "Color",
                paper: .maximum,
                exportFormat: .jpeg,
                ocr: false,
                removeBlankPages: false
            ),
            ScanProfile(
                id: BuiltInProfile.multipage,
                localizationKey: "Multi-page document",
                customName: "Multi-page document",
                source: "ADF",
                resolution: 300,
                mode: "Gray",
                paper: .a4,
                exportFormat: .pdf,
                ocr: false,
                removeBlankPages: false
            ),
            ScanProfile(
                id: BuiltInProfile.ocr,
                localizationKey: "OCR document",
                customName: "OCR document",
                source: "Flatbed",
                resolution: 300,
                mode: "Gray",
                paper: .a4,
                exportFormat: .pdf,
                ocr: true,
                removeBlankPages: false
            )
        ]
    }
}

struct SessionState: Codable, Equatable {
    var pages: [EditablePage]
    var selectedPageID: UUID?
}

final class LibraryStore {
    let layout: AppStorageLayout
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(layout: AppStorageLayout) {
        self.layout = layout
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadLibrary() -> ScannerLibrary {
        guard let data = try? Data(contentsOf: layout.libraryFile),
              let library = try? decoder.decode(ScannerLibrary.self, from: data) else {
            return .makeDefault()
        }
        var restored = library
        if restored.profiles.isEmpty {
            restored.profiles = ScanProfile.defaults
        }
        return restored
    }

    func saveLibrary(_ library: ScannerLibrary) throws {
        try layout.prepare()
        let data = try encoder.encode(library)
        try data.write(to: layout.libraryFile, options: .atomic)
    }

    func loadSession() -> SessionState {
        guard let data = try? Data(contentsOf: layout.sessionFile),
              let session = try? decoder.decode(SessionState.self, from: data) else {
            return SessionState(pages: [], selectedPageID: nil)
        }
        let existing = session.pages.filter { page in
            FileManager.default.fileExists(atPath: layout.sessionPages.appendingPathComponent(page.fileName).path)
        }
        return SessionState(pages: existing, selectedPageID: session.selectedPageID)
    }

    func saveSession(_ session: SessionState) throws {
        try layout.prepare()
        let data = try encoder.encode(session)
        try data.write(to: layout.sessionFile, options: .atomic)
    }

    func appendLog(_ line: String) {
        try? layout.prepare()
        let stamped = "\(ISO8601DateFormatter().string(from: Date())) \(line)\n"
        let url = layout.logFile
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            if let data = stamped.data(using: .utf8) {
                try? handle.write(contentsOf: data)
            }
        } else {
            try? stamped.data(using: .utf8)?.write(to: url)
        }
        trimLogIfNeeded()
    }

    private func trimLogIfNeeded() {
        let url = layout.logFile
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int,
              size > 200_000,
              let data = try? Data(contentsOf: url) else { return }
        let tail = data.suffix(120_000)
        try? tail.write(to: url, options: .atomic)
    }
}
