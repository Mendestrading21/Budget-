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
| L2 Fondations | DONE | **validation humaine reçue le 23.07.2026** ; CI #172 verte (run 30021212918) : web + parité + design system + build Debug + 214 tests iOS 0 échec + build Release + manifeste dans Budget.app | — |
| L3 Pilote PWA | DONE | **validation humaine reçue le 23.07.2026** ; CI #173 verte (run 30028514793, SHA 8a82a2e) : 53 parcours web zéro erreur console + 5 parité + design system + build Debug + 214 tests iOS 0 échec + build Release + manifeste dans Budget.app (le run manuel #174 confirme) | — |
| L4 Pilote iOS | DONE | **validation humaine reçue le 23.07.2026** ; commit `99cbb75` ; CI #175 verte (run 30038788928 : 222 tests iOS 0 échec, ObsidianPilotTests passed, Debug+Release, manifeste) ; workflow Demo vert (run 30039344152, artefact budget-demo 36,5 Mo, tour 12 étapes asserté). Risque visuel NON bloquant conservé : la capture native détaillée de la feuille « Ajouter un mouvement » n'a pas été inspectée séparément par le propriétaire | — |
| L5 Mouvements/Comptes | VERIFYING | livré : 4 parcours refondus (PWA + iOS), 56 e2e verts, 9 tests natifs L5, 12 captures PWA + README, tour Demo 13 étapes (détail ci-dessous) | CI verte + workflow Demo + validation humaine |
| L6 Modules financiers | BLOCKED | — | L5 validé |
| L7 Onboarding/Confiance | BLOCKED | — | L6 validé |
| L8 Widgets/Mouvement | BLOCKED | — | L7 validé |
| L9 Audit final | BLOCKED | — | L8 validé |

Statuts autorisés : `BLOCKED`, `READY`, `IN_PROGRESS`, `VERIFYING`, `DONE`.

## Critères d'acceptation L5 (annoncés avant toute édition, 23.07.2026)

**Périmètre strict** : Mouvements et Comptes, PWA
(`renderMovements`/`renderMoreTxList`/`txRow`/`renderAccounts`/
`renderAccountDetail` + CSS) et iOS (`TransactionsListView`,
`AccountsTab`, `AccountDetailView`, boutons Dupliquer/Supprimer visibles
dans `TransactionFormView` en édition) + tests + captures + tour Demo.
Aucun module L6, aucune formule, migration, clé localStorage, structure
SwiftData ou sauvegarde modifiée.

**Mouvements PWA.** Recherche 44 px stylée tokens ; chips de filtres
`aria-pressed` (état actif = teinte de marque, plus de gradient) ;
regroupement par JOUR avec en-têtes datés ; virement marqué « neutre » en
toutes lettres dans la ligne ; états vide/sans-résultat via
`.empty-state` ; montants extrêmes non tronqués ; undo de suppression
existant CONSERVÉ (pushUndo/toast Annuler).

**Mouvements iOS.** `TransactionRow` : StatusPill « Prévu », caption
« · neutre » pour les virements, teinte épargne = marque ; liste en
`LazyVStack` (performance) ; `EmptyState` L2 ; swipe actions (dupliquer /
supprimer) UNIQUEMENT avec équivalents visibles ajoutés : boutons
« Dupliquer » et « Supprimer » dans la feuille d'édition (parité web),
suppression toujours confirmée ; duplication factorisée
`TransactionDuplication.copy` (testée).

**Comptes PWA.** Détail : bouton direct « Mettre le solde à jour… »
(`data-reconacc`, même feuille de réconciliation, langage simple
existant) + fraîcheur du solde dans le héros ; liste : fraîcheur déjà
affichée, devise étrangère signalée, aucune addition non convertie
(conversion explicite existante `toCHF`).

**Comptes iOS.** `AccountRow` : StatusPill « Dette » / « Archivé »
(jamais couleur/opacité seules) ; `AccountDetailView` : `AmountText`
héros, StatusPill « Archivé », caption « Dernier mouvement le X »
(fraîcheur) quand pas de réconciliation ; `MovementRow` : `AmountText`
signé ; `EmptyState` L2 ; natif V1 mono-devise CHF (ADR-017) — aucune
addition multi-devises possible, documenté.

