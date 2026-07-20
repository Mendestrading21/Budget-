import Foundation

/// Cumuls de versements « façon Finary » pour un compte de placement :
/// tout ce qui y a été versé s'additionne — total depuis toujours,
/// année en cours, retraits. Pur : aucune persistance, aucune horloge.
struct ContributionSummary: Equatable {
    /// Somme des versements comptabilisés reçus par le compte.
    let total: Decimal
    /// Part des versements datés de l'année de `now`.
    let currentYear: Decimal
    /// Argent sorti du compte (hors ajustements de valeur).
    let withdrawn: Decimal

    var net: Decimal { total - withdrawn }
}

struct ContributionService {
    let calendar: Calendar

    /// Natures de compte où « chaque versement s'additionne ».
    static func tracksContributions(_ type: AccountType) -> Bool {
        switch type {
        case .savings, .broker, .pillar3a, .pillar3b, .occupationalPension: true
        default: false
        }
    }

    func summary(of account: Account, movements: [BudgetTransaction], now: Date) -> ContributionSummary {
        let year = calendar.component(.year, from: now)
        var total: Decimal = .zero
        var currentYear: Decimal = .zero
        var withdrawn: Decimal = .zero
        for movement in movements where movement.status == .posted {
            if movement.destinationAccount?.id == account.id {
                total += movement.amount
                if calendar.component(.year, from: movement.date) == year {
                    currentYear += movement.amount
                }
            }
            if movement.account?.id == account.id {
                switch movement.type {
                case .expense, .saving, .investment, .transfer, .taxPayment, .debtPayment:
                    withdrawn += movement.amount
                case .income, .refund, .adjustment:
                    // Entrées et corrections de valeur : pas des retraits.
                    break
                }
            }
        }
        return ContributionSummary(total: total, currentYear: currentYear, withdrawn: withdrawn)
    }

    /// Plus-value d'un compte titres : valeur actuelle − ouverture −
    /// versements nets. Honnête seulement si la valeur est tenue à jour
    /// (réconciliation) — l'appelant l'affiche avec sa méthode.
    func performance(balance: Decimal, openingBalance: Decimal, summary: ContributionSummary) -> Decimal {
        balance - openingBalance - summary.net
    }
}
