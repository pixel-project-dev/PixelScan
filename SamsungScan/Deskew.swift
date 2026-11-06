import CoreGraphics
import Foundation
import Vision

enum Deskew {
    static func suggestedDegrees(for image: CGImage) -> Double? {
        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = 0.6
        request.maximumObservations = 1
        request.minimumAspectRatio = 0.2
        request.quadratureTolerance = 25
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let rectangle = request.results?.first as? VNRectangleObservation else { return nil }
        let dx = rectangle.topRight.x - rectangle.topLeft.x
        let dy = rectangle.topRight.y - rectangle.topLeft.y
        guard dx != 0 || dy != 0 else { return nil }
        let degrees = atan2(dy, dx) * 180 / .pi
        guard abs(degrees) >= 0.4, abs(degrees) <= 12 else { return nil }
        return -degrees
    }
}
