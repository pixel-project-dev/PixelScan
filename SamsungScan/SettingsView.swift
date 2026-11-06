import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }
            installation
                .tabItem { Label("Installation", systemImage: "shippingbox") }
            exportTab
                .tabItem { Label("Export…", systemImage: "square.and.arrow.up") }
            help
                .tabItem { Label("Help", systemImage: "questionmark.circle") }
        }
        .frame(width: 560, height: 460)
        .padding(12)
    }

    private var general: some View {
        Form {
            Section("General") {
                Text("Language and appearance follow the system setting.")
                LabeledContent("Version") {
                    Text(versionText)
                }
            }
            Section("Storage") {
                Button("Open Data Folder") { model.openDataFolder() }
                Button("Show Log") { model.openLog() }
                Button("Clear Pages") { model.showClearConfirmation = true }
            }
            Section("Profiles") {
                Button("Restore Default Profiles") { model.restoreDefaultProfiles() }
                Text("Profiles can be edited from the scan sidebar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var installation: some View {
        Form {
            Section("SANE") {
                LabeledContent("Status") {
                    Text(model.sane.isUsable ? "scanimage is ready" : "scanimage was not found")
                }
                if let path = model.sane.scanimageURL?.path {
                    Text(path)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                if let version = model.sane.version {
                    Text(version)
                        .font(.caption)
                }
                if !model.sane.executableArchitectures.isEmpty {
                    LabeledContent("Processor") {
                        Text(model.sane.executableArchitectures.joined(separator: ", "))
                    }
                }
                if let warning = model.sane.architectureWarning {
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text(L10n.format("This app is running as %@.", MachOArchitecture.process))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Choose scanimage…") { model.chooseScanimage() }
                Button("Open Setup") { model.showSetup = true }
                Text("SANE is installed separately and is started as its own program.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Samsung Scan never changes printer drivers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var exportTab: some View {
        Form {
            Section("Export…") {
                Picker("Format", selection: formatBinding) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                Toggle("Searchable PDF", isOn: ocrBinding)
                Text("German and English text recognition runs on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("PDF compression", selection: compressionBinding) {
                    ForEach(PDFCompression.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                LabeledContent("JPEG quality") {
                    Slider(value: qualityBinding, in: 0.4...0.95)
                }
                Toggle("Skip blank pages", isOn: $model.exportSkipBlanks)
            }
        }
        .formStyle(.grouped)
    }

    private var help: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Manual")
                    .font(.title2)
                Text("Add the scanner, put a page on the glass or in the feeder, then press Scan.")
                Text("Export as PDF, PNG, JPEG, or TIFF. PDF can include recognized text.")
                Text("If the scanner is not reachable, check the IP address, the network, and that the device is turned on.")
                Divider()
                Text("System Integration")
                    .font(.headline)
                Text("Image Capture and Preview have no supported way to list this scanner. Finished documents can be opened in Preview.")
                Divider()
                Text("Troubleshooting")
                    .font(.headline)
                Text("The scanner is not reachable.")
                Text("The port is not reachable.")
                Text("The document feeder is empty.")
                Text("Paper jam. Pages that were already scanned are kept.")
                Text("SANE components are missing.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var formatBinding: Binding<ExportFormat> {
        Binding(
            get: { model.library.settings.exportFormat },
            set: { value in model.updateSetting { $0.exportFormat = value } }
        )
    }

    private var ocrBinding: Binding<Bool> {
        Binding(
            get: { model.library.settings.ocr },
            set: { value in model.updateSetting { $0.ocr = value } }
        )
    }

    private var compressionBinding: Binding<PDFCompression> {
        Binding(
            get: { model.library.settings.pdfCompression },
            set: { value in model.updateSetting { $0.pdfCompression = value } }
        )
    }

    private var qualityBinding: Binding<Double> {
        Binding(
            get: { model.library.settings.jpegQuality },
            set: { value in model.updateSetting { $0.jpegQuality = value } }
        )
    }
}
