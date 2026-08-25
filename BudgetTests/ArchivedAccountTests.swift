import XCTest
import SwiftData
@testable import Budget

/// W4.7 (FI-13 → TENU natif) — archiver un compte (`isActive = false`)
/// sort son solde des agrégats du PRÉSENT, mais les FLUX d'un mois
/// PASSÉ ne bougent pas d'un centime : l'histoire est l'histoire.
final class ArchivedAccountTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    func testPastMonthReportsAreIdenticalAfterArchiving() throws {
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let household = Household(name: "Test", taxProvisionRate: Decimal("0.30"))
        context.insert(household)
        let courant = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        let ancien = Account(name: "Ancien", type: .current, openingBalance: Decimal("1000.00"))
        context.insert(courant); context.insert(ancien)
        // Un mois PASSÉ (juin 2026) avec un flux sur le compte à archiver.
        let juin = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12))!
        let mouvement = BudgetTransaction(
            date: juin, amount: Decimal("100.00"), type: .expense,
            title: "Dépense ancienne", account: ancien)
        context.insert(mouvement)
        try context.save()

        let snapshots = MonthlySnapshotService(calendar: calendar)
        let netWorth = NetWorthService(calendar: calendar)
        let avant = snapshots.snapshot(
            monthOf: juin, now: now, household: household,
            accounts: [courant, ancien], transactions: [mouvement])
        let fortuneAvant = netWorth.breakdown(
            accounts: [courant, ancien], assets: [], pensions: [], liabilities: []).netWorth

        ancien.isActive = false
        try context.save()

        let apres = snapshots.snapshot(
            monthOf: juin, now: now, household: household,
            accounts: [courant, ancien], transactions: [mouvement])
        // FI-13 : les FLUX du mois passé sont IDENTIQUES.
        XCTAssertEqual(apres.totalIncome, avant.totalIncome)
        XCTAssertEqual(apres.totalLivingExpenses, avant.totalLivingExpenses)
        XCTAssertEqual(apres.cashFlow, avant.cashFlow)
        XCTAssertEqual(mouvement.amount, Decimal("100.00"), "le mouvement n'a pas bougé")
        // Le PRÉSENT, lui, exclut le compte archivé : le stock liquide
        // baisse d'exactement son solde (1000 − 100 = 900).
        XCTAssertEqual(avant.available.liquidBalance - apres.available.liquidBalance,
                       Decimal("900.00"))
        let fortuneApres = netWorth.breakdown(
            accounts: [courant, ancien], assets: [], pensions: [], liabilities: []).netWorth
        XCTAssertEqual(fortuneAvant - fortuneApres, Decimal("900.00"),
                       "le patrimoine du présent exclut l'archivé — l'histoire, jamais")
    }
}
