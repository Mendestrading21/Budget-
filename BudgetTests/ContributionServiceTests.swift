import XCTest
@testable import Budget

/// Cumuls « façon Finary » : chaque versement s'additionne — total,
/// année en cours, retraits, et plus-value des comptes titres.
final class ContributionServiceTests: XCTestCase {
    private var calendar: Calendar!
    private var service: ContributionService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)
    // 15.06.2025 12:00 UTC — l'année précédente
    private let lastYear = Date(timeIntervalSince1970: 1_749_988_800)

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        service = ContributionService(calendar: calendar)
    }

    override func tearDown() {
        service = nil
        calendar = nil
    }

    func testContributionsAccumulateAcrossYears() {
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("9000.00"))
        let savings = Account(name: "Épargne", type: .savings)
        let older = BudgetTransaction(
            date: lastYear, amount: Decimal("2400.00"), type: .saving,
            title: "Épargne 2025", account: current, destinationAccount: savings
        )
        let recent = BudgetTransaction(
            date: now, amount: Decimal("600.00"), type: .saving,
            title: "Épargne juin", account: current, destinationAccount: savings
        )
        let summary = service.summary(of: savings, movements: [older, recent], now: now)
        XCTAssertEqual(summary.total, Decimal("3000.00"), "Chaque versement s'additionne, toutes années confondues")
        XCTAssertEqual(summary.currentYear, Decimal("600.00"))
        XCTAssertEqual(summary.withdrawn, .zero)
    }

    func testWithdrawalReducesNetButNotTotal() {
        let current = Account(name: "Courant", type: .current)
        let savings = Account(name: "Épargne", type: .savings)
        let inflow = BudgetTransaction(
            date: now, amount: Decimal("1000.00"), type: .saving,
            title: "Versement", account: current, destinationAccount: savings
        )
        let out = BudgetTransaction(
            date: now, amount: Decimal("300.00"), type: .transfer,
            title: "Retrait", account: savings, destinationAccount: current
        )
        let summary = service.summary(of: savings, movements: [inflow, out], now: now)
        XCTAssertEqual(summary.total, Decimal("1000.00"), "Le total versé n'oublie jamais un versement")
        XCTAssertEqual(summary.withdrawn, Decimal("300.00"))
        XCTAssertEqual(summary.net, Decimal("700.00"))
    }

    func testPlannedMovementsAndAdjustmentsAreIgnored() {
        let current = Account(name: "Courant", type: .current)
        let broker = Account(name: "Titres", type: .broker)
        let planned = BudgetTransaction(
            date: now, amount: Decimal("500.00"), type: .investment, status: .planned,
            title: "Prévu", account: current, destinationAccount: broker
        )
        let valueUp = BudgetTransaction(
            date: now, amount: Decimal("250.00"), type: .adjustment,
            title: "Réévaluation", account: broker
        )
        let summary = service.summary(of: broker, movements: [planned, valueUp], now: now)
        XCTAssertEqual(summary.total, .zero, "Un mouvement prévu n'est pas encore un versement")
        XCTAssertEqual(summary.withdrawn, .zero, "Une réévaluation n'est pas un retrait")
    }

    func testBrokerPerformanceIsValueMinusNetContributions() {
        // Ouverture 1000, versé net 2000, valeur actuelle 3450 → +450.
        let summary = ContributionSummary(
            total: Decimal("2300.00"), currentYear: Decimal("2300.00"), withdrawn: Decimal("300.00")
        )
        XCTAssertEqual(
            service.performance(balance: Decimal("3450.00"), openingBalance: Decimal("1000.00"), summary: summary),
            Decimal("450.00")
        )
        XCTAssertEqual(
            service.performance(balance: Decimal("2700.00"), openingBalance: Decimal("1000.00"), summary: summary),
            Decimal("-300.00"),
            "Une moins-value s'affiche telle quelle — jamais masquée"
        )
    }

    func testTrackedAccountTypes() {
        XCTAssertTrue(ContributionService.tracksContributions(.savings))
        XCTAssertTrue(ContributionService.tracksContributions(.broker))
        XCTAssertTrue(ContributionService.tracksContributions(.pillar3a))
        XCTAssertTrue(ContributionService.tracksContributions(.pillar3b))
        XCTAssertTrue(ContributionService.tracksContributions(.occupationalPension))
        XCTAssertFalse(ContributionService.tracksContributions(.current))
        XCTAssertFalse(ContributionService.tracksContributions(.creditCard))
    }
}
