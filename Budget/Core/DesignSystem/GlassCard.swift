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

/// Wrapper de compatibilité des anciennes cartes vers Budget Prisme.
///
/// L'API reste stable pour ne toucher ni les écrans ni leurs données. Le
/// rendu est désormais le même que Neon Ultra : surfaces mates, listes sans
/// ombre et un seul liseré spectral discret sur le héros.
struct GlassCard<Content: View>: View {
    enum Style: Equatable {
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
                radius: style == .hero ? 18 : 0,
                y: style == .hero ? 10 : 0
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
        case .hero: NeonUltraRadius.hero
        case .standard: NeonUltraRadius.card
        case .row: NeonUltraRadius.control
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(fillStyle)
            .overlay {
                shape.strokeBorder(NeonUltraColor.border, lineWidth: 1)
                if style == .hero && !isOpaqueFallback {
                    shape
                        .strokeBorder(NeonUltraGradient.prismEdge, lineWidth: 1)
                        .opacity(0.42)
                }
            }
    }

    private var fillStyle: AnyShapeStyle {
        // Transparence réduite : surface graphite OPAQUE, sans blur.
        if isOpaqueFallback {
            return AnyShapeStyle(NeonUltraColor.surfaceFallback)
        }
        switch style {
        case .hero:
            return AnyShapeStyle(NeonUltraColor.surfaceElevated)
        case .standard, .row:
            return AnyShapeStyle(NeonUltraColor.surface)
        }
    }

    private var shadowColor: Color {
        style == .hero && !isOpaqueFallback ? Color.black.opacity(0.45) : .clear
    }
}

/// Full-screen branded background used behind every screen.
struct BudgetScreenBackground: View {
    var body: some View {
        Rectangle()
            .fill(NeonUltraColor.canvas)
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
