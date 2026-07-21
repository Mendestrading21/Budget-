# Portes qualité

## Définition de fini

Un lot est fini seulement si : critères acceptés, tests nouveaux, tests existants verts, inspection visuelle, accessibilité, migration si nécessaire, documentation exacte, commit isolé et CI verte.

## Matrice

| Changement | Tests requis |
|---|---|
| Calcul | unité, bords, fixture de parité |
| Persistance | création, relance, migration, rollback |
| Formulaire | valide, vide, invalide, annulation, clavier |
| Écran | vide, données, volume, texte long, accessibilité |
| Suppression | confirmation, annulation, relations |
| Import | doublon, rejet, format suisse, rollback |
| Sauvegarde | round-trip, corruption, version future |
| Graphique | vide, constant, négatif, résumé accessible |

## Commandes

- Web : node webapp/tests/e2e.test.mjs avec Chromium configuré.
- Natif : build Debug, xcodebuild test, puis build Release.
- UI : workflow Demo ou simulateur avec captures.

Adapter la destination aux simulateurs disponibles sans diminuer la couverture.

## Contrôles statiques

- Rechercher TODO, FIXME, try?, secrets, URLs, devises codées en dur et flottants monétaires.
- Comparer contrôles interactifs rendus et handlers.
- Vérifier que chaque erreur informe l'utilisateur.
- Vérifier chaînes non localisées et jargon interdit.

## Visuel

Contrôler iPhone compact/récent, clair/sombre, grande taille de texte, mouvement réduit, clavier web, safe areas et orientation supportée.

## Échec CI

Lire le journal exact, reproduire, corriger la cause, ajouter un test si nécessaire, pousser et attendre le vert. Ne jamais relancer au hasard ni masquer un test.
