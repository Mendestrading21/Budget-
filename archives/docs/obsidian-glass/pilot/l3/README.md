# Pilote PWA Obsidian Glass — preuves L3

Captures de la VRAIE PWA rendue (`webapp/index.html`, Chromium headless,
`deviceScaleFactor: 2`, viewport mobile — jamais fabriquées). Données de
démonstration `seedState("CH")` (bannière « données fictives » visible),
sauf mention contraire. Date : 23.07.2026. Commit observé : le commit
`feat(l3)` référencé dans `OBSIDIAN_GLASS_STATUS.md` (branche
`refonte/budget-obsidian-glass-v1`).

## Captures

| Fichier | Écran | État | Viewport | Accessibilité |
|---|---|---|---|---|
| `l3-390-mois-normal.png` | Mois | démo, mois courant | 390×844 | — |
| `l3-320-mois-normal.png` | Mois | démo | 320×844 | — |
| `l3-390-mois-empty.png` | Mois | nouvel utilisateur « Léa », aucun mouvement (vide guidé) | 390×844 | — |
| `l3-390-budget-normal.png` | Budget | démo, dans le plan/à surveiller | 390×844 | — |
| `l3-320-budget-normal.png` | Budget | démo | 320×844 | — |
| `l3-390-budget-over.png` | Budget | dépassement réel injecté (dépense > planifié) : pill « Dépassé », 156 % du budget utilisé | 390×844 | — |
| `l3-390-add-movement.png` | Ajouter un mouvement | feuille neuve, chips de type, détails repliés | 390×844 | — |
| `l3-320-add-movement-keyboard.png` | Ajouter un mouvement | montant focalisé, hauteur 480 = clavier ouvert simulé (headless sans clavier réel) — montant ET Enregistrer visibles (barre sticky) | 320×480 | — |
| `l3-390-validation-error.png` | Ajouter un mouvement | montant « abc » soumis : erreur SOUS le champ, `aria-invalid`, saisie conservée | 390×844 | — |
| `l3-390-reduced-transparency.png` | Mois | démo | 390×844 | `data-reduced-transparency="true"` → surfaces graphite opaques, halo et blurs retirés |
| `l3-320-large-text.png` | Mois | démo | 320×844 | `data-large-text="true"` (130 %) — aucun débordement |

## Méthode de génération

Script Playwright (`playwright-core` + Chromium local), zéro erreur console
tolérée (le script échoue sinon). États réels : la démo est chargée par
`seedState("CH")` persisté puis rechargé ; le dépassement Budget est une
vraie dépense ajoutée par `addTx()` ; l'erreur de validation est une vraie
soumission. Reproductible : Tests 44-48 de `webapp/tests/e2e.test.mjs`
vérifient les mêmes états automatiquement.

## Comparaison avec la baseline L1 (`docs/obsidian-glass/baseline/l1/`)

- Carte « Priorité » : tronquée en L1 (« …quelques va… ») → texte complet
  multi-ligne, carte dédiée à bord indigo.
- FAB sur le chip « Investir » à 320 px (L1) → zone de sécurité de
  défilement (96 px) : plus aucun chevauchement en bas de page (Test 45).
- Premier viewport L1 dense (bandeau + héros + priorité + 4 chips +
  4 métriques hétérogènes) → ordre du contrat : salutation courte, héros
  « Argent disponible » dominant avec action universelle intégrée,
  4 métriques du vocabulaire produit (Entré, Dépensé, À payer, Mis de
  côté), UNE priorité, actions rapides, aperçu Budget.
- Deux thèmes (L1 clair par défaut) → identité Obsidian unique (L2).
- Anneau Budget « 92 % » ambigu (L1) → « X % du budget utilisé » écrit en
  toutes lettres + pill d'état (Dans le plan / À surveiller / Dépassé) +
  « utilisé » dans l'anneau ; aria « Budget consommé » conservée.
- Feuille mouvement L1 : intitulé requis en premier, type en select,
  erreur en bas de feuille → chips de type tactiles, montant d'abord
  (focus + clavier numérique), statut expliqué, intitulé facultatif
  replié, erreur près du champ, Enregistrer sticky.

## Référence visuelle utilisée

- `visual/01_canonical_budget_identity.png` — hiérarchie héros/cartes,
  crédibilité financière.
- `visual/04_graph_focused_budget_iteration.png` — composition de la carte
  Budget (anneau + montants).
- `budget-horizon/…/07-high-contrast-dark-widgets.png` — dominance du
  montant héros et de l'action principale.

## Choix volontairement refusés

- Graphique dominant avant l'action (interdit par la matrice) — la courbe
  6 mois reste sous le premier viewport.
- Carrousel de métriques — grille 2×2 stable, lisible à 320 px.
- Suppression des actions rapides — conservées (fonctionnalité + Test 26),
  déplacées sous la priorité.
- Statut porté par la couleur seule — pills et badges TOUJOURS textuels.
- Sélecteur manuel Prévu/Comptabilisé — le statut reste dérivé de la date
  (logique financière inchangée), désormais expliqué en clair.
- Copie d'une application de référence, néon, seconde palette.