**Preuves.** e2e Tests 49-51 (groupes par jour, recherche+filtre
combinés, sans résultat, « neutre », extrême, undo, réconciliation
directe, devise étrangère, fraîcheur, 44 px, 320 px) — suite portée à
56 parcours, rien d'affaibli ; `ObsidianMovementsAccountsTests` natifs
(duplication fidèle, suppression persistée, archivage sans perte,
réconciliation horodatée, fraîcheur, prévu≠comptabilisé, extrême/texte
long, écrans construits 320 pt/a11y/transparence réduite, garde CHF) ;
tour Demo enrichi « 13-compte-detail » asserté ; captures PWA
`docs/obsidian-glass/movements-accounts/l5/` + README (l'état
« archivé » n'existe que côté natif — documenté) ; un commit
`feat(l5): redesign movements and accounts with Obsidian Glass` ; CI
complète + Demo verts ; **L5 = VERIFYING**, L6 = BLOCKED.

## Critères d'acceptation L4 (archivés, 23.07.2026)

**Périmètre strict** : `HomeTab.swift`, `BudgetTab.swift`,
`TransactionFormView.swift` + tests/previews. Aucun autre écran, aucune
ligne PWA, aucun service financier, modèle SwiftData, migration ou
sauvegarde modifiés. Lot suivant interdit.

**Mois (natif = pilote PWA L3, conventions SwiftUI).** Héros « Argent
disponible » via `AmountText` hero (jamais tronqué), jours restants +
« CHF X par jour » en secondaire DANS le héros, « D'où vient ce
montant ? » dépliable, bouton `PrimaryActionButtonStyle` « ＋ Ajouter un
mouvement » ; 4 métriques Entré / Dépensé / À payer / Mis de côté —
« À payer » = `committedCharges + recurringCharges + taxReserveGap`
(champs DÉJÀ calculés par `MonthlySnapshotService`, somme d'affichage
pure via un helper testé) ; UNE priorité mise en avant après les
métriques (la première action), les suivantes restent dans « À faire »
(aucune fonctionnalité perdue) ; mouvements récents inchangés.

**Budget.** Héros : `AmountText`, `StatusPill` textuelle Dans le plan /
À surveiller / Dépassé, « X % du budget utilisé » écrit en toutes
lettres, barre plan/réel avec résumé accessible ; lignes : « réel X /
planifié Y », `StatusPill` « À surveiller » dès 85 % et « Dépassé »
(symbole + texte, jamais couleur seule) — `BudgetVarianceService`
INTACT.

**Ajouter un mouvement.** Ordre du pilote : type → montant (focus
automatique, `decimalPad`, jamais caché — bouton Enregistrer en barre de
navigation native) → date → statut (picker natif existant CONSERVÉ,
déplacé après la date) → comptes → catégorie → résumé explicite
virement/épargne (« neutre », « mis de côté ») → détails facultatifs
(intitulé FACULTATIF : défaut = catégorie/type injecté côté vue —
`TransactionValidationService` byte-identique) ; erreurs typées FR
conservées ; fond Obsidian ; tous les chemins préservés (création,
édition, 9 types, ajustement, statuts manuels).

**Preuves.** `BudgetTests/ObsidianPilotTests.swift` : helper « À payer »,
montant extrême `CHF -9'999'999.99`, construction des trois écrans à
320 pt / texte accessibilité / transparence réduite forcée, mouvement
valide + erreur récupérable + virement via le service réel, persistance
après sauvegarde (contexte neuf), résultats financiers inchangés
(snapshot avant/après refonte identique par fixtures). Previews
déterministes par écran (standard, texte agrandi, transparence
réduite). CI complète verte ; captures NATIVES réelles via le workflow
Demo (artefact `budget-demo`), jamais fabriquées ; commit
`feat(l4): redesign iOS pilot with Obsidian Glass` ; **L4 = VERIFYING**
(jamais DONE sans validation humaine), lot suivant = BLOCKED.

## Critères d'acceptation L3 (archivés, 23.07.2026)

**Périmètre strict** : Mois/Accueil, Budget, feuille Ajouter un mouvement —
aucun autre écran refondu, aucune formule financière, migration, clé
localStorage, route ou logique Swift modifiée. L4 interdit.

**Mois.** Premier viewport dans l'ordre : salutation courte + mois → carte
héros « Argent disponible » (montant dominant jamais tronqué, jours
restants secondaires, explication dépliable, action universelle Ajouter) →
quatre métriques exactement : Entré, Dépensé, À payer, Mis de côté
(agrégats DÉJÀ calculés par `snapshot()`, aucune formule nouvelle) → UNE
priorité non tronquée (multi-ligne) → actions rapides conservées
(fonctionnalité + Test 26) → aperçu Budget → mouvements récents (sections
existantes). Corrections baseline L1 : priorité multi-ligne, `.screen`
avec zone de sécurité FAB (plus de chevauchement à 320 px), densité et
hiérarchie du premier viewport.

**Budget.** Premier viewport : reste à dépenser + planifié + réel + état
textuel (pill « Dans le plan / À surveiller / Dépassé ») + anneau avec
résumé textuel explicite « X % du budget utilisé » (l'aria « Budget
consommé » du Test 31 est conservée). Chaque catégorie : nom, planifié,
réel, reste/dépassement, barre, badge textuel « À surveiller »/« Dépassé »
(jamais couleur seule), montants longs sans troncature. « Pas encore
classé » réconcilié par une phrase. Comparaison mois précédent conservée
(« Mois dernier : coût de la vie »). Planifié ≠ réel, épargne/impôts à
part — formules `budgetReport()` intactes.

**Ajout d'un mouvement.** Ordre : type (chips tactiles ≥ 44 px synchronisés
sur le `select` existant) → montant + devise du compte source → date →
compte → catégorie/destination → statut auto affiché (Comptabilisé/Prévu,
logique inchangée) → détails avancés repliés (intitulé facultatif, défaut =
catégorie) → Enregistrer sticky jamais caché par le clavier (feuille
`100dvh` défilante). Erreur près du champ concerné + `aria-invalid` +
focus ; résumé explicite pour virement/épargne ; parcours fréquent en
3 gestes hors saisie du montant ; aucun chemin existant supprimé
(création, édition, duplication, suppression, ajustement, tous types,
devise étrangère figée).

