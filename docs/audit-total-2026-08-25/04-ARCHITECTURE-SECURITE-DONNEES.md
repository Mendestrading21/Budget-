# 04 — Architecture, sécurité et données

## 1. Architecture cible

Budget doit conserver une interface simple mais adopter une architecture en
couches, avec un contrat financier testable indépendamment des écrans.

```text
apps/
  ios/
  web/
  android/                 # seulement après décision W11
packages/
  contracts/               # schémas JSON et fixtures canoniques
  domain-spec/             # invariants, transitions, erreurs
  localization/
docs/
  architecture/
  product/
  security/
```

Le dépôt actuel peut évoluer progressivement vers cette structure sans
réécriture immédiate. Les deux applications restent en place pendant la
migration.

## 2. Contrats interplateformes

Le moteur Swift et le moteur Web doivent consommer les mêmes fixtures JSON :

```text
FixtureInput
- now
- calendar
- baseCurrency
- accounts
- journalEntries
- scheduledSeries
- scheduledOccurrences
- fxQuotes
- budgets

FixtureExpected
- accountBalances
- monthActuals
- monthForecast
- netWorth
- openOccurrences
- validationErrors
```

Toute modification d'une formule commence par une fixture rouge, approuvée
comme changement de vérité. La parité devient une gate, pas une vérification
ponctuelle.

## 3. iOS

### 3.1 Domain/Application/UI

- `Domain` : Money, journal, occurrence, budget, devise, invariants ;
- `Application` : commandes et requêtes atomiques ;
- `Infrastructure` : SwiftData, fichiers, import, sécurité ;
- `Features` : vues et view models sans calcul financier dupliqué.

Commandes recommandées :

- `CreateManualEntry`
- `ConfirmOccurrence`
- `MatchOccurrenceToEntry`
- `ReverseEntry`
- `ReconcileStatement`
- `ApplyImportBatch`
- `RestoreEncryptedBackup`

Requêtes recommandées :

- `GetMonthOverview`
- `GetAccountStatement`
- `GetPlanCalendar`
- `GetNetWorthAtDate`
- `GetFinancialInbox`

### 3.2 SwiftData et migrations

Les schémas historiques doivent être figés par version, avec un vrai
`SchemaMigrationPlan`. Pour chaque version publique :

- fixture de store réel ;
- migration vers la dernière version ;
- vérification des comptes, montants, relations et identifiants ;
- interruption simulée ;
- backup automatique pré-migration ;
- message de récupération sans effacement automatique.

Une modification de modèle n'entre pas dans une PR d'écran.

### 3.3 Navigation et état

Brancher réellement les `NavigationPath`, définir des routes typées, restaurer
la destination après interruption et supprimer les paths morts. Les feuilles
financières reçoivent une intention et appellent une commande ; elles ne
modifient pas directement plusieurs modèles.

## 4. PWA

### 4.1 Décomposition

Remplacer progressivement le fichier monolithique par TypeScript :

```text
webapp/src/
  domain/
  application/
  storage/
  platform/
  features/
  components/
  routes/
```

Une étape de compatibilité peut charger l'ancien store, écrire dans IndexedDB
et comparer les résultats avant bascule.

### 4.2 Persistance

IndexedDB doit remplacer `localStorage` pour les données métier :

- transactions atomiques ;
- stores et indexes versionnés ;
- migrations ;
- erreurs de quota visibles ;
- import dans un store temporaire ;
- commit ou rollback complet ;
- événements de changement de version ;
- stratégie multi-onglets.

`localStorage` peut rester réservé à de petites préférences non sensibles.

### 4.3 Routes

Utiliser de vraies routes pour Mois, Activité, Plan, Comptes, Plus et leurs
détails. Chaque route doit gérer retour, rechargement, deep link, focus,
404 interne et état supprimé.

### 4.4 Service worker

- précacher seulement les actifs applicatifs versionnés ;
- stratégie explicite par type de ressource ;
- aucune sauvegarde ou export dans le cache ;
- mise à jour contrôlée et message utilisateur ;
- fallback hors ligne prouvé ;
- erreurs de stockage non avalées ;
- tests première installation, mise à jour et retour à une version saine.

### 4.5 Sécurité Web

- Content Security Policy stricte ;
- aucun script tiers inutile ;
- échappement et sanitation systématiques ;
- aucune donnée financière dans URL, analytics, crash logs ou console ;
- dépendances épinglées et auditées ;
- protection contre clickjacking et injection ;
- export sensible après ré-authentification locale quand disponible.

