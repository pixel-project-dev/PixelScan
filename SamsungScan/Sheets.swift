import SwiftUI

struct AddScannerSheet: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var port = "9400"
    @State private var backendID = DeviceAddress.samsungNetwork
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Scanner")
                .font(.title2)
            Text("The address is stored only for this scanner.")
                .font(.callout)
                .foregroundStyle(.secondary)
            TextField("Name", text: $name)
            TextField("IP Address", text: $host, prompt: Text("for example 192.168.1.20"))
            DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                TextField("Port", text: $port)
                Picker("Connection", selection: $backendID) {
                    ForEach(DeviceAddress.selectableIDs(installedLibraries: model.sane.installedLibraries), id: \.self) { id in
                        Text(DeviceAddress.plainTitle(for: id)).tag(id)
                    }
                }
            }
            HStack {
                Button("Discover") {
                    if model.discovery.isRunning {
                        model.discovery.stop()
                    } else {
                        model.discovery.start()
                    }
                }
                if model.discovery.isRunning {
                    ProgressView().controlSize(.small)
                    Text("Searching the local network…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text("Discover looks for scanners already announced on the local network. It does not sweep the subnet.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !model.discovery.suggestions.isEmpty {
                Text("Suggested scanners")
                    .font(.headline)
                ForEach(model.discovery.suggestions) { suggestion in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(suggestion.name)
                            Text("\(suggestion.host):\(suggestion.port)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Add") {
                            model.addScanner(
                                name: suggestion.name,
                                host: suggestion.host,
                                port: suggestion.port,
                                backendID: suggestion.backendHint,
                                secure: suggestion.secureConnection
                            )
                            dismiss()
                        }
                    }
                }
            } else if !model.discovery.isRunning && model.discovery.suggestions.isEmpty {
                EmptyView()
            }
            HStack {
                Button("Cancel", role: .cancel) {
                    model.discovery.stop()
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
                    let parsedPort = Int(port) ?? 0
                    model.addScanner(name: name, host: trimmedHost, port: parsedPort, backendID: backendID)
                    if DeviceName.isValidHost(trimmedHost), (1...65535).contains(parsedPort) {
                        model.discovery.stop()
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onDisappear { model.discovery.stop() }
    }
}

struct PreviewAreaSheet: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan area")
                .font(.title2)
            Text("Drag a rectangle to choose the scan area.")
                .foregroundStyle(.secondary)
            ZStack {
                if let image = model.previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                }
                CropOverlay(selection: $model.previewSelection)
            }
            .frame(minWidth: 520, minHeight: 360)
            .background(Color(nsColor: .underPageBackgroundColor))
            HStack {
                Button("Use paper size") {
                    model.clearCustomArea()
                    dismiss()
                }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Scan this area") {
                    model.scanPreviewSelection()
                    dismiss()
                }
                .disabled(model.previewSelection == nil)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 720, height: 560)
    }
}

struct SetupSheet: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Installation")
                .font(.title2)
            Text("SANE is installed separately and is started as its own program.")
            Text("Samsung Scan never changes printer drivers.")
                .foregroundStyle(.secondary)
            LabeledContent("Executable") {
                Text(model.sane.scanimageURL?.path ?? L10n.text("scanimage was not found"))
                    .font(.caption)
                    .textSelection(.enabled)
            }
            LabeledContent("Backend") {
                Text(backendStatus)
            }
            if let version = model.sane.version {
                Text(version)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button("Choose scanimage…") { model.chooseScanimage() }
                Button("Refresh") { Task { await model.refreshConnection() } }
            }
            if model.sane.xeroxBackendEnabled == false {
                Text("This writes xerox_mfp into the SANE configuration on this Mac. Printer drivers are not changed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Enable xerox_mfp") { model.enableXeroxBackend() }
            }
            if model.sane.scanimageURL == nil {
                if model.sane.homebrewURL != nil {
                    Button("Install with Homebrew") { model.installWithHomebrew() }
                        .disabled(model.isInstalling)
                } else {
                    Text("Homebrew was not found. Install Homebrew first, then return here.")
                    Button("Open Homebrew Website") { model.openHomebrewWebsite() }
                }
            }
            if model.isInstalling || !model.installLog.isEmpty {
                ScrollView {
                    Text(model.installLog)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 140)
                .background(Color(nsColor: .textBackgroundColor))
            }
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 560)
    }

    private var backendStatus: String {
        switch model.sane.xeroxBackendEnabled {
        case true: L10n.text("xerox_mfp is enabled")
        case false: L10n.text("xerox_mfp is disabled")
        case nil: L10n.text("Not checked")
        }
    }
}

struct NamePrompt: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    let label: LocalizedStringKey
    var initial = ""
    let confirm: (String) -> Void
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
            TextField(label, text: $name)
            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button("Save") {
                    confirm(name)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear { name = initial }
    }
}
