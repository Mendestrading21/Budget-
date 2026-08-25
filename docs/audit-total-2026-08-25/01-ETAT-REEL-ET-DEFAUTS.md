# 01 — État réel et défauts

## 1. Périmètre technique observé

Le dépôt contient deux applications fonctionnelles : une application native
iPhone SwiftUI/SwiftData et une PWA installable. Il ne contient ni projet
Android natif, ni moteur financier partagé compilé par les deux produits. La
parité est obtenue par discipline, documentation et fixtures, pas par une source
de code unique.

Le périmètre métier est très large : foyer, membres, comptes, opérations,
budgets, récurrences, impôts, objectifs, assurances, prévoyance, actifs,
dettes, patrimoine, positions titres, documents, import CSV, export et
restauration.

## 2. Forces réelles à conserver

### 2.1 Décimales et validation

- Les montants iOS utilisent `Decimal`.
- Le parsing accepte plusieurs conventions de saisie.
- Les montants non valides ne deviennent pas silencieusement zéro.
- Les comptes source/destination et catégories sont validés.
- Les écritures SwiftData utilisent un garde de sauvegarde et rollback.

### 2.2 Séparation partielle prévu / réel

- Les mouvements ont un statut `planned` ou `posted`.
- Les soldes de comptes n'incluent que les mouvements comptabilisés.
- Le mois calcule séparément réalisé et prévu.
- Le correctif de la PR #119 évite de présenter une projection future comme
  argent déjà reçu.

### 2.3 Sauvegarde structurée

- Les décimales voyagent comme chaînes exactes.
- Les UUID et relations sont contrôlés avant restauration.
- Les versions futures sont refusées.
- Une restauration illisible ou incohérente tente de préserver les données
  existantes.

### 2.4 Qualité et preuves

- CI web et iOS ;
- tests navigateur réel ;
- fixtures de parité ;
- contrôles design et manifeste de confidentialité ;
- nombreuses ADR et traces de décisions.

Ces forces doivent être reprises dans la nouvelle architecture. Le programme
ne part pas de zéro.

---

## 3. Vérité financière : défauts critiques

### F-01 — Cycle de vie à deux états

`TransactionStatus` ne connaît que `planned` et `posted`.

Une app grand public doit distinguer au minimum : échéance seulement prévue,
mouvement importé en attente, mouvement confirmé, mouvement pointé,
mouvement rapproché, correction, annulation et échec. Sans cela, boutons,
imports, connexions bancaires futures et corrections se rabattent sur une
distinction binaire trop pauvre.

**Sévérité : P0.**

### F-02 — La date décide du réel

`TransactionPostingPolicy.automaticStatus` rend `posted` toute date qui n'est
pas future.

Scénarios incorrects :

- ajouter aujourd'hui une facture d'hier qui n'est pas payée ;
- saisir un salaire attendu le mois précédent ;
- importer une opération pending datée d'hier ;
- préparer rétroactivement une échéance oubliée.

La date décrit quand le mouvement était attendu, pas la preuve qu'il est
arrivé. Séparer `scheduledFor`, `effectiveDate`, `postedAt`, `clearedAt` et
`reconciledAt`.

**Sévérité : P0.**

### F-03 — Occurrence récurrente non persistée

`RecurringScheduleService` génère une `ForecastOccurrence` en mémoire. Le
mouvement réel est lié par `recurringID` et comparaison de jour.

Défauts :

- pas d'UUID d'occurrence durable ;
- pas de contrainte unique `série + date locale + séquence` ;
- pas d'état `due`, `paid`, `received`, `skipped`, `snoozed`, `cancelled` ;
- pas de montant attendu distinct du montant réel ;
- une occurrence déplacée peut couvrir la mauvaise échéance ;
- plusieurs occurrences mensuelles sont couvertes par comptage ;
- une modification de série peut réinterpréter l'historique ;
- le double tap dépend du code applicatif, pas d'une clé d'idempotence persistée.

**Sévérité : P0.**

### F-04 — Planifier matérialise déjà un mouvement

