# Page Work Order : W9 — PWA modulaire

Écrit en mode `plan` (aucun code) à la fermeture de W8 (`main` inclut
W8.1–W8.7). Il n'autorise ni implémentation, ni fusion : `execute W9`
prend W9.1.

## Autorités

`WORK_BREAKDOWN.md` (W9.1–W9.8), la règle du skill « aucune refonte
massive » (qui PRIME : W9 avance par ajouts prouvés, jamais par
réécriture), FI-40 (les fixtures canon sont la gate de parité),
ADR-058 (portes uniques, lecture d'abord), l'interdit produit « la PWA
reste fonctionnelle, installable, honnête, hors-ligne » (CLAUDE.md).

## Problème (mesuré)

`webapp/index.html` est un monofichier (~11 000 lignes) : un seul
espace de noms, aucun typage, `localStorage` comme seul stockage
(quota ~5 Mo, synchro inter-onglets non gérée), service worker
minimal. Les 231 parcours e2e, 14 fixtures canon et 9 parités
protègent le comportement — c'est l'appui du chantier.

## Résultat mesurable

Le comportement NE CHANGE PAS (mêmes suites vertes, mêmes fixtures,
mêmes captures) pendant que l'architecture devient modulaire : un
build TypeScript reproductible, un domaine extrait et typé, IndexedDB
avec migration prouvée depuis localStorage, des routes propres, une
CSP stricte, un hors-ligne robuste (quota, multi-onglets), et le
monolithe RETIRÉ seulement quand tout le reste est prouvé.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Garde-fou |
|---|---|---|
| W9.1 | Build TypeScript : outillage (esbuild ou équivalent sans réseau en CI), `webapp/src/` compilé vers UN artefact vérifié au octet près contre l'existant au premier passage (build à vide) | le monofichier reste la source servie |
| W9.2 | Domaine/application : extraire les calculs PURS (snapshot, fortune, taux datés, contributions) en modules typés, le monofichier les importe — comparateur : mêmes sorties sur les 14 fixtures | aucune logique modifiée |
| W9.3 | IndexedDB : couche de stockage additive derrière une interface unique (`storage.get/set`), localStorage reste la vérité | double écriture prouvée |
| W9.4 | Migration localStorage → IndexedDB : bascule par drapeau, migration idempotente prouvée (aller, échec au milieu, retour), sauvegarde de secours avant bascule | jamais de perte |
| W9.5 | Routes : l'état de navigation (activeTab/moreView/cursor) devient une route restaurable (hash), retour arrière honnête | mêmes écrans |
| W9.6 | CSP/service worker : CSP stricte déclarée, SW versionné avec invalidation propre | l'app hors-ligne reste installable |
| W9.7 | Offline/quota/multi-onglets : quota surveillé et DIT, verrou d'écriture inter-onglets, reprise après éviction | rien de silencieux |
| W9.8 | Retrait du monolithe : la source devient `webapp/src/`, l'artefact servi est le build — SEULEMENT quand W9.1–W9.7 sont fusionnés et publiés | dernière étape, réversible |

## Stratégie

Chaque sous-lot garde le monofichier COMME RÉFÉRENCE vivante jusqu'à
W9.8 ; le comparateur (fixtures canon + e2e) tranche à chaque étape ;
le natif n'est pas touché ; la CI doit rester capable de tourner SANS
réseau (vendorer l'outillage ou le committer).

## Non-objectifs

Pas de framework (React/Vue/Svelte), pas de refonte visuelle, pas de
changement de comportement, pas de nouveau stockage distant, pas de
suppression d'historique de tests.

## Décisions propriétaire à poser

Aucune : chantier technique. La décision « chiffrement backup »
appartient à W10.4 ; « Android » à W11.4.

## Preuves exigées

Chaque sous-lot : mesure, né-rouge (ou verrou consigné), sabotage qui
mord seul, suites complètes, captures si l'UI bouge (elle ne devrait
pas), statut consigné, CI verte sur HEAD exact, fusion squash,
publication au SHA, run id consigné.
