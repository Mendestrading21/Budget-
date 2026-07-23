# Budget decision log

## ADR-021 — L1 : montants historiques figés à la saisie, restauration refusant les montants corrompus

Date: 2026-07-23
Status: accepted

### Context

Audit L1 des cinq P0 Obsidian Glass. Deux étaient réellement présents dans le
code courant :

1. Natif : `BackupService.decimal(_:)` convertissait toute chaîne illisible en
   `.zero` (`Decimal(string:) ?? .zero`). Une sauvegarde corrompue pouvait donc
   restaurer silencieusement des montants à zéro — perte de données invisible.
2. PWA : `txCHF()` convertissait les mouvements en devise étrangère avec le taux
   ACTUEL (`S.fxRates`). Modifier un taux recalculait rétroactivement tout
   l'historique (coût de la vie, budgets, mois bouclés), en violation de
   l'invariant « les montants historiques ne changent jamais parce qu'un taux
   actuel a changé ».

### Decision

1. Natif : `decimal(_:)` devient `throws` et lève `BackupError.corruptAmount`
   avec le montant fautif ; la restauration transactionnelle (ADR-014) annule
   tout et laisse les données actuelles intactes. Aucune coercition vers zéro.
2. PWA : chaque mouvement en devise ≠ devise de base est estampillé À LA
   CRÉATION avec `fx` (taux du jour) et `fxBase` (devise de base au moment de
   la saisie) via le nouveau point d'entrée unique `addTx()` ; les virements
   inter-devises figent aussi `destAmount`. `txCHF()` et les lectures de crédit
   destination privilégient la valeur estampillée et ne retombent sur le taux
   actuel que pour l'historique antérieur non estampillé (comportement inchangé
   pour les données existantes, aucune migration destructive).
3. Ces champs (`fx`, `fxBase`, `destAmount`) sont additifs dans l'état v1 ; ils
   ne cassent ni les sauvegardes existantes ni les fixtures de parité.

### Verification

`BudgetTests/BackupServiceTests.testRestoreRejectsCorruptAmountWithoutCoercingToZero`
(sauvegarde altérée → erreur dédiée, store intact, zéro montant à zéro) ;
e2e Test 38 « changer un taux ne change pas l'historique » (mouvement EUR
estampillé, taux divisé par deux, coût de la vie inchangé à 0.005 près) ;
suites : 43 parcours e2e + 5 fixtures de parité verts.


## ADR-020 — Obsidian Glass : identité sombre unique et skill canonique

Date: 2026-07-23
Status: accepted

### Context

Le propriétaire valide la direction « Budget — Obsidian Glass » : une
application sombre, premium, simple, vivante et professionnelle, avec des
widgets transparents et une seule palette de marque. Les programmes précédents
ont laissé plusieurs skills et deux directions visuelles concurrentes
(Horizon clair/sombre et identité verre sombre).

### Decision

1. `/budget-v1` devient l'unique autorité opérationnelle pour Claude Code.
   Les autres skills Budget restent des archives et ne doivent plus être
   invoqués ou combinés.
2. Obsidian Glass utilise une seule identité sombre : fond `#090C12`, surfaces
   graphite translucides et accent Indigo Aurora `#7367FF`. Vert, corail et
   ambre restent strictement sémantiques.
3. Cette décision remplace uniquement la partie visuelle et multi-thème
   d'ADR-019. Les décisions financières d'ADR-019, notamment la parité dette,
   restent valides.
4. La refonte progresse par lots sur une branche dédiée. Le pilote porte sur
   Mois, Budget et Ajout d'un mouvement avant tout déploiement général.
5. PWA et iOS partagent les rôles, tokens, vocabulaire et invariants, sans
   obligation de copie pixel par pixel.
6. Un P0 de données, restauration, confidentialité ou publication confirmé
   bloque le lot visuel suivant jusqu'à correction et test.
7. Chaque lot produit tests, captures, mise à jour du statut et commit ciblé,
   puis s'arrête pour revue.

### Consequences

Le sélecteur de thème et l'ancien rendu ne sont pas supprimés pendant L0. Leur
migration contrôlée appartient aux lots de fondation et de pilote. Aucune
logique financière, donnée, route, migration ou persistance n'est modifiée par
cette décision de gouvernance.

### Verification

Branche `refonte/budget-obsidian-glass-v1`, `CLAUDE.md`, skill
`/budget-v1`, constitution, plan de livraison, matrice d'écrans et statut
créés. Aucun code applicatif modifié dans L0.


