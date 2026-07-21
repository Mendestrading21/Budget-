# Audit complet — Budget

Date : 21.07.2026  
Dépôt : `Mendestrading21/Budget-`  
Branche auditée : `claude/execute-tbkhsd`  
Branche de travail : `codex/audit-simplicite-budget`

## 1. Verdict

Budget possède déjà une base technique sérieuse : application native SwiftUI/SwiftData, PWA installable, calculs financiers testés, import/export, sauvegarde, sécurité locale native, CI et parcours navigateur.

Le principal risque produit n'est plus le manque de fonctions. C'est la densité : trop d'informations et trop de vocabulaire financier peuvent donner l'impression d'une application compliquée. Pour viser un public très large, Budget doit devenir un rituel de quelques minutes par mois, avec une lecture immédiate :

1. Combien ai-je reçu ?
2. Combien ai-je dépensé ?
3. Qu'est-ce qui reste à payer ?
4. Combien ai-je mis de côté ?
5. Où en est mon patrimoine ?

La V1 doit exceller sur ces cinq questions avant d'ajouter de nouvelles fonctions.

## 2. État réel du produit

| Domaine | État | Verdict |
|---|---|---|
| App iOS native | SwiftUI, SwiftData, iOS 17+, tests et build Release | Base solide |
| App web | PWA hors ligne, installable, données en localStorage | Très utile pour tester, moins sûre que le natif |
| Navigation | Accueil, Mouvements, Budget, Comptes, Plus | Bonne architecture |
| Calculs | Virements neutres, épargne distincte des dépenses, impôts, dettes, patrimoine | Logique mature |
| Qualité | Environ 190 tests natifs et 22 parcours navigateur documentés | Très bon niveau pour une V1 |
| Distribution | GitHub Pages opérationnel, pipeline TestFlight préparé | Appareil réel et compte Apple encore nécessaires |
| Monétisation | Prix unique CHF 6 proposé, non validé | Décision produit restante |
| Connexions bancaires | Aucune | Cohérent avec l'offline-first, mais saisie manuelle à simplifier |

## 3. Score avant cette intervention

| Axe | Note / 10 | Lecture |
|---|---:|---|
| Cohérence produit | 8 | Vision claire : mois + patrimoine |
| Logique financière | 9 | Bonnes conventions et tests |
| Simplicité immédiate | 5 | Accueil trop long, jargon encore présent |
| Design | 7 | Glass sombre cohérent, mais hiérarchie perfectible |
| Fiabilité | 8 | CI et tests solides ; QA appareil manquante |
| Accessibilité | 7 | Clavier, VoiceOver et mouvement réduit pris en compte |
| Confidentialité native | 9 | Local, biométrie, fichiers protégés |
| Confidentialité PWA | 5 | localStorage non chiffré, code de verrouillage visuel |
| Maintenabilité web | 4 | Un fichier HTML d'environ 220 000 caractères et plus de 100 fonctions |
| Préparation commerciale | 6 | Store préparé, validations humaines absentes |

## 4. Audit parcours par parcours

### Bienvenue

Points forts :

- cinq étapes maximum ;
- choix du pays, du foyer, des prénoms, des revenus et des comptes ;
- comptes ajoutables en un geste ;
- démonstration facultative.

À améliorer :

- expliquer le résultat attendu en une phrase : « En 2 minutes, vous verrez ce qu'il vous reste ce mois » ;
- proposer trois profils de départ : Simple, Famille, Complet ;
- permettre de terminer sans saisir le salaire ni le solde ;
- demander les détails avancés plus tard, au moment où ils deviennent utiles.

### Accueil

Problème principal trouvé : l'écran enchaînait le disponible, quatre indicateurs, le check, les revenus, les factures, les dépenses, les envois, le budget, les paiements à venir et le patrimoine. Toutes les informations sont utiles, mais pas au même moment.

Correction de cette branche :

- quatre actions directes : Dépense, Revenu, Épargne, Investir ;
- accueil essentiel visible immédiatement ;
- contenu avancé replié derrière « Voir tous mes détails » ;
- préférence conservée ;
- pictogrammes SVG propres à Budget pour les opérations ;
- vocabulaire de comptes simplifié.

