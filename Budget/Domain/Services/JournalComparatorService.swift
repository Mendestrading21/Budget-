import Foundation
import SwiftData

/// W3.6b (Budget Autonomie 100, ADR-058 étape 4, miroir natif du
/// comparateur W3.4) — avant toute bascule de lecture, le solde de
/// CHAQUE compte dérivé du journal doit être EXACTEMENT le solde
/// vivant (`AccountBalanceService`). L'historique non couvert est
/// complété par l'ombre (idempotent), l'ouverture devient une chaîne
/// d'écritures (FI-12). Tout mouvement resté sans écriture est un
/// écart NOMMÉ portant son refus — jamais un trou silencieux (FI-34).
/// Un compte assis sur un point de rapprochement
/// (`reconciledBalance`) est un écart CONSIGNÉ : le journal ne
/// modélise pas encore les relevés (W4).
struct JournalComparatorService {
    let balanceService: AccountBalanceService
    private let ombre = JournalShadowService()

    init(balanceService: AccountBalanceService = AccountBalanceService()) {
        self.balanceService = balanceService
    }

    /// Le solde d'un compte raconté par le JOURNAL : somme des jambes
    /// `compte:<id>` de toutes les écritures non « pending » (le prévu
    /// ne pèse sur rien, FI-01), en centimes entiers, devise du compte.
    func soldeDerive(de compte: Account, context: ModelContext) -> Decimal {
        guard let toutes = try? context.fetch(FetchDescriptor<JournalEntry>()) else { return .zero }
        let jambe = "compte:\(compte.id.uuidString)"
        var centimes: Int64 = 0
        for ecriture in toutes where ecriture.lifecycle != .pending {
            for posting in ecriture.postings where posting.accountKey == jambe {
                centimes += posting.isDebit ? posting.minorUnits : -posting.minorUnits
            }
        }
        return Money(minorUnits: centimes, currency: compte.currencyCode).decimalValue
    }

    /// Complète l'ombre (mouvements + ouvertures) puis compare CHAQUE
    /// solde. Retourne la liste des écarts — vide = le journal raconte
    /// exactement la même histoire.
    func comparer(now: Date, context: ModelContext) -> [String] {
        var ecarts: [String] = []
        let mouvements = (try? context.fetch(FetchDescriptor<BudgetTransaction>())) ?? []
        var refus: [UUID: String] = [:]
        for mouvement in mouvements
        where ombre.ecritureActive(transactionID: mouvement.id, context: context) == nil {
            if let erreur = ombre.deposer(mouvement, now: now, context: context) {
                refus[mouvement.id] = erreur
            }
        }
        let comptes = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        for compte in comptes {
            if let erreur = ombre.deposerOuverture(compte, now: now, context: context) {
                ecarts.append("ouverture \(compte.name) : \(erreur)")
            }
        }
        try? context.save()
        for mouvement in mouvements
        where ombre.ecritureActive(transactionID: mouvement.id, context: context) == nil {
            let detailRefus = refus[mouvement.id].map { " — \($0)" } ?? ""
            ecarts.append("mouvement « \(mouvement.title) » sans écriture\(detailRefus)")
        }
        for compte in comptes {
            if compte.reconciledBalance != nil {
                // FI-35/W4 : la base « point de rapprochement » n'existe
                // pas encore dans le journal — jamais deviné.
                ecarts.append("compte \(compte.name) : point de rapprochement — journal en attente des relevés (W4)")
                continue
            }
            let vivant = balanceService.balance(of: compte)
            let derive = soldeDerive(de: compte, context: context)
            if vivant != derive {
                ecarts.append("compte \(compte.name) : solde vivant \(vivant), journal \(derive)")
            }
        }
        return ecarts
    }
}

/// W3.6b — LA porte de bascule native. Allumer EXIGE le comparateur à
/// zéro écart ; éteindre est toujours permis (rollback documenté —
/// l'ancien chemin `AccountBalanceService` reste la seule lecture tant
/// qu'aucune vue n'est branchée, consigné W3.7+).
enum JournalReadSwitch {
    static let cle = "journalActifNatif"

    static func estActif(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: cle)
    }

    /// Retourne nil quand la bascule est acceptée, sinon le refus
    /// nommé — et le drapeau ne bouge pas.
    static func activer(
        now: Date,
        context: ModelContext,
        defaults: UserDefaults = .standard,
        comparateur: JournalComparatorService = JournalComparatorService()
    ) -> String? {
        let ecarts = comparateur.comparer(now: now, context: context)
        guard ecarts.isEmpty else {
            return "Bascule refusée — le journal ne raconte pas encore la même histoire : "
                + ecarts.joined(separator: " ; ")
        }
        defaults.set(true, forKey: cle)
        return nil
    }

    static func desactiver(defaults: UserDefaults = .standard) {
        defaults.set(false, forKey: cle)
    }
}
