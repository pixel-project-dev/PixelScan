import CoreGraphics
import Foundation

enum BuiltInProfile {
    static let document = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    static let photo = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
    static let multipage = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    static let ocr = UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
}

enum PaperFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case a4
    case a5
    case letter
    case legal
    case maximum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .a4: L10n.text("A4")
        case .a5: L10n.text("A5")
        case .letter: L10n.text("Letter")
        case .legal: L10n.text("Legal")
        case .maximum: L10n.text("Maximum")
        }
    }

    func area(maxWidth: Double, maxHeight: Double) -> ScanAreaMM {
        let requested: (Double, Double)
        switch self {
        case .a4: requested = (210, 297)
        case .a5: requested = (148, 210)
        case .letter: requested = (215.9, 279.4)
        case .legal: requested = (215.9, 355.6)
        case .maximum: requested = (maxWidth, maxHeight)
        }
        return ScanAreaMM(
            left: 0,
            top: 0,
            width: min(requested.0, maxWidth),
            height: min(requested.1, maxHeight)
        )
    }
}

struct ScanAreaMM: Codable, Equatable, Sendable {
    var left: Double
    var top: Double
    var width: Double
    var height: Double

    func clamped(maxWidth: Double, maxHeight: Double) -> ScanAreaMM {
        let left = min(max(0, self.left), max(0, maxWidth - 1))
        let top = min(max(0, self.top), max(0, maxHeight - 1))
        let width = min(max(1, self.width), max(1, maxWidth - left))
        let height = min(max(1, self.height), max(1, maxHeight - top))
        return ScanAreaMM(left: left, top: top, width: width, height: height)
    }
}

struct NormalizedRect: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var isValid: Bool {
        width > 0.01 && height > 0.01 && x >= -0.001 && y >= -0.001 && x + width <= 1.05 && y + height <= 1.05
    }

    func clamped() -> NormalizedRect {
        let x = min(max(0, self.x), 1)
        let y = min(max(0, self.y), 1)
        let width = min(max(0, self.width), 1 - x)
        let height = min(max(0, self.height), 1 - y)
        return NormalizedRect(x: x, y: y, width: width, height: height)
    }

    func rotatedClockwise() -> NormalizedRect {
        let current = clamped()
        return NormalizedRect(
            x: 1 - current.y - current.height,
            y: current.x,
            width: current.height,
            height: current.width
        ).clamped()
    }

    func rotatedCounterClockwise() -> NormalizedRect {
        let current = clamped()
        return NormalizedRect(
            x: current.y,
            y: 1 - current.x - current.width,
            width: current.height,
            height: current.width
        ).clamped()
    }

    func rotated180() -> NormalizedRect {
        let current = clamped()
        return NormalizedRect(
            x: 1 - current.x - current.width,
            y: 1 - current.y - current.height,
            width: current.width,
            height: current.height
        ).clamped()
    }
}

enum ExportFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case pdf
    case png
    case jpeg
    case tiff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pdf: "PDF"
        case .png: "PNG"
        case .jpeg: "JPEG"
        case .tiff: "TIFF"
        }
    }

    var fileExtension: String {
        switch self {
        case .pdf: "pdf"
        case .png: "png"
        case .jpeg: "jpg"
        case .tiff: "tiff"
        }
    }
}

enum PDFCompression: String, Codable, CaseIterable, Identifiable, Sendable {
    case smaller
    case balanced
    case higher
    case lossless

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smaller: L10n.text("Smaller file")
        case .balanced: L10n.text("Balanced")
        case .higher: L10n.text("Higher quality")
        case .lossless: L10n.text("Lossless")
        }
    }

    var jpegQuality: CGFloat? {
        switch self {
        case .smaller: 0.45
        case .balanced: 0.72
        case .higher: 0.88
        case .lossless: nil
        }
    }
}

struct ScannerConfiguration: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var createdAt: Date
    var lastUsedAt: Date?
    var backendID: String
    var secureConnection: Bool

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 9400,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        backendID: String = DeviceAddress.samsungNetwork,
        secureConnection: Bool = false
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.backendID = backendID
        self.secureConnection = secureConnection
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt)
        try container.encode(backendID, forKey: .backendID)
        try container.encode(secureConnection, forKey: .secureConnection)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, host, port, createdAt, lastUsedAt, backendID, secureConnection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(Int.self, forKey: .port)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        backendID = try container.decodeIfPresent(String.self, forKey: .backendID) ?? DeviceAddress.samsungNetwork
        secureConnection = try container.decodeIfPresent(Bool.self, forKey: .secureConnection) ?? false
    }
}

struct ScanProfile: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var localizationKey: String?
    var customName: String
    var source: String
    var resolution: Int
    var mode: String
    var paper: PaperFormat
    var exportFormat: ExportFormat
    var ocr: Bool
    var removeBlankPages: Bool

    var displayName: String {
        if let localizationKey {
            return L10n.text(localizationKey)
        }
        return customName
    }
}

struct ScanSettings: Codable, Equatable, Sendable {
    var source: String
    var resolution: Int
    var mode: String
    var paper: PaperFormat
    var customArea: ScanAreaMM?
    var exportFormat: ExportFormat
    var ocr: Bool
    var removeBlankPages: Bool
    var append: Bool
    var pdfCompression: PDFCompression
    var jpegQuality: Double

    static let document = ScanSettings(
        source: "Flatbed",
        resolution: 300,
        mode: "Gray",
        paper: .a4,
        customArea: nil,
        exportFormat: .pdf,
        ocr: false,
        removeBlankPages: false,
        append: true,
        pdfCompression: .balanced,
        jpegQuality: 0.85
    )

