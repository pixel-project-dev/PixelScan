import Foundation

enum DeviceName {
    static let backend = "xerox_mfp"
    static let defaultPort = 9400

    static func make(host: String, port: Int) throws -> String {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidHost(trimmed), (1...65535).contains(port) else {
            throw ScanFailure.invalidAddress
        }
        return "\(backend):tcp \(trimmed) \(port)"
    }

    static func isValidHost(_ host: String) -> Bool {
        if host.count > 253 || host.isEmpty { return false }
        if host.contains("..") { return false }
        if host.allSatisfy({ $0.isNumber || $0 == "." }) {
            return isIPv4(host)
        }
        return isHostname(host)
    }

    static func isIPv4(_ host: String) -> Bool {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard part.count <= 3, part.allSatisfy(\.isNumber), let value = Int(part) else { return false }
            if part.count > 1 && part.hasPrefix("0") { return false }
            return (0...255).contains(value)
        }
    }

    private static func isHostname(_ host: String) -> Bool {
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard !labels.isEmpty, labels.count <= 127 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        return labels.allSatisfy { label in
            guard (1...63).contains(label.count) else { return false }
            guard label.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
            guard let first = label.first, let last = label.last else { return false }
            return first.isLetter || first.isNumber
                ? !(last == "-") && (first.isLetter || first.isNumber)
                : false
        }
    }
}
