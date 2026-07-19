# Budget project status

Last updated: 2026-07-19
Current branch: claude/execute-tbkhsd
Current phase: Phases 0 à 6 terminées — prochaine : Phase 7 (Impôts)
Invocation mode: build (session Claude Code sur Linux, vérification via CI GitHub Actions)

## Product goal (confirmé par l'utilisateur, 2026-07-19)

1. **Court terme** : usage personnel par l'utilisateur sur son propre iPhone (via TestFlight dès qu'un compte Apple Developer existe).
2. **Moyen terme** : publication sur l'App Store pour la **vendre** — la Phase 14 (release) devra inclure le choix du modèle de prix (app payante vs achat intégré), les métadonnées store et la conformité App Review.

## Product state

- App launches: phases 0-4 compilées et validées sur Mac par l'utilisateur ; ajouts de la phase 5 NON COMPILÉS (Linux, pas de toolchain Apple)
- Persistence: SwiftData, schéma versionné V3 (`BudgetSchemaV3` : + RecurringTransaction, + BudgetTransaction.recurringID), migrations légères V1→V2→V3 (ADR-006/007)
- Demo data: `DemoDataFactory` — mode démo isolé + previews déterministes (date fixe 15.06.2026)
- Onboarding: flux complet 5 étapes (confidentialité, ménage, canton, taux d'impôts 30 %, premier compte) + catégories suisses par défaut
- Accounts: liste groupée, détail, formulaire, réconciliation horodatée, archivage, flags cash/patrimoine, solde dérivé
- Transactions: 9 types, validation typée FR, virements internes atomiques et neutres, liste avec mois/recherche/filtres/file non catégorisée, dupliquer/supprimer
- Dashboard: `MonthlySnapshotService` (pur, calendrier + « now » injectés), montant vraiment disponible avec décomposition, budget quotidien, 4 cartes, graphique 6 mois (Swift Charts) avec résumé accessible, 3 actions prioritaires, mouvements récents
- Budget: onglet complet — lignes par catégorie (groupes essentiel/discrétionnaire/épargne/impôts), planifié vs réel avec badge de dépassement, section « Hors budget » (réconciliation totale), copie du mois précédent, grille annuelle 12 mois, graphique dashboard budget-vs-réel avec fallback 6 mois
- Recurring/subscriptions: entité unique (charges/revenus/abonnements), occurrences par multiples d'ancre sans dérive, dédup prévision/réel par recurringID, équivalents mensuel/annualisé, échéances de résiliation (badge + action prioritaire), section « À venir ce mois » avec comptabilisation en un geste, liste + formulaire complets (ADR-007)
- Taxes: taux sur `Household` (ADR-003), résumé mensuel recommandé/payé/écart ; module complet en Phase 7
- Goals: non commencé (Phase 8)
- Insurance/pension: non commencé (Phase 9)
- Net worth: somme des comptes inclus (convention signée, dettes négatives) ; entités Asset/Liability en Phase 10
- Import/export: champ `importFingerprint` prêt ; module en Phase 11
- Security: non commencé (Phase 12)
- Release readiness: non commencé

## Current acceptance criteria (Phases 0-4)

- [x] Phase 0 : fondation compilable en principe (projet Xcode 16, thème, formatage fr-CH, modèles, démo, tests)
- [x] Phase 1 : un nouvel utilisateur crée un profil local valide et retombe dans l'app au relancement (test de persistance inclus)
- [x] Phase 2 : types de comptes multiples, formatage CHF, soldes persistants, archivage sans perte d'historique
- [x] Phase 3 : tests de neutralité des virements et de rejets de transactions invalides ; liste gère vide et volume
- [x] Phase 4 : toutes les valeurs du dashboard dérivent des données persistées via des tests d'invariants
- [x] Phase 5 : planifié et réel restent séparés ; toutes les variances se réconcilient (tests) ; copie de mois sans doublons ; grille annuelle
- [x] Phase 6 : toute charge active apparaît exactement une fois dans les prévisions du mois ; les inactives jamais (tests d'échéancier + dédup)
- [x] Build + tests des phases 0-4 validés sur Mac par l'utilisateur (« Ça fonctionne ✓ »)
- [x] Build + 82 tests de la phase 5 VERTS en CI GitHub Actions (run 29701802089)
- [ ] CI verte sur la phase 6 (en cours au moment de cette mise à jour — voir Actions)
- [ ] Migration V1→V3 à valider sur un appareil contenant un store existant (non couvrable en CI unitaire)

## Build and test evidence

- CI GitHub Actions (`.github/workflows/ci.yml`, runner macos-15, simulateur iPhone 16) : build + `xcodebuild test` à chaque push.
- **Run vert** : run 29701802089 sur le commit `5f22ec4` (phases 0-5 + correctifs) — build OK, **82 tests, 0 échec**.
  https://github.com/Mendestrading21/Budget-/actions/runs/29701802089
- Historique : le run 29701528788 (rouge) a attrapé un vrai bug SwiftData dans les données de démo (mouvements futurs persistés via le graphe de relations), corrigé en `5f22ec4`.
- Reste à vérifier sur appareil : la migration V1→V2 par-dessus un store réel existant, et le parcours manuel complet (la CI ne couvre que build + tests unitaires).

## Decisions made

Voir DECISION_LOG.md (ADR-001 à ADR-005). Convention patrimoine : soldes signés, un compte de dette (carte, prêt, hypothèque) porte un solde négatif.

## Known risks or blockers

- Ajouts phase 5 non compilés : erreurs résiduelles possibles à l'ouverture dans Xcode.
- Migration V1→V2 : à valider impérativement sur un simulateur/appareil contenant déjà des données des phases 0-4 (aucune perte attendue, changement additif).
- Filtres et rapports calculés en mémoire (volumes V1 acceptables) — indexation/#Predicate à revisiter en Phase 13 (performance).

## Next exact action

1. Attendre la CI verte sur la phase 6 ; en cas d'échec, corriger et repousser (boucle habituelle).
2. Puis : `/budget-v1 build` → Phase 7 (module Impôts complet : profil fiscal, provision réservé/payé/arriérés, échéances, migration du taux depuis Household).
