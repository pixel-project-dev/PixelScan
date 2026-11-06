import SwiftUI

struct InspectorView: View {
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                scanSection
                Divider()
                pageSection
                Divider()
                documentSection
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var scanSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scan")
                .font(.headline)
            if let scanner = model.library.selectedScanner {
                LabeledContent("Selected scanner") {
                    Text(scanner.name)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Choose a scanner first.")
                    .foregroundStyle(.secondary)
            }
            sourcePicker
            paperPicker
            resolutionPicker
            modePicker
            if model.capabilities?.supportsDuplex == true {
                Text("Duplex")
                    .font(.callout)
                Text(model.capabilities?.duplexSource ?? model.capabilities?.duplexFlag ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            areaSummary
            Text(sourceHint)
                .font(.caption)
                .foregroundStyle(.secondary)
            Toggle("Append to current document", isOn: appendBinding)
            Toggle("Remove blank pages", isOn: blankBinding)
            Button {
                model.scan()
            } label: {
                Label("Scan", systemImage: "scanner")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!model.canScan)
            HStack {
                Button("Preview") { model.preview() }
                    .disabled(!model.canPreview)
                if model.isScanning {
                    Button("Cancel") { model.cancel() }
                }
            }
            if !model.statusText.isEmpty {
                Text(model.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var pageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adjustments")
                .font(.headline)
            HStack {
                Button { model.rotateSelected(clockwise: false) } label: { Image(systemName: "rotate.left") }
                    .help("Rotate Left")
                Button { model.rotateSelected(clockwise: true) } label: { Image(systemName: "rotate.right") }
                    .help("Rotate Right")
                Button { model.isCropping.toggle() } label: {
                    Image(systemName: model.isCropping ? "crop.rotate" : "crop")
                }
                .help("Crop")
                Button("Reset") { model.resetAdjustments() }
                    .disabled(model.selectedPage == nil)
            }
            .disabled(model.selectedPage == nil)
            Text("Brightness")
            Slider(value: brightnessBinding, in: -0.5...0.5)
                .disabled(model.selectedPage == nil)
            Text("Contrast")
            Slider(value: contrastBinding, in: 0.5...1.8)
                .disabled(model.selectedPage == nil)
            Button("Auto Align") { model.autoAlignSelected() }
                .disabled(model.selectedPage == nil)
            HStack {
                Button("Delete Page") { model.deleteSelectedPage() }
                Button("Move Left") { model.moveSelected(offset: -1) }
                Button("Move Right") { model.moveSelected(offset: 1) }
            }
            .disabled(model.selectedPage == nil)
            if model.isCropping {
                Text("Drag a rectangle to choose the scan area.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var documentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pages")
                .font(.headline)
            Button("Detect Blank Pages") { model.detectBlankPages() }
                .disabled(model.document.pages.isEmpty)
            Button("Clear Pages", role: .destructive) { model.showClearConfirmation = true }
                .disabled(model.document.pages.isEmpty)
            Button("Save to Profile") { model.saveSettingsToSelectedProfile() }
            HStack {
                Button("New Profile") { model.showNewProfile = true }
                Button("Delete Profile") { model.deleteSelectedProfile() }
                    .disabled(model.library.profiles.count < 2)
            }
        }
    }

    @ViewBuilder
    private var sourcePicker: some View {
        Picker("Source", selection: sourceBinding) {
            ForEach(sources, id: \.self) { source in
                Text(sourceTitle(source)).tag(source)
            }
        }
    }

    @ViewBuilder
    private var paperPicker: some View {
        Picker("Paper size", selection: paperBinding) {
            ForEach(PaperFormat.allCases) { paper in
                Text(paper.title).tag(paper)
            }
        }
        .disabled(model.library.settings.customArea != nil)
    }

    @ViewBuilder
    private var resolutionPicker: some View {
        Picker("Resolution", selection: resolutionBinding) {
            ForEach(resolutions, id: \.self) { value in
                Text("\(value) dpi").tag(value)
            }
        }
    }

    @ViewBuilder
    private var modePicker: some View {
        Picker("Color mode", selection: modeBinding) {
            ForEach(modes, id: \.self) { mode in
                Text(modeTitle(mode)).tag(mode)
            }
        }
    }

    private var areaSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let area = model.library.settings.customArea {
                Text("Custom area")
                    .font(.callout)
                Text(String(format: "%.0f × %.0f mm", area.width, area.height))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Use paper size") { model.clearCustomArea() }
            } else {
                Text("Scan area")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sourceHint: String {
        if model.library.settings.source == "ADF" {
            return L10n.text("Load the feeder. Pages already scanned are kept if it stops.")
        }
        return L10n.text("Place the page on the glass.")
    }

    private var sources: [String] {
        let reported = model.capabilities?.sources ?? ["Flatbed", "ADF", "Auto"]
        return reported.filter { $0.range(of: "duplex", options: .caseInsensitive) == nil }
    }

    private var modes: [String] {
        model.capabilities?.modes ?? ["Color", "Gray", "Lineart", "Halftone"]
    }

    private var resolutions: [Int] {
        model.capabilities?.resolutions ?? [75, 100, 150, 200, 300, 600]
    }

    private var sourceBinding: Binding<String> {
        Binding(
            get: { model.library.settings.source },
            set: { newValue in model.updateSetting { $0.source = newValue } }
        )
    }

    private var paperBinding: Binding<PaperFormat> {
        Binding(
            get: { model.library.settings.paper },
            set: { model.setPaper($0) }
        )
    }

    private var resolutionBinding: Binding<Int> {
        Binding(
            get: { model.library.settings.resolution },
            set: { newValue in model.updateSetting { $0.resolution = newValue } }
        )
    }

    private var modeBinding: Binding<String> {
        Binding(
            get: { model.library.settings.mode },
            set: { newValue in model.updateSetting { $0.mode = newValue } }
        )
    }

    private var appendBinding: Binding<Bool> {
        Binding(
            get: { model.library.settings.append },
            set: { newValue in model.updateSetting { $0.append = newValue } }
        )
    }

    private var blankBinding: Binding<Bool> {
        Binding(
            get: { model.library.settings.removeBlankPages },
            set: { newValue in model.updateSetting { $0.removeBlankPages = newValue } }
        )
    }

    private var brightnessBinding: Binding<Double> {
        Binding(
            get: { model.selectedPage?.brightness ?? 0 },
            set: { model.setBrightness($0) }
        )
    }

    private var contrastBinding: Binding<Double> {
        Binding(
            get: { model.selectedPage?.contrast ?? 1 },
            set: { model.setContrast($0) }
        )
    }

    private func sourceTitle(_ source: String) -> String {
        switch source {
        case "Flatbed": L10n.text("Flatbed")
        case "ADF": L10n.text("Document feeder")
        case "Auto": L10n.text("Automatic")
        default: source
        }
    }

    private func modeTitle(_ mode: String) -> String {
        switch mode {
        case "Color": L10n.text("Color")
        case "Gray": L10n.text("Grayscale")
        case "Lineart": L10n.text("Black & White")
        case "Halftone": L10n.text("Halftone")
        default: mode
        }
    }
}
