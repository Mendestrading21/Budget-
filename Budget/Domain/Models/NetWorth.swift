import Foundation
import SwiftData

enum AssetKind: String, CaseIterable, Codable, Identifiable {
    case realEstate
    case vehicle
    case business
    case preciousMetal
    case collectible
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .realEstate: "Immobilier"
        case .vehicle: "Véhicule"
        case .business: "Entreprise"
        case .preciousMetal: "Métaux précieux"
        case .collectible: "Collection"
        case .other: "Autre"
        }
    }

    var systemImage: String {
        switch self {
        case .realEstate: "house"
        case .vehicle: "car"
        case .business: "building.2"
        case .preciousMetal: "sparkles"
        case .collectible: "photo.artframe"
        case .other: "shippingbox"
        }
    }
}

/// A non-account asset (property, vehicle…). `currentValue` is the user's
/// estimate, always ≥ 0.
@Model
final class Asset {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRawValue: String
    var currentValue: Decimal
    var includeInNetWorth: Bool
    var valuationDate: Date?
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var kind: AssetKind {
        get { AssetKind(rawValue: kindRawValue) ?? .other }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: AssetKind,
        currentValue: Decimal,
        includeInNetWorth: Bool = true,
        valuationDate: Date? = nil,
        note: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kindRawValue = kind.rawValue
        self.currentValue = currentValue
        self.includeInNetWorth = includeInNetWorth
        self.valuationDate = valuationDate
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum LiabilityKind: String, CaseIterable, Codable, Identifiable {
    case mortgage
    case loan
    case creditCardDebt
    case leasing
    case taxDebt
    case privateDebt
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mortgage: "Hypothèque"
        case .loan: "Prêt"
        case .creditCardDebt: "Dette de carte de crédit"
        case .leasing: "Leasing"
        case .taxDebt: "Dette fiscale"
        case .privateDebt: "Dette privée"
        case .other: "Autre"
        }
    }

    var systemImage: String {
        switch self {
        case .mortgage: "house"
        case .loan: "arrow.down.circle"
        case .creditCardDebt: "creditcard"
        case .leasing: "car"
        case .taxDebt: "doc.text"
        case .privateDebt: "person.2"
        case .other: "tray"
        }
    }
}

/// A standalone debt. `outstandingAmount` is ALWAYS stored positive — the
/// net-worth service subtracts it, so a debt can never be double-negated.
/// Debts already carried by a debt-type account (negative balance) belong
/// to that account, not here.
@Model
final class Liability {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRawValue: String
    var outstandingAmount: Decimal
    var includeInNetWorth: Bool
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var kind: LiabilityKind {
        get { LiabilityKind(rawValue: kindRawValue) ?? .other }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: LiabilityKind,
        outstandingAmount: Decimal,
        includeInNetWorth: Bool = true,
        note: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kindRawValue = kind.rawValue
        self.outstandingAmount = outstandingAmount
        self.includeInNetWorth = includeInNetWorth
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// A frozen daily photo of the net-worth components, recorded at most
/// once per calendar day for the historical trend.
@Model
final class NetWorthSnapshot {
    @Attribute(.unique) var id: UUID
    var date: Date
    var accountsTotal: Decimal
    var assetsTotal: Decimal
    var pensionTotal: Decimal
    var liabilitiesTotal: Decimal
    var netWorth: Decimal

    init(
        id: UUID = UUID(),
        date: Date,
        accountsTotal: Decimal,
        assetsTotal: Decimal,
        pensionTotal: Decimal,
        liabilitiesTotal: Decimal,
        netWorth: Decimal
    ) {
        self.id = id
        self.date = date
        self.accountsTotal = accountsTotal
        self.assetsTotal = assetsTotal
        self.pensionTotal = pensionTotal
        self.liabilitiesTotal = liabilitiesTotal
        self.netWorth = netWorth
    }
}
