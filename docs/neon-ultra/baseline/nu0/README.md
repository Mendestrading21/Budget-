# NU0 — Baseline prouvée (27.07.2026)

État de départ du programme Neon Ultra, mesuré sur le HEAD source
`26d186e8e31bbdf1bc41651afcaf7a1699988644` (dernier commit Obsidian approuvé,
branche `refonte/budget-obsidian-glass-v1`), AVANT toute modification
visuelle. Aucun écran, rendu, token ni logique n'a été modifié dans NU0.

## 1. Preuves automatiques — suites locales (ré-exécutées dans cette session)

| Suite | Résultat |
|---|---|
| e2e PWA navigateur réel | **72 parcours verts** (48 historiques + 5 pilote L3 + 3 mouvements/comptes L5 + 4 modules financiers L6 + 4 onboarding/confiance L7 + 3 correctif L7 + 4 widgets/mouvement L8 + 1 charset L9), **zéro pageerror, zéro erreur console** |
| Parité web ↔ natif | **5 fixtures réconciliées** (`fixtures/parity-fixtures.json`), zéro erreur console |
| Design system | vert — tokens, parité, **contrastes mesurés** (brand/canvas 4.77:1, brand-bright 6.68:1, blanc/CTA 5.04:1, positif 10.19:1, négatif 7.12:1, alerte 11.10:1 — tous ≥ 4.5), galerie 320/390, cibles 44 px, focus, reduced motion/transparency |
| Performance (mesures réelles jusqu'à la peinture, 10 000 mouvements) | répartis 27 ms / 200 lignes DOM · concentrés 34 ms / 200 lignes DOM par page · navigation 32 ms · recherche 28 ms / 111 lignes · défilement 25 ms |

## 2. Preuves automatiques — CI du HEAD source (run #229, id 30221277893, success)

| Contrôle | Résultat (extrait des logs du run) |
|---|---|
| Tests iOS (simulateur, Debug) | **« Executed 259 tests, with 0 failures (0 unexpected) »** — Test Suite 'All tests' passed |
| Build Debug | SUCCEEDED (phase de tests) |
| Build Release | **« ** BUILD SUCCEEDED ** »** |
| PrivacyInfo | « PrivacyInfo.xcprivacy présent et valide dans Budget.app ✓ » (`plutil -lint` OK) |
| UIDeviceFamily | « UIDeviceFamily == [1] dans le produit Release ✓ » (liste exacte) |
| TARGETED_DEVICE_FAMILY | « = 1 en Debug ✓ » et « = 1 en Release ✓ » |
| Job Web CI | « Web (e2e navigateur réel) » success (mêmes suites que localement) |

Workflow Demo (archive + IPA + mêmes contrôles + captures simulateur) :
dernier run success `30171837501` (25.07.2026, HEAD `9e0a754140b2`) — les
captures iOS simulateur existent comme ARTEFACTS de ce workflow, aucune n'est
committée dans le dépôt (voir §5).

## 3. Persistance, sauvegarde et tests financiers nommés (inchangés, vérifiés par les suites ci-dessus)

- Persistance disque native : `DiskStoreLifecycleTests` (écriture puis
  relecture d'un store SQLite réel sur disque, 2 tests dédiés) + le chemin
  disque exercé par chaque lancement Demo.
- Sauvegarde/restauration : `BackupServiceTests` (10 tests — refus atomiques
  ADR-014, enveloppe versionnée) côté natif ; e2e PWA export JSON →
  suppression → restauration → données revenues (couvert dans les 72
  parcours, revalidé aussi lors du déploiement de prévisualisation).
- Invariants financiers : chacun rattaché à un test NOMMÉ — inventaire
  complet dans `docs/obsidian-glass/final-audit/l9/FINANCIAL_AUDIT.md`
  (Decimal, fr-CH, planifié≠réel, virements neutres ADR-016, patrimoine,
  mono-CHF ADR-017, historique figé ADR-021, zéro coercition, imports
  idempotents, fiscalité unifiée ADR-018).
- Persistance PWA : localStorage `budget-app-state-v1` (+ `-rescue`),
  rechargement et hors-ligne couverts par les e2e (service worker).

## 4. Captures PWA de baseline (générées et inspectées dans cette session)

Outillage reproductible committé :
`.claude/skills/budget-neon-ultra/assets/tools/capture-baseline.mjs`
(données fictives Alex/Charlie, zéro erreur console pendant la capture).

| Fichier | Contenu |
|---|---|
| `pwa-390-onboarding-bienvenue.png` | onboarding étape 1 (dots en bas, centré) |
| `pwa-390-mois.png` / `pwa-320-mois.png` | Accueil : titre-salutation, héros + CTA, 4 métriques, barre 4 onglets + ＋ central |
| `pwa-390-budget.png` / `pwa-320-budget.png` | Budget (état guidé) |
| `pwa-390-comptes.png` / `pwa-320-comptes.png` | Comptes |
| `pwa-390-plus.png` / `pwa-320-plus.png` | hub Plus (5 groupes, 11 destinations, Mouvements en tête) |
| `pwa-390-mouvements.png` / `pwa-320-mouvements.png` | Mouvements en sous-vue de Plus (retour « ‹ Plus ») |
| `pwa-390-ajouter.png` / `pwa-320-ajouter.png` | menu rapide Ajouter ouvert depuis le ＋ central |

Inspection réelle effectuée : à 320 px, aucun chevauchement ni débordement ;
le ＋ est au centre exact de la barre ; la feuille Ajouter liste ses 8
destinations avec cibles ≥ 44 px.

## 5. Divergence de navigation PWA / iOS (documentée, NON réconciliée)

| | PWA (`webapp/index.html`) | iOS (`Budget/App/RootView.swift:57-77`) |
|---|---|---|
| Barre | **4 onglets** : Mois, Budget · **＋ central 46×46** · Comptes, Plus | **5 onglets** : Mois, Mouvements, Budget, Comptes, Plus |
| Mouvements | dans **Plus** (sous-vue avec retour), décision propriétaire du tour 26.07.2026 (commits `e4b1a25`, `26d186e`) | onglet dédié (`TransactionsTab`) |
| Bouton ＋ | membre central de la barre, ouvre le menu rapide (8 créations) | menu flottant en surimpression bas-droite (`quickCreateButton`, RootView.swift:47-49) |
| Preuves | captures `pwa-*-mois.png`, `pwa-*-plus.png`, `pwa-*-ajouter.png` + e2e test 1 (4 onglets + Mouvements via Plus) et test 57 (11 destinations du hub) | code cité ; captures simulateur dans les artefacts du workflow Demo (run `30171837501`) |

**Décision produit séparée requise** avant toute réconciliation — interdite
pendant NU0–NU8 (ADR-024 §5, matrice §1).

## 6. Limites honnêtes de cette baseline

- Environnement local = Linux : les chiffres iOS proviennent des logs de la
  CI macOS du HEAD source (run cité §2), pas d'une exécution locale.
- Aucune capture iOS committée dans le dépôt ; disponibles uniquement via les
  artefacts du workflow Demo (rétention GitHub limitée).
- Haptique, Face ID, VoiceOver physique, iPhone réel : JAMAIS validés depuis
  un simulateur — PENDING HUMAN (inchangé depuis L9).
- L'image de référence artistique Neon Ultra n'était pas jointe au prompt
  NU0 : HUMAN REQUIRED (voir `REFERENCE_INDEX.md` du skill).
