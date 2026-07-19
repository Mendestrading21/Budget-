import Foundation
import SwiftData

/// Recurrence rhythm: a calendar unit repeated every `intervalCount` units.
/// Monthly = (month, 1), quarterly = (month, 3), annual = (year, 1).
enum RecurrenceUnit: String, CaseIterable, Codable, Identifiable {
    case week
    case month
    case year

    var id: String { rawValue }

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}

/// A recurring charge, income or contribution — subscriptions included
/// (they carry renewal/cancellation metadata). Forecast occurrences are
/// derived by RecurringScheduleService and NEVER duplicate posted
/// transactions: materialized instances link back via
/// `BudgetTransaction.recurringID`.
@Model
final class RecurringTransaction {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Always positive; direction comes from `type` (same convention as
    /// BudgetTransaction).
    var amount: Decimal
    var typeRawValue: String

    var intervalUnitRawValue: String
    /// Every N units; ≥ 1.
    var intervalCount: Int
    /// Anchor date: the k-th occurrence is firstOccurrence + k·interval.
    var firstOccurrence: Date
    var endDate: Date?

    var isActive: Bool
    /// Personal vs professional classification.
    var isProfessional: Bool
    /// Subscriptions expose renewal/cancellation metadata in the UI.
    var isSubscription: Bool
    var renewalDate: Date?
    var cancellationDeadline: Date?

    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var account: Account?
    var destinationAccount: Account?
    var category: BudgetCategory?
    var member: HouseholdMember?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    var intervalUnit: RecurrenceUnit {
        get { RecurrenceUnit(rawValue: intervalUnitRawValue) ?? .month }
        set { intervalUnitRawValue = newValue.rawValue }
    }

    /// French rhythm label: « Mensuel », « Trimestriel », « Tous les 2 mois »…
    var frequencyLabel: String {
        switch (intervalUnit, intervalCount) {
        case (.week, 1): "Hebdomadaire"
        case (.month, 1): "Mensuel"
        case (.month, 3): "Trimestriel"
        case (.month, 6): "Semestriel"
        case (.year, 1): "Annuel"
        case (.week, let n): "Toutes les \(n) semaines"
        case (.month, let n): "Tous les \(n) mois"
        case (.year, let n): "Tous les \(n) ans"
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        type: TransactionType,
        intervalUnit: RecurrenceUnit = .month,
        intervalCount: Int = 1,
        firstOccurrence: Date,
        endDate: Date? = nil,
        isActive: Bool = true,
        isProfessional: Bool = false,
        isSubscription: Bool = false,
        renewalDate: Date? = nil,
        cancellationDeadline: Date? = nil,
        note: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        account: Account? = nil,
        destinationAccount: Account? = nil,
        category: BudgetCategory? = nil,
        member: HouseholdMember? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.typeRawValue = type.rawValue
        self.intervalUnitRawValue = intervalUnit.rawValue
        self.intervalCount = max(1, intervalCount)
        self.firstOccurrence = firstOccurrence
        self.endDate = endDate
        self.isActive = isActive
        self.isProfessional = isProfessional
        self.isSubscription = isSubscription
        self.renewalDate = renewalDate
        self.cancellationDeadline = cancellationDeadline
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.account = account
        self.destinationAccount = destinationAccount
        self.category = category
        self.member = member
    }
}
