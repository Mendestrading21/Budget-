# Budget — Neon Ultra : état d'avancement

Programme actif (ADR-024) · branche `main` (v1 unifiée le 13.08.2026 ;
historique : tags `archive/…`) · créée
depuis `26d186e8e31bbdf1bc41651afcaf7a1699988644` (dernier HEAD Obsidian à CI
verte prouvée — run CI #229 id 30221277893, success, jobs Web + iOS).

| Lot | Intitulé | État |
|---|---|---|
| NU0 | Gouvernance et baseline | **DONE** (validation définitive du propriétaire le 27.07.2026, CI #231 verte sur `828ea63`) |
| NU1 | Tokens et primitives | **DONE** (validation du propriétaire le 27.07.2026 sur `5796e3c`) |
| NU2 | Pilote PWA — Mois, Budget, Ajouter | **DONE** (validation du propriétaire le 27.07.2026 sur `ff029388`, publication Pages autorisée) |
| NU3 | Pilote SwiftUI équivalent | **VERIFYING** (CI macOS verte, 296 tests iOS, captures simulateur inspectées — validation du propriétaire attendue) |
| NU4 | Mouvements, Comptes et shell | À VENIR |
| NU5 | Factures, Objectifs et Récurrents | À VENIR |
| NU6 | Patrimoine et graphiques | À VENIR |
| NU7 | Onboarding, confiance, réglages, identité | À VENIR |
| NU8 | Mouvement, accessibilité, performances | À VENIR |
| NU9 | Audit final | À VENIR |

## Les données restaurées restent du texte inerte (14.08.2026) — VERIFYING

Lot correctif isolé sur `agent/budget-securite-donnees`. Il ne modifie ni
calcul financier, ni modèle, ni sauvegarde : il ferme les points de rendu HTML
qui acceptaient encore des valeurs historiques restaurées sans échappement.

### Invariant tenu

- Un identifiant historique reste exactement le même en mémoire et dans
  `localStorage` : il peut toujours ouvrir, modifier et supprimer son
  mouvement.
- Cet identifiant ne peut plus sortir de `data-txid` ou `data-confirmtx` pour
  créer un attribut ou un gestionnaire d'évènement.
- Les icônes restaurées des récurrents, abonnements, biens, dettes, assurances
  et prévoyance sont affichées comme texte, jamais interprétées comme HTML.
- La migration de la toute première clé locale échappe aussi ses anciennes
  dates dans l'Historique et dans la fraîcheur des comptes.
- La validation et la restauration atomique existantes restent inchangées :
  aucune migration destructive n'est introduite pour masquer le défaut.

### Preuves

- Nouveau parcours navigateur 120 dans un contexte isolé : état hostile
  restauré, absence d'élément/attribut/script injecté, identifiant textuel
  intact, puis vraie modification et vraie suppression vérifiées en mémoire
  et sur disque.
- Le même parcours ouvre Patrimoine, Assurances, Récurrents et Abonnements,
  puis rejoue la migration `budget-proto-mouvements` sur Historique et Comptes.
- `node --check` sur les trois suites `.mjs`, syntaxe des deux scripts inline et
  `git diff --check` : propres.
- Chromium n'est pas présent dans ce conteneur : le navigateur réel doit être
  confirmé par la CI GitHub avant toute fusion.

## Mon mois en 10 secondes (14.08.2026) — DONE, SOURCE PUBLIÉE

Le lot vertical ADR-030 a été fusionné dans `main` par la PR #5, commit
`68f28790ffb88ea44a0adf44de5ba17b58a54285`, sans migration ni modification
des moteurs financiers.

### Résultat visible

- PWA et iOS : un héros mensuel, une phrase de rythme, trois repères et une
  liste unique `À faire ce mois` ; le carrousel, la carte de rythme autonome,
  la grille de grandes cartes et les tuiles ont quitté l'accueil.
- Un seul `Ajouter` ouvre quatre intentions humaines. Le formulaire courant
  commence par le montant et replie les choix techniques. `J'ai mis de côté`
  prépare réellement Épargne, Impôts ou 3e pilier et leur compte d'arrivée.
- iOS : revenus, factures, épargne et investissements ont des libellés/action
  distincts ; une date future n'a plus de bouton qui prétend qu'elle est déjà
  payée. L'ajout depuis un autre mois reçoit la date de ce mois.
- Récurrents iOS : `Facture · Abonnement · Revenu · Mise de côté`, avec le
  prochain passage visible, puis le rythme et la date de fin sous options
  avancées. L'écran de gestion sépare factures, mises de côté et revenus.
- PWA : les réserves mensuelles proposent exactement `Épargne · Pilier 3a ·
  Impôts`; les feuilles sont des dialogues nommés, le menu Ajouter piège le
  focus et restitue le focus à sa fermeture.

### Preuves locales

- `git diff --check` : propre.
- Scripts inline PWA, trois fichiers de test `.mjs` et tous les JSON : syntaxe
  valide.
- Tests adaptés : accueil sans tuiles/carrousel, quatre intentions, cibles
  44 px, dialogue accessible, verbes mensuels et soumission réelle des trois
  réserves.
- Tests Swift ajoutés : intentions rapides, natures récurrentes, verbes,
  échéance future et conservation du mois sélectionné ; tours UI adaptés.

### Validation et publication

- CI `31801855513` entièrement verte sur le SHA fusionné : Web (119 parcours
  navigateur, parité, design/accessibilité) et iOS (build, tests unitaires,
  Release, PrivacyInfo, iPhone-only).
- Le code source est bien publié sur `main`.
- La PWA en ligne n'a pas encore reçu ce SHA : le run Pages `31801855597` est
  rejeté avant toute étape parce que l'environnement `github-pages` n'autorise
  pas la branche `main`. Action propriétaire : Settings → Environments →
  `github-pages` → Deployment branches and tags → autoriser `main`, puis
  relancer le workflow Pages.

## Mettre de côté est une ligne mensuelle — et l'argent arrive quelque part (10.08.2026) — VERIFYING

Demande du propriétaire : **« Je veux ça dans facture 🧾. Parce que pour moi,
mettre de côté, ça part de mes factures mensuelles… sans le virement : ce qui
sort de mon compte chaque mois. »**

### Ce que j'ai trouvé en allant vérifier — un défaut d'argent (P1)

Le choix existait bien, mais replié sous « Détails (facultatif) ». En ouvrant
le code pour le remonter, j'ai mesuré bien pire. Sonde reproductible sur
données fictives :

```
patrimoine avant   3'400.00
patrimoine après   2'900.00      ← 500 CHF disparus
solde d'épargne        0.00      ← l'argent n'est arrivé nulle part
mouvement créé     type saving, dest: null
```

Une ligne mensuelle de nature « réserve » créait un mouvement `saving` /
`investment` **sans compte d'arrivée**. L'argent quittait le compte source et
n'atterrissait sur aucun compte : le patrimoine baissait du montant réservé,
**chaque mois**. C'est l'exact inverse de l'invariant du projet — mettre de
côté est neutre pour le patrimoine. Le défaut date du lot C1 (07.08).

### Ce qui change

1. **Un seul axe visible dans la feuille**, à la place de deux (Dépense/Revenu
   en haut + nature cachée sous « Détails ») : `🧾 Facture · 🔁 Abonnement ·
   🏦 Mettre de côté · 💰 Revenu`. Pas de virement — une ligne mensuelle est
   ce qui **sort** du compte. Les deux selects historiques (`rType`,
   `rFamily`) restent la source de vérité ; le choix unique les écrit.
2. **La poche d'arrivée devient un vrai champ**, visible seulement pour une
   mise de côté et **jamais facultatif**. Défaut déduit de la catégorie
   (3e pilier → prévoyance, sinon épargne), jamais le compte de départ.
3. **`materializeRecurring` pose la destination** et **refuse** de créer le
   mouvement s'il n'existe aucune poche possible — un refus visible plutôt
   qu'un patrimoine faux. Les deux appelants affichaient déjà le message.
4. **Réparation des mouvements déjà créés** : un mouvement `saving` /
   `investment` sans destination **et lié à une ligne mensuelle** retrouve la
   poche de sa ligne. Bornée exprès : un mouvement saisi à la main n'est
   jamais touché, et si aucune poche ne se déduit, rien n'est modifié.

### Preuves

- **Parcours 114 « mise de côté sans évaporation »** : 500 sortent du compte
  courant, arrivent sur l'épargne, le patrimoine ne bouge pas d'un centime, le
  mois compte 500 de mis de côté ; sans compte d'arrivée l'app refuse et le
  dit ; la réparation touche l'ancien mouvement lié et **rien d'autre**.
- **Parcours 115 « mettre de côté au premier plan »** : quatre choix sur un
  seul axe, aucun virement, rien sous un repli, 44 px chacun, la poche
  apparaît pour une réserve et jamais pour un revenu ni une facture.
- **Contrôle négatif exécuté** : `dest` remis à `null` → 4 assertions tombent,
  dont `le patrimoine ne bouge pas d'un centime (44963.95 → 44463.95)`.
- 115 e2e · 5 parités · design system · audit-total 320/390/430 · audit-final
  (14 contrôles) — verts. Captures 390 et 320 px inspectées.

### Le natif audité et aligné (même journée)

Résultat de l'audit annoncé : `RecurringScheduleService.makeTransaction`
propageait déjà `recurring.destinationAccount`. Le natif n'avait donc **pas**
le trou de la matérialisation. Mais il l'avait par une autre porte —
`TransactionValidationService` déclarait la destination **facultative** pour
`.saving` et `.investment` (commentaire « Destination optional »), et le
formulaire annonçait même « (facultatif) » dans le libellé. Un utilisateur
pouvait donc créer nativement la même ligne qui évapore l'argent.

Corrigé :

- destination **obligatoire** pour `.saving` et `.investment`, nouvelle
  erreur typée `missingContributionDestination` avec son message français ;
- `.debtPayment` garde la destination facultative — elle désigne la dette
  remboursée, et rembourser une dette non suivie par l'app reste un cas
  réel. Ce périmètre est tenu par un test dédié, pour que le durcissement ne
  déborde pas ;
- la feuille des lignes mensuelles refuse la destination vide ou égale au
  compte de départ ;
- les libellés cessent de promettre « facultatif » là où la règle l'exige.

Tests natifs : `testSavingRequiresADestinationSoMoneyNeverVanishes`
(**inversion assumée** de `testSavingWithOptionalDestinationIsValid` — la
raison est écrite dans le test, l'ancien n'a pas été supprimé mais retourné),
`testDebtPaymentStillAcceptsNoDestination`,
`testMaterializedContributionCarriesItsDestination`,
`testContributionWithoutDestinationIsRejectedAtEntry`.
Décision consignée en **ADR-029**.

**Non vérifié ici, et c'est une vraie limite** : cet environnement n'a aucun
compilateur Swift. Le natif est validé par la CI macOS, pas par une
exécution locale — le résultat de la CI fait foi.

### Incident d'environnement (10.08.2026)

Le conteneur a été recyclé en cours de session : le clone local est revenu à
`102cbd0`, deux commits en arrière. Les commits `e7c7e6a` et `c203f2f`
étaient déjà sur GitHub et intacts ; le travail natif en cours a été mis de
côté, la branche remise sur `origin`, puis le travail réappliqué. Aucune
perte. Noté ici parce qu'un rapport qui tait un incident n'est pas un
rapport.

### Prochaine action exacte

Retour du propriétaire sur l'app installée.

## Version 1 — le dépôt devient une seule vraie version (13.08.2026) — VERIFYING

Demande du propriétaire : « trie tout ce qu'il y a sur GitHub, un seul
dossier avec la seule vraie version, efface les anciennes versions, que ce
soit la version une ». Autorisation explicite donnée pour toucher aux
branches, aux PRs et à la branche par défaut.

### Règle appliquée : rien n'est perdu, tout est rangé

- **`main` devient la seule branche**, créée depuis l'état Neon Ultra
  complet. La branche par défaut du dépôt (qui était `claude/execute-tbkhsd`,
  un reste) bascule sur `main`. Tag **`v1.0.0`** posé.
- **Chaque ancienne branche reçoit un tag `archive/…` avant suppression** :
  son contenu reste accessible à jamais, seule la liste des branches est
  nettoyée. Les deux PRs ouvertes (vers l'ancienne branche par défaut) sont
  fermées avec un mot d'explication.
- **La racine du dépôt est rangée** : `archives/` reçoit les journaux des
  programmes précédents (Obsidian Glass, Horizon, Master Evolution), les
  six skills historiques et `docs/obsidian-glass` (préservés à l'identique,
  ADR-024 : jamais réécrits). La racine ne garde que la version vivante :
  code, autorités, journal, décisions, préparation App Store.
- **Nouveau `README.md`** : ce qu'est l'app, où l'installer, ce qui ne
  bouge jamais, comment développer.
- **Workflows** : Pages déploie depuis `main` ; la CI couvrait déjà `main` ;
  Demo reste manuel.

### Résultat de la chirurgie distante (13.08.2026)

Fait depuis la session :

- **`main` créée** sur l'état v1 (`ff69d0a`), CI verte dessus (web + iOS).
- **Sept branches d'archive** créées — une par ancienne tête :
  `archive/obsidian-glass-v1`, `archive/execute-tbkhsd`,
  `archive/budget-project-connection-link`,
  `archive/codex-audit-simplicite-budget`,
  `archive/codex-budget-leader-refonte`,
  `archive/codex-budget-pwa-simplification-v2`,
  `archive/v0.5.0-phases-0-5`. (Le proxy de la session bloque la création
  de TAGS — git et API — les archives sont donc des branches ; elles se
  convertissent en tags en une minute depuis une machine normale.)
- **Les deux PRs ouvertes fermées** (#1, #2) avec un mot d'explication et
  le nom de leur archive.
- **La v1 est déployée sur Pages** (run dispatch vert sur `ff69d0a`).

Bloqué par le proxy de la session — trois clics du propriétaire :

1. **Branche par défaut → `main`** (Settings → General) : refus
   « Repository settings writes are not permitted ».
2. **Environnement `github-pages` : autoriser `main`** (Settings →
   Environments) : le premier déploiement depuis `main` a échoué avant sa
   première étape — règle de branches de l'environnement. Le déploiement
   v1 est passé par un dispatch sur l'ancienne branche, encore autorisée.
3. **Supprimer les sept anciennes branches** (la suppression est ignorée
   par le proxy en git et refusée en API). À faire APRÈS le clic 1 pour
   `claude/execute-tbkhsd`, encore branche par défaut.
4. Facultatif : Releases → « v1.0.0 » sur `main`.

### Vérifié avant de toucher au distant

Aucun outil ni workflow ne référence les fichiers déplacés (grep sur
`.github`, `webapp`, `Budget*`, outils du skill). La seule occurrence de
« budget-web » dans les tests est l'identifiant du FORMAT d'export — une
constante de données, pas un chemin. Suites complètes relancées après le
rangement.

## La bannière est prouvée à l'écran, plus seulement en calcul (12.08.2026) — VERIFYING

La limite consignée au lot précédent — « le branchement feuille → coquille
n'a pas de test automatique » — se referme aux deux tiers.

### Ce qui change

- **Crochet de lancement `-uiTestGoalBanner`** (même famille que
  `-uiTestImportCSV` et `-uiTestRestorePrompt`) : pose une annonce fictive
  dès le démarrage du mode démo.
- **`testGoalProgressBannerShowsAndDismisses`** dans le tour UI : la
  coquille AFFICHE la bannière (capture `17-bandeau-objectif` à l'appui) et
  la FERME — au toucher ou par l'effacement automatique, les deux chemins
  sont valides et l'un des deux doit survenir.

### Pourquoi un crochet, et pas un vrai versement

Le mode démo vit à la date RÉELLE. Un parcours « marquer la mise de côté
payée » serait vert avant le 15 du mois et rouge après — un test flaky par
calendrier ne prouve rien. Le crochet rend le test déterministe ; ce qu'il
ne couvre pas est dit ci-dessous.

### Ce qui reste non couvert, précisément

La ligne d'assignation dans `TransactionFormView.save()` et dans
`HomeTab.post()` (« un enregistrement réussi pose le message ») n'a
toujours pas de test automatique. C'est une affectation gardée par
`status == .posted`, dont le calcul amont et l'affichage aval sont
désormais couverts chacun. Le maillon du milieu se vérifie sur appareil :
mettre 50 CHF de côté et voir la bannière.

### Résultat (12.08.2026, run Demo 31640534718)

- CI verte sur `a55638b`, et **workflow Demo vert** — déclenché depuis la
  session (le refus `workflow_dispatch` constaté le 08.08 ne s'applique pas
  à la voie GitHub App).
- `testGoalProgressBannerShowsAndDismisses` **passé sur simulateur**
  (13,1 s) : la coquille affiche la bannière et la ferme. Sa capture
  `17-bandeau-objectif` est exportée dans l'artefact.
- Le tour complet est passé (527 s, 25 captures) : `01-accueil` montre
  désormais la carte du rythme.
- Deux allers-retours avant le vert, dits ici : (1) le point d'insertion du
  nouveau test avait volé le `@MainActor` de `snap()` — cible UITests
  incompilable, CI et Demo rouges une fois ; (2) réparé, relancé, tout vert.
- **Limite d'environnement** : l'artefact (200 Mo) est servi par un blob
  Azure que le proxy de cette session bloque — les captures n'ont PAS été
  ouvertes ici. Elles sont téléchargeables par le propriétaire :
  <https://github.com/Mendestrading21/Budget-/actions/runs/31640534718>
  (artefact `budget-demo`, expire le 10.11.2026).

### Prochaine action exacte

Retour du propriétaire : ouvrir l'artefact `budget-demo` (captures
`01-accueil` et `17-bandeau-objectif`), puis tester sur l'app installée.

## L'iPhone fête aussi les progrès — la dette du lot précédent est soldée (10.08.2026) — VERIFYING

Le lot précédent avait consigné une dette : l'annonce de progrès d'objectif
n'existait que côté web, faute d'infrastructure de message éphémère sur iOS.
Elle est construite, et la dette est fermée.

### Ce qui change

- **`GoalProgressService`** (`Budget/Domain/Services/`) : le calcul PUR du
  message, miroir du web — photo des valeurs AVANT l'écriture, candidats
  reliés au compte qui reçoit, paliers 25 / 50 / 75 / 100 %, départage
  palier → priorité → le plus avancé, UN seul message. La valeur courante
  vient de la même règle que l'écran Objectifs (solde du compte relié).
  Seuls les objectifs ACTIFS parlent : un objectif en pause l'a été exprès,
  un objectif atteint a déjà eu son message.
- **`GoalProgressBanner`** dans la coquille (`MainTabView`) : bannière
  éphémère en haut, surface mate + liseré (aucun glow), fondu simple déjà
  correct en mouvement réduit, toute la bannière est le bouton de fermeture
  (≥ 44 pt), disparition seule après 4 s. VoiceOver reçoit l'annonce
  immédiatement via `UIAccessibility.post`, sans dépendre de la durée.
- **L'état vit sur `AppContainer`** (`goalProgressMessage`) : l'écriture
  part d'une feuille qui se ferme aussitôt — un message posé dans la
  feuille mourrait avec elle. Même précédent que `duePostingErrorMessage`.
- **Deux portes branchées**, comme le web : la feuille de saisie
  (`TransactionFormView`, seulement quand le mouvement est COMPTABILISÉ)
  et « Marquer payée » sur l'accueil (`HomeTab.post`).

### Preuves

- **`GoalProgressServiceTests`** (8 tests) : pourcentages identiques à
  l'écran Objectifs (68 % → 78 % recalculés), palier dit en mots, silence
  sur une dépense ordinaire, silence sur un mouvement PRÉVU (aucun solde ne
  bouge), seuls les objectifs actifs parlent, compte partagé = un seul
  message et le palier l'emporte sur la priorité, la priorité l'emporte sur
  le plus avancé, et un objectif absent de la photo reste muet.
- Le tour de démo (captures CI) ne marque jamais de facture payée : aucune
  interférence de la bannière avec les captures existantes.
- **Non vérifié ici** : pas de toolchain Swift local — la CI macOS fait foi.

### Limite honnête

Le branchement de la bannière (feuille → coquille) n'a pas de test
automatique : c'est de la plomberie SwiftUI que seule une UI-test
dédiée couvrirait. Le calcul, lui, est entièrement testé ; côté web le
contrôle négatif avait précisément montré qu'un branchement peut casser
sans qu'un test de fonction le voie — c'est documenté ici plutôt que caché.

### Prochaine action exacte

CI macOS verte, puis retour du propriétaire sur l'app installée.

## L'iPhone dit le même rythme que le web (10.08.2026) — VERIFYING

Le rythme du mois n'existait que côté web. Le natif avait le même trou que
le web avant lui : `MonthSnapshot` calcule `dailyAvailableBudget` et
`daysRemaining` depuis des mois, et l'accueil n'en montrait qu'une ligne
discrète « CHF X par jour » sous le héros.

### Ce qui change

- **`MonthRhythm`** (`Budget/Domain/Snapshots/MonthRhythm.swift`) : le
  calcul PUR, séparé de la vue. Deux cas — `pace` (parts d'argent et de
  temps, budget du jour, marge de trois points avant « en avance ») et
  `overdrawn` (le manque, dit en positif). Il lit les MÊMES grandeurs du
  snapshot que le web lit du sien : jamais une seconde formule. Les parts
  sont des `Double` car ce sont des géométries d'affichage ; l'argent reste
  en `Decimal`, conformément à l'invariant.
- **La carte « Où vous en êtes »** dans `HomeTab`, entre le héros et les
  quatre montants : budget du jour en grand, règle graduée (remplissage =
  argent parti, jalon clair = temps écoulé, liseré sombre pour que le jalon
  se détache du vert comme de l'ambre — leçon du web, où il a d'abord été
  peint invisible), verdict écrit qui dit la même chose que la teinte. À
  découvert : pas de barre, le fait et le temps restant.
- **La ligne « CHF X par jour » quitte le héros** : la carte du rythme
  porte le même chiffre en grand. La garder aurait été un doublon — le
  défaut que l'audit de cohérence traque côté web.
- La barre est `accessibilityHidden` : décorative, le verdict écrit porte
  les pourcentages pour VoiceOver.

### Preuves

- **`MonthRhythmTests`** (8 tests) : mois passé silencieux, dans le rythme,
  en avance, la marge de trois points testée à ses DEUX bords (52 % pour
  50 % du temps reste calme, 54 % avertit), découvert dit en positif,
  enveloppe vide silencieuse, part bornée à 100 %, et un test qui prouve
  que le raccourci snapshot lit les mêmes grandeurs que le cœur primitif.
- **Non vérifié localement** : aucun compilateur Swift dans cet
  environnement — la CI macOS (build + tests + captures Demo) fait foi.

### Dette assumée, à décider

L'annonce de progrès d'objectif (« 🛟 Fonds d'urgence : 68 % → 71 % ») n'a
PAS été portée au natif dans ce lot : l'app iOS n'a aucune infrastructure de
message éphémère (toast), et en créer une est une décision de design à part
entière (placement, durée, VoiceOver). Plutôt qu'un à-peu-près, c'est noté
ici comme prochaine décision produit.

### Prochaine action exacte

CI macOS verte, puis retour du propriétaire sur l'app installée.

## Le geste dit ce qu'il fait avancer (10.08.2026) — VERIFYING

Mettre 250 CHF de côté et lire « Mouvement ajouté », c'est perdre le seul
moment où l'app peut donner envie de recommencer.

### Ce qui change

Quand un mouvement alimente un compte relié à un objectif, le message dit ce
qui vient de bouger :

```
🛟 Fonds d'urgence : 68 % → 71 %
✈️ Voyage — La moitié est atteinte
🎯 Permis — C'est fait, objectif atteint 🎉
```

Les deux portes le disent : la feuille de saisie **et** « Marquer mis de côté
ce mois » sur une transaction mensuelle.

Trois règles tenues :

- **un constat, jamais une félicitation creuse** — les pourcentages viennent
  de `goalCurrent`, la même source que l'écran Objectifs ;
- **un seul emoji, et seulement sur un vrai palier** (25 / 50 / 75 / 100 %) :
  la constitution interdit l'esthétique de casino, donc pas de confettis à
  chaque franc ;
- **rien du tout** si rien n'avance, si le mouvement est seulement prévu, ou
  si aucun objectif n'est relié.

### Une vraie question posée par le test

Plusieurs objectifs peuvent être reliés au **même compte** : le solde monte
pour tous. Annoncer « le premier de la liste » aurait été arbitraire. L'ordre
est explicite et testé : un **palier franchi** passe devant, puis l'objectif
**prioritaire**, puis le **plus avancé**. Un seul message, jamais trois.

### Un trou dans mon propre test, trouvé par le contrôle négatif

Débrancher l'annonce du message ne faisait tomber **aucune** assertion : mes
contrôles appelaient la fonction, jamais le geste. Un parcours passant par la
feuille de saisie a été ajouté ; le contrôle négatif le fait maintenant
tomber avec « obtenu : Mouvement ajouté ».

### Preuves

- **Parcours 119 « un objectif qui avance se voit »** : progrès annoncé et
  vrai, pourcentages identiques à l'écran Objectifs, rien sur une dépense
  ordinaire, rien sans mouvement, palier dit en mots, au plus deux emojis,
  départage sur compte partagé, et le geste réel par la feuille.
- **Contrôles négatifs exécutés** : annonce débranchée → 1 assertion tombe ;
  départage retiré → 1 assertion tombe.
- 119 e2e · 5 parités · design system · audit-total 320/390/430 · audit-final
  · audit-coherence — verts.

### Prochaine action exacte

Retour du propriétaire sur l'app installée.

## Le rythme du mois : répondre à la vraie question (10.08.2026) — VERIFYING

« Est-ce que je peux sortir ce week-end ? » ne se répond pas avec un solde.
Elle se répond avec un **rythme**.

### Ce que j'ai trouvé

L'app calculait `daily` et `daysRemaining` **depuis des mois**… dans
`renderHome`, l'écran détaillé qui n'est plus rendu depuis ADR-026. Le calcul
le plus utile de l'application était juste, testé, et **invisible**.

### Ce qui change

Une carte « Où vous en êtes », sous le héros du mois en cours :

- **`CHF 544.97 par jour pendant 21 jours`** — le disponible réparti sur les
  jours qui restent.
- **Une règle graduée à deux repères** : le remplissage marque la part de
  l'enveloppe libre déjà dépensée, un jalon blanc marque la part du mois
  écoulée. Si l'argent va plus vite que le temps, le remplissage passe en
  ambre et la phrase le dit.
- **À découvert, aucune barre** : « Il manque CHF 800.00 pour finir le mois »,
  et l'action utile. Une jauge pleine ferait la morale ; ce n'est pas le rôle
  de l'app.

C'est un **constat arithmétique** sur ses propres données, jamais un conseil.
L'enveloppe libre = déjà dépensé + disponible ; `available` ayant déjà déduit
ce qui doit encore sortir, rien n'est compté deux fois.

### Trois défauts trouvés en chemin, dont deux à moi

1. **Le repère du temps était invisible.** Peint en `var(--text)`, un jeton
   qui n'existe pas : pour une propriété non héritée, une variable inconnue
   tombe en **transparent**. La position était juste, le test de position
   passait, et on ne voyait rien. Les pastilles de filtre du lot précédent
   avaient le même défaut.
2. **Mon test était trop faible** : il vérifiait la position du jalon, pas sa
   visibilité. Il mesure désormais la couleur réellement peinte.
3. **Mon garde-fou anti-jeton-fantôme criait au loup** : il ne lisait que
   `index.html` et signalait neuf jetons Neon Ultra définis dans la feuille
   liée. Corrigé : il lit maintenant toutes les feuilles référencées.

### Un texte retiré, puis remis ailleurs

La carte a fait passer l'accueil de 220 à 249 mots — mon propre audit de
cohérence a attrapé ma régression. J'ai retiré une légende de 24 mots qui
**répétait** la note de la carte « Mis de côté ce mois », et déplacé
l'explication sur la carte qui porte le chiffre. Le parcours 88 a refusé la
première version (l'explication avait disparu sans remplaçante) : il avait
raison. Accueil de retour à 220 mots, rythme compris.

### Preuves

- **Parcours 118 « le rythme du mois »** : montant par jour et jours restants
  recalculés depuis le moteur, barre et jalon comparés au centième, équivalent
  texte pour VoiceOver, couleur et phrase qui disent la même chose, et le cas
  à découvert sans barre.
- **Garde-fou permanent** : « aucun jeton CSS fantôme » — chaque `var(--x)`
  employé doit être défini. Contrôle négatif exécuté.
- **Contrôle négatif du rythme** : jalon et remplissage échangés → 2
  assertions tombent.
- 118 e2e · 5 parités · design system · audit-total 320/390/430 · audit-final
  · audit-coherence — verts. Captures 390 et 320 px, plus le cas à découvert.

### Prochaine action exacte

Retour du propriétaire sur l'app installée.

## Choisir où va l'argent, et un seul mot pour la ligne mensuelle (10.08.2026) — VERIFYING

Deux demandes du propriétaire sur la feuille d'une ligne mensuelle.

### 1. « Affiche-moi les comptes que j'ai ouverts »

Le champ existait mais ne montrait que des noms nus, dans l'ordre de
création. Il dit maintenant, pour chaque compte réel : **son nom et son
solde** — `Épargne · CHF 13'700.00`, `Pilier 3a · CHF 19'364.00`. La poche
la plus probable est proposée en premier (prévoyance pour un 3e pilier,
épargne sinon), et le compte de départ n'y figure jamais.

Première version testée : `nom — nature · solde`. La capture à 390 px a
montré le montant coupé par le chevron du sélecteur, et la nature répétait
ce que le nom dit déjà. Retirée.

L'exemple d'intitulé suit aussi le choix : proposer « Loyer » sous une mise
de côté, c'était suggérer le contraire de ce qu'on vient de choisir. Chaque
nature a le sien — Loyer, Netflix, Épargne de secours, Salaire.

### 2. « Facture mensuelle » devient « Transaction mensuelle »

Le mot était devenu faux : l'écran accueille aussi des abonnements, des
mises de côté et des revenus. Renommé partout sur les deux plateformes —
écran, menu Gérer, accueil, menu ＋, feuille, états vides, messages de
confirmation, et l'app iPhone. Deux défauts de langue corrigés au passage :
« Supprimer cette facture mensuelle **mensuelle** ? » et une bascule de
genre devenue fausse.

Les messages disent aussi le bon geste : on ne « paie » pas une mise de
côté. Le bouton dit « Marquer mis de côté ce mois », et le message de
confirmation « Mis de côté ce mois — l'argent est arrivé sur l'autre
compte ».

### Preuves

- **Parcours 116 « choisir où va l'argent »** : tous les autres comptes
  proposés et eux seuls, le compte de départ jamais, le nom réel de chaque
  compte présent, le solde affiché, l'épargne en tête, et quatre exemples
  d'intitulé distincts.
- **Parcours 117 « un seul mot »** : plus aucun « facture mensuelle » visible
  sur l'accueil, le menu Gérer, l'écran, les abonnements ni la feuille.
- **Contrôle négatif exécuté** : ancien libellé et ancienne liste remis →
  4 assertions tombent.
- Neuf assertions existantes **adaptées** au nouveau mot, aucune supprimée
  ni affaiblie.
- 117 e2e · 5 parités · design system · audit-total 320/390/430 ·
  audit-final — verts. Captures 390 px inspectées.

### Prochaine action exacte

Retour du propriétaire sur l'app installée.

## Le retour ressemble enfin à un retour (10.08.2026) — VERIFYING

Question du propriétaire, capture de « Factures mensuelles » à l'appui :
**« pourquoi il y a ici le bouton ? pour voir les mouvements du mois ? »**

Réponse : non. C'était le **retour vers Gérer**. Écrit `‹ Gérer` dans un
bouton plein, il avait exactement la forme des actions de contenu de l'écran
(`＋ Ajouter une facture…`), donc il se lisait comme une destination à
ouvrir. Le propriétaire avait déjà tranché la même question sur le
questionnaire d'accueil le 06.08 : *« enlève la barre retour et ajoute une
flèche vers la gauche »*. La règle valait pour les douze autres écrans, elle
n'y avait simplement pas été appliquée.

### Ce qui change

`backBar()` — la barre partagée par les **douze écrans de Gérer** — passe du
bouton plein `‹ Gérer` à la même flèche 44 × 44 que le questionnaire
(`.ob-back`). Le nom de la destination ne disparaît pas : il passe dans
`aria-label="Retour à Gérer"`, donc VoiceOver annonce toujours où l'on va.
Un seul point de code, douze écrans corrigés.

Le mois, lui, était déjà là : chaque ligne porte sa pastille
« Payée ce mois », « À régler ce mois » ou « Pas ce mois ». L'écran répond
déjà à la question, aucun bouton supplémentaire n'était nécessaire.

### Preuves

- **Parcours 113 « retour lisible sur les écrans de Gérer »** (nouveau) :
  pour chacune des douze vues, le retour est une flèche seule, porte un nom
  accessible qui contient encore la destination, mesure au moins 44 × 44 et
  s'aligne au centre du titre ; puis un clic réel prouve qu'il ramène bien à
  Gérer (`activeTab = "more"`, `moreView = null`).
- **Contrôle négatif exécuté** : l'ancien bouton remis en place fait tomber
  **24 assertions sur 12 écrans**. Le test discrimine, il ne décore pas.
- 113 e2e · 5 parités · design system · audit-total 320/390/430
  (« Aucun écran en défaut », un seul bord gauche à 18 px) · audit-final
  (14 contrôles) — verts.
- Captures inspectées à 390 px : Factures mensuelles, Impôts 2026,
  Abonnements.

### Prochaine action exacte

Retour du propriétaire sur l'app installée.

## Le héros tourne, et un loyer n'est plus un abonnement (06.08.2026) — VERIFYING

Trois retours du propriétaire sur ses vraies données, la même nuit.

### 1. « Le mis de côté, c'est le montant disponible après les factures ? »

Non — et le fait qu'il pose la question EST le défaut. « Mis de côté », c'est
l'argent envoyé vers ses comptes d'épargne. Ce qu'il cherchait, « Disponible »,
était déjà là, en haut, sans le dire.

Deux corrections, aucune invention de chiffre :

- Une phrase sous les quatre tuiles : *« Mis de côté » = l'argent envoyé vers
  vos comptes d'épargne ce mois. Ce n'est pas ce qui vous reste : ça, c'est
  « Disponible », en haut.*
- Chaque carte du héros écrit désormais **d'où vient son montant**.

### 2. Le héros tourne

Demande explicite : « que tu puisses tourner le widget et avoir tout,
placement, patrimoine, disponible, prévoyance… que je puisse choisir de gauche
à droite ». Cinq cartes aimantées, un point par carte :

`Disponible` · `Mis de côté ce mois` · `Épargne et placements` ·
`Prévoyance` · `Patrimoine`

Aucun gestionnaire de geste maison : c'est le défilement natif avec
`scroll-snap`. Le clavier, la molette et VoiceOver fonctionnent donc seuls, et
le mouvement réduit remplace le glissement par un saut. Les points font 44 px
de cible pour 7 px de dessin — la première version était à 30 px, le test l'a
refusée.

Rien n'est additionné entre les cartes : chacune répond à une question, avec sa
propre phrase d'explication.

### 3. Un loyer n'est pas un abonnement

Sur ses données réelles, l'écran annonçait **« vos abonnements coûtent
CHF 98'652.00 par an »** en comptant loyer, crèche et leasing dedans. Faux.

Le champ `family` ajouté plus tôt ne réglait le cas que des NOUVELLES saisies.
Il fallait une règle pour les données déjà là :

- `family` explicite (« Abonnement » / « Charge du foyer ») dans la feuille,
  sous « Détails », avec des pastilles ;
- à défaut, **déduction par catégorie** : Logement, Assurance maladie,
  Transports et Impôts sont des charges du foyer.

Ce classement est **calculé à l'affichage** : aucun montant ne bouge, rien
n'est réécrit sur le disque, et un choix explicite l'emporte toujours sur la
déduction. L'écran Abonnements annonce en bas ce qu'il n'affiche pas — sinon il
aurait l'air d'oublier des dépenses.

### Preuves

- **105 parcours e2e** (104 conservés + le n° 105) · 5 parités · design vert.
- Deux gardes **adaptées avec leur raison écrite** : le total attendu de
  l'écran Abonnements ne compte plus que les abonnements ; la règle « un seul
  bord gauche » exclut les cartes d'un carrousel horizontal, qui sont côte à
  côte par construction — et uniquement celles-là.
- **Contrôles négatifs** : remettre le loyer dans les abonnements → échec
  nommé ; figer le héros → échec nommé.
- Défaut trouvé par le test et corrigé : points de 30 px, sous le seuil tactile.

## Plus de jour de paiement, et deux écrans de charges (06.08.2026) — VERIFYING

Deux demandes du propriétaire, le même soir : « enlève les jours de paiement
ou date » et « ajoute une page question pour les dépenses mensuelles et une
autre page abonnement — comme ça il peut déjà rentrer pas mal de trucs avant
d'ouvrir l'app ».

### 1. Le jour de paiement disparaît

Personne ne connaît par cœur la date de prélèvement de six abonnements, et se
tromper d'un jour faisait apparaître **« En retard »** sur une facture
parfaitement à jour. La règle qui remplace le jour tient en une phrase :

> **Une charge régulière est due DANS le mois.**

Elle n'est donc jamais en retard tant que le mois court, et elle l'est dès que
le mois est passé — ce que donne exactement la fin du mois comme échéance.
Une seule fonction, `recurringDueDate(y, m)`, plutôt que `r.day` recopié à dix
endroits.

Conséquences assumées et vérifiées :

- Le champ « Jour du mois (1-28) » disparaît de la feuille des factures
  mensuelles, et « Jour de réception » de celle du salaire.
- Les libellés perdent leur date : « Tous les mois, le 22 » → « Tous les
  mois » ; « à régler depuis le 25 » → « pas encore payée ».
- Les pastilles **« En retard »** et **« À venir »** disparaissent au profit de
  **« À régler ce mois »** / **« À recevoir ce mois »**.
- « Planifier ce mois » n'existe plus : sans date, il ne planifiait qu'une
  date. Reste « Marquer payée ce mois ».
- Marquer une charge payée la date **du jour**, pas d'un 1er inventé. Dater du
  1er une facture réglée le 20 serait faux.
- **Les FACTURES gardent leur échéance au jour près.** Une facture sans date
  d'échéance ne sert plus à rien : l'app ne pourrait plus dire ce qui est en
  retard. C'est le périmètre choisi par le propriétaire, sur trois options.
- Le champ `day` **reste dans les données** (le contrôle de chargement exige un
  entier 1-28) et n'est jamais réécrit sur un enregistrement existant.

### 2. Deux écrans de plus à la bienvenue : charges, puis abonnements

Le parcours passe de 6 à 8 étapes. Les deux nouveaux écrans posent une liste de
postes courants avec un champ montant à droite. Ce qui n'est pas rempli
n'existe pas ; **aucun montant n'est proposé d'avance** — remplir un budget à
la place de quelqu'un, c'est lui mentir sur ses propres chiffres.

L'enjeu n'est pas le nombre d'écrans. C'est qu'à la **première ouverture**,
« Disponible » veuille déjà dire quelque chose au lieu d'afficher le salaire
entier comme s'il était libre. Mesuré sur le parcours de test : salaire 5'500,
solde 3'400, trois charges et un abonnement saisis → l'accueil affiche
« À payer 2'081.90 » et « 0 sur 4 payées » sans que l'app ait été ouverte une
seule fois.

Rien n'est **comptabilisé** pour autant : ce sont des dépenses PRÉVUES, elles
ne deviennent réelles qu'une fois marquées payées. Le test le vérifie
(`transactions.length === 0`).

Un montant illisible est **refusé en nommant sa ligne**, jamais transformé en
zéro dans le dos de la personne.

### 3. Un loyer n'est pas un abonnement

Conséquence directe et non anticipée du point 2 : l'écran « Abonnements »
listant toutes les dépenses régulières, il annonçait « vos abonnements coûtent
27'009.60 par an » **en comptant le loyer dedans**. Faux en français courant.
Champ **additif** `family: "charge"` sur les cinq postes du foyer ; l'écran
Abonnements les exclut. Une récurrence enregistrée avant ce champ n'en a pas et
reste affichée exactement comme avant — aucune donnée n'est réécrite. Après
correction : 2 abonnements, CHF 1'330.80 par an.

### 4. Le retour devient une flèche

Demande du propriétaire, capture annotée à l'appui : le bouton « ‹ Retour »
pleine largeur avait le même poids visuel que « Continuer » — trois dalles
empilées dont une qui recule. Remplacé par une flèche de 44 px en haut à
gauche, là où le pouce la cherche. Le geste existe toujours, il ne crie plus.

### Un défaut préexistant trouvé au passage

Le halo décoratif des écrans de bienvenue faisait **10 px de débordement
horizontal à 320 px**, depuis sa création — un `width: 340px` en dur dans un
écran plus étroit que lui. Personne ne l'avait vu parce qu'aucun test ne
visitait l'onboarding à 320 px. Corrigé (`min(340px, 100%)`), et le nouveau
test mesure désormais ce débordement.

### Preuves

- **104 parcours e2e** (103 conservés + le n° 104) · 5 fixtures de parité ·
  design system vert · zéro erreur console.
- Deux gardes **inversées, pas supprimées** : le test qui vidait le champ jour
  pour vérifier qu'un refus ne désigne pas un champ replié vérifie désormais
  qu'aucune des deux feuilles ne réclame de date ; celui qui exigeait « le jour
  exact » d'une échéance future exige la fin de mois pour une récurrence, et
  **le jour exact pour une facture**.
- **Contrôles négatifs exécutés** : réafficher le jour dans la liste → échec
  nommé ; accepter un montant illisible → échec nommé ; retirer « Passer » →
  échec.
- Écrans **rendus et regardés** à 390 et 320 px : charges, abonnements,
  accueil, Abonnements, Factures mensuelles, écran verrouillé.

## Les vrais logos du propriétaire (06.08.2026) — VERIFYING

Le propriétaire a fourni les **deux dessins officiels** de la marque, avec
leur usage : « celle à la typo, c'est pour voir partout » ; « l'autre, c'est
celle pour utiliser sur l'app qu'on voit sur l'iPhone » ; « fais les trucs
transparents pour que ça soit bien carré sur un fond noir ».

Les sources sont archivées dans
`.claude/skills/budget-neon-ultra/assets/marque/` et **tous** les fichiers de
l'app en dérivent par un seul script,
`assets/tools/generer-marque.py`. Aucun PNG n'est retouché à la main : une
correction se fait dans le script, sinon PWA et iOS divergent dès la
première retouche. L'anneau que j'avais tracé pendant l'audit est remplacé,
et son générateur (`generer-icones.mjs`) supprimé — le laisser en place
aurait permis d'écraser silencieusement l'artwork du propriétaire.

### Une réserve, et elle est de plateforme

**Les icônes d'application restent OPAQUES.** iOS ne respecte pas la
transparence d'une icône : il la composite sur du **BLANC**. Une icône
trouée reviendrait cernée de blanc sur l'écran d'accueil — l'inverse exact
de ce qui est demandé. La demande est donc honorée là où elle a un sens :

| Fichier | Régime |
|---|---|
| `icon-192`, `icon-512`, `apple-touch-icon`, `AppIcon1024` | **opaques**, posées sur `#05060A` |
| `webapp/logo-budget.png` (verrou anneau + mot) | **transparent** |
| `webapp/logo-anneau.png` (anneau seul) | **transparent** |
| `LogoBudget.imageset`, `LogoAnneau.imageset` (natif, ×1 ×2 ×3) | **transparents** |

### Où ils apparaissent — les mêmes écrans des deux côtés

- **Premier écran de l'onboarding** (PWA *et* natif) : le verrou remplace
  l'icône de 76 px et le titre écrit « Budget ». Côté web l'image EST le
  `h1`, avec `alt="Budget"` ; côté natif elle porte l'étiquette
  d'accessibilité « Budget » et le trait `.isHeader`. Le mot est dans le
  dessin : l'écrire une seconde fois en dessous le disait deux fois à l'œil
  et deux fois à VoiceOver.
- **Écran verrouillé** (PWA *et* natif) : l'anneau remplace le 🔒 de 44 px —
  emoji côté web, `lock.fill` côté natif. Le sens est porté par la phrase
  « Budget est verrouillé », pas par le pictogramme, et VoiceOver n'annonce
  plus « cadenas » sans qu'on le lui demande.

Les trois échelles natives sont générées par le même script. Un seul PNG
suffirait à Xcode, mais il serait rééchantillonné sur les écrans @2x et @3x —
sur un trait fin en dégradé, ça se voit.

### Comment la transparence est calculée

L'alpha vient de la luminosité (`max(r, v, b)`) au-dessus d'un **plancher
mesuré sur le bord**, et la couleur est dé-prémultipliée. Un néon sur fond
noir n'a pas de contour net : le halo FAIT partie du dessin, le découper sur
un seuil le hacherait. Les logos internes sont ensuite **recadrés sur leur
dessin** : l'artwork laisse ~30 % de vide, et posé tel quel dans une balise
de 150 px le dessin n'en aurait occupé que 105.

Conséquence assumée : ces deux logos sont faits pour des surfaces **sombres**
— c'est le cas des cinq surfaces de l'app. Sur un fond clair ils paraîtraient
délavés.

### Preuves

- **103 parcours e2e** · 5 fixtures de parité · design system vert.
- Le n° 98 **décode réellement les pixels** des deux logos internes et exige
  des coins à 0 et un dessin à 255. Vérifier « a un canal alpha » ne suffisait
  pas : le premier essai en avait un et gardait quand même un voile à 17/255
  dans les coins, parce que le fond de l'artwork n'est pas noir PUR mais
  ≈ `#060612`. Le même test continue d'exiger l'**absence** d'alpha sur les
  quatre icônes d'application.
- Le n° 103 exige désormais le logo officiel, son `alt`, et l'absence de
  « Budget » écrit deux fois. L'assertion `icon-192.png` a été **remplacée,
  pas supprimée** : elle garde son rôle, empêcher le retour à un emoji.
- **Contrôles négatifs exécutés** (voir plus bas).
- Les fichiers produits ont été **ouverts et regardés** sur `#05060A` et sur
  `#11141C`, l'icône aux tailles réelles 110 / 60 / 40 px, et les écrans
  d'accueil et de verrouillage rendus à 390 et 320 px.
- **Côté natif, rien n'est prouvé localement** : il n'y a pas de chaîne Swift
  dans cet environnement. Le build, les 296 tests et le tour d'interface
  dépendent de la CI macOS. `DemoTourUITests` cherchait
  `staticTexts["Budget"]` ; l'assertion est **déplacée** sur
  `images["Budget"]`, pas retirée.

### Le rectangle que je n'avais pas vu

Première version livrable, tests verts, coins à 0 — et un **rectangle plus
clair visible autour du logo** sur la capture 390 px. Deux causes, toutes
deux invisibles aux quatre coins :

1. L'artwork porte une **nappe lumineuse très large** autour de l'anneau (18
   au bord, ~46 près du trait). Invisible sur son fond d'origine, elle
   devient une tache claire sur `#05060A`. Corrigé en mesurant le plancher
   sur le 85ᵉ centile de toute l'image, pas seulement sur le bord.
2. Le recadrage **tranchait le halo** là où il valait encore 14/255. Corrigé
   par un fondu sur la largeur exacte de la marge ajoutée — le dessin est
   intouché par construction, pas par chance.

Le test regarde désormais **tout le pourtour**, pas quatre pixels : quatre
coins propres ne prouvent rien sur les 1 864 autres pixels du bord.

## Le premier écran donne envie (06.08.2026) — VERIFYING

Premier retour du test en conditions réelles, sur la toute première
capture : « je les trouve un peu simples ». Trois défauts, pas un goût.

1. **Un 💰 en guise de logo** — alors qu'on venait de dessiner l'anneau. Le
   tout premier écran de l'app ne montrait pas l'app.
2. **Environ 600 px de noir vide** au-dessus du contenu, qui flottait au
   milieu de rien.
3. **Trois dalles identiques**, rien qui bouge, rien sous le doigt.

### Ce qui change

- L'**icône de l'app** remplace l'emoji, à 76 px, avec une ombre portée
  discrète. *(Remplacée le jour même par le logo officiel du propriétaire —
  voir le lot ci-dessus.)*
- Un **halo** derrière elle : c'est l'unique point lumineux que la
  constitution autorise, et il remplit le vide au lieu de le laisser noir.
- **Entrée en cascade** : logo, titre, puis les choix un par un, 60 ms
  d'écart. L'œil suit le chemin au lieu de découvrir trois blocs d'un coup.
- **Retour au toucher** : le bouton s'enfonce légèrement, puis se colore
  140 ms avant que l'écran change. Sans ce battement, on ne sait pas si on a
  appuyé au bon endroit.
- Contenu remonté de 14 % de la hauteur : il ne flotte plus au centre.

### Ce qui n'est pas négociable

**Tout s'arrête en mouvement réduit** — animation, transition, et même le
battement de 140 ms, qui est sauté et jamais bloquant. Une animation qui
ignore ce réglage est un défaut d'accessibilité, pas un détail de style.

### Preuves

- **103 parcours e2e** (102 conservés + le n° 103) · 5 fixtures de parité ·
  design system vert.
- Le n° 103 vérifie le logo (la vraie icône, pas un emoji), sa taille
  réelle, le halo, l'animation d'entrée, la réaction au toucher — puis
  rejoue tout en **mouvement réduit** et exige que plus rien ne bouge ET
  que le parcours reste franchissable.
- **Contrôles négatifs exécutés** : remettre le 💰 produit trois échecs
  nommés ; retirer la règle de mouvement réduit en produit un.

## Déploiement Pages bloqué côté GitHub (06.08.2026) — À RELANCER

Le site publié sert encore **`6bc7960`**, pas `77d8128`. Il lui manque donc
uniquement le lot « feuilles de saisie ».

Ce n'est pas le code : quatre tentatives sur ce SHA, toutes bloquées à la
même étape.

| Run | Résultat |
|---|---|
| Pages #62 | déploiement annulé |
| relance du #62 | `Multiple artifacts named "github-pages" — count is 2` |
| Pages #63 | SHA court refusé (ma faute : le workflow exige le SHA complet) |
| Pages #64 et #65 | `in_progress` pendant ~10 min puis `error` |

À chaque fois le job « Vérifier la CI du SHA » passe, le site s'assemble et
s'empaquette : c'est l'action `deploy-pages` qui échoue. Un des messages
d'erreur le dit lui-même — « Is githubstatus.com reporting issues with API
requests, Pages, or Actions? Please re-run the deployment at a later time. »

**Deux choses que j'ai apprises à mes dépens et qui sont notées ici pour la
prochaine fois :**

1. Ne jamais **relancer** un run Pages échoué — l'artefact de la tentative
   précédente reste, `deploy-pages` en trouve deux et refuse. Il faut une
   exécution NEUVE.
2. L'entrée `sha` du `workflow_dispatch` exige le SHA **complet**.

**Action** : relancer `Actions → Pages → Run workflow` avec le SHA complet
quand le service est rétabli. Rien à corriger dans le dépôt.

## Les feuilles de saisie parlent enfin comme le reste (06.08.2026) — VERIFYING

Trouvé en regardant une capture réelle du simulateur : la feuille
« Nouveau mouvement » affichait **« Statut : Comptabilisé »**. Le mot que
trois passes de langage avaient chassé de partout ailleurs.

### Pourquoi il avait survécu

Le garde-fou anti-jargon (test n° 101) balaie les **seize écrans**. Les
**feuilles**, elles, n'étaient pas balayées — et c'est précisément là que
s'étaient réfugiés « Comptabilisé », « Nature », « Périodicité »,
« Solde d'ouverture », « ligne budgétaire », « Contribution prévue »,
« cash disponible », « fortune nette », « récurrence », « Projection à la
retraite ». Vingt-six textes dans treize feuilles.

Le test balaie désormais aussi les feuilles, avec dix mots de plus.

### Quelques exemples

| Avant | Maintenant |
|---|---|
| Sera compté comme : Comptabilisé. | C'est déjà fait : ça compte dans vos soldes. |
| Nature · Devise · Solde d'ouverture | Type de compte · Monnaie · Solde de départ |
| Compter dans le cash disponible | Compter dans l'argent disponible |
| Nouvelle ligne budgétaire · Montant planifié | Nouveau budget par catégorie · Montant prévu |
| Déjà atteint (si non lié) · Contribution prévue | Déjà là (si pas relié à un compte) · Ce que vous mettez chaque mois |
| Périodicité | Vous payez |
| Institution / position | Nom (caisse, banque…) |
| Marquer payée (crée le mouvement) | Marquer payée (crée la dépense) |

Côté natif, `TransactionStatus.posted` disait aussi « Comptabilisé » : il
dit « Déjà fait ».

### Preuves

- 102 parcours e2e · 5 fixtures de parité · design system vert · audit
  total propre.
- **Contrôle négatif exécuté** : remettre « Nature » dans la feuille Compte
  produit un échec nommé, avec le nom de la feuille.
- Trois assertions existantes suivent le nouveau vocabulaire sans être
  affaiblies : la note de statut doit toujours DIRE que le mouvement compte
  déjà, la mise à jour de solde doit toujours promettre que l'historique
  n'est jamais réécrit.

## Le natif rejoint le web : une seule identité, deux plateformes (06.08.2026) — VERIFYING

Le lot précédent avait unifié les surfaces du **web** — et créé du même
coup un écart avec l'**iPhone**, qui portait exactement la même divergence
en interne. Deux plateformes, quatre couleurs de fond. Ce lot le referme.

- `BudgetColor.canvas / canvasRaised / glass / glassStrong / glassFallback`
  prennent les valeurs de `NeonUltraColor`.
- Les cartes deviennent **mates** : `.ultraThinMaterial` disparaît de
  `GlassCard` et d'`ObsidianComponents`. Un matériau système laisse
  transparaître ce qui défile dessous — sur un noir aussi sombre, la carte
  changeait d'aspect selon le contenu.
- Les deux voiles `glassStrong.opacity(0.55)` qui recouvraient ce matériau
  n'ont plus d'objet : la carte porte directement sa couleur. Les garder
  n'aurait fait qu'assombrir une surface au hasard.

### La couleur de lancement mentait à nouveau

Le manifeste et la balise `theme-color` annonçaient toujours `#090C12` :
c'est la couleur de l'écran qui s'affiche pendant que l'app installée
démarre. Elles étaient **d'accord entre elles et fausses toutes les deux**
— précisément ce que le test n° 98 ne pouvait pas voir, puisqu'il ne
comparait que les deux déclarations l'une à l'autre.

Le test compare désormais les déclarations à la couleur **réellement
peinte** par l'app. C'est un contrôle strictement plus fort, et il aurait
attrapé cette régression tout seul.

### Preuves

- 102 parcours e2e · 5 fixtures de parité · design system vert · zéro
  erreur console.
- **Contrôle négatif exécuté** : laisser le manifeste sur `#090C12` produit
  deux échecs nommés.
- Côté Swift, les assertions de `DesignSystemTests` suivent les nouvelles
  valeurs, et l'assistant de composition du verre est remplacé par la
  couleur elle-même — composer une transparence qui n'existe plus
  mesurerait une surface fantôme.

## Une seule identité de surface sur toute la PWA (06.08.2026) — VERIFYING

Suite directe de l'audit total. Après avoir unifié la géométrie, la même
question se posait sur les couleurs de fond — et la mesure a confirmé le
pire cas.

### Ce qui était mesuré avant

| Écran | fond | carte |
|---|---|---|
| Mois, Budget, Année, Abonnements | `#05060A` | `#181C26` mate |
| Historique, Comptes, Gérer, Objectifs, Patrimoine… | `#090C12` | `rgba(20,25,37,0.72)` **translucide** |

**Le noir du fond changeait en changeant d'onglet**, et les cartes n'étaient
pas de la même matière — verre flouté d'un côté, surface mate de l'autre.
Personne ne l'avait vu parce que les deux noirs sont proches ; la sonde,
elle, ne se fatigue pas.

Les cinq surfaces d'Obsidian prennent les valeurs de Neon Ultra. Le flou
disparaît : la constitution cible impose des cartes **mates**.

### Onze garde-fous retournés, aucun relâché

Onze assertions exigeaient précisément la séparation qu'on vient de
supprimer. Aucune n'a été effacée — chacune a été **retournée** :

- « index.html ne doit contenir AUCUNE valeur Neon Ultra » devient « les
  deux feuilles doivent DÉCLARER LA MÊME valeur pour les cinq surfaces
  partagées ». Les accents, eux, restent interdits en dur dans l'app.
- « le verre doit être translucide par défaut puis devenir opaque en
  transparence réduite » devient « les cartes sont opaques et sans flou
  **dans les deux modes** » — la garantie utilisateur est désormais vraie en
  permanence, plus seulement quand on l'a demandée. C'est plus strict.
- « Comptes et Gérer gardent leurs cartes translucides » devient « Comptes
  et Gérer peignent la MÊME matière que les écrans pilotes, sans porter
  leur classe ni leurs accents ».
- Le contrat de contraste était calculé sur `#090C12` et sur un verre
  composité. Recalculé sur le noir réel et sur la carte opaque réelle —
  sinon il mesurerait une surface qui n'existe plus.

### Preuves

- 102 parcours e2e · 5 fixtures de parité · design system vert · zéro
  erreur console.
- Sonde de fond re-mesurée après correction : deux matières de carte sur
  les seize écrans (`#11141C` standard, `#181C26` élevée), un seul noir.
- Audit total propre à 320, 390 et 430 px.

## Audit total + nouveau logo (06.08.2026) — VERIFYING

Demande du propriétaire : « un audit total complet de A à Z, tous les petits
détails, que tout soit aligné, cohérent, en ordre » — et « regarde aussi
pour le logo ».

Nouvel outil : `audit-total.mjs`. Il mesure les seize écrans à **320, 390 et
430 px** sur des axes que l'œil rate après trois heures — alignement, rayons,
paddings, tailles, contraste RÉEL de chaque texte sur son fond effectif,
cibles tactiles, boutons sans destination, débordement, nombre de titres.

### Ce qui était déjà bon

Aux trois largeurs : zéro débordement, zéro contraste sous AA, zéro bouton
mort, **un seul bord gauche à 18 px sur les seize écrans**, un titre par
écran. La discipline des lots précédents tient.

### Les trois défauts trouvés

1. **Deux systèmes géométriques.** Obsidian arrondissait les cartes à
   22 px, Neon Ultra à 18 px — cinq rayons distincts dans l'app. Visible
   dès qu'on passait de Comptes à Mois. Unifié sur la géométrie Neon Ultra.
2. **Deux textes sous le seuil.** Le « utilisé » de l'anneau à **8 px**, les
   mois de la page Année à 9 px. Passés à 10 px.
3. **Une cible à 43,5 px** — « Suppr. » d'un document, visible seulement à
   430 px.

### Une correction de l'outil lui-même

Sa première version signalait « plus de deux rayons » et criait au loup sur
quatre écrans qui contenaient simplement le système au complet (un héros,
des cartes, des lignes). Un audit qui crie au loup est pire qu'aucun audit.
Il compare désormais aux valeurs autorisées, pas à leur nombre.

### Le logo

L'ancien était une **courbe boursière** — l'héritage direct de
« Mendestrading ». Sur une fiche App Store, c'est la première chose qu'un
acheteur voit, et elle promettait la Bourse alors que le produit promet de
savoir où passe son argent. Elle était en plus presque noire sur noir, et
son trait fin disparaissait à 40 px.

Le nouveau est l'**anneau du budget** — l'élément signature de l'app, celui
de l'écran Budget. Vérifié à 120, 60, 40 et 29 px : il tient partout.

Première tentative rejetée : le dégradé par défaut plaçait le cyan dans le
coin du cadre, exactement là où l'anneau est ouvert — la couleur
n'apparaissait nulle part. Corrigé en `userSpaceOnUse`.

### Preuves

- **102 parcours e2e** (101 conservés + le n° 102) · 5 fixtures de parité ·
  design system vert · zéro erreur console.
- Le n° 102 verrouille les trois rayons autorisés, l'absence de texte sous
  10 px, l'unicité du bord gauche, et **l'accord des deux feuilles de style**
  sur la géométrie — sans quoi la divergence reviendrait au premier écran
  rebranché.
- **Contrôle négatif exécuté** : rendre 22 px à Obsidian produit sept échecs
  nommés plus le désaccord des feuilles ; redescendre le « utilisé » à 8 px
  en produit un.
- Audit total propre aux trois largeurs après correction.

## NU4 (première tranche) — la coquille natives passe en Neon Ultra (05.08.2026) — VERIFYING

Rendu possible par le lot précédent : le workflow Demo remarche, donc on
peut enfin **regarder** l'app iPhone au lieu de l'écrire en aveugle.

La capture `nu3-mois` du run Demo #42 montre trois choses :

1. Une **bande indigo saturée** occupe tout le haut de l'écran — la
   bannière de démonstration. C'est le premier point lumineux de CHAQUE
   écran, alors que la constitution réserve le point focal unique au
   contenu.
2. La **barre d'onglets et le ＋ sont indigo Obsidian**, pendant que les
   flèches de mois, elles, sont déjà **cyan Neon Ultra**. Deux accents se
   battent sur la même capture.
3. Le fond, lui, est bien le noir Neon Ultra : NU3 avait fait son travail,
   c'est bien la coquille qui était restée en arrière.

### Ce qui change

- `.tint(BudgetColor.indigo)` → `.tint(NeonUltraColor.cyan)` sur la
  `TabView`. Le cyan mesure ≈ 9,3:1 sur la navigation `#0B0D13` : il peut
  porter seul un petit libellé actif. Le violet, à 3,41:1, ne le pourrait
  pas — c'est écrit dans le token lui-même, et c'est pour ça que ce n'est
  pas lui qui est choisi.
- Fond de la barre d'onglets forcé sur `NeonUltraColor.navigation`.
- La bannière de démonstration devient une surface mate avec un liseré :
  un rappel, plus une enseigne. Le ✦ passe magenta, « Quitter » cyan.

### Ce que ça ne fait pas

Les vingt-six écrans non pilotes gardent leurs propres cartes Obsidian :
seule la **coquille** change ici. C'est voulu — changer la coquille et les
écrans dans le même lot rendrait impossible de dire lequel a cassé quoi si
une capture cloche.

### Preuve regardée, pas supposée

**Demo #43 verte sur `da1358e`**, CI #290 verte (Web + 296 tests iOS).
Captures avant/après dans `docs/neon-ultra/nu4/` — extraites des journaux
en base64 et **ouvertes**. La bande indigo a disparu ; le ＋, les flèches
de mois, « Quitter », « Gérer » et l'onglet actif partagent le même cyan ;
le ✦ magenta reste la seule autre touche.

| Lot | État |
|---|---|
| NU4 (coquille) | VERIFYING |

## Lot « le tour natif remarche » (05.08.2026) — VERIFYING

Le workflow **Demo** — la seule façon d'obtenir des captures réelles du
simulateur — était rouge depuis le 25.07. Sans lui, aucun travail visuel
natif n'est vérifiable à l'œil : on écrit du SwiftUI en aveugle.

### Neuf choses périmées, pas deux

Les deux échecs affichés (« ＋ flottant absent », « Documents introuvable »)
n'étaient que les deux PREMIERS. En comparant les étiquettes tapées par le
tour aux étiquettes réellement produites par `MoreTab`, il en restait sept :

| Le tour tapait | L'app affiche |
|---|---|
| Année en revue | Bilan de l'année |
| Récurrents et abonnements | Factures mensuelles |
| Assurances | Assurances et prévoyance → Assurances |
| Prévoyance | Assurances et prévoyance → Prévoyance |
| Documents | Documents et import → Mes documents |
| Import CSV | Documents et import → Importer un relevé CSV |
| À organiser (repère de sommet) | Mon mois |

Corriger les deux échecs visibles aurait produit un troisième run rouge.
La comparaison mécanique des deux listes a évité trois tours de CI.

**Deux entrées sont devenues des sommaires.** `visitMoreEntry` et
`visitFinancialModule` acceptent maintenant un second niveau : sans ça, la
capture montrerait le sommaire au lieu de l'écran promis — une preuve verte
qui ne prouve rien.

### L'invariant du ＋ n'a plus d'objet — il n'est pas supprimé, il est déplacé

Le tour vérifiait qu'aucun contenu ne passait sous le ＋ flottant, grâce à
une zone d'exclusion. ADR-026 a supprimé ce bouton : l'assertion ne pouvait
plus que échouer.

Ce qui la remplace n'est pas rien : c'est **la barre d'onglets**. Le défaut
existe pour de vrai — NU3 l'a trouvé sur Mois et Budget, ~80 pt de contenu
coincés dessous, invisibles en lecture de code parce que noir sur noir.
`assertLastIdentifiedElementClearsTabBar` exige donc qu'après défilement
complet, la dernière ligne financière soit ENTIÈREMENT au-dessus de la
barre.

Ce qui est assumé comme perdu : le contrôle à CHAQUE position intermédiaire.
Il n'avait de sens que parce qu'une zone d'exclusion garantissait qu'aucun
pixel ne pouvait passer sous le ＋. Sous une barre d'onglets translucide, du
contenu passe dessous **légitimement** pendant le défilement ; seul l'état
final est jugeable. Consigné plutôt que maquillé.

`Self.hubTopSection` remplace quatre littéraux « À organiser » : le tour est
resté périmé trois mois parce que le repère était recopié à quatre endroits.

## Lot « iPhone dit la même chose que le web » (05.08.2026) — VERIFYING

Les trois lots de langage précédents n'avaient touché que la PWA. L'app
iPhone continuait d'afficher « Fortune nette », « réel / planifié » et
« Réserve constituée » : **les deux applications ne parlaient plus la même
langue**. C'est un vrai défaut, pas un détail — le même utilisateur passe de
l'une à l'autre.

Cinquante-six lignes alignées sur le vocabulaire du web, dans douze
fichiers : `NetWorthView`, `TaxesView`, `BudgetTab`, `BudgetLineFormView`,
`AnnualBudgetView`, `GoalsTab`, `AccountDetailView`, `ReconcileSheet`,
`SettingsView`, `AppContainer`, `TransactionValidationService`,
`GoalProjectionService`.

Les libellés d'accessibilité suivent les libellés visibles — sinon VoiceOver
lirait l'ancien vocabulaire par-dessus le nouveau.

### Ce qui a été vérifié AVANT d'écrire

- Aucune des vingt-quatre étiquettes assertées par `BudgetUITests` ne fait
  partie des textes modifiés (vérifié par extraction des sélecteurs).
- Les occurrences de « comptabilisé » et « planifié » dans `BudgetTests`
  sont toutes dans des **commentaires** et des **messages d'assertion**,
  jamais dans une comparaison de chaîne d'interface.

Sans ces deux contrôles, ce lot serait parti à l'aveugle : il n'y a pas de
chaîne Swift ici, chaque essai coûte un tour complet de CI macOS.

### Preuve

La compilation et les 296 tests iOS ne peuvent être exécutés que par la CI
macOS — aucune chaîne Swift dans cet environnement. Le diff a donc été relu
ligne par ligne (interpolations, guillemets, apostrophes) avant d'être
poussé, et c'est la CI qui fait foi.

## Lot « messages et retours » (05.08.2026) — VERIFYING

Suite directe du précédent, sur les textes qu'on ne voit qu'au moment où
quelque chose se passe : les refus de formulaire, l'accueil du premier
lancement, et les dix-neuf messages de confirmation.

| Avant | Maintenant |
|---|---|
| Solde d'ouverture invalide. | Ce solde n'est pas un montant valable. |
| Jour entre 1 et 28 (les mois courts sont ainsi toujours couverts). | Choisissez un jour entre 1 et 28, comme ça février est couvert aussi. |
| Les deux saisies ne correspondent pas. | Les deux codes ne sont pas les mêmes. |
| Code incorrect — le verrouillage reste actif. | Ce code n'est pas le bon. L'app reste verrouillée. |
| Salaire mensuel net | Ce que vous recevez chaque mois |
| Stockage indisponible — ce changement ne survivra pas au rechargement | Votre navigateur refuse d'enregistrer. Ce changement disparaîtra si vous rechargez la page. |
| Sauvegarde illisible — rien n'a été modifié | Ce fichier ne se lit pas. Rien n'a changé. |
| Opérations effacées — comptes, budgets et réglages conservés | Mouvements effacés. Vos comptes, budgets et réglages sont gardés. |

Les quatre refus de restauration restent **quatre messages distincts** —
trop gros, illisible, autre version, pas une sauvegarde Budget. Les
confondre aurait rendu le texte plus simple et l'app moins utile.

### Preuves

- 101 parcours e2e · 5 fixtures de parité · design system vert · zéro
  erreur console.
- Le test de restauration exige désormais **deux** choses du message : ce
  qui cloche avec le fichier **et** que rien n'a bougé. C'est plus strict
  qu'avant, qui cherchait seulement le mot « invalide ».
- Chaque refus continue de DÉSIGNER son champ, y compris replié.

## Note de méthode — une CI rouge que j'ai poussée (05.08.2026)

`441f91c` est parti avec une CI rouge : la suite design échouait sur
« les valeurs réel / planifié sont écrites en toutes lettres ».

La cause n'est pas le code, c'est ma boucle. J'avais lancé les trois suites,
**puis** modifié la ligne d'enveloppe du Budget après avoir regardé une
capture, **puis** relancé l'e2e seul — celui que je pensais concerné — avant
de committer. La suite design n'a jamais revu ce changement.

Corrigé au commit suivant (`7e034b3`, CI #286 et Pages #57 vertes), et
l'assertion est maintenant portée par le héros du Budget plutôt que par les
lignes d'enveloppe : elle ne dépend plus de l'état des données. La règle
tient toujours : **les trois suites, après la dernière modification, avant
chaque commit** — sans exception, même quand la modification paraît
cosmétique.

## Lot « l'app parle comme une personne » (05.08.2026) — VERIFYING

Retour du propriétaire sur cinq captures : « j'aime beaucoup, mais ça fait
trop technique — c'est accessible à tout le monde, un peu comme Duolingo ».
Il a raison, et `CLAUDE.md` l'exigeait déjà depuis le début : « français
simple, compréhensible par un enfant de dix ans ». Rien ne le VÉRIFIAIT,
alors la règle s'est érodée écran par écran.

### Ce qui était écrit, et ce qui est écrit maintenant

| Avant | Maintenant |
|---|---|
| Encore dû (arriérés compris) — estimation | Il vous reste à payer, à peu près |
| Revenus comptabilisés depuis le 1er janvier × 30 % | Vos revenus depuis le 1er janvier, à 30 % |
| Réserve constituée · Saisie par vous — bouton Ajuster | Déjà mis de côté · Le montant que vous avez indiqué |
| Estimé = payé + encore dû, toujours | On compte seulement ce que vous avez noté en 2026 |
| Fortune nette · soldes du jour, dérivés de vos comptes | Tout ce qui est à vous · vos comptes, vos biens et votre prévoyance, moins ce que vous devez |
| Le chemin — votre patrimoine projeté | Si vous continuez comme ça |
| avec des hypothèses de rendement annualisées par classe | et d'un rendement moyen |
| Progression globale (objectifs actifs) | Déjà mis de côté |
| Atteint (solde du compte lié) · Échéance · Rythme réel | Déjà là (sur le compte) · Pour quand · Vous mettez |
| Calcul : montant restant ÷ rythme mensuel | On divise ce qu'il reste par ce que vous mettez chaque mois |
| réel CHF 2'150.00 / planifié CHF 2'150.00 | CHF 2'150.00 dépensé sur CHF 2'150.00 prévu |
| Protège l'affichage (pas un chiffrement) | Cache vos montants. Ce n'est pas un coffre-fort |
| Devise de référence | Votre monnaie |
| chaque ligne porte une empreinte (date + compte + type + signe…) | chaque ligne est reconnue à sa date, son compte, son intitulé et son montant |

Cinquante-neuf textes réécrits, sur les seize écrans — pas seulement les
cinq des captures. Aucun chiffre, aucune formule, aucune règle métier n'a
bougé : seuls les mots changent.

### Ce qui n'a PAS été assoupli

Dire simplement n'est pas promettre. Sont conservés mot pour mot :
« estimation, pas une promesse », « pas un conseil fiscal », « l'app ne
calcule rien ici », « rien n'est enregistré avant que vous confirmiez ».

Le héros Impôts avait perdu sa réserve dans ma première passe — le chiffre
se lisait comme un fait. Rendu explicite : « Il vous reste à payer, **à peu
près** », et le test l'exige désormais **sur le héros lui-même**, plus
seulement quelque part dans la page.

L'invariant produit « planifié et réel jamais mélangés » est intact : les
deux montants restent NOMMÉS séparément, en « prévu » et « dépensé ».

### Preuves

- **101 parcours e2e** (100 conservés + le n° 101) · 5 fixtures de parité ·
  design Obsidian, NU1 et NU2 verts · zéro erreur console.
- Le n° 101 lit le texte **réellement rendu** (`innerText`, jamais le HTML)
  sur les seize écrans et refuse trente-cinq mots de comptable. Il mesure
  aussi la plus longue phrase — mais **uniquement dans la prose** : mesurer
  l'écran entier recollait les tableaux libellé/montant en un bloc de
  83 « mots » qui n'est une phrase pour personne. Première version de ma
  sonde : fausse, corrigée après vérification.
- **Contrôle négatif exécuté** : réintroduire « Réserve constituée » ou une
  phrase de 43 mots produit bien deux échecs nommés.
- Vingt-deux assertions existantes réécrites pour suivre le nouveau
  vocabulaire — **aucune supprimée, aucune affaiblie** : chacune vérifie la
  même chose qu'avant.
- Audit des 16 écrans propre à 320 **et** 390 px : les phrases sont plus
  longues, rien ne déborde.

### Reste ouvert

Le natif garde l'ancien vocabulaire : ces textes vivent dans les écrans
SwiftUI, hors périmètre pilote. À traiter en NU4–NU6, sans quoi PWA et iOS
ne diront plus la même chose.

## Lot « couleurs et lignes honnêtes » (05.08.2026) — VERIFYING

Demande du propriétaire : « continue de le peaufiner ». Quatre défauts
trouvés en **mesurant l'app rendue**, pas en relisant du code. Preuves
avant/après dans `docs/neon-ultra/couleurs/`.

### 1. Des couleurs qui mentaient sur deux graphiques

Les quatre courbes du Patrimoine empruntaient le vert, le corail et l'ambre.
Une courbe « Prévoyance » tracée en corail se lit comme une perte, alors que
la constitution réserve ces trois couleurs à leur sens financier.

Plus grave : `--electric` et `--violet` pointent **tous deux** vers
`--brand-bright` depuis la remise à plat L2. La barre de composition
dessinait « Comptes » et « Prévoyance » dans la même couleur, avec deux
pastilles identiques en légende — elle ne se lisait pas. La répartition des
Comptes avait le même mal autrement : sa troisième classe tirait sur
`--line-strong`, une couleur de **bordure**, si bien que la plus grosse part
(48 %) se lisait comme du vide.

Rampe `--series-1..5`, non sémantique, plus **un trait différent par
courbe** : deux indigos voisins ne se distinguent pas à 1,5 px, et la
couleur seule ne doit jamais porter le sens.

### 2. Deux pastilles sur huit ignoraient la teinte

📈 et 🧾 n'ont aucune présentation texte : U+FE0E ne les change pas. Mesuré
glyphe par glyphe — rendu sous deux couleurs CSS, comparé au pixel — le
trait de 📈 reste rouge : une pastille « Investir » violette portait un
symbole de perte. Remplacés par ↗ et ✉, qui suivent `currentColor`.

### 3. À 320 px, le texte n'avait plus la place d'exister

Mesuré : ligne de 284 px, montant `flex: none` à 108 px, titre réduit à
**78 px**. « Caisse maladie (LAMal) » tenait sur trois lignes hachées. Sous
381 px le montant descend sous le texte. Les listes de mouvements, denses,
gardent leur mise en page.

### 4. Deux libellés coupés en deux

« ‹ Gérer » se scindait en deux lignes, « 68,5 % » aussi.

### Preuves

- **100 parcours e2e** (99 conservés + le n° 100) · 5 fixtures de parité ·
  design Obsidian, NU1 et NU2 verts · zéro erreur console.
- **Contrôle négatif exécuté** : les quatre correctifs annulés un par un
  produisent quatre échecs nommés.
- Audit des 16 écrans propre à 320 **et** 390 px après correction — une
  première version de mon correctif 320 débordait de 23 px sur six écrans
  (`flex-basis: 100 %` plus une marge extérieure), rattrapée en marge
  intérieure.
- Captures régénérées et **regardées**, pas seulement produites.

### Ce que ce lot ne fait pas

Le natif ne reçoit rien : `AccountsTab` et le Patrimoine sont des écrans
non pilotes (NU4/NU6). Et le **fond des textes reste trop technique** —
retour du propriétaire le 05.08 sur ces mêmes écrans : « ça fait trop
technique, c'est accessible à tout le monde, un peu comme Duolingo ».
C'est le lot suivant, pas celui-ci.

## Lot « graphiques honnêtes » (05.08.2026) — VERIFYING

Demande du propriétaire sur quatre captures iPhone (Abonnements, Comptes,
Budget, Mouvements) : « j'aimerais que tu m'améliore ces pages », puis
« le visuel, les graphes plus jolis ».

### 1. Les pastilles de type étaient hors palette

`TYPE_ICON` utilisait des flèches et symboles nus. iOS les rend en **emoji
bleus** : une dépense affichait une flèche bleue sur une pastille corail,
deux couleurs qui se contredisent dans un carré de 34 px. Chaque symbole
porte désormais le VARIATION SELECTOR-15 (`U+FE0E`), qui force le rendu
texte, et `.ico.t-*` pose la `color` sémantique. Le symbole prend donc la
teinte de sa pastille : vert pour une entrée, corail pour une sortie,
violet pour l'épargne, gris pour le neutre.

### 2. Trois graphiques remplacent trois listes de chiffres

Aucun n'invente de donnée : chacun dessine une série qui existait déjà en
texte, et rien d'autre.

- **Budget → Année** : la grille « mois / dépensé / budget » devient douze
  colonnes. La hauteur est le taux d'utilisation, plafonné à 100 % ; un
  dépassement ajoute un chapeau corail au-dessus du plafond plutôt que de
  faire mentir l'échelle. Un mois **sans mouvement** a une piste
  transparente — sans quoi un mois vide se lisait comme un mois à 100 %.
- **Abonnements** : une barre de part par ligne (73 / 18 / 9 %). Le total
  perd sa couleur négative : un abonnement assumé n'est pas une alerte.
- **Comptes** : « Où est votre argent » — une barre de répartition segmentée
  avec sa légende, calculée sur les soldes réels.

### 3. Les libellés ne débordent plus

Le badge « Prévu » collé au titre rognait le libellé à 95 px sur 320. La
ligne de métadonnée passe en flex **dans la liste dense uniquement** : le
titre s'ellipse, le badge garde sa place. Partout où le texte doit revenir
à la ligne (page Année, abonnements, cartes prioritaires, lignes de
gestion), `display: block` est restauré — la première version de ce
correctif faisait chevaucher « Stockage en ligne (annuel) » de 54 px avec
son montant.

### Preuves

- **99 parcours e2e** (98 conservés + le n° 99) · 5 fixtures de parité ·
  design Obsidian, NU1 et NU2 verts · zéro erreur console.
- Le n° 99 vérifie que chaque colonne de l'année reste dans son cadre, que
  les parts d'abonnement totalisent 100 %, et que la barre de répartition
  correspond aux soldes affichés.
- **Contrôle négatif effectué** : une colonne non plafonnée, une part
  fausse et une pastille sans `color` produisent trois échecs nommés.
- Sonde de chevauchement à 320 et 390 px : `[]` sur les 16 écrans. Captures
  d'audit régénérées et **regardées**, notamment `320-subs.png`,
  `320-year.png` et `390-comptes.png`.

### Ce que ce lot ne fait pas

Le natif n'a pas ces graphiques : `AccountsTab` et les abonnements sont des
écrans **non pilotes**, ils appartiennent à NU4/NU6. L'écart PWA/iOS est
donc temporairement plus grand sur ces trois pages — consigné, pas comblé
en douce.

## NU3 — Pilote SwiftUI : Mois, Budget, Nouveau mouvement (05.08.2026) — VERIFYING

Lot démarré sur accord explicite du propriétaire (« Fait développe »,
05.08.2026). Périmètre du plan de livraison, sans extension : `HomeTab`,
`BudgetTab` et `TransactionFormView` portent l'identité Neon Ultra ; parité
visuelle raisonnable avec NU2.

### Stratégie d'isolation (le cœur du lot, comme en NU2)

- Une primitive manquait : `NeonUltraScreenBackground` (canvas `#05060A`),
  **distincte** de `BudgetScreenBackground` (dégradé Obsidian). C'est ce qui
  garantit qu'un écran non piloté ne peut pas changer de fond par accident.
- **EXACTEMENT trois fichiers** de `Budget/Features/` référencent Neon Ultra,
  vérifié par recherche. Les vingt-six autres écrans restent Obsidian.
- Aucun token Obsidian n'est modifié ; aucune primitive Obsidian n'est
  retouchée. `StatusPill` et `PrimaryActionButtonStyle`, partagés avec des
  écrans non pilotes, sont laissés intacts : les surfaces pilotes utilisent
  les équivalents Neon Ultra.

### Deux décisions prises en connaissance de cause

1. **Le montant de la feuille reste `amount`, pas `heroAmount`.** Dans une
   ligne de `Form`, un `largeTitle` déborde dès que le texte est agrandi — et
   je ne peux pas vérifier le rendu sans simulateur. La domination du montant
   est donc moindre que dans la PWA : écart assumé, à revoir sur captures.
2. **`NeonUltraAmountText` gagne une option `signed`** (additive, calquée sur
   le composant Obsidian). Sans elle, le solde d'un mois PASSÉ perdait son
   `+`/`−` explicite et le sens serait retombé sur la seule couleur, ce que la
   constitution interdit.

### Ce que les captures simulateur ont réellement corrigé

Cinq exécutions du workflow Demo ont été nécessaires pour obtenir les trois
captures. Elles ont ensuite servi à quelque chose :

1. **Bande morte de ~80 pt** entre le dernier contenu et la barre d'onglets,
   sur Mois ET Budget — noir sur noir, invisible en lecture de code.
   `obsidianFABClearance()` réservait la place d'un ＋ flottant supprimé par
   ADR-026. Les écrans pilotes utilisent désormais
   `neonUltraScrollClearance()` ; « Factures du mois » est réapparu.
2. **Le montant de la feuille ne dominait pas du tout.** Mon premier choix
   (`amount`, par crainte d'un débordement) rendait le champ indistinguable
   des autres libellés. Nouveau token `formAmount` (`title2`) : visible sans
   déborder, et il suit Dynamic Type.
3. **La feuille héritait de l'indigo Obsidian** de `RootView` — « Annuler »,
   « Enregistrer » et tous les sélecteurs hors palette sur une surface
   pilote. Teinte cyan Neon Ultra appliquée à la feuille.

### Ce que les captures montrent et que NU3 ne corrige PAS

Le **shell reste Obsidian** : la bannière de démonstration forme un large
bloc indigo saturé, et le ＋, l'icône de vue annuelle et l'onglet sélectionné
tirent leur teinte de `RootView`. C'est visible et ça jure. Mais `RootView`
n'est pas un fichier pilote et le shell appartient à **NU4** : consigné, pas
élargi en douce.

Les quatorze écrans non pilotes gardent la bande de 80 pt.

### Le workflow Demo était cassé, et pas par NU3

- Il n'avait plus tourné depuis le **25.07** (branche Obsidian, avant NU0).
- Le runner `macos-15` ne livrait **aucun simulateur** : le nom `iPhone 16`
  était figé. Le workflow résout désormais un iPhone disponible, en crée un
  au besoin, et échoue bruyamment s'il n'y a aucun runtime iOS.
- Le tour UI pilotait l'app avec les **anciens noms** (« Accueil »,
  « Mouvements », « Plus », un ＋ universel à menu, un groupe « À organiser »)
  — tous périmés depuis ADR-026. La CI saute `BudgetUITests` : personne ne
  pouvait le voir.
- Structurellement, la preuve de NU3 dépendait d'un tour de cinquante étapes
  sur des écrans étrangers au lot. `NeonUltraPilotTourUITests` capture
  désormais les trois surfaces et rien d'autre, indépendamment.

### Preuves et limites — honnêtement

- `NeonUltraPilotTests` ajouté : les trois surfaces se construisent à 320 et
  390 pt, en `accessibility3`, et sous transparence réduite **Neon Ultra** ;
  le fond piloté est prouvé opaque, égal au canvas et **différent** du fond
  Obsidian ; les rôles Obsidian sont vérifiés intacts ; deux écrans non
  pilotes continuent de se construire.
- **CI macOS VERTE** sur `4cf5888` puis sur chaque correctif jusqu'à
  `9c3fb86` : builds Debug et Release, `** TEST SUCCEEDED **`,
  **296 tests iOS, 0 échec** (289 avant + les 7 de `NeonUltraPilotTests`),
  PrivacyInfo présent et valide, `UIDeviceFamily == [1]`.
- **Captures simulateur RÉELLES inspectées une par une** :
  `docs/neon-ultra/nu3/` (README + 4 images, dont l'état AVANT correction).
- Aucun compilateur Swift dans cet environnement : le code n'a jamais été
  compilé localement, la CI macOS reste la seule vérification de build. La
  relecture ligne à ligne a suffi cette fois, ce n'est pas une garantie.
- Aucune formule financière, aucun identifiant, aucune migration touchés.

### Dette laissée ouverte, explicitement

- Le **shell reste Obsidian** (bannière de démo, ＋, onglet sélectionné,
  `RootView.tint`). Visible sur les trois captures, franchement discordant —
  mais c'est le périmètre **NU4**.
- Les **quatorze écrans non pilotes** gardent la bande morte de 80 pt.
- `DemoTourUITests` (tour hérité) reste cassé sur des assertions périmées
  d'avant ADR-026, sans rapport avec NU3. Il ne bloque plus la preuve du lot
  depuis que `NeonUltraPilotTourUITests` capture les trois surfaces seul,
  mais il devra être remis d'aplomb.

## Lot « identité installée » (05.08.2026) — VERIFYING

Les deux points laissés en attente de décision sont levés sur accord du
propriétaire (« go », 05.08.2026).

### 1. Le manifeste mentait sur la couleur

`manifest.webmanifest` annonçait `#07090e` en `theme_color` et
`background_color`, alors que l'app peint `#090C12` (token `--canvas`, posé
par `applyTheme()`). Au lancement de l'app installée, l'écran d'attente
n'avait donc pas la couleur de l'app. Les deux valeurs sont alignées sur
`#090C12` — la couleur RÉELLE, pas une troisième inventée.

### 2. L'icône passe en Neon Ultra

L'icône restait l'ancienne courbe indigo Obsidian. Elle adopte la palette
ADR-024 : fond `#11141C → #05060A`, trait en dégradé
`violet #7C3AED → magenta #D946EF → cyan #38BDF8`, point cyan à pastille
claire. **La FORME est conservée** : seule l'identité chromatique change.
Le choix du symbole lui-même (une courbe qui monte, héritée de l'ancienne
marque) reste une décision du propriétaire, non tranchée ici.

Le dessin était décrit en SVG dans `generer-icones.mjs`. **Périmé depuis le
06.08.2026** : le propriétaire a fourni les vrais dessins, le script SVG est
supprimé et la source est désormais `assets/marque/` + `generer-marque.py`.
Le principe, lui, ne change pas — les quatre cibles sont
générées ensemble — `icon-192`, `icon-512`, `apple-touch-icon` (180) et
l'`AppIcon1024` natif — sans quoi PWA et iOS divergeraient à la première
retouche. Pas de coin arrondi dessiné : iOS et Android appliquent déjà leur
masque.

### Preuves

- **98 parcours e2e** (97 conservés + le n° 98) · 5 fixtures de parité ·
  design Obsidian, NU1 et NU2 verts · zéro erreur console.
- Le n° 98 exige que manifeste et balise annoncent la **même** couleur, que
  chaque icône soit carrée, **opaque** (une icône trouée est compositée sur
  du blanc par iOS) et réellement dessinée, et que la taille déclarée au
  manifeste soit la vraie.
- **Contrôle négatif effectué** : une couleur divergente et une taille
  déclarée fausse produisent bien deux échecs nommés.
- Les quatre PNG ont été **ouverts et regardés**, pas seulement mesurés.

## Lot « audit visuel des 16 écrans » (05.08.2026) — VERIFYING

Demande du propriétaire : « continue le peaufinage, aucune erreur visuelle,
icônes, tout tout. » L'audit est mécanique et reproductible
(`audit-visuel.mjs`) : les 5 onglets et les 11 sous-écrans sont parcourus à
390 px et à 320 px, à la recherche de pastilles d'icône non carrées, de
débordement horizontal, de cibles sous 44 px et de texte réellement tronqué.
**NU3 reste non commencé.**

### Cinq défauts trouvés et corrigés

1. **Le badge « Prévu » était rogné jusqu'à 95 px** — totalement invisible sur
   7 lignes sur 10 à 320 px. « Prévu » et « comptabilisé » sont un invariant
   du produit, et ce badge était le seul signal sur la ligne : deux mouvements
   de nature opposée devenaient identiques. Le titre cède la place, le badge
   reste entier.
2. **L'icône de la carte de sauvegarde s'étalait sur 324 × 19 px** : la carte
   avait oublié la classe `tx`, donc la pastille n'héritait d'aucune taille.
   Seul cas du code.
3. **Les noms étaient tronqués dans les listes de gestion** à 320 px (comptes,
   factures, factures mensuelles). La règle `read-row` du projet — déjà
   appliquée aux Actifs et à la Prévoyance — leur est étendue. La liste dense
   des mouvements garde son ellipse (choix L5 assumé).
4. **Un libellé long collait son montant** dans les récapitulatifs à 320 px.
5. **Une pastille d'état touchait son titre** faute de marge.

### Preuves

- **97 parcours e2e** (96 conservés + le n° 97, qui contrôle à 390 px **et** à
  320 px) · 5 fixtures de parité · design Obsidian, NU1 et NU2 verts · zéro
  erreur console.
- **Contrôle négatif effectué** : les trois premiers défauts réintroduits
  produisent huit échecs nommés.
- **16/16 écrans propres** aux deux largeurs, 32 captures conservées dans
  `docs/neon-ultra/audit-visuel/` avec leur README.

## Lot « rituel du mois » (05.08.2026) — VERIFYING

Demande du propriétaire : « ce mois salaire reçu, bouton facture payée, op ça
disparaît — rendre l'outil pratique et simple à remplir et à comprendre. »
L'accueil raconte désormais le mois dans l'ordre où on le vit : ce qui doit
rentrer, puis ce qui doit sortir, et chaque chose faite quitte la liste. Le
programme visuel reste gelé : **NU3 n'est pas commencé.**

### Trois manques réels

1. **Aucune action pour encaisser un revenu** sur l'accueil simplifié : il
   fallait quitter l'écran pour dire « salaire reçu ». Carte « Revenus
   attendus » avec l'action au bon endroit.
2. **Une échéance seulement PRÉVUE n'était plus actionnable du tout** — elle
   restait « Planifiée » jusqu'à sa date sans aucun moyen de confirmer
   qu'elle avait eu lieu. C'est exactement le salaire prévu le 25 : zéro
   bouton, alors que « Entré » affichait CHF 0.00.
3. **Ce qui était réglé restait dans la liste des choses à faire.** Elle ne
   montre plus que le restant ; tout réglé, la carte le dit. Compteur, barre
   et « Gérer » gardent la trace complète.

Deux défauts d'affichage trouvés au passage : l'icône des lignes d'obligation
n'héritait d'aucune taille (`.home-bill-row` n'est pas un `.tx`) — l'emoji se
collait à gauche d'un rectangle teinté ; et chaque ligne coûtait 117 px, tombés
à **75 px** à 390 px en sortant le nom du compte du libellé et en passant
l'action en ligne au-dessus de 380 px.

### Règles financières : inchangées

Confirmer une échéance prévue est une transition explicite, pas un mélange.
Seul un mouvement **prévu** bascule ; un mouvement comptabilisé n'est jamais
retouché (verrouillé par test). La date ne recule **jamais** : seule une
échéance encore à venir prend la date d'aujourd'hui, parce que c'est
aujourd'hui que l'argent a bougé. Aucun montant, compte, catégorie ou
identifiant modifié. Revenus et dépenses gardent deux cartes et deux totaux,
jamais additionnés. Écriture annulable six secondes.

### Preuves

- **96 parcours e2e** (95 conservés sans affaiblissement + le n° 96) ·
  5 fixtures de parité · design Obsidian, NU1 et NU2 verts · zéro erreur
  console.
- Le n° 96 coche un mois entier depuis l'accueil : salaire prévu →
  comptabilisé **au jour réel**, « Entré » qui augmente, chaque facture réglée
  qui quitte la liste, compteur atteignant son total, et garde-fou prouvant
  qu'un mouvement comptabilisé n'est jamais re-daté.
- **Contrôle négatif effectué** : sans l'action de confirmation, la suite
  échoue.
- **Rendu inspecté** à 390 px et 320 px sur les trois étapes du rituel :
  `docs/neon-ultra/features/month-ritual/` (README + `capture-ritual.mjs`).

## Lot « feuilles de saisie » (02.08.2026) — VERIFYING

Demande du propriétaire, deux captures iPhone à l'appui : « je suis pas fan,
j'aimerais un autre style de page quand tu dois rentrer les données ». Choix
verrouillés par lui : le style **« Nouveau mouvement »**, appliqué aux **six
feuilles qu'il utilise vraiment**, puis étendu aux **dix-neuf** — un style
unifié n'a de valeur que s'il n'a aucun trou. Le programme visuel reste gelé :
**NU3 n'est pas commencé.**

Contrat porté par les 19 feuilles : pied collant (« Enregistrer » jamais sous
le clavier), action principale en dégradé de marque, montant dominant,
pastilles tactiles ≥ 44 px pilotant le `select` historique via `aria-pressed`,
reste replié sous « Détails (facultatif) ».

### Ce que l'inspection des captures a réellement trouvé

Quatre défauts, dont **trois qui empêchaient purement et simplement
d'enregistrer** :

1. **Aucun objectif ne pouvait être créé ni modifié.** Le gestionnaire lisait
   une variable inexistante (`covered`, reste d'un copier-coller depuis
   « Facture ponctuelle »). Le bouton « Enregistrer » ne faisait
   **strictement rien** : ni message, ni fermeture, ni donnée. Défaut
   silencieux, donc le pire.
2. **Aucune facture mensuelle** sans déplier « Détails » : le jour du mois y
   est obligatoire et n'avait pas de valeur par défaut. Il vaut désormais 1,
   et un refus **déplie** le bloc — un message ne désigne jamais un champ
   invisible.
3. **Le salaire refusait la saisie** tant qu'aucun salaire n'existait : jour
   vide alors qu'obligatoire. Pré-rempli à 25, jour de paie de référence.
4. **20 px de débordement horizontal** dans `txForm`, `recForm` et
   `itemForm`, présents depuis NU2 : le doublon masqué des `select` pilotés
   par pastilles (`.sr-select`) était redimensionné par `.sheet select`.

Corrigés au passage, sans changer aucune règle financière : cohérence de la
case « Solde négatif » avec les autres cases à cocher.

### Preuves

- **95 parcours e2e** (94 conservés sans affaiblissement + le n° 95) ·
  5 fixtures de parité · design system Obsidian, NU1 et NU2 verts · zéro
  erreur console · `git diff --check` propre.
- Le parcours n° 95 remplit chaque feuille **comme le propriétaire le ferait**
  — les champs visibles, rien de plus — et exige que la donnée existe ensuite.
- **Contrôle négatif effectué** : les deux premiers défauts réintroduits font
  bien échouer la suite (`objectif`, `facture mensuelle`, `pageerror: covered
  is not defined`). Le test a une valeur réelle, il ne décore pas.
- Le parcours n° 94 couvre les **19** feuilles, avec assertion de
  non-débordement horizontal et prédicat de cible tactile corrigé (un doublon
  `aria-hidden` hors tabulation n'est pas une cible).
- **Rendu inspecté** à 390 px, 320 px et 320 px à 200 % de texte :
  `docs/neon-ultra/features/forms/` (README + captures reproductibles par
  `capture-forms.mjs`).

## Lot fonctionnel « comme le tableur » (29.07.2026) — VERIFYING

Demande explicite du propriétaire : remplacer son tableur de référence, et
donc combler trois écarts fonctionnels. Décidé par **ADR-028**. Le programme
visuel reste gelé : **NU3 n'est pas commencé.**

Trois lots, un commit chacun, suites vertes à chaque étape :

1. **Page Année** (`3d2721e`) — les douze mois d'un coup d'œil, chacun
   ouvrable d'un tap : état écrit (Bouclé / En cours / À boucler / À venir /
   Vide), entré et sorti du mois, solde signé, douze barres de solde bornées
   à leur cadre, navigation d'année. Vue PURE : aucune formule nouvelle.
2. **Abonnements** (`440e348`) — les charges régulières reçoivent un rythme
   (`every`, `dueM`) et une résiliation (`endedOn`), tous **additifs**. Un
   annuel est engagé **uniquement sur son mois d'échéance** (décision du
   propriétaire), jamais lissé. Écran dédié avec deux totaux jamais
   additionnés entre eux : coût réel annuel, et moyenne mensuelle nommée
   comme telle.
3. **Tuiles d'accueil** (`d728c22`) — sept raccourcis portant chacun un
   chiffre réel, sous les factures. Navigation, pas analyse : aucune jauge,
   aucune courbe, aucun dégradé, point focal unique préservé.

### Le défaut que les tests ont réellement attrapé

La première passe du lot 2 n'avait adapté que `snapshot()`. Les suites ont
révélé deux oublis qui auraient été graves en usage réel :

- `monthlyObligations()` : un abonnement annuel apparaissait « en retard »
  onze mois sur douze dans le widget de l'accueil ;
- `monthCheckItems()` : il restait éternellement à cocher, ce qui rendait le
  mois **impossible à boucler**.

Corrigés, avec les revenus récurrents attendus et le bouton « régler ce
mois » qui ne s'offre plus hors échéance.

### Preuves

- **91 parcours e2e** (88 conservés sans affaiblissement + 3 nouveaux) ·
  5 fixtures de parité · design system Obsidian, NU1 et NU2 verts · zéro
  erreur console.
- **Le calcul verrouillé par test** : un annuel de 1200 dû en mars, avec un
  mensuel de 100, pèse 1300 en mars, 100 en avril, et **2400 sur la somme
  des douze mois** — jamais 15'600. Rituel et obligations vérifiés sur les
  deux mois.
- **Restauration durcie** : rythme inconnu, mois d'échéance hors 1-12 et
  date de résiliation illisible font REFUSER la sauvegarde. Absents restent
  acceptés — les sauvegardes antérieures gardent leur sens exact.
- **Rendu inspecté** à 390 px, 320 px et 320 px à 200 % de texte sur les
  trois surfaces : zéro débordement, zéro troncature, zéro cible sous 44 px,
  zéro erreur console.
- L'assertion du blueprint d'accueil a été **précisée, pas affaiblie** :
  elle distingue le widget d'analyse du raccourci de navigation et vérifie en
  plus qu'aucune tuile ne porte de jauge et que la grille suit les factures.

Les écrans Année et Abonnements naissent dans l'identité Neon Ultra : la
portée pilote les accueille, et le garde-fou d'isolation passe d'une tranche
de source à une attribution par fonction englobante avec liste blanche
explicite.

## Correctif critique de fiabilité (29.07.2026) — VERIFIED

La poursuite visuelle reste gelée avant NU3 pendant la validation d'un lot
correctif transversal découvert par audit. Ce lot ne change pas la direction
Neon Ultra et ne clôt aucun lot visuel.

- dates futures centralisées : une date après aujourd'hui reste planifiée,
  y compris après import CSV et matérialisation d'une échéance, puis devient
  comptabilisée une seule fois le jour dû (chargement/rendu web et
  lancement/retour au premier plan iOS) ;
- factures et paiements réguliers liés au compte choisi, dédupliqués par
  échéance et conservant leur date réelle ;
- remboursements annuels comptés une seule fois ;
- accueil et écran Impôts alimentés par le même rapport fiscal annuel ;
- restauration PWA validée intégralement avant remplacement de l'état
  (collections secondaires, rapport d'import, IDs et relations), avec retour
  à l'ancien blob si l'écriture échoue ;
- historique multi-devise PWA estampillé avec sa devise et son taux source,
  sans repli silencieux 1:1 ; devise du compte et devise de référence
  verrouillées dès qu'un historique existe ;
- restauration native refusant avant purge les enums inconnus, UUID orphelins,
  identifiants dupliqués et montants illisibles ;
- mutations SwiftData sauvegardées avec rollback explicite en cas d'échec.

Les tests dédiés sont ajoutés au web et au natif. Validation locale web :
**86 parcours e2e** (78 conservés + 8 scénarios critiques), zéro erreur
console, et **5 fixtures de parité** vertes. Validation distante :
**CI #253 verte** sur `a6ea692be7bcffdce527568c5bdfd7084826f9d5`
(86 e2e, 5 parités, design/accessibilité, **289 tests iOS**, builds Debug
et Release, PrivacyInfo et iPhone uniquement). Le code de fiabilité est
**CI VERIFIED**. Le workflow Pages est durci pour exiger une CI push verte
sur le SHA exact et publier automatiquement les changements `webapp/**`.
Le même garde-fou est synchronisé sur les trois branches autorisées par
l'environnement `github-pages`. La livraison `0afda7f3` a repassé la CI
complète (run `30449175567`, success), puis Pages #44
(`30449175379`, success) l'a publiée. Les sept fichiers publics ont été
retéléchargés et leurs SHA-256 correspondent octet pour octet aux sources
validées, notamment le nouvel `index.html`. Le lot de fiabilité est
**VERIFIED**. **NU3 reste READY et non commencé.**

## NU2 — Pilote PWA : Mois, Budget, Ajouter, Nouveau mouvement (27.07.2026) — DONE

Quatre surfaces — et quatre seulement — portent désormais l'identité Neon
Ultra dans la PWA réelle : `renderHome()` (Mois), `renderBudget()` (Budget),
la feuille `#quickMenu` (Ajouter) et la feuille `#txForm`
(Nouveau mouvement). Le reste de l'app demeure Obsidian Glass.

### Stratégie d'isolation (le cœur du lot)

- `webapp/design-system/neon-ultra.css` est chargée **exactement une fois**
  depuis `index.html`. Chaque règle de production est enracinée dans
  `#screen.nu-pilot-screen` ou `.sheet.nu-pilot-sheet` — aucune ne peut
  atteindre un écran non piloté.
- `index.html` ne **déclare** aucun token `--nu-*` et ne contient **aucune**
  valeur brute Neon Ultra : les vues pilotes ne référencent que des rôles
  (`var(--nu-*)`). Le corps de production ne porte jamais `.nu-body`.
- Les modifications JavaScript se limitent au périmètre autorisé : une
  bascule de classe dans `render()` (Mois et Budget uniquement, hors
  onboarding et hors verrouillage) et la durée du compteur héros
  (`animateHeroAmount`, 200 ms, neutralisée sous mouvement réduit).
- Tous les tokens Obsidian d'`index.html` sont vérifiés **inchangés** par
  test, et le tableau BANNED historique reste intact.
- La vérification de clôture interdit désormais toute référence
  `var(--nu-*)` injectée hors des deux renderers pilotes. Elle ouvre aussi le
  détail Compte et mesure ses styles calculés : courbe Indigo et règle grise
  restent strictement Obsidian, sans classe pilote.

### Ce qui change à l'écran

- **Mois** : canvas `#05060A`, cartes de liste **mates** `#11141C` sans flou,
  héros seul en surface élevée `#181C26`, un **unique** point focal lumineux
  (CTA `#C000A4 → #6E00E8`, texte blanc dédié), aucun halo autour d'un
  montant, légendes remontées à 13 px.
- **Budget** : anneau et jauges plats, couleurs strictement sémantiques,
  état du plan toujours **écrit** (« Dans le plan » / « À surveiller » /
  « Dépassé »), planifié et réel jamais mélangés. L'état vide devient
  pédagogique : promesse, action unique, puis les trois étapes de
  « Comment ça marche ».
- **Ajouter** : feuille pilote opaque, huit destinations **strictement
  égales** entre elles (aucun faux point focal), cibles ≥ 44 px.
- **Nouveau mouvement** : le montant devient le champ dominant (20 px),
  les sept types sont des pastilles ≥ 44 px, l'intitulé est multiligne et
  reste entièrement lisible, le CTA « Enregistrer » est collant en pied,
  et le message d'erreur s'affiche **contre le champ fautif** (corail
  `#FF6577`, `aria-invalid`, focus déplacé).
- **Correctif d'accessibilité découvert par le lot** : la zone cliquable
  d'une facture (`.meta[role="button"]`) tombait à 29 px de haut à 320 px.
  Elle est ramenée à 44 px minimum dans la portée pilote.
- **Correctifs de clôture** : la cible repliable
  « Détails (facultatif) » mesure elle aussi au moins 44 px ; à 320 px, les
  montants héros, métriques et Budget s'adaptent aux polices système larges
  sans perdre un chiffre. Un Budget à sept chiffres réorganise son héros
  avant de réduire le montant.

### Preuves

- **Tests web** : 78 parcours e2e (72 conservés sans affaiblissement +
  **6 parcours NU2** : Mois piloté et isolation des écrans Obsidian, Budget
  vide puis chargé, ＋ → Ajouter → mouvement réellement enregistré au
  centime, erreur de formulaire, accessibilité 320 px / focus / mouvement
  réduit, HTTP + service worker + hors-ligne) · 5 fixtures de parité ·
  design system Obsidian **et** fondations NU1 **et** surfaces pilotes NU2
  verts · zéro erreur console. Le passage final mesure aussi tous les
  contrôles visibles du formulaire et inspecte le détail Compte.
- **HTTP, rechargement et hors-ligne** : serveur local réel, `sw.js` livré
  tel quel (aucune modification, nom de cache inchangé), page réellement
  **contrôlée** par le service worker, rechargement en ligne puis coupure
  réseau et vrai rechargement — l'app s'ouvre entière, les données du foyer
  survivent, `neon-ultra.css` est servie depuis le cache et parsée, le
  canvas, le héros et le CTA gardent leurs valeurs mesurées.
- **Captures** : `docs/neon-ultra/pilot/nu2/README.md` + **12 captures**
  générées par outillage reproductible sur données fictives et toutes
  réellement ouvertes (390, 320, montant extrême à sept chiffres, budget
  vide, menu Ajouter, formulaire, erreur, clavier simulé, texte 200 %,
  transparence réduite).
- **Non-régression financière** : aucune formule, conversion, validation,
  clé `localStorage`, structure de données ni destination de navigation
  n'est touchée — seules des règles de présentation et la bascule de classe
  changent.

### Limite connue, non corrigée par NU2

La PWA dimensionne ses textes en pixels (**P3-5**, ouverte depuis L9) : le
grossissement disponible est le zoom de page. La capture 200 % le reproduit
fidèlement plutôt que de simuler un mécanisme absent.

Validation du propriétaire reçue le **27.07.2026** sur
`ff029388d275798a98046a777e4f3389507c1399` : les quatre surfaces sont
acceptées et leur publication GitHub Pages est explicitement autorisée.
**NU2 est clos ; NU3 est autorisé mais n'est pas commencé.**

## NU1 — Tokens et primitives (27.07.2026) — DONE

Fondations Neon Ultra livrées en familles parallèles ISOLÉES (aucun écran
réel modifié ; la PWA publique et les écrans SwiftUI restent Obsidian
jusqu'à NU2/NU3) :

- **iOS** : `NeonUltraColor/Gradient/Radius/Motion/Typography` (ajout pur en
  fin de `DesignTokens.swift`), primitives `NeonUltraComponents.swift`
  (cartes mate/élevée, CTA gradient, secondaire, destructif sémantique,
  chip 3 états, badge ×4, montant sans glow via FinanceFormatting, focus
  cyan, résolveur Reduce Transparency → `#151923`),
  `NeonUltraComponentGallery.swift` (jamais reliée à la navigation ;
  harness `UIHostingController`), `BudgetTests/NeonUltraDesignSystemTests.swift`
  (**17 tests**, prouvés par CI : RGBA exacts, contrastes AA mesurés, CTA
  blanc pur 5,56/7,43, identité unique, sémantique ≠ marque,
  géométrie/mouvement, cibles tactiles MESURÉES ≥ 44×44 pt par rendu,
  Reduce Motion comportemental via `NeonUltraMotionResolver`, montant
  extrême, galerie 320/390/accessibility3/transparence réduite) —
  **276 tests iOS au total, 0 échec**.
- **PWA** : `webapp/design-system/neon-ultra.css` (variables `--nu-*`,
  valeurs brutes uniquement dans `:root`) + `neon-ultra-gallery.html`
  (seule page qui charge cette feuille). `webapp/index.html` : zéro octet
  modifié ; le tableau BANNED historique interdit toujours les teintes
  Neon Ultra dans l'app.
- **Tests web additifs** (`design.test.mjs` §NU1–NU9) : tokens exacts,
  isolation de l'app, parité Swift↔CSS (18 rôles + rayons + mouvement),
  contrastes complets (15 paires texte/surface + CTA + sémantique + focus),
  galerie 320/390, focus cyan ≥ 2 px, états sélectionné/erreur/désactivé,
  texte agrandi 200 %, reduced motion, transparence réduite opaque sans blur.
- **Preuves** : `docs/neon-ultra/foundations/nu1/README.md` + 7 captures
  inspectées (390, 320, 320@200 % — champ multiligne complet, transparence
  réduite, reduced motion, focus cyan réel, gros plan des états). Captures simulateur iOS : impossibles depuis cet
  environnement Linux — harness de test CI en attendant, PNG au plus tard
  avec NU3 (limitation documentée).
- **Inventaire d'identité** (manifest `#07090e`, theme-color `#090C12`,
  icônes PWA, AccentColor `#4B5CFF`, AppIcon) : consigné, AUCUNE
  modification — différé à NU7.

Validation du propriétaire reçue le **27.07.2026** sur
`5796e3c74bc44ae6a5f75c4e3e9f3eec526979ce` : NU1 est clos, NU2 autorisé.

## NU0 — Clôture (27.07.2026) — DONE

Validation propriétaire du contenu technique NU0 reçue, définitive après :

- **Image de référence intégrée** :
  `.claude/skills/budget-neon-ultra/assets/visual/neon-ultra-reference.jpeg`
  — reçue, copiée sous nom stable, décodage vérifié (JPEG valide,
  **736×1174 px**, 530 614 octets), réellement ouverte et inspectée.
  Éléments retenus : fond noir, profondeur graphite, éclairages
  magenta/violet/cyan, cartes superposées, énergie premium — aucun texte,
  personnage, nom, logo ni écran exact ne sera copié.
- **Correction AA du contrat** (mesures indépendantes reproduites) : texte
  discret `#747E8E` → **`#7C8696`** (l'ancien mesurait 4,49:1 / 4,15:1 /
  4,28:1 sur surface standard / élevée / fallback — sous AA ; le nouveau
  mesure canvas 5,50:1 · navigation 5,28:1 · surface standard 5,00:1 ·
  surface élevée 4,63:1 · fallback opaque 4,78:1). Constitution, résumé du
  skill et ADR-024 alignés.
- **Règle violet** ajoutée à la constitution : `#7C3AED` ≈ 3,41:1 sur la
  navigation — icônes grandes, bordures et indicateurs seulement, jamais
  seul pour un petit libellé actif (texte actif = `#F5F7FA` + indicateur
  violet, sauf paire mesurée ≥ 4,5:1).
- Aucun écran, token applicatif, rendu ni comportement modifiés ;
  `git diff --check` vert ; CI complète verte attendue sur le commit de
  clôture (rapportée en session).

## NU0 — Gouvernance et baseline (27.07.2026) — historique de la passe initiale

Livré (aucun écran, rendu, token ni logique modifiés) :

- **Skill** `.claude/skills/budget-neon-ultra/` : `SKILL.md` (plan / execute
  NU0–NU9 / continue / verify / prompt) + `NEON_ULTRA_CONSTITUTION.md`
  (palette et règles canoniques) + `NEON_ULTRA_DELIVERY.md` (10 lots) +
  `NEON_ULTRA_SCREEN_MATRIX.md` (écrans PWA/iOS + divergence navigation) +
  `REPOSITORY_CONTRACT.md` (protections, commandes, bases) +
  `REFERENCE_INDEX.md` + outillage reproductible de capture
  (`assets/tools/capture-baseline.mjs`).
- **ADR-024** (DECISION_LOG.md) : Neon Ultra remplace UNIQUEMENT les clauses
  visuelles d'ADR-020/022/CLAUDE.md/constitution Obsidian ; historique
  L0–L9 conservé tel quel, aucun rapport réécrit.
- **CLAUDE.md** aligné (programme actif, branche, autorités) ; **budget-v1**
  reçoit un bloc ROUTAGE (skill historique, ne plus l'invoquer).
- **Baseline prouvée** : `docs/neon-ultra/baseline/nu0/README.md` — 72 e2e ·
  5 parités · design system vert (contrastes mesurés) · 259 tests iOS,
  0 échec · builds Debug+Release SUCCEEDED · PrivacyInfo valide ·
  `UIDeviceFamily == [1]` · TARGETED_DEVICE_FAMILY = 1 (Debug+Release) ·
  zéro pageerror/erreur console · persistance disque
  (`DiskStoreLifecycleTests`) · sauvegarde/restauration
  (`BackupServiceTests` + e2e) · tests financiers nommés (FINANCIAL_AUDIT
  L9) · perf 10k mouvements (27–34 ms/peinture, DOM ≤ 200 lignes) ·
  13 captures PWA 390/320 générées et inspectées.
- **Divergence navigation documentée, NON réconciliée** : PWA 4 onglets +
  ＋ central (Mouvements dans Plus) vs iOS 5 onglets + ＋ flottant —
  décision produit séparée requise (baseline §5, matrice §1, ADR-024 §5).

### Inventaire de référence (HEAD source)

- PWA : `webapp/index.html` (≈ 305 Ko, app complète), `webapp/sw.js`,
  `webapp/manifest.webmanifest` (protégés hors lots visuels concernés).
- Tests web : `webapp/tests/e2e.test.mjs` (72 parcours),
  `webapp/tests/parity.test.mjs` (5 fixtures),
  `webapp/tests/design.test.mjs` (design system).
- iOS : `Budget/App/RootView.swift` (5 onglets + ＋ flottant),
  `Budget/Core/DesignSystem/DesignTokens.swift` + `GlassCard.swift` (tokens
  à faire évoluer en NU1), Features par onglet ; 259 tests
  (`BudgetTests`, dont `DiskStoreLifecycleTests`, `BackupServiceTests`,
  `AppLockManagerTests`, suites financières nommées).
- Workflows : `ci.yml` (Web + macOS iOS + contrôles produit), `demo.yml`
  (archive + IPA + captures simulateur en artefacts), `pages.yml`
  (déploiement Pages du propriétaire — sur la branche Obsidian, intouché).
- Fixtures : `fixtures/parity-fixtures.json` (protégées).

### En attente du propriétaire (HUMAN REQUIRED)

1. Décision produit navigation PWA/iOS (hors périmètre NU0–NU8) —
   divergence documentée, décision séparée en attente.
2. Héritage L9 inchangé : L9 Obsidian = VERIFYING (historique) ; QA iPhone
   réel, haptique, Face ID, VoiceOver physique, compte Apple/TestFlight —
   PENDING HUMAN.

### Prochaine action exacte

`/budget-neon-ultra execute NU3` — pilote SwiftUI équivalent, sans modifier
la navigation. La divergence de navigation PWA/iOS demeure une décision
produit séparée.
