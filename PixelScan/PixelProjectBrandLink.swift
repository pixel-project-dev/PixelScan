import AppKit
import SwiftUI

enum PixelProjectSite {
    static let url = URL(string: "https://pixel-project.de")!
    static let sourceRepository = URL(string: "https://github.com/pixel-project-dev/PixelScan")!
    static let opensOnLaunch = false
}

struct PixelProjectBrandLink: View {
    var maxWidth: CGFloat = 220
    @FocusState private var focused: Bool

    var body: some View {
        Link(destination: PixelProjectSite.url) {
            Image("PixelProjectLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: maxWidth)
                .padding(4)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.accentColor, lineWidth: focused ? 2 : 0)
                }
        }
        .buttonStyle(.plain)
        .focused($focused)
        .onContinuousHover { phase in
            switch phase {
            case .active:
                NSCursor.pointingHand.push()
            case .ended:
                NSCursor.pop()
            }
        }
        .accessibilityLabel(Text("PixelProject – Open website"))
        .accessibilityHint(Text("Opens pixel-project.de in the default browser"))
        .accessibilityAddTraits(.isLink)
        .help("pixel-project.de")
    }
}
