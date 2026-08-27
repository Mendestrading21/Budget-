# Fiche App Store — Budget (W11.6)

Tout ce qui peut être préparé SANS le propriétaire l'est ici, en
français simple, dans les limites exactes d'App Store Connect
(vérifiées par l'audit racine : nom ≤ 30, sous-titre ≤ 30, mots-clés
≤ 100, texte promotionnel ≤ 170, description ≤ 4000 caractères). Ce
qui exige un geste ou une donnée du propriétaire est marqué HUMAN
REQUIRED — jamais inventé.

## Champs de la fiche

- **NOM** : `Budget — argent du ménage`
- **SOUS-TITRE** : `Dépenses, épargne, patrimoine`
- **MOTS-CLÉS** : `budget,dépenses,épargne,patrimoine,ménage,suisse,CHF,abonnements,impôts,finances`
- **TEXTE-PROMO** : `Votre argent, expliqué simplement. Tout reste sur votre iPhone : pas de compte, pas de serveur, pas de pub.`

## Description

<description>
Budget répond en dix secondes à la seule question qui compte : combien
il vous reste, et ce qu'il faut encore payer.

TOUT RESTE CHEZ VOUS
Pas de compte, pas de serveur, pas de publicité, aucune connexion à
votre banque. Vos données vivent sur votre iPhone, point. Vous pouvez
les exporter, les sauvegarder — protégées par une phrase de passe si
vous voulez — et tout supprimer d'un geste.

QUATRE FAMILLES, TOUJOURS LES MÊMES
Rentrées, Dépenses, Abonnements, Mis de côté. Chaque franc vit dans une
seule famille, les virements entre vos comptes ne comptent jamais
double, et l'argent envoyé vers l'épargne n'est pas une dépense : il
reste à vous.

CHAQUE MOIS, VALIDEZ, BOUCLEZ
Salaire, loyer, factures, abonnements : vos récurrents arrivent tout
seuls, vous les confirmez d'un geste. Rien ne s'enregistre sans vous.

VOTRE CHEMIN SE DESSINE
Soldes de comptes, budgets par catégorie, patrimoine (comptes, biens,
dettes, prévoyance), impôts mis de côté, échéances d'assurances.
Des graphiques sobres, des montants exacts au centime, en francs
suisses ou en euros.

PENSÉ POUR LA SUISSE
Format fr-CH, pilier 3a, caisse de pension, provisions d'impôts par
année, délais de résiliation des assurances.

HONNÊTE PAR CONSTRUCTION
Pas de connexion bancaire promise, pas de conseils financiers, pas de
chiffres inventés : ce que l'app affiche vient de ce que vous avez
saisi, et elle vous dit quand une information manque.
</description>

## Notes pour la review Apple

- **REVIEW-COMPTE** : aucun compte de démonstration à fournir — l'app
  n'a AUCUN compte ni connexion ; l'écran d'accueil propose un pays,
  puis tout fonctionne hors ligne. Un jeu de démonstration intégré
  (« Charger la démonstration » dans Réglages) permet d'explorer avec
  des données fictives.
- **REVIEW-RESEAU** : l'app ne fait aucune requête réseau — un test en
  mode avion est le chemin nominal, pas un cas d'erreur.
- **REVIEW-VERROU** : le verrouillage utilise Face ID/Touch ID/code de
  l'appareil ; l'activer demande une authentification (rien à
  configurer côté review).

## Storyboard des captures (à générer via le workflow Demo)

| # | Écran | Message |
|---|---|---|
| 1 | Mois (accueil) | « Combien il reste, en un regard » |
| 2 | Historique | « Chaque franc dans sa famille » |
| 3 | Budget | « Des enveloppes qui disent la vérité » |
| 4 | Comptes/Patrimoine | « Comptes, biens, dettes, prévoyance » |
| 5 | Gérer/Réglages | « Vos données restent sur votre iPhone » |

Appareils : 6.9" (obligatoire) et 6.5" ; données FICTIVES uniquement
(jeu de démonstration) ; mode sombre unique (ADR-074).

## Éléments propriétaire (HUMAN REQUIRED)

| Élément | État |
|---|---|
| URL de support publique | HUMAN REQUIRED — à fournir (page ou adresse de contact) |
| URL de la politique de confidentialité | HUMAN REQUIRED — même élément que la fiche App Privacy (W11.5) |
| Validation du nom exact sur le store (disponibilité) | HUMAN REQUIRED — le nom proposé peut être pris ; App Store Connect tranche à la création |
| Compte App Store Connect, création de la fiche, envoi des captures | HUMAN REQUIRED — geste propriétaire (avec les 4 secrets TestFlight du backlog) |

## Synthèse

Fiche prête à recopier : nom, sous-titre, mots-clés, promo et
description dans les limites Apple (vérifiées par l'audit), notes de
review honnêtes (pas de compte — rien à fournir), storyboard de
5 captures aligné sur les quatre familles. Les quatre manques sont
propriétaire et nommés.
