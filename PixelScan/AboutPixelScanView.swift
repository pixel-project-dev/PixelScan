import AppKit
import SwiftUI

struct AboutPixelScanView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
                .accessibilityLabel("PixelScan")
            Text("PixelScan")
                .font(.title2.weight(.semibold))
            Text(versionLabel)
                .foregroundStyle(.secondary)
            Text("PixelScan scans documents on this Mac and keeps the pages local.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            PixelProjectBrandLink(maxWidth: 240)
                .padding(.vertical, 4)
            Text("Developed by PixelProject")
            Link(destination: PixelProjectSite.url) {
                Text("Project website")
            }
            Link(destination: PixelProjectSite.sourceRepository) {
                Text("GitHub")
            }
            Text(copyright)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("PixelScan is free and open source. Scanning stays on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(width: 440)
    }

    private var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ProductIdentity.marketingVersion
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ProductIdentity.buildNumber
        return L10n.format("Version %@ (Build %@)", version, build)
    }

    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
            ?? "PixelScan is an independent application. Samsung is a trademark of its owner."
    }
}
