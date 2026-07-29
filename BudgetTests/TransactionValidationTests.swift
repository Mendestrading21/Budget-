import XCTest
import SwiftData
@testable import Budget

final class TransactionValidationTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = TransactionValidationService()
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var activeAccount: Account!
    private var otherAccount: Account!
    private var archivedAccount: Account!
    private var expenseCategory: BudgetCategory!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        activeAccount = Account(name: "Courant", type: .current)
        otherAccount = Account(name: "Épargne", type: .savings)
        archivedAccount = Account(name: "Ancien", type: .current, isActive: false)
        expenseCategory = BudgetCategory(name: "Alimentation", kind: .expense)
        context.insert(activeAccount)
        context.insert(otherAccount)
        context.insert(archivedAccount)
        context.insert(expenseCategory)
    }

    override func tearDown() {
        activeAccount = nil
        otherAccount = nil
        archivedAccount = nil
        expenseCategory = nil
        context = nil
        container = nil
    }

    private func validDraft() -> TransactionDraft {
        TransactionDraft(
            date: now,
            amount: Decimal("45.50"),
            type: .expense,
            status: .posted,
            title: "Courses",
            account: activeAccount,
            category: expenseCategory
        )
    }

    func testValidExpensePasses() {
        XCTAssertTrue(service.validate(validDraft(), now: now).isEmpty)
    }

    func testMissingDateFails() {
        var draft = validDraft()
        draft.date = nil
        XCTAssertTrue(service.validate(draft, now: now).contains(.missingDate))
    }

    func testPostedFutureDateFails() {
        var draft = validDraft()
        draft.date = now.addingTimeInterval(86_400)
        XCTAssertTrue(service.validate(draft, now: now).contains(.postedDateInFuture))
    }

    func testAutomaticPostingPolicyUsesCalendarDayAcrossYearBoundary() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let policy = TransactionPostingPolicy(calendar: calendar)
        let newYearsEve = calendar.date(
            from: DateComponents(year: 2026, month: 12, day: 31, hour: 23)
        )!
        let newYear = calendar.date(
            from: DateComponents(year: 2027, month: 1, day: 1, hour: 0)
        )!

        XCTAssertEqual(policy.automaticStatus(for: newYearsEve, now: newYearsEve), .posted)
        XCTAssertEqual(policy.automaticStatus(for: newYear, now: newYearsEve), .planned)
    }

    func testDuePlannedTransactionsPromoteOnceAndFutureStaysNeutral() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let policy = TransactionPostingPolicy(calendar: calendar)
        let today = calendar.date(from: DateComponents(year: 2026, month: 7, day: 29, hour: 12))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let dueBefore = BudgetTransaction(
            date: yesterday, amount: 40, type: .expense,
            status: .planned, title: "Échue", account: activeAccount
        )
        let dueToday = BudgetTransaction(
            date: today, amount: 50, type: .expense,
            status: .planned, title: "Aujourd'hui", account: activeAccount
        )
        let future = BudgetTransaction(
            date: tomorrow, amount: 60, type: .expense,
            status: .planned, title: "Demain", account: activeAccount
        )

        XCTAssertEqual(
            policy.promoteDueTransactions([dueBefore, dueToday, future], now: today),
            2
        )
        XCTAssertEqual(dueBefore.status, .posted)
        XCTAssertEqual(dueToday.status, .posted)
        XCTAssertEqual(future.status, .planned)
        XCTAssertEqual(
            policy.promoteDueTransactions([dueBefore, dueToday, future], now: today),
            0,
            "Une échéance déjà promue ne doit jamais être recomptée"
        )
    }

    func testPostingPolicyUsesZurichCalendarDayAcrossDST() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        let policy = TransactionPostingPolicy(calendar: calendar)
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 29, hour: 0, minute: 30)
        )!
        let sameDayLate = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 29, hour: 23, minute: 30)
        )!
        let nextDay = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 30, hour: 0)
        )!

        XCTAssertEqual(policy.automaticStatus(for: sameDayLate, now: now), .posted)
        XCTAssertEqual(policy.automaticStatus(for: nextDay, now: now), .planned)
    }

    @MainActor
    func testAppContainerPromotesTheMainContextAndPersistsIt() throws {
        let fixedNow = Date(timeIntervalSince1970: 1_785_278_400)
        let appContainer = try AppContainer(
            dateProvider: FixedDateProvider(now: fixedNow),
            inMemory: true
        )
        let mainContext = appContainer.modelContainer.mainContext
        let account = Account(name: "Courant", type: .current)
        let due = BudgetTransaction(
            date: appContainer.calendar.date(byAdding: .day, value: -1, to: fixedNow)!,
            amount: 75,
            type: .expense,
            status: .planned,
            title: "Échéance à promouvoir",
            account: account
        )
        let future = BudgetTransaction(
            date: appContainer.calendar.date(byAdding: .day, value: 1, to: fixedNow)!,
            amount: 90,
            type: .expense,
            status: .planned,
            title: "Échéance future",
            account: account
        )
        mainContext.insert(account)
        mainContext.insert(due)
        mainContext.insert(future)
        try mainContext.save()
        let alreadyLoaded = try mainContext.fetch(FetchDescriptor<BudgetTransaction>())
        let loadedDue = try XCTUnwrap(
            alreadyLoaded.first { $0.title == "Échéance à promouvoir" }
        )
        let loadedFuture = try XCTUnwrap(
            alreadyLoaded.first { $0.title == "Échéance future" }
        )

        appContainer.postDuePlannedTransactions()

        XCTAssertNil(appContainer.duePostingErrorMessage)
        XCTAssertEqual(loadedDue.status, .posted)
        XCTAssertEqual(loadedFuture.status, .planned)
        let readContext = ModelContext(appContainer.modelContainer)
        let persisted = try readContext.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(
            persisted.first { $0.title == "Échéance à promouvoir" }?.status,
            .posted
        )
        XCTAssertEqual(
            persisted.first { $0.title == "Échéance future" }?.status,
            .planned
        )
    }

    @MainActor
    func testPromotionNeverCommitsOrRollsBackPendingMainContextEdits() throws {
        let fixedNow = Date(timeIntervalSince1970: 1_785_278_400)
        let appContainer = try AppContainer(
            dateProvider: FixedDateProvider(now: fixedNow),
            inMemory: true
        )
        let mainContext = appContainer.modelContainer.mainContext
        let account = Account(name: "Courant", type: .current)
        let due = BudgetTransaction(
            date: appContainer.calendar.date(byAdding: .day, value: -1, to: fixedNow)!,
            amount: 75,
            type: .expense,
            status: .planned,
            title: "Échéance protégée",
            account: account
        )
        mainContext.insert(account)
        mainContext.insert(due)
        try mainContext.save()

        account.name = "Édition non enregistrée"
        XCTAssertTrue(mainContext.hasChanges)
        appContainer.postDuePlannedTransactions()

        XCTAssertTrue(mainContext.hasChanges, "La maintenance ne doit pas annuler l'édition en cours")
        XCTAssertEqual(account.name, "Édition non enregistrée")
        XCTAssertEqual(due.status, .planned)
        XCTAssertNotNil(appContainer.duePostingErrorMessage)
        mainContext.rollback()

        let readContext = ModelContext(appContainer.modelContainer)
        let persisted = try readContext.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(persisted.first?.status, .planned)
    }

    func testPlannedFutureDateIsAllowed() {
        var draft = validDraft()
        draft.status = .planned
        draft.date = now.addingTimeInterval(10 * 86_400)
        XCTAssertTrue(service.validate(draft, now: now).isEmpty)
    }

    func testMissingAndNonPositiveAmountsFail() {
        var draft = validDraft()
        draft.amount = nil
        XCTAssertTrue(service.validate(draft, now: now).contains(.missingAmount))

        draft.amount = .zero
        XCTAssertTrue(service.validate(draft, now: now).contains(.nonPositiveAmount))

        draft.amount = Decimal("-10")
        XCTAssertTrue(service.validate(draft, now: now).contains(.nonPositiveAmount))
    }

    func testMissingTitleAccountAndCategoryFail() {
        var draft = validDraft()
        draft.title = "   "
        draft.account = nil
        draft.category = nil
        let errors = service.validate(draft, now: now)
        XCTAssertTrue(errors.contains(.missingTitle))
        XCTAssertTrue(errors.contains(.missingAccount))
        XCTAssertTrue(errors.contains(.missingCategory))
    }

    func testArchivedAccountFailsUnlessHistoricalEdit() {
        var draft = validDraft()
        draft.account = archivedAccount
        XCTAssertTrue(service.validate(draft, now: now).contains(.inactiveAccount))
        XCTAssertFalse(service.validate(draft, now: now, allowInactiveAccounts: true).contains(.inactiveAccount))
    }

    func testTransferRequiresDistinctDestination() {
        var draft = validDraft()
        draft.type = .transfer
        draft.category = nil

        draft.destinationAccount = nil
        XCTAssertTrue(service.validate(draft, now: now).contains(.missingTransferDestination))

        draft.destinationAccount = activeAccount
        XCTAssertTrue(service.validate(draft, now: now).contains(.transferDestinationEqualsSource))

        draft.destinationAccount = archivedAccount
        XCTAssertTrue(service.validate(draft, now: now).contains(.inactiveDestination))

        draft.destinationAccount = otherAccount
        XCTAssertTrue(service.validate(draft, now: now).isEmpty)
    }

    func testTransferNeedsNoCategory() {
        var draft = validDraft()
        draft.type = .transfer
        draft.category = nil
        draft.destinationAccount = otherAccount
        XCTAssertTrue(service.validate(draft, now: now).isEmpty)
        XCTAssertFalse(service.categoryRequired(for: .transfer))
        XCTAssertFalse(service.categoryRequired(for: .adjustment))
        XCTAssertTrue(service.categoryRequired(for: .expense))
        XCTAssertTrue(service.categoryRequired(for: .income))
    }

    func testDestinationRejectedForPlainExpense() {
        var draft = validDraft()
        draft.destinationAccount = otherAccount
        XCTAssertTrue(service.validate(draft, now: now).contains(.destinationNotSupported))
    }

    func testSavingWithOptionalDestinationIsValid() {
        var draft = validDraft()
        draft.type = .saving
        draft.category = BudgetCategory(name: "Épargne", kind: .saving)
        draft.destinationAccount = otherAccount
        XCTAssertTrue(service.validate(draft, now: now).isEmpty)

        draft.destinationAccount = nil
        XCTAssertTrue(service.validate(draft, now: now).isEmpty)
    }

    func testEveryErrorHasAFrenchMessage() {
        let allErrors: [TransactionValidationError] = [
            .missingDate, .postedDateInFuture, .missingAmount, .nonPositiveAmount,
            .missingTitle, .missingAccount, .inactiveAccount, .missingCategory,
            .missingTransferDestination, .transferDestinationEqualsSource,
            .inactiveDestination, .destinationNotSupported,
        ]
        for error in allErrors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "\(error) has no message")
        }
    }
}
