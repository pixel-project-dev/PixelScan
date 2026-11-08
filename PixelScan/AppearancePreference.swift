import AppKit
import SwiftUI

enum AppearancePreference {
    static let storageKey = "pixelscan.appearance"

    static func scheme(for raw: String) -> ColorScheme? {
        switch raw {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    static func nsAppearance(for raw: String) -> NSAppearance? {
        switch raw {
        case "light": NSAppearance(named: .aqua)
        case "dark": NSAppearance(named: .darkAqua)
        default: nil
        }
    }

    static func toggled(from raw: String, current: ColorScheme) -> String {
        let isDark = raw == "dark" || (raw != "light" && current == .dark)
        return isDark ? "light" : "dark"
    }

    static func apply(_ raw: String) {
        NSApp.appearance = nsAppearance(for: raw)
    }
}

struct AppearanceOverride: ViewModifier {
    @AppStorage(AppearancePreference.storageKey) private var raw = ""

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(AppearancePreference.scheme(for: raw))
            .onAppear { AppearancePreference.apply(raw) }
            .onChange(of: raw) { _, newValue in
                AppearancePreference.apply(newValue)
            }
    }
}

extension View {
    func pixelScanAppearance() -> some View {
        modifier(AppearanceOverride())
    }
}
