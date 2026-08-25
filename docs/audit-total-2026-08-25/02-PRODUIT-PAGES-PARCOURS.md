# 02 — Produit, pages et parcours

## 1. Positionnement cible

Budget n'est ni une banque, ni un tableur comptable, ni un conseiller
financier. C'est un **cockpit personnel de vérité financière** : simple pour
une personne qui ne connaît pas la comptabilité, rigoureux dans son moteur.

### Promesse

En quelques minutes, la personne doit répondre à cinq questions :

1. Combien ai-je réellement maintenant ?
2. Qu'est-ce qui doit encore entrer ou sortir ce mois ?
3. Combien ai-je gagné, dépensé et mis de côté ?
4. Où se trouve mon argent et quelles dettes ai-je ?
5. Est-ce que mon plan tient jusqu'à la fin du mois et sur l'année ?

### Non-promesses

- l'app ne devine pas qu'un paiement est passé ;
- l'app ne garantit pas une projection ;
- l'app ne conseille pas un investissement ;
- l'app ne remplace pas un relevé bancaire ;
- l'app ne calcule pas un impôt officiel sans source et avertissement ;
- l'app ne revend pas les données.

## 2. Profils à servir

- **Débutant** : un compte, salaire, factures, veut savoir ce qu'il reste.
- **Revenu variable** : commissions, bonus, indépendance, scénarios prudents.
- **Couple/foyer** : comptes personnels/communs, dépenses partagées, membres.
- **Épargnant** : fonds d'urgence, réserves, objectifs, argent accessible.
- **Investisseur** : contributions, retraits, dividendes, frais, valorisations.
- **Multi-devise** : devise de base et conversion datée.
- **Utilisateur d'assistance** : lecteur d'écran, texte très grand, clavier.

## 3. Architecture de l'information recommandée

Conserver cinq onglets, alignés sur les questions réelles.

### 1. Mois

**Question :** « Où j'en suis et que reste-t-il à faire ? »

- mois sélectionné et bandeau janvier–décembre ;
- argent réel sur les comptes ;
- prévision fin de mois séparée ;
- revenus réels, dépenses réelles, mis de côté ;
- inbox `À confirmer`, `En retard`, `À vérifier` ;
- écarts de budget ;
- bouton principal `Ajouter`.

Aucun carrousel de chiffres concurrents. Les variantes deviennent segments
explicites : `Maintenant`, `Fin du mois`, `Patrimoine`.

### 2. Activité

**Question :** « Qu'est-ce qui s'est passé ? »

- journal ;
- pending/comptabilisé/rapproché ;
- recherche et filtres ;
- splits ;
- file de revue ;
- détail et correction traçable.

### 3. Plan

**Question :** « Qu'est-ce que j'ai prévu ? »

- budgets ;
- revenus récurrents ;
- factures régulières ;
- abonnements ;
- factures ponctuelles ;
- objectifs/fonds ;
- calendrier ;
- règles.

Les abonnements sont un filtre de récurrence, pas un moteur séparé.

### 4. Comptes

**Question :** « Où est mon argent et pourquoi ce solde ? »

- comptes quotidiens, épargne, cartes, dettes, investissements ;
- actifs hors compte ;
- patrimoine net ;
- fiche compte, relevés, rapprochement ;
- fraîcheur et source de valorisation.

### 5. Plus

**Question :** « Comment configurer et protéger l'app ? »

- foyer/membres ;
- catégories/tags/règles ;
- modules régionaux ;
- import/export/backup ;
- sécurité/confidentialité ;
- langue, devise, apparence ;
- aide et support.

## 4. Dictionnaire des chiffres visibles

| Libellé | Formule | Prévu ? |
|---|---|---|
| Sur vos comptes maintenant | Soldes comptabilisés des comptes inclus | Non |
| Disponible maintenant | Comptes disponibles − réserves réellement bloquées | Non |
| Reçu ce mois | Revenus comptabilisés du mois | Non |
| Dépensé ce mois | Dépenses réelles du coût de la vie | Non |
| Mis de côté ce mois | Transferts/affectations épargne et placements | Non |
| Flux net du mois | Reçu − dépensé | Non |
| Prévu restant | Occurrences ouvertes du mois | Oui, séparé |
| Si tout se passe comme prévu | Disponible + prévu restant net | Oui, conditionnel |
| Patrimoine net | Actifs convertis − dettes converties | Non, à date |
| Budget restant | Plan − dépenses de catégorie | Le plan oui, jamais le solde |

