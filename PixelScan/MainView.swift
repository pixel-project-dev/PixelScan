import AppKit
import SwiftUI

struct MainView: View {
    @Bindable var model: AppModel
    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HSplitView {
            ScannerSidebar(model: model)
                .frame(minWidth: 230, idealWidth: 260, maxWidth: 340)
            VStack(spacing: 0) {
                if !model.sane.isUsable {
                    backendBanner
                }
                PreviewPane(model: model)
                Divider()
                FilmstripView(model: model)
                    .frame(height: 156)
            }
            InspectorView(model: model)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        }
        .toolbar { toolbar }
        .alert("Error", isPresented: $model.showError) {
            Button("Copy Details") { model.copyError() }
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.lastError)
        }
        .sheet(isPresented: $model.showAddScanner) {
            AddScannerSheet(model: model)
        }
        .sheet(isPresented: $model.showSetup) {
            SetupSheet(model: model)
        }
        .sheet(isPresented: $model.showWizard) {
            SetupWizard(model: model)
        }
        .sheet(isPresented: $model.showPreviewArea) {
            PreviewAreaSheet(model: model)
        }
        .sheet(isPresented: $model.showNewProfile) {
            NamePrompt(title: "New profile", label: "Profile name") { name in
                model.createProfile(named: name)
            }
        }
        .sheet(isPresented: $model.showRenameScanner) {
            NamePrompt(title: "Rename Scanner", label: "Name", initial: model.library.selectedScanner?.name ?? "") { name in
                model.renameSelectedScanner(to: name)
            }
        }
        .sheet(isPresented: $model.showAbout) {
            AboutPixelScanView()
        }
        .confirmationDialog("Clear all pages?", isPresented: $model.showClearConfirmation) {
            Button("Clear Pages", role: .destructive) { model.clearPages() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the current document from PixelScan.")
        }
        .confirmationDialog("Blank pages", isPresented: $model.showBlankConfirmation) {
            Button("Remove", role: .destructive) { model.removeConfirmedBlankPages() }
            Button("Keep", role: .cancel) {}
        } message: {
            Text(L10n.format("%lld blank pages will be removed.", Int64(model.blankIDs.count)))
        }
        .task { await model.startup() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            model.shutdown()
        }
        .pixelScanAppearance()
    }

    private var backendBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("SANE components are missing.")
            Spacer()
            Button("Open Setup") { model.showSetup = true }
        }
        .padding(10)
        .background(.yellow.opacity(0.25))
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                model.scan()
            } label: {
                Label("Scan", systemImage: "scanner")
            }
            .disabled(!model.canScan)
            Button {
                model.preview()
            } label: {
                Label("Preview", systemImage: "eye")
            }
            .disabled(!model.canPreview)
            if model.isScanning {
                Button {
                    model.cancel()
                } label: {
                    Label("Cancel", systemImage: "stop.fill")
                }
            }
            Button {
                model.export()
            } label: {
                Label("Export…", systemImage: "square.and.arrow.up")
            }
            .disabled(model.document.pages.isEmpty || model.isScanning)
            Button {
                model.openInPreview()
            } label: {
                Label("Open in Preview", systemImage: "doc.richtext")
            }
            .disabled(model.document.pages.isEmpty || model.isScanning)
            Button {
                appearanceRaw = AppearancePreference.toggled(from: appearanceRaw, current: colorScheme)
            } label: {
                Label(appearanceIsDark ? "Switch to Light Mode" : "Switch to Dark Mode", systemImage: appearanceIsDark ? "sun.max" : "moon")
            }
            .help(appearanceIsDark ? "Switch to Light Mode" : "Switch to Dark Mode")
        }
    }

    private var appearanceIsDark: Bool {
        appearanceRaw == "dark" || (appearanceRaw != "light" && colorScheme == .dark)
    }
}
