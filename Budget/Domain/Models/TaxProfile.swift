import Foundation
import SwiftData

/// Tax location and assumptions of the household. Once a profile exists,
/// its `provisionRate` is the single source of truth — the legacy
/// `Household.taxProvisionRate` only seeds it (ADR-008).
///
/// Everything here is an ORGANIZATIONAL ESTIMATE, never an official tax
/// statement — the UI must say so.
@Model
final class TaxProfile {
    @Attribute(.unique) var id: UUID
    var canton: String
    var municipality: String
    /// Fraction of taxable income to set aside (0.30 = 30 %).
    var provisionRate: Decimal
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TaxProvision.profile)
    var provisions: [TaxProvision]

    init(
        id: UUID = UUID(),
        canton: String = "",
        municipality: String = "",
        // FE2-11 : opt-in - aucun taux implicite.
        provisionRate: Decimal = .zero,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.canton = canton
        self.municipality = municipality
        self.provisionRate = provisionRate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.provisions = []
    }
}

/// One instalment/deadline of a tax year.
struct TaxDueDate: Codable, Hashable, Identifiable {
    var id: UUID
    var date: Date
    var label: String

    init(id: UUID = UUID(), date: Date, label: String) {
        self.id = id
        self.date = date
        self.label = label
    }
}

/// Provision state for one tax year. Stored fields are what the user
/// controls (override, reserved cash, arrears, deadlines); paid and
/// outstanding amounts are DERIVED from posted taxPayment transactions by
/// TaxService — never stored, so states always reconcile.
@Model
final class TaxProvision {
    @Attribute(.unique) var id: UUID
    var year: Int
    /// Manual override of the annual tax estimate; nil = derived from the
    /// year's income × profile rate.
    var estimatedAnnualTaxOverride: Decimal?
    /// Cash the user has explicitly set aside for this tax year.
    var reservedAmount: Decimal
    /// Debts from previous tax years (rattrapages, décomptes finaux).
    var arrearsAmount: Decimal
    var dueDates: [TaxDueDate]
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var profile: TaxProfile?

    init(
        id: UUID = UUID(),
        year: Int,
        estimatedAnnualTaxOverride: Decimal? = nil,
        reservedAmount: Decimal = .zero,
        arrearsAmount: Decimal = .zero,
        dueDates: [TaxDueDate] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.year = year
        self.estimatedAnnualTaxOverride = estimatedAnnualTaxOverride
        self.reservedAmount = reservedAmount
        self.arrearsAmount = arrearsAmount
        self.dueDates = dueDates
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
