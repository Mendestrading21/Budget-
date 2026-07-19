# Proposed architecture

Adapt this layout to the existing repository rather than forcing a rewrite.

```text
BudgetApp/
├── App/
│   ├── BudgetApp.swift
│   ├── AppContainer.swift
│   ├── AppRouter.swift
│   └── RootView.swift
├── Core/
│   ├── DesignSystem/
│   ├── Formatting/
│   ├── Persistence/
│   ├── Security/
│   ├── Validation/
│   └── Utilities/
├── Domain/
│   ├── Models/
│   ├── Snapshots/
│   ├── Services/
│   └── Protocols/
├── Features/
│   ├── Onboarding/
│   ├── Dashboard/
│   ├── Accounts/
│   ├── Transactions/
│   ├── Budget/
│   ├── Recurring/
│   ├── Taxes/
│   ├── Goals/
│   ├── Insurance/
│   ├── Pension/
│   ├── NetWorth/
│   ├── Documents/
│   ├── ImportExport/
│   └── Settings/
├── PreviewSupport/
├── Resources/
└── Tests/
```

## Core services

- `TransactionValidationService`
- `MonthlySnapshotService`
- `BudgetVarianceService`
- `RecurringScheduleService`
- `TaxProvisionService`
- `GoalProjectionService`
- `NetWorthService`
- `CSVImportService`
- `ExportService`
- `AuthenticationService`
- `DemoDataFactory`

Keep services pure where possible. Persistence coordination can wrap them, but formulas should be independently testable.

## State strategy

- `@Query` for simple persisted collections filtered by feature.
- Feature view models for multi-step forms, temporary filters, chart selection, import orchestration, or asynchronous security/file work.
- Environment injection for app container, router, theme, date provider, and services.
- Avoid a single “god” store containing the entire application.

## Navigation

Recommended main tabs:

1. Accueil
2. Budget
3. Comptes
4. Objectifs
5. Plus

`Plus` exposes Taxes, Assurances, Prévoyance, Patrimoine, Documents, Import/Export, and Settings. Use `NavigationStack` and typed routes.

## Migrations

Create a documented model schema version even before the first store ships. Add fields with safe defaults. Write migration tests for any change that affects amounts, relationships, import fingerprints, or tax states.
