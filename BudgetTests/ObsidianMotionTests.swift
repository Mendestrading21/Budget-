import SwiftUI
import SwiftData
import UIKit
import XCTest
@testable import Budget

/// Lot L8 (passe corrective) — widgets, graphiques et micro-interactions.
/// Preuves AUTOMATIQUES : étiquette de sélection fr-CH exacte (positive et
/// négative), point le plus proche, valeur accessible annonçant la
/// sélection, déclencheur haptique avançant UNIQUEMENT sur un
/// enregistrement réussi, étiquette qui passe à la ligne en tailles
/// accessibilité. Preuve VISUELLE : rendu réel de Patrimoine SÉLECTIONNÉ à
/// 320 pt en Dynamic Type accessibility3 et transparence réduite, attaché
/// à l'artefact (à inspecter humainement). La vibration physique reste un
/// contrôle humain sur iPhone réel (L9) — le simulateur ne la prouve pas.
final class ObsidianMotionTests: XCTestCase {
    /// Normalise les glyphes d'apostrophe ICU (même garde que
    /// FinanceFormattingTests) pour des assertions stables.
    private func normalized(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    /// Date construite dans le fuseau courant (même garde que
    /// FinanceFormattingTests) : l'assertion tient sur toute CI.
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func snapshot(_ date: Date, _ netWorth: Decimal) -> NetWorthSnapshot {
        NetWorthSnapshot(date: date, accountsTotal: netWorth, assetsTotal: 0,
                         pensionTotal: 0, liabilitiesTotal: 0, netWorth: netWorth)
    }

    // MARK: - L'étiquette de sélection dit la vérité, en fr-CH

    func testTrendSelectionLabelUsesSwissFormatting() {
        let label = NetWorthView.trendSelectionLabel(
            date: date(2026, 6, 15),
            netWorth: Decimal("128450.30")
        )
        XCTAssertEqual(normalized(label), "15.06.2026 : CHF 128'450.30 de fortune nette",
                       "date suisse + montant CHF exacts — la valeur affichée est celle de la série")
    }

    func testTrendSelectionLabelKeepsNegativeNetWorthHonest() {
        let label = NetWorthView.trendSelectionLabel(
            date: date(2026, 1, 3),
            netWorth: Decimal("-2500.00")
        )
        XCTAssertEqual(normalized(label), "03.01.2026 : -CHF 2'500.00 de fortune nette",
                       "une fortune nette négative reste négative — jamais maquillée")
    }

    // MARK: - Le point le plus proche vient des instantanés EXISTANTS

    func testNearestTrendPointPicksClosestSnapshot() {
        let points = [
            snapshot(date(2026, 1, 31), Decimal("1000")),
            snapshot(date(2026, 3, 31), Decimal("-250.50")),
            snapshot(date(2026, 6, 30), Decimal("4000")),
        ]
        XCTAssertNil(NetWorthView.nearestTrendPoint(to: nil, in: points),
                     "aucune sélection : aucun point")
        let nearMarch = NetWorthView.nearestTrendPoint(to: date(2026, 4, 10), in: points)
        XCTAssertEqual(nearMarch?.netWorth, Decimal("-250.50"),
                       "le 10 avril est plus proche du 31 mars que du 30 juin")
        let nearJune = NetWorthView.nearestTrendPoint(to: date(2026, 5, 20), in: points)
        XCTAssertEqual(nearJune?.netWorth, Decimal("4000"),
                       "le 20 mai est plus proche du 30 juin que du 31 mars")
    }

    func testTrendAccessibilityValueAnnouncesTheSelection() {
        let points = [
            snapshot(date(2026, 1, 31), Decimal("1000")),
            snapshot(date(2026, 6, 30), Decimal("-4000")),
        ]
        let selected = points[1]
        let announced = NetWorthView.trendAccessibilityValue(selected: selected, points: points)
        XCTAssertEqual(announced,
                       NetWorthView.trendSelectionLabel(date: selected.date, netWorth: selected.netWorth),
                       "sélection active : la courbe annonce le MOIS et le MONTANT choisis")
        let summary = NetWorthView.trendAccessibilityValue(selected: nil, points: points)
        XCTAssertTrue(summary.contains("De ") && summary.contains(" à "),
                      "sans sélection : le résumé global reste annoncé")
    }

    // MARK: - Haptique : n'avance QUE sur un enregistrement réellement réussi

    func testHapticTriggerAdvancesOnlyOnRealSave() {
        XCTAssertTrue(
            TransactionFormView.hapticTriggerAdvances(validationErrors: [], saveSucceeded: true),
            "validation passée + save réussi : EXACTEMENT un pas de trigger"
        )
        XCTAssertFalse(
            TransactionFormView.hapticTriggerAdvances(validationErrors: [.missingAmount], saveSucceeded: true),
            "validation refusée : aucun retour haptique"
        )
        XCTAssertFalse(
            TransactionFormView.hapticTriggerAdvances(validationErrors: [], saveSucceeded: false),
            "erreur de sauvegarde : aucun retour haptique"
        )
    }

    // MARK: - L'étiquette passe à la ligne en tailles accessibilité

    @MainActor
    func testSelectionCaptionWrapsAtAccessibilitySizes() {
        let label = NetWorthView.trendSelectionLabel(date: date(2026, 6, 15), netWorth: Decimal("128450.30"))
        func height(dynamicType: DynamicTypeSize) -> CGFloat {
            let view = Text(label)
                .font(BudgetFont.caption)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.dynamicTypeSize, dynamicType)
            return UIHostingController(rootView: view)
                .sizeThatFits(in: CGSize(width: 320 - 2 * BudgetSpacing.screenMargin, height: 10_000)).height
        }
        let standard = height(dynamicType: .large)
        let accessible = height(dynamicType: .accessibility3)
        XCTAssertGreaterThanOrEqual(accessible, standard * 1.8,
            "en accessibility3 l'étiquette grandit et passe à la ligne — jamais tronquée ni figée")
    }

