import XCTest
import SwiftData
@testable import Budget

final class OnboardingViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    private func makeValidModel() -> OnboardingViewModel {
        let model = OnboardingViewModel()
        model.householdName = "Famille Test"
        model.ownerFirstName = "Alex"
        model.canton = .GE
        model.municipality = "Genève"
        model.accountName = "Compte courant"
        model.openingBalanceText = "2'500.00"
        return model
    }

    func testHouseholdStepRequiresAName() {
        let model = OnboardingViewModel()
        model.step = .household
        model.householdName = "   "
        XCTAssertFalse(model.validateCurrentStep())
        XCTAssertNotNil(model.validationMessage)
    }

    func testFirstAccountStepRejectsInvalidAmount() {
        let model = makeValidModel()
        model.step = .firstAccount
        model.openingBalanceText = "abc"
        XCTAssertFalse(model.validateCurrentStep())
        XCTAssertNotNil(model.validationMessage)
    }

    /// A17 (risque n° 4) : la même borne de taux que la PWA — 0 à 60 % —
    /// partout où le taux se saisit nativement, via l'unique constante
    /// `TaxService.maximumProvisionRate`.
    func testTaxRateStepSharesTheSingleSixtyPercentBoundWithThePWA() {
        XCTAssertEqual(TaxService.maximumProvisionRate, Decimal("0.60"))

        let model = makeValidModel()
        model.step = .taxRate
        model.taxProvisionRate = Decimal("0.61")
        XCTAssertFalse(model.validateCurrentStep())
        XCTAssertEqual(model.validationMessage, "Le taux doit être compris entre 0 % et 60 %.")

        model.taxProvisionRate = Decimal("0.60")
        XCTAssertTrue(model.validateCurrentStep())

        model.taxProvisionRate = Decimal("-0.01")
        XCTAssertFalse(model.validateCurrentStep())
    }

    func testEmptyBalanceDefaultsToZero() {
        let model = makeValidModel()
        model.openingBalanceText = ""
        XCTAssertEqual(model.openingBalance, .zero)
    }

    func testSwissAmountInputIsParsed() {
        let model = makeValidModel()
        model.openingBalanceText = "18'190,00"
        XCTAssertEqual(model.openingBalance, Decimal("18190.00"))
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func testFinishCreatesProfileCategoriesAndAccount() throws {
        let model = makeValidModel()
        model.step = .income
        let now = Date(timeIntervalSince1970: 1_781_524_800)

        try model.finish(context: context, calendar: utcCalendar, now: now)

        let households = try context.fetch(FetchDescriptor<Household>())
        XCTAssertEqual(households.count, 1)
        let household = try XCTUnwrap(households.first)
        XCTAssertEqual(household.name, "Famille Test")
        XCTAssertEqual(household.canton, "GE")
        XCTAssertEqual(household.taxProvisionRate, Decimal("0.30"))
        XCTAssertEqual(household.members.count, 1)
        XCTAssertEqual(household.members.first?.role, .owner)

        let accounts = try context.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts.first?.openingBalance, Decimal("2500.00"))
        XCTAssertEqual(accounts.first?.type, .current)

        let categories = try context.fetch(FetchDescriptor<BudgetCategory>())
        XCTAssertEqual(categories.count, DefaultCategories.all.count)
    }

    func testFinishDoesNothingWhenInvalid() throws {
        let model = makeValidModel()
        model.step = .firstAccount
        model.householdName = ""
        model.step = .household
        XCTAssertFalse(model.validateCurrentStep())

        model.step = .firstAccount
        model.accountName = ""
        try model.finish(context: context, calendar: utcCalendar, now: Date())
        XCTAssertEqual(try context.fetch(FetchDescriptor<Household>()).count, 0)
    }
}
