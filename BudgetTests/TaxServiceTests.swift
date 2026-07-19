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
        service.report(year: 2026, profile: profile, provision: provision, transactions: transactions)
    }

    // MARK: - Estimation

    func testEstimateIsIncomeTimesRate() {
        let income = addTransaction(Decimal("50000.00"), type: .income)
        let report = makeReport([income])
        XCTAssertEqual(report.taxableIncome, Decimal("50000.00"))
        XCTAssertEqual(report.estimatedTax, Decimal("15000.00"))
        XCTAssertFalse(report.isOverridden)
    }

    func testManualOverrideWins() {
        let income = addTransaction(Decimal("50000.00"), type: .income)
        provision.estimatedAnnualTaxOverride = Decimal("12500.00")
        let report = makeReport([income])
        XCTAssertEqual(report.estimatedTax, Decimal("12500.00"))
        XCTAssertTrue(report.isOverridden)
    }

    func testIncomeFromOtherYearsIsExcluded() {
        let thisYear = addTransaction(Decimal("50000.00"), type: .income)
        let lastYear = addTransaction(Decimal("99999.00"), type: .income, year: 2025)
        let planned = addTransaction(Decimal("8000.00"), type: .income, month: 12, status: .planned)
        let report = makeReport([thisYear, lastYear, planned])
        XCTAssertEqual(report.taxableIncome, Decimal("50000.00"), "Autres années et prévus exclus")
    }

    // MARK: - Paid / outstanding reconciliation

    func testPaidSumsOnlyPostedTaxPaymentsOfTheYear() {
        let income = addTransaction(Decimal("50000.00"), type: .income)
        let paid1 = addTransaction(Decimal("4000.00"), type: .taxPayment, month: 4)
        let paid2 = addTransaction(Decimal("2500.00"), type: .taxPayment, month: 5)
        let otherYear = addTransaction(Decimal("999.00"), type: .taxPayment, year: 2025)
        let plannedPayment = addTransaction(Decimal("777.00"), type: .taxPayment, month: 9, status: .planned)
        let expense = addTransaction(Decimal("100.00"), type: .expense)

        let report = makeReport([income, paid1, paid2, otherYear, plannedPayment, expense])
        XCTAssertEqual(report.paid, Decimal("6500.00"))
        XCTAssertEqual(report.outstanding, Decimal("8500.00"))
        // Réconciliation totale : estimé = payé + encore dû.
        XCTAssertEqual(report.estimatedTax, report.paid + report.outstanding)
    }

    func testOutstandingNeverGoesNegative() {
        let income = addTransaction(Decimal("1000.00"), type: .income)
        let overpaid = addTransaction(Decimal("900.00"), type: .taxPayment)
        let report = makeReport([income, overpaid])
        XCTAssertEqual(report.estimatedTax, Decimal("300.00"))
        XCTAssertEqual(report.outstanding, .zero)
    }

    // MARK: - Reserve and arrears

    func testReserveGapCoversOutstandingPlusArrears() {
        let income = addTransaction(Decimal("50000.00"), type: .income)
        provision.reservedAmount = Decimal("10000.00")
        provision.arrearsAmount = Decimal("2000.00")

        let report = makeReport([income])
        XCTAssertEqual(report.outstanding, Decimal("15000.00"))
        XCTAssertEqual(report.totalDue, Decimal("17000.00"))
        XCTAssertEqual(report.reserveGap, Decimal("7000.00"))
    }

    func testSufficientReserveMeansNoGap() {
        let income = addTransaction(Decimal("10000.00"), type: .income)
        provision.reservedAmount = Decimal("5000.00")
        let report = makeReport([income])
        XCTAssertEqual(report.outstanding, Decimal("3000.00"))
        XCTAssertEqual(report.reserveGap, .zero)
    }

    func testZeroIncomeYieldsSafeZeroes() {
        let report = makeReport([])
        XCTAssertEqual(report.estimatedTax, .zero)
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

    func testSnapshotPrefersProfileRateOverHousehold() {
        let household = Household(name: "Test", taxProvisionRate: Decimal("0.30"))
        context.insert(household)
        profile.provisionRate = Decimal("0.20")
        let income = addTransaction(Decimal("10000.00"), type: .income, month: 6, status: .posted)

        let snapshotService = MonthlySnapshotService(calendar: calendar)
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: household,
            accounts: [account], transactions: [income],
            taxProfile: profile
        )
        XCTAssertEqual(snapshot.taxProvision.rate, Decimal("0.20"))
        XCTAssertEqual(snapshot.taxProvision.recommended, Decimal("2000.00"))
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
