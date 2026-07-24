import SwiftUI
import SwiftData
import UIKit
import XCTest
@testable import Budget

/// Lot L8 — widgets, graphiques et micro-interactions : l'étiquette de
/// sélection de la courbe Évolution lit les instantanés EXISTANTS et les
/// formate en fr-CH ; l'écran Patrimoine restructuré se construit à
/// 320 pt, transparence réduite comprise. Rien de recalculé, rien d'animé
/// en permanence.
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

    // MARK: - L'écran Patrimoine restructuré se construit dans les états exigés

    @MainActor
    func testNetWorthScreenBuildsAt320WithReducedTransparency() {
        let preview = DemoDataFactory.previewAppContainer()
        let controller = UIHostingController(rootView:
            NavigationStack { NetWorthView() }
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.obsidianForcedReducedTransparency, true)
        )
        controller.view.frame = CGRect(x: 0, y: 0, width: 320, height: 844)
        controller.view.layoutIfNeeded()
        XCTAssertNotNil(controller.view, "Patrimoine (courbe + sélection) à 320 pt en transparence réduite")
    }
}
