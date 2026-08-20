import Foundation
import SwiftData

enum InsuranceKind: String, CaseIterable, Codable, Identifiable {
    case healthBase
    case healthComplementary
    case liability
    case householdContents
    case vehicle
    case legal
    case life
    case travel
    case building
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .healthBase: "Assurance maladie (LAMal)"
        case .healthComplementary: "Complémentaire (LCA)"
        case .liability: "Responsabilité civile"
        case .householdContents: "Ménage"
        case .vehicle: "Véhicule"
        case .legal: "Protection juridique"
        case .life: "Assurance vie"
        case .travel: "Voyage"
        case .building: "Bâtiment"
        case .other: "Autre"
        }
    }

    var systemImage: String {
        switch self {
        case .healthBase, .healthComplementary: "cross.case"
        case .liability: "person.2.badge.gearshape"
        case .householdContents: "house"
        case .vehicle: "car"
        case .legal: "text.book.closed"
        case .life: "heart"
        case .travel: "airplane"
        case .building: "building.2"
        case .other: "shield"
        }
    }
}

/// One insurance policy of the household. The premium is stored with its
/// real payment rhythm; annual/monthly equivalents are derived by
/// InsurancePensionService so they always reconcile.
@Model
final class InsuranceContract {
    @Attribute(.unique) var id: UUID
    var insurerName: String
    var policyName: String
    var policyNumber: String?
    var kindRawValue: String

    /// Premium per payment, > 0.
    var premiumAmount: Decimal
    var premiumUnitRawValue: String
    var premiumIntervalCount: Int
    /// Franchise.
    var deductible: Decimal?

    var startDate: Date?
    var renewalDate: Date?
    var cancellationDeadline: Date?
    var noticePeriodDays: Int?

    var coverageSummary: String?
    /// Placeholder link until the documents module (Phase 11).
    var documentReference: String?

    var isActive: Bool
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var member: HouseholdMember?

    var kind: InsuranceKind {
        get { InsuranceKind(rawValue: kindRawValue) ?? .other }
        set { kindRawValue = newValue.rawValue }
    }

    var premiumUnit: RecurrenceUnit {
        get { RecurrenceUnit(rawValue: premiumUnitRawValue) ?? .month }
        set { premiumUnitRawValue = newValue.rawValue }
    }

    var frequencyLabel: String {
        switch (premiumUnit, premiumIntervalCount) {
        case (.month, 1): "par mois"
        case (.month, 3): "par trimestre"
        case (.month, 6): "par semestre"
        case (.year, 1): "par an"
        case (.week, 1): "par semaine"
        case (.week, let n): "toutes les \(n) semaines"
        case (.month, let n): "tous les \(n) mois"
        case (.year, let n): "tous les \(n) ans"
        }
    }

    init(
        id: UUID = UUID(),
        insurerName: String,
        policyName: String,
        policyNumber: String? = nil,
        kind: InsuranceKind,
        premiumAmount: Decimal,
        premiumUnit: RecurrenceUnit = .month,
        premiumIntervalCount: Int = 1,
        deductible: Decimal? = nil,
        startDate: Date? = nil,
        renewalDate: Date? = nil,
        cancellationDeadline: Date? = nil,
        noticePeriodDays: Int? = nil,
        coverageSummary: String? = nil,
        documentReference: String? = nil,
        isActive: Bool = true,
        note: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        member: HouseholdMember? = nil
    ) {
        self.id = id
        self.insurerName = insurerName
        self.policyName = policyName
        self.policyNumber = policyNumber
        self.kindRawValue = kind.rawValue
        self.premiumAmount = premiumAmount
        self.premiumUnitRawValue = premiumUnit.rawValue
        self.premiumIntervalCount = max(1, premiumIntervalCount)
        self.deductible = deductible
        self.startDate = startDate
        self.renewalDate = renewalDate
        self.cancellationDeadline = cancellationDeadline
        self.noticePeriodDays = noticePeriodDays
        self.coverageSummary = coverageSummary
        self.documentReference = documentReference
        self.isActive = isActive
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.member = member
    }
}

enum PensionPillar: String, CaseIterable, Codable, Identifiable {
    case pillar1
    case pillar2
    case pillar3a
    case pillar3b

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pillar1: "1er pilier (AVS)"
        case .pillar2: "2e pilier (LPP)"
        case .pillar3a: "Pilier 3a"
        case .pillar3b: "Pilier 3b"
        }
    }

    var shortName: String {
        switch self {
        case .pillar1: "AVS"
        case .pillar2: "LPP"
        case .pillar3a: "3a"
        case .pillar3b: "3b"
        }
    }

    var systemImage: String {
        switch self {
        case .pillar1: "building.columns"
        case .pillar2: "briefcase"
        case .pillar3a: "shield.checkered"
        case .pillar3b: "shield"
        }
    }
}

/// A snapshot of one pension position, entered from official statements
/// (LPP certificate, 3a statement, AVS estimate). Values are what the
/// documents say — the app never projects growth on its own.
@Model
final class PensionAsset {
    @Attribute(.unique) var id: UUID
    var pillarRawValue: String
    var institutionName: String
    /// Current value from the latest statement. ADR-036 : pour le 1er
    /// pilier ce champ porte une estimation de RENTE (par mois ou par an,
    /// à préciser dans `note`) — jamais comptée comme capital ni dans le
    /// patrimoine.
    var currentValue: Decimal
    var annualContribution: Decimal
    /// Projected value AT RETIREMENT as printed on the certificate — an
    /// institution's assumption, never a promise.
    var projectedValueAtRetirement: Decimal?
    var retirementAge: Int?
    var sourceDocumentDate: Date?
    var sourceReference: String?
    var isActive: Bool
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var owner: HouseholdMember?

    var pillar: PensionPillar {
        get { PensionPillar(rawValue: pillarRawValue) ?? .pillar3a }
        set { pillarRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        pillar: PensionPillar,
        institutionName: String,
        currentValue: Decimal,
        annualContribution: Decimal = .zero,
        projectedValueAtRetirement: Decimal? = nil,
        retirementAge: Int? = nil,
        sourceDocumentDate: Date? = nil,
        sourceReference: String? = nil,
        isActive: Bool = true,
        note: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        owner: HouseholdMember? = nil
    ) {
        self.id = id
        self.pillarRawValue = pillar.rawValue
        self.institutionName = institutionName
        self.currentValue = currentValue
        self.annualContribution = annualContribution
        self.projectedValueAtRetirement = projectedValueAtRetirement
        self.retirementAge = retirementAge
        self.sourceDocumentDate = sourceDocumentDate
        self.sourceReference = sourceReference
        self.isActive = isActive
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.owner = owner
    }
}
