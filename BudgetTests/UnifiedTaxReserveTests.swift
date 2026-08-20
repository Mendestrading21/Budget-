import XCTest
import SwiftData
@testable import Budget

/// ADR-035 : UNE seule vérité fiscale, 100 % saisie — TaxService.report
/// additionne le montant annuel saisi, la réserve, les arriérés et les
/// paiements notés ; le snapshot mensuel n'a plus AUCUN terme fiscal.
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

    // MARK: - La vérité fiscale est SAISIE — le rapport additionne

    func testReportAddsUpUserEnteredAmounts() {
        let provision = makeProvision(reserved: Decimal("2500.00"), arrears: Decimal("400.00"))
        provision.estimatedAnnualTaxOverride = Decimal("3000.00")

        let report = taxService.report(year: 2026, provision: provision, transactions: [])
        // 3000 saisis encore dus + 400 d'arriérés − 2500 réservés = 900.
        XCTAssertEqual(report.outstanding, Decimal("3000.00"))
        XCTAssertEqual(report.totalDue, Decimal("3400.00"))
        XCTAssertEqual(report.reserveGap, Decimal("900.00"))
        XCTAssertEqual(report.reserved, Decimal("2500.00"))
        XCTAssertEqual(report.arrears, Decimal("400.00"))
    }

    func testReportOfAnotherYearProvisionStaysEmpty() {
        // La sélection par année vit dans l'écran : une provision 2025 ne
        // sert jamais un rapport 2026 — et sans saisie, rien n'est inventé.
        let provisions = [TaxProvision(
            year: 2025, reservedAmount: Decimal("99999.00"),
            createdAt: now, updatedAt: now
        )]
        let match = provisions.first { $0.year == 2026 }
        let report = taxService.report(year: 2026, provision: match, transactions: [])
        XCTAssertNil(report.annualTax)
        XCTAssertEqual(report.reserved, .zero)
        XCTAssertEqual(report.reserveGap, .zero)
    }

    func testSnapshotCarriesNoTaxTermAnymore() {
        // ADR-035 : six salaires et un taux hérité de 30 % ne pèsent RIEN
        // sur la projection — l'identité du disponible n'a plus de terme
        // fiscal, et le type n'a même plus de champ pour ça.
        let account = Account(name: "Courant", type: .current)
        let incomes = (1...6).map { month in
            BudgetTransaction(
                date: calendar.date(from: DateComponents(year: 2026, month: month, day: 15, hour: 9))!,
                amount: Decimal("10000.00"), type: .income, status: .posted,
                title: "Salaire", account: account
            )
        }
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now,
            household: Household(name: "Test", taxProvisionRate: Decimal("0.30")),
            accounts: [account], transactions: incomes
        )
        XCTAssertEqual(
            snapshot.available.total,
            snapshot.available.liquidBalance + snapshot.available.expectedIncome
                + snapshot.available.recurringIncome
                - snapshot.available.committedCharges - snapshot.available.recurringCharges
        )
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
