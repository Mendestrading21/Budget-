# Budget — index des documents

Carte du dépôt documentaire. L’histoire est préservée; cet index indique
ce qui fait foi aujourd’hui.

## Autorité actuelle

| Document | Rôle |
|---|---|
| `README.md` | Présentation du produit, architecture et commandes |
| `CLAUDE.md` | Protocole opérationnel et invariants |
| `BUDGET_1_0_READINESS.md` | Porte de sortie de la version 1.0 |
| `BUDGET_PRISME_STATUS.md` | Journal détaillé des lots, preuves et incidents |
| `BUDGET_FAMILLES_PLAN.md` | Matrice des quatre familles |
| `FINANCIAL_ENGINE_V2.md` | Contrat des cinq chiffres et lots FE2 |
| `.claude/skills/budget-prisme/` | Skill maître et références |
| `.claude/skills/README.md` | Statut et priorité des skills |
| `DECISION_LOG.md` | ADR structurelles |
| `CHANGELOG.md` | Changements destinés aux releases |
| `webapp/tests/` | e2e navigateur, parité et design |
| `fixtures/parity-fixtures.json` | Fixtures financières canoniques |

## Qualité, contribution et sécurité

| Document | Rôle |
|---|---|
| `CONTRIBUTING.md` | Règles de branche, tests et PR |
| `SECURITY.md` | Signalement et traitement des vulnérabilités |
| `.github/PULL_REQUEST_TEMPLATE.md` | Preuves obligatoires par PR |
| `.github/ISSUE_TEMPLATE/` | Rapports structurés |
| `.github/scripts/repository-audit.mjs` | Audit automatisé du dépôt |
| `.github/workflows/ci.yml` | Structure, web et iOS |
| `.github/workflows/pages.yml` | Déploiement Pages au SHA exact |
| `.github/workflows/testflight.yml` | TestFlight au SHA exact |

## Publication

| Document | Rôle |
|---|---|
| `APP_STORE_LISTING.md` | Fiche candidate; assertions à valider sur la build finale |
| `TESTFLIGHT_SETUP.md` | Configuration et exécution TestFlight |
| `MANUAL_QA_CHECKLIST.md` | QA de l’artefact sur appareil réel |
| `BUDGET_1_0_READINESS.md` | Enregistrement du GO/NO-GO et des runs |

## Code et preuves

- **iOS** : `Budget/`; tests `BudgetTests/` et `BudgetUITests/`; projet
  `Budget.xcodeproj`.
- **PWA** : `webapp/index.html`, design system, service worker, manifeste
  et icônes.
- **Preuves Prisme** :
  `docs/neon-ultra/budget-prisme/<lot>/`.
- **Marque** : `branding/`.
- **CI et publication** : `.github/workflows/`.

## Histoire préservée

| Emplacement | Programme |
|---|---|
| `PROJECT_STATUS.md`, `NEON_ULTRA_STATUS.md` | Neon Ultra |
| `archives/OBSIDIAN_GLASS_STATUS.md` | Obsidian Glass |
| `archives/BUDGET_MASTER_STATUS.md` | Budget Master Evolution |
| `archives/HORIZON_REFONTE_PLAN.md` | Refonte Horizon |
| `archives/AUDIT_COMPLET_BUDGET_2026-07-21.md` | Audit du 21 juillet 2026 |
| `archives/docs/`, anciennes preuves `docs/neon-ultra/` | Programmes précédents |
| `.claude/skills/budget-neon-ultra/` | Skill historique |

L’historique n’est pas réécrit. Lorsqu’une information ancienne est
obsolète, la source actuelle la remplace par référence explicite.
