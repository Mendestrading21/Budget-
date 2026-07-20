import XCTest
import SwiftData
@testable import Budget

final class RecurringScheduleServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: RecurringScheduleService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var account: Account!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = RecurringScheduleService(calendar: calendar)
        account = Account(name: "Courant", type: .current)
        context.insert(account)
    }

    override func tearDown() {
        account = nil
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    private func date(_ day: Int, _ month: Int, _ year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9))!
    }

    private func june() -> MonthInterval {
        MonthInterval(containing: now, calendar: calendar)
    }

    private func makeRecurring(
        amount: Decimal = Decimal("100.00"),
        type: TransactionType = .expense,
        unit: RecurrenceUnit = .month,
        count: Int = 1,
        first: Date,
        end: Date? = nil,
        isActive: Bool = true
    ) -> RecurringTransaction {
        let recurring = RecurringTransaction(
            title: "Test", amount: amount, type: type,
            intervalUnit: unit, intervalCount: count,
            firstOccurrence: first, endDate: end, isActive: isActive,
            account: account
        )
        context.insert(recurring)
        return recurring
    }

    // MARK: - Occurrence generation

    func testMonthlyChargeAppearsExactlyOnceInMonth() {
        let recurring = makeRecurring(first: date(5, 1))
        let dates = service.occurrenceDates(of: recurring, in: june())
        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(calendar.component(.day, from: dates[0]), 5)
    }

    func testInactiveChargeHasNoOccurrences() {
        let recurring = makeRecurring(first: date(5, 1), isActive: false)
        XCTAssertTrue(service.occurrenceDates(of: recurring, in: june()).isEmpty)
    }

    func testEndedChargeHasNoOccurrencesAfterEndDate() {
        let recurring = makeRecurring(first: date(5, 1), end: date(31, 5))
        XCTAssertTrue(service.occurrenceDates(of: recurring, in: june()).isEmpty)
    }

    func testFutureFirstOccurrenceYieldsNothingBeforeStart() {
        let recurring = makeRecurring(first: date(5, 9))
        XCTAssertTrue(service.occurrenceDates(of: recurring, in: june()).isEmpty)
    }

    func testQuarterlyOccurrences() {
        // 15 janvier → 15 avril, 15 juillet ; rien en juin.
        let recurring = makeRecurring(unit: .month, count: 3, first: date(15, 1))
        XCTAssertTrue(service.occurrenceDates(of: recurring, in: june()).isEmpty)

        let april = MonthInterval(containing: date(1, 4), calendar: calendar)
        XCTAssertEqual(service.occurrenceDates(of: recurring, in: april).count, 1)
    }

    func testAnnualOccursOnlyOnAnniversaryMonth() {
        let recurring = makeRecurring(unit: .year, count: 1, first: date(12, 6, 2024))
        let dates = service.occurrenceDates(of: recurring, in: june())
        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(calendar.component(.day, from: dates[0]), 12)

        let may = MonthInterval(containing: date(1, 5), calendar: calendar)
        XCTAssertTrue(service.occurrenceDates(of: recurring, in: may).isEmpty)
    }

    func testMonthEndAnchorDoesNotDrift() {
        // Ancre au 31 janvier : février (28) puis retour au 31 en mars.
        let recurring = makeRecurring(first: date(31, 1))
        let february = MonthInterval(containing: date(10, 2), calendar: calendar)
        let march = MonthInterval(containing: date(10, 3), calendar: calendar)

        let febDates = service.occurrenceDates(of: recurring, in: february)
        let marDates = service.occurrenceDates(of: recurring, in: march)
        XCTAssertEqual(febDates.count, 1)
        XCTAssertEqual(calendar.component(.day, from: febDates[0]), 28)
        XCTAssertEqual(marDates.count, 1)
        XCTAssertEqual(calendar.component(.day, from: marDates[0]), 31, "L'ancre par multiples évite la dérive Feb 28 → Mar 28")
    }

    func testLeapYearAnniversary() {
        // Ancre au 29 février 2024 (bissextile) → 28 février 2026.
        let recurring = makeRecurring(unit: .year, count: 1, first: date(29, 2, 2024))
        let february2026 = MonthInterval(containing: date(10, 2, 2026), calendar: calendar)
        let dates = service.occurrenceDates(of: recurring, in: february2026)
        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(calendar.component(.day, from: dates[0]), 28)
    }

    func testCustomIntervalEveryTwoMonths() {
        let recurring = makeRecurring(unit: .month, count: 2, first: date(8, 2))
        // Février, avril, juin, août…
        XCTAssertEqual(service.occurrenceDates(of: recurring, in: june()).count, 1)
        let may = MonthInterval(containing: date(1, 5), calendar: calendar)
        XCTAssertTrue(service.occurrenceDates(of: recurring, in: may).isEmpty)
    }

    func testWeeklyOccurrencesInJune() {
        // Lundis : 1, 8, 15, 22, 29 juin 2026 → 5 occurrences.
        let recurring = makeRecurring(unit: .week, count: 1, first: date(1, 6))
        XCTAssertEqual(service.occurrenceDates(of: recurring, in: june()).count, 5)
    }

    func testNextOccurrenceLooksAcrossMonths() {
        let recurring = makeRecurring(unit: .year, count: 1, first: date(3, 11, 2025))
        let next = service.nextOccurrence(of: recurring, onOrAfter: now)
        XCTAssertNotNil(next)
        XCTAssertEqual(calendar.component(.month, from: next!), 11)
        XCTAssertEqual(calendar.component(.year, from: next!), 2026)
    }

    // MARK: - Forecast dedup

    func testForecastSkipsOccurrencesCoveredByLinkedTransactions() {
        let recurring = makeRecurring(first: date(5, 1))
        let posted = BudgetTransaction(
            date: date(4, 6), amount: Decimal("100.00"), type: .expense,
            title: "Test", recurringID: recurring.id, account: account
        )
        context.insert(posted)

        let remaining = service.remainingOccurrences(of: recurring, in: june(), transactions: [posted])
        XCTAssertTrue(remaining.isEmpty, "Un mouvement lié couvre l'occurrence même si le jour diffère")
    }

    func testForecastKeepsUncoveredOccurrences() {
        let recurring = makeRecurring(first: date(5, 1))
        let unlinked = BudgetTransaction(
            date: date(5, 6), amount: Decimal("100.00"), type: .expense,
            title: "Autre chose", account: account
        )
        context.insert(unlinked)

        let remaining = service.remainingOccurrences(of: recurring, in: june(), transactions: [unlinked])
        XCTAssertEqual(remaining.count, 1, "Sans lien recurringID, l'occurrence reste prévue")
    }

    func testForecastCoverageIsScopedToTheMonth() {
        let recurring = makeRecurring(first: date(5, 1))
        let lastMonth = BudgetTransaction(
            date: date(5, 5), amount: Decimal("100.00"), type: .expense,
            title: "Test", recurringID: recurring.id, account: account
        )
        context.insert(lastMonth)

        let remaining = service.remainingOccurrences(of: recurring, in: june(), transactions: [lastMonth])
        XCTAssertEqual(remaining.count, 1, "La couverture de mai ne couvre pas juin")
    }

    func testWeeklyPartialCoverageDropsEarliestOccurrences() {
        let recurring = makeRecurring(unit: .week, count: 1, first: date(1, 6))
        let coverTwo = (0..<2).map { index in
            let transaction = BudgetTransaction(
                date: date(1 + index * 7, 6), amount: Decimal("100.00"), type: .expense,
                title: "Test", recurringID: recurring.id, account: account
            )
            context.insert(transaction)
            return transaction
        }

        let remaining = service.remainingOccurrences(of: recurring, in: june(), transactions: coverTwo)
        XCTAssertEqual(remaining.count, 3)
        XCTAssertEqual(calendar.component(.day, from: remaining[0].date), 15)
    }

    // MARK: - Normalized costs

    func testMonthlyEquivalents() {
        XCTAssertEqual(
            service.monthlyEquivalent(of: makeRecurring(amount: Decimal("1200.00"), unit: .year, first: now)),
            Decimal("100.00")
        )
        XCTAssertEqual(
            service.monthlyEquivalent(of: makeRecurring(amount: Decimal("300.00"), unit: .month, count: 3, first: now)),
            Decimal("100.00")
        )
        XCTAssertEqual(
            service.monthlyEquivalent(of: makeRecurring(amount: Decimal("12.00"), unit: .week, first: now)),
            Decimal("52.00")
        )
    }

    func testAnnualizedCosts() {
        XCTAssertEqual(
            service.annualizedCost(of: makeRecurring(amount: Decimal("15.90"), unit: .month, first: now)),
            Decimal("190.80")
        )
        XCTAssertEqual(
            service.annualizedCost(of: makeRecurring(amount: Decimal("190.00"), unit: .year, first: now)),
            Decimal("190.00")
        )
    }

    // MARK: - Materialization

    func testMakeTransactionLinksBackToRecurring() {
        let recurring = makeRecurring(first: date(5, 6))
        let transaction = service.makeTransaction(from: recurring, on: date(5, 6), now: now)
        XCTAssertEqual(transaction.recurringID, recurring.id)
        XCTAssertEqual(transaction.amount, recurring.amount)
        XCTAssertEqual(transaction.status, .posted)
        XCTAssertEqual(transaction.account?.id, account.id)
    }

    // MARK: - Snapshot integration

    func testRecurringChargesAndIncomeEnterAvailableBreakdown() {
        let household = Household(name: "Test")
        context.insert(household)
        let salary = makeRecurring(amount: Decimal("8000.00"), type: .income, first: date(25, 1))
        let rent = makeRecurring(amount: Decimal("2000.00"), type: .expense, first: date(28, 1))
        _ = salary
        _ = rent

        let snapshotService = MonthlySnapshotService(calendar: calendar)
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: household,
            accounts: [account], transactions: [],
            recurrings: [salary, rent]
        )
        XCTAssertEqual(snapshot.available.recurringIncome, Decimal("8000.00"))
        XCTAssertEqual(snapshot.available.recurringCharges, Decimal("2000.00"))
        XCTAssertEqual(
            snapshot.available.total,
            snapshot.available.liquidBalance + Decimal("8000.00") - Decimal("2000.00") - snapshot.available.taxReserveGap
        )
    }

    func testPostedLinkedOccurrenceLeavesForecastAndEntersActuals() {
        let household = Household(name: "Test")
        context.insert(household)
        let rent = makeRecurring(amount: Decimal("2000.00"), type: .expense, first: date(1, 1))
        let posted = service.makeTransaction(from: rent, on: date(1, 6), now: now)
        context.insert(posted)

        let snapshotService = MonthlySnapshotService(calendar: calendar)
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: household,
            accounts: [account], transactions: [posted],
            recurrings: [rent]
        )
        XCTAssertEqual(snapshot.available.recurringCharges, .zero, "Occurrence comptabilisée = plus prévue")
        XCTAssertEqual(snapshot.totalLivingExpenses, Decimal("2000.00"), "…mais bien réelle — jamais les deux")
    }

    func testRecurringTransferStaysNeutralInBreakdown() {
        let household = Household(name: "Test")
        context.insert(household)
        let destination = Account(name: "Épargne", type: .savings)
        context.insert(destination)
        let transfer = RecurringTransaction(
            title: "Virement", amount: Decimal("500.00"), type: .transfer,
            firstOccurrence: date(20, 1),
            account: account, destinationAccount: destination
        )
        context.insert(transfer)

        let snapshotService = MonthlySnapshotService(calendar: calendar)
        let snapshot = snapshotService.snapshot(
            monthOf: now, now: now, household: household,
            accounts: [account, destination], transactions: [],
            recurrings: [transfer]
        )
        XCTAssertEqual(snapshot.available.recurringIncome, .zero)
        XCTAssertEqual(snapshot.available.recurringCharges, .zero)
    }

    // MARK: - Persistence

    func testRecurringPersistsAcrossContexts() throws {
        _ = makeRecurring(first: date(5, 1))
        try context.save()

        let secondContext = ModelContext(container)
        let fetched = try secondContext.fetch(FetchDescriptor<RecurringTransaction>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.intervalUnit, .month)
        XCTAssertEqual(fetched.first?.amount, Decimal("100.00"))
    }
}

