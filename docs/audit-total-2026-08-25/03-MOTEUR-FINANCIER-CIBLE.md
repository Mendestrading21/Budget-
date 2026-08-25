# 03 — Moteur financier cible

## 1. Objectif

Construire un noyau qui rende impossibles les erreurs les plus coûteuses :
argent prévu compté comme réel, double salaire, facture confirmée deux fois,
transfert compté comme dépense, devise étrangère additionnée comme CHF,
suppression silencieuse, import répliqué, occurrence couverte par le mauvais
paiement et patrimoine doublement compté.

Le moteur peut utiliser une comptabilité interne rigoureuse sans exposer sa
complexité à l'utilisateur.

## 2. Invariants non négociables

### INV-01 — Le prévu ne modifie jamais un solde réel

Une série, une échéance ou une projection n'écrit aucun posting réel.

### INV-02 — Tout solde provient d'écritures comptabilisées

`balance(account, at)` est dérivé des postings comptabilisés et d'un point de
rapprochement éventuel, jamais d'une prévision.

### INV-03 — Toute écriture est équilibrée par devise

Pour chaque `JournalEntry`, la somme des postings dans une devise est nulle.

### INV-04 — Un transfert est atomique et neutre

Il ne peut exister avec un seul côté et ne crée ni revenu ni coût de la vie.

### INV-05 — Une occurrence possède une identité stable

Clé unique recommandée : `seriesID + dueLocalDate + sequence + seriesRevision`.
Une occurrence déplacée conserve son UUID et trace son ancienne date.

### INV-06 — Confirmer est idempotent

Deux pressions, retries ou webhooks avec la même clé ne créent qu'une écriture.

### INV-07 — Une écriture comptabilisée n'est pas réécrite

Correction par inversion/remplacement lié.

### INV-08 — La devise n'est jamais implicite

Chaque montant porte une devise. Toute conversion porte taux, source et date.

### INV-09 — Le patrimoine a une source unique par valeur

Une position qui explique un compte ne s'ajoute pas au solde de ce compte.

### INV-10 — Les rapports sont des vues, pas des écritures

Budget, projection, mois et année ne mutent pas les mouvements.

### INV-11 — Les imports sont réessayables

Un lot appliqué puis relancé ne duplique pas ses opérations.

### INV-12 — Toute automatisation est explicable et annulable

L'app conserve la règle ou correspondance à l'origine de l'action.

## 3. Modèle Money

```text
Money
- minorUnits: Int64
- currency: ISO 4217
```

Pour une monnaie à deux décimales, CHF 12.35 devient 1235. La table ISO définit
l'exposant ; ne jamais supposer deux décimales partout.

Swift `Decimal` peut rester aux frontières UI/import et pour les taux. Le
journal en unités mineures évite les ambiguïtés.

### Conversion

```text
FxQuote
- id
- baseCurrency
- quoteCurrency
- rateDecimal
- observedAt
- source: manual | provider | statement
```

```text
ConvertedMoney
- originalMoney
- baseMoney
- fxQuoteID
```

Règles : taux historique conservé, valorisation datée, « valeur au… », et taux
manquant = inconnu, jamais zéro.

## 4. Journal et postings

### JournalEntry

```text
JournalEntry
- id: UUID
- kind: income | expense | transfer | saving | investmentCashFlow |
        debtPayment | refund | adjustment | valuation
- lifecycle: draft | pending | posted | cleared | reconciled |
             reversed | voided | failed
- effectiveDate: LocalDate
- postedAt: Instant?
- clearedAt: Instant?
- reconciledAt: Instant?
- title
- merchant
- note
- source: manual | recurring | csv | bankSync | migration | system
- sourceReference: String?
- idempotencyKey: String?
- occurrenceID: UUID?
- importBatchID: UUID?
- reversesEntryID: UUID?
- replacesEntryID: UUID?
- createdAt
- updatedAt
```

### Posting

```text
Posting
- id
- entryID
- accountID
- direction: debit | credit
- money
- baseMoney?
- categoryID?
- splitGroupID?
- memberID?
- tags[]
```