    init(
        source: String,
        resolution: Int,
        mode: String,
        paper: PaperFormat,
        customArea: ScanAreaMM? = nil,
        exportFormat: ExportFormat,
        ocr: Bool,
        removeBlankPages: Bool,
        append: Bool,
        pdfCompression: PDFCompression,
        jpegQuality: Double
    ) {
        self.source = source
        self.resolution = resolution
        self.mode = mode
        self.paper = paper
        self.customArea = customArea
        self.exportFormat = exportFormat
        self.ocr = ocr
        self.removeBlankPages = removeBlankPages
        self.append = append
        self.pdfCompression = pdfCompression
        self.jpegQuality = jpegQuality
    }
}

struct ScannerCapabilities: Codable, Equatable, Sendable {
    var resolutions: [Int]
    var modes: [String]
    var sources: [String]
    var supportsJPEGCompression: Bool
    var duplexSource: String?
    var duplexFlag: String?
    var maxWidthMM: Double
    var maxHeightMM: Double

    var supportsDuplex: Bool {
        duplexSource != nil || duplexFlag != nil
    }
}

struct EditablePage: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var fileName: String
    var source: String
    var resolution: Int
    var createdAt: Date
    var rotation: Int
    var crop: NormalizedRect?
    var deskewDegrees: Double
    var brightness: Double
    var contrast: Double

    init(
        id: UUID = UUID(),
        fileName: String,
        source: String,
        resolution: Int,
        createdAt: Date = Date(),
        rotation: Int = 0,
        crop: NormalizedRect? = nil,
        deskewDegrees: Double = 0,
        brightness: Double = 0,
        contrast: Double = 1
    ) {
        self.id = id
        self.fileName = fileName
        self.source = source
        self.resolution = resolution
        self.createdAt = createdAt
        self.rotation = rotation
        self.crop = crop
        self.deskewDegrees = deskewDegrees
        self.brightness = brightness
        self.contrast = contrast
    }
}

struct DiscoveredScanner: Identifiable, Equatable, Sendable {
    var id: String { "\(host):\(port):\(backendHint)" }
    var name: String
    var host: String
    var port: Int
    var serviceType: String
    var backendHint: String
    var secureConnection: Bool
    var detail: String
}

enum ConnectionState: Equatable {
    case unknown
    case checking
    case ready
    case missingBackend
    case backendDisabled
    case failed(String)

    var title: String {
        switch self {
        case .unknown: L10n.text("Not checked")
        case .checking: L10n.text("Checking…")
        case .ready: L10n.text("Ready")
        case .missingBackend: L10n.text("SANE is missing")
        case .backendDisabled: L10n.text("The selected scanner support is turned off.")
        case .failed(let message): message
        }
    }
}

struct ScanOutcome: Equatable, Sendable {
    var files: [URL]
    var warning: ScanFailure?
}

enum ScanFailure: Error, Equatable, LocalizedError {
    case invalidAddress
    case unreachable
    case portUnreachable
    case busy
    case adfEmpty
    case paperJam
    case multiFeed
    case cancelled
    case networkInterrupted
    case incomplete
    case backendMissing
    case backendDisabled
    case backendNotInstalled
    case unsupportedBackend
    case localNetwork
    case badImage
    case exportFailed(String)
    case couldNotReadOptions
    case deviceError(String)

    var errorDescription: String? { message }

    var message: String {
        switch self {
        case .invalidAddress:
            L10n.text("The address is not a valid IPv4 address or hostname.")
        case .unreachable:
            L10n.text("The scanner is not reachable.")
        case .portUnreachable:
            L10n.text("The port is not reachable.")
        case .busy:
            L10n.text("The scanner is busy.")
        case .adfEmpty:
            L10n.text("The document feeder is empty.")
        case .paperJam:
            L10n.text("Paper jam. Pages that were already scanned are kept.")
        case .multiFeed:
            L10n.text("A multiple feed was reported. Pages that were already scanned are kept.")
        case .cancelled:
            L10n.text("The scan was cancelled. Pages that were already scanned are kept.")
        case .networkInterrupted:
            L10n.text("The network connection was interrupted. Pages that were already scanned are kept.")
        case .incomplete:
            L10n.text("The scan ended early. Pages that were already scanned are kept.")
        case .backendMissing:
            L10n.text("SANE components are missing.")
        case .backendDisabled:
            L10n.text("The selected scanner support is turned off.")
        case .backendNotInstalled:
            L10n.text("This connection method is not installed with the scanner software.")
        case .unsupportedBackend:
            L10n.text("This connection method is not available.")
        case .localNetwork:
            L10n.text("The scanner was found, but it could not be opened. Check that it is turned on and on the same network. If macOS asked for local network access, allow Samsung Scan.")
        case .badImage:
            L10n.text("The image data is invalid.")
        case .exportFailed(let detail):
            L10n.text("The file could not be written.") + " " + detail
        case .couldNotReadOptions:
            L10n.text("The scanner options could not be read.")
        case .deviceError(let detail):
            L10n.text("The scanner reported an error.") + " " + detail
        }
    }
}

struct ScanRequest: Equatable, Sendable {
    var deviceName: String
    var source: String
    var resolution: Int
    var mode: String
    var area: ScanAreaMM
    var outputDirectory: URL
    var batch: Bool
    var capabilities: ScannerCapabilities
}
