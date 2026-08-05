# Audit visuel des 16 écrans

Demande du propriétaire (05.08.2026) : « continue le peaufinage, aucune erreur
visuelle, icônes, tout tout. »

L'audit est **mécanique et reproductible** :
`.claude/skills/budget-neon-ultra/assets/tools/audit-visuel.mjs` parcourt les
5 onglets et les 11 sous-écrans avec des données fictives déterministes, et
cherche à chaque fois ce qu'un œil rate :

- une pastille d'icône **non carrée ou non dimensionnée** ;
- un **débordement horizontal** de l'écran ;
- une **cible tactile sous 44 px** (hors doublons masqués) ;
- un **texte réellement tronqué** (`scrollWidth > clientWidth` **et**
  `text-overflow: ellipsis`).

```
W=390 BUDGET_CHROMIUM=/chemin/vers/chrome \
  node .claude/skills/budget-neon-ultra/assets/tools/audit-visuel.mjs
```

Résultat actuel : **16/16 écrans propres à 390 px et à 320 px**, zéro erreur
console. Une capture par écran et par largeur est conservée ici (32 fichiers).

## Cinq défauts trouvés et corrigés

1. **Le badge « Prévu » était rogné jusqu'à 95 px** — donc totalement
   invisible sur 7 lignes sur 10 à 320 px. Or « prévu » et « comptabilisé »
   sont un invariant du produit, et ce badge était le seul signal sur la
   ligne : deux mouvements de nature opposée devenaient identiques. Le titre
   cède désormais la place ; le badge reste entier.
2. **L'icône de la carte de sauvegarde s'étalait sur 324 × 19 px.** La carte
   avait oublié la classe `tx`, donc la pastille n'héritait d'aucune taille :
   l'emoji se collait à gauche d'un rectangle teinté qui ressemblait à un bug
   d'affichage. Seul cas du code, désormais aligné sur les autres lignes.
3. **Les noms étaient tronqués dans les listes de gestion** à 320 px —
   comptes (« Compte ménage »), factures (« Électricité (trimestre) »,
   « SERAFE (redevance) »), factures mensuelles. Le projet a déjà sa règle
   pour ça (`read-row`, appliquée aux Actifs et à la Prévoyance) : dans une
   liste de gestion, le nom **est** l'information. Elle leur est étendue. La
   liste dense des mouvements garde son ellipse, choix assumé (L5).
4. **Un libellé long collait son montant** dans les récapitulatifs
   (« … à payer »+« CHF 519.30 » se touchaient à 320 px). Le bloc gagne une
   respiration et le montant ne se comprime plus.
5. **Une pastille d'état touchait son titre** faute de marge — même
   respiration que les badges.

## Preuve

Parcours e2e n° 97 : à **390 px et à 320 px**, il vérifie qu'aucun état n'est
rogné dans l'historique, qu'aucun nom n'est coupé dans les trois listes de
gestion, et que toute pastille d'icône reste carrée sur cinq écrans.
Contrôle négatif effectué : en réintroduisant les trois premiers défauts, la
suite produit huit échecs nommés.
