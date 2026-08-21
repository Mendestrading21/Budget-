import Foundation
import SwiftData

enum GoalKind: String, CaseIterable, Codable, Identifiable {
    case emergencyFund
    case taxes
    case travel
    case vehicle
    case property
    case children
    case retirement
    case pillar3a
    case debt
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .emergencyFund: "Fonds d'urgence"
        case .taxes: "Impôts"
        case .travel: "Voyage"
        case .vehicle: "Véhicule"
        case .property: "Logement"
        case .children: "Enfants"
        case .retirement: "Retraite"
        case .pillar3a: "Pilier 3a"
        case .debt: "Remboursement de dette"
        case .custom: "Personnalisé"
        }
    }

    /// Lifestyle accent — goals are one of the sanctioned emoji contexts.
    var defaultEmoji: String {
        switch self {
        case .emergencyFund: "☔️"
        case .taxes: "🧾"
        case .travel: "🏖️"
        case .vehicle: "🚗"
        case .property: "🏠"
        case .children: "🧸"
        case .retirement: "🌅"
        case .pillar3a: "🛡️"
        case .debt: "⚖️"
        case .custom: "🎯"
        }
    }

    var systemImage: String {
        switch self {
        case .emergencyFund: "umbrella"
        case .taxes: "doc.text"
        case .travel: "airplane"
        case .vehicle: "car"
        case .property: "house"
        case .children: "figure.2.and.child.holdinghands"
        case .retirement: "sunset"
        case .pillar3a: "shield.checkered"
        case .debt: "creditcard.and.123"
        case .custom: "target"
        }
    }
}

enum GoalPriority: String, CaseIterable, Codable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Basse"
        case .normal: "Normale"
        case .high: "Haute"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: 0
        case .normal: 1
        case .low: 2
        }
    }
}

enum GoalStatus: String, CaseIterable, Codable, Identifiable {
    case active
    case paused
    case achieved
    case archived

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: "Actif"
        case .paused: "En pause"
        case .achieved: "Atteint"
        case .archived: "Archivé"
        }
    }
}

/// A savings goal. Its current value comes either from a linked account's
/// derived balance or from a manually maintained amount — never both.
@Model
final class FinancialGoal {
    /// P10 (ADR-046) : l'emoji est un CHOIX — il ne suit le type que tant
    /// qu'il n'a jamais été personnalisé. Un emoji restauré ou choisi
    /// survit à toute modification, y compris un changement de type.
    static func emojiAfterEditing(current: String?, from oldKind: GoalKind, to newKind: GoalKind) -> String? {
        (current == nil || current == oldKind.defaultEmoji) ? newKind.defaultEmoji : current
    }

    @Attribute(.unique) var id: UUID
    var name: String
    var kindRawValue: String
    var emoji: String?

    var targetAmount: Decimal
    var targetDate: Date?
    /// Used only when no account is linked.
    var manualCurrentAmount: Decimal
    /// What the user plans to put aside each month.
    var plannedMonthlyContribution: Decimal

    var priorityRawValue: String
    var statusRawValue: String
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var linkedAccount: Account?

    var kind: GoalKind {
        get { GoalKind(rawValue: kindRawValue) ?? .custom }
        set { kindRawValue = newValue.rawValue }
    }

    var priority: GoalPriority {
        get { GoalPriority(rawValue: priorityRawValue) ?? .normal }
        set { priorityRawValue = newValue.rawValue }
    }

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRawValue) ?? .active }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: GoalKind,
        emoji: String? = nil,
        targetAmount: Decimal,
        targetDate: Date? = nil,
        manualCurrentAmount: Decimal = .zero,
        plannedMonthlyContribution: Decimal = .zero,
        priority: GoalPriority = .normal,
        status: GoalStatus = .active,
        note: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        linkedAccount: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.kindRawValue = kind.rawValue
        self.emoji = emoji ?? kind.defaultEmoji
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.manualCurrentAmount = manualCurrentAmount
        self.plannedMonthlyContribution = plannedMonthlyContribution
        self.priorityRawValue = priority.rawValue
        self.statusRawValue = status.rawValue
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.linkedAccount = linkedAccount
    }
}