Le bouton « Planifier » crée une transaction persistée `planned`. Cela mélange
l'obligation attendue et le mouvement bancaire. Une échéance doit pouvoir
exister, être déplacée, ignorée ou rapprochée sans pseudo-transaction dans le
journal réel.

**Sévérité : P1, devient P0 avec synchronisation bancaire.**

### F-05 — Modification et suppression du passé

Le formulaire peut modifier directement une transaction comptabilisée et la
suppression est définitive après confirmation.

Risques : solde historique réécrit, rapport annuel modifié, rapprochement non
reproductible et synchronisation qui recrée l'élément supprimé.

Décision cible :

- brouillon/prévu modifiable ;
- import en attente corrigeable avant validation ;
- comptabilisé corrigé par remplacement ou ajustement lié ;
- rapproché verrouillé, correction par inversion ;
- suppression physique réservée aux objets jamais comptabilisés.

**Sévérité : P0.**

### F-06 — Transfert non garanti par écriture équilibrée

Le modèle source/destination fonctionne sur les cas simples, mais la neutralité
dépend de chaque service et rapport. Un nouveau rapport peut compter un côté ou
un signe faux.

Décision cible : journal interne équilibré. L'utilisateur voit toujours
« Transfert de A vers B », le moteur crée deux postings atomiques.

**Sévérité : P1.**

### F-07 — Dette et carte de crédit fragiles

Les comptes de dette reposent sur des soldes signés et les paiements peuvent
être type spécialisé ou transfert. Sans contrat unique, capital, intérêts,
frais et remboursement se mélangent.

Décision cible : compte de dette explicite ; capital = transfert ; intérêts et
frais = dépenses ; remise = ajustement documenté ; aucune convention négative
cachée dans l'interface.

**Sévérité : P1.**

---

## 4. Soldes, comptes, devises et patrimoine

### A-01 — Addition de devises sans conversion

Les modèles stockent `currencyCode`, mais le formatage impose CHF,
`MonthlySnapshotService` et `NetWorthService` additionnent les montants, les
positions portent une `priceCurrency`, et la sauvegarde refuse les comptes non
CHF. La multi-devise n'est donc pas réellement prise en charge.

Deux options seulement sont honnêtes : V1 strictement mono-devise partout, ou
vrai moteur multi-devise avec devise de base, taux, source et date. L'objectif
mondial impose la seconde à terme.

**Sévérité : P0 pour une app internationale.**

### A-02 — Dictionnaire de chiffres absent

Le produit doit définir et réutiliser partout :

- **Solde bancaire** : comptes comptabilisés, sans prévu ;
- **Disponible maintenant** : comptes utilisables moins réserves réellement
  bloquées ;
- **Flux net du mois** : revenus réels moins dépenses réelles ;
- **Prévision fin de mois** : disponible + occurrences ouvertes ;
- **Épargne mise de côté** : transferts vers comptes/poches dédiés ;
- **Patrimoine net** : actifs convertis moins dettes converties, à date.

### A-03 — Réconciliation insuffisamment modélisée

Un compte peut avoir un solde rapproché et une date. Il manque lot de relevé,
solde d'ouverture/fermeture, état par opération, écart, verrouillage et
historique de rapprochements.

**Sévérité : P1.**

### A-04 — Archivage et références

Toute fermeture doit préserver opérations, récurrences, objectifs, positions,
documents et rapprochements. La suppression est impossible tant qu'une
référence existe. Un compte fermé reste consultable et exclu des choix futurs.

### A-05 — Positions titres : bonne prévention du double compte, modèle incomplet

La position manuelle explique le solde et ne s'y ajoute pas, ce qui est sain.
Il manque taux de change daté, valeur historique, cash/positions, revenus,
frais, impôts, lots, coût et alerte si les positions dépassent le solde.
L'app ne doit pas promettre une performance de portefeuille précise avant ces
contrats.

---

## 5. Budgets, catégories et automatisation

### B-01 — « Divers » n'est pas « Imprévu »

