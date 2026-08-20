import SwiftUI
import UIKit

/// Autorité sémantique unique de l'iconographie Budget Prisme.
///
/// Les écrans choisissent un sens (`income`, `setAside`, `accounts`), jamais
/// une chaîne SF Symbols au hasard. Les tracés Budget 24 × 24 restent la
/// source native de cette grammaire visuelle ; seuls les gestes universels
/// gardent un SF Symbol de repli. Le puits, le poids et les couleurs
/// appartiennent au design system Budget.
enum BudgetGlyph: String, CaseIterable, Equatable, Hashable {
    // Navigation principale
    case month
    case history
    case budget
    case accounts
    case manage

    // Natures financières
    case income
    case expense
    case setAside
    case investment
    case recurring
    case transfer
    case taxes
    case debt
    case refund
    case adjustment

    // Comptes et objectifs
    case currentAccount
    case creditCard
    case cash
    case pension
    case property
    case travel
    case vehicle
    case children
    case retirement
    case emergency
    case customGoal
    case other

    // Catégories du catalogue des identités locales (IC1, ADR-038) —
    // mêmes clés que fixtures/catalogue-glyph-map.json.
    case bill
    case video
    case music
    case cloud
    case software
    case ai
    case gaming
    case fitness
    case health
    case press
    case telecom
    case transport
    case dating
    case delivery

    // Actions et états génériques
    case previous
    case next
    case add
    case annual
    case success
    case warning
    case error
    case copy
    case delete
    case demo

    var systemName: String {
        switch self {
        case .month: "calendar"
        case .history: "clock.arrow.circlepath"
        case .budget: "chart.pie"
        case .accounts: "creditcard"
        case .manage: "square.grid.2x2"
        case .income: "arrow.down.left"
        case .expense: "arrow.up.right"
        case .setAside: "tray.and.arrow.down"
        case .investment: "chart.line.uptrend.xyaxis"
        case .recurring: "arrow.triangle.2.circlepath"
        case .transfer: "arrow.left.arrow.right"
        case .taxes: "doc.text"
        case .debt: "creditcard.and.123"
        case .refund: "arrow.uturn.down"
        case .adjustment: "slider.horizontal.3"
        case .currentAccount: "creditcard"
        case .creditCard: "creditcard.fill"
        case .cash: "banknote"
        case .pension: "shield.checkered"
        case .property: "house"
        case .travel: "airplane"
        case .vehicle: "car"
        case .children: "figure.2.and.child.holdinghands"
        case .retirement: "sunset"
        case .emergency: "umbrella"
        case .customGoal: "target"
        case .other: "tray"
        case .bill: "doc.plaintext"
        case .video: "play.rectangle"
        case .music: "music.note"
        case .cloud: "cloud"
        case .software: "app.badge"
        case .ai: "wand.and.stars"
        case .gaming: "gamecontroller"
        case .fitness: "dumbbell"
        case .health: "cross.case"
        case .press: "newspaper"
        case .telecom: "antenna.radiowaves.left.and.right"
        case .transport: "tram"
        case .dating: "heart"
        case .delivery: "shippingbox"
        case .previous: "chevron.left"
        case .next: "chevron.right"
        case .add: "plus"
        case .annual: "calendar.badge.clock"
        case .success: "checkmark"
        case .warning: "clock"
        case .error: "exclamationmark.triangle"
        case .copy: "plus.square.on.square"
        case .delete: "trash"
        case .demo: "sparkles"
        }
    }

    /// Nom du tracé canonique côté PWA. Les métaphores principales gardent
    /// exactement le même nom et la même géométrie sur les deux plateformes.
    var pwaName: String? {
        switch self {
        case .month: "home"
        case .history: "movements"
        case .budget: "budget"
        case .accounts: "accounts"
        case .manage: "more"
        case .income: "income"
        case .expense: "expense"
        case .setAside: "saving"
        case .investment: "investment"
        case .recurring: "recurring"
        case .transfer: "transfer"
        case .taxes: "taxPayment"
        case .debt: "liability"
        case .refund: "refund"
        case .adjustment: "adjustment"
        default: nil
        }
    }

    var usesCustomVector: Bool { pwaName != nil }
}

/// Teinte du puits. Les couleurs financières restent strictement
/// sémantiques ; `brand` sert aux sélections et aux flux neutres de produit.
enum BudgetIconTone: Equatable {
    case neutral
    case brand
    case positive
    case negative
    case warning