Chaque montant a une définition, un composant partagé, un test, une période et
une devise.

## 5. Parcours critiques

### 5.1 Recevoir un salaire

1. Créer une série ou occurrence ponctuelle.
2. Afficher `Prévu`, sans changer le solde.
3. À la date attendue, passer à `À confirmer`.
4. Bouton `Reçu`.
5. Feuille rapide montant/compte/date préremplis.
6. Confirmation atomique : écriture réelle + occurrence confirmée + lien.
7. Bannière `Salaire reçu — Annuler`.
8. Annuler crée une inversion et réouvre l'occurrence.

Si une transaction bancaire correspond, proposer `Rapprocher` au lieu de créer
un doublon.

### 5.2 Payer une facture

Même cycle, avec montant fixe/estimé, montant réel modifiable, justificatif,
compte de paiement et distinction facture/transfert/remboursement de dette.

### 5.3 Dépense imprévue

1. `Ajouter` → `J'ai dépensé`.
2. Montant.
3. Catégorie ou `Autre`.
4. Tag `Imprévu`.
5. Compte.
6. Enregistrer.
7. Montrer l'effet sur mois et budget sans catégorie artificielle.

### 5.4 Abonnement annuel

- cadence annuelle ;
- coût mensuel équivalent seulement analytique ;
- date de renouvellement ;
- délai de résiliation ;
- rappel ;
- occurrence annuelle réelle ;
- fonds mensuel dédié sans compter ce fonds comme dépense.

### 5.5 Transfert vers l'épargne

- source et destination ;
- aucune dépense du coût de la vie ;
- baisse du disponible quotidien ;
- hausse de l'épargne ;
- patrimoine inchangé ;
- progression d'objectif si lié.

### 5.6 Investissement

Distinguer : transfert de cash vers titres, achat/vente interne si positions,
et revenu de placement. La variation de valeur n'est jamais un revenu encaissé.

### 5.7 Import bancaire

1. Choisir format/compte.
2. Parser en modèle intermédiaire.
3. Prévisualiser nouveaux, doublons, matches, invalides.
4. Corriger mappings/catégories/statut.
5. Confirmer atomiquement.
6. Ouvrir `À vérifier`.
7. Rapprocher occurrences/transferts.
8. Rollback de lot traçable.

### 5.8 Rapprocher un relevé

1. Choisir compte/période.
2. Solde de clôture.
3. Pointer les opérations.
4. Afficher l'écart.
5. Terminer à zéro ou avec ajustement explicite.
6. Verrouiller le lot.
7. Correction future par trace.

### 5.9 Fermer le mois

Une revue, pas une obligation comptable : échéances non confirmées, mouvements
à vérifier, comptes non rapprochés, budget dépassé, imprévus, épargne et
résultat. Le mois peut rester ouvert.

### 5.10 Sauvegarder/restaurer

Export chiffré, pièces jointes optionnelles, résumé, intégrité, store
temporaire, comparaison, biométrie, remplacement atomique et retour possible à
la sauvegarde pré-restauration.

## 6. Contrat des pages actuelles P00–P18

