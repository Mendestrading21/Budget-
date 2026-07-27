import SwiftUI

// ============================================================
// Budget — Neon Ultra · primitives réutilisables (ADR-024, NU1)
// ------------------------------------------------------------
// ISOLÉES : aucun écran de l'application ne les utilise encore
// (rebranchement réservé à NU2/NU3). Aucune couleur brute ici —
// uniquement les rôles `NeonUltraColor`/`NeonUltraGradient`.
// Cartes mates SANS blur ; la carte élevée porte une profondeur
// subtile (ombre noire), jamais un glow. Reduce Transparency
// remplace toute surface par `surfaceFallback` ; Reduce Motion
// neutralise les transitions.
// ============================================================

/// Bascule déterministe de « transparence réduite » pour les tests et
/// la galerie (même mécanisme que la famille Obsidian, clé distincte).
private struct NeonUltraForcedReducedTransparencyKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var neonUltraForcedReducedTransparency: Bool {
        get { self[NeonUltraForcedReducedTransparencyKey.self] }
        set { self[NeonUltraForcedReducedTransparencyKey.self] = newValue }
    }
}

/// Résolution des surfaces sous Reduce Transparency : toute surface
/// (déjà opaque par conception — cartes mates) bascule sur le
/// remplaçant opaque canonique `surfaceFallback`, sans blur ni halo.
enum NeonUltraSurfaceResolver {
    static func surface(reduceTransparency: Bool) -> Color {
        reduceTransparency ? NeonUltraColor.surfaceFallback : NeonUltraColor.surface
    }

    static func elevated(reduceTransparency: Bool) -> Color {
        reduceTransparency ? NeonUltraColor.surfaceFallback : NeonUltraColor.surfaceElevated
    }
}

// MARK: - Cartes

/// Carte standard MATE : surface `#11141C`, bordure `#293040`,
/// aucun blur, aucune ombre — la carte des listes denses.
struct NeonUltraCard<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.neonUltraForcedReducedTransparency) private var forcedReduceTransparency
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(BudgetSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                NeonUltraSurfaceResolver.surface(
                    reduceTransparency: systemReduceTransparency || forcedReduceTransparency
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: NeonUltraRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeonUltraRadius.card, style: .continuous)
                    .stroke(NeonUltraColor.border, lineWidth: 1)
            )
    }
}

/// Carte ÉLEVÉE : surface `#181C26`, profondeur subtile par ombre
/// noire (jamais un glow coloré), aucun blur. Sous Reduce
/// Transparency : `surfaceFallback` opaque et ombre retirée.
struct NeonUltraElevatedCard<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.neonUltraForcedReducedTransparency) private var forcedReduceTransparency
    @ViewBuilder var content: Content

    var body: some View {
        let reduced = systemReduceTransparency || forcedReduceTransparency
        content
            .padding(BudgetSpacing.heroPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NeonUltraSurfaceResolver.elevated(reduceTransparency: reduced))
            .clipShape(RoundedRectangle(cornerRadius: NeonUltraRadius.hero, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeonUltraRadius.hero, style: .continuous)
                    .stroke(NeonUltraColor.border, lineWidth: 1)
            )
            .shadow(
                color: reduced ? .clear : Color.black.opacity(0.45),
                radius: 18, x: 0, y: 10
            )
    }
}

// MARK: - Boutons

/// CTA principal — SEUL usage du dégradé de marque. Texte
/// `textOnCta` (blanc pur : 5,56 / 7,43 sur les deux extrémités),
/// cible ≥ 44 pt, pression 0,98 respectant Reduce Motion.
struct NeonUltraPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NeonUltraTypography.label)
            .foregroundStyle(NeonUltraColor.textOnCta)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, BudgetSpacing.medium)
            .background(NeonUltraGradient.cta)
            .clipShape(RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? NeonUltraMotion.pressScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: NeonUltraMotion.press),
                value: configuration.isPressed
            )
    }
}

/// Bouton secondaire — surface opaque `surfaceFallback`, bordure,
/// texte `textPrimary` (jamais le violet seul sur un petit libellé).
struct NeonUltraSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NeonUltraTypography.label)
            .foregroundStyle(NeonUltraColor.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, BudgetSpacing.medium)
            .background(NeonUltraColor.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous)
                    .stroke(NeonUltraColor.border, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? NeonUltraMotion.pressScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: NeonUltraMotion.press),
                value: configuration.isPressed
            )
    }
}

