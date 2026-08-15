# Budget Prisme — statut vivant

Mis à jour le 15.08.2026. Ce fichier décrit l'état observable; il ne remplace ni
la CI, ni les ADR, ni le code. Ne pas y recopier un journal de commits.

## Source vérifiée

- Branche de release : `main`.
- Branche GitHub par défaut observée : `claude/execute-tbkhsd`, ancienne et non
  autorisée comme source de release. Toujours cibler explicitement `main`.
- Fondation Budget Prisme fusionnée par la PR #8 au SHA de merge
  `f42872dcdb3208b96111055a9cb1c03f5bf98da5`.
- CI push de ce SHA : verte pour Web et iOS, run `31848174498`.
- Pages de ce SHA : **BLOCKED**, run `31848174521`.
- Cause exacte : la branche `main` n'est pas autorisée à déployer vers
  l'environnement `github-pages`. La version Prisme fusionnée n'est donc pas
  déclarée publiée.

Toujours résoudre de nouveau ces informations sur GitHub avant une action.

## Lot actif

**Fondation F01 — skill maître page par page**

- État : `VERIFYING_AUTOMATED`.
- Résultat : créer `/budget-prisme`, le registre P00–P18, le langage, les
  garde-fous finance/données, les preuves qualité et le protocole de release.
- Ne modifie aucun écran, modèle, calcul, stockage ou sauvegarde.
- Prochaine étape : valider le skill, ouvrir une PR ciblée et attendre CI +
  approbation propriétaire.

## Registre d'avancement

| ID | Page | État | Note courte |
|---|---|---|---|
| P00 | Coquille et navigation | WAITING_VISUAL | Fondation Prisme fusionnée, audit page complet à faire |
| P01 | Mois | WAITING_VISUAL | Dashboard simplifié fusionné, validation publique bloquée |
| P02 | Ajouter | WAITING_VISUAL | Intentions et glyphes fusionnés, formulaires à auditer entièrement |
| P03 | Historique | READY | Prochaine passe visuelle et fonctionnelle recommandée |
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

## Prochaine page après F01

`P03 Historique` — « Qu'est-ce qui est réellement entré, sorti ou déplacé ? »

Ne pas la commencer avant fusion/validation explicite du lot F01.
