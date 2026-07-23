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
| L1 Vérité/baseline/P0 | DONE | ADR-021, test restore corrompu, e2e Test 38, captures `l1-*.png`, 43 e2e + 5 parité verts | validation humaine du rapport L1 |
| L2 Fondations | READY | — | validation humaine de L1 |
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
- [x] **P0-2 restauration native** — CONFIRMÉ puis CORRIGÉ : `decimal()`
  transformait tout montant illisible en zéro ; désormais
  `BackupError.corruptAmount` annule la restauration (transactionnelle
  ADR-014). Test `testRestoreRejectsCorruptAmountWithoutCoercingToZero`.
- [x] **P0-3 historique PWA figé** — CONFIRMÉ puis CORRIGÉ : les mouvements en
  devise étrangère étaient convertis au taux ACTUEL ; désormais `addTx()`
  estampille `fx`/`fxBase`/`destAmount` à la création (ADR-021). e2e Test 38.
- [x] **P0-4 PrivacyInfo.xcprivacy** — CONFIRMÉ puis CORRIGÉ : absent du dépôt
  (find + pbxproj = 0 occurrence) ; créé dans `Budget/` (aucune collecte,
  aucun tracking, UserDefaults raison CA92.1 pour le verrouillage). Le projet
  utilise des groupes synchronisés Xcode 16 (`PBXFileSystemSynchronizedRootGroup`,
  path = Budget) : le fichier est inclus au produit automatiquement ; la CI
  macOS (build Release) sert de vérification.
- [x] **P0-5 URLs / bundle ID / métadonnées** — cohérents : bundle
  `ch.budgetapp.Budget` identique app/tests/UITests ; zéro URL codée en dur
  dans le code Swift ; les URLs d'`APP_STORE_LISTING.md` sont des
  placeholders explicitement marqués « à créer avant la soumission » (action
  humaine, pas un défaut du code).

## Baseline L1 (captures et mesures)

- Captures (scratchpad session, thème clair Horizon actuel + sombre) :
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

À lancer UNIQUEMENT après validation humaine du rapport L1. Résultat attendu :
tokens sémantiques Obsidian (PWA + iOS), primitives `GlassCard`, `AmountText`,
`StatusPill`, fallback reduced transparency, galerie déterministe — sans
refondre les écrans.