    var foreground: Color {
        switch self {
        case .neutral: NeonUltraColor.textSecondary
        case .brand: NeonUltraColor.cyan
        case .positive: NeonUltraColor.positive
        case .negative: NeonUltraColor.negative
        case .warning: NeonUltraColor.warning
        }
    }

    var background: Color {
        switch self {
        case .neutral: NeonUltraColor.tintNeutral
        case .brand: NeonUltraColor.tintViolet
        case .positive: NeonUltraColor.tintPositive
        case .negative: NeonUltraColor.tintNegative
        case .warning: NeonUltraColor.tintWarning
        }
    }
}

// MARK: - Tracés vectoriels partagés avec la PWA

/// Construit les mêmes chemins 24 × 24 que `BUDGET_GLYPHS` dans la PWA.
/// Tous les segments sont tracés avec extrémités et jonctions arrondies.
enum BudgetGlyphVectorPath {
    static func path(for glyph: BudgetGlyph, in rect: CGRect) -> Path {
        var unit = Path()

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        func polyline(_ points: [CGPoint], close: Bool = false) {
            guard let first = points.first else { return }
            unit.move(to: first)
            points.dropFirst().forEach { unit.addLine(to: $0) }
            if close { unit.closeSubpath() }
        }
        func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) {
            polyline([point(x1, y1), point(x2, y2)])
        }
        func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) {
            unit.addEllipse(
                in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            )
        }
        func roundedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat) {
            unit.addRoundedRect(
                in: CGRect(x: x, y: y, width: width, height: height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        }
        /// Convertit un arc circulaire SVG (coordonnées d'extrémités) en
        /// courbes de Bézier. Chaque arc ouvre son propre sous-chemin : il ne
        /// peut donc jamais hériter du point courant et tracer une diagonale
        /// parasite entre deux éléments du glyphe.
        func svgArc(
            from start: CGPoint,
            to end: CGPoint,
            radius requestedRadius: CGFloat,
            largeArc: Bool,
            sweep: Bool
        ) {
            guard start != end, requestedRadius > 0 else { return }

            let halfX = (start.x - end.x) / 2
            let halfY = (start.y - end.y) / 2
            var radius = requestedRadius
            let radiusScale = ((halfX * halfX) + (halfY * halfY)) / (radius * radius)
            if radiusScale > 1 { radius *= sqrt(radiusScale) }

            let denominator = (halfX * halfX) + (halfY * halfY)
            guard denominator > 0 else { return }
            let numerator = max(0, (radius * radius) - denominator)
            let direction: CGFloat = largeArc == sweep ? -1 : 1
            let coefficient = direction * sqrt(numerator / denominator)
            let center = CGPoint(
                x: ((start.x + end.x) / 2) + (coefficient * halfY),
                y: ((start.y + end.y) / 2) - (coefficient * halfX)
            )

            let startAngle = atan2(start.y - center.y, start.x - center.x)
            let endAngle = atan2(end.y - center.y, end.x - center.x)
            var delta = endAngle - startAngle
            if sweep, delta < 0 { delta += 2 * .pi }
            if !sweep, delta > 0 { delta -= 2 * .pi }

            let segmentCount = max(1, Int(ceil(abs(delta) / (.pi / 2))))
            let segmentAngle = delta / CGFloat(segmentCount)
            unit.move(to: start)

            for index in 0..<segmentCount {
                let angle0 = startAngle + (CGFloat(index) * segmentAngle)
                let angle1 = angle0 + segmentAngle
                let alpha = (4 / 3) * tan(segmentAngle / 4)
                let segmentEnd = CGPoint(
                    x: center.x + (radius * cos(angle1)),
                    y: center.y + (radius * sin(angle1))
                )
                let control1 = CGPoint(
                    x: center.x + (radius * cos(angle0)) - (alpha * radius * sin(angle0)),
                    y: center.y + (radius * sin(angle0)) + (alpha * radius * cos(angle0))
                )
                let control2 = CGPoint(
                    x: segmentEnd.x + (alpha * radius * sin(angle1)),
                    y: segmentEnd.y - (alpha * radius * cos(angle1))
                )
                unit.addCurve(to: segmentEnd, control1: control1, control2: control2)
            }
        }

        switch glyph {
        case .month:
            unit.move(to: point(4, 10.5))
            unit.addLine(to: point(12, 4))
            unit.addLine(to: point(20, 10.5))
            unit.addLine(to: point(20, 18.5))
            unit.addQuadCurve(to: point(18.5, 20), control: point(20, 20))
            unit.addLine(to: point(5.5, 20))
            unit.addQuadCurve(to: point(4, 18.5), control: point(4, 20))
            unit.closeSubpath()
            polyline([point(9, 20), point(9, 14), point(15, 14), point(15, 20)])

        case .history:
            line(5, 7, 16, 7)
            polyline([point(13, 4), point(16, 7), point(13, 10)])
            line(19, 17, 8, 17)
            polyline([point(11, 14), point(8, 17), point(11, 20)])

        case .budget:
            circle(12, 12, 8.5)
            polyline([point(12, 3.5), point(12, 12), point(18.8, 16.8)])

        case .accounts:
            roundedRect(3.5, 6.5, 17, 12, 2.5)
            unit.move(to: point(6, 6.5))
            unit.addLine(to: point(6, 5.8))
            unit.addQuadCurve(to: point(8.3, 3.5), control: point(6, 3.5))
            unit.addLine(to: point(17.5, 3.5))
            line(3.5, 11, 20.5, 11)
            line(16.5, 15, 17.5, 15)

        case .manage:
            line(4, 6, 10, 6)
            line(14, 6, 20, 6)
            line(4, 12, 15, 12)
            line(19, 12, 20, 12)
            line(4, 18, 6, 18)
            line(10, 18, 20, 18)
            circle(12, 6, 2)
            circle(17, 12, 2)
            circle(8, 18, 2)

        case .income:
            line(12, 4, 12, 14)
            polyline([point(8.5, 10.5), point(12, 14), point(15.5, 10.5)])
            unit.move(to: point(5, 15.5))
            unit.addLine(to: point(5, 18.5))
            unit.addQuadCurve(to: point(6.5, 20), control: point(5, 20))
            unit.addLine(to: point(17.5, 20))
            unit.addQuadCurve(to: point(19, 18.5), control: point(19, 20))
            unit.addLine(to: point(19, 15.5))

        case .expense:
            line(12, 14, 12, 4)
            polyline([point(8.5, 7.5), point(12, 4), point(15.5, 7.5)])
            unit.move(to: point(5, 15.5))
            unit.addLine(to: point(5, 18.5))
            unit.addQuadCurve(to: point(6.5, 20), control: point(5, 20))
            unit.addLine(to: point(17.5, 20))
            unit.addQuadCurve(to: point(19, 18.5), control: point(19, 20))
            unit.addLine(to: point(19, 15.5))

        case .setAside:
            roundedRect(3.5, 6, 17, 13, 3)
            polyline([point(7, 6), point(7, 4), point(17, 4), point(17, 6)])
            circle(12, 12.5, 3)
            line(12, 10.5, 12, 14.5)
            line(10, 12.5, 14, 12.5)

        case .investment:
            line(4, 19, 4, 5)
            line(4, 19, 20, 19)
            polyline([point(7, 15), point(11, 11), point(14, 13), point(19, 7)])
            polyline([point(15.5, 7), point(19, 7), point(19, 10.5)])

        case .transfer:
            line(4, 8, 18, 8)
            polyline([point(15, 5), point(18, 8), point(15, 11)])
            line(20, 16, 6, 16)
            polyline([point(9, 13), point(6, 16), point(9, 19)])

        case .taxes:
            polyline([
                point(7, 3.5), point(15, 3.5), point(18, 6.5),
                point(18, 20.5), point(7, 20.5), point(7, 3.5),
            ])
            polyline([point(15, 3.5), point(15, 6.5), point(18, 6.5)])
            line(10, 11, 15, 11)
            line(10, 15, 15, 15)

        case .debt:
            polyline([
                point(7, 3.5), point(15, 3.5), point(18, 6.5),
                point(18, 20.5), point(7, 20.5), point(7, 3.5),
            ])
            polyline([point(15, 3.5), point(15, 6.5), point(18, 6.5)])
            line(10, 13, 15, 13)

        case .refund:
            polyline([point(7.5, 8), point(4, 8), point(4, 4.5)])
            svgArc(
                from: point(4.5, 8), to: point(5, 17), radius: 8,
                largeArc: true, sweep: true
            )
            line(9, 12, 15, 12)

        case .adjustment:
            line(4, 7, 9, 7)
            line(13, 7, 20, 7)
            line(4, 17, 13, 17)
            line(17, 17, 20, 17)
            circle(11, 7, 2)
            circle(15, 17, 2)

        case .recurring:
            polyline([point(7, 7), point(17, 7), point(14.5, 4.5)])
            polyline([point(17, 17), point(7, 17), point(9.5, 19.5)])
            svgArc(
                from: point(19, 9), to: point(19, 15), radius: 7,
                largeArc: false, sweep: true
            )
            svgArc(
                from: point(5, 15), to: point(5, 9), radius: 7,
                largeArc: false, sweep: true
            )

        default:
            // Les commandes universelles conservent un SF Symbol natif.
            break
        }

        let scale = min(rect.width, rect.height) / 24
        let transform = CGAffineTransform(
            a: scale, b: 0, c: 0, d: scale,
            tx: rect.midX - (12 * scale),
            ty: rect.midY - (12 * scale)
        )
        return unit.applying(transform)
    }
}

