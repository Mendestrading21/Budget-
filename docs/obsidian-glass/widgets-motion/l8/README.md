# L8 — Widgets, graphiques et micro-interactions (preuves PWA)

Captures générées le 24.07.2026 (Chromium réel, deviceScaleFactor 2, zéro
erreur console, onboarding réel « Elio + Sara », aucun toast résiduel).

## Ce que montre chaque capture

| Fichier | Preuve |
| --- | --- |
| `l8-390-patrimoine-avant-selection.png` | État initial : invite textuelle « Touchez la courbe (ou parcourez-la au clavier) pour lire un mois précis. » — aucune sélection imposée, aucun marqueur. |
| `l8-390-patrimoine-selection.png` | Mois choisi : règle verticale + point Indigo Aurora vif sur la courbe, étiquette `avril 2026 : CHF 2'000.00 de fortune nette` — la valeur vient de la série EXISTANTE (`points[i]`), rien n'est recalculé. |
| `l8-390-compte-detail-selection.png` | Même patron sur la courbe du solde d'un compte : `avril 2026 : solde CHF 2'000.00`. |
| `l8-320-patrimoine-selection.png` | 320 px : l'étiquette passe à la ligne, zéro débordement horizontal (vérifié par script et par le test 63). |
| `l8-390-patrimoine-selection-transparence-reduite.png` | `data-reduced-transparency` actif : surfaces graphite opaques, sélection et lisibilité intactes. |

## Le patron de sélection (PWA)

- Le SVG est enveloppé dans `.chart-select` ; 12 boutons transparents
  (`.zones`, un par mois) couvrent toute la hauteur de la courbe
  (96–110 px). Chaque bouton porte `aria-label`
  « Voir {mois} {année} : {montant} » et `aria-pressed`.
- L'étiquette est TEXTUELLE et `aria-live="polite"` : la sélection est
  annoncée aux lecteurs d'écran sans vol de focus ; après re-rendu, le
  focus clavier est restauré sur le bouton choisi
  (`focus({ preventScroll: true })`).
- Cibles : chaque zone fait ≈ 30 × 96 px (surface > 44 × 44). C'est un
  continuum de balayage — un doigt décalé d'une zone lit simplement le
  mois voisin, sans conséquence destructive ; au clavier et au lecteur
  d'écran, les 12 boutons restent des cibles discrètes focus-visibles
  (anneau `--brand-bright`). Compromis documenté, identique en esprit au
  scrub continu de `chartXSelection` côté natif.
- Valeurs affichées : TOUJOURS `series[i]` / `points[i]` déjà calculés
  pour la courbe — l'étiquette ne recalcule rien.

## Mouvement sobre

- Aucune animation infinie nulle part : l'état sélectionné apparaît
  instantanément (aucune transition ajoutée).
- `prefers-reduced-motion` : la garde globale existante coupe l'entrée
  des cartes (`animation: none`) — vérifié par le test 63.
- Côté natif : un seul retour haptique `.sensoryFeedback(.success…)`
  déclenché UNIQUEMENT après un `modelContext.save()` réussi du
  formulaire de mouvement — jamais décoratif, réglages système respectés.

## Performance (test 64, suite e2e)

- 10 000 mouvements semés en mémoire : `render()` de l'écran Mouvements
  < 4 s, navigation de mois < 4 s.
- Le DOM reste borné par le MOIS affiché (< 1 500 lignes rendues pour
  10 000 mouvements) — la liste ne rend jamais tout l'historique.

## Décision de périmètre

La personnalisation des widgets natifs (« éventuelle » dans
OBSIDIAN_GLASS_DELIVERY.md) n'est PAS ajoutée : la PWA possède déjà la
personnalisation de l'écran Mois, et aucun besoin utilisateur validé ne
justifie d'introduire une nouvelle surface de réglages native dans ce
lot. Décision consignée, réversible dans un lot ultérieur si demandée.

## Preuves natives

- `BudgetTests/ObsidianMotionTests.swift` : étiquette de sélection
  fr-CH exacte (positive et négative), écran Patrimoine restructuré
  construit à 320 pt en transparence réduite.
- Les captures simulateur passent par le workflow Demo (artefact du run
  déclenché pour L8) — le tour existant capture l'écran Patrimoine avec
  la courbe restructurée.
