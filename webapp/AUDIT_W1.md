# Audit app web — synthèse et suivi (skill /budget-web)

Audit indépendant du 20.07.2026 sur la version plein écran. Résultat :
5 BLOCKER, 15 WARNING, 11 NIT. Détail des constats majeurs et statut.

## Corrigé en W1 (cette version)

- **B1 XSS stocké** : tout texte utilisateur passe par `esc()` avant innerHTML.
- **B2 Épargne détruisait de la fortune** : épargne → crédite le compte
  Épargne, investissement → Pilier 3a, virement → Espèces (`DEST_BY_TYPE`).
- **B3 Impôts codés en dur** : payé = somme réelle des « Paiement
  d'impôts » comptabilisés ; estimation = revenu mensuel moyen observé
  annualisé × taux ; réserve dans l'état (`S.taxReserve`).
- **B4 Stockage non validé** : `loadState()` valide la structure,
  rejette le JSON corrompu ; toast si stockage indisponible (W6).
- **B5.1 Mouvements** : tap sur une ligne → modifier/supprimer, champ
  date, statut prévu/comptabilisé recalculé.
- **B5.8/5.9 Réglages** : export CSV réel, sauvegarde JSON réelle,
  restauration validée (refus propre), suppression totale à double
  confirmation, réinitialisation démo confirmée (W8).
- **B5.11** : types remboursement / investissement / virement au
  formulaire ; salaire intégré aux récurrents avec déduplication.
- **W2 grille annuelle** : consommation calculée mois par mois.
- **W4** : jours restants sur la vraie longueur du mois.
- **W9/W11/W12/W14/W15** : aria-live retiré de l'écran (région dédiée au
  toast), `role="alert"` sur l'erreur de formulaire, cibles 44 px,
  viewport complet, toasts de confirmation, FAB au-dessus de la
  safe-area, Échap ferme la feuille, retour en haut à la navigation.

## Backlog W2 (prochain « Go »)

- CRUD comptes (groupes dynamiques, suppression refusée si mouvements — règle .deny)
- Lignes budgétaires éditables + ajout + copie de mois (B5.3)
- W5 : montants en centimes entiers
- W7 : History API (bouton retour naturel)
- W10 : rendu ciblé (focus/scroll préservés)

## Backlog W3

- CRUD objectifs + contributions liées aux virements d'épargne (W13, B5.4)
- CRUD récurrents + « comptabiliser » une occurrence (B5.12)
- CRUD actifs/dettes/prévoyance/assurances (B5.6)
- Courbe de patrimoine dérivée des soldes réels (W3)

## Backlog W4

- Import CSV réel : fichier, délimiteur, doublons par empreinte,
  rapport, rollback (B5.7)
- Taux/réserve d'impôts éditables, provision sur revenus attendus (W1)
- Verrouillage par code + WebAuthn si disponible (B5.10)
- NIT restants : progressbars aria, focus-trap de la feuille, libellés.
