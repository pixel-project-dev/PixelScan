import Foundation

enum ProgressParser {
    static func fraction(in chunk: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"Progress:\s*([0-9]+(?:\.[0-9]+)?)%"#) else {
            return nil
        }
        let range = NSRange(chunk.startIndex..., in: chunk)
        let matches = regex.matches(in: chunk, range: range)
        guard let match = matches.last, match.numberOfRanges > 1, let valueRange = Range(match.range(at: 1), in: chunk) else {
            return nil
        }
        guard let value = Double(chunk[valueRange]) else { return nil }
        return min(1, max(0, value / 100))
    }
}
