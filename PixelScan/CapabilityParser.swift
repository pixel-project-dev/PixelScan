import Foundation

enum CapabilityParser {
    static func parse(_ text: String) -> ScannerCapabilities {
        var resolutions: [Int] = []
        var modes: [String] = []
        var sources: [String] = []
        var jpeg = false
        var duplexSource: String?
        var duplexFlag: String?
        var maxWidth = 0.0
        var maxHeight = 0.0

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let option = parseOption(line) else { continue }
            let name = option.name
            let body = option.body
            if name == "--resolution" || name == "-resolution" {
                resolutions = integers(in: body)
            } else if name == "--mode" {
                modes = choices(in: body)
            } else if name == "--source" {
                sources = choices(in: body)
                duplexSource = sources.first { $0.range(of: "duplex", options: .caseInsensitive) != nil }
            } else if name == "--jpeg" || name == "--jpeg-compression" {
                jpeg = true
            } else if name == "-x" || name == "--width" {
                maxWidth = rangeMaximum(in: body) ?? maxWidth
            } else if name == "-y" || name == "--height" {
                maxHeight = rangeMaximum(in: body) ?? maxHeight
            } else if name.localizedCaseInsensitiveContains("duplex") {
                duplexFlag = String(name.drop { $0 == "-" })
            }
        }

        return ScannerCapabilities(
            resolutions: resolutions.sorted(),
            modes: modes,
            sources: sources,
            supportsJPEGCompression: jpeg,
            duplexSource: duplexSource,
            duplexFlag: duplexFlag,
            maxWidthMM: maxWidth > 0 ? maxWidth : 215.9,
            maxHeightMM: maxHeight > 0 ? maxHeight : 297.18
        )
    }

    private struct Option {
        var name: String
        var body: String
    }

    private static func parseOption(_ line: String) -> Option? {
        guard line.hasPrefix("--") || (line.hasPrefix("-") && line.dropFirst().first?.isLetter == true) else {
            return nil
        }
        let parts = line.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
        guard parts.count == 2 else { return nil }
        let name = String(parts[0]).components(separatedBy: "[").first ?? String(parts[0])
        return Option(name: name, body: String(parts[1]))
    }

    private static func choices(in body: String) -> [String] {
        let head = body.components(separatedBy: "[").first ?? body
        let cleaned = head.replacingOccurrences(of: "dpi", with: "")
        guard cleaned.contains("|") else { return [] }
        return cleaned
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func integers(in body: String) -> [Int] {
        choices(in: body).compactMap { token in
            let digits = token.prefix { $0.isNumber }
            return Int(digits)
        }
    }

    private static func rangeMaximum(in body: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"(-?\d+(?:\.\d+)?)\.\.(-?\d+(?:\.\d+)?)"#) else {
            return nil
        }
        let range = NSRange(body.startIndex..., in: body)
        guard let match = regex.firstMatch(in: body, range: range),
              match.numberOfRanges > 2,
              let valueRange = Range(match.range(at: 2), in: body) else {
            return nil
        }
        return Double(body[valueRange])
    }
}
