import XCTest
import SwiftData
@testable import Budget

/// W6.1 (ADR-067, décision propriétaire du 26.08.2026) — miroir natif
/// du report budgétaire : OPT-IN par ligne (`rollover`), le reste non
/// dépensé se calcule en CHAÎNE depuis les mois précédents, jamais
/// stocké ; un dépassement ne se reporte jamais ; sans rollover, rien
/// ne change (FI-20 : le budget ne touche aucun solde).
final class BudgetRolloverTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: BudgetVarianceService!

    // 15.06.2026 12:00 UTC — le mois consulté est juin.
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var account: Account!
    private var food: BudgetCategory!
    private var sport: BudgetCategory!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        service = BudgetVarianceService(calendar: calendar)
        account = Account(name: "Courant", type: .current, openingBalance: Decimal("9000.00"))
        food = BudgetCategory(name: "Alimentation", kind: .expense, isEssential: true)
        sport = BudgetCategory(name: "Sport", kind: .expense)
        context.insert(account)
        context.insert(food)
        context.insert(sport)
    }

    override func tearDown() {
        account = nil; food = nil; sport = nil
        service = nil; calendar = nil; context = nil; container = nil
    }

    private func month(_ m: Int, _ y: Int = 2026) -> MonthlyBudget {
        let budget = MonthlyBudget(year: y, month: m)
        context.insert(budget)
        return budget
    }

    private func line(_ amount: Decimal, category: BudgetCategory,
                      budget: MonthlyBudget, rollover: Bool) {
        let line = BudgetLine(plannedAmount: amount, rollover: rollover, category: category)
        line.budget = budget
        context.insert(line)
    }

    private func spend(_ amount: Decimal, category: BudgetCategory, month: Int) {
        let transaction = BudgetTransaction(
            date: calendar.date(from: DateComponents(year: 2026, month: month, day: 5, hour: 10))!,
            amount: amount, type: .expense, status: .posted,
            title: "Test", account: account, category: category
        )
        context.insert(transaction)
    }

    private func allTransactions() throws -> [BudgetTransaction] {
        try context.fetch(FetchDescriptor<BudgetTransaction>())
    }

    // La chaîne : avril reste 100, mai reste 600+100−400 = 300 → juin
    // reçoit 300 (enveloppe effective 900). Calculé, jamais stocké.
    func testCarryChainsAcrossMonths() throws {
        let april = month(4), may = month(5), june = month(6)
        line(600, category: food, budget: april, rollover: true)
        line(600, category: food, budget: may, rollover: true)
        line(600, category: food, budget: june, rollover: true)
        spend(500, category: food, month: 4)
        spend(400, category: food, month: 5)
        spend(100, category: food, month: 6)
        let report = service.report(
            budget: june, monthOf: now,
            transactions: try allTransactions(),
            previousBudgets: [april, may]
        )
        let ligne = try XCTUnwrap(report.lineReports.first { $0.categoryID == food.id })
        XCTAssertEqual(ligne.carry, 300, "la chaîne apporte 100 + 200")
        XCTAssertEqual(ligne.effective, 900)
        XCTAssertEqual(ligne.variance, 800, "il reste 900 − 100")
    }

    // Sans rollover : carry zéro, l'ancien comportement au centime près.
    func testWithoutRolloverNothingChanges() throws {
        let may = month(5), june = month(6)
        line(600, category: food, budget: may, rollover: false)
        line(600, category: food, budget: june, rollover: false)
        spend(400, category: food, month: 5)
        let report = service.report(
            budget: june, monthOf: now,
            transactions: try allTransactions(),
            previousBudgets: [may]
        )
        let ligne = try XCTUnwrap(report.lineReports.first { $0.categoryID == food.id })
        XCTAssertEqual(ligne.carry, .zero, "sans opt-in, rien ne se reporte")
        XCTAssertEqual(ligne.effective, ligne.planned)
    }

    // Un dépassement ne se reporte JAMAIS — pas de dette de budget cachée.
    func testOverrunNeverCarriesNegative() throws {
        let may = month(5), june = month(6)
        line(100, category: sport, budget: may, rollover: true)
        line(100, category: sport, budget: june, rollover: true)
        spend(150, category: sport, month: 5)
        let report = service.report(
            budget: june, monthOf: now,
            transactions: try allTransactions(),
            previousBudgets: [may]
        )
        let ligne = try XCTUnwrap(report.lineReports.first { $0.categoryID == sport.id })
        XCTAssertEqual(ligne.carry, .zero, "150 sur 100 : rien n'arrive en juin")
        XCTAssertEqual(ligne.effective, 100)
    }

    // Sans previousBudgets (appels existants) : carry = 0, API intacte.
    func testDefaultCallKeepsLegacyBehaviour() throws {
        let june = month(6)
        line(600, category: food, budget: june, rollover: true)
        spend(100, category: food, month: 6)
        let report = service.report(budget: june, monthOf: now, transactions: try allTransactions())
        let ligne = try XCTUnwrap(report.lineReports.first { $0.categoryID == food.id })
        XCTAssertEqual(ligne.carry, .zero, "sans historique fourni, rien n'est inventé")
        XCTAssertEqual(ligne.variance, 500)
    }

    // FI-20 : construire le rapport ne touche AUCUN solde de compte.
    func testReportNeverTouchesAccountBalances() throws {
        let may = month(5), june = month(6)
        line(600, category: food, budget: may, rollover: true)
        line(600, category: food, budget: june, rollover: true)
        spend(400, category: food, month: 5)
        let balanceService = AccountBalanceService()
        let before = balanceService.balance(of: account, movements: try allTransactions())
        _ = service.report(
            budget: june, monthOf: now,
            transactions: try allTransactions(),
            previousBudgets: [may]
        )
        let after = balanceService.balance(of: account, movements: try allTransactions())
        XCTAssertEqual(before, after, "un budget ne touche jamais un solde bancaire")
    }
}
