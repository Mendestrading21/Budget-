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
    /// convention: debt balances are negative). FE2 : ce n'est PAS la
    /// fortune totale — biens, prévoyance manuelle et dettes hors comptes
    /// vivent dans NetWorthService, l'unique source du patrimoine. Aucun
    /// écran ne doit présenter ce champ comme « fortune ».
    let netWorth: Decimal

    let previousMonth: MonthComparison?
}

/// The end-of-month projection with its full, visible decomposition:
/// total = liquidBalance + expectedIncome + recurringIncome
///         − committedCharges − recurringCharges − taxMonthlyEffort.
/// FE2 : l'écart fiscal ANNUEL (`taxReserveGap`) reste exposé pour
/// l'écran Impôts, mais seul l'effort DU MOIS pèse sur la projection.
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
    /// Remaining recommended reserve for the selected calendar year, after
    /// posted tax payments and cash explicitly reserved by the user.
    /// FE2 : information annuelle — n'entre PLUS dans le total.
    let taxReserveGap: Decimal
    /// FE2 : l'effort d'impôts DU MOIS — taux × revenus du mois
    /// (comptabilisés + attendus), moins ce qui est déjà mis ou engagé de
    /// côté pour les impôts ce mois, plafonné par l'écart annuel anticipé.
    let taxMonthlyEffort: Decimal

    var total: Decimal {
        liquidBalance + expectedIncome + recurringIncome
            - committedCharges - recurringCharges - taxMonthlyEffort
    }
}

/// Tax provision for the calendar year containing the selected month.
/// Every value comes from TaxService.report — the SAME truth as the Impôts
/// module (annual income, payments, reserve, override and arrears).
struct TaxProvisionSummary: Equatable {
    /// Configured household rate (fraction).
    let rate: Decimal
    /// Estimated tax for the year (or the user's annual override).
    let recommended: Decimal
    /// Posted tax payments of the year.
    let paid: Decimal
    /// Annual cash reserved in the Impôts module, counted as cover.
    let reserved: Decimal
    /// User-entered arrears from previous years, still due.
    let arrears: Decimal
    /// TaxYearReport.reserveGap (outstanding + arrears − reserved, floor 0).
    let gap: Decimal
}

struct MonthComparison: Equatable {
    let incomeDelta: Decimal
    let livingExpensesDelta: Decimal
    let cashFlowDelta: Decimal
}
