import XCTest
import SwiftData
@testable import Budget

/// W6.5 — miroir natif : « un objectif avance par affectation réelle ou
/// valeur manuelle explicitement DATÉE, jamais par projection seule »
/// (DATA_MODEL_TARGET). La date est additive (`manualCurrentDate`),
/// `nil` pour l'existant — jamais une date inventée ; un objectif lié
/// n'en porte pas, son solde fait foi.
final class GoalDatedManualValueTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: GoalProgressService!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        service = GoalProgressService()
    }

    override func tearDown() {
        service = nil; context = nil; container = nil
    }

    // Une valeur manuelle datée garde sa date à travers le store.
    func testManualDateSurvivesRoundtrip() throws {
        let date = Date(timeIntervalSince1970: 1_787_500_800)
        let goal = FinancialGoal(
            name: "Vélo", kind: .custom, targetAmount: 3000,
            manualCurrentAmount: 1500, manualCurrentDate: date
        )
        context.insert(goal)
        try context.save()
        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<FinancialGoal>()).first)
        XCTAssertEqual(fetched.manualCurrentDate, date)
        XCTAssertEqual(service.currentProvenance(of: fetched), .manualDated(date))
    }

    // L'existant reste NON daté — le service le dit, il n'invente rien.
    func testLegacyGoalStaysUndated() throws {
        let goal = FinancialGoal(name: "Fonds", kind: .emergency, targetAmount: 10000,
                                 manualCurrentAmount: 1200)
        context.insert(goal)
        XCTAssertNil(goal.manualCurrentDate)
        XCTAssertEqual(service.currentProvenance(of: goal), .manualUndated)
    }

    // Un objectif LIÉ : le solde fait foi — provenance nommée, valeur
    // dérivée du compte, jamais de la saisie manuelle.
    func testLinkedGoalReadsBalanceNotManual() throws {
        let account = Account(name: "Épargne", type: .savings, openingBalance: 4000)
        context.insert(account)
        let goal = FinancialGoal(
            name: "Coussin", kind: .emergency, targetAmount: 10000,
            manualCurrentAmount: 999, linkedAccount: account
        )
        context.insert(goal)
        XCTAssertEqual(service.currentAmount(of: goal), 4000,
                       "le solde du compte relié fait foi, jamais la saisie")
        XCTAssertEqual(service.currentProvenance(of: goal),
                       .linkedBalance(accountName: "Épargne"))
    }
}
