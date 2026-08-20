import XCTest
import SwiftData
@testable import Budget

final class TaxServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: TaxService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var account: Account!
    private var profile: TaxProfile!
    private var provision: TaxProvision!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = TaxService(calendar: calendar)

        account = Account(name: "Courant", type: .current)
        profile = TaxProfile(provisionRate: Decimal("0.30"))
        provision = TaxProvision(year: 2026)
        provision.profile = profile
        context.insert(account)
        context.insert(profile)
        context.insert(provision)
    }

    override func tearDown() {
        account = nil
        profile = nil
        provision = nil
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    private func date(_ day: Int, _ month: Int, _ year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9))!
    }

    @discardableResult
    private func addTransaction(
        _ amount: Decimal,
        type: TransactionType,
        day: Int = 5,
        month: Int = 3,
        year: Int = 2026,
        status: TransactionStatus = .posted
    ) -> BudgetTransaction {
        let transaction = BudgetTransaction(
            date: date(day, month, year), amount: amount, type: type,
            status: status, title: "Test", account: account
        )
        context.insert(transaction)
        return transaction
    }

    private func makeReport(_ transactions: [BudgetTransaction]) -> TaxYearReport {
        service.report(year: 2026, provision: provision, transactions: transactions)
    }

    // MARK: - ADR-035 : rien n'est estimé, tout est saisi

    func testNothingIsEstimatedWithoutAUserAmount() {
        // Le profil du setUp porte encore un taux hérité de 30 % : il doit
        // rester lettre morte — aucun revenu ne fabrique un chiffre.
        let income = addTransaction(Decimal("50000.00"), type: .income)
        let report = makeReport([income])
        XCTAssertNil(report.annualTax, "l'app n'invente jamais le montant de l'année")
        XCTAssertEqual(report.outstanding, .zero)
        XCTAssertEqual(report.reserveGap, .zero)
    }

    func testUserAnnualAmountDrivesOutstanding() {
        let income = addTransaction(Decimal("50000.00"), type: .income)
        provision.estimatedAnnualTaxOverride = Decimal("12500.00")
        let report = makeReport([income])
        XCTAssertEqual(report.annualTax, Decimal("12500.00"))
        XCTAssertEqual(report.outstanding, Decimal("12500.00"),
                       "encore dû = le montant saisi − les paiements notés")
    }

    // MARK: - Paid / outstanding reconciliation

    func testPaidSumsOnlyPostedTaxPaymentsOfTheYear() {
        provision.estimatedAnnualTaxOverride = Decimal("15000.00")
        let income = addTransaction(Decimal("50000.00"), type: .income)
        let paid1 = addTransaction(Decimal("4000.00"), type: .taxPayment, month: 4)
        let paid2 = addTransaction(Decimal("2500.00"), type: .taxPayment, month: 5)
        let otherYear = addTransaction(Decimal("999.00"), type: .taxPayment, year: 2025)
        let plannedPayment = addTransaction(Decimal("777.00"), type: .taxPayment, month: 9, status: .planned)
        let expense = addTransaction(Decimal("100.00"), type: .expense)

        let report = makeReport([income, paid1, paid2, otherYear, plannedPayment, expense])
        XCTAssertEqual(report.paid, Decimal("6500.00"))
        XCTAssertEqual(report.outstanding, Decimal("8500.00"))
        // Réconciliation totale : montant saisi = payé + encore dû.
        XCTAssertEqual(report.annualTax, report.paid + report.outstanding)
    }

    func testOutstandingNeverGoesNegative() {
        provision.estimatedAnnualTaxOverride = Decimal("300.00")
        let overpaid = addTransaction(Decimal("900.00"), type: .taxPayment)
        let report = makeReport([overpaid])
        XCTAssertEqual(report.outstanding, .zero, "un trop-payé ne devient jamais un dû négatif")
    }

    // MARK: - Reserve and arrears

    func testReserveGapCoversOutstandingPlusArrears() {
        provision.estimatedAnnualTaxOverride = Decimal("15000.00")
        provision.reservedAmount = Decimal("10000.00")
        provision.arrearsAmount = Decimal("2000.00")

        let report = makeReport([])
        XCTAssertEqual(report.outstanding, Decimal("15000.00"))
        XCTAssertEqual(report.totalDue, Decimal("17000.00"))
        XCTAssertEqual(report.reserveGap, Decimal("7000.00"))
    }

    func testSufficientReserveMeansNoGap() {
        provision.estimatedAnnualTaxOverride = Decimal("3000.00")
        provision.reservedAmount = Decimal("5000.00")
        let report = makeReport([])
        XCTAssertEqual(report.outstanding, Decimal("3000.00"))
        XCTAssertEqual(report.reserveGap, .zero)
    }

    func testEmptyYearYieldsSafeZeroes() {
        let report = makeReport([])
        XCTAssertNil(report.annualTax)
        XCTAssertEqual(report.outstanding, .zero)
        XCTAssertEqual(report.reserveGap, .zero)
    }

    // MARK: - Due dates

    func testDueDatesSplitAroundNow() {
        provision.dueDates = [
            TaxDueDate(date: date(30, 9), label: "Acompte 3"),
            TaxDueDate(date: date(31, 3), label: "Acompte 1"),
            TaxDueDate(date: date(30, 6), label: "Acompte 2"),
        ]
        let upcoming = service.upcomingDueDates(provision: provision, now: now)
        let overdue = service.overdueDueDates(provision: provision, now: now)
        XCTAssertEqual(upcoming.map(\.label), ["Acompte 2", "Acompte 3"])
        XCTAssertEqual(overdue.map(\.label), ["Acompte 1"])
    }

    // MARK: - Lazy creation

    func testEnsureProfileSeedsFromHouseholdRate() throws {
        // Store vierge : on repart d'un container dédié.
        let freshContainer = try PersistenceFactory.makeInMemoryContainer()
        let freshContext = ModelContext(freshContainer)
        let household = Household(name: "Test", taxProvisionRate: Decimal("0.25"))
        freshContext.insert(household)

        let created = try service.ensureProfile(context: freshContext, household: household, now: now)
        XCTAssertEqual(created.provisionRate, Decimal("0.25"))

        let again = try service.ensureProfile(context: freshContext, household: household, now: now)
        XCTAssertEqual(created.id, again.id, "Un seul profil, jamais dupliqué")
    }

    func testEnsureProvisionIsUniquePerYear() throws {
        let first = try service.ensureProvision(year: 2026, profile: profile, context: context, now: now)
        let second = try service.ensureProvision(year: 2026, profile: profile, context: context, now: now)
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(profile.provisions.filter { $0.year == 2026 }.count, 1)
    }

    // MARK: - Snapshot integration

    func testSnapshotIgnoresEveryStoredRate() {
        // ADR-035 : un taux hérité (ménage OU profil) ne pèse plus RIEN sur
        // la projection — le moteur n'a même plus de champ pour ça.
        let household = Household(name: "Test", taxProvisionRate: Decimal("0.30"))
        context.insert(household)
        profile.provisionRate = Decimal("0.20")
        let income = addTransaction(Decimal("10000.00"), type: .income, month: 6, status: .posted)

        let snapshotService = MonthlySnapshotService(calendar: calendar)
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: household,
            accounts: [account], transactions: [income]
        )
        XCTAssertEqual(
            snapshot.available.total,
            snapshot.available.liquidBalance + snapshot.available.expectedIncome
                + snapshot.available.recurringIncome
                - snapshot.available.committedCharges - snapshot.available.recurringCharges,
            "la projection additionne seulement ce qui est saisi"
        )
    }

    // MARK: - Persistence

    func testProvisionRoundTripsWithDueDates() throws {
        provision.reservedAmount = Decimal("5200.00")
        provision.dueDates = [TaxDueDate(date: date(30, 9), label: "Acompte cantonal")]
        try context.save()

        let secondContext = ModelContext(container)
        let fetched = try secondContext.fetch(FetchDescriptor<TaxProvision>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.reservedAmount, Decimal("5200.00"))
        XCTAssertEqual(fetched.first?.dueDates.count, 1)
        XCTAssertEqual(fetched.first?.dueDates.first?.label, "Acompte cantonal")
        XCTAssertEqual(fetched.first?.profile?.id, profile.id)
    }
}
