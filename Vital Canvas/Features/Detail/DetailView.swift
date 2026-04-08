import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    let artwork: CanvasArtwork
    let image: UIImage?
    var controller: AppController
    var languageManager: LanguageManager

    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    private var s: Strings { languageManager.s }

    var body: some View {
        ZStack {
            VCColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
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

                    ArtworkCanvasView(artwork: artwork, image: image, cornerRadius: 20)
                        .padding(.horizontal, VCSpacing.lg)
                        .padding(.top, VCSpacing.sm)
                        .shadow(color: VCColor.accent.opacity(0.15), radius: 30, x: 0, y: 10)

                    VStack(alignment: .leading, spacing: VCSpacing.sm) {
                        Text(dateLabel)
                            .font(VCFont.caption(11))
                            .foregroundStyle(VCColor.textTertiary)
                            .kerning(languageManager.current == .japanese ? 0 : 1)
                            .textCase(.uppercase)

                        Text(artwork.title)
                            .font(VCFont.display(28))
                            .foregroundStyle(VCColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(artwork.subtitle)
                            .font(VCFont.body(16))
                            .foregroundStyle(VCColor.textSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .background(VCColor.divider)
                            .padding(.top, VCSpacing.sm)

                        Text(artwork.summary)
                            .font(VCFont.body(14))
                            .foregroundStyle(VCColor.textTertiary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, VCSpacing.lg)
                    .padding(.top, VCSpacing.lg)

                    VStack(alignment: .leading, spacing: VCSpacing.sm) {
                        Text(s.detailHealthSnapshot.uppercased())
                            .font(VCFont.caption(11))
                            .foregroundStyle(VCColor.textTertiary)
                            .kerning(languageManager.current == .japanese ? 0 : 1)

                        HealthSummaryRow(artwork: artwork, strings: s)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, VCSpacing.lg)
                    .padding(.top, VCSpacing.xl)

                    Button {
                        prepareShare()
                    } label: {
                        HStack(spacing: VCSpacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                            Text(s.detailSaveShare)
                        }
                        .font(VCFont.body(16))
                        .foregroundStyle(VCColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(VCColor.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, VCSpacing.lg)
                    .padding(.top, VCSpacing.xl)
                    .padding(.bottom, VCSpacing.xxl)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    private var dateLabel: String {
        let f = DateFormatter()
        if languageManager.current == .japanese {
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "M月d日（EEEE）"
        } else {
            f.dateFormat = "EEEE · MMM d"
        }
        return f.string(from: artwork.date)
    }

    private func prepareShare() {
        if let image {
            shareImage = image
            showShareSheet = true
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
