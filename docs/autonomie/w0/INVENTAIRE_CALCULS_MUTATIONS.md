# W0.4 — Inventaire des calculs et mutations Web/iOS

Mesuré au SHA `bcef018` (grep réel, pas de mémoire). Cet inventaire délimite ce
que W1 doit couvrir en fixtures et ce que W3 remplacera par le journal. Rien
n'est modifié.

## Calculs financiers — PWA (`webapp/index.html`, lignes au SHA)

| Fonction | Ligne | Rôle | Lot cible |
|---|---:|---|---|
| `toCHF` / `txCHF` / `convertAmount` | 1862 / 1867 / 2011 | conversion de devise (taux stockés, sans date/source par ligne) | W4 |
| `pensionPositionsTotal` | 2552 | prévoyance capitalisée (rentes exclues, ADR-036) | W8 |
| `balance` | 2641 | solde d'un compte (`posted` seulement, centimes) | W3 |
| `accountMonthFlows` | 2660 | entrées/sorties du mois d'un compte (ADR-057) | W3 |
| `recurringRemainingCount` | 2753 | échéances restantes non couvertes d'un mois (REC2) | W2 |
| `snapshot` | 2871 | agrégats du mois : liquid, prévu, projection, trio, cashFlow | W1/W3 |
| `estimationEnchainee` | 2953 | estimation des mois futurs, enchaînée (ADR-056) | W2/W6 |
| `liabilitiesTotal` | 2977 | total des dettes incluses | W3 |
| `monthCheckItems` | 2989 | rituel « boucler le mois » | W5 |
| `budgetReport` | 3131 | enveloppes planifié/réel (`categoryKind`, ADR-051) | W6 |
| `goalCurrent` | 4327 | avancement d'objectif | W6 |
| `fortuneTotale` | 4440 | fortune totale UNIQUE (ADR-053) | W3/W4 |
| `taxSummary` | 4446 | réserve/payé/dû d'impôts, 100 % saisis (ADR-035) | W8 |
| `contributions` / `contributionsFor` | 4504 / 4524 | versements par compte/genre | W8 |
| `balanceAt` | 4533 | solde historique fin de mois | W3 |

## Calculs financiers — iOS (`Budget/Domain/Services/`)

| Service | Rôle | Lot cible |
|---|---|---|
| `AccountBalanceService` | solde, `signedEffect` par mouvement | W3 |
| `MonthlySnapshotService` | agrégats du mois (`MonthSnapshot`) | W1/W3 |
| `RecurringScheduleService` | prévision des échéances en mémoire | W2 |
| `NetWorthService` | fortune totale, épargne accessible, fortune liquide | W3/W4 |
| `GoalProgressService` / `GoalProjectionService` | objectifs | W6 |
| `ContributionService` | versements | W8 |
| `TaxService` | impôts saisis (ADR-035) | W8 |
| `InsurancePensionService` | rente ≠ capital (ADR-036) | W8 |
| `WealthProjectionService` | projections de patrimoine | W6/W8 |
| `YearStatsService` | agrégats annuels | W6 |
| `TransactionValidationService` | validation des mouvements (dont la politique de statut par date — constat n° 3) | W2 |
| `CSVImportService` | import (empreinte liée au fichier — constat audit) | W7 |
| `BackupService` | sauvegarde/restauration versionnée | W10 |
| `BrokeragePositionMath` (`Models/`) | positions explicatives, jamais additives (ADR-047) | W8 |

## Mutations d'état — PWA

| Mutation | Mécanisme mesuré | Risque connu | Lot |
|---|---|---|---|
| `addTx` + `saveState` | push tableau + `localStorage` monolithique | pas de transaction ; quota → erreur visible à vérifier par fixture | W9 |
| Confirmation « Reçu/Payé » | `planned` → `posted` | pas d'idempotency key ; double tap à couvrir | W2 |
| « Mettre le solde à jour » | crée un `adjustment` `posted` neutre daté | conforme (correction traçable) | — |
| `validatedRestoreState` | restauration validée avant remplacement, entrées invalides refusées/filtrées | filtres tolérants : le REJET total vs. l'ABANDON d'entrée doit devenir contractuel | W10 |
| Import CSV | préview puis écriture | empreinte dépendante du nom de fichier/ligne | W7 |
| `pushUndo` / listes d'annulation | instantanés en mémoire | rollback dépendant de l'état UI (interdit cible) | W9 |
| `deleteAllData` | remise à zéro (positions comprises) | conforme | — |
| `rememberCustomCategory` | catégories libres additives (ADR-051) | conforme | — |

## Mutations d'état — iOS

| Mutation | Mécanisme | Risque connu | Lot |
|---|---|---|---|
| `modelContext.insert/delete` + `save` | SwiftData | erreurs de save affichées (`saveErrorMessage`) ; atomicité multi-objet à contractualiser | W2/W3 |
| Confirmation d'échéance | crée le mouvement lié au `recurringId` | occurrence non persistée (constat n° 4) | W2 |
| Restauration | `BackupService` valide avant écriture | schémas historiques non figés (constat n° 7) | W10 |
| Gardes de suppression | compte référencé (récurrents, objectifs, positions) refusé | conforme (P06, INV1-B/C) | — |

## Doubles vérités à surveiller (aucune nouvelle autorisée)

- solde : `balance()` ↔ `AccountBalanceService` ;
- mois : `snapshot()` ↔ `MonthlySnapshotService` ;
- fortune : `fortuneTotale()` ↔ `NetWorthService` ;
- échéances : compteurs PWA ↔ `RecurringScheduleService` ;
- impôts : `taxSummary` ↔ `TaxService` (unifiés par fixtures depuis #70 Lot B).

Chaque paire DOIT recevoir une fixture canonique W1. Toute nouvelle formule
introduite avant W3 doit naître avec sa fixture des deux côtés.
