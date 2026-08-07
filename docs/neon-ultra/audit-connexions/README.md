# Audit des connexions — une donnée saisie une fois (07.08.2026)

Demande du propriétaire : « je veux une application qui fonctionne comme un
seul système financier cohérent, et non comme plusieurs pages indépendantes ».

Cet audit lit le code, pas les écrans. Il répond à trois questions par
donnée : **qui l'écrit**, **qui la lit**, **y a-t-il deux vérités**.

---

## 1. Ce qui est DÉJÀ connecté (et qu'il ne faut pas casser)

Il faut le dire avant de critiquer : l'ossature est saine. Tout part d'une
seule collection, `transactions`, et deux fonctions dérivent tout le reste.

| Fonction | Rôle | Lue par |
|---|---|---|
| `snapshot(y, m)` | tous les totaux d'un mois | Mois, Budget, Année, Historique, Impôts, Assistant |
| `balance(compteId)` | solde d'un compte | Comptes, Patrimoine, héros, Objectifs |
| `taxSummary(année)` | impôts de l'année | Impôts **et** dashboard |
| `monthlyObligations(y, m)` | ce qui reste à payer | Mois, Factures |

Une facture mensuelle réglée crée **un vrai mouvement** lié
(`recurringId`), donc elle apparaît d'un coup dans l'Historique, dans le
solde du compte, dans le Budget de sa catégorie, dans l'Année et dans le
patrimoine. Ça, ça marche déjà.

---

## 2. Les quatre endroits où il y a DEUX vérités

### 2.1 Les impôts — trois systèmes parallèles ✗ GRAVE

C'est le défaut principal, et c'est exactement celui que vous avez pointé.

| Source | Nature | Qui l'écrit |
|---|---|---|
| `S.taxRate` | un **pourcentage** (30 %) | l'onboarding, puis « Changer le taux » |
| `S.taxReserve` | un **nombre tapé à la main** | « Changer ma réserve » |
| mouvements `taxPayment` | de **vrais paiements** | l'écran Mouvements |

`estimated = revenus de l'année × taux`, puis
`reserveGap = max(0, estimated − payé − S.taxReserve)`.

**Le problème est réel et mesurable** : `S.taxReserve` est un nombre déclaré,
**relié à rien**. Si vous mettez 2'500 CHF de côté par un vrai virement vers
un compte d'épargne, l'app ne le voit pas comme une provision d'impôts. Vous
devez le retaper dans « ma réserve ». C'est la double saisie que vous décrivez.

Et sur votre capture, la page affiche « déjà mis de côté 7'000 » à côté de
« reste à payer 4'550 » : deux chiffres qui ne viennent pas de la même
réalité.

### 2.2 Le 3e pilier / la prévoyance — deux vérités ✗ GRAVE

| Source | Nature |
|---|---|
| comptes de type `pension` | un solde, alimenté par de vrais virements |
| `PENSIONS[]` | des positions **saisies à la main** (valeur figée) |

Le patrimoine additionne les deux :
`net = … + pensionAccounts + pensionPositions + …`

**Rien n'empêche de compter deux fois le même argent.** Si vous créez un
compte « Pilier 3a » ET une position « 3a » dans Prévoyance, votre patrimoine
est faux, en votre faveur. C'est le pire sens pour une erreur.

Et votre cas : un versement mensuel de 500 CHF vers le 3e pilier alimente le
**solde du compte**, mais pas la **position** de la page Prévoyance. D'où
votre remarque : il faut ressaisir.

### 2.3 Les objectifs — deux vérités ⚠ MOYEN

Un objectif a `manualCurrent` (tapé) **et** `linked` (un compte). `goalCurrent()`
choisit l'un ou l'autre. Un objectif lié à un compte est juste et vivant ; un
objectif à saisie manuelle vieillit en silence dès le premier mois.

### 2.4 Facture / mis de côté — la distinction n'existe pas ✗ GRAVE

Aujourd'hui une charge régulière n'a que deux axes : `type` (revenu/dépense)
et, depuis hier, `family` (abonnement/charge du foyer). **Il n'existe aucun
moyen de dire « ce montant n'est pas une dépense, c'est de l'argent que je
réserve ».**