L'équilibre peut utiliser des comptes techniques invisibles :
`Income:Salary`, `Expense:Housing`, `Equity:OpeningBalance`,
`Valuation:UnrealizedGain`. L'interface conserve des catégories simples.

### Exemples

Salaire CHF 5'000 : posting compte courant + posting revenu salaire.

Loyer CHF 2'000 : posting dépense logement + posting compte courant.

Transfert courant → épargne CHF 1'000 : deux comptes d'actif, aucune dépense.

## 5. États et transitions

```text
draft
  ├─> pending
  ├─> posted
  └─> voided

pending
  ├─> posted
  ├─> failed
  └─> voided

posted
  ├─> cleared
  ├─> reversed
  └─> replacement lié

cleared
  ├─> reconciled
  └─> reversed

reconciled
  └─> reversal + nouvelle écriture, jamais mutation
```

| Interne | Visible |
|---|---|
| draft/scheduled | Prévu |
| pending | En attente |
| posted | Reçu / Payé |
| cleared | Pointé |
| reconciled | Rapproché |
| reversed | Annulé |
| failed | Échec |

## 6. Série et occurrence

### ScheduledSeries

```text
ScheduledSeries
- id
- title
- kind
- recurrenceRule
- timezone
- businessDayPolicy
- startDate
- endDate?
- expectedAmountMode: fixed | range | lastKnown | variable
- expectedAmount?
- minAmount?
- maxAmount?
- sourceAccountID?
- destinationAccountID?
- categoryID?
- tags[]
- memberID?
- active
- subscriptionMetadata?
- revision
```

### ScheduledOccurrence

```text
ScheduledOccurrence
- id
- seriesID?
- seriesRevision
- dueDate
- originalDueDate?
- expectedMoney?
- state: scheduled | due | matchProposed | confirmed |
         skipped | snoozed | cancelled | failed
- matchedEntryID?
- confirmedAt?
- skippedReason?
- idempotencyKey
- createdAt
- updatedAt
```

Une facture ponctuelle est une occurrence sans série.

Le système matérialise une fenêtre d'occurrences. La génération est idempotente
par contrainte unique.

Édition : cette occurrence, celle-ci et les suivantes, ou toute la série. Les
occurrences confirmées ne sont jamais réinterprétées.

## 7. Confirmation Reçu / Payé

```text
ConfirmOccurrence
- occurrenceID
- actualMoney
- actualDate
- sourceAccountID
- destinationAccountID?
- categoryID?
- idempotencyKey
```

Transaction atomique :

1. vérifier occurrence ouverte ;
2. vérifier idempotence ;
3. créer l'écriture équilibrée ;
4. lier l'écriture ;
5. passer occurrence à `confirmed` ;
6. sauvegarder ;
7. rafraîchir ;
8. afficher undo.

Aucune étape ne réussit seule. Le montant attendu reste conservé si le réel est
différent.

Paiement en retard : `dueDate` reste attendu, `effectiveDate` est réel, les
rapports utilisent le réel et l'analyse du retard calcule l'écart.

## 8. Correspondance avec mouvements importés

### Candidats

Score déterministe : même compte, sens, devise, montant/tolérance, date dans une
fenêtre, marchand/titre et référence fournisseur.

### Décision

Score élevé = proposition, pas fusion silencieuse au lancement. Validation
utilisateur, occurrence liée à l'entrée existante, aucune nouvelle écriture.

### Pending → posted

Conserver provider transaction ID, pending transaction ID, relation de
remplacement, statut et historique. Une posted peut changer d'identifiant,
date, nom ou montant.

## 9. Soldes

### Solde comptable

```text
accountBalance(account, date) =
openingPosting + somme(postings comptabilisés jusqu'à date)
```

Le `openingBalance` devient une écriture d'ouverture, évitant deux sources de
vérité.

### Rapprochement

Un snapshot peut accélérer le calcul mais reste lié à un lot de relevé et à ses
opérations.

### Disponible

```text
availableNow =
somme(comptes includeInAvailableCash convertis)
- réserves réellement verrouillées
```

