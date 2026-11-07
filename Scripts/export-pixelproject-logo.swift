import AppKit
import CoreText
import Foundation

struct Piece {
    var path: CGPath
    var role: String
}

enum BrandExport {
    static let background = "#11131a"
    static let text = "#f7f8f4"
    static let accent = "#bdff65"
    static let lightBackground = "#f5f7fa"
    static let lightText = "#171c26"
    static let lightAccent = "#3d6410"

    static func run() throws {
        let pieces = layout()
        let union = pieces.reduce(CGRect.null) { $0.union($1.path.boundingBoxOfPath) }
        let pad: CGFloat = 28
        let width = union.width + pad * 2
        let height = union.height + pad * 2
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("branding")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let preview = root.appendingPathComponent("previews")
        try FileManager.default.createDirectory(at: preview, withIntermediateDirectories: true)

        func svgPoint(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x - union.minX + pad, y: union.maxY - point.y + pad)
        }
        let mark = pathData(pieces.filter { $0.role == "mark" }, svgPoint)
        let pixel = pathData(pieces.filter { $0.role == "pixel" }, svgPoint)
        let project = pathData(pieces.filter { $0.role == "project" }, svgPoint)

        try writeSVG(named: "pixelproject-logo.svg", width: width, height: height, background: background, pixel: text, grid: accent, project: accent, mark: mark, pixelPath: pixel, projectPath: project, to: root)
        try writeSVG(named: "pixelproject-logo-transparent.svg", width: width, height: height, background: nil, pixel: text, grid: accent, project: accent, mark: mark, pixelPath: pixel, projectPath: project, to: root)
        try writeSVG(named: "pixelproject-logo-dark.svg", width: width, height: height, background: background, pixel: text, grid: accent, project: accent, mark: mark, pixelPath: pixel, projectPath: project, to: root)
        try writeSVG(named: "pixelproject-logo-light.svg", width: width, height: height, background: lightBackground, pixel: lightText, grid: accent, project: lightAccent, mark: mark, pixelPath: pixel, projectPath: project, to: root, note: "The word pixel uses the website light text color. The word project. uses the website light accent because the neon accent fails text contrast on the light background. The pixel grid keeps the neon accent.")
        try writeMark(mark, width: width, height: height, to: root)

