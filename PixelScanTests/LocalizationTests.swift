import XCTest
@testable import PixelScan

final class LocalizationTests: XCTestCase {
    func testTranslatedCatalogsMatchTheGermanKeysAndSpecifiers() throws {
        let root = try sourceRoot()
        let reference = try catalog(at: root.appendingPathComponent("PixelScan/de.lproj/Localizable.strings"))
        XCTAssertGreaterThan(reference.count, 100)
        for language in ["fr", "es", "it"] {
            let translated = try catalog(at: root.appendingPathComponent("PixelScan/\(language).lproj/Localizable.strings"))
            XCTAssertEqual(Set(translated.keys), Set(reference.keys), language)
            for (key, value) in reference {
                let other = try XCTUnwrap(translated[key])
                XCTAssertEqual(formatSpecifiers(in: value), formatSpecifiers(in: other), "\(language): \(key)")
                XCTAssertFalse(other.isEmpty, "\(language): \(key)")
            }
            let info = try catalog(at: root.appendingPathComponent("PixelScan/\(language).lproj/InfoPlist.strings"))
            XCTAssertEqual(Set(info.keys), ["NSLocalNetworkUsageDescription", "NSHumanReadableCopyright"])
        }
    }

    func testAppearanceToggleChoosesTheOppositeMode() {
        XCTAssertEqual(AppearancePreference.toggled(from: "", current: .light), "dark")
        XCTAssertEqual(AppearancePreference.toggled(from: "", current: .dark), "light")
        XCTAssertEqual(AppearancePreference.toggled(from: "dark", current: .light), "light")
        XCTAssertEqual(AppearancePreference.toggled(from: "light", current: .dark), "dark")
        XCTAssertEqual(AppearancePreference.scheme(for: "light"), .light)
        XCTAssertEqual(AppearancePreference.scheme(for: "dark"), .dark)
        XCTAssertNil(AppearancePreference.scheme(for: ""))
        XCTAssertNil(AppearancePreference.nsAppearance(for: ""))
        XCTAssertEqual(AppearancePreference.nsAppearance(for: "light")?.name, .aqua)
        XCTAssertEqual(AppearancePreference.nsAppearance(for: "dark")?.name, .darkAqua)
    }

    func testToolbarContainsTheAppearanceSymbol() throws {
        let source = try String(contentsOf: sourceRoot().appendingPathComponent("PixelScan/MainView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("Switch to Dark Mode"))
        XCTAssertTrue(source.contains("systemImage: appearanceIsDark ? \"sun.max\" : \"moon\""))
        XCTAssertTrue(source.contains(".pixelScanAppearance()"))
    }

    private func catalog(at url: URL) throws -> [String: String] {
        let text = try String(contentsOf: url, encoding: .utf8)
        var entries: [String: String] = [:]
        var index = text.startIndex
        func skipWhitespaceAndComments() {
            while index < text.endIndex {
                if text[index].isWhitespace { index = text.index(after: index); continue }
                if text[index...].hasPrefix("/*") {
                    guard let end = text[index...].range(of: "*/") else { break }
                    index = end.upperBound
                    continue
                }
                if text[index...].hasPrefix("//") {
                    if let newline = text[index...].firstIndex(of: "\n") {
                        index = text.index(after: newline)
                    } else {
                        index = text.endIndex
                    }
                    continue
                }
                break
            }
        }
        func readQuoted() throws -> String {
            XCTAssertEqual(text[index], "\"")
            index = text.index(after: index)
            var value = ""
            while index < text.endIndex {
                let character = text[index]
                index = text.index(after: index)
                if character == "\\" {
                    guard index < text.endIndex else { break }
                    let escaped = text[index]
                    index = text.index(after: index)
                    value.append(escaped == "n" ? "\n" : escaped)
                    continue
                }
                if character == "\"" { return value }
                value.append(character)
            }
            XCTFail("Unclosed string in \(url.lastPathComponent)")
            return value
        }

        while index < text.endIndex {
            skipWhitespaceAndComments()
            if index >= text.endIndex { break }
            let key = try readQuoted()
            skipWhitespaceAndComments()
            XCTAssertEqual(text[index], "=")
            index = text.index(after: index)
            skipWhitespaceAndComments()
            let value = try readQuoted()
            skipWhitespaceAndComments()
            XCTAssertEqual(text[index], ";")
            index = text.index(after: index)
            XCTAssertNil(entries[key], "Duplicate key \(key)")
            entries[key] = value
        }
        return entries
    }

    private func formatSpecifiers(in value: String) -> [String] {
        var found: [String] = []
        var index = value.startIndex
        while index < value.endIndex {
            guard value[index] == "%" else {
                index = value.index(after: index)
                continue
            }
            let next = value.index(after: index)
            if next < value.endIndex, value[next] == "%" {
                index = value.index(after: next)
                continue
            }
            var end = next
            while end < value.endIndex, !"@dDuUxXoOfeEgGcCsSp".contains(value[end]) {
                end = value.index(after: end)
            }
            if end < value.endIndex { end = value.index(after: end) }
            found.append(String(value[index..<end]))
            index = end
        }
        return found
    }

    private func sourceRoot() throws -> URL {
        let bundle = Bundle(for: LocalizationTests.self)
        let value = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "PixelScanSourceRoot") as? String)
        XCTAssertFalse(value.contains("$("))
        return URL(fileURLWithPath: value, isDirectory: true)
    }
}
