import XCTest
import SwiftData
@testable import Budget

final class PersistenceFoundationTests: XCTestCase {
    func testInMemoryContainerRoundTripsAHousehold() throws {
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)

        let household = Household(name: "Test", canton: "VD", municipality: "Lausanne")
        context.insert(household)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Household>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test")
        XCTAssertEqual(fetched.first?.baseCurrencyCode, "CHF")
        XCTAssertEqual(fetched.first?.taxProvisionRate, Decimal("0.30"))
    }

    func testDefaultCategoriesCoverEveryKindAndStayOrdered() {
        let categories = DefaultCategories.makeCategories()
        XCTAssertFalse(categories.isEmpty)

        let kinds = Set(categories.map(\.kind))
        for kind in CategoryKind.allCases {
            XCTAssertTrue(kinds.contains(kind), "Kind \(kind) missing from defaults")
        }

        XCTAssertEqual(categories.map(\.sortOrder), Array(0..<categories.count))
        XCTAssertEqual(Set(categories.map(\.name)).count, categories.count, "Category names must be unique")
    }

    func testDemoDataPopulatesIsolatedContainer() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = FinanceFormatting.locale
        let container = try PersistenceFactory.makeInMemoryContainer()
        let reference = Date(timeIntervalSince1970: 1_781_524_800)

        DemoDataFactory.populate(container: container, now: reference, calendar: calendar)

        let context = ModelContext(container)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Household>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Account>()).count, 4)
        let transactions = try context.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertFalse(transactions.isEmpty)
        XCTAssertTrue(transactions.allSatisfy { $0.date <= reference }, "Demo history must not contain future movements")
        XCTAssertTrue(transactions.allSatisfy { $0.amount > 0 }, "Positive-amount convention")
    }

    func testMonthIntervalIsHalfOpen() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!

        let midJuly = calendar.date(from: DateComponents(year: 2026, month: 7, day: 19))!
        let interval = MonthInterval(containing: midJuly, calendar: calendar)

        let firstOfJuly = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        let lastOfJuly = calendar.date(from: DateComponents(year: 2026, month: 7, day: 31, hour: 23, minute: 59))!
        let firstOfAugust = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!

        XCTAssertTrue(interval.contains(firstOfJuly))
        XCTAssertTrue(interval.contains(lastOfJuly))
        XCTAssertFalse(interval.contains(firstOfAugust))
    }
}
