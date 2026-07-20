import XCTest
@testable import Budget

/// « Le chemin » : la projection est une arithmétique pure et honnête —
/// taux nul = addition, capitalisation mensuelle sinon, jamais de Double.
final class WealthProjectionServiceTests: XCTestCase {
    private let service = WealthProjectionService()

    func testZeroRateDegeneratesToPlainAddition() {
        // 1000 + 100 × 24 mois = 3400, exactement.
        XCTAssertEqual(
            service.futureValue(balance: Decimal("1000.00"), monthlyContribution: Decimal("100.00"),
                                annualRate: .zero, years: 2),
            Decimal("3400.00")
        )
    }

    func testZeroYearsReturnsBalance() {
        XCTAssertEqual(
            service.futureValue(balance: Decimal("1234.56"), monthlyContribution: Decimal("999.00"),
                                annualRate: Decimal("0.05"), years: 0),
            Decimal("1234.56")
        )
    }

    func testCompoundingBeatsPlainAdditionWithPositiveRate() {
        let flat = service.futureValue(balance: Decimal("10000.00"), monthlyContribution: Decimal("500.00"),
                                       annualRate: .zero, years: 10)
        let compounded = service.futureValue(balance: Decimal("10000.00"), monthlyContribution: Decimal("500.00"),
                                             annualRate: Decimal("0.05"), years: 10)
        XCTAssertGreaterThan(compounded, flat, "Un rendement positif doit dépasser la simple addition")
        // Ordre de grandeur sain : 10 ans à 5 % ne font pas ×3.
        XCTAssertLessThan(compounded, flat * 2)
    }

    func testOneYearSingleContributionMatchesHandComputation() {
        // 0 de départ, 100/mois à 12 % annuel (1 %/mois) :
        // annuité de fin de mois = 100 × ((1.01)^12 − 1) / 0.01 = 1268.25.
        let value = service.futureValue(balance: .zero, monthlyContribution: Decimal("100.00"),
                                        annualRate: Decimal("0.12"), years: 1)
        XCTAssertEqual(value, Decimal("1268.25"))
    }

    func testProfilesAreOrderedByAmbition() {
        for keyPath in [\WealthProjectionService.Profile.savingsRate,
                        \WealthProjectionService.Profile.brokerRate,
                        \WealthProjectionService.Profile.pensionRate] {
            let prudent = WealthProjectionService.Profile.prudent[keyPath: keyPath]
            let balanced = WealthProjectionService.Profile.balanced[keyPath: keyPath]
            let ambitious = WealthProjectionService.Profile.ambitious[keyPath: keyPath]
            XCTAssertLessThan(prudent, balanced)
            XCTAssertLessThan(balanced, ambitious)
        }
    }
}