/// Variante destructive — STRICTEMENT sémantique (corail), jamais la
/// marque : teinte translucide dérivée + bordure + texte corail.
struct NeonUltraDestructiveButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NeonUltraTypography.label)
            .foregroundStyle(NeonUltraColor.negative)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, BudgetSpacing.medium)
            .background(NeonUltraColor.tintNegative)
            .clipShape(RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous)
                    .stroke(NeonUltraColor.negative, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? NeonUltraMotion.pressScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: NeonUltraMotion.press),
                value: configuration.isPressed
            )
    }
}

// MARK: - Chip

/// Chip Neon Ultra — trois états réels : normal, sélectionné,
/// désactivé. RÈGLE AA : l'état sélectionné garde le texte
/// `textPrimary` et signale la sélection par l'INDICATEUR violet
/// (point + bordure), jamais par un libellé violet seul (3,41:1).
struct NeonUltraChip: View {
    let label: String
    var isSelected = false
    var isDisabled = false

    var body: some View {
        HStack(spacing: 6) {
            if isSelected {
                Circle()
                    .fill(NeonUltraColor.violet)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }
            Text(label)
                .font(NeonUltraTypography.label)
                .foregroundStyle(NeonUltraColor.textPrimary)
        }
        .padding(.horizontal, BudgetSpacing.compact)
        .frame(minHeight: 44)
        .background(isSelected ? NeonUltraColor.tintViolet : NeonUltraColor.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(
                isSelected ? NeonUltraColor.violet : NeonUltraColor.border,
                lineWidth: isSelected ? 1.5 : 1
            )
        )
        .opacity(isDisabled ? 0.4 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isDisabled ? "Indisponible" : "")
    }
}

// MARK: - Badge

/// Badge d'état — TOUJOURS texte + symbole, jamais la couleur seule.
/// Les rôles sémantiques ne sont jamais remplacés par la marque.
struct NeonUltraBadge: View {
    enum Kind {
        case positive, negative, warning, neutral

        var color: Color {
            switch self {
            case .positive: NeonUltraColor.positive
            case .negative: NeonUltraColor.negative
            case .warning: NeonUltraColor.warning
            case .neutral: NeonUltraColor.textSecondary
            }
        }

        var tint: Color {
            switch self {
            case .positive: NeonUltraColor.tintPositive
            case .negative: NeonUltraColor.tintNegative
            case .warning: NeonUltraColor.tintWarning
            case .neutral: NeonUltraColor.tintNeutral
            }
        }

        var symbol: String {
            switch self {
            case .positive: "checkmark"
            case .negative: "exclamationmark.triangle"
            case .warning: "clock"
            case .neutral: "circle"
            }
        }
    }

    let kind: Kind
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: kind.symbol)
                .font(.system(size: 9, weight: .bold))
                .accessibilityHidden(true)
            Text(label)
                .font(NeonUltraTypography.meta.weight(.bold))
        }
        .foregroundStyle(kind.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(kind.tint)
        .clipShape(Capsule())
        .accessibilityLabel(label)
    }
}

// MARK: - Montant

/// Montant financier Neon Ultra — `FinanceFormatting` (fr-CH, jamais
/// de calcul local), chiffres tabulaires, UNE ligne jamais tronquée,
/// AUCUN glow ni effet lumineux. Négatif = corail sémantique.
struct NeonUltraAmountText: View {
    let amount: Decimal
    var hero = false

    var body: some View {
        Text(FinanceFormatting.chf(amount))
            .font(hero ? NeonUltraTypography.heroAmount : NeonUltraTypography.amount)
            .foregroundStyle(amount < 0 ? NeonUltraColor.negative : NeonUltraColor.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityLabel(FinanceFormatting.chf(amount))
    }
}

// MARK: - Focus

extension View {
    /// Anneau de focus visible Neon Ultra : cyan (préféré au violet sur
    /// fond sombre, contraste non textuel ≥ 3:1), ≥ 2 pt, décalé.
    func neonUltraFocusRing(_ focused: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous)
                .stroke(focused ? NeonUltraColor.cyan : .clear, lineWidth: 2)
                .padding(-3)
        )
    }
}
