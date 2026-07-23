# Livraison Horizon

## Lots recommandés

Adapter l'ordre à l'état réel, sans refaire les lots déjà prouvés.

0. Audit : branche, diff, architecture, matrice de conservation, données, tests,
   captures avant et risques P0-P3.
1. Fondations : tokens, composants, navigation, mouvement, widgets et finance
   engine partagé.
2. Coquille produit : navigation cible, ajout global, recherche, thèmes, erreurs.
3. Mois : disponible, priorité, actions rapides et accueil personnalisable.
4. Mouvements et budget : CRUD, prévisions, récurrents, réconciliation.
5. Comptes et patrimoine : historique, transferts, actifs, dettes, projections.
6. Suisse : impôts, factures, assurances, 3a/prévoyance et textes honnêtes.
7. Objectifs, assistant et pédagogie : scénarios, progression, explications.
8. Onboarding, réglages, sauvegarde/import/export et confidentialité.
9. Retrait contrôlé : doublons et ancien design uniquement après parité prouvée.
10. Qualité et release : accessibilité, performance, CI, appareil réel, store.

## Gates PWA

- Syntaxe JS et suite Chromium vertes.
- Zéro erreur console.
- CRUD et persistance après rechargement.
- Service worker, manifest, icônes et mode hors ligne vérifiés.
- Safe areas, plein écran iPhone, thème persistant, clavier et 320 px.
- Aucun débordement horizontal, bouton mort ou promesse native trompeuse.

## Gates iOS

- Build Debug et Release sur runner macOS/Xcode compatible.
- Tests unitaires et tests UI critiques verts.
- SwiftData sur store disque, migration et restauration testées.
- VoiceOver, Dynamic Type, contraste, cibles 44 pt, thèmes et reduced motion.
- Aucun crash, warning critique ou erreur de persistance masquée.

## CI et Git

- Préserver les changements de l'utilisateur ; pas de commande destructive.
- Un commit par lot cohérent, message décrivant le résultat.
- La CI doit bloquer une régression critique et conserver les artefacts utiles en
  cas d'échec.
- Corriger avant de poursuivre si une gate du lot échoue.
- Ne pas confondre « non exécutable ici » et « validé ».

## Définition de prêt à publier

- Parcours essentiels complets sur PWA et iOS selon leur périmètre déclaré.
- Calculs réconciliés et tests de non-régression verts.
- QA réelle sur iPhone et migration depuis une version existante.
- Textes confidentialité/support complets.
- Prix, pays, conformité et compte Apple décidés humainement.
- Publication, fusion, Pages, TestFlight ou App Store uniquement après accord
  explicite du propriétaire.

## Rapport attendu

Pour chaque lot : résultat utilisateur, critères terminés, fichiers principaux,
commandes/tests et résultats, preuves visuelles si utiles, risques connus,
prochaine action exacte.
