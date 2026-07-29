# Constitution visuelle — Budget Neon Ultra

Direction canonique autorisée par le propriétaire le 27.07.2026 (ADR-024).
Elle remplace la direction « Obsidian Glass / accent indigo unique »
(ADR-020/022) UNIQUEMENT pour les clauses visuelles. Toutes les règles
financières, techniques, de confidentialité, de sauvegarde, d'accessibilité et
de publication restent en vigueur.

## 1. Palette canonique

### Fonds et surfaces

| Rôle | Valeur | Usage |
|---|---|---|
| Canvas | `#05060A` | fond d'écran global |
| Navigation | `#0B0D13` | barre d'onglets, barres système |
| Surface standard | `#11141C` | cartes de listes, cellules |
| Surface élevée | `#181C26` | héros, feuilles, éléments surélevés |
| Fallback opaque | `#151923` | remplace tout verre/blur quand Reduce Transparency est actif |
| Bordure | `#293040` | séparations, contours de cartes |

### Néons (accents de marque)

| Rôle | Valeur | Usage |
|---|---|---|
| Magenta | `#D946EF` | accent principal de marque |
| Violet | `#7C3AED` | accent secondaire, états actifs |
| Cyan | `#38BDF8` | accent d'information, sélection de graphique |
| CTA profond | dégradé `#C000A4 → #6E00E8` | bouton d'action principal uniquement |

### Textes

| Rôle | Valeur |
|---|---|
| Principal | `#F5F7FA` |
| Secondaire | `#A3ACBA` |
| Discret | `#7C8696` |

Correction AA du 27.07.2026 (clôture NU0) : le texte discret initial
`#747E8E` mesurait 4,49:1 sur surface standard, 4,15:1 sur surface élevée et
4,28:1 sur le fallback opaque — sous le seuil AA de 4,5:1 pour du texte
courant. La valeur canonique est `#7C8696`, mesurée : canvas 5,50:1 ·
navigation 5,28:1 · surface standard 5,00:1 · surface élevée 4,63:1 ·
fallback opaque 4,78:1.

### Sémantique financière (jamais décorative)

| Rôle | Valeur |
|---|---|
| Positif (entrées, progrès sain) | `#35D39A` |
| Négatif (sorties, dépassement) | `#FF6577` |
| Alerte (à surveiller) | `#F6C453` |

## 2. Règles de composition

1. **Proportions** : 75 % noir/graphite, 15 % neutres, 10 % maximum de néon
   par écran.
2. **Un seul point focal lumineux majeur par viewport** (le héros OU le CTA,
   jamais les deux en même temps au même niveau d'intensité).
3. **Gradient** réservé exclusivement au CTA principal, à l'état de sélection
   et aux moments de marque (onboarding, écran d'identité). Jamais sur les
   cartes de listes.
4. **Aucun glow autour des montants** : les chiffres financiers restent en
   texte net, contrasté, sans halo.
5. **Vert, corail et ambre restent exclusivement sémantiques** : jamais
   utilisés comme décoration ou accent de marque.
6. **Cartes de listes mates** : pas de blur lourd, pas de verre décoratif sur
   les listes denses.
7. **Aucun clignotement, pulsation infinie, confetti ni esthétique
   casino/crypto.** Budget est une app de confiance, pas une machine à sous.
8. **Animations courtes et utiles** (~150–250 ms), déclenchées par une action,
   jamais permanentes.
9. **Violet et petits libellés** : `brandViolet #7C3AED` mesure environ
   3,41:1 sur la navigation `#0B0D13`. Il peut servir pour des icônes
   suffisamment grandes, des bordures et des indicateurs graphiques, mais
   JAMAIS seul pour un petit libellé actif. Le texte actif reste
   `textPrimary #F5F7FA`, accompagné d'un indicateur violet, sauf autre
   paire réellement mesurée à ≥ 4,5:1.

## 3. Accessibilité (non négociable)

- **Reduce Transparency** : rendu opaque sans blur — toutes les surfaces
  translucides basculent sur `#151923`.
- **Reduce Motion** : animations supprimées ou réduites ; aucun mouvement
  d'entrée, compteur ou transition décorative.
- **Contraste** : texte courant WCAG AA (≥ 4.5:1) sur toutes les surfaces ;
  vérifié par le test design system (les paires texte/surface et
  sémantique/canvas sont mesurées, pas estimées).
- **Cibles tactiles ≥ 44 pt** partout (boutons, chips, lignes de hub,
  scrubbers de graphiques).
- **Dynamic Type** (iOS) et équivalents web respectés ; VoiceOver et lecteurs
  d'écran couverts (libellés réels, jamais la couleur seule).
- **Montants CHF longs, négatifs et à sept chiffres toujours lisibles** — ni
  troncature du signe, ni chevauchement, à 320 px comme en accessibility3.

## 4. Hiérarchie et langage

- Chaque écran répond à une question principale et propose une action
  évidente ; mots imposés : « Disponible », « À payer », « Dépensé »,
  « Mis de côté », « Patrimoine ».
- Français simple compréhensible par un enfant de dix ans ; format `fr-CH`.
- Les graphiques restent pédagogiques avant d'être spectaculaires ; la
  sélection utilise le cyan, les séries gardent leurs couleurs sémantiques.

## 5. Référence artistique

L'image d'inspiration vit dans `../assets/visual/` (voir
`REFERENCE_INDEX.md`). Inspiration de direction artistique seulement : ne
jamais copier un texte, un nom, un personnage, une marque ou un écran exact.

## 6. Ce que cette constitution ne change pas

- Aucune formule, agrégat, migration, clé localStorage, sauvegarde,
  service worker, bundle identifier, signature, PrivacyInfo, cible
  iPhone-only ([1]) ni donnée de démonstration.
- La navigation suit ADR-026 : cinq destinations identiques PWA/iOS
  (`Mois · Historique · Budget · Comptes · Gérer`), sans bouton global
  central ou flottant. Cette convergence ne modifie aucune règle financière.
