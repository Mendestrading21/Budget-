# W5.1 — Inventaire mesuré des routes (25.08.2026)

Mesuré sur `main` à l'ouverture de W5 — la carte de ce que la
navigation OFFRE réellement, avant tout changement. ADR-026 prévaut :
cinq destinations stables, pas de bouton d'ajout global.

## Les cinq destinations (identiques des deux côtés)

| Id PWA (`TABS`) | Id natif (`AppRouter`) | Libellé |
|---|---|---|
| `home` | `.home` | Mois |
| `movements` | `.transactions` | Historique |
| `budget` | `.budget` | Budget |
| `accounts` | `.accounts` | Comptes |
| `more` | `.more` | Gérer |

## Sous-vues de « Gérer » (PWA, `MORE_RENDERERS`)

| Route (`moreView`) | Écran | Groupe du menu |
|---|---|---|
| `recurring` | Ce qui revient | Chaque mois |
| `subs` | Abonnements (filtre de `recurring`) | Chaque mois |
| `bills` | Factures | Chaque mois |
| `taxes` | Impôts | À prévoir |
| `insurance` | Assurances & prévoyance | À prévoir |
| `networth` | Patrimoine | À construire |
| `goals` | Objectifs | À construire |
| `year` | Année | À construire |
| `importcsv` | Import CSV & documents | Mes données |
| `assistant` | Assistant | Application |
| `settings` | Réglages | Application |
| `movements` | Historique (alias interne) | — (raccourcis) |

Chaque sous-vue s'ouvre par `[data-more]` et revient par `[data-back]`
vers le menu Gérer. Le natif porte les mêmes surfaces dans ses onglets
et feuilles (pas de huitième destination cachée).

## Ce que W5.1 verrouille (parcours 204)

1. Les CINQ destinations, ids et libellés EXACTS, dans l'ordre ADR-026.
2. Chaque destination s'ouvre par le vrai clic et rend un écran.
3. Chaque sous-vue de Gérer s'ouvre et son retour revient à Gérer.
4. Aucun bouton d'ajout global flottant.
5. Le moteur de rendu ne connaît aucune route morte : chaque clé de
   `MORE_RENDERERS` est atteignable depuis le menu (ou consignée comme
   alias), et chaque entrée du menu a son rendeur.
