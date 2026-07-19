# Budget project status

Last updated: 2026-07-19
Current branch: claude/execute-tbkhsd
Current phase: Phase 0 — Fondation (terminée, build non vérifié)
Invocation mode: bootstrap

## Product state

- App launches: code complet (shell 5 onglets + fond de marque) — NON COMPILÉ dans cet environnement (Linux, pas de toolchain Apple)
- Persistence: SwiftData, schéma versionné V1 (BudgetSchemaV1) + plan de migration vide
- Demo data: DemoDataFactory (in-memory uniquement, données fictives, ~3 mois)
- Onboarding: écran d'accueil de marque + mode démo (flux complet en Phase 1)
- Accounts: modèle + AccountBalanceService (UI en Phase 2)
- Transactions: modèle + convention montants positifs (UI + validation en Phase 3)
- Dashboard: placeholder (Phase 4)
- Budget: non commencé (Phase 5)
- Recurring/subscriptions: non commencé (Phase 6)
- Taxes: taux de provision sur Household (défaut 30 %) ; module en Phase 7
- Goals: non commencé (Phase 8)
- Insurance/pension: non commencé (Phase 9)
- Net worth: non commencé (Phase 10)
- Import/export: champ importFingerprint prévu ; module en Phase 11
- Security: non commencé (Phase 12)
- Release readiness: non commencé

## Current acceptance criteria (Phase 0)

- [x] Projet Xcode (format Xcode 16, groupes synchronisés) avec cibles Budget + BudgetTests et scheme partagé
- [x] Thème (DesignTokens, GlassCard), formatage fr-CH centralisé, Decimal partout
- [x] Container SwiftData versionné + factory production/in-memory
- [x] Modèles: Household, HouseholdMember, Account, BudgetCategory, BudgetTransaction
- [x] Données démo isolées + previews déterministes
- [x] Tests de fondation (formatage, soldes, persistance)
- [ ] Build + tests vérifiés sur Mac (impossible dans cet environnement)

## Build and test evidence

- Build command: `xcodebuild -project Budget.xcodeproj -scheme Budget -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Result: NON EXÉCUTÉ — environnement Linux sans Xcode. À exécuter sur Mac (Xcode 16+ requis par le format du projet).
- Test command: `xcodebuild -project Budget.xcodeproj -scheme Budget -destination 'platform=iOS Simulator,name=iPhone 16' test`
- Result: NON EXÉCUTÉ (même raison)
- Simulator/device: aucun disponible ici

## Decisions made

Voir DECISION_LOG.md (ADR-001 à ADR-004).

## Known risks or blockers

- Le projet n'a jamais été compilé : des erreurs de compilation sont possibles et devront être corrigées à la première ouverture sur Mac.
- Le pbxproj est écrit à la main (format objectVersion 77) : nécessite Xcode 16+.

## Next exact action

- Sur Mac : ouvrir Budget.xcodeproj, compiler, lancer les tests, corriger les éventuelles erreurs.
- Ensuite : `/budget-v1 continue` (ou suivre le roadmap) pour les phases suivantes.
