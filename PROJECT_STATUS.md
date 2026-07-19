# Budget project status

Last updated: 2026-07-19
Current branch: claude/execute-tbkhsd
Current phase: Phases 0 à 4 terminées (build non vérifié) — prochaine : Phase 5 (Budget)
Invocation mode: bootstrap + build (session Claude Code sur Linux)

## Product state

- App launches: code complet (onboarding → 5 onglets) — NON COMPILÉ dans cet environnement (Linux, pas de toolchain Apple)
- Persistence: SwiftData, schéma versionné V1 (`BudgetSchemaV1`) + plan de migration ; container production séparé du in-memory
- Demo data: `DemoDataFactory` — mode démo isolé + previews déterministes (date fixe 15.06.2026)
- Onboarding: flux complet 5 étapes (confidentialité, ménage, canton, taux d'impôts 30 %, premier compte) + catégories suisses par défaut
- Accounts: liste groupée, détail, formulaire, réconciliation horodatée, archivage, flags cash/patrimoine, solde dérivé
- Transactions: 9 types, validation typée FR, virements internes atomiques et neutres, liste avec mois/recherche/filtres/file non catégorisée, dupliquer/supprimer
- Dashboard: `MonthlySnapshotService` (pur, calendrier + « now » injectés), montant vraiment disponible avec décomposition, budget quotidien, 4 cartes, graphique 6 mois (Swift Charts) avec résumé accessible, 3 actions prioritaires, mouvements récents
- Budget: non commencé (Phase 5) — le graphique budget-vs-réel remplacera le graphique revenus/coût de la vie quand les budgets existeront
- Recurring/subscriptions: non commencé (Phase 6)
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
- [ ] Build + tests exécutés sur Mac (IMPOSSIBLE dans cet environnement — voir ci-dessous)

## Build and test evidence

- Build command: `xcodebuild -project Budget.xcodeproj -scheme Budget -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Result: NON EXÉCUTÉ — session sur Linux sans Xcode. Xcode 16+ requis (format de projet objectVersion 77).
- Test command: `xcodebuild -project Budget.xcodeproj -scheme Budget -destination 'platform=iOS Simulator,name=iPhone 16' test`
- Result: NON EXÉCUTÉ (même raison). Une passe de revue statique par agent a été effectuée à la place ; les correctifs sont dans l'historique git.
- Simulator/device: aucun

## Decisions made

Voir DECISION_LOG.md (ADR-001 à ADR-005). Convention patrimoine : soldes signés, un compte de dette (carte, prêt, hypothèque) porte un solde négatif.

## Known risks or blockers

- Jamais compilé : des erreurs de compilation résiduelles sont possibles à la première ouverture dans Xcode — les corriger puis relancer les tests.
- pbxproj manuscrit : si Xcode < 16, régénérer un projet et y glisser les dossiers `Budget/` et `BudgetTests/`.
- Filtres de liste calculés en mémoire (volumes V1 acceptables) — indexation/#Predicate à revisiter en Phase 13 (performance).

## Next exact action

1. Sur Mac : ouvrir `Budget.xcodeproj`, compiler, exécuter les tests, corriger les éventuels écarts, cocher la case build ci-dessus avec la sortie de commande.
2. Puis : `/budget-v1 build` → Phase 5 (budgets mensuels/annuels, variances, grille 12 mois).
