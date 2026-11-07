import Foundation

enum CompatibilityStatus: String, Codable, Equatable, Sendable {
    case tested
    case backendSupportConfirmed
    case experimental
    case unsupported

    var title: String {
        switch self {
        case .tested: L10n.text("Tested")
        case .backendSupportConfirmed: L10n.text("Backend support confirmed")
        case .experimental: L10n.text("Experimental")
        case .unsupported: L10n.text("Not supported")
        }
    }
}

struct CompatibilityDevice: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var vendor: String
    var model: String
    var family: String
    var identification: String
    var backend: String
    var networkProtocol: String?
    var defaultPort: Int?
    var flatbed: Bool?
    var adf: Bool?
    var duplex: Bool?
    var operatingSystems: [String]
    var status: CompatibilityStatus
    var limitations: String
    var evidence: String
}

struct CompatibilityDocument: Codable, Equatable, Sendable {
    var schema: Int
    var source: String
    var devices: [CompatibilityDevice]
}

enum CompatibilityDatabase {
    static func loadBundled() -> CompatibilityDocument {
        guard let url = Bundle.main.url(forResource: "compatibility", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let document = try? JSONDecoder().decode(CompatibilityDocument.self, from: data) else {
            return CompatibilityDocument(schema: 1, source: "", devices: [])
        }
        return document
    }

    static func load(data: Data) throws -> CompatibilityDocument {
        try JSONDecoder().decode(CompatibilityDocument.self, from: data)
    }

    static func search(_ document: CompatibilityDocument, query: String) -> [CompatibilityDevice] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard needle.count >= 2 else { return [] }
        return document.devices.filter { device in
            [device.vendor, device.model, device.family, device.identification]
                .joined(separator: " ")
                .lowercased()
                .contains(needle)
        }
    }
}
