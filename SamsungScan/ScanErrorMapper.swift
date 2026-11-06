import Foundation

enum ScanErrorMapper {
    static func map(exitCode: Int32, stderr: String, stdout: String, cancelled: Bool, pageCount: Int, failedToLaunch: Bool) -> ScanFailure? {
        if failedToLaunch {
            return .backendMissing
        }
        if cancelled {
            return .cancelled
        }
        let text = stderr + "\n" + stdout
        if pageCount > 0 && contains(text, ["out of documents", "feeder out of documents"]) && !contains(text, ["jam"]) {
            return nil
        }
        if exitCode == 0 {
            return pageCount == 0 ? .incomplete : nil
        }
        if contains(text, ["document feeder jammed", "paper jam", "jammed"]) || contains(text, ["\\bjam\\b"]) {
            return .paperJam
        }
        if contains(text, ["multipick", "multi-feed", "multifeed", "multiple feed", "double feed"]) {
            return .multiFeed
        }
        if contains(text, ["device busy", "resource busy", "scanner busy"]) {
            return .busy
        }
        if contains(text, ["out of documents", "feeder empty", "no documents"]) {
            return .adfEmpty
        }
        if contains(text, ["timed out", "timeout", "connection reset", "broken pipe", "host is down", "no route", "network is unreachable"]) {
            return .networkInterrupted
        }
        if contains(text, ["unknown backend", "backend `xerox_mfp' is not", "dll"]) && contains(text, ["xerox_mfp"]) {
            return .backendDisabled
        }
        if contains(text, ["failed to open", "no such device", "name or service not known", "nodename nor servname", "could not resolve"]) {
            return .unreachable
        }
        if pageCount > 0 {
            return .incomplete
        }
        let detail = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("Progress:") && !$0.hasPrefix("Output format") }
            .suffix(4)
            .joined(separator: " ")
        if detail.isEmpty {
            return .deviceError("exit \(exitCode)")
        }
        return .deviceError(String(detail.prefix(400)))
    }

    private static func contains(_ text: String, _ patterns: [String]) -> Bool {
        for pattern in patterns {
            if pattern.hasPrefix("\\b") {
                if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                    return true
                }
            } else if text.range(of: pattern, options: .caseInsensitive) != nil {
                return true
            }
        }
        return false
    }
}
