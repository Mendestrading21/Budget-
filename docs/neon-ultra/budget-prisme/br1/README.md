# BR1 — Provenance des marques (ADR-048) : preuve visuelle

- `reglages-marques-390.png` / `reglages-marques-320.png` — la carte
  « Marques et logos » des réglages, dépliée : « Les noms et marques
  appartiennent à leurs propriétaires respectifs… Budget n'est ni
  affilié, ni sponsorisé, ni connecté… », et l'état vrai d'aujourd'hui
  (aucun logo tiers — nom + monogramme neutre dessiné par Budget).

Le reste du lot est structurel et prouvé par la suite catalogue :
manifeste `fixtures/provenance-marques.json` (zéro entrée = couverture
complète) et validateur (champs exigés, checksums exacts, entrées
orphelines refusées, `approved_asset` interdit sans manifeste).

Rendu réel Chromium 390 px et 320 px, zéro erreur console, données
fictives.
