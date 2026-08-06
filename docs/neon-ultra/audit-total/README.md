# Audit total — ce que la machine a trouvé

`audit-total.mjs` mesure les seize écrans à 320, 390 et 430 px sur des axes
que l'œil rate après trois heures : alignement, rayons, paddings, tailles de
texte, **contraste réel** de chaque texte sur son fond effectif, cibles
tactiles, boutons sans destination, débordement, nombre de titres.

Il ne juge pas le goût. Il compte, mesure, compare.

## Ce qui était déjà bon

Aux trois largeurs : zéro débordement, zéro contraste sous le seuil AA,
zéro cible sous 44 px (une exception corrigée), zéro bouton sans
destination, **un seul bord gauche à 18 px sur les seize écrans**, un seul
titre par écran.

## Les trois défauts trouvés

### 1. Deux systèmes géométriques dans la même application

| | héros | carte | ligne |
|---|---|---|---|
| Obsidian (14 écrans) | 28 px | **22 px** | 14 px |
| Neon Ultra (pilotes) | 26 px | **18 px** | 14 px |

Cinq rayons distincts. Visible dès qu'on passait de Comptes à Mois : les
cartes changeaient de forme. Unifié sur la géométrie Neon Ultra, identité
cible d'ADR-024.

### 2. Deux textes sous le seuil de lisibilité

Le « utilisé » sous l'anneau du Budget était à **8 px** — la plus petite
taille de l'app, et de loin. Les mois de la page Année à 9 px. Passés à
10 px ; douze colonnes les tiennent largement.

### 3. Une cible tactile à 43,5 px

Le bouton « Suppr. » d'un document, visible seulement à 430 px de large.

## Une correction de l'outil lui-même

La première version signalait « plus de deux rayons » comme un défaut — et
criait au loup sur quatre écrans qui contenaient simplement un héros, des
cartes et des lignes, c'est-à-dire le système au complet. Un audit qui crie
au loup est pire qu'aucun audit. Il compare désormais aux trois valeurs
autorisées, pas à leur nombre.

## Le logo

| Fichier | |
|---|---|
| `logo-ancien.png` | La courbe boursière héritée de « Mendestrading » |
| `logo-nouveau.png` | L'anneau du budget |
| `logo-a-toutes-les-tailles.png` | 120, 60, 40 et 29 px — les tailles réelles |

L'ancien dessin promettait la **Bourse** alors que le produit promet de
savoir où passe son argent. Il était aussi presque noir sur noir, et son
trait fin disparaissait à 40 px.

Le nouveau est l'**anneau du budget** : l'élément signature de
l'application, celui de l'écran Budget avec « 73 % utilisé ». Une icône qui
EST le composant central du produit est cohérente par construction, et elle
dit la bonne chose — voilà la part de ton mois déjà partie, voilà ce qui
reste.

Décisions vérifiables sur le rendu : anneau épais (13 % du côté), rempli à
72 % et jamais fermé, piste restante **visible** sans quoi on ne lit pas une
proportion, fond légèrement remonté au centre pour que l'icône ne se
dissolve pas sur un fond d'écran noir, aucun coin arrondi dessiné (iOS
applique le sien).

Première tentative rejetée : le dégradé par défaut plaçait le cyan dans le
coin haut-droit du cadre, exactement là où l'anneau est **ouvert** — la
couleur n'apparaissait nulle part, et l'ouverture penchait. Corrigé en
`userSpaceOnUse` avec un axe explicite et une ouverture centrée en haut.

## Reproduire

```
W=390 BUDGET_CHROMIUM=… node .claude/skills/budget-neon-ultra/assets/tools/audit-total.mjs
BUDGET_CHROMIUM=… node .claude/skills/budget-neon-ultra/assets/tools/generer-icones.mjs
```
