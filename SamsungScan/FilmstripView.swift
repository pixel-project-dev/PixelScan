import SwiftUI

struct FilmstripView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.format("%lld pages", Int64(model.document.pages.count)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let page = model.selectedPage, let index = model.document.index(of: page.id) {
                    Text(L10n.format("Page %lld of %lld", Int64(index + 1), Int64(model.document.pages.count)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(model.document.pages) { page in
                        thumbnail(page)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private func thumbnail(_ page: EditablePage) -> some View {
        let selected = page.id == model.selectedPageID
        return Button {
            model.selectedPageID = page.id
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
                if let image = model.thumbnail(for: page) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.medium)
                        .scaledToFit()
                        .padding(4)
                }
            }
            .frame(width: 78, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .help(page.source)
    }
}
