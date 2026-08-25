# W0.6 — Page Work Order : W1 — Fixtures canoniques

Ce Work Order autorise la PLANIFICATION de W1. Il n'autorise ni code, ni
fusion, ni publication. `execute W1` ne prendra que le premier sous-lot READY
(W1.1) après la fusion de W0.

## Problème utilisateur

Chaque vérité financière de Budget existe deux fois (PWA et iOS). Aujourd'hui,
9 fixtures de parité couvrent des scénarios choisis — pas le contrat entier de
l'inventaire W0.4. Tant que la preuve commune n'existe pas, chaque correction
risque de réparer une plateforme et pas l'autre, et les lots W2/W3 n'ont pas de
filet.

## Résultat mesurable

Un dossier de fixtures canoniques versionnées (`fixtures/canon/…`), un runner
Web et un runner Swift qui produisent des sorties STRUCTURÉES identiques champ
par champ, branchés en CI, avec un sabotage prouvant que la gate mord de
chaque côté.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | État initial |
|---|---|---|
| W1.1 | Schéma de fixture et version : format JSON (entrées : comptes, mouvements, récurrences, taux datés ; sorties attendues : soldes, agrégats du mois, patrimoine), `version: 1`, règles d'arrondi ISO écrites (FI-18) | READY après fusion W0 |
| W1.2 | Money/comptes : soldes par devise, solde d'ouverture, comptes exclus/archivés | BLOCKED (W1.1) |
| W1.3 | Mois : trio réel, projection, transferts neutres, épargne interne (FI-09, 10, 21) | BLOCKED (W1.2) |
| W1.4 | Dette, devise, patrimoine : capital/intérêts, conversion datée, fortune (FI-14, 19, 25) | BLOCKED (W1.3) |
| W1.5 | Récurrences, import, corrections : échéances couvertes, doublons, ajustements | BLOCKED (W1.4) |
| W1.6 | Runners : Web (Node, moteur PWA) et Swift (XCTest) lisant les MÊMES fichiers, sorties comparées structurellement | BLOCKED (W1.5) |
| W1.7 | CI + contrôle négatif : job de parité obligatoire ; sabotage d'UN côté → échec nommé ; restauration → vert | BLOCKED (W1.6) |

## Périmètre de fichiers attendu

- `fixtures/canon/**` (nouveaux, données fictives déterministes) ;
- `webapp/tests/canon.test.mjs` (nouveau runner) ;
- `BudgetTests/CanonicalFixtureTests.swift` (nouveau runner) ;
- `.github/workflows/ci.yml` (job de parité) ;
- statut et ADR si une règle d'arrondi doit être tranchée.

## Non-objectifs

- AUCUNE modification de formule (si une fixture révèle un écart Web/iOS :
  STOP, consigner, proposer une ADR — ne jamais « aligner » en copiant un bug,
  règle du skill) ;
- aucun nouveau modèle, aucune migration, aucun écran ;
- ne remplace pas les 9 fixtures de parité existantes tant que la couverture
  canonique ne les contient pas prouvablement.

## Invariants engagés

FI-18 (arrondi déterministe), FI-40 (même vérité Web/iOS) ; tous les invariants
`TENUS` du registre restent verts (leurs tests actuels ne bougent pas).

## Migration / rollback

Additif pur : de nouveaux fichiers et de nouveaux tests. Rollback = revert de
la PR. Aucune donnée utilisateur touchée.

## Preuves exigées (gates)

1. runner Web rouge AVANT le runner Swift (ou l'inverse) — né rouge ;
2. sorties identiques champ par champ, pas de comparaison de texte formaté ;
3. sabotage d'un seul côté → échec qui NOMME la fixture et le champ ;
4. suites existantes inchangées et vertes (e2e, 9 parités, design, catalogue,
   audit) — totaux OBSERVÉS, jamais recopiés ;
5. CI verte sur le HEAD exact de la PR.

## Décision à trancher pendant W1 (ADR courte attendue)

La représentation des montants DANS les fixtures : unités mineures entières
(recommandation de l'audit, compatible G01 côté PWA) ou décimales chaînes.
Cette décision ne préjuge PAS du stockage interne (décision W3, propriétaire).

## Arrêt

Si deux sorties légitimes divergent entre plateformes sans ADR existante :
arrêter le sous-lot, consigner l'écart mesuré (valeurs exactes des deux côtés),
proposer l'ADR — le propriétaire tranche.