Conséquence directe et vérifiable : le 3e pilier saisi comme facture
mensuelle est compté comme une **dépense de vie**, ce qui viole l'invariant
du projet — « épargne et investissement ne sont pas des dépenses de vie » —
et fait mentir le Budget, le coût de la vie annuel et le « Disponible ».

---

## 3. Ce qu'il faut construire

### Une seule idée, appliquée partout

> Un mouvement d'argent a une **destination**, et c'est la destination qui
> décide de tout : dépense de vie, réserve pour impôts, prévoyance, objectif.

Concrètement :

1. **Ajouter un axe `destination` aux charges régulières** : `facture` (défaut)
   ou `réserve`. Une réserve n'est **jamais** une dépense de vie ; elle
   alimente une poche.
2. **La poche est un compte réel.** Réserver pour les impôts = virer vers un
   compte. Verser au 3e pilier = virer vers le compte 3a. Ce sont déjà des
   mouvements de type `saving` / `investment`, neutres pour le patrimoine et
   déjà exclus des dépenses de vie. **Toute la mécanique existe.**
3. **Supprimer `S.taxReserve`** comme source : la provision devient la somme
   réelle des mouvements affectés aux impôts. Le taux devient une simple
   **aide facultative** pour proposer un montant, plus le pilier du calcul.
4. **Supprimer le double compte prévoyance** : une position `PENSIONS` liée à
   un compte n'est plus additionnée, elle affiche le solde du compte.

### Ce que la page d'accueil pourra alors dire, sans rien compter deux fois

```
Dépensé              ce qui est vraiment parti (vie courante)
Mis de côté          total des réserves du mois
  · impôts           part affectée aux impôts
  · prévoyance       part versée au 3e pilier
  · objectifs        part affectée à un objectif
Disponible           ce qui reste, réserves déduites
```

---

## 4. Les textes trop longs

Trois défauts confirmés sur vos captures :

1. **Sous-titres redondants** : sur chaque ligne de facture,
   « Tous les mois · facture payée · Compte courant » répète une pastille déjà
   affichée juste au-dessus, et casse la ligne en laissant « courant » seul.
2. **Légendes sous les tuiles d'Impôts** : quatre phrases qui expliquent des
   chiffres qui se suffisent.
3. **La phrase sous « Disponible »** : utile une fois, du bruit ensuite.

Règle à appliquer : **un chiffre, un mot, une action**. L'explication va dans
un repli, jamais dans le flux principal.

---

## 5. Ordre d'exécution proposé

Chaque lot est autonome, testé, et n'invente aucune donnée.

| Lot | Contenu | Risque |
|---|---|---|
| **C1** | Axe `destination` (facture / réserve) sur les charges régulières, avec impact réel sur le Budget et le Disponible | moyen |
| **C2** | Impôts : la provision devient la somme des mouvements réels ; le taux redevient une suggestion | **élevé — touche un calcul financier** |
| **C3** | Prévoyance : fin du double compte, un versement mensuel alimente le total | **élevé — touche le patrimoine** |
| **C4** | Accueil : les cinq lignes ci-dessus, sans double compte | moyen |
| **C5** | Objectifs : lier au compte par défaut, la saisie manuelle devient l'exception | faible |
| **C6** | Allègement des textes, orphelins de fin de ligne, hiérarchie | faible |

C2 et C3 changent des **montants affichés**. Ils exigent des tests de
régression écrits avant le code, et une migration qui ne réécrit aucune
donnée existante.

---

## 6. Ce que cet audit ne dit pas encore

- Les **boutons sans effet** : `audit-total.mjs` en cherche déjà à chaque
  passe et n'en trouve aucun sur les seize écrans. Ça ne couvre pas les
  boutons qui agissent mais dont l'effet n'est pas répercuté ailleurs — c'est
  précisément ce que les lots C1–C5 corrigent.
- L'**app native iOS** suit la même architecture mais n'est pas encore
  auditée ligne à ligne sur ces points.
