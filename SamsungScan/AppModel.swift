import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
@Observable
final class AppModel {
    var library: ScannerLibrary
    var sane: SANEInstallation
    var capabilities: ScannerCapabilities?
    var connection: ConnectionState = .unknown
    var document = PageDocument(pages: [])
    var selectedPageID: UUID?
    var isScanning = false
    var progress: Double?
    var statusText = ""
    var lastError = ""
    var showError = false
    var showAddScanner = false
    var showExport = false
    var showSetup = false
    var showWizard = false
    var showPreviewArea = false
    var showNewProfile = false
    var showRenameScanner = false
    var showClearConfirmation = false
    var showBlankConfirmation = false
    var isCropping = false
    var previewImage: NSImage?
    var previewSelection: CGRect?
    var blankIDs: [UUID] = []
    var installLog = ""
    var isInstalling = false
    var exportSkipBlanks = false
    let discovery = ScannerDiscovery()

    @ObservationIgnored private let store: LibraryStore
    @ObservationIgnored private var driver: ScanimageDriver
    @ObservationIgnored private var displayCache: [String: NSImage] = [:]
    @ObservationIgnored private var didStart = false

    init(store: LibraryStore? = nil) {
        let resolved = store ?? LibraryStore(layout: .live())
        self.store = resolved
        let loaded = resolved.loadLibrary()
        library = loaded
        let installation = SANEInstallation.locate(overridePath: loaded.scanimageOverridePath)
        sane = installation
        driver = ScanimageDriver(installation: installation)
    }

    var selectedPage: EditablePage? {
        guard let selectedPageID else { return nil }
        return document.pages.first { $0.id == selectedPageID }
    }

    var canScan: Bool {
        !isScanning && sane.isUsable && library.selectedScanner != nil && capabilities != nil && connection == .ready
    }

    var canPreview: Bool {
        canScan && capabilities?.sources.contains("Flatbed") == true
    }

    func startup() async {
        guard !didStart else { return }
        didStart = true
        try? store.layout.prepare()
        await reloadBackend()
        let session = store.loadSession()
        document.pages = session.pages
        selectedPageID = session.pages.contains { $0.id == session.selectedPageID } ? session.selectedPageID : session.pages.first?.id
        recoverInbox()
        if library.selectedScannerID == nil {
            library.selectedScannerID = library.scanners.max { lhs, rhs in
                (lhs.lastUsedAt ?? .distantPast) < (rhs.lastUsedAt ?? .distantPast)
            }?.id
        }
        await refreshConnection()
        if library.scanners.isEmpty && !library.setupCompleted {
            showWizard = true
        }
    }

    func shutdown() {
        driver.cancel()
        persist()
        saveSession()
    }

    func selectScanner(_ id: UUID?) {
        library.selectedScannerID = id
        capabilities = nil
        connection = .unknown
        persist()
        Task { await refreshConnection() }
    }

    func selectProfile(_ id: UUID?) {
        guard let id, let profile = library.profiles.first(where: { $0.id == id }) else { return }
        library.selectedProfileID = id
        library.settings.source = profile.source
        library.settings.resolution = profile.resolution
        library.settings.mode = profile.mode
        library.settings.paper = profile.paper
        library.settings.customArea = nil
        library.settings.exportFormat = profile.exportFormat
        library.settings.ocr = profile.ocr
        library.settings.removeBlankPages = profile.removeBlankPages
        normalizeSettings()
        persist()
    }