struct BudgetGlyphShape: Shape {
    let glyph: BudgetGlyph

    func path(in rect: CGRect) -> Path {
        BudgetGlyphVectorPath.path(for: glyph, in: rect)
    }
}

/// Marque vectorielle sans conteneur, utilisable dans les sélecteurs et les
/// résumés textuels. Le parent fournit la couleur, jamais le glyphe.
struct BudgetGlyphMark: View {
    let glyph: BudgetGlyph
    var color: Color = NeonUltraColor.textPrimary
    var lineWidth: CGFloat = 1.75

    var body: some View {
        BudgetGlyphShape(glyph: glyph)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .accessibilityHidden(true)
    }
}

/// `TabView` exige une `Image` pour conserver le comportement UIKit natif.
/// Elle est rasterisée à la taille du dock depuis le MÊME chemin vectoriel ;
/// l'état sélectionné ajoute un puits violet explicite sans remplacer la
/// barre d'onglets ni ses libellés VoiceOver.
enum BudgetGlyphTabImage {
    static func image(for glyph: BudgetGlyph, isSelected: Bool) -> UIImage {
        let size = CGSize(width: isSelected ? 30 : 24, height: 24)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let rendered = renderer.image { context in
            let cg = context.cgContext
            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            let glyphRect: CGRect
            if isSelected {
                let selection = UIBezierPath(
                    roundedRect: CGRect(x: 0.5, y: 0.5, width: 29, height: 23),
                    cornerRadius: 7
                )
                UIColor(NeonUltraColor.violet).withAlphaComponent(0.16).setFill()
                selection.fill()
                UIColor(NeonUltraColor.violet).withAlphaComponent(0.82).setStroke()
                selection.lineWidth = 1
                selection.stroke()
                cg.setStrokeColor(UIColor(NeonUltraColor.textPrimary).cgColor)
                glyphRect = CGRect(x: 7, y: 4, width: 16, height: 16)
            } else {
                cg.setStrokeColor(UIColor.black.cgColor)
                glyphRect = CGRect(x: 1.5, y: 1.5, width: 21, height: 21)
            }

            cg.setLineWidth(1.75)
            cg.addPath(BudgetGlyphVectorPath.path(for: glyph, in: glyphRect).cgPath)
            cg.strokePath()
        }

        return rendered.withRenderingMode(isSelected ? .alwaysOriginal : .alwaysTemplate)
    }
}