## ADR-019 — Horizon : thème clair par défaut (web), sombre premium conservé ; parité dette D04

Date: 2026-07-21
Status: accepted

### Context

Le programme « Budget Leader Refonte » impose une direction « Swiss calm
fintech » : interface claire par défaut, sombre premium fonctionnel. La
branche codex/budget-leader-refonte annoncée n'existe pas sur GitHub —
la spécification du propriétaire fait foi. Par ailleurs l'audit de
parité (fixtures A05) avait documenté que le web comptait les
mensualités de dette dans le coût de la vie, contrairement à ADR-016.

### Decision

1. PWA : tokens de thème (`--bg/--surface/--surface-2/--surface-3/--field/
   --line/--line-strong/--sheen/--hero-surface/--badge-ink`) ; clair par
   défaut dans `:root`, l'identité verre sombre historique intacte sous
   `html[data-theme="dark"]` ; préférence `S.theme` persistée, bascule
   dans Réglages, `meta theme-color` synchronisé. Le natif reprendra les
   mêmes rôles de tokens (DesignTokens) lors d'un lot dédié vérifié par CI.
2. Web : les mouvements `recurringId` préfixé `r-debt-` sont exclus du
   coût de la vie, du « pas encore classé » et des dépenses de l'accueil
   (capital ≠ dépense ; intérêts saisis à part) — aligné sur ADR-016.

### Consequences

Les montants du mois web et natif sont réconciliés par les fixtures de
parité (living 0 / cashFlow 0 / dette décrémentée sur le scénario
dette-vivante). Les utilisateurs existants du web basculent en clair au
prochain chargement (S.theme absent → light) ; le sombre se réactive en
deux gestes dans Réglages.

### Verification

38 parcours e2e Chromium + 4 fixtures de parité verts, zéro erreur
console ; captures clair/sombre 390 px et 320 px sans débordement.

## ADR-013 — Sécurité/portabilité : verrouillage authentifié dans les deux sens, sauvegarde en montants String

Date: 2026-07-19
Status: accepted

### Context

Phase 12. Critères : états de verrouillage, annulation, version de restauration et confirmations destructives corrects ; textes de confidentialité conformes à l'implémentation.

### Decision