**Preuves.** Tests L3 ajoutés dans la suite e2e (accueil : ordre, 4
métriques, priorité non tronquée, 320 px sans chevauchement, montant
extrême, vide, démo ; budget : résumé %, 3 états, réconciliation, montant
extrême, aria graphique ; ajout : parcours fréquent, clavier, erreur
récupérable, reload, édition, virement, devise figée ; a11y : 44 px,
focus, ordre clavier, labels, reduced motion/transparency, 320/390, zéro
erreur console). Les 48 parcours existants, 5 fixtures de parité et tests
design system restent verts SANS affaiblissement. Captures
`docs/obsidian-glass/pilot/l3/` (11 fichiers exigés) + README. Un commit
`feat(l3): redesign PWA pilot with Obsidian Glass`, CI complète verte,
**L3 = VERIFYING** (jamais DONE sans validation humaine), L4 = BLOCKED.

## Critères d'acceptation L2 (archivés, 23.07.2026)

**A — Identité unique.** PWA : `:root` = tokens Obsidian canoniques, bloc
`html[data-theme="dark"]` et valeurs claires supprimés, apparence toujours
sombre quel que soit `S.theme` (champ préservé dans les sauvegardes, plus
aucune commande visuelle), ligne « Apparence » des Réglages retirée sans
toucher au reste de l'écran. iOS : identité sombre établie à la racine
(`RootView`), résolution clair/sombre supprimée de `DesignTokens.swift`,
aucun écran individuel modifié.

**B — Fondations PWA.** Tokens canoniques (`canvas`, `canvasRaised`, `glass`,
`glassStrong`, `glassFallback`, `stroke`, `strokeActive`, `brand`,
`brandBright`, `textPrimary/Secondary/Tertiary`, `positive`, `negative`,
`warning`) dans `webapp/design-system/obsidian.css` ET `webapp/index.html`
avec les mêmes valeurs (parité testée) ; anciens noms (`--indigo`,
`--electric`, `--violet`, `--teal`, `--graphite`, …) réduits à des alias vers
les nouveaux tokens — aucune teinte teal/cyan/violet/bleu électrique
indépendante active. Primitives : cartes verre standard/forte/légère,
montants héros/standard, badge de statut, boutons primaire/secondaire/
destructif, champ, feuille, état vide, état d'erreur, focus-visible global.
`prefers-reduced-transparency` + mécanisme déterministe
`html[data-reduced-transparency="true"]` → `glassFallback` opaque, halo
supprimé. Galerie déterministe hors navigation
(`webapp/design-system/obsidian-gallery.html`). Cibles ≥ 44 px,
`CHF -9'999'999.99` jamais tronqué, chiffres tabulaires, AA, 320 px, reduced
motion, aucune animation infinie, aucun asset externe, aucun empilement de
blurs lourds. App installable et hors ligne inchangée.

