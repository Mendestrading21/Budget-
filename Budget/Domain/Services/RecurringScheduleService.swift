import Foundation

/// One forecast occurrence of a recurring charge within a month.
struct ForecastOccurrence: Identifiable, Equatable {
    /// Stable across rebuilds: recurring id + occurrence date.
    let id: String
    let recurringID: UUID
    let title: String
    let amount: Decimal
    let type: TransactionType
    let date: Date
    let isSubscription: Bool

    static func == (lhs: ForecastOccurrence, rhs: ForecastOccurrence) -> Bool {
        lhs.id == rhs.id
    }
}

/// Pure recurrence arithmetic. Occurrences are computed as multiples of
/// the anchor date (firstOccurrence + k·interval) rather than by
/// incrementally adding intervals, so short months never make the day
/// drift (Jan 31 → Feb 28 → Mar 31, not Mar 28).
struct RecurringScheduleService {
    let calendar: Calendar

    /// Hard cap on iterations — safety net against absurd anchors.
    private static let maxIterations = 5000

    /// All occurrence dates of `recurring` inside `interval`.
    /// Inactive recurrences have none; `endDate` is inclusive.
    func occurrenceDates(of recurring: RecurringTransaction, in interval: MonthInterval) -> [Date] {
        guard recurring.isActive, recurring.intervalCount >= 1 else { return [] }
        var dates: [Date] = []
        for k in 0..<Self.maxIterations {
            guard let date = calendar.date(
                byAdding: recurring.intervalUnit.calendarComponent,
                value: k * recurring.intervalCount,
                to: recurring.firstOccurrence
            ) else { break }
            if date >= interval.end { break }
            if let endDate = recurring.endDate, date > endDate { break }
            if interval.contains(date) {
                dates.append(date)
            }
        }
        return dates
    }

    /// Next occurrence on or after `date`, looking ahead up to `horizonMonths`.
    func nextOccurrence(of recurring: RecurringTransaction, onOrAfter date: Date, horizonMonths: Int = 24) -> Date? {
        var anchor = date
        for _ in 0..<max(1, horizonMonths) {
            let interval = MonthInterval(containing: anchor, calendar: calendar)
            if let match = occurrenceDates(of: recurring, in: interval).first(where: { $0 >= date }) {
                return match
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: anchor) else { return nil }
            anchor = next
        }
        return nil
    }

    /// Occurrences of the month NOT yet covered by a linked transaction.
    ///
    /// Coverage is count-based and chronological: N transactions of the
    /// month linked to this recurring (posted or planned) cover the N
    /// earliest occurrences, even when their exact day differs (a salary
    /// paid on the 24th covers the occurrence of the 25th). This is what
    /// guarantees a forecast never duplicates real movements.
    func remainingOccurrences(
        of recurring: RecurringTransaction,
        in interval: MonthInterval,
        transactions: [BudgetTransaction]
    ) -> [ForecastOccurrence] {
        let dates = occurrenceDates(of: recurring, in: interval)
        guard !dates.isEmpty else { return [] }
        let coveredCount = transactions.filter {
            $0.recurringID == recurring.id && interval.contains($0.date)
        }.count
        return dates.dropFirst(min(coveredCount, dates.count)).map { date in
            ForecastOccurrence(
                id: "\(recurring.id.uuidString)-\(Int(date.timeIntervalSince1970))",
                recurringID: recurring.id,
                title: recurring.title,
                amount: recurring.amount,
                type: recurring.type,
                date: date,
                isSubscription: recurring.isSubscription
            )
        }
    }

    /// Every remaining occurrence of the month across `recurrings`,
    /// chronological. Feeds the dashboard forecast and available-to-spend.
    func monthForecast(
        recurrings: [RecurringTransaction],
        in interval: MonthInterval,
        transactions: [BudgetTransaction]
    ) -> [ForecastOccurrence] {
        recurrings
            .flatMap { remainingOccurrences(of: $0, in: interval, transactions: transactions) }
            .sorted { $0.date < $1.date }
    }