// MARK: - Rituel « Check du mois » (parité web)

extension RecurringScheduleServiceTests {
    private func makeCheckFixtures() -> (salary: RecurringTransaction, rent: RecurringTransaction) {
        // Un salaire (le 25) et un loyer (le 5), tous deux dus en juin.
        let salary = RecurringTransaction(
            title: "Salaire", amount: Decimal("8450.00"), type: .income,
            firstOccurrence: calendar.date(from: DateComponents(year: 2026, month: 1, day: 25, hour: 9))!,
            account: account
        )
        let rent = RecurringTransaction(
            title: "Loyer", amount: Decimal("1850.00"), type: .expense,
            firstOccurrence: calendar.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 9))!,
            account: account
        )
        context.insert(salary)
        context.insert(rent)
        return (salary, rent)
    }

    func testMonthCheckCountsPendingAndDone() {
        let (salary, rent) = makeCheckFixtures()
        let interval = MonthInterval(containing: now, calendar: calendar)

        let before = service.monthCheck(recurrings: [salary, rent], in: interval, transactions: [])
        XCTAssertEqual(before.done, 0)
        XCTAssertEqual(before.total, 2)

        // Le loyer est comptabilisé (mouvement lié par recurringID).
        let posted = service.makeTransaction(
            from: rent,
            on: calendar.date(from: DateComponents(year: 2026, month: 6, day: 5, hour: 9))!,
            now: now
        )
        let after = service.monthCheck(recurrings: [salary, rent], in: interval, transactions: [posted])
        XCTAssertEqual(after.done, 1, "Le loyer comptabilisé compte comme validé")
        XCTAssertEqual(after.total, 2)
    }

    func testMonthCheckClosedWhenEverythingIsPosted() {
        let (salary, rent) = makeCheckFixtures()
        let interval = MonthInterval(containing: now, calendar: calendar)
        let postedSalary = service.makeTransaction(
            from: salary, on: now, now: now
        )
        let postedRent = service.makeTransaction(
            from: rent,
            on: calendar.date(from: DateComponents(year: 2026, month: 6, day: 5, hour: 9))!,
            now: now
        )
        let check = service.monthCheck(
            recurrings: [salary, rent], in: interval, transactions: [postedSalary, postedRent]
        )
        XCTAssertEqual(check.done, check.total, "Tout validé = mois bouclé")
        XCTAssertEqual(check.total, 2)
    }

    func testMonthCheckIgnoresInactiveAndOutOfMonthRecurrings() {
        let (_, rent) = makeCheckFixtures()
        rent.isActive = false
        let futureOnly = RecurringTransaction(
            title: "Prime annuelle", amount: Decimal("500.00"), type: .expense,
            firstOccurrence: calendar.date(from: DateComponents(year: 2026, month: 9, day: 1, hour: 9))!,
            account: account
        )
        context.insert(futureOnly)
        let interval = MonthInterval(containing: now, calendar: calendar)
        let check = service.monthCheck(
            recurrings: [rent, futureOnly], in: interval, transactions: []
        )
        XCTAssertEqual(check.total, 0, "Inactif ou hors du mois : rien à valider")
        XCTAssertEqual(check.done, 0)
    }
}

