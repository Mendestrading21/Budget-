# A15 — Mois futur : quatre blocs et bouton « Planifier »

Preuves visuelles du lot A15 (PR #56), données entièrement fictives
(sonde d'onboarding : Elio, salaire 18 200, solde 156 000, puis
Électricité 90, Streaming vidéo 21.90, Mise de côté 2 000).
Mois observé : le mois suivant le mois courant (futur).

- `avant-390.png` — avant le lot : le mois futur n'a qu'une liste
  « Prévu ce mois », sans aucun bouton (0 bloc).
- `apres-390.png` — après : les MÊMES quatre blocs que le mois courant
  (Rentrées, Dépenses, Abonnements, Mis de côté), compteurs « 1 prévu »,
  bouton « Planifier » à la couleur de son sens sur chaque ligne, aucun
  bouton de confirmation.
- `apres-390-planifie.png` — après un appui sur « Planifier » du
  salaire : toast « “Salaire” planifié », mouvement créé PRÉVU
  (`planned`, daté fin de mois), la ligne dit « · Prévu » sans bouton.
- `apres-320.png` — même écran à 320 px : boutons sous la ligne, aucun
  débordement horizontal, aucun montant coupé.

Contrôles négatifs consignés dans le message de commit du lot :
gate futur rétabli → 8 échecs ciblés ; confirmation future autorisée →
1 échec ciblé (`boutonRestant: true`).
