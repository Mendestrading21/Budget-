# Contrat des données et des calculs

## Sources de vérité

Dans Budget, utiliser les services de domaine, leurs types et les décisions actuelles. Le modèle de référence joint est un support pédagogique isolé, limité au CHF, à deux périodes fictives et à des opérations simples. Il ne prend pas en charge les impôts calculés, les conversions, la consolidation multi-propriétaire, le crédit ou les valorisations de marché.

Pour un moteur nouveau, employer des entiers en unité monétaire mineure quand la précision requise le permet, ou un type décimal exact. Garder `Decimal` sur iOS. Définir l’échelle par devise ; ne pas appliquer arbitrairement deux décimales à tous les actifs. Ne pas utiliser des flottants binaires pour les agrégats financiers.

## Définitions

| Indicateur | Définition | Ne pas confondre avec |
| --- | --- | --- |
| Reçu | Somme des entrées externes comptabilisées dans la période | Revenus attendus, ventes brutes de titres, virements internes |
| Dépenses | Consommations payées hors famille Abonnements | Mises de côté ou remboursements de capital |
| Abonnements payés | Paiements comptabilisés rattachés à un abonnement | Somme annualisée des contrats |
| Dépensé au total | Dépenses + abonnements payés sur un périmètre précisé | Tous les débits indistinctement |
| Mis de côté | Affectations effectives avec destination, selon le modèle existant | Excédent arithmétique reçu moins dépensé |
| À payer | Obligations encore dues et non déjà comptabilisées, dans l’horizon affiché | Dépenses déjà payées |
| Reste du budget | Plan alloué moins réalisé admissible sur la même période | Solde bancaire |
| Patrimoine net | Actifs moins dettes, avec propriétaires, date et conversions explicités | Argent disponible |

Les paiements fiscaux sont des sorties suivies une seule fois. Une vue fiscale peut les expliquer séparément. Si le coût de la vie est affiché hors impôts, rendre cette exclusion explicite. Ne pas changer cette définition dans un lot esthétique.

## Disponible

Définir d’abord les comptes inclus et l’horizon. Partir des liquidités observées de ce périmètre, retrancher les obligations encore dues qui les consommeront et les sommes réservées qui y sont **encore incluses**. Ne pas retrancher un compte de réserve déjà exclu ni une dépense déjà reflétée dans le solde.

Garder une prévision qui inclut les revenus futurs séparée du disponible observé. Si un élément nécessaire manque, fournir les montants connus et la cause de l’incomplétude ; ne pas publier un résultat partiel sous un libellé certain.

Exemple fictif de la référence : 10’860 CHF de liquidités, dont 2’000 CHF réservés, et 1’480 CHF d’obligations encore dues donnent 7’380 CHF disponibles selon ce périmètre. Confirmer une de ces obligations diminue à la fois la liquidité et le restant dû : le disponible ne doit pas être débité deux fois.

## Neutralité, dettes et patrimoine

- Transfert entre deux comptes du même périmètre : aucune entrée ou consommation nouvelle, patrimoine total inchangé.
- Mise de côté : peut réduire le disponible du compte courant ; augmente la poche d’arrivée et ne détruit pas de patrimoine.
- Remboursement de dette : séparer capital, intérêts et frais. Le capital diminue liquidités et dette ; intérêts et frais constituent un coût.
- Carte de crédit : distinguer solde créditeur, dette et plafond. Un crédit disponible n’est pas une épargne.
- Compte titres et positions : choisir une source de valorisation, puis utiliser l’autre comme détail. Ne pas les additionner deux fois.
- Enfant, conjoint et foyer : stocker le titulaire et le périmètre inclus. Une étiquette affective n’établit pas la propriété.
- Prévoyance : distinguer capital, prestation projetée et rente ; ne pas additionner une rente annuelle à un capital.

## Devises et dates

Conserver montant original, devise, date de l’opération et taux historique appliqué. Pour une valorisation actuelle, conserver la date de valorisation et la provenance du taux. Ne pas recalculer une transaction ancienne avec le cours du jour.

La date prévue, la date de paiement et la période budgétaire peuvent différer. Une facture de décembre payée en janvier doit apparaître dans les bonnes lectures sans devenir deux paiements. Employer une vraie clé de période, par exemple `2026-09`, plutôt qu’un titre « Septembre » sans année.

## Récurrence et fiscalité

Un abonnement est une définition ; une échéance est une occurrence ; un paiement est un événement comptabilisé. Relier les trois. L’identifiant d’occurrence doit être stable et l’application d’un paiement idempotente.

Ne pas transformer « toutes les quatre semaines » en « mensuel ». Présenter séparément coût annualisé et décaissement du mois. Une résiliation affecte les occurrences futures selon les règles du contrat, sans réécrire les paiements passés.

Suivre l’impôt renseigné, le montant payé et l’argent réservé comme trois notions distinctes. Garder la fiscalité manuelle du projet : aucune réintroduction d’un taux automatique ou d’un ancien calcul issu d’une archive.

## Sauvegarde, import et provenance

Conserver une donnée saisie une seule fois, puis des vues dérivées. Préserver identifiants et historique. Une restauration valide tout le contenu avant le remplacement ; un échec ne détruit pas la version précédente. L’écran n’annonce « enregistré » qu’après le succès réel du stockage.

Un import passe par lecture, mapping, aperçu, validation et application contrôlée. Identifier sa source et sa clé de dédoublonnage. Ne pas prendre un export à zéro, une date absente ou un statut inconnu comme une certitude métier.

## Cas de preuve prioritaires

1. Un revenu seulement prévu ne gonfle pas le reçu ni le solde observé.
2. Payer une échéance déjà incluse dans « À payer » ne diminue pas deux fois le disponible.
3. Répéter le même paiement ne change plus aucun total.
4. Une mise de côté change les poches mais pas le patrimoine consolidé.
5. Un abonnement payé n’entre pas dans deux familles.
6. Un transfert interne ne devient pas un revenu externe.
7. Une devise sans conversion fiable bloque le total consolidé concerné.
8. Une donnée manquante et un vrai zéro restent distincts.
9. Le mois sélectionné pilote tous les agrégats mensuels.
10. Une erreur de stockage conserve la saisie et n’affiche pas un succès.
