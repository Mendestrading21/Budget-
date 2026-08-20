# FE2-12 — Impôts 100 % manuels (ADR-035) : preuves visuelles

Scénario : l'état EXACT de la capture du propriétaire (20.08.2026) —
`taxRate: 0.3` encore stocké sur l'appareil, compte courant CHF 10'000,
salaire de CHF 2'000 à recevoir, aucune facture.

- `mois-finmois-taux-herite-inerte-390.png` — la position « Fin du mois »
  dit désormais **CHF 12'000.00** avec la note « CHF 10'000.00 maintenant
  + CHF 2'000.00 à recevoir. » Le taux hérité de 30 % ne produit plus
  JAMAIS de « − CHF 600.00 d'impôts à mettre de côté » : plus aucune
  formule ne le lit (données de l'appareil intactes).
- `impots-page-manuelle-390.png` — la page Impôts additionne ce qui est
  noté : « Payé en 2026 », « Déjà mis de côté » (envois + report),
  « Vos prochains acomptes » (des factures « Impôts » à saisir soi-même),
  boutons « Ajouter un acompte » et « Corriger mon report ». Aucune
  estimation, aucun taux.

Sonde : injection de l'état ci-dessus dans `budget-app-state-v1`
(version 1), rendu réel dans Chromium 390 px, zéro erreur console.
Données entièrement fictives.
