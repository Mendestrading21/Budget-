import Foundation
import SwiftData

/// The household is the root profile of the app. V1 supports a single
/// household per store.
@Model
final class Household {
    @Attribute(.unique) var id: UUID
    var name: String
    var baseCurrencyCode: String
    var canton: String
    var municipality: String

    /// Configured tax provision rate as a fraction (0.30 = 30 %).
    /// Lives here until the dedicated TaxProfile entity ships in Phase 7;
    /// see DECISION_LOG ADR-003.
    var taxProvisionRate: Decimal

    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HouseholdMember.household)
    var members: [HouseholdMember]

    init(
        id: UUID = UUID(),
        name: String,
        baseCurrencyCode: String = "CHF",
        canton: String = "",
        municipality: String = "",
        taxProvisionRate: Decimal = Decimal("0.30"),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        members: [HouseholdMember] = []
    ) {
        self.id = id
        self.name = name
        self.baseCurrencyCode = baseCurrencyCode
        self.canton = canton
        self.municipality = municipality
        self.taxProvisionRate = taxProvisionRate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.members = members
    }
}

/// Swiss cantons for pickers; stored as the two-letter abbreviation.
enum SwissCanton: String, CaseIterable, Identifiable {
    case AG, AI, AR, BE, BL, BS, FR, GE, GL, GR, JU, LU, NE, NW, OW, SG, SH, SO, SZ, TG, TI, UR, VD, VS, ZG, ZH

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .AG: "Argovie"
        case .AI: "Appenzell Rhodes-Intérieures"
        case .AR: "Appenzell Rhodes-Extérieures"
        case .BE: "Berne"
        case .BL: "Bâle-Campagne"
        case .BS: "Bâle-Ville"
        case .FR: "Fribourg"
        case .GE: "Genève"
        case .GL: "Glaris"
        case .GR: "Grisons"
        case .JU: "Jura"
        case .LU: "Lucerne"
        case .NE: "Neuchâtel"
        case .NW: "Nidwald"
        case .OW: "Obwald"
        case .SG: "Saint-Gall"
        case .SH: "Schaffhouse"
        case .SO: "Soleure"
        case .SZ: "Schwytz"
        case .TG: "Thurgovie"
        case .TI: "Tessin"
        case .UR: "Uri"
        case .VD: "Vaud"
        case .VS: "Valais"
        case .ZG: "Zoug"
        case .ZH: "Zurich"
        }
    }
}
