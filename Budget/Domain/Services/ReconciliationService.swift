import Foundation
import SwiftData

/// W4.4b (Budget Autonomie 100) — réconcilier passe par UNE porte qui
/// fait les TROIS gestes ensemble, dans le même save de l'appelant :
/// 1. le point du compte (`reconciledBalance`/`reconciledAt`) — le
///    comportement historique que `balance()` continue de lire ;
/// 2. le RELEVÉ daté (W4.3) — la preuve, source « réconciliation
///    manuelle » ;
/// 3. le FIGEAGE du journal (W4.4, FI-06/07) — les écritures postées du
///    compte jusqu'à la date deviennent « reconciled » ; le prévu et
///    les autres comptes ne bougent jamais.
/// Ne sauvegarde jamais elle-même : l'atomicité est celle de
/// l'appelant (`saveOrRollback`).
struct ReconciliationService {
    @discardableResult
    func reconcilier(
        compte: Account,
        soldeConstate: Decimal,
        now: Date,
        context: ModelContext
    ) -> Statement {
        compte.reconciledBalance = soldeConstate
        compte.reconciledAt = now
        compte.updatedAt = now
        let releve = Statement(
            accountID: compte.id,
            periodEnd: now,
            closingBalance: soldeConstate,
            state: .reconciled,
            source: "réconciliation manuelle",
            reconciledAt: now,
            createdAt: now
        )
        context.insert(releve)
        figerJournal(compteID: compte.id, jusquA: now, context: context)
        return releve
    }

    /// FI-06 : l'histoire confirmée par le solde constaté est FIGÉE.
    /// Les conditions vérifient la légalité AVANT chaque transition —
    /// la machine ne peut pas refuser ici.
    private func figerJournal(compteID: UUID, jusquA date: Date, context: ModelContext) {
        let jambe = "compte:\(compteID.uuidString)"
        let entrees = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        for entree in entrees
        where (entree.lifecycle == .posted || entree.lifecycle == .cleared)
            && entree.effectiveDate <= date
            && entree.postings.contains(where: { $0.accountKey == jambe }) {
            try? entree.avancerCycle(vers: .reconciled)
        }
    }
}
