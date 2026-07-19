import XCTest
import SwiftData
@testable import Budget

final class BudgetPlanningServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: BudgetPlanningService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var food: BudgetCategory!
    private var housing: BudgetCategory!
    private var archivedCategory: BudgetCategory!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = BudgetPlanningService(calendar: calendar)

        food = BudgetCategory(name: "Alimentation", kind: .expense)
        housing = BudgetCategory(name: "Logement", kind: .expense)
        archivedCategory = BudgetCategory(name: "Ancienne", kind: .expense, isActive: false)
        context.insert(food)
        context.insert(housing)
        context.insert(archivedCategory)
    }

    override func tearDown() {
        food = nil
        housing = nil
        archivedCategory = nil
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    private func date(day: Int, month: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 10))!
    }

    // MARK: - findOrCreate

    func testFindOrCreateNeverDuplicatesAMonth() throws {
        let first = try service.findOrCreate(monthOf: now, now: now, context: context)
        let second = try service.findOrCreate(monthOf: date(day: 28, month: 6), now: now, context: context)

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(try context.fetch(FetchDescriptor<MonthlyBudget>()).count, 1)
        XCTAssertEqual(first.year, 2026)
        XCTAssertEqual(first.month, 6)
    }

    func testFindOrCreatePersistsAcrossContexts() throws {
        _ = try service.findOrCreate(monthOf: now, now: now, context: context)

        let secondContext = ModelContext(container)
        let fetched = try service.budget(monthOf: now, context: secondContext)
        XCTAssertNotNil(fetched)
    }

    // MARK: - Copy previous month

    private func makeMayBudget() throws -> MonthlyBudget {
        let may = try service.findOrCreate(monthOf: date(day: 1, month: 5), now: now, context: context)
        for (category, amount) in [(food!, Decimal("600.00")), (housing!, Decimal("2150.00"))] {
            let line = BudgetLine(plannedAmount: amount, category: category)
            line.budget = may
            context.insert(line)
        }
        try context.save()
        return may
    }

    func testCopyPreviousMonthCopiesAmounts() throws {
        _ = try makeMayBudget()

        let copied = try service.copyPreviousMonthLines(into: now, now: now, context: context)
        XCTAssertEqual(copied, 2)

        let june = try XCTUnwrap(service.budget(year: 2026, month: 6, context: context))
        XCTAssertEqual(june.lines.count, 2)
        let amounts = Set(june.lines.map(\.plannedAmount))
        XCTAssertEqual(amounts, [Decimal("600.00"), Decimal("2150.00")])
    }

    func testCopySkipsExistingCategoriesAndKeepsTheirAmounts() throws {
        _ = try makeMayBudget()
        let june = try service.findOrCreate(monthOf: now, now: now, context: context)
        let existing = BudgetLine(plannedAmount: Decimal("700.00"), category: food)
        existing.budget = june
        context.insert(existing)
        try context.save()

        let copied = try service.copyPreviousMonthLines(into: now, now: now, context: context)
        XCTAssertEqual(copied, 1, "Seul Logement est copié ; Alimentation existait déjà")

        let foodLines = june.lines.filter { $0.category?.id == food.id }
        XCTAssertEqual(foodLines.count, 1)
        XCTAssertEqual(foodLines.first?.plannedAmount, Decimal("700.00"), "La ligne existante garde son montant")
    }

    func testCopySkipsArchivedCategories() throws {
        let may = try makeMayBudget()
        let archivedLine = BudgetLine(plannedAmount: Decimal("50.00"), category: archivedCategory)
        archivedLine.budget = may
        context.insert(archivedLine)
        try context.save()

        let copied = try service.copyPreviousMonthLines(into: now, now: now, context: context)
        XCTAssertEqual(copied, 2, "La catégorie archivée n'est pas copiée")
    }

    func testCopyDoesNotCreateEmptyBudgetWhenNothingIsCopyable() throws {
        // Le budget de mai n'a qu'une ligne de catégorie archivée.
        let may = try service.findOrCreate(monthOf: date(day: 1, month: 5), now: now, context: context)
        let archivedLine = BudgetLine(plannedAmount: Decimal("50.00"), category: archivedCategory)
        archivedLine.budget = may
        context.insert(archivedLine)
        try context.save()

        let copied = try service.copyPreviousMonthLines(into: now, now: now, context: context)
        XCTAssertEqual(copied, 0)
        XCTAssertNil(try service.budget(year: 2026, month: 6, context: context), "Aucun budget vide créé en effet de bord")
    }

    func testCopyWithoutPreviousBudgetDoesNothing() throws {
        let copied = try service.copyPreviousMonthLines(into: now, now: now, context: context)
        XCTAssertEqual(copied, 0)
        XCTAssertNil(try service.budget(year: 2026, month: 6, context: context))
    }

    // MARK: - Schema V2 smoke

    func testSchemaV2RoundTripsBudgetsWithLines() throws {
        let budget = try service.findOrCreate(monthOf: now, now: now, context: context)
        let line = BudgetLine(plannedAmount: Decimal("600.00"), category: food)
        line.budget = budget
        context.insert(line)
        try context.save()

        let secondContext = ModelContext(container)
        let budgets = try secondContext.fetch(FetchDescriptor<MonthlyBudget>())
        XCTAssertEqual(budgets.count, 1)
        XCTAssertEqual(budgets.first?.lines.count, 1)
        XCTAssertEqual(budgets.first?.lines.first?.plannedAmount, Decimal("600.00"))
        XCTAssertEqual(budgets.first?.lines.first?.category?.name, "Alimentation")
    }

    func testDeletingBudgetCascadesToLinesButNotCategories() throws {
        let budget = try service.findOrCreate(monthOf: now, now: now, context: context)
        let line = BudgetLine(plannedAmount: Decimal("600.00"), category: food)
        line.budget = budget
        context.insert(line)
        try context.save()

        context.delete(budget)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<BudgetLine>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BudgetCategory>()).count, 3, "Les catégories survivent au budget")
    }
}
