import AppKit
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RenderedPage: Sendable {
    var image: CGImage
    var resolution: Int
    var tokens: [OCRToken]
}

enum ExportService {
    static func exportPDF(pages: [RenderedPage], to url: URL, compression: PDFCompression, title: String) throws {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
        var firstBox = pageBox(for: pages.first)
        let info: [CFString: Any] = [
            kCGPDFContextTitle: title,
            kCGPDFContextCreator: "PixelScan"
        ]
        guard let context = CGContext(consumer: consumer, mediaBox: &firstBox, info as CFDictionary) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
        for page in pages {
            let box = pageBox(for: page)
            context.beginPDFPage([kCGPDFContextMediaBox: box] as CFDictionary)
            if let quality = compression.jpegQuality, let jpegImage = jpegImage(page.image, quality: quality) {
                context.draw(jpegImage, in: box)
            } else {
                context.draw(page.image, in: box)
            }
            drawInvisibleText(page.tokens, in: box, context: context)
            context.endPDFPage()
        }
        context.closePDF()
        do {
            try (data as Data).write(to: url, options: .atomic)
        } catch {
            throw ScanFailure.exportFailed(error.localizedDescription)
        }
    }

    static func exportImage(_ image: CGImage, to url: URL, format: ExportFormat, jpegQuality: Double) throws {
        let type: CFString
        switch format {
        case .png: type = UTType.png.identifier as CFString
        case .jpeg: type = UTType.jpeg.identifier as CFString
        case .tiff: type = UTType.tiff.identifier as CFString
        case .pdf: throw ScanFailure.exportFailed("pdf")
        }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
        var properties: [CFString: Any] = [:]
        if format == .jpeg {
            properties[kCGImageDestinationLossyCompressionQuality] = jpegQuality
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
    }

    static func exportTIFF(images: [CGImage], to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.tiff.identifier as CFString, images.count, nil) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
        for image in images {
            CGImageDestinationAddImage(destination, image, nil)
        }
        guard CGImageDestinationFinalize(destination) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
    }

    static func pageBox(for page: RenderedPage?) -> CGRect {
        guard let page else { return CGRect(x: 0, y: 0, width: 595, height: 842) }
        let dpi = max(72, CGFloat(page.resolution))
        return CGRect(
            x: 0,
            y: 0,
            width: CGFloat(page.image.width) / dpi * 72,
            height: CGFloat(page.image.height) / dpi * 72
        )
    }

    static func drawInvisibleText(_ tokens: [OCRToken], in box: CGRect, context: CGContext) {
        guard !tokens.isEmpty else { return }
        context.saveGState()
        context.setTextDrawingMode(.invisible)
        for token in tokens {
            let rect = CGRect(
                x: box.minX + token.boundingBox.minX * box.width,
                y: box.minY + token.boundingBox.minY * box.height,
                width: max(1, token.boundingBox.width * box.width),
                height: max(1, token.boundingBox.height * box.height)
            )
            let fontSize = max(4, rect.height * 0.8)
            let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: token.text, attributes: attributes))
            context.textMatrix = .identity
            context.textPosition = CGPoint(x: rect.minX, y: rect.minY)
            CTLineDraw(line, context)
        }
        context.restoreGState()
    }

    private static func jpegImage(_ image: CGImage, quality: CGFloat) -> CGImage? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination),
              let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
