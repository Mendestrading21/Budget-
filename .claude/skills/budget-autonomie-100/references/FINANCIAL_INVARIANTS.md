# Financial Invariants

## Truth and lifecycle

| ID | Invariant | Example de test |
|---|---|---|
| FI-01 | Prévu ne modifie aucun solde réel | Salaire futur visible en projection, solde inchangé |
| FI-02 | Date attendue n'est pas preuve | Facture d'hier non confirmée reste due |
| FI-03 | Une occurrence a une identité persistée | Relance/génération ne crée pas une seconde échéance |
| FI-04 | Confirmation idempotente | Double tap = une écriture |
| FI-05 | Montant attendu et réel sont conservés | Facture prévue 100, payée 97.50 |
| FI-06 | Pending ≠ posted ≠ cleared ≠ reconciled | Sync bancaire traverse les états sans doublon |
| FI-07 | Mouvement rapproché immuable | Correction crée inversion/remplacement |

## Journal and accounts

| ID | Invariant | Example de test |
|---|---|---|
| FI-08 | Chaque entrée est équilibrée par devise | Somme postings CHF = 0 |
| FI-09 | Transfert interne est atomique et neutre | A −500, B +500, dépense 0, patrimoine stable |
| FI-10 | Épargne/placement interne n'est pas coût de vie | Mis de côté +500, dépenses inchangées |
| FI-11 | Solde dérive des postings comptabilisés | Aucun calcul de prévision dans balance |
| FI-12 | Solde d'ouverture est une écriture | Une source unique, pas propriété + posting |
| FI-13 | Compte archivé conserve l'histoire | Rapports passés identiques |
| FI-14 | Dette : capital, intérêts et frais distincts | Paiement capital neutre entre actif/dette |

## Money and currencies

| ID | Invariant | Example de test |
|---|---|---|
| FI-15 | Montant porte une devise | Aucun Decimal nu dans contrat public |
| FI-16 | Conversion porte taux/source/date | EUR inclus seulement avec quote datée |
| FI-17 | Taux absent ne devient jamais 1 ou 0 | Patrimoine marqué incomplet |
| FI-18 | Arrondi déterministe | Unités mineures/exposant ISO testés |
| FI-19 | Valeur historique conserve son taux | Rapport ancien stable après nouveau taux |

## Planning and reporting

| ID | Invariant | Example de test |
|---|---|---|
| FI-20 | Budget restant ≠ solde bancaire | Changer budget ne change aucun compte |
| FI-21 | Flux net = revenus réels − coût réel | Transferts/épargne exclus |
| FI-22 | Projection est conditionnelle | Label et formule incluent seulement occurrences ouvertes |
| FI-23 | Mois/année consultés utilisent leur période | Aucune horloge courante dans agrégat historique |
| FI-24 | Remboursement possède un traitement explicite | Réduction de dépense ou revenu, jamais hasard |

## Net worth and investments

| ID | Invariant | Example de test |
|---|---|---|
| FI-25 | Une valeur n'est comptée qu'une fois | Positions expliquent le compte, ne s'y ajoutent pas |
| FI-26 | Valeur de marché ≠ revenu encaissé | Plus-value non réalisée hors revenus du mois |
| FI-27 | Actifs et dettes ont date/source | « Valeur au… » visible |
| FI-28 | Rente ≠ capital | Rente AVS non ajoutée au patrimoine |

## Imports, backup and persistence

| ID | Invariant | Example de test |
|---|---|---|
| FI-29 | Import réessayable sans doublon | Fichier renommé/réordonné reconnu |
| FI-30 | Aucune écriture avant confirmation | Preview ne modifie pas store |
| FI-31 | Mutation multi-objet atomique | Échec confirmation laisse occurrence et journal intacts |
| FI-32 | Save échoué n'affiche pas succès | Stockage refusé produit erreur visible |
| FI-33 | Restore validé avant remplacement | Backup corrompu conserve store actuel |
| FI-34 | Relations/enum/montants inconnus refusés | Aucun fallback silencieux |
| FI-35 | Migration conserve IDs et soldes | Fixture Vn → latest identique métier |

## Security and product truth

| ID | Invariant | Example de test |
|---|---|---|
| FI-36 | Verrou d'écran n'est pas appelé chiffrement | Texte sécurité exact |
| FI-37 | Logs sans données financières | Scan des diagnostics |
| FI-38 | Intégration absente non promise | Aucun logo « connecté » fictif |
| FI-39 | Automatisation explicable et annulable | Règle/source/undo visibles |
| FI-40 | Même vérité Web/iOS | Fixtures structurées identiques |

## Politique de changement

Modifier un invariant exige :

1. incident ou besoin documenté ;
2. ADR et décision propriétaire ;
3. fixture rouge sur les deux plateformes ;
4. migration/compatibilité ;
5. contrôle négatif ;
6. mise à jour des textes et rapports ;
7. PR séparée de toute refonte décorative.
