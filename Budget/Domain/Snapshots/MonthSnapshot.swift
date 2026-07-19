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

    let taxProvision: TaxProvisionSummary

    /// Sum of balances of accounts included in net worth (signed
    /// convention: debt balances are negative).
    let netWorth: Decimal

    let previousMonth: MonthComparison?
}

/// The "truly available" amount with its full, visible decomposition:
/// total = liquidBalance + expectedIncome − committedCharges − taxReserveGap.
struct AvailableBreakdown: Equatable {
    /// Current balance of accounts flagged include-in-available-cash.
    let liquidBalance: Decimal
    /// Planned income still expected during this month.
    let expectedIncome: Decimal
    /// Planned outflows of the month not yet posted (expenses, savings,
    /// investments, taxes, debt payments) — committed goal contributions
    /// join in Phase 8.
    let committedCharges: Decimal
    /// Recommended tax reserve for the month's income not yet covered.
    let taxReserveGap: Decimal

    var total: Decimal {
        liquidBalance + expectedIncome - committedCharges - taxReserveGap
    }
}

/// Monthly view of the tax provision. Until the dedicated tax module
/// (Phase 7) tracks reserved cash separately, posted tax payments are the
/// only recognized cover.
struct TaxProvisionSummary: Equatable {
    /// Configured household rate (fraction).
    let rate: Decimal
    /// income × rate for this month.
    let recommended: Decimal
    /// Posted tax payments of the month.
    let paid: Decimal

    var gap: Decimal { max(.zero, recommended - paid) }
}

struct MonthComparison: Equatable {
    let incomeDelta: Decimal
    let livingExpensesDelta: Decimal
    let cashFlowDelta: Decimal
}
