# Audit à cent pour cent — l'app est-elle simple pour quelqu'un de 15 ans ? (10.08.2026)

Demande du propriétaire : *« un audit cent pour cent complet… que tout soit
cohérent, bien affiché, logique, le plus simple possible à utiliser.
N'oublie pas que c'est des gens qui peuvent avoir quinze, seize, dix-sept ans
qui vont utiliser cette application. »*

Cet audit ne donne pas d'avis. Il **compte, mesure et compare**, avec des
outils reproductibles sur des données fictives. Un quatrième outil a été
écrit pour cette passe, parce que les trois existants ne mesuraient pas la
chose la plus importante ici : **la langue et l'architecture**.

| Outil | Ce qu'il mesure | Existait |
|---|---|---|
| `audit-total.mjs` | 16 écrans × 3 largeurs : alignement, rayons, contraste réel, cibles tactiles, boutons morts, débordement | oui |
| `audit-visuel.mjs` | pastilles non carrées, texte tronqué | oui |
| `audit-final.mjs` | présentation des émojis, émojis lus à voix haute, fidélité des graphiques | oui |
| **`audit-coherence.mjs`** | **vocabulaire, jargon, longueur des phrases, charge de texte, un sens = un emoji, doublons de menu, recouvrement entre écrans, coût réel de l'accueil** | **non — écrit pour cet audit** |

---

## 1. La bonne nouvelle : l'accueil ne pose pas cent cinquante questions

Le propriétaire craignait un questionnaire interminable. Mesure réelle :

```
6 écrans avant d'entrer dans l'app
1 seul champ vraiment obligatoire (le solde de départ)
3 écrans sur 6 sont passables d'un geste
12 à 53 mots par écran
```

| Écran | Champs | Mots | Passable |
|---|---|---|---|
| Pays et foyer | 0 (deux boutons) | 12 | — |
| Salaire | 2 | 53 | oui |
| Comptes | 1 | 36 | non |
| Charges | 5 | 42 | oui |
| Abonnements | 4 | 37 | oui |
| Objectif | 0 (trois boutons) | 44 | oui |

**Verdict : rien à corriger.** Quelqu'un de quinze ans entre dans l'app en
six gestes s'il le veut, et peut tout remplir plus tard.

---

## 2. Le vrai défaut : deux écrans montrent le même engagement

C'est le défaut le plus grave trouvé, et il est **mesuré, pas supposé** :

```
« Transactions mensuelles » : 3 lignes
« Abonnements »             : 3 lignes
partagées                   : 2 lignes
```

Le même abonnement Netflix apparaît **deux fois dans le menu Gérer**, sous
deux noms, dans le **même groupe « À organiser »**. Pour quelqu'un qui
découvre l'app, il faut choisir entre deux portes avant de savoir ce qu'il y a
derrière. Et depuis que la nature (*facture / abonnement / mise de côté*) est
un choix de la ligne elle-même, « Abonnements » n'est plus qu'un **filtre**
de « Transactions mensuelles » présenté comme une destination.

**Correction retenue** : un seul écran, avec des filtres. Voir §6.

---

## 3. Deux entrées de menu promettent la même chose

| Mot-clé | Promis par |
|---|---|
| « 3e pilier » | **Assurances & prévoyance** *et* **Objectifs** |
| « abonnement » | **Transactions mensuelles** *et* **Abonnements** |

Un sous-titre de menu est une promesse. Deux promesses identiques, c'est une
hésitation garantie à chaque fois.

---

## 4. Ce qui va déjà, et qu'il ne faut pas casser

Il faut le dire aussi clairement que les défauts.

- **Aucune phrase au-dessus de 28 mots** sur les 17 écrans. C'est le seuil
  au-delà duquel un lecteur de quinze ans décroche.
- **Aucun jargon** sur 20 termes surveillés (amortissement, lissage,
  cash-flow, prorata, idempotent…) — **sauf un**, voir §5.
- **Aucun synonyme concurrent** : l'app dit « mis de côté » partout, jamais
  « provision » ni « réserve d'argent » ; « disponible » partout, jamais
  « reste à vivre » ; « patrimoine » partout, jamais « actif net ».
- **Un sens = un emoji** sur les quatre concepts contrôlés.
- **Aucun écran doublon** au sens strict sur les 12 vues.
- **Console propre**, zéro erreur.
- Aux trois largeurs (320, 390, 430 px) : zéro débordement, zéro contraste
  sous le seuil AA, zéro cible sous 44 px, zéro bouton sans destination.

---

## 5. Défauts mineurs mesurés

| # | Défaut | Mesure | Gravité |
|---|---|---|---|
| A | « Abonnements » double « Transactions mensuelles » | 2 lignes sur 3 partagées | **P1** |
| B | « 3e pilier » promis par deux entrées de menu | 2 entrées | **P1** |
| C | L'écran Patrimoine se lit comme une notice | 221 mots (seuil 220) | P2 |
| D | Jargon « métadonnée » sur Import CSV | 1 occurrence | P2 |

Trois écrans frôlent le seuil sans le dépasser — Mois (220), Historique
(220), Année (211). Ils sont sous surveillance, pas en défaut.

---

## 6. Ce qui est corrigé dans cette passe

1. **Un seul écran pour tout ce qui revient chaque mois.** « Abonnements »
   cesse d'être une destination séparée et devient un **filtre** de
   « Transactions mensuelles » : *Tout · Factures · Abonnements · Mis de
   côté · Revenus*. Le récapitulatif du coût annuel des abonnements est
   conservé — il s'affiche quand le filtre correspondant est actif. Une
   destination de moins, et plus aucun engagement affiché deux fois.
2. **Chaque entrée de menu promet une seule chose.** Le 3e pilier vit dans
   « Assurances & prévoyance » ; « Objectifs » parle de projets d'épargne.
3. **Patrimoine allégé** sous le seuil de lecture.
4. **« Métadonnée » remplacé** par un mot que tout le monde comprend.

---

## Reproduire

```
export BUDGET_CHROMIUM=/chemin/vers/chrome
node .claude/skills/budget-neon-ultra/assets/tools/audit-coherence.mjs
for W in 320 390 430; do W=$W node .claude/skills/budget-neon-ultra/assets/tools/audit-total.mjs; done
node .claude/skills/budget-neon-ultra/assets/tools/audit-visuel.mjs
node .claude/skills/budget-neon-ultra/assets/tools/audit-final.mjs
(cd webapp/tests && node e2e.test.mjs && node design.test.mjs && node parity.test.mjs)
```

## Ce que cet audit NE dit pas

- **Rien n'a été vérifié sur un iPhone physique.** Tout est mesuré dans un
  Chromium réel à 320, 390 et 430 px.
- **L'app native iOS** est validée par la CI macOS, pas par un œil humain sur
  un appareil.
- **Aucune donnée réelle** n'a été utilisée, ni dans les tests, ni dans les
  captures, ni dans les journaux.
- Un outil qui ne trouve rien ne prouve pas qu'il n'y a rien : il prouve que
  **ce qu'il sait mesurer** est propre. Les seuils (28 mots, 220 mots, 20
  termes de jargon) sont écrits dans le code de l'outil et discutables.
