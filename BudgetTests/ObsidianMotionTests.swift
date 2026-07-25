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
    /// (NetWorthTrendCard — le composant rendu tel quel par NetWorthView,
    /// jamais une copie de test), à 320 pt, Dynamic Type accessibility3,
    /// transparence réduite, avec une sélection INJECTÉE d'un véritable
    /// instantané. AVANT la capture : sélection résolue, étiquette
    /// LITTÉRALE de la fixture, largeur ≤ 320 (aucun débordement),
    /// hauteur suffisante (titre + graphique + étiquette), et l'état
    /// sélectionné change réellement le rendu (les deux images
    /// diffèrent). Pièce : ios-l8-patrimoine-selection-320-a11y.
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
        XCTAssertEqual(NetWorthView.nearestTrendPoint(to: target.date, in: points)?.date, target.date,
                       "la sélection injectée résout vers le véritable instantané le plus proche")
        XCTAssertEqual(
            normalized(NetWorthView.trendSelectionLabel(date: target.date, netWorth: target.netWorth)),
            "30.04.2026 : CHF 125'900.00 de fortune nette",
            "l'étiquette attendue est un LITTÉRAL de la fixture"
        )

        @MainActor
        func renderCard(selection: Date?) throws -> (image: UIImage, size: CGSize) {
            let card = NetWorthTrendCard(points: points, heldTrendSelection: .constant(selection))
                .environment(\.dynamicTypeSize, .accessibility3)
                .environment(\.obsidianForcedReducedTransparency, true)
                .frame(width: 320)
            let controller = UIHostingController(rootView: card)
            let fitted = controller.sizeThatFits(in: CGSize(width: 320, height: 10_000))
            let frame = CGRect(origin: .zero, size: CGSize(width: 320, height: fitted.height))
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
            return (image, fitted)
        }

        let selectedRender = try renderCard(selection: target.date)
        let unselectedRender = try renderCard(selection: nil)
        XCTAssertLessThanOrEqual(selectedRender.size.width, 320.5,
                                 "aucun débordement horizontal à 320 pt")
        XCTAssertGreaterThan(selectedRender.size.height, 200,
                             "titre + graphique (160 pt) + étiquette tiennent dans la carte rendue")
        XCTAssertGreaterThanOrEqual(selectedRender.size.height + 0.5, unselectedRender.size.height,
                                    "l'étiquette passe à la ligne — jamais tronquée par une hauteur figée")
        let selPNG = try XCTUnwrap(selectedRender.image.pngData())
        let unselPNG = try XCTUnwrap(unselectedRender.image.pngData())
        XCTAssertNotEqual(selPNG, unselPNG,
                          "l'état SÉLECTIONNÉ (règle, point, étiquette) doit réellement changer le rendu")
        let attachment = XCTAttachment(image: selectedRender.image)
        attachment.name = "ios-l8-patrimoine-selection-320-a11y"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
