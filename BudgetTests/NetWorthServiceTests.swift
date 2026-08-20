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

    /// ADR-036 (P0 AVS) : une rente estimée du 1er pilier n'entre pas
    /// dans le patrimoine — de l'argent qui n'existe pas encore ne peut
    /// pas gonfler la fortune.
    func testPensionAnnuityIsExcludedFromNetWorth() {
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        let lpp = PensionAsset(pillar: .pillar2, institutionName: "Caisse", currentValue: Decimal("85000.00"))
        let avs = PensionAsset(pillar: .pillar1, institutionName: "AVS", currentValue: Decimal("2450.00"))
        context.insert(current)
        context.insert(lpp)
        context.insert(avs)

        let breakdown = service.breakdown(accounts: [current], assets: [], pensions: [lpp, avs], liabilities: [])
        XCTAssertEqual(breakdown.pensionTotal, Decimal("85000.00"),
                       "le capital LPP compte, la rente AVS jamais")
        XCTAssertEqual(breakdown.netWorth, Decimal("90000.00"))
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

    // MARK: - FE2-4 : les vues d'argent (mêmes définitions que la PWA)

    func testAccessibleSavingsIsTheStockOfActiveSavingsAccountsOnly() {
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        let savings = Account(name: "Épargne", type: .savings, openingBalance: Decimal("2300.00"))
        let broker = Account(name: "Titres", type: .broker, openingBalance: Decimal("500.00"))
        let pillar = Account(name: "3a", type: .pillar3a, openingBalance: Decimal("8000.00"))
        let archived = Account(name: "Ancienne épargne", type: .savings, openingBalance: Decimal("999.00"), isActive: false)
        for account in [current, savings, broker, pillar, archived] { context.insert(account) }

        XCTAssertEqual(
            service.accessibleSavings(accounts: [current, savings, broker, pillar, archived]),
            Decimal("2300.00"),
            "L'épargne accessible = comptes d'épargne actifs SEULEMENT — ni quotidien, ni titres, ni prévoyance, ni archivés"
        )
    }

    func testLiquidWealthCountsEachFrancExactlyOnce() {
        // Reflet de la fixture de parité n° 6 : 104'700 au quotidien
        // + 2'300 d'épargne = 107'000 de fortune liquide.
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("104700.00"))
        let savings = Account(name: "Épargne", type: .savings, openingBalance: Decimal("2300.00"))
        context.insert(current)
        context.insert(savings)
        XCTAssertEqual(
            service.liquidWealth(accounts: [current, savings]),
            Decimal("107000.00"),
            "Fortune liquide = disponible maintenant + épargne accessible"
        )

        // Un compte d'épargne marqué « compte dans le cash disponible »
        // porte les deux qualités — il ne doit être compté qu'UNE fois.
        let both = Account(name: "Épargne quotidienne", type: .savings, openingBalance: Decimal("1000.00"), includeInAvailableCash: true)
        context.insert(both)
        XCTAssertEqual(
            service.liquidWealth(accounts: [current, savings, both]),
            Decimal("108000.00"),
            "Aucun double comptage : chaque franc vit une seule fois dans la fortune liquide"
        )
    }

    func testSetAsideFlowsCountPostedSavingAndInvestmentOnly() {
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        let savings = Account(name: "Épargne", type: .savings, openingBalance: Decimal("1000.00"))
        context.insert(current)
        context.insert(savings)
        let june = calendar.dateInterval(of: .month, for: now)!
        let posted = BudgetTransaction(
            date: now, amount: Decimal("300.00"), type: .saving,
            title: "Mise de côté", account: current, destinationAccount: savings
        )
        let invested = BudgetTransaction(
            date: now, amount: Decimal("200.00"), type: .investment,
            title: "Titres", account: current, destinationAccount: savings
        )
        // Le PRÉVU n'entre jamais dans un flux « mis de côté » : une
        // projection n'est pas de l'argent possédé (règle d'or FE2).
        let planned = BudgetTransaction(
            date: now, amount: Decimal("500.00"), type: .saving, status: .planned,
            title: "Prévu", account: current, destinationAccount: savings
        )
        let expense = BudgetTransaction(
            date: now, amount: Decimal("80.00"), type: .expense,
            title: "Courses", account: current
        )
        let lastYear = BudgetTransaction(
            date: now.addingTimeInterval(-400 * 86_400), amount: Decimal("700.00"), type: .saving,
            title: "Vieille mise de côté", account: current, destinationAccount: savings
        )
        for transaction in [posted, invested, planned, expense, lastYear] { context.insert(transaction) }

        let all = [posted, invested, planned, expense, lastYear]
        XCTAssertEqual(
            AccountsTab.setAsideFlows(all, from: june.start, to: june.end),
            Decimal("500.00"),
            "Le flux du mois = mises de côté et investissements COMPTABILISÉS du mois"
        )
        let year = calendar.dateInterval(of: .year, for: now)!
        XCTAssertEqual(
            AccountsTab.setAsideFlows(all, from: year.start, to: year.end),
            Decimal("500.00"),
            "Le flux de l'année ignore l'an dernier, le prévu et les dépenses"
        )
    }

    // MARK: - FE2-7 : composition du patrimoine brut

    func testCompositionPartsKeepOnlyPositiveClasses() {
        let breakdown = NetWorthBreakdown(
            accountsTotal: Decimal("-500.00"),
            assetsTotal: Decimal("12000.00"),
            pensionTotal: Decimal("8000.00"),
            liabilitiesTotal: Decimal("100.00")
        )
        let parts = NetWorthView.compositionParts(breakdown)
        XCTAssertEqual(parts.map(\.label), ["Vos biens", "Prévoyance"],
                       "Un total négatif ou nul ne crée pas de part ; les dettes n'entrent jamais dans la barre")
        XCTAssertEqual(NetWorthView.percentage(Decimal("12000.00"), of: Decimal("20000.00")), 60)
        XCTAssertEqual(NetWorthView.percentage(Decimal("1.00"), of: .zero), 0,
                       "Jamais de division par zéro")
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