| ID | Destination cible | Décision |
|---|---|---|
| P00 Coquille/navigation | Shell commun | Garder, vraies routes/deep links, retirer routes mortes |
| P01 Mois | Onglet Mois | Refaire autour du réel, projection et inbox |
| P02 Ajouter | Feuille universelle | Garder, statut, splits, tags, justificatif |
| P03 Historique | Onglet Activité | Renommer, pending/review/reconciliation |
| P04 Budget | Onglet Plan | Garder comme sous-vue, report/cibles |
| P05 Comptes | Onglet Comptes | Garder, types universels et devises |
| P06 Fiche compte | Comptes | Garder, relevés/rapprochements/audit trail |
| P07 Gérer | Onglet Plus | Simplifier fortement |
| P08 Ce qui revient | Onglet Plan | Garder, nouveau moteur d'occurrences |
| P09 Factures ponctuelles | Onglet Plan | Fusionner dans occurrences, rendre paritaire |
| P10 Objectifs | Plan/Comptes | Garder, lier aux affectations réelles |
| P11 Impôts | Module régional | Opt-in, hors cœur mondial |
| P12 Patrimoine | Comptes | Garder, valorisation multi-devise datée |
| P13 Assurances/prévoyance | Module régional | Opt-in, éviter doubles valeurs |
| P14 Année | Mois/Plan | Rapport, pas silo |
| P15 Import/documents | Activité/Plus | Séparer import et coffre documentaire |
| P16 Onboarding | Adaptatif | Raccourcir, proposer sans comptabiliser |
| P17 Réglages/verrou/backup | Plus | Garder, clarifier chiffrement/portabilité |
| P18 Assistant local | Insights déterministes | Différer, ne pas promettre IA |

## 7. Pages à créer

### Inbox financière

Liste triée : à confirmer, en retard, match à valider, transaction à
catégoriser, compte à rapprocher, renouvellement proche. Chaque carte explique
pourquoi elle apparaît, ce que fait l'action, et permet reporter/ignorer.

### Centre des règles

Liste ordonnée, conditions lisibles, actions, nombre de matches, preview,
activation, journal, sans annuler les transactions lors de la désactivation.

### Rapprochements

Relevés par compte, état, différence, dates, opérations et historique.

### Centre des devises

Devise de base, taux, source, date, valeurs manquantes et politique historique.

## 8. Catégories, tags et termes

### Catégories de départ universelles

Revenus : Salaire, Indépendant, Bonus/commission, Allocations, Intérêts et
dividendes, Remboursement reçu, Autre revenu.

Dépenses : Logement, Énergie/communications, Assurances, Alimentation,
Restaurants/sorties, Transport, Santé, Enfants/garde, Shopping, Loisirs/voyages,
Abonnements, Impôts/taxes, Frais financiers, Cadeaux/dons, Autre dépense.

Affectations : Épargne, Fonds d'urgence, Objectif, Investissement, Provision
fiscale.

### Tags de départ

Imprévu, Professionnel, Remboursable, Partagé, Enfant, Voyage, À vérifier.

Les catégories répondent « pour quoi ? », les tags « dans quel contexte ? ».

### Terminologie utilisateur

| Interne | Visible |
|---|---|
| posted | Reçu / Payé / Comptabilisé selon contexte |
| pending | En attente |
| scheduled occurrence | Échéance prévue |
| cleared | Pointé sur le compte |
| reconciled | Rapproché avec le relevé |
| reversal | Annulation liée |
| idempotency | Protection contre les doublons |
| ledger | Journal financier |
| posting | Mouvement sur un compte |

Ne pas exposer débit/crédit aux débutants sauf écran avancé.

## 9. Onboarding cible

1. Objectif : mois, factures, épargne, comptes, foyer.
2. Région/langue/devise : Suisse active modules canton/3a/prévoyance.
3. Premier compte : solde d'ouverture comme photographie datée.
4. Revenus prévus : série, jamais revenu réel.
5. Factures : suggestions facultatives, aucune dépense réelle.
6. Résumé : réel, prévu à recevoir, prévu à payer, projection.

La démo utilise un store isolé, marqué et réinitialisable.

## 10. Principes visuels et accessibilité

- un chiffre focal ;
- montant + période + devise ;
- couleur jamais seule ;
- cibles 44 pt/px ;
- texte dynamique ;
- tableaux transformables en listes ;
- graphiques avec résumé textuel ;
- clair/sombre/système ;
- réduire mouvement/transparence ;
- erreurs annoncées ;
- focus restauré ;
- aucun swipe comme seule action ;
- destructif récupérable si possible.

Le design Budget Prisme reste applicable. Cette architecture précise ce que
chaque page doit raconter.
