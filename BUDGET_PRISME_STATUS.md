# Budget Prisme — statut vivant

Mis à jour le 15.08.2026. Ce fichier décrit l'état observable; il ne remplace ni
la CI, ni les ADR, ni le code. Ne pas y recopier un journal de commits.

## Source vérifiée

- Branche de release : `main`.
- Branche GitHub par défaut observée : `claude/execute-tbkhsd`, ancienne et non
  autorisée comme source de release. Toujours cibler explicitement `main`.
- Fondation Budget Prisme (design) fusionnée par la PR #8 au SHA de merge
  `f42872dcdb3208b96111055a9cb1c03f5bf98da5` ; version déployée sur Pages par
  dispatch au SHA exact (run `31867323790`, succès) le 15.08.2026.
- Skill maître fusionné par la PR #9 au SHA de merge
  `4f4b21d3dc77e38e95c7a24ba34127121e6fac9c`. **F01 validée par le
  propriétaire le 15.08.2026** (« Je valide la Fondation F01 après la fusion
  de la PR #9 »).
- Publication automatique depuis `main` : toujours bloquée par la règle de
  l'environnement `github-pages` (clic propriétaire requis) ; le chemin de
  déploiement par dispatch au SHA exact reste le contournement vérifié.

Toujours résoudre de nouveau ces informations sur GitHub avant une action.

## Lot actif

**P03 — Historique** · « Qu'est-ce qui est réellement entré, sorti ou déplacé ? »

- État : `VERIFYING_AUTOMATED` — PR ouverte depuis `agent/prisme-p03-historique`,
  CI Web+iOS à confirmer sur le HEAD exact, puis `WAITING_VISUAL`.
- Classe : Présentation / Langage. Aucun calcul, modèle, sauvegarde ni clé modifié.
- Livré :
  - PWA : l'écran s'appelle `Historique`, comme son onglet ;
  - PWA + iOS : l'ajustement de solde est **neutre** — couleur informative ET
    mention « · neutre » écrite (matrice des opérations) ; le signe ± garde la
    direction ; libellé de ligne court `Ajustement` pour que la mention reste
    visible (le formulaire garde `Ajustement de solde`) ;
  - PWA : états vides en Budget Glyphs (`search` ajouté au registre, `movements`
    réutilisé) — plus d'emoji fonctionnel 🔍/📝 ;
  - textes possédés par P03 en « opération » (recherche, compteur, pager, vide
    guidé ; iOS : recherche, suppression, bannière sans catégorie, états vides).
- Preuves : e2e 122 → 123 parcours (titre, langue, neutralité peinte ET
  réellement visible — anti-ellipse, glyphes SVG) ; contrôle négatif 3 échecs
  ciblés puis 123 verts ; 5 parités ; design ; audit-total 320/390/430,
  audit-final (13 contrôles), audit-visuel, audit-coherence : aucun défaut ;
  captures avant/après 390/320 inspectées (défaut d'ellipse attrapé sur la
  capture 390 et corrigé avant commit).
- Limite connue : à 320 px les sous-titres denses tronquent comme avant
  (comportement préexistant, lecture d'écran complète) — amélioré par le
  libellé court, pas éliminé.
- Non-objectifs consignés : bascule transversale « mouvement » → « opération »
  (micro-lot Fondation recommandé) ; unification des champs de recherche
  PWA/iOS (titre+catégorie vs titre+marchand+note).

## Registre d'avancement

| ID | Page | État | Note courte |
|---|---|---|---|
| P00 | Coquille et navigation | WAITING_VISUAL | Fondation Prisme fusionnée, audit page complet à faire |
| P01 | Mois | WAITING_VISUAL | Dashboard simplifié fusionné, validation publique bloquée |
| P02 | Ajouter | WAITING_VISUAL | Intentions et glyphes fusionnés, formulaires à auditer entièrement |
| P03 | Historique | VERIFYING_AUTOMATED | PR ouverte : titre, langue, ajustement neutre, glyphes |
| P04 | Budget | WAITING_VISUAL | Pilote fusionné, vue annuelle et feuilles à reprendre |
| P05 | Comptes | READY | Inventaire complet requis |
| P06 | Fiche compte | READY | Références et suppression à contrôler |
| P07 | Gérer | READY | Sous-titres, retour et densité à contrôler |
| P08 | Ce qui revient | READY | Rythmes, preuve réelle et vocabulaire à contrôler |
| P09 | Factures ponctuelles | READY | PWA uniquement; catégorie Impôts à décider |
| P10 | Objectifs | READY | États pause/atteint/archivé à décider |
| P11 | Impôts | READY | Borne de taux et parcours facture à aligner |
| P12 | Patrimoine | READY | Sources uniques et chevauchements à prouver |
| P13 | Assurances et prévoyance | READY | Double compte PWA à reproduire avant polish |
| P14 | Année | READY | Année consultée pour les contributions à corriger/tester |
| P15 | Import et documents | READY | Atomicité, round-trip et confirmations à prouver |
| P16 | Onboarding | READY | Promesses et vocabulaire livré/futur à corriger |
| P17 | Réglages et confidentialité | READY | Verrou, backup, restore et suppression à auditer |
| P18 | Assistant local | READY | PWA uniquement; réponses déterministes et explicables |

## Incident P0 ouvert — « annee-consultee » (15.08.2026)

- **Scénario fictif** : 1000 CHF mis de côté l'an dernier, 250 CHF cette
  année. Consulter l'an dernier sur la page Année.
- **Attendu / obtenu** : la carte « Mis de côté en <an dernier>, par type »
  doit dire 1000.00 ; elle affiche **250.00** — le montant de l'année
  COURANTE sous l'étiquette de l'année consultée.
- **Source unique suspectée** : `contributions()` filtre `t.y === NOW.y`
  (année courante figée) alors que `renderYearReview()` étiquette
  `yearCursor` ; `contributionsFor()` ne transmet aucune année.
- **Pages touchées** : P14 Année (carte « par type »). Les usages avec
  étiquette `NOW.y` explicite (prévoyance/assurances) disent vrai.
- **Fixture rouge** : parcours e2e 124 sur `agent/prisme-p0-annee-consultee`
  — échec unique et ciblé, message exact « attendu 1'000.00, obtenu 250.00 ».
  La CI de cette branche est ROUGE PAR CONSTRUCTION tant que le correctif
  n'est pas approuvé.
- **Contrôle adverse** : l'étiquette de la carte, elle, suit bien l'année
  consultée (vérifié par le même parcours) — c'est la donnée qui ment.
- **Critères de reprise** : correctif approuvé (année en paramètre de
  `contributions()`/`contributionsFor()`, `NOW.y` par défaut pour les autres
  usages), test 124 vert, suites complètes vertes, fusion, CI push verte du
  SHA de merge.
- Aucun lot visuel actif interrompu (P03 fusionné avant l'ouverture).

## Risques prioritaires connus

Ces éléments sont des hypothèses d'audit à reproduire avant correction :

1. P13 PWA : héros Prévoyance susceptible de recompter un compte lié.
2. P14 PWA : contributions « par type » susceptibles d'utiliser l'année courante
   au lieu de l'année consultée.
3. P06 : suppression d'un compte à vérifier contre toutes les références,
   notamment destination récurrente et position de prévoyance.
4. P11 : bornes de taux différentes selon onboarding et page Impôts.
5. P10 iOS : un objectif archivé peut devenir inaccessible dans la liste.
6. Publication web : règle d'environnement `github-pages` à corriger par le
   propriétaire avant de pouvoir marquer la version fusionnée `PUBLISHED`.
7. Dépôt GitHub : la branche par défaut reste une ancienne branche Claude;
   ne pas l'utiliser pour baser une PR ou un artefact de release.

## Prochaine page après P03

`P14 Année` en mode `audit` d'abord — le registre des risques soupçonne les
contributions « par type » d'utiliser l'année courante au lieu de l'année
consultée : une vérité à reproduire avant tout polish. Ne pas la commencer
avant validation explicite du lot P03.
