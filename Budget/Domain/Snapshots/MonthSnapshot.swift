import Foundation

/// Derived, non-persisted aggregation of one month. Every value comes from
/// persisted data through MonthlySnapshotService — nothing here is stored.
struct MonthSnapshot: Equatable {
    let interval: MonthInterval

    // Actuals (posted only)
    let totalIncome: Decimal
    /// Consumption expenses minus received refunds. Excludes savings,
    /// investments, taxes, debt payments and internal transfers.
    let totalLivingExpenses: Decimal
    let totalSavings: Decimal
    let totalInvestments: Decimal
    let totalTaxPayments: Decimal
    let totalDebtPayments: Decimal

    // Planned (separate from actuals, never mixed)
    let plannedIncome: Decimal
    let plannedOutflows: Decimal

    /// (savings + investments) / income — zero when income is zero.
    let savingsRate: Decimal
    /// Income minus every posted non-transfer outflow of the month.
    let cashFlow: Decimal

    let available: AvailableBreakdown
    let daysRemaining: Int
    let dailyAvailableBudget: Decimal

    /// Sum of balances of accounts included in net worth (signed
    /// convention: debt balances are negative). FE2 : ce n'est PAS la
    /// fortune totale — biens, prévoyance manuelle et dettes hors comptes
    /// vivent dans NetWorthService, l'unique source du patrimoine. Aucun
    /// écran ne doit présenter ce champ comme « fortune ».
    let netWorth: Decimal

    let previousMonth: MonthComparison?
}

/// The end-of-month projection with its full, visible decomposition:
/// total = liquidBalance + expectedIncome + recurringIncome
///         − committedCharges − recurringCharges.
/// ADR-035 : plus AUCUN terme fiscal automatique — un acompte pèse par sa
/// facture ou son mouvement prévu, comme n'importe quelle sortie saisie.
struct AvailableBreakdown: Equatable {
    /// Current balance of accounts flagged include-in-available-cash.
    let liquidBalance: Decimal
    /// Planned income still expected during this month.
    let expectedIncome: Decimal
    /// Planned outflows of the month not yet posted (expenses, savings,
    /// investments, taxes, debt payments) — committed goal contributions
    /// join in Phase 8.
    let committedCharges: Decimal
    /// Recurring income occurrences of the month not yet materialized
    /// (e.g. the salary that has not landed yet).
    let recurringIncome: Decimal
    /// Recurring charge occurrences of the month not yet materialized —
    /// every active recurring charge appears in the forecast exactly once.
    let recurringCharges: Decimal

    var total: Decimal {
        liquidBalance + expectedIncome + recurringIncome
            - committedCharges - recurringCharges
    }
}

struct MonthComparison: Equatable {
    let incomeDelta: Decimal
    let livingExpensesDelta: Decimal
    let cashFlowDelta: Decimal
}
