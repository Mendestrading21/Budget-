# Budget 1.0 — checklist QA manuelle

Cette checklist valide l’artefact réellement distribué, pas seulement le
code source. Elle doit être exécutée avec des données fictives sur un
iPhone réel; les contrôles PWA sont réalisés séparément.

## Enregistrement

| Champ | Valeur |
|---|---|
| SHA Git complet | |
| Run CI `push` | |
| Build TestFlight | |
| Appareil | |
| Version iOS | |
| Testeur | |
| Date | |
| Résultat final | GO / NO-GO |

Tout écart financier, perte de données, défaut de confidentialité ou
différence de SHA produit un **NO-GO** immédiat.

## Préconditions

- [ ] Le SHA correspond exactement à la tête de `main`.
- [ ] La CI `push` est verte sur ce SHA.
- [ ] Le build TestFlight a été produit par `testflight.yml` avec ce SHA.
- [ ] Les tests utilisent uniquement des personnes et montants fictifs.
- [ ] Une sauvegarde de toute donnée utile préexistante a été faite.

## Installation et mise à jour

### Installation neuve

- [ ] Installer depuis TestFlight puis vérifier le numéro de version/build.
- [ ] L’onboarding présente honnêtement le stockage local et la
  confidentialité.
- [ ] Le parcours ménage → canton → premier compte aboutit à `Mois` sans
  demander un taux fiscal supprimé.
- [ ] Fermer puis relancer : l’onboarding ne revient pas et les données
  saisies sont conservées.
- [ ] Le mode démo, s’il est proposé, reste clairement identifié et ne
  modifie aucune donnée réelle.

### Mise à jour

- [ ] Installer par-dessus la dernière build utilisée.
- [ ] Comptes, opérations, catégories, récurrences, budgets, objectifs,
  dettes, impôts, prévoyance et documents restent présents.
- [ ] Aucun doublon n’est créé par la migration.
- [ ] Les anciens identifiants et liaisons restent fonctionnels.

## Navigation et compréhension

- [ ] Les cinq destinations sont exactement :
  `Mois · Historique · Budget · Comptes · Gérer`.
- [ ] Aucun bouton d’ajout flottant global n’apparaît.
- [ ] `Mois` expose l’action principale d’ajout d’opération.
- [ ] Chaque autre écran ne propose que ses actions contextuelles.
- [ ] Un utilisateur peut expliquer en quelques secondes la différence
  entre « Maintenant » et « Fin du mois ».
- [ ] Aucun terme interne de développeur, code de type ou libellé obsolète
  n’est visible.

## Vérité mensuelle

Préparer un compte courant à **CHF 5’000.00** et noter chaque valeur avant
et après les actions.

- [ ] Un salaire **réel** augmente « Maintenant » et « Fin du mois ».
- [ ] Un salaire **planifié** augmente uniquement la projection.
- [ ] Une dépense **réelle** diminue l’argent disponible maintenant.
- [ ] Une dépense **planifiée** diminue uniquement la projection.
- [ ] Comptabiliser un élément planifié le déplace vers le réel sans le
  compter deux fois.
- [ ] Une récurrence à venir n’est jamais présentée comme déjà payée/reçue.
- [ ] Changer de date ne transforme pas silencieusement un planifié en réel.
- [ ] Les quatre familles gardent le même ordre et les mêmes totaux :
  Rentrées, Dépenses, Abonnements, Mis de côté.
- [ ] La somme des lignes visibles se réconcilie avec les cartes de total.
- [ ] Les montants négatifs, zéros et grands nombres restent lisibles.

## Opérations et historique

- [ ] Ajouter, modifier puis supprimer une entrée.
- [ ] Ajouter, modifier puis supprimer une dépense.
- [ ] Ajouter un abonnement et vérifier son coût mensuel/annuel.
- [ ] Ajouter une mise de côté vers un compte de destination.
- [ ] Ajouter un virement interne : soldes source/destination changent,
  revenus, dépenses et fortune nette restent neutres.
- [ ] Rechercher dans `Historique`.
- [ ] Tester les filtres, le changement de mois et les états vides.
- [ ] Une opération modifiée conserve une chronologie et un type cohérents.
- [ ] Les catégories personnalisées s’affichent avec le bon type et peuvent
  être réutilisées sans doublon.

## Budget

- [ ] Créer un budget mensuel et plusieurs lignes.
- [ ] Vérifier consommé, restant, dépassement et hors-budget.
- [ ] Modifier une opération source met à jour le budget une seule fois.
- [ ] Copier vers le mois suivant ne copie pas les dépenses réelles.
- [ ] La vue annuelle additionne les mois effectivement sélectionnés.
- [ ] Une mise de côté n’est pas classée comme dépense de vie.

## Comptes, épargne et patrimoine

- [ ] Créer un compte courant, un compte épargne et un compte investissement.
- [ ] Les vues « argent immédiat » excluent les montants non disponibles
  selon les règles produit.
