# Budget Prisme — langue et états

## Sommaire

1. Principe
2. Navigation et dashboard
3. Matrice des opérations
4. Termes simples
5. Formules de texte
6. Audit de cohérence

## 1. Principe

Écrire en français simple, concret et compréhensible par une personne de dix
ans. Préférer une phrase courte à un terme financier non expliqué. Dire ce qui
s'est passé, quand et où va l'argent.

Ne jamais améliorer un texte sans vérifier le type, le statut et la mutation
réels. Chercher le même geste dans Mois, Historique, Ce qui revient, Factures,
Année, Assistant, formulaires, erreurs, toasts et VoiceOver.

## 2. Navigation et dashboard

Conserver exactement :

`Mois · Historique · Budget · Comptes · Gérer`

| Contexte | Libellé principal |
|---|---|
| Mois courant | `Reste pour le mois` |
| Mois passé | `Résultat du mois` |
| Mois futur | `Estimation du mois` |
| Trois repères | `Reçu · Dépensé · Mis de côté` |
| Liste mensuelle | `Bilan du mois` |
| Courant à faire | `À faire` |
| Courant terminé | `Fait ce mois` |
| Futur | `Prévu ce mois` / `N prévus` |
| Régularité | `Ce qui revient` |
| Ajout régulier | `Ça revient régulièrement` |

`Dépensé` est un total du coût de la vie. `Payé` est l'état d'une ligne; ne
pas remplacer l'un par l'autre.

## 3. Matrice des opérations

| Nature | Avant | Après | Total | Ton/signe |
|---|---|---|---|---|
| revenu, salaire, remboursement | `À recevoir` | `Reçu` | Reçu | positif |
| dépense, facture, impôt | `À payer` | `Payé` | Dépensé selon règle métier | négatif |
| épargne | `À mettre de côté` | `Mis de côté` | Mis de côté | neutre, jamais rouge |
| investissement | `À investir` | `Investi` | Mis de côté | neutre |
| virement interne | `À transférer` | `Transféré` | aucun | neutre |
| remboursement de dette | `À payer` | `Payé` | principal distinct | négatif cash, fortune neutre si lié |
| ajustement | `À confirmer` | `Confirmé` | aucun revenu/dépense | neutre |

Ajouter `Prévu` à un mouvement futur. Ne jamais appeler un mouvement prévu
`Reçu`, `Payé` ou `Fait`.

## 4. Termes simples

| Préférer | Éviter ou expliquer |
|---|---|
| `Opération` | `mouvement` hors export/technique |
| `Mettre le solde à jour` | `réconcilier` seul |
| `Argent disponible` | `cash disponible` |
| `Somme mise de côté pour les impôts` | `provision` seule |
| `Sommes encore dues des années passées` | `arriérés` seul |
| `Compte utilisé` | `compte source` sans aide |
| `Vers quel compte` | `destination` seule |
| `Désactiver` | `archiver` si l'objet reste visible |
| `Selon votre certificat` | projection présentée comme promesse |

Employer `Patrimoine` pour actifs moins dettes. Ne pas appeler toute position
de prévoyance un capital si le modèle représente une rente; ouvrir une
décision financière séparée au lieu de corriger le mot dans une PR visuelle.

## 5. Formules de texte

### Titre

Nommer la tâche, pas la structure technique :

- `Nouveau compte`
- `Ajouter ce qui revient`
- `Mettre le solde à jour`
- `Importer un relevé`

### Aide

Répondre à une seule question : « qu'est-ce que cela change ? »

Exemple : `Cet argent arrive sur votre compte épargne. Il reste à vous : ce
n'est pas une dépense.`

### Erreur

Utiliser : problème concret + donnée concernée + action possible.

- Mauvais : `Erreur invalide`.
- Bon : `Choisissez un compte différent pour recevoir cet argent.`

Ne pas effacer la saisie après une erreur. Placer le message près du champ et
l'annoncer au lecteur d'écran.

### Destructif

Nommer l'objet et la conséquence :

`Supprimer cette facture` puis `Le paiement déjà enregistré restera dans
l'historique.`

### Estimation

Nommer hypothèse, période et limite :

`Estimation pour vous organiser, pas un conseil fiscal.`

### Objectif

Préférer une description à une injonction :

`Pour atteindre cette date : CHF 250 par mois` plutôt que `Il faut CHF 250`.

## 6. Audit de cohérence

Avant clôture :

1. extraire tous les textes visibles et accessibles de la page;
2. rechercher leurs variantes dans tout le dépôt;
3. vérifier singulier/pluriel, genre et ponctuation;
4. vérifier date, période, CHF, signe et statut;
5. vérifier que bouton, toast, ligne historique et écran destination emploient
   le même verbe;
6. vérifier que la couleur n'est jamais la seule preuve;
7. tester textes longs, 320 px, 200 % et Dynamic Type;
8. supprimer anglais décoratif, jargon de trading, faux conseil et promesse
   de connexion bancaire ou de donnée en direct;
9. adapter les assertions de texte sans les rendre plus vagues;
10. documenter toute divergence PWA/iOS volontaire dans une ADR ou le registre.
