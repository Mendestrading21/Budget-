import Foundation
import SwiftData

/// Planned money for one calendar month. Actual amounts are never stored
/// here — they derive from posted transactions via BudgetVarianceService,
/// keeping planned and actual strictly separate.
///
/// Uniqueness of (year, month) is enforced by BudgetPlanningService,
/// which is the only creation path.
@Model
final class MonthlyBudget {
    @Attribute(.unique) var id: UUID
    var year: Int
    /// 1...12
    var month: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BudgetLine.budget)
    var lines: [BudgetLine]

    init(
        id: UUID = UUID(),
        year: Int,
        month: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.year = year
        self.month = month
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lines = []
    }

    /// First instant of the budgeted month in the given calendar.
    func startDate(calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }
}

/// One planned amount for one category within a monthly budget.
@Model
final class BudgetLine {
    @Attribute(.unique) var id: UUID
    /// Always ≥ 0; a budget line plans an envelope, not a direction.
    var plannedAmount: Decimal
    var createdAt: Date
    var updatedAt: Date

    var category: BudgetCategory?
    var budget: MonthlyBudget?

    init(
        id: UUID = UUID(),
        plannedAmount: Decimal,
        category: BudgetCategory? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.plannedAmount = plannedAmount
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