## 5. Android

Le dépôt ne contient pas d'application Android native. Ne pas promettre une
publication Google Play avant décision documentée :

1. PWA distribuée et installable, sans fiche Play ;
2. Trusted Web Activity, seulement si la PWA satisfait toutes les exigences ;
3. application Compose native ;
4. framework partagé après preuve qu'il n'affaiblit pas le moteur.

La décision vient après les contrats financiers, car multiplier les clients
avant de stabiliser la vérité multiplierait les défauts.

## 6. Synchronisation bancaire

### 6.1 Principes

- lecture seule en première version ;
- provider derrière un adaptateur ;
- consentement explicite, périmètre et expiration ;
- identifiant fournisseur conservé ;
- pending et posted distincts ;
- suppression provider traitée sans effacer silencieusement l'historique ;
- retry idempotent ;
- rapprochement proposé, jamais doublon automatique ;
- mode manuel complet si provider indisponible.

### 6.2 Suisse

Prévoir un adaptateur compatible avec l'écosystème open banking suisse et les
formats bancaires usuels. Aucun nom, logo ou banque ne doit être présenté comme
intégré avant contrat et certification réels.

## 7. Sauvegarde chiffrée V2

Format recommandé :

```text
budget-backup/
  manifest.json
  data.enc
  attachments/
  checksums.json
```

Le manifeste contient version, date, locale, devise, empreinte et nombre
d'objets, mais aucun montant sensible. `data.enc` et les pièces jointes sont
chiffrés avec AES-GCM. La clé provient d'un secret utilisateur ou d'une clé
stockée dans le trousseau ; l'interface explique la conséquence d'une perte.

Restauration :

1. sélectionner ;
2. vérifier checksum/version ;
3. déchiffrer dans un espace temporaire ;
4. valider le domaine complet ;
5. afficher un résumé ;
6. demander biométrie/code ;
7. créer une sauvegarde de retour ;
8. remplacer atomiquement ;
9. vérifier ;
10. conserver un chemin de rollback.

## 8. Confidentialité

### 8.1 Inventaire

Documenter : identité de foyer, montants, comptes, établissements, opérations,
notes, documents, catégories, objectifs, données fiscales et diagnostic.

Pour chaque donnée : finalité, stockage, durée, export, suppression,
transmission et base juridique applicable.

### 8.2 Collecte minimale

- aucune donnée obligatoire sans fonction associée ;
- aucun tracker publicitaire ;
- analytics opt-in ou strictement agrégé et sans montant ;
- crash reports nettoyés ;
- données de démo fictives ;
- suppression locale complète et vérifiable ;
- export avant suppression.

### 8.3 Stores

Les déclarations Apple et Google doivent correspondre exactement au binaire et
aux SDK. Toute intégration bancaire, analytics, crash reporting, support ou
cloud déclenche une nouvelle revue.

## 9. Modèle de menace

Avant bêta publique, documenter au minimum :

- perte/vol de l'appareil ;
- personne ayant accès à une session déverrouillée ;
- sauvegarde partagée par erreur ;
- fichier bancaire malveillant ;
- XSS et dépendance compromise ;
- corruption ou migration interrompue ;
- provider compromis ;
- capture d'écran/app switcher ;
- logs et support ;
- attaques par doublon/retry.

Les contrôles sont alignés sur OWASP MASVS, sans prétendre à une certification
non réalisée.

## 10. Observabilité respectueuse

Les événements autorisés ne contiennent jamais montant, nom de compte,
marchand, note, document ou référence bancaire.

Exemples : version de schéma, réussite/échec typé, durée d'import, écran, type
d'erreur, état offline. Fournir une page diagnostic exportable et nettoyée.

## 11. Feature flags et rollback

Chaque migration transversale a :

- flag de lecture ;
- shadow write ;
- comparateur ;
- métrique sans données sensibles ;
- procédure de rollback ;
- date/condition de suppression du flag.

Un flag ne doit jamais permettre deux écritures concurrentes non idempotentes.

## 12. Nettoyage du dépôt

- archiver les readiness historiques avec SHA ;
- générer le statut courant ;
- une autorité par sujet ;
- supprimer fichiers/routes/composants réellement non référencés après preuve ;
- interdire secrets, données réelles et captures personnelles ;
- ajouter règles CODEOWNERS pour domaine, migrations, sécurité et workflows ;
- protéger `main` et remettre la branche par défaut sur `main` après contrôle ;
- privilégier PR ciblée et squash ;
- ne jamais déplacer un tag publié.
