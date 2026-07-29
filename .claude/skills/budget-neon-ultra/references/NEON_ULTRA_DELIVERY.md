# Plan de livraison — Budget Neon Ultra (NU0–NU9)

Un lot = une session = un périmètre vertical (code + états + tests + rendu +
captures + documentation + un commit). Aucun lot ne commence sans que le
précédent soit validé par le propriétaire (statut DONE dans
`NEON_ULTRA_STATUS.md`). Chaque lot se termine en VERIFYING.

## NU0 — Gouvernance et baseline

- Créer le skill et ses références ; ADR-024 ; alignement minimal de
  `CLAUDE.md` et du routage `budget-v1` ; `NEON_ULTRA_STATUS.md`.
- Baseline prouvée depuis le HEAD source CI-vert : e2e PWA, parités, design
  system, tests iOS (total exact), builds Debug/Release, PrivacyInfo,
  `UIDeviceFamily == [1]`, zéro pageerror/erreur console, persistance disque,
  sauvegarde/restauration, tests financiers nommés, mesures de performance,
  captures PWA 390/320 inspectées, captures iOS inventoriées.
- Documenter la divergence de navigation PWA/iOS SANS la réconcilier.
- AUCUN écran, rendu, token ou logique modifiés.

## NU1 — Tokens et primitives

- Introduire les tokens Neon Ultra (PWA : variables CSS ; iOS :
  `DesignTokens.swift`) SANS rebrancher les écrans : alias d'abord, bascule
  contrôlée ensuite.
- Primitives : carte mate, carte élevée, CTA gradient, chip, badge, focus.
- Étendre le test design system aux nouvelles paires de contraste (toutes les
  paires texte/surface et sémantique/canvas de la constitution).
- Aucun écran ne change encore d'apparence sans preuve de contraste.

## NU2 — Pilote PWA : Mois, Budget, Ajouter

- Rebrancher les écrans Mois et Budget et la feuille Ajouter sur les tokens
  Neon Ultra ; un seul point focal par viewport ; CTA gradient.
- Avant/après 390 + 320, e2e adaptés, zéro régression de parcours.

## NU3 — Pilote SwiftUI équivalent

- HomeTab, BudgetTab et la feuille de création natives sur les tokens Neon
  Ultra ; parité visuelle raisonnable avec NU2 ; CI macOS verte (tests iOS
  complets), captures simulateur via le workflow Demo.

## NU4 — Mouvements, Comptes et shell

- Listes Mouvements (PWA : sous-vue Plus ; iOS : onglet), Comptes, barres de
  navigation et shell (bannière démo, verrouillage) sur les tokens.
- Cartes de listes mates ; densité préservée ; pagination intacte.

## NU5 — Factures, Objectifs et Récurrents

- Écrans Factures, Objectifs, Paiements réguliers des deux plateformes.

## NU6 — Patrimoine et graphiques

- Patrimoine, courbes et répartitions ; sélection cyan ; séries sémantiques ;
  échelles et valeurs STRICTEMENT identiques aux séries existantes.

## NU7 — Onboarding, confiance, réglages et identité

- Onboarding (textes conservés, habillage Neon Ultra), écrans de confiance
  (sauvegarde/restauration), Réglages, moments de marque (gradient autorisé).

## NU8 — Mouvement, accessibilité et performances

- Passe transversale : animations courtes, Reduce Motion/Transparency,
  VoiceOver/Dynamic Type/a11y web, 10 000 mouvements, mesures de peinture
  comparées à la baseline NU0 (aucune dégradation > 20 %).

## NU9 — Audit final

- Audit écran par écran et bouton par bouton (matrice), défauts P0–P3,
  preuves automatiques/visuelles/humaines distinguées, dossier
  `docs/neon-ultra/final-audit/`, réserves humaines explicites
  (iPhone réel, haptique, Face ID, VoiceOver physique : PENDING HUMAN).

## Discipline commune

- Bases minimales (jamais moins) : 72 e2e · 5 parités · design system vert ·
  259 tests iOS · 0 échec · 0 erreur console · `UIDeviceFamily == [1]`.
- Tests adaptés, jamais supprimés ni affaiblis ; fixtures fictives
  déterministes uniquement (jamais les données réelles du propriétaire).
- Un commit ciblé par lot, poussé sur `refonte/budget-neon-ultra-v1`
  uniquement ; CI attendue et inspectée avant le rapport.
- Aucun merge, PR, tag, déploiement, TestFlight ou App Store sans
  autorisation explicite.
