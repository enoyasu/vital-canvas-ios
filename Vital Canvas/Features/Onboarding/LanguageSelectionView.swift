import SwiftUI

struct LanguageSelectionView: View {
    var languageManager: LanguageManager
    @State private var selected: Language = .english

    var body: some View {
        ZStack {
            VCColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / symbol
                ZStack {
                    Circle()
                        .fill(VCColor.accent.opacity(0.08))
                        .frame(width: 90, height: 90)
                    Image(systemName: "leaf")
                        .font(.system(size: 34, weight: .thin))
                        .foregroundStyle(VCColor.accent)
                }
                .padding(.bottom, VCSpacing.xl)

                // Title
                Text(selected == .japanese ? "言語を選択" : "Choose your language")
                    .font(VCFont.display(30))
                    .foregroundStyle(VCColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: selected)
                    .padding(.bottom, VCSpacing.sm)

                Text(selected == .japanese ? "あとで設定から変更できます。" : "You can change this later in Settings.")
                    .font(VCFont.body(15))
                    .foregroundStyle(VCColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: selected)
                    .padding(.horizontal, VCSpacing.xxl)

                Spacer()

                // Language options
                VStack(spacing: VCSpacing.sm) {
                    ForEach(Language.allCases, id: \.rawValue) { lang in
                        LanguageOptionRow(
                            language: lang,
                            isSelected: selected == lang
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selected = lang
                            }
                        }
                    }
                }
                .padding(.horizontal, VCSpacing.lg)

                Spacer()

                // Continue button
                Button {
                    withAnimation {
                        languageManager.select(selected)
                    }
                } label: {
                    Text(selected == .japanese ? "続ける" : "Continue")
                        .font(VCFont.body(17))
                        .foregroundStyle(VCColor.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(VCColor.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, VCSpacing.xl)
                .padding(.bottom, VCSpacing.xxl)
                .animation(.easeInOut(duration: 0.15), value: selected)
            }
        }
    }
}

private struct LanguageOptionRow: View {
    let language: Language
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: VCSpacing.md) {
                // Flag / icon
                Text(language == .english ? "🇺🇸" : "🇯🇵")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 3) {
                    Text(language.nativeName)
                        .font(VCFont.body(18))
                        .foregroundStyle(VCColor.textPrimary)
                    // Translation in the other language so both audiences can recognise the option
                    Text(language == .english ? "英語" : "Japanese")
                        .font(VCFont.body(13))
                        .foregroundStyle(VCColor.textTertiary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? VCColor.accent : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(VCColor.accent)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, VCSpacing.md)
            .padding(.vertical, VCSpacing.md)
            .background(
                isSelected ? VCColor.accent.opacity(0.08) : VCColor.surface,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? VCColor.accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
