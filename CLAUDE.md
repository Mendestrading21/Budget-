# Budget — authority for Claude Code

Use only the project skill `/budget-neon-ultra` for substantial work on Budget.

The skill `/apple-design` (`.claude/skills/apple-design/SKILL.md`) is an
**active companion reference** for interaction feel: instant response,
gesture-driven motion, springs, spatial consistency, materials, typography
and reduced-motion. It complements — never overrides — the Neon Ultra
constitution: palette, hierarchy, navigation and accessibility rules stay
governed by ADR-024/ADR-026 and the invariants below.

## Active programme

- Programme: **Budget v1 — Neon Ultra** (ADR-024, unifié en v1 le 13.08.2026)
- Required branch: **`main`** (la seule branche ; l'historique des anciennes
  branches vit dans les tags `archive/…`)
- Progress source: `NEON_ULTRA_STATUS.md`
- Visual constitution: `.claude/skills/budget-neon-ultra/references/NEON_ULTRA_CONSTITUTION.md`
- Delivery plan: `.claude/skills/budget-neon-ultra/references/NEON_ULTRA_DELIVERY.md`
- Screen contract: `.claude/skills/budget-neon-ultra/references/NEON_ULTRA_SCREEN_MATRIX.md`
- Repository contract: `.claude/skills/budget-neon-ultra/references/REPOSITORY_CONTRACT.md`

The previous programmes (Obsidian Glass, Horizon, Master Evolution) and
their six skills live under `archives/` — historical record only. Do not
invoke them, combine their roadmaps, or let them override
`/budget-neon-ultra`. Their reports (L0–L9 included) are preserved as-is
and are never rewritten.

## Working protocol

1. Confirm the active branch (`main`) and inspect `git status`.
2. Read this file, `/budget-neon-ultra`, `NEON_ULTRA_STATUS.md`,
   `PROJECT_STATUS.md`, and `DECISION_LOG.md`.
3. Execute exactly one lot per session.
4. State acceptance criteria before editing.
5. Preserve all existing functionality and financial history.
6. Add or update tests before declaring a risky financial or persistence change complete.
7. Build, test, inspect rendered screens, and produce before/after captures.
8. Update `NEON_ULTRA_STATUS.md` with evidence and the next exact action.
9. Make one focused commit for the lot, then stop for review.

Do not merge, deploy, publish, close existing PRs, or start the next lot
without explicit approval. Pushing `webapp/**` to `main` deploys the PWA
to GitHub Pages — a push to `main` IS a publish; treat it with that level
of care (full local validation first, CI must be green).

## Product invariants

- Native: SwiftUI + SwiftData + Swift Charts, iOS 17+, iPhone only
  (`UIDeviceFamily == [1]`, ADR-023).
- PWA remains functional, installable, honest about local storage, and offline-capable.
- Financial amounts use `Decimal` in native code; never silently coerce invalid values to zero.
- Planned and actual money remain separate.
- Savings and investments are not living expenses.
- Internal transfers are neutral for household metrics and net worth.
- A set-aside always has a destination account — money never evaporates (ADR-029).
- Historical amounts never change because a current exchange rate changed.
- No fake bank connection, no fake live data, and no personalized regulated advice.
- Preserve stable identifiers, migrations, backups, privacy behavior, and user history.
- Use `fr-CH` formatting and plain French understandable by a ten-year-old.

## Visual authority

Neon Ultra is a single dark identity (ADR-024): deep black surfaces with
magenta `#D946EF`, violet `#7C3AED`, and cyan `#38BDF8` accents, CTA gradient
`#C000A4 → #6E00E8`. 75% black/graphite, at most 10% neon, one major luminous
focal point per viewport, no glow around amounts, no casino aesthetics; green,
coral, and amber are semantic only. Full rules in the Neon Ultra constitution.

Respect Dynamic Type, VoiceOver, WCAG AA body text, 44-point targets, reduced
motion, increased contrast, and reduced transparency. When transparency is
reduced, replace any blur with the opaque surface `#151923`.

## Navigation (ADR-026)

PWA and iOS use the same five stable destinations: `Mois`, `Historique`,
`Budget`, `Comptes`, `Gérer`. There is no global centered or floating
add button. The home screen carries one primary movement action; each other
screen owns only its useful contextual action.
