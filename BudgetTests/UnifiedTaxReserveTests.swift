import XCTest
import SwiftData
@testable import Budget

/// Production-completion P1 : une SEULE vérité fiscale. Le tableau de
/// bord (snapshot mensuel) et le module Impôts lisent la même réserve
/// annuelle et les mêmes arriérés via TaxService.monthReserveGap.
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

    // MARK: - monthReserveGap (formule unique)

    func testGapWithoutProvisionIsShortfall() {
        XCTAssertEqual(
            taxService.monthReserveGap(
                monthIncome: Decimal("10000.00"), monthPaid: Decimal("1000.00"),
                rate: Decimal("0.30"), provision: nil
            ),
            Decimal("2000.00")
        )
    }

    func testAnnualReserveCoversTheMonthGap() {
        XCTAssertEqual(
            taxService.monthReserveGap(
                monthIncome: Decimal("10000.00"), monthPaid: .zero,
                rate: Decimal("0.30"), provision: makeProvision(reserved: Decimal("5000.00"))
            ),
            .zero,
            "Une réserve annuelle suffisante annule le manque du mois"
        )
    }

    func testArrearsIncreaseTheGap() {
        XCTAssertEqual(
            taxService.monthReserveGap(
                monthIncome: Decimal("10000.00"), monthPaid: .zero,
                rate: Decimal("0.30"),
                provision: makeProvision(reserved: Decimal("1000.00"), arrears: Decimal("800.00"))
            ),
            Decimal("2800.00"),
            "3000 − 1000 de réserve + 800 d'arriérés"
        )
    }

    func testOverpaidMonthNeverProducesNegativeGap() {
        XCTAssertEqual(
            taxService.monthReserveGap(
                monthIncome: Decimal("1000.00"), monthPaid: Decimal("900.00"),
                rate: Decimal("0.30"), provision: makeProvision(reserved: Decimal("100.00"))
            ),
            .zero
        )
    }

    // MARK: - Le snapshot mensuel lit la même vérité

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

    func testDashboardAndTaxesModuleAgree() {
        // Un seul mois de données : le rapport annuel et le snapshot
        // mensuel doivent produire le MÊME manque de réserve.
        let account = Account(name: "Courant", type: .current)
        let income = BudgetTransaction(
            date: now, amount: Decimal("9000.00"), type: .income,
            title: "Salaire", account: account
        )
        income.status = .posted
        let paid = BudgetTransaction(
            date: now, amount: Decimal("700.00"), type: .taxPayment,
            title: "Acompte", account: account
        )
        paid.status = .posted
        let provision = makeProvision(reserved: Decimal("1200.00"), arrears: Decimal("300.00"))

        let report = taxService.report(
            year: 2026, profile: nil, provision: provision,
            transactions: [income, paid]
        )
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: nil,
            accounts: [account], transactions: [income, paid],
            taxProvisions: [provision]
        )
        XCTAssertEqual(snapshot.taxProvision.gap, report.reserveGap,
                       "Accueil et module Impôts doivent afficher le même manque")
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
