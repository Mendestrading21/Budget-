import SwiftUI

/// Mécanisme DÉTERMINISTE de vérification de la transparence réduite
/// (previews et tests) — miroir du `html[data-reduced-transparency]` web.
/// Le réglage système `accessibilityReduceTransparency` reste prioritaire.
private struct ForcedReducedTransparencyKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var obsidianForcedReducedTransparency: Bool {
        get { self[ForcedReducedTransparencyKey.self] }
        set { self[ForcedReducedTransparencyKey.self] = newValue }
    }
}

/// Carte verre Obsidian : surface translucide, reflet supérieur discret,
/// bord d'un point et une seule ombre extérieure mesurée.
///
/// `style` dose le traitement — `.hero` pour la carte principale (verre
/// fort + blur), `.standard` pour les cartes de section, `.row` pour les
/// cellules de listes où tout matériau lourd nuirait aux performances.
struct GlassCard<Content: View>: View {
    enum Style {
        case hero
        case standard
        case row
    }

    private let style: Style
    private let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.obsidianForcedReducedTransparency) private var forcedFallback

    init(style: Style = .standard, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { background }
            .shadow(
                color: shadowColor,
                radius: style == .hero ? 24 : 12,
                y: style == .hero ? 12 : 6
            )
    }

    private var isOpaqueFallback: Bool {
        reduceTransparency || forcedFallback
    }

    private var padding: CGFloat {
        switch style {
        case .hero: BudgetSpacing.heroPadding
        case .standard: BudgetSpacing.cardPadding
        case .row: BudgetSpacing.medium
        }
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .hero: BudgetRadius.hero
        case .standard: BudgetRadius.card
        case .row: BudgetRadius.control
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(fillStyle)
            .overlay {
                // Voile de verre fort par-dessus l'unique matériau du héros.
                if style == .hero && !isOpaqueFallback {
                    shape.fill(BudgetColor.glassStrong.opacity(0.55))
                }
            }
            .overlay {
                // Reflet supérieur très discret — supprimé sans transparence.
                if !isOpaqueFallback {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.06), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            }
            .overlay {
                shape.strokeBorder(borderStyle, lineWidth: 1)
            }
    }

    private var fillStyle: AnyShapeStyle {
        // Transparence réduite : surface graphite OPAQUE, sans blur.
        if isOpaqueFallback {
            return AnyShapeStyle(BudgetColor.glassFallback)
        }
        switch style {
        case .hero:
            // Un seul matériau (blur mesuré) — le voile glassStrong est
            // appliqué en overlay dans `background`.
            return AnyShapeStyle(.ultraThinMaterial)
        case .standard, .row:
            // Cellule légère : pas de matériau dans les listes.
            return AnyShapeStyle(BudgetColor.glass)
        }
    }

    private var borderStyle: AnyShapeStyle {
        if isOpaqueFallback {
            return AnyShapeStyle(BudgetColor.stroke)
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [.white.opacity(0.16), BudgetColor.strokeActive, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var shadowColor: Color {
        style == .hero ? BudgetColor.brand.opacity(0.14) : Color.black.opacity(0.25)
    }
}

/// Full-screen branded background used behind every screen.
struct BudgetScreenBackground: View {
    var body: some View {
        Rectangle()
            .fill(BudgetTheme.screenBackground(.dark))
            .ignoresSafeArea()
    }
}

#Preview("GlassCard", traits: .sizeThatFitsLayout) {
    ZStack {
        BudgetScreenBackground()
        VStack(spacing: BudgetSpacing.medium) {
            GlassCard(style: .hero) {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text("Disponible ce mois")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(BudgetColor.textSecondary)
                    Text("CHF 2'450.00")
                        .font(BudgetFont.heroAmount)
                        .foregroundStyle(BudgetColor.textPrimary)
                }
            }
            GlassCard(style: .row) {
                Text("Ligne de liste")
                    .foregroundStyle(BudgetColor.textPrimary)
            }
        }
        .padding(BudgetSpacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
