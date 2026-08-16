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

## Lot actif

**P09 — Factures ponctuelles** · « Qu'est-ce qui reste à payer une seule fois ? »

- État : `VERIFYING_AUTOMATED` — PR ouverte depuis
  `agent/prisme-p09-factures-ponctuelles`.
- Livré : glyphe facture sur les lignes et l'état vide (plus de 🧾 ni de
  🎉) ; « payée » sans coche décorative ; boutons en mots ; l'état vide ne
  promet plus « Acomptes d'impôts » — la feuille facture ne propose que
  des catégories de dépense (`Impôts` est de genre `tax`), le texte renvoie
  honnêtement à l'écran Impôts. Le parcours fonctionnel « facture d'acompte
  d'impôts » reste une dette consciente (lot fonctionnel séparé).
- Preuves : e2e 132 → 133 parcours ; contrôle négatif à 2 échecs ciblés ;
  5 parités ; design ; audit-final, audit-coherence, audit-total 320/390 :
  aucun défaut ; captures avant/après dans
  `docs/neon-ultra/budget-prisme/p09/`.
- iOS : page volontairement PWA uniquement (registre) — aucun équivalent.

## Lot fusionné — P08 Ce qui revient

- **`APPROVED` + `PUBLISHED`** : fusion squash PR #19 au SHA de merge
  `c214e64db904f4e1d27f014c0f15bb11a47c0562`, CI push verte, publication
  Pages par dispatch au SHA exact (en cours de confirmation).

## Lot fusionné — P07 Gérer

- **`APPROVED` + `PUBLISHED`** : fusion squash PR #18 au SHA de merge
  `ce55dfc11032ee2dc9f220fabd1d373f16dc07b5`, CI push verte, déployé sur
  Pages par dispatch au SHA exact (run `31968446608`, succès) le 16.08.2026.

## Lot fusionné — P13 Assurances et prévoyance

- **`APPROVED` + `PUBLISHED`** : fusion squash PR #17 au SHA de merge
  `5f8ffecd79957e51d00c70e80c01f724b0dd94ec`, CI push verte, déployé sur
  Pages par dispatch au SHA exact (run `31967270427`, succès) le 16.08.2026.
- Classe : Visuel + Langage (le défaut financier de la page a été corrigé
  AVANT ce lot, par l'incident P0 ci-dessous — aucune formule touchée ici).
- Livré :
  - Budget Glyphs : plus aucun emoji fonctionnel — bouclier sur les lignes
    assurance, prévoyance et la carte Pilier 3a (les icônes stockées ne
    sont plus jamais rendues : le test de sécurité 120 exige désormais 0).
  - Chevrons de navigation sur chaque ligne cliquable — et correction d'un
    défaut latent : un chevron en span libre n'avait AUCUNE taille CSS et
    restait invisible (0×0 mesuré, y compris ceux posés par P14/P17) ; la
    nouvelle règle ne vise que ce motif, tailles des autres contextes
    prouvées inchangées (pastilles 44, tabbar 22, boutons nav 30, vide 28).
  - Boutons en mots : « Ajouter une assurance », « Ajouter une prévoyance ».
  - États vides guidés avec glyphe ; héros honnête sans contrat (plus de
    « Soit CHF 0.00 par an »).
  - Feuille prévoyance : libellé du montant à la retraite dit une seule fois.
  - iOS : sain, aucun changement (SF Symbols natifs, textes déjà justes).
- Preuves : e2e 129 → 130 parcours (le 130 exige des chevrons PEINTS
  ≥ 12 px, pas seulement présents) ; contrôle négatif : sabotage → 4 échecs
  ciblés dont le test de sécurité renforcé ; 5 parités ; design ;
  audit-final, audit-coherence, audit-total 320/390 : aucun défaut ;
  captures avant/après (pleines et vides) réellement inspectées dans
  `docs/neon-ultra/budget-prisme/p13/`.

## Incident P0 clos — « acompte-impots » (16.08.2026)

Découvert pendant l'audit P11 (écran Impôts). `taxBills` liste les factures
de catégorie « Impôts » (données importées ou restaurées — l'écran les
affiche comme « Vos prochains acomptes »), mais `materializeBill` créait
TOUJOURS `type: "expense"` : payer un acompte gonflait le coût de la vie
et ne réduisait jamais « il vous reste à payer » (`taxSummary.paid` ne
compte que les `taxPayment`).

- **Fixture rouge → verte** : parcours e2e 134, né rouge (« obtenu
  expense », payé 0 → 0), vert avec le correctif : la catégorie Impôts
  matérialise un `taxPayment`. Une ligne changée, aucun autre calcul.
- iOS non concerné (les factures ponctuelles sont PWA uniquement).
- 134 parcours + 5 parités + design + audit-final + audit-coherence +
  audit-total : verts.
- Suite : le lot P11 rendra le parcours réel (catégorie « Impôts »
  proposable dans la feuille facture) — aujourd'hui seules des données
  restaurées/importées portent cette catégorie.

## Incident P0 clos — « prevoyance-double-compte » (16.08.2026)

Ouvert pendant l'audit P13, conformément à la règle « défaut financier →
incident séparé, test rouge d'abord ». **Corrigé, fusionné (PR #16, SHA de
merge `ec3661a6ba7dfb9d3172cfd13f74e2d774989c82`, CI push verte) et publié
sur Pages par dispatch au SHA exact (run `31963328553`, succès).**

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
- Critères de reprise remplis : CI de la PR #16 verte sur le HEAD exact,
  fusion approuvée par le propriétaire, CI push verte, publication faite.

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

Programme autorisé en continu (16.08.2026). Ordre restant :
P07 (en cours) → P08 → P09 → P10 → P11 → P12 → P15 → P16 → P18 →
P00 → P01 → P02 → P04. Pour chaque lot : audit, développement, tests
(rouge d'abord pour toute vérité), contrôle négatif, suites + audits,
captures inspectées, PR, CI verte sur le HEAD exact, fusion squash,
publication Pages au SHA de merge. Tout défaut financier découvert ouvre
un incident P0 séparé avant le lot visuel.
