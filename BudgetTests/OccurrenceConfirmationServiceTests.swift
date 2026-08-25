import XCTest
import SwiftData
@testable import Budget

/// W2.4b — la confirmation atomique : un geste = un mouvement lié ;
/// double tap = une écriture ; montant attendu conservé ; refus sans
/// trace.
final class OccurrenceConfirmationServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: OccurrenceConfirmationService!
    private var compte: Account!

    private let now = Date(timeIntervalSince1970: 1_781_524_800) // 15.06.2026

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        service = OccurrenceConfirmationService(calendar: calendar)
        compte = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        context.insert(compte)
    }

    override func tearDown() {
        compte = nil; service = nil; calendar = nil; context = nil; container = nil
    }

    private func echeance(_ etat: ScheduledOccurrenceState = .due,
                          attendu: Decimal? = Decimal("150.00")) -> ScheduledOccurrence {
        let o = ScheduledOccurrence(
            seriesID: UUID(), dueDate: now.addingTimeInterval(-86_400),
            expectedAmount: attendu, state: etat,
            idempotencyKey: UUID().uuidString)
        context.insert(o)
        return o
    }

    // FI-05 : 150 attendu, 97.50 payé — les deux vérités survivent.
    func testConfirmKeepsExpectedAmountBesideRealAmount() throws {
        let o = echeance()
        let mouvement = try service.confirm(
            o, amount: Decimal("97.50"), type: .expense, title: "Loyer",
            account: compte, now: now, context: context)
        XCTAssertEqual(mouvement.amount, Decimal("97.50"))
        XCTAssertEqual(mouvement.status, .posted)
        XCTAssertEqual(mouvement.recurringID, o.seriesID)
        XCTAssertEqual(o.state, .confirmed)
        XCTAssertEqual(o.matchedTransactionID, mouvement.id)
        XCTAssertEqual(o.expectedAmount, Decimal("150.00"),
                       "le montant ATTENDU survit au montant réel")
        XCTAssertEqual(o.confirmedAt, now)
    }

    // FI-04 : double tap = UNE écriture — la seconde confirmation
    // retrouve le mouvement existant.
    func testDoubleConfirmWritesExactlyOnce() throws {
        let o = echeance()
        let premier = try service.confirm(
            o, type: .expense, title: "Loyer", account: compte, now: now, context: context)
        let second = try service.confirm(
            o, type: .expense, title: "Loyer", account: compte, now: now, context: context)
        XCTAssertEqual(premier.id, second.id)
        let mouvements = try context.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(mouvements.count, 1, "jamais deux écritures pour un tap répété")
    }

    // La machine à états protège : une échéance IGNORÉE refuse la
    // confirmation directe et RIEN n'est écrit (FI-31).
    func testSkippedOccurrenceRefusesAndWritesNothing() throws {
        let o = echeance(.skipped)
        XCTAssertThrowsError(try service.confirm(
            o, type: .expense, title: "Test", account: compte, now: now, context: context)) { erreur in
            XCTAssertEqual(erreur as? OccurrenceTransitionError,
                           .forbidden(from: .skipped, to: .confirmed))
        }
        XCTAssertEqual(o.state, .skipped, "l'état n'a pas bougé")
        XCTAssertNil(o.matchedTransactionID)
        XCTAssertTrue(try context.fetch(FetchDescriptor<BudgetTransaction>()).isEmpty,
                      "aucun mouvement fantôme")
    }

    // FI-34 : sans montant attendu ni montant réel, refus nommé — jamais
    // un zéro silencieux, et l'échéance reste due.
    func testMissingAmountIsANamedErrorNeverZero() throws {
        let o = echeance(attendu: nil)
        XCTAssertThrowsError(try service.confirm(
            o, type: .expense, title: "Variable", account: compte, now: now, context: context)) { erreur in
            XCTAssertEqual(erreur as? OccurrenceConfirmationError, .montantManquant)
        }
        XCTAssertEqual(o.state, .due)
        XCTAssertTrue(try context.fetch(FetchDescriptor<BudgetTransaction>()).isEmpty)
    }

    // Le mouvement confirmé porte la date de L'ÉCHÉANCE — l'histoire
    // raconte quand l'argent devait bouger, pas quand on a tapé.
    func testMovementCarriesTheDueDate() throws {
        let o = echeance()
        let mouvement = try service.confirm(
            o, type: .expense, title: "Loyer", account: compte, now: now, context: context)
        XCTAssertEqual(mouvement.date, o.dueDate)
    }
}
