# ADR-028 — Rythme des charges, page Année, tuiles d'accès

Preuves visuelles des trois lots qui permettent à l'app de remplacer le
tableur de référence du propriétaire. Décision : **ADR-028**
(`DECISION_LOG.md`). Programme visuel Neon Ultra **gelé** pendant cette
passe : NU3 n'est pas commencé.

Captures générées par
`.claude/skills/budget-neon-ultra/assets/tools/capture-adr028.mjs` sur un
foyer **entièrement fictif** (« Alex »), le jeu de démonstration de l'app, et
un abonnement annuel explicite. Aucune donnée réelle du propriétaire.

```
BUDGET_CHROMIUM=/chemin/vers/chrome \
  node .claude/skills/budget-neon-ultra/assets/tools/capture-adr028.mjs
```

> Une capture ne remplace jamais un test. Tout ce qui est montré ici est
> verrouillé par `webapp/tests/e2e.test.mjs` (parcours 87 à 91) et
> `webapp/tests/design.test.mjs`.

## L'erreur du tableur que l'app corrige

Le tableau d'abonnements de référence affiche **SOMME 995.75 CHF**. Ce
chiffre ne veut rien dire : il additionne des prix **annuels** et des prix
**mensuels** dans la même colonne.

| | Détail | Coût réel |
| --- | --- | --- |
| Annuels | TradingView 234 + IPTV 170 + PS5 169.90 + Notion 130 + Microsoft 99.95 | **803.85 / an** |
| Mensuels | Claude 100 + Manus 40 + Apple Music 21.90 + ChatGPT 20 + iCloud 10 | **191.90 / mois** = 2'302.80 / an |
| | | **3'106.65 / an, soit 258.90 / mois** |

L'écran Abonnements affiche donc **deux totaux jamais additionnés entre
eux** : le coût réel annuel, et la moyenne mensuelle nommée comme telle.

## Les neuf captures

| Fichier | Ce qu'elle prouve |
| --- | --- |
| `adr028-390-accueil-tuiles.png` | Sept tuiles d'accès sous les factures, chacune avec un chiffre réel. Navigation, pas analyse : aucune jauge, aucune courbe, aucun dégradé. Le point focal lumineux reste l'unique CTA du héros |
| `adr028-320-accueil-tuiles.png` | Même grille au plancher supporté : deux colonnes, rien de tronqué, cibles ≥ 44 px |
| `adr028-390-annee-haut.png` | Année : héros « mis de côté », entré et sorti de l'année, taux d'épargne, puis les douze barres de solde avec la ligne de zéro et le mois en cours repéré en cyan |
| `adr028-390-annee-mois.png` | Les douze mois avec leurs **cinq états distincts** écrits : Bouclé, En cours, À boucler, À venir, Vide — jamais la couleur seule. Février en négatif (4'000 entré − 5'200 sorti = −1'200) |
| `adr028-320-annee.png` | Année à 320 px : barres bornées à leur cadre, aucun débordement |
| `adr028-390-abonnements.png` | Abonnements : coût annuel réel, moyenne mensuelle nommée, répartition mensuels/annuels séparée, tri du plus coûteux au moins coûteux, rythme et échéance écrits sur chaque ligne |
| `adr028-320-abonnements.png` | Abonnements à 320 px |
| `adr028-320-annee-texte-200.png` | Année à 200 % de texte sur 320 px : aucune fonction perdue, aucune troncature |
| `adr028-320-abonnements-texte-200.png` | Abonnements à 200 % de texte sur 320 px — le cas le plus contraint de l'app |

## La règle des charges annuelles, vérifiée par test

Un abonnement annuel est engagé **uniquement sur son mois d'échéance**.
Jamais lissé sur douze mois : l'app n'affiche pas un prélèvement qui
n'existe pas.

Avec un mensuel de 100 et un annuel de 1'200 dû en mars :

| Mesure | Attendu | Pourquoi |
| --- | --- | --- |
| Charges engagées en mars | **1'300** | le mensuel plus l'annuel |
| Charges engagées en avril | **100** | le mensuel seul |
| Somme des douze mois | **2'400** | 1'200 × 1 + 100 × 12 — et non 15'600 |

La règle vaut partout où une récurrence pèse, pas seulement dans l'argent
disponible : obligations du mois, rituel de bouclage, revenus attendus.

## Le défaut que les tests ont réellement attrapé

La première passe n'avait adapté que `snapshot()`. Les suites ont révélé deux
oublis qui auraient été graves en usage réel :

- `monthlyObligations()` — un abonnement annuel apparaissait « en retard »
  onze mois sur douze dans le widget de l'accueil ;
- `monthCheckItems()` — il restait éternellement à cocher, ce qui rendait le
  mois **impossible à boucler**.

Les deux sont corrigés et couverts par le parcours 89, qui vérifie
explicitement rituel et obligations sur le mois d'échéance **et** sur un
autre mois.

## Compatibilité et refus

Les trois champs (`every`, `dueM`, `endedOn`) sont **additifs**. Absents, ils
valent mensuel et actif : le sens des sauvegardes antérieures est strictement
préservé. En revanche, une valeur **présente mais illisible** fait REFUSER la
restauration au lieu d'être ramenée en silence à un défaut :

- rythme inconnu (autre que `month` / `year`) ;
- mois d'échéance annuelle hors 1-12 ;
- date de résiliation hors 2000-2100 ou incomplète.

Dans les trois cas, les données en place restent intactes.

## Inconsistance cosmétique connue, non corrigée

L'app mélange deux signes moins : le formateur canonique `money()` utilise le
trait d'union `-` (« -CHF 1'200.00 » sur la page Année), tandis que les
écrans de charges régulières préfixent le vrai signe moins `−` (« −CHF
89.00 »). L'écart préexiste à cette passe. Le corriger toucherait des
chaînes d'affichage déjà testées sur plusieurs écrans : il est consigné ici
plutôt que modifié au passage.
