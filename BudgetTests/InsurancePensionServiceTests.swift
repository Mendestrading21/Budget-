import XCTest
import SwiftData
@testable import Budget

final class InsurancePensionServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = InsurancePensionService()

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    private func makeContract(
        premium: Decimal,
        unit: RecurrenceUnit,
        count: Int = 1,
        isActive: Bool = true,
        cancellationDeadline: Date? = nil
    ) -> InsuranceContract {
        let contract = InsuranceContract(
            insurerName: "Test",
            policyName: "Police",
            kind: .other,
            premiumAmount: premium,
            premiumUnit: unit,
            premiumIntervalCount: count,
            cancellationDeadline: cancellationDeadline,
            isActive: isActive
        )
        context.insert(contract)
        return contract
    }

    // MARK: - Premium equivalents reconcile

    func testMonthlyPremiumAnnualizes() {
        let lamal = makeContract(premium: Decimal("745.60"), unit: .month)
        XCTAssertEqual(service.annualPremium(of: lamal), Decimal("8947.20"))
        XCTAssertEqual(service.monthlyPremium(of: lamal), Decimal("745.60"), "Mensuel : équivalent mensuel = prime")
    }

    func testAnnualPremiumMonthlyEquivalent() {
        let rc = makeContract(premium: Decimal("320.00"), unit: .year)
        XCTAssertEqual(service.annualPremium(of: rc), Decimal("320.00"))
        XCTAssertEqual(service.monthlyPremium(of: rc), Decimal("26.67"))
    }

    func testQuarterlyPremiumEquivalents() {
        let contract = makeContract(premium: Decimal("300.00"), unit: .month, count: 3)
        XCTAssertEqual(service.annualPremium(of: contract), Decimal("1200.00"))
        XCTAssertEqual(service.monthlyPremium(of: contract), Decimal("100.00"))
    }

    func testHouseholdTotalsReconcile() {
        let lamal = makeContract(premium: Decimal("745.60"), unit: .month)
        let rc = makeContract(premium: Decimal("320.00"), unit: .year)
        let inactive = makeContract(premium: Decimal("999.00"), unit: .month, isActive: false)
        let contracts = [lamal, rc, inactive]

        let annual = service.totalAnnualPremium(contracts: contracts)
        XCTAssertEqual(annual, Decimal("9267.20"), "Les contrats résiliés ne comptent pas")
        XCTAssertEqual(
            service.totalMonthlyPremium(contracts: contracts),
            FinanceMath.roundedToCents(annual / Decimal(12)),
            "Le total mensuel dérive du total annuel : toujours réconciliés"
        )
    }

    // MARK: - Deadlines

    func testCloseCancellationDeadlinesAreDetectedAndSorted() {
        let soon = makeContract(
            premium: Decimal("100.00"), unit: .year,
            cancellationDeadline: now.addingTimeInterval(10 * 86_400)
        )
        let later = makeContract(
            premium: Decimal("100.00"), unit: .year,
            cancellationDeadline: now.addingTimeInterval(40 * 86_400)
        )
        let far = makeContract(
            premium: Decimal("100.00"), unit: .year,
            cancellationDeadline: now.addingTimeInterval(90 * 86_400)
        )
        let past = makeContract(
            premium: Decimal("100.00"), unit: .year,
            cancellationDeadline: now.addingTimeInterval(-5 * 86_400)
        )
        let inactive = makeContract(
            premium: Decimal("100.00"), unit: .year, isActive: false,
            cancellationDeadline: now.addingTimeInterval(10 * 86_400)
        )

        let close = service.contractsWithCloseDeadline(
            contracts: [far, later, soon, past, inactive],
            now: now
        )
        XCTAssertEqual(close.map(\.id), [soon.id, later.id])
    }

    // MARK: - Pension totals reconcile

    /// ADR-036 (P0 AVS) : une estimation de rente ne devient JAMAIS un
    /// capital — ni dans le total, ni par pilier, ni en contributions, ni
    /// en projection. Elle reste listée à part.
    func testAnnuityEstimateNeverCountsAsCapital() {
        let avs = PensionAsset(
            pillar: .pillar1, institutionName: "AVS",
            currentValue: Decimal("2450.00"),
            annualContribution: Decimal("500.00"),
            projectedValueAtRetirement: Decimal("29400.00")
        )
        let lpp = PensionAsset(
            pillar: .pillar2, institutionName: "Caisse",
            currentValue: Decimal("85000.00"),
            annualContribution: Decimal("9600.00"),
            projectedValueAtRetirement: Decimal("420000.00")
        )
        context.insert(avs)
        context.insert(lpp)
        let assets = [avs, lpp]

        XCTAssertEqual(service.totalPensionCapital(assets: assets), Decimal("85000.00"),
                       "la rente AVS n'entre pas dans le capital")
        XCTAssertTrue(service.pensionTotalsByPillar(assets: assets).allSatisfy { $0.pillar != .pillar1 },
                      "aucune carte « capital » pour le 1er pilier")
        XCTAssertEqual(service.totalAnnualContributions(assets: assets), Decimal("9600.00"),
                       "les cotisations AVS ne construisent pas un capital individuel")
        XCTAssertEqual(service.totalProjectedAtRetirement(assets: assets), Decimal("420000.00"),
                       "la projection ignore la rente — sinon elle mélangerait rente et capital")
        XCTAssertEqual(service.estimatedAnnuities(assets: assets).map(\.id), [avs.id],
                       "la rente reste visible, à part")
    }

    func testPensionTotalsPerPillarSumToGrandTotal() {
        let lpp = PensionAsset(pillar: .pillar2, institutionName: "Caisse", currentValue: Decimal("85000.00"))
        let thirdA = PensionAsset(pillar: .pillar3a, institutionName: "Fondation", currentValue: Decimal("18190.00"))
        let thirdA2 = PensionAsset(pillar: .pillar3a, institutionName: "Banque", currentValue: Decimal("5000.00"))
        let closed = PensionAsset(pillar: .pillar3b, institutionName: "Ancienne", currentValue: Decimal("999.00"), isActive: false)
        for asset in [lpp, thirdA, thirdA2, closed] { context.insert(asset) }
        let assets = [lpp, thirdA, thirdA2, closed]

        let byPillar = service.pensionTotalsByPillar(assets: assets)
        XCTAssertEqual(byPillar.count, 2)
        XCTAssertEqual(byPillar.first { $0.pillar == .pillar2 }?.total, Decimal("85000.00"))
        XCTAssertEqual(byPillar.first { $0.pillar == .pillar3a }?.total, Decimal("23190.00"))

        let grandTotal = service.totalPensionCapital(assets: assets)
        XCTAssertEqual(grandTotal, Decimal("108190.00"), "Les positions inactives ne comptent pas")
        XCTAssertEqual(
            byPillar.reduce(Decimal.zero) { $0 + $1.total },
            grandTotal,
            "La somme des piliers égale le total général"
        )
    }

    func testProjectedTotalRequiresEveryPositionToHaveOne() {
        let withProjection = PensionAsset(
            pillar: .pillar2, institutionName: "Caisse",
            currentValue: Decimal("85000.00"),
            projectedValueAtRetirement: Decimal("420000.00")
        )
        let without = PensionAsset(pillar: .pillar3a, institutionName: "Fondation", currentValue: Decimal("18190.00"))
        context.insert(withProjection)
        context.insert(without)

        XCTAssertNil(
            service.totalProjectedAtRetirement(assets: [withProjection, without]),
            "Une somme partielle serait trompeuse"
        )
        XCTAssertEqual(
            service.totalProjectedAtRetirement(assets: [withProjection]),
            Decimal("420000.00")
        )
        XCTAssertNil(service.totalProjectedAtRetirement(assets: []))
    }

    func testContributionsTotal() {
        let lpp = PensionAsset(pillar: .pillar2, institutionName: "Caisse", currentValue: .zero, annualContribution: Decimal("9600.00"))
        let thirdA = PensionAsset(pillar: .pillar3a, institutionName: "Fondation", currentValue: .zero, annualContribution: Decimal("7044.00"))
        context.insert(lpp)
        context.insert(thirdA)
        XCTAssertEqual(service.totalAnnualContributions(assets: [lpp, thirdA]), Decimal("16644.00"))
    }

    // MARK: - Persistence

    func testContractAndAssetRoundTrip() throws {
        _ = makeContract(
            premium: Decimal("745.60"), unit: .month,
            cancellationDeadline: now.addingTimeInterval(40 * 86_400)
        )
        let asset = PensionAsset(
            pillar: .pillar2, institutionName: "Caisse",
            currentValue: Decimal("85000.00"),
            annualContribution: Decimal("9600.00"),
            projectedValueAtRetirement: Decimal("420000.00"),
            retirementAge: 65
        )
        context.insert(asset)
        try context.save()

        let secondContext = ModelContext(container)
        let contracts = try secondContext.fetch(FetchDescriptor<InsuranceContract>())
        XCTAssertEqual(contracts.count, 1)
        XCTAssertEqual(contracts.first?.premiumAmount, Decimal("745.60"))
        XCTAssertEqual(contracts.first?.premiumUnit, .month)
        XCTAssertNotNil(contracts.first?.cancellationDeadline)

        let assets = try secondContext.fetch(FetchDescriptor<PensionAsset>())
        XCTAssertEqual(assets.count, 1)
        XCTAssertEqual(assets.first?.pillar, .pillar2)
        XCTAssertEqual(assets.first?.retirementAge, 65)
        XCTAssertEqual(assets.first?.projectedValueAtRetirement, Decimal("420000.00"))
    }
}