    /// Rituel « Check du mois » : combien de récurrents dus dans le mois
    /// sont déjà comptabilisés. `total` = récurrents actifs avec au moins
    /// une occurrence dans l'intervalle ; `done` = ceux qui n'ont plus
    /// d'occurrence en attente (couverts par un mouvement lié).
    func monthCheck(
        recurrings: [RecurringTransaction],
        in interval: MonthInterval,
        transactions: [BudgetTransaction]
    ) -> (done: Int, total: Int) {
        let due = recurrings.filter { $0.isActive && !occurrenceDates(of: $0, in: interval).isEmpty }
        guard !due.isEmpty else { return (0, 0) }
        let pendingIDs = Set(
            monthForecast(recurrings: recurrings, in: interval, transactions: transactions)
                .map(\.recurringID)
        )
        return (due.filter { !pendingIDs.contains($0.id) }.count, due.count)
    }

    /// Série de mois bouclés consécutifs (🔥) : en remontant depuis le
    /// mois de `anchor` (inclus seulement s'il est bouclé), compte les
    /// mois où TOUT ce qui était dû a été comptabilisé. Un mois sans
    /// récurrent dû casse la série — il n'y avait rien à boucler.
    func closedStreak(
        endingAt anchor: Date,
        recurrings: [RecurringTransaction],
        transactions: [BudgetTransaction],
        horizonMonths: Int = 24
    ) -> Int {
        func isClosed(_ date: Date) -> Bool {
            let interval = MonthInterval(containing: date, calendar: calendar)
            let check = monthCheck(recurrings: recurrings, in: interval, transactions: transactions)
            return check.total > 0 && check.done == check.total
        }
        var cursor = anchor
        if !isClosed(cursor) {
            guard let previous = calendar.date(byAdding: .month, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }
        var count = 0
        for _ in 0..<max(1, horizonMonths) {
            guard isClosed(cursor) else { break }
            count += 1
            guard let previous = calendar.date(byAdding: .month, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    // MARK: - Normalized costs

    /// Cost per month: annual/12, quarterly/3, weekly ×52/12…
    func monthlyEquivalent(of recurring: RecurringTransaction) -> Decimal {
        let count = Decimal(max(1, recurring.intervalCount))
        let raw: Decimal
        switch recurring.intervalUnit {
        case .month: raw = recurring.amount / count
        case .year: raw = recurring.amount / (Decimal(12) * count)
        case .week: raw = recurring.amount * Decimal(52) / (Decimal(12) * count)
        }
        return FinanceMath.roundedToCents(raw)
    }

    /// Cost per year: monthly ×12, quarterly ×4, weekly ×52…
    func annualizedCost(of recurring: RecurringTransaction) -> Decimal {
        let count = Decimal(max(1, recurring.intervalCount))
        let raw: Decimal
        switch recurring.intervalUnit {
        case .month: raw = recurring.amount * Decimal(12) / count
        case .year: raw = recurring.amount / count
        case .week: raw = recurring.amount * Decimal(52) / count
        }
        return FinanceMath.roundedToCents(raw)
    }

    /// Materializes one forecast occurrence, linked back to its recurring
    /// definition. A future due date stays planned until that day.
    func makeTransaction(
        from recurring: RecurringTransaction,
        on date: Date,
        now: Date
    ) -> BudgetTransaction {
        BudgetTransaction(
            date: date,
            amount: recurring.amount,
            type: recurring.type,
            status: TransactionPostingPolicy(calendar: calendar)
                .automaticStatus(for: date, now: now),
            title: recurring.title,
            note: recurring.note,
            recurringID: recurring.id,
            createdAt: now,
            updatedAt: now,
            account: recurring.account,
            destinationAccount: recurring.destinationAccount,
            category: recurring.category,
            member: recurring.member
        )
    }

    /// Materializes an occurrence once. The exact due date is the stable
    /// identity of a newly generated recurring movement; this guard closes
    /// the double-tap/rerender window before SwiftData refreshes the query.
    func makeTransactionIfNeeded(
        from recurring: RecurringTransaction,
        occurrence: ForecastOccurrence,
        existingTransactions: [BudgetTransaction],
        now: Date
    ) -> BudgetTransaction? {
        guard recurring.id == occurrence.recurringID else { return nil }
        let alreadyMaterialized = existingTransactions.contains {
            $0.recurringID == recurring.id
                && calendar.isDate($0.date, inSameDayAs: occurrence.date)
        }
        guard !alreadyMaterialized else { return nil }
        return makeTransaction(from: recurring, on: occurrence.date, now: now)
    }
}
