# Budget Prisme — statut vivant

Mis à jour le 16.08.2026. Ce fichier décrit l'état observable; il ne remplace ni
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

## Lots approuvés récents

- **P06 — Fiche compte : `APPROVED` + `PUBLISHED`.** Fusion squash PR #15 au
  SHA de merge `eb37270ae6b2ba81b3bbe403fcc0e79e9e8c5132`, CI push verte,
  déployé sur Pages par dispatch au SHA exact (run `31960854165`, succès)
  le 16.08.2026. Gardes de suppression PWA+iOS (risque n° 3 confirmé puis
  corrigé, test 128 rouge→vert), langue de la fiche alignée.
- P03 Historique, P14 Année, P17 Confidentialité, P05 Comptes : `APPROVED`,
  publiés (SHA respectifs 931128a / b9e52a1 / bc9d3ae / db22b2b).

## Incident P0 actif — « prevoyance-double-compte » (16.08.2026)

Ouvert pendant l'audit P13, conformément à la règle « défaut financier →
incident séparé, test rouge d'abord ». Branche
`agent/prisme-p0-prevoyance-double-compte`.

- **Scénario fictif** : un compte de prévoyance à 10 000 CHF, une position de
  prévoyance LIÉE à ce compte (elle suit son solde), une position non liée
  de 5 000 CHF (certificat).
- **Attendu / obtenu** : la carte « Déjà mis de côté » de l'écran Assurances
  & prévoyance doit dire **15 000** ; elle affichait **25 000** — le compte
  lié compté DEUX fois, sous les lignes mêmes qui totalisent 15 000.
- **Source unique** : `renderInsurance()` additionnait
  `pensionDisplayTotal()` (qui vaut déjà le solde du compte pour toute
  position liée — la feuille de liaison n'accepte QUE des comptes
  `pension`/`lifeinsurance`) PLUS les soldes de ces mêmes comptes.
- **Correctif** : la carte additionne les positions NON liées
  (`pensionPositionsTotal()`) et les soldes des comptes de prévoyance —
  chaque franc une seule fois. Aucune formule partagée modifiée : le
  patrimoine (`pensionPositionsTotal` dans le hero Patrimoine) était déjà
  juste ; seule la carte de l'écran Prévoyance mentait.
- **Fixture rouge → verte** : parcours e2e 129, né rouge (échec unique
  « affiché 25'000.00, honnête 15'000.00 »), vert avec le correctif.
  Contrôle négatif : sabotage (retour à `pensionDisplayTotal`) → le 129
  remord exactement ; correctif rétabli, suite verte.
- **iOS : sain.** `PensionView` totalise uniquement les positions saisies
  (`totalPensionCapital`), sans addition de soldes de comptes — aucune
  liaison position↔compte n'existe côté natif. Aucun changement Swift.
- **Preuves** : 129 parcours e2e + 5 parités + design verts ;
  audit-final (13 contrôles), audit-coherence, audit-total 390 : aucun
  défaut ; captures avant (25'000) / après (15'000) réellement inspectées
  dans `docs/neon-ultra/budget-prisme/p0-prevoyance/`.
- **Critères de reprise** : CI Web+iOS verte sur le HEAD exact de la PR,
  fusion approuvée par le propriétaire, CI push verte du SHA de merge,
  publication. La refonte P13 reste en pause jusque-là.

## Incident P0 clos — « annee-consultee » (15.08.2026)

Corrigé et fusionné (PR #11) : `contributions()`/`contributionsFor()`
prennent l'année en paramètre, la page Année transmet `yearCursor` ;
test 124 rouge→vert. Reproduction après correctif : an dernier → 1'000.00,
année courante → 250.00.

## Risques prioritaires connus

Ces éléments sont des hypothèses d'audit à reproduire avant correction :

1. P13 PWA : **confirmé et corrigé** (incident P0 « prevoyance-double-compte »
   ci-dessus) — carte « Déjà mis de côté » recomptait un compte lié.
2. P14 PWA : **confirmé et corrigé** (incident P0 « annee-consultee », clos).
3. P06 : **confirmé et corrigé** — gardes destination récurrente et position
   de prévoyance ajoutées (PWA + iOS), test 128 rouge→vert.
4. P11 : bornes de taux différentes selon onboarding et page Impôts.
5. P10 iOS : un objectif archivé peut devenir inaccessible dans la liste.
6. Publication web : règle d'environnement `github-pages` à corriger par le
   propriétaire avant de pouvoir marquer la version fusionnée `PUBLISHED`
   sans dispatch manuel.
7. Dépôt GitHub : la branche par défaut reste une ancienne branche Claude;
   ne pas l'utiliser pour baser une PR ou un artefact de release.

## Prochaine action exacte

1. Valider puis fusionner la PR de l'incident P0
   « prevoyance-double-compte » (CI complète sur le HEAD exact d'abord).
2. Publier le SHA de merge par dispatch Pages.
3. Reprendre `P13 Assurances et prévoyance` en mode `audit` là où il s'est
   arrêté : le défaut du risque n° 1 est corrigé ; reste l'audit complet de
   présentation/langage de la page (boutons, états, formulaires, a11y),
   puis le Page Work Order et le lot visuel.
