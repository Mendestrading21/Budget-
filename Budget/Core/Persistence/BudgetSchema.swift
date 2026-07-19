import Foundation
import SwiftData

/// Schema v1.0.0 — first shipped schema. Any model change requires a new
/// versioned schema plus a migration stage; see DECISION_LOG.
enum BudgetSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Household.self,
            HouseholdMember.self,
            Account.self,
            BudgetCategory.self,
            BudgetTransaction.self,
        ]
    }
}

enum BudgetMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BudgetSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

enum PersistenceFactory {
    /// On-disk store for real user data. Demo and preview data never use it.
    static func makeProductionContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV1.self),
            migrationPlan: BudgetMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// Isolated in-memory store for demo mode, previews, and tests.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV1.self),
            migrationPlan: BudgetMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
