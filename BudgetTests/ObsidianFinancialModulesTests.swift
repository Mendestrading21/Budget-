import SwiftUI
import SwiftData
import UIKit
import XCTest
@testable import Budget

/// Lot L6 — modules financiers : la refonte Obsidian n'invente AUCUNE
/// donnée fiscale ni rendement, garde réservé/payé/estimé distincts, la
/// fortune = actifs − dettes, les projections séparées du réel, et les
/// écrans se construisent dans les états exigés.
final class ObsidianFinancialModulesTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!

    // 15.06.2026 12:00 UTC — même référence déterministe que les fixtures.
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
    }

    override func tearDown() {
        context = nil
        container = nil
        calendar = nil
    }

    // MARK: - Objectifs : réel, projection et états distincts

    func testGoalReportSeparatesRealProgressFromProjection() throws {
        let account = Account(name: "Épargne", type: .savings, openingBalance: Decimal("2000.00"))
        context.insert(account)
        let due = calendar.date(byAdding: .month, value: 10, to: now)!
        let goal = FinancialGoal(
            name: "Fonds d'urgence", kind: .emergencyFund,
            targetAmount: Decimal("10000.00"), targetDate: due,
            plannedMonthlyContribution: Decimal("300.00"),
            linkedAccount: account
        )
        context.insert(goal)
        try context.save()

        let report = GoalProjectionService(calendar: calendar).report(for: goal, now: now)
        XCTAssertEqual(report.currentAmount, Decimal("2000.00"), "le RÉEL vient du solde lié")
        XCTAssertEqual(report.remainingAmount, Decimal("8000.00"))
        XCTAssertNotNil(report.monthsRemaining)
        XCTAssertNotNil(report.requiredMonthlyContribution,
                        "l'effort requis n'existe que parce que la logique EXISTANTE le calcule")
    }

    func testGoalWithoutDateHasNoInventedDeadline() throws {
        let goal = FinancialGoal(
            name: "Sans date", kind: .custom,
            targetAmount: Decimal("5000.00"), targetDate: nil,
            manualCurrentAmount: Decimal("1000.00")
        )
        context.insert(goal)
        try context.save()

        let report = GoalProjectionService(calendar: calendar).report(for: goal, now: now)
        XCTAssertNil(report.monthsRemaining, "sans date : aucun délai inventé")
        XCTAssertNil(report.requiredMonthlyContribution, "sans date : aucun effort mensuel inventé")
        XCTAssertEqual(report.remainingAmount, Decimal("4000.00"))
    }

    func testAchievedGoalReportsFullProgress() throws {
        let goal = FinancialGoal(
            name: "Atteint", kind: .travel,
            targetAmount: Decimal("1000.00"),
            manualCurrentAmount: Decimal("1000.00")
        )
        context.insert(goal)
        try context.save()

        let report = GoalProjectionService(calendar: calendar).report(for: goal, now: now)
        XCTAssertEqual(report.progressFraction, 1, "objectif atteint : progression pleine")
        XCTAssertEqual(report.remainingAmount, .zero)
    }

    // MARK: - Patrimoine : actifs − dettes, dette > actifs

    func testNetWorthIsAssetsMinusLiabilitiesEvenWhenNegative() throws {
        let account = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        let asset = Asset(name: "Voiture", kind: .vehicle, currentValue: Decimal("5000.00"))
        let liability = Liability(name: "Prêt", kind: .loan, outstandingAmount: Decimal("9000.00"))
        context.insert(account)
        context.insert(asset)
        context.insert(liability)
        try context.save()

        let breakdown = NetWorthService(calendar: calendar).breakdown(
            accounts: [account], assets: [asset], pensions: [], liabilities: [liability]
        )
        XCTAssertEqual(breakdown.accountsTotal, Decimal("1000.00"))
        XCTAssertEqual(breakdown.assetsTotal, Decimal("5000.00"))
        XCTAssertEqual(breakdown.liabilitiesTotal, Decimal("9000.00"))
        XCTAssertEqual(breakdown.netWorth, Decimal("-3000.00"),
                       "fortune nette = actifs − dettes, négative quand la dette domine")
    }

    // MARK: - Prévoyance : rien d'inventé, pas de faux zéro

    func testPensionProjectionIsNeverInvented() throws {
        let withProjection = PensionAsset(
            pillar: .pillar3a, institutionName: "Banque",
            currentValue: Decimal("20000.00"),
            projectedValueAtRetirement: Decimal("80000.00")
        )
        let withoutProjection = PensionAsset(
            pillar: .pillar2, institutionName: "Caisse",
            currentValue: Decimal("50000.00")
        )
        context.insert(withProjection)
        context.insert(withoutProjection)
        try context.save()

        let service = InsurancePensionService()
        XCTAssertEqual(service.totalPensionCapital(assets: [withProjection, withoutProjection]), Decimal("70000.00"))
        // Une position SANS projection de certificat n'en reçoit jamais une.
        XCTAssertNil(service.totalProjectedAtRetirement(assets: [withoutProjection]),
                     "aucun rendement futur inventé quand le certificat n'en donne pas")
        XCTAssertEqual(service.totalProjectedAtRetirement(assets: [withProjection]), Decimal("80000.00"))
    }

    // MARK: - Assurances : équivalents mensuels/annuels réconciliés

    func testInsurancePremiumEquivalentsReconcile() throws {
        let annual = InsuranceContract(
            insurerName: "Assureur A", policyName: "RC", kind: .liability,
            premiumAmount: Decimal("600.00"), premiumUnit: .year
        )
        let monthly = InsuranceContract(
            insurerName: "Assureur B", policyName: "LAMal", kind: .healthBase,
            premiumAmount: Decimal("400.00"), premiumUnit: .month
        )
        context.insert(annual)
        context.insert(monthly)
        try context.save()

        let service = InsurancePensionService()
        XCTAssertEqual(service.monthlyPremium(of: annual), Decimal("50.00"),
                       "600/an = 50 par mois — jamais deux formules")
        XCTAssertEqual(service.totalAnnualPremium(contracts: [annual, monthly]), Decimal("5400.00"),
                       "600 + 400×12 : équivalents réconciliés")
    }

    // MARK: - Impôts : réservé, payé, estimé restent distincts (aucune invention)

    func testTaxFieldsStayDistinct() throws {
        let profile = TaxProfile(provisionRate: Decimal("0.30"))
        let provision = TaxProvision(
            year: 2026,
            estimatedAnnualTaxOverride: Decimal("6000.00"),
            reservedAmount: Decimal("1000.00")
        )
        profile.provisions.append(provision)
        context.insert(profile)
        // Le « payé » n'est JAMAIS stocké : il dérive des paiements
        // d'impôts comptabilisés — impossible de le désynchroniser.
        let payment = BudgetTransaction(
            date: now, amount: Decimal("400.00"),
            type: .taxPayment, status: .posted, title: "Acompte cantonal"
        )
        context.insert(payment)
        try context.save()

        let report = TaxService(calendar: calendar).report(
            year: 2026, profile: profile, provision: provision,
            transactions: [payment]
        )
        XCTAssertTrue(report.isOverridden, "l'estimation vient de la saisie, pas d'un calcul caché")
        XCTAssertEqual(report.estimatedTax, Decimal("6000.00"))
        XCTAssertEqual(report.paid, Decimal("400.00"))
        XCTAssertEqual(report.reserved, Decimal("1000.00"))
        XCTAssertNotEqual(report.paid, report.reserved, "payé ≠ réservé, toujours")
        XCTAssertEqual(report.outstanding, Decimal("5600.00"))
        XCTAssertEqual(report.estimatedTax, report.paid + report.outstanding,
                       "estimé = payé + encore dû — l'identité de réconciliation tient")
        XCTAssertEqual(report.reserveGap, Decimal("4600.00"),
                       "réserve manquante = encore dû − réservé, sans double comptage")
    }

    // MARK: - Construction des écrans dans les états exigés

    @MainActor
    private func host<V: View>(_ view: V, width: CGFloat) -> UIHostingController<V> {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 844)
        controller.view.layoutIfNeeded()
        return controller
    }

    @MainActor
    func testFinancialModuleScreensBuildInCompactAndAccessibleStates() {
        let preview = DemoDataFactory.previewAppContainer()
        func screen<V: View>(_ view: V) -> some View {
            NavigationStack { view }
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
        }
        XCTAssertNotNil(host(screen(GoalsListView()), width: 320).view, "Objectifs à 320 pt")
        XCTAssertNotNil(host(screen(TaxesView()), width: 320).view, "Impôts à 320 pt")
        XCTAssertNotNil(
            host(screen(NetWorthView()).environment(\.dynamicTypeSize, .accessibility3), width: 390).view,
            "Patrimoine en texte accessibilité"
        )
        XCTAssertNotNil(
            host(screen(PensionView()).environment(\.obsidianForcedReducedTransparency, true), width: 390).view,
            "Prévoyance en transparence réduite"
        )
        XCTAssertNotNil(host(screen(InsuranceListView()), width: 320).view, "Assurances à 320 pt")
        XCTAssertNotNil(host(screen(RecurringListView()), width: 320).view, "Récurrents à 320 pt")
    }
}