Cible suivante :

- une seule recommandation prioritaire à la fois ;
- état vide guidé : « Ajoutez votre première dépense » ;
- mini bilan en langage naturel, par exemple « Il vous reste CHF 2'140 après les factures ».

### Mouvements

Points forts :

- recherche, filtres, duplication, modification, suppression ;
- distinction prévu/comptabilisé ;
- comptes source et destination.

À améliorer :

- remplacer « Comptabilisé » par « Payé » ou « Reçu » dans l'interface grand public ;
- montrer les filtres avancés uniquement à la demande ;
- proposer les derniers intitulés et montants ;
- ajouter un bouton « Répéter le mois prochain » après la saisie ;
- permettre une catégorisation rapide par pictogrammes.

### Budget

Points forts :

- planifié et réel séparés ;
- hors budget réconcilié ;
- copie du mois précédent ;
- grille annuelle.

À améliorer :

- démarrer avec trois enveloppes simples : Nécessaire, Plaisir, Épargne ;
- cacher les sous-catégories tant que l'utilisateur ne les demande pas ;
- présenter le reste à dépenser avant les variances ;
- remplacer le jargon « Hors budget » par « Pas encore classé » ;
- proposer un budget automatiquement à partir des trois derniers mois, avec validation explicite.

### Comptes

Points forts :

- plusieurs types de comptes et devises ;
- solde dérivé ;
- réconciliation ;
- historique et courbe ;
- versements cumulés pour les placements.

À améliorer :

- utiliser « Mettre le solde à jour » au lieu de « Réconcilier » ;
- distinguer visuellement Argent disponible, Épargne, Investissements et Dettes ;
- afficher la dernière mise à jour ;
- ajouter une action « Transférer entre mes comptes » directement sur la fiche ;
- regrouper les comptes archivés et avancés.

### Plus

Points forts :

- couverture très complète : objectifs, paiements réguliers, impôts, assurances, prévoyance, patrimoine, documents, import et réglages.

Risque : dix destinations dans un menu secondaire recréent une sensation de complexité.

Cible :

- Aujourd'hui : objectifs, paiements réguliers, impôts ;
- Patrimoine : prévoyance, actifs, dettes, assurances ;
- Données : documents, import, sauvegarde ;
- Réglages : foyer, devise, confidentialité.

## 5. Audit de la logique financière

Les invariants importants sont correctement pensés :

- une dépense réduit le compte source et le résultat du mois ;
- un revenu augmente le compte et le résultat du mois ;
- un virement entre comptes n'est ni un revenu ni une dépense ;
- un versement vers l'épargne ou un placement conserve le patrimoine net ;
- un remboursement de dette réduit le cash et la dette ;
- le planifié ne doit jamais modifier le solde réel ;
- les opérations ne doivent jamais être comptées deux fois ;
- l'app native utilise `Decimal`.

Risque important restant : la PWA utilise les nombres JavaScript. L'affichage arrondit correctement, mais la logique ne garantit pas la précision décimale parfaite sur toutes les additions. Avant de considérer la PWA comme produit financier définitif, les montants doivent être stockés en centimes entiers ou traités par un moteur décimal.

Autres points à durcir :

- recalculer la date courante après un passage de minuit ou de mois sans rechargement ;
- documenter précisément la méthode de conversion multi-devises ;
- ajouter des tests de propriété sur des milliers d'opérations aléatoires ;
- ajouter une migration versionnée de l'état PWA au lieu d'un unique `version: 1`.

## 6. Sécurité et confidentialité

### Native

Bon niveau pour une V1 hors ligne :

- SwiftData local ;
- verrouillage biométrique avec repli système ;
- protection des fichiers ;
- sauvegarde et restauration versionnées ;
- aucun SDK tiers ni backend annoncé.

### PWA

À présenter honnêtement comme une version pratique, pas comme un coffre-fort :

