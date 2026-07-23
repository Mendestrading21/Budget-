import SwiftUI

// MARK: - AmountText

/// Montant financier Obsidian : chiffres tabulaires, jamais tronqué
/// (y compris `CHF -9'999'999.99`), teinte STRICTEMENT sémantique.
/// Tout le formatage est délégué à `FinanceFormatting` — ce composant
/// n'introduit AUCUN calcul financier.
struct AmountText: View {
    enum Role {
        /// 36-44 pt, carte héros.
        case hero
        /// Ligne de liste ou métrique.
        case standard
    }

    enum Emphasis {
        case neutral
        case positive
        case negative
        case warning
    }

    let amount: Decimal
    var role: Role = .standard
    /// `true` : affiche `+CHF …` / `-CHF …` (flux) via `chfSigned`.
    var signed: Bool = false
    var emphasis: Emphasis = .neutral

    var body: some View {
        Text(formatted)
            .font(role == .hero ? BudgetFont.heroAmount : BudgetFont.amount)
            .foregroundStyle(color)
            .lineLimit(1)
            // Un montant à sept chiffres se resserre au lieu d'être coupé.
            .minimumScaleFactor(role == .hero ? 0.45 : 0.6)
            .accessibilityLabel(Text(formatted))
    }

    private var formatted: String {
        signed ? FinanceFormatting.chfSigned(amount) : FinanceFormatting.chf(amount)
    }

    private var color: Color {
        switch emphasis {
        case .neutral: BudgetColor.textPrimary
        case .positive: BudgetColor.positive
        case .negative: BudgetColor.negative
        case .warning: BudgetColor.warning
        }
    }
}

// MARK: - StatusPill

/// Badge de statut : combine TOUJOURS un symbole et un texte avec la
/// couleur — jamais la couleur seule (accessibilité).
struct StatusPill: View {
    enum Kind {
        case positive
        case negative
        case warning
        case neutral

        var color: Color {
            switch self {
            case .positive: BudgetColor.positive
            case .negative: BudgetColor.negative
            case .warning: BudgetColor.warning
            case .neutral: BudgetColor.textSecondary
            }
        }

        var symbol: String {
            switch self {
            case .positive: "checkmark.circle.fill"
            case .negative: "exclamationmark.circle.fill"
            case .warning: "clock.fill"
            case .neutral: "circle.dashed"
            }
        }

        var fill: Color {
            switch self {
            case .positive: BudgetColor.positive.opacity(0.16)
            case .negative: BudgetColor.negative.opacity(0.14)
            case .warning: BudgetColor.warning.opacity(0.18)
            case .neutral: Color.white.opacity(0.08)
            }
        }
    }

    let text: String
    let kind: Kind

    var body: some View {
        HStack(spacing: BudgetSpacing.micro) {
            Image(systemName: kind.symbol)
                .font(.caption2)
                .accessibilityHidden(true)
            Text(text)
                .font(BudgetFont.caption.weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(kind.color)
        .background(kind.fill, in: Capsule())
    }
}

// MARK: - Boutons

/// Bouton primaire Obsidian : fond indigo profond dérivé (blanc AA),
/// cible ≥ 44 pt, pression 0.98 respectant `accessibilityReduceMotion`.
struct PrimaryActionButtonStyle: ButtonStyle {
    /// `true` : variante destructive (corail sémantique, jamais décoratif).
    var destructive = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BudgetFont.body.weight(.bold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(destructive ? BudgetColor.negative : .white)
            .background(background, in: RoundedRectangle(cornerRadius: BudgetRadius.control, style: .continuous))
            .overlay {
                if destructive {
                    RoundedRectangle(cornerRadius: BudgetRadius.control, style: .continuous)
                        .strokeBorder(BudgetColor.negative, lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var background: AnyShapeStyle {
        if destructive {
            return AnyShapeStyle(BudgetColor.negative.opacity(0.14))
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [BudgetColor.brandDeep, BudgetColor.brandDeep.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

/// Bouton secondaire : surface graphite, texte indigo clair.
struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BudgetFont.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(BudgetColor.brandBright)
            .background(BudgetColor.glassFallback, in: RoundedRectangle(cornerRadius: BudgetRadius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: BudgetRadius.control, style: .continuous)
                    .strokeBorder(BudgetColor.stroke, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - ObsidianSheet

/// Surface de feuille/popover Obsidian : verre fort, rayon héros,
/// opaque quand la transparence est réduite.
struct ObsidianSheetSurface<Content: View>: View {
    private let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.obsidianForcedReducedTransparency) private var forcedFallback

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(BudgetSpacing.heroPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = UnevenRoundedRectangle(
                    topLeadingRadius: BudgetRadius.hero,
                    topTrailingRadius: BudgetRadius.hero,
                    style: .continuous
                )
                if reduceTransparency || forcedFallback {
                    shape.fill(BudgetColor.glassFallback)
                        .overlay { shape.strokeBorder(BudgetColor.stroke, lineWidth: 1) }
                } else {
                    shape.fill(.ultraThinMaterial)
                        .overlay { shape.fill(BudgetColor.glassStrong.opacity(0.55)) }
                        .overlay { shape.strokeBorder(BudgetColor.stroke, lineWidth: 1) }
                }
            }
    }
}

// MARK: - États vide et erreur

/// État vide guidé : glyphe, titre, phrase courte, action facultative.
struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: BudgetSpacing.small) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundStyle(BudgetColor.textSecondary)
                .accessibilityHidden(true)
            Text(title)
                .font(BudgetFont.sectionTitle)
                .foregroundStyle(BudgetColor.textPrimary)
            Text(message)
                .font(BudgetFont.body)
                .foregroundStyle(BudgetColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryActionButtonStyle())
                    .padding(.top, BudgetSpacing.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(BudgetSpacing.large)
    }
}

/// État d'erreur récupérable : message honnête + action de reprise.
/// Le corail est sémantique et toujours accompagné de texte et symbole.
struct ErrorState: View {
    let title: String
    let message: String
    var retryTitle: String?
    var retry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            HStack(spacing: BudgetSpacing.small) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(BudgetColor.negative)
                    .accessibilityHidden(true)
                Text(title)
                    .font(BudgetFont.sectionTitle)
                    .foregroundStyle(BudgetColor.textPrimary)
            }
            Text(message)
                .font(BudgetFont.body)
                .foregroundStyle(BudgetColor.textSecondary)
            if let retryTitle, let retry {
                Button(retryTitle, action: retry)
                    .buttonStyle(SecondaryActionButtonStyle())
                    .padding(.top, BudgetSpacing.micro)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BudgetSpacing.cardPadding)
        .background(
            BudgetColor.negative.opacity(0.14),
            in: RoundedRectangle(cornerRadius: BudgetRadius.card, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: BudgetRadius.card, style: .continuous)
                .strokeBorder(BudgetColor.negative, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