Une simple catégorie Impôts ne retire pas l'argent d'un compte.

### Prévision fin de mois

```text
forecastEnd =
availableNow
+ revenus ouverts
- dépenses ouvertes
- sorties d'affectation des comptes disponibles
+ entrées d'affectation vers comptes disponibles
```

Afficher une plage pour montants variables.

## 10. Budget

```text
BudgetLine
- period
- categoryID
- plannedMoney
- rolloverPolicy: none | positive | full
- targetMode: spend | setAside | refill
```

Les dépenses viennent des splits analytiques des écritures comptabilisées.

Un remboursement peut réduire une dépense, être un revenu ou être lié à une
opération d'origine ; le choix est explicite.

## 11. Catégories, tags et splits

### Category

Nom localisé par défaut, kind universel, parent, active/archive, ordre.

### Tag

Libre, utilisable par règles et rapports.

### Split

```text
SplitLine
- transactionID
- categoryID
- money
- tags[]
- note?
```

Invariant : somme des splits = montant analytique de l'écriture.

## 12. Règles

```text
Rule
- id
- priority
- enabled
- conditions[]
- actions[]
- stopProcessing
- createdAt
- updatedAt
```

Conditions : compte, marchand, texte, montant/plage, devise, direction, source.

Actions : renommer, catégoriser, taguer, ventiler, masquer des rapports,
marquer à vérifier, proposer une occurrence.

Sécurité : preview, compteur, pas d'exécution rétroactive sans confirmation,
journal de version et aucune création réelle à partir d'une prévision seule.

## 13. Investissements

Séparer :

1. cash ledger : versements, retraits, dividendes, intérêts, frais, impôts ;
2. positions : quantité, instrument, coût ;
3. valuation : prix et taux à date.

```text
gain réalisé = produit vente - coût vendu - frais
revenu encaissé = dividendes + intérêts + coupons
variation non réalisée = valeur de marché - coût restant
```

Ne jamais mélanger variation non réalisée et revenu mensuel.

Mode simple : le solde titres est valeur totale manuelle, les positions
l'expliquent, l'app montre le non-réparti et ne promet pas un rendement précis.

## 14. Modules régionaux

Impôts : estimation, échéance, paiement, argent affecté et arriéré sont des
concepts différents.

Assurance : prime = obligation ; contrat = métadonnée ; valeur assurée n'entre
pas automatiquement au patrimoine.

Prévoyance : capital, contribution, projection documentée et rente ne sont pas
additionnés comme capitaux interchangeables.

## 15. Migration progressive

### A — Contrats canoniques

Fixtures JSON pour chaque invariant.

### B — Shadow ledger

Toute transaction actuelle crée aussi une entrée shadow, non affichée.

### C — Comparateur

Comparer compte, mois, année, patrimoine, transfert, épargne et dette.

### D — Migration historique

Transformer les données avec dry-run et rapport.

### E — Lecture par nouveau moteur

Basculer une vue à la fois derrière feature flag.

### F — Suppression de l'ancien chemin

Seulement après égalité prouvée ou différences approuvées, backup et rollback.

## 16. Exemples d'acceptation

### Salaire prévu

Série CHF 5'000 le 25, aujourd'hui 20, solde CHF 1'000 : écran réel 1'000,
prévu +5'000, projection 6'000, aucun posting salaire.

### Double tap

Deux commandes avec même clé : une seule écriture et même réponse au retry.

### Transfert

Courant 2'000, épargne 5'000, transfert 500 : soldes 1'500/5'500, patrimoine et
dépenses inchangés.

### Devise

CHF 1'000 + EUR 1'000 sans taux : patrimoine incomplet, jamais CHF 2'000. Avec
taux 0.95 daté : CHF 1'950, source/date visibles.

### Correction

Dépense rapprochée 100, réel 90 : ancienne entrée, inversion 100, nouvelle 90,
net −90 et trace visible.

### Série modifiée

Loyer 1'500 jusqu'en juin, 1'600 dès juillet : juin confirmé reste 1'500,
juillet attendu 1'600, aucun historique réécrit.