- les données sont dans localStorage ;
- le code PIN masque l'affichage mais ne chiffre pas les données ;
- toute personne ayant un accès technique au navigateur peut potentiellement lire le stockage ;
- effacer Safari ou les données du site peut supprimer les informations sans sauvegarde.

Priorité : afficher un rappel de sauvegarde, proposer une sauvegarde automatique locale chiffrée, ou réserver les données sensibles à l'app native.

## 7. Architecture et qualité du code

Points forts :

- séparation claire des modèles, services et écrans dans le natif ;
- services purs et testables ;
- CI macOS et navigateur ;
- décisions techniques documentées ;
- absence de dépendances applicatives tierces côté natif.

Dette technique principale :

- `webapp/index.html` est un monolithe d'environ 4 200 lignes ;
- état, calculs, rendu, formulaires et navigation vivent ensemble ;
- une modification locale peut avoir un effet global difficile à voir ;
- la PWA et le natif peuvent diverger.

Découpage recommandé :

1. `state.js` — stockage et migrations ;
2. `money.js` — centimes, devises et formatage ;
3. `domain.js` — règles financières ;
4. `views/` — écrans ;
5. `components/` — cartes, boutons, graphiques, pictogrammes ;
6. `tests/` — invariants unitaires + parcours E2E.

La source de vérité fonctionnelle doit être explicite. Recommandation : règles métier natives documentées, mêmes jeux de fixtures partagés avec la PWA, puis tests de parité.

## 8. Connexions et automatisations

Les connexions bancaires ne doivent pas être ajoutées comme un simple bouton décoratif. Elles impliquent un fournisseur, un backend, du consentement, de la sécurité, des coûts et une couverture variable selon les banques.

Ordre recommandé :

1. saisie manuelle ultra-rapide ;
2. import CSV guidé ;
3. import récurrent et détection de doublons ;
4. raccourcis iOS « Ajouter une dépense » ;
5. seulement ensuite, étude d'une connexion bancaire en lecture seule.

Toute connexion doit montrer clairement : banque, dernière synchronisation, comptes importés, erreurs, doublons et bouton de déconnexion.

## 9. Feuille de route vers une application grand public

### P0 — confiance

- QA complète sur un iPhone réel ;
- test de migration avec de vraies données ;
- centimes entiers dans la PWA ;
- sauvegarde guidée et rappel de sécurité ;
- CI verte obligatoire avant fusion.

### P1 — simplicité

- accueil essentiel ;
- langage sans jargon ;
- états vides guidés ;
- ajout en moins de trois gestes ;
- hiérarchie du menu Plus ;
- pictogrammes cohérents et personnalisables.

### P2 — rétention

- clôture mensuelle en moins de cinq minutes ;
- bilan hebdomadaire et mensuel ;
- suggestions basées sur l'historique, toujours validées par l'utilisateur ;
- rappels locaux ;
- progression des objectifs et célébrations sobres.

### P3 — croissance

- TestFlight ;
- dix à vingt foyers pilotes ;
- mesure anonyme uniquement avec consentement, ou entretiens qualitatifs ;
- support et confidentialité publiés ;
- positionnement commercial et prix validés ;
- connexion bancaire étudiée après validation de l'usage manuel.

## 10. Critères de réussite

Budget est prêt à viser un large public quand :

- un nouvel utilisateur comprend l'accueil en moins de dix secondes ;
- une dépense se saisit en moins de trois gestes après ouverture ;
- un mois se clôture en moins de cinq minutes ;
- aucun chiffre n'est inexpliqué ;
- aucune opération n'est doublée ;
- aucune perte de données n'est possible sans avertissement clair ;
- les parcours principaux passent sur appareil réel ;
- le web et le natif donnent les mêmes résultats sur les mêmes données.

## 11. Changements livrés avec cet audit

- accueil PWA simplifié ;
- quatre actions rapides visibles ;
- détails avancés repliables et mémorisés ;
- pictogrammes financiers SVG propres à Budget ;
- libellés de comptes simplifiés ;
- « Récurrents » renommé « Paiements réguliers » ;
- nouveau parcours navigateur dédié à l'accueil simple ;
- suite annoncée à 23 parcours.
