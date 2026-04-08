import SwiftUI

struct HealthChipView: View {
    let label: String
    let value: String
    let icon: String
    let normalized: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(chipColor)
                Text(label)
                    .font(VCFont.caption(9))
                    .foregroundStyle(VCColor.textTertiary)
                    .kerning(0.5)
            }
            Text(value)
                .font(VCFont.body(14))
                .foregroundStyle(VCColor.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(VCColor.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(chipColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var chipColor: Color {
        if normalized > 0.3 { return VCColor.accent }
        if normalized < -0.3 { return Color.white.opacity(0.3) }
        return Color.white.opacity(0.45)
    }
}

struct HealthSummaryRow: View {
    let artwork: CanvasArtwork
    let strings: Strings

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            HealthChipView(
                label: strings.chipSleep,
                value: sleepLabel,
                icon: "moon.fill",
                normalized: artwork.sleepNormalized
            )
            HealthChipView(
                label: strings.chipRecovery,
                value: recoveryLabel,
                icon: "heart.fill",
                normalized: artwork.hrvNormalized
            )
            HealthChipView(
                label: strings.chipActivity,
                value: activityLabel,
                icon: "figure.walk",
                normalized: artwork.activityNormalized
            )
            HealthChipView(
                label: strings.chipCalm,
                value: calmLabel,
                icon: "leaf.fill",
                normalized: artwork.mindfulnessNormalized
            )
        }
    }

    private var sleepLabel: String {
        if artwork.sleepNormalized > 0.5 { return strings.sleepGood }
        if artwork.sleepNormalized < -0.5 { return strings.sleepBad }
        return strings.sleepNeutral
    }

    private var recoveryLabel: String {
        if artwork.hrvNormalized > 0.5 { return strings.recoveryGood }
        if artwork.hrvNormalized < -0.5 { return strings.recoveryBad }
        return strings.recoveryNeutral
    }

    private var activityLabel: String {
        if artwork.activityNormalized > 0.5 { return strings.activityGood }
        if artwork.activityNormalized < -0.5 { return strings.activityBad }
        return strings.activityNeutral
    }

    private var calmLabel: String {
        if artwork.mindfulnessNormalized > 0.5 { return strings.calmGood }
        if artwork.mindfulnessNormalized < -0.5 { return strings.calmBad }
        return strings.calmNeutral
    }
}
