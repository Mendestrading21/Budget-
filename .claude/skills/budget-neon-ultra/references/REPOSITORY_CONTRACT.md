# Contrat de dépôt — Budget Neon Ultra

## Branches

- Travail : `refonte/budget-neon-ultra-v1` (seule branche poussée).
- Source figée : `refonte/budget-obsidian-glass-v1` — ne JAMAIS la modifier ;
  elle porte l'app validée L0–L9 (VERIFYING) et le déploiement Pages du
  propriétaire.
- Branche par défaut : intouchable. Aucun merge, PR, tag, déploiement,
  TestFlight, App Store Connect sans autorisation explicite.

## Protections absolues (interdiction de modification)

- `Budget/Domain/**`
- `Budget/Core/Persistence/**`
- `FinanceFormatting.swift`
- `AppContainer.swift`
- `OnboardingViewModel.swift`
- `fixtures/parity-fixtures.json`
- modèles SwiftData et migrations
- calculs, agrégats, fiscalité ; `Decimal`
- import/export ; sauvegarde/restauration
- clés localStorage (`budget-app-state-v1`, `budget-app-state-rescue`)
- service worker (`webapp/sw.js`) et manifest
- bundle identifier (`ch.budgetapp.Budget`), signature, entitlements
- `PrivacyInfo.xcprivacy`
- cible iPhone uniquement (`TARGETED_DEVICE_FAMILY = 1`, `UIDeviceFamily == [1]`)
- données de démonstration
- l'application PWA ou SwiftUI dans les lots documentaires (NU0, NU9 hors
  correctifs prouvés)

Un besoin réel de toucher un fichier protégé = s'arrêter et demander.

## Commandes canoniques (reprises des workflows, ne pas en inventer)

Local (Linux, `BUDGET_CHROMIUM` requis) :

```
node --check webapp/index.html-extraits && node --check webapp/tests/*.mjs
cd webapp/tests && node e2e.test.mjs && node parity.test.mjs && node design.test.mjs
```

CI (`.github/workflows/ci.yml`) : job Web (e2e navigateur réel) + job
macOS-15 « Build + tests (simulateur iOS) » — xcodebuild test (Debug) puis
build Release + contrôles PrivacyInfo (`plutil -lint`) + `UIDeviceFamily ==
[1]` (plutil -extract, liste exacte) + `TARGETED_DEVICE_FAMILY = 1`
(Debug et Release). Workflow `demo.yml` : archive + IPA + mêmes contrôles +
captures simulateur. Workflow `pages.yml` : déploiement (interdit sans
autorisation).

## Bases minimales (jamais moins, à chaque lot)

| Suite | Base |
|---|---|
| e2e PWA navigateur | 72 parcours verts, zéro erreur console |
| Parité web↔natif | 5 fixtures réconciliées |
| Design system | vert (tokens, contrastes mesurés, galerie 320/390, 44 px, focus, reduced motion/transparency) |
| Tests iOS | 259, 0 échec |
| Builds | Debug + Release SUCCEEDED |
| Produit | PrivacyInfo présent et valide ; `UIDeviceFamily == [1]` |

Baseline chiffrée complète : `docs/neon-ultra/baseline/nu0/README.md`.

## Discipline de tests

- Tests adaptés quand un libellé/markup change ; JAMAIS supprimés ni
  affaiblis ; toute nouvelle assertion s'ajoute aux bases.
- Fixtures fictives déterministes (Alex/Charlie…) ; jamais de donnée réelle
  du propriétaire dans tests, captures ou logs.
- Une régression = corrigée avant commit, pas documentée à la place.

## Commits

- Un commit ciblé par lot : `feat(nuX): …` / `docs(neon-ultra): …` /
  `fix(nuX): …` ; description honnête des preuves.
- Push : `git push -u origin refonte/budget-neon-ultra-v1` uniquement.
- Attendre et inspecter la CI avant le rapport de lot.

## Validation humaine

Chaque lot se termine VERIFYING. Seul le propriétaire passe un lot à DONE.
Jamais de déclaration de QA physique (haptique, Face ID, VoiceOver iPhone
réel) depuis un simulateur ou un navigateur : marquer PENDING HUMAN.
