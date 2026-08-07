# Audit complet avant la semaine de test (07.08.2026)

Demande du propriétaire : « un audit totalement complet sur tout ce que tu as
modifié… chaque graphique, chaque donnée, que tout soit aligné, que les émojis
soient parfaits… l'objectif, c'est que l'application soit prête à cent pour
cent pendant une semaine. »

Trois outils, tous reproductibles, tous sur des données **fictives et
déterministes**. Aucun jugement de goût : on compte, on mesure, on compare.

| Outil | Ce qu'il mesure |
|---|---|
| `audit-total.mjs` | 16 écrans × 3 largeurs : alignement, rayons, paddings, tailles de texte, **contraste réel de chaque texte sur son fond effectif**, cibles tactiles, boutons sans destination, débordement, nombre de titres |
| `audit-visuel.mjs` | pastilles d'icône non carrées, texte réellement tronqué |
| `audit-final.mjs` (nouveau) | **présentation des émojis**, émojis lus à voix haute, **fidélité des graphiques et des montants** |

## Résultat

```
audit-total  320 px : Aucun écran en défaut
audit-total  390 px : Aucun écran en défaut
audit-total  430 px : Aucun écran en défaut
audit-visuel        : console propre, 16 écrans
audit-final         : Aucun défaut — 14 contrôles passés
105 parcours e2e · 5 fixtures de parité · design system — verts
```

Aux trois largeurs : **zéro débordement horizontal, zéro contraste sous le
seuil AA, zéro cible sous 44 px, zéro bouton sans destination, un seul bord
gauche à 18 px sur les seize écrans, un seul titre par écran**, et trois rayons
et trois seulement — héros 26, carte 18, ligne 14.

## Ce que l'audit a réellement corrigé

### Les émojis : plus rien n'est laissé à la police de l'appareil

Un emoji sans **sélecteur de présentation** a un rendu qui dépend de l'appareil :
`⚠`, `🛡`, `🏖` et `🏛` ont pour défaut Unicode la présentation **texte**, donc un
trait fin monochrome là où on attend un pictogramme en couleur. 30 occurrences
corrigées.

La preuve est mécanique, pas visuelle : un emoji couleur **ignore** la propriété
`color`, un glyphe texte la suit. On dessine donc chaque glyphe deux fois, en
rouge puis en bleu, et on compare les pixels.

Un seul glyphe reste volontairement en présentation texte : `✉︎`, dans les
icônes de mouvement. Là, le trait fin qui **suit la couleur du montant** est le
comportement voulu — un emoji couleur en serait incapable.

### Un signe qui parlait sans rien dire

Sur les objectifs, le `⚠️` du rythme d'épargne était annoncé « attention » par la
synthèse vocale, sans dire de quoi. Le signe devient décoratif et l'étiquette
dit la phrase entière : *« CHF 250.00 par mois — en dessous du rythme
nécessaire »*.

## Les graphiques disent-ils la vérité ?

Chaque valeur dessinée est **recalculée depuis l'état** et comparée au dessin.

| Contrôle | Résultat |
|---|---|
| Anneau du Budget : le % écrit est celui de ses deux montants | 86 % = 3'407.95 / 3'950.00 ✓ |
| Anneau du Budget : le « dépensé » est la vraie dépense de vie | 3'407.95 = 3'407.95 ✓ |
| Barres des abonnements : largeur dessinée = % écrit | 3 barres ✓ |
| Page Année : 12 mois, chacun avec son vrai résultat | ✓ |
| Héros — disponible, mis de côté, placements, prévoyance, patrimoine | 5 cartes recalculées ✓ |
| Tuile « À payer » | 3'520.70 = 3'520.70 ✓ |

## Quatre fois où mon propre outil avait tort

Un audit qui crie au loup est pire qu'aucun audit. Sur cinq signalements de la
première passe, **quatre venaient de l'outil, pas de l'application** :

1. **L'anneau du Budget « mentait de 29 points ».** Mon calcul divisait par
   TOUTES les lignes de budget — épargne, 3e pilier et impôts compris. L'app
   divise par les seules dépenses de vie, ce qui est l'invariant du projet, et
   elle l'**écrit à l'écran** : « L'épargne et les impôts sont comptés à part ».
   L'application avait raison.
2. **La page Année « oubliait neuf mois ».** Un mois sans mouvement affiche
   « Vide » ou « À venir — rien d'enregistré », pas « 0.00 ». C'est mieux :
   zéro franc et rien du tout ne veulent pas dire la même chose.
3. **`⚙️` et `☁️` accusés d'être en noir et blanc.** La sonde testait le glyphe
   **sans** son sélecteur ; ils portaient déjà le bon.
4. **Le drapeau suisse jugé monochrome.** Il est fait de deux indicateurs
   régionaux : ma sonde en testait un seul, ce qui ne veut rien dire.

## Un dégât que j'ai causé, et que le test a attrapé

Le remplacement global `🏛 → 🏛️` a touché `TYPE_ICON`, où le sélecteur est écrit
en **séquence d'échappement** (`"🏛︎"`) et non en caractère. L'icône
d'épargne a cessé de suivre la teinte du sens pendant une passe. Le test
« couleurs et lignes honnêtes » l'a dit immédiatement, avant tout commit.

## Reproduire

```
export BUDGET_CHROMIUM=/chemin/vers/chrome
for W in 320 390 430; do W=$W node .claude/skills/budget-neon-ultra/assets/tools/audit-total.mjs; done
node .claude/skills/budget-neon-ultra/assets/tools/audit-visuel.mjs
node .claude/skills/budget-neon-ultra/assets/tools/audit-final.mjs
(cd webapp/tests && node e2e.test.mjs && node design.test.mjs && node parity.test.mjs)
```

## Ce que cet audit NE dit pas

Il est honnête de borner ce qui est prouvé.

- **Rien n'a été vérifié sur un iPhone physique.** Tout est mesuré dans un
  Chromium réel à 320, 390 et 430 px. Le rendu des émojis, les gestes et le
  retour haptique sur un vrai appareil restent à confirmer par vous.
- **L'app native iOS** est validée par la CI macOS (build, tests, Release,
  manifeste de confidentialité, iPhone uniquement) — pas par un œil humain sur
  un appareil.
- **Le site publié** n'a pas pu être ouvert depuis l'environnement d'audit :
  `github.io` y est bloqué. Ce qui est vérifié, c'est le déploiement rapporté
  par GitHub sur le SHA exact.
- **Aucune donnée réelle n'a été utilisée**, ni dans les tests, ni dans les
  captures, ni dans les journaux.
