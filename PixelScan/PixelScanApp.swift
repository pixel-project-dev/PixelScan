import SwiftUI

@main
struct PixelScanApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            MainView(model: model)
                .frame(minWidth: 1080, minHeight: 700)
        }
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About PixelScan") { model.showAbout = true }
            }
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Scan") {
                Button("Scan") { model.scan() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(!model.canScan)
                Button("Preview") { model.preview() }
                    .disabled(!model.canPreview)
                Button("Cancel scan") { model.cancel() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(!model.isScanning)
                Divider()
                Button("Export…") { model.export() }
                    .keyboardShortcut("e", modifiers: .command)
                    .disabled(model.document.pages.isEmpty || model.isScanning)
                Button("Open in Preview") { model.openInPreview() }
                    .disabled(model.document.pages.isEmpty)
                Divider()
                Button("Setup Assistant") { model.showWizard = true }
            }
        }
        Settings {
            SettingsView(model: model)
        }
    }
}
