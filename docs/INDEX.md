# Budget — index des documents

Carte de tous les documents du dépôt. Rien n'est réécrit : l'histoire
reste où elle est, cet index dit seulement ce qui fait foi aujourd'hui.

## Fait foi aujourd'hui

| Document | Rôle |
|---|---|
| `CLAUDE.md` | Autorité opérationnelle (programme actif, protocole, invariants) |
| `BUDGET_PRISME_STATUS.md` | Statut vivant du programme Budget Prisme (lots, preuves, publications) |
| `BUDGET_FAMILLES_PLAN.md` | Matrice « Les quatre familles partout » (concept + lots A8→A12) |
| `.claude/skills/budget-prisme/` | Skill maître et ses six références (finance, langue, registre des pages, workflow, preuves, release) |
| `DECISION_LOG.md` | ADR — décisions structurelles, toujours valides sauf remplacement explicite |
| `docs/neon-ultra/budget-prisme/` | Preuves par lot (captures avant/après, rapports de sonde) |
| `webapp/tests/` | Suites e2e navigateur, parité web↔natif, design system |
| `fixtures/parity-fixtures.json` | Fixtures de parité des calculs |

## Préparation publication (à tenir à jour au moment voulu)

| Document | Rôle |
|---|---|
| `APP_STORE_LISTING.md` | Fiche App Store préparée (décisions propriétaire marquées HUMAN REQUIRED) |
| `TESTFLIGHT_SETUP.md` | Procédure TestFlight |
| `MANUAL_QA_CHECKLIST.md` | QA manuelle iPhone réel |

## Histoire préservée (ne jamais réécrire)

| Document | Programme d'origine |
|---|---|
| `PROJECT_STATUS.md`, `NEON_ULTRA_STATUS.md` | Neon Ultra (bannières de renvoi vers Prisme en tête) |
| `archives/OBSIDIAN_GLASS_STATUS.md` | Obsidian Glass (L0–L9) |
| `archives/BUDGET_MASTER_STATUS.md` | Budget Master Evolution |
| `archives/HORIZON_REFONTE_PLAN.md` | Refonte Horizon (R1–R9) |
| `archives/AUDIT_COMPLET_BUDGET_2026-07-21.md` | Audit complet du 21.07.2026 |
| `archives/docs/`, `docs/neon-ultra/` (hors `budget-prisme/`) | Preuves des programmes précédents |
| `.claude/skills/` (hors `budget-prisme/`) | Skills hérités — références seulement |

## Où vivent les choses

- **PWA** : `webapp/index.html` (app monofichier) + `webapp/design-system/neon-ultra.css` (tokens et primitives) + `webapp/sw.js`, `manifest.webmanifest`, icônes.
- **iOS natif** : `Budget/` (SwiftUI + SwiftData), tests `BudgetTests/`, UI `BudgetUITests/`, projet `Budget.xcodeproj`.
- **Marque** : `branding/`.
- **CI** : `.github/workflows/` — la publication Pages passe par le dispatch de `pages.yml` au SHA exact (voir `CLAUDE.md`).
