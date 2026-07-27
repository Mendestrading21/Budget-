# Budget — Neon Ultra : état d'avancement

Programme actif (ADR-024) · branche `refonte/budget-neon-ultra-v1` · créée
depuis `26d186e8e31bbdf1bc41651afcaf7a1699988644` (dernier HEAD Obsidian à CI
verte prouvée — run CI #229 id 30221277893, success, jobs Web + iOS).

| Lot | Intitulé | État |
|---|---|---|
| NU0 | Gouvernance et baseline | **DONE** (validé par le propriétaire le 27.07.2026 ; clôture : image intégrée + contrat AA corrigé, CI verte exigée sur le commit de clôture) |
| NU1 | Tokens et primitives | **READY** |
| NU2 | Pilote PWA — Mois, Budget, Ajouter | À VENIR |
| NU3 | Pilote SwiftUI équivalent | À VENIR |
| NU4 | Mouvements, Comptes et shell | À VENIR |
| NU5 | Factures, Objectifs et Récurrents | À VENIR |
| NU6 | Patrimoine et graphiques | À VENIR |
| NU7 | Onboarding, confiance, réglages, identité | À VENIR |
| NU8 | Mouvement, accessibilité, performances | À VENIR |
| NU9 | Audit final | À VENIR |

## NU0 — Clôture (27.07.2026) — DONE

Validation propriétaire du contenu technique NU0 reçue, définitive après :

- **Image de référence intégrée** :
  `.claude/skills/budget-neon-ultra/assets/visual/neon-ultra-reference.jpeg`
  — reçue, copiée sous nom stable, décodage vérifié (JPEG valide,
  **736×1174 px**, 530 614 octets), réellement ouverte et inspectée.
  Éléments retenus : fond noir, profondeur graphite, éclairages
  magenta/violet/cyan, cartes superposées, énergie premium — aucun texte,
  personnage, nom, logo ni écran exact ne sera copié.
- **Correction AA du contrat** (mesures indépendantes reproduites) : texte
  discret `#747E8E` → **`#7C8696`** (l'ancien mesurait 4,49:1 / 4,15:1 /
  4,28:1 sur surface standard / élevée / fallback — sous AA ; le nouveau
  mesure canvas 5,50:1 · navigation 5,28:1 · surface standard 5,00:1 ·
  surface élevée 4,63:1 · fallback opaque 4,78:1). Constitution, résumé du
  skill et ADR-024 alignés.
- **Règle violet** ajoutée à la constitution : `#7C3AED` ≈ 3,41:1 sur la
  navigation — icônes grandes, bordures et indicateurs seulement, jamais
  seul pour un petit libellé actif (texte actif = `#F5F7FA` + indicateur
  violet, sauf paire mesurée ≥ 4,5:1).
- Aucun écran, token applicatif, rendu ni comportement modifiés ;
  `git diff --check` vert ; CI complète verte attendue sur le commit de
  clôture (rapportée en session).

## NU0 — Gouvernance et baseline (27.07.2026) — historique de la passe initiale

Livré (aucun écran, rendu, token ni logique modifiés) :

- **Skill** `.claude/skills/budget-neon-ultra/` : `SKILL.md` (plan / execute
  NU0–NU9 / continue / verify / prompt) + `NEON_ULTRA_CONSTITUTION.md`
  (palette et règles canoniques) + `NEON_ULTRA_DELIVERY.md` (10 lots) +
  `NEON_ULTRA_SCREEN_MATRIX.md` (écrans PWA/iOS + divergence navigation) +
  `REPOSITORY_CONTRACT.md` (protections, commandes, bases) +
  `REFERENCE_INDEX.md` + outillage reproductible de capture
  (`assets/tools/capture-baseline.mjs`).
- **ADR-024** (DECISION_LOG.md) : Neon Ultra remplace UNIQUEMENT les clauses
  visuelles d'ADR-020/022/CLAUDE.md/constitution Obsidian ; historique
  L0–L9 conservé tel quel, aucun rapport réécrit.
- **CLAUDE.md** aligné (programme actif, branche, autorités) ; **budget-v1**
  reçoit un bloc ROUTAGE (skill historique, ne plus l'invoquer).
- **Baseline prouvée** : `docs/neon-ultra/baseline/nu0/README.md` — 72 e2e ·
  5 parités · design system vert (contrastes mesurés) · 259 tests iOS,
  0 échec · builds Debug+Release SUCCEEDED · PrivacyInfo valide ·
  `UIDeviceFamily == [1]` · TARGETED_DEVICE_FAMILY = 1 (Debug+Release) ·
  zéro pageerror/erreur console · persistance disque
  (`DiskStoreLifecycleTests`) · sauvegarde/restauration
  (`BackupServiceTests` + e2e) · tests financiers nommés (FINANCIAL_AUDIT
  L9) · perf 10k mouvements (27–34 ms/peinture, DOM ≤ 200 lignes) ·
  13 captures PWA 390/320 générées et inspectées.
- **Divergence navigation documentée, NON réconciliée** : PWA 4 onglets +
  ＋ central (Mouvements dans Plus) vs iOS 5 onglets + ＋ flottant —
  décision produit séparée requise (baseline §5, matrice §1, ADR-024 §5).

### Inventaire de référence (HEAD source)

- PWA : `webapp/index.html` (≈ 305 Ko, app complète), `webapp/sw.js`,
  `webapp/manifest.webmanifest` (protégés hors lots visuels concernés).
- Tests web : `webapp/tests/e2e.test.mjs` (72 parcours),
  `webapp/tests/parity.test.mjs` (5 fixtures),
  `webapp/tests/design.test.mjs` (design system).
- iOS : `Budget/App/RootView.swift` (5 onglets + ＋ flottant),
  `Budget/Core/DesignSystem/DesignTokens.swift` + `GlassCard.swift` (tokens
  à faire évoluer en NU1), Features par onglet ; 259 tests
  (`BudgetTests`, dont `DiskStoreLifecycleTests`, `BackupServiceTests`,
  `AppLockManagerTests`, suites financières nommées).
- Workflows : `ci.yml` (Web + macOS iOS + contrôles produit), `demo.yml`
  (archive + IPA + captures simulateur en artefacts), `pages.yml`
  (déploiement Pages du propriétaire — sur la branche Obsidian, intouché).
- Fixtures : `fixtures/parity-fixtures.json` (protégées).

### En attente du propriétaire (HUMAN REQUIRED)

1. Décision produit navigation PWA/iOS (hors périmètre NU0–NU8) —
   divergence documentée, décision séparée en attente.
2. Héritage L9 inchangé : L9 Obsidian = VERIFYING (historique) ; QA iPhone
   réel, haptique, Face ID, VoiceOver physique, compte Apple/TestFlight —
   PENDING HUMAN.

### Prochaine action exacte

`/budget-neon-ultra execute NU1` (tokens et primitives — alias d'abord,
aucun écran rebranché sans preuve de contraste). Ne pas démarrer sans
demande explicite du propriétaire.
