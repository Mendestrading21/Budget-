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

**P14 — Année** · « Qu'est-ce qui est entré, sorti et mis de côté cette année ? »

- État : `VERIFYING_AUTOMATED` — PR ouverte depuis `agent/prisme-p14-annee`,
  CI Web+iOS à confirmer sur le HEAD exact, puis `WAITING_VISUAL`.
- Classe : Présentation / Langage. Aucun calcul modifié (la vérité de l'année
  consultée a été rétablie séparément par l'incident P0, fusionné et publié).
- Livré :
  - PWA : carte « par type » en Budget Glyphs (glyphe `shield` ajouté au
    registre) — plus d'emojis 🏛️📈🛡️ ; héros « Mis de côté » en blanc Prisme
    (l'épargne n'est ni un gain vert ni une perte rouge — matrice) ;
    navigation d'année en glyphes chevron avec bornes 2000/2100 réellement
    désactivées ; « Aucune opération ce mois » ; chevrons de ligne en glyphe.
  - iOS : contributionsCard en BudgetIcon (.setAside/.investment/.pension),
    héros et versements au ton neutre de l'accueil — plus de vert.
- Preuves : e2e 124 → 125 parcours (glyphes, zéro emoji, couleur calculée du
  héros, bornes, montant de l'année consultée toujours exact) ; contrôle
  négatif 2 échecs ciblés puis 125 verts ; 5 parités ; design ; audit-total
  320/390/430, audit-final (13 contrôles), audit-visuel, audit-coherence :
  aucun défaut ; captures avant/après 390/320 inspectées.
- Non-objectif consigné : cible tactile du lien « cette année » (motif
  partagé avec « aujourd'hui » du Mois — appartient à P00/P01).

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
- **Fixture rouge → verte** : parcours e2e 124, né rouge (commit `6fc7e4b`,
  échec unique « attendu 1'000.00, obtenu 250.00 »), vert depuis le correctif
  approuvé par le propriétaire : `contributions()`/`contributionsFor()`
  prennent l'année en paramètre (`NOW.y` par défaut pour les écrans qui
  étiquettent l'année courante), la page Année transmet `yearCursor`.
  Reproduction directe après correctif : 2025 → 1'000.00, 2026 → 250.00.
- **Contrôle adverse** : l'étiquette de la carte, elle, suit bien l'année
  consultée (vérifié par le même parcours) — c'est la donnée qui ment.
- **Critères de reprise** : correctif livré, test 124 vert, 124 parcours +
  5 parités + design + 4 audits verts en local. Restent : CI de la PR #11 sur
  le HEAD exact, fusion approuvée, CI push verte du SHA de merge.
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

## Prochaine page après P14

`P05 Comptes` — « Où se trouve mon argent aujourd'hui ? » Inventaire complet
requis (groupes, fraîcheur, devise, archivés, formulaire). Ne pas la commencer
avant validation explicite du lot P14.
