import Foundation
import SwiftData

enum CategoryKind: String, CaseIterable, Codable, Identifiable {
    case income
    case expense
    case saving
    case investment
    case tax

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .income: "Revenus"
        case .expense: "Dépenses"
        case .saving: "Épargne"
        case .investment: "Investissements"
        case .tax: "Impôts"
        }
    }
}

@Model
final class BudgetCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRawValue: String

    /// SF Symbol token; emojis stay optional lifestyle accents.
    var iconToken: String
    var emoji: String?

    var isEssential: Bool
    var isActive: Bool
    var sortOrder: Int

    var parent: BudgetCategory?

    @Relationship(deleteRule: .cascade, inverse: \BudgetCategory.parent)
    var children: [BudgetCategory]

    var kind: CategoryKind {
        get { CategoryKind(rawValue: kindRawValue) ?? .expense }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: CategoryKind,
        iconToken: String = "tag",
        emoji: String? = nil,
        isEssential: Bool = false,
        isActive: Bool = true,
        sortOrder: Int = 0,
        parent: BudgetCategory? = nil
    ) {
        self.id = id
        self.name = name
        self.kindRawValue = kind.rawValue
        self.iconToken = iconToken
        self.emoji = emoji
        self.isEssential = isEssential
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.parent = parent
        self.children = []
    }
}

/// Default Swiss household categories seeded at onboarding.
enum DefaultCategories {
    struct Definition {
        let name: String
        let kind: CategoryKind
        let iconToken: String
        let emoji: String?
        let isEssential: Bool
    }

    static let all: [Definition] = [
        // Revenus
        Definition(name: "Salaire", kind: .income, iconToken: "banknote", emoji: nil, isEssential: true),
        Definition(name: "Revenus accessoires", kind: .income, iconToken: "plus.circle", emoji: nil, isEssential: false),
        Definition(name: "Allocations", kind: .income, iconToken: "figure.2.and.child.holdinghands", emoji: nil, isEssential: true),
        // Dépenses essentielles
        Definition(name: "Logement", kind: .expense, iconToken: "house", emoji: "🏠", isEssential: true),
        Definition(name: "Assurance maladie", kind: .expense, iconToken: "cross.case", emoji: nil, isEssential: true),
        Definition(name: "Autres assurances", kind: .expense, iconToken: "shield", emoji: nil, isEssential: true),
        Definition(name: "Alimentation", kind: .expense, iconToken: "cart", emoji: "🛒", isEssential: true),
        Definition(name: "Transports", kind: .expense, iconToken: "tram", emoji: nil, isEssential: true),
        Definition(name: "Énergie et communication", kind: .expense, iconToken: "bolt", emoji: nil, isEssential: true),
        Definition(name: "Santé", kind: .expense, iconToken: "heart.text.square", emoji: nil, isEssential: true),
        Definition(name: "Enfants et garde", kind: .expense, iconToken: "figure.and.child.holdinghands", emoji: nil, isEssential: true),
        // Dépenses discrétionnaires
        Definition(name: "Restaurants et sorties", kind: .expense, iconToken: "fork.knife", emoji: "🍽️", isEssential: false),
        Definition(name: "Loisirs et vacances", kind: .expense, iconToken: "airplane", emoji: "✈️", isEssential: false),
        Definition(name: "Shopping", kind: .expense, iconToken: "bag", emoji: nil, isEssential: false),
        Definition(name: "Abonnements", kind: .expense, iconToken: "arrow.triangle.2.circlepath", emoji: nil, isEssential: false),
        Definition(name: "Divers", kind: .expense, iconToken: "ellipsis.circle", emoji: nil, isEssential: false),
        // Épargne et investissements
        Definition(name: "Épargne", kind: .saving, iconToken: "building.columns", emoji: nil, isEssential: false),
        Definition(name: "Fonds d'urgence", kind: .saving, iconToken: "umbrella", emoji: nil, isEssential: false),
        Definition(name: "Pilier 3a", kind: .investment, iconToken: "shield.checkered", emoji: nil, isEssential: false),
        Definition(name: "Bourse", kind: .investment, iconToken: "chart.line.uptrend.xyaxis", emoji: nil, isEssential: false),
        // Impôts
        Definition(name: "Impôts", kind: .tax, iconToken: "doc.text", emoji: nil, isEssential: true),
    ]

    /// Builds fresh category models, ordered as defined.
    static func makeCategories() -> [BudgetCategory] {
        all.enumerated().map { index, definition in
            BudgetCategory(
                name: definition.name,
                kind: definition.kind,
                iconToken: definition.iconToken,
                emoji: definition.emoji,
                isEssential: definition.isEssential,
                sortOrder: index
            )
        }
    }
}
