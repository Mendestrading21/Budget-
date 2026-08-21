# INV1-B — Garde de suppression des positions (ADR-049) : preuve visuelle

État fictif : compte titres à 44'000 avec une position « Actions
Monde » (VWRL).

- `garde-suppression-390.png` / `garde-suppression-320.png` — la feuille
  du compte après « Supprimer ce compte » : la suppression est BLOQUÉE
  en le disant — « Des positions expliquent ce compte — supprimez-les
  d'abord sur sa fiche. » Sans cette garde, les positions devenaient
  orphelines en silence (retirées à la prochaine restauration).

Rendu réel Chromium 390 px et 320 px, zéro erreur console, données
fictives.
