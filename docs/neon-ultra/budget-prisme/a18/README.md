# A18 — L'onboarding ne demande plus de taux d'impôts

Demande propriétaire (18.08.2026, capture annotée en rouge) : « Déjà
enlevé le taux d'impôts, on s'en fout. »

- `avant-390.png` — l'étape salaire posait aussi « Part mise de côté
  pour les impôts (%) » avec sa légende.
- `apres-390.png` — l'étape ne demande plus que le salaire. Le taux
  d'impôts prend le défaut du pays (30 % pour la Suisse) et reste
  modifiable dans Gérer → Impôts, borné 0–60 %.

Tests : parcours 56 (champ absent, défaut appliqué à la fin) et 136
(la borne 0–60 % de la feuille Impôts vérifiée EN VRAI : 61 refusé avec
message, 25 accepté, état rendu). Contrôles négatifs : champ réintroduit
→ 1 échec ciblé ; borne retirée → 1 échec ciblé.
