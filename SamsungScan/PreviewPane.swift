import SwiftUI

struct PreviewPane: View {
    @Bindable var model: AppModel

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            if let page = model.selectedPage, let image = model.thumbnail(for: page) {
                imageView(image, page: page)
            } else {
                ContentUnavailableView(
                    "No pages yet",
                    systemImage: "doc.viewfinder",
                    description: Text("Choose a scanner and start a scan.")
                )
            }
        }
        .overlay(alignment: .bottom) {
            if model.isScanning {
                scanningBar
                    .padding()
            }
        }
    }

    private func imageView(_ image: NSImage, page: EditablePage) -> some View {
        GeometryReader { geometry in
            let fitted = fittedSize(imageSize: image.size, in: geometry.size)
            ZStack {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: fitted.width, height: fitted.height)
                if model.isCropping {
                    CropOverlay(selection: cropBinding)
                        .frame(width: fitted.width, height: fitted.height)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .padding(16)
    }

    private var cropBinding: Binding<CGRect?> {
        Binding(
            get: {
                guard let crop = model.selectedPage?.crop else { return nil }
                return CGRect(x: crop.x, y: crop.y, width: crop.width, height: crop.height)
            },
            set: { model.setCrop($0) }
        )
    }

    private var scanningBar: some View {
        HStack(spacing: 12) {
            if let progress = model.progress, progress > 0 {
                ProgressView(value: progress)
                    .frame(width: 180)
                Text("\(Int(progress * 100))%")
                    .monospacedDigit()
            } else {
                ProgressView()
                    .controlSize(.small)
            }
            Text(model.statusText.isEmpty ? L10n.text("Scanning…") : model.statusText)
                .lineLimit(1)
            Spacer()
            Button("Cancel") { model.cancel() }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func fittedSize(imageSize: CGSize, in container: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return container }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}

struct CropOverlay: View {
    @Binding var selection: CGRect?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.001)
                if let selection {
                    Rectangle()
                        .path(in: denormalize(selection, in: geometry.size))
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        let width = max(geometry.size.width, 1)
                        let height = max(geometry.size.height, 1)
                        let x = min(value.startLocation.x, value.location.x) / width
                        let y = min(value.startLocation.y, value.location.y) / height
                        let rectWidth = abs(value.location.x - value.startLocation.x) / width
                        let rectHeight = abs(value.location.y - value.startLocation.y) / height
                        selection = CGRect(x: x, y: y, width: rectWidth, height: rectHeight)
                    }
            )
        }
    }

    private func denormalize(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * size.width,
            y: rect.origin.y * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }
}
