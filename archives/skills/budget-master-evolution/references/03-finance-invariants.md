# Invariants financiers

## Convention

- Natif : Decimal, jamais Double pour un montant.
- Web cible : centimes entiers, conversion uniquement à l'entrée et à l'affichage.
- Ne jamais additionner deux devises sans conversion explicite et traçable.

## Effets

| Type | Source | Destination | Résultat du mois | Patrimoine |
|---|---:|---:|---:|---:|
| Revenu | + | — | + | + |
| Dépense | − | — | − | − |
| Virement interne | − | + | 0 | 0 |
| Épargne interne | − | + | 0, présenté mis de côté | 0 |
| Investissement interne | − | + | 0, présenté investi | 0 |
| Impôt payé | − | — | séparé du coût de la vie | − |
| Dette remboursée | − cash | dette moins négative | 0 hors intérêts | 0 hors intérêts |
| Ajustement | selon sens | — | 0 | variation expliquée |

Refuser un versement interne sans destination ou expliquer qu'il s'agit d'une sortie externe.

## Règles

- Le planifié ne modifie jamais le solde réel.
- Une occurrence matérialisée ne reste pas à venir.
- Une facture payée référence son mouvement.
- Une opération ne compte qu'une fois après import, duplication ou restauration.
- Solde = ouverture + effets signés.
- Patrimoine = comptes + actifs + prévoyance − dettes.
- Contribution et performance restent distinctes.
- Estimé fiscal = payé + encore dû, avec hypothèses visibles.

## Cas obligatoires

Tester zéro, grands montants, centimes, dette soldée, mois passé/futur, suppression annulée, restauration, devise différente, taux absent, réimport identique et 10 000 opérations générées.