/// Rendu commun d'un glyphe : même poids optique, même grille et mêmes
/// puits sur Mois, Budget, Historique, Comptes et Gérer.
struct BudgetIcon: View {
    enum Style: Equatable {
        /// Glyphe seul, à placer dans une cible interactive déjà dimensionnée.
        case plain
        /// Puits compact de 40 pt pour lignes et métriques.
        case well
        /// Puits de 40 pt avec liseré spectral, réservé à une sélection.
        case selected
        /// Puits interactif de 44 pt.
        case control
    }

    private let glyph: BudgetGlyph?
    private let fallbackSystemName: String
    let tone: BudgetIconTone
    let style: Style

    init(
        _ glyph: BudgetGlyph,
        tone: BudgetIconTone = .neutral,
        style: Style = .well
    ) {
        self.glyph = glyph
        self.fallbackSystemName = glyph.systemName
        self.tone = tone
        self.style = style
    }

    /// Les catégories persistées portent déjà un `iconToken`. Cet
    /// initialiseur les fait passer par le même traitement sans modifier les
    /// sauvegardes ni le modèle de données.
    init(
        systemName: String,
        tone: BudgetIconTone = .neutral,
        style: Style = .well
    ) {
        self.glyph = nil
        self.fallbackSystemName = systemName
        self.tone = tone
        self.style = style
    }

