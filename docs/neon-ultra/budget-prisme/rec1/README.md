# REC1 — Cadences exactes (ADR-039) : preuves visuelles

Scénario (données fictives) : Netflix mensuel 17.90, Électricité
trimestrielle 180 (ancrée février), Assurance ménage semestrielle 240
(ancrée janvier), iCloud+ annuel 11.90 (mars).

- `abonnements-cadences-390.png` / `-320.png` — le héros dit le coût
  annuel EXACT : **CHF 1'426.70** = 4×180 + 2×240 + 12×17.90 + 11.90,
  avec le détail par rythme (« 1 trimestriel — CHF 180.00 par
  trimestre »…). Chaque ligne porte sa pilule (Trimestriel/Semestriel/
  Mensuel/Annuel), son vrai calendrier (« Quatre fois par an, dès
  février ») et sa comparaison honnête (« soit CHF 60.00 par mois »).
- `feuille-rythme-trimestriel-390.png` — la feuille : QUATRE pastilles
  de rythme, « Mois où elle tombe », note « Déduit 4 fois par an, à
  partir du mois choisi — jamais réparti sur les autres mois. »

Sonde : état injecté (version 1), rendu réel Chromium 390/320 px, zéro
erreur console. `four_weeks` volontairement absent (lot REC2 — preuve
native 13/an ajoutée dans RecurringScheduleServiceTests).