**C — Fondations iOS.** `DesignTokens.swift` : rôles Obsidian complets,
valeurs brutes centralisées là uniquement, alias documentés à retirer
(`electricBlue`/`violet`/`cyan`/`teal` → `brand`/`brandBright`). Rayons
28/22/14, marge écran 18, paddings 24/18, grille 4-32 (+12). `GlassCard`
évolué (hero/standard/row, reduceTransparency → `glassFallback` opaque, pas
de matériau lourd en liste). `AmountText` (FinanceFormatting, zéro nouveau
calcul), `StatusPill` (jamais couleur seule), `PrimaryActionButton`,
`ObsidianSheet`, `EmptyState`, `ErrorState`, `ObsidianComponentGallery` avec
previews déterministes (7 chiffres, négatif, texte agrandi, transparence
réduite, 4 états sémantiques).

**D — Preuves.** Nouveau test web design-system (tokens + parité,
contrastes AA mesurés, galerie sans débordement 320/390, cibles 44 px,
focus clavier, reduced motion, fallback opaque, zéro erreur console) ;
tests iOS des rôles/alias/contrastes ; 48 e2e (Test 29 adapté à l'identité
unique) + 5 parité + 206 tests iOS conservés verts ; captures
`docs/obsidian-glass/foundations/l2/` + README ; un commit
`feat(l2): establish Obsidian Glass foundations` ; CI complète verte ;
L2 = VERIFYING (jamais DONE sans validation humaine), L3 = BLOCKED.

Interdits : refonte Mois/Budget/Ajout d'un mouvement, formules financières,
données/migrations/persistance, suppression de fonctionnalité, L3.

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

## Livraison L2 (23.07.2026) — en VERIFYING

- **Identité unique** : PWA `:root` = tokens Obsidian canoniques, bloc
  `html[data-theme="dark"]` supprimé, apparence toujours sombre ; `S.theme`
  préservé dans l'état/sauvegardes mais sans effet (ADR-022) ; ligne
  « Apparence » des Réglages retirée. iOS : `.preferredColorScheme(.dark)` à
  la racine (BudgetApp), résolution clair/sombre supprimée de
  `DesignTokens.swift`.
- **Alias hérités** : `--electric`/`--violet`/`--teal`/`--indigo-text` →
  `brand`/`brandBright` (idem `electricBlue`/`violet`/`cyan`/`teal`/
  `informative` côté Swift) — aucune seconde palette active, alias documentés
  à retirer en L3+.
