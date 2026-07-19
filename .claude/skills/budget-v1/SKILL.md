---
name: Budget V1 — Build the full iOS app
description: Build, continue, audit, verify, and polish Budget V1, a native offline-first Swiss household finance app. Use for end-to-end product construction in SwiftUI/SwiftData, architecture, financial rules, Swiss localization, premium glass UI, tests, CSV import, security, accessibility, and App Store readiness.
when_to_use: Invoke when creating the Budget app from scratch, continuing an existing implementation, auditing its quality, rebuilding a screen, applying the supplied visual identity, or preparing a release.
argument-hint: "[bootstrap|plan|build|continue|audit|verify|release] [optional scope]"
arguments:
  - mode
  - scope
disable-model-invocation: true
user-invocable: true
effort: max
allowed-tools: Read Write Edit Grep Glob Bash
---

# Budget V1 mission

Create a production-quality native iOS application named **Budget** that becomes the financial dashboard of Swiss households. Build the product from end to end, not a visual prototype. The application must remain useful without a backend, protect financial data, compile at every completed milestone, and preserve all domain invariants.

Invocation mode: **$mode**  
Optional scope: **$scope**

## Load the right references before acting

Read only the documents needed for the current task, but always load these first:

1. [PRODUCT_VISION.md](references/PRODUCT_VISION.md)
2. [ENGINEERING_CONTRACT.md](references/ENGINEERING_CONTRACT.md)
3. [DESIGN_SYSTEM.md](references/DESIGN_SYSTEM.md)
4. [REFERENCE_INDEX.md](references/REFERENCE_INDEX.md)

Then load the relevant specialist document:

- Models and calculations: [DATA_MODEL_AND_RULES.md](references/DATA_MODEL_AND_RULES.md)
- Screens and flows: [FUNCTIONAL_SPEC.md](references/FUNCTIONAL_SPEC.md)
- Architecture and folders: [ARCHITECTURE.md](references/ARCHITECTURE.md)
- Delivery sequence: [IMPLEMENTATION_ROADMAP.md](references/IMPLEMENTATION_ROADMAP.md)
- Tests and release gates: [QUALITY_PLAN.md](references/QUALITY_PLAN.md)
- Notion migration: [CSV_IMPORT_SPEC.md](references/CSV_IMPORT_SPEC.md)
- Launch and growth readiness: [RELEASE_AND_GROWTH.md](references/RELEASE_AND_GROWTH.md)

Inspect the visual files in `references/visual/` whenever the task touches UI, charts, branding, spacing, icons, colors, onboarding, screenshots, or App Store assets.

## Interpret the mode

### `bootstrap`

Create or normalize the project foundation. If no iOS project exists, create the project structure and implementation files that can be opened in Xcode. If an Xcode project already exists, inspect and improve it without destroying current work. Establish models, services, theme, demo data, tests, project status, and the first compilable vertical slice.

### `plan`

Audit the repository and produce a phased execution plan grounded in the actual code. Do not make broad implementation changes. Small diagnostic or documentation edits are allowed. Identify current state, missing foundations, risks, dependencies, and exact acceptance criteria.

### `build`

Implement the requested scope or the next incomplete roadmap phase. Finish the vertical slice fully: model, service, UI, previews, empty/error states, tests, build verification, and documentation.

### `continue`

Read `PROJECT_STATUS.md`, git history, current diff, tests, and TODOs. Resume from the first incomplete acceptance criterion. Do not restart completed work or replace working architecture without evidence.

### `audit`

Perform a rigorous product, architecture, financial-correctness, visual, accessibility, security, and performance audit. Fix high-confidence defects. Record larger redesigns as prioritized findings before changing them.

### `verify`

Run the complete applicable quality gate. Build the app, run unit tests, verify previews or simulator behavior where available, inspect data integrity, and report evidence. Do not claim success without command output or direct inspection.

### `release`

Complete production hardening, privacy copy, onboarding polish, accessibility, localization, export/backup flows, store metadata drafts, screenshots checklist, and final regression verification. Do not upload or publish without explicit permission.

If the mode is omitted, infer the safest useful mode from the repository. Prefer `plan` for a large unknown codebase and `continue` when `PROJECT_STATUS.md` clearly identifies the next task.

# Non-negotiable product contract

