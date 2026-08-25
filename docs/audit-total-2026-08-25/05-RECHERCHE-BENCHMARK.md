# 05 — Recherche et benchmark

## 1. Méthode

Recherche effectuée le 25 août 2026. Les références servent à extraire des
principes de produit, de sécurité et de conformité. Budget ne doit copier ni
interface, ni texte, ni marque, ni actif d'un tiers.

Priorité donnée aux documentations officielles, normes et sources primaires.

## 2. Gestion financière personnelle

### Actual Budget

Références :

- https://actualbudget.org/docs/accounts/reconciliation/
- https://actualbudget.org/docs/experimental/goal-templates/
- https://actualbudget.org/docs/transactions/schedules/

Principes retenus :

- le rapprochement compare le solde de l'app à un relevé réel ;
- les opérations non rapprochées restent identifiables ;
- les échéances sont des objets de planification distincts ;
- les transferts sont liés et neutres ;
- une approche local-first peut rester exportable.

À ne pas copier : enveloppes, navigation, textes, composants ou terminologie
spécifique.

### YNAB

Référence :

- https://support.ynab.com/en_us/underfunded-a-guide-BJwPhQO09

Principes retenus :

- montrer le montant nécessaire pour tenir le plan ;
- distinguer ce qui manque au budget de l'argent disponible ;
- permettre une action guidée plutôt qu'un tableau opaque ;
- traiter objectifs et dépenses périodiques dans le plan.

À ne pas copier : méthode propriétaire, slogans, catégories ou interface.

### Monarch Money

Référence :

- https://help.monarchmoney.com/hc/en-us/articles/360048393292-Transaction-rules

Principes retenus :

- règles compréhensibles avec conditions et actions ;
- ordre/priorité ;
- catégorisation, renommage et tags ;
- preview et correction ;
- séparation catégorie/contexte.

À ne pas copier : catalogue de règles, design ou textes.

## 3. Données bancaires

### Plaid — cycle pending/posted

Référence :

- https://plaid.com/docs/transactions/transactions-data/

Principes retenus :

- une transaction pending n'est pas équivalente à une transaction posted ;
- les identifiants et attributs peuvent évoluer ;
- le remplacement pending → posted doit être rapproché ;
- les synchronisations sont incrémentales et réessayables ;
- les webhooks/retries nécessitent idempotence.

Conséquence : le statut binaire actuel de Budget est insuffisant avant toute
connexion bancaire.

### SIX bLink / multibanking suisse

Référence :

- https://www.six-group.com/en/products-services/banking-services/standardization/blink.html

Principes retenus :

- concevoir un adaptateur provider, pas une intégration collée au domaine ;
- consentement et authentification sont des préoccupations de plateforme ;
- la couverture dépend des institutions et contrats ;
- garder un fonctionnement manuel complet.

Budget ne doit afficher aucun logo ou établissement comme « connecté » sans
intégration opérationnelle et autorisée.

## 4. Ledger, idempotence et corrections

### Modern Treasury

Références :

- https://www.moderntreasury.com/journal/enforcing-immutability-in-your-double-entry-ledger
- https://www.moderntreasury.com/journal/how-to-scale-a-ledger-part-i
- https://docs.moderntreasury.com/platform/reference/ledger-transaction-object

Principes retenus :

- écritures équilibrées ;
- journal append-only ;
- idempotency keys ;
- corrections par annulation et remplacement ;
- état et audit trail ;
- calculs reproductibles.

Budget n'a pas besoin d'exposer la comptabilité en partie double. Cette rigueur
reste interne et permet une interface plus simple.

## 5. Accessibilité

### W3C WCAG 2.2

Référence :

- https://www.w3.org/TR/WCAG22/

Principes retenus :

- cible WCAG 2.2 niveau AA pour la PWA ;
- focus visible et non masqué ;
- alternatives aux gestes ;
- cibles suffisantes ;
- authentification accessible ;
- erreurs identifiables et compréhensibles ;
- couleur jamais comme seul signal.

