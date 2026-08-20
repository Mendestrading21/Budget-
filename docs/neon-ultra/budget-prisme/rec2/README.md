# REC2 — « toutes les quatre semaines » exact (ADR-040) : preuves visuelles

Scénario (données fictives) : Salle de sport 45.00 toutes les 4 semaines
(ancrée au 15.01.2026) + Netflix 18.90 mensuel.

- `abonnements-quatre-semaines-390.png` — le héros dit **CHF 811.80 par
  an** = 13 × 45 (585) + 12 × 18.90 (226.80) ; la ligne porte la pastille
  « Toutes les 4 semaines » et « 13 fois par an · soit CHF 48.75 par
  mois » ; le détail du héros sépare « 1 mensuel » et « 1 toutes les 4
  semaines ».
- `feuille-rythme-quatre-semaines-390.png` — la feuille « Ce qui
  revient » offre les cinq rythmes ; « Toutes les 4 semaines » ouvre le
  champ « Prochaine échéance » (le jour fait partie du rythme) et la note
  dit : « 13 fois par an, jamais 12. Certains mois portent deux
  échéances. »

Sonde : état injecté (version 1), rendu réel Chromium 390 px, zéro
erreur console. Coût annuel observé par sonde : 585.