- Native iOS only: Swift 5.10+, SwiftUI, SwiftData, Swift Charts, iOS 17 minimum.
- iPhone first; layouts must remain adaptable for iPad and Dynamic Type.
- No external runtime dependency in V1 unless explicitly approved.
- Offline first. No backend is required for core use.
- Store monetary values as `Decimal`, never `Double` or binary floating point.
- Use stable identifiers and explicit relationships. Avoid hidden global mutable state.
- Use `fr-CH` formatting: `CHF 18’190.00` and `dd.MM.yyyy`.
- Planned and actual money are separate concepts.
- Savings and investments are not cost-of-living expenses.
- Internal transfers are neutral for income, expenses, savings rate, cash flow, and net worth.
- Tax provisioning is configurable and defaults to 30% of taxable income.
- Every active recurring charge appears in the month forecast.
- No financial ratio may produce `NaN` or infinity.
- Never silently discard an import row or financial error.
- No fake claim of live bank connectivity in V1.
- No personalized regulated financial advice. Present calculations as organizational estimates.
- Never embed the user's real personal financial data in source code or previews.

# Repository safety protocol

Before changing code:

1. Run `pwd`, inspect the directory tree, identify `.xcodeproj` or `.xcworkspace`, targets, schemes, deployment target, and test targets.
2. Run `git status --short --branch` and inspect relevant uncommitted changes.
3. Preserve unrelated work. Never reset, clean, delete, or overwrite user changes.
4. Read existing architecture and conventions before introducing a competing pattern.
5. Locate build and test commands from the project, CI, README, and scheme configuration.
6. Create `PROJECT_STATUS.md` from [PROJECT_STATUS_TEMPLATE.md](templates/PROJECT_STATUS_TEMPLATE.md) if absent.
7. Record material architectural choices in `DECISION_LOG.md` using [DECISION_LOG_TEMPLATE.md](templates/DECISION_LOG_TEMPLATE.md).

When the repository is empty, create a clean structure based on [ARCHITECTURE.md](references/ARCHITECTURE.md). Do not generate hundreds of placeholder files. Build a small compilable foundation, then grow it vertically.

# Mandatory execution loop

For every phase or screen:

1. **Understand** — inspect existing models, services, views, tests, and the canonical references.
2. **Specify** — state the user outcome and acceptance criteria in `PROJECT_STATUS.md`.
3. **Model** — add or adapt domain types and migrations before UI work.
4. **Calculate** — place financial logic in pure, testable services.
5. **Test first where risk is financial** — write invariant tests before or alongside implementation.
6. **Build UI** — implement the complete screen with loading, empty, populated, error, and edit states.
7. **Preview** — create deterministic SwiftUI previews using fictional demo data.
8. **Integrate** — connect navigation, persistence, validation, and related modules.
9. **Compile** — build the actual scheme. Fix warnings that indicate correctness or API issues.
10. **Verify** — run targeted tests, then the broader suite when the slice is stable.
11. **Inspect visually** — compare against the canonical brand board and chart reference. Correct spacing, clipping, contrast, hierarchy, and glass depth.
12. **Document** — update status, decisions, known limitations, and the next exact action.

Do not move to the next phase while the current acceptance criteria are incomplete, unless a blocker is documented with evidence.

# Build order

Follow the detailed roadmap, with this default sequence:

1. Project foundation, theme, formatting, persistence container, demo data, and tests.
2. Local onboarding and household profile.
3. Accounts and balances.
4. Transactions and strict validation.
5. Monthly dashboard and snapshots.
6. Monthly and annual budget.
7. Recurring transactions and subscriptions.
8. Tax profile and tax provisions.
9. Savings goals and emergency fund.
10. Insurance and contract register.
11. Swiss pension overview: pillars 1, 2, 3a, 3b.
12. Assets, liabilities, and net worth.
13. Documents, CSV import, export, backup, Face ID, and privacy controls.
14. Accessibility, localization, performance, release hardening, and App Store package.

A later phase may introduce future-ready types earlier when a relationship requires them, but avoid implementing incomplete screens out of sequence.

# Architecture rules

- Prefer feature folders and small focused types.
- Use SwiftData models for persisted entities and plain structs for derived snapshots and presentation data.
- Views may use `@Query`; nontrivial calculations must live in services or view models.
- Prefer constructor/environment injection over service singletons.
- Keep date, calendar, locale, exchange-rate, and “now” dependencies injectable for deterministic tests.
- Make Decimal arithmetic explicit and centralized.
- Treat transfers as linked double-entry-like movements or a single transfer entity with atomic balance effects; never duplicate them as income and expense.
- Use schema versions and migration planning from the beginning.
- Isolate file import/export and biometric authentication behind protocols.
- Keep demo and preview data out of production stores.
- Do not place formatting logic, persistence writes, or tax calculations directly in SwiftUI view bodies.

