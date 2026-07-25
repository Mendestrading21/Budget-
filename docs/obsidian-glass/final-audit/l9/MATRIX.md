# L9 — Matrice finale écran par écran / bouton par bouton (25.07.2026)

Trois familles de preuves, jamais confondues : **A** = automatique
(tests, exécutés par la CI canonique) · **V** = visuelle (capture
réellement INSPECTÉE) · **H** = contrôle humain (consigné, jamais
prétendu). Résultat : PASS quand toutes les preuves listées existent et
sont vertes/inspectées ; le risque résiduel est toujours dit.

Zéro bouton mort : contrôle STATIQUE (85 hooks `data-*` émis ↔ 86
requêtes de handlers, 0 orphelin ; 0 `onclick` inline ; champs `id`
routés par délégation vérifiés) + contrôle DYNAMIQUE (navigation réelle
de chaque écran ci-dessous, zéro erreur console).

## Écrans de la matrice canonique

| Espace | PWA | iOS | Preuves A | Preuves V | H | Résultat | Risque résiduel |
|---|---|---|---|---|---|---|---|
| Mois (Accueil) | ✓ | ✓ | e2e « accueil essentiel », « mois blueprint », « mois L3 structure », « mois L3 320px/vide/demo », « check du mois », « recommandation du mois », « comparaison mois » ; natif `ObsidianPilotTests` + snapshot réconcilié (`testAvailableBreakdownReconciles`) | `l9-390-mois`, `l9-320-mois` ; Demo `01-accueil` | — | **PASS** | aucun connu |
| Mouvements | ✓ | ✓ | e2e « mouvements », « vide guidé mouvements », « creation/edition/suppression », pagination ≤ 200 lignes DOM + perf 10k (test 66, temps loggés) ; natif `ObsidianMovementsAccountsTests` | `l9-390-mouvements` ; Demo `02-mouvements` | — | **PASS** | listes natives : intitulés très longs tronqués (P3-1) |
| Budget | ✓ | ✓ | e2e « budget L3 » (anneau, plan/réel, hors budget) ; natif `BudgetPlanningServiceTests` + `BudgetVarianceServiceTests` (16) | `l9-390-budget` ; Demo `03-budget` | — | **PASS** | aucun connu |
| Comptes + détail | ✓ | ✓ | e2e « compte », « comptes L5 », « cumuls », « solde negatif », « courbe » + scrubber L8 (63-65) ; natif `AccountBalanceServiceTests`, `AccountLifecycleTests`, `ContributionServiceTests` | `l9-390-comptes`, `l9-390-compte-detail` ; Demo `04-comptes`, `13-compte-detail` | — | **PASS** | aucun connu |
| Factures | ✓ | ✓ | e2e « facture », « factures L6 » (payer = concordance intitulé/action, retard) ; natif `RecurringScheduleServiceTests` (27) | `l9-390-bills` ; Demo captures L6 | — | **PASS** | aucun connu |
| Objectifs | ✓ | ✓ | e2e « scenario objectifs », « objectifs+impôts L6 » ; natif `GoalProjectionServiceTests` (13 : cible zéro, date passée, contribution requise) | `l9-390-goals` ; Demo `06-objectifs` | — | **PASS** | aucun connu |
| Impôts | ✓ | ✓ | e2e « objectifs+impôts L6 » ; natif `TaxServiceTests` (13) + `UnifiedTaxReserveTests` (8, accueil = module, ADR-018) | `l9-390-taxes` ; Demo `07-impots` | — | **PASS** | aucun connu |
| Patrimoine | ✓ | ✓ | e2e « patrimoine+prévoyance L6 », scrubber + échelle sûre + isolation (63-65) ; natif `NetWorthServiceTests` (8) + `ObsidianMotionTests` (7, sélection + 320-a11y pixel) + geste Demo déterministe (CHF 138'400.00) | `l9-390-networth`, `l9-320-networth` ; Demo `08-patrimoine`, `ios-l8-patrimoine-avant/-selection`, pièce 320-a11y 960×1212 px inspectée | — | **PASS** | aucun connu |
| Assurances + Prévoyance | ✓ | ✓ | e2e « echeance contrat », « patrimoine+prévoyance L6 » ; natif `InsurancePensionServiceTests` (9) | `l9-390-insurance` ; Demo `14-assurances`, `15-prevoyance` | — | **PASS** | aucun connu |
| Documents (+ import) | ✓ | ✓ | e2e « documents L7 » (édition métadonnées, textes destructifs concordants), « import L7 » (mapping, compte OBLIGATOIRE, aperçu, idempotence, rollback) ; natif `CSVImportServiceTests` (14) + tour L7 (import parcouru, compte choisi) | `l9-390-importcsv` ; Demo `16-documents`, `ios-l7-import-*`, `ios-l7-documents-*` | — | **PASS** | aucun connu |
| Plus (hub) | ✓ | ✓ | e2e « menu plus groupé », « hub Plus L7 » (zéro lien mort, 44 pt, sous-titres) ; natif tour Demo `05-plus`, `ios-l7-plus` | `l9-390-plus` | — | **PASS** | aucun connu |
| Réglages | ✓ | ✓ | e2e « reglages », « sauvegarde sans code », « verrouillage », « confiance L7 » (textes exacts) ; natif `BackupServiceTests` (verrouillage 4 tests) + `ObsidianTrustTests` (9) | `l9-390-settings` ; Demo `10-reglages`, `ios-l7-reglages/-securite/-confidentialite/-methodologie/-sauvegarde` | — | **PASS** | aucun connu |
| Onboarding | ✓ | ✓ | e2e « bienvenue », « onboarding L7 » (retour conservant les saisies, estimation modifiable, atomicité), « démo pays » ; natif `OnboardingViewModelTests` (6) + tour `-onboardingTour` (store VIDE réel) | Demo `ios-l7-onboarding-*` (6 captures) ; audit : parcours complet rejoué avant chaque suite | — | **PASS** | aucun connu |
| Assistant / Année en revue / Récurrents (hors matrice, livrés) | ✓ | ✓(année/récurrents) | e2e « assistant » (4 questions canoniques, données locales), « charges annuelles », « projection persistée » ; natif `YearStatsServiceTests`, `RecurringScheduleServiceTests`, `WealthProjectionServiceTests` | `l9-390-assistant`, `l9-390-year`, `l9-390-recurring` ; Demo `09-recurrents`, `11-annee` | — | **PASS** | assistant = PWA uniquement (décision produit documentée, pas un trou) |

## Parcours transverses

| Parcours | Preuves A | Preuves V | H | Résultat | Risque résiduel |
|---|---|---|---|---|---|
| Feuille « Ajouter un mouvement » (3 gestes, montant long, erreur, clavier) | e2e « ajout L3 », « creation mouvement », « garde-fou saisie », « echap », « retour ferme feuille », « clavier » ; natif `TransactionValidationTests` (12, messages français) + étape `12-nouveau-mouvement` + erreur montant invalide du tour | `l9-390-action-universelle`, `l9-390-ajouter-montant-long` | — | **PASS** | aucun connu |
| Zone d'exclusion permanente du ＋ | e2e test 60 (390/320, ouverture + défilement, rectangles réels rognés au viewport) ; audit L9 : MÊME géométrie sur les 15 écrans × 2 largeurs ; natif `assertNoFABOverlap` à chaque position intermédiaire du tour Demo | toutes les captures l9-* | — | **PASS** | aucun connu |
| Actions destructives (intitulé = action, double confirmation, undo) | e2e « double suppression », « edition/suppression » (undo 6 s), « documents L7 » ; natif `17-suppression-annulee` + `ios-l7-suppression-annulee` (dialogue ouvert PUIS annulé) | Demo captures citées | — | **PASS** | aucun connu |
| Sauvegarde / restauration / refus | e2e « sauvegarde guidee », « restauration validée », « sauvetage donnees », « sauvegarde restaurée normalisée » ; natif `BackupServiceTests` (14 : round-trip 18 modèles, refus schéma futur/corruption/montant/devise, ADR-014/017) | `ios-l7-restauration-resume`, `ios-l7-sauvegarde` | — | **PASS** | aucun connu |
| Verrouillage (succès, annulation, échec, arrière-plan) | e2e « verrouillage » ; natif `BackupServiceTests` (lock 4) + voile de confidentialité (`PrivacyShieldView`) | `ios-l7-securite` | H : Face ID réel sur iPhone (checklist) | **PASS** (simulé) | biométrie PHYSIQUE = PENDING HUMAN |
| Hors ligne / service worker / installabilité | audit L9 partie 2 : SW `activated`, manifest standalone + 2 icônes servies, rechargement HORS LIGNE réussi (contexte http dédié) | `l9-390-hors-ligne` | — | **PASS** | P2-1 : charset dépend de l'en-tête serveur (voir DEFECTS.md) |
| Persistance après rechargement | e2e (reload dans « creation mouvement », « retour navigateur », « projection persistée ») + audit L9 (données extrêmes retrouvées après reload) | — | — | **PASS** | localStorage = par navigateur (dit honnêtement dans l'app) |
| Accessibilité (VoiceOver/équiv., clavier, 44 pt, DT, reduced motion/transparency, 320) | e2e « a11y L3/L5/L6/L7 », test 65 ; design system (contrastes mesurés ≥ 4.5:1, cibles, focus) ; natif previews a11y + `testSelectionCaptionWrapsAtAccessibilitySizes`, `testNetWorthSelectedStateRendersAt320WithA11yType` (pixel) | pièce 320-a11y 960×1212 ; `l8-390-…-transparence-réduite` | — | **PASS** | VoiceOver RÉEL à l'oreille = geste humain conseillé (checklist iPhone) |
| Performance (10 000 mouvements) | test 66 : répartis 32 ms / concentrés 30 ms jusqu'à la peinture, ≤ 200 lignes DOM après CHAQUE navigation, référence indépendante première/dernière ligne ; natif : listes bornées par mois | — | — | **PASS** | mesures CI de référence = run final (voir statut) |
| Graphiques sélectionnables = séries existantes | e2e 63-64 (étiquette = valeur EXACTE de la série, clavier, extrêmes 6…294) ; natif `nearestTrendPoint`/`trendSelectionLabel` testés + geste Demo asserté contre la fixture (CHF 138'400.00) | captures L8 (7) + pièce sélection | — | **PASS** | aucun connu |
| Haptique natif | `testHapticTriggerAdvancesOnlyOnRealSave` (déclencheur : validation ET save réussis, sinon rien) | — | **H OBLIGATOIRE : sensation physique** (protocole 4 points) | **PASS (déclencheur)** / **PENDING HUMAN (sensation)** | le simulateur ne vibre pas — seul le propriétaire peut clore |
| Mode démo | e2e « démo pays » ; natif ADR-013 (conteneur in-memory isolé, bannière permanente, `.id(isDemoMode)`) | bannière visible sur captures Demo | — | **PASS** | aucun connu |

## Limites honnêtes de cette matrice

- Les preuves « V » iOS proviennent du workflow Demo (simulateur
  iPhone 16, iOS de la CI) — pas d'un appareil physique.
- Aucun contrôle humain n'est coché ici : les cases H restent au
  propriétaire (haptique, Face ID réel, VoiceOver à l'oreille, QA
  appareil — `IPHONE_QA_CHECKLIST.md`).
- Les temps « PERF L8 » de référence sont ceux du run CI final de L9
  (imprimés dans les logs du job Web).
