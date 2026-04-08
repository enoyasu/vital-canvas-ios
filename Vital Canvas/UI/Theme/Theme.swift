import SwiftUI

enum VCColor {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.12)
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.20)
    static let surfaceElevated = Color(red: 0.13, green: 0.13, blue: 0.26)
    static let accent = Color(red: 0.52, green: 0.62, blue: 0.98)
    static let accentSoft = Color(red: 0.52, green: 0.62, blue: 0.98).opacity(0.3)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)
    static let divider = Color.white.opacity(0.08)
}

enum VCFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .thin, design: .serif)
    }
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

enum VCSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 36
    static let xxl: CGFloat = 56
}
