import Foundation

enum DeviceAddress {
    static let samsungNetwork = "xerox_mfp"
    static let webScan = "escl"
    static let canonNetwork = "pixma"

    static func make(backendID: String, host: String, port: Int, secure: Bool = false) throws -> String {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard DeviceName.isValidHost(trimmed), (1...65535).contains(port) else {
            throw ScanFailure.invalidAddress
        }
        switch backendID {
        case samsungNetwork:
            return "xerox_mfp:tcp \(trimmed) \(port)"
        case webScan:
            return "escl:\(secure ? "https" : "http")://\(trimmed):\(port)"
        case canonNetwork:
            return "pixma:bjnp://\(trimmed):\(port)"
        default:
            throw ScanFailure.unsupportedBackend
        }
    }

    static func plainTitle(for backendID: String) -> String {
        switch backendID {
        case samsungNetwork:
            L10n.text("Samsung network")
        case webScan:
            L10n.text("Web scan")
        case canonNetwork:
            L10n.text("Canon network protocol")
        default:
            backendID
        }
    }

    static func defaultPort(for backendID: String, secure: Bool) -> Int {
        switch backendID {
        case webScan: secure ? 443 : 80
        case canonNetwork: 8612
        default: 9400
        }
    }

    static func selectableIDs(installedLibraries: [String]) -> [String] {
        var ids = [samsungNetwork, webScan]
        if installedLibraries.isEmpty || installedLibraries.contains(canonNetwork) {
            ids.append(canonNetwork)
        }
        return ids
    }
}

enum BackendAvailability {
    static func libraryIsPresent(_ backendID: String, installedLibraries: [String]) -> Bool {
        if installedLibraries.isEmpty { return true }
        return installedLibraries.contains(backendID)
    }

    static func isEnabled(_ backendID: String, enabledBackends: [String]) -> Bool? {
        if enabledBackends.isEmpty { return nil }
        return enabledBackends.contains(backendID)
    }
}

enum SANEConfigText {
    static let writableBackends: Set<String> = ["xerox_mfp", "escl", "pixma", "net"]

    static func enabling(_ backend: String, in text: String) -> String {
        guard writableBackends.contains(backend) else { return text }
        let lines = text.components(separatedBy: .newlines)
        let rewritten = lines.map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "#\(backend)" || trimmed == "# \(backend)" {
                return backend
            }
            return line
        }
        var result = rewritten.joined(separator: "\n")
        if !enabledBackends(in: result).contains(backend) {
            if !result.hasSuffix("\n") { result += "\n" }
            result += backend + "\n"
        }
        return result
    }

    static func enabledBackends(in text: String) -> [String] {
        text.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), !trimmed.hasPrefix(";") else { return nil }
            let token = trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
            guard token.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else { return nil }
            return token
        }
    }

    static func libraryNames(in fileNames: [String]) -> [String] {
        fileNames.compactMap { name in
            guard name.hasPrefix("libsane-"), name.hasSuffix(".so") else { return nil }
            let core = String(name.dropFirst("libsane-".count).dropLast(".so".count))
            guard !core.isEmpty, !core.contains(".") else { return nil }
            return core
        }
    }
}
