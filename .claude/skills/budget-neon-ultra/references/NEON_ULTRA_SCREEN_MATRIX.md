# Matrice des écrans et composants — Budget Neon Ultra

État observé au HEAD source `26d186e` (26.07.2026). Cette matrice sert de
contrat de couverture : chaque lot NU2–NU7 doit pointer les lignes qu'il
rebranche, et NU9 la revalide intégralement.

## 1. Navigation — convergence PWA / iOS (ADR-026)

| Plateforme | Barre | Détail |
|---|---|---|
| PWA | 5 destinations, aucun bouton global | `Mois · Historique · Budget · Comptes · Gérer`. Historique est une destination de premier niveau ; aucun ＋ central ni menu rapide global. |
| iOS | 5 destinations, aucun bouton global | `Mois · Historique · Budget · Comptes · Gérer`. Aucun ＋ flottant au-dessus du contenu ou de la barre d'onglets. |

La divergence historique documentée par ADR-024 est close par ADR-026. Chaque
écran héberge ses propres créations ; l'accueil conserve une seule action
principale « Ajouter un mouvement ». Cette convergence de navigation ne
modifie aucune formule financière. Le contrat des récurrents en retard et de
leur déduplication stricte est documenté séparément par ADR-027.

## 2. Écrans PWA (`webapp/index.html`)

| Écran / vue | Accès | Composants clés | Lot Neon Ultra |
|---|---|---|---|
| Mois (Accueil) | onglet 1 | mois, héros « Disponible » + CTA Ajouter, 4 montants, widget unique des factures mensuelles | NU2 |
| Historique | onglet 2 | recherche, 5 filtres, groupes par jour, pagination ≤ 200 lignes | NU4 |
| Budget | onglet 3 | anneau/encours, groupes Essentiel/Discrétionnaire/Épargne/Impôts, barres de progression, badges | NU2 |
| Comptes | onglet 4 | total, cartes de comptes, fiche compte + courbe | NU4 |
| Gérer (hub) | onglet 5 | groupes d'intentions et destinations secondaires, sans création globale flottante | NU4 |
| Feuille Ajouter (txForm) | CTA de Mois | chips de type, champs, chips comptes, détails repliés | NU2 |
| Factures | Gérer | liste, retard/à payer, marquer payé | NU5 |
| Paiements réguliers | Gérer | charges/revenus/abonnements, validation salaire | NU5 |
| Objectifs | Gérer | cartes objectifs, progression, versements | NU5 |
| Impôts | Gérer | estimé/payé/encore dû, réserve mensuelle | NU5 |
| Assurances & prévoyance | Gérer | primes, LPP, 3e pilier | NU5 |
| Patrimoine | Gérer | fortune nette, courbe scrubber, composition actifs/dettes | NU6 |
| Année en revue | Gérer | bilan, taux d'épargne, mois bouclés | NU6 |
| Import CSV & documents | Gérer | mapping, aperçu, confirmation, documents | NU7 |
| Assistant | Gérer | 4 questions canoniques, réponses locales expliquées | NU7 |
| Réglages | Gérer | apparence, code, export/sauvegarde/restauration, démo | NU7 |
| Onboarding (6 étapes) | premier lancement | pays, foyer, prénoms, salaire, solde, objectif — dots en bas, étapes centrées | NU7 |
| Verrouillage | code actif | écran code 6 chiffres | NU7 |
| Feuilles secondaires (19) | action locale de leur écran hôte | comptes, lignes budget, objectifs, récurrents, actifs/dettes, assurances, prévoyance, impôts, code, documents, factures, salaire, taux, rapprochement, prénom, devise, pays, widgets | avec leur écran hôte |

## 3. Écrans iOS (SwiftUI)

| Écran | Fichier | Lot |
|---|---|---|
| HomeTab (Mois, onglet 1) | `Budget/Features/Dashboard/HomeTab.swift` | NU3 |
| TransactionsListView (Historique, onglet 2) | `Budget/Features/Transactions/…` | NU4 |
| BudgetTab (onglet 3) | `Budget/Features/Budget/BudgetTab.swift` | NU3 |
| AccountsTab (onglet 4) | `Budget/Features/Accounts/AccountsTab.swift` | NU4 |
| MoreTab (Gérer, onglet 5) | `Budget/Features/More/MoreTab.swift` | NU4 |
| TransactionFormView (Ajouter) | action locale de son écran hôte | NU3 |
| Shell sans bouton global (RootView, bannière démo, verrouillage) | `Budget/App/RootView.swift` | NU4 |
| Gérer + Factures/Objectifs/Récurrents | `Budget/Features/More/…`, `Goals/…` | NU5 |
| Patrimoine + graphiques | `Budget/Features/NetWorth/…` | NU6 |
| Onboarding + Réglages + confiance | `Budget/Features/Onboarding/…`, `Settings/…` | NU7 |
| Tokens | `Budget/Core/DesignSystem/DesignTokens.swift`, `GlassCard.swift` | NU1 |

## 4. Composants transversaux

| Composant | Règle Neon Ultra |
|---|---|
| Carte de liste | mate, surface `#11141C`, bordure `#293040`, sans blur |
| Carte élevée / héros | `#181C26`, point focal unique du viewport |
| CTA principal | gradient `#C000A4 → #6E00E8`, texte `#F5F7FA` AA |
| Barre d'onglets | `#0B0D13` ; 5 destinations stables, aucun bouton central ou flottant ; état actif violet/magenta, jamais les trois néons à la fois |
| Chips / filtres | ≥ 44 pt, état pressé visible, `aria-pressed` |
| Graphiques | sélection cyan, séries sémantiques, étiquettes textuelles |
| Badges d'état | sémantique uniquement (vert/corail/ambre) |
| Focus visible | ≥ 2 px, jamais la couleur seule |

## 5. États à couvrir pour chaque écran rebranché

Vide guidé · chargé · erreur · montant long (7 chiffres, négatif) · contenu
long · clavier ouvert · 320 px · Reduce Motion · Reduce Transparency ·
Dynamic Type (iOS) / zoom texte (web).
