# NU4 — la coquille native passe en Neon Ultra

Captures **réelles** du simulateur iPhone, produites par le workflow Demo et
regardées une par une. Ce ne sont ni des aperçus Xcode ni des maquettes.

| Fichier | Run | Ce qu'il montre |
|---|---|---|
| `avant-coquille-indigo.png` | Demo #42 (`77166a2`) | La bande indigo saturée et la barre d'onglets indigo |
| `apres-coquille-neon.png` | Demo #43 (`da1358e`) | Un seul accent : le cyan |
| `apres-budget.png` | Demo #43 | Budget avec la nouvelle coquille |
| `apres-nouveau-mouvement.png` | Demo #43 | La feuille de saisie |

## Ce que la capture « avant » montrait

1. La **bannière de démonstration** formait un bloc indigo saturé sur toute
   la largeur, au-dessus de la barre d'état. C'était le premier point
   lumineux de CHAQUE écran, alors que la constitution réserve le point
   focal unique au contenu.
2. La **barre d'onglets et le ＋** tiraient leur teinte de `RootView`
   (`BudgetColor.indigo`) pendant que les **flèches de mois étaient déjà
   cyan**. Deux accents se battaient dans la même image.
3. Le fond, lui, était bien le noir Neon Ultra — NU3 avait fait son
   travail. C'est la coquille qui était restée en arrière.

## Pourquoi le cyan et pas le violet

Le token le dit lui-même : `violet #7C3AED` mesure ≈ 3,41:1 sur la
navigation `#0B0D13` et « ne porte JAMAIS seul un petit libellé actif ».
`cyan #38BDF8` mesure ≈ 9,3:1. Un libellé d'onglet sélectionné est
exactement ce cas — donc cyan.

## Ce qui n'est PAS fait

Les vingt-six écrans non pilotes gardent leurs cartes Obsidian. Seule la
coquille change ici : changer la coquille **et** les écrans dans le même lot
rendrait impossible de dire lequel a cassé quoi si une capture cloche.

## Pourquoi ces captures existent enfin

Le workflow Demo était rouge depuis le 25.07 — neuf étiquettes périmées
dans le tour hérité, dont sept que les journaux n'affichaient même pas
(l'exécution s'arrêtait à la première). Tant qu'il restait rouge, tout
travail visuel natif se faisait en aveugle. C'est ce qui a été réparé juste
avant ce lot.

## Reproduire

```
GitHub → Actions → Demo → Run workflow (branche refonte/budget-neon-ultra-v1)
```

Le workflow imprime aussi ces images en base64 dans ses journaux : le
stockage d'artefacts est injoignable depuis certains environnements de
revue, et sans ce contournement rien de tout cela n'aurait pu être regardé.
