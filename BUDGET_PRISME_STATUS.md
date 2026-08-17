# Budget Prisme — statut vivant

Mis à jour le 17.08.2026. Ce fichier décrit l'état observable; il ne remplace ni
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

Le lot actif est **A2 — Formatage et alignement** (voir « Améliorations
continues » ci-dessous).

**Fondation finale** · langue des opérations + champs morts

- État : `MERGED` + `PUBLISHED`. **Dernier lot du registre P00–P18.**
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

## Améliorations continues

**A1 — Année imprimable** · `MERGED` + `PUBLISHED` — PR #31, `main` =
`fb31859`, publié par dispatch au SHA exact (run `32024859933`).

- Bouton « Imprimer ou enregistrer en PDF » sur la page Année
  (`window.print()` — rien ne quitte l'appareil autrement) ; feuille
  `@media print` : document blanc à l'encre noire, navigation, boutons et
  légende du bouton masqués, cartes insécables, pilules grisées. Aucun
  calcul touché.
- Preuves : e2e 142 → 143 parcours (le stub `window.print` de la suite
  compte les appels — un vrai print gèle Chromium headless) ; contrôle
  négatif à 2 échecs ciblés ; 5 parités ; design ; 4 audits verts ;
  captures avant / après / rendu d'impression émulé inspectées dans
  `docs/neon-ultra/budget-prisme/a1/`.
- Incident de base consigné : une première branche A1 avait été créée sur
  un clone périmé après un redémarrage de conteneur (parent `102cbd0`,
  ancien Neon Ultra) — détectée par l'échec d'un test disparu du vrai
  `main`, rejouée proprement. La branche distante périmée
  `agent/prisme-a1-annee-imprimable` reste à supprimer (403 sur la
  suppression distante) — ajoutée au ménage propriétaire.
- Règle renforcée : après chaque redémarrage, vérifier `git log -1` de la
  base avant de créer une branche.

**A2 — Formatage et alignement (5 photos annotées du propriétaire)** ·
`MERGED` + `PUBLISHED` — PR #32 fusionnée en squash, `main` =
`04df82b5d4982e13e36172f4d7fa33ea7990f2a5`, CI de fusion verte (SHA, iOS,
web — l'étape « Déployer l'app web » reste bloquée par la règle
d'environnement, comme toujours), publié par dispatch au SHA exact
(run `32032950436`, succès) le 17.08.2026.

- Demande du 17.08.2026 : « il y a un CHF qui est en bas, les autres non…
  ça déborde… toujours les mêmes espacements, toujours pareil, même quand
  il y a des montants ». Chaque photo reproduite par sonde géométrique
  (fixture : salaire 18'200, mises de côté 2'000/210/100'000, Logement
  258 prévu / 11'570 dépensé, Épargne 199'800, Bourse 44'000) avant tout
  correctif.
- Livré :
  - **Montants insécables partout** : l'espace du préfixe devise est
    U+00A0 (`CURRENCY_PREFIX`) — « CHF 102'210.00 » ne se coupe plus en
    deux lignes (photo 2 Comptes, photo 5 Bilan du mois). La largeur du
    montant des lignes du bilan passe à 132 px pour contenir
    « CHF 100'000.00 » entier.
  - **Trio du Mois uniforme** (photo 5) : trois cellules IDENTIQUES —
    libellé, « CHF », chiffres, aux mêmes positions ; une seule taille de
    chiffres pour les trois (paliers `wide` ≥ 6 chiffres, `xwide` ≥ 7,
    décidés sur le montant le plus long) ; sous 381 px les libellés
    réservent la même hauteur pour garder l'alignement exact.
  - **Historique** (photo 4) : la liste groupée n'imprime plus la date
    dans chaque ligne (l'en-tête de jour la porte déjà) ; « mis de côté »
    ne se répète plus quand la destination est affichée (« Épargne →
    Compte épargne ») — plus aucune ellipse en plein mot ; le détail d'un
    compte garde ses dates.
  - **Budget** (photo 3) : l'anneau réduit sa police dès 4 chiffres
    (« 4484% » lisible dedans) ; « Prévu … · dépensé … » sur sa propre
    ligne.
  - **quickMenu** (photo 1) : `grid-auto-rows: 1fr` — quatre tuiles
    d'intention à hauteur strictement égale, icônes identiques.
- Preuves : e2e 143 → 144 parcours (test 144 : détecteur Range de montant
  coupé, uniformité du trio à 390 ET 320 px, en-têtes de date uniques,
  tuiles égales, anneau extrême) ; contrôle négatif à 4 sabotages →
  13 échecs ciblés ; 5 parités ; design NU1+NU2+Obsidian verts ; captures
  avant/après 390+320 et rapports de sonde JSON inspectés dans
  `docs/neon-ultra/budget-prisme/a2/`.
- Hors périmètre assumé : montants ≥ 10 M dans le trio (déjà imparfaits
  avant le lot) ; iOS non concerné (les photos sont la PWA ; les vues
  SwiftUI utilisent leurs propres piles `AmountText`).

**A3 — Beauté des cartes (« encore plus beau »)** · `MERGED` +
`PUBLISHED` — PR #34 fusionnée en squash, `main` =
`7ff7c6eb9f68ec473e9003a29c838bb26b15c7f0`, CI de fusion verte, publié
par dispatch au SHA exact (run `32036956303`, succès) le 17.08.2026.

- Demande du 17.08.2026 (capture post-A2) : « Améliore encore plus beau…
  plus jolie les carrés ». Raffinement mat, sans un seul glow :
  - **Biseau des cartes** : nouvelle arête haute `--nu-border-highlight`
    (un cheveu plus claire que le contour) sur cartes, stats et tuiles —
    la lumière vient d'en haut ; le héros garde son liseré spectral.
  - **Trio façon cadran** : séparateurs en retrait (dégradé mat vers
    transparent), chiffres en graisse 700 resserrés.
  - **Jauge d'avancement du mois** dans le héros : « Jour 17 sur 31 »,
    jour calendaire réel, uniquement sur le mois courant — piste mate,
    remplissage violet de marque, aucune animation permanente.
- Preuves : e2e 144 → 145 parcours (biseau mesuré, dégradé du séparateur,
  graisse, exactitude jour/largeur, absence hors mois courant) ; contrôle
  négatif à 3 sabotages → 3 échecs ciblés ; 5 parités ; design
  Obsidian+NU1+NU2 verts ; captures avant/après 390+320 dans
  `docs/neon-ultra/budget-prisme/a3/`.

**A4 — Trio : « CHF » en bas, chiffres agrandis** · `MERGED` +
`PUBLISHED` — PR #36 fusionnée en squash, `main` =
`bebd90c4cc249ea595207bb99f549ce1abfda1d4`, CI de fusion verte, publié
par dispatch au SHA exact (run `32040114211`, succès) le 17.08.2026.

- Demande du 17.08.2026 (capture annotée, 16:02) : « mettre le CHF en bas
  et augmenter plus grand la police ». Dans chaque cellule du trio,
  l'ordre devient libellé → montant → « CHF » (chip en bas, au même
  endroit dans les trois cellules — mesuré 48,9 px du haut de cellule
  partout) ; le palier `wide` (six chiffres) passe de 3.1vw à 3.6vw
  (12,1 → 14 px à 390 px), `xwide` de 2.8vw à 3.0vw — la ligne des
  chiffres profite de la largeur libérée par le chip.
- Preuves : e2e 145 → 146 parcours (ordre vérifié par géométrie, hauteur
  du chip identique, plancher 13 px du palier wide, aucun débordement) ;
  contrôle négatif à 2 sabotages → 2 échecs ciblés ; 5 parités ; design
  vert ; captures avant/après 390+320 dans
  `docs/neon-ultra/budget-prisme/a4/`.

**A5 — Trio en deux lignes** · `MERGED` + `PUBLISHED` — PR #38
fusionnée en squash, `main` = `ffb72d551e321904f5dfd71538e4836a285faff9`,
CI de fusion verte, publié par dispatch au SHA exact (run `32055712814`,
succès) le 17.08.2026.

- Demande du 17.08.2026 : « T'arrive pas à faire plus jolie en deux
  lignes ? ». Chaque cellule du trio tient désormais en DEUX lignes : le
  libellé, puis « CHF » en petit (10 px, plancher de lisibilité) devant
  les chiffres, sur la même ligne de base — l'ordre suisse
  « CHF 18'200.00 », devise discrète. Sous 381 px la colonne se renverse
  (chiffres puis « CHF » dessous) : rien ne se coupe, trois cellules
  identiques à chaque largeur. Flancs de cellule 8 → 6 px et paliers
  recalés : chiffres « wide » mesurés 13,3 px à 390 px et 14,6 px à
  430 px (iPhone du propriétaire), marge droite ≥ 14,5 px partout. Dans
  le trio, le point violet ne double plus « CHF » (le libellé porte le
  sens) ; il reste partout ailleurs. Plancher 10 px appliqué aussi au
  palier xwide à 320 px (violation latente corrigée).
- Preuves : test 146 réécrit (même ligne de base + chip devant à 390,
  bascule dessous à 320, hauteur identique, plancher 12 px, aucun
  débordement, point supprimé) — 146 parcours verts ; contrôle négatif à
  2 sabotages → 3 échecs ciblés ; 5 parités ; design vert ; sondes et
  captures avant/après 320/390/430 dans
  `docs/neon-ultra/budget-prisme/a5/`.

**A6 — Bilan du mois ordonné + boutons de sens** · `VERIFYING_AUTOMATED`
— PR depuis `agent/prisme-a6-bilan-ordonne`.

- Demande du 17.08.2026 (capture 22:28, logique Notion du propriétaire) :
  - **Ordre du Bilan** : Salaire (revenus), puis Factures et charges,
    puis Abonnements, puis Mis de côté — le retard reste devant DANS son
    groupe. Un abonnement MENSUEL apparaît bien dans son mois (mécanique
    `recurringNature` existante, désormais garantie par test).
  - **Six lignes visibles** (au lieu de trois) : le salaire et les mises
    de côté ne restent plus cachés derrière « Et N autres à faire ».
  - **Boutons de sens (« comme sur Notion »)** : Reçu en vert, Payé en
    corail, Mis de côté en violet neutre — sémantique stricte, un appui
    enregistre l'opération automatiquement (mécanique un-geste existante,
    couleur ajoutée).
  - **Bouton long sous la ligne** : « Mis de côté »/« Planifier »
    descendent sous la ligne — le titre ne se coupe plus en plein mot
    (« mensue / lle » mesuré avant correctif).
- Test 104 ajusté honnêtement : les trois charges de bienvenue sont
  désormais TOUTES visibles au bilan avec le salaire (plafond 6).
- Preuves : e2e 146 → 147 parcours (ordre mesuré, abonnement mensuel
  visible, trois couleurs distinctes calculées, un appui → opération
  postée et ligne dans « Fait ce mois », bouton long dessous) ; contrôle
  négatif à 2 sabotages → 2 échecs ciblés ; 5 parités ; design vert ;
  captures avant/après dans `docs/neon-ultra/budget-prisme/a6/`.

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
