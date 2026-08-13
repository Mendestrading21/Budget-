# Refonte complète Horizon

## Table des matières

1. Résultat cible
2. Audit de conservation
3. Architecture cible
4. Migration
5. Contrats de qualité
6. Interdictions

## Résultat cible

Transformer l'existant en un produit cohérent, et non appliquer un nouveau
thème sur d'anciens écrans. Repenser navigation, hiérarchie, composants,
microcopie, visualisation, états, accessibilité et parcours, tout en préservant
les règles financières, les données et les capacités utiles.

Le produit terminé doit être :

- compris en moins de dix secondes ;
- utilisable sans vocabulaire financier ;
- assez complet pour un foyer suisse réel ;
- vivant, tactile, reconnaissable et premium ;
- cohérent entre SwiftUI et PWA ;
- sûr pour les montants, migrations et sauvegardes.

## Audit de conservation

Créer une matrice avant les suppressions majeures :

| Élément | Usage réel | Décision | Remplacement | Preuve |
|---|---|---|---|---|
| Écran/action/service | Oui/non | Conserver/améliorer/fusionner/déplacer/remplacer/retirer | Cible | Test, recherche d'usage, capture |

Inspecter :

- routes, onglets, feuilles, deep links et écrans inaccessibles ;
- CRUD complet, formulaires, validations et confirmations ;
- modèles SwiftData, migrations, sauvegarde, import/export ;
- services de calcul, agrégats et formatage ;
- composants, tokens, styles locaux et duplications ;
- PWA, manifest, service worker, persistance et hors ligne ;
- tests unitaires, UI, web et CI ;
- textes, états vides, erreurs, données de démonstration ;
- performance, accessibilité et petits écrans.

Ne pas confondre « ancien visuellement » et « inutile métier ».

## Architecture cible

### Navigation principale

Utiliser cinq destinations au maximum :

1. Mois
2. Budget
3. Comptes
4. Objectifs
5. Plus

Placer mouvements, factures, abonnements, patrimoine, impôts, assurances,
analyses, import/export et réglages dans les destinations les plus naturelles.
Une action Ajouter globale peut accélérer les créations sans devenir un sixième
onglet.

### Structure de chaque écran

1. Question principale.
2. Réponse immédiate et contexte court.
3. Action primaire.
4. Visualisation ou liste utile.
5. Détails progressifs.
6. États vide, chargement, erreur et succès.

Limiter la profondeur de navigation. Le retour doit conserver filtres, période,
position de défilement et saisie lorsque pertinent.

### Système partagé

Centraliser :

- tokens de couleur, typographie, espace, rayon, ombre et matière ;
- composants d'action, saisie, carte, liste, badge, message et modal ;
- formats CHF/fr-CH et vocabulaire produit ;
- widgets et graphiques ;
- mouvement, haptique et reduced motion ;
- états asynchrones et erreurs ;
- règles d'accessibilité.

SwiftUI et PWA partagent le contrat, pas nécessairement l'implémentation.

## Migration

### Lot A — Cartographie et protection

Établir la matrice de conservation, exécuter les tests disponibles, sauvegarder
les preuves visuelles et identifier les risques de données.

### Lot B — Fondations

Stabiliser design tokens, composants, modèles de widgets, navigation cible,
formats, mouvement et contrats d'accessibilité.

### Lot C — Coquille produit

Migrer navigation, structure commune, ajout global, recherche, thème, gestion
des erreurs et système de feuilles.

### Lots D à I — Parcours verticaux

Migrer successivement Mois, Budget/Mouvements, Comptes/Patrimoine,
Factures/Charges suisses, Objectifs/Intelligence, Onboarding/Réglages.
Chaque lot inclut modèle, calcul, UI, états, accessibilité et tests.

### Lot J — Retrait contrôlé

Rechercher tous les usages avant retrait. Supprimer seulement lorsque la cible
couvre le comportement, les données migrent et les tests passent. Ne jamais
laisser deux systèmes actifs sans stratégie de transition.

### Lot K — Durcissement

Valider performance, offline, migration depuis une ancienne version, gros
volumes, petits écrans, clair/sombre, reduced motion, VoiceOver et erreurs.

## Contrats de qualité

Pour chaque parcours :

- aucun bouton factice ;
- action principale réalisable en peu d'étapes ;
- annulation et erreur sans perte de données ;
- termes compréhensibles et explications courtes ;
- état réel après relance ;
- résultat identique pour les mêmes données ;
- rendu clair, sombre, étroit et texte agrandi ;
- animation interrompable et alternative reduced motion ;
- tests couvrant règle métier et régression.

Une capture jolie ne prouve ni l'interaction, ni la persistance, ni le calcul.

## Interdictions

- Ne pas recréer l'application dans un nouveau dossier.
- Ne pas casser les identifiants ou migrations pour simplifier l'UI.
- Ne pas masquer une fonctionnalité utile faute de place.
- Ne pas supprimer un service parce qu'un écran ne l'utilise plus encore.
- Ne pas mener une refonte « big bang » impossible à vérifier.
- Ne pas déclarer la parité sur la base d'une maquette.
- Ne pas publier, fusionner ou déployer sans autorisation.
