# Budget — Neon Ultra : état d'avancement

Programme actif (ADR-024) · branche `refonte/budget-neon-ultra-v1` · créée
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
