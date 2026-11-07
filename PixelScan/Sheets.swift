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
            Text("Scanner software")
                .font(.title2)
            Text("PixelScan uses a scanner program that is installed separately. Printer setup is not changed.")
                .foregroundStyle(.secondary)
            checklist
            if model.sane.scanimageURL == nil {
                missingSteps
            }
            if model.isInstalling || !model.installLog.isEmpty {
                ScrollView {
                    Text(model.installLog)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 120)
            }
            DisclosureGroup("Advanced") {
                if let path = model.sane.scanimageURL?.path {
                    Text(path).font(.caption).textSelection(.enabled)
                }
                if let version = model.sane.version {
                    Text(version).font(.caption).foregroundStyle(.secondary)
                }
                if !model.sane.executableArchitectures.isEmpty {
                    Text(L10n.format("Processor: %@", model.sane.executableArchitectures.joined(separator: ", ")))
                        .font(.caption)
                }
                if let warning = model.sane.architectureWarning {
                    Text(warning).font(.caption)
                }
                Text(backendStatus).font(.caption)
                if let directory = model.userConfigDirectory {
                    Text(directory.path).font(.caption).textSelection(.enabled)
                }
                Text("Saved scanners are written only into PixelScan's own folder.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if model.systemScannerEntryPresent == true {
                    Text("A matching line also exists in the system scanner file. PixelScan does not change that file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Button("Choose scanimage…") { model.chooseScanimage() }
                    Button("Refresh") {
                        Task {
                            await model.reloadBackendForDisplay()
                            await model.refreshConnection()
                        }
                    }
                }
                if model.sane.xeroxBackendEnabled == false {
                    Text("This writes one line into the shared scanner configuration. Printer drivers are not changed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Enable samsung support in the shared configuration") { model.enableXeroxBackend() }
                }
            }
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 580)
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 6) {
            row(model.sane.isUsable, "Scanner program found")
            row(model.sane.architectureWarning == nil && model.sane.isUsable, "Processor matches this Mac")
            row(model.sane.installedLibraries.isEmpty || model.sane.installedLibraries.contains("xerox_mfp"), "Samsung support is installed")
            row(model.userConfigDirectory != nil, "Scanner list is stored for this user")
        }
    }

    private var missingSteps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The scanner program is not installed yet.")
            Text("1. Install Homebrew, if it is not already on this Mac.")
            Text("2. Return here and install the scanner software. macOS will ask for permission.")
            Text("3. Add the scanner by its address. The usual port is 9400.")
                .foregroundStyle(.secondary)
            if model.sane.homebrewURL != nil {
                Button("Install scanner software") { model.installWithHomebrew() }
                    .disabled(model.isInstalling)
            } else {
                Button("Open Homebrew Website") { model.openHomebrewWebsite() }
            }
        }
    }

    private func row(_ ok: Bool, _ title: LocalizedStringKey) -> some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(ok ? .green : .orange)
            Text(title)
        }
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
