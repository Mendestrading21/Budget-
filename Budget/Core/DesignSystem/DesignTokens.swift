import SwiftUI

/// Obsidian Glass — tokens sémantiques (ADR-020, ADR-022).
/// UNE seule identité sombre : plus aucune résolution clair/sombre.
/// Les valeurs brutes vivent UNIQUEMENT ici ; les vues référencent les rôles.
/// Vert, corail et ambre sont STRICTEMENT sémantiques — jamais décoratifs.
enum BudgetColor {
    // MARK: - Rôles Obsidian canoniques (constitution §2)

    // Surfaces unifiées sur Neon Ultra (ADR-024). Mesuré côté web avant
    // correction : le fond noir CHANGEAIT d'un onglet à l'autre et les
    // cartes n'avaient pas la même matière. Le natif portait exactement la
    // même divergence — deux plateformes, quatre couleurs de fond. Ces cinq
    // valeurs sont désormais celles de `NeonUltraColor`, et les cartes sont
    // MATES : plus de `.ultraThinMaterial`, c'est ce qu'impose l'identité
    // cible et c'est aussi plus lisible sur un fond très sombre.
    /// `#05060A` — fond principal.
    static let canvas = rgb(5, 6, 10)
    /// `#0B0D13` — zone élevée ou navigation.
    static let canvasRaised = rgb(11, 13, 19)
    /// `#11141C` — carte standard, mate.
    static let glass = rgb(17, 20, 28)
    /// `#181C26` — héros, feuille, popover — mate.
    static let glassStrong = rgb(24, 28, 38)
    /// `#151923` — surface opaque quand la transparence est réduite.
    static let glassFallback = rgb(21, 25, 35)
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

    /// Diamètre du ＋ flottant global (cible ≥ 44 pt).
    static let fabDiameter: CGFloat = 52
    /// Décalage du ＋ au-dessus du bord inférieur de l'écran.
    static let fabBottomOffset: CGFloat = 62
    /// Hauteur de la zone d'EXCLUSION permanente sous les contenus
    /// défilants survolés par le ＋. Le ＋ culmine à
    /// `fabBottomOffset + fabDiameter` = 114 pt du bord de l'écran ; une
    /// tab bar compacte (49 pt, sans home indicator) en absorbe le
    /// moins. 49 + 80 = 129 pt ≥ 114 + 8 : le viewport s'arrête toujours
    /// AU-DESSUS du ＋, sur tous les iPhone — rien ne peut être rendu ni
    /// masqué dessous, avant comme après défilement.
    static let fabExclusionHeight: CGFloat = 80
}

extension View {
    /// Zone d'exclusion PERMANENTE du ＋ flottant : rétrécit réellement le
    /// viewport du contenu défilant (padding, pas une simple marge de
    /// défilement) — aucun élément ne peut apparaître sous le ＋, dans
    /// l'état initial comme après défilement. Une petite marge de fin de
    /// défilement complète le confort de lecture.
    func obsidianFABClearance() -> some View {
        contentMargins(.bottom, BudgetSpacing.medium, for: .scrollContent)
            .clipped() // ceinture : rien ne peut être DESSINÉ sous la bande
            .padding(.bottom, BudgetSpacing.fabExclusionHeight)
    }
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

// ============================================================
// Budget — Neon Ultra · tokens canoniques (ADR-024, NU1)
// ------------------------------------------------------------
// FAMILLE PARALLÈLE ET ISOLÉE : aucun écran de l'application ne
// référence encore ces rôles (le rebranchement est réservé aux
// lots NU2/NU3). Les valeurs brutes vivent UNIQUEMENT ici ; les
// primitives `NeonUltra*` référencent les rôles. Rien de ce qui
// précède (BudgetColor/Tint/Theme/Spacing/Radius/Font, gradients
// Obsidian) n'est modifié.
// Vert, corail et ambre restent STRICTEMENT sémantiques.
// ============================================================

/// Rôles de couleur Neon Ultra (constitution Neon Ultra §1).
/// Une seule identité sombre — aucune variation clair/sombre.
enum NeonUltraColor {
    // MARK: - Fonds et surfaces (opaques : cartes mates, jamais de blur)

    /// `#05060A` — fond d'écran global.
    static let canvas = rgb(5, 6, 10)
    /// `#0B0D13` — barre d'onglets, barres système.
    static let navigation = rgb(11, 13, 19)
    /// `#11141C` — carte standard (liste, cellule) — mate.
    static let surface = rgb(17, 20, 28)
    /// `#181C26` — carte élevée (héros, feuille).
    static let surfaceElevated = rgb(24, 28, 38)
    /// `#151923` — remplaçant opaque de TOUTE surface translucide
    /// quand la transparence est réduite.
    static let surfaceFallback = rgb(21, 25, 35)
    /// `#293040` — séparations et contours de cartes.
    static let border = rgb(41, 48, 64)

    // MARK: - Néons (≤ 10 % d'un écran, un seul point focal majeur)