    func addScanner(name: String, host: String, port: Int, backendID: String = DeviceAddress.samsungNetwork, secure: Bool = false) {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard DeviceName.isValidHost(trimmedHost), (1...65535).contains(port) else {
            present(ScanFailure.invalidAddress)
            return
        }
        guard (try? DeviceAddress.make(backendID: backendID, host: trimmedHost, port: port, secure: secure)) != nil else {
            present(ScanFailure.unsupportedBackend)
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = ScannerConfiguration(
            name: trimmedName.isEmpty ? trimmedHost : trimmedName,
            host: trimmedHost,
            port: port,
            backendID: backendID,
            secureConnection: secure
        )
        library.scanners.append(scanner)
        library.selectedScannerID = scanner.id
        persist()
        store.appendLog("added scanner \(scanner.name) \(scanner.host):\(scanner.port)")
        Task { await refreshConnection() }
    }

    func renameSelectedScanner(to name: String) {
        guard let id = library.selectedScannerID, let index = library.scanners.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        library.scanners[index].name = trimmed
        persist()
    }

    func setConnectionMethod(_ backendID: String) {
        guard let id = library.selectedScannerID, let index = library.scanners.firstIndex(where: { $0.id == id }) else { return }
        let current = library.scanners[index]
        var updated = current
        let previousDefault = DeviceAddress.defaultPort(for: current.backendID, secure: current.secureConnection)
        updated.backendID = backendID
        if backendID == DeviceAddress.webScan {
            updated.secureConnection = current.secureConnection
        }
        if current.port == previousDefault {
            updated.port = DeviceAddress.defaultPort(for: backendID, secure: updated.secureConnection)
        }
        library.scanners[index] = updated
        capabilities = nil
        persist()
        store.appendLog("connection method \(backendID) \(updated.host):\(updated.port)")
        Task { await refreshConnection() }
    }

    func finishSetup(startPreview: Bool) {
        library.setupCompleted = true
        showWizard = false
        persist()
        if startPreview {
            preview()
        }
    }

    func removeSelectedScanner() {
        guard let id = library.selectedScannerID else { return }
        library.scanners.removeAll { $0.id == id }
        library.selectedScannerID = library.scanners.first?.id
        capabilities = nil
        connection = .unknown
        persist()
        Task { await refreshConnection() }
    }

    func saveSettingsToSelectedProfile() {
        guard let id = library.selectedProfileID, let index = library.profiles.firstIndex(where: { $0.id == id }) else { return }
        library.profiles[index].source = library.settings.source
        library.profiles[index].resolution = library.settings.resolution
        library.profiles[index].mode = library.settings.mode
        library.profiles[index].paper = library.settings.paper
        library.profiles[index].exportFormat = library.settings.exportFormat
        library.profiles[index].ocr = library.settings.ocr
        library.profiles[index].removeBlankPages = library.settings.removeBlankPages
        persist()
    }

    func createProfile(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            presentMessage(L10n.text("A profile needs a name."))
            return
        }
        let profile = ScanProfile(
            id: UUID(),
            localizationKey: nil,
            customName: trimmed,
            source: library.settings.source,
            resolution: library.settings.resolution,
            mode: library.settings.mode,
            paper: library.settings.paper,
            exportFormat: library.settings.exportFormat,
            ocr: library.settings.ocr,
            removeBlankPages: library.settings.removeBlankPages
        )
        library.profiles.append(profile)
        library.selectedProfileID = profile.id
        persist()
    }

    func deleteSelectedProfile() {
        guard library.profiles.count > 1, let id = library.selectedProfileID else {
            presentMessage(L10n.text("At least one profile has to stay."))
            return
        }
        library.profiles.removeAll { $0.id == id }
        library.selectedProfileID = library.profiles.first?.id
        if let id = library.selectedProfileID {
            selectProfile(id)
        }
    }

    func restoreDefaultProfiles() {
        for preset in ScanProfile.defaults {
            if let index = library.profiles.firstIndex(where: { $0.id == preset.id }) {
                library.profiles[index] = preset
            } else {
                library.profiles.insert(preset, at: 0)
            }
        }
        library.selectedProfileID = BuiltInProfile.document
        selectProfile(BuiltInProfile.document)
    }

