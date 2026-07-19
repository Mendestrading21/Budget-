import XCTest
import SwiftData
@testable import Budget

final class AccountLifecycleTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    func testDefaultCashInclusionFollowsAccountType() {
        XCTAssertTrue(Account(name: "Courant", type: .current).includeInAvailableCash)
        XCTAssertTrue(Account(name: "Espèces", type: .cash).includeInAvailableCash)
        XCTAssertFalse(Account(name: "3a", type: .pillar3a).includeInAvailableCash)
        XCTAssertFalse(Account(name: "Titres", type: .broker).includeInAvailableCash)
    }

    func testLiabilityTypes() {
        XCTAssertTrue(AccountType.creditCard.isLiability)
        XCTAssertTrue(AccountType.mortgage.isLiability)
        XCTAssertTrue(AccountType.loan.isLiability)
        XCTAssertFalse(AccountType.current.isLiability)
        XCTAssertFalse(AccountType.pillar3a.isLiability)
    }

    func testArchivingKeepsHistory() throws {
        let account = Account(name: "Ancien compte", type: .current, openingBalance: Decimal("100.00"))
        context.insert(account)
        let movement = BudgetTransaction(
            date: Date(), amount: Decimal("40.00"), type: .expense,
            title: "Courses", account: account
        )
        context.insert(movement)
        try context.save()

        account.isActive = false
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertFalse(fetched[0].isActive)
        XCTAssertEqual(fetched[0].transactions.count, 1)
    }

    func testAccountPersistsAcrossContexts() throws {
        let account = Account(
            name: "Persisté",
            type: .savings,
            openingBalance: Decimal("1234.56")
        )
        context.insert(account)
        try context.save()

        // A fresh context simulates a relaunch against the same store.
        let secondContext = ModelContext(container)
        let fetched = try secondContext.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Persisté")
        XCTAssertEqual(fetched.first?.openingBalance, Decimal("1234.56"))
        XCTAssertEqual(fetched.first?.type, .savings)
    }
}