        let asset = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("PixelScan/Assets.xcassets/PixelProjectLogo.imageset")
        try FileManager.default.createDirectory(at: asset, withIntermediateDirectories: true)
        try writePDF(pieces: pieces, union: union, pad: pad, pixel: NSColor(srgbRed: 0xf7/255, green: 0xf8/255, blue: 0xf4/255, alpha: 1), accent: NSColor(srgbRed: 0xbd/255, green: 0xff/255, blue: 0x65/255, alpha: 1), background: nil, to: asset.appendingPathComponent("PixelProjectLogoDark.pdf"))
        try writePDF(pieces: pieces, union: union, pad: pad, pixel: NSColor(srgbRed: 0x17/255, green: 0x1c/255, blue: 0x26/255, alpha: 1), accent: NSColor(srgbRed: 0x3d/255, green: 0x64/255, blue: 0x10/255, alpha: 1), grid: NSColor(srgbRed: 0xbd/255, green: 0xff/255, blue: 0x65/255, alpha: 1), background: nil, to: asset.appendingPathComponent("PixelProjectLogoLight.pdf"))
        try renderPreviews(pieces: pieces, union: union, pad: pad, to: preview)
        print("viewBox 0 0 \(fmt(width)) \(fmt(height))")
        print("font \(font(64).fontName)")
    }

    static func layout() -> [Piece] {
        let markFont = font(64)
        let wordFont = font(44.8)
        let mark = glyphs("▦", font: markFont, role: "mark", kern: 0)
        let pixel = glyphs("pixel", font: wordFont, role: "pixel", kern: -0.045 * 44.8)
        let project = glyphs("project.", font: wordFont, role: "project", kern: -0.045 * 44.8)
        let markBounds = union(mark.pieces)
        let pixelBounds = union(pixel.pieces)
        let projectBounds = union(project.pieces)
        let gap = 64 * (9.0 / 32.0)
        var markShift = CGAffineTransform(translationX: -markBounds.minX, y: -markBounds.midY)
        var pixelShift = CGAffineTransform(translationX: -pixelBounds.minX + markBounds.width + gap, y: -pixelBounds.midY)
        var projectShift = CGAffineTransform(translationX: -projectBounds.minX + markBounds.width + gap + pixel.advance, y: -projectBounds.midY)
        return mark.pieces.map { Piece(path: $0.path.copy(using: &markShift) ?? $0.path, role: $0.role) }
            + pixel.pieces.map { Piece(path: $0.path.copy(using: &pixelShift) ?? $0.path, role: $0.role) }
            + project.pieces.map { Piece(path: $0.path.copy(using: &projectShift) ?? $0.path, role: $0.role) }
    }

    static func glyphs(_ string: String, font: NSFont, role: String, kern: CGFloat) -> (pieces: [Piece], advance: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: kern
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let advance = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        var pieces: [Piece] = []
        for run in runs {
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
            let count = CTRunGetGlyphCount(run)
            var glyphs = Array(repeating: CGGlyph(), count: count)
            var positions = Array(repeating: CGPoint(), count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)
            for index in 0..<count {
                var transform = CGAffineTransform(translationX: positions[index].x, y: positions[index].y)
                guard let path = CTFontCreatePathForGlyph(runFont, glyphs[index], &transform) else { continue }
                pieces.append(Piece(path: path, role: role))
            }
        }
        return (pieces, advance)
    }

    static func font(_ size: CGFloat) -> NSFont {
        let base = NSFont.systemFont(ofSize: size)
        let descriptor = base.fontDescriptor.addingAttributes([
            .traits: [NSFontDescriptor.TraitKey.weight: 0.48]
        ])
        return NSFont(descriptor: descriptor, size: size) ?? NSFont.systemFont(ofSize: size, weight: .bold)
    }

    static func union(_ pieces: [Piece]) -> CGRect {
        pieces.reduce(CGRect.null) { $0.union($1.path.boundingBoxOfPath) }
    }

    static func pathData(_ pieces: [Piece], _ map: (CGPoint) -> CGPoint) -> String {
        var data = ""
        for piece in pieces {
            piece.path.applyWithBlock { element in
                let points = element.pointee.points
                switch element.pointee.type {
                case .moveToPoint:
                    let p = map(points[0])
                    data += "M\(fmt(p.x)) \(fmt(p.y))"
                case .addLineToPoint:
                    let p = map(points[0])
                    data += "L\(fmt(p.x)) \(fmt(p.y))"
                case .addQuadCurveToPoint:
                    let c = map(points[0])
                    let p = map(points[1])
                    data += "Q\(fmt(c.x)) \(fmt(c.y)) \(fmt(p.x)) \(fmt(p.y))"
                case .addCurveToPoint:
                    let c1 = map(points[0])
                    let c2 = map(points[1])
                    let p = map(points[2])
                    data += "C\(fmt(c1.x)) \(fmt(c1.y)) \(fmt(c2.x)) \(fmt(c2.y)) \(fmt(p.x)) \(fmt(p.y))"
                case .closeSubpath:
                    data += "Z"
                @unknown default:
                    break
                }
            }
        }
        return data
    }

    static func writeSVG(named name: String, width: CGFloat, height: CGFloat, background: String?, pixel: String, grid: String, project: String, mark: String, pixelPath: String, projectPath: String, to root: URL, note: String? = nil) throws {
        var body = ""
        if let background {
            body += "<rect width=\"100%\" height=\"100%\" fill=\"\(background)\"/>"
        }
        body += "<path fill=\"\(grid)\" d=\"\(mark)\"/>"
        body += "<path fill=\"\(pixel)\" d=\"\(pixelPath)\"/>"
        body += "<path fill=\"\(project)\" d=\"\(projectPath)\"/>"
        let desc = note ?? "PixelProject wordmark pixelproject. reconstructed from the website brand: system font outlines, no embedded font."
        let svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(fmt(width)) \(fmt(height))" role="img">
        <title>pixelproject.</title>
        <desc>\(desc)</desc>
        \(body)
        </svg>
        """
        try svg.write(to: root.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }

    static func writeMark(_ mark: String, width: CGFloat, height: CGFloat, to root: URL) throws {
        let piece = layout().first { $0.role == "mark" }!
        let bounds = piece.path.boundingBoxOfPath
        let pad: CGFloat = 4
        let map: (CGPoint) -> CGPoint = { point in
            CGPoint(x: point.x - bounds.minX + pad, y: bounds.maxY - point.y + pad)
        }
        let data = pathData([piece], map)
        let svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(fmt(bounds.width + pad * 2)) \(fmt(bounds.height + pad * 2))" role="img">
        <title>PixelProject</title>
        <desc>Square pixel grid used as the PixelProject mark. Fill \(accent).</desc>
        <path fill="\(accent)" d="\(data)"/>
        </svg>
        """
        try svg.write(to: root.appendingPathComponent("pixelproject-mark.svg"), atomically: true, encoding: .utf8)
        _ = width
        _ = height
        _ = mark
    }

    static func writePDF(pieces: [Piece], union: CGRect, pad: CGFloat, pixel: NSColor, accent: NSColor, grid: NSColor? = nil, background: NSColor?, to url: URL) throws {
        let width = union.width + pad * 2
        let height = union.height + pad * 2
        var media = CGRect(x: 0, y: 0, width: width, height: height)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &media, nil) else {
            throw NSError(domain: "BrandExport", code: 1)
        }
        context.beginPDFPage(nil)
        if let background {
            context.setFillColor(background.cgColor)
            context.fill(media)
        }
        var shift = CGAffineTransform(translationX: -union.minX + pad, y: -union.minY + pad)
        for piece in pieces {
            guard let path = piece.path.copy(using: &shift) else { continue }
            let color: NSColor
            if piece.role == "pixel" {
                color = pixel
            } else if piece.role == "mark" {
                color = grid ?? accent
            } else {
                color = accent
            }
            context.setFillColor(color.cgColor)
            context.addPath(path)
            context.fillPath()
        }
        context.endPDFPage()
        context.closePDF()
    }

    static func renderPreviews(pieces: [Piece], union: CGRect, pad: CGFloat, to directory: URL) throws {
        for width in [128, 256, 512, 1024] {
            let fullWidth = union.width + pad * 2
            let fullHeight = union.height + pad * 2
            let scale = CGFloat(width) / fullWidth
            let height = Int((fullHeight * scale).rounded())
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { continue }
            context.setFillColor(NSColor(srgbRed: 0x11/255, green: 0x13/255, blue: 0x1a/255, alpha: 1).cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -union.minX + pad, y: -union.minY + pad)
            for piece in pieces {
                let color = piece.role == "pixel"
                    ? NSColor(srgbRed: 0xf7/255, green: 0xf8/255, blue: 0xf4/255, alpha: 1)
                    : NSColor(srgbRed: 0xbd/255, green: 0xff/255, blue: 0x65/255, alpha: 1)
                context.setFillColor(color.cgColor)
                context.addPath(piece.path)
                context.fillPath()
            }
            guard let image = context.makeImage() else { continue }
            let rep = NSBitmapImageRep(cgImage: image)
            let png = rep.representation(using: .png, properties: [:])!
            try png.write(to: directory.appendingPathComponent("logo-\(width).png"))
        }
    }

    static func fmt(_ value: CGFloat) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

do {
    try BrandExport.run()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
