import XCTest
import SwiftData
@testable import Budget

final class BudgetVarianceServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: BudgetVarianceService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var account: Account!
    private var savingsAccount: Account!
    private var food: BudgetCategory!
    private var housing: BudgetCategory!
    private var savingCategory: BudgetCategory!
    private var budget: MonthlyBudget!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = BudgetVarianceService(calendar: calendar)

        account = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        savingsAccount = Account(name: "Épargne", type: .savings)
        food = BudgetCategory(name: "Alimentation", kind: .expense, isEssential: true)
        housing = BudgetCategory(name: "Logement", kind: .expense, isEssential: true)
        savingCategory = BudgetCategory(name: "Épargne", kind: .saving)
        budget = MonthlyBudget(year: 2026, month: 6)
        context.insert(account)
        context.insert(savingsAccount)
        context.insert(food)
        context.insert(housing)
        context.insert(savingCategory)
        context.insert(budget)
    }

    override func tearDown() {
        account = nil
        savingsAccount = nil
        food = nil
        housing = nil
        savingCategory = nil
        budget = nil
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    private func date(day: Int, month: Int = 6) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 10))!
    }

    private func addLine(_ amount: Decimal, category: BudgetCategory) -> BudgetLine {
        let line = BudgetLine(plannedAmount: amount, category: category)
        line.budget = budget
        context.insert(line)
        return line
    }

    @discardableResult
    private func addTransaction(
        _ amount: Decimal,
        type: TransactionType,
        category: BudgetCategory?,
        day: Int = 5,
        month: Int = 6,
        status: TransactionStatus = .posted,
        destination: Account? = nil
    ) -> BudgetTransaction {
        let transaction = BudgetTransaction(
            date: date(day: day, month: month),
            amount: amount,
            type: type,
            status: status,
            title: "Test",
            account: account,
            destinationAccount: destination,
            category: category
        )
        context.insert(transaction)
        return transaction
    }

    private func makeReport(_ transactions: [BudgetTransaction]) -> BudgetReport {
        service.report(budget: budget, monthOf: now, transactions: transactions)
    }

    // MARK: - Line variance

    func testVarianceIsPlannedMinusActual() {
        _ = addLine(Decimal("600.00"), category: food)
        let t1 = addTransaction(Decimal("212.35"), type: .expense, category: food)
        let t2 = addTransaction(Decimal("150.00"), type: .expense, category: food)

        let report = makeReport([t1, t2])
        let line = report.lineReports[0]
        XCTAssertEqual(line.planned, Decimal("600.00"))
        XCTAssertEqual(line.actual, Decimal("362.35"))
        XCTAssertEqual(line.variance, Decimal("237.65"))
        XCTAssertFalse(line.isOverrun)
    }

    func testOverrunIsFlagged() {
        _ = addLine(Decimal("200.00"), category: food)
        let t = addTransaction(Decimal("250.00"), type: .expense, category: food)

        let line = makeReport([t]).lineReports[0]
        XCTAssertTrue(line.isOverrun)
        XCTAssertEqual(line.variance, Decimal("-50.00"))
        XCTAssertEqual(line.consumedFraction, Decimal(1), "Barre de progression bornée à 100 %")
    }

    func testActualExcludesPlannedTransactionsAndTransfers() {
        _ = addLine(Decimal("600.00"), category: food)
        let posted = addTransaction(Decimal("100.00"), type: .expense, category: food)
        let planned = addTransaction(Decimal("400.00"), type: .expense, category: food, status: .planned)
        let transfer = addTransaction(Decimal("999.00"), type: .transfer, category: nil, destination: savingsAccount)

        let report = makeReport([posted, planned, transfer])
        XCTAssertEqual(report.lineReports[0].actual, Decimal("100.00"))
        XCTAssertTrue(report.outOfBudget.isEmpty, "Un virement n'apparaît jamais dans un budget")
    }

    func testRefundsReduceTheirCategoryActual() {
        _ = addLine(Decimal("600.00"), category: food)
        let expense = addTransaction(Decimal("300.00"), type: .expense, category: food)
        let refund = addTransaction(Decimal("80.00"), type: .refund, category: food)

        XCTAssertEqual(makeReport([expense, refund]).lineReports[0].actual, Decimal("220.00"))
    }

    func testActualRespectsMonthBoundaries() {
        _ = addLine(Decimal("600.00"), category: food)
        let june = addTransaction(Decimal("100.00"), type: .expense, category: food, day: 1)
        let july = addTransaction(Decimal("999.00"), type: .expense, category: food, day: 1, month: 7)
        let may = addTransaction(Decimal("999.00"), type: .expense, category: food, day: 31, month: 5)

        XCTAssertEqual(makeReport([june, july, may]).lineReports[0].actual, Decimal("100.00"))
    }

    func testDebtPaymentsCountAgainstExpenseCategory() {
        _ = addLine(Decimal("500.00"), category: housing)
        let debt = addTransaction(Decimal("450.00"), type: .debtPayment, category: housing)
        XCTAssertEqual(makeReport([debt]).lineReports[0].actual, Decimal("450.00"))
    }

    func testSavingLineMatchesSavingTransactions() {
        _ = addLine(Decimal("600.00"), category: savingCategory)
        let saving = addTransaction(Decimal("600.00"), type: .saving, category: savingCategory, destination: savingsAccount)
        let line = makeReport([saving]).lineReports[0]
        XCTAssertEqual(line.actual, Decimal("600.00"))
        XCTAssertEqual(line.variance, .zero)
    }

    // MARK: - Reconciliation

    func testEveryPostedFrancIsEitherInALineOrOutOfBudget() {
        _ = addLine(Decimal("600.00"), category: food)
        let inLine = addTransaction(Decimal("200.00"), type: .expense, category: food)
        let otherCategory = addTransaction(Decimal("2150.00"), type: .expense, category: housing)
        let uncategorized = addTransaction(Decimal("45.50"), type: .expense, category: nil)

        let report = makeReport([inLine, otherCategory, uncategorized])
        XCTAssertEqual(report.totalActualInLines, Decimal("200.00"))
        XCTAssertEqual(report.totalOutOfBudget, Decimal("2195.50"))
        // Réconciliation globale : rien n'est perdu.
        XCTAssertEqual(
            report.totalActualInLines + report.totalOutOfBudget,
            Decimal("2395.50")
        )
        XCTAssertEqual(report.outOfBudget.count, 2)
        XCTAssertTrue(report.outOfBudget.contains { $0.categoryName == "Sans catégorie" })
    }

    func testPlannedAndActualStayIndependentlyQueryable() {
        // Une ligne sans aucune transaction…
        _ = addLine(Decimal("600.00"), category: food)
        // …et une transaction sans aucune ligne.
        let loneExpense = addTransaction(Decimal("100.00"), type: .expense, category: housing)

        let report = makeReport([loneExpense])
        XCTAssertEqual(report.lineReports[0].planned, Decimal("600.00"))
        XCTAssertEqual(report.lineReports[0].actual, .zero)
        XCTAssertEqual(report.totalOutOfBudget, Decimal("100.00"))
    }

    func testKindTotalsReconcile() {
        _ = addLine(Decimal("600.00"), category: food)
        _ = addLine(Decimal("2150.00"), category: housing)
        _ = addLine(Decimal("600.00"), category: savingCategory)

        let report = makeReport([])
        XCTAssertEqual(report.totalPlanned(kind: .expense), Decimal("2750.00"))
        XCTAssertEqual(report.totalPlanned(kind: .saving), Decimal("600.00"))
        XCTAssertEqual(report.totalPlanned, Decimal("3350.00"))
    }

    func testEmptyBudgetReportsEverythingOutOfBudget() {
        let expense = addTransaction(Decimal("120.00"), type: .expense, category: food)
        let report = service.report(budget: nil, monthOf: now, transactions: [expense])
        XCTAssertTrue(report.lineReports.isEmpty)
        XCTAssertEqual(report.totalOutOfBudget, Decimal("120.00"))
    }
}
