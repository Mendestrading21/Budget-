# A22 — Grandes pastilles du hub Gérer

Demande propriétaire (18.08.2026, capture annotée) : « augmente encore un
peu les emojis, plus grand, centré dans un carré plus grand ».

- `avant-390.png` — pastilles 44 px, glyphe 20 px.
- `apres-390.png` — pastilles 54 px (rayon 15), glyphe 26 px, centré.
  Portée limitée aux entrées du hub (`.read-row[data-more]`) : les listes
  denses du Mois et de l'Historique gardent leur géométrie serrée.

Test 151 mis à jour : Mois et Historique identiques entre eux ; le hub
porte sa grande pastille uniforme 54/26. Contrôle négatif : règle retirée
→ échec ciblé (44x44 obtenu).
