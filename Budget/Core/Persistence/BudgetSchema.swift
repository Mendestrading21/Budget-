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

/// Schema v5.0.0 — adds savings goals (FinancialGoal). Purely additive.
enum BudgetSchemaV5: VersionedSchema {
    static let versionIdentifier = Schema.Version(5, 0, 0)

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
            FinancialGoal.self,
        ]
    }
}

/// Schema v6.0.0 — adds the insurance register and pension snapshots
/// (InsuranceContract, PensionAsset). Purely additive.
enum BudgetSchemaV6: VersionedSchema {
    static let versionIdentifier = Schema.Version(6, 0, 0)

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
            FinancialGoal.self,
            InsuranceContract.self,
            PensionAsset.self,
        ]
    }
}

/// Schema v7.0.0 — adds net worth (Asset, Liability, NetWorthSnapshot).
/// Purely additive.
enum BudgetSchemaV7: VersionedSchema {
    static let versionIdentifier = Schema.Version(7, 0, 0)

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
            FinancialGoal.self,
            InsuranceContract.self,
            PensionAsset.self,
            Asset.self,
            Liability.self,
            NetWorthSnapshot.self,
        ]
    }
}

/// Schema v8.0.0 — adds documents and import batches (FinancialDocument,
/// ImportBatch) plus the optional BudgetTransaction.importBatchID link.
/// Purely additive.
enum BudgetSchemaV8: VersionedSchema {
    static let versionIdentifier = Schema.Version(8, 0, 0)

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
            FinancialGoal.self,
            InsuranceContract.self,
            PensionAsset.self,
            Asset.self,
            Liability.self,
            NetWorthSnapshot.self,
            FinancialDocument.self,
            ImportBatch.self,
        ]
    }
}

/// Schema v9.0.0 — adds the optional RecurringTransaction.identityKey
/// (ID1, ADR-042). Purely additive.
enum BudgetSchemaV9: VersionedSchema {
    static let versionIdentifier = Schema.Version(9, 0, 0)

    static var models: [any PersistentModel.Type] {
        BudgetSchemaV8.models
    }
}

/// Schema v10.0.0 — adds manual dated brokerage positions
/// (BrokeragePosition, INV1, ADR-047). Purely additive.
enum BudgetSchemaV10: VersionedSchema {
    static let versionIdentifier = Schema.Version(10, 0, 0)

    static var models: [any PersistentModel.Type] {
        BudgetSchemaV8.models + [BrokeragePosition.self]
    }
}

/// Schema v11.0.0 — adds persisted scheduled occurrences
/// (ScheduledOccurrence, W2.1 Budget Autonomie 100). Purely additive:
/// no view or service reads the new model yet (shadow-write strategy,
/// ADR-058) — existing data keeps exactly the same meaning.
enum BudgetSchemaV11: VersionedSchema {
    static let versionIdentifier = Schema.Version(11, 0, 0)

    static var models: [any PersistentModel.Type] {
        BudgetSchemaV10.models + [ScheduledOccurrence.self]
    }
}

/// Schema v12.0.0 — adds the financial journal (JournalEntry,
/// JournalPosting — W3.1 Budget Autonomie 100, ADR-063). Purely
/// additive: no view or service reads the new models yet (shadow-write
/// strategy, ADR-058) — existing data keeps exactly the same meaning.
enum BudgetSchemaV12: VersionedSchema {
    static let versionIdentifier = Schema.Version(12, 0, 0)

    static var models: [any PersistentModel.Type] {
        BudgetSchemaV11.models + [JournalEntry.self, JournalPosting.self]
    }
}

/// Schema v13.0.0 — adds dated, sourced exchange-rate quotes (FxQuote —
/// W4.2b Budget Autonomie 100, ADR-065). Purely additive: existing data
/// keeps exactly the same meaning.
enum BudgetSchemaV13: VersionedSchema {
    static let versionIdentifier = Schema.Version(13, 0, 0)

    static var models: [any PersistentModel.Type] {
        BudgetSchemaV12.models + [FxQuote.self]
    }
}

/// Schema v14.0.0 — adds reconciliation statements (Statement — W4.3
/// Budget Autonomie 100). Purely additive: the account's legacy
/// `reconciledBalance` point stays untouched until W4.4.
enum BudgetSchemaV14: VersionedSchema {
    static let versionIdentifier = Schema.Version(14, 0, 0)

    static var models: [any PersistentModel.Type] {
        BudgetSchemaV13.models + [Statement.self]
    }
}

// V1 relies on SwiftData's AUTOMATIC lightweight migration: every schema
// change from V1 to V10 was strictly additive (ADR-015). A staged
// SchemaMigrationPlan is deliberately absent — because the versioned
// schema enums above all reference the SAME live @Model classes, every
// stage would carry an identical model checksum and
// NSStagedMigrationManager aborts at launch trying to tell them apart
// (SIGABRT caught by the Demo tour on a fresh on-disk store; in-memory
// stores never enter that code path, which is why unit tests stayed
// green). A real staged plan requires frozen per-version model
// snapshots — planned for the first post-release breaking change.
enum PersistenceFactory {
    /// On-disk store for real user data. Demo and preview data never use it.
    static func makeProductionContainer() throws -> ModelContainer {
        try makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: false))
    }

    /// Isolated in-memory store for demo mode, previews, and tests.
    static func makeInMemoryContainer() throws -> ModelContainer {
        try makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    /// Point d'injection minimal (passe corrective L9) : le MÊME schéma
    /// et le MÊME chemin de construction que la production, avec une
    /// configuration contrôlée — réutilisé par les deux fabriques
    /// ci-dessus et par `DiskStoreLifecycleTests` (URL disque
    /// temporaire). Aucun modèle ni plan de migration modifié.
    static func makeContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV14.self),
            configurations: [configuration]
        )
    }
}
