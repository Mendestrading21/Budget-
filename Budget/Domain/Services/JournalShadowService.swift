import Foundation
import SwiftData

/// W3.3b (Budget Autonomie 100, ADR-058 étape 3) — l'ombre NATIVE du
/// journal : chaque mutation réelle d'un mouvement entretient AUSSI son
/// écriture, dans le MÊME `save` que le geste (FI-31 — l'atomicité est
/// celle de l'appelant : `saveOrRollback`/`rollback` emportent l'ombre
/// avec le mouvement). Un mouvement intraduisible ne casse JAMAIS le
/// geste de la personne : le refus est RETOURNÉ (consigné par les tests
/// et le comparateur W3.4), jamais une exception qui perdrait la saisie
/// (FI-34). Le journal reste une ombre : aucune vue ne le lit avant la
/// bascule prouvée (W3.6).
struct JournalShadowService {
    private let translator = JournalTranslationService()

    /// Dépose (ou REMPLACE — idempotent) l'écriture d'ombre d'un
    /// mouvement. Retourne nil quand l'écriture est déposée, sinon le
    /// refus nommé en français. Ne sauvegarde jamais elle-même.
    @discardableResult
    func deposer(_ transaction: BudgetTransaction, now: Date, context: ModelContext) -> String? {
        retirer(transactionID: transaction.id, context: context)
        do {
            let ecriture = try translator.entry(from: transaction, now: now)
            context.insert(ecriture)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// Retire l'écriture d'ombre d'un mouvement supprimé — l'écriture
    /// part avec le mouvement, jamais un lien pendu. Si la lecture
    /// échouait, le dépôt suivant heurterait la clé UNIQUE au `save`
    /// et l'échec resterait VISIBLE (FI-32).
    func retirer(transactionID: UUID, context: ModelContext) {
        let cle = "mouvement:\(transactionID.uuidString)"
        let descripteur = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.idempotencyKey == cle })
        if let existantes = try? context.fetch(descripteur) {
            for ecriture in existantes { context.delete(ecriture) }
        }
    }
}
