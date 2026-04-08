import SwiftUI
import HealthKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPremium = false

    var controller: AppController
    var languageManager: LanguageManager
    private var s: Strings { languageManager.s }

    var body: some View {
        ZStack {
            VCColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Text(s.settingsTitle)
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
                    .padding(.bottom, VCSpacing.xl)

                    // Health
                    sectionHeader(s.settingsHealthSection)
                    SettingsRow(
                        icon: "heart.fill",
                        title: s.settingsHealthStatus,
                        subtitle: healthStatusText,
                        trailingContent: AnyView(healthStatusBadge)
                    )

                    // Language
                    sectionHeader(s.settingsLanguage)
                    LanguagePickerRow(languageManager: languageManager)

                    // Notifications
                    sectionHeader(s.settingsNotifSection)
                    SettingsRow(
                        icon: "bell",
                        title: s.settingsMorning,
                        subtitle: s.settingsMorningDesc,
                        trailingContent: AnyView(Toggle("", isOn: .constant(false)).labelsHidden().tint(VCColor.accent))
                    )
                    SettingsRow(
                        icon: "calendar.badge.checkmark",
                        title: s.settingsWeekly,
                        subtitle: s.settingsWeeklyDesc,
                        trailingContent: AnyView(Toggle("", isOn: .constant(false)).labelsHidden().tint(VCColor.accent))
                    )

                    // Premium
                    sectionHeader(s.settingsPremiumSection)
                    Button {
                        showPremium = true
                    } label: {
                        SettingsRow(
                            icon: "sparkles",
                            title: s.premiumTitle,
                            subtitle: s.settingsPremiumDesc,
                            trailingContent: AnyView(
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(VCColor.textTertiary)
                            )
                        )
                    }
                    .buttonStyle(.plain)

                    // Privacy
                    sectionHeader(s.settingsPrivacySection)
                    SettingsRow(
                        icon: "lock.shield",
                        title: s.settingsPrivacyPolicy,
                        subtitle: nil,
                        trailingContent: AnyView(
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 13))
                                .foregroundStyle(VCColor.textTertiary)
                        )
                    )

                    Text(s.settingsVersion)
                        .font(VCFont.caption(11))
                        .foregroundStyle(VCColor.textTertiary)
                        .padding(.top, VCSpacing.xl)
                        .padding(.bottom, VCSpacing.xxl)
                }
            }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView(languageManager: languageManager)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(VCFont.caption(11))
            .foregroundStyle(VCColor.textTertiary)
            .kerning(languageManager.current == .japanese ? 0 : 1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VCSpacing.lg)
            .padding(.top, VCSpacing.lg)
            .padding(.bottom, VCSpacing.sm)
    }

    private var healthStatusText: String {
        HKHealthStore.isHealthDataAvailable() ? s.settingsHealthConnected : s.settingsHealthUnavail
    }

    private var healthStatusBadge: some View {
        let isActive = HKHealthStore.isHealthDataAvailable()
        return Text(isActive ? s.settingsHealthActive : s.settingsHealthInactive)
            .font(VCFont.caption(11))
            .foregroundStyle(isActive ? VCColor.accent : VCColor.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (isActive ? VCColor.accent : VCColor.textTertiary).opacity(0.15),
                in: Capsule()
            )
    }
}

// MARK: - Language picker row

private struct LanguagePickerRow: View {
    var languageManager: LanguageManager

    var body: some View {
        HStack(spacing: VCSpacing.md) {
            Image(systemName: "globe")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(VCColor.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.current == .japanese ? "言語" : "Language")
                    .font(VCFont.body(15))
                    .foregroundStyle(VCColor.textPrimary)
            }

            Spacer()

            HStack(spacing: VCSpacing.sm) {
                ForEach(Language.allCases, id: \.rawValue) { lang in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            languageManager.select(lang)
                        }
                    } label: {
                        Text(lang.nativeName)
                            .font(VCFont.body(13))
                            .foregroundStyle(languageManager.current == lang ? VCColor.background : VCColor.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                languageManager.current == lang ? VCColor.accent : VCColor.surfaceElevated,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, VCSpacing.lg)
        .padding(.vertical, VCSpacing.md)
        .background(VCColor.surface)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let trailingContent: AnyView

    var body: some View {
        HStack(spacing: VCSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(VCColor.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(VCFont.body(15))
                    .foregroundStyle(VCColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(VCFont.body(12))
                        .foregroundStyle(VCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
            trailingContent
        }
        .padding(.horizontal, VCSpacing.lg)
        .padding(.vertical, VCSpacing.md)
        .background(VCColor.surface)
    }
}
