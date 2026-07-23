import SwiftUI

/// Obsidian Glass — tokens sémantiques (ADR-020, ADR-022).
/// UNE seule identité sombre : plus aucune résolution clair/sombre.
/// Les valeurs brutes vivent UNIQUEMENT ici ; les vues référencent les rôles.
/// Vert, corail et ambre sont STRICTEMENT sémantiques — jamais décoratifs.
enum BudgetColor {
    // MARK: - Rôles Obsidian canoniques (constitution §2)

    /// `#090C12` — fond principal.
    static let canvas = rgb(9, 12, 18)
    /// `#0D1119` — zone élevée ou navigation.
    static let canvasRaised = rgb(13, 17, 25)
    /// `rgba(20,25,37,0.72)` — carte standard.
    static let glass = rgb(20, 25, 37, alpha: 0.72)
    /// `rgba(27,34,48,0.88)` — héros, feuille, popover.
    static let glassStrong = rgb(27, 34, 48, alpha: 0.88)
    /// `#151B26` — surface opaque quand la transparence est réduite.
    static let glassFallback = rgb(21, 27, 38)
    /// `rgba(255,255,255,0.10)` — bord standard.
    static let stroke = Color.white.opacity(0.10)
    /// `rgba(115,103,255,0.48)` — sélection ou focus.
    static let strokeActive = rgb(115, 103, 255, alpha: 0.48)
    /// `#7367FF` — Indigo Aurora : action, série principale, focus.
    static let brand = rgb(115, 103, 255)
    /// `#9188FF` — surbrillance de la même teinte.
    static let brandBright = rgb(145, 136, 255)
    /// `#F6F7FB` — montants et titres.
    static let textPrimary = rgb(246, 247, 251)
    /// `#A7B0C0` — explications.
    static let textSecondary = rgb(167, 176, 192)
    /// `#758094` — métadonnées.
    static let textTertiary = rgb(117, 128, 148)
    /// `#36D399` — sémantique : progrès, résultat favorable.
    static let positive = rgb(54, 211, 153)
    /// `#FF6B7A` — sémantique : perte, dépassement, erreur.
    static let negative = rgb(255, 107, 122)
    /// `#FFB454` — sémantique : échéance, attention.
    static let warning = rgb(255, 180, 84)

    // MARK: - Tons dérivés de l'indigo (constitution : dérivés permis)

    /// `#6457F0` — fond des boutons primaires : texte blanc AA (≥ 4.5:1).
    static let brandDeep = rgb(100, 87, 240)

    // MARK: - Alias hérités (transition L2 — À RETIRER après la refonte
    // des écrans, L3+). Chaque alias pointe vers `brand`, `brandBright`
    // ou un rôle Obsidian : aucune teinte teal, cyan, violette ou bleu
    // électrique indépendante ne reste active.

    /// Alias hérité → `canvas`.
    static let graphite = canvas
    /// Alias hérité → `canvasRaised`.
    static let midnight = canvasRaised
    /// Alias hérité → `glassFallback`.
    static let slateBlue = glassFallback
    /// Alias hérité → `brand`.
    static let indigo = brand
    /// Ex-bleu électrique `#5AA7FF` → `brandBright`.
    static let electricBlue = brandBright
    /// Ex-violet `#8B5CF6` → `brandBright`.
    static let violet = brandBright
    /// Ex-cyan `#55DDE0` → `brandBright`.
    static let cyan = brandBright
    /// Ex-teal `#2DD4BF` → `brandBright`.
    static let teal = brandBright
    /// Alias hérité → `textPrimary`.
    static let offWhite = textPrimary
    /// Alias hérité → `textSecondary`.
    static let coolGray = textSecondary
    /// Ex-bleu informatif → `brandBright`.
    static let informative = brandBright

    private static func rgb(_ r: Double, _ g: Double, _ b: Double, alpha: Double = 1) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255, opacity: alpha)
    }
}

/// Teintes de pastilles par nature financière. Le paramètre `scheme` est
/// conservé pour ne pas toucher les sites d'appel existants (transition L2),
/// mais l'identité est unique : il n'est plus consulté.
/// Revenu vert / dépense corail = SÉMANTIQUE ; épargne, objectif et info
/// utilisent la teinte de marque (les ex-teal/violet ont disparu).
enum BudgetTint {
    static func income(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.positive.opacity(0.16)
    }

    static func expense(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.negative.opacity(0.14)
    }

    static func saving(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.brand.opacity(0.16)
    }

    static func goal(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.brand.opacity(0.16)
    }

    static func info(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.brand.opacity(0.14)
    }

    static func neutral(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color.white.opacity(0.08)
    }
}

/// Rôles d'apparence. Le paramètre `scheme` est conservé pour la
/// compatibilité des sites d'appel (transition L2) mais n'est plus
/// consulté : l'identité Obsidian est unique et sombre.
enum BudgetTheme {
    static func screenBackground(_ scheme: ColorScheme) -> some ShapeStyle {
        _ = scheme
        return AnyShapeStyle(
            LinearGradient(
                colors: [BudgetColor.canvas, BudgetColor.canvasRaised],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.textPrimary
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.textSecondary
    }

    static func cardFill(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return BudgetColor.glass
    }

    static func cardBorder(_ scheme: ColorScheme) -> LinearGradient {
        _ = scheme
        return LinearGradient(
            colors: [.white.opacity(0.16), BudgetColor.strokeActive, .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension LinearGradient {
    /// Accent indigo retenu des CTA — profond vers marque, même teinte
    /// (le blanc reste AA sur toute la course pour un glyphe/texte large).
    static let budgetAccent = LinearGradient(
        colors: [BudgetColor.brandDeep, BudgetColor.brand],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Rampe de la série principale des graphiques — indigo unique.
    static let budgetChartLine = LinearGradient(
        colors: [BudgetColor.brandBright, BudgetColor.brand],
        startPoint: .leading,
        endPoint: .trailing
    )
}

/// Grille 4 / 8 / 12 / 16 / 24 / 32 (constitution §3).
enum BudgetSpacing {
    static let micro: CGFloat = 4
    static let small: CGFloat = 8
    static let compact: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32

    /// Marge horizontale d'écran.
    static let screenMargin: CGFloat = 18
    /// Padding interne d'une carte héros.
    static let heroPadding: CGFloat = 24
    /// Padding interne d'une carte standard.
    static let cardPadding: CGFloat = 18
}

enum BudgetRadius {
    /// Carte héros ou feuille.
    static let hero: CGFloat = 28
    /// Carte standard.
    static let card: CGFloat = 22
    /// Contrôle, ligne de liste.
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
