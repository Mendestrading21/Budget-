import SwiftUI
import UIKit
import XCTest
@testable import Budget

/// Budget Prisme : une seule grammaire d'icônes pour la navigation, les
/// intentions simples et les natures financières. Ces tests ne touchent ni
/// les modèles persistés ni les calculs.
final class BudgetGlyphTests: XCTestCase {

    func testFiveTabsKeepTheirTitlesAndReceiveStableUniqueGlyphs() {
        XCTAssertEqual(AppTab.allCases.count, 5)
        XCTAssertEqual(
            AppTab.allCases.map(\.budgetGlyph),
            [.month, .history, .budget, .accounts, .manage]
        )
        XCTAssertEqual(
            AppTab.allCases.compactMap { $0.budgetGlyph.pwaName },
            ["home", "movements", "budget", "accounts", "more"]
        )
        XCTAssertEqual(
            Set(AppTab.allCases.compactMap { $0.budgetGlyph.pwaName }).count,
            AppTab.allCases.count
        )
    }

    func testFourQuickIntentionsUsePlainFinancialGlyphs() {
        XCTAssertEqual(
            QuickEntryIntent.allCases.map(\.budgetGlyph),
            [.expense, .income, .setAside, .recurring]
        )
        XCTAssertEqual(QuickEntryIntent.expense.budgetIconTone, .negative)
        XCTAssertEqual(QuickEntryIntent.income.budgetIconTone, .positive)
        XCTAssertEqual(QuickEntryIntent.setAside.budgetIconTone, .brand)
        XCTAssertEqual(QuickEntryIntent.recurring.budgetIconTone, .brand)
    }

    func testEveryTransactionTypeHasOneSemanticGlyphAndTone() {
        let expected: [(TransactionType, BudgetGlyph, BudgetIconTone)] = [
            (.income, .income, .positive),
            (.expense, .expense, .negative),
            (.saving, .setAside, .brand),
            (.investment, .investment, .brand),
            (.transfer, .transfer, .neutral),
            (.taxPayment, .taxes, .negative),
            (.debtPayment, .debt, .negative),
            (.refund, .refund, .positive),
            (.adjustment, .adjustment, .neutral),
        ]

        XCTAssertEqual(expected.count, TransactionType.allCases.count)
        for (type, glyph, tone) in expected {
            XCTAssertEqual(type.budgetGlyph, glyph)
            XCTAssertEqual(type.budgetIconTone, tone)
        }
    }

    func testAccountsAndGoalsAreCoveredWithoutDefaultEmojiGlyphs() {
        XCTAssertEqual(AccountType.allCases.count, 11)
        XCTAssertEqual(GoalKind.allCases.count, 10)
        XCTAssertTrue(AccountType.allCases.allSatisfy { !$0.budgetGlyph.systemName.isEmpty })
        XCTAssertTrue(GoalKind.allCases.allSatisfy { !$0.budgetGlyph.systemName.isEmpty })
        XCTAssertTrue(
            BudgetGlyph.allCases.allSatisfy { glyph in
                glyph.systemName.unicodeScalars.allSatisfy { $0.isASCII }
            },
            "l'autorité visuelle utilise des glyphes, pas des emojis par défaut"
        )
    }

    func testNavigationIntentionsAndTransactionTypesUseCustomPwaVectors() {
        let visibleGlyphs =
            AppTab.allCases.map(\.budgetGlyph)
            + QuickEntryIntent.allCases.map(\.budgetGlyph)
            + TransactionType.allCases.map(\.budgetGlyph)

        XCTAssertTrue(visibleGlyphs.allSatisfy { $0.usesCustomVector })
        XCTAssertTrue(visibleGlyphs.allSatisfy { $0.pwaName != nil })

        let rect = CGRect(x: 0, y: 0, width: 24, height: 24)
        for glyph in Set(visibleGlyphs) {
            XCTAssertFalse(
                BudgetGlyphVectorPath.path(for: glyph, in: rect).isEmpty,
                "\(glyph.rawValue) doit posséder un tracé vectoriel"
            )
        }
    }

