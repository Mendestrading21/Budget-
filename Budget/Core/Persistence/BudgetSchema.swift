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

/// Schema v2.0.0 — adds monthly budgets (MonthlyBudget, BudgetLine).
/// Purely additive relative to V1, hence a lightweight migration.
enum BudgetSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Household.self,
            HouseholdMember.self,
            Account.self,
            BudgetCategory.self,
            BudgetTransaction.self,
            MonthlyBudget.self,
            BudgetLine.self,
        ]
    }
}

/// Schema v3.0.0 — adds recurring transactions/subscriptions and the
/// optional BudgetTransaction.recurringID link. Purely additive.
enum BudgetSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Household.self,
            HouseholdMember.self,
            Account.self,
            BudgetCategory.self,
            BudgetTransaction.self,
            MonthlyBudget.self,
            BudgetLine.self,
            RecurringTransaction.self,
        ]
    }
}

/// Schema v4.0.0 — adds the tax module (TaxProfile, TaxProvision).
/// Purely additive; the profile is seeded lazily from
/// Household.taxProvisionRate by TaxService (ADR-008).
enum BudgetSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Household.self,
            HouseholdMember.self,
            Account.self,
            BudgetCategory.self,
            BudgetTransaction.self,
            MonthlyBudget.self,
            BudgetLine.self,
            RecurringTransaction.self,
            TaxProfile.self,
            TaxProvision.self,
        ]
    }
}

enum BudgetMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BudgetSchemaV1.self, BudgetSchemaV2.self, BudgetSchemaV3.self, BudgetSchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: BudgetSchemaV1.self, toVersion: BudgetSchemaV2.self),
            .lightweight(fromVersion: BudgetSchemaV2.self, toVersion: BudgetSchemaV3.self),
            .lightweight(fromVersion: BudgetSchemaV3.self, toVersion: BudgetSchemaV4.self),
        ]
    }
}

enum PersistenceFactory {
    /// On-disk store for real user data. Demo and preview data never use it.
    static func makeProductionContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV4.self),
            migrationPlan: BudgetMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// Isolated in-memory store for demo mode, previews, and tests.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV4.self),
            migrationPlan: BudgetMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
