# Refonte complète Horizon — matrice et architecture cible

Branche : `codex/budget-leader-refonte` · Base vérifiée : 39 e2e + 5 parité verts, CI 7/7.
Règle d'or : la logique métier, les calculs (centimes G01, invariants ADR-001→019),
les données, migrations et la parité web/natif sont **intouchables**. La refonte
porte sur l'expérience : hiérarchie, composants, textes, mouvement, identité.

> Tokens visuels v2 : **en attente du skill `budget-horizon` (zip utilisateur)** —
> les images de `assets/visual-references/` fixeront la direction artistique
> définitive. Tout le reste de ce document est indépendant des images.

## 1. Matrice — navigation et écrans

| Élément | Verdict | Justification |
|---|---|---|
| 5 onglets (Accueil, Mouvements, Budget, Comptes, Plus) | **CONSERVER** | Architecture validée, identique au natif ; 5 = plafond |
| Accueil : héros « Argent disponible » + décomposition | **AMÉLIORER** | Ajouter la tendance (sparkline 6 mois) dans le héros ; garder le détail replié |
| Accueil : 4 actions rapides | **CONSERVER** | Livré (B04), conforme blueprint |
| Accueil : recommandation du mois | **AMÉLIORER** | Icône vivante + action directe intégrée (bouton), pas seulement navigation |
| Accueil : Check du mois | **AMÉLIORER** | Progression animée, célébration sobre au bouclage ; logique intacte |
| Accueil : sections Salaire/Factures/Dépenses/Envois | **FUSIONNER** | Regrouper en « Ce mois » avec sous-sections repliables — l'accueil reste < 3 écrans de hauteur |
| Accueil : patrimoine replié (details) | **CONSERVER** | Livré (B03), conforme |
| Mouvements : liste + recherche + filtres | **AMÉLIORER** | Groupes par jour avec sous-totaux, filtres en chips avec compteur |
| Budget : héros + anneau + barres par groupe | **AMÉLIORER** | Anneau livré ; ajouter jauges par groupe (essentiel/discrétionnaire/épargne/impôts) |
| Budget : grille annuelle | **CONSERVER** | Utile, secondaire, déjà repliée derrière navigation |
| Comptes : groupes + hero disponible | **AMÉLIORER** | Fraîcheur du solde (« mis à jour il y a N j ») par compte |
| Fiche de compte (courbe, cumuls, historique) | **CONSERVER** | Riche et conforme blueprint |
| Plus : hub groupé par intention | **CONSERVER** | Livré (B07), états vivants |
| Objectifs (cartes + scénario + explication) | **CONSERVER** | Livré (L6) |
| Impôts (réconcilié, hypothèses visibles) | **CONSERVER** | Logique ADR-008/018 — ne pas toucher aux formules |
| Patrimoine (décomposition, projection, 12 mois) | **AMÉLIORER** | Ajouter répartition en composition (barres empilées ou donut accessible) |
| Assurances & prévoyance | **CONSERVER** | Conforme ; textes déjà honnêtes |
| Année en revue | **CONSERVER** | Livré, riche |
| Factures (+ charges de l'année) | **CONSERVER** | Livré (L5) |
| Import CSV & documents | **CONSERVER** | Confirmation réelle livrée ; flux éprouvé |
| Réglages | **CONSERVER** | Apparence 3 états, sauvegarde guidée livrées |
| Onboarding 5 écrans | **REMPLACER (réécrire)** | R6 : mêmes 5 étapes et données, textes/rythme/visuel réécrits selon références |
| Écran de verrouillage | **AMÉLIORER** | Aligner sur les tokens v2 (déjà fonctionnel) |
| — éléments à RETIRER | **AUCUN** | Rien n'est retiré sans preuve de parité ; aucun candidat identifié |

## 2. Matrice — composants et système

| Composant | Verdict | Cible |
|---|---|---|
| Tokens CSS (bg/surface/line/…) + clair/sombre/système | **AMÉLIORER** | v2 selon images : profondeur douce, rayons, ombres, élévations |
| Cartes `.card` (verre) | **AMÉLIORER** | Hiérarchie à 3 niveaux (héros / carte / rangée), état pressé tactile |
| Boutons `.btn` | **AMÉLIORER** | État pressé (scale 0.98 + 120 ms), variantes pleine/secondaire/discrète |
| Feuilles (19 sheets) | **AMÉLIORER** | Poignée, entrée 200 ms, garde-fou saisie conservé |
| Anneau budget | **DÉPLACER (généraliser)** | Composant `ring()` réutilisable : budget, objectifs, réserve d'impôts |
| Barres de progression `.track/.fill` | **CONSERVER** | Déjà tokenisées |
| Graphiques SVG (courbes patrimoine/compte, 6 mois) | **AMÉLIORER** | Dégradés de marque, résumé accessible conservé, jamais décoratif |
| Toast + undo | **CONSERVER** | Fonctionnel, sobre |
| Emojis de catégories | **CONSERVER** | Accents humains (règle design) ; bibliothèque courte |
| Micro-animations | **AMÉLIORER** | Compteur héros existant + transitions d'écran discrètes ; `prefers-reduced-motion` partout |
| Textes/libellés | **AMÉLIORER** | Passe finale « 10 ans » sur les nouveaux écrans ; jamais vide ni infantile |

## 3. Architecture cible (rappel exécutable)

Chaque écran = 1 question → 1 héros → 1 action → 2-3 secondaires → détail replié.
Navigation : 5 onglets + sous-vues « Plus » (History API complète, livrée).
Mouvement : 150-250 ms, easing standard, jamais bloquant, réduit si demandé.
Couleur : sens avant décor — vert=favorable, rouge=défavorable/alerte, ambre=attention,
indigo/electric=action/info ; accents (turquoise/corail/violet) réservés aux
illustrations et célébrations, jamais aux montants.

## 4. Ordre d'exécution

R1 design system vivant → R2 accueil → R3 budget/mouvements → R4 comptes/patrimoine →
R5 plus/objectifs/impôts → R6 onboarding → R7 PWA technique → R8 tokens natifs →
R9 écrans natifs. Discipline par lot : suites vertes, captures 390/320 clair/sombre,
artifact republié, commit CI, docs. Aucun retrait sans parité prouvée.
