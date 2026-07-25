# L9 — Résultats exacts des tests et builds (25.07.2026)

## Environnements réels

| Où | Quoi |
|---|---|
| Conteneur d'audit (Linux, Node 22.22.2, Chromium Playwright 1194) | suites web locales + audit navigateur écran par écran |
| CI GitHub Actions `ubuntu-latest` (Node 22, Playwright 1.61.1 + Chromium) | job « Web (e2e navigateur réel) » |
| CI GitHub Actions `macos-15`, Xcode de la CI, **simulateur iPhone 16** | build Debug, 258 tests, build Release, manifeste dans Budget.app |
| Workflow Demo (`demo.yml`, macos-15, simulateur iPhone 16 démarré) | tours UI assertés + captures + vidéo + base64 des pièces |
| iPhone physique | **AUCUN disponible dans cet environnement** — protocole consigné, PENDING HUMAN |

## Commandes canoniques locales (audit, 25.07.2026)

| Commande | Résultat |
|---|---|
| `git diff --check` | OK (aucun conflit/espace) |
| `node --check e2e.test.mjs` / `parity.test.mjs` / `design.test.mjs` | OK × 3 |
| `node e2e.test.mjs` (Chromium réel) | **71 parcours verts** (48 historiques + 5 L3 + 3 L5 + 4 L6 + 4 L7 + 3 correctif L7 + 4 L8), **zéro erreur console** |
| — dont PERF L8 (mesures jusqu'à la peinture) | 10 000 mouvements : répartis **32 ms** / concentrés **30 ms** (200 lignes DOM par page) · navigation **33 ms** · recherche **23 ms** (111 lignes) · défilement **21 ms** |
| `node parity.test.mjs` | **5 fixtures réconciliées** web ↔ attendus natifs, zéro erreur console |
| `node design.test.mjs` | tokens, parité CSS, **contrastes mesurés** (blanc/brand-deep 5.04:1 ; positive 10.19:1 ; negative 7.12:1 ; warning 11.10:1 — exigé ≥ 4.5), galerie 320/390, cibles 44 px, focus, reduced motion/transparency — OK |

## Audit navigateur écran par écran (script `l9-pwa-audit.mjs`)

Voir `pwa/audit-results.json` (résultat par écran et par contrôle) et
les captures `pwa/*.png`. Périmètre : 5 onglets + 10 destinations du
hub + détail de compte (dont compte négatif) + action universelle ＋ +
feuille Ajouter (montant 7 chiffres) — chaque écran contrôlé à 390 px
ET 320 px : débordement horizontal, zone d'exclusion du ＋ (géométrie du
test e2e 60 : rectangles visibles rognés au viewport de `#screen`, à
l'ouverture ET après défilement complet), zéro erreur console cumulée ;
persistance des données extrêmes après rechargement ; service worker,
installabilité et rechargement HORS LIGNE sur serveur https local.

## Référence CI de départ (HEAD `35c9790`)

- CI #215 verte (run 30166009397) : 71 e2e + 5 parité + design system ;
  **258 tests iOS, 0 échec** ; builds Debug + Release ;
  `PrivacyInfo.xcprivacy` présent et valide dans `Budget.app` (Release).
- Demo vert de référence L8 : run 30159052445 (tour principal 18 étapes
  + tour onboarding/confiance + preuve de sélection native ; pièce
  `ios-l8-patrimoine-selection-320-a11y` 960 × 1212 px inspectée).

## Référence CI finale de L9

Renseignée dans `OBSIDIAN_GLASS_STATUS.md` après la poussée du commit
documentaire : numéro de run CI + run Demo + artefacts, inspectés avant
le rapport final (les totaux ne doivent jamais descendre sous
71 e2e / 5 parité / 258 tests iOS / 0 échec / 0 erreur console).
