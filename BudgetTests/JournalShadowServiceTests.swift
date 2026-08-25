import XCTest
import SwiftData
@testable import Budget

/// W3.3b — l'ombre NATIVE : chaque mutation entretient l'écriture du
/// mouvement dans le même save ; idempotente ; un mouvement
/// intraduisible ne casse jamais le geste (FI-34) ; la confirmation
/// d'échéance emporte son écriture dans la même transaction (FI-31).
final class JournalShadowServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: JournalShadowService!
    private var compte: Account!
    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        service = JournalShadowService()
        compte = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        context.insert(compte)
    }

    override func tearDown() {
        compte = nil; service = nil; context = nil; container = nil
    }

    private func ecritures(pour id: UUID) throws -> [JournalEntry] {
        let cle = "mouvement:\(id.uuidString)"
        return try context.fetch(FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.idempotencyKey == cle }))
    }

    // Le dépôt écrit UNE écriture équilibrée persistée, sans toucher au
    // mouvement.
    func testDeposerWritesOneBalancedPersistedEntry() throws {
        let mouvement = BudgetTransaction(
            date: now, amount: Decimal("84.30"), type: .expense,
            title: "Courses", account: compte)
        context.insert(mouvement)
        XCTAssertNil(service.deposer(mouvement, now: now, context: context))
        try context.save()
        let relues = try ecritures(pour: mouvement.id)
        XCTAssertEqual(relues.count, 1)
        XCTAssertEqual(relues.first?.postings.count, 2)
        XCTAssertEqual(relues.first?.postings.map(\.minorUnits), [8430, 8430])
        XCTAssertEqual(mouvement.amount, Decimal("84.30"), "le mouvement n'est jamais modifié")
    }

    // Redéposer est IDEMPOTENT : la modification REMPLACE — jamais deux
    // écritures pour un mouvement.
    func testDeposerReplacesOnEdit() throws {
        let mouvement = BudgetTransaction(
            date: now, amount: Decimal("84.30"), type: .expense,
            title: "Courses", account: compte)
        context.insert(mouvement)
        service.deposer(mouvement, now: now, context: context)
        try context.save()
        mouvement.amount = Decimal("99.90")
        service.deposer(mouvement, now: now, context: context)
        try context.save()
        let relues = try ecritures(pour: mouvement.id)
        XCTAssertEqual(relues.count, 1, "jamais deux écritures pour un mouvement")
        XCTAssertEqual(relues.first?.postings.map(\.minorUnits), [9990, 9990])
    }

    // L'écriture part avec le mouvement supprimé.
    func testRetirerRemovesTheEntry() throws {
        let mouvement = BudgetTransaction(
            date: now, amount: Decimal("25.00"), type: .expense,
            title: "Café", account: compte)
        context.insert(mouvement)
        service.deposer(mouvement, now: now, context: context)
        try context.save()
        service.retirer(transactionID: mouvement.id, context: context)
        context.delete(mouvement)
        try context.save()
        XCTAssertTrue(try ecritures(pour: mouvement.id).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<JournalPosting>()).isEmpty,
                      "aucun posting orphelin après le retrait")
    }

    // FI-34 : un mouvement intraduisible ne casse JAMAIS le geste — le
    // refus est retourné, le mouvement reste sauvé, aucune écriture.
    func testUntranslatableMovementNeverBreaksTheGesture() throws {
        let perdu = BudgetTransaction(
            date: now, amount: Decimal("50.00"), type: .saving,
            title: "Sans destination", account: compte)
        context.insert(perdu)
        let refus = service.deposer(perdu, now: now, context: context)
        XCTAssertNotNil(refus, "le refus est consigné, jamais silencieux")
        try context.save()
        XCTAssertTrue(try ecritures(pour: perdu.id).isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BudgetTransaction>()).count, 1,
                       "le geste de la personne survit au refus de traduction")
    }

    // FI-31 : confirmer une échéance écrit mouvement + écriture d'ombre
    // dans la MÊME transaction de contexte.
    func testConfirmationCarriesItsShadowEntry() throws {
        let calendar = Calendar(identifier: .gregorian)
        let confirmation = OccurrenceConfirmationService(calendar: calendar)
        let echeance = ScheduledOccurrence(
            seriesID: UUID(), dueDate: now.addingTimeInterval(-86_400),
            expectedAmount: Decimal("150.00"), state: .due,
            idempotencyKey: "w33b:1")
        context.insert(echeance)
        let mouvement = try confirmation.confirm(
            echeance, type: .expense, title: "Loyer",
            account: compte, now: now, context: context)
        let relues = try ecritures(pour: mouvement.id)
        XCTAssertEqual(relues.count, 1, "l'écriture d'ombre naît avec la confirmation")
        XCTAssertEqual(relues.first?.occurrenceID, nil,
                       "le lien d'échéance du journal arrive avec la bascule W3.6 — pas inventé ici")
    }
}
