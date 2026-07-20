import Foundation

/// « Année en revue » : agrégats annuels dérivés des mouvements
/// comptabilisés — mêmes conventions que le snapshot mensuel (les
/// remboursements réduisent le coût de la vie, les envois vers les
/// placements ne sont jamais des dépenses).
struct YearStats: Equatable {
    let income: Decimal
    let livingExpenses: Decimal
    let saved: Decimal
    let taxesPaid: Decimal

    /// Part des revenus mise de côté (épargne + investissements).
    var savingsRate: Decimal {
        FinanceMath.safeRatio(saved, income)
    }
}

struct YearStatsService {
    let calendar: Calendar

    func stats(year: Int, transactions: [BudgetTransaction]) -> YearStats {
        let posted = transactions.filter {
            $0.status == .posted && calendar.component(.year, from: $0.date) == year
        }
        func sum(_ types: Set<TransactionType>) -> Decimal {
            posted.filter { types.contains($0.type) }.reduce(.zero) { $0 + $1.amount }
        }
        return YearStats(
            income: sum([.income, .refund]),
            livingExpenses: sum([.expense]) - sum([.refund]),
            saved: sum([.saving, .investment]),
            taxesPaid: sum([.taxPayment])
        )
    }
}