La conformité ne se déduit pas des tests automatisés. Elle exige tests clavier,
lecteurs d'écran, zoom et revue humaine.

### Apple

Références :

- https://developer.apple.com/design/human-interface-guidelines/accessibility
- https://developer.apple.com/accessibility/

Principes retenus : Dynamic Type, VoiceOver, Reduce Motion, contraste,
libellés/traits, ordre de focus, cibles et préférences système.

### Android

Référence :

- https://developer.android.com/guide/topics/ui/accessibility

Principes retenus : TalkBack, sémantique, cibles, navigation et tests sur
appareil réel avant une version Android.

## 6. Sécurité mobile

### OWASP MASVS

Références :

- https://mas.owasp.org/MASVS/
- https://mas.owasp.org/MASVS/controls/MASVS-STORAGE/

Principes retenus :

- inventaire des données sensibles ;
- stockage protégé ;
- secrets hors code ;
- authentification et session ;
- cryptographie standard ;
- réseau ;
- résilience proportionnée ;
- confidentialité des logs et backups.

Le verrou visuel actuel est utile mais ne suffit pas à qualifier le stockage,
les exports et la PWA de chiffrés.

## 7. Migrations Apple

Référence :

- https://developer.apple.com/documentation/swiftdata/schemamigrationplan

Principes retenus : versions de schéma, étapes de migration, tests depuis les
versions distribuées et conservation de modèles historiques réellement figés.

Conséquence : les enums de version qui réutilisent les modèles actifs ne sont
pas une garantie suffisante pour la première migration cassante.

## 8. App Store et Google Play

### Apple App Review et confidentialité

Références :

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/app-store/app-privacy-details/

Principes retenus :

- fonctionnalité complète et testable ;
- informations de revue exactes ;
- politique de confidentialité ;
- déclarations cohérentes avec les SDK ;
- suppression de compte si un compte est créé ;
- absence de contenu trompeur ;
- données minimales et consentement.

### Google Play

Références :

- https://support.google.com/googleplay/android-developer/answer/10787469
- https://support.google.com/googleplay/android-developer/answer/13849271

Principes retenus :

- fiche Data safety cohérente ;
- déclaration des fonctionnalités financières si applicable ;
- politique de confidentialité ;
- sécurité et exactitude des affirmations ;
- compte de test et instructions si une connexion est requise.

## 9. Synthèse : ce qui marche le mieux

Les produits et systèmes robustes convergent sur dix idées :

1. réel et planifié séparés ;
2. échéances persistées ;
3. journal immuable et corrections liées ;
4. rapprochement avec une source externe ;
5. règles déterministes et explicables ;
6. catégories simples + tags ;
7. transferts neutres ;
8. import/sync idempotent ;
9. projection qualifiée d'estimation ;
10. données exportables et protégées.

## 10. Décisions pour Budget

### Adopter

- échéances et inbox ;
- rapprochement ;
- ledger interne équilibré ;
- règles, tags et splits ;
- architecture locale modulaire ;
- backup chiffré ;
- normes d'accessibilité et gates stores.

### Adapter

- fonds/objectifs au contexte simple de Budget ;
- modules fiscaux et prévoyance selon région ;
- connexion bancaire selon marché ;
- catégorisation assistée, mais déterministe avant IA.

### Exclure maintenant

- copier une application ;
- « IA qui gère votre argent » ;
- conseil d'investissement ;
- initiation de paiement ;
- gamification agressive ;
- publicité ou vente de données ;
- automatisation qui affirme un paiement sans preuve.

## 11. Critère d'originalité

Avant chaque livraison inspirée par une référence :

- documenter le principe abstrait ;
- concevoir une composition propre à Budget Prisme ;
- utiliser les glyphes/tokens Budget ;
- écrire les textes de zéro ;
- ne reprendre aucun logo/actif sans droit ;
- comparer le résultat final et consigner qu'il n'est pas une copie.
