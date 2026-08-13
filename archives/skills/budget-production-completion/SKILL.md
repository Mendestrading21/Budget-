---
name: budget-production-completion
description: Audit, corrige, simplifie, teste et prépare l'application Budget pour une utilisation réelle et une publication, en faisant de l'app iOS native la source de vérité et de la version web un prototype de démonstration fiable.
---
# Budget — Production Completion Skill
## Mission
Tu travailles sur le dépôt GitHub :
- Repository : `Mendestrading21/Budget-`
- Produit principal : application iOS native SwiftUI + SwiftData
- Produit secondaire : prototype web autonome dans `webapp/index.html`
- Langue produit : français de Suisse
- Devise produit V1 recommandée : CHF
- Utilisateur cible : particulier ou ménage suisse souhaitant comprendre immédiatement :
  - ce qui est réellement disponible ;
  - ce qui est dépensé ;
  - ce qui doit encore être payé ;
  - ce qui est épargné ou investi ;
  - la situation des impôts ;
  - la fortune nette ;
  - les actions prioritaires du mois.
Ta mission est de poursuivre le développement jusqu'à obtenir une V1 cohérente, fiable, simple, testée et réellement utilisable.
Ne te contente pas de produire un plan. Inspecte le code réel, applique les corrections, exécute les tests, vérifie les parcours et documente les résultats.
---
# 1. Règle produit principale
## Source de vérité
L'application iOS native est la source de vérité fonctionnelle et financière.
La version web sert principalement à :
- démontrer le produit ;
- tester rapidement des idées d'UX ;
- produire une démo visuelle ;
- valider les parcours avant implémentation native.
Ne laisse jamais les deux versions diverger silencieusement.
Lorsqu'une fonctionnalité existe uniquement dans le web, décide explicitement :
1. soit elle doit être portée dans l'app native ;
2. soit elle reste une expérimentation web clairement identifiée ;
3. soit elle doit être supprimée du web pour éviter une fausse promesse produit.
Documente chaque décision dans `DECISION_LOG.md`.
---
# 2. Objectif final
Le produit doit répondre simplement à cinq questions :
1. Combien ai-je réellement à disposition aujourd'hui ?
2. Qu'est-ce qui va encore entrer ou sortir ce mois ?
3. Suis-je dans mon budget ?
4. Où va mon argent : dépenses, épargne, investissement, impôts ou dette ?
5. Quelle est ma situation financière globale ?
Toute fonctionnalité, carte, graphique, bouton ou texte qui ne sert pas clairement l'une de ces cinq questions doit être simplifié, déplacé dans « Plus » ou supprimé.
---
# 3. Principes obligatoires
## Fiabilité financière
- Utiliser `Decimal` pour tous les montants dans l'app native.
- Ne jamais additionner des devises différentes sans conversion explicite.
- Un virement interne ne crée ni revenu ni dépense.
- Une épargne ou un investissement avec compte de destination doit préserver la fortune nette.
- Un remboursement de dette doit réduire simultanément le cash et la dette liée.
- Le planifié et le comptabilisé doivent rester strictement séparés.
- Une opération ne doit jamais être comptée deux fois.
- Les impôts doivent être filtrés par année, statut et source.
- Les estimations fiscales doivent toujours afficher leurs hypothèses.
- Aucun montant fiscal, échéance ou taux ne doit être codé en dur comme s'il s'agissait d'une donnée réelle.
- Toute formule affichée doit pouvoir être expliquée par une décomposition visible.
## Intégrité des données
- Aucune suppression silencieuse.
- Aucune mutation destructive sans confirmation adaptée.
- Aucune erreur de persistance ne doit être ignorée.
- Interdiction d'utiliser `try? modelContext.save()` dans une mutation utilisateur.
- Toute erreur de sauvegarde doit :
  1. afficher un message ;
  2. annuler ou restaurer l'état incohérent ;
  3. ne jamais faire croire que l'opération a réussi.
- Les sauvegardes et restaurations doivent être versionnées.
- Une restauration invalide ne doit modifier aucune donnée.
- Les migrations doivent être testées sur un store disque réel, pas uniquement en mémoire.
## UX
- L'action la plus fréquente doit être accessible en un ou deux gestes.
- Aucun bouton ne doit ouvrir une simple liste si l'intention est clairement de créer un élément.
- Les alertes doivent mener directement à l'action correcte.
- Les textes doivent être compréhensibles sans vocabulaire comptable avancé.
- Préférer :
  - « Argent disponible »
  - « Dépenses du mois »
  - « À payer »
  - « Mis de côté »
  - « Envoyé vers mes comptes »
