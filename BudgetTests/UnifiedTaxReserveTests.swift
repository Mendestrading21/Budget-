import XCTest
import SwiftData
@testable import Budget

/// Production-completion P1 : une SEULE vérité fiscale annuelle. Le tableau
/// de bord (snapshot mensuel) et le module Impôts lisent TaxService.report.
/// Couvre aussi ADR-017 : V1 mono-devise, restauration non-CHF refusée.
final class UnifiedTaxReserveTests: XCTestCase {
    private var calendar: Calendar!
    private var taxService: TaxService!
    private var snapshotService: MonthlySnapshotService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        taxService = TaxService(calendar: calendar)
        snapshotService = MonthlySnapshotService(calendar: calendar)
    }

    override func tearDown() {
        snapshotService = nil
        taxService = nil
        calendar = nil
    }

    private func makeProvision(reserved: Decimal, arrears: Decimal = .zero) -> TaxProvision {
        TaxProvision(
            year: 2026, reservedAmount: reserved, arrearsAmount: arrears,
            createdAt: now, updatedAt: now
        )
    }

    // MARK: - Le snapshot mensuel lit la même vérité annuelle

    func testSnapshotUsesAnnualReserveAndArrears() {
        let account = Account(name: "Courant", type: .current, openingBalance: Decimal("8000.00"))
        let income = BudgetTransaction(
            date: now, amount: Decimal("10000.00"), type: .income,
            title: "Salaire", account: account
        )
        income.status = .posted
        let provision = makeProvision(reserved: Decimal("2500.00"), arrears: Decimal("400.00"))

        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: nil,
            accounts: [account], transactions: [income],
            taxProvisions: [provision]
        )
        // 10000 × 0.30 = 3000 de manque + 400 d'arriérés − 2500 réservés
        XCTAssertEqual(snapshot.taxProvision.gap, Decimal("900.00"))
        XCTAssertEqual(snapshot.taxProvision.reserved, Decimal("2500.00"))
        XCTAssertEqual(snapshot.taxProvision.arrears, Decimal("400.00"))
        XCTAssertEqual(snapshot.available.taxReserveGap, Decimal("900.00"))
    }

    func testSnapshotIgnoresProvisionOfAnotherYear() {
        let account = Account(name: "Courant", type: .current)
        let income = BudgetTransaction(
            date: now, amount: Decimal("10000.00"), type: .income,
            title: "Salaire", account: account
        )
        income.status = .posted
        let otherYear = TaxProvision(
            year: 2025, reservedAmount: Decimal("99999.00"),
            createdAt: now, updatedAt: now
        )
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: nil,
            accounts: [account], transactions: [income],
            taxProvisions: [otherYear]
        )
        XCTAssertEqual(snapshot.taxProvision.gap, Decimal("3000.00"),
                       "La réserve 2025 ne couvre pas juin 2026")
    }

    func testDashboardAndTaxesModuleAgreeAcrossSeveralMonths() {
        let account = Account(name: "Courant", type: .current)
        let incomes = (1...6).map { month in
            BudgetTransaction(
                date: calendar.date(from: DateComponents(year: 2026, month: month, day: 15, hour: 9))!,
                amount: Decimal("10000.00"), type: .income, status: .posted,
                title: "Salaire", account: account
            )
        }
        let provision = makeProvision(reserved: Decimal("5000.00"))

        let report = taxService.report(
            year: 2026, profile: nil, provision: provision,
            transactions: incomes
        )
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: nil,
            accounts: [account], transactions: incomes,
            taxProvisions: [provision]
        )
        XCTAssertEqual(report.estimatedTax, Decimal("18000.00"))
        XCTAssertEqual(report.reserveGap, Decimal("13000.00"))
        XCTAssertEqual(snapshot.taxProvision.recommended, Decimal("18000.00"))
        XCTAssertEqual(snapshot.taxProvision.gap, report.reserveGap,
                       "La réserve annuelle ne peut pas masquer cinq mois de manque sur l'Accueil")
        XCTAssertEqual(snapshot.available.taxReserveGap, Decimal("13000.00"))
    }

    // MARK: - ADR-017 : restauration mono-devise

    func testRestoreRefusesNonCHFAccounts() throws {
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        let backupService = BackupService()

        let chf = Account(name: "Courant", type: .current)
        let eur = Account(name: "Compte France", type: .current, currencyCode: "EUR")
        context.insert(chf)
        context.insert(eur)
        try context.save()
        let data = try backupService.makeBackup(context: context, now: now)

        let freshContainer = try PersistenceFactory.makeInMemoryContainer()
        let freshContext = ModelContext(freshContainer)
        let marker = Account(name: "Existant", type: .current)
        freshContext.insert(marker)
        try freshContext.save()

        XCTAssertThrowsError(
            try backupService.restore(data: data, context: freshContext, documentFileStore: nil)
        ) { error in
            XCTAssertEqual(error as? BackupError, .unsupportedCurrency(codes: ["EUR"]))
        }
        // Refus AVANT toute mutation : le store existant est intact.
        let survivors = try freshContext.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(survivors.map(\.name), ["Existant"])
    }
}
