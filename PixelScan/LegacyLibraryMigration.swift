import Foundation

enum LegacyLibraryMigration {
    static let itemNames = ["library.json", "session.json", "scan.log", "pages", "inbox", "sane.d"]

    struct Report: Equatable {
        var copied: [String]
        var skipped: [String]
        var missing: [String]
        var sourcePreserved: Bool
        var failure: String?
    }

    static func migrate(from source: URL, to destination: URL, fileManager: FileManager = .default) -> Report {
        var report = Report(copied: [], skipped: [], missing: [], sourcePreserved: true, failure: nil)
        let sourceExisted = fileManager.fileExists(atPath: source.path)
        guard sourceExisted else { return report }
        guard source.standardizedFileURL.path != destination.standardizedFileURL.path else {
            report.failure = "source and destination are the same folder"
            report.sourcePreserved = true
            return report
        }

        do {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        } catch {
            report.failure = error.localizedDescription
            report.sourcePreserved = fileManager.fileExists(atPath: source.path)
            return report
        }

        for name in itemNames {
            let from = source.appendingPathComponent(name)
            let to = destination.appendingPathComponent(name)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: from.path, isDirectory: &isDirectory) else {
                report.missing.append(name)
                continue
            }
            if fileManager.fileExists(atPath: to.path) {
                if isDirectory.boolValue, isEmptyDirectory(to, fileManager), !isEmptyDirectory(from, fileManager) {
                    do {
                        try copyContents(of: from, to: to, fileManager: fileManager)
                        report.copied.append(name)
                    } catch {
                        report.failure = error.localizedDescription
                        break
                    }
                } else {
                    report.skipped.append(name)
                }
                continue
            }
            do {
                try fileManager.copyItem(at: from, to: to)
                report.copied.append(name)
            } catch {
                report.failure = error.localizedDescription
                break
            }
        }

        report.sourcePreserved = fileManager.fileExists(atPath: source.path)
        return report
    }

    private static func isEmptyDirectory(_ url: URL, _ fileManager: FileManager) -> Bool {
        guard let children = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return false
        }
        return children.isEmpty
    }

    private static func copyContents(of source: URL, to destination: URL, fileManager: FileManager) throws {
        let children = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
        for child in children {
            let target = destination.appendingPathComponent(child.lastPathComponent)
            if fileManager.fileExists(atPath: target.path) { continue }
            try fileManager.copyItem(at: child, to: target)
        }
    }
}