`Divers` est un classement. Une dépense imprévue est un attribut. Une facture
surprise peut appartenir à Santé, Auto ou Logement.

Décision cible : catégorie ou fallback `Autre`, plus tags multiples
`Imprévu`, `Remboursable`, `Professionnel`, `Partagé` et tags libres.

### B-02 — Pas de transaction ventilée

Un achat mixte impose une fausse catégorie ou plusieurs mouvements. Ajouter des
splits analytiques dont la somme égale exactement le montant.

### B-03 — Règles d'automatisation absentes

Moteur déterministe attendu : conditions marchand, montant, compte, sens,
texte ; actions renommer, catégoriser, taguer, masquer, marquer à vérifier,
ventiler. Toute règle a preview, explication, priorité et journal.

### B-04 — Budget annuel et report à clarifier

Décider explicitement : report positif/négatif, enveloppe ponctuelle, cible
« mettre de côté » versus « remplir jusqu'à », saisonnalité, grille annuelle et
revenus variables. Aucun de ces concepts ne modifie le solde bancaire.

---

## 6. Import et restauration

### I-01 — Empreinte CSV trop liée au fichier

L'empreinte inclut nom du fichier et index de ligne. Une opération dans un
export renommé, consolidé ou réordonné aura une autre empreinte.

Cible : `sourceRowId` fournisseur quand disponible, plus empreinte normalisée
indépendante du fichier et rapprochement par fenêtre.

### I-02 — Catégories importées créées comme dépenses

Une nouvelle catégorie d'une ligne de revenu est créée avec `kind = expense`.
Le système doit collecter le type attendu, refuser les conflits et demander une
décision si le même nom apparaît dans plusieurs types.

### I-03 — Import passé automatiquement comptabilisé

Une ligne passée devient `posted`. Un import bancaire doit conserver son état
pending/posted/cleared. Un import manuel doit prévisualiser le statut.

### I-04 — Formats limités

Évoluer vers adaptateurs CSV, CAMT.053/054, OFX/QFX/QIF selon marchés. Chaque
adaptateur produit le même modèle intermédiaire et les mêmes erreurs typées.

### I-05 — Sauvegarde JSON non chiffrée

Soldes, revenus, dettes, établissements et notes sont lisibles. Cible : bundle
versionné, manifeste, checksum, AES-GCM, clé utilisateur/appareil, pièces
jointes optionnelles, store temporaire et remplacement atomique.

### I-06 — Pièces jointes non portables

La sauvegarde exporte la référence, pas les octets. L'interface doit dire
« données uniquement » ou le format doit inclure les fichiers.

### I-07 — Validation de restauration incomplète

Ajouter validation des montants, destinations, catégories, récurrences,
dates, actifs/dettes, devises, positions, écritures équilibrées et clés uniques.

---

## 7. Architecture applicative

### T-01 — PWA monolithique

`webapp/index.html` contient styles, composants, modèles, calculs, stockage,
import, navigation et écrans. Conséquences : couplage, conflits, CSP difficile,
risque de casser le domaine par changement d'écran.

Cible TypeScript modulaire : `domain`, `application`, `storage`, `platform`,
`ui`, `features`, `tests/fixtures`.

### T-02 — `localStorage` comme base de données

`localStorage` est synchrone et non transactionnel. IndexedDB doit fournir
transactions, versioning, indexes, migrations, quota/erreur et store temporaire.

### T-03 — Navigation sans vraies routes

La PWA utilise des variables ; iOS a un `AppRouter` non réellement branché.
Cible : URL/deep links, `NavigationPath`, restauration, aucun route morte et
focus/retour testés.

### T-04 — Écrans trop responsables

`HomeTab` et `TransactionFormView` combinent calcul, mutation et UI. Extraire
use cases, view models, composants et commandes atomiques.

### T-05 — Deux moteurs sans contrat exhaustif

Les fixtures de parité doivent devenir la définition exécutable, avec entrées
et sorties sérialisées stables et aucune formule modifiée sans fixture.

---

## 8. Migrations et durabilité