    // MARK: - Preuve VISUELLE : Patrimoine SÉLECTIONNÉ à 320 pt, a11y3, transparence réduite

    /// Preuve VISUELLE réelle : la carte Évolution DE PRODUCTION
    /// (NetWorthTrendCard, rendue telle quelle par NetWorthView) dans un
    /// VIEWPORT réel de 320 pt — avec les marges horizontales de
    /// production (BudgetSpacing.screenMargin), jamais une largeur
    /// artificielle —, Dynamic Type accessibility3, transparence
    /// réduite, sélection injectée d'un véritable instantané. Les
    /// assertions portent sur la GÉOMÉTRIE réelle après layout (cadres
    /// d'accessibilité) : étiquette entière DANS l'image avec marge
    /// inférieure positive, graphique dans le cadre, étiquette
    /// littérale exacte de la fixture, axe X adapté (2 repères en
    /// tailles accessibilité). La comparaison de PNG n'est qu'une
    /// preuve SECONDAIRE. Pièce : ios-l8-patrimoine-selection-320-a11y.
    @MainActor
    func testNetWorthSelectedStateRendersAt320WithA11yType() throws {
        let points = [
            snapshot(date(2026, 1, 31), Decimal("118200.00")),
            snapshot(date(2026, 2, 28), Decimal("121300.00")),
            snapshot(date(2026, 3, 31), Decimal("124150.50")),
            snapshot(date(2026, 4, 30), Decimal("125900.00")),
            snapshot(date(2026, 5, 31), Decimal("127000.00")),
            snapshot(date(2026, 6, 30), Decimal("128450.30")),
        ]
        let target = points[3]
        let expectedLabel = "30.04.2026 : CHF 125'900.00 de fortune nette"
        XCTAssertEqual(NetWorthView.nearestTrendPoint(to: target.date, in: points)?.date, target.date,
                       "la sélection injectée résout vers le véritable instantané le plus proche")
        XCTAssertEqual(
            normalized(NetWorthView.trendSelectionLabel(date: target.date, netWorth: target.netWorth)),
            expectedLabel,
            "l'étiquette attendue est un LITTÉRAL de la fixture"
        )
        // Axe X adapté aux tailles accessibilité — deux repères lisibles
        // au lieu de six libellés superposés ; rendu normal inchangé.
        XCTAssertEqual(NetWorthTrendCard.xAxisMarkCount(for: .accessibility3), 2)
        XCTAssertEqual(NetWorthTrendCard.xAxisMarkCount(for: .large), 4)

        let margin = BudgetSpacing.screenMargin

        @MainActor
        func renderViewport(selection: Date?) -> (image: UIImage, height: CGFloat, root: UIView) {
            // Viewport RÉEL : 320 pt avec les marges de production — la
            // carte reçoit 320 − 2 × screenMargin, comme dans NetWorthView.
            let viewport = NetWorthTrendCard(points: points, heldTrendSelection: .constant(selection))
                .padding(margin)
                .environment(\.dynamicTypeSize, .accessibility3)
                .environment(\.obsidianForcedReducedTransparency, true)
            let controller = UIHostingController(rootView: viewport)
            controller.safeAreaRegions = [] // la zone sûre du conteneur de test ne doit pas décaler ni rogner la carte
            let fitted = controller.sizeThatFits(in: CGSize(width: 320, height: 10_000))
            let frame = CGRect(x: 0, y: 0, width: 320, height: ceil(fitted.height))
            let window = UIWindow(frame: frame)
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = frame
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.4))
            let renderer = UIGraphicsImageRenderer(size: frame.size)
            let image = renderer.image { _ in
                controller.view.drawHierarchy(in: frame, afterScreenUpdates: true)
            }
            return (image, frame.height, controller.view)
        }

        /// Cadre RÉEL (post-layout) d'un élément d'accessibilité, en
        /// coordonnées de la fenêtre de rendu (origine 0,0).
        func accessibilityFrame(_ identifier: String, in root: UIView) -> CGRect? {
            var stack: [Any] = [root]
            while let node = stack.popLast() {
                if let ident = node as? UIAccessibilityIdentification,
                   ident.accessibilityIdentifier == identifier {
                    return (node as? NSObject)?.accessibilityFrame
                }
                if let object = node as? NSObject, let children = object.accessibilityElements {
                    stack.append(contentsOf: children)
                }
                if let view = node as? UIView {
                    stack.append(contentsOf: view.subviews)
                }
            }
            return nil
        }

        let selectedRender = renderViewport(selection: target.date)
        let unselectedRender = renderViewport(selection: nil)

        // Étiquette : cadre COMPLET dans l'image, marge inférieure
        // positive, aucune troncature horizontale ni verticale.
        let labelFrame = try XCTUnwrap(
            accessibilityFrame("networth.chart.selectionLabel", in: selectedRender.root),
            "l'étiquette sélectionnée doit exister dans la hiérarchie d'accessibilité"
        )
        XCTAssertGreaterThan(labelFrame.height, 0, "cadre d'étiquette réel après layout")
        XCTAssertGreaterThanOrEqual(labelFrame.minY, 0, "l'étiquette ne dépasse pas le haut de l'image")
        XCTAssertLessThanOrEqual(labelFrame.maxY, selectedRender.height - margin,
            "marge inférieure POSITIVE sous l'étiquette : sa dernière ligne ne touche jamais le bord (maxY \(labelFrame.maxY), image \(selectedRender.height))")
        XCTAssertGreaterThanOrEqual(labelFrame.minX, margin - 1, "l'étiquette respecte la marge gauche de production")
        XCTAssertLessThanOrEqual(labelFrame.maxX, 320 - margin + 1,
            "aucune troncature horizontale : l'étiquette tient dans la largeur réellement disponible")
        // Le TEXTE exposé est l'étiquette COMPLÈTE de la fixture — pas un
        // fragment rogné.
        let labelElement = try XCTUnwrap(findAccessibilityElement("networth.chart.selectionLabel", in: selectedRender.root))
        XCTAssertEqual(normalized((labelElement as? NSObject)?.accessibilityLabel ?? ""), expectedLabel,
                       "l'étiquette exposée est le littéral complet de la fixture")

        // Graphique : cadre réel DANS l'image, à la largeur de production.
        let chartFrame = try XCTUnwrap(
            accessibilityFrame("networth.chart.evolution", in: selectedRender.root),
            "la courbe doit exister dans la hiérarchie d'accessibilité"
        )
        XCTAssertGreaterThanOrEqual(chartFrame.minX, margin - 1, "la courbe respecte la marge gauche")
        XCTAssertLessThanOrEqual(chartFrame.maxX, 320 - margin + 1, "la courbe respecte la marge droite")
        XCTAssertGreaterThanOrEqual(chartFrame.minY, 0)
        XCTAssertLessThanOrEqual(chartFrame.maxY, selectedRender.height, "la courbe (règle et point compris) est entière dans l'image")
        XCTAssertGreaterThan(chartFrame.width, 200, "largeur réellement disponible après les marges de production")
        XCTAssertLessThan(chartFrame.maxY, labelFrame.minY + 1, "l'étiquette est SOUS le graphique, jamais recouverte")

        // Preuve SECONDAIRE : l'état sélectionné change réellement le rendu.
        let selPNG = try XCTUnwrap(selectedRender.image.pngData())
        let unselPNG = try XCTUnwrap(unselectedRender.image.pngData())
        XCTAssertNotEqual(selPNG, unselPNG,
                          "règle, point et étiquette rendent l'image sélectionnée différente de l'invite")

        let attachment = XCTAttachment(image: selectedRender.image)
        attachment.name = "ios-l8-patrimoine-selection-320-a11y"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Retrouve l'ÉLÉMENT d'accessibilité (pas seulement son cadre) —
    /// pour lire le texte réellement exposé.
    private func findAccessibilityElement(_ identifier: String, in root: UIView) -> Any? {
        var stack: [Any] = [root]
        while let node = stack.popLast() {
            if let ident = node as? UIAccessibilityIdentification,
               ident.accessibilityIdentifier == identifier {
                return node
            }
            if let object = node as? NSObject, let children = object.accessibilityElements {
                stack.append(contentsOf: children)
            }
            if let view = node as? UIView {
                stack.append(contentsOf: view.subviews)
            }
        }
        return nil
    }
}
