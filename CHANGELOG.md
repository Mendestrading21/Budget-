# Changelog

Les changements notables de Budget sont consignés ici. Le statut de
publication fait foi dans `BUDGET_1_0_READINESS.md`.

## [Unreleased]

### Added

- Audit automatisé de la structure du dépôt, de la version Xcode et des
  artefacts sensibles suivis par Git.
- Gouvernance GitHub : CODEOWNERS, modèles de PR et d’issues, règles de
  contribution et procédure de sécurité.
- Porte de sortie unique `BUDGET_1_0_READINESS.md`.

### Changed

- Distinction visible entre argent disponible maintenant et projection de
  fin de mois intégrée sur la PWA et iOS; six fixtures canoniques
  verrouillent désormais le moteur FE2 des deux côtés.
- Documentation réalignée sur Budget Prisme et la navigation
  `Mois · Historique · Budget · Comptes · Gérer`.
- Publication TestFlight verrouillée sur un SHA explicite de `main` avec
  CI `push` verte.
- Documentation TestFlight, QA et fiche App Store réécrite pour le
  produit actuel, sans promesse non vérifiée.
- CI durcie avec permissions minimales et annulation des exécutions
  obsolètes.

## [1.0.0-rc] — 2026-08-18

> Candidat de release documenté; cette section ne signifie pas qu’un tag
> ou une publication App Store existe déjà.

### Added

- Application iPhone native SwiftUI/SwiftData/Swift Charts.
- PWA installable et utilisable hors ligne.
- Lecture mensuelle, historique, budgets, comptes, patrimoine, impôts,
  prévoyance, objectifs et gestion.
- Suites automatisées iOS, e2e navigateur, parité financière et design.
- Manifeste de confidentialité embarqué dans le produit Release.
- Mode iPhone uniquement vérifié en CI.

### Changed

- Modèle financier centré sur des agrégats explicites et testables.
- Distinction visible entre argent réel et projection de fin de mois.
- Navigation commune en cinq destinations.
- Identité visuelle sombre Budget Prisme et iconographie Budget Glyphs.

### Fixed

- Neutralité des virements internes.
- Cas de double comptage de prévoyance documenté et couvert par régression.
- Paiements d’impôts matérialisés comme paiements fiscaux plutôt que comme
  dépenses de vie.
- Consultation annuelle utilisant l’année effectivement sélectionnée.

### Security

- Données locales, sans compte ni connexion bancaire simulée.
- Vérification du manifeste de confidentialité dans le produit compilé.
- Voile de confidentialité et verrouillage biométrique couverts par la QA.
