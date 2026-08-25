# Screen Contracts

## Structure globale

Cinq onglets cibles : `Mois`, `Activité`, `Plan`, `Comptes`, `Plus`.

Chaque page possède :

- une question principale ;
- un chiffre/action focal maximum ;
- source/période/devise ;
- états vide, partiel, normal, erreur et extrême ;
- résultat de mutation ;
- accessibilité et retour ;
- aucun calcul financier local dupliqué.

## Mois

**Question :** où j'en suis et que reste-t-il à faire ?

Sections : mois, réel maintenant, projection séparée, reçu/dépensé/mis de côté,
inbox, budget, résumé. Futur non actionnable sauf planification ; passé utilise
les écritures historiques.

Actions : Ajouter, Reçu, Payé, Rapprocher, Reporter, Ignorer. Toute confirmation
ouvre un résumé prérempli et propose Annuler après succès.

## Activité

**Question :** qu'est-ce qui s'est réellement passé ?

États/filters : pending, comptabilisé, pointé, rapproché, prévu séparé, à
vérifier, compte, catégorie, tag, source, date.

Détail : postings simplifiés, splits, occurrence/source, historique des
corrections. Un mouvement rapproché ne propose pas `Modifier/Supprimer`, mais
`Corriger`.

## Plan

**Question :** qu'est-ce qui est prévu et mon plan tient-il ?

Sous-vues : budget, calendrier, ce qui revient, abonnements filtrés, factures
ponctuelles, objectifs et règles. Une occurrence n'est jamais une transaction
réelle.

## Comptes

**Question :** où est mon argent et pourquoi ce solde ?

Liste : regroupement, solde, devise, fraîcheur, inclusion disponible/patrimoine.
Fiche : solde, flux du mois, journal, relevés, rapprochement, positions
explicatives, modification/archive. Patrimoine est une vue agrégée datée.

## Plus

**Question :** comment configurer et protéger l'app ?

Foyer, catégories/tags/règles, modules régionaux, documents, import/export,
backup, sécurité, langue/devise/apparence, aide. Aucun doublon vers la même liste
sous deux noms sans filtre clair.

## Feuille Ajouter

Intentions simples : `J'ai dépensé`, `J'ai reçu`, `J'ai mis de côté`,
`Transfert`. Options avancées : dette, remboursement, ajustement.

Ordre : montant, catégorie/destination, compte, date/statut explicite, détails.
`Autre` disponible ; tag `Imprévu` séparé ; split possible ; intitulé par défaut
mais jamais donnée vide silencieuse.

## Inbox financière

Priorités :

1. erreur/persistance ;
2. transaction à rapprocher ;
3. échéance en retard ;
4. due à confirmer ;
5. match proposé ;
6. à catégoriser ;
7. renouvellement/résiliation ;
8. compte à rapprocher.

Chaque carte dit pourquoi elle existe et ce que fera l'action. Reporter/ignorer
ne crée aucun mouvement.

## Erreurs et succès

- erreur près de l'action ;
- aucune donnée sensible dans le message ;
- succès seulement après commit ;
- action annulable quand possible ;
- répétition sûre ;
- lecteur d'écran annoncé ;
- focus dirigé vers erreur/résultat.

## Accessibilité

- 44 pt/px minimum ;
- Dynamic Type/zoom sans troncature de montants ;
- montant lisible dans un texte alternatif ;
- graphique avec résumé/tabulation ;
- couleur + icône/texte ;
- clavier et lecteur ;
- Reduce Motion/Transparency ;
- thème système ;
- swipe jamais unique.

## Règle de suppression

Avant de supprimer page/bouton/donnée : prouver absence de route, appel, test,
document, migration, deep link et référence utilisateur. Archiver/migrer les
données avant suppression. Une fonction avancée peut être déplacée, pas cachée
sans chemin de remplacement.
