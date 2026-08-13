# Mouvements et Comptes Obsidian Glass — preuves L5 (PWA)

Captures de la VRAIE PWA rendue (`webapp/index.html`, Chromium headless,
`deviceScaleFactor: 2`) — jamais fabriquées. Données de démonstration
`seedState("CH")` (bannière « données fictives » visible). Date :
23.07.2026. Commit observé : le commit `feat(l5)` référencé dans
`OBSIDIAN_GLASS_STATUS.md` (branche `refonte/budget-obsidian-glass-v1`).

## Captures

| Fichier | Écran | État | Viewport | Accessibilité |
|---|---|---|---|---|
| `l5-390-mouvements-normal.png` | Mouvements | démo, groupes par jour, « Prévu », signes +/− | 390×844 | — |
| `l5-390-mouvements-filtre-actif.png` | Mouvements | chip « Épargne » active (`aria-pressed`), « mis de côté » écrit | 390×844 | — |
| `l5-390-mouvements-sans-resultat.png` | Mouvements | recherche infructueuse, filtre CONSERVÉ, état guidé | 390×844 | — |
| `l5-390-mouvements-vide.png` | Mouvements | mois sans mouvement, état vide guidé + action | 390×844 | — |
| `l5-390-mouvement-detail.png` | Détail/édition | feuille du mouvement (type, montant, statut, comptes) | 390×844 | — |
| `l5-390-mouvement-erreur.png` | Détail/édition | montant « abc » : erreur SOUS le champ, saisie conservée | 390×844 | — |
| `l5-390-comptes.png` | Comptes | héros « Argent disponible », fraîcheur, compte EUR signalé | 390×844 | — |
| `l5-390-compte-detail.png` | Détail compte | solde daté en langage simple, courbe 12 mois, « Mettre le solde à jour… », historique | 390×844 | — |
| `l5-390-reconciliation.png` | Réconciliation | feuille en langage simple (relevé bancaire, historique jamais réécrit) | 390×844 | — |
| `l5-320-mouvements.png` | Mouvements | largeur étroite, zéro débordement | 320×844 | — |
| `l5-320-comptes-texte-agrandi.png` | Comptes | texte agrandi 130 % | 320×844 | `data-large-text` |
| `l5-390-mouvements-transparence-reduite.png` | Mouvements | surfaces graphite opaques | 390×844 | `data-reduced-transparency` |

## Méthode

Script Playwright (`playwright-core` + Chromium local), zéro erreur console
tolérée. États réels : démo persistée puis rechargée, filtre cliqué,
recherche saisie, erreur réellement soumise, réconciliation ouverte depuis
le bouton direct du détail. Reproductible : Tests 49-51 de
`webapp/tests/e2e.test.mjs`.

## Comparaison avec le rendu précédent

- Filtres : boutons gradient indigo→violet sans état accessible → chips
  44 px `aria-pressed` à teinte de marque unique.
- Liste plate triée par date → regroupement par JOUR avec en-têtes datés
  (même lecture que la liste native).
- Neutralité d'un virement : implicite (couleur/absence de signe) →
  ÉCRITE « · neutre » (et « · mis de côté » pour épargne/investissement),
  placée AVANT la destination pour survivre à l'ellipse.
- États vide/sans-résultat : cartes brutes → `.empty-state` L2 guidés.
- Détail compte : réconciliation cachée dans la feuille d'édition →
  bouton PRIMAIRE « Mettre le solde à jour… » + fraîcheur du solde datée
  en langage simple dans le héros.
- Recherche : styles inline → champ 44 px aux tokens.

## Preuve native (iOS)

Le workflow Demo (tour asserté) capture `02-mouvements`, `04-comptes` et
la NOUVELLE étape `13-compte-detail` — artefact `budget-demo` du run
référencé dans `OBSIDIAN_GLASS_STATUS.md`. L'état « compte archivé »
n'existe que côté natif (la PWA n'a pas d'archivage) : il est couvert par
les tests natifs (`testArchivingPreservesMovementsAndBalance`) et les
pills « Archivé » — documenté ici plutôt que capturé en PWA.

## Choix volontairement refusés

- Swipe actions natives SANS équivalents visibles — remplacées par des
  boutons « Dupliquer »/« Supprimer » dans la feuille d'édition (les
  swipes hors `List` seraient des gestes morts).
- Suppression en un geste : toujours une confirmation, l'undo web reste.
- Faux statut de synchronisation bancaire : aucun — les soldes sont datés
  par les mouvements réels ou la réconciliation manuelle.
- Addition multi-devises : jamais — conversion explicite existante côté
  PWA, natif V1 mono-devise CHF (ADR-017).
