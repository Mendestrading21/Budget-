# Widgets, interactions et mouvement

## Table des matières

1. Principes
2. Système de widgets
3. Graphiques
4. Mouvement
5. Haptique et son
6. Performance et accessibilité

## Principes

Créer une interface vivante, jamais un empilement de cartes statiques. Chaque
mouvement doit expliquer un changement, confirmer une action ou faciliter
l'orientation. Hiérarchie avant animation ; compréhension avant spectacle.

Chaque écran contient :

- un point focal animé principal ;
- quelques réactions tactiles cohérentes ;
- une transition de navigation naturelle ;
- aucun mouvement permanent parasite.

## Système de widgets

### Catalogue

- disponible réel ;
- résultat et prévision de fin de mois ;
- budget restant ;
- dépenses par catégorie ;
- factures à venir ;
- objectif prioritaire ;
- épargne et patrimoine net ;
- calendrier financier ;
- abonnements ;
- activité récente ;
- comptes et provisions fiscales ;
- recommandation du moment.

### Contrat

Chaque widget définit :

- question à laquelle il répond ;
- donnée source et fraîcheur ;
- état compact, standard et développé si utile ;
- action primaire et destination de détail ;
- vide, chargement, erreur et contenu volumineux ;
- texte accessible équivalent au graphique ;
- comportement clair/sombre/reduced motion.

Un widget compact porte une information. Un widget standard ajoute contexte ou
mini-graphique. Un widget développé offre exploration et action, pas uniquement
plus de décoration.

### Personnalisation

Fournir une disposition recommandée immédiatement utile. Autoriser ensuite :

- afficher/masquer les widgets secondaires ;
- réordonner par glisser-déposer avec alternative accessible ;
- développer/réduire ;
- filtrer période ou compte ;
- restaurer la disposition recommandée ;
- persister choix et ordre.

Ne pas afficher plus de huit modules sur l'accueil sans regroupement ou
personnalisation. Les alertes critiques peuvent remonter temporairement.

## Graphiques

Un graphique doit répondre à une question et conduire à une compréhension.
Fournir titre, période, unité, résumé textuel et état sans données.

Interactions utiles :

- toucher/glisser pour date et valeur ;
- filtres semaine, mois, année ;
- comparaison précédente ;
- point ou catégorie sélectionné ;
- accès aux mouvements liés ;
- annotation d'une anomalie ou échéance ;
- transition animée entre périodes ;
- haptique discret lors du changement de point sur iOS.

Limiter séries et couleurs. Éviter 3D, jauges trompeuses, axes dramatisés,
camemberts surchargés et animations qui rejouent à chaque apparition.

## Mouvement

### Durées indicatives

| Usage | Durée |
|---|---:|
| Pression/réaction tactile | 100–160 ms |
| Micro-transition | 180–260 ms |
| Développement/navigation | 280–420 ms |
| Célébration exceptionnelle | 500–800 ms |

Utiliser des courbes naturelles, interrompables et cohérentes. Adapter plutôt
que copier mécaniquement ces valeurs lorsque la plateforme fournit un mouvement
natif plus juste.

### Bibliothèque

- apparition légèrement décalée des cartes au premier chargement seulement ;
- compteur animé uniquement quand la valeur change réellement ;
- tracé progressif d'une courbe lors d'un changement de période ;
- barre de progression fluide ;
- morphing résumé/détail si techniquement fiable ;
- skeleton court pour une vraie attente ;
- confirmation visuelle lors d'ajout, paiement ou transfert ;
- célébration discrète à un jalon d'objectif ;
- transition directionnelle entre mois.

Ne jamais retarder une action pour terminer une animation.

## Haptique et son

Utiliser les haptiques iOS avec parcimonie :

- sélection légère pour filtres et points de graphique ;
- succès pour action financière enregistrée ;
- avertissement avant action risquée ;
- erreur seulement lorsqu'une action échoue.

Aucun son automatique. Ne jamais utiliser uniquement l'haptique pour transmettre
une information.

## Performance et accessibilité

- viser 60 FPS et mesurer les écrans riches ;
- éviter effets glass coûteux sur listes longues ;
- charger progressivement les graphiques ;
- réduire les recalculs et observer seulement les données nécessaires ;
- respecter Réduire les animations et Réduire la transparence ;
- remplacer morphing/parallaxe par fondu court ou changement instantané ;
- rendre le réordonnancement accessible sans glisser-déposer ;
- ne jamais dépendre uniquement de couleur, mouvement ou haptique ;
- tester avec gros montants, longues catégories et grand texte.
