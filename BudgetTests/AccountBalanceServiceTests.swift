import XCTest
import SwiftData
@testable import Budget

final class AccountBalanceServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = AccountBalanceService()

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    private func makeAccount(
        type: AccountType = .current,
        openingBalance: Decimal = Decimal("1000.00")
    ) -> Account {
        let account = Account(name: "Test", type: type, openingBalance: openingBalance)
        context.insert(account)
        return account
    }

    func testBalanceStartsAtOpeningBalance() {
        let account = makeAccount()
        XCTAssertEqual(service.balance(of: account, movements: []), Decimal("1000.00"))
    }

    func testIncomeIncreasesAndExpenseDecreasesBalance() {
        let account = makeAccount()
        let income = BudgetTransaction(
            date: Date(), amount: Decimal("500.00"), type: .income,
            title: "Salaire", account: account
        )
        let expense = BudgetTransaction(
            date: Date(), amount: Decimal("120.50"), type: .expense,
            title: "Courses", account: account
        )
        context.insert(income)
        context.insert(expense)

        let balance = service.balance(of: account, movements: [income, expense])
        XCTAssertEqual(balance, Decimal("1379.50"))
    }

    func testPlannedTransactionsNeverTouchBalances() {
        let account = makeAccount()
        let planned = BudgetTransaction(
            date: Date(), amount: Decimal("999.00"), type: .expense,
            status: .planned, title: "Facture prévue", account: account
        )
        context.insert(planned)

        XCTAssertEqual(service.balance(of: account, movements: [planned]), Decimal("1000.00"))
    }

    func testTransferMovesMoneyBetweenAccountsAtomically() {
        let source = makeAccount(openingBalance: Decimal("1000.00"))
        let destination = makeAccount(type: .savings, openingBalance: Decimal("200.00"))
        let transfer = BudgetTransaction(
            date: Date(), amount: Decimal("300.00"), type: .transfer,
            title: "Virement épargne", account: source, destinationAccount: destination
        )
        context.insert(transfer)

        XCTAssertEqual(service.balance(of: source, movements: [transfer]), Decimal("700.00"))
        XCTAssertEqual(service.balance(of: destination, movements: [transfer]), Decimal("500.00"))
        // The transfer moves money but creates or destroys nothing.
        let total = service.balance(of: source, movements: [transfer])
            + service.balance(of: destination, movements: [transfer])
        XCTAssertEqual(total, Decimal("1200.00"))
    }

    func testSavingWithDestinationCreditsDestination() {
        let source = makeAccount()
        let pillar3a = makeAccount(type: .pillar3a, openingBalance: .zero)
        let contribution = BudgetTransaction(
            date: Date(), amount: Decimal("587.00"), type: .investment,
            title: "Versement 3a", account: source, destinationAccount: pillar3a
        )
        context.insert(contribution)

        XCTAssertEqual(service.balance(of: source, movements: [contribution]), Decimal("413.00"))
        XCTAssertEqual(service.balance(of: pillar3a, movements: [contribution]), Decimal("587.00"))
    }

    func testAdjustmentDirectionIsExplicit() {
        let account = makeAccount()
        let up = BudgetTransaction(
            date: Date(), amount: Decimal("50.00"), type: .adjustment,
            title: "Correction +", adjustmentIncreasesBalance: true, account: account
        )
        let down = BudgetTransaction(
            date: Date(), amount: Decimal("20.00"), type: .adjustment,
            title: "Correction -", adjustmentIncreasesBalance: false, account: account
        )
        context.insert(up)
        context.insert(down)

        XCTAssertEqual(service.balance(of: account, movements: [up, down]), Decimal("1030.00"))
    }

    func testReconciliationOverridesHistoryBeforeItsDate() {
        let account = makeAccount()
        let now = Date()
        let before = BudgetTransaction(
            date: now.addingTimeInterval(-3600), amount: Decimal("100.00"),
            type: .expense, title: "Avant réconciliation", account: account
        )
        let after = BudgetTransaction(
            date: now.addingTimeInterval(3600), amount: Decimal("40.00"),
            type: .expense, title: "Après réconciliation", account: account
        )
        context.insert(before)
        context.insert(after)

        account.reconciledBalance = Decimal("2000.00")
        account.reconciledAt = now

        let balance = service.balance(of: account, movements: [before, after])
        XCTAssertEqual(balance, Decimal("1960.00"))
    }

    func testDuplicateMovementReferencesAreCountedOnce() {
        let account = makeAccount()
        let expense = BudgetTransaction(
            date: Date(), amount: Decimal("100.00"), type: .expense,
            title: "Unique", account: account
        )
        context.insert(expense)

        let balance = service.balance(of: account, movements: [expense, expense])
        XCTAssertEqual(balance, Decimal("900.00"))
    }
}
