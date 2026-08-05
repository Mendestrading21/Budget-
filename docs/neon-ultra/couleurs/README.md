# Couleurs et lignes honnêtes — preuves avant/après

Quatre défauts **mesurés sur l'app rendue**, pas devinés en lecture de code.

| Fichier | Ce qu'il montre |
|---|---|
| `avant-390-patrimoine.png` | La composition : deux segments sur trois de la **même** couleur |
| `apres-390-patrimoine-courbe.png` | Quatre courbes, quatre couleurs, quatre traits |
| `avant-320-assurances.png` | « Caisse maladie (LAMal) » haché sur trois lignes dans 78 px |
| `apres-320-assurances.png` | Le titre sur une ligne, le montant dessous |
| `avant-320-factures.png` | Sous-titres sur quatre lignes, bas de page coupé |
| `apres-320-factures.png` | Tout l'écran tient, note de bas de page comprise |
| `apres-390-pastilles.png` | Les huit pastilles de mouvement suivent leur teinte |
| `apres-320-comptes.png` | « Où est votre argent » : trois segments distincts |

## 1. Des couleurs qui mentaient

Les quatre courbes du Patrimoine empruntaient `--positive` (vert),
`--negative` (corail) et `--warning` (ambre). Une courbe « Prévoyance »
tracée en corail se lit comme une perte. La constitution réserve ces trois
couleurs à leur sens financier : elles ne peuvent pas servir à distinguer
des séries.

Pire, `--electric` et `--violet` pointent **tous les deux** vers
`--brand-bright` depuis la remise à plat L2. La barre de composition
dessinait donc « Comptes » et « Prévoyance » dans la même couleur, avec deux
pastilles identiques en légende. La barre ne se lisait pas.

Rampe `--series-1..5` : des pas d'indigo et de gris froid, tous ≥ 3:1 sur le
fond, **plus un trait différent par courbe** — deux indigos voisins ne se
distinguent pas à 1,5 px sur un téléphone, et la couleur seule ne doit jamais
porter le sens.

La répartition des Comptes avait le même mal, autrement : sa troisième
classe tirait sur `--line-strong`, une couleur de **bordure**. La plus grosse
classe (48 %) se lisait comme du vide. Mesuré après correction :
`#CDC8FF`, `#948BFF`, `#6457F0`.

## 2. Deux pastilles sur huit ignoraient la teinte

📈 et 🧾 n'ont **aucune** présentation texte : U+FE0E ne les change pas.
Mesuré glyphe par glyphe — chaque caractère rendu deux fois, sous deux
couleurs CSS, comparé au pixel — le trait de 📈 reste rouge. Une pastille
« Investir » violette portait donc un symbole de perte.

Remplacés par des symboles qui, eux, suivent `currentColor` : `↗` (la valeur
monte) et `✉` (l'avis d'impôt arrive par la poste, même métaphore que le 📮
de l'écran Impôts).

## 3. À 320 px, le texte n'avait plus la place d'exister

Mesuré : ligne de 284 px, montant `flex: none` à 108 px, titre réduit à
**78 px** — quatre lignes hachées. Sous 381 px, le montant descend sous le
texte, aligné sur lui. Les listes de mouvements, denses et non `read-row`,
gardent leur mise en page : elles ellipsent, elles ne se hachent pas.

## 4. Deux libellés coupés en deux

« ‹ Gérer » se scindait en « ‹ » puis « Gérer » dès que le titre d'écran
était long ; « 68,5 % » retombait en « 68,5 » puis « % » dès qu'un objectif
portait un badge. Deux `flex: none` + `nowrap`.

## Ce que le test 100 verrouille

- Les cinq couleurs de série sont différentes et n'empruntent ni le vert, ni
  le corail, ni l'ambre.
- Chaque pastille de `TYPE_ICON` **suit** la couleur du sens — vérifié en
  rendant le glyphe sous deux couleurs et en comparant les pixels.
- Deux classes ne partagent jamais couleur ni trait ; aucun segment ne porte
  la couleur de sa piste.
- À 320 px le montant est sous le texte, le titre garde plus de la moitié de
  la ligne et tient en deux lignes au plus.
- Le bouton retour et le pourcentage tiennent sur une seule ligne — compté
  par `Range.getClientRects()`, la hauteur ne dit rien quand un plancher
  tactile de 44 px l'écrase.

**Contrôle négatif exécuté** : les quatre correctifs annulés un par un
produisent bien quatre échecs nommés.
