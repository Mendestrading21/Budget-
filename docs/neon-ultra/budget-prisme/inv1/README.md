# INV1 — Positions manuelles datées (ADR-047) : preuve visuelle

État fictif : compte titres « Compte titres » (Swissquote) au solde de
CHF 44'000, une position « Actions Monde » (VWRL, 100 × 400.00, prix
saisi le 15.08.2026, prix d'achat 36'000).

- `fiche-positions-390.png` / `fiche-positions-320.png` — la fiche du
  compte titres : la position vaut CHF 40'000.00, « Espèces / non
  réparti » affiche CHF 4'000.00, et la phrase d'autorité dit que la
  valeur des positions plus les espèces égale le solde (44'000) — la
  fortune lit ce solde, jamais 84'000.
- `position-formulaire-390.png` / `position-formulaire-320.png` — la
  feuille Position : quantité, prix par part, « Prix saisi le » avec sa
  légende honnête (aucun cours du marché promis), prix d'achat
  facultatif, suppression qui ne change pas le solde.

Rendu réel Chromium 390 px et 320 px, zéro erreur console, données
fictives.
