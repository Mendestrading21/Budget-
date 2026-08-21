# ID1 — Clé d'identité stable (ADR-042) : preuve visuelle

État fictif : deux abonnements — « Mes films » avec `identityKey:
"netflix"` (ligne RENOMMÉE après choix au catalogue), « Mon club local »
en saisie libre sans clé.

- `abonnements-identite-stable-390.png` — la ligne renommée garde la
  tuile « N » (l'identité choisie prime sur le titre) ; la ligne libre
  garde le glyphe générique. Sonde DOM observée :
  `[{"r-club": null}, {"r-films": "N"}]`.

Rendu réel Chromium 390 px, zéro erreur console, données fictives.
