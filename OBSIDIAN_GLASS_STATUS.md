# Budget — Statut Obsidian Glass

## Source de vérité

- Programme : Budget — Obsidian Glass
- Branche : `refonte/budget-obsidian-glass-v1`
- Branche source : `codex/budget-leader-refonte`
- Autorité Claude : `.claude/skills/budget-v1/SKILL.md`
- Dernière mise à jour : 23.07.2026

Les anciens fichiers de statut et skills restent des archives de programmes
précédents. Ils ne définissent pas le prochain travail Obsidian Glass.

## Avancement

| Lot | Statut | Preuve | Prochaine condition |
|---|---|---|---|
| L0 Gouvernance | DONE | branche, skill, constitution, matrice et livraison | vérifier les fichiers distants |
| L1 Vérité/baseline/P0 | DONE | runs CI 167 (échec constaté) → 168 (correctif vert) → 170 (couverture 18 modèles verte) ; 48 e2e + 5 parité + 206 tests iOS ; manifeste vérifié dans Budget.app ; captures versionnées | — |
| L2 Fondations | READY | — | lancer `/budget-v1 execute L2` |
| L3 Pilote PWA | BLOCKED | — | L2 validé |
| L4 Pilote iOS | BLOCKED | — | validation humaine de L3 |
| L5 Mouvements/Comptes | BLOCKED | — | L4 validé |
| L6 Modules financiers | BLOCKED | — | L5 validé |
| L7 Onboarding/Confiance | BLOCKED | — | L6 validé |
| L8 Widgets/Mouvement | BLOCKED | — | L7 validé |
| L9 Audit final | BLOCKED | — | L8 validé |

Statuts autorisés : `BLOCKED`, `READY`, `IN_PROGRESS`, `VERIFYING`, `DONE`.

## P0 revalidés en L1 (23.07.2026)

- [x] **P0-1 branche et vérité de release** — constat, pas de correction code :
  la branche par défaut GitHub reste l'ancienne `claude/execute-tbkhsd` ;
  `pages.yml` publie depuis `codex/budget-leader-refonte` ; la branche de
  travail Obsidian est `refonte/budget-obsidian-glass-v1` (L0 = docs
  uniquement, vérifié). Changer la branche par défaut est interdit pendant L1
  → action humaine listée dans les risques.
- [x] **P0-2 restauration native** — CONFIRMÉ puis CORRIGÉ (2 passes) :
  `decimal()` transformait tout montant illisible en zéro ; désormais
  `throws BackupError.corruptAmount`, y compris sur les quatre champs
  optionnels (`try Optional.map(decimal)` — la première passe ne compilait
  pas, run CI 167 rouge). La restauration entière (suppression +
  reconstruction + sauvegarde) est UNE transaction avec `rollback()` ; les
  fichiers de documents ne sont jamais touchés. Tests : montant obligatoire,
  optionnel et entité tardive corrompus ; comptages complets avant/après ;
  store persistant vérifié via un `ModelContext` neuf ; zéro coercition.
- [x] **P0-3 historique PWA figé** — CONFIRMÉ puis CORRIGÉ (2 passes) :
  les mouvements en devise étrangère étaient convertis au taux ACTUEL.
  Désormais `stampTx()` (fonction unique, création ET édition, purge avant
  recalcul, repli 1:1 explicite) + migration additive `stampAllTransactions`
  au chargement qui estampille TOUT l'historique (y compris une sauvegarde
  restaurée) une seule fois puis persiste immédiatement (ADR-021).
  e2e Tests 38-43.
- [x] **P0-4 PrivacyInfo.xcprivacy** — CONFIRMÉ puis CORRIGÉ : absent du
  dépôt ; créé dans `Budget/` (aucune collecte, aucun tracking, UserDefaults
  raison CA92.1). Vérification rendue DÉTERMINISTE en CI : `plutil -lint`
  du manifeste source, build Release avec `derivedDataPath` connu, présence
  de `Budget.app/PrivacyInfo.xcprivacy` exigée dans le produit compilé
  (échec de CI sinon).
- [x] **P0-5 URLs / bundle ID / métadonnées** — cohérence TECHNIQUE corrigée :
  identité canonique `ch.budgetapp.Budget` (les cibles de test ont leurs
  identifiants dédiés `ch.budgetapp.BudgetTests`/`BudgetUITests`, jamais
  soumis) ; `APP_STORE_LISTING.md` corrigé (il indiquait encore
  `com.mendes.budget`) ; zéro URL codée en dur dans le Swift. RESTE OUVERT
  (RELEASE_BLOCKER humain) : les URLs support/confidentialité
  `VOTRE-DOMAINE` à créer avant toute soumission — jamais inventées ici.

