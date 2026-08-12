import Foundation

/// Ce que le geste vient de faire avancer — parité avec le web (10.08.2026).
///
/// Mettre 250 CHF de côté n'est pas « Mouvement ajouté » : c'est un objectif
/// qui bouge. Ce service produit LE message à afficher après un mouvement
/// qui alimente un compte relié à un objectif, à partir d'une photo des
/// valeurs prises AVANT l'écriture.
///
/// Règles, identiques au web :
/// - un CONSTAT, jamais une félicitation creuse : les pourcentages viennent
///   de la même source que l'écran Objectifs (solde du compte relié) ;
/// - un seul palier fêté (25 / 50 / 75 / 100 %), pas de confettis à chaque
///   franc — la constitution interdit l'esthétique de casino ;
/// - rien si rien n'avance, rien si aucun objectif n'est relié ;
/// - plusieurs objectifs peuvent partager un compte : UN seul message.
///   Départage explicite — palier franchi, puis priorité, puis le plus
///   avancé.
struct GoalProgressService {
    let balanceService: AccountBalanceService

    init(balanceService: AccountBalanceService = AccountBalanceService()) {
        self.balanceService = balanceService
    }

    /// Paliers, du plus haut au plus bas : le premier franchi l'emporte.
    static let milestones: [(threshold: Double, label: String)] = [
        (1.0, "C'est fait — objectif atteint 🎉"),
        (0.75, "Les trois quarts sont là"),
        (0.5, "La moitié est atteinte"),
        (0.25, "Le premier quart est là"),
    ]

    /// Valeur courante d'un objectif — la même règle que l'écran Objectifs :
    /// le solde du compte relié fait foi, sinon la saisie manuelle.
    func currentAmount(of goal: FinancialGoal) -> Decimal {
        if let account = goal.linkedAccount {
            return balanceService.balance(of: account)
        }
        return goal.manualCurrentAmount
    }

    /// Photo des valeurs AVANT l'écriture : sans elle, impossible de dire de
    /// combien ça a bougé. À prendre juste avant d'insérer le mouvement.
    func snapshotCurrents(goals: [FinancialGoal]) -> [UUID: Decimal] {
        var currents: [UUID: Decimal] = [:]
        for goal in goals where goal.linkedAccount != nil && goal.status == .active {
            currents[goal.id] = currentAmount(of: goal)
        }
        return currents
    }

    /// Le message à afficher après l'écriture, ou nil si rien n'avance.
    /// `destination` est le compte qui a REÇU l'argent.
    func progressMessage(
        destination: Account?,
        goals: [FinancialGoal],
        before: [UUID: Decimal]
    ) -> String? {
        guard let destination else { return nil }

        struct Candidate {
            let goal: FinancialGoal
            let beforeShare: Double
            let afterShare: Double
            let milestone: String?
        }

        let candidates: [Candidate] = goals.compactMap { goal in
            // Seuls les objectifs ACTIFS parlent : un objectif en pause a
            // été mis en pause exprès, un objectif atteint a déjà eu son
            // message.
            guard goal.status == .active,
                  goal.linkedAccount?.id == destination.id,
                  goal.targetAmount > 0,
                  let beforeAmount = before[goal.id] else { return nil }
            let afterAmount = currentAmount(of: goal)
            guard afterAmount > beforeAmount else { return nil }
            // Les parts sont des Double : géométrie de seuil d'affichage,
            // jamais un montant. L'argent reste en Decimal.
            let target = NSDecimalNumber(decimal: goal.targetAmount).doubleValue
            let beforeShare = min(1, max(0, NSDecimalNumber(decimal: beforeAmount).doubleValue / target))
            let afterShare = min(1, max(0, NSDecimalNumber(decimal: afterAmount).doubleValue / target))
            let milestone = Self.milestones.first {
                afterShare >= $0.threshold && beforeShare < $0.threshold
            }?.label
            return Candidate(
                goal: goal,
                beforeShare: beforeShare,
                afterShare: afterShare,
                milestone: milestone
            )
        }
        guard !candidates.isEmpty else { return nil }

        // UN seul message. Départage : palier franchi, puis priorité (haute
        // avant normale avant basse), puis le plus avancé.
        let best = candidates.sorted { a, b in
            if (a.milestone != nil) != (b.milestone != nil) { return a.milestone != nil }
            if a.goal.priority.sortOrder != b.goal.priority.sortOrder {
                return a.goal.priority.sortOrder < b.goal.priority.sortOrder
            }
            return a.afterShare > b.afterShare
        }[0]

        let emoji = best.goal.emoji ?? best.goal.kind.defaultEmoji
        let name = "\(emoji) \(best.goal.name)"
        if let milestone = best.milestone {
            return "\(name) — \(milestone)"
        }
        let beforePct = Int((best.beforeShare * 100).rounded())
        let afterPct = Int((best.afterShare * 100).rounded())
        return "\(name) : \(beforePct) % → \(afterPct) %"
    }
}