- Éviter dans l'interface principale :
  - « décomposition réconciliée »
  - « liquidités incluses »
  - « occurrence matérialisée »
  - « source de vérité »
- Ces termes peuvent rester dans le code ou dans la documentation technique.
## Accessibilité
- VoiceOver doit comprendre chaque montant, bouton, graphique et statut.
- Dynamic Type doit fonctionner jusqu'aux tailles d'accessibilité.
- Aucun statut ne doit dépendre uniquement de la couleur.
- Toute cible tactile doit mesurer au moins 44 × 44 points.
- Le mode clair et le mode sombre doivent être réellement lisibles.
- « Réduire les animations » et « Réduire la transparence » doivent être respectés.
---
# 4. Démarrage obligatoire
Avant toute modification :
1. Lire :
   - `PROJECT_STATUS.md`
   - `DECISION_LOG.md`
   - `MANUAL_QA_CHECKLIST.md`
   - `webapp/AUDIT_W1.md`
   - `.github/workflows/ci.yml`
   - les tests existants ;
   - les services financiers principaux ;
   - les vues principales.
2. Vérifier :
   - la branche active ;
   - `git status` ;
   - les changements non commités ;
   - les derniers workflows GitHub ;
   - les tests réellement exécutés ;
   - les tests UI actuellement ignorés.
3. Ne jamais écraser un travail non commit.
4. Créer une liste de tâches hiérarchisée P0, P1, P2, P3.
5. Commencer immédiatement par les P0.
6. Ne pas s'arrêter après l'audit ou le plan.
---
# 5. Priorités de correction
## P0 — Bloqueurs
### Web : ajout de mouvement
Corriger la signature du formulaire de mouvement :
```javascript
function openTxSheet(tx, presetType = null)
```
Vérifier tous les appels :
- menu universel ;
- ajout rapide de dépense ;
- ajout rapide d'épargne ;
- ajout depuis la liste ;
- duplication ;
- édition.
Ajouter un test navigateur qui :
1. ouvre le menu `＋` ;
2. choisit « Mouvement » ;
3. crée une dépense ;
4. vérifie que la dépense apparaît ;
5. recharge la page ;
6. vérifie la persistance.
### Web : impôts
Corriger le calcul pour que :
- seuls les revenus `posted` de l'année affichée soient inclus ;
- seuls les paiements d'impôts `posted` de l'année affichée soient inclus ;
- les revenus futurs ne gonflent pas l'estimation ;
- les échéances codées en dur soient supprimées ;
- les arriérés soient une donnée utilisateur réelle ;
- l'estimation annuelle affiche sa méthode ;
- le module et le dashboard utilisent le même taux et la même réserve.
### Native : remboursement de dette
Repenser `.debtPayment`.
Résultat attendu :
- le compte source est débité ;
- la dette ou le compte de dette lié est réduit ;
- la fortune nette reste inchangée pour un simple remboursement de capital ;
- les intérêts ou frais éventuels restent des dépenses séparées ;
- le formulaire permet de choisir la dette remboursée ;
- les tests couvrent :
  - carte de crédit ;
  - prêt ;
  - hypothèque ;
  - dette standalone ;
  - paiement partiel ;
  - paiement supérieur au montant dû ;
  - dette archivée.