    func refreshConnection() async {
        guard let scanner = library.selectedScanner else {
            connection = .unknown
            capabilities = nil
            return
        }
        if !sane.isUsable {
            connection = .missingBackend
            capabilities = nil
            return
        }
        if scanner.backendID == DeviceAddress.samsungNetwork, sane.xeroxBackendEnabled == false {
            connection = .backendDisabled
        }
        guard BackendAvailability.libraryIsPresent(scanner.backendID, installedLibraries: sane.installedLibraries) else {
            capabilities = nil
            connection = .failed(ScanFailure.backendNotInstalled.message)
            statusText = ScanFailure.backendNotInstalled.message
            return
        }
        connection = .checking
        statusText = L10n.text("Checking the connection…")
        guard let deviceName = try? DeviceAddress.make(
            backendID: scanner.backendID,
            host: scanner.host,
            port: scanner.port,
            secure: scanner.secureConnection
        ) else {
            present(ScanFailure.invalidAddress)
            return
        }
        let tcp = await TCPProbe.check(host: scanner.host, port: scanner.port)
        statusText = L10n.text("Reading scanner options…")
        let probed = await driver.probe(deviceName: deviceName)
        switch probed {
        case .success(let found):
            capabilities = found
            connection = .ready
            normalizeSettings()
            statusText = L10n.text("Ready")
            store.appendLog("ready \(deviceName) sources=\(found.sources.joined(separator: ","))")
        case .failure(let failure):
            capabilities = nil
            if case .failure(let tcpFailure) = tcp {
                connection = .failed(tcpFailure.message)
                statusText = tcpFailure.message
                store.appendLog("probe tcp failed \(scanner.host):\(scanner.port) \(tcpFailure.message)")
            } else {
                connection = .failed(failure.message)
                statusText = failure.message
                store.appendLog("probe failed \(failure.message)")
            }
        }
    }

    func scan() {
        Task { await runScan(preview: false) }
    }

    func preview() {
        Task { await runScan(preview: true) }
    }

    func cancel() {
        driver.cancel()
        statusText = L10n.text("Cancel scan")
    }

    func updateSetting(_ body: (inout ScanSettings) -> Void) {
        body(&library.settings)
        if library.settings.jpegQuality < 0.4 { library.settings.jpegQuality = 0.4 }
        if library.settings.jpegQuality > 0.95 { library.settings.jpegQuality = 0.95 }
        persist()
    }

    func setPaper(_ paper: PaperFormat) {
        library.settings.paper = paper
        library.settings.customArea = nil
        persist()
    }

    func clearCustomArea() {
        library.settings.customArea = nil
        persist()
    }

    func rotateSelected(clockwise: Bool) {
        guard let id = selectedPageID else { return }
        document.rotate(id: id, clockwise: clockwise)
        saveSession()
    }

    func deleteSelectedPage() {
        guard let id = selectedPageID else { return }
        deletePage(id)
    }

    func moveSelected(offset: Int) {
        guard let id = selectedPageID, let index = document.index(of: id) else { return }
        document.move(id, to: index + offset)
        saveSession()
    }

    func setBrightness(_ value: Double) {
        guard let id = selectedPageID else { return }
        document.update(id) { $0.brightness = min(0.5, max(-0.5, value)) }
        saveSession()
    }

    func setContrast(_ value: Double) {
        guard let id = selectedPageID else { return }
        document.update(id) { $0.contrast = min(1.8, max(0.5, value)) }
        saveSession()
    }

