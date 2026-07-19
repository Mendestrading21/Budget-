# Budget decision log

## ADR-007 — Récurrents : entité unique, occurrences par multiples d'ancre, schéma V3

Date: 2026-07-19
Status: accepted

### Context

La Phase 6 introduit charges récurrentes et abonnements, avec prévisions mensuelles qui ne doivent jamais dupliquer les mouvements réels.

### Decision

- Une seule entité `RecurringTransaction` couvre charges, revenus, contributions ET abonnements (`isSubscription` + renouvellement/résiliation), plutôt que deux entités quasi identiques.
- Rythme = (unité semaine/mois/année, intervalle N) : mensuel (mois,1), trimestriel (mois,3), annuel (année,1), personnalisé libre.
- La k-ième occurrence = `firstOccurrence + k·intervalle` (multiples de l'ancre, jamais d'addition incrémentale) : 31 janv → 28 févr → **31** mars, sans dérive ; 29 févr bissextile → 28 févr les années communes.
- Dédup prévision/réel par `BudgetTransaction.recurringID` : N mouvements liés dans le mois couvrent les N premières occurrences (couverture chronologique par comptage, tolérante aux jours décalés — un salaire versé le 24 couvre l'échéance du 25).
- Schéma V3 (3.0.0) : + `RecurringTransaction`, + `recurringID` optionnel sur `BudgetTransaction` ; migrations légères V1→V2→V3 (changements purement additifs).
- Le disponible intègre deux composantes visibles de plus : revenus récurrents à venir et charges récurrentes à venir ; les virements récurrents restent neutres.

### Alternatives considered

- Entité `Subscription` séparée : duplication de champs sans bénéfice V1.
- Dédup par date exacte : casse dès qu'un salaire tombe un jour plus tôt.

### Consequences

Toute occurrence comptabilisée doit passer par `makeTransaction(from:on:now:)` (ou poser `recurringID`) pour sortir des prévisions.

### Verification

`RecurringScheduleServiceTests` : bornes de mois, bissextiles, trimestriel/annuel/hebdo/personnalisé, dédup partielle, neutralité des virements, intégration snapshot.

## ADR-001 — Projet Xcode manuscrit au format « synchronized groups » (Xcode 16)

Date: 2026-07-19
Status: accepted

### Context

Le projet est bootstrappé depuis un environnement Linux sans Xcode. Il faut un `.xcodeproj` ouvrable directement sur Mac.

### Decision

Écrire `project.pbxproj` à la main en `objectVersion = 77` avec des `PBXFileSystemSynchronizedRootGroup` (`Budget/`, `BudgetTests/`) : les fichiers ajoutés sur disque rejoignent automatiquement les cibles, sans listes de fichiers fragiles dans le pbxproj.

### Alternatives considered

- XcodeGen/Tuist : dépendance d'outillage externe, contraire à l'esprit « aucune dépendance » du contrat V1.
- pbxproj classique (objectVersion 56) : chaque fichier devrait être référencé manuellement, très sujet aux erreurs hors Xcode.

### Consequences

Xcode 16+ requis. Aucune maintenance de liste de fichiers.

### Verification

Ouvrir le projet sur Mac ; compiler l'app et les tests.

## ADR-002 — Enums persistés en rawValue String

Date: 2026-07-19
Status: accepted

### Context

SwiftData sait persister des enums Codable, mais les prédicats et migrations sur enums restent fragiles.

### Decision

Persister `typeRawValue`/`statusRawValue`/etc. en `String` avec propriétés calculées typées (`type`, `status`, …). Les valeurs inconnues retombent sur un cas sûr.

### Consequences

Prédicats simples et migrations robustes ; discipline nécessaire pour passer par les propriétés typées.

## ADR-003 — Taux de provision fiscale sur Household jusqu'à la Phase 7

Date: 2026-07-19
Status: accepted

### Context

L'onboarding (Phase 1) et le dashboard (Phase 4) ont besoin du taux de provision (défaut 30 %), mais l'entité TaxProfile complète n'arrive qu'en Phase 7.

### Decision

Stocker `taxProvisionRate: Decimal` sur `Household` avec défaut `0.30`. Migration vers `TaxProfile` planifiée en Phase 7 (nouvelle version de schéma + stage de migration).

### Consequences

Pas d'entité prématurée ; une migration à écrire en Phase 7.

## ADR-004 — Convention de montants positifs + direction par type

Date: 2026-07-19
Status: accepted

### Context

Le spec impose une convention unique, jamais mélangée.

### Decision

`BudgetTransaction.amount > 0` toujours ; la direction vient du `type` (income/refund entrants ; expense/saving/investment/transfer/taxPayment/debtPayment sortants). Seul `adjustment` porte un drapeau explicite `adjustmentIncreasesBalance`. Les virements et contributions internes (saving/investment avec `destinationAccount`) créditent la destination — un seul enregistrement, effet atomique, jamais dupliqué en revenu+dépense.

### Consequences

Les invariants (neutralité des virements, patrimoine) se testent sur une seule source de vérité : `AccountBalanceService.signedEffect`.

## ADR-006 — Schéma V2 : budgets mensuels, migration légère

Date: 2026-07-19
Status: accepted

### Context

La Phase 5 introduit `MonthlyBudget` et `BudgetLine`. Les stores V1 existants (phases 0-4) doivent migrer sans perte.

### Decision

`BudgetSchemaV2` (2.0.0) = modèles V1 + les deux nouveaux ; `MigrationStage.lightweight(fromVersion: V1, toVersion: V2)` car le changement est purement additif. L'unicité d'un budget par (année, mois) est garantie par `BudgetPlanningService.findOrCreate` — unique chemin de création — plutôt que par une contrainte composite SwiftData (non disponible). Le réel n'est jamais stocké sur une ligne : il dérive des transactions comptabilisées via `BudgetVarianceService`, et les montants hors budget sont exposés séparément pour que la réconciliation soit totale.

### Alternatives considered

- Contrainte `#Unique` composite : non supportée sur iOS 17.
- Stocker le réel sur la ligne : violerait la séparation planifié/réel.

### Consequences

Migration à valider sur un appareil contenant des données V1 ; toute création de budget passe par le service.

### Verification

Tests `BudgetPlanningServiceTests` (unicité, round-trip V2, cascade) ; test manuel de migration sur simulateur avec store V1 existant.

## ADR-005 — Mode démo sur container in-memory séparé

Date: 2026-07-19
Status: accepted

### Context

Le contrat interdit toute donnée démo dans le store de production.

### Decision

`AppContainer.isDemoMode` bascule l'app entière sur un `ModelContainer` in-memory peuplé par `DemoDataFactory` ; bannière visible en permanence ; retour aux vraies données en quittant le mode.

### Consequences

Isolation totale ; l'interface est reconstruite au changement de mode (`.id(isDemoMode)`).
