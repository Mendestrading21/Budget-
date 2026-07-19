import SwiftUI

/// Semantic design tokens for the Budget visual identity.
/// Raw hex values live only here; views must reference semantic names.
enum BudgetColor {
    // Core surfaces
    static let graphite = Color(red: 11 / 255, green: 14 / 255, blue: 20 / 255)      // #0B0E14
    static let midnight = Color(red: 15 / 255, green: 22 / 255, blue: 36 / 255)      // #0F1624
    static let slateBlue = Color(red: 30 / 255, green: 35 / 255, blue: 51 / 255)     // #1E2333

    // Accents
    static let indigo = Color(red: 75 / 255, green: 92 / 255, blue: 255 / 255)       // #4B5CFF
    static let electricBlue = Color(red: 90 / 255, green: 167 / 255, blue: 255 / 255) // #5AA7FF
    static let violet = Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)      // #8B5CF6
    static let cyan = Color(red: 85 / 255, green: 221 / 255, blue: 224 / 255)        // #55DDE0

    // Text
    static let offWhite = Color(red: 242 / 255, green: 244 / 255, blue: 248 / 255)   // #F2F4F8
    static let coolGray = Color(red: 122 / 255, green: 134 / 255, blue: 153 / 255)   // #7A8699

    // Semantic status
    static let positive = Color(red: 57 / 255, green: 217 / 255, blue: 138 / 255)    // #39D98A
    static let negative = Color(red: 255 / 255, green: 102 / 255, blue: 122 / 255)   // #FF667A
    static let warning = Color(red: 255 / 255, green: 178 / 255, blue: 77 / 255)     // #FFB24D
    static let informative = electricBlue
}

/// Semantic roles resolved against the current appearance.
/// The canonical identity is dark; light mode keeps indigo as primary accent
/// on a pale background with navy-tinted cards.
enum BudgetTheme {
    static func screenBackground(_ scheme: ColorScheme) -> some ShapeStyle {
        scheme == .dark
            ? AnyShapeStyle(
                LinearGradient(
                    colors: [BudgetColor.graphite, BudgetColor.midnight],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            : AnyShapeStyle(Color(red: 246 / 255, green: 247 / 255, blue: 250 / 255))
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.offWhite : BudgetColor.graphite
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.coolGray : Color(red: 90 / 255, green: 99 / 255, blue: 115 / 255)
    }

    static func cardFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.midnight.opacity(0.48) : Color.white.opacity(0.72)
    }

    static func cardBorder(_ scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
            ? LinearGradient(
                colors: [.white.opacity(0.24), BudgetColor.indigo.opacity(0.28), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [BudgetColor.midnight.opacity(0.14), BudgetColor.indigo.opacity(0.18), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }
}

extension LinearGradient {
    /// Restrained indigo→violet accent used on active/hero elements.
    static let budgetAccent = LinearGradient(
        colors: [BudgetColor.indigo, BudgetColor.violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Luminous blue→indigo→violet ramp for chart strokes.
    static let budgetChartLine = LinearGradient(
        colors: [BudgetColor.electricBlue, BudgetColor.indigo, BudgetColor.violet],
        startPoint: .leading,
        endPoint: .trailing
    )
}

/// 8 pt spacing rhythm; 4 pt reserved for micro-alignment.
enum BudgetSpacing {
    static let micro: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32

    /// Horizontal screen margin.
    static let screenMargin: CGFloat = 20
}

enum BudgetRadius {
    static let card: CGFloat = 24
    static let control: CGFloat = 14
}

/// Typography roles from the design system. All roles rely on
/// Dynamic Type text styles so accessibility sizes keep working.
enum BudgetFont {
    /// Hero amount, monospaced digits so amounts do not jitter.
    static var heroAmount: Font {
        .system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit()
    }

    static var screenTitle: Font {
        .system(.title, design: .default).weight(.bold)
    }

    static var sectionTitle: Font {
        .system(.headline, design: .default).weight(.semibold)
    }

    static var cardLabel: Font {
        .system(.footnote, design: .default).weight(.medium)
    }

    static var body: Font {
        .system(.body, design: .default)
    }

    static var caption: Font {
        .system(.caption, design: .default)
    }

    static var amount: Font {
        .system(.body, design: .default).weight(.semibold).monospacedDigit()
    }
}
