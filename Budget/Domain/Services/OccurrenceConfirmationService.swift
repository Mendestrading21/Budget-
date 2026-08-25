import Foundation
import SwiftData

/// W2.4b — un montant manquant est une erreur nommée, jamais un zéro
/// silencieux (FI-34).
enum OccurrenceConfirmationError: Error, Equatable, LocalizedError {
    case montantManquant

    var errorDescription: String? {
        "Montant manquant : indiquez ce qui a réellement bougé."
    }
}

/// W2.4b (Budget Autonomie 100) — CONFIRMER une échéance : un seul
/// geste écrit LE mouvement lié ET fait vivre la transition, dans la
/// MÊME transaction de contexte. Idempotent : une échéance déjà
/// confirmée retrouve son mouvement — double tap = UNE écriture
/// (FI-04). Le montant RÉEL peut différer du montant ATTENDU, qui est
/// conservé (FI-05). Un refus (machine à états, montant manquant,
/// échec de save) ne laisse AUCUNE trace : le contexte revient en
/// arrière (FI-31). SHADOW : aucune vue ne l'appelle encore (ADR-058).
struct OccurrenceConfirmationService {
    let calendar: Calendar

    @discardableResult
    func confirm(
        _ occurrence: ScheduledOccurrence,
        amount: Decimal? = nil,
        type: TransactionType,
        title: String,
        account: Account?,
        destinationAccount: Account? = nil,
        category: BudgetCategory? = nil,
        now: Date,
        context: ModelContext
    ) throws -> BudgetTransaction {
        // Idempotence : déjà confirmée → retrouver le mouvement lié.
        if occurrence.state == .confirmed, let lien = occurrence.matchedTransactionID {
            let tous = try context.fetch(FetchDescriptor<BudgetTransaction>())
            if let existant = tous.first(where: { $0.id == lien }) {
                return existant
            }
        }
        guard let montantReel = amount ?? occurrence.expectedAmount,
              montantReel > 0 else {
            throw OccurrenceConfirmationError.montantManquant
        }
        // La machine à états d'abord : son refus sort AVANT toute écriture.
        try occurrence.transition(to: .confirmed, at: now)
        let mouvement = BudgetTransaction(
            date: occurrence.dueDate,
            amount: montantReel,
            type: type,
            status: .posted,
            title: title,
            recurringID: occurrence.seriesID,
            account: account,
            destinationAccount: destinationAccount,
            category: category
        )
        context.insert(mouvement)
        occurrence.matchedTransactionID = mouvement.id
        // W3.3b : l'écriture d'ombre naît dans la MÊME transaction que le
        // mouvement confirmé — le rollback l'emporte avec tout le reste.
        JournalShadowService().deposer(mouvement, now: now, context: context)
        do {
            try context.save()
        } catch {
            // Atomicité (FI-31/32) : l'échec de persistance annule TOUT
            // — la transition, le lien et l'insertion — et remonte
            // visiblement.
            context.rollback()
            throw error
        }
        return mouvement
    }
}
