import CoreImage
import Foundation
import ImageIO

enum ImagePipeline {
    static func render(_ page: EditablePage, fileURL: URL, maxPixelSize: Int? = nil) throws -> CGImage {
        guard var image = load(fileURL, maxPixelSize: maxPixelSize) else {
            throw ScanFailure.badImage
        }
        if normalizedRotation(page.rotation) != 0 {
            image = try rotate(image, degrees: CGFloat(normalizedRotation(page.rotation)))
        }
        if abs(page.deskewDegrees) > 0.05 {
            image = try rotate(image, degrees: CGFloat(page.deskewDegrees))
        }
        if let crop = page.crop?.clamped(), crop.width > 0.01, crop.height > 0.01 {
            image = try cropImage(image, normalizedTopLeft: crop)
        }
        if abs(page.brightness) > 0.001 || abs(page.contrast - 1) > 0.001 {
            image = try adjust(image, brightness: page.brightness, contrast: page.contrast)
        }
        return image
    }

    static func load(_ url: URL, maxPixelSize: Int?) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        if let maxPixelSize {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            if let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return thumbnail
            }
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    static func rotate(_ image: CGImage, degrees: CGFloat) throws -> CGImage {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        if abs(normalized) < 0.01 { return image }
        let radians = normalized * .pi / 180
        let swap = abs(abs(normalized) - 90) < 0.01 || abs(abs(normalized) - 270) < 0.01
        let width: Int
        let height: Int
        if swap {
            width = image.height
            height = image.width
        } else if abs(abs(normalized) - 180) < 0.01 {
            width = image.width
            height = image.height
        } else {
            let absCos = abs(cos(radians))
            let absSin = abs(sin(radians))
            width = Int(ceil(CGFloat(image.width) * absCos + CGFloat(image.height) * absSin))
            height = Int(ceil(CGFloat(image.width) * absSin + CGFloat(image.height) * absCos))
        }
        guard let context = context(width: width, height: height) else { throw ScanFailure.badImage }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
        context.rotate(by: radians)
        context.translateBy(x: -CGFloat(image.width) / 2, y: -CGFloat(image.height) / 2)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let result = context.makeImage() else { throw ScanFailure.badImage }
        return result
    }

    static func cropImage(_ image: CGImage, normalizedTopLeft crop: NormalizedRect) throws -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        var rect = CGRect(
            x: crop.x * width,
            y: crop.y * height,
            width: crop.width * width,
            height: crop.height * height
        ).integral
        rect = rect.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        guard rect.width >= 1, rect.height >= 1, let cropped = image.cropping(to: rect) else {
            throw ScanFailure.badImage
        }
        return cropped
    }

    static func adjust(_ image: CGImage, brightness: Double, contrast: Double) throws -> CGImage {
        let input = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIColorControls") else { throw ScanFailure.badImage }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(1.0, forKey: kCIInputSaturationKey)
        guard let output = filter.outputImage else { throw ScanFailure.badImage }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let rendered = context.createCGImage(output, from: output.extent) else {
            throw ScanFailure.badImage
        }
        return rendered
    }

    static func makeSolidImage(width: Int, height: Int, color: (CGFloat, CGFloat, CGFloat)) -> CGImage? {
        guard let context = context(width: width, height: height) else { return nil }
        context.setFillColor(CGColor(red: color.0, green: color.1, blue: color.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ScanFailure.exportFailed(url.lastPathComponent)
        }
    }

    private static func context(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    private static func normalizedRotation(_ degrees: Int) -> Int {
        let value = degrees % 360
        return value >= 0 ? value : value + 360
    }
}
