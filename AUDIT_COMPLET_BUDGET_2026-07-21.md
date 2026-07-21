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

Vérifié sain : les 58 hooks `data-*` ont tous un handler ; 5 onglets ↔ 5 renderers, 9 entrées du menu Plus toutes atteignables ; tous les champs montant en `inputmode="decimal"`, dates en `type="date"/"month"` ; SVG et boutons-icônes étiquetés ; cartes `role="button"` activables au clavier.

### BLOCKER

- **B1 (bouton mort)** — `id="bCancel"` dupliqué (l.738 billForm et l.798 baseForm) : les deux `addEventListener` s'attachent au premier élément → le bouton « Annuler » de la feuille « Devise de référence » n'a aucun handler. (l.738/798, 4021/4154)

### WARNING

- **W1 (vocabulaire, test « 10 ans »)** — occurrences visibles : « Réconcilier » (l.542, 548, 555, 1809, 1817, 4214, 4220), « Récurrent(s) » (l.604, 623-625, 754, 805, 1503, 1658, 2216-2219, 2428-2431, 2517, 3391, 3703-3731), « Comptabiliser/comptabilisé » (l.623, 1965-1979, 2043, 2065, 2219, 2435, 3721), « Provision » (l.701, 2434), « Liquidités » (l.1500, 1831, 1837, 2084, 2431), « Hors budget » (l.1733), « Flux net » (l.1510).
- **W2 (perte de saisie)** — les 19 feuilles se ferment (Annuler, tap fond, Échap) sans garde-fou : un formulaire rempli est jeté silencieusement.
- **W3** — `#reconAmount` en `inputmode="decimal"` : impossible de saisir un solde négatif au pavé iOS alors que le code gère le préfixe « - ». (l.551, 4204)
- **W4** — Retour navigateur : `data-back`/`data-accback` ne dépilent pas l'History API (pression à vide) ; `popstate` ne ferme pas une feuille ouverte. (l.2848, 2887, 3566-3573)

### NIT

N1 `ICONS.goals` mort ; N2 CSS mort (`.stage-caption`, `.footnote`, `.placeholder-list`) ; N3 lignes « Épargne »/« Bourse » non tappables dans Portefeuille global (asymétrie) ; N4 chevrons « › » sans `aria-hidden` ; N5 le mois affiché ne participe pas à l'History API ; N6 double listener sur le `bCancel` de billForm ; N7 « Marquer non payée » sans confirm (atténué par undo 6 s).

## Ordre de correction verrouillé (A06)

1. **P0-DATA** — A04-B1 + A04-B2 (perte de données au chargement/restauration).
2. **P0-UI** — A03-B1 (bouton Annuler mort, id dupliqué).
3. **P1-UX** — A03-W2 (garde-fou de fermeture des feuilles), A03-W3 (moins au clavier), A04-W1/W2 (références nettoyées), A04-W3 (quota sur seed), A04-W4 (comparaisons flottantes).
4. **B05 vocabulaire** — A03-W1 (passe complète du jargon).
5. **A03-W4** — History API cohérente.
6. Lots B restants, puis C/F/G selon la roadmap.

## A04 — Audit données (PWA)

État `S` versionné (`version: 1`) sous la clé `budget-app-state-v1` ; écriture atomique mono-clé (pas d'état à moitié écrit) ; restauration avec confirm() et refus des versions futures déclarées ; suppression de compte refusée s'il porte des mouvements.

### BLOCKER

- **B1 (P0, perte de données)** — `loadState()` traite un JSON corrompu OU une version stockée plus récente exactement pareil : `return null` → état vierge silencieux, et le blob d'origine (peut-être récupérable) est écrasé au premier `saveState()`. Aucune copie de secours, aucun message. (l.1140, 1182, 1197-1200)
- **B2 (P0, perte de données)** — `restoreFromFile` valide `payload.version` mais jamais `payload.state.version` ; un fichier avec `payload.version` absent (`undefined > 1` = false) passe, est écrit tel quel, puis rejeté par `loadState()` au reload → remplacement par l'état vierge. (l.3373-3384)

### WARNING

- **W1** — Suppression d'un mouvement : `bill.paidTxId` non nettoyé → facture affichée « payée » pointant sur un mouvement disparu. (l.3263-3273)
- **W2** — `canDeleteAccount` ignore `goals[].linked` : supprimer un compte lié à un objectif fait retomber l'objectif à 0 silencieusement. (l.3479-3494)
- **W3** — Quota localStorage plein : toast sur `saveState`, mais les chemins seed/reset démo avalent l'erreur puis `location.reload()`. (l.2716, 3060-3065)
- **W4** — Comparaison flottante stricte `v !== 0` sur sommes en cascade (`outOfBudget`) → lignes fantômes « 0.00 » possibles ; `money()` peut afficher `-CHF 0.00`. (l.1378, 892-897)

### NIT

- N1 montants Number flottants, jamais ré-arrondis après FX/restore (→ lot G01) ; N2 doublons d'import : deux lignes légitimes identiques silencieusement ignorées ; N3 seul le dernier lot d'import est annulable via l'UI ; N4 l'import écrit sans confirmation malgré le texte affiché ; N5 ligne importée d'un mois futur → `posted` au lieu de `planned` ; N6 `exportBackup` embarque le hash du code de verrouillage ; N7 undo mono-niveau qui force `onboarded = true`.
