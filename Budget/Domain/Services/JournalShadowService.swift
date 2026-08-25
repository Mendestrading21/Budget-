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
///
/// W3.5b (FI-07) — corriger n'est JAMAIS réécrire : un POSTÉ corrigé
/// garde son originale INTACTE, gagne une inversion liée
/// (`reversesEntryID`, jambes inversées, clé `inversion:<id>`) puis une
/// remplaçante liée (`replacesEntryID`, clé `mouvement:<id>:r<n>`) ; un
/// PRÉVU corrigé se remplace en place (un plan n'est pas de
/// l'histoire) ; supprimer un POSTÉ pousse l'inversion tracée,
/// supprimer un PRÉVU l'efface.
struct JournalShadowService {
    private let translator = JournalTranslationService()

    /// La tête de chaîne d'une lignée (`<exacte>` ou `<exacte>:r<n>`) :
    /// la seule écriture qu'aucune inversion ne vise.
    func ecritureActive(cle exacte: String, context: ModelContext) -> JournalEntry? {
        guard let toutes = try? context.fetch(FetchDescriptor<JournalEntry>()) else { return nil }
        let inversees = Set(toutes.compactMap(\.reversesEntryID))
        let prefixe = exacte + ":r"
        return toutes.first { entry in
            !inversees.contains(entry.id)
                && (entry.idempotencyKey == exacte || entry.idempotencyKey.hasPrefix(prefixe))
        }
    }

    func ecritureActive(transactionID: UUID, context: ModelContext) -> JournalEntry? {
        ecritureActive(cle: "mouvement:\(transactionID.uuidString)", context: context)
    }

    /// W3.6b (FI-12 + FI-07) : l'ouverture d'un compte vit dans le
    /// journal comme une CHAÎNE corrigeable — éditer le solde
    /// d'ouverture inverse l'ancienne écriture et en lie une nouvelle ;
    /// le remettre à zéro laisse l'inversion tracée. Idempotent : la
    /// même photo est un no-op. Retourne nil quand l'ombre est à jour,
    /// sinon le refus nommé.
    @discardableResult
    func deposerOuverture(_ compte: Account, now: Date, context: ModelContext) -> String? {
        let nouvelle: JournalEntry?
        do {
            nouvelle = try translator.openingEntry(for: compte, now: now)
        } catch {
            return error.localizedDescription
        }
        let active = ecritureActive(cle: "ouverture:\(compte.id.uuidString)", context: context)
        guard let active else {
            if let nouvelle { context.insert(nouvelle) }
            return nil
        }
        if let nouvelle, memePhoto(active, nouvelle) { return nil }
        context.insert(inversion(de: active, now: now))
        guard let nouvelle else { return nil } // remise à zéro : la trace suffit
        let revision: Int
        if let marque = active.idempotencyKey.range(of: ":r", options: .backwards),
           let numero = Int(active.idempotencyKey[marque.upperBound...]) {
            revision = numero + 1
        } else {
            revision = 2
        }
        nouvelle.idempotencyKey = "ouverture:\(compte.id.uuidString):r\(revision)"
        nouvelle.replacesEntryID = active.id
        context.insert(nouvelle)
        return nil
    }

    /// Deux écritures racontent-elles la MÊME chose ? (idempotence du
    /// dépôt — les jambes se comparent en multiensemble, l'ordre d'une
    /// relation SwiftData n'étant pas un contrat.)
    private func memePhoto(_ a: JournalEntry, _ b: JournalEntry) -> Bool {
        func cle(_ p: JournalPosting) -> String {
            "\(p.accountKey)|\(p.isDebit)|\(p.minorUnits)|\(p.currency)"
        }
        // W4.4b : une écriture dont le CYCLE a avancé (cleared/
        // reconciled) reste la même photo qu'une traduction fraîche
        // « posted » — l'avancée du cycle n'est pas une différence de
        // contenu.
        let cycleCompatible = a.lifecycleRawValue == b.lifecycleRawValue
            || ((a.lifecycle == .cleared || a.lifecycle == .reconciled)
                && (b.lifecycle == .posted || b.lifecycle == .cleared))
        return a.kindRawValue == b.kindRawValue
            && cycleCompatible
            && a.effectiveDate == b.effectiveDate
            && a.title == b.title
            && a.postings.map(cle).sorted() == b.postings.map(cle).sorted()
    }

    /// L'inversion LIÉE d'une écriture : mêmes jambes, sens inversés,
    /// datée du jour de la correction — l'originale ne bouge jamais.
    /// Idempotente : une écriture n'a qu'une inversion (clé unique).
    private func inversion(de ecriture: JournalEntry, now: Date) -> JournalEntry {
        JournalEntry(
            kind: ecriture.kind,
            lifecycle: .posted,
            effectiveDate: now,
            title: "Annulation \(ecriture.title)",
            idempotencyKey: "inversion:\(ecriture.id.uuidString)",
            reversesEntryID: ecriture.id,
            postings: ecriture.postings.map { JournalPosting(
                accountKey: $0.accountKey,
                isDebit: !$0.isDebit,
                minorUnits: $0.minorUnits,
                currency: $0.currency,
                categoryID: $0.categoryID
            ) },
            createdAt: now,
            updatedAt: now
        )
    }

    /// Dépose l'écriture d'un mouvement — ou fait MÛRIR sa chaîne
    /// (FI-07) quand une écriture active existe déjà. Retourne nil
    /// quand l'ombre est à jour, sinon le refus nommé en français.
    /// Ne sauvegarde jamais elle-même.
    @discardableResult
    func deposer(_ transaction: BudgetTransaction, now: Date, context: ModelContext) -> String? {
        let nouvelle: JournalEntry
        do {
            nouvelle = try translator.entry(from: transaction, now: now)
        } catch {
            return error.localizedDescription
        }
        guard let active = ecritureActive(transactionID: transaction.id, context: context) else {
            context.insert(nouvelle)
            return nil
        }
        if memePhoto(active, nouvelle) { return nil } // rien n'a changé
        if active.lifecycle == .pending {
            // Un plan corrigé se remplace en place — même clé, pas d'inversion.
            nouvelle.idempotencyKey = active.idempotencyKey
            context.delete(active)
            context.insert(nouvelle)
            return nil
        }
        // FI-07 : inversion liée PUIS remplaçante liée — chaîne lisible,
        // l'originale intacte.
        context.insert(inversion(de: active, now: now))
        let revision: Int
        if let marque = active.idempotencyKey.range(of: ":r", options: .backwards),
           let numero = Int(active.idempotencyKey[marque.upperBound...]) {
            revision = numero + 1
        } else {
            revision = 2
        }
        nouvelle.idempotencyKey = "mouvement:\(transaction.id.uuidString):r\(revision)"
        nouvelle.replacesEntryID = active.id
        context.insert(nouvelle)
        return nil
    }

    /// Retire l'ombre d'un mouvement supprimé : un PRÉVU s'efface, un
    /// POSTÉ laisse son inversion tracée — le journal raconte
    /// l'aller-retour net (FI-07), jamais un trou.
    func retirer(transactionID: UUID, context: ModelContext) {
        guard let active = ecritureActive(transactionID: transactionID, context: context) else { return }
        if active.lifecycle == .pending {
            context.delete(active)
            return
        }
        context.insert(inversion(de: active, now: Date()))
    }
}
