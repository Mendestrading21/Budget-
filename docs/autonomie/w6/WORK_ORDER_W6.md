# Page Work Order : W6 — Plan, budgets, objectifs

Écrit en mode `plan` (aucun code) à la fermeture de W5 (`main` inclut
W5.1–W5.8). Il n'autorise ni implémentation, ni fusion : `execute W6`
prend W6.1.

## Autorités

`WORK_BREAKDOWN.md` (W6.1–W6.6), `DATA_MODEL_TARGET.md` (« Budget and
goals » : BudgetLine avec rolloverPolicy/targetMode, Goal,
GoalAllocation), `FINANCIAL_INVARIANTS.md` (FI-20 budget restant ≠
solde bancaire, FI-21 flux net, FI-22 projection conditionnelle,
FI-23 chaque mois utilise sa période), ADR-055/056 (conditionnel,
confirmés à l'écran par W5.4), ADR-061 (le résultat du mois exclut
l'épargne), ADR-066 (ignorer libère). ADR-026 : aucune nouvelle
destination.

## Problème utilisateur

Le budget actuel est plat : des lignes mensuelles copiables à la main,
sans report (une catégorie sous-dépensée repart de zéro), sans cible
long terme, sans lien prouvé entre objectifs et affectations réelles.
Les revenus variables (indépendants) n'ont qu'une moyenne implicite
sur 3 mois dans la prévision — aucune surface ne l'explique. Les
charges annuelles n'ont pas de fonds de lissage : janvier prend la
prime d'assurance en pleine figure.

## Résultat mesurable

Chaque franc planifié a une règle NOMMÉE : une ligne budgétaire dit si
elle reporte son reste (rollover) ou repart à zéro ; un objectif
avance par affectations RÉELLES (jamais par projection seule,
DATA_MODEL_TARGET) ; un fonds annuel lisse une charge annuelle en
douzièmes visibles ; le budget d'un mois consulté utilise SA période
(FI-23) ; rien ne touche les soldes bancaires (FI-20).

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Périmètre |
|---|---|---|
| W6.1 | Cibles/report : `rolloverPolicy` par ligne budgétaire (`none` par défaut — comportement actuel verrouillé ; `carry` = le reste du mois M rejoint le budget de M+1, calculé, jamais stocké en double) | modèle additif + Budget |
| W6.2 | Revenus variables : la moyenne 3 mois existante devient VISIBLE et honnête (« Estimation sur vos 3 derniers mois : … ») ; décision propriétaire sur la fenêtre si divergence mesurée | UI + mesure |
| W6.3 | Obligations/abonnements : le Budget montre la part ENGAGÉE (charges récurrentes dues) séparée du discrétionnaire — lecture des occurrences (W2/W5.7), zéro nouveau compteur | UI + lecture |
| W6.4 | Fonds annuels : une charge annuelle peut alimenter un fonds de lissage affiché en douzièmes (« mis de côté pour SERAFE : 3/12 ») — lecture seule d'abord, aucune écriture automatique | modèle additif + UI |
| W6.5 | Objectifs/allocations : un objectif avance par affectation réelle datée (`GoalAllocation` additif) ou valeur manuelle datée — jamais par projection ; l'écran objectifs raconte la provenance | modèle additif + UI |
| W6.6 | Mois/année : la page Année et le Budget consultés utilisent LEUR période partout (FI-23 vérifié par sonde), régressions verrouillées | tests + consignation |

## Stratégie (ADR-058, reconduite)

Clés ADDITIVES sur les modèles existants (`rolloverPolicy` sur une
ligne, `allocations` sur un objectif) — jamais de migration
destructive ; les états existants restent valides sans modification
(défauts = comportement actuel). Chaque sous-lot suit la méthode :
mesure, test né rouge, implémentation, sabotage, suites, captures
320/390 si UI, statut.

## Non-objectifs

Pas de multi-période libre (BudgetPeriod reste le mois civil en V1 —
consigné) ; pas d'écriture automatique d'argent (un fonds annuel LIT,
il ne vire pas) ; pas de nouvelle destination (ADR-026) ; pas
d'allumage du journal (ADR-064) ; les miroirs natifs suivent le même
lot ou sont consignés à la PR.

## Décisions propriétaire à poser (AskUserQuestion, une par surface)

1. W6.1 : le report est-il opt-in par ligne (recommandé : `none` par
   défaut, l'utilisateur active « reporter le reste ») ?
2. W6.4 : le fonds annuel est-il purement informatif en V1
   (recommandé) ou crée-t-il des virements réels ?

## Preuves exigées

Chaque sous-lot : mesure d'abord, test né rouge (échecs nommés),
sabotage qui mord seul, captures 320/390 inspectées si UI, suites
complètes vertes, CI verte sur HEAD exact, fusion squash, publication
au SHA, statut consigné avec run ids.
