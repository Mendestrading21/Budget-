# Data Model Target

Ce document décrit le contrat cible. Il ne prescrit pas une migration massive
ni les noms Swift/TypeScript finaux.

## Money

```text
Money { minorUnits: Int64, currency: CurrencyCode }
FxQuote { base, quote, rateDecimal, observedAt, source }
ConvertedMoney { original, base, fxQuoteID }
```

## Account

```text
Account
- id
- name
- institutionName?
- type: cash | checking | savings | creditCard | loan | brokerage |
        pension | wallet | otherAsset | otherLiability
- currency
- active
- includeInAvailableCash
- includeInNetWorth
- owner/member
- openedAt?
- closedAt?
```

Le solde d'ouverture vit dans le journal.

## Journal

```text
JournalEntry
- id
- kind
- lifecycle
- effectiveDate
- postedAt?
- clearedAt?
- reconciledAt?
- title/merchant/note
- source/sourceReference
- idempotencyKey?
- occurrenceID?
- importBatchID?
- reversesEntryID?
- replacesEntryID?
- timestamps

Posting
- id
- entryID
- accountID ou compte analytique
- debit/credit
- Money
- ConvertedMoney?
- categoryID?
- splitGroupID?
- memberID?
- tags[]
```

Contraintes : équilibre par devise, idempotency key unique dans son scope,
relations valides, entry rapprochée non mutable.

## Planning

```text
ScheduledSeries
- id
- title/kind
- recurrenceRule/timezone/businessDayPolicy
- start/end
- expectedAmountMode et montant/plage
- source/destination/category/tags/member
- subscription metadata
- active/revision

ScheduledOccurrence
- id
- seriesID?
- seriesRevision
- dueDate/originalDueDate
- expectedMoney?
- state
- matchedEntryID?
- confirmedAt?
- idempotencyKey
- timestamps
```

Une facture ponctuelle est une occurrence sans série.

## Analysis

```text
Category { id, kind, parentID?, names localized, active, order }
Tag { id, name, active }
SplitLine { id, entryID, categoryID, Money, tags, note? }
Rule { id, priority, enabled, conditions, actions, stopProcessing, version }
```

## Budget and goals

```text
BudgetPeriod { id, start, end, baseCurrency }
BudgetLine { categoryID, plannedMoney, rolloverPolicy, targetMode }
Goal { targetMoney, targetDate?, linkedAccountID?, status, priority }
GoalAllocation { goalID, entry/postingID, Money }
```

Un objectif avance par affectation réelle ou valeur manuelle explicitement
datée, jamais par projection seule.

## Reconciliation

```text
Statement
- id/accountID
- start/end
- opening/closing Money
- source/documentReference?
- state: draft | reconciled | reopened
- reconciledAt?

StatementMatch
- statementID
- entryID
- state
```

Terminer exige différence zéro ou ajustement explicite.

## Imports and providers

```text
ImportBatch
- id/source/fileHash/provider
- startedAt/appliedAt/rolledBackAt
- counters/state

SourceRecord
- stableProviderID?
- normalizedFingerprint
- rawReferenceHash
- pendingReference?
- proposedEntry
- verdict

BankConnection
- provider/institution/consent scope/expiry/state
- aucun secret dans le modèle synchronisable
```

## Investments

```text
Instrument { id, name, ticker?, isin?, currency }
PositionLot { accountID, instrumentID, quantity, costMoney, acquiredAt }
Valuation { instrument/account, priceMoney, date, source }
InvestmentIncome/Fee/Tax = écritures du journal
```

Mode simple autorisé : valeur totale manuelle datée ; les positions restent
explicatives et ne s'additionnent pas au compte.

## Regional modules

```text
RegionalProfile { region, enabledModules }
TaxEstimate/TaxObligation
InsuranceContract
PensionStatement
```

Chaque module traduit ses valeurs vers les concepts cœur sans créer de seconde
source de solde.

## Backup envelope

```text
BackupManifest
- formatVersion
- schemaVersion
- exportedAt
- appVersion
- locale/baseCurrency
- objectCounts
- encryption/kdf metadata
- checksum references
```

Données et pièces jointes chiffrées. Restore dans un store temporaire.

## Migration mapping depuis le modèle actuel

- `openingBalance` → posting d'ouverture ;
- `BudgetTransaction` → JournalEntry + postings ;
- `planned BudgetTransaction` → occurrence ou pending selon provenance ;
- `RecurringTransaction` → ScheduledSeries ;
- dates générées non confirmées → ScheduledOccurrence ;
- `recurringID` + date → tentative de lien, rapport des ambiguïtés ;
- `reconciledBalance/reconciledAt` → statement synthétique clairement marqué ;
- `BrokeragePosition` → valuation/position explicative ;
- `Asset/Liability/PensionAsset` → sources patrimoniales datées ;
- documents : métadonnées + fichier vérifié ;
- import fingerprints : conserver legacy et calculer normalized fingerprint.

Aucun objet ambigu n'est transformé silencieusement. Le dry-run produit :
créés, liés, ignorés, ambigus, invalides et différences de soldes.
