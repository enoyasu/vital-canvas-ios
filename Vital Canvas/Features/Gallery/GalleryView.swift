import SwiftUI

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedArtwork: CanvasArtwork?
    @State private var images: [UUID: UIImage] = [:]

    var controller: AppController
    var languageManager: LanguageManager
    private var s: Strings { languageManager.s }

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        ZStack {
            VCColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(s.galleryTitle)
                        .font(VCFont.display(26))
                        .foregroundStyle(VCColor.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(VCColor.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(VCColor.surface, in: Circle())
                    }
                }
                .padding(.horizontal, VCSpacing.lg)
                .padding(.top, VCSpacing.lg)
                .padding(.bottom, VCSpacing.md)

                if controller.recentArtworks.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(controller.recentArtworks, id: \.id) { artwork in
                                GalleryCell(artwork: artwork, image: images[artwork.id], languageManager: languageManager)
                                    .onTapGesture {
                                        selectedArtwork = artwork
                                    }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadImages()
        }
        .sheet(item: $selectedArtwork) { artwork in
            DetailView(artwork: artwork, image: images[artwork.id], controller: controller, languageManager: languageManager)
        }
    }

    private func loadImages() {
        for artwork in controller.recentArtworks {
            images[artwork.id] = controller.loadImage(for: artwork)
        }
    }

    private var emptyState: some View {
        VStack(spacing: VCSpacing.md) {
            Image(systemName: "photo.stack")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(VCColor.accent.opacity(0.4))
            Text(s.galleryEmptyTitle)
                .font(VCFont.title(18))
                .foregroundStyle(VCColor.textSecondary)
            Text(s.galleryEmptyBody)
                .font(VCFont.body(14))
                .foregroundStyle(VCColor.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VCSpacing.xxl)
        }
    }
}

private struct GalleryCell: View {
    let artwork: CanvasArtwork
    let image: UIImage?
    let languageManager: LanguageManager

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArtworkCanvasView(artwork: artwork, image: image)
                .aspectRatio(1, contentMode: .fill)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel)
                    .font(VCFont.caption(9))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .kerning(languageManager.current == .japanese ? 0 : 1)
                Text(dateShort)
                    .font(VCFont.body(12))
                    .foregroundStyle(.white)
            }
            .padding(10)
        }
        .clipped()
    }

    private var dateLabel: String {
        let f = DateFormatter()
        if languageManager.current == .japanese {
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "EEEE"
        } else {
            f.dateFormat = "EEEE"
        }
        return f.string(from: artwork.date).uppercased()
    }

    private var dateShort: String {
        let f = DateFormatter()
        if languageManager.current == .japanese {
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "M月d日"
        } else {
            f.dateFormat = "MMM d"
        }
        return f.string(from: artwork.date)
    }
}
