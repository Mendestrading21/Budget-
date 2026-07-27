# NU1 — Fondations Neon Ultra : preuves (27.07.2026)

Tokens et primitives Neon Ultra livrés en FAMILLES PARALLÈLES ISOLÉES sur les
deux plateformes. **Aucun écran réel de Budget n'a changé d'apparence** : la
PWA publique n'a reçu aucune modification (`webapp/index.html`, `sw.js`,
`manifest`, `obsidian.css` : intouchés) et aucun écran SwiftUI ne référence
les nouveaux rôles. Le rebranchement est réservé à NU2 (PWA) et NU3 (iOS).

## 1. Architecture livrée

| Plateforme | Tokens | Primitives | Galerie isolée |
|---|---|---|---|
| iOS | `NeonUltraColor` / `NeonUltraGradient` / `NeonUltraRadius` / `NeonUltraMotion` / `NeonUltraTypography` (ajout parallèle en fin de `DesignTokens.swift` — `BudgetColor`/`BudgetTheme`/alias Obsidian inchangés) | `NeonUltraComponents.swift` : cartes mate/élevée, styles de bouton CTA-gradient/secondaire/destructif, chip (3 états), badge ×4, `NeonUltraAmountText` (FinanceFormatting, sans glow), anneau de focus cyan, `NeonUltraSurfaceResolver` (Reduce Transparency → `#151923`) | `NeonUltraComponentGallery.swift` — construite UNIQUEMENT par le harness `UIHostingController` des tests, reliée à aucun écran/onglet |
| PWA | `webapp/design-system/neon-ultra.css` — variables `--nu-*` (aucune collision), valeurs brutes uniquement dans `:root` | classes `.nu-*` : cartes, boutons, chips, badges, champs, montants fluides (`min(rem, vw)` = équivalent du `minimumScaleFactor` SwiftUI) | `webapp/design-system/neon-ultra-gallery.html` — seule page qui charge `neon-ultra.css` |

Parité sémantique PWA ↔ iOS verrouillée par test (17 rôles de couleur, rayons
26/18/14, mouvement 140/240 ms, pression 0,98).

## 2. Contrastes mesurés (WCAG, jamais estimés)

| Paire | Mesure |
|---|---|
| textPrimary `#F5F7FA` / canvas · navigation · surface · élevée · fallback | 18,87 · 18,10 · 17,15 · 15,87 · 16,37 |
| textSecondary `#A3ACBA` / les cinq surfaces | 8,84 · 8,48 · 8,04 · 7,44 · 7,67 |
| textTertiary `#7C8696` / les cinq surfaces | **5,50 · 5,28 · 5,00 · 4,63 · 4,78** (minimums contractuels NU0) |
| textOnCta `#FFFFFF` (blanc pur) / CTA `#C000A4` → `#6E00E8` | **5,56 · 7,43** (les deux extrémités ≥ 4,5 ; `textPrimary #F5F7FA` mesurait 5,18 / 6,92 — d'où le rôle dédié blanc pur, conforme au contrat « texte blanc ») |
| positive `#35D39A` · negative `#FF6577` · warning `#F6C453` / canvas | **10,55 · 7,12 · 12,48** |
| focus cyan `#38BDF8` / les cinq surfaces (non textuel) | ≥ 3:1 partout (9,45 sur canvas, 8,20 sur fallback) |
| violet `#7C3AED` / navigation | **3,41** → règle appliquée : jamais seul sur un petit libellé actif ; chip sélectionné = texte `#F5F7FA` + indicateur violet |

(Toutes re-mesurées par `webapp/tests/design.test.mjs` §NU4 et
`BudgetTests/NeonUltraDesignSystemTests.swift` à chaque exécution.)

## 3. Captures (galerie PWA — outillage reproductible `capture-nu1.mjs`)

| Fichier | Contenu | Inspection |
|---|---|---|
| `nu1-pwa-390.png` (390×3084) | galerie complète standard | ✓ nuancier 17 rôles, un seul point focal (CTA du héros), aucun glow sur les montants, montant extrême entier |
| `nu1-pwa-320.png` (320×3176) | galerie complète 320 px | ✓ aucun débordement, aucun texte coupé |
| `nu1-pwa-320-texte-200.png` | texte agrandi 200 % à 320 px | ✓ corps de texte doublé, montants fluides ENTIERS, zéro débordement |
| `nu1-pwa-390-transparence-reduite.png` | Reduce Transparency | ✓ surfaces `#151923` opaques, ombre supprimée, aucun blur |
| `nu1-pwa-390-reduced-motion.png` | contexte reduced motion | ✓ rendu identique sans transitions (vérifié aussi par test) |
| `nu1-pwa-390-etats.png` | gros plan états | ✓ chip sélectionné (point + bordure violette, texte blanc), désactivés à opacité réduite, erreur = bordure + message textuel |

**Galerie iOS** : construite et vérifiée par le harness de test
(`UIHostingController`, 320/390 pt, accessibility3, transparence réduite) sur
la CI macOS. **Limitation honnête** : cet environnement (Linux) ne peut pas
produire de PNG simulateur ; les captures visuelles iOS de la galerie seront
produites au plus tard avec les preuves NU3 (lot SwiftUI) via l'environnement
macOS. Rien ici ne prétend valider haptique, Face ID ou VoiceOver physique.

## 4. Inventaire d'identité — DIFFÉRÉ À NU7 (aucune modification en NU1)

| Élément | Valeur actuelle | Décision attendue | Lot |
|---|---|---|---|
| `webapp/manifest.webmanifest` `theme_color` | `#07090e` (héritage pré-Obsidian) | future teinte Neon Ultra (`#05060A` ou navigation) — choix propriétaire | NU7 |
| `webapp/manifest.webmanifest` `background_color` | `#07090e` | idem | NU7 |
| `<meta name="theme-color">` (index.html) | `#090C12` (canvas Obsidian) | canvas Neon Ultra `#05060A` | NU7 (avec le rebranchement final) |
| Icônes PWA `icon-192.png` / `icon-512.png` / `apple-touch-icon.png` | identité actuelle (fond sombre, glyphe indigo) | refonte d'identité Neon Ultra — validation propriétaire | NU7 |
| `branding/logo.svg` | absent du dépôt (aucun fichier `branding/`) — l'identité vit dans les icônes ci-dessus | création éventuelle d'un logo canonique | NU7 |
| iOS `AccentColor.colorset` | sRGB (0.294, 0.361, 1.0) ≈ `#4B5CFF` (héritage) | accent Neon Ultra — choix propriétaire (magenta ou violet) | NU7 |
| iOS `AppIcon.appiconset` (1024) | icône actuelle | refonte d'identité Neon Ultra | NU7 |
| Service worker / cache PWA | inchangés | — (aucun changement d'identité requis) | NU7 |

## 5. Isolation prouvée

- `webapp/index.html` : zéro octet modifié ; aucun `--nu-`, aucune référence
  `neon-ultra.css` (verrouillé par test §NU2).
- Le tableau `BANNED` historique interdit TOUJOURS `#7C3AED` (et les autres
  teintes) dans `index.html` et `obsidian.css` — inchangé ; la vérification
  Neon Ultra est séparée et limitée à `neon-ultra.css`.
- iOS : `git diff` sur `DesignTokens.swift` = ajout pur en fin de fichier ;
  `GlassCard/ObsidianComponents/ObsidianComponentGallery/RootView/BudgetApp`
  et tous les écrans `Budget/Features/**` : intouchés ; `project.pbxproj`
  intouché (groupes synchronisés).
