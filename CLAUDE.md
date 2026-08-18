# Budget — authority for Claude Code

Use only the project skill `/budget-prisme` for substantial work on
Budget.

## Active programme

- Programme: **Budget Prisme**, followed by the release-hardening programme
  **Budget 1.0**.
- Release branch: **`main`**. All work flows through a short-lived
  `agent/prisme-*` or `agent/release-*` branch → French PR → green CI on
  the exact HEAD → squash merge → green `push` CI on the merge SHA.
- Release gate: `BUDGET_1_0_READINESS.md`.
- Detailed engineering journal: `BUDGET_PRISME_STATUS.md`. It preserves
  lot-by-lot evidence; it is not a substitute for the current release
  checklist.
- Publishing:
  - GitHub Pages deploys only through a manual dispatch of `pages.yml`
    **from `main`**, with `{"sha":"<full green main SHA>"}`.
  - TestFlight deploys only through a manual dispatch of `testflight.yml`
    **from `main`**, with the same full SHA.
  - Never release from the repository’s implicit/default branch selection.
- Concept grid: `BUDGET_FAMILLES_PLAN.md` — the four families
  (Rentrées · Dépenses · Abonnements · Mis de côté), same order, same
  glyphs and same semantic colours on every surface. Each franc lives in
  exactly one family; internal transfers remain transversal and neutral.
- Skill references: `.claude/skills/budget-prisme/references/`. They
  prevail over legacy skills.
- Financial views: `FINANCIAL_ENGINE_V2.md` prevails over the obsolete
  hero wording in section 8 of `STYLE.md`. FE2-0 à FE2-3 sont
  fusionnés; FE2-4 et les créances restent des décisions explicites de
  périmètre avant le tag final.

`/budget-neon-ultra` is a preserved historical reference. `/apple-design`
may support visual work but never overrides `/budget-prisme`, the product
invariants or the financial engine. The skills map is
`.claude/skills/README.md`.

The Obsidian Glass and Neon Ultra history (`OBSIDIAN_GLASS_STATUS.md` in
`archives/`, `NEON_ULTRA_STATUS.md`, `PROJECT_STATUS.md`) is preserved
as-is and is never rewritten. `docs/INDEX.md` maps every document.

## Working protocol (per lot)

1. After any container restart: `git fetch origin main`, then
   `git checkout -B main origin/main`, and verify `git log -1` lineage
   before branching. Never build on a stale clone.
2. Read this file, `BUDGET_1_0_READINESS.md`,
   `BUDGET_PRISME_STATUS.md`, `BUDGET_FAMILLES_PLAN.md`, and the
   `/budget-prisme` references relevant to the lot.
3. One focused lot per PR. Measure first, then fix, then prove.
4. Financial defects require a failing regression test before the fix and
   a negative control after it.
5. Tests are additive. The browser e2e, parity, design and iOS suites must
   remain green. Do not hard-code their counts in living documentation.
6. For layout work, inspect before/after captures at 390 px and at 320 px
   when narrow geometry is affected. Store evidence under
   `docs/neon-ultra/budget-prisme/<lot>/`.
7. Run `node .github/scripts/repository-audit.mjs` before opening a PR.
8. Update the relevant living status/readiness document, commit one
   coherent lot, open a French PR, wait for green CI on the exact HEAD,
   squash merge, then wait for green `push` CI on the merge SHA.
9. Never push directly to `main`; never disable TLS or unset
   `HTTPS_PROXY`; use fictional data only in tests, captures and demos.

## Product invariants

- Native: SwiftUI + SwiftData + Swift Charts, iOS 17+, iPhone only
  (`UIDeviceFamily == [1]`, ADR-023).
- PWA remains functional, installable, honest about local storage and
  offline-capable.
- Financial amounts use `Decimal` in native code; never silently coerce
  invalid values to zero.
- Actual, planned and projected money remain separate.
- A future date never silently promotes planned money to actual money.
- Savings and investments are not living expenses.
- Internal transfers are neutral for household metrics and net worth.
- Historical amounts never change because a current exchange rate changed.
- Household debts remain liabilities. If receivables (money owed to the
  household) are introduced, they require a distinct model and must never
  be silently treated as income or merged with liabilities.
- No fake bank connection, fake live data or personalised regulated advice.
- Preserve stable identifiers, migrations, backups, privacy behaviour and
  user history.
- Use `fr-CH` formatting and plain French understandable by a ten-year-old.
- Amounts are unbreakable words (NBSP after the currency prefix) and are
  never truncated or wrapped mid-token.

## Visual authority

Budget Prisme keeps one dark identity: deep black surfaces with magenta
`#D946EF`, violet `#7C3AED` and cyan `#38BDF8` accents, with CTA gradient
`#C000A4 → #6E00E8`. Approximately 75% of the interface remains
black/graphite, at most 10% neon, with one major luminous focal point per
viewport. There is no glow around amounts and no casino aesthetic.
Green, coral and amber are semantic only.

Budget Glyphs (stroke 1.75, viewBox 24, `currentColor`) are the functional
iconography. Do not add functional emoji. Country flags, user-chosen goal
emoji and real milestone celebrations may remain.

Respect Dynamic Type, VoiceOver, WCAG AA body text, 44-point targets,
reduced motion, increased contrast and reduced transparency. When
transparency is reduced, replace blur with opaque surface `#151923`.

## Navigation (ADR-026)

PWA and iOS use the same five stable destinations:

`Mois` · `Historique` · `Budget` · `Comptes` · `Gérer`

There is no global centred or floating add button. `Mois` carries the
primary operation action; other screens expose only contextual actions.

## Budget 1.0 release discipline

A build is not Budget 1.0 merely because `MARKETING_VERSION` equals `1.0`.
The release exists only when all P0 criteria in
`BUDGET_1_0_READINESS.md` are checked against one immutable SHA.

Before a final tag or App Store submission:

- repository default branch is `main`;
- `main` is protected against direct/forced pushes and deletion;
- exact-SHA CI is green;
- Pages and TestFlight artefacts originate from that SHA;
- manual QA is signed on a real iPhone;
- privacy text, App Store listing and screenshots match observed behaviour;
- no P0/P1 financial defect remains open;
- version/build metadata and `CHANGELOG.md` are frozen;
- the owner has made an explicit licence decision.
