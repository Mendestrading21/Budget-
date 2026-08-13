---
name: budget-web
description: Piloter l'app web Budget (artifact plein écran) jusqu'au niveau d'une app de suivi de dépenses/budget de 2026 — audit, phases W1-W4, zéro bouton mort, vérification systématique. Utiliser pour toute évolution de webapp/index.html ou de l'artifact Budget.
---

# Budget Web — skill de construction et d'audit

L'app web Budget est la déclinaison navigateur de l'app iOS native
(`Budget/`, skill `/budget-v1`). Source de vérité : `webapp/index.html`
dans ce repo (copie de travail possible dans le scratchpad de session).
Publication : TOUJOURS le même artifact
`https://claude.ai/code/artifact/f14dbf92-6e71-41ed-bdaa-89e8e54b8a52`
(favicon 💰).

## Contrat (hérite du contrat /budget-v1)

1. **Mêmes règles financières que le Swift** : montants formatés fr-CH
   (`CHF 1'234.50`), planifié ≠ réel, virements internes neutres
   (ni revenu, ni dépense, ni patrimoine), épargne/investissements ≠
   coût de la vie, estimé d'impôts = payé + encore dû, jamais de NaN,
   remboursements réduisent leur catégorie.
2. **Zéro bouton mort** : tout élément qui ressemble à une action agit,
   ou n'existe pas. Si une capacité n'existe que dans l'app native,
   l'étiqueter explicitement « app native » — jamais un bouton factice.
3. **Local d'abord** : tout l'état vit dans `localStorage` de l'appareil
   de l'utilisateur ; aucune requête réseau, aucun CDN (CSP artifact),
   aucun tracker. Export/sauvegarde par téléchargement local uniquement.
4. **Un seul fichier autonome** (HTML+CSS+JS inline), mobile d'abord
   (100dvh, safe-areas), thème sombre canonique de l'identité Budget.
5. **Chaque phase se termine vérifiée** : test headless Node (tous les
   écrans rendent, les totaux se réconcilient, les reducers mutent et
   persistent), puis republication sur le MÊME artifact, puis commit
   dans le repo (`webapp/index.html` à jour).

## Roadmap

- **W1 — Fondation d'état** : store unique versionné persisté en
  localStorage (comptes, catégories, mouvements, budgets, récurrents,
  objectifs, patrimoine, impôts, réglages), graine démo au premier
  lancement ; mouvements modifiables et supprimables (tap sur la ligne
  → feuille d'édition avec suppression) ; export CSV réel
  (téléchargement Blob), sauvegarde JSON réelle versionnée,
  restauration validée (refus propre des fichiers invalides),
  suppression totale à double confirmation, réinitialisation démo.
- **W2 — Comptes et budget éditables** : CRUD comptes (groupes par type
  dynamiques, suppression refusée si des mouvements y pointent — règle
  .deny du natif), lignes budgétaires : modifier le planifié, ajouter
  une ligne, copier le budget vers un mois vide.
- **W3 — Objectifs, récurrents, patrimoine** : CRUD complet des trois ;
  « Comptabiliser » une occurrence récurrente (création du mouvement
  lié, disparition de la prévision sans doublon) ; objectif « atteint ».
- **W4 — Import CSV réel + finitions** : import d'un fichier/collage
  CSV (détection délimiteur, dates/montants suisses, doublons par
  empreinte, rapport importées/doublons/invalides, annulation de lot) ;
  taux et réserve d'impôts éditables ; verrouillage par code (simulé,
  honnête sur ses limites) ; états vides élégants partout ; passe a11y.

## Boucle de vérification (obligatoire à chaque phase)

1. `node --check` sur le script extrait.
2. Test headless : DOM factice + localStorage factice ; exécuter chaque
   renderer, vérifier « Vraiment disponible » = sa décomposition au
   centime, mutations (ajout/édition/suppression) suivies de
   re-rendu sans exception, persistance (save → reload state).
3. Republication artifact (même URL), mise à jour de
   `webapp/index.html`, commit + push sur la branche de travail.
4. PROJECT_STATUS.md : section « App web » tenue à jour.

## Audits

Pour « audit » : agent indépendant sur le fichier complet — boutons
morts, écarts de règles financières vs Swift, UX mobile (cibles
tactiles, claviers inputmode, safe-areas), a11y (labels, focus,
contrastes), robustesse (localStorage plein/indisponible, JSON
corrompu), qualité JS. Rapport priorisé BLOCKER/WARNING/NIT ; les
BLOCKER se corrigent avant toute nouvelle fonctionnalité.