### D-01 — Schémas historiques non figés

Les `VersionedSchema` réutilisent les classes actives. Une modification future
peut changer rétroactivement les versions historiques.

Cible : namespace gelé par version, vrai `SchemaMigrationPlan`, fixture par
version, test `Vn → dernière`, interruption/reprise, backup avant migration.

### D-02 — Pas de journal d'événements métier

Ajouter source de commande, idempotency key, lien remplacement/inversion,
version d'occurrence, provider/import et raison de correction.

### D-03 — Calendriers

Tester 28/29/30/31, fin de mois, DST, fuseaux, semaines ISO, jours ouvrés,
pause/reprise, cadence modifiée et édition cette occurrence/suivantes/série.

---

## 9. Sécurité et confidentialité

### S-01 — Verrou d'écran ≠ chiffrement

L'authentification locale masque l'interface. Elle ne chiffre pas le store, les
exports ou la PWA. Le texte doit rester exact.

### S-02 — PWA en clair dans le navigateur

Une XSS ou un script tiers compromis pourrait lire les données. Cible : zéro
script tiers inutile, CSP stricte, sanitation, aucune donnée dans logs/URL,
dépendances minimales et stockage protégé selon threat model.

### S-03 — Service worker permissif

Limiter origine/assets, ne jamais cacher backup/export sensible, versionner,
afficher mise à jour, prouver offline et remonter les échecs.

### S-04 — Actions sensibles

Ré-authentifier pour export, restauration, effacement, révélation de données,
désactivation du verrou et sync externe.

### S-05 — Documentation sécurité

Avant store : threat model, inventaire des données, finalités, conservation,
suppression/export, SDK, privacy manifests et revue OWASP MASVS.

---

## 10. Accessibilité et universalité

### X-01 — Thème sombre forcé

Respecter le thème système ou proposer un choix, avec contrastes vérifiés en
clair, sombre et contraste élevé.

### X-02 — Localisation figée

`fr_CH`, CHF, cantons, manifest et textes sont codés. Cible : ressources de
localisation, devise/locale du foyer, formats système et module Suisse opt-in.

### X-03 — Tests humains

VoiceOver, TalkBack futur, clavier web, lecteur d'écran, zoom, Dynamic Type,
réduction des animations, contraste, cibles, erreurs et focus. L'automatisation
ne remplace pas ces vérifications.

---

## 11. Gouvernance et documentation

### G-01 — Statuts périssables

Un readiness doit être généré pour un SHA, pas rester une vérité permanente.
Les anciens audits sont archivés avec date/SHA ; les preuves vivent dans les
runs/PR ; les totaux de tests ne sont pas copiés dans plusieurs fichiers.

### G-02 — Autorités

- `budget-autonomie-100` : cible système, ordre, invariants ;
- `budget-prisme` : exécution page par page et design ;
- `budget-identites-locales` : catalogues locaux ;
- ADR : décisions ;
- statut unique : lot actif et preuves.

### G-03 — Publication

Les exigences de l'issue #70 restent valables : SHA exact, CI liée, protection
de branche, QA appareil réel et autorisation séparée.

---

## 12. Retirer, fusionner, déplacer, différer

### Retirer du chemin actif

- routes obsolètes, `ComingSoonView`, galerie de composants, liens morts ;
- textes promettant banque, IA ou calcul absent.

### Fusionner

- abonnements dans « Ce qui revient » ;
- factures ponctuelles et récurrences dans un moteur d'obligations ;
- import et rapprochement dans une file « À vérifier » ;
- patrimoine, comptes, positions et dettes sous la même valorisation.

### Déplacer

- récurrences/abonnements/factures vers `Plan` ;
- rapprochement dans fiche compte ;
- actions du mois dans une inbox ;
- impôts/assurances/prévoyance en modules régionaux.

### Différer

- assistant intelligent ;
- conseil financier ;
- sync bancaire en écriture ;
- performance détaillée de portefeuille ;
- collaboration cloud avant chiffrement et gestion des conflits.
