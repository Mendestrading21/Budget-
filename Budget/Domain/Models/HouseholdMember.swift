import Foundation
import SwiftData

enum HouseholdRole: String, CaseIterable, Codable, Identifiable {
    case owner
    case partner
    case child
    case dependent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .owner: "Titulaire"
        case .partner: "Partenaire"
        case .child: "Enfant"
        case .dependent: "Personne à charge"
        }
    }
}

@Model
final class HouseholdMember {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var roleRawValue: String
    var birthDate: Date?
    var employmentStatus: String?
    var includeInBudget: Bool

    var household: Household?

    var role: HouseholdRole {
        get { HouseholdRole(rawValue: roleRawValue) ?? .owner }
        set { roleRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        role: HouseholdRole = .owner,
        birthDate: Date? = nil,
        employmentStatus: String? = nil,
        includeInBudget: Bool = true
    ) {
        self.id = id
        self.firstName = firstName
        self.roleRawValue = role.rawValue
        self.birthDate = birthDate
        self.employmentStatus = employmentStatus
        self.includeInBudget = includeInBudget
    }
}
