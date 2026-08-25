import XCTest
@testable import Budget

/// W2.3 — la machine à états des échéances : chemins permis, refus
/// NOMMÉS des transitions interdites, terminaux vraiment terminaux.
final class OccurrenceStateMachineTests: XCTestCase {

    private let reference = Date(timeIntervalSince1970: 1_781_524_800)

    private func occurrence(_ etat: ScheduledOccurrenceState) -> ScheduledOccurrence {
        let o = ScheduledOccurrence(
            seriesID: UUID(), dueDate: reference,
            expectedAmount: Decimal("100.00"), idempotencyKey: UUID().uuidString)
        o.stateRawValue = etat.rawValue
        return o
    }

    // Le chemin heureux d'une facture : prévue → due → confirmée,
    // avec l'horodatage de confirmation.
    func testHappyPathStampsConfirmedAt() throws {
        let o = occurrence(.scheduled)
        try o.transition(to: .due, at: reference)
        XCTAssertNil(o.confirmedAt)
        try o.transition(to: .confirmed, at: reference)
        XCTAssertEqual(o.state, .confirmed)
        XCTAssertEqual(o.confirmedAt, reference)
    }

    // « Confirmé » est TERMINAL : aucune transition n'en sort — une
    // correction passe par le journal (FI-07), jamais par un retour.
    func testConfirmedIsTerminal() {
        let o = occurrence(.confirmed)
        for cible in ScheduledOccurrenceState.allCases {
            XCTAssertThrowsError(try o.transition(to: cible, at: reference),
                "confirmé → \(cible.rawValue) doit être refusé") { erreur in
                XCTAssertEqual(erreur as? OccurrenceTransitionError,
                    .forbidden(from: .confirmed, to: cible))
            }
        }
        XCTAssertEqual(o.state, .confirmed, "l'état n'a pas bougé après les refus")
    }

    // « Annulé » est terminal aussi.
    func testCancelledIsTerminal() {
        let o = occurrence(.cancelled)
        for cible in ScheduledOccurrenceState.allCases {
            XCTAssertThrowsError(try o.transition(to: cible, at: reference))
        }
    }

    // « Ignoré » se ROUVRE (action annulable) — mais seulement vers
    // « À confirmer », jamais directement vers « Confirmé ».
    func testSkippedReopensToDueOnly() throws {
        let o = occurrence(.skipped)
        XCTAssertThrowsError(try o.transition(to: .confirmed, at: reference))
        try o.transition(to: .due, at: reference)
        XCTAssertEqual(o.state, .due)
    }

    // « Échec » se retente : échec → due → confirmé. Jamais échec →
    // confirmé direct (la confirmation doit repasser par la porte).
    func testFailedRetriesThroughDue() throws {
        let o = occurrence(.failed)
        XCTAssertThrowsError(try o.transition(to: .confirmed, at: reference))
        try o.transition(to: .due, at: reference)
        try o.transition(to: .confirmed, at: reference)
        XCTAssertEqual(o.state, .confirmed)
    }

    // Le temps ne recule pas : « À confirmer » ne redevient jamais
    // « Prévu ».
    func testDueNeverGoesBackToScheduled() {
        let o = occurrence(.due)
        XCTAssertThrowsError(try o.transition(to: .scheduled, at: reference))
    }

    // Payer en avance est permis : « Prévu » → « Confirmé » direct.
    func testEarlyConfirmationIsAllowed() throws {
        let o = occurrence(.scheduled)
        try o.transition(to: .confirmed, at: reference)
        XCTAssertEqual(o.state, .confirmed)
    }

    // La table est EXHAUSTIVE : chaque état déclare ses sorties, et
    // aucune sortie ne pointe vers soi-même (une transition change
    // toujours d'état).
    func testTransitionTableIsCoherent() {
        for etat in ScheduledOccurrenceState.allCases {
            XCTAssertFalse(etat.allowedTransitions.contains(etat),
                "\(etat.rawValue) ne transitionne pas vers lui-même")
        }
    }
}

// W2.5 — reporter/ignorer/annuler : de l'agenda, jamais de l'argent.
extension OccurrenceStateMachineTests {
    private var ref: Date { Date(timeIntervalSince1970: 1_781_524_800) }

    func testSnoozeMovesDueDateNeverTheOrigin() throws {
        let o = ScheduledOccurrence(
            seriesID: UUID(), dueDate: ref,
            expectedAmount: Decimal("25.00"), state: .due,
            idempotencyKey: "w25:1")
        let plusTard = ref.addingTimeInterval(7 * 86_400)
        try o.snooze(to: plusTard, at: ref)
        XCTAssertEqual(o.state, .snoozed)
        XCTAssertEqual(o.dueDate, plusTard)
        XCTAssertEqual(o.originalDueDate, ref, "l'origine ne bouge JAMAIS")
    }

    func testSnoozeOfConfirmedRefusesAndMovesNothing() {
        let o = ScheduledOccurrence(
            seriesID: UUID(), dueDate: ref, state: .confirmed,
            idempotencyKey: "w25:2")
        XCTAssertThrowsError(try o.snooze(to: ref.addingTimeInterval(86_400), at: ref))
        XCTAssertEqual(o.dueDate, ref, "un refus ne déplace RIEN")
    }

    func testSkipAndCancelGoThroughTheMachine() throws {
        let a = ScheduledOccurrence(seriesID: UUID(), dueDate: ref, state: .due, idempotencyKey: "w25:3")
        try a.skip(at: ref)
        XCTAssertEqual(a.state, .skipped)
        let b = ScheduledOccurrence(seriesID: UUID(), dueDate: ref, state: .scheduled, idempotencyKey: "w25:4")
        try b.cancel(at: ref)
        XCTAssertEqual(b.state, .cancelled)
        XCTAssertThrowsError(try b.skip(at: ref), "annulé est terminal")
    }
}