- **Primitives PWA** : cartes verre standard/forte(28px, blur 22)/légère,
  montants héros/standard (clamp, jamais tronqués), `.pill` statut
  (point + texte), `.btn`/`.btn.secondary`/`.btn.destructive` (≥ 44 px,
  blanc AA sur `--brand-deep` #6457F0 : 5.04:1), champs + état
  `aria-invalid`, feuille verre fort, `.empty-state`/`.error-state`,
  `:focus-visible` global, `prefers-reduced-transparency` +
  `html[data-reduced-transparency="true"]` → `glassFallback` opaque.
- **Primitives iOS** : `GlassCard` hero/standard/row évolué (fallback
  opaque, pas de matériau en liste), `AmountText` (FinanceFormatting, zéro
  calcul), `StatusPill` (symbole + texte), `PrimaryActionButtonStyle`
  (+ destructive) / `SecondaryActionButtonStyle` (44 pt, reduceMotion),
  `ObsidianSheetSurface`, `EmptyState`, `ErrorState`,
  `ObsidianComponentGallery` (previews standard / texte agrandi /
  transparence réduite ; argument `-obsidianGallery`).
- **Galerie** : `webapp/design-system/obsidian-gallery.html` +
  `obsidian.css` (source canonique, parité `index.html` testée), hors
  navigation, déterministe.
- **Tests** : nouveau `webapp/tests/design.test.mjs` (tokens + parité,
  11 contrastes mesurés — tous AA, galerie 320/390 sans débordement,
  cibles ≥ 44 px, focus clavier ≥ 2 px, reduced motion, fallback opaque,
  zéro erreur console) exécuté en CI ; `BudgetTests/DesignSystemTests.swift`
  (rôles, alias, contrastes, géométrie 28/22/14-18-24/18, grille +12,
  montants extrêmes, galerie construite à 320 pt). Test 29 e2e réécrit pour
  l'identité unique. Local : 48 e2e ✓, 5 parité ✓, design ✓.
- **Contrastes mesurés** : textPrimary/canvas 18.28:1 ; textPrimary/verre
  17.03:1 ; textSecondary/verre 8.35:1 ; textTertiary/verre 4.58:1 ;
  brand/canvas 4.77:1 ; brandBright/canvas 6.68:1 ; blanc/brandDeep 5.04:1 ;
  positive 10.19:1 ; negative 7.12:1 ; warning 11.10:1.
- **Captures** : `docs/obsidian-glass/foundations/l2/` (galerie 390, 320,
  transparence réduite 390, texte agrandi 320 + README complet). Sanité
  app : écran Mois hérite de l'identité sans refonte, zéro erreur console.
- **Hors ligne** : `index.html` reste auto-suffisant (tokens embarqués,
  aucun nouvel asset de production), service worker inchangé.
- **Preuve native visuelle** : en attente du workflow Demo / pilote L4
  (pas de simulateur dans cet environnement Linux) — raison du VERIFYING
  avec la validation humaine.

## Livraison L3 (23.07.2026) — en VERIFYING

- **Mois** : premier viewport au contrat — salutation courte (`.hello`) +
  mois, héros « Argent disponible » dominant (classe `long` dès 7 chiffres,
  jamais tronqué ; jours restants secondaires ; « D'où vient ce montant ? »
  dépliable ; bouton universel « ＋ Ajouter un mouvement » intégré),
  4 métriques exactement (Entré, Dépensé, À payer, Mis de côté — « À
  payer » = somme d'agrégats DÉJÀ calculés par `snapshot()` : charges
  prévues + réguliers à venir + réserve d'impôts manquante, affichage
  seul), UNE priorité multi-ligne jamais tronquée (`.priority-card`),
  actions rapides conservées (Test 26), aperçu Budget, sections
  mouvements récents inchangées. Zone de sécurité FAB (`.screen`
  padding-bas 96 px) : plus de chevauchement à 320 px.
- **Budget** : héros avec pill textuelle « Dans le plan / À surveiller /
  Dépassé », « X % du budget utilisé » écrit en toutes lettres, anneau
  avec « utilisé » au centre et aria « Budget consommé » (Test 31
  conservé), montant `fit-row` qui ne passe jamais sous l'anneau
  (anneau à la ligne si étroit), lignes « réel X / planifié Y » + badge
  « À surveiller » dès 85 % (plus jamais couleur seule), « Pas encore
  classé » expliqué et réconcilié. `budgetReport()` INTACT.
- **Ajout d'un mouvement** : chips de type tactiles ≥ 44 px synchronisées
  sur le `#fType` historique (tests/handlers inchangés), montant en
  premier (focus + clavier décimal, devise du compte source `#fCur` +
  note de conversion figée), note de statut dérivée de la date (« Sera
  compté comme : Prévu/Comptabilisé », logique inchangée), résumé
  explicite épargne/virement (« neutre », « mis de côté »), intitulé
  FACULTATIF replié (défaut = catégorie), erreur près du champ
  (`fieldError` + `aria-invalid` + focus, saisie jamais effacée),
  Enregistrer sticky jamais caché (feuille `100dvh` défilante), feuille
  fermée uniquement après sauvegarde. Tous les chemins préservés
  (création, édition, duplication, suppression, ajustement, 7 types,
  devise figée ADR-021).
- **Tests** : e2e **53 parcours verts** (48 existants + Tests 44-48 :
  structure/ordre/4 métriques/priorité entière/montant extrême ;
  320 px sans chevauchement FAB/vide guidé/démo explicite ; Budget
  %/états/dépassement réel/extrême ; ajout chips/statut/erreur près du
  champ/3 gestes/reload/édition/virement/clavier sticky ; a11y focus/
  transparence réduite/labels SVG/320 px) ; 5 parité ✓ ; design system ✓ ;
  zéro erreur console. Aucun test affaibli (3 sites e2e ouvrent le pli
  `fMore` avant de saisir l'intitulé, désormais replié).
- **Captures** : `docs/obsidian-glass/pilot/l3/` — 11 fichiers exigés +
  README (états, viewports, méthode, comparaison baseline L1, refus).
- **Hors ligne** : `index.html` reste mono-fichier auto-suffisant ; service
  worker et clés localStorage INCHANGÉS ; captures et suites en `file://`.
- iOS totalement inchangé (L4 = BLOCKED).

## Livraison L4 (23.07.2026) — en VERIFYING

- **Mois natif** : héros « Argent disponible » (`AmountText` hero, jamais
  tronqué), jours restants + « CHF X par jour » en secondaire dans le
  héros, « D'où vient ce montant ? » dépliable, bouton
  `PrimaryActionButtonStyle` « ＋ Ajouter un mouvement » (feuille sans
  préréglage) ; 4 métriques Entré / Dépensé / À payer / Mis de côté
  (« À payer » = `HomePilotDisplay.toPay` : somme d'affichage de
  composantes DÉJÀ calculées par `MonthlySnapshotService`, testée) ; UNE
  priorité mise en avant (pill « Priorité » + bord indigo, multi-ligne),
  les suivantes restent dans « À faire » — aucune fonctionnalité perdue ;
  mois clôturés : « Ce qui reste du mois ».
- **Budget natif** : `AmountText` hero, `StatusPill` Dans le plan / À
  surveiller / Dépassé, « X % du budget utilisé » écrit + barre plan/réel
  teintée, résumé accessible « Budget consommé : X pour cent » ; lignes
  « réel X / planifié Y » + `StatusPill` « À surveiller » dès 85 % et
  « Dépassé » — `BudgetVarianceService` INTACT (fraction affichée via
  `FinanceMath.safeRatio` existant).
- **Feuille native** : ordre du pilote (type → montant focalisé
  `decimalPad` → date + statut natif conservé → comptes avec résumé
  explicite virement/épargne → catégorie → « Détails (facultatif) » avec
  intitulé DÉFAUT = catégorie/type injecté côté vue —
  `TransactionValidationService` byte-identique) ; Enregistrer en barre
  de navigation (jamais caché par le clavier) ; fond Obsidian ; erreurs
  typées FR conservées ; tous les chemins préservés (édition, 9 types,
  ajustement, statuts manuels).
- **Tests** : `BudgetTests/ObsidianPilotTests.swift` (8 tests — helper
  « À payer », identité du disponible et séparation épargne/vie
  inchangées, mouvement valide + persistance via contexte neuf, erreur
  récupérable sans écriture, virement neutre (fortune constante),
  montant extrême exact, écrans construits à 320 pt / texte
  accessibilité / transparence réduite forcée). Previews ajoutées :
  texte agrandi + transparence réduite (Mois, Budget), texte agrandi +
  virement (feuille). Total attendu : 222 tests iOS.
- **Preuve native RÉELLE (23.07.2026)** : CI #175 verte sur `99cbb75`
  (run 30038788928 — **222 tests iOS, 0 échec**, `ObsidianPilotTests
  passed`, builds Debug + Release, manifeste dans Budget.app) ; workflow
  **Demo vert** (run 30039344152) — la vraie app en simulateur iPhone 16,
  tour de 12 étapes ASSERTÉES (dont « 12-nouveau-mouvement » : FAB →
  Dépense → feuille), artefact **`budget-demo` 36,5 Mo** (captures de
  chaque écran + vidéo du tour + .ipa non signée), téléchargeable depuis
  le run jusqu'au 21.10.2026 :
  <https://github.com/Mendestrading21/Budget-/actions/runs/30039344152>.
  Limitation d'environnement : la politique d'egress de cette session
  refuse `*.blob.core.windows.net` (stockage des artefacts GitHub) — les
  captures natives n'ont donc pas pu être RE-versionnées dans `docs/`
  depuis ici ; elles s'inspectent et se téléchargent depuis le run
  ci-dessus (aucune capture fabriquée).
- PWA, services financiers, modèles, migrations, sauvegardes : INCHANGÉS.

## Livraison L5 (23.07.2026) — en VERIFYING

- **Mouvements PWA** : recherche 44 px aux tokens, chips de filtres
  `aria-pressed` (teinte de marque, gradient supprimé), regroupement par
  JOUR avec en-têtes datés, « · neutre » (virement) et « · mis de côté »
  (épargne/investissement) ÉCRITS avant la destination, états
  vide/sans-résultat en `.empty-state` guidés, undo de suppression
  conservé, montants extrêmes intacts.
- **Mouvements iOS** : `LazyVStack` (performance longues listes),
  `StatusPill` « Prévu », nature écrite dans la ligne et le libellé
  VoiceOver, épargne en teinte de marque, `EmptyState` L2 ; pas de swipe
  hors `List` (geste mort évité) — équivalents VISIBLES ajoutés :
  boutons « Dupliquer (copie modifiable) » et « Supprimer ce mouvement »
  (confirmé) dans la feuille d'édition ; duplication factorisée
  `TransactionDuplication.copy` testée.
- **Comptes PWA** : détail avec bouton PRIMAIRE « Mettre le solde à
  jour… » (`data-reconacc`, même feuille de réconciliation en langage
  simple), fraîcheur du solde datée dans le héros, devise du compte dans
  l'en-tête, montant extrême géré (`long`).
- **Comptes iOS** : héros « Argent disponible » en `AmountText`,
  `StatusPill` « Dette »/« Archivé » (plus jamais couleur/opacité
  seules, VoiceOver enrichi), fraîcheur « Dernier mouvement le X » quand
  pas de réconciliation, `MovementRow` en `AmountText` signé,
  `EmptyState` L2 ; V1 natif mono-devise CHF (ADR-017) — aucune addition
  multi-devises possible, gardé par test.
- **Tests** : e2e **56 parcours verts** (48 + 5 L3 + Tests 49-51 :
  groupes/chips/recherche-filtre combinés/sans résultat/neutre/extrême/
  undo restaurant le mouvement ; détail compte/fraîcheur/réconciliation
  directe créant un ajustement daté/devise étrangère ; 44 px/320 px/
  signes textuels) ; 5 parité ✓ ; design system ✓ ; natif :
  `ObsidianMovementsAccountsTests` (9 tests — duplication fidèle champ à
  champ, suppression persistée contexte neuf, archivage sans perte de
  solde ni d'historique, réconciliation horodatée sans réécriture,
  fraîcheur par dernier mouvement, prévu hors totaux réels, garde CHF,
  écrans 320 pt/a11y/transparence réduite, lignes extrêmes) — total
  attendu 231 tests iOS.
- **Preuves** : 12 captures PWA + README dans
  `docs/obsidian-glass/movements-accounts/l5/` ; tour Demo enrichi
  « 13-compte-detail » asserté (l'état archivé, natif seulement, est
  couvert par test — documenté).
- Formules, migrations, clés localStorage, structures : INCHANGÉES.
- **Preuves finales (23.07.2026)** : CI #177 verte sur `f4ea4d0`
  (run 30043810568 — 56 e2e + 5 parité + design system, **231 tests iOS
  0 échec**, `ObsidianMovementsAccountsTests passed`, builds Debug +
  Release, manifeste dans Budget.app) ; workflow **Demo vert**
  (run 30044319681) — tour de **13 étapes assertées** (dont
  `13-compte-detail`), artefact `budget-demo` **47,2 Mo** (captures +
  vidéo + .ipa), téléchargeable jusqu'au 21.10.2026 :
  <https://github.com/Mendestrading21/Budget-/actions/runs/30044319681>.
  (Egress de session : `*.blob.core.windows.net` refusé — captures
  natives à inspecter depuis le run, comme en L4.)

## Prochaine commande exacte

```text
/budget-v1 verify L5
```

L4 reste VERIFYING jusqu'à validation humaine des trois écrans natifs et
des captures du workflow Demo. Ne pas lancer le lot suivant sans cette
validation explicite.
