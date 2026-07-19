import Foundation

/// Injectable "now" so calculation services stay deterministic in tests.
protocol DateProviding {
    var now: Date { get }
}

struct SystemDateProvider: DateProviding {
    var now: Date { Date() }
}

struct FixedDateProvider: DateProviding {
    let now: Date
}

/// Month boundaries as half-open intervals [start, end).
struct MonthInterval: Equatable {
    let start: Date
    let end: Date

    /// The month containing `date` in the given calendar.
    init(containing date: Date, calendar: Calendar) {
        let start = calendar.dateInterval(of: .month, for: date)?.start ?? date
        self.start = start
        self.end = calendar.date(byAdding: .month, value: 1, to: start) ?? date
    }

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
