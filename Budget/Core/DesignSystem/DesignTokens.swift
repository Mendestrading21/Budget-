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

    // Semantic status — dynamic (ADR-019) : les teintes lumineuses de
    // l'identité sombre passent en versions assombries AA sur fond clair,
    // les mêmes valeurs que la PWA. Résolu par trait UIKit pour que tous
    // les sites d'appel existants restent inchangés.
    static let positive = dynamic(dark: (57, 217, 138), light: (11, 138, 87))     // #39D98A / #0B8A57
    static let negative = dynamic(dark: (255, 102, 122), light: (210, 59, 85))    // #FF667A / #D23B55
    static let warning = dynamic(dark: (255, 178, 77), light: (169, 106, 16))     // #FFB24D / #A96A10
    static let informative = dynamic(dark: (90, 167, 255), light: (37, 99, 235))  // #5AA7FF / #2563EB

    // Horizon v2 — accent teal premium, mêmes valeurs que la PWA.
    static let teal = dynamic(dark: (45, 212, 191), light: (13, 148, 136))     // #2DD4BF / #0D9488

    private static func dynamic(
        dark: (CGFloat, CGFloat, CGFloat),
        light: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255, alpha: 1)
        })
    }
}

/// Horizon v2 — teintes de pastilles d'icônes par nature financière,
/// miroir des tokens PWA (--tint-*). La pastille oriente avant la lecture :
/// revenu vert, dépense/impôt corail, épargne/investissement teal,
/// virement neutre, objectif/patrimoine violet.
enum BudgetTint {
    static func income(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.positive.opacity(0.16) : BudgetColor.positive.opacity(0.14)
    }

    static func expense(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.negative.opacity(0.14) : BudgetColor.negative.opacity(0.12)
    }

    static func saving(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.teal.opacity(0.15) : BudgetColor.teal.opacity(0.14)
    }

    static func goal(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.violet.opacity(0.16) : BudgetColor.violet.opacity(0.12)
    }

    static func info(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? BudgetColor.electricBlue.opacity(0.14) : BudgetColor.indigo.opacity(0.12)
    }

    static func neutral(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : BudgetColor.graphite.opacity(0.06)
    }
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