# UI and design rules

Use the canonical visual board as the primary direction, not as a pixel-for-pixel screenshot to copy.

- Mood: neutral, premium, reassuring, precise, human.
- Base: graphite and midnight navy with transparent layered glass cards.
- Accents: indigo, electric blue, restrained violet/cyan glow; amber only for attention.
- Positive: green; negative: coral red; warning: amber; informational: indigo/blue.
- Use soft frosted transparency, subtle inner highlights, one-pixel borders, gentle shadows, and controlled bloom.
- Avoid excessive neon, heavy gradients, noisy backgrounds, tiny text, and generic banking clichés.
- Use SF Pro/system typography in the actual app. Reproduce the hierarchy of the visual references without bundling font files.
- Charts must be legible before decorative: clear scale, restrained grid, meaningful highlights, accessible labels, and no misleading area encoding.
- Emojis are small lifestyle accents, not core navigation icons. Limit them to friendly greetings, goals, categories, and celebrations. Never use them as the sole meaning for critical data.
- The dashboard must answer within ten seconds: what is available, what came in, what went out, what is reserved, and what requires action.
- Every polished screen needs light/dark behavior, Dynamic Type, VoiceOver labels, reduced-motion behavior, and color-independent status cues.

Use [DesignTokens.swift](examples/DesignTokens.swift), [GlassCard.swift](examples/GlassCard.swift), and [FinanceFormatting.swift](examples/FinanceFormatting.swift) only as patterns; adapt them to the actual repository rather than copying blindly.

# Financial correctness gates

Before marking a feature complete, verify all applicable rules:

- Planned amount and actual amount are independently queryable.
- Savings rate = `(savings + investments) / income`, safely returning zero when income is zero.
- Cost of living excludes savings, investments, and internal transfers.
- An internal transfer changes account balances but not household net worth.
- Tax provision distinguishes recommended, reserved, paid, outstanding, and arrears.
- Available-to-spend subtracts committed future charges, tax reserve, debt payments, and committed goals according to the defined policy.
- Net worth = included assets − included liabilities.
- Investment contribution and market-value change are distinguishable.
- Active subscriptions forecast correctly for monthly, quarterly, annual, and custom schedules.
- Validation rejects missing dates, nonpositive amounts where inappropriate, missing accounts/categories, and invalid transfer destinations.
- Imported rows are reproducible, traceable, and idempotent.

# Quality gate

A phase is complete only when:

- The actual app target compiles.
- Relevant unit tests pass.
- No known crash path exists in normal use.
- Empty, first-use, populated, validation-error, and edge states are handled.
- SwiftUI previews compile for meaningful screen states.
- Financial values use `Decimal` end to end.
- Accessibility labels and Dynamic Type have been inspected.
- The screen visually aligns with the reference identity.
- Persistence survives relaunch in a manual or automated check.
- Status documentation reflects reality.

For release verification, also require the complete checklist in [QUALITY_PLAN.md](references/QUALITY_PLAN.md).

# Decision behavior

- Make sensible reversible defaults without interrupting the user.
- Ask only when blocked by an irreversible product decision, missing legal/commercial requirement, unavailable signing credential, or destructive data migration.
- When uncertain, inspect evidence before redesigning.
- Prefer a smaller finished vertical slice over a broad unfinished implementation.
- Never claim an action, build, test, simulator verification, or migration succeeded unless it was actually performed.
- Do not push, publish, purchase, or alter production services without explicit permission.

# Progress output

At the end of each invocation, provide:

1. What was completed.
2. Files and modules materially changed.
3. Build and test evidence.
4. Remaining risks or blockers.
5. The next exact phase or command.

Also update `PROJECT_STATUS.md` so another session can resume without re-discovering the project.

# Definition of Budget V1 done

Budget V1 is done only when a new Swiss user can install the app, complete onboarding, create accounts, enter/import transactions, distinguish planned from actual money, understand the month dashboard, manage recurring charges, reserve taxes, track goals, record insurance and pension data, view net worth, export/backup data, protect access with Face ID, and use the core experience offline without crashes or misleading calculations.
