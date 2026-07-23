# Budget — authority for Claude Code

Use only the project skill `/budget-v1` for substantial work on Budget.

## Active programme

- Programme: **Budget — Obsidian Glass**
- Required branch: `refonte/budget-obsidian-glass-v1`
- Source branch: `codex/budget-leader-refonte`
- Progress source: `OBSIDIAN_GLASS_STATUS.md`
- Visual constitution: `.claude/skills/budget-v1/references/OBSIDIAN_GLASS_CONSTITUTION.md`
- Delivery plan: `.claude/skills/budget-v1/references/OBSIDIAN_GLASS_DELIVERY.md`
- Screen contract: `.claude/skills/budget-v1/references/OBSIDIAN_GLASS_SCREEN_MATRIX.md`

All other Budget skills are legacy references. Do not invoke them, combine their
roadmaps, or let them override `/budget-v1`. Preserve useful existing code and
domain decisions, but treat this file and `/budget-v1` as the only operational
authority.

## Working protocol

1. Confirm the active branch and inspect `git status`.
2. Read this file, `/budget-v1`, `OBSIDIAN_GLASS_STATUS.md`,
   `PROJECT_STATUS.md`, and `DECISION_LOG.md`.
3. Execute exactly one Obsidian Glass lot per session.
4. State acceptance criteria before editing.
5. Preserve all existing functionality and financial history.
6. Add or update tests before declaring a risky financial or persistence change complete.
7. Build, test, inspect rendered screens, and produce before/after captures.
8. Update `OBSIDIAN_GLASS_STATUS.md` with evidence and the next exact action.
9. Make one focused commit for the lot, then stop for review.

Do not merge, deploy, publish, alter the default branch, close existing PRs, or
start the next lot without explicit approval.

## Product invariants

- Native: SwiftUI + SwiftData + Swift Charts, iOS 17+.
- PWA remains functional, installable, honest about local storage, and offline-capable.
- Financial amounts use `Decimal` in native code; never silently coerce invalid values to zero.
- Planned and actual money remain separate.
- Savings and investments are not living expenses.
- Internal transfers are neutral for household metrics and net worth.
- Historical amounts never change because a current exchange rate changed.
- No fake bank connection, no fake live data, and no personalized regulated advice.
- Preserve stable identifiers, migrations, backups, privacy behavior, and user history.
- Use `fr-CH` formatting and plain French understandable by a ten-year-old.

## Visual authority

Obsidian Glass is a single dark identity. There is no decorative light theme and
no palette selector in this programme. Use one brand hue, Indigo Aurora
`#7367FF`; green, coral, and amber are semantic only.

Glass must improve hierarchy, not reduce readability. Respect Dynamic Type,
VoiceOver, 44-point targets, reduced motion, increased contrast, and reduced
transparency. When transparency is reduced, replace blur with an opaque graphite
surface.