    var body: some View {
        mark
            .frame(width: dimension, height: dimension)
            .background(background)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: style == .plain ? 0 : NeonUltraIconMetric.radius,
                    style: .continuous
                )
            )
            .overlay { border }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var mark: some View {
        if let glyph, glyph.usesCustomVector {
            BudgetGlyphMark(glyph: glyph, color: tone.foreground)
                .frame(
                    width: NeonUltraIconMetric.glyph,
                    height: NeonUltraIconMetric.glyph
                )
        } else {
            Image(systemName: fallbackSystemName)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: NeonUltraIconMetric.glyph, weight: .semibold))
                .foregroundStyle(tone.foreground)
                .frame(
                    width: NeonUltraIconMetric.glyph,
                    height: NeonUltraIconMetric.glyph
                )
        }
    }

    private var dimension: CGFloat {
        switch style {
        case .plain: 24
        case .well, .selected: NeonUltraIconMetric.well
        case .control: NeonUltraIconMetric.controlWell
        }
    }

    private var background: Color {
        style == .plain ? .clear : tone.background
    }

    @ViewBuilder
    private var border: some View {
        if style == .selected {
            RoundedRectangle(cornerRadius: NeonUltraIconMetric.radius, style: .continuous)
                .stroke(NeonUltraGradient.prismEdge, lineWidth: 1)
                .opacity(0.58)
        } else if style == .well || style == .control {
            RoundedRectangle(cornerRadius: NeonUltraIconMetric.radius, style: .continuous)
                .stroke(NeonUltraColor.border, lineWidth: 1)
        }
    }
}

// MARK: - Mappings de domaine vers la grammaire visuelle

extension AppTab {
    var budgetGlyph: BudgetGlyph {
        switch self {
        case .home: .month
        case .transactions: .history
        case .budget: .budget
        case .accounts: .accounts
        case .more: .manage
        }
    }
}

extension QuickEntryIntent {
    var budgetGlyph: BudgetGlyph {
        switch self {
        case .expense: .expense
        case .income: .income
        case .setAside: .setAside
        case .recurring: .recurring
        }
    }

    var budgetIconTone: BudgetIconTone {
        switch self {
        case .expense: .negative
        case .income: .positive
        case .setAside: .brand
        case .recurring: .brand
        }
    }
}

extension TransactionType {
    var budgetGlyph: BudgetGlyph {
        switch self {
        case .income: .income
        case .expense: .expense
        case .saving: .setAside
        case .investment: .investment
        case .transfer: .transfer
        case .taxPayment: .taxes
        case .debtPayment: .debt
        case .refund: .refund
        case .adjustment: .adjustment
        }
    }

    var budgetIconTone: BudgetIconTone {
        switch self {
        case .income, .refund: .positive
        case .expense, .taxPayment, .debtPayment: .negative
        case .saving, .investment: .brand
        case .transfer, .adjustment: .neutral
        }
    }

    /// Une occurrence encore prévue porte son ÉTAT, pas encore son impact
    /// comptable : les sorties attendues sont ambre jusqu'à leur validation.
    var budgetPlannedIconTone: BudgetIconTone {
        switch self {
        case .expense, .taxPayment, .debtPayment: .warning
        default: budgetIconTone
        }
    }
}

extension AccountType {
    var budgetGlyph: BudgetGlyph {
        switch self {
        case .current: .currentAccount
        case .savings: .setAside
        case .creditCard: .creditCard
        case .cash: .cash
        case .broker: .investment
        case .pillar3a, .pillar3b, .occupationalPension: .pension
        case .mortgage: .property
        case .loan: .debt
        case .other: .other
        }
    }
}

extension GoalKind {
    var budgetGlyph: BudgetGlyph {
        switch self {
        case .emergencyFund: .emergency
        case .taxes: .taxes
        case .travel: .travel
        case .vehicle: .vehicle
        case .property: .property
        case .children: .children
        case .retirement: .retirement
        case .pillar3a: .pension
        case .debt: .debt
        case .custom: .customGoal
        }
    }
}
