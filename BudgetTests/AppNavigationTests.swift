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
            ["J'ai dépensé", "J'ai reçu", "J'ai mis de côté", "Ça revient régulièrement"]
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
            (.expense, "Payé", "À payer"),
            (.taxPayment, "Payé", "À payer"),
            (.debtPayment, "Payé", "À payer"),
            (.saving, "Mis de côté", "À mettre de côté"),
            (.investment, "Investi", "À investir"),
            (.transfer, "Transféré", "À transférer"),
            (.adjustment, "Confirmé", "À confirmer"),
        ]

        XCTAssertEqual(expected.count, TransactionType.allCases.count)
        for (type, verb, label) in expected {
            XCTAssertEqual(HomePilotDisplay.actionVerb(for: type), verb)
            XCTAssertEqual(HomePilotDisplay.actionLabel(for: type), label)
        }
    }

    func testMonthlyProgressAlwaysSaysWhatRemainsAndWhatIsDone() {
        XCTAssertEqual(HomePilotDisplay.monthProgress(pending: 0, completed: 0), "Rien à faire")
        XCTAssertEqual(HomePilotDisplay.monthProgress(pending: 2, completed: 0), "2 à faire")
        XCTAssertEqual(HomePilotDisplay.monthProgress(pending: 0, completed: 1), "Tout est à jour · 1 fait")
        XCTAssertEqual(HomePilotDisplay.monthProgress(pending: 2, completed: 4), "2 à faire · 4 faits")
        XCTAssertEqual(HomePilotDisplay.monthProgress(pending: 0, completed: 0, isFuture: true), "Rien de prévu")
        XCTAssertEqual(HomePilotDisplay.monthProgress(pending: 2, completed: 0, isFuture: true), "2 prévus")
    }

    func testMonthlyDashboardKeepsOnlyPostedRegularOperationsAsDone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        let august = calendar.date(from: DateComponents(year: 2026, month: 8, day: 14))!
        let july = calendar.date(from: DateComponents(year: 2026, month: 7, day: 31))!
        let interval = MonthInterval(containing: august, calendar: calendar)
        let recurringID = UUID()
        let salary = BudgetTransaction(
            date: august,
            amount: 4_500,
            type: .income,
            status: .posted,
            title: "Salaire",
            recurringID: recurringID
        )
        let plannedRent = BudgetTransaction(
            date: august,
            amount: 1_500,
            type: .expense,
            status: .planned,
            title: "Loyer",
            recurringID: recurringID
        )
        let manual = BudgetTransaction(
            date: august,
            amount: 30,
            type: .expense,
            status: .posted,
            title: "Courses"
        )
        let old = BudgetTransaction(
            date: july,
            amount: 100,
            type: .saving,
            status: .posted,
            title: "Épargne",
            recurringID: recurringID
        )

        let completed = HomePilotDisplay.completedTransactions(
            in: interval,
            from: [plannedRent, old, salary, manual]
        )
        let planned = HomePilotDisplay.plannedRegularTransactions(
            in: interval,
            from: [plannedRent, old, salary, manual]
        )

        XCTAssertEqual(completed.map(\.title), ["Salaire"])
        XCTAssertEqual(planned.map(\.title), ["Loyer"])
    }

    func testOnlyTheNextOccurrenceOfEachRegularLineCanBeConfirmed() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        let firstRecurring = UUID()
        let secondRecurring = UUID()
        func occurrence(_ id: String, _ recurringID: UUID, day: Int) -> ForecastOccurrence {
            ForecastOccurrence(
                id: id,
                recurringID: recurringID,
                title: id,
                amount: 20,
                type: .expense,
                date: calendar.date(from: DateComponents(year: 2026, month: 8, day: day))!,
                isSubscription: false
            )
        }
        let occurrences = [
            occurrence("weekly-15", firstRecurring, day: 15),
            occurrence("other-12", secondRecurring, day: 12),
            occurrence("weekly-01", firstRecurring, day: 1),
            occurrence("weekly-08", firstRecurring, day: 8),
        ]

        XCTAssertEqual(
            HomePilotDisplay.confirmableOccurrenceIDs(from: occurrences),
            Set(["weekly-01", "other-12"])
        )
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
