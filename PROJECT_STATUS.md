# Budget project status

Last updated: 2026-07-19
Current branch: claude/execute-tbkhsd
Current phase: Phases 0 à 12 terminées — prochaine : Phase 13 (Polish produit)
Invocation mode: build (session Claude Code sur Linux, vérification via CI GitHub Actions)

## Product goal (confirmé par l'utilisateur, 2026-07-19)

1. **Court terme** : usage personnel par l'utilisateur sur son propre iPhone (via TestFlight dès qu'un compte Apple Developer existe).
2. **Moyen terme** : publication sur l'App Store pour la **vendre** — la Phase 14 (release) devra inclure le choix du modèle de prix (app payante vs achat intégré), les métadonnées store et la conformité App Review.

## Product state

- App launches: phases 0-11 compilées et testées en CI GitHub Actions (dernier run vert : 29704772603)
- Persistence: SwiftData, schéma versionné V8 (`BudgetSchemaV8` : + FinancialDocument/ImportBatch, + importBatchID), migrations légères V1→…→V8 (ADR-006..012)
- Demo data: `DemoDataFactory` — mode démo isolé + previews déterministes (date fixe 15.06.2026)
- Onboarding: flux complet 5 étapes (confidentialité, ménage, canton, taux d'impôts 30 %, premier compte) + catégories suisses par défaut
- Accounts: liste groupée, détail, formulaire, réconciliation horodatée, archivage, flags cash/patrimoine, solde dérivé
- Transactions: 9 types, validation typée FR, virements internes atomiques et neutres, liste avec mois/recherche/filtres/file non catégorisée, dupliquer/supprimer
- Dashboard: `MonthlySnapshotService` (pur, calendrier + « now » injectés), montant vraiment disponible avec décomposition, budget quotidien, 4 cartes, graphique 6 mois (Swift Charts) avec résumé accessible, 3 actions prioritaires, mouvements récents
- Budget: onglet complet — lignes par catégorie (groupes essentiel/discrétionnaire/épargne/impôts), planifié vs réel avec badge de dépassement, section « Hors budget » (réconciliation totale), copie du mois précédent, grille annuelle 12 mois, graphique dashboard budget-vs-réel avec fallback 6 mois
- Recurring/subscriptions: entité unique (charges/revenus/abonnements), occurrences par multiples d'ancre sans dérive, dédup prévision/réel par recurringID, équivalents mensuel/annualisé, échéances de résiliation (badge + action prioritaire), section « À venir ce mois » avec comptabilisation en un geste, liste + formulaire complets (ADR-007)
- Taxes: module complet — TaxProfile (taux, source de vérité, seedé depuis Household), TaxProvision par année (réserve, arriérés, override, échéances), états dérivés toujours réconciliés (estimé = payé + dû), écran avec hypothèses visibles + disclaimer, échéances en action prioritaire du dashboard (ADR-008)
- Goals: onglet complet — types suisses (fonds d'urgence, 3a, voyage…), progrès via compte lié ou montant manuel, contribution mensuelle requise vs prévue, statuts En bonne voie/À accélérer/Échéance dépassée/Atteint (célébration sobre), projection au rythme prévu, action prioritaire dashboard (ADR-009)
- Insurance/pension: registre de contrats (prime + fréquence réelle, équivalents annuel/mensuel réconciliés, franchise, renouvellement, délais de résiliation à 60 j) ; prévoyance par piliers 1/2/3a/3b (valeurs des relevés officiels, contributions, projections des institutions jamais présentées comme garanties, somme partielle refusée) (ADR-010)
- Net worth: écran Patrimoine complet — décomposition réconciliée (comptes signés + actifs + prévoyance − dettes stockées positives), toggles d'inclusion respectés partout, instantané quotidien automatique, courbe de tendance Swift Charts avec résumé accessible, CRUD actifs/dettes (ADR-011)
- Import/export: wizard CSV Notion complet (détection délimiteur/en-têtes, mappage corrigeable, parsing dates/montants suisses, états ready/doublon/invalide, empreintes SHA-256 → ré-import 0 doublon, catégories créées uniquement sur confirmation, rapport réconcilié + file de réparation avec texte brut, rollback de lot) ; export en Phase 12 (ADR-012)
- Documents: registre local — fichiers copiés dans le conteneur protégé (completeFileProtection) via protocole DocumentFileStoring (impl réelle + fake), métadonnées typées, partage ShareLink, suppression fichier+métadonnées
- Security: verrouillage Face ID/Touch ID derrière protocole (activation/désactivation authentifiées, verrouillage au passage en arrière-plan, annulation = reste verrouillé), export CSV machine-stable, sauvegarde JSON complète versionnée (montants en String, relations par UUID), restauration avec confirmation destructive et rejet des schémas plus récents, suppression totale à double confirmation (données + fichiers), écrans Confidentialité et Méthodologie conformes à l'implémentation (ADR-013)
- Release readiness: non commencé

## Current acceptance criteria (Phases 0-10)

- [x] Phase 0 : fondation compilable en principe (projet Xcode 16, thème, formatage fr-CH, modèles, démo, tests)
- [x] Phase 1 : un nouvel utilisateur crée un profil local valide et retombe dans l'app au relancement (test de persistance inclus)
- [x] Phase 2 : types de comptes multiples, formatage CHF, soldes persistants, archivage sans perte d'historique
- [x] Phase 3 : tests de neutralité des virements et de rejets de transactions invalides ; liste gère vide et volume
- [x] Phase 4 : toutes les valeurs du dashboard dérivent des données persistées via des tests d'invariants
- [x] Phase 5 : planifié et réel restent séparés ; toutes les variances se réconcilient (tests) ; copie de mois sans doublons ; grille annuelle
- [x] Phase 6 : toute charge active apparaît exactement une fois dans les prévisions du mois ; les inactives jamais (tests d'échéancier + dédup) — CI verte (run 29702260574)
- [x] Phase 7 : tous les états fiscaux se réconcilient (estimé = payé + dû, tests) et les hypothèses sont visibles à l'écran
- [x] Build + tests des phases 0-4 validés sur Mac par l'utilisateur (« Ça fonctionne ✓ »)
- [x] Build + 82 tests de la phase 5 VERTS en CI GitHub Actions (run 29701802089)
- [x] CI verte sur la phase 7 (run 29702569987)
- [x] Phase 8 : contribution requise et bords cible-zéro/date passée sûrs (tests) — CI verte (run 29702937482)
- [x] Phase 9 : équivalents annuel/mensuel et totaux de prévoyance se réconcilient (tests) — CI verte (run 29703182761)
- [x] Phase 10 : neutralité des virements, signes des dettes et toggles inclus/exclus corrects (tests) — CI verte (run 29704249404)
- [x] Phase 11 : un ré-import ne duplique jamais ; chaque ligne rejetée est visible avec sa raison (tests) — CI verte (run 29704772603)
- [x] Phase 12 : états de verrouillage, annulation, version de restauration et confirmations destructives corrects (tests) — run 29704984445 rouge (l'API batch `context.delete(model:)` est incompatible avec les règles `.deny` de Account), corrigé par des suppressions individuelles dans `BackupService.deleteAll` — CI verte (run 29705302551)

- [x] Phase 13 : perf (un seul calcul de snapshot/rapport par rendu, préfiltre annuel), mode clair/mouvement réduit/a11y, checklist QA manuelle ; audit par agent → 1 bloqueur corrigé (la restauration effaçait définitivement les fichiers de documents, ADR-014) + restauration transactionnelle avec rollback, round-trip complet (ImportBatch, employmentStatus, updatedAt), voile de confidentialité dans le sélecteur d'apps, contraste carte impôts en mode clair — CI verte (runs 29705322894 puis 29705497072, ~168 tests)

- [x] Phase 14 : paquet App Store préparé sans publication — icône 1024 générée (monogramme B, identité verre sombre) et câblée dans AppIcon.appiconset, écran de lancement généré (clé INFOPLIST déjà en place), APP_STORE_LISTING.md (nom/sous-titre, description fr-CH, mots-clés, nutrition de confidentialité « aucune donnée collectée », storyboard des 6 captures en mode démo, placeholders support/confidentialité, recommandation de prix CHF 6.00 à l'achat), vérification d'archive = étape Build Release ajoutée à la CI — CI verte (run 29705804198 : suite complète + build Release sans erreur)

- [x] Le tour simulateur a attrapé un crash au premier lancement sur store disque (plan de migration étagé avec empreintes identiques → SIGABRT) — plan retiré, migration légère automatique (ADR-015)
- [x] Workflow Demo VERT (run 29724935362) : la vraie app démarre dans le simulateur, tour complet des 9 écrans capturé (captures + vidéo + .ipa non signée dans l'artefact « budget-demo ») ; CI verte sur le correctif (run 29724933695)
- [ ] Dérouler MANUAL_QA_CHECKLIST.md sur un appareil réel
- [ ] Décision de prix à valider par l'utilisateur (recommandation : CHF 6.00 à l'achat, sans IAP — APP_STORE_LISTING.md)

## Build and test evidence

- CI GitHub Actions (`.github/workflows/ci.yml`, runner macos-15, simulateur iPhone 16) : build + `xcodebuild test` à chaque push.
- **Derniers runs verts** : phases 5→14 (dernier : 29705804198, paquet App Store) — build Debug + Release OK, suite complète (~168 tests) sans échec.
  https://github.com/Mendestrading21/Budget-/actions
- Historique : le run 29701528788 (rouge) a attrapé un vrai bug SwiftData dans les données de démo (mouvements futurs persistés via le graphe de relations), corrigé en `5f22ec4`.
- Reste à vérifier sur appareil : la migration V1→V8 par-dessus un store réel existant, et le parcours manuel complet (la CI ne couvre que build + tests unitaires).

## Decisions made

Voir DECISION_LOG.md (ADR-001 à ADR-018). Convention patrimoine : soldes signés, un compte de dette (carte, prêt, hypothèque) porte un solde négatif.

## Audit externe soldé (2026-07-20, skill budget-production-completion)

Un audit tiers a été vérifié contre le code puis corrigé en P0→P2,
un commit par correctif, CI verte à chaque étape :

- **Natif** : `.debtPayment` transfer-like — cash et dette bougent
  ensemble, fortune neutre (ADR-016, `DebtPaymentTests`) ; plus aucun
  `try? modelContext.save()` — `saveOrRollback` + alerte utilisateur ;
  réserve d'impôts UNIFIÉE accueil↔module via
  `TaxService.monthReserveGap` (ADR-018, `UnifiedTaxReserveTests`) ;
  V1 mono-devise CHF avec garde à la restauration (ADR-017) ;
  ＋ universel flottant, onglet « Mouvements » dans la barre (Objectifs
  → Plus), actions prioritaires → formulaires préremplis.
- **Web** : `openTxSheet` réparé (P0 bloquant), impôts par année/statut,
  suppression scindée (opérations vs réinitialisation complète),
  confidentialité honnête, cockpit unique Accueil, onglet Mouvements —
  détail dans `webapp/AUDIT_W1.md`.
- **Tests** : suite navigateur réelle `webapp/tests/e2e.test.mjs`
  (Chromium, 12 parcours, zéro erreur console) exécutée par le nouveau
  job CI `web-tests` ; suite native enrichie (dette, réserve unifiée,
  garde devise).

## Known risks or blockers

- Migration V1→V8 : à valider sur un simulateur/appareil contenant déjà des données réelles (aucune perte attendue, changements additifs).
- Filtres et rapports calculés en mémoire (volumes V1 acceptables) — indexation/#Predicate à revisiter en Phase 13 (performance).

## Vague produit post-audit (2026-07-20, après-midi)

L'app web est devenue LE produit utilisable aujourd'hui, installée sur
l'iPhone de l'utilisateur :

- **Distribution** : PWA sur GitHub Pages
  (https://mendestrading21.github.io/Budget-/) — workflow `pages.yml`
  auto-déployé à chaque évolution de `webapp/` ; icône d'app, plein
  écran, service worker hors-ligne (réseau d'abord, cache en secours).
- **Première ouverture** : écran de bienvenue 4 étapes (prénom, devise
  de référence CHF/EUR/USD, salaire facultatif, compte principal) — la
  démo est un choix, plus jamais imposée ; « Réinitialiser
  complètement » ramène à la bienvenue.
- **Rituel « Check du mois »** : carte de progression (salaire,
  récurrents, factures validables d'un geste), « Mois bouclé »
  persistant et réversible, frise des 6 derniers mois. Porté en natif
  (RecurringScheduleService.monthCheck + carte HomeTab, dérivé pur).
- **Cumuls façon Finary** : contributions par compte de placement
  (versé année/total, retraits, perf. des comptes titres) — web ET
  natif (ContributionService + carte sur la fiche de compte) ;
  assurance vie (3b) suivie comme placement ; bilan « Versé cette
  année » et évolution 12 mois par classe dans Patrimoine ; échéances
  de contrats d'assurance avec alertes ≤ 45 jours sur l'Accueil.
- **Qualité** : second audit par agent → 23 correctifs (XSS échappé,
  ajustements cohérents, devise de référence partout, clavier complet,
  restauration d'état exhaustive) — zéro bouton mort vérifié (51 hooks
  ↔ 51 handlers). Suite navigateur : 18 parcours Chromium en CI (job
  `web-tests`) + suite native ~190 tests.

## Programme BUDGET 2027 (2026-07-20, soirée) — 20 lots livrés

Skill `.claude/skills/budget-2027/SKILL.md` exécuté de bout en bout,
un commit par lot, CI + Pages verts à chaque étape :

- **A. Marque** : logo original « le chemin du patrimoine » (SVG +
  icônes 1024/512/192/180), palette AA mesurée, épure (compteur animé,
  retour tactile, libellés raccourcis).
- **B. Public** : pays 🇨🇭🇫🇷🇧🇪 à la bienvenue (devise/impôts/
  vocabulaire), moteur de labels L() (3a ↔ PER ↔ épargne-pension),
  profils seul/couple/famille avec deux prénoms et deux salaires.
- **C. Chemin** : projection 5/10/20 ans (profils prudent/équilibré/
  ambitieux, Decimal itératif côté natif), objectifs projetés
  (« Atteint vers… », « ＋X/mois »), Année en revue, streak 🔥 +
  rattrapage des mois ouverts.
- **D. Comptes** : fiche de compte (courbe 12 mois, cumuls, historique),
  multi-revenus + moyenne 3 mois pour l'irrégulier, dettes vivantes
  (mensualité → décrément dérivé, fin projetée).
- **E. Simplicité** : bienvenue 5 écrans avec comptes en un tap, démo
  localisée par pays, guide « Comment ça marche » en 3 cartes.
- **F. Qualité** : suite navigateur à 22 parcours, audit agent final
  (zéro bouton mort sur 61 hooks ; 3 majeurs + 7 mineurs corrigés —
  commit b0eaac2), WealthProjectionService natif testé, ce bilan.

Validations humaines restantes : usage réel sur iPhone (seul juge du
produit), compte Apple Developer pour TestFlight/App Store, choix du
prix, et — avant tout lancement public FR/BE — une revue réglementaire
humaine des textes (l'app ne donne aucun conseil financier, mais la
formulation doit être validée par pays).

## Next exact action

Le code V1 est terminé (phases 0-14) et le pipeline TestFlight est prêt : `.github/workflows/testflight.yml` (déclenchement manuel, signature cloud via clé API App Store Connect, aucun Mac requis) + guide `TESTFLIGHT_SETUP.md` (100 % faisable depuis l'iPhone). Exemption de chiffrement déclarée (`ITSAppUsesNonExemptEncryption = NO`). Il reste ce qui exige un humain ou un compte Apple Developer (~99 $/an) :

**App web (skill /budget-web)** : W1-W4 livrées sur l'artifact unique — état persistant complet (localStorage), CRUD intégral (mouvements, comptes, budget par mois avec copie, objectifs liés aux comptes, récurrents avec « Comptabiliser », actifs/dettes, assurances, prévoyance, documents), import CSV réel avec empreintes et rollback, export CSV/JSON + restauration, impôts réglables, verrouillage par code, History API. Audit initial (5 BLOCKER dont un XSS et une perte de fortune sur l'épargne) intégralement soldé — webapp/AUDIT_W1.md. Source : webapp/index.html, vérifiée par suite headless Node à chaque phase.

En attendant le compte Apple, le workflow **Demo** (Actions → Demo → Run workflow, aucun secret) fait tourner la vraie app dans le simulateur iPhone via `BudgetUITests/DemoTourUITests` (argument de lancement `-demoTour` → mode démo in-memory) et livre l'artefact « budget-demo » : captures de chaque écran, vidéo du tour, .ipa non signée. La CI ordinaire saute les tests UI (`-skip-testing:BudgetUITests`).

1. Suivre TESTFLIGHT_SETUP.md : adhésion Apple Developer, App ID `ch.budgetapp.Budget`, fiche App Store Connect, clé API, 4 secrets GitHub, puis « Run workflow ».
2. Valider la décision de prix (APP_STORE_LISTING.md).
3. Sur appareil : MANUAL_QA_CHECKLIST.md + migration V1→V8 sur un store existant.
