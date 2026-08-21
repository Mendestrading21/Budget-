# Budget Prisme — statut vivant

Mis à jour le 20.08.2026. Ce fichier décrit l'état observable; il ne remplace ni
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

Programme **Budget Identités locales** (skill `budget-identites-locales`,
arrivé par la PR #91, `main` = `b6220fd`). Dernier lot publié : FE2-12
(ADR-035, run `32347846802`). Réconciliation de gouvernance faite le
20.08.2026 : l'ancienne ligne « lot actif : A2 » datait du 17.08 et
contredisait les lots publiés depuis (A3–A7, FE2-1 à FE2-12).

Six lots livrés, fusionnés dans l'ordre (#92 → #97) sur ordre du
propriétaire (« Publié et continue », 20.08.2026) et publiés ensemble par dispatch au SHA exact `58d5af29` (run `32413719185`, succès) le 20.08.2026 :
gouvernance, P0 AVS (ADR-036), IC0 (ADR-037), IC1 (ADR-038), REC1
(ADR-039), REC2 (ADR-040). CI verte sur chaque HEAD exact rebasé puis
sur `main`. Depuis, six lots supplémentaires fusionnés dans l'ordre sur
ordres du propriétaire : P08-C (#99, `6cef3ac`) et ID1 (#100,
`4a0646f`, « Fusionne et continue » du 21.08), puis la pile P05-C
(#101, `909d9e8`) → P06/P16 (#102, `2098a92`) → P13-C (#103,
`173b813`) → P10/P12-C (#104, `ff9bdba`) sur « Publié et continue fini
tout les lots en cours » du 21.08 — chaque PR rebasée à arbre
byte-identique et CI verte sur son HEAD exact, puis CI verte sur `main`
(pas de déploiement excepté). **Publiés ensemble** par dispatch au SHA
exact `ff9bdba` : run `32469395779`, succès, 21.08.2026. Puis INV1
(#105, `main` = `2192faa`) fusionné et publié sur « Continue et
publie » du 21.08 — dispatch au SHA exact `2192faa`, run
`32475209448`, succès : le site sert P08-C, ID1, P05-C, P06/P16,
P13-C, P10/P12-C et INV1. Audit de publication du 21.08.2026 : le log
du run `32475209448` prouve `TARGET_SHA = 2192faa…`, « CI verte
confirmée » pour ce SHA exact et « Checkout du SHA validé » en succès —
le contenu servi est bien celui de `2192faa` (les enregistrements de
déploiement au HEAD de la branche du workflow sont la comptabilité
interne de `deploy-pages`, sans effet). La lecture directe de
`github.io` est bloquée par la politique réseau de l'environnement —
vérification par les logs du run, pas par le site rendu. Dernier lot du programme : **BR1 —
provenance des marques** (en PR brouillon) ; approuver un premier actif
réel restera un micro-lot déclenché par le propriétaire
(LOGO_POLICY : revue humaine consignée obligatoire).

Fixture du catalogue validée le 20.08.2026 (commande du skill, sortie
observée) : **164 identités — CH 107 · FR 96 · BE 94** ; 28 banques,
8 courtiers, 15 assureurs, 19 télécoms ; tout en `monogram` ou
`generic_glyph`, aucun logo tiers.

**IC1 — Fondation Présentation (ADR-038)** · `MERGED` + `PUBLISHED` —
PR #95 (`main` = `b15a480`), publiés ensemble par dispatch au SHA exact `58d5af29` (run `32413719185`, succès) le 20.08.2026. Les 14 clés de catégories du
catalogue reçoivent de vrais glyphes des deux côtés (13 tracés PWA
originaux + 14 cas `BudgetGlyph`), la carte passe en mappage 100 %
direct ; monogramme déterministe partagé (`monogramFor` ↔
`BudgetMonogram`) prouvé par la fixture commune
`fixtures/monogram-cases.json` ; tuiles décoratives `identityTile` /
`BudgetIdentityIcon` (texte pur, aria-hidden, jamais d'image). Test
catalogue rouge d'abord (28 « absent du registre réel »), e2e 158-IC1 né
rouge ; consommation de `BudgetIcon` par P05/P08/P12/P13 reportée aux
lots d'écrans (décision ADR-038).

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

**A6 — Bilan du mois ordonné + boutons de sens** · `MERGED` +
`PUBLISHED` — PR #40 fusionnée en squash, `main` =
`39fec44039df009302d4e183934b57e07b94e928`, CI de fusion verte, publié
par dispatch au SHA exact (run `32070087322`, succès) le 17.08.2026.

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

**A7 — Bilan en quatre blocs** · `MERGED` + `PUBLISHED` — PR #42
fusionnée en squash, `main` = `efb75136adc60022d62b3878563b47f3172e65ec`,
CI de fusion verte, publié par dispatch au SHA exact (run `32112863070`,
succès) le 18.08.2026.

- Demande du 18.08.2026 : « quatre blocs, pas tout dans un seul bloc ».
  Le Bilan du mois courant devient un GROUPE de quatre cartes nommées —
  **Rentrées, Dépenses, Abonnements, Mis de côté** — sous un en-tête
  commun (compteur global + Gérer). Chaque bloc porte ses lignes à faire
  (bouton un appui, couleurs de sens A6) ET ses lignes faites : la ligne
  validée RESTE dans son bloc, marquée « Reçu/Payé/Mis de côté ce mois »,
  comme une case cochée de Notion. Compteur par bloc (« 2 à faire ·
  1 fait ») ; bloc sans rien : « Rien ce mois. » ; bornes par bloc
  (5 à faire + 3 faits + « Et N autres »). Un mois FUTUR garde sa carte
  unique « Prévu ce mois » (une prévision, pas une liste de cases) ; un
  mois vide garde son invitation.
- Deux tests historiques mis à jour honnêtement : « bilan unique »
  devient « groupe de quatre blocs nommés » (tests 35 et 91).
- Preuves : e2e 147 → 148 parcours (quatre titres exacts, chaque ligne
  dans SON bloc, réserve validée restée dans son bloc, mois futur à carte
  unique, un appui → « Reçu ce mois » sans quitter Rentrées) ; contrôle
  négatif : retour au bloc unique → échec net du test ; 5 parités ;
  design vert ; captures avant/après dans
  `docs/neon-ultra/budget-prisme/a7/`.

**A8 — Les quatre familles : plan + Historique** · `MERGED` +
`PUBLISHED` — PR #44 fusionnée en squash, `main` =
`cc346dece66dade9aee370edc6897c2a59cdfe02`, CI de fusion verte, publié
par dispatch au SHA exact (run `32116582990`, succès) le 18.08.2026.

- Demande du 18.08.2026 : « réorganise tout le concept… dépenses, reçues,
  investissement, abonnements… les logos, la structure du dossier ».
  - **`BUDGET_FAMILLES_PLAN.md`** : la matrice du nouveau concept — une
    seule grille (Rentrées · Dépenses · Abonnements · Mis de côté), même
    ordre, mêmes logos, mêmes couleurs partout ; état → cible pour chaque
    écran, lots A8→A12 planifiés (quickMenu, hub Gérer, Budget, dossier,
    iOS).
  - **Historique par familles** : chips « Tous · Rentrées · Dépenses ·
    Abonnements · Mis de côté · Virements », **partition stricte** via
    `txFamille()` — une dépense d'abonnement vit sous « Abonnements »,
    plus sous « Dépenses » ; chaque franc dans UNE famille ; virements et
    ajustements transversaux inchangés.
  - **« Ce qui revient »** : chips réordonnées à l'ordre canonique
    (Tout · Rentrées · Factures · Abonnements · Mis de côté).
- Preuves : e2e 148 → 149 parcours (ordre exact des chips, abonnement payé
  sous « Abonnements » seulement, partition vérifiée opération par
  opération, ordre de « Ce qui revient ») ; contrôle négatif à 2 sabotages
  → 3 échecs ciblés ; 5 parités ; design vert ; captures avant/après dans
  `docs/neon-ultra/budget-prisme/a8/`.

**A9 — Menu d'ajout et hub Gérer aux familles** · `MERGED` +
`PUBLISHED` — PR #46 fusionnée en squash, `main` =
`f3b61c6c0a425fdf511885e5554d9f3503c6685f`, CI de fusion verte, publié
par dispatch au SHA exact le 18.08.2026.

- Les quatre familles, suite (BUDGET_FAMILLES_PLAN.md) :
  - **Menu « Ajouter »** : intentions dans l'ordre canonique — J'ai reçu,
    J'ai dépensé, Ça revient régulièrement, J'ai mis de côté ;
  - **Hub Gérer** : le premier groupe s'appelle « Les quatre familles »
    (Ce qui revient + Factures ponctuelles) ; l'invite vide de « Ce qui
    revient » parle l'ordre des familles.
- Correctif de fixtures découvert par le rechargement réel : les
  récurrences de test A6 n'avaient pas de champ `day` — l'état persisté
  était honnêtement REFUSÉ par la validation stricte au rechargement
  (comportement app correct, fixture fautive). Fixtures corrigées : la
  suite traverse désormais un vrai rechargement avec cet état.
- Preuves : e2e 149 → 150 parcours (ordre du menu, premier groupe du hub,
  invite vide) ; contrôle négatif à 2 sabotages → 4 échecs ciblés ;
  5 parités ; design vert ; captures avant/après dans
  `docs/neon-ultra/budget-prisme/a9/`.

**A10 — Budget en mots de famille + logos uniformes** · `MERGED` +
`PUBLISHED` — PR #48 fusionnée en squash, `main` =
`1bf53882f70696fe5d1a3e91e43880ea7a64bf74`, CI de fusion verte, publié
par dispatch au SHA exact le 18.08.2026.

- Les quatre familles, suite : l'écran Budget appelle son groupe
  d'épargne par le mot de la famille — « **Mis de côté** » remplace
  « Épargne et investissements » (même contenu, même calcul, même
  séparation stricte d'avec les dépenses de vie). **Audit des logos** :
  les pastilles `.ico` + Budget Glyph ont exactement la même géométrie
  (44×44 / 20×20) sur le Mois, l'Historique et le hub Gérer — déjà
  uniformes, désormais GARANTI par test (une pastille dérogeante fait
  échouer la suite).
- Preuves : e2e 150 → 151 parcours ; contrôle négatif à 2 sabotages
  (ancien libellé ; pastille 40×40 sur le Mois) → 2 échecs ciblés ;
  5 parités ; design vert ; captures avant/après dans
  `docs/neon-ultra/budget-prisme/a10/`.

**A11 — Structure du dossier** · `MERGED` + `PUBLISHED` — PR #50
fusionnée en squash (`main` = `444f0a1`) ; lot documentaire publié avec
les dispatches suivants (marqueur « VERIFYING_AUTOMATED » périmé,
réconcilié le 21.08.2026 — `docs/INDEX.md` est sur `main`, `CLAUDE.md`
réaligné).

- Les quatre familles, suite (« la structure du dossier, tout ») :
  - **`CLAUDE.md` réécrit** pour dire la vérité opérationnelle : skill
    maître `/budget-prisme`, release sur `main` (branche → PR → CI →
    squash → dispatch au SHA exact), sources de vérité
    `BUDGET_PRISME_STATUS.md` + `BUDGET_FAMILLES_PLAN.md`, protocole par
    lot (resynchronisation après redémarrage, sonde d'abord, contrôle
    négatif, captures), invariants produit et autorité visuelle
    conservés mot pour mot (complétés : montants insécables, plancher
    10 px, couleurs de sens des familles).
  - **`docs/INDEX.md`** : la carte de tous les documents — ce qui fait
    foi, la préparation publication, l'histoire préservée (Obsidian,
    Neon Ultra, Horizon, Master — rien n'est réécrit ni déplacé), et où
    vit chaque chose.
- Lot documentaire : aucun code applicatif touché — la CI le confirme.

**A12 — iOS au vocabulaire des familles** · `MERGED` + `PUBLISHED` —
PR #51 fusionnée en squash, `main` =
`6f35830a5af79eef9f6d368cc986b79ab4486cef`, CI de fusion verte (build +
tests iOS), publié par dispatch au SHA exact le 18.08.2026. **Le plan
A8→A12 des quatre familles est entièrement livré.**

- Audit du vocabulaire des familles côté SwiftUI (grep systématique) :
  un seul écart structurel — `BudgetTab.swift` disait encore « Épargne
  et investissements ». Aligné sur « **Mis de côté** » (parité de
  vocabulaire avec la PWA, lot A10) ; même contenu, même calcul. Les
  autres usages (« Revenus » comme libellé de type de mouvement ou de
  statistique annuelle) sont conformes au plan : le vocabulaire de
  STRUCTURE parle familles, les libellés de mouvement restent.
- Validation : build + tests iOS par la CI (pas de simulateur local).

**A13 — Parité iOS du Bilan (quatre familles natives)** · `MERGED` +
`PUBLISHED` — PR #53 fusionnée en squash, `main` =
`b84863353af70c39907eac8c99d498347b43ea1f`, CI de fusion verte (build +
tests iOS du premier coup), publié par dispatch au SHA exact le
18.08.2026.

- « Tout ce que tu peux faire, fais-le » : le chantier restant exécutable
  sans propriétaire est la parité iOS. Ce lot porte au natif ce que la
  PWA a gagné (lots A3, A6, A7) :
  - **Bilan en quatre blocs** sur mois courant/passé — Rentrées,
    Dépenses, Abonnements, Mis de côté — chaque bloc avec son résumé
    (« 2 à faire · 1 fait » / « Rien ce mois. »), ses lignes à faire et
    ses lignes faites qui RESTENT dans leur bloc ; bornes 5+3 et
    « Et N autres » ; mois futur inchangé (liste « Prévu ce mois ») ;
  - **Partition stricte** : `HomePilotDisplay.family(for:isSubscription:)`
    + `HomeFamily` — un abonnement (champ `isSubscription` de la
    récurrence) vit dans SA famille, plus dans « Dépenses » ;
  - **Boutons de sens un-appui** : Reçu teinté vert, Payé corail,
    Mis de côté violet neutre (tokens sémantiques existants) ;
  - **Jauge du mois** dans le héros : « Jour X sur Y », jour calendaire
    réel, violet de marque, aucune animation permanente.
- Logique pure couverte par un test unitaire natif
  (`testHomeFamilyGridIsAStrictPartitionInCanonicalOrder`) : ordre
  canonique, partition exacte type par type, résumés de bloc.
  L'identifiant `home.month-summary.title` (UITest du tour Demo) est
  préservé.
- Validation : build + ~260 tests iOS par la CI macOS (pas de simulateur
  local sur ce runner Linux) ; la suite web n'est pas touchée.

**A14 — Listes natives aux familles** · `MERGED` + `PUBLISHED` — PR #55
fusionnée en squash, `main` = `d1370b14e28b51001b529eb0558188d0c557a110`,
CI de fusion verte, publié par dispatch au SHA exact (run `32141164454`,
succès) le 18.08.2026. Première CI de la PR rouge pour une raison saine :
deux tests figeaient l'ancien ordre du menu rapide
(`testQuickEntryOffersExactlyFourPlainIntentions`,
`testFourQuickIntentionsUsePlainFinancialGlyphs`) — mis à jour vers
l'ordre canonique des familles, CI verte ensuite.

- Parité iOS, suite (lots A8/A9 web) :
  - **Menu d'ajout natif** : les quatre intentions dans l'ordre des
    familles — J'ai reçu, J'ai dépensé, Ça revient régulièrement, J'ai
    mis de côté (l'ordre des cas de `QuickEntryIntent` est l'ordre
    affiché) ;
  - **« Ce qui revient » natif** : quatre sections dans l'ordre
    canonique — Mes rentrées, Mes factures, Mes abonnements (séparés par
    le drapeau `isSubscription`, jamais devinés), Mes mises de côté ; le
    total du héros reste calculé sur toutes les sorties régulières
    (chiffre inchangé) ;
  - **Historique natif** : rangée de chips de familles de premier
    niveau — Tous · Rentrées · Dépenses · Abonnements · Mis de côté ·
    Virements — partition stricte via `TransactionFamilyFilter`
    (l'abonnement quitte « Dépenses » ; ajustements transversaux sous
    « Tous » seulement) ; le menu « Filtres » (type précis, compte,
    statut) reste pour l'affinage et sa réinitialisation couvre la
    famille.
- Logique pure couverte par un test unitaire natif
  (`testTransactionFamilyFilterPartitionsEveryMovement`) : titres et
  ordre, partition exacte type par type, virements/ajustements à part.
- Validation : build + tests iOS par la CI macOS.

**A15 — Mois futur PWA : quatre blocs + « Planifier »** · `MERGED` +
`PUBLISHED` — PR #56 fusionnée en squash, `main` =
`ff59e51c706f4c4efeaf435b0719952bdc40fa5c`, CI de fusion verte, publié
avec A16 par dispatch au SHA `5f102c8b` (run `32142897362`, succès) le
18.08.2026.

- Demande propriétaire (18.08.2026, capture Septembre 2026) : « ajoute
  aussi la même mise en page que les autres et il manque toujours le
  bouton où j'appuie ». Un mois FUTUR montre les mêmes quatre blocs que
  le mois courant ; chaque ligne non planifiée porte un bouton un appui
  « Planifier », à la couleur de son sens.
- Honnêteté conservée : « Planifier » crée le mouvement PRÉVU du mois
  (échéance fin de mois, règle existante `recurringDueDate`) — jamais
  reçu ni payé d'avance ; une ligne déjà planifiée dit « · Prévu » sans
  bouton de confirmation ; les compteurs disent « N prévus », jamais
  « à faire » ; le mois futur vide garde son invitation.
- Preuves : parcours 152 ajouté ; parcours 104 et 148 mis à jour ;
  152 e2e + 5 parités + design verts ; deux contrôles négatifs (gate
  futur rétabli → 8 échecs ciblés ; confirmation future autorisée →
  1 échec ciblé) ; captures 390/320 avant (liste sans boutons) / après
  (4 blocs + « Planifier » + toast « planifié ») inspectées.

**A16 — Mois futur natif : quatre blocs + « Planifier »** · `MERGED` +
`PUBLISHED` — PR #57 fusionnée en squash, `main` =
`5f102c8bfd837b5de9a0ad2caf72c8e2f6ff1842` (parité iOS du lot A15,
compilation + tests natifs verts du premier coup), publié par dispatch
au SHA exact (run `32142897362`, succès) le 18.08.2026.

- `HomeTab` : le Bilan d'un mois futur montre les quatre blocs
  (`familyBlock(isFutureMonth:)`), compteurs « N prévus »
  (`HomeFamily.blockSummary(pending:completed:isFuture:)`), bouton
  « Planifier » réutilisant `post(occurrence)` →
  `makeTransactionIfNeeded` (statut `planned` garanti par
  `TransactionPostingPolicy.automaticStatus` pour une date future) ;
  une ligne déjà planifiée reste « Prévu » sans bouton (`canConfirm`
  inchangé). L'ancienne liste unique du futur et sa section « Fait ce
  mois » sont supprimées (diff net-négatif).
- Test natif étendu : cas `isFuture` de `blockSummary` dans
  `testHomeFamilyGridIsAStrictPartitionInCanonicalOrder`.
- Workflow Demo relancé sur `main` (A16 inclus) : run `32143463083`,
  succès — artifact simulateur `budget-demo` (142 Mo) téléchargeable
  depuis la page du run. Le réseau de l'agent ne peut pas télécharger
  les artifacts Actions (blob Azure refusé par la politique) : captures
  simulateur NON inspectées par l'agent, à regarder côté propriétaire.

**A17 — Borne unique du taux d'impôts natif (risque n° 4)** · `MERGED`
— PR #59 fusionnée en squash, `main` =
`58b74986694ad5a2b28d030554c26df04b5fa7bc`, CI de la PR verte du premier
coup, publié par dispatch au SHA exact (run `32144828974`, succès) le
18.08.2026 — statut `MERGED` + `PUBLISHED`.

- Mesure d'abord : la PWA borne le taux à 0–60 % aux deux endroits
  (commentaires « P11 (risque n°4) » en place) ; côté iOS la feuille
  « Votre taux » acceptait n'importe quel pourcentage (250 % stocké
  comme 2.5 sans un mot) et la validation d'onboarding montait à 100 %
  (slider limité à 50 %, mais le modèle est l'API).
- Correctif : constante unique `TaxService.maximumProvisionRate = 0.60` ;
  validation d'onboarding alignée (« entre 0 % et 60 % ») ;
  `AmountEntrySheet` gagne une borne haute optionnelle — la feuille
  Impôts refuse au-delà de 60 avec les mots de la PWA, jamais de
  troncature silencieuse ; les trois autres feuilles inchangées ; aucune
  donnée persistée réécrite.
- Test : `testTaxRateStepSharesTheSingleSixtyPercentBoundWithThePWA`
  (constante, 61 % refusé avec le bon message, 60 % accepté, négatif
  refusé). NB : remplacé au lot A19 par
  `testOnboardingNoLongerAsksForATaxRate` — l'étape d'onboarding a
  disparu, la constante et la borne de la feuille Impôts restent.

**A18 — L'onboarding PWA ne demande plus de taux d'impôts** · `MERGED`
+ `PUBLISHED` — PR #60 fusionnée en squash, `main` =
`012eb4f5e77a7e48ac0624d8a0e9b62fc9a0bc53`, publié avec A19 par
dispatch au SHA `7b9c49f7` (run `32154103046`, succès) le 18.08.2026.

- Demande propriétaire (18.08.2026, capture annotée pendant SON test) :
  « Déjà enlevé le taux d'impôts, on s'en fout. » L'étape salaire ne
  pose plus que la question du salaire ; le champ « Part mise de côté
  pour les impôts (%) », sa légende et la mécanique
  `captureTaxRate`/`obTaxRate` disparaissent.
- Le taux prend le défaut du pays (30 % en Suisse) et se règle dans
  Gérer → Impôts, toujours borné 0–60 % — borne désormais testée EN
  VRAI (parcours 136 : 61 refusé avec message sans rien changer, 25
  accepté, état rendu).
- Preuves : parcours 56 mis à jour (champ absent, salaire conservé au
  Retour, défaut 0.30 appliqué) ; 152 e2e + 5 parités + design verts ;
  deux contrôles négatifs mordants (champ réintroduit → 1 échec ciblé ;
  borne retirée → 1 échec ciblé) ; captures avant/après dans
  `docs/neon-ultra/budget-prisme/a18/`.

**A19 — L'onboarding natif ne demande plus de taux d'impôts** ·
`MERGED` + `PUBLISHED` — PR #61 fusionnée en squash, `main` =
`7b9c49f71e265a5cdee3d2c9caa96504e84e4d5e`, CI verte du premier coup,
publié par dispatch au SHA exact (run `32154103046`, succès) le 18.08.2026.

- Parité iOS du lot A18 : l'étape « Provision d'impôts » (slider)
  disparaît de `OnboardingStep` et d'`OnboardingFlowView` — la
  localisation mène directement au premier compte. Le taux garde son
  défaut 30 % et continue d'alimenter le ménage à la finalisation ; la
  seule saisie reste la feuille Impôts (borne A17 intacte). La visite
  guidée UITest saute l'écran supprimé.
- Test : `testOnboardingNoLongerAsksForATaxRate` (plus de cas
  `taxRate`, défaut 0.30, constante 0.60) ;
  `testFinishCreatesProfileCategoriesAndAccount` prouve toujours le
  30 % du ménage.

**A20 — Le disponible provisionne d'avance l'impôt des revenus
attendus** · `MERGED` + `PUBLISHED` — PR #63 fusionnée en squash,
`main` = `1592d279`, publié par dispatch au SHA exact
(run `32178827138`, succès) le 18.08.2026.

- Défaut confirmé par le propriétaire pendant SON test : le disponible
  chutait de tout l'écart fiscal seulement APRÈS la réception du
  salaire (8'150 → 6'710). Correctif : l'impôt des revenus attendus est
  anticipé — recevoir un revenu prévu ne fait plus bouger la projection.
- Preuves : parcours 153 (continuité à travers le rituel Reçu/Payé) ;
  contrôle négatif mordant ; suites complètes vertes.
- NB : remplacé fonctionnellement par FE2-0 (l'écart annuel ne pèse
  plus du tout sur le mois — seul l'effort mensuel compte), la
  propriété de continuité reste testée telle quelle.

**A22 — Grandes pastilles centrées sur le hub Gérer** · `MERGED` —
PR #64 fusionnée en squash, `main` = `fea4b9f7`, publication portée
par le dispatch FE2 (voir ci-dessous).

- Demande propriétaire (capture annotée) : « augmente encore un peu
  les emojis, plus grand, mais centre, un pool plus grand ». Pastilles
  du hub 44 → 54 px, glyphe 20 → 26 px, centrés — hub Gérer uniquement,
  les listes Mois/Historique restent inchangées.
- Preuves : parcours 151 (listes Mois+Historique identiques, hub
  uniforme « 54x54/26x26 ») ; contrôle négatif : règle CSS retirée →
  le 151 remord (« 44x44 ») ; captures dans
  `docs/neon-ultra/budget-prisme/a22/`.

## Programme FE2 — Moteur financier V2 (18.08.2026)

Cahier propriétaire transcrit dans `FINANCIAL_ENGINE_V2.md` (racine).
Règle d'or : **ne jamais présenter une projection comme de l'argent
possédé.** Cinq chiffres distincts (Disponible maintenant, Épargne
accessible, Fortune liquide, Prévu fin de mois, Fortune totale), fin de
la comptabilisation automatique par date (une date atteinte rend une
opération « à confirmer », elle ne prouve jamais que l'argent a bougé),
et séparation écart fiscal annuel / effort du mois (seul l'effort
mensuel réduit la projection). Tests de l'ancien comportement réécrits
EN MÊME TEMPS que le moteur, comme exigé.

**FE2-0 — Moteur PWA** · `MERGED` — PR #65, `main` = `2dcb2acc`.
`snapshot()` expose les agrégats explicites (`endOfMonthForecast`,
`taxMonthlyEffort`, `taxGapForecast`, `taxSetAsideMonth`,
`savingsAccessible`, `liquidWealth`) ; `promoteDuePlannedTransactions`
supprimée (une échéance passée affiche « À confirmer ») ; parcours 84
réécrit (un salaire prévu à date passée RESTE prévu, seul le geste
comptabilise) ; parcours 154 (écart annuel de 25'000+ n'écrase pas le
mois). Contrôles négatifs : promotion réintroduite → 84 mord ; écart
annuel rebranché → 154 mord.

**FE2-1 — Écrans PWA** · `MERGED` — PR #66, `main` = `ca837520`.
Grande carte à deux positions « Maintenant / Fin du mois » avec
décomposition écrite (X maintenant + Y à recevoir − Z à sortir) ;
Comptes : cartes « Ma fortune » et « Épargne » (stock ≠ flux) ;
Patrimoine : carte « Fortune liquide » à côté de la fortune totale.
Parcours 155 ; captures `docs/neon-ultra/budget-prisme/fe2-1/` aux
valeurs de l'exemple du cahier (5'000 / 6'710).

**FE2-2 — Parité Swift** · `MERGED` — PR #67, `main` = `791661eb`.
Mêmes formules dans `MonthlySnapshotService` (`taxMonthlyEffort`,
anticipation des revenus attendus, plafond par l'écart anticipé) ;
`TransactionPostingPolicy.promoteDueTransactions` et
`AppContainer.postDuePlannedTransactions` supprimés (le statut
automatique ne décide que du statut INITIAL d'une saisie datée) ; carte
héros native à deux positions (`HeroPosition`). Tests réécrits :
continuité (confirmer un revenu attendu ne change pas la projection),
écart annuel borné, échéances passées inertes sans geste.

**FE2-3 — Fixture de parité n° 6** · `MERGED` + `PUBLISHED` — PR #68
fusionnée en squash, `main` = `4758e4724f83c945144f82f28cf622283d4fc68d`,
CI verte sur le HEAD exact puis sur `main` ; publié par dispatch au SHA
exact (run `32189154462`, succès) le 18.08.2026 — ce dispatch unique
publie d'un coup A22 + FE2-0/1/2/3. Scénario
`moteur-v2-effort-mensuel` (juin 2026) verrouillant d'un coup : un
salaire prévu à date passée qui reste prévu (l'ancien moteur l'aurait
promu au chargement), un écart annuel énorme (revenu de 100'000 en
janvier, écart anticipé 31'140) qui ne pèse sur le mois que par
l'effort mensuel (1'140 = 30 % × 4'800 − 300 déjà mis de côté), et les
nouveaux agrégats (`savingsAccessible` 2'300, `liquidWealth` 107'000,
`endOfMonthForecast` 107'160). Contrôle négatif : projection rebranchée
sur l'écart annuel → la fixture 6 mord exactement (écart de 30'000).
Suites : 6 parités + 155 e2e + design, vertes.

**FE2-4 — Les vues d'argent natives (Comptes / Épargne / Patrimoine)** ·
`MERGED` + `PUBLISHED` — PR #72 fusionnée en squash, `main` =
`d7e18b9e`, CI verte sur le HEAD exact `b589a73` puis sur `main` ;
publié par dispatch au SHA final `b5e6e161` (run `32221728707`,
succès) le 19.08.2026, avec le lot audit 1.0 (PR #73 : registre
`BUDGET_1_0_READINESS.md`, script `repository-audit.mjs` 33/33 PASS,
ADR-033 créances). Parité iOS des cartes FE2-1 :

- Comptes : héros renommé « Disponible maintenant » (caption « Sur vos
  comptes utilisables au quotidien ») ; carte « Ma fortune » (Épargne
  accessible / Fortune liquide / Fortune totale — fortune totale lue
  dans `NetWorthService.breakdown`, la MÊME décomposition que l'écran
  Patrimoine, jamais un recalcul local) ; carte « Épargne » (stock
  « Épargne actuelle » d'un côté, flux « Mis de côté ce mois / cette
  année » de l'autre, jamais additionnés).
- Patrimoine : carte « Fortune liquide » (quotidien + épargne
  accessible, « mobilisable vite ») à côté de la fortune totale.
- Moteur : `NetWorthService.accessibleSavings` (comptes `savings`
  actifs seulement — ni titres, ni prévoyance, ni quotidien, comme la
  PWA) et `NetWorthService.liquidWealth` (union des qualités — un
  compte d'épargne aussi marqué « cash disponible » n'est compté
  qu'UNE fois, garde-fou absent de la PWA). `AccountsTab.setAsideFlows`
  ne compte que les mises de côté/investissements COMPTABILISÉS de
  l'intervalle — le prévu n'entre jamais dans un flux.
- Tests : `testAccessibleSavingsIsTheStockOfActiveSavingsAccountsOnly`,
  `testLiquidWealthCountsEachFrancExactlyOnce` (reflet de la fixture
  n° 6 : 104'700 + 2'300 = 107'000),
  `testSetAsideFlowsCountPostedSavingAndInvestmentOnly`.
  Contrôles négatifs structurels : titres dans l'épargne accessible →
  2'800 ≠ 2'300 ; double comptage → 109'000 ≠ 108'000 ; prévu compté →
  1'000 ≠ 500. Exécution par la CI (pas de simulateur local).

**FE2-5 — Une seule définition de « Fortune liquide » (PWA)** ·
`MERGED` + `PUBLISHED` — PR #75 fusionnée en squash, `main` =
`d524d5e4`, CI verte sur le HEAD exact puis sur `main` ; publié par
dispatch au SHA final `0091d449` (run `32230441056`, succès) le
19.08.2026, avec le correctif du tour Demo (PR #76 : le recentrage de
la courbe Évolution reste dans le viewport et hors de la courbe —
prouvé par le run Demo `32225260671`, succès, artefact « budget-demo »
avec les captures FE2-4).
L'audit FE2-4 a révélé deux formules web pour la même étiquette :
Comptes additionnait « cash disponible + épargne » (un compte d'épargne
aussi marqué cash était compté DEUX fois), le Patrimoine additionnait
les genres current/cash/savings (ignorant le choix « ne compte pas
dans le cash disponible »). Désormais `snapshot().liquidWealth` est
l'union des comptes cash et des comptes d'épargne — chaque franc UNE
fois, la même règle que le natif (`NetWorthService.liquidWealth`,
FE2-4) — et les cartes Comptes + Patrimoine LISENT le moteur au lieu
de recalculer. Parcours 156 né rouge (3 échecs exacts : 7'300 ≠ 7'000,
double compte de 300, Patrimoine à 8'000), vert après correctif ;
contrôle négatif : carte Patrimoine rebranchée sur les genres → le 156
remord seul. Suites : 156 e2e + 6 parités + design, vertes (fixture 6
inchangée au centime).

**FE2-6 — « Mis de côté en 2026 » dans le Patrimoine natif** ·
`MERGED` + `PUBLISHED` — PR #78 fusionnée en squash, `main` =
`eb0a7414`, CI verte + tour Demo vert sur le HEAD exact.
Dernière vue d'épargne manquante à la parité : la PWA montre, par
classe de placement (Épargne / Bourse / Prévoyance), le flux de
l'année et le total depuis toujours — le Patrimoine natif gagne la
même carte, entre le héros et la projection.
`ContributionService.classSummary` agrège les cumuls des comptes
ACTIFS d'une classe (source unique, testée :
`testClassSummaryAggregatesOnlyItsActiveAccounts` — l'archivé exclu,
l'année ne mélange pas 2025). Stock ≠ flux : la carte n'additionne
jamais ces montants aux soldes. Tour Demo re-prouvé sur la branche.

**FE2-7 — Barre de composition du héros Patrimoine natif** ·
`MERGED` + `PUBLISHED` — PR #79 fusionnée en squash, `main` =
`e3197105`, CI verte + tour Demo vert sur le HEAD exact `7e45038`
(l'invite de la courbe n'est exigée qu'avant toute lecture — le
défilement du tour peut l'effleurer, « dernière lecture conservée »). La PWA montre sous la
décomposition la part de chaque classe positive du patrimoine BRUT
(Sur vos comptes / Vos biens / Prévoyance) avec sa légende en % ; le
héros natif gagne la même barre. Rampe NON sémantique portée en
tokens (`NeonUltraColor.series1..3` = `--series-1..3` exacts). Les
dettes ne colorent jamais la barre — elles restent dans la
décomposition. Tests : `testCompositionPartsKeepOnlyPositiveClasses`
(classe négative sans part, 60 % exact, zéro sûr).

**CI durcie (PR #80 + PR #81)** · `MERGED` — le job web gelait par
périodes : d'abord marge (cache du navigateur Playwright + timeout
25 min, `main` = `d4606aab`), puis cause racine (le miroir apt
`azure.archive.ubuntu.com` pendait, appelé par `--with-deps` — 25 min
de silence au log du run `32236297184`) : plus AUCUN appel apt dans le
job (`main` = `28bb9c01`). Preuve : Web vert du premier coup sur les
runs suivants.

**Publication finale du cycle** : dispatch au SHA exact `28bb9c01`
(run `32239926920`, succès, 19.08.2026) — l'app en ligne porte
FE2-0..7 ; les lots FE2-6/7 sont natifs (la PWA publiée est celle de
`0091d449`, inchangée depuis).

**FE2-8 — Fixture de parité n° 7 : l'union de la fortune liquide** ·
`MERGED` + `PUBLISHED` — PR #82 fusionnée en squash (`main` =
`b1e1dc3`), série FE2 close (marqueur « en PR » périmé, réconcilié le
21.08.2026). Le scénario `fortune-liquide-union` grave la règle FE2-5 dans
le contrat de parité web↔natif : quatre comptes (courant hors
quotidien 1'000, quotidien 200, épargne 500, épargne marquée cash
300) → `liquid` 500, `savingsAccessible` 800, `liquidWealth` 1'000 —
jamais 1'300 (chaque franc une fois), le courant hors quotidien exclu.
Réconciliée du premier coup ; contrôle négatif : somme naïve
rebranchée → la fixture mord seule (obtenu 1'300, attendu 1'000).
Suites : 7 parités + 156 e2e + design, vertes.

**FE2-9 — Preuves visuelles des vues d'argent** · `MERGED` +
`PUBLISHED` (série FE2 close — marqueur « en PR » périmé, corrigé le
20.08.2026). Deux dettes
de preuve soldées :
- **Web** : captures 390 px de l'état DISCRIMINANT de FE2-5 (compte
  d'épargne aussi « cash disponible ») — Comptes et Patrimoine disent
  tous deux Fortune liquide **1'000** (jamais 1'300 ni 2'000), moteur
  vérifié en page avant capture, inspectées réellement —
  `docs/neon-ultra/budget-prisme/fe2-5/`.
- **Natif** : le tour Demo PROUVE désormais les cartes FE2-4/6 au lieu
  de les traverser — « Ma fortune » et « Épargne » assertées sur
  Comptes avant la capture ; « Mis de côté en <année> » et « Fortune
  liquide » ajoutées aux preuves nommées du Patrimoine (avant ET après
  défilement). Validé par un run Demo sur la branche.

**FE2-10 — La décomposition nomme l'impôt à mettre de côté** ·
`MERGED` + `PUBLISHED` — PR #85 fusionnée en squash, `main` =
`51d3f740`, CI verte sur le HEAD exact puis sur `main` ; publié par
dispatch au SHA exact (run `32283259619`, succès) le 19.08.2026.
Premier retour terrain de la v1.0.0 (capture propriétaire : « pourquoi
sortir 600 alors que je n'ai pas de facture ? ») : la ligne « à
sortir » de la position « Fin du mois » fondait l'effort d'impôts du
mois avec les vraies sorties — chiffre juste, étiquette mensongère.
Désormais chaque terme réel est NOMMÉ (« − X d'impôts à mettre de
côté ») et un terme à zéro se tait, sur les deux plateformes
(`noteFinMois` web ↔ `HomePilotDisplay.forecastDecomposition`).
Parcours 157 né rouge (« 1'009.90 à sortir » = 109.90 réels + 900
d'impôts fondus) ; test natif des deux sens ; capture de l'état exact
du propriétaire inspectée (`docs/neon-ultra/budget-prisme/fe2-10/`).
Aucune formule touchée — le moteur disait déjà vrai.

**FE2-11 — Aucun impôt automatique : la provision est OPT-IN
(ADR-034)** · `MERGED` + `PUBLISHED` — PR #87 fusionnée en squash,
`main` = `2de27b74`, CI verte sur le HEAD exact (`6df3bdd6`) puis sur
`main` ; publié par dispatch au SHA exact (run `32297267551`, succès)
le 19.08.2026. Contrôle négatif mordant : le défaut 0.30 remis
temporairement fait échouer les deux assertions du parcours 56, et
elles seules. Ordre propriétaire pendant sa QA : « ne calcule
pas les impôts automatiquement — c'est moi qui les mets comme
dépenses. » Tous les défauts de taux passent à ZÉRO (web : COUNTRIES,
gabarit vierge, assainisseur, fallback moteur, restauration, feuille
Impôts ; natif : Household, TaxProfile, OnboardingViewModel,
TaxService, MonthlySnapshotService, TaxesView) ; la démo garde 30 %
(elle montre la fonction) ; les formules FE2 restent intactes et
s'activent seulement quand l'utilisateur choisit un taux dans
Gérer → Impôts. Parcours 56 réécrit et né rouge (taux 0.3 appliqué en
douce, effort 1500 sans consentement) ; les tests fiscaux passent un
taux explicite. Données existantes non réécrites — le propriétaire
passe son taux à 0 % d'un geste.

**FE2-12 — Impôts 100 % manuels : le taux disparaît, l'app additionne
(ADR-035)** · `MERGED` + `PUBLISHED` — PR #89 fusionnée en squash,
`main` = `97b1efbe`, CI verte sur le HEAD exact (`0803058a`, avec tour
démo natif) puis sur `main` ; publié par dispatch au SHA exact (run
`32347846802`, succès) le 20.08.2026. Le lendemain de FE2-11, la capture du propriétaire
montrait toujours « − 600 d'impôts » : son appareil portait le taux 30 %
stocké d'avant (jamais réécrit, par principe). Ordre définitif : « une
page impôts où c'est moi qui mets combien je verse, comme une facture —
toutes les données, c'est moi qui dois les rentrer. » Le CONCEPT de taux
disparaît : plus aucune formule ne lit un taux stocké (le « − 600 »
s'éteint sans toucher à ses données), le moteur perd tous ses champs
fiscaux dérivés (projection = argent + attendu − sorties saisies, deux
plateformes), la page Impôts additionne payé / mis de côté / acomptes et
gagne « Ajouter un acompte », la feuille ne règle plus que le report.
Parcours 157 réécrit sur le scénario exact de sa capture, né rouge
(« − 900 d'impôts » encore présent) ; tests 53/56/82/107/136/153/154
réécrits ; fixture `impots-manuels-taux-herite` garde `taxRate: 0.3`
EXPRÈS dans le state (107'160 → 108'300) ; miroir natif complet ;
FINANCIAL_ENGINE_V2.md amendé. Au passage : le parcours 97 fournissait
son badge « Prévu » par accident du jeu de démo (l'acompte du jour 20) —
il injecte désormais son propre mouvement prévu, déterministe quel que
soit le jour du mois.

**P0 AVS — une rente n'est pas un capital (ADR-036)** · `MERGED` +
`PUBLISHED` — PR #93 (`main` = `051f669`), publiés ensemble par dispatch au SHA exact `58d5af29` (run `32413719185`, succès) le 20.08.2026. Premier lot codé du
programme Identités locales, exigé par l'alerte préalable du skill.
iOS : le 1er pilier est exclu de tous les agrégats de capital et du
patrimoine (`isAnnuity`), affiché à part « Rentes estimées — hors
patrimoine · à confirmer » ; aucun schéma touché. PWA : drapeau additif
`rente` (case dans la feuille), position marquée hors
`pensionPositionsTotal()` et non liable ; ligne ambiguë « AVS » comptée
telle quelle avec « À confirmer : rente ou capital ? » — rien n'est
réécrit en douce. Parcours 158 né rouge ; 2 tests natifs ajoutés ;
suites web vertes ; captures Prévoyance inspectées.
**IC0 — contrat du catalogue, fixture partagée et glyphes (ADR-037)** ·
`MERGED` + `PUBLISHED` — PR #94 (`main` = `b0f07d3`), publiés ensemble par dispatch au SHA exact `58d5af29` (run `32413719185`, succès) le 20.08.2026.
Aucun changement de modèle ni d'écran. Livré :
`fixtures/catalogue-identites.json` (octet-copie de la fixture du skill,
garde de synchronisation exécutable), `fixtures/catalogue-glyph-map.json`
(8 clés mappées PWA+iOS · 14 en repli commun `recurring` que IC1
remplacera — jamais de repli divergent entre plateformes), suite Node
`catalogue.test.mjs` branchée dans la CI avant les suites navigateur et
dans l'audit du dépôt. V1 = monogrammes et glyphes seulement
(`approved_asset` interdit avant BR1).

**REC1 — Cadences exactes : trimestriel et semestriel PWA (ADR-039)** ·
`MERGED` + `PUBLISHED` — PR #96 (`main` = `6b2c447`), publiés ensemble par dispatch au SHA exact `58d5af29` (run `32413719185`, succès) le 20.08.2026. Le natif exprimait
déjà tous les rythmes ((month,3), (month,6), (week,4)) ; la PWA ne
connaissait que mensuel/annuel. Elle gagne `quarter` et `semiannual`
ancrés par `dueM` (formule unique : écart à l'ancrage multiple du pas),
coût annuel exact ×4/×2, jamais réparti, résiliation identique, quatre
pastilles au formulaire, restauration stricte (rythme inconnu ou sans
ancrage refusé). `four_weeks` PWA volontairement hors lot : 13/an dont
un mois à DEUX échéances — incompatible avec la grille mensuelle sans
identité d'occurrence par date → lot REC2 dédié AVANT P08-C (preuve
native : test 13/an ajouté). Parcours 159 né rouge ; fixture de parité
8 « cadences-exactes » (580 prévu) ; 2 tests natifs ; suites vertes.

**REC2 — « toutes les quatre semaines » exact côté PWA (ADR-040)** ·
`MERGED` + `PUBLISHED` — PR #97 (`main` = `58d5af2`), publiés ensemble par dispatch au SHA exact `58d5af29` (run `32413719185`, succès) le 20.08.2026.
Après rebase de la pile, la numérotation e2e finale est : 158 P0 AVS ·
159 IC1 · 160 REC1 · 161 REC2 (161 parcours verts). La grille mensuelle
apprend le comptage d'échéances : `four_weeks` avec date d'ancrage
(`startOn`), 13 échéances/an jamais 12, mois à double échéance engagé
deux fois et attendant deux gestes (le 3e refusé), coût annuel × 13,
restauration stricte (date d'ancrage exigée). Rythmes existants
byte-identiques (dueCount 0/1). Parcours 160 né rouge ; fixture de
parité 9 « quatre-semaines-exactes » née rouge (juillet 2026 : échéances
des 2 et 30, 90 = 2 × 45) ; test natif miroir aux mêmes dates ; 160 e2e
+ 9 parités + design + catalogue verts.

**P08-C — Catalogue des services et saisie libre (ADR-041)** ·
`MERGED` + `PUBLISHED` — PR #99 (`main` = `6cef3ac`), fusionnée le
21.08.2026, publiée par dispatch au SHA exact `ff9bdba` (run `32469395779`, succès) le 21.08.2026. « Ce qui revient » gagne
« Choisir un service du catalogue » : 105 services/besoins (abonnements,
factures, mises de côté) filtrés par pays, recherche pliée avec alias,
sections par catégorie, « Je ne trouve pas mon service » qui restaure la
saisie. Choisir remplit AU PLUS nom + nature + catégorie sûre + rythme
compatible — jamais un montant, un compte, une date ni une ligne créée.
Une seule autorité : copie structurelle embarquée PWA (garde
exécutable) + `BudgetIdentityCatalog.swift` GÉNÉRÉ (garde de dérive en
CI) ; iOS limité CH+GLOBAL (base CHF). Parcours 162 né rouge ;
`BudgetIdentityCatalogTests` ; sélecteur natif
(`IdentityServicePickerView`) branché dans le formulaire récurrent.

**ID1 — Clé d'identité optionnelle, validation, schéma et sauvegardes
(ADR-042)** · `MERGED` + `PUBLISHED` — PR #100 (`main` = `4a0646f`), rebasée sur
#99 fusionné (arbre byte-identique vérifié), CI verte sur le HEAD
exact, fusionnée le 21.08.2026, publiée par dispatch au SHA exact
`ff9bdba` (run `32469395779`, succès) le 21.08.2026. Choisir Netflix persiste `identityKey: "netflix"` à
l'enregistrement — renommer « Mes films » garde l'identité (tuile
« N »). Règle de clé UNE et partagée (kebab 1-40, fixture 12 cas +
garde littérale PWA/natif) ; clé hostile retirée sans perdre la ligne
(restauration PWA, init du modèle natif, fichier de sauvegarde
trafiqué) ; clé inconnue conservée et repli monogramme (catalogue
extensible) ; `BudgetSchemaV9` additif, DTO optionnel, fichier ancien
restauré à l'identique. Parcours 163 né rouge ; 3 tests natifs ajoutés.

**P05-C — Établissements sur « Comptes » (ADR-043)** · `MERGED` +
`PUBLISHED` — PR #101 (`main` = `909d9e8`), fusionnée puis publiée par
dispatch au SHA exact `ff9bdba` (run `32469395779`, succès) le 21.08.2026. Le MÊME sélecteur sert
deux portes jamais mélangées : services (« Ce qui revient ») et
institutions (« Comptes » — 44 banques, courtiers et caisses de
prévoyance filtrés par pays, dont 19 pour la Suisse ; les assureurs
attendent P13-C). « Choisir ma banque ou mon courtier »
remplit UNIQUEMENT le champ « Établissement » — jamais un solde, un
accès, une connexion ni un nom de compte (légende honnête dans le
formulaire ; l'écran ne dit jamais « connecté », « synchronisé » ni
« en direct », assertion du parcours 164). La liste des comptes décore
par correspondance EXACTE nom/alias pliée (jamais un « contient » —
« CA »/« BP » ne devinent rien) via `institutionEntryFor` (PWA) et
`BudgetIdentityCatalog.institutionEntry(matching:)` (généré) ; sinon le
glyphe du type reste ; aucun agrégat ne change. Libellés français des
catégories d'institutions des deux côtés (Banques, Courtiers, Banques
en ligne). Parcours 164 né rouge ; 2 tests natifs ajoutés
(`testInstitutionEntriesStayOnTheirDoor`,
`testInstitutionMatchingIsExactNeverContains`) ; 164 e2e + 9 parités +
design + catalogue + audit verts ; captures 320/390 inspectées.

**P06/P16 — Fiche et onboarding (ADR-044)** · `MERGED` + `PUBLISHED` —
PR #102 (`main` = `2098a92`), rebasée à arbre byte-identique, CI verte
sur le HEAD exact, fusionnée puis publiée par dispatch au SHA exact
`ff9bdba` (run `32469395779`, succès) le 21.08.2026. La fiche de compte P06 porte la
MÊME tuile d'identité que la liste (correspondance exacte, un inconnu
reste sans tuile) ; l'étape comptes de l'onboarding P16 propose la
banque en OPTION — champ libre + « Choisir ma banque… » (sélecteur
d'institutions filtré par le pays choisi à l'étape 1, `svcCountry()`),
Annuler ne change rien, et RIEN n'est écrit avant la fin : le nom
devient l'`inst` du premier compte dans la même sauvegarde atomique
(PWA `finishOnboarding`, natif `OnboardingViewModel.finish`). Appelant
explicite du sélecteur (`svcPickerCaller` rec/acc/ob). Parcours 165 né
rouge (7 échecs nommés) ; `testFinishCarriesOptionalInstitutionName`
natif ; 165 e2e + 9 parités + design + catalogue + audit verts ;
captures 320/390 inspectées.

**P13-C — Assureurs (ADR-045)** · `MERGED` + `PUBLISHED` — PR #103
(`main` = `173b813`), rebasée à arbre byte-identique, CI verte sur le
HEAD exact, fusionnée puis publiée par dispatch au SHA exact `ff9bdba`
(run `32469395779`, succès) le 21.08.2026. Le sélecteur gagne une troisième
porte strictement séparée : mode assureurs — institutions au sens
`insurance` seulement (13 assureurs, CSS→Generali), jamais une banque,
jamais un besoin générique (« Assurance ménage » reste `generic`).
« Choisir mon assureur » sur la feuille Assurance remplit UNIQUEMENT le
champ assureur (instantané `svcInsSnapshot`) ; l'assureur reste
distinct du type de contrat ; la liste décore par la même
correspondance exacte que les banques (helper réutilisé, aucune
nouvelle architecture), l'inconnu garde son bouclier. Natif :
`insurerEntries` (générateur), `Mode.insurers`, bouton + feuille dans
`InsuranceFormView`, tuile dans `InsuranceRow`. Parcours 166 né rouge
(4 échecs nommés) ; `testInsurerEntriesStayOnTheirDoor` natif ; 166 e2e
+ 9 parités + design + catalogue + audit verts ; captures 320/390
inspectées.

**P10/P12-C — Icône choisie préservée (ADR-046)** · `MERGED` +
`PUBLISHED` — PR #104 (`main` = `ff9bdba`), rebasée à arbre
byte-identique, CI verte sur le HEAD exact, fusionnée puis publiée par
dispatch au SHA exact `ff9bdba` (run `32469395779`, succès) le 21.08.2026. Deux défauts réels
corrigés sur P10 : la PWA imposait 🎯 à la modification d'un objectif
sans emoji (désormais le défaut ne s'applique qu'à la création, vide
reste vide) ; le natif réécrivait `goal.emoji = kind.defaultEmoji` à
chaque enregistrement, détruisant un emoji restauré — règle unique
testable `FinancialGoal.emojiAfterEditing` (l'emoji ne suit le type que
tant qu'il n'a jamais été personnalisé). P12 vérifié conforme des deux
côtés (glyphes dérivés du type, emoji stocké jamais rendu) et
verrouillé par le test. Parcours 167 né rouge (« obtenu 🎯 ») ;
`FinancialGoalEmojiTests` natif ; 167 e2e + 9 parités + design +
catalogue + audit verts ; captures 320/390 inspectées.

**INV1 — Positions manuelles datées (ADR-047)** · `MERGED` +
`PUBLISHED` — PR #105 (`main` = `2192faa`), fusionnée puis publiée par
dispatch au SHA exact `2192faa` (run `32475209448`, succès) le
21.08.2026. Autorité de patrimoine : le SOLDE du
compte titres — les positions l'expliquent (valeur + espèces/non
réparti = solde, 44'000 jamais 84'000, dépassement en négatif averti,
jamais ramené à zéro). Champs du contrat du skill (`instrumentName`,
`tickerOrISIN?`, `quantity`, `manualPrice`, `priceCurrency`,
`valuationDate`, `costBasis?`) ; « Prix saisi le … », jamais « en
direct » ni « cours actuel » (interdits et testés). PWA : clé d'état
additive `positions` (ancien état → `[]`, restauration tolérante — une
position illisible/orpheline est retirée sans faire échouer le
fichier), section sur la fiche du compte titres + feuille `posForm`.
Natif : `BrokeragePosition` (`BudgetSchemaV10` additif, ADR-015),
`BrokeragePositionMath` testable, section `AccountDetailView`
(`.broker`), `PositionFormView`, DTO de sauvegarde optionnel (fichier
ancien restauré à l'identique), garde de suppression de compte.
Parcours 168 né rouge (6 échecs nommés) ; `BrokeragePositionTests`
natif (4 tests) ; 168 e2e + 9 parités + design + catalogue + audit
verts ; captures 320/390 inspectées.

**BR1 — Provenance des marques (ADR-048)** · en PR (brouillon, fusion
sur ordre du propriétaire). Le manifeste versionné
`fixtures/provenance-marques.json` (version 1, zéro entrée = couverture
complète, le monogramme n'est pas un échec) et son validateur en CI
(suite catalogue) : `approved_asset` interdit sans entrée complète —
13 champs de LOGO_POLICY, clé existante, fallback sûr, SHA-256 et
checksum EXACT recalculé sur le fichier, entrées orphelines refusées.
Mention légale visible des deux côtés (réglages « Marques et logos » :
« ni affilié, ni sponsorisé, ni connecté », aucun logo tiers
aujourd'hui). Correctif d'honnêteté : la méthodologie native parlait
encore d'un « taux configuré (30 % par défaut) » — alignée sur ADR-035.
Suite catalogue née rouge (3 échecs nommés) ; parcours 169 ; contrôle
négatif par sabotage ; captures 320/390 inspectées. Approuver un
premier actif réel = micro-lot futur déclenché par le propriétaire.

**INV1-B — Garde de suppression des positions (ADR-049)** · en PR
(brouillon, empilée sur GOV-3/#107). Chasse aux défauts
post-programme : la PWA ignorait les positions dans
`accountDeleteBlocker` — supprimer un compte titres laissait ses
positions orphelines en silence (perte muette à la restauration) ; le
natif avait déjà la garde. Corrigé : même règle des deux côtés (« Des
positions expliquent ce compte — supprimez-les d'abord sur sa
fiche »), et « Effacer les opérations » DIT désormais qu'il efface
aussi les positions (confirmation + confidentialité). Parcours 170 né
rouge (2 échecs nommés) ; 170 e2e + 9 parités + design + catalogue +
audit verts ; captures 320/390 inspectées.

**INV1-C — Le type d'un compte à positions ne change pas en silence
(ADR-050)** · en PR (brouillon, empilée sur INV1-B/#108). Changer le
type d'un compte titres rendait ses positions invisibles alors que la
suppression restait bloquée (ADR-049) en pointant une fiche qui ne les
montrait plus — impasse des deux côtés. Corrigé : quitter « Bourse /
titres » avec des positions est bloqué en le disant, même règle PWA
(`accForm`) et natif (`AccountFormView.save`) ; sans position, le
changement reste libre. Parcours 171 né rouge (« type savings » obtenu
en silence) ; 171 e2e + 9 parités + design + catalogue + audit verts ;
captures 320/390 inspectées.

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
4. P11 : **confirmé et corrigé.** PWA : bornes 0–60 % déjà alignées
   pendant P11 (commentaires « risque n°4 » dans le code). Natif : la
   feuille Impôts n'avait AUCUNE borne — corrigé par le lot A17
   (constante unique `TaxService.maximumProvisionRate`).
5. P10 iOS : **vérifié corrigé** — la section « Archivés » de
   `GoalsTab` (commentaire « P10 (risque n°5) ») garde tout objectif
   archivé visible et rouvrable.
6. Publication web : règle d'environnement `github-pages` à corriger par le
   propriétaire avant de pouvoir marquer la version fusionnée `PUBLISHED`
   sans dispatch manuel.
7. Dépôt GitHub : la branche par défaut reste une ancienne branche Claude;
   ne pas l'utiliser pour baser une PR ou un artefact de release.

## Prochaine action exacte

Registre P00–P18, améliorations A1–A22, programme FE2-0..4 : terminés,
fusionnés et **publiés** (dernier dispatch au SHA `b5e6e161`, run
`32221728707`, succès, 19.08.2026). Audit « créances » : exclusion
documentée (ADR-033). Audit release : `BUDGET_1_0_READINESS.md` +
`repository-audit.mjs` 33/33 PASS. Verdict courant :
**READY FOR TESTFLIGHT (côté code)** — voir le registre 1.0 ; le tag
`v1.0.0` attend les actions propriétaire (secrets Apple, QA iPhone,
décisions App Store) et son accord explicite. Prochain travail agent
seulement sur demande : FE3 (créances) ou finitions. Discipline
inchangée : audit, tests rouges d'abord, contrôle négatif, suites
complètes, PR, CI verte sur le HEAD exact, fusion squash, publication
au SHA de merge.
