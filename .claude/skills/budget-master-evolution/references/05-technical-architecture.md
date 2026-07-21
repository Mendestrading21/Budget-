# Architecture cible

## Natif

Conserver Swift 5.10+, SwiftUI, SwiftData, iOS 17+, Swift Charts, MVVM léger, services purs et aucune dépendance externe sans décision. Injecter date, calendrier et taux pour rendre les tests déterministes.

## PWA

Découper progressivement sans réécriture totale :

1. core/state.js — stockage, migrations, sauvegarde.
2. core/money.js — centimes, devises, formatage.
3. domain/ — comptes, mois, impôts, patrimoine, projections.
4. components/ — cartes, boutons, feuilles, graphiques, glyphes.
5. views/ — un module par destination.
6. app.js — routeur et orchestration.

Garder le service worker simple, versionné et testé hors ligne.

## Parité

Créer des fixtures JSON communes couvrant opérations, comptes, budgets, taxes, dettes et devises. Exécuter les mêmes scénarios dans Swift et JavaScript. Documenter toute différence volontaire.

## Persistance

- Augmenter la version lors d'un changement de schéma.
- Migrer dans une copie ou transaction.
- Valider avant remplacement.
- Prévoir rollback et sauvegarde.
- Tester chaque version supportée.
- Ne pas retirer un champ sans phase de compatibilité.

## Connexions

Toute banque exige une ADR : fournisseur, pays, données lues, consentement, révocation, coût, backend, secrets, rétention, incidents et hors-ligne. Aucun secret dans l'app ou le dépôt. Sans ADR approuvée, rester sur import local et Raccourcis iOS.

## Performance

Calculer une fois par rendu, préfiltrer par période, mesurer avant d'optimiser. Tester 10 000 mouvements, 100 comptes et cinq ans d'historique.