- [ ] La fortune totale inclut exactement les comptes/actifs choisis.
- [ ] Ajouter un actif et une dette puis tester les options d’inclusion.
- [ ] Une position de prévoyance liée à un compte n’est pas comptée deux fois.
- [ ] Un remboursement de carte à solde négatif baisse le cash, rapproche
  la dette de zéro et ne change pas la fortune nette.
- [ ] Un trop-payé de dette laisse un solde positif visible et explicable.

## Dettes et remboursements

- [ ] Créer un compte de carte/prêt avec un solde négatif et une dette
  autonome dans le patrimoine; vérifier qu’ils ne sont pas comptés deux
  fois.
- [ ] Un remboursement partiel débite le compte source et rapproche le
  compte de dette de zéro du même montant.
- [ ] Le remboursement de capital ne modifie pas la fortune nette et ne
  gonfle pas le coût de la vie.
- [ ] Un trop-payé laisse un solde positif visible, sans être masqué.
- [ ] Une dette autonome sans compte lié reste modifiable manuellement et
  sa mensualité n’est pas déduite deux fois.

## Impôts, prévoyance et objectifs

- [ ] Ajouter un paiement d’impôts : payé + encore dû = estimation selon la
  méthode affichée.
- [ ] Une réserve d’impôts est une mise de côté, pas une dépense de vie.
- [ ] Les bornes de taux refusent proprement les valeurs hors limites.
- [ ] Ajouter une position de prévoyance liée et une non liée; le total ne
  compte chaque franc qu’une fois.
- [ ] Créer un objectif avec montant et échéance.
- [ ] Les contributions font avancer le bon objectif.
- [ ] Archiver puis rouvrir un objectif sans perte.

## Import, export et sauvegarde

- [ ] Importer un CSV fictif : rapport clair et lignes rejetées motivées.
- [ ] Réimporter le même fichier : aucun doublon.
- [ ] Annuler le lot importé sans toucher au reste.
- [ ] Ouvrir l’export CSV dans Numbers ou Excel.
- [ ] Créer une sauvegarde JSON.
- [ ] Supprimer toutes les données avec la double confirmation.
- [ ] Restaurer : données et relations reviennent à l’identique.
- [ ] Restaurer sans suppression préalable : les documents locaux encore
  présents restent ouvrables.
- [ ] Un fichier non JSON est refusé sans modifier les données.
- [ ] Une sauvegarde contenant une devise non prise en charge est refusée
  avec un message exploitable et sans perte.

## Verrouillage et confidentialité

- [ ] Activer Face ID exige une authentification.
- [ ] Arrière-plan puis retour : l’app est verrouillée.
- [ ] Annuler ou échouer l’authentification laisse l’app verrouillée.
- [ ] Désactiver le verrouillage exige aussi une authentification.
- [ ] Le sélecteur d’apps ne montre aucun montant.
- [ ] Revenir d’une simple interruption retire correctement le voile.
- [ ] Aucun montant ou nom fictif complet n’apparaît dans les logs Xcode.
- [ ] La suppression totale renvoie à l’onboarding sans trace visible.
- [ ] Les textes Confidentialité/Méthodologie décrivent le comportement
  réellement observé.

## Accessibilité et rendu

- [ ] VoiceOver lit le sens des cartes, montants, graphiques et formulaires.
- [ ] Dynamic Type au maximum ne tronque aucune information critique.
- [ ] Toutes les cibles utiles atteignent 44 points.
- [ ] Réduire les animations supprime les mouvements non essentiels.
- [ ] Réduire la transparence remplace le flou par une surface opaque lisible.
- [ ] Augmenter le contraste conserve la hiérarchie.
- [ ] Aucun statut n’est transmis par la couleur seule.
- [ ] L’identité sombre reste cohérente sur chaque écran.
- [ ] Aucun montant n’a de glow, n’est coupé ou ne passe sur deux lignes.
- [ ] Petit iPhone et grand iPhone : feuilles, clavier et scroll restent
  utilisables.
- [ ] Les états vides expliquent l’action suivante.

## Performance et robustesse

- [ ] Lancement à froid sans blocage visible.
- [ ] Navigation entre mois et onglets fluide.
- [ ] Historique volumineux défile sans sauts majeurs.
- [ ] Passage hors ligne ne provoque ni crash ni perte.
- [ ] Interruption pendant un formulaire ne crée pas d’opération partielle.
- [ ] Les erreurs affichent une action de récupération compréhensible.

## PWA

- [ ] Déploiement Pages produit depuis le même SHA que le candidat.
- [ ] Installation sur l’écran d’accueil réussie.
- [ ] Relance hors ligne réussie après une première ouverture en ligne.
- [ ] Données conservées après fermeture/réouverture.
- [ ] Navigation et distinction Maintenant/Fin du mois cohérentes avec iOS.
- [ ] Fixtures manuelles principales donnent les mêmes totaux que l’app iOS.
- [ ] Aucun message ne prétend à une connexion bancaire ou à une
  synchronisation inexistante.

## Signature

```text
Écarts ouverts :
P0 :
P1 :
P2 :
Décision : GO / NO-GO
Nom :
Date :
```
