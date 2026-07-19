import SwiftUI

/// Layered glass card: translucent fill, top-left highlight, one-pixel
/// gradient border and a single restrained outer shadow.
///
/// `style` controls how heavy the treatment is — `.hero` for the main
/// dashboard card, `.standard` for section cards, `.row` for scrolling
/// list cells where stacked materials would hurt performance.
struct GlassCard<Content: View>: View {
    enum Style {
        case hero
        case standard
        case row
    }

    private let style: Style
    private let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

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

    private var padding: CGFloat {
        switch style {
        case .hero: BudgetSpacing.large
        case .standard: BudgetSpacing.medium + BudgetSpacing.micro
        case .row: BudgetSpacing.medium
        }
    }

    private var cornerRadius: CGFloat {
        style == .row ? BudgetRadius.control : BudgetRadius.card
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(fillStyle)
            .overlay {
                // Top-left soft highlight.
                shape
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(colorScheme == .dark ? 0.07 : 0.4), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }
            .overlay {
                shape.strokeBorder(BudgetTheme.cardBorder(colorScheme), lineWidth: 1)
            }
    }

    private var fillStyle: AnyShapeStyle {
        // Respect "reduce transparency": use an opaque card instead of material.
        if reduceTransparency {
            return AnyShapeStyle(colorScheme == .dark ? BudgetColor.slateBlue : .white)
        }
        switch style {
        case .hero:
            return AnyShapeStyle(.ultraThinMaterial)
        case .standard, .row:
            return AnyShapeStyle(BudgetTheme.cardFill(colorScheme))
        }
    }

    private var shadowColor: Color {
        guard colorScheme == .dark else { return Color.black.opacity(0.08) }
        return style == .hero ? BudgetColor.indigo.opacity(0.14) : Color.black.opacity(0.25)
    }
}

/// Full-screen branded background used behind every screen.
struct BudgetScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(BudgetTheme.screenBackground(colorScheme))
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
                        .foregroundStyle(BudgetColor.coolGray)
                    Text("CHF 2'450.00")
                        .font(BudgetFont.heroAmount)
                        .foregroundStyle(BudgetColor.offWhite)
                }
            }
            GlassCard(style: .row) {
                Text("Ligne de liste")
                    .foregroundStyle(BudgetColor.offWhite)
            }
        }
        .padding(BudgetSpacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
