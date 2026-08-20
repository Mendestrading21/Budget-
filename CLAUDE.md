# Budget — authority for Claude Code

Use the project skill `/budget-prisme` as the primary authority for substantial
work on Budget. For catalogues, services, subscriptions, banks, brokers,
insurers, local identities, logos, monograms or recurring cadence presets, also
load the companion skill `/budget-identites-locales`. The companion never
overrides Budget Prisme's financial, data, design, evidence or release rules.

## Active programme

- Programme : **Budget Prisme** — pages P00–P18 terminées, puis
  améliorations continues (lots A1+) et le programme
  **« Les quatre familles partout »** (`BUDGET_FAMILLES_PLAN.md`).
- Release branch: **`main`**. All work flows through a short-lived
  `agent/prisme-*` branch → French PR → green CI on the exact HEAD →
  squash merge → publish.
- Publishing: GitHub Pages deploys ONLY via workflow dispatch of
  `pages.yml` at ref `refonte/budget-neon-ultra-v1` with inputs
  `{"sha": "<full merge sha>"}`. The auto-deploy step from `main` is
  blocked by the `github-pages` environment rule (owner click pending) —
  its failure on merge commits is expected and documented.
- Progress source: `BUDGET_PRISME_STATUS.md` (living status).
- Concept grid: `BUDGET_FAMILLES_PLAN.md` — the four families
  (Rentrées · Dépenses · Abonnements · Mis de côté), same order, same
  glyphs, same semantic colors on every surface; strict partition —
  each franc lives in exactly one family; internal transfers stay
  transversal and neutral.
- Skill references: `.claude/skills/budget-prisme/references/`
  (finance/data, language, page registry, page workflow, quality
  evidence, GitHub release) — they prevail over legacy skills.
- Local identities companion:
  `.claude/skills/budget-identites-locales/` (catalogue CH/FR/BE, safe
  monograms, brand provenance, recurrence requirements and validator). Use it
  only together with `/budget-prisme` on its declared scope.

Except for the declared companion `/budget-identites-locales`, all other Budget
skills (`/budget-v1`, `/budget-neon-ultra`,
`/budget-horizon`, `/budget-master-evolution`, `/budget-2027`,
`/budget-web`, `/budget-production-completion` included) are legacy
references. Do not invoke them, combine their roadmaps, or let them
override `/budget-prisme`. Preserve useful existing code and domain
decisions. The Obsidian Glass and Neon Ultra history (L0–L9 and NU
reports, `OBSIDIAN_GLASS_STATUS.md` in `archives/`, `NEON_ULTRA_STATUS.md`,
`PROJECT_STATUS.md`) is preserved as-is and is never rewritten.
`docs/INDEX.md` maps every document.

## Working protocol (per lot)

1. After ANY container restart: `git fetch origin main` then
   `git checkout -B main origin/main` and verify `git log -1` lineage
   BEFORE branching. Never build on a stale clone.
2. Read this file, `BUDGET_PRISME_STATUS.md`, `BUDGET_FAMILLES_PLAN.md`,
   and the `/budget-prisme` references relevant to the lot.
3. One focused lot per PR. Measure first (geometry/behaviour probe),
   then fix, then prove.
4. Tests are additive: the e2e browser suite (`webapp/tests/e2e.test.mjs`),
   5 parity fixtures, and the design suites must stay green; every lot
   adds its own test. Prove each fix with a negative control (targeted
   sabotage → targeted failures → restore green).
5. Before/after captures at 390 px (and 320 px when layout is involved),
   actually inspected, stored under `docs/neon-ultra/budget-prisme/<lot>/`.
6. Update `BUDGET_PRISME_STATUS.md` with evidence, then commit (French,
   one lot), PR, wait for green CI on the exact HEAD, squash merge, wait
   for green CI on `main` (deploy step excepted), publish by dispatch at
   the exact SHA, record the run id in the status file.
7. Never push directly to `main`; never disable TLS or unset HTTPS_PROXY;
   fictional data only in tests and captures.

## Product invariants

- Native: SwiftUI + SwiftData + Swift Charts, iOS 17+, iPhone only
  (`UIDeviceFamily == [1]`, ADR-023).
- PWA remains functional, installable, honest about local storage, and offline-capable.
- Financial amounts use `Decimal` in native code; never silently coerce invalid values to zero.
- Planned and actual money remain separate.
- Savings and investments are not living expenses.
- Internal transfers are neutral for household metrics and net worth.
- Historical amounts never change because a current exchange rate changed.
- No fake bank connection, no fake live data, and no personalized regulated advice.
- Preserve stable identifiers, migrations, backups, privacy behavior, and user history.
- Use `fr-CH` formatting and plain French understandable by a ten-year-old.
- Amounts are unbreakable words (NBSP after the currency prefix) and are
  never truncated or wrapped mid-token.

## Visual authority

Budget Prisme keeps the single dark identity (ADR-024 base): deep black
surfaces with magenta `#D946EF`, violet `#7C3AED`, cyan `#38BDF8`
accents, CTA gradient `#C000A4 → #6E00E8`. 75% black/graphite, at most
10% neon, one major luminous focal point per viewport, no glow around
amounts, no casino aesthetics; green, coral, and amber are semantic only
(green = money in, coral = money out, violet neutral = set aside).
Budget Glyphs (stroke 1.75, viewBox 24, currentColor) are the only
iconography — no functional emojis; country flags, user-chosen goal
emojis and real-milestone 🎉 stay. Full rules in
`.claude/skills/budget-prisme/references/` and the Neon Ultra
constitution it builds on.

Within `BudgetIdentityIcon` only, a safe monogram or a provenance-approved
local brand asset may decorate an explicitly named service or institution.
These identity marks never replace Budget Glyphs for actions, financial
meaning, categories, navigation or status.

Respect Dynamic Type, VoiceOver, WCAG AA body text (nothing under 10 px),
44-point targets, reduced motion, increased contrast, and reduced
transparency. When transparency is reduced, replace any blur with the
opaque surface `#151923`.

## Navigation (ADR-026)

PWA and iOS use the same five stable destinations: `Mois`, `Historique`,
`Budget`, `Comptes`, `Gérer`. There is no global centered or floating
add button. The home screen carries one primary movement action; each
other screen owns only its useful contextual action.