// MARK: - Streak de mois bouclés (🔥)

extension RecurringScheduleServiceTests {
    func testStreakCountsConsecutiveClosedMonths() {
        let (_, rent) = makeCheckFixtures()
        // Loyer comptabilisé en avril, mai et juin — juin inclus dans la série.
        let posted = [4, 5, 6].map { month in
            service.makeTransaction(
                from: rent,
                on: calendar.date(from: DateComponents(year: 2026, month: month, day: 5, hour: 9))!,
                now: now
            )
        }
        // On ne garde que le loyer comme récurrent dû (le salaire casserait la série).
        let streak = service.closedStreak(endingAt: now, recurrings: [rent], transactions: posted)
        XCTAssertEqual(streak, 3)
    }

    func testStreakSkipsOpenCurrentMonthAndBreaksOnGap() {
        let (_, rent) = makeCheckFixtures()
        // Mai comptabilisé, juin (courant) ouvert → série = 1 (mai).
        let may = service.makeTransaction(
            from: rent,
            on: calendar.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 9))!,
            now: now
        )
        XCTAssertEqual(service.closedStreak(endingAt: now, recurrings: [rent], transactions: [may]), 1)
        // Avril seul (trou en mai) → la série s'arrête à zéro.
        let april = service.makeTransaction(
            from: rent,
            on: calendar.date(from: DateComponents(year: 2026, month: 4, day: 5, hour: 9))!,
            now: now
        )
        XCTAssertEqual(service.closedStreak(endingAt: now, recurrings: [rent], transactions: [april]), 0)
    }
}
