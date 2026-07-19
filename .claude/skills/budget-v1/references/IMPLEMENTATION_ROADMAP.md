# Implementation roadmap

Each phase must compile and meet its acceptance gate before the next phase.

## Phase 0 — Audit and foundation

- Inspect or create the Xcode project, schemes, targets, test target.
- Establish folders, SwiftData container, schema version, service injection, theme, formatters, demo store.
- Add project status and decision log.
- Acceptance: app launches into a branded shell; unit test target runs.

## Phase 1 — Onboarding and household

- Household, member, tax settings, first account, demo option.
- Acceptance: fresh install can create a valid local profile and relaunch into the app.

## Phase 2 — Accounts

- Account model, list/detail, balance policy, archive, reconciliation.
- Acceptance: multiple account types and CHF formatting work; balances persist.

## Phase 3 — Transactions

- Models, validation, add/edit/delete, filters, transfer.
- Acceptance: transfer neutrality and invalid transaction tests pass; list handles empty and large data.

## Phase 4 — Monthly dashboard

- Snapshot service, month navigation, available amount, income/expense/savings/tax cards, charts, actions.
- Acceptance: all dashboard values derive from persisted data and invariant tests.

## Phase 5 — Budget

- Monthly budgets, lines, annual grid, copy flow, variances.
- Acceptance: planned and actual remain separate and all variances reconcile.

## Phase 6 — Recurring and subscriptions

- Scheduling service, forecast occurrences, renewal/cancellation data.
- Acceptance: active charges appear once in forecasts; inactive charges do not.

## Phase 7 — Taxes

- Profile, provision, payments, arrears, due dates, dashboard integration.
- Acceptance: all states reconcile and assumptions are visible.

## Phase 8 — Goals

- Goal CRUD, projections, linked accounts, progress, celebrations.
- Acceptance: required contribution and zero/expired-date edges are safe.

## Phase 9 — Insurance and pension

- Contract register, pillars, documents, renewal reminders, overview.
- Acceptance: annual/monthly equivalents and pension totals reconcile.

## Phase 10 — Net worth

- Assets, liabilities, historical snapshots, trend chart.
- Acceptance: transfer neutrality, liability signs, and included/excluded toggles are correct.

## Phase 11 — Documents and migration

- Secure local document metadata, Notion CSV wizard, idempotence, repair queue.
- Acceptance: reimport does not duplicate; every rejected row is visible.

## Phase 12 — Security and portability

- Face ID, export, backup/restore, deletion, privacy/methodology screens.
- Acceptance: lock states, cancellation, restore version, and destructive confirmations work.

## Phase 13 — Product polish

- Accessibility, light appearance, reduced transparency/motion, localization audit, performance profiling, visual regression checklist.
- Acceptance: no critical accessibility issue, no known data-loss path, no misleading calculation.

## Phase 14 — Release package

- App icon/assets, launch screen, store copy draft, screenshots plan, support/privacy links placeholders, archive verification.
- Acceptance: clean release build and full regression evidence.
