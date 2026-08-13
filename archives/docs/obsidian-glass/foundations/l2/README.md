# Fondations Obsidian Glass — preuves L2

Captures de la galerie déterministe du design system
(`webapp/design-system/obsidian-gallery.html`), générées après la bascule de
l'identité unique sombre (ADR-020, ADR-022).

## Captures

| Fichier | Viewport | État d'accessibilité |
|---|---|---|
| `l2-pwa-gallery-390.png` | 390 × 844 (iPhone courant) | par défaut |
| `l2-pwa-gallery-320.png` | 320 × 844 (petit iPhone) | par défaut |
| `l2-pwa-reduced-transparency-390.png` | 390 × 844 | transparence réduite : verre remplacé par `glassFallback` `#151B26` opaque, blurs et halo supprimés |
| `l2-pwa-large-text-320.png` | 320 × 844 | texte agrandi 130 % (`html[data-large-text="true"]`) — aucun débordement |

## Méthode de génération

- Commit observé : branche `refonte/budget-obsidian-glass-v1`, état du lot L2
  (commit `feat(l2)` référencé dans `OBSIDIAN_GLASS_STATUS.md`).
- Date : 23.07.2026.
- Chromium headless (playwright-core, `deviceScaleFactor: 2`), page ouverte en
  `file://`, capture pleine page après interaction avec les bascules
  déterministes de la galerie (`#toggleTransparency`, `#toggleLargeText`).
- Zéro erreur console tolérée pendant la capture (le script échoue sinon).
- Reproductible : `node webapp/tests/design.test.mjs` vérifie les mêmes états
  automatiquement (tokens, parité, contrastes, 320/390, cibles 44 px, focus,
  reduced motion/transparency).

## Références visuelles retenues

- `visual/01_canonical_budget_identity.png` — identité, monogramme, palette
  graphite + indigo, sérieux financier.
- `visual/02_graph_and_glass_reference.jpeg` — profondeur du verre, reflet
  discret, hiérarchie des cartes sombres.
- `budget-horizon/…/07-high-contrast-dark-widgets.png` — contraste des
  montants héros et action principale.
- `budget-horizon/…/11-purple-dark-fintech.png` — usage MESURÉ d'un accent
  indigo unique.

## Éléments volontairement refusés

- Esthétique crypto/néon et glow permanent (interdits par la constitution).
- Palette multiple : les ex-teintes teal `#2DD4BF`, violet `#8B5CF6`, cyan
  `#55DDE0` et bleu électrique `#5AA7FF` sont réduites à des ALIAS de
  `brand`/`brandBright` — aucune seconde palette active.
- Thème clair et sélecteur d'apparence : identité sombre unique ; l'ancien
  champ `S.theme` reste stocké (compatibilité des sauvegardes) mais sans
  effet visuel.
- Copie littérale d'une application de référence : composition originale
  Budget, aucune reprise de nom, logo, texte ou mise en page exacte.
- Dégradés multicolores sur les boutons : fond indigo profond dérivé
  `#6457F0` pour garantir un texte blanc AA (5.04:1 mesuré).

## Preuve native

Les fondations SwiftUI (`DesignTokens`, `GlassCard`, `AmountText`,
`StatusPill`, boutons, `ObsidianSheetSurface`, états, galerie) sont
construites et testées par la CI macOS (`DesignSystemTests`, previews
compilées). La galerie native s'ouvre avec l'argument de lancement
`-obsidianGallery` (sans effet sur l'expérience Release) ; la capture
simulateur passera par le workflow Demo lors de la validation du pilote
iOS (L4) — le simulateur n'existe pas dans cet environnement Linux.
