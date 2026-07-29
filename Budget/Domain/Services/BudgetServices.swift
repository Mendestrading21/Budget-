import Foundation
import SwiftData

// MARK: - Reports (derived, never persisted)

/// Planned vs actual for one budget line. `variance = planned − actual`:
/// positive means room left, negative means overrun.
struct BudgetLineReport: Identifiable, Equatable {
    let id: UUID
    let categoryID: UUID?
    let categoryName: String
    let categoryKind: CategoryKind
    let isEssential: Bool
    let planned: Decimal
    let actual: Decimal

    var variance: Decimal { planned - actual }
    var isOverrun: Bool { actual > planned }
    /// Consumed fraction clamped to [0, 1] for progress bars (a net-refund
    /// month floors at 0); overrun is signalled separately (never by color
    /// alone).
    var consumedFraction: Decimal {
        guard planned > 0 else { return actual > 0 ? Decimal(1) : .zero }
        return max(.zero, min(Decimal(1), FinanceMath.safeRatio(actual, planned)))
    }
}

/// Full reconciliation of one month: every posted franc of the month is
/// either matched to a budget line or listed in `outOfBudget`.
struct BudgetReport: Equatable {
    let interval: MonthInterval
    let lineReports: [BudgetLineReport]
    /// Actual amounts of categories (or missing categories) without a
    /// budget line, keyed for display.
    let outOfBudget: [OutOfBudgetEntry]

    struct OutOfBudgetEntry: Identifiable, Equatable {
        /// Stable across report rebuilds: category UUID or "uncategorized".
        let id: String
        let categoryName: String
        let categoryKind: CategoryKind
        let actual: Decimal
    }

    var totalPlanned: Decimal { lineReports.reduce(.zero) { $0 + $1.planned } }
    var totalActualInLines: Decimal { lineReports.reduce(.zero) { $0 + $1.actual } }
    var totalOutOfBudget: Decimal { outOfBudget.reduce(.zero) { $0 + $1.actual } }
    var totalVariance: Decimal { totalPlanned - totalActualInLines }

    /// "Remaining to spend" totals: income lines are informative but must
    /// not inflate the spending envelope.
    var spendingPlanned: Decimal {
        lineReports.filter { $0.categoryKind != .income }.reduce(.zero) { $0 + $1.planned }
    }
    var spendingActual: Decimal {
        lineReports.filter { $0.categoryKind != .income }.reduce(.zero) { $0 + $1.actual }
    }
    var spendingVariance: Decimal { spendingPlanned - spendingActual }

    func totalPlanned(kind: CategoryKind) -> Decimal {
        lineReports.filter { $0.categoryKind == kind }.reduce(.zero) { $0 + $1.planned }
    }

    func totalActual(kind: CategoryKind) -> Decimal {
        lineReports.filter { $0.categoryKind == kind }.reduce(.zero) { $0 + $1.actual }
    }
}

// MARK: - Variance service

/// Pure planned-vs-actual arithmetic. Actual amounts come only from
/// POSTED transactions of the month; planned movements and internal
/// transfers never enter a budget.
struct BudgetVarianceService {
    let calendar: Calendar

    /// Transaction types whose amounts feed a category of the given kind.
    private func matchingTypes(for kind: CategoryKind) -> Set<TransactionType> {
        switch kind {
        case .income: [.income]
        case .expense: [.expense, .debtPayment]
        case .saving: [.saving]
        case .investment: [.investment]
        case .tax: [.taxPayment]
        }
    }

    /// Actual amount of one category over an interval. For expense
    /// categories, refunds linked to the category reduce the actual.
    func actualAmount(
        categoryID: UUID,
        kind: CategoryKind,
        interval: MonthInterval,
        transactions: [BudgetTransaction]
    ) -> Decimal {
        let types = matchingTypes(for: kind)
        var total: Decimal = .zero
        for transaction in transactions {
            guard transaction.status == .posted,
                  interval.contains(transaction.date),
                  transaction.category?.id == categoryID else { continue }
            if types.contains(transaction.type) {
                total += transaction.amount
            } else if transaction.type == .refund {
                // A refund always reduces its category, whatever the kind —
                // otherwise the franc would silently vanish from the report.
                total -= transaction.amount
            }
        }
        return total
    }

