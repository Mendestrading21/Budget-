# L9 — Résultats exacts des tests et builds (25.07.2026)

## Environnements réels

| Où | Quoi |
|---|---|
| Conteneur d'audit (Linux, Node 22.22.2, Chromium Playwright 1194) | suites web locales + audit navigateur écran par écran |
| CI GitHub Actions `ubuntu-latest` (Node 22, Playwright 1.61.1 + Chromium) | job « Web (e2e navigateur réel) » |
| CI GitHub Actions `macos-15`, Xcode 16.4, **simulateur iPhone 16** | build Debug, tests iOS (259 depuis la passe corrective), build Release, manifeste dans Budget.app, contrôles UIDeviceFamily == [1] |
| Workflow Demo (`demo.yml`, macos-15, simulateur iPhone 16 démarré) | tours UI assertés + captures + vidéo + base64 des pièces |
| iPhone physique | **AUCUN** — l'app n'a JAMAIS été installée sur un iPhone réel (aucun compte Apple Developer, App ID non enregistré, TestFlight jamais exécuté) ; protocole consigné, PENDING HUMAN |

## Commandes canoniques locales (audit + passe corrective, 25.07.2026)

| Commande | Résultat |
|---|---|
| `git diff --check` | OK (aucun conflit/espace) — passes initiale ET corrective |
| `node --check e2e.test.mjs` / `parity.test.mjs` / `design.test.mjs` | OK × 3 — passes initiale ET corrective |
| `node e2e.test.mjs` (Chromium réel, passe corrective) | **72 parcours verts** (48 historiques + 5 L3 + 3 L5 + 4 L6 + 4 L7 + 3 correctif L7 + 4 L8 + **1 charset L9**), **zéro erreur console** (passe initiale : 71) |
| `node parity.test.mjs` | **5 fixtures réconciliées** web ↔ attendus natifs, zéro erreur console |
| `node design.test.mjs` | tokens, parité CSS, **contrastes mesurés** (blanc/brand-deep 5.04:1 ; positive 10.19:1 ; negative 7.12:1 ; warning 11.10:1 — exigé ≥ 4.5), galerie 320/390, cibles 44 px, focus, reduced motion/transparency — OK |

## Mesures PERF L8 — trois sources, jamais confondues

Chaque exécution imprime SES mesures ; seules celles du DERNIER run CI
font foi comme référence finale.

| Source | répartis | concentrés | navigation | recherche | défilement |
|---|---|---|---|---|---|
| Local, passe initiale (25.07, conteneur d'audit) | 32 ms | 30 ms | 33 ms | 23 ms (111 lignes) | 21 ms |
| Local, passe corrective (25.07) | 35 ms | 32 ms | 29 ms | 22 ms (111 lignes) | 17 ms |
| CI #216 (run 30168699554 — passe initiale) | 23 ms | 30 ms | 25 ms | 14 ms (111 lignes) | 31 ms |
| CI #217 (run 30169693598 — passe initiale) | 24 ms | 34 ms | 23 ms | 15 ms (111 lignes) | 29 ms |
| **CI FINALE (passe corrective)** | voir « Référence CI finale » ci-dessous — seules valeurs de référence | | | | |

## Audit navigateur écran par écran (script `l9-pwa-audit.mjs`)

Voir `pwa/audit-results.json` (résultat par écran et par contrôle) et
les **21 captures** `pwa/*.png`. Périmètre : 5 onglets + 10 destinations du
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

## Référence CI finale de L9 (passe corrective)

Renseignée dans `OBSIDIAN_GLASS_STATUS.md` (« Preuves finales L9 —
passe corrective ») après vérification réelle : numéro de run CI + run
Demo + artefacts et pièces inspectés avant le rapport. Bases minimales
depuis la passe corrective : **72 e2e / 5 parités / 259 tests iOS /
0 échec / 0 erreur console / UIDeviceFamily == [1]** — jamais moins.
