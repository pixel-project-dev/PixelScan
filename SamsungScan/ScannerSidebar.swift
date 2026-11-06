import SwiftUI

struct ScannerSidebar: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List(selection: scannerSelection) {
                Section("Scanners") {
                    if model.library.scanners.isEmpty {
                        Text("No scanner yet")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.library.scanners) { scanner in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scanner.name)
                            Text("\(scanner.host):\(scanner.port)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(Optional(scanner.id))
                        .contextMenu {
                            Button("Rename") {
                                model.selectScanner(scanner.id)
                                model.showRenameScanner = true
                            }
                            Button("Delete", role: .destructive) {
                                model.selectScanner(scanner.id)
                                model.removeSelectedScanner()
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            Divider()
            profileList
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(model.connection.title)
                        .font(.callout)
                        .lineLimit(2)
                }
                HStack {
                    Button("Add Scanner") { model.showAddScanner = true }
                    Button("Refresh") { Task { await model.refreshConnection() } }
                        .disabled(model.library.selectedScanner == nil || model.isScanning)
                }
            }
            .padding(12)
        }
    }

    private var profileList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Profiles")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            ForEach(model.library.profiles) { profile in
                Button {
                    model.selectProfile(profile.id)
                } label: {
                    HStack {
                        Text(profile.displayName)
                        Spacer()
                        if model.library.selectedProfileID == profile.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 8)
    }

    private var scannerSelection: Binding<UUID?> {
        Binding(
            get: { model.library.selectedScannerID },
            set: { model.selectScanner($0) }
        )
    }

    private var statusColor: Color {
        switch model.connection {
        case .ready: .green
        case .checking: .orange
        case .unknown: .gray
        default: .red
        }
    }
}
