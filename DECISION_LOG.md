# Budget decision log

## ADR-011 — Patrimoine : dettes positives soustraites, instantané quotidien

Date: 2026-07-19
Status: accepted

### Context

Phase 10. Les comptes de dette (carte, hypothèque tenue en compte) portent déjà un solde négatif ; il faut des dettes autonomes sans jamais double-compter, et une tendance historique.

### Decision

- Schéma V7 : `Asset`, `Liability` (montant TOUJOURS stocké positif, soustrait par le service — jamais de double négatif), `NetWorthSnapshot` (composantes figées).
- `NetWorthService.breakdown` : `net = comptes inclus actifs (convention signée existante) + actifs inclus + prévoyance active − dettes incluses`. Une dette portée par un compte reste sur ce compte (le formulaire le rappelle) ; les Liability couvrent les dettes hors comptes (leasing, dette fiscale…).
- Tendance : au plus UN instantané par jour calendaire, enregistré à l'ouverture de l'écran Patrimoine ; composantes figées pour que l'historique survive aux changements ultérieurs.
- `MonthSnapshot.netWorth` (comptes seuls) reste inchangé : le patrimoine complet vit dans NetWorthService ; le dashboard mensuel n'affiche pas de fortune totale.

### Consequences

La distinction contribution/variation de valeur (spec) attendra des données réelles multi-instantanés ; V1 montre la courbe totale.

### Verification

`NetWorthServiceTests` : réconciliation, signes, non-double-comptage des comptes de dette, toggles, neutralité des virements sur le patrimoine complet, unicité quotidienne des instantanés, tri de tendance, round-trip V7.

## ADR-010 — Assurances/prévoyance : prime au rythme réel, projections jamais inventées

Date: 2026-07-19
Status: accepted

### Context

Phase 9. Les primes suisses se paient à des rythmes variés (LAMal mensuelle, RC annuelle) et la prévoyance vient de relevés officiels.

### Decision

- Schéma V6 : `InsuranceContract` (prime stockée à son rythme réel via RecurrenceUnit + intervalle ; équivalents annuel/mensuel DÉRIVÉS par `InsurancePensionService` avec les mêmes formules que les récurrents → réconciliation garantie, le total mensuel dérive du total annuel) et `PensionAsset` (piliers 1/2/3a/3b, valeurs recopiées des certificats).
- L'app n'invente aucune croissance : la « projection à la retraite » est celle imprimée sur le certificat de l'institution, étiquetée comme hypothèse ; la somme des projections n'est affichée que si CHAQUE position en a une (une somme partielle serait trompeuse).
- Délais de résiliation surveillés à 60 jours (les résiliations d'assurance demandent plus d'anticipation que les abonnements à 30 j).
- Pas de comparaison commerciale d'assurances en V1 (contrat produit).

### Consequences

`documentReference` reste un champ libre jusqu'au module Documents (Phase 11).

### Verification

`InsurancePensionServiceTests` : équivalents mensuel/trimestriel/annuel, totaux ménage réconciliés, tri des délais, totaux par pilier = total général, refus de somme partielle, round-trip V6.

## ADR-009 — Objectifs : valeur courante exclusive, contributions non soustraites du disponible

Date: 2026-07-19
Status: accepted

### Context

Phase 8. La valeur courante d'un objectif peut venir d'un compte lié ou d'un suivi manuel ; et la formule « disponible » du spec mentionne « − contributions d'objectifs engagées ».

### Decision

- Schéma V5 : `FinancialGoal` (type, cible, date, compte lié OU montant manuel — jamais les deux, le formulaire remet le manuel à zéro quand un compte est lié ; contribution prévue, priorité, statut).
- Projections dérivées, jamais stockées : progrès borné [0,1] (cible ≤ 0 = atteint, sans division), mois restants comptés en jours entiers (un mois entamé compte), contribution requise = restant / mois (tout dû immédiatement si échéance passée ou dernier mois), statut En bonne voie/À accélérer selon prévu vs requis, projection par division plafond.
- Les contributions d'objectifs ne sont PAS soustraites du « vraiment disponible » : l'épargne planifiée est déjà modélisée par les récurrents (type saving/investment) — la soustraire une seconde fois via les objectifs double-compterait. Les objectifs mesurent le progrès, les récurrents engagent le cash.
- Célébration sobre : badge « Atteint » + coche, pas d'animation tapageuse (design system).

### Consequences

Un objectif alimenté par un récurrent lié au même compte se met à jour tout seul ; déviation documentée de la formule du spec (composant objectifs = 0 en V1).

### Verification

`GoalProjectionServiceTests` : bords sûrs, mois restants, requis vs prévu, division plafond, round-trip V5.

## ADR-008 — Impôts : profil paresseux, états dérivés, schéma V4

Date: 2026-07-19
Status: accepted

### Context

La Phase 7 doit distinguer recommandé / réservé / payé / encore dû / arriérés avec des états qui se réconcilient toujours, et solder l'ADR-003 (taux sur Household).

### Decision

- Schéma V4 : `TaxProfile` (localisation + taux, source de vérité) et `TaxProvision` par année (override d'estimation, réserve, arriérés, échéances `[TaxDueDate]` Codable). Migration légère, purement additive.
- Pas de stage de migration custom : `TaxService.ensureProfile` crée le profil **paresseusement** en le semant depuis `Household.taxProvisionRate` — couvre stores migrés ET installations neuves par le même chemin ; le champ Household devient un simple seed conservé cohérent quand le taux change.
- Payé et encore dû ne sont JAMAIS stockés : dérivés des mouvements `taxPayment` comptabilisés de l'année → `estimé = payé + encore dû` par construction ; `écart de réserve = max(0, encore dû + arriérés − réserve)`.
- Hypothèses visibles à l'écran (taux, revenus, base de calcul) + avertissement explicite « estimation d'organisation, pas un décompte officiel ».

### Alternatives considered

- Stage `MigrationStage.custom` copiant le taux : fragile avec le pattern de classes partagées et redondant avec la création paresseuse.
- Stocker paid/outstanding sur la provision : casse la réconciliation à la première divergence.

### Consequences

Un seul profil par store (garanti par ensureProfile) ; une provision par (profil, année) (garantie par ensureProvision).

### Verification

`TaxServiceTests` : réconciliation estimé/payé/dû, override, bornes d'années, écart de réserve avec arriérés, unicité, échéances, priorité du taux profil dans le snapshot, round-trip V4.

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
