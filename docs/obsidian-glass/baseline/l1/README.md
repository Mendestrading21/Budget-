# Baseline L1 — captures AVANT Obsidian Glass

Ces captures documentent l'état réel de la PWA **avant** toute refonte
Obsidian Glass (rendu Horizon actuel, non embelli). Elles servent de point
de comparaison pour les lots L2+.

- **Commit observé** : `2c5214d7afb9fd74df8122ede8a4a6e799d94954`
  (branche `refonte/budget-obsidian-glass-v1`, lot L1)
- **Date de génération** : 23.07.2026
- **Méthode** : Chromium headless (playwright-core, exécutable
  `/opt/pw-browsers/chromium-1194`), `file://webapp/index.html`, état de
  démonstration injecté via `seedState("CH")` dans `localStorage`
  (`budget-app-state-v1`), attente du rendu (`#tabbar button` + 400 ms),
  `page.screenshot({ fullPage: true })` sauf la feuille (viewport).
  Mesures relevées à la génération : rendu ~180 ms (390 px) / ~137 ms
  (320 px), zéro erreur console, aucun débordement horizontal.

| Fichier | Écran | Largeur | Thème |
|---|---|---:|---|
| `l1-390-mois.png` | Mois / Accueil | 390 px | clair (défaut Horizon) |
| `l1-390-budget.png` | Budget | 390 px | clair |
| `l1-390-txform.png` | Feuille « Ajouter un mouvement » | 390 px | clair |
| `l1-390-mois-sombre.png` | Mois / Accueil | 390 px | sombre |
| `l1-320-mois.png` | Mois / Accueil | 320 px | clair |
| `l1-320-budget.png` | Budget | 320 px | clair |

Constats baseline (à traiter dans les lots visuels, pas en L1) : carte
« Priorité » tronquée aux deux largeurs ; à 320 px le bouton « + »
recouvre partiellement le chip « Investir » ; anneau Budget sans résumé
textuel ; deux thèmes coexistent alors qu'Obsidian Glass vise une seule
identité sombre.
