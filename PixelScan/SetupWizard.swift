import SwiftUI

struct SetupWizard: View {
    @Bindable var model: AppModel
    @State private var step = 0
    @State private var name = ""
    @State private var host = ""
    @State private var port = "9400"
    @State private var backendID = DeviceAddress.samsungNetwork
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
            content
            Divider()
            HStack {
                if step > 0 {
                    Button("Back") { step = max(0, step - 1) }
                }
                Spacer()
                Button("Close") { model.finishSetup(startPreview: false) }
                if step == 0 {
                    Button("Continue") {
                        step = 1
                        model.discovery.start()
                    }
                    .keyboardShortcut(.defaultAction)
                } else if step == 1 {
                    Button("Continue") {
                        model.discovery.stop()
                        step = 2
                    }
                    .keyboardShortcut(.defaultAction)
                } else if step == 3 {
                    Button("Finish") { model.finishSetup(startPreview: false) }
                    Button("Try a Preview") { model.finishSetup(startPreview: true) }
                        .disabled(!model.canPreview)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(20)
        .frame(width: 560, height: 520)
        .onDisappear { model.discovery.stop() }
    }

    private var title: String {
        switch step {
        case 0: L10n.text("Welcome to PixelScan")
        case 1: L10n.text("Looking for scanners")
        case 2: L10n.text("Choose a scanner")
        default: L10n.text("Connection check")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            Text("PixelScan looks for a scanner on your network and keeps every page on this Mac.")
            Text("No account and no cloud service are required.")
                .foregroundStyle(.secondary)
            Spacer()
            PixelProjectBrandLink(maxWidth: 180)
        case 1:
            HStack {
                if model.discovery.isRunning {
                    ProgressView().controlSize(.small)
                }
                Text("Searching the local network…")
            }
            Text("A printer announcement is not treated as a scanner unless the scan port answers.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if !model.sane.isUsable {
                Text("The scanner software is not installed yet. You can still save a scanner and install the software afterwards.")
                    .foregroundStyle(.secondary)
                Button("Open Setup") { model.showSetup = true }
            }
        case 2:
            chooseStep
        default:
            checkStep
        }
    }

    private var chooseStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.discovery.suggestions.isEmpty {
                Text("No scanner was found. Enter the address manually.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.discovery.suggestions) { suggestion in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(suggestion.name)
                            Text(suggestion.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Use") {
                            model.addScanner(
                                name: suggestion.name,
                                host: suggestion.host,
                                port: suggestion.port,
                                backendID: suggestion.backendHint,
                                secure: suggestion.secureConnection
                            )
                            step = 3
                        }
                    }
                }
            }
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
            Button("Add Scanner") {
                let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
                let parsedPort = Int(port) ?? 0
                model.addScanner(name: name, host: trimmedHost, port: parsedPort, backendID: backendID, secure: false)
                if DeviceName.isValidHost(trimmedHost), (1...65535).contains(parsedPort) {
                    step = 3
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var checkStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.connection == .checking {
                ProgressView()
                Text("Checking the connection…")
            } else {
                Text(model.connection.title)
                Text(model.statusText)
                    .foregroundStyle(.secondary)
                if model.connection == .ready {
                    Text("The scanner is ready. A preview uses the glass and does not pull paper from the feeder.")
                } else {
                    Text("The scanner was found, but it could not be opened. Check that it is turned on and on the same network.")
                }
            }
        }
    }
}
