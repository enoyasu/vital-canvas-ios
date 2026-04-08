import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var loadedImage: UIImage?
    @State private var showDetail = false
    @State private var showGallery = false
    @State private var showSettings = false

    var controller: AppController
    var languageManager: LanguageManager
    private var s: Strings { languageManager.s }

    var body: some View {
        ZStack {
            VCColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, VCSpacing.lg)
                        .padding(.top, VCSpacing.lg)

                    Spacer().frame(height: VCSpacing.xl)

                    mainArtworkSection
                        .padding(.horizontal, VCSpacing.lg)

                    Spacer().frame(height: VCSpacing.xl)

                    if let artwork = controller.todayArtwork {
                        HealthSummaryRow(artwork: artwork, strings: s)
                            .padding(.horizontal, VCSpacing.lg)
                    }

                    Spacer().frame(height: VCSpacing.xl)

                    galleryEntry
                        .padding(.horizontal, VCSpacing.lg)

                    Spacer().frame(height: VCSpacing.xxl)
                }
            }
        }
        .task {
            await controller.generateTodayArtworkIfNeeded(modelContext: modelContext, language: languageManager.current)
            if let artwork = controller.todayArtwork {
                loadedImage = controller.loadImage(for: artwork)
            }
        }
        .onChange(of: controller.todayArtwork) { _, artwork in
            if let artwork {
                loadedImage = controller.loadImage(for: artwork)
            }
        }
        .sheet(isPresented: $showDetail) {
            if let artwork = controller.todayArtwork {
                DetailView(artwork: artwork, image: loadedImage, controller: controller, languageManager: languageManager)
            }
        }
        .sheet(isPresented: $showGallery) {
            GalleryView(controller: controller, languageManager: languageManager)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(controller: controller, languageManager: languageManager)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(todayDateString)
                    .font(VCFont.caption(11))
                    .foregroundStyle(VCColor.textTertiary)
                    .kerning(1.2)
                    .textCase(.uppercase)
                Text(s.homeTitle)
                    .font(VCFont.display(28))
                    .foregroundStyle(VCColor.textPrimary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(VCColor.textSecondary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var mainArtworkSection: some View {
        VStack(alignment: .leading, spacing: VCSpacing.md) {
            if controller.isLoading {
                loadingState
            } else if let artwork = controller.todayArtwork {
                artworkCard(artwork: artwork)
            } else {
                emptyState
            }
        }
    }

    private func artworkCard(artwork: CanvasArtwork) -> some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: VCSpacing.md) {
                ArtworkCanvasView(artwork: artwork, image: loadedImage, cornerRadius: 20)
                    .shadow(color: VCColor.accent.opacity(0.15), radius: 30, x: 0, y: 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text(artwork.title)
                        .font(VCFont.display(22))
                        .foregroundStyle(VCColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(artwork.subtitle)
                        .font(VCFont.body(14))
                        .foregroundStyle(VCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var loadingState: some View {
        VStack(spacing: VCSpacing.lg) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(VCColor.surface)
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    VStack(spacing: VCSpacing.md) {
                        ProgressView()
                            .tint(VCColor.accent)
                        Text(s.homeGenerating)
                            .font(VCFont.body(14))
                            .foregroundStyle(VCColor.textTertiary)
                    }
                }

            Text(s.homeGathering)
                .font(VCFont.display(22))
                .foregroundStyle(VCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(VCColor.surface)
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                VStack(spacing: VCSpacing.md) {
                    Image(systemName: "leaf")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(VCColor.accent.opacity(0.5))
                    Text(s.homeNoCanvas)
                        .font(VCFont.body(14))
                        .foregroundStyle(VCColor.textTertiary)
                }
            }
    }

    private var galleryEntry: some View {
        Button {
            showGallery = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.homeRecentTitle)
                        .font(VCFont.body(15))
                        .foregroundStyle(VCColor.textPrimary)
                    Text(s.homeRecentCount(controller.recentArtworks.count))
                        .font(VCFont.caption(12))
                        .foregroundStyle(VCColor.textTertiary)
                }
                Spacer()

                HStack(spacing: -8) {
                    ForEach(Array(controller.recentArtworks.prefix(3)), id: \.id) { artwork in
                        let img = controller.loadImage(for: artwork)
                        ArtworkCanvasView(artwork: artwork, image: img, cornerRadius: 6)
                            .frame(width: 36, height: 36)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(VCColor.background, lineWidth: 2))
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(VCColor.textTertiary)
                    .padding(.leading, 8)
            }
            .padding(VCSpacing.md)
            .background(VCColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var todayDateString: String {
        let f = DateFormatter()
        if languageManager.current == .japanese {
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "M月d日 EEEE"
        } else {
            f.dateFormat = "EEEE, MMMM d"
        }
        return f.string(from: Date())
    }
}
