import SwiftUI

extension Color {
    static let ghAmber = Color(red: 1.0, green: 0.65, blue: 0.1)
    static let ghAmberDeep = Color(red: 0.85, green: 0.42, blue: 0.0)
    static let ghGold = Color(red: 1.0, green: 0.82, blue: 0.35)
    static let ghSunrise = Color(red: 1.0, green: 0.38, blue: 0.18)

    static let ghMorning = Color(red: 1.0, green: 0.75, blue: 0.3)
    static let ghPeakFocus = Color(red: 0.98, green: 0.55, blue: 0.1)
    static let ghCaffeine = Color(red: 0.55, green: 0.35, blue: 0.18)
    static let ghAfternoon = Color(red: 0.4, green: 0.72, blue: 0.56)
    static let ghSunset = Color(red: 0.85, green: 0.3, blue: 0.55)

    static let ghBgDeep = Color(red: 0.06, green: 0.04, blue: 0.02)
    static let ghBgMid = Color(red: 0.12, green: 0.08, blue: 0.03)
    static let ghBgCard = Color(white: 1.0, opacity: 0.06)
    static let ghBgCardHover = Color(white: 1.0, opacity: 0.10)

    static let ghTextPrimary = Color.white
    static let ghTextSecondary = Color(white: 1.0, opacity: 0.55)
    static let ghTextTertiary = Color(white: 1.0, opacity: 0.30)
}

enum GHFont {
    static let hero = Font.system(size: 72, weight: .thin, design: .rounded)
    static let largeTitle = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let titleLarge = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let micro = Font.system(size: 11, weight: .semibold, design: .rounded)
}

enum GHSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum GHRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let xl: CGFloat = 36
    static let pill: CGFloat = 999
}

extension DayPhase {
    var accentColor: Color {
        switch visualFallback {
        case .morningPrep: return .ghMorning
        case .focus: return .ghPeakFocus
        case .caffeine: return .ghCaffeine
        case .afternoon: return .ghAfternoon
        case .sunset: return .ghSunset
        case .idle: return .ghAmber
        }
    }

    var gradientColors: [Color] {
        switch visualFallback {
        case .morningPrep:
            return [Color(red: 0.18, green: 0.1, blue: 0.02), Color(red: 0.35, green: 0.2, blue: 0.04), .ghMorning]
        case .focus:
            return [Color(red: 0.22, green: 0.1, blue: 0.01), Color(red: 0.45, green: 0.25, blue: 0.03), .ghPeakFocus]
        case .caffeine:
            return [Color(red: 0.12, green: 0.07, blue: 0.03), Color(red: 0.28, green: 0.16, blue: 0.07), .ghCaffeine]
        case .afternoon:
            return [Color(red: 0.04, green: 0.12, blue: 0.09), Color(red: 0.08, green: 0.22, blue: 0.16), .ghAfternoon]
        case .sunset:
            return [Color(red: 0.18, green: 0.05, blue: 0.1), Color(red: 0.35, green: 0.08, blue: 0.18), .ghSunset]
        case .idle:
            return [.ghBgDeep, .ghBgMid, .ghAmber]
        }
    }
}

extension View {
    func ghGlassCard(cornerRadius: CGFloat = GHRadius.lg, tint: Color? = nil) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassEffect(.regular.tint(tint ?? .clear), in: .rect(cornerRadius: cornerRadius))
    }
}
