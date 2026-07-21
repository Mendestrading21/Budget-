# Audit complet Budget — 2026-07-21

Document produit par le programme Budget Master Evolution (jalon J1).
Sections : A01 inventaire, A03 boutons/routes/vocabulaire, A04 données.

## A01 — Inventaire réel

App iOS native (SwiftUI + SwiftData) + PWA web autonome. Interface fr-CH, multi-pays CH/FR/BE côté web.

### Natif — `Budget/`

- **Navigation** : 5 onglets (`AppTab`) : Accueil, Mouvements, Budget, Comptes, Plus — `App/` (BudgetApp, AppContainer, AppRouter, RootView).
- **Écrans** (`Features/`) :
  - Accueil : `Dashboard/HomeTab.swift`
  - Mouvements : `Transactions/TransactionsListView.swift`, `TransactionFormView.swift`
  - Budget : `Budget/BudgetTab.swift`, `AnnualBudgetView.swift`, `BudgetLineFormView.swift`
  - Comptes : `Accounts/AccountsTab.swift`, `AccountDetailView.swift`, `AccountFormView.swift`, `ReconcileSheet.swift`
  - Plus : `More/MoreTab.swift`, `YearReviewView.swift` → Objectifs, Impôts, Patrimoine, Assurances, Prévoyance, Récurrents, Import/Export, Documents, Réglages (dossiers `Goals/ Taxes/ NetWorth/ Insurance/ Pension/ Recurring/ ImportExport/ Documents/ Settings/`)
  - Onboarding : `Onboarding/OnboardingFlowView.swift` + ViewModel
  - Design system : `Core/DesignSystem/DesignTokens.swift`, `GlassCard.swift`
- **Modèles SwiftData** (18 entités, schéma **V8** strictement additif V1→V8, migration légère — ADR-015) : Household, HouseholdMember, Account, BudgetCategory, BudgetTransaction, MonthlyBudget, BudgetLine, RecurringTransaction, TaxProfile, TaxProvision, FinancialGoal, InsuranceContract, PensionAsset, Asset, Liability, NetWorthSnapshot, FinancialDocument, ImportBatch.
- **Services purs** (14) : AccountBalance, Backup, Budget, CSVImport, Contribution, GoalProjection, InsurancePension, MonthlySnapshot, NetWorth, RecurringSchedule, Tax, TransactionValidation, WealthProjection, YearStats (+ Security/, FinanceFormatting, SafeSave, DemoDataFactory).
- **Tests** : `BudgetTests/` 20 fichiers (soldes, backup, budget, import, contributions, dette, formatage, objectifs, assurance/prévoyance, snapshots, patrimoine, onboarding, persistance, récurrents, impôts, validation, projections, stats) ; `BudgetUITests/` 1 fichier (DemoTourUITests).

### Web — `webapp/`

- `index.html` : 4225 lignes, monofichier autonome, localStorage (clé `budget-app-state-v1`, migration depuis clé héritée `budget-proto-mouvements`), état global `S`, mutations directes + `render()`.
- **Router** : `RENDERERS = {home, movements, budget, accounts, more}` (mêmes 5 onglets que le natif) ; sous-routeur `MORE_RENDERERS` : goals, bills, taxes, networth, insurance, recurring, importcsv, settings, year. 18 fonctions `render*` + onboarding + écran de verrouillage.
- `sw.js` (réseau d'abord, cache `budget-app-v2`), `manifest.webmanifest` (standalone, fr-CH), tests `webapp/tests/e2e.test.mjs` (Chromium réel, zéro erreur console).

### CI — `.github/workflows/`

- `ci.yml` : e2e web Chromium + build/tests iOS simulateur + build Release (push claude/**, main, PR).
- `demo.yml` : manuel — vraie app dans le simulateur, artefact captures/vidéo/.ipa.
- `pages.yml` : publie `webapp/` sur GitHub Pages (https://mendestrading21.github.io/Budget-/).
- `testflight.yml` : manuel — archive signée + upload TestFlight (4 secrets requis).

### Docs racine

CLAUDE.md (instructions projet), PROJECT_STATUS.md, BUDGET_MASTER_STATUS.md, DECISION_LOG.md (ADR-001→018), APP_STORE_LISTING.md, MANUAL_QA_CHECKLIST.md, TESTFLIGHT_SETUP.md.

### Branding

`branding/logo.svg` (chemin ascendant du patrimoine) + `render_icons.py` → icônes 1024/512/192/180 ; assets natifs AppIcon/AccentColor ; icônes web 192/512/apple-touch.

## A02 — Baseline reproductible

- Web : `node webapp/tests/e2e.test.mjs` — **22 parcours verts, zéro erreur console** (2026-07-21, Chromium /opt/pw-browsers, session Linux).
- Natif : non exécutable localement (session Linux) — vérifié par la CI GitHub Actions à chaque push (runner macos-15, iPhone 16 : build Debug + ~190 tests + build Release). Baseline : run CI du commit `6677166`.

## A03 — Audit boutons/routes/vocabulaire (PWA)

_(en cours — rempli à la livraison de l'audit)_

## A04 — Audit données (PWA)

_(en cours — rempli à la livraison de l'audit)_
