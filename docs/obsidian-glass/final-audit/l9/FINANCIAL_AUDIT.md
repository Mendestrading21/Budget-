# L9 — Audit d'intégrité financière et des données (25.07.2026)

Chaque invariant est rattaché à sa preuve automatique NOMMÉE (exécutée
par la CI canonique à chaque poussée) ou explicitement marqué comme trou.
Aucune règle n'a été modifiée pendant l'audit.

## Invariants financiers → preuves nommées

| Invariant | Preuve native (BudgetTests) | Preuve PWA (e2e/parité) |
|---|---|---|
| `Decimal` de bout en bout, jamais `Double` pour l'argent | grep audité : zéro `Double` monétaire (seuls usages : `ProgressView`, jours, RGB) ; `WealthProjectionService` documente la règle | moteur centimes : « precision centimes » (test 30) ; parité 5 fixtures web↔natif |
| Format fr-CH (CHF 1'234.50, dd.MM.yyyy) | `FinanceFormattingTests` (8 tests : conventions suisses, 2 décimales, signes, dates, parsing, arrondi centimes, ratio sûr) | « identite obsidian » + assertions chf() dans toute la suite |
| Planifié ≠ comptabilisé | `MonthlySnapshotServiceTests.testPlannedMovementsStaySeparateFromActuals` ; `testPostedFutureDateFails` / `testPlannedFutureDateIsAllowed` (validation) | « creation mouvement » (statut), « mois L3 structure » |
| Épargne/investissement hors dépenses de vie | `MonthlySnapshotServiceTests.testTotalsSeparateLivingCostsFromSavingsAndTaxes` ; `testRefundsReduceLivingExpenses` | « epargne » (test 4) : l'épargne ne gonfle jamais « Dépensé » |
| Virement interne neutre (revenu, dépense, taux d'épargne, cash-flow, patrimoine) | `MonthlySnapshotServiceTests.testInternalTransferIsNeutralForAllHouseholdMetrics` + `testTransferStillMovesAccountBalances` ; `NetWorthServiceTests.testInternalTransferLeavesFullNetWorthUnchanged` | parité fixture « virement neutre » ; « cumuls » |
| Remboursement de capital ≠ dépense ; intérêts/frais séparés ; cash et dette bougent ensemble | `DebtPaymentTests` (6 tests : validation destination, effets signés, neutralité de fortune, partiel, trop-payé, sans destination) — ADR-016 | « dette vivante » (mensualité → décrément) |
| Patrimoine = actifs − dettes ; une dette positive est SOUSTRAITE | `NetWorthServiceTests.testBreakdownComponentsSumToNetWorth`, `testPositiveLiabilityIsSubtractedNeverAdded`, `testDebtAccountCountsOnceThroughAccounts`, `testExcludedItemsStayOut` | « patrimoine+prévoyance L6 » (décomposition affichée) |
| Aucune addition de devises sans conversion explicite | V1 native STRICTEMENT mono-CHF (ADR-017) : `UnifiedTaxReserveTests.testRestoreRefusesNonCHFAccounts` (garde à l'entrée, store intact) | « devise de référence », « annuler devise » (web multi-devise à taux manuels historisés) |
| Un taux actuel ne réécrit JAMAIS l'historique | non applicable nativement (mono-CHF V1) | « change historique fige » (test 33), « migration estampille l'historique », « édition ré-estampille », « édition change de devise », « destAmount jamais périmé » (tests 34-37) |
| Zéro NaN/infini/coercition silencieuse vers zéro | `BackupServiceTests.testRestoreRejectsCorruptAmountWithoutCoercingToZero`, `testRestoreRejectsCorruptOptionalAmount`, `testRestoreRejectsCorruptAmountInLateEntity` ; `FinanceFormattingTests.testParseAmountRejectsMalformedInput`, `testSafeRatioNeverDividesByZero` ; `MonthlySnapshotServiceTests.testZeroIncomeGivesZeroSavingsRateWithoutCrash` | « échelle de courbe L8 » (test 64 : coordonnées finies sur constantes, extrêmes ±10¹²) ; « sauvegarde restaurée normalisée » |
| Erreur de persistance TOUJOURS visible | grep audité : **zéro** `try? modelContext.save()` dans l'app ; 7 usages de `saveOrRollback(onError:)` (ADR-016) | `saveState()` : échec localStorage → toast explicite « Stockage indisponible… » |
| Import idempotent + doublons détectés + rejets visibles | `CSVImportServiceTests` (14 tests : `testReimportCreatesZeroDuplicates`, `testDuplicateRowsInsideTheSameFileAreCaughtOnce`, `testEveryRejectedRowIsVisibleWithItsReason`, `testFingerprintIsStable`, `testRollbackRemovesOnlyTheBatch`, compteurs réconciliés) | « import L7 » (test 61 : mapping, compte OBLIGATOIRE, aperçu, idempotence, rollback) |
| Une seule vérité fiscale (accueil = module) | `UnifiedTaxReserveTests` (8 tests, ADR-018 : `testDashboardAndTaxesModuleAgree`, réserve annuelle, arriérés, année isolée) ; `TaxServiceTests` (13) | « objectifs+impôts L6 » |
| Réconciliation disponible / composantes | `MonthlySnapshotServiceTests.testAvailableBreakdownReconciles` | « accueil essentiel », « mois blueprint » |
| Aucune donnée personnelle réelle dans tests/captures/logs | fixtures fictives déterministes (`DemoDataFactory`, « Elio + Sara ») ; grep : zéro `print`/`NSLog`/`os_log` applicatif | onboarding e2e fictif ; captures inspectées |

## Validation sur store disque (exigence L9)

- **Création puis relance** : le VRAI conteneur disque
  (`PersistenceFactory.makeProductionContainer()`,
  `isStoredInMemoryOnly: false`) est construit par `AppContainer()` à
  CHAQUE lancement de la vraie app — y compris sous `-demoTour` : le
  store de production est ouvert d'abord, le mode démo bascule ENSUITE
  sur un conteneur in-memory séparé (`BudgetApp.swift`). Le workflow
  Demo lance l'app plusieurs fois dans le même simulateur (tour
  principal, tour onboarding/confiance, preuve de sélection) : le store
  disque est créé au premier lancement puis ROUVERT aux lancements
  suivants. C'est exactement ce chemin qui avait attrapé le SIGABRT du
  plan de migration étagé (ADR-015) — la garde fonctionne.
- **Migration depuis chaque schéma réellement livré** : AUCUN store
  n'a jamais été distribué (pas de TestFlight, pas d'App Store — le
  pipeline existe mais n'a jamais tourné). Le seul format réel est V8
  créé par l'app actuelle. Les changements V1→V8 sont strictement
  additifs ; la migration légère AUTOMATIQUE de SwiftData les couvre
  (ADR-015). Le plan étagé a été retiré parce qu'il PLANTAIT (empreintes
  identiques) ; il ne reviendra qu'au premier changement rupteur
  post-publication, avec des instantanés de modèles gelés.
- **Sauvegarde/restauration dans un store isolé** :
  `BackupServiceTests.testBackupRestoreRoundTripPreservesEverything`
  (round-trip COMPLET des 18 modèles, comptages exhaustifs),
  `testRestoreReplacesExistingData`, `testRestoreNeverDeletesDocumentFiles`
  (ADR-014) — chaque test sur son conteneur isolé neuf.
- **Restauration invalide/corrompue/version future refusée
  ATOMIQUEMENT, données intactes** : `testRestoreRejectsNewerSchema`,
  `testRestoreRejectsCorruptData`, `testRestoreRejectsCorruptAmount*`
  (× 3, y compris une entité TARDIVE — preuve qu'aucune écriture
  partielle ne survit : purge + insertions partagent UNE transaction,
  échec → `rollback()`, ADR-014) ; devise non supportée :
  `testRestoreRefusesNonCHFAccounts` (ADR-017). Côté PWA :
  « restauration validée » (schéma inconnu/montant invalide → REFUS,
  état intact) et « sauvegarde restaurée normalisée ».
- **Suppression totale** : `testDeleteAllEmptiesEveryEntityAndDocumentFiles`
  (fichiers effacés APRÈS le commit de purge, jamais d'enregistrements
  survivants avec fichiers perdus) ; PWA « double suppression »
  (opérations vs réinitialisation complète, textes exacts).
- **Verrouillage** : `BackupServiceTests` (état verrouillé par défaut ?
  non — désactivé par défaut, activation exige une authentification
  RÉUSSIE, verrouillage en arrière-plan, survit à la relance) ; échec et
  annulation couverts (`testLocksOnBackgroundAndUnlocksOnlyOnSuccess`).

## Commandes canoniques exécutées (aucune inventée)

En local pour cet audit : `git diff --check` (OK), `node --check` sur
les trois suites (OK), 71 e2e + 5 parité + design system (verts, zéro
erreur console, temps PERF L8 réels loggés). En CI à chaque poussée :
les trois suites web (Chromium réel), `plutil -lint
Budget/PrivacyInfo.xcprivacy`, build Debug, **258 tests** (0 échec
attendu), build Release, présence + validité de `PrivacyInfo.xcprivacy`
DANS `Budget.app` Release ; puis workflow Demo complet sur simulateur.

## Trous connus et assumés (pas de dissimulation)

1. La migration V1→V8 sur un store RÉEL d'utilisateur n'existe pas
   encore comme scénario : aucun utilisateur, aucun store distribué.
   Elle est couverte par le runtime Apple (migration légère) et par le
   boot disque du Demo à chaque run. Risque résiduel : FAIBLE, réévalué
   au premier changement de schéma post-publication.
2. Les tests unitaires natifs tournent sur des conteneurs in-memory
   (voulu : isolation) ; le chemin disque est couvert par le lancement
   réel de l'app (Demo) et non par un test unitaire dédié. Risque
   résiduel : FAIBLE (le chemin qui a réellement cassé une fois — plan
   étagé — est précisément celui que le Demo exerce à chaque run).
3. Le contrôle du format d'une sauvegarde PWA restaurée dans l'app
   NATIVE (et inversement) n'est pas un parcours produit : les deux
   plateformes ont des formats distincts et honnêtes — documenté dans
   l'écran Confidentialité. Aucune promesse croisée.
