import CoreGraphics
import Foundation

enum BlankPageDetector {
    static func isBlank(_ image: CGImage, whiteThreshold: Double = 0.94, deviationThreshold: Double = 0.03) -> Bool {
        let sample = 48
        guard let context = CGContext(
            data: nil,
            width: sample,
            height: sample,
            bitsPerComponent: 8,
            bytesPerRow: sample,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return false }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: sample, height: sample))
        context.draw(image, in: CGRect(x: 0, y: 0, width: sample, height: sample))
        guard let data = context.data else { return false }
        let pointer = data.bindMemory(to: UInt8.self, capacity: sample * sample)
        var sum = 0.0
        for index in 0..<(sample * sample) {
            sum += Double(pointer[index]) / 255
        }
        let count = Double(sample * sample)
        let mean = sum / count
        var variance = 0.0
        for index in 0..<(sample * sample) {
            let value = Double(pointer[index]) / 255
            variance += (value - mean) * (value - mean)
        }
        let deviation = (variance / count).squareRoot()
        return mean >= whiteThreshold && deviation <= deviationThreshold
    }
}
