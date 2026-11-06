import CoreGraphics
import Foundation
import Vision

struct OCRToken: Equatable, Sendable {
    var text: String
    var boundingBox: CGRect
}

enum OCRService {
    static func recognize(image: CGImage, languages: [String] = ["de-DE", "en-US"]) throws -> [OCRToken] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        let usable = languages.filter { supported.contains($0) }
        if !usable.isEmpty {
            request.recognitionLanguages = usable
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        let observations = request.results ?? []
        return observations.compactMap { observation in
            guard let text = observation.topCandidates(1).first?.string, !text.isEmpty else { return nil }
            return OCRToken(text: text, boundingBox: observation.boundingBox)
        }
    }
}
