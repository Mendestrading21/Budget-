import Foundation

/// Pure monthly aggregation. Injected calendar and "now" keep it fully
/// deterministic; no persistence access happens here.
struct MonthlySnapshotService {
    let calendar: Calendar
    let balanceService: AccountBalanceService

    init(calendar: Calendar, balanceService: AccountBalanceService = AccountBalanceService()) {
        self.calendar = calendar
        self.balanceService = balanceService
    }

    func snapshot(
        monthOf anchor: Date,
        now: Date,
        household: Household?,
        accounts: [Account],
        transactions: [BudgetTransaction]
    ) -> MonthSnapshot {
        let interval = MonthInterval(containing: anchor, calendar: calendar)
        let inMonth = transactions.filter { interval.contains($0.date) }
        let posted = inMonth.filter { $0.status == .posted }
        let planned = inMonth.filter { $0.status == .planned }

        func sum(_ items: [BudgetTransaction], _ type: TransactionType) -> Decimal {
            items.filter { $0.type == type }.reduce(.zero) { $0 + $1.amount }
        }

        let totalIncome = sum(posted, .income)
        let refunds = sum(posted, .refund)
        let totalLivingExpenses = sum(posted, .expense) - refunds
        let totalSavings = sum(posted, .saving)
        let totalInvestments = sum(posted, .investment)
        let totalTaxPayments = sum(posted, .taxPayment)
        let totalDebtPayments = sum(posted, .debtPayment)

        let plannedIncome = sum(planned, .income)
        let plannedOutflows = [
            sum(planned, .expense),
            sum(planned, .saving),
            sum(planned, .investment),
            sum(planned, .taxPayment),
            sum(planned, .debtPayment),
        ].reduce(.zero, +)

        let savingsRate = FinanceMath.safeRatio(totalSavings + totalInvestments, totalIncome)

        let cashFlow = totalIncome
            - totalLivingExpenses
            - totalSavings
            - totalInvestments
            - totalTaxPayments
            - totalDebtPayments

        let rate = household?.taxProvisionRate ?? Decimal("0.30")
        let taxProvision = TaxProvisionSummary(
            rate: rate,
            recommended: FinanceMath.roundedToCents(totalIncome * rate),
            paid: totalTaxPayments
        )

        let liquidBalance = accounts
            .filter { $0.isActive && $0.includeInAvailableCash }
            .reduce(Decimal.zero) { $0 + balanceService.balance(of: $1) }

        let available = AvailableBreakdown(
            liquidBalance: liquidBalance,
            expectedIncome: plannedIncome,
            committedCharges: plannedOutflows,
            taxReserveGap: taxProvision.gap
        )

        let daysRemaining = self.daysRemaining(in: interval, now: now)
        let dailyBudget: Decimal
        if available.total > 0, daysRemaining > 0 {
            dailyBudget = FinanceMath.roundedToCents(available.total / Decimal(daysRemaining))
        } else {
            dailyBudget = .zero
        }

        let netWorth = accounts
            .filter { $0.isActive && $0.includeInNetWorth }
            .reduce(Decimal.zero) { $0 + balanceService.balance(of: $1) }

        return MonthSnapshot(
            interval: interval,
            totalIncome: totalIncome,
            totalLivingExpenses: totalLivingExpenses,
            totalSavings: totalSavings,
            totalInvestments: totalInvestments,
            totalTaxPayments: totalTaxPayments,
            totalDebtPayments: totalDebtPayments,
            plannedIncome: plannedIncome,
            plannedOutflows: plannedOutflows,
            savingsRate: savingsRate,
            cashFlow: cashFlow,
            available: available,
            daysRemaining: daysRemaining,
            dailyAvailableBudget: dailyBudget,
            taxProvision: taxProvision,
            netWorth: netWorth,
            previousMonth: comparison(
                interval: interval,
                current: (totalIncome, totalLivingExpenses, cashFlow),
                transactions: transactions
            )
        )
    }

    /// Days from `now` (inclusive) to the end of the month; for past months
    /// zero, for future months the full month length.
    func daysRemaining(in interval: MonthInterval, now: Date) -> Int {
        if now >= interval.end { return 0 }
        let reference = max(now, interval.start)
        let fromDay = calendar.startOfDay(for: reference)
        let days = calendar.dateComponents([.day], from: fromDay, to: interval.end).day ?? 0
        return max(days, 0)
    }

    private func comparison(
        interval: MonthInterval,
        current: (income: Decimal, living: Decimal, cashFlow: Decimal),
        transactions: [BudgetTransaction]
    ) -> MonthComparison? {
        guard let previousAnchor = calendar.date(byAdding: .month, value: -1, to: interval.start) else {
            return nil
        }
        let previousInterval = MonthInterval(containing: previousAnchor, calendar: calendar)
        let posted = transactions.filter { previousInterval.contains($0.date) && $0.status == .posted }
        guard !posted.isEmpty else { return nil }

        func sum(_ type: TransactionType) -> Decimal {
            posted.filter { $0.type == type }.reduce(.zero) { $0 + $1.amount }
        }

        let previousIncome = sum(.income)
        let previousLiving = sum(.expense) - sum(.refund)
        let previousCashFlow = previousIncome
            - previousLiving
            - sum(.saving)
            - sum(.investment)
            - sum(.taxPayment)
            - sum(.debtPayment)

        return MonthComparison(
            incomeDelta: current.income - previousIncome,
            livingExpensesDelta: current.living - previousLiving,
            cashFlowDelta: current.cashFlow - previousCashFlow
        )
    }

    /// Income vs living expenses per month over the trailing `count` months
    /// (oldest first) — feeds the dashboard chart.
    func monthlyFlows(
        endingAt anchor: Date,
        count: Int,
        transactions: [BudgetTransaction]
    ) -> [(monthStart: Date, income: Decimal, livingExpenses: Decimal)] {
        guard count > 0 else { return [] }
        return (0..<count).reversed().compactMap { offset in
            guard let monthAnchor = calendar.date(byAdding: .month, value: -offset, to: anchor) else {
                return nil
            }
            let interval = MonthInterval(containing: monthAnchor, calendar: calendar)
            let posted = transactions.filter { interval.contains($0.date) && $0.status == .posted }
            let income = posted.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
            let expenses = posted.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
            let refunds = posted.filter { $0.type == .refund }.reduce(Decimal.zero) { $0 + $1.amount }
            return (interval.start, income, expenses - refunds)
        }
    }
}
