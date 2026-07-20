import Foundation

/// « Le chemin » : projection du patrimoine à long terme — parité avec
/// le prototype web. Capitalisation mensuelle par classe à partir du
/// solde actuel et d'un versement mensuel constant. Une SIMULATION,
/// jamais une promesse : l'appelant affiche méthode et disclaimer.
struct WealthProjectionService {
    /// Hypothèses de rendement ANNUEL par classe, par profil.
    enum Profile: String, CaseIterable {
        case prudent, balanced, ambitious

        var savingsRate: Decimal {
            switch self {
            case .prudent: Decimal("0.005")
            case .balanced: Decimal("0.01")
            case .ambitious: Decimal("0.015")
            }
        }

        var brokerRate: Decimal {
            switch self {
            case .prudent: Decimal("0.02")
            case .balanced: Decimal("0.05")
            case .ambitious: Decimal("0.08")
            }
        }

        var pensionRate: Decimal {
            switch self {
            case .prudent: Decimal("0.01")
            case .balanced: Decimal("0.02")
            case .ambitious: Decimal("0.03")
            }
        }
    }

    /// Valeur future d'une classe : capitalisation mensuelle itérative en
    /// Decimal pur (règle du projet : jamais de Double pour l'argent) —
    /// chaque mois, le solde croît du taux mensuel puis reçoit le
    /// versement. Un taux nul dégénère en simple addition.
    func futureValue(
        balance: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal,
        years: Int
    ) -> Decimal {
        let months = years * 12
        guard months > 0 else { return FinanceMath.roundedToCents(balance) }
        let monthlyRate = annualRate / 12
        var value = balance
        for _ in 0..<months {
            value = value * (1 + monthlyRate) + monthlyContribution
        }
        return FinanceMath.roundedToCents(value)
    }
}
