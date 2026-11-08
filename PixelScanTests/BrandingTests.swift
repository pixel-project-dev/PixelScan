import AppKit
import XCTest
@testable import PixelScan

final class BrandingTests: XCTestCase {
    func testWebsiteAddressIsExactAndDoesNotOpenByItself() {
        XCTAssertEqual(PixelProjectSite.url.absoluteString, "https://pixel-project.de")
        XCTAssertEqual(PixelProjectSite.url.scheme, "https")
        XCTAssertNotEqual(PixelProjectSite.url.host, "github.com")
        XCTAssertFalse(PixelProjectSite.opensOnLaunch)
        XCTAssertNotEqual(PixelProjectSite.sourceRepository, PixelProjectSite.url)
    }

    func testLogoFilesAreVectorSVG() throws {
        let root = try sourceRoot()
        let names = [
            "pixelproject-logo.svg",
            "pixelproject-logo-transparent.svg",
            "pixelproject-logo-dark.svg",
            "pixelproject-logo-light.svg",
            "pixelproject-mark.svg"
        ]
        for name in names {
            let text = try String(contentsOf: root.appendingPathComponent("branding/\(name)"), encoding: .utf8)
            let document = try XMLDocument(xmlString: text, options: [.nodePreserveAll])
            let rootElement = try XCTUnwrap(document.rootElement())
            XCTAssertEqual(rootElement.name, "svg")
            XCTAssertFalse(rootElement.attribute(forName: "viewBox")?.stringValue?.isEmpty ?? true)
            XCTAssertFalse(text.contains("<image"))
            XCTAssertFalse(text.contains("<script"))
            XCTAssertFalse(text.contains("@font-face"))
            if name != "pixelproject-mark.svg" {
                XCTAssertTrue(text.contains("pixelproject."))
            }
        }
    }

    func testLightLogoKeepsTheNeonGridAndDarkensTheWord() throws {
        let text = try String(contentsOf: sourceRoot().appendingPathComponent("branding/pixelproject-logo-light.svg"), encoding: .utf8)
        XCTAssertTrue(text.contains("#bdff65"))
        XCTAssertTrue(text.contains("#171c26"))
        XCTAssertTrue(text.contains("#3d6410"))
        XCTAssertTrue(text.contains("#f5f7fa"))
    }

    func testDarkLogoUsesTheWebsiteColors() throws {
        let text = try String(contentsOf: sourceRoot().appendingPathComponent("branding/pixelproject-logo.svg"), encoding: .utf8)
        XCTAssertTrue(text.contains("#11131a"))
        XCTAssertTrue(text.contains("#f7f8f4"))
        XCTAssertTrue(text.contains("#bdff65"))
    }

    func testLogoAssetAndCatalogExist() throws {
        let image = try XCTUnwrap(NSImage(named: "PixelProjectLogo"))
        XCTAssertGreaterThan(image.size.width, 0)
        let catalog = try sourceRoot().appendingPathComponent("PixelScan/Assets.xcassets/PixelProjectLogo.imageset/Contents.json")
        let contents = try String(contentsOf: catalog, encoding: .utf8)
        XCTAssertTrue(contents.contains("PixelProjectLogoDark.pdf"))
        XCTAssertTrue(contents.contains("PixelProjectLogoLight.pdf"))
        XCTAssertTrue(contents.contains("preserves-vector-representation"))
    }

    func testGermanBrandStrings() throws {
        let text = try String(contentsOf: sourceRoot().appendingPathComponent("PixelScan/de.lproj/Localizable.strings"), encoding: .utf8)
        XCTAssertTrue(text.contains("\"About PixelScan\" = \"Über PixelScan\";"))
        XCTAssertTrue(text.contains("\"Developed by PixelProject\" = \"Entwickelt von PixelProject\";"))
        XCTAssertTrue(text.contains("\"Project website\" = \"Projektwebsite\";"))
        XCTAssertTrue(text.contains("\"PixelProject – Open website\" = \"PixelProject – Website öffnen\";"))
        XCTAssertTrue(text.contains("\"Version %@ (Build %@)\" = \"Version %@ (Build %@)\";"))
    }

    func testMainWindowShowsTheBrandLink() throws {
        let sidebar = try String(contentsOf: sourceRoot().appendingPathComponent("PixelScan/ScannerSidebar.swift"), encoding: .utf8)
        XCTAssertTrue(sidebar.contains("PixelProjectBrandLink"))
    }

    func testApplicationSourceDoesNotOpenTheWebsiteAtLaunch() throws {
        let app = try String(contentsOf: sourceRoot().appendingPathComponent("PixelScan/PixelScanApp.swift"), encoding: .utf8)
        let model = try String(contentsOf: sourceRoot().appendingPathComponent("PixelScan/AppModel.swift"), encoding: .utf8)
        XCTAssertFalse(app.contains("pixel-project.de"))
        XCTAssertFalse(app.contains("PixelProjectSite"))
        XCTAssertFalse(model.contains("pixel-project.de"))
        XCTAssertFalse(model.contains("PixelProjectSite"))
    }

    private func sourceRoot() throws -> URL {
        let bundle = Bundle(for: BrandingTests.self)
        let value = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "PixelScanSourceRoot") as? String)
        XCTAssertFalse(value.contains("$("))
        return URL(fileURLWithPath: value, isDirectory: true)
    }
}
