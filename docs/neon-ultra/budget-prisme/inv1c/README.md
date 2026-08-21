# INV1-C — Le type d'un compte à positions ne change pas en silence (ADR-050) : preuve visuelle

État fictif : compte titres à 44'000 avec une position.

- `garde-type-390.png` / `garde-type-320.png` — la feuille du compte
  après une tentative de passage en « Compte épargne » : l'enregistrement
  est BLOQUÉ en le disant — « Des positions expliquent ce compte —
  supprimez-les avant de changer son type. » Sans cette garde, les
  positions devenaient invisibles (la section ne vit que sur la fiche
  d'un compte titres) alors que la suppression du compte restait
  bloquée en pointant cette fiche : une impasse.

Rendu réel Chromium 390 px et 320 px, zéro erreur console, données
fictives.