    /// Builds the month's reconciliation: one report per budget line, plus
    /// every out-of-budget actual so nothing is silently dropped.
    func report(
        budget: MonthlyBudget?,
        monthOf anchor: Date,
        transactions: [BudgetTransaction]
    ) -> BudgetReport {
        let interval = MonthInterval(containing: anchor, calendar: calendar)
        let lines = budget?.lines ?? []

        let lineReports: [BudgetLineReport] = lines.compactMap { line in
            guard let category = line.category else { return nil }
            return BudgetLineReport(
                id: line.id,
                categoryID: category.id,
                categoryName: category.name,
                categoryKind: category.kind,
                isEssential: category.isEssential,
                planned: line.plannedAmount,
                actual: actualAmount(
                    categoryID: category.id,
                    kind: category.kind,
                    interval: interval,
                    transactions: transactions
                )
            )
        }
        .sorted { lhs, rhs in
            if lhs.categoryKind != rhs.categoryKind {
                return kindOrder(lhs.categoryKind) < kindOrder(rhs.categoryKind)
            }
            return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending
        }

        let budgetedCategoryIDs = Set(lineReports.compactMap(\.categoryID))

        // Aggregate the month's posted spending-side movements that are
        // NOT covered by a line. Transfers and adjustments never belong to
        // a budget; income without a line is not "out-of-budget spending";
        // refunds follow their category.
        var uncovered: [UUID?: (name: String, kind: CategoryKind, total: Decimal)] = [:]
        for transaction in transactions {
            guard transaction.status == .posted, interval.contains(transaction.date) else { continue }
            guard transaction.type != .transfer,
                  transaction.type != .adjustment,
                  transaction.type != .income else { continue }
            let categoryID = transaction.category?.id
            if let categoryID, budgetedCategoryIDs.contains(categoryID) { continue }

            let kind = transaction.category?.kind ?? fallbackKind(for: transaction.type)
            let signedAmount = transaction.type == .refund ? -transaction.amount : transaction.amount
            let name = transaction.category?.name ?? "Sans catégorie"
            var entry = uncovered[categoryID] ?? (name, kind, .zero)
            entry.total += signedAmount
            uncovered[categoryID] = entry
        }

        let outOfBudget = uncovered
            .map { key, value in
                BudgetReport.OutOfBudgetEntry(
                    id: key?.uuidString ?? "uncategorized",
                    categoryName: value.name,
                    categoryKind: value.kind,
                    actual: value.total
                )
            }
            .filter { $0.actual != .zero }
            .sorted { $0.actual > $1.actual }

        return BudgetReport(interval: interval, lineReports: lineReports, outOfBudget: outOfBudget)
    }

    private func kindOrder(_ kind: CategoryKind) -> Int {
        switch kind {
        case .income: 0
        case .expense: 1
        case .saving: 2
        case .investment: 3
        case .tax: 4
        }
    }

    private func fallbackKind(for type: TransactionType) -> CategoryKind {
        switch type {
        case .income: .income
        case .saving: .saving
        case .investment: .investment
        case .taxPayment: .tax
        default: .expense
        }
    }
}

// MARK: - Planning service

/// Creation, lookup and copy of monthly budgets. This is the only place
/// allowed to create MonthlyBudget instances, which guarantees at most
/// one budget per (year, month).
struct BudgetPlanningService {
    let calendar: Calendar

    func yearAndMonth(of date: Date) -> (year: Int, month: Int) {
        let components = calendar.dateComponents([.year, .month], from: date)
        return (components.year ?? 0, components.month ?? 0)
    }

    /// Existing budget for the month containing `anchor`, if any.
    func budget(monthOf anchor: Date, context: ModelContext) throws -> MonthlyBudget? {
        let (year, month) = yearAndMonth(of: anchor)
        return try budget(year: year, month: month, context: context)
    }

    func budget(year: Int, month: Int, context: ModelContext) throws -> MonthlyBudget? {
        let descriptor = FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate { $0.year == year && $0.month == month }
        )
        return try context.fetch(descriptor).first
    }

    /// Returns the month's budget, creating it (empty) when absent.
    @discardableResult
    func findOrCreate(monthOf anchor: Date, now: Date, context: ModelContext) throws -> MonthlyBudget {
        if let existing = try budget(monthOf: anchor, context: context) {
            return existing
        }
        let (year, month) = yearAndMonth(of: anchor)
        let budget = MonthlyBudget(year: year, month: month, createdAt: now, updatedAt: now)
        context.insert(budget)
        try context.saveOrRollback()
        return budget
    }

    /// Copies the previous month's lines into the month of `anchor`,
    /// skipping archived and already-budgeted categories. Returns the
    /// number of lines copied; when nothing is copyable, no empty budget
    /// is created as a side effect.
    @discardableResult
    func copyPreviousMonthLines(into anchor: Date, now: Date, context: ModelContext) throws -> Int {
        guard let previousAnchor = calendar.date(byAdding: .month, value: -1, to: anchor),
              let previous = try budget(monthOf: previousAnchor, context: context),
              !previous.lines.isEmpty else {
            return 0
        }
        let existingCategoryIDs = Set(
            try budget(monthOf: anchor, context: context)?.lines.compactMap { $0.category?.id } ?? []
        )
        let copyableLines = previous.lines.filter { line in
            guard let category = line.category else { return false }
            return category.isActive && !existingCategoryIDs.contains(category.id)
        }
        guard !copyableLines.isEmpty else { return 0 }

        let target = try findOrCreate(monthOf: anchor, now: now, context: context)
        for line in copyableLines {
            let copy = BudgetLine(
                plannedAmount: line.plannedAmount,
                category: line.category,
                createdAt: now,
                updatedAt: now
            )
            copy.budget = target
            context.insert(copy)
        }
        target.updatedAt = now
        try context.saveOrRollback()
        return copyableLines.count
    }
}
