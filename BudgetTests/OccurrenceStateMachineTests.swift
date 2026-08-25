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
