import XCTest
import SwiftData
@testable import Budget

final class NetWorthServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: NetWorthService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = NetWorthService(calendar: calendar)
    }

    override func tearDown() {
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    // MARK: - Formula and signs

    func testBreakdownComponentsSumToNetWorth() {
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        let car = Asset(name: "Voiture", kind: .vehicle, currentValue: Decimal("12000.00"))
        let lpp = PensionAsset(pillar: .pillar2, institutionName: "Caisse", currentValue: Decimal("85000.00"))
        let lease = Liability(name: "Leasing", kind: .leasing, outstandingAmount: Decimal("8400.00"))
        for model in [current] as [Account] { context.insert(model) }
        context.insert(car)
        context.insert(lpp)
        context.insert(lease)

        let breakdown = service.breakdown(accounts: [current], assets: [car], pensions: [lpp], liabilities: [lease])
        XCTAssertEqual(breakdown.accountsTotal, Decimal("5000.00"))
        XCTAssertEqual(breakdown.assetsTotal, Decimal("12000.00"))
        XCTAssertEqual(breakdown.pensionTotal, Decimal("85000.00"))
        XCTAssertEqual(breakdown.liabilitiesTotal, Decimal("8400.00"))
        XCTAssertEqual(breakdown.netWorth, Decimal("93600.00"))
        XCTAssertEqual(
            breakdown.netWorth,
            breakdown.accountsTotal + breakdown.assetsTotal + breakdown.pensionTotal - breakdown.liabilitiesTotal,
            "La décomposition se réconcilie toujours"
        )
    }

    func testPositiveLiabilityIsSubtractedNeverAdded() {
        let debt = Liability(name: "Dette fiscale", kind: .taxDebt, outstandingAmount: Decimal("2000.00"))
        context.insert(debt)
        let breakdown = service.breakdown(accounts: [], assets: [], pensions: [], liabilities: [debt])
        XCTAssertEqual(breakdown.netWorth, Decimal("-2000.00"), "Dette stockée positive, toujours soustraite")
    }

    func testDebtAccountCountsOnceThroughAccounts() {
        // Une carte de crédit à solde négatif vit dans les comptes ; elle
        // n'est PAS doublée par une Liability.
        let card = Account(name: "Carte", type: .creditCard, openingBalance: Decimal("-1500.00"))
        context.insert(card)
        let breakdown = service.breakdown(accounts: [card], assets: [], pensions: [], liabilities: [])
        XCTAssertEqual(breakdown.accountsTotal, Decimal("-1500.00"))
        XCTAssertEqual(breakdown.netWorth, Decimal("-1500.00"))
    }

    // MARK: - Include/exclude toggles

    func testExcludedItemsStayOut() {
        let included = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        let excludedAccount = Account(name: "Hors patrimoine", type: .savings, openingBalance: Decimal("9999.00"), includeInNetWorth: false)
        let archived = Account(name: "Archivé", type: .savings, openingBalance: Decimal("7777.00"), isActive: false)
        let excludedAsset = Asset(name: "Montres", kind: .collectible, currentValue: Decimal("3500.00"), includeInNetWorth: false)
        let excludedDebt = Liability(name: "Contestée", kind: .privateDebt, outstandingAmount: Decimal("500.00"), includeInNetWorth: false)
        let closedPension = PensionAsset(pillar: .pillar3b, institutionName: "Ancienne", currentValue: Decimal("111.00"), isActive: false)
        for account in [included, excludedAccount, archived] { context.insert(account) }
        context.insert(excludedAsset)
        context.insert(excludedDebt)
        context.insert(closedPension)

        let breakdown = service.breakdown(
            accounts: [included, excludedAccount, archived],
            assets: [excludedAsset],
            pensions: [closedPension],
            liabilities: [excludedDebt]
        )
        XCTAssertEqual(breakdown.netWorth, Decimal("1000.00"), "Chaque drapeau exclu/inactif est respecté")
    }

    // MARK: - Transfer neutrality

    func testInternalTransferLeavesFullNetWorthUnchanged() {
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        let savings = Account(name: "Épargne", type: .savings, openingBalance: Decimal("1000.00"))
        let car = Asset(name: "Voiture", kind: .vehicle, currentValue: Decimal("12000.00"))
        let lease = Liability(name: "Leasing", kind: .leasing, outstandingAmount: Decimal("8400.00"))
        context.insert(current)
        context.insert(savings)
        context.insert(car)
        context.insert(lease)

        let before = service.breakdown(accounts: [current, savings], assets: [car], pensions: [], liabilities: [lease]).netWorth

        let transfer = BudgetTransaction(
            date: now, amount: Decimal("1500.00"), type: .transfer,
            title: "Virement", account: current, destinationAccount: savings
        )
        context.insert(transfer)

        let after = service.breakdown(accounts: [current, savings], assets: [car], pensions: [], liabilities: [lease]).netWorth
        XCTAssertEqual(before, after, "Un virement interne ne change jamais la fortune nette")
    }

    // MARK: - Snapshots

    func testSnapshotRecordedAtMostOncePerDay() throws {
        let breakdown = NetWorthBreakdown(
            accountsTotal: Decimal("5000.00"),
            assetsTotal: Decimal("12000.00"),
            pensionTotal: .zero,
            liabilitiesTotal: Decimal("8400.00")
        )
        let first = try service.recordSnapshotIfNeeded(breakdown: breakdown, existing: [], now: now, context: context)
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.netWorth, Decimal("8600.00"))

        let existing = try context.fetch(FetchDescriptor<NetWorthSnapshot>())
        let sameDayLater = now.addingTimeInterval(3 * 3600)
        let second = try service.recordSnapshotIfNeeded(breakdown: breakdown, existing: existing, now: sameDayLater, context: context)
        XCTAssertNil(second, "Un seul instantané par jour calendaire")

        let nextDay = now.addingTimeInterval(24 * 3600)
        let third = try service.recordSnapshotIfNeeded(breakdown: breakdown, existing: existing, now: nextDay, context: context)
        XCTAssertNotNil(third)
        XCTAssertEqual(try context.fetch(FetchDescriptor<NetWorthSnapshot>()).count, 2)
    }

    func testTrendIsChronological() {
        let older = NetWorthSnapshot(date: now.addingTimeInterval(-86_400 * 60), accountsTotal: .zero, assetsTotal: .zero, pensionTotal: .zero, liabilitiesTotal: .zero, netWorth: Decimal("100.00"))
        let newer = NetWorthSnapshot(date: now, accountsTotal: .zero, assetsTotal: .zero, pensionTotal: .zero, liabilitiesTotal: .zero, netWorth: Decimal("200.00"))
        let middle = NetWorthSnapshot(date: now.addingTimeInterval(-86_400 * 30), accountsTotal: .zero, assetsTotal: .zero, pensionTotal: .zero, liabilitiesTotal: .zero, netWorth: Decimal("150.00"))
        let trend = service.trend(snapshots: [newer, older, middle])
        XCTAssertEqual(trend.map(\.netWorth), [Decimal("100.00"), Decimal("150.00"), Decimal("200.00")])
    }

    // MARK: - Persistence

    func testAssetsAndLiabilitiesRoundTrip() throws {
        context.insert(Asset(name: "Voiture", kind: .vehicle, currentValue: Decimal("12000.00")))
        context.insert(Liability(name: "Leasing", kind: .leasing, outstandingAmount: Decimal("8400.00")))
        try context.save()

        let secondContext = ModelContext(container)
        let assets = try secondContext.fetch(FetchDescriptor<Asset>())
        let liabilities = try secondContext.fetch(FetchDescriptor<Liability>())
        XCTAssertEqual(assets.first?.kind, .vehicle)
        XCTAssertEqual(assets.first?.currentValue, Decimal("12000.00"))
        XCTAssertTrue(assets.first?.includeInNetWorth ?? false)
        XCTAssertEqual(liabilities.first?.kind, .leasing)
        XCTAssertEqual(liabilities.first?.outstandingAmount, Decimal("8400.00"))
    }
}
