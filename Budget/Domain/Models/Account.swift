import Foundation
import SwiftData

enum AccountType: String, CaseIterable, Codable, Identifiable {
    case current
    case savings
    case creditCard
    case cash
    case broker
    case pillar3a
    case pillar3b
    case occupationalPension
    case mortgage
    case loan
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .current: "Compte courant"
        case .savings: "Compte épargne"
        case .creditCard: "Carte de crédit"
        case .cash: "Espèces"
        case .broker: "Compte titres"
        case .pillar3a: "Pilier 3a"
        case .pillar3b: "Pilier 3b"
        case .occupationalPension: "Caisse de pension (2e pilier)"
        case .mortgage: "Hypothèque"
        case .loan: "Prêt"
        case .other: "Autre"
        }
    }

    var systemImage: String {
        switch self {
        case .current: "creditcard"
        case .savings: "building.columns"
        case .creditCard: "creditcard.fill"
        case .cash: "banknote"
        case .broker: "chart.line.uptrend.xyaxis"
        case .pillar3a, .pillar3b, .occupationalPension: "shield.checkered"
        case .mortgage: "house"
        case .loan: "arrow.down.circle"
        case .other: "tray"
        }
    }

    /// Debt accounts hold what the household owes; their balance reduces
    /// net worth.
    var isLiability: Bool {
        switch self {
        case .creditCard, .mortgage, .loan: true
        default: false
        }
    }

    /// Sensible default for "counts as spendable cash".
    var defaultIncludeInAvailableCash: Bool {
        switch self {
        case .current, .cash: true
        default: false
        }
    }
}

@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var institutionName: String
    var typeRawValue: String
    var currencyCode: String

    /// Balance at account creation, before any recorded movement.
    var openingBalance: Decimal

    /// Explicit manual reconciliation point: the user asserted this balance
    /// at `reconciledAt`. Movements posted after that date are added on top.
    var reconciledBalance: Decimal?
    var reconciledAt: Date?

    var isShared: Bool
    var isActive: Bool
    var includeInAvailableCash: Bool
    var includeInNetWorth: Bool

    var createdAt: Date
    var updatedAt: Date

    var owner: HouseholdMember?

    /// Movements whose source is this account.
    @Relationship(deleteRule: .deny, inverse: \BudgetTransaction.account)
    var transactions: [BudgetTransaction]

    /// Transfers and internal contributions arriving into this account.
    @Relationship(deleteRule: .deny, inverse: \BudgetTransaction.destinationAccount)
    var incomingMovements: [BudgetTransaction]

    var type: AccountType {
        get { AccountType(rawValue: typeRawValue) ?? .other }
        set { typeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        institutionName: String = "",
        type: AccountType,
        currencyCode: String = "CHF",
        openingBalance: Decimal = .zero,
        isShared: Bool = false,
        isActive: Bool = true,
        includeInAvailableCash: Bool? = nil,
        includeInNetWorth: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        owner: HouseholdMember? = nil
    ) {
        self.id = id
        self.name = name
        self.institutionName = institutionName
        self.typeRawValue = type.rawValue
        self.currencyCode = currencyCode
        self.openingBalance = openingBalance
        self.reconciledBalance = nil
        self.reconciledAt = nil
        self.isShared = isShared
        self.isActive = isActive
        self.includeInAvailableCash = includeInAvailableCash ?? type.defaultIncludeInAvailableCash
        self.includeInNetWorth = includeInNetWorth
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.owner = owner
        self.transactions = []
        self.incomingMovements = []
    }
}
