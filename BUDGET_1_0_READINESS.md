# Budget 1.0 — registre de préparation release

Ce document est la SEULE liste de contrôle de la release 1.0. Une case
n'est cochée qu'avec une preuve réelle (run CI, SHA, test observé) —
jamais sur parole. Il est tenu à jour lot par lot.

Dernière mise à jour : 19.08.2026 (publication finale + verdict).

## 1. Programmes terminés

- [x] Registre Budget Prisme P00–P18 : terminé, fusionné, publié
      (`BUDGET_PRISME_STATUS.md`, bilan du 16–17.08.2026).
- [x] Améliorations continues A1–A22 : livrées (même registre).
- [x] **Moteur financier V2 (FE2-0 → FE2-3)** : fusionné et publié —
      dispatch Pages au SHA `4758e472`, run `32189154462`, succès.
      Règle d'or appliquée : une projection n'est jamais présentée
      comme de l'argent possédé ; plus de comptabilisation automatique
      par date ; effort fiscal mensuel séparé de l'écart annuel ;
      fixture de parité n° 6 verrouille le tout web↔natif.
- [x] **FE2-4 — vues natives Comptes/Épargne/Patrimoine** : PR #72
      fusionnée en squash, `main` = `d7e18b9e`, CI verte sur le HEAD
      exact `b589a73` (web + iOS, dont les trois nouveaux tests
      `NetWorthServiceTests`). Publié par dispatch au SHA final
      `b5e6e161` (run `32221728707`, succès).

## 2. Vérité financière et parité

- [x] 7 fixtures de parité web↔natif réconciliées au centime
      (`fixtures/parity-fixtures.json`, suite `parity.test.mjs` —
      la n° 7 grave l'union de la fortune liquide, FE2-5).
- [x] 155 parcours e2e navigateur réel verts (CI `Web (e2e navigateur
      réel)` sur `main` = `4758e472` puis `a100cca4`).
- [x] Tests iOS verts en CI (`Build + tests (simulateur iOS)`, mêmes
      SHAs). Totaux exacts relevés à chaque run dans les logs CI.
- [x] `Decimal` de bout en bout côté natif ; planifié ≠ comptabilisé ;
      épargne/investissement hors coût de la vie ; virements neutres
      (suites `MonthlySnapshotServiceTests`, `NetWorthServiceTests`,
      `TransactionValidationTests`).

## 3. « Ce qu'on me doit » (créances) — décision 1.0

**Exclu de Budget 1.0 — ADR-033, 18.08.2026.** L'audit du dépôt
(natif + web) ne trouve AUCUN modèle, écran ou type « créance » : la
fonctionnalité n'existe pas, même à moitié — il n'y a donc rien
d'inachevé à terminer ni à retirer. Plutôt que d'ajouter en fin de
cycle un modèle financier incomplet (avec migrations et parité à
prouver), Budget 1.0 assume :

- une dette se suit dans Patrimoine (« Ce que vous devez ») ;
- un prêt accordé se note honnêtement comme un actif libre de
  Patrimoine (« Prêt à … ») que l'on met à jour, et le remboursement
  reçu se saisit comme mouvement « Remboursement reçu » (`refund`) ;
- un vrai module de créances (encours, échéances, relances) est un
  candidat FE3, à spécifier par le propriétaire.

## 4. Dépôt et hygiène (audit `node .github/scripts/repository-audit.mjs`)

- [x] Script d'audit exécuté en local le 18.08.2026 : 33 contrôles,
      tous PASS. Contrôle négatif du script lui-même : un TODO injecté
      dans un fichier Swift → FAIL ciblé ; un faux jeton `ghp_…` dans
      un test → FAIL ciblé ; restauration → tout PASS.
- [x] Aucun TODO/FIXME/HACK dans le code livré.
- [x] Aucun secret en dur ; aucune donnée personnelle réelle dans
      code, tests ou fixtures.
- [x] Xcode : `TARGETED_DEVICE_FAMILY = 1` (6 occurrences), cible
      iOS 17.0 (8 occurrences), `MARKETING_VERSION = 1.0` (ADR-023).
- [x] `PrivacyInfo.xcprivacy` : `NSPrivacyTracking = false`, aucune
      donnée collectée.
- [x] Skills du dépôt : `apple-design`, `budget-neon-ultra` (alias
      légacy explicite), `budget-prisme` (actif) — conformes à
      `CLAUDE.md`.
- [x] PWA : manifeste installable (nom, icônes, display) + service
      worker network-first.

(Le script se ré-exécute à chaque lot ; toute régression décoche.)

## 5. CI et publication

- [x] CI `ci.yml` : deux jobs (web e2e réel + build/tests simulateur
      iOS) verts sur chaque PR et sur `main` (hors étape « Déployer »,
      bloquée par la règle d'environnement — échec attendu documenté).
- [x] Publication Pages par dispatch de `pages.yml` au SHA exact —
      dernière publication : run `32239926920` au SHA `28bb9c01`
      (FE2-0..7 complets + CI durcie + registre 1.0 + audit +
      ADR-033), succès le 19.08.2026. Suites au moment de la
      publication : 156 e2e + 6 parités + design, 341+ tests iOS
      (dont classSummary et composition).
- [ ] Workflow `testflight.yml` : présent, jamais exécuté — exige les
      4 secrets Apple décrits dans `TESTFLIGHT_SETUP.md` (propriétaire).

## 6. Actions que seul le propriétaire peut faire

1. **GitHub → Settings → Environments → github-pages** : autoriser la
   branche `main` (supprime le besoin de dispatch manuel à chaque
   publication).
2. **GitHub → Settings → Branches** : faire de `main` la branche par
   défaut ; supprimer les branches mortes (l'agent reçoit 403).
3. **Apple** : compte développeur, certificats, les 4 secrets
   TestFlight (`TESTFLIGHT_SETUP.md`), décisions App Store
   (nom public, prix, capture story — `APP_STORE_LISTING.md`).
4. **QA iPhone réel** : protocole dans `MANUAL_QA_CHECKLIST.md`
   (haptique et biométrie ne se vérifient que sur appareil).

## 7. Verdict courant

**v1.0.0 ordonnée par le propriétaire** (19.08.2026, « tag v1.0.0 ») :
le tag et la Release se créent par le workflow `release.yml` (le proxy
git de l'agent ne pousse pas de tags) — dispatch au SHA exact de
`main`. Réserve consignée : la QA iPhone réel (haptique, Face ID,
VoiceOver) reste `PENDING HUMAN` — la release l'affiche honnêtement.

### Verdict au moment de l'audit

**READY FOR TESTFLIGHT (côté code)** — 19.08.2026, `main` =
`b5e6e161` : programmes P00–P18 / A1–A22 / FE2-0..4 fusionnés et
publiés, 155 parcours e2e + 6 parités + design verts, 341 tests iOS
0 échec observés sur le SHA exact, audit release 33/33 PASS, aucun
P0/P1 ouvert.

`v1.0.0` reste BLOQUÉ par les seules actions propriétaire (§ 6) :
secrets Apple + premier run TestFlight, QA iPhone réel
(`MANUAL_QA_CHECKLIST.md` — haptique/biométrie), décisions App Store,
et idéalement l'environnement github-pages ouvert à `main`. Le tag
`v1.0.0` ne sera JAMAIS créé sans l'accord explicite du propriétaire.
