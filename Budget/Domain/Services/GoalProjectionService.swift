import Foundation

/// Where a goal stands relative to its plan.
enum GoalScheduleStatus: Equatable {
    /// Target reached.
    case achieved
    /// Planned contribution covers the required pace.
    case onTrack
    /// Planned contribution is below the required pace.
    case behind
    /// Target date has passed with money still missing.
    case overdue
    /// No target date: pace is whatever the user planned.
    case noDeadline

    var displayName: String {
        switch self {
        case .achieved: "Atteint"
        case .onTrack: "En bonne voie"
        case .behind: "À accélérer"
        case .overdue: "Échéance dépassée"
        case .noDeadline: "Sans échéance"
        }
    }
}

/// Derived, never-persisted projection of one goal. All edges are safe:
/// zero targets, zero contributions and past dates can never produce a
/// crash, a NaN or a negative requirement.
struct GoalReport: Equatable {
    let goalID: UUID
    let currentAmount: Decimal
    let targetAmount: Decimal
    /// Clamped to [0, 1]; a non-positive target counts as reached.
    let progressFraction: Decimal
    let remainingAmount: Decimal
    /// Whole months still available before the target date (nil without
    /// date; 0 when the date has passed).
    let monthsRemaining: Int?
    /// What must be saved each month to make the date — nil without date;
    /// equals the full remaining amount when the date is past or this is
    /// the last month.
    let requiredMonthlyContribution: Decimal?
    let plannedMonthlyContribution: Decimal
    let scheduleStatus: GoalScheduleStatus
    /// When the goal completes at the planned pace (nil when nothing is
    /// planned or already achieved).
    let projectedCompletionDate: Date?
}

/// Pure goal arithmetic with injected calendar and balance derivation.
struct GoalProjectionService {
    let calendar: Calendar
    let balanceService: AccountBalanceService

    init(calendar: Calendar, balanceService: AccountBalanceService = AccountBalanceService()) {
        self.calendar = calendar
        self.balanceService = balanceService
    }

    /// Linked-account balance when linked, manual amount otherwise.
    func currentAmount(of goal: FinancialGoal) -> Decimal {
        if let account = goal.linkedAccount {
            return balanceService.balance(of: account)
        }
        return goal.manualCurrentAmount
    }

    /// Whole months from `now` to `date`, counting a started month as one
    /// more; never negative. Compares whole days so the time of day can
    /// never shift the result.
    func monthsRemaining(until date: Date, now: Date) -> Int {
        guard date > now else { return 0 }
        let from = calendar.startOfDay(for: now)
        let to = calendar.startOfDay(for: date)
        let months = calendar.dateComponents([.month], from: from, to: to).month ?? 0
        guard let advanced = calendar.date(byAdding: .month, value: months, to: from) else {
            return max(0, months)
        }
        return max(0, months + (advanced < to ? 1 : 0))
    }

    func report(for goal: FinancialGoal, now: Date) -> GoalReport {
        let current = currentAmount(of: goal)
        let target = goal.targetAmount

        let progress: Decimal
        if target <= 0 {
            progress = 1
        } else {
            progress = max(.zero, min(Decimal(1), FinanceMath.safeRatio(current, target)))
        }
        let remaining = max(.zero, target - current)
        let isAchieved = remaining == .zero

        var months: Int?
        var required: Decimal?
        if let targetDate = goal.targetDate {
            let value = monthsRemaining(until: targetDate, now: now)
            months = value
            if isAchieved {
                required = .zero
            } else if value <= 1 {
                // Last month or already past: everything is due now.
                required = remaining
            } else {
                required = FinanceMath.roundedToCents(remaining / Decimal(value))
            }
        }

        let status: GoalScheduleStatus
        if isAchieved {
            status = .achieved
        } else if let targetDate = goal.targetDate {
            if targetDate <= now {
                status = .overdue
            } else if let required, goal.plannedMonthlyContribution >= required {
                status = .onTrack
            } else {
                status = .behind
            }
        } else {
            status = .noDeadline
        }

        var projected: Date?
        if !isAchieved && goal.plannedMonthlyContribution > 0 {
            let monthsNeeded = ceilDivision(remaining, by: goal.plannedMonthlyContribution)
            projected = calendar.date(byAdding: .month, value: monthsNeeded, to: now)
        }

        return GoalReport(
            goalID: goal.id,
            currentAmount: current,
            targetAmount: target,
            progressFraction: progress,
            remainingAmount: remaining,
            monthsRemaining: months,
            requiredMonthlyContribution: required,
            plannedMonthlyContribution: goal.plannedMonthlyContribution,
            scheduleStatus: status,
            projectedCompletionDate: projected
        )
    }

    /// ⌈numerator / denominator⌉ as Int, safe for positive Decimals.
    private func ceilDivision(_ numerator: Decimal, by denominator: Decimal) -> Int {
        guard denominator > 0 else { return 0 }
        var quotient = numerator / denominator
        var rounded = Decimal()
        NSDecimalRound(&rounded, &quotient, 0, .up)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
