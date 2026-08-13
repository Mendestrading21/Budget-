# Finance et données

## Argent

- Natif : `Decimal` de bout en bout, arrondi explicite selon la règle métier.
- Web : représentation décimale sûre en unités mineures ou stratégie testée ;
  jamais d'égalité flottante naïve pour une réconciliation.
- Affichage `fr-CH`, CHF et dates suisses ; stockage indépendant du formatage.

## Flux

- Revenu/dépense : change le cash-flow du foyer.
- Virement interne : débit source + crédit destination, impact foyer nul.
- Épargne/investissement : transfert vers un compte détenu, pas coût de vie.
- Dette : solde signé et convention unique ; remboursement du capital neutre sur
  la fortune, intérêts/frais en dépense.
- Récurrent : prévision et transaction comptabilisée liées par identifiant stable
  pour empêcher les doublons.

## Agrégats

- Disponible réel = formule centrale unique et décomposable.
- Budget = planifié distinct du comptabilisé ; hors budget inclus dans la
  réconciliation.
- Patrimoine = actifs et comptes inclus + prévoyance incluse - dettes, sans
  double comptage.
- Impôts = estimation, payé, réserve, arriérés et dû issus d'un service unique,
  filtrés par année et statut.
- Projections = hypothèses configurables, calcul déterministe, méthode affichée,
  résultat jamais garanti.

## Persistance

- Identifiants stables et relations explicites.
- Mutations atomiques ou compensées ; aucune erreur de sauvegarde ignorée.
- Import : prévisualisation, validation, doublons, rapport et rollback du lot.
- Export : schéma versionné, montants non ambigus, aucune donnée omise.
- Restauration : valider entièrement avant mutation, refuser version future,
  rollback complet en cas d'échec.
- Migration : tester avec un store disque de version précédente.

## Confidentialité

- Local d'abord, collecte nulle tant que l'architecture le permet.
- Aucun secret ou montant personnel dans logs, analytics, fixtures ou captures.
- La PWA décrit honnêtement `localStorage` et ses limites ; ne pas prétendre à un
  chiffrement ou Face ID inexistants.
- Toute future synchronisation, banque connectée, analytics ou cloud exige une
  décision produit, sécurité et confidentialité explicite.

## Tests minimaux pour toute règle modifiée

Cas nominal, zéro, négatif si autorisé, très grand montant, arrondi, date limite,
répétition, doublon, suppression/archivage, échec de persistance et round-trip.
Ajouter un test de non-régression reproduisant précisément le défaut corrigé.