## Preuves CI de clôture L1 (23.07.2026)

- Run **167** (workflow_dispatch, commit `2c5214d`) : ÉCHEC constaté du job
  macOS — 4 `try` manquants sur `Optional.map(decimal)` dans
  `BackupService.swift` ; le correctif est né de cet échec.
  <https://github.com/Mendestrading21/Budget-/actions/runs/30010413674>
- Run **168** (push, commit `2d095a7` `fix(l1)`) : VERT complet — web e2e
  48 parcours + 5 fixtures de parité ; build Debug ; **206 tests iOS,
  0 échec** ; build Release (`derivedDataPath` connu) ; log littéral
  « PrivacyInfo.xcprivacy présent et valide dans Budget.app ✓ ».
  <https://github.com/Mendestrading21/Budget-/actions/runs/30012413633>
- Run **170** (push, commit `fe374f6` `test(l1)`) : VERT complet — mêmes
  jobs, avec la couverture transactionnelle portée aux **18 modèles
  persistants** (`counts(in:)` + sentinelles HouseholdMember/ImportBatch
  survivant au rollback) ; 206 tests iOS, 0 échec ;
  `Test Suite 'BackupServiceTests' passed`.
  <https://github.com/Mendestrading21/Budget-/actions/runs/30014447802>

## Baseline L1 (captures et mesures)

- Captures VERSIONNÉES dans `docs/obsidian-glass/baseline/l1/` (README avec
  écran, largeur, thème, commit observé, date et méthode) :
  `l1-390-mois.png`, `l1-390-budget.png`, `l1-390-txform.png`,
  `l1-390-mois-sombre.png`, `l1-320-mois.png`, `l1-320-budget.png`.
- Rendu (reload → tabbar interactive) : ~180 ms à 390 px, ~137 ms à 320 px.
- Zéro erreur console sur tous les parcours capturés ; aucun débordement
  horizontal à 320 px ni 390 px.
- Simulateur natif indisponible dans cet environnement Linux : la preuve
  native passe par la CI macOS et le workflow Demo (artifact `budget-demo`).

Constats à traiter dans les lots visuels (PAS corrigés en L1, interdits) :

1. carte « Priorité » tronquée (« …quelques va… » à 390 px, pire à 320 px) —
   texte à réécrire court ou multi-ligne en L3;
2. à 320 px le FAB recouvre partiellement le chip « Investir » — zone de
   sécurité à prévoir en L3;
3. premier viewport « Mois » : salutation + bandeau démo + héros + priorité +
4 chips + 4 métriques = dense ; la matrice Obsidian (4 métriques max, une
   priorité) est déjà presque respectée mais la hiérarchie typographique
   sera refaite en L2/L3;
4. deux thèmes (clair défaut + sombre) coexistent — Obsidian Glass exigera la
   migration contrôlée vers l'identité sombre unique (L2/L3, ADR-020);
5. anneau Budget : libellé « 92 % » ambigu (92 % consommé) — résumé textuel
   requis par la constitution, à traiter en L3.

## Invariants de programme

- Aucun changement de logique financière pour servir le visuel.
- Aucun écran général avant validation du pilote.
- Un lot, un commit, des tests, des captures, puis arrêt.
- Une seule identité sombre Obsidian Glass.
- Un seul accent de marque indigo.
- Vert, corail et ambre uniquement sémantiques.
- PWA et iOS partagent rôles, vocabulaire et composants, pas une copie pixel par pixel.
- Aucun merge, déploiement ou publication sans autorisation.

## Risques ouverts (actions humaines)

- Branche par défaut GitHub obsolète (`claude/execute-tbkhsd`) — à changer
  dans les réglages GitHub quand le propriétaire le décide.
- URLs support/confidentialité d'`APP_STORE_LISTING.md` à créer avant toute
  soumission App Store.
- Environnement `github-pages` : autoriser la branche de déploiement choisie
  (Settings → Environments) — hors périmètre Obsidian.

## Prochaine commande exacte

```text
/budget-v1 execute L2
```

L1 est DONE (CI verte, preuves ci-dessus) ; L2 est READY. Résultat attendu de
L2 : tokens sémantiques Obsidian (PWA + iOS), primitives `GlassCard`,
`AmountText`, `StatusPill`, fallback reduced transparency, galerie
déterministe — sans refondre les écrans, sans toucher aux formules
financières.
