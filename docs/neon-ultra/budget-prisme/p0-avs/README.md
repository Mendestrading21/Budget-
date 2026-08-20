# P0 AVS — une rente n'est pas un capital (ADR-036) : preuves visuelles

Scénario (données fictives) : LPP 85'000 (capital), « Rente AVS estimée »
2'450 marquée rente, ligne ambiguë « AVS » 1'200 non marquée.

- `prevoyance-rente-hors-patrimoine-390.png` / `-320.png` — l'écran
  Assurances & prévoyance : « Déjà mis de côté » vaut **CHF 86'200.00**
  = 85'000 (capital) + 1'200 (ambiguë, comptée telle quelle en attendant
  confirmation) — la rente marquée de 2'450 est EXCLUE. Sonde DOM
  observée : la ligne rente dit « Rente estimée — hors patrimoine ·
  montant tel que saisi », la ligne ambiguë porte « À confirmer : rente
  ou capital ? ».

Sonde : état injecté dans `budget-app-state-v1` (version 1), rendu réel
Chromium 390 et 320 px, zéro erreur console.
