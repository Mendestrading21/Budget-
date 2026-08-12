import XCTest
import SwiftData
@testable import Budget

/// Le geste dit ce qu'il fait avancer — parité avec le toast web
/// (10.08.2026). Chaque test vérifie une des règles écrites dans le
/// service : un constat vrai, un seul message, et le silence partout où
/// une annonce serait fausse ou creuse.
final class GoalProgressServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = GoalProgressService()
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var current: Account!
    private var savings: Account!

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        current = Account(name: "Courant", type: .current, openingBalance: Decimal("4000.00"))
        savings = Account(name: "Épargne", type: .savings, openingBalance: Decimal("680.00"))
        context.insert(current)
        context.insert(savings)
    }

    override func tearDown() {
        current = nil
        savings = nil
        context = nil
        container = nil
    }

    private func makeGoal(
        name: String = "Voyage",
        target: Decimal = Decimal("1000.00"),
        priority: GoalPriority = .normal,
        status: GoalStatus = .active,
        linked: Account? = nil
    ) -> FinancialGoal {
        let goal = FinancialGoal(
            name: name,
            kind: .travel,
            targetAmount: target,
            priority: priority,
            status: status,
            linkedAccount: linked ?? savings
        )
        context.insert(goal)
        return goal
    }

    /// Verse `amount` du courant vers l'épargne, comme la feuille de saisie.
    private func contribute(_ amount: Decimal, status: TransactionStatus = .posted) throws {
        let movement = BudgetTransaction(
            date: now,
            amount: amount,
            type: .saving,
            status: status,
            title: "Mise de côté",
            account: current,
            destinationAccount: savings
        )
        context.insert(movement)
        try context.save()
    }

    func testProgressIsAnnouncedWithTheGoalsOwnNumbers() throws {
        let goal = makeGoal()
        let before = service.snapshotCurrents(goals: [goal])
        try contribute(Decimal("50.00"))

        let message = service.progressMessage(destination: savings, goals: [goal], before: before)
        // 680 → 730 sur 1000 : 68 % → 73 %, aucun palier entre les deux.
        // Première version : +100, donc 68 % → 78 % — et la CI a répondu
        // « Les trois quarts sont là ». Le service avait raison : 78 %
        // FRANCHIT le palier des 75 % que l'arithmétique du test avait
        // oublié. C'est le test qui a été corrigé, jamais le service.
        XCTAssertEqual(message, "🏖️ Voyage : 68 % → 73 %")
    }

    func testCrossingAMilestoneSpeaksInWords() throws {
        let goal = makeGoal(target: Decimal("900.00"))
        let before = service.snapshotCurrents(goals: [goal])
        // 680/900 ≈ 75,6 %… déjà au-dessus de 75 : visons la fin.
        try contribute(Decimal("300.00"))

        let message = service.progressMessage(destination: savings, goals: [goal], before: before)
        XCTAssertEqual(message, "🏖️ Voyage — C'est fait — objectif atteint 🎉")
    }

    func testNothingWhenMoneyGoesElsewhere() throws {
        let goal = makeGoal()
        let before = service.snapshotCurrents(goals: [goal])
        let expense = BudgetTransaction(
            date: now,
            amount: Decimal("50.00"),
            type: .expense,
            status: .posted,
            title: "Courses",
            account: current
        )
        context.insert(expense)
        try context.save()

        XCTAssertNil(service.progressMessage(destination: nil, goals: [goal], before: before),
                     "une dépense ordinaire n'annonce aucun progrès")
        XCTAssertNil(service.progressMessage(destination: savings, goals: [goal], before: before),
                     "sans argent arrivé sur la poche, rien à annoncer")
    }

    func testPlannedMoneyStaysSilent() throws {
        let goal = makeGoal()
        let before = service.snapshotCurrents(goals: [goal])
        // Un mouvement PRÉVU ne bouge aucun solde : balance() l'exclut.
        try contribute(Decimal("100.00"), status: .planned)

        XCTAssertNil(service.progressMessage(destination: savings, goals: [goal], before: before))
    }

    func testOnlyActiveGoalsSpeak() throws {
        let paused = makeGoal(name: "En pause", status: .paused)
        let achieved = makeGoal(name: "Atteint", status: .achieved)
        let before = service.snapshotCurrents(goals: [paused, achieved])
        try contribute(Decimal("100.00"))

        XCTAssertNil(service.progressMessage(
            destination: savings, goals: [paused, achieved], before: before))
    }

    /// Plusieurs objectifs sur le MÊME compte : un seul message, et le
    /// palier franchi l'emporte sur tout le reste.
    func testSharedAccountSpeaksOnceMilestoneFirst() throws {
        // 680 + 100 = 780 : « Presque fini » (cible 750) franchit 100 %,
        // « Très loin » (cible 10000, priorité haute) ne franchit rien.
        let almost = makeGoal(name: "Presque fini", target: Decimal("750.00"))
        let far = makeGoal(name: "Très loin", target: Decimal("10000.00"), priority: .high)
        let before = service.snapshotCurrents(goals: [almost, far])
        try contribute(Decimal("100.00"))

        let message = service.progressMessage(
            destination: savings, goals: [almost, far], before: before)
        XCTAssertNotNil(message)
        XCTAssertTrue(message?.contains("Presque fini") == true,
                      "le palier franchi parle en premier (obtenu \(message ?? "nil"))")
    }

    /// Sans palier, la priorité départage — puis le plus avancé.
    func testWithoutMilestonePriorityDecides() throws {
        let normal = makeGoal(name: "Normal", target: Decimal("10000.00"))
        let urgent = makeGoal(name: "Urgent", target: Decimal("20000.00"), priority: .high)
        let before = service.snapshotCurrents(goals: [normal, urgent])
        try contribute(Decimal("100.00"))

        let message = service.progressMessage(
            destination: savings, goals: [normal, urgent], before: before)
        XCTAssertTrue(message?.contains("Urgent") == true,
                      "la priorité haute parle avant (obtenu \(message ?? "nil"))")
    }

    /// La photo « avant » est indispensable : un objectif absent de la photo
    /// ne peut pas prétendre avoir avancé.
    func testGoalMissingFromSnapshotStaysSilent() throws {
        let goal = makeGoal()
        try contribute(Decimal("100.00"))

        XCTAssertNil(service.progressMessage(destination: savings, goals: [goal], before: [:]))
    }
}