    /// `#D946EF` — accent principal de marque.
    static let magenta = rgb(217, 70, 239)
    /// `#7C3AED` — accent secondaire, états actifs. ≈ 3,41:1 sur la
    /// navigation : ne porte JAMAIS seul un petit libellé actif — le
    /// texte actif reste `textPrimary`, accompagné d'un indicateur
    /// violet.
    static let violet = rgb(124, 58, 237)
    /// `#38BDF8` — information, sélection de graphique, focus.
    static let cyan = rgb(56, 189, 248)
    /// `#C000A4` — départ du dégradé CTA.
    static let ctaStart = rgb(192, 0, 164)
    /// `#6E00E8` — arrivée du dégradé CTA.
    static let ctaEnd = rgb(110, 0, 232)

    // MARK: - Textes (AA mesuré sur les cinq surfaces)

    /// `#F5F7FA` — montants et titres.
    static let textPrimary = rgb(245, 247, 250)
    /// `#A3ACBA` — explications.
    static let textSecondary = rgb(163, 172, 186)
    /// `#7C8696` — métadonnées (corrigé AA le 27.07.2026 : ≥ 4,5:1
    /// sur les cinq surfaces, mesuré).
    static let textTertiary = rgb(124, 134, 150)
    /// `#FFFFFF` — texte du CTA : blanc pur, 5,56:1 / 7,43:1 mesurés
    /// sur les deux extrémités du dégradé.
    static let textOnCta = rgb(255, 255, 255)

    // MARK: - Sémantique financière (jamais décorative)

    /// `#35D39A` — entrées, progrès sain.
    static let positive = rgb(53, 211, 154)
    /// `#FF6577` — sorties, dépassement, erreur.
    static let negative = rgb(255, 101, 119)
    /// `#F6C453` — à surveiller, échéance.
    static let warning = rgb(246, 196, 83)

    // MARK: - Teintes translucides dérivées (badges/chips uniquement —
    // dérivées des rôles ci-dessus, jamais de nouvelle teinte)

    static let tintPositive = positive.opacity(0.14)
    static let tintNegative = negative.opacity(0.14)
    static let tintWarning = warning.opacity(0.16)
    static let tintNeutral = Color.white.opacity(0.07)
    static let tintViolet = violet.opacity(0.16)

    private static func rgb(_ r: Double, _ g: Double, _ b: Double, alpha: Double = 1) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255, opacity: alpha)
    }
}

/// Dégradés Neon Ultra — réservés au CTA principal, à la sélection et
/// aux courts moments de marque (constitution §2.3). Jamais sur les
/// cartes de listes, jamais autour d'un montant.
enum NeonUltraGradient {
    /// CTA profond `135deg, #C000A4 → #6E00E8` (équivalent SwiftUI :
    /// topLeading → bottomTrailing).
    static let cta = LinearGradient(
        colors: [NeonUltraColor.ctaStart, NeonUltraColor.ctaEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Rayons Neon Ultra (parité avec `--nu-radius-*` côté PWA).
enum NeonUltraRadius {
    /// Carte élevée / héros / feuille.
    static let hero: CGFloat = 26
    /// Carte standard mate.
    static let card: CGFloat = 18
    /// Contrôle, chip, bouton.
    static let control: CGFloat = 14
}

/// Mouvement Neon Ultra : court, utile, jamais permanent.
/// Reduce Motion neutralise toute transition non essentielle.
enum NeonUltraMotion {
    /// Pression / focus : 120–160 ms.
    static let press: Double = 0.14
    /// Ouverture / changement d'état : ≤ 280 ms.
    static let state: Double = 0.24
    /// Échelle maximale de pression.
    static let pressScale: CGFloat = 0.98
}

/// Rôles typographiques Neon Ultra — police système, Dynamic Type,
/// chiffres tabulaires sur tous les montants (aucun glow, jamais).
enum NeonUltraTypography {
    /// Montant héros — chiffres tabulaires, sans effet lumineux.
    static var heroAmount: Font {
        .system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit()
    }

    /// Titre d'écran ou de carte.
    static var title: Font {
        .system(.title3, design: .default).weight(.bold)
    }

    /// Corps de texte.
    static var body: Font {
        .system(.body, design: .default)
    }

    /// Libellé de carte / chip.
    static var label: Font {
        .system(.footnote, design: .default).weight(.semibold)
    }

    /// Métadonnée discrète.
    static var meta: Font {
        .system(.caption, design: .default)
    }

    /// Montant courant — chiffres tabulaires.
    static var amount: Font {
        .system(.body, design: .default).weight(.semibold).monospacedDigit()
    }

    /// Montant SAISI dans une feuille : le champ dominant, sans être un
    /// héros. `heroAmount` (largeTitle) déborde d'une ligne de `Form` dès
    /// que le texte est agrandi ; `amount` (body) ne se distingue pas des
    /// autres libellés — la capture simulateur NU3 l'a montré. `title2`
    /// suit Dynamic Type et tient dans la ligne.
    static var formAmount: Font {
        .system(.title2, design: .default).weight(.semibold).monospacedDigit()
    }
}