    func testCurvedGlyphsOpenIndependentSubpathsWithoutConnectorLines() {
        let rect = CGRect(x: 0, y: 0, width: 24, height: 24)
        let refundTypes = elementTypes(
            in: BudgetGlyphVectorPath.path(for: .refund, in: rect).cgPath
        )
        let recurringTypes = elementTypes(
            in: BudgetGlyphVectorPath.path(for: .recurring, in: rect).cgPath
        )

        XCTAssertEqual(refundTypes.filter { $0 == .moveToPoint }.count, 3)
        XCTAssertEqual(refundTypes.filter { $0 == .addCurveToPoint }.count, 4)
        XCTAssertEqual(refundTypes.filter { $0 == .addLineToPoint }.count, 3)

        XCTAssertEqual(recurringTypes.filter { $0 == .moveToPoint }.count, 4)
        XCTAssertEqual(recurringTypes.filter { $0 == .addCurveToPoint }.count, 2)
        XCTAssertEqual(recurringTypes.filter { $0 == .addLineToPoint }.count, 4)
    }

    func testPlannedExpensesUseWarningWhilePostedExpensesStayNegative() {
        XCTAssertEqual(TransactionType.expense.budgetPlannedIconTone, .warning)
        XCTAssertEqual(TransactionType.taxPayment.budgetPlannedIconTone, .warning)
        XCTAssertEqual(TransactionType.debtPayment.budgetPlannedIconTone, .warning)
        XCTAssertEqual(TransactionType.expense.budgetIconTone, .negative)
        XCTAssertEqual(TransactionType.income.budgetPlannedIconTone, .positive)
    }

    func testEveryNativeGlyphExistsOnTheMinimumSupportedOS() {
        for glyph in BudgetGlyph.allCases {
            XCTAssertNotNil(
                UIImage(systemName: glyph.systemName),
                "SF Symbol introuvable pour le rôle Budget Prisme \(glyph.rawValue) : \(glyph.systemName)"
            )
        }
    }

    @MainActor
    func testIconWellsRenderAtFortyAndFortyFourPoints() {
        XCTAssertEqual(NeonUltraIconMetric.well, 40)
        XCTAssertEqual(NeonUltraIconMetric.controlWell, 44)
        XCTAssertEqual(NeonUltraIconMetric.glyph, 18)
        XCTAssertEqual(NeonUltraIconMetric.radius, 12)

        let compact = measuredSize(BudgetIcon(.income, tone: .positive))
        XCTAssertEqual(compact.width, 40, accuracy: 0.5)
        XCTAssertEqual(compact.height, 40, accuracy: 0.5)

        let control = measuredSize(
            BudgetIcon(.add, tone: .brand, style: .control)
        )
        XCTAssertGreaterThanOrEqual(control.width, 44)
        XCTAssertGreaterThanOrEqual(control.height, 44)
    }

    @MainActor
    func testNativeTabImageKeepsVectorMetaphorAndExplicitSelectedShape() {
        let inactive = BudgetGlyphTabImage.image(for: .month, isSelected: false)
        let active = BudgetGlyphTabImage.image(for: .month, isSelected: true)

        XCTAssertEqual(inactive.renderingMode, .alwaysTemplate)
        XCTAssertEqual(active.renderingMode, .alwaysOriginal)
        XCTAssertEqual(inactive.size, CGSize(width: 24, height: 24))
        XCTAssertEqual(active.size, CGSize(width: 30, height: 24))
    }

    @MainActor
    private func measuredSize<V: View>(_ view: V) -> CGSize {
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        host.view.layoutIfNeeded()
        return host.sizeThatFits(in: CGSize(width: 200, height: 200))
    }

    private func elementTypes(in path: CGPath) -> [CGPathElementType] {
        var types: [CGPathElementType] = []
        path.applyWithBlock { element in
            types.append(element.pointee.type)
        }
        return types
    }
}