    func setCrop(_ rect: CGRect?) {
        guard let id = selectedPageID else { return }
        if let rect, rect.width > 0.02, rect.height > 0.02 {
            document.update(id) {
                $0.crop = NormalizedRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height).clamped()
            }
        }
        saveSession()
    }

    func resetAdjustments() {
        guard let id = selectedPageID else { return }
        document.update(id) {
            $0.rotation = 0
            $0.crop = nil
            $0.deskewDegrees = 0
            $0.brightness = 0
            $0.contrast = 1
        }
        saveSession()
    }

    func autoAlignSelected() {
        guard let page = selectedPage else { return }
        var clean = page
        clean.deskewDegrees = 0
        clean.crop = nil
        clean.brightness = 0
        clean.contrast = 1
        guard let image = try? ImagePipeline.render(clean, fileURL: fileURL(for: clean), maxPixelSize: 1400) else {
            present(ScanFailure.badImage)
            return
        }
        guard let degrees = Deskew.suggestedDegrees(for: image) else {
            presentMessage(L10n.text("Auto alignment did not find a reliable page angle."))
            return
        }
        document.update(page.id) { $0.deskewDegrees = degrees }
        statusText = L10n.text("Auto Align")
        saveSession()
    }

    func detectBlankPages() {
        var found: [UUID] = []
        for page in document.pages {
            guard let image = try? ImagePipeline.render(page, fileURL: fileURL(for: page), maxPixelSize: 500) else { continue }
            if BlankPageDetector.isBlank(image) {
                found.append(page.id)
            }
        }
        blankIDs = found
        if found.isEmpty {
            statusText = L10n.text("Detect Blank Pages")
        } else {
            showBlankConfirmation = true
        }
    }

    func removeConfirmedBlankPages() {
        for id in blankIDs {
            deletePage(id, persistAfter: false)
        }
        blankIDs = []
        saveSession()
    }

    func clearPages() {
        for page in document.pages {
            try? FileManager.default.removeItem(at: fileURL(for: page))
        }
        document.pages = []
        selectedPageID = nil
        displayCache.removeAll()
        saveSession()
    }

    func thumbnail(for page: EditablePage) -> NSImage? {
        let crop = page.crop
        let key = "\(page.id)|\(page.rotation)|\(page.deskewDegrees)|\(crop?.x ?? 0)|\(crop?.y ?? 0)|\(crop?.width ?? 0)|\(crop?.height ?? 0)|\(page.brightness)|\(page.contrast)"
        if let cached = displayCache[key] { return cached }
        guard let image = try? ImagePipeline.render(page, fileURL: fileURL(for: page), maxPixelSize: 1600) else { return nil }
        let rendered = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        if displayCache.count > 40 { displayCache.removeAll() }
        displayCache[key] = rendered
        return rendered
    }

    func applyPreviewSelection() {
        guard let capabilities, let previewSelection else { return }
        let rect = NormalizedRect(
            x: previewSelection.origin.x,
            y: previewSelection.origin.y,
            width: previewSelection.width,
            height: previewSelection.height
        ).clamped()
        guard rect.width > 0.02, rect.height > 0.02 else { return }
        library.settings.customArea = ScanAreaMM(
            left: rect.x * capabilities.maxWidthMM,
            top: rect.y * capabilities.maxHeightMM,
            width: rect.width * capabilities.maxWidthMM,
            height: rect.height * capabilities.maxHeightMM
        )
        persist()
        showPreviewArea = false
    }

    func scanPreviewSelection() {
        applyPreviewSelection()
        scan()
    }

    func export() {
        let format = library.settings.exportFormat
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowedContentTypes = [format.utType]
        panel.nameFieldStringValue = suggestedName(extension: format.fileExtension)
        if format == .png || format == .jpeg, document.pages.count > 1 {
            panel.message = L10n.text("Additional pages are saved beside this file.")
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await writeExport(to: url, format: format) }
    }

    func openInPreview() {
        Task { await openDocumentInPreview() }
    }

    func revealSelected() {
        guard let page = selectedPage else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fileURL(for: page)])
    }

    func chooseScanimage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/opt/homebrew/bin")
        panel.prompt = L10n.text("Use")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await adoptScanimage(url) }
    }

    func installWithHomebrew() {
        guard !isInstalling else { return }
        Task { await runHomebrewInstall() }
    }

    func enableXeroxBackend() {
        guard let url = sane.dllConfigURL else { return }
        do {
            try SANEInstallation.enableXeroxBackend(at: url)
            store.appendLog("enabled xerox_mfp in \(url.path)")
            Task { await reloadBackend() }
        } catch {
            presentMessage(error.localizedDescription)
        }
    }

    func openDataFolder() {
        try? store.layout.prepare()
        NSWorkspace.shared.open(store.layout.root)
    }

    func openLog() {
        try? store.layout.prepare()
        if !FileManager.default.fileExists(atPath: store.layout.logFile.path) {
            store.appendLog("log created")
        }
        NSWorkspace.shared.open(store.layout.logFile)
    }

    func openHomebrewWebsite() {
        if let url = URL(string: "https://brew.sh") {
            NSWorkspace.shared.open(url)
        }
    }

    func copyError() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lastError, forType: .string)
    }

    func fileURL(for page: EditablePage) -> URL {
        store.layout.sessionPages.appendingPathComponent(page.fileName)
    }

    private func runScan(preview: Bool) async {
        guard let scanner = library.selectedScanner, let capabilities else {
            presentMessage(L10n.text("Choose a scanner first."))
            return
        }
        guard sane.isUsable, let _ = sane.scanimageURL else {
            showSetup = true
            present(ScanFailure.backendMissing)
            return
        }
        guard let deviceName = try? DeviceAddress.make(
            backendID: scanner.backendID,
            host: scanner.host,
            port: scanner.port,
            secure: scanner.secureConnection
        ) else {
            present(ScanFailure.invalidAddress)
            return
        }
        let source: String
        let resolution: Int
        let mode: String
        let area: ScanAreaMM
        let batch: Bool
        if preview {
            guard capabilities.sources.contains("Flatbed") else { return }
            source = "Flatbed"
            resolution = capabilities.resolutions.filter { $0 <= 100 }.max() ?? capabilities.resolutions.min() ?? 75
            mode = capabilities.modes.contains("Color") ? "Color" : (capabilities.modes.first ?? "Color")
            area = ScanAreaMM(left: 0, top: 0, width: capabilities.maxWidthMM, height: capabilities.maxHeightMM)
            batch = false
        } else {
            source = library.settings.source
            resolution = library.settings.resolution
            mode = library.settings.mode
            area = resolvedArea(capabilities)
            batch = source != "Flatbed"
        }
        emptyInbox()
        let request = ScanRequest(
            deviceName: deviceName,
            source: source,
            resolution: resolution,
            mode: mode,
            area: area,
            outputDirectory: store.layout.inbox,
            batch: batch,
            capabilities: capabilities
        )
        markUsed(scanner.id)
        isScanning = true
        progress = 0
        statusText = preview ? L10n.text("Preview scan") : L10n.text("Starting the scan…")
        store.appendLog("scan start preview=\(preview) \(deviceName) \(source) \(resolution) \(mode)")
        let outcome = await driver.scan(request: request) { [weak self] fraction in
            Task { @MainActor in
                self?.progress = fraction
                self?.statusText = L10n.text("Scanning…")
            }
        }
        let imported = importFiles(outcome.files, source: source, resolution: resolution)
        isScanning = false
        progress = nil
        if preview, let first = imported.first, let image = thumbnail(for: first) {
            previewImage = image
            previewSelection = nil
            showPreviewArea = true
            deletePage(first.id)
            statusText = L10n.text("Drag a rectangle to choose the scan area.")
        } else if !preview {
            if !library.settings.append {
                clearPages()
            }
            var kept = imported
            if library.settings.removeBlankPages {
                let blanks = kept.filter { page in
                    guard let image = try? ImagePipeline.render(page, fileURL: fileURL(for: page), maxPixelSize: 400) else { return false }
                    return BlankPageDetector.isBlank(image)
                }
                if !blanks.isEmpty && blanks.count < kept.count {
                    for page in blanks {
                        try? FileManager.default.removeItem(at: fileURL(for: page))
                    }
                    kept.removeAll { page in blanks.contains { $0.id == page.id } }
                    statusText = L10n.format("Removed %lld blank pages.", Int64(blanks.count))
                } else if !blanks.isEmpty {
                    statusText = L10n.text("All scanned pages look blank. They were kept.")
                }
            }
            document.pages.append(contentsOf: kept)
            selectedPageID = kept.last?.id ?? selectedPageID
            saveSession()
            if kept.count > 0 && (statusText == L10n.text("Scanning…") || statusText == L10n.text("Starting the scan…")) {
                statusText = L10n.format("Scanned %lld pages.", Int64(kept.count))
            } else if kept.isEmpty && outcome.warning == nil {
                statusText = L10n.text("The scan ended early. Pages that were already scanned are kept.")
            }
        }
        if let warning = outcome.warning {
            store.appendLog("scan warning \(warning.message) files=\(outcome.files.count)")
            if outcome.files.isEmpty || warning != .cancelled && preview {
                present(warning)
            } else if !outcome.files.isEmpty {
                present(warning)
            } else {
                present(warning)
            }
        } else {
            store.appendLog("scan finished files=\(outcome.files.count)")
        }
        emptyInbox()
    }

    private func writeExport(to url: URL, format: ExportFormat) async {
        statusText = L10n.text("Writing the file…")
        do {
            var rendered: [RenderedPage] = []
            for page in document.pages {
                let image = try ImagePipeline.render(page, fileURL: fileURL(for: page))
                if exportSkipBlanks && BlankPageDetector.isBlank(image) { continue }
                var tokens: [OCRToken] = []
                if format == .pdf && library.settings.ocr {
                    statusText = L10n.text("Recognizing text…")
                    tokens = try await recognize(image)
                }
                rendered.append(RenderedPage(image: image, resolution: page.resolution, tokens: tokens))
            }
            guard !rendered.isEmpty else {
                presentMessage(L10n.text("No pages yet"))
                return
            }
            switch format {
            case .pdf:
                try ExportService.exportPDF(
                    pages: rendered,
                    to: url,
                    compression: library.settings.pdfCompression,
                    title: url.deletingPathExtension().lastPathComponent
                )
            case .tiff:
                try ExportService.exportTIFF(images: rendered.map(\.image), to: url)
            case .png, .jpeg:
                if rendered.count == 1 {
                    try ExportService.exportImage(rendered[0].image, to: url, format: format, jpegQuality: library.settings.jpegQuality)
                } else {
                    for (index, page) in rendered.enumerated() {
                        let pageURL = siblingURL(url, index: index, count: rendered.count)
                        try ExportService.exportImage(page.image, to: pageURL, format: format, jpegQuality: library.settings.jpegQuality)
                    }
                }
            }
            statusText = L10n.text("Export complete.")
            store.appendLog("exported \(url.path)")
        } catch let failure as ScanFailure {
            present(failure)
        } catch {
            present(ScanFailure.exportFailed(error.localizedDescription))
        }
    }

    private func recognize(_ image: CGImage) async throws -> [OCRToken] {
        try await Task.detached(priority: .userInitiated) {
            try OCRService.recognize(image: image)
        }.value
    }

    private func openDocumentInPreview() async {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SamsungScan-preview", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Samsung-Scan.pdf")
        do {
            var rendered: [RenderedPage] = []
            for page in document.pages {
                let image = try ImagePipeline.render(page, fileURL: fileURL(for: page), maxPixelSize: 2400)
                rendered.append(RenderedPage(image: image, resolution: page.resolution, tokens: []))
            }
            guard !rendered.isEmpty else { return }
            try ExportService.exportPDF(pages: rendered, to: url, compression: .balanced, title: "Samsung Scan")
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: URL(fileURLWithPath: "/System/Applications/Preview.app"),
                configuration: NSWorkspace.OpenConfiguration()
            ) { application, _ in
                if application == nil {
                    Task { @MainActor in
                        self.presentMessage(L10n.text("Could not open Preview."))
                    }
                }
            }
        } catch let failure as ScanFailure {
            present(failure)
        } catch {
            present(ScanFailure.exportFailed(error.localizedDescription))
        }
    }

    private func importFiles(_ urls: [URL], source: String, resolution: Int) -> [EditablePage] {
        var pages: [EditablePage] = []
        for url in urls {
            let page = EditablePage(fileName: "\(UUID().uuidString).png", source: source, resolution: resolution)
            do {
                try FileManager.default.copyItem(at: url, to: fileURL(for: page))
                pages.append(page)
            } catch {
                store.appendLog("import failed \(error.localizedDescription)")
            }
        }
        return pages
    }

    private func recoverInbox() {
        let recovered = importFiles(ScanimageDriver.validImages(in: store.layout.inbox), source: "Flatbed", resolution: library.settings.resolution)
        guard !recovered.isEmpty else { return }
        document.pages.append(contentsOf: recovered)
        selectedPageID = recovered.last?.id
        saveSession()
        emptyInbox()
        store.appendLog("recovered \(recovered.count) pages")
    }

    private func deletePage(_ id: UUID, persistAfter: Bool = true) {
        if let page = document.pages.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: fileURL(for: page))
        }
        document.remove(id: id)
        if selectedPageID == id {
            selectedPageID = document.pages.last?.id
        }
        if persistAfter { saveSession() }
    }

    private func emptyInbox() {
        let files = (try? FileManager.default.contentsOfDirectory(at: store.layout.inbox, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func resolvedArea(_ capabilities: ScannerCapabilities) -> ScanAreaMM {
        if let custom = library.settings.customArea {
            return custom.clamped(maxWidth: capabilities.maxWidthMM, maxHeight: capabilities.maxHeightMM)
        }
        return library.settings.paper.area(maxWidth: capabilities.maxWidthMM, maxHeight: capabilities.maxHeightMM)
    }

    private func normalizeSettings() {
        guard let capabilities else { return }
        if !capabilities.sources.contains(library.settings.source) {
            library.settings.source = capabilities.sources.contains("Flatbed") ? "Flatbed" : (capabilities.sources.first ?? "Flatbed")
        }
        if !capabilities.modes.contains(library.settings.mode) {
            library.settings.mode = capabilities.modes.contains("Color") ? "Color" : (capabilities.modes.first ?? "Color")
        }
        if !capabilities.resolutions.contains(library.settings.resolution) {
            library.settings.resolution = capabilities.resolutions.min { abs($0 - library.settings.resolution) < abs($1 - library.settings.resolution) } ?? 300
        }
        persist()
    }

    private func markUsed(_ id: UUID) {
        guard let index = library.scanners.firstIndex(where: { $0.id == id }) else { return }
        library.scanners[index].lastUsedAt = Date()
        persist()
    }

    private func reloadBackend() async {
        sane = SANEInstallation.locate(overridePath: library.scanimageOverridePath)
        if let url = sane.scanimageURL {
            sane.version = await SANEInstallation.version(of: url)
        }
        driver.cancel()
        driver = ScanimageDriver(installation: sane)
    }

    private func adoptScanimage(_ url: URL) async {
        let version = await SANEInstallation.version(of: url)
        guard version != nil else {
            present(ScanFailure.backendMissing)
            return
        }
        library.scanimageOverridePath = url.path
        persist()
        await reloadBackend()
        await refreshConnection()
    }

    private func runHomebrewInstall() async {
        guard let brew = sane.homebrewURL else {
            presentMessage(L10n.text("Homebrew was not found. Install Homebrew first, then return here."))
            return
        }
        isInstalling = true
        installLog = ""
        statusText = L10n.text("Installing sane-backends…")
        let runner = ProcessRunner()
        let result = await runner.run(executable: brew, arguments: ["install", "sane-backends"]) { chunk in
            Task { @MainActor in
                self.installLog += chunk
            }
        }
        isInstalling = false
        installLog += "\nexit \(result.exitCode)\n"
        if result.exitCode == 0 {
            statusText = L10n.text("Installation finished. Checking again…")
            await reloadBackend()
            await refreshConnection()
        } else {
            presentMessage(L10n.text("Installation failed."))
        }
    }

    private func siblingURL(_ url: URL, index: Int, count: Int) -> URL {
        if index == 0 { return url }
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        return url.deletingLastPathComponent().appendingPathComponent("\(base)-\(index + 1).\(ext)")
    }

    private func suggestedName(extension ext: String) -> String {
        let raw = library.selectedScanner?.name ?? "Scan"
        let cleaned = raw.map { character -> Character in
            if character.isLetter || character.isNumber || character == "-" || character == "_" || character == " " {
                return character
            }
            return "-"
        }
        let name = String(cleaned).trimmingCharacters(in: .whitespaces)
        return (name.isEmpty ? "Scan" : name) + ".\(ext)"
    }

    private func present(_ failure: ScanFailure) {
        lastError = failure.message
        showError = true
        statusText = failure.message
    }

    private func presentMessage(_ message: String) {
        lastError = message
        showError = true
    }

    private func persist() {
        try? store.saveLibrary(library)
    }

    private func saveSession() {
        try? store.saveSession(SessionState(pages: document.pages, selectedPageID: selectedPageID))
    }
}

extension ExportFormat {
    var utType: UTType {
        switch self {
        case .pdf: .pdf
        case .png: .png
        case .jpeg: .jpeg
        case .tiff: .tiff
        }
    }
}
