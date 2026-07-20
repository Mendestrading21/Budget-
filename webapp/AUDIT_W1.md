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

## Corrigé en W2

- CRUD comptes : ajout/édition/suppression, groupes par nature,
  suppression refusée si des mouvements y pointent (règle .deny),
  destination d'épargne/investissement résolue dynamiquement,
  garde sur les comptes disparus (solde 0, jamais de crash)
- Budgets DANS l'état, par mois : lignes éditables (tap), ajout,
  retrait, copie vers un mois vide isolée du mois source (B5.3)
- W7 : History API — le bouton retour remonte l'app au lieu d'en sortir

## Reporté (assumé)

- W5 centimes entiers : les montants restent des flottants arrondis au
  centime à chaque mutation ; réconciliation vérifiée à 0.001 près en
  headless. À reprendre si des dérives apparaissent.
- W10 rendu ciblé : le re-rendu complet reste acceptable à cette échelle.

## Corrigé en W3

- CRUD objectifs : ajout/édition/suppression, emoji, priorité, échéance
  (champ mois), « Marquer atteint »/réactiver, et OBJECTIF LIÉ À UN
  COMPTE : la progression suit le solde réel (W13) ; contribution
  requise = (cible − atteint) ÷ mois restants, échéance passée signalée
- CRUD récurrents : ajout/édition/suppression + « Comptabiliser ce
  mois » (crée le mouvement, retire la prévision sans doublon — B5.12)
- CRUD actifs/dettes avec toggle « compter dans la fortune » (B5.6
  partiel) ; migration douce des anciennes formes stockées
- Courbe de patrimoine DÉRIVÉE des soldes réels de fin de mois (W3)
- Progressbars avec aria (N2 partiel)

## Corrigé en W4 — l'audit est soldé

- Import CSV RÉEL (B5.7) : fichier ou collage, délimiteur auto
  (; , tab), guillemets, dates suisses (31.12.2026, 31/12/2026, ISO),
  montants signés (négatif = dépense), mappage des colonnes par
  en-têtes, empreinte date+montant+intitulé → ré-import = 0 doublon,
  rapport persistant (importées/doublons/invalides avec raison et texte
  brut), « Annuler ce lot » chirurgical (le reste survit)
- Taux et réserve d'impôts éditables (feuille « Ajuster ») ; le taux
  vit dans l'état et alimente snapshot ET écran Impôts
- Verrouillage par CODE réel (B5.10) : définir (2 saisies), vérifier
  pour désactiver, écran verrouillé avec compteur d'échecs ; copie
  honnête (protège l'affichage, pas un chiffrement) ; l'ancien
  simulacre Face ID est migré proprement
- CRUD assurances (primes mois/an → équivalent mensuel) et prévoyance
  (valeur + projection du certificat) — fin de B5.6
- Documents : liste de métadonnées ajout/suppression — plus une seule
  ligne inerte dans l'app

## Assumé en l'état (documenté)

- Provision d'impôts sur revenus comptabilisés uniquement (parité avec
  l'app native — décision produit commune aux deux plateformes)
- Flottants arrondis au centime à chaque mutation (W5) ; centimes
  entiers si des dérives apparaissent
- Période de démo avril-juin 2026 (les imports hors période sont
  refusés avec une raison claire) — les mois dynamiques viendront avec
  la synchronisation des données réelles

## W5 — Expérience maximale (demande utilisateur post-W4)

- **Factures** : nouveau module complet — en retard / à payer / payées,
  CRUD, « Marquer payée » crée le mouvement lié (et « non payée » le
  retire), carte « Factures à payer » sur le dashboard (dues sous 14
  jours), les factures ouvertes du mois pèsent sur le « Vraiment
  disponible ».
- **Menu ＋ universel** : le bouton flottant est visible sur tous les
  onglets et ouvre un menu de création — mouvement, facture, compte,
  objectif, récurrent, actif/dette, assurance, prévoyance.
- **Annulation globale** : chaque geste destructeur (suppressions,
  paiement de facture, rollback d'import, suppression totale) affiche
  un toast avec « Annuler » (6 s) qui restaure l'état exact.
- **Dupliquer** un mouvement depuis sa feuille (copie datée du jour).
- **Recherche + filtres** dans Mouvements : insensible aux accents,
  puces Dépenses/Revenus/Épargne/Virements, compteur et net du mois,
  liste rafraîchie sans perdre le focus de saisie.

## W6 — Vraie plateforme (demande utilisateur post-W5)

- **Temps réel** : NOW est la vraie date du jour ; la démo s'ancre sur
  le mois courant (3 mois d'historique générés relativement) ; plus
  aucune date codée en dur.
- **Navigation libre** : le curseur de mois va où l'on veut (passé et
  futur sans bornes) avec un raccourci « aujourd'hui » ; la grille
  annuelle suit l'année affichée (cellule active si budget ou
  mouvements) ; la courbe de patrimoine couvre les 6 derniers mois
  réels ; l'écran Impôts moyenne les revenus de l'année affichée ;
  dates libres dans tous les formulaires et l'import CSV.
- **Multi-devises** : chaque compte a sa devise (CHF/EUR/USD), soldes
  et mouvements affichés dans la devise du compte (€ 1'234.50),
  totaux ménage convertis en CHF via des TAUX MANUELS éditables dans
  Réglages (aucune connexion réseau, mention explicite) ; destinations
  d'épargne/investissement exigées dans la même devise (message clair).
- **Choix du compte par mouvement** : sélecteur de compte dans la
  feuille mouvement (le mouvement porte la devise de son compte).
- **Mon salaire** : carte dédiée en tête des Réglages (montant + jour),
  branchée sur le récurrent Salaire (créé s'il manque) — prévisions et
  « Vraiment disponible » suivent immédiatement.
- Migrations : comptes sans devise → CHF, fxRates par défaut, budgets
  re-seedés sur les mois relatifs si absents, anciens mouvements 2026
  conservés et accessibles par la navigation.
