import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    var languageManager: LanguageManager
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

                    VStack(spacing: VCSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(VCColor.accent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "sparkles")
                                .font(.system(size: 30, weight: .thin))
                                .foregroundStyle(VCColor.accent)
                        }

                        Text(s.premiumTitle)
                            .font(VCFont.display(28))
                            .foregroundStyle(VCColor.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(s.premiumTagline)
                            .font(VCFont.body(16))
                            .foregroundStyle(VCColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, VCSpacing.xl)
                    .padding(.horizontal, VCSpacing.xl)

                    VStack(spacing: VCSpacing.sm) {
                        featureRow("calendar.badge.clock", s.premiumFeat1Title, s.premiumFeat1Desc)
                        featureRow("paintpalette", s.premiumFeat2Title, s.premiumFeat2Desc)
                        featureRow("arrow.up.doc", s.premiumFeat3Title, s.premiumFeat3Desc)
                        featureRow("chart.bar.xaxis", s.premiumFeat4Title, s.premiumFeat4Desc)
                        featureRow("rectangle.3.group", s.premiumFeat5Title, s.premiumFeat5Desc)
                        featureRow("film", s.premiumFeat6Title, s.premiumFeat6Desc)
                    }
                    .padding(.horizontal, VCSpacing.lg)
                    .padding(.top, VCSpacing.xxl)

                    VStack(spacing: VCSpacing.md) {
                        PricingCard(
                            label: s.premiumMonthly,
                            price: "$3.99",
                            period: s.premiumMonthlyPeriod,
                            bestValue: nil
                        )
                        PricingCard(
                            label: s.premiumYearly,
                            price: "$29.99",
                            period: s.premiumYearlyPeriod,
                            bestValue: s.premiumBestValue
                        )
                    }
                    .padding(.horizontal, VCSpacing.lg)
                    .padding(.top, VCSpacing.xl)

                    Button {
                        // StoreKit purchase (placeholder)
                    } label: {
                        Text(s.premiumCTA)
                            .font(VCFont.body(17))
                            .foregroundStyle(VCColor.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(VCColor.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, VCSpacing.lg)
                    .padding(.top, VCSpacing.lg)

                    Button(s.premiumRestore) {}
                        .font(VCFont.body(13))
                        .foregroundStyle(VCColor.textTertiary)
                        .padding(.top, VCSpacing.md)

                    Text(s.premiumFooter)
                        .font(VCFont.caption(11))
                        .foregroundStyle(VCColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, VCSpacing.sm)
                        .padding(.horizontal, VCSpacing.xl)
                        .padding(.bottom, VCSpacing.xxl)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: VCSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(VCColor.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(VCFont.body(15))
                    .foregroundStyle(VCColor.textPrimary)
                Text(desc)
                    .font(VCFont.body(13))
                    .foregroundStyle(VCColor.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(VCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VCColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct PricingCard: View {
    let label: String
    let price: String
    let period: String
    let bestValue: String?

    var isHighlighted: Bool { bestValue != nil }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .font(VCFont.caption(11))
                    .foregroundStyle(isHighlighted ? VCColor.accent : VCColor.textTertiary)
                    .kerning(0.8)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(VCFont.title(22))
                        .foregroundStyle(VCColor.textPrimary)
                    Text(period)
                        .font(VCFont.body(12))
                        .foregroundStyle(VCColor.textTertiary)
                }
            }
            Spacer()
            if let bestValue {
                Text(bestValue)
                    .font(VCFont.caption(10))
                    .foregroundStyle(VCColor.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VCColor.accentSoft, in: Capsule())
            }
        }
        .padding(VCSpacing.md)
        .background(isHighlighted ? VCColor.surfaceElevated : VCColor.surface,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isHighlighted ? VCColor.accent.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}
