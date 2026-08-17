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

**Fondation finale** · langue des opérations + champs morts

- État : `VERIFYING_AUTOMATED` — PR ouverte depuis
  `agent/prisme-fondation-finale`. **Dernier lot du programme.**
- Livré :
  - **Balayage « mouvement → opération »** guidé par sonde : 34 chaînes
    utilisateur migrées (titres de feuille, boutons, toasts,
    confirmations, raisons de refus de restauration, export, reset).
    Restent volontairement : identifiants techniques (clé legacy, nom du
    fichier CSV), commentaires de code, et les titres par intention
    (« Nouvelle dépense »… — plus précis que le mot générique).
  - **Champs morts retirés** : `ACCOUNT_KINDS.icon` (aucun consommateur
    depuis P05) et `monthPriority().icon` (jamais rendu).
  - Décision consignée : les flèches typographiques « ‹ › » (retour et
    pageur) sont un choix propriétaire documenté — conservées.
- Preuves : e2e 141 → 142 parcours — le 142 balaie les SEIZE écrans
  (aucun ne dit plus « mouvement ») ET la source servie (toasts,
  confirmations, titres) ; contrôle négatif à 2 sabotages mordants ;
  5 parités ; design ; audit-final, audit-coherence, audit-total 320/390 :
  aucun défaut.
- P00/P01/P02 : audits consignés — écrans déjà propres (accueil en
  glyphes de sens, feuilles en `data-budget-glyph`, tabbar en glyphes),
  aucun commit artificiel.

## Bilan du programme Budget Prisme (16–17.08.2026)

Toutes les pages du registre P00–P18 sont traitées : auditées, corrigées
quand il le fallait, testées, fusionnées et publiées au SHA exact.

- **3 incidents P0** ouverts test-rouge-d'abord, corrigés, fusionnés,
  publiés : « annee-consultee » (P14), « prevoyance-double-compte » (P13),
  « acompte-impots » (P11 — un acompte payé est un taxPayment, jamais une
  dépense de vie).
- **5 risques du registre** tous corrigés (n°1 à n°5), dont deux côté
  iOS (objectif archivé retrouvable ; gardes de suppression de compte).
- **Suite e2e : 123 → 142 parcours** ; test de sécurité des icônes
  restaurées durci à 0 rendu sur quatre vues ; chevrons exigés PEINTS.
- **Budget Glyphs** : registre étendu (search, shield, person, couple,
  family, globe, alert, check, cash, goal, docImport, document, chat,
  gear) — plus aucun emoji fonctionnel sur les 16 écrans ; restent les
  drapeaux (sens géographique), les emojis choisis par l'utilisateur
  (objectifs) et le palier réel de Comptes.
- **Langue** : « opération » canonique partout, épargne en ton neutre,
  boutons en mots, états vides guidés, promesses honnêtes (catégorie
  Impôts réelle, stockage des documents dit vrai).
- Chaque lot : test né rouge quand une vérité était en jeu, contrôle
  négatif, 4 audits outillés, captures avant/après inspectées, PR
  française, CI Web+iOS verte sur le HEAD exact, fusion squash,
  publication Pages au SHA de merge.

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
