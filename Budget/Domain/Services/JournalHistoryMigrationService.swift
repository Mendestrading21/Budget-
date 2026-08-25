import Foundation
import SwiftData

/// W3.7 (Budget Autonomie 100, ADR-064 — décision propriétaire du
/// 25.08.2026 : « préparer sans allumer ») : la MIGRATION de
/// l'historique vers le journal. L'essai à blanc RACONTE — créés,
/// refus nommés, écarts prévus — sans RIEN insérer (les brouillons ne
/// touchent jamais le contexte). La migration réelle n'applique que si
/// TOUT est propre (zéro refus, zéro écart) : sinon rien ne change
/// (atomique, FI-31). Elle n'allume JAMAIS la lecture des soldes
/// (`JournalReadSwitch`) : l'allumage attend W4 et une décision
/// propriétaire distincte. Rollback : le journal est additif — les
/// écritures se suppriment sans toucher un seul mouvement.
struct RapportMigrationJournal: Equatable {
    let essai: Bool
    let creees: Int
    let refus: [String]
    let ecarts: [String]
    let applique: Bool
}

struct JournalHistoryMigrationService {
    private let translator = JournalTranslationService()
    private let ombre = JournalShadowService()
    private let comparateur: JournalComparatorService
    private let balanceService: AccountBalanceService

    init(balanceService: AccountBalanceService = AccountBalanceService()) {
        self.balanceService = balanceService
        self.comparateur = JournalComparatorService(balanceService: balanceService)
    }

    func migrer(essai: Bool, now: Date, context: ModelContext) -> RapportMigrationJournal {
        let mouvements = (try? context.fetch(FetchDescriptor<BudgetTransaction>())) ?? []
        let comptes = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        var refus: [String] = []
        var brouillons: [JournalEntry] = []

        for mouvement in mouvements
        where ombre.ecritureActive(transactionID: mouvement.id, context: context) == nil {
            do {
                brouillons.append(try translator.entry(from: mouvement, now: now))
            } catch {
                refus.append("mouvement « \(mouvement.title) » : \(error.localizedDescription)")
            }
        }
        for compte in comptes
        where ombre.ecritureActive(cle: "ouverture:\(compte.id.uuidString)", context: context) == nil {
            do {
                if let ouverture = try translator.openingEntry(for: compte, now: now) {
                    brouillons.append(ouverture)
                }
            } catch {
                refus.append("ouverture \(compte.name) : \(error.localizedDescription)")
            }
        }

        // Les écarts se PRÉVOIENT sans insérer : solde déjà dérivé +
        // jambes des brouillons, contre le solde vivant.
        var ecarts: [String] = []
        for compte in comptes {
            if compte.reconciledBalance != nil {
                ecarts.append("compte \(compte.name) : point de rapprochement — journal en attente des relevés (W4)")
                continue
            }
            let jambe = "compte:\(compte.id.uuidString)"
            var centimes: Int64 = 0
            for brouillon in brouillons where brouillon.lifecycle != .pending {
                for posting in brouillon.postings where posting.accountKey == jambe {
                    centimes += posting.isDebit ? posting.minorUnits : -posting.minorUnits
                }
            }
            let derive = comparateur.soldeDerive(de: compte, context: context)
                + Money(minorUnits: centimes, currency: compte.currencyCode).decimalValue
            let vivant = balanceService.balance(of: compte)
            if derive != vivant {
                ecarts.append("compte \(compte.name) : solde vivant \(vivant), journal prévu \(derive)")
            }
        }

        if essai || !refus.isEmpty || !ecarts.isEmpty {
            // Essai à blanc OU migration refusée : les brouillons n'ont
            // JAMAIS touché le contexte — rien à défaire.
            return RapportMigrationJournal(
                essai: essai, creees: brouillons.count, refus: refus,
                ecarts: ecarts, applique: false)
        }
        for brouillon in brouillons { context.insert(brouillon) }
        do {
            try context.save()
        } catch {
            context.rollback()
            return RapportMigrationJournal(
                essai: essai, creees: brouillons.count,
                refus: refus + ["enregistrement refusé : \(error.localizedDescription)"],
                ecarts: ecarts, applique: false)
        }
        return RapportMigrationJournal(
            essai: essai, creees: brouillons.count, refus: refus,
            ecarts: ecarts, applique: true)
    }
}
