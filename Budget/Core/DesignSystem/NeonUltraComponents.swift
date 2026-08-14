import SwiftUI

// ============================================================
// Budget — Neon Ultra · primitives réutilisables (ADR-024, NU1)
// ------------------------------------------------------------
// PORTÉE (depuis NU3) : ces primitives habillent EXACTEMENT trois
// surfaces natives — Mois (`HomeTab`), Budget (`BudgetTab`) et la
// feuille Nouveau mouvement (`TransactionFormView`). Tous les autres
// écrans restent Obsidian jusqu'à NU4–NU7. Aucune couleur brute ici —
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

/// Résolution du mouvement sous Reduce Motion : la DÉCISION unique que
/// tous les styles de bouton Neon Ultra appliquent. Sous réduction des
/// animations : aucune échelle de pression (1,0) et aucune animation
/// (nil). Sinon : pression `NeonUltraMotion.pressScale` (0,98) animée
/// sur `NeonUltraMotion.press`.
enum NeonUltraMotionResolver {
    static func pressScale(isPressed: Bool, reduceMotion: Bool) -> CGFloat {
        guard isPressed, !reduceMotion else { return 1 }
        return NeonUltraMotion.pressScale
    }

    static func pressAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: NeonUltraMotion.press)
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

// MARK: - Fond d'écran

/// Fond d'écran Neon Ultra — noir profond `#05060A`, opaque, sans
/// dégradé ni halo. DISTINCT de `BudgetScreenBackground` (Obsidian) :
/// c'est ce qui garantit qu'un écran non piloté ne change pas de fond.
struct NeonUltraScreenBackground: View {
    var body: some View {
        Rectangle()
            .fill(NeonUltraColor.canvas)
            .ignoresSafeArea()
    }
}

/// Marge de fin de défilement des surfaces PILOTES.
///
/// Remplace `obsidianFABClearance()` sur ces écrans. Cette dernière réserve
/// 80 pt pour un ＋ flottant qui n'existe PLUS : ADR-026 a supprimé l'ajout
/// global. Les captures simulateur NU3 le montrent noir sur noir — une bande
/// vide d'environ 80 pt entre le dernier contenu et la barre d'onglets, sur
/// Mois comme sur Budget. On garde la respiration de fin de liste, on rend
/// les 80 pt au contenu.
extension View {
    func neonUltraScrollClearance() -> some View {
        contentMargins(.bottom, BudgetSpacing.medium, for: .scrollContent)
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

/// Carte ÉLEVÉE Budget Prisme : surface `#181C26`, profondeur subtile par
/// ombre noire et un liseré spectral d'un point. Ce liseré est la signature
/// rare du héros — il ne se répète jamais sur les cartes de liste. Sous
/// Reduce Transparency : `surfaceFallback` opaque, bord simple et ombre
/// retirée.
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
            .overlay {
                let shape = RoundedRectangle(
                    cornerRadius: NeonUltraRadius.hero,
                    style: .continuous
                )
                shape.stroke(NeonUltraColor.border, lineWidth: 1)
                if !reduced {
                    shape
                        .stroke(NeonUltraGradient.prismEdge, lineWidth: 1)
                        .opacity(0.42)
                }
            }
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
            .scaleEffect(NeonUltraMotionResolver.pressScale(isPressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(
                NeonUltraMotionResolver.pressAnimation(reduceMotion: reduceMotion),
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
            .scaleEffect(NeonUltraMotionResolver.pressScale(isPressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(
                NeonUltraMotionResolver.pressAnimation(reduceMotion: reduceMotion),
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
            .scaleEffect(NeonUltraMotionResolver.pressScale(isPressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(
                NeonUltraMotionResolver.pressAnimation(reduceMotion: reduceMotion),
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
    /// `true` : affiche `+CHF …` / `-CHF …` via `chfSigned`. Un solde de
    /// FIN de mois se lit avec son signe — le sens ne repose jamais sur la
    /// seule couleur (constitution).
    var signed = false

    private var formatted: String {
        signed ? FinanceFormatting.chfSigned(amount) : FinanceFormatting.chf(amount)
    }

    var body: some View {
        Text(formatted)
            .font(hero ? NeonUltraTypography.heroAmount : NeonUltraTypography.amount)
            .foregroundStyle(amount < 0 ? NeonUltraColor.negative : NeonUltraColor.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityLabel(formatted)
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
