# Matrice des écrans et composants — Budget Neon Ultra

État observé au HEAD source `26d186e` (26.07.2026). Cette matrice sert de
contrat de couverture : chaque lot NU2–NU7 doit pointer les lignes qu'il
rebranche, et NU9 la revalide intégralement.

## 1. Navigation — DIVERGENCE PWA / iOS (décision produit séparée)

| Plateforme | Barre | Détail |
|---|---|---|
| PWA | 4 onglets + ＋ central | Mois, Budget · ＋ (46×46, ouvre le menu rapide) · Comptes, Plus. **Mouvements vit dans Plus** (sous-vue avec retour), décision propriétaire du tour 26.07.2026 (`26d186e`, `e4b1a25`). |
| iOS | 5 onglets + ＋ flottant | Mois, Mouvements, Budget, Comptes, Plus (`RootView.swift:57-77`) + menu ＋ flottant en surimpression bas-droite (`quickCreateButton`, `RootView.swift:47-49`). |

**Interdiction NU0–NU8 : ne pas réconcilier.** La convergence (4+1 vs 5)
exige une décision produit explicite du propriétaire, enregistrée par ADR,
avant tout lot de navigation.

## 2. Écrans PWA (`webapp/index.html`)

| Écran / vue | Accès | Composants clés | Lot Neon Ultra |
|---|---|---|---|
| Mois (Accueil) | onglet 1 | titre-salutation, héros « Argent disponible » + CTA Ajouter, 4 métriques, priorité, actions rapides, fonds d'urgence, Check du mois, courbe 6 mois, widgets | NU2 |
| Budget | onglet 2 | anneau/encours, groupes Essentiel/Discrétionnaire/Épargne/Impôts, barres de progression, badges | NU2 |
| Feuille Ajouter (txForm) | ＋ central, héros, quick-menu | chips de type, champs, chips comptes, détails repliés | NU2 |
| Menu rapide (quickMenu) | ＋ central | 8 destinations de création | NU2 |
| Comptes | onglet 3 | total, cartes de comptes, fiche compte + courbe | NU4 |
| Mouvements | Plus → Mouvements | recherche, 5 filtres, groupes par jour, pagination ≤ 200 lignes | NU4 |
| Plus (hub) | onglet 4 | 5 groupes d'intentions, 11 destinations | NU4 |
| Factures | Plus | liste, retard/à payer, marquer payé | NU5 |
| Paiements réguliers | Plus | charges/revenus/abonnements, validation salaire | NU5 |
| Objectifs | Plus | cartes objectifs, progression, versements | NU5 |
| Impôts | Plus | estimé/payé/encore dû, réserve mensuelle | NU5 |
| Assurances & prévoyance | Plus | primes, LPP, 3e pilier | NU5 |
| Patrimoine | Plus | fortune nette, courbe scrubber, composition actifs/dettes | NU6 |
| Année en revue | Plus | bilan, taux d'épargne, mois bouclés | NU6 |
| Import CSV & documents | Plus | mapping, aperçu, confirmation, documents | NU7 |
| Assistant | Plus | 4 questions canoniques, réponses locales expliquées | NU7 |
| Réglages | Plus | apparence, code, export/sauvegarde/restauration, démo | NU7 |
| Onboarding (6 étapes) | premier lancement | pays, foyer, prénoms, salaire, solde, objectif — dots en bas, étapes centrées | NU7 |
| Verrouillage | code actif | écran code 6 chiffres | NU7 |
| Feuilles secondaires (19) | diverses | comptes, lignes budget, objectifs, récurrents, actifs/dettes, assurances, prévoyance, impôts, code, documents, factures, salaire, taux, rapprochement, prénom, devise, pays, widgets | avec leur écran hôte |

## 3. Écrans iOS (SwiftUI)

| Écran | Fichier | Lot |
|---|---|---|
| HomeTab (Mois) | `Budget/Features/Dashboard/HomeTab.swift` | NU3 |
| BudgetTab | `Budget/Features/Budget/BudgetTab.swift` | NU3 |
| TransactionFormView (Ajouter) | `Budget/Features/Transactions/…` | NU3 |
| TransactionsTab (Mouvements) | `Budget/Features/Transactions/…` | NU4 |
| AccountsTab | `Budget/Features/Accounts/AccountsTab.swift` | NU4 |
| Shell (RootView, bannière démo, verrouillage) | `Budget/App/RootView.swift` | NU4 |
| MoreTab + Factures/Objectifs/Récurrents | `Budget/Features/More/…`, `Goals/…` | NU5 |
| Patrimoine + graphiques | `Budget/Features/NetWorth/…` | NU6 |
| Onboarding + Réglages + confiance | `Budget/Features/Onboarding/…`, `Settings/…` | NU7 |
| Tokens | `Budget/Core/DesignSystem/DesignTokens.swift`, `GlassCard.swift` | NU1 |

## 4. Composants transversaux

| Composant | Règle Neon Ultra |
|---|---|
| Carte de liste | mate, surface `#11141C`, bordure `#293040`, sans blur |
| Carte élevée / héros | `#181C26`, point focal unique du viewport |
| CTA principal | gradient `#C000A4 → #6E00E8`, texte `#F5F7FA` AA |
| Barre d'onglets | `#0B0D13` ; état actif violet/magenta, jamais les trois néons à la fois |
| Chips / filtres | ≥ 44 pt, état pressé visible, `aria-pressed` |
| Graphiques | sélection cyan, séries sémantiques, étiquettes textuelles |
| Badges d'état | sémantique uniquement (vert/corail/ambre) |
| Focus visible | ≥ 2 px, jamais la couleur seule |

## 5. États à couvrir pour chaque écran rebranché

Vide guidé · chargé · erreur · montant long (7 chiffres, négatif) · contenu
long · clavier ouvert · 320 px · Reduce Motion · Reduce Transparency ·
Dynamic Type (iOS) / zoom texte (web).
