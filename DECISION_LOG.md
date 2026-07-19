# Budget decision log

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

## ADR-005 — Mode démo sur container in-memory séparé

Date: 2026-07-19
Status: accepted

### Context

Le contrat interdit toute donnée démo dans le store de production.

### Decision

`AppContainer.isDemoMode` bascule l'app entière sur un `ModelContainer` in-memory peuplé par `DemoDataFactory` ; bannière visible en permanence ; retour aux vraies données en quittant le mode.

### Consequences

Isolation totale ; l'interface est reconstruite au changement de mode (`.id(isDemoMode)`).
