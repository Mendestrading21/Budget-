import XCTest
import SwiftData
@testable import Budget

final class GoalProjectionServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: GoalProjectionService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = GoalProjectionService(calendar: calendar)
    }

    override func tearDown() {
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    private func date(_ day: Int, _ month: Int, _ year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeGoal(
        target: Decimal = Decimal("3000.00"),
        targetDate: Date? = nil,
        manual: Decimal = .zero,
        planned: Decimal = .zero,
        linked: Account? = nil
    ) -> FinancialGoal {
        let goal = FinancialGoal(
            name: "Test",
            kind: .travel,
            targetAmount: target,
            targetDate: targetDate,
            manualCurrentAmount: manual,
            plannedMonthlyContribution: planned,
            linkedAccount: linked
        )
        context.insert(goal)
        return goal
    }

    // MARK: - Current amount

    func testLinkedAccountBalanceDrivesCurrentAmount() {
        let account = Account(name: "Épargne", type: .savings, openingBalance: Decimal("12500.00"))
        context.insert(account)
        let goal = makeGoal(target: Decimal("20000.00"), manual: Decimal("999.00"), linked: account)
        XCTAssertEqual(service.currentAmount(of: goal), Decimal("12500.00"), "Le compte lié prime sur le manuel")
    }

    func testManualAmountUsedWithoutLink() {
        let goal = makeGoal(manual: Decimal("1200.00"))
        XCTAssertEqual(service.currentAmount(of: goal), Decimal("1200.00"))
    }

    // MARK: - Safe edges

    func testZeroTargetIsSafeAndCountsAsReached() {
        let goal = makeGoal(target: .zero, manual: Decimal("100.00"))
        let report = service.report(for: goal, now: now)
        XCTAssertEqual(report.progressFraction, Decimal(1))
        XCTAssertEqual(report.remainingAmount, .zero)
        XCTAssertEqual(report.scheduleStatus, .achieved)
    }

    func testProgressIsClampedToOne() {
        let goal = makeGoal(target: Decimal("1000.00"), manual: Decimal("2500.00"))
        let report = service.report(for: goal, now: now)
        XCTAssertEqual(report.progressFraction, Decimal(1))
        XCTAssertEqual(report.scheduleStatus, .achieved)
        XCTAssertNil(report.projectedCompletionDate)
    }

    func testExpiredDateWithMissingMoneyIsOverdueAndDueNow() {
        let goal = makeGoal(target: Decimal("3000.00"), targetDate: date(1, 3), manual: Decimal("1000.00"))
        let report = service.report(for: goal, now: now)
        XCTAssertEqual(report.scheduleStatus, .overdue)
        XCTAssertEqual(report.monthsRemaining, 0)
        XCTAssertEqual(report.requiredMonthlyContribution, Decimal("2000.00"), "Tout est dû immédiatement")
    }

    func testZeroPlannedContributionYieldsNoProjectionAndNoCrash() {
        let goal = makeGoal(target: Decimal("3000.00"), manual: Decimal("1000.00"), planned: .zero)
        let report = service.report(for: goal, now: now)
        XCTAssertNil(report.projectedCompletionDate)
        XCTAssertEqual(report.scheduleStatus, .noDeadline)
    }

    // MARK: - Months remaining and required contribution

    func testMonthsRemainingCountsExactMonths() {
        XCTAssertEqual(service.monthsRemaining(until: date(15, 12), now: now), 6)
    }

    func testMonthsRemainingCountsStartedMonthAsOne() {
        XCTAssertEqual(service.monthsRemaining(until: date(31, 12), now: now), 7)
        XCTAssertEqual(service.monthsRemaining(until: date(20, 6), now: now), 1)
    }

    func testRequiredContributionSpreadsRemainingOverMonths() {
        // Reste 1800 sur 6 mois → 300 / mois.
        let goal = makeGoal(target: Decimal("3000.00"), targetDate: date(15, 12), manual: Decimal("1200.00"), planned: Decimal("150.00"))
        let report = service.report(for: goal, now: now)
        XCTAssertEqual(report.monthsRemaining, 6)
        XCTAssertEqual(report.requiredMonthlyContribution, Decimal("300.00"))
        XCTAssertEqual(report.scheduleStatus, .behind, "150 prévu < 300 requis")
    }

    func testOnTrackWhenPlannedCoversRequired() {
        let goal = makeGoal(target: Decimal("3000.00"), targetDate: date(15, 12), manual: Decimal("1200.00"), planned: Decimal("300.00"))
        XCTAssertEqual(service.report(for: goal, now: now).scheduleStatus, .onTrack)
    }

    func testLastMonthRequiresEverything() {
        let goal = makeGoal(target: Decimal("3000.00"), targetDate: date(20, 6), manual: Decimal("2500.00"))
        let report = service.report(for: goal, now: now)
        XCTAssertEqual(report.monthsRemaining, 1)
        XCTAssertEqual(report.requiredMonthlyContribution, Decimal("500.00"))
    }

    // MARK: - Projection at planned pace

    func testProjectedCompletionUsesCeilDivision() {
        // Reste 1000, prévu 300 / mois → 4 mois (⌈3.33⌉).
        let goal = makeGoal(target: Decimal("2000.00"), manual: Decimal("1000.00"), planned: Decimal("300.00"))
        let report = service.report(for: goal, now: now)
        let expected = calendar.date(byAdding: .month, value: 4, to: now)
        XCTAssertEqual(report.projectedCompletionDate, expected)
    }

    // MARK: - Persistence

    func testGoalRoundTripsAcrossContexts() throws {
        let account = Account(name: "Épargne", type: .savings, openingBalance: Decimal("500.00"))
        context.insert(account)
        _ = makeGoal(target: Decimal("20000.00"), targetDate: date(31, 12), planned: Decimal("600.00"), linked: account)
        try context.save()

        let secondContext = ModelContext(container)
        let fetched = try secondContext.fetch(FetchDescriptor<FinancialGoal>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.kind, .travel)
        XCTAssertEqual(fetched.first?.priority, .normal)
        XCTAssertEqual(fetched.first?.status, .active)
        XCTAssertEqual(fetched.first?.linkedAccount?.name, "Épargne")
        XCTAssertEqual(fetched.first?.plannedMonthlyContribution, Decimal("600.00"))
    }
}
