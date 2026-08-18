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

    /// A19 (parité PWA, lot A18) : l'onboarding ne demande PLUS de taux
    /// d'impôts. Le défaut (30 %) s'applique, et la seule saisie du taux —
    /// la feuille Impôts — reste bornée par l'unique constante 0–60 %
    /// (`TaxService.maximumProvisionRate`, lot A17).
    func testOnboardingNoLongerAsksForATaxRate() {
        XCTAssertFalse(
            OnboardingStep.allCases.map { String(describing: $0) }.contains("taxRate")
        )
        XCTAssertEqual(makeValidModel().taxProvisionRate, Decimal("0.30"))
        XCTAssertEqual(TaxService.maximumProvisionRate, Decimal("0.60"))
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
