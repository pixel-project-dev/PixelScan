import Foundation

enum ScanCommandBuilder {
    static func probeArguments(deviceName: String) -> [String] {
        ["-d", deviceName, "--format=png", "-A"]
    }

    static func scanArguments(for request: ScanRequest) throws -> [String] {
        guard request.capabilities.sources.contains(request.source) else {
            throw ScanFailure.deviceError("source")
        }
        guard request.capabilities.modes.contains(request.mode) else {
            throw ScanFailure.deviceError("mode")
        }
        guard request.capabilities.resolutions.contains(request.resolution) else {
            throw ScanFailure.deviceError("resolution")
        }
        let area = request.area.clamped(
            maxWidth: request.capabilities.maxWidthMM,
            maxHeight: request.capabilities.maxHeightMM
        )
        guard area.width >= 1, area.height >= 1 else {
            throw ScanFailure.deviceError("geometry")
        }
        guard request.outputDirectory.isFileURL else {
            throw ScanFailure.exportFailed("output")
        }

        var arguments = [
            "-d", request.deviceName,
            "--format=png",
            "--progress",
            "--source=\(request.source)",
            "--resolution=\(request.resolution)",
            "--mode=\(request.mode)",
            "-l", formatMM(area.left),
            "-t", formatMM(area.top),
            "-x", formatMM(area.width),
            "-y", formatMM(area.height)
        ]

        if request.batch {
            let pattern = request.outputDirectory.appendingPathComponent("page-%03d.png").path
            arguments.append("--batch=\(pattern)")
            arguments.append("--batch-print")
            arguments.append("--batch-start=1")
        } else {
            let file = request.outputDirectory.appendingPathComponent("scan.png").path
            arguments.append("--output-file=\(file)")
        }
        return arguments
    }

    static func formatMM(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
