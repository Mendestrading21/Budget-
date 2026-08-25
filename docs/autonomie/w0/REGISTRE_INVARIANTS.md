# W0.5 — Registre des invariants

État mesuré de chaque invariant FI-01…FI-40
(`.claude/skills/budget-autonomie-100/references/FINANCIAL_INVARIANTS.md`) au
SHA `bcef018`. Trois verdicts : `TENU` (code + test), `PARTIEL` (comportement
présent mais contrat incomplet), `OUVERT` (à construire). Le lot qui ferme
chaque invariant est nommé. Ce registre est le contrat de vérité : un lot qui
touche un invariant `TENU` doit garder son test vert, un lot qui ferme un
invariant `OUVERT` doit le faire passer à `TENU` avec fixture des deux côtés.

| ID | Invariant (résumé) | Verdict | Preuve/écart mesuré | Lot |
|---|---|---|---|---|
| FI-01 | Prévu ne modifie aucun solde | TENU | `balance()`/`AccountBalanceService` ne lisent que `posted` ; parcours 176/178 | gardé par W1 |
| FI-02 | Date ≠ preuve | OUVERT | la politique de saisie classe date passée → `posted` (constat n° 3) | W2 |
| FI-03 | Occurrence à identité persistée | OUVERT | occurrences en mémoire, « couvertes » par comptage (constat n° 4) | W2 |
| FI-04 | Confirmation idempotente | OUVERT | pas d'idempotency key sur « Reçu/Payé » | W2 |
| FI-05 | Montant attendu ≠ montant réel conservés | PARTIEL | montant modifiable à la confirmation, l'attendu n'est pas conservé à part | W2 |
| FI-06 | pending ≠ posted ≠ cleared ≠ reconciled | OUVERT | seuls `planned/posted` existent | W3 |
| FI-07 | Mouvement rapproché immuable | OUVERT | pas d'état rapproché ; l'histoire est réécrite (constat n° 5) | W3 |
| FI-08 | Écriture équilibrée par devise | OUVERT | pas de journal à postings | W3 |
| FI-09 | Transfert atomique et neutre | PARTIEL | neutre dans les agrégats et testé ; pas d'écriture atomique unique | W3 |
| FI-10 | Épargne interne ≠ coût de vie | TENU | invariant produit historique, testé (parités, e2e) | gardé |
| FI-11 | Solde dérive des écritures comptabilisées | TENU | aucun terme de prévision dans `balance()` | gardé |
| FI-12 | Solde d'ouverture = une écriture | OUVERT | `opening` est une propriété du compte | W3 |
| FI-13 | Compte archivé garde l'histoire | PARTIEL | archivage présent ; rapports passés non verrouillés par test dédié | W4 |
| FI-14 | Dette : capital/intérêts/frais distincts | TENU | `isDebtPayment`, parité D04/ADR-016 | gardé |
| FI-15 | Un montant porte une devise | PARTIEL | devises portées par comptes/positions, `Decimal`/nombres nus dans les agrégats | W4 |
| FI-16 | Conversion avec taux/source/date | OUVERT | taux stockés sans date ni source par conversion | W4 |
| FI-17 | Taux absent ≠ 1 ou 0 | OUVERT | à contractualiser (patrimoine « incomplet ») | W4 |
| FI-18 | Arrondi déterministe | PARTIEL | centimes entiers PWA (G01), `Decimal` iOS ; pas de contrat commun testé | W1 |
| FI-19 | Valeur historique garde son taux | OUVERT | risque P1 connu (#70 : historique réévalué au taux courant) | W4 |
| FI-20 | Budget ≠ solde bancaire | TENU | budgets purs, aucun effet sur comptes | gardé |
| FI-21 | Flux net = réel − réel | TENU | `cashFlow` exclut transferts/épargne | gardé |
| FI-22 | Projection conditionnelle | PARTIEL | ADR-055/056 (réel d'abord, conditionnel écrit) ; composition avec moyennes non étiquetée | W2/W6 |
| FI-23 | Période consultée, pas l'horloge | TENU | incident « annee-consultee » corrigé et verrouillé | gardé |
| FI-24 | Remboursement explicite | TENU | type `refund` distinct, testé | gardé |
| FI-25 | Une valeur comptée une fois | TENU | positions explicatives, jamais additives (ADR-047, 44k jamais 84k) | gardé |
| FI-26 | Valeur de marché ≠ revenu | TENU | performance = valeur − versements, hors revenus | gardé |
| FI-27 | Actif/dette datés et sourcés | PARTIEL | fraîcheur affichée sur comptes ; pas systématique sur biens/dettes | W4 |
| FI-28 | Rente ≠ capital | TENU | ADR-036, `InsurancePensionService.isAnnuity` testé | gardé |
| FI-29 | Import réessayable sans doublon | OUVERT | empreinte CSV liée au nom de fichier/ligne (constat audit) | W7 |
| FI-30 | Aucune écriture avant confirmation | TENU | préview d'import sans mutation | gardé |
| FI-31 | Mutation multi-objet atomique | OUVERT | `localStorage` sans transaction ; SwiftData sans contrat testé | W3/W9 |
| FI-32 | Save échoué ≠ succès | PARTIEL | iOS affiche `saveErrorMessage` ; PWA : échec quota à prouver par fixture (#70 Lot C) | W9/W10 |
| FI-33 | Restore validé avant remplacement | TENU | `validatedRestoreState` + `BackupService`, tests négatifs (INV1-D) | gardé |
| FI-34 | Inconnu refusé, pas de fallback | PARTIEL | filtres tolérants documentés ; frontière rejet/abandon à contractualiser | W10 |
| FI-35 | Migration conserve IDs et soldes | OUVERT | schémas historiques non figés (constat n° 7) | W10 |
| FI-36 | Verrou ≠ chiffrement | TENU | textes de sécurité exacts, export dit vrai | gardé |
| FI-37 | Logs sans montants | PARTIEL | discipline appliquée ; scan automatisé absent | W10 |
| FI-38 | Aucune intégration promise à tort | TENU | BR1 (provenance), « aucun cours du marché » | gardé |
| FI-39 | Automatisation explicable et annulable | PARTIEL | undo présent ; règles d'import à venir | W7 |
| FI-40 | Même vérité Web/iOS | PARTIEL | 9 fixtures de parité ; couverture partielle de l'inventaire W0.4 | W1 |

## Synthèse

- **TENUS : 15** — le socle produit (prévu ≠ réel dans les agrégats, épargne,
  transferts, positions, restauration validée) est réel et testé.
- **PARTIELS : 12** — comportement présent, contrat ou preuve incomplets.
- **OUVERTS : 13** — concentrés sur : cycle de vie (FI-02→07), journal
  (FI-08, 12, 31), devises (FI-16, 17, 19), import (FI-29), migrations (FI-35).

C'est exactement l'ordre du programme : W1 fige la preuve, W2 ferme le cycle
de vie, W3 le journal, W4 les devises, W7 l'import, W10 les migrations.
