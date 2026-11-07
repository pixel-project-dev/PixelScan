import AppKit
import PDFKit
import XCTest
@testable import PixelScan

final class ImagingTests: XCTestCase {
    func testQuarterTurnChangesDimensions() throws {
        let image = try XCTUnwrap(ImagePipeline.makeSolidImage(width: 12, height: 4, color: (0.2, 0.4, 0.6)))
        let turned = try ImagePipeline.rotate(image, degrees: 90)
        XCTAssertEqual(turned.width, 4)
        XCTAssertEqual(turned.height, 12)
        let full = try ImagePipeline.rotate(image, degrees: 180)
        XCTAssertEqual(full.width, 12)
        XCTAssertEqual(full.height, 4)
    }

    func testCropAndColorAdjustment() throws {
        let image = try XCTUnwrap(ImagePipeline.makeSolidImage(width: 100, height: 80, color: (0.1, 0.2, 0.3)))
        let cropped = try ImagePipeline.cropImage(
            image,
            normalizedTopLeft: NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        )
        XCTAssertEqual(cropped.width, 50)
        XCTAssertEqual(cropped.height, 40)
        let adjusted = try ImagePipeline.adjust(image, brightness: 0.1, contrast: 1.1)
        XCTAssertEqual(adjusted.width, 100)
        XCTAssertEqual(adjusted.height, 80)
    }

    func testBlankDetection() throws {
        let white = try XCTUnwrap(ImagePipeline.makeSolidImage(width: 80, height: 80, color: (1, 1, 1)))
        XCTAssertTrue(BlankPageDetector.isBlank(white))
        let marked = try XCTUnwrap(drawSquare())
        XCTAssertFalse(BlankPageDetector.isBlank(marked))
    }

    func testPNGJPEGAndMultipageTIFF() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let image = try XCTUnwrap(ImagePipeline.makeSolidImage(width: 30, height: 20, color: (0.3, 0.5, 0.2)))
        let png = directory.appendingPathComponent("page.png")
        let jpeg = directory.appendingPathComponent("page.jpg")
        let tiff = directory.appendingPathComponent("pages.tiff")
        try ExportService.exportImage(image, to: png, format: .png, jpegQuality: 0.8)
        try ExportService.exportImage(image, to: jpeg, format: .jpeg, jpegQuality: 0.8)
        try ExportService.exportTIFF(images: [image, image], to: tiff)
        XCTAssertTrue(ScanimageDriver.isImage(png))
        XCTAssertTrue(ScanimageDriver.isImage(jpeg))
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(tiff as CFURL, nil))
        XCTAssertEqual(CGImageSourceGetCount(source), 2)
    }

    func testSearchablePDF() throws {
        let image = try XCTUnwrap(textImage("Hello Scanner"))
        let tokens = try OCRService.recognize(image: image)
        XCTAssertTrue(tokens.contains { $0.text.localizedCaseInsensitiveContains("Hello") || $0.text.localizedCaseInsensitiveContains("Scanner") })
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        try ExportService.exportPDF(
            pages: [RenderedPage(image: image, resolution: 72, tokens: tokens)],
            to: url,
            compression: .lossless,
            title: "OCR"
        )
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertEqual(document.pageCount, 2 - 1)
        let text = document.string ?? ""
        XCTAssertTrue(text.localizedCaseInsensitiveContains("Hello") || text.localizedCaseInsensitiveContains("Scanner"))
    }

    func testMultipagePDFPageCount() throws {
        let first = try XCTUnwrap(ImagePipeline.makeSolidImage(width: 40, height: 50, color: (1, 0, 0)))
        let second = try XCTUnwrap(ImagePipeline.makeSolidImage(width: 40, height: 50, color: (0, 0, 1)))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        try ExportService.exportPDF(
            pages: [
                RenderedPage(image: first, resolution: 72, tokens: []),
                RenderedPage(image: second, resolution: 72, tokens: [])
            ],
            to: url,
            compression: .balanced,
            title: "Pages"
        )
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertEqual(document.pageCount, 2)
    }

    private func drawSquare() -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: 80,
            height: 80,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 10, y: 10, width: 30, height: 30))
        return context.makeImage()
    }

    private func textImage(_ text: String) -> CGImage? {
        let size = NSSize(width: 1600, height: 420)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 120, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        (text as NSString).draw(at: NSPoint(x: 60, y: 140), withAttributes: attributes)
        image.unlockFocus()
        var rect = NSRect(origin: .zero, size: size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}
