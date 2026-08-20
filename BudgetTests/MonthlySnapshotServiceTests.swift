import XCTest
import SwiftData
@testable import Budget

final class MonthlySnapshotServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: MonthlySnapshotService!

    // 15.06.2026 12:00 UTC — mid-month reference.
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var household: Household!
    private var current: Account!
    private var savings: Account!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = MonthlySnapshotService(calendar: calendar)

        // ADR-035 : le taux hérité stocké reste à 30 % EXPRÈS — chaque test
        // prouve qu'il est lettre morte.
        household = Household(name: "Test", taxProvisionRate: Decimal("0.30"))
        current = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        savings = Account(name: "Épargne", type: .savings, openingBalance: Decimal("1000.00"))
        context.insert(household)
        context.insert(current)
        context.insert(savings)
    }

    override func tearDown() {
        household = nil
        current = nil
        savings = nil
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    private func date(day: Int, month: Int = 6, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 10))!
    }

    private func insert(_ transaction: BudgetTransaction) -> BudgetTransaction {
        context.insert(transaction)
        return transaction
    }

    private func makeSnapshot(_ transactions: [BudgetTransaction]) -> MonthSnapshot {
        service.snapshot(
            monthOf: now,
            now: now,
            household: household,
            accounts: [current, savings],
            transactions: transactions
        )
    }

    // MARK: - Core totals

    func testTotalsSeparateLivingCostsFromSavingsAndTaxes() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 1), amount: Decimal("8000.00"), type: .income, title: "Salaire", account: current)),
            insert(BudgetTransaction(date: date(day: 2), amount: Decimal("2000.00"), type: .expense, title: "Loyer", account: current)),
            insert(BudgetTransaction(date: date(day: 3), amount: Decimal("500.00"), type: .saving, title: "Épargne", account: current, destinationAccount: savings)),
            insert(BudgetTransaction(date: date(day: 4), amount: Decimal("300.00"), type: .investment, title: "3a", account: current)),
            insert(BudgetTransaction(date: date(day: 5), amount: Decimal("1000.00"), type: .taxPayment, title: "Impôts", account: current)),
        ]
        let snapshot = makeSnapshot(transactions)

        XCTAssertEqual(snapshot.totalIncome, Decimal("8000.00"))
        XCTAssertEqual(snapshot.totalLivingExpenses, Decimal("2000.00"))
        XCTAssertEqual(snapshot.totalSavings, Decimal("500.00"))
        XCTAssertEqual(snapshot.totalInvestments, Decimal("300.00"))
        XCTAssertEqual(snapshot.totalTaxPayments, Decimal("1000.00"))
        // Savings, investments and taxes are NOT living expenses.
        XCTAssertEqual(snapshot.savingsRate, Decimal("0.10"))
        XCTAssertEqual(snapshot.cashFlow, Decimal("4200.00"))
    }

    func testRefundsReduceLivingExpenses() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 2), amount: Decimal("500.00"), type: .expense, title: "Médecin", account: current)),
            insert(BudgetTransaction(date: date(day: 10), amount: Decimal("350.00"), type: .refund, title: "Remboursement caisse maladie", account: current)),
        ]
        let snapshot = makeSnapshot(transactions)
        XCTAssertEqual(snapshot.totalLivingExpenses, Decimal("150.00"))
    }

    func testZeroIncomeGivesZeroSavingsRateWithoutCrash() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 3), amount: Decimal("500.00"), type: .saving, title: "Épargne", account: current, destinationAccount: savings)),
        ]
        let snapshot = makeSnapshot(transactions)
        XCTAssertEqual(snapshot.savingsRate, .zero)
    }

    // MARK: - Transfer neutrality

    func testInternalTransferIsNeutralForAllHouseholdMetrics() {
        let base = [
            insert(BudgetTransaction(date: date(day: 1), amount: Decimal("8000.00"), type: .income, title: "Salaire", account: current)),
            insert(BudgetTransaction(date: date(day: 2), amount: Decimal("2000.00"), type: .expense, title: "Loyer", account: current)),
            insert(BudgetTransaction(date: date(day: 3), amount: Decimal("500.00"), type: .saving, title: "Épargne", account: current, destinationAccount: savings)),
        ]
        let without = makeSnapshot(base)

        let transfer = insert(BudgetTransaction(
            date: date(day: 10), amount: Decimal("1500.00"), type: .transfer,
            title: "Virement interne", account: current, destinationAccount: savings
        ))
        let with = makeSnapshot(base + [transfer])

        XCTAssertEqual(with.totalIncome, without.totalIncome)
        XCTAssertEqual(with.totalLivingExpenses, without.totalLivingExpenses)
        XCTAssertEqual(with.totalSavings, without.totalSavings)
        XCTAssertEqual(with.savingsRate, without.savingsRate)
        XCTAssertEqual(with.cashFlow, without.cashFlow)
        XCTAssertEqual(with.netWorth, without.netWorth, "Un virement interne ne change pas le patrimoine")
    }

    func testTransferStillMovesAccountBalances() {
        let balanceService = AccountBalanceService()
        let transfer = insert(BudgetTransaction(
            date: date(day: 10), amount: Decimal("1500.00"), type: .transfer,
            title: "Virement interne", account: current, destinationAccount: savings
        ))
        XCTAssertEqual(balanceService.balance(of: current, movements: [transfer]), Decimal("3500.00"))
        XCTAssertEqual(balanceService.balance(of: savings, movements: [transfer]), Decimal("2500.00"))
    }

    // MARK: - Impôts manuels (ADR-035)

    func testStoredRateNeverCreatesATaxFigure() {
        // 10'000 de revenus et un taux hérité de 30 % : AUCUN chiffre
        // fiscal n'apparaît nulle part dans le snapshot.
        let income = [
            insert(BudgetTransaction(date: date(day: 1), amount: Decimal("10000.00"), type: .income, title: "Salaire", account: current)),
        ]
        let snapshot = makeSnapshot(income)
        XCTAssertEqual(snapshot.totalTaxPayments, .zero)
        XCTAssertEqual(
            snapshot.available.total,
            snapshot.available.liquidBalance,
            "sans mouvement prévu ni charge engagée, la projection = l'argent présent"
        )
    }

    func testTaxPaymentsAreOnlyWhatWasEntered() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 1), amount: Decimal("1000.00"), type: .income, title: "Salaire", account: current)),
            insert(BudgetTransaction(date: date(day: 5), amount: Decimal("900.00"), type: .taxPayment, title: "Acompte saisi", account: current)),
        ]
        let snapshot = makeSnapshot(transactions)
        XCTAssertEqual(snapshot.totalTaxPayments, Decimal("900.00"),
                       "les impôts du mois = les paiements notés, rien d'autre")
        XCTAssertEqual(snapshot.cashFlow, Decimal("100.00"))
    }

    // MARK: - Available to spend

    func testAvailableBreakdownReconciles() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 1), amount: Decimal("8000.00"), type: .income, title: "Salaire", account: current)),
            insert(BudgetTransaction(date: date(day: 25), amount: Decimal("2000.00"), type: .expense, status: .planned, title: "Loyer à venir", account: current)),
            insert(BudgetTransaction(date: date(day: 28), amount: Decimal("1000.00"), type: .income, status: .planned, title: "Bonus attendu", account: current)),
        ]
        let snapshot = makeSnapshot(transactions)
        let available = snapshot.available

        // Liquid: only the current account counts as available cash.
        XCTAssertEqual(available.liquidBalance, Decimal("13000.00"))
        XCTAssertEqual(available.expectedIncome, Decimal("1000.00"))
        XCTAssertEqual(available.committedCharges, Decimal("2000.00"))
        // ADR-035 : plus aucun terme fiscal — la projection additionne
        // exactement ce qui est saisi, malgré le taux hérité de 30 %.
        XCTAssertEqual(
            available.total,
            available.liquidBalance + available.expectedIncome - available.committedCharges
        )
        XCTAssertEqual(available.total, Decimal("12000.00"))
    }

    /// A20 : confirmer un revenu attendu ne change pas la projection —
    /// et depuis ADR-035, plus aucun terme fiscal ne s'en mêle.
    func testConfirmingAnExpectedIncomeDoesNotChangeTheForecast() {
        let salary = BudgetTransaction(
            date: date(day: 25), amount: Decimal("4800.00"), type: .income,
            status: .planned, title: "Salaire attendu", account: current
        )
        let before = makeSnapshot([insert(salary)])
        salary.status = .posted
        let after = makeSnapshot([salary])

        XCTAssertEqual(before.available.total, after.available.total,
                       "confirmer un salaire attendu ne doit pas faire bouger la projection")
    }

    /// ADR-035 : même un gros revenu de l'année et un taux hérité de 30 %
    /// ne fabriquent AUCUNE déduction — le scénario exact de la capture du
    /// propriétaire (20.08.2026).
    func testStoredRateStaysInertEvenWithBigYearIncome() {
        let past = BudgetTransaction(
            date: date(day: 10, month: 1), amount: Decimal("100000.00"),
            type: .income, title: "Gros revenu passé", account: current
        )
        let salary = BudgetTransaction(
            date: date(day: 1), amount: Decimal("4000.00"), type: .income,
            title: "Salaire du mois", account: current
        )
        let snapshot = makeSnapshot([insert(past), insert(salary)])

        XCTAssertEqual(
            snapshot.available.total,
            snapshot.available.liquidBalance,
            "rien de prévu, rien d'engagé : la projection = l'argent présent, sans AUCUN impôt inventé"
        )
    }

    func testPlannedMovementsStaySeparateFromActuals() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 25), amount: Decimal("2000.00"), type: .expense, status: .planned, title: "Prévu", account: current)),
        ]
        let snapshot = makeSnapshot(transactions)
        XCTAssertEqual(snapshot.totalLivingExpenses, .zero, "Un mouvement prévu n'est pas une dépense réelle")
        XCTAssertEqual(snapshot.plannedOutflows, Decimal("2000.00"))
    }

    func testDailyBudgetIsZeroWhenNothingAvailable() {
        current.openingBalance = Decimal("-9000.00")
        let snapshot = makeSnapshot([])
        XCTAssertLessThan(snapshot.available.total, .zero)
        XCTAssertEqual(snapshot.dailyAvailableBudget, .zero)
    }

    // MARK: - Date boundaries

    func testMonthBoundariesAreHalfOpen() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 1), amount: Decimal("100.00"), type: .expense, title: "Début juin", account: current)),
            insert(BudgetTransaction(date: date(day: 30), amount: Decimal("50.00"), type: .expense, title: "Fin juin", account: current)),
            insert(BudgetTransaction(date: date(day: 1, month: 7), amount: Decimal("999.00"), type: .expense, title: "Juillet", account: current)),
            insert(BudgetTransaction(date: date(day: 31, month: 5), amount: Decimal("999.00"), type: .expense, title: "Mai", account: current)),
        ]
        let snapshot = makeSnapshot(transactions)
        XCTAssertEqual(snapshot.totalLivingExpenses, Decimal("150.00"))
    }

    func testDaysRemaining() {
        let interval = MonthInterval(containing: now, calendar: calendar)
        // 15 June, days 15..30 remain → 16 days.
        XCTAssertEqual(service.daysRemaining(in: interval, now: now), 16)

        let pastInterval = MonthInterval(containing: date(day: 10, month: 4), calendar: calendar)
        XCTAssertEqual(service.daysRemaining(in: pastInterval, now: now), 0)

        let futureInterval = MonthInterval(containing: date(day: 10, month: 9), calendar: calendar)
        XCTAssertEqual(service.daysRemaining(in: futureInterval, now: now), 30)
    }

    // MARK: - Previous month comparison

    func testPreviousMonthComparisonDeltas() throws {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 5, month: 5), amount: Decimal("7000.00"), type: .income, title: "Salaire mai", account: current)),
            insert(BudgetTransaction(date: date(day: 6, month: 5), amount: Decimal("3000.00"), type: .expense, title: "Dépenses mai", account: current)),
            insert(BudgetTransaction(date: date(day: 5), amount: Decimal("8000.00"), type: .income, title: "Salaire juin", account: current)),
            insert(BudgetTransaction(date: date(day: 6), amount: Decimal("2500.00"), type: .expense, title: "Dépenses juin", account: current)),
        ]
        let snapshot = makeSnapshot(transactions)
        let comparison = try XCTUnwrap(snapshot.previousMonth)
        XCTAssertEqual(comparison.incomeDelta, Decimal("1000.00"))
        XCTAssertEqual(comparison.livingExpensesDelta, Decimal("-500.00"))
        XCTAssertEqual(comparison.cashFlowDelta, Decimal("1500.00"))
    }

    func testNoComparisonWhenPreviousMonthIsEmpty() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 5), amount: Decimal("8000.00"), type: .income, title: "Salaire", account: current)),
        ]
        XCTAssertNil(makeSnapshot(transactions).previousMonth)
    }

    // MARK: - Chart series

    func testMonthlyFlowsProducesOrderedSeries() {
        let transactions = [
            insert(BudgetTransaction(date: date(day: 5, month: 5), amount: Decimal("7000.00"), type: .income, title: "Mai", account: current)),
            insert(BudgetTransaction(date: date(day: 5), amount: Decimal("8000.00"), type: .income, title: "Juin", account: current)),
        ]
        let flows = service.monthlyFlows(endingAt: now, count: 3, transactions: transactions)
        XCTAssertEqual(flows.count, 3)
        XCTAssertEqual(flows[0].income, .zero) // avril
        XCTAssertEqual(flows[1].income, Decimal("7000.00"))
        XCTAssertEqual(flows[2].income, Decimal("8000.00"))
        XCTAssertTrue(flows[0].monthStart < flows[1].monthStart)
    }
}
