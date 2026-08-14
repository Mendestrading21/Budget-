import XCTest
@testable import Budget

final class AppNavigationTests: XCTestCase {
    func testMainNavigationStaysLimitedToFiveClearDestinations() {
        XCTAssertEqual(AppTab.allCases.count, 5)
        XCTAssertEqual(
            AppTab.allCases.map(\.title),
            ["Mois", "Historique", "Budget", "Comptes", "Gérer"]
        )
    }

    func testEveryMainDestinationHasAnIconAndUniqueTitle() {
        let titles = AppTab.allCases.map(\.title)
        let icons = AppTab.allCases.map(\.systemImage)

        XCTAssertEqual(Set(titles).count, titles.count)
        XCTAssertTrue(icons.allSatisfy { !$0.isEmpty })
    }

    func testQuickEntryOffersExactlyFourPlainIntentions() {
        XCTAssertEqual(
            QuickEntryIntent.allCases.map(\.title),
            ["J'ai dépensé", "J'ai reçu", "J'ai mis de côté", "Ça revient chaque mois"]
        )
        XCTAssertEqual(QuickEntryIntent.expense.transactionType, .expense)
        XCTAssertEqual(QuickEntryIntent.income.transactionType, .income)
        XCTAssertEqual(QuickEntryIntent.setAside.transactionType, .saving)
        XCTAssertNil(QuickEntryIntent.recurring.transactionType)
    }

    func testRecurringEntryOffersExactlyFourPlainKinds() {
        XCTAssertEqual(
            RecurringEntryKind.allCases.map(\.title),
            ["Facture", "Abonnement", "Revenu", "Mise de côté"]
        )
        XCTAssertEqual(RecurringEntryKind.bill.defaultTransactionType, .expense)
        XCTAssertEqual(RecurringEntryKind.subscription.defaultTransactionType, .expense)
        XCTAssertTrue(RecurringEntryKind.subscription.marksSubscription)
        XCTAssertEqual(RecurringEntryKind.income.defaultTransactionType, .income)
        XCTAssertEqual(RecurringEntryKind.setAside.defaultTransactionType, .saving)
    }

    func testMonthlyChecklistUsesTheTrueVerbForEveryFinancialNature() {
        let expected: [(TransactionType, String, String)] = [
            (.income, "Reçu", "À recevoir"),
            (.refund, "Reçu", "À recevoir"),
            (.expense, "Payée", "À payer"),
            (.taxPayment, "Payée", "À payer"),
            (.debtPayment, "Payée", "À payer"),
            (.saving, "Mis de côté", "À mettre de côté"),
            (.investment, "Versé", "À investir"),
            (.transfer, "Effectué", "À transférer"),
            (.adjustment, "Confirmé", "À confirmer"),
        ]

        XCTAssertEqual(expected.count, TransactionType.allCases.count)
        for (type, verb, label) in expected {
            XCTAssertEqual(HomePilotDisplay.actionVerb(for: type), verb)
            XCTAssertEqual(HomePilotDisplay.actionLabel(for: type), label)
        }
    }

    func testFutureMonthlyActionCannotBeConfirmedAsAlreadyDone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 12))!
        let laterToday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 23))!
        let tomorrow = calendar.date(from: DateComponents(year: 2026, month: 8, day: 15, hour: 8))!

        XCTAssertTrue(HomePilotDisplay.canConfirm(date: laterToday, now: now, calendar: calendar))
        XCTAssertFalse(HomePilotDisplay.canConfirm(date: tomorrow, now: now, calendar: calendar))
    }

    func testGuidedTransactionKeepsTheMonthDatePassedByHome() {
        let now = Date(timeIntervalSince1970: 1_786_700_000)
        let selectedMonthDate = Date(timeIntervalSince1970: 1_778_000_000)

        XCTAssertEqual(
            TransactionFormView.initialDate(prefilledDate: selectedMonthDate, now: now),
            selectedMonthDate
        )
        XCTAssertEqual(TransactionFormView.initialDate(prefilledDate: nil, now: now), now)
    }
}
