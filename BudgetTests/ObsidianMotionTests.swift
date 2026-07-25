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

        // GÉOMÉTRIE RÉELLE 1 — l'étiquette COMPLÈTE tient dans la carte.
        // La carte sélectionnée grandit EXACTEMENT de la différence entre
        // la hauteur MESURÉE de l'étiquette complète et celle de l'invite
        // (même rendu, même largeur intérieure de production). Si une
        // ligne était rognée, ce delta serait plus petit.
        let selectedRender = renderViewport(selection: target.date)
        let unselectedRender = renderViewport(selection: nil)
        let innerWidth = 320 - 2 * margin - 2 * BudgetSpacing.cardPadding

        @MainActor
        func measuredTextHeight(_ text: String) -> CGFloat {
            let view = Text(text)
                .font(BudgetFont.caption)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.dynamicTypeSize, .accessibility3)
            return UIHostingController(rootView: view)
                .sizeThatFits(in: CGSize(width: innerWidth, height: 10_000)).height
        }
        let labelHeight = measuredTextHeight(expectedLabel)
        let hintHeight = measuredTextHeight("Glissez sur la courbe pour lire un mois précis.")
        XCTAssertGreaterThanOrEqual(labelHeight, hintHeight,
                                    "l'étiquette complète n'est jamais plus courte que l'invite")
        // Preuve DIRECTE, indépendante de l'invite : la carte réserve au
        // moins graphique (160 pt) + étiquette complète + marges et
        // paddings — borne inférieure stricte de la hauteur intrinsèque.
        XCTAssertGreaterThanOrEqual(
            selectedRender.height,
            160 + labelHeight + 2 * margin + 2 * BudgetSpacing.cardPadding,
            "la carte obtient sa vraie hauteur intrinsèque : graphique + étiquette complète + marges"
        )
        XCTAssertEqual(selectedRender.height - unselectedRender.height, labelHeight - hintHeight, accuracy: 2,
            "hauteur intrinsèque RÉELLE : la carte grandit exactement de la hauteur de l'étiquette complète — aucune ligne rognée")

        // GÉOMÉTRIE RÉELLE 2 — analyse pixel par pixel du rendu : rien ne
        // touche le bord inférieur, l'étiquette est rendue en bas de
        // carte, rien ne déborde des marges horizontales.
        let (brightRows, brightCols, pixelScale) = try brightMap(of: selectedRender.image)
        let lastBrightRow = CGFloat(try XCTUnwrap(brightRows.lastIndex(of: true))) / pixelScale
        let firstBrightCol = CGFloat(try XCTUnwrap(brightCols.firstIndex(of: true))) / pixelScale
        let lastBrightCol = CGFloat(try XCTUnwrap(brightCols.lastIndex(of: true))) / pixelScale
        XCTAssertLessThanOrEqual(lastBrightRow, selectedRender.height - margin - 6,
            "espace RÉEL sous la dernière ligne : aucun contenu ne touche le bord inférieur (dernier pixel clair à \(lastBrightRow) pt pour \(selectedRender.height) pt)")
        XCTAssertGreaterThanOrEqual(lastBrightRow, selectedRender.height - margin - labelHeight - BudgetSpacing.cardPadding - 8,
            "l'étiquette est réellement RENDUE en bas de carte — pas seulement mesurée")
        XCTAssertGreaterThanOrEqual(firstBrightCol, margin - 2,
            "aucun débordement à gauche de la marge de production")
        XCTAssertLessThanOrEqual(lastBrightCol, 320 - margin + 2,
            "aucun débordement à droite de la marge de production")

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

    /// Carte des pixels CLAIRS (texte, courbe, règle, point — tout canal
    /// > 140 sur fond sombre Obsidian) : lignes et colonnes marquées, en
    /// pixels, avec l'échelle points→pixels de l'image.
    private func brightMap(of image: UIImage) throws -> (rows: [Bool], cols: [Bool], scale: CGFloat) {
        let cg = try XCTUnwrap(image.cgImage)
        let width = cg.width, height = cg.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(
            data: &buffer, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        var rows = [Bool](repeating: false, count: height)
        var cols = [Bool](repeating: false, count: width)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                if buffer[i] > 140 || buffer[i + 1] > 140 || buffer[i + 2] > 140 {
                    rows[y] = true
                    cols[x] = true
                }
            }
        }
        return (rows, cols, CGFloat(width) / 320)
    }
}
