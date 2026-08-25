# Page Work Order : W3 — Journal financier

Écrit en mode `plan` (aucun code) juste après la fermeture de W2
(occurrences persistées, `main` inclut W2.1–W2.7b). La décision
« unités mineures vs `Decimal` canonique » (matrice W0.5, échéance =
ce Work Order) est tranchée par les autorités déjà approuvées — voir
« Décisions » ci-dessous.

## Problème utilisateur

Aujourd'hui l'argent n'a pas de journal : un mouvement est un objet
plat (`BudgetTransaction` / entrée `movements`) que l'on peut modifier
ou supprimer sans trace (constat n° 5 de l'audit — l'histoire est
réécrite, FI-07 OUVERT). Le solde d'ouverture est une propriété du
compte (FI-12 OUVERT), un virement n'est pas UNE écriture atomique
(FI-09 PARTIEL), rien ne garantit l'équilibre par devise (FI-08
OUVERT), et une mutation multi-objet n'est pas transactionnelle (FI-31
OUVERT). Conséquence réelle : une correction efface la vérité au lieu
de la corriger.

## Résultat mesurable

Chaque franc vit dans une écriture équilibrée : `JournalEntry` +
`postings` (débit/crédit par devise), cycle de vie
`pending · posted · cleared · reconciled` (FI-06), correction par
inversion/remplacement lié (`reversesEntryID`/`replacesEntryID`,
FI-07), solde d'ouverture = une écriture d'ouverture (FI-12), soldes
dérivés du journal identiques aux soldes actuels (comparateur ADR-058),
sur les DEUX plateformes, prouvé par fixtures canoniques v2 et suites
inchangées.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Périmètre |
|---|---|---|
| W3.1 | `Money` + `postings` : type monétaire commun (décision propriétaire : unités mineures vs `Decimal`), forme des écritures, équilibre par devise refusé sinon (FI-08) ; AUCUNE lecture par les vues | modèles + tests domaine |
| W3.2 | Écritures types : dépense, rentrée, virement interne (UNE écriture, deux postings, FI-09), mise de côté, remboursement de dette (capital/intérêts, FI-14 gardé), ouverture de compte (FI-12) | domaine |
| W3.3 | Shadow-write : chaque mutation actuelle (addTx, édition, suppression, import, undo) écrit AUSSI son écriture journal, sans changer l'interface ni l'ancien modèle | services + persistance |
| W3.4 | Comparateur : soldes par compte et agrégats du mois dérivés du journal ↔ chemins actuels ; zéro écart exigé sur les fixtures canoniques et sur les parcours e2e | services + tests |
| W3.5 | Inversion/remplacement : corriger un mouvement confirmé crée une écriture liée, jamais une réécriture ; suppression d'un posté = inversion tracée (FI-07) | domaine + persistance |
| W3.6 | Bascule des soldes : lectures de solde derrière feature flag vers le journal, rollback documenté | UI minimale + flag |
| W3.7 | Migration de l'historique : dry-run (créés, liés, ignorés, ambigus, invalides, écarts de soldes), backup avant, migration additive, preuve sur store disque | migration + preuve |

## Stratégie de migration (ADR-058, reconduite)

Journal NOUVEAU en parallèle : les vues et les soldes continuent de
lire l'ancien chemin pendant W3.1–W3.5 (shadow-write) ; le comparateur
W3.4 est la gate de bascule (W3.6) ; l'historique n'est migré (W3.7)
qu'après bascule prouvée ; rollback = feature flag + ancien chemin
intact + backup.

## Non-objectifs

Pas de rapprochement bancaire ni de statements (W4), pas de devises ni
FX (W4 — le journal naît mono-devise par écriture, l'équilibre est PAR
devise), pas de refonte des pages (W5), pas de règles d'import (W7),
pas d'IndexedDB (W9).

## Décisions

1. **Unités mineures — tranchée (ADR-063)** : la question a été posée
   au propriétaire (25.08.2026) qui l'a écartée en ordonnant de
   continuer ; les autorités approuvées tranchent déjà —
   `DATA_MODEL_TARGET.md` définit `Money { minorUnits: Int64,
   currency }` et l'ADR-059 a fixé les fixtures canoniques en unités
   mineures entières. Le journal STOCKE donc des centimes entiers +
   devise ; le natif continue de CALCULER en `Decimal` et convertit
   aux frontières avec arrondi déterministe (FI-18).
2. Stratégie de migration de l'historique (bloque W3.7, ADR attendue) :
   après le comparateur W3.4, choisir big-bang datée vs migration
   paresseuse — à poser au propriétaire au Work Order de W3.7.

## Preuves exigées

Chaque sous-lot : test rouge d'abord, contrôle négatif (sabotage qui
mord seul), fixtures des deux côtés quand une vérité change, migration
testée sur store disque, suites complètes, CI verte sur HEAD exact,
statut consigné avec run ids.
