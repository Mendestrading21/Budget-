# Contrat de P01 — Mois

## Périmètre

Construire l’accueil mensuel et les feuilles qu’il ouvre directement. Réutiliser les pages Historique, Budget, Comptes et Gérer pour les détails. Ne pas inventer sept nouveaux onglets pour afficher sept blocs de données.

La référence HTML est un exemple de composition. Son menu est constitué d’ancres vers ses sections de démonstration ; il ne représente pas des pages déjà implémentées dans le produit.

## Contrats des zones

| Zone | Source et comportement | État incomplet |
| --- | --- | --- |
| Mois consulté | Une seule période canonique ; tous les abonnés de cette période se mettent à jour | Aucune date ambiguë supposée |
| Disponible | Décomposition accessible : liquidités du périmètre, réserve encore incluse, obligations restant dues | « Calcul incomplet », raisons et sources connues |
| Quatre familles | Rentrées reçues, dépenses payées, abonnements payés, mises de côté effectives | Ne pas additionner le prévu au réalisé |
| Échéances | Priorité aux retards, puis dates croissantes ; mois dû distinct du mois payé | Date absente : « Échéance à renseigner » |
| Mouvements | Recherche, famille, statut, ouverture du détail, retour au même filtre | Vide initial différent de filtre sans résultat |
| Budget du mois | Budget alloué et dépenses admissibles ; écart expliqué | Pas de plan : invitation à définir le budget |
| Mis de côté | Objectifs avec montant réellement affecté, source et date | Pas d’objectif : action pour en créer un |
| Comptes et patrimoine | Résumé secondaire, périmètre daté, distinction liquidité / placements / prévoyance / dettes | Conversion ou propriété manquante signalée |

## Interactions principales

**Ajouter une opération.** Ouvrir le formulaire existant. Dans une création indépendante, demander l’intention, le montant, la date et les champs qui changent le calcul. Séparer texte de saisie et montant validé. Garder la saisie en cas d’échec. Une mise de côté demande une destination. Un revenu prévu reste prévu tant qu’il n’est pas reçu.

**Confirmer un paiement.** Ouvrir ou mettre à jour la facture/occurrence existante, conserver sa date prévue et sa date réelle. Éviter les écritures répétées. Une annulation rétablit un état cohérent. Ne pas déduire le paiement d’une couleur ou de la valeur d’un champ.

**Ouvrir un chiffre.** Afficher sa formule de lecture en français simple et les éléments source. Les lignes du détail réconcilient le montant affiché. Expliquer explicitement les exclusions utiles, par exemple les comptes bloqués hors du disponible.

**Changer de mois.** Conserver le mois dans l’état de page, pas dans une variable indépendante par widget. Le filtre de recherche peut être conservé s’il reste visible ; sinon le réinitialiser de manière explicite. Une liste annuelle porte « Année » et ne se fait pas passer pour mensuelle.

**Parcourir une date future.** Respecter les règles actuelles de l’application. Présenter des prévisions comme telles. Ne pas afficher une situation future comme un solde observé et ne pas permettre une confirmation interdite par la politique de date.

**Masquer les montants.** Traiter la page et ses détails comme un ensemble. Ne pas laisser les chiffres dans une infobulle, un attribut accessible, un graphe ou une fenêtre déjà ouverte.

## États à concevoir

Prévoir état normal, mois vide, mois partiel, mois passé, mois futur, aucun résultat, dette ou disponible négatif, montant élevé, date inconnue, conversion manquante, erreur de lecture et échec d’enregistrement. N’afficher un squelette que pendant une vraie attente. Un état vide doit permettre une action utile sans injecter de données fictives dans le budget réel.

## Ordre d’implémentation

1. Vérifier les sélecteurs et définitions actuels ; isoler les éventuels défauts financiers.
2. Adapter la hiérarchie de P01, avec les vraies valeurs et l’ouverture de leurs détails.
3. Terminer sélecteur de mois, filtres et échéances.
4. Brancher formulaires existants, validation, sauvegarde et relecture.
5. Vérifier tous les états et le rendu téléphone/ordinateur.

Une adaptation SwiftUI n’est pas une traduction mécanique du CSS. Utiliser les matériaux, tailles de texte et composants natifs, puis vérifier les mêmes définitions financières. Une amélioration PWA seule doit être annoncée comme telle.
