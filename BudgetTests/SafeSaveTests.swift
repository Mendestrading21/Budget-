import XCTest
import SwiftData
@testable import Budget

final class SafeSaveTests: XCTestCase {
    func testSaveFailureRollsBackPendingUserMutation() throws {
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        let account = Account(name: "Courant", type: .current)
        let transaction = BudgetTransaction(
            date: Date(timeIntervalSince1970: 1_781_524_800),
            amount: Decimal("45.00"),
            type: .expense,
            title: "Courses",
            account: account
        )
        context.insert(account)
        context.insert(transaction)
        try context.save()

        // Account.transactions uses a deny rule: deleting the account while
        // its movement remains must fail, which gives a deterministic save
        // error without a mock ModelContext.
        context.delete(account)
        var message: String?
        let succeeded = context.saveOrRollback { message = $0 }

        XCTAssertFalse(succeeded)
        XCTAssertNotNil(message)
        let freshContext = ModelContext(container)
        XCTAssertEqual(try freshContext.fetch(FetchDescriptor<Account>()).count, 1)
        XCTAssertEqual(try freshContext.fetch(FetchDescriptor<BudgetTransaction>()).count, 1)
    }
}