Documenter la décision métier.
### Native : erreurs de sauvegarde
Remplacer tous les `try? modelContext.save()` et toute erreur silencieuse dans :
- récurrents ;
- duplication ;
- suppression ;
- rapprochement ;
- objectifs ;
- budget ;
- impôts ;
- documents ;
- patrimoine.
Créer un mécanisme commun de mutation sécurisée avec :
- `do/catch` ;
- rollback ;
- message utilisateur ;
- journal technique sans montant sensible.
---
## P1 — Fiabilité financière
### Devise native
Choisir explicitement l'une des deux stratégies.
#### Stratégie recommandée pour V1
CHF uniquement.
Dans ce cas :
- retirer le choix de devise des modèles ou le masquer proprement ;
- valider que tous les comptes sont CHF ;
- refuser les anciennes données non CHF avec un message de migration ;
- simplifier tous les libellés et calculs ;
- documenter que la multi-devise viendra dans une V2.
#### Alternative
Vraie multi-devise.
Dans ce cas :
- devise de référence du ménage ;
- taux manuels ou service externe clairement documenté ;
- historique des taux ;
- conversion dans tous les agrégats ;
- validation stricte des virements interdevises ;
- test de patrimoine, budget, objectifs et impôts multi-devises.
Ne jamais conserver une fausse multi-devise partielle.
### Réserve d'impôts unique
Créer ou consolider un service unique, utilisé par :
- dashboard ;
- budget quotidien ;
- écran Impôts ;
- actions prioritaires ;
- projections annuelles.
La réserve doit intégrer de façon cohérente :
- estimation annuelle ;
- payé ;
- réserve réellement constituée ;
- arriérés ;
- échéances ;
- éventuel override utilisateur.
### Récurrents web
Remplacer la déduplication par titre par un identifiant stable :
- `recurringId`
- date d'occurrence ;
- identifiant de transaction liée.
Deux récurrents ayant le même titre doivent fonctionner indépendamment.
### Compte web et historique
Interdire la modification rétroactive du solde initial après la première transaction.
À la place :
- proposer « Réconcilier le solde » ;
- enregistrer date et nouveau solde de référence ;
- préserver l'historique ;
- tester les mouvements avant et après réconciliation.
### Suppression complète web
Séparer :
1. « Effacer les opérations »
2. « Réinitialiser complètement l'application »
La seconde doit réellement supprimer :
- comptes ;
- mouvements ;
- budgets ;
- récurrents ;
- objectifs ;
- impôts ;
- taux de change ;
- documents ;
- factures ;
- assurances ;
- prévoyance ;
- actifs et dettes ;
- code de verrouillage ;
- préférences.
Le message affiché doit correspondre exactement à ce qui est supprimé.
### Confidentialité web
Corriger tous les textes qui parlent :
- de chiffrement iOS ;
- de documents réellement stockés ;
- de suppression complète ;
- de Face ID.
La version web doit décrire son vrai comportement :
- données dans `localStorage` ;
- verrouillage d'affichage par code ;
- absence de chiffrement applicatif ;
- documents limités à des métadonnées si aucun fichier n'est stocké.
---
## P2 — Simplicité et navigation
### Navigation cible commune
Adopter autant que possible :
1. **Mois**
2. **Mouvements**
3. **Budget**
4. **Comptes**
5. **Plus**
Dans « Plus » :
- Objectifs
- Factures
- Impôts
- Récurrents
- Patrimoine
- Assurances
- Prévoyance
- Documents
- Import/Export
- Réglages
Fusionner l'accueil et le cockpit « Mois » si leur contenu se répète.
### Action universelle
Ajouter un bouton universel `＋` dans l'app native permettant de créer :
- mouvement ;
- facture ;
- compte ;
- objectif ;
- récurrent ;
- actif ou dette ;
- assurance ;
- position de prévoyance.
Le formulaire doit être prérempli selon le contexte.
### Actions prioritaires
Chaque carte « À faire » doit mener directement à la bonne action :
- « Ajouter vos revenus » → formulaire revenu prérempli ;
- « Planifier une épargne » → formulaire épargne prérempli ;
- « Catégoriser 3 mouvements » → liste déjà filtrée ;
- « Réserver pour les impôts » → écran Impôts avec action correspondante ;
- « Objectif en retard » → objectif concerné ;
- « Abonnement à résilier » → récurrent concerné.
### Dashboard
Le premier écran doit montrer, dans cet ordre :
1. argent réellement disponible ;
2. salaire et revenus attendus ;
3. factures et charges à venir ;
4. dépenses du mois ;
5. argent envoyé vers épargne, bourse, 3a ou autres comptes ;
6. actions prioritaires ;
7. résumé patrimoine ;
8. derniers mouvements.
Éviter de montrer trop de graphiques avant les actions utiles.
---
# 6. Tests obligatoires
## Tests unitaires natifs
Ajouter ou renforcer les tests pour :
- soldes ;
- virements ;
- épargne ;
- investissement ;
- dette ;
- impôts ;
- réserve ;
- objectifs ;
- récurrents ;
- budget ;
- patrimoine ;
- restauration ;
- migration ;
- multi-devise ou validation CHF-only ;
- erreurs de sauvegarde ;
- réconciliation ;
- suppression ;
- documents.
## Tests UI natifs
Le test UI ne doit plus seulement visiter les écrans.
Créer des parcours qui :
### Parcours 1 — Fresh install
1. lancer l'app sans données ;
2. terminer l'onboarding ;
3. ajouter un compte ;
4. relancer ;
5. vérifier que les données persistent.
### Parcours 2 — Cycle mensuel
1. ajouter un salaire ;
2. ajouter une dépense ;
3. ajouter une épargne ;
4. ajouter un virement ;
5. vérifier les soldes ;
6. vérifier « disponible » ;
7. vérifier que le virement ne change pas la fortune.
### Parcours 3 — Budget
1. créer un budget ;
2. ajouter des lignes ;
3. créer une dépense sous budget ;
4. créer une dépense hors budget ;
5. vérifier les écarts ;
6. copier le budget au mois suivant.
### Parcours 4 — Récurrent
1. créer un récurrent ;
2. vérifier la prévision ;
3. le comptabiliser ;
4. vérifier qu'il disparaît des prévisions ;
5. vérifier qu'il n'est pas dupliqué.
### Parcours 5 — Dette
1. créer une dette ;
2. enregistrer un remboursement ;
3. vérifier cash, dette et patrimoine.
### Parcours 6 — Sauvegarde
1. exporter ;
2. modifier les données ;
3. restaurer ;
4. vérifier le retour à l'état exact.
### Parcours 7 — Verrouillage
1. activer ;
2. passer en arrière-plan ;
3. revenir ;
4. annuler l'authentification ;
5. vérifier que l'app reste verrouillée ;
6. réussir ;
7. vérifier le déverrouillage.
## Tests web
Mettre en place une suite automatisée avec Playwright ou équivalent.
Tester au minimum :
- ouverture de chaque onglet ;
- création, édition, duplication et suppression d'un mouvement ;
- persistance après reload ;
- navigation navigateur ;
- menu universel ;
- ajout de compte ;
- impossibilité de réécrire le solde initial avec historique ;
- budget ;
- facture ;
- récurrent ;
- objectif ;
- impôts ;
- patrimoine ;
- sauvegarde/restauration ;
- verrouillage ;
- suppression complète ;
- clavier : Entrée, Espace, Échap ;
- graphique patrimoine avec valeurs constantes ou nulles ;
- absence de `ReferenceError` et d'erreur console.
Toute erreur console doit faire échouer les tests.
## CI
La CI doit :
- construire Debug ;
- exécuter les tests unitaires ;
- construire Release ;
- exécuter les tests UI critiques ;
- exécuter la suite web ;
- publier les artefacts en cas d'échec ;
- conserver les captures d'écran utiles ;
- empêcher le merge si un test critique échoue.
---
# 7. Critères d'acceptation par module
## Mouvements
- ajouter ;
- modifier ;
- dupliquer ;
- supprimer ;
- annuler ;
- rechercher ;
- filtrer ;
- catégoriser ;
- gérer prévu/comptabilisé ;
- gérer compte source et destination ;
- gérer une erreur de sauvegarde ;
- aucun bouton inerte.
## Comptes
- création ;
- édition ;
- archivage ;
- réactivation ;
- réconciliation ;
- suppression refusée si historique ;
- solde explicable ;
- dette correctement signée ;
- devise cohérente.
## Budget
- aucune catégorie dupliquée ;
- copie isolée du mois source ;
- réel et planifié séparés ;
- remboursements correctement déduits ;
- hors budget complet ;
- total réconcilié.
## Impôts
- année correcte ;
- seulement mouvements comptabilisés ;
- aucune valeur cachée ou codée en dur ;
- estimation, payé, réserve, arriérés et dû cohérents ;
- disclaimer visible ;
- hypothèses modifiables.
## Patrimoine
- comptes inclus ;
- actifs ;
- prévoyance ;
- dettes ;
- aucune double comptabilisation ;
- virements neutres ;
- dette remboursée correctement ;
- graphique stable avec série constante ;
- historique explicable.
## Sauvegarde
- export lisible ;
- restauration transactionnelle ;
- rollback sur erreur ;
- schéma futur refusé ;
- relations restaurées ;
- documents traités honnêtement ;
- aucune perte silencieuse.
---
# 8. Qualité du code
## Native
- Services métier purs autant que possible.
- Les vues ne recalculent pas plusieurs fois les mêmes agrégats.
- Les requêtes volumineuses utilisent `FetchDescriptor`, `#Predicate` ou un service indexé lorsque nécessaire.
- Les mutations sont centralisées.
- Les messages utilisateurs sont en français clair.
- Les erreurs techniques ne contiennent aucun montant réel dans les logs.
## Web
Découper progressivement `webapp/index.html`.
Structure cible minimale :
```text
webapp/
  index.html
  styles/
    tokens.css
    app.css
  src/
    app.js
    state.js
    storage.js
    navigation.js
    finance-engine.js
    transactions.js
    accounts.js
    budgets.js
    taxes.js
    recurrings.js
    goals.js
    networth.js
    settings.js
  tests/
```
Ne pas continuer à ajouter des modules importants dans un unique fichier de plus de 3 000 lignes.
---
# 9. Méthode de travail
Pour chaque phase :
1. lire le code concerné ;
2. écrire ou corriger les tests ;
3. appliquer la correction ;
4. exécuter les tests ciblés ;
5. exécuter la suite complète ;
6. vérifier visuellement ;
7. mettre à jour la documentation ;
8. faire un commit clair.
Format de commit recommandé :
```text
fix(native): make debt payments preserve net worth
fix(web): repair transaction quick-add flow
test(web): cover universal add menu and persistence
refactor(web): split finance engine from rendering
feat(native): add direct contextual actions
```
Ne regroupe pas toutes les corrections dans un seul commit illisible.
---
# 10. Interdictions
- Ne pas créer de faux bouton.
- Ne pas afficher « Fonctionne » sans test réel.
- Ne pas confondre une capture d'écran avec un test fonctionnel.
- Ne pas ignorer les erreurs avec `try?`.
- Ne pas coder des chiffres fiscaux en dur.
- Ne pas présenter une estimation comme officielle.
- Ne pas supprimer des données sans confirmation.
- Ne pas modifier l'historique financier en changeant un solde initial.
- Ne pas compter deux fois un compte 3a ou une position de prévoyance.
- Ne pas additionner CHF, EUR et USD comme s'ils étaient identiques.
- Ne pas prétendre que le web utilise Face ID ou le chiffrement iOS.
- Ne pas arrêter le travail après avoir produit un plan.
---
# 11. Définition de terminé
Le travail est considéré terminé uniquement lorsque :
- tous les P0 sont corrigés ;
- tous les P1 sont corrigés ou explicitement repoussés avec justification ;
- l'app native compile en Debug et Release ;
- les tests unitaires sont verts ;
- les tests UI critiques sont verts ;
- la suite web est verte ;
- aucune erreur console web n'apparaît ;
- la checklist QA manuelle est exécutée sur au moins un appareil réel ;
- la migration depuis un ancien store a été testée ;
- tous les boutons principaux ont été exercés ;
- les calculs sont réconciliés ;
- les textes de confidentialité correspondent au comportement réel ;
- la navigation est simple et cohérente ;
- `PROJECT_STATUS.md`, `DECISION_LOG.md` et `MANUAL_QA_CHECKLIST.md` sont à jour ;
- le rapport final liste clairement ce qui a été corrigé, testé et ce qui reste externe, par exemple un compte Apple Developer.
Ne déclare jamais « 100 % terminé » si une validation appareil, migration ou publication dépend encore d'une action humaine non exécutée.
---
# 12. Rapport final obligatoire
À la fin, produire un rapport avec :
## Résumé
- état de l'app native ;
- état du web ;
- niveau de préparation TestFlight ;
- niveau de préparation App Store.
## Corrections réalisées
Pour chaque correction :
- problème ;
- cause ;
- solution ;
- fichiers modifiés ;
- tests ajoutés ;
- résultat.
## Tests
- commandes exécutées ;
- nombre de tests ;
- résultat Debug ;
- résultat Release ;
- résultat UI ;
- résultat web ;
- éventuelles captures.
## Risques restants
Uniquement les risques réels, pas une liste générique.
## Prochaines actions humaines
Par exemple :
- tester sur iPhone réel ;
- créer le compte Apple Developer ;
- choisir le prix ;
- valider les textes App Store.
---
# Instruction finale
Prends possession du chantier technique de bout en bout.
Commence par inspecter le dépôt réel et confirmer ou invalider chaque problème cité dans ce skill. Corrige immédiatement ce qui est confirmé. Ne protège pas le code existant lorsqu'il est incohérent, mais protège toujours les données et l'historique Git.
L'objectif n'est pas d'ajouter le maximum de fonctionnalités. L'objectif est de livrer l'application de budget la plus claire, fiable et agréable possible, avec une logique financière explicable et des parcours réellement testés.