- `AuthenticationProviding` (protocole, contrat architecture) : impl LAContext (`deviceOwnerAuthentication` = biométrie avec repli code) + fake scripté. `AppLockManager` : verrouillé au lancement et au passage en arrière-plan quand activé ; annulation/échec = reste verrouillé ; l'ACTIVATION ET la désactivation exigent une authentification (un passant ne désactive pas la protection). Préférence dans UserDefaults (pas un secret) ; `NSFaceIDUsageDescription` ajouté au projet.
- Sauvegarde JSON versionnée (`schemaVersion` = 8) : chaque montant voyage en **String** (`"2150.00"`) — le Codable de Decimal via JSON perdrait la précision ; relations recousues par UUID à la restauration ; une sauvegarde d'un schéma PLUS RÉCENT est refusée avec message clair ; un JSON corrompu est refusé AVANT tout effacement.
- Restauration = remplacement total (confirmation destructive) ; les fichiers de documents ne voyagent pas dans le JSON (métadonnées seulement, référence conservée).
- Export CSV machine-stable (dates ISO, décimales à point, `;`, guillemets doublés) — l'affichage fr-CH reste dans l'app, l'export vise la portabilité.
- Suppression totale : double confirmation, efface toutes les entités (transactions d'abord pour ne jamais heurter les règles .deny) ET les fichiers de documents.
- Écrans Confidentialité/Méthodologie : textes alignés sur le comportement réel (aucun réseau, aucune analyse, formules exactes du disponible/taux d'épargne/impôts).

### Consequences

L'export sur demande uniquement ; aucune écriture réseau nulle part.

### Verification

`BackupServiceTests` (round-trip complet sur les données démo, remplacement, rejet schéma plus récent sans effacement, rejet corruption, suppression totale fichiers compris, échappement CSV) et `AppLockManagerTests` (défaut déverrouillé, activation authentifiée, annulation/échec/succès, persistance à la relance).

## ADR-012 — Import CSV : empreintes SHA-256, écriture au dernier pas, fichiers derrière protocole

Date: 2026-07-19
Status: accepted

### Context

Phase 11. La spec CSV_IMPORT_SPEC exige : aucun doublon au ré-import, chaque ligne rejetée visible, jamais d'import depuis une préview, pas de création massive de catégories.

### Decision

- Empreinte = SHA-256 (CryptoKit, framework système) de l'identité normalisée `fichier|index|dateISO|montant|type|intitulé` → stockée dans `importFingerprint` (existant depuis V1) ; doublon si l'empreinte existe déjà (dans le store OU plus haut dans le même fichier). L'index de ligne fait partie de l'identité : deux lignes volontairement identiques dans le fichier restent deux mouvements.
- Le wizard est pur jusqu'au bout : parse/mapping/validation ne touchent jamais le store ; seul `apply` écrit, en lot (`ImportBatch` + `importBatchID` additif sur BudgetTransaction) → rollback exact du lot (les catégories créées survivent car potentiellement réutilisées).
- Catégories manquantes listées et créées UNIQUEMENT si cochées ; lignes non confirmées importées sans catégorie (file « non catégorisés » existante).
- Fichiers de documents : protocole `DocumentFileStoring` (contrat architecture), impl réelle FileManager avec `.completeFileProtection` dans le conteneur, fake in-memory pour tests/previews. Pas de blob SwiftData.
- Export CSV/JSON : Phase 12, conformément au découpage de la roadmap.

### Consequences

Le rapport réconcilie par construction (total = importées + doublons + invalides) ; le texte brut des lignes est conservé dans le rapport jusqu'à sa fermeture.

### Verification

`CSVImportServiceTests` : détection, guillemets, dates suisses, raisons visibles, ré-import 0 doublon, stabilité d'empreinte, confirmations de catégories, réconciliation, rollback ciblé, fake store.

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

## ADR-014 — La restauration ne touche jamais aux fichiers de documents

Date: 2026-07-19
Status: accepted

### Context

L'audit de la Phase 13 a révélé un scénario de perte définitive : `restore()` appelait `deleteAll` avec le vrai `DocumentFileStore`, effaçait donc tous les fichiers de documents, puis réinsérait des métadonnées dont les `fileReference` ne pointaient plus sur rien. Les fichiers ne voyagent pas dans la sauvegarde JSON — rien ne pouvait les faire revenir.

### Decision

1. La restauration remplace les ENTITÉS uniquement (`wipeEntities`) et ne supprime jamais un fichier : une référence restaurée retrouve son fichier s'il est encore présent.
2. Aucune écriture n'est committée avant la fin de la reconstruction : la purge et les insertions partagent la même transaction, un échec fait `rollback()` et le store reste tel quel — le message « vos données actuelles sont intactes » est vrai dans tous les cas.
3. Dans la suppression totale, les fichiers ne sont effacés qu'APRÈS le commit de la purge des entités (jamais de fichiers perdus avec des enregistrements survivants).
4. La sauvegarde embarque désormais aussi `ImportBatch`, `employmentStatus` et les `updatedAt` (round-trip réellement sans perte) ; les nouveaux champs sont optionnels au décodage pour rester compatibles avec les sauvegardes antérieures.

### Consequences

Restaurer sur un appareil contenant des documents est sans danger ; l'historique d'import et ses poignées de rollback survivent au round-trip.

### Verification

`testRestoreNeverDeletesDocumentFiles`, round-trip étendu aux lots d'import (`BackupServiceTests`).

## ADR-015 — Migration V1 : légère automatique, plan étagé retiré

Date: 2026-07-20
Status: accepted

### Context

Le tour simulateur (workflow Demo) a fait planter l'app au premier lancement sur un store disque neuf : `NSStagedMigrationManager` abandonne (SIGABRT) dans `makeProductionContainer`. Cause : les huit `VersionedSchema` (V1→V8) référencent les MÊMES classes @Model vivantes — chaque étape du plan porte donc une empreinte de modèle identique et le gestionnaire de migration ne peut pas déterminer l'étape courante. Les tests unitaires n'ont jamais vu le crash : le conteneur in-memory n'entre pas dans ce chemin de code. L'app aurait planté au premier lancement sur n'importe quel iPhone.

### Decision

1. Retirer le `SchemaMigrationPlan` des deux fabriques de conteneur : chaque changement V1→V8 étant strictement additif, la migration légère AUTOMATIQUE de SwiftData couvre tous les stores existants (aucun n'a d'ailleurs été distribué).
2. Conserver les enums `BudgetSchemaV1…V8` comme documentation de l'historique du schéma.
3. Un vrai plan étagé (avec instantanés de modèles gelés par version) ne sera introduit qu'au premier changement RUPTEUR après la mise en production.

### Consequences

Le lancement sur appareil fonctionne ; la validation « migration V1→V8 sur un appareil » se réduit à la migration légère automatique d'Apple, couverte par leur runtime.

### Verification

Workflow Demo : la vraie app démarre dans le simulateur (tour complet capturé) ; suite unitaire inchangée.

## ADR-016 — Remboursement de dette atomique et fin des sauvegardes silencieuses

Date: 2026-07-20
Status: accepted

### Context

Audit externe (skill budget-production-completion) : `.debtPayment` débitait le compte source sans jamais réduire la dette — un remboursement faisait BAISSER la fortune nette au lieu de la laisser neutre. Par ailleurs six mutations utilisateur utilisaient `try? modelContext.save()` : un échec de persistance passait inaperçu et l'écran divergeait du store.

### Decision

1. `.debtPayment` accepte un compte de destination : le compte de dette remboursé (carte de crédit, prêt, hypothèque — soldes négatifs par convention ADR patrimoine). `supportsDestinationAccount` et la validation le traitent comme épargne/investissement (destination facultative, ≠ source, active) ; `signedEffect` créditait déjà toute destination — cash et dette bougent ensemble, fortune inchangée. Sans destination, le remboursement reste une sortie vers un créancier externe (dette du Patrimoine mise à jour manuellement). Intérêts et frais = dépenses séparées.
2. `ModelContext.saveOrRollback(onError:)` (Core/Persistence/SafeSave.swift) : do/catch + rollback + message français ; les six `try? save` sont remplacés, chaque vue affiche l'erreur (bannière ou alerte). Interdiction contractuelle de réintroduire `try? save` dans une mutation utilisateur.

### Verification

`DebtPaymentTests` (validation, effets signés, neutralité de fortune, partiel, trop-payé, sans destination) ; grep CI-able : zéro `try? modelContext.save()`.

## ADR-017 — V1 mono-devise : le CHF partout, garde à la restauration

Date: 2026-07-20
Status: accepted

### Context

`Account.currencyCode` existe dans le schéma (défaut "CHF") mais aucun service ne convertit : soldes, snapshot mensuel, budgets et fortune ADDITIONNENT les montants bruts. Un compte EUR restauré depuis une sauvegarde fausserait silencieusement tous les totaux. L'UI native n'expose nulle part le choix de devise — le seul chemin d'entrée d'un compte non-CHF est `BackupService.restore`.

### Decision

1. Budget V1 natif est STRICTEMENT mono-devise CHF. Aucun taux de change, aucune conversion, aucune promesse multi-devises dans l'app ni sur la fiche App Store.
2. Garde à l'entrée : `BackupService.restore` refuse toute sauvegarde contenant un compte ou un ménage non-CHF (`BackupError.unsupportedCurrency`, message listant les devises) AVANT de toucher au store — les données existantes restent intactes.
3. `currencyCode` reste dans le schéma comme réservation V2 ; le prototype web (multi-devises CHF/EUR/USD à taux manuels) sert de laboratoire pour la V2 native.

### Verification

`UnifiedTaxReserveTests.testRestoreRefusesNonCHFAccounts` : sauvegarde avec compte EUR → erreur dédiée, store intact.

## ADR-018 — Une seule vérité fiscale : le snapshot mensuel lit TaxService

Date: 2026-07-20
Status: accepted

### Context

Audit externe : le tableau de bord calculait sa « réserve d'impôts manquante » localement (revenus du mois × taux − impôts payés du mois) en IGNORANT la réserve annuelle constituée (`TaxProvision.reservedAmount`) et les arriérés saisis dans le module Impôts. Un utilisateur ayant déjà mis de côté sa provision voyait l'accueil réclamer une réserve déjà couverte — deux écrans, deux vérités.

### Decision

1. `TaxService.monthReserveGap(monthIncome:monthPaid:rate:provision:)` est la formule UNIQUE : manque du mois (plancher zéro) + arriérés − réserve annuelle constituée, plancher zéro.
2. `MonthlySnapshotService` reçoit les `TaxProvision` (année du mois affiché) et délègue le calcul — plus aucune formule fiscale locale ; `TaxProvisionSummary` transporte `reserved`, `arrears` et un `gap` figé.
3. Même principe côté web : `taxSummary(year)` est la seule source (fait en P0.2).

### Verification

`UnifiedTaxReserveTests` : réserve couvrante → écart nul ; arriérés → écart augmenté ; provision d'une autre année ignorée ; accueil et module Impôts produisent le MÊME `reserveGap` sur un mois isolé.
