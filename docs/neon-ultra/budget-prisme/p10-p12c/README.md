# P10/P12-C — Icône choisie préservée (ADR-046) : preuve visuelle

État fictif : deux objectifs — « Ma voiture » avec l'emoji choisi 🚗 et
« Réserve discrète » sans emoji (glyphe neutre) — plus un bien
(« Vélo cargo », champ hérité `icon: "🚲"`) et une dette (« Prêt
vélo », `icon: "📄"`).

- `objectifs-icones-390.png` / `objectifs-icones-320.png` — capturés
  APRÈS une modification de chaque objectif (le toast « Objectif
  modifié » est visible) : 🚗 est toujours là, et la réserve garde son
  glyphe neutre — avant le correctif, elle recevait 🎯 dans le dos de
  la personne.
- `patrimoine-glyphes-390.png` / `patrimoine-glyphes-320.png` — biens
  et dettes portent le glyphe DÉRIVÉ de leur type ; les emojis stockés
  (🚲, 📄) ne sont jamais rendus, aucune marque commerciale.

Rendu réel Chromium 390 px et 320 px, zéro erreur console, données
fictives.
