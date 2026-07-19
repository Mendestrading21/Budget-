# Budget project status

Last updated: 2026-07-19
Current branch: claude/execute-tbkhsd
Current phase: Phases 0 à 9 terminées — prochaine : Phase 10 (Patrimoine)
Invocation mode: build (session Claude Code sur Linux, vérification via CI GitHub Actions)

## Product goal (confirmé par l'utilisateur, 2026-07-19)

1. **Court terme** : usage personnel par l'utilisateur sur son propre iPhone (via TestFlight dès qu'un compte Apple Developer existe).
2. **Moyen terme** : publication sur l'App Store pour la **vendre** — la Phase 14 (release) devra inclure le choix du modèle de prix (app payante vs achat intégré), les métadonnées store et la conformité App Review.

## Product state

- App launches: phases 0-7 compilées et testées en CI GitHub Actions (dernier run vert : 29702569987)
- Persistence: SwiftData, schéma versionné V6 (`BudgetSchemaV6` : + InsuranceContract/PensionAsset), migrations légères V1→…→V6 (ADR-006..010)
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
- Net worth: somme des comptes inclus (convention signée, dettes négatives) ; entités Asset/Liability en Phase 10
- Import/export: champ `importFingerprint` prêt ; module en Phase 11
- Security: non commencé (Phase 12)
- Release readiness: non commencé

## Current acceptance criteria (Phases 0-7)

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

- [ ] Migration V1→V6 à valider sur un appareil contenant un store existant (non couvrable en CI unitaire)

## Build and test evidence

- CI GitHub Actions (`.github/workflows/ci.yml`, runner macos-15, simulateur iPhone 16) : build + `xcodebuild test` à chaque push.
- **Derniers runs verts** : phase 5 (29701802089), phase 6 (29702260574), phase 7 (29702569987) — build OK, suite complète sans échec.
  https://github.com/Mendestrading21/Budget-/actions
- Historique : le run 29701528788 (rouge) a attrapé un vrai bug SwiftData dans les données de démo (mouvements futurs persistés via le graphe de relations), corrigé en `5f22ec4`.
- Reste à vérifier sur appareil : la migration V1→V6 par-dessus un store réel existant, et le parcours manuel complet (la CI ne couvre que build + tests unitaires).

## Decisions made

Voir DECISION_LOG.md (ADR-001 à ADR-010). Convention patrimoine : soldes signés, un compte de dette (carte, prêt, hypothèque) porte un solde négatif.

## Known risks or blockers

- Migration V1→V6 : à valider sur un simulateur/appareil contenant déjà des données réelles (aucune perte attendue, changements additifs).
- Filtres et rapports calculés en mémoire (volumes V1 acceptables) — indexation/#Predicate à revisiter en Phase 13 (performance).

## Next exact action

1. `/budget-v1 build` → Phase 10 (patrimoine : actifs, dettes, historique, tendance).
