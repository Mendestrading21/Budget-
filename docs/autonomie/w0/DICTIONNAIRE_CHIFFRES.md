# W0.3 — Dictionnaire des chiffres

Chaque chiffre montré à l'utilisateur a UNE définition, UNE source de calcul
par plateforme et UN propriétaire de vérité. Mesuré au SHA `bcef018` (PWA
`webapp/index.html`, iOS `Budget/Domain/Services/`). Ce document ne change
aucune formule : il fige ce que chaque chiffre PROMET, pour que W1 puisse
écrire les fixtures canoniques.

Règle : un chiffre = une fonction. Deux écrans qui montrent « le même »
chiffre appellent la MÊME fonction (précédents : `fortuneTotale()` partagé
carte↔Comptes depuis ADR-053 ; `estimationEnchainee` depuis ADR-056).

## Les chiffres du Mois

| Chiffre (mot à l'écran) | Promesse | Source PWA | Source iOS | États comptés |
|---|---|---|---|---|
| « Disponible maintenant » | L'argent réellement présent sur les comptes du quotidien (`cash`). | `snapshot().liquid` ← `balance()` | `MonthSnapshot.available.liquidBalance` ← `AccountBalanceService` | `posted` seulement |
| « Prévu fin du mois » | Projection conditionnelle du mois courant : réel + prévu du mois. | `snapshot().endOfMonthForecast` | `available.total` | `posted` + prévus/engagés du mois |
| « Tout votre argent » | Fortune totale — LE chiffre de Comptes/Patrimoine (ADR-053/054). | `fortuneTotale()` | `NetWorthService.breakdown(...).netWorth` | `posted` + valeurs datées |
| « Sur vos comptes maintenant » (mois futur) | L'argent réel aujourd'hui — jamais l'estimation (ADR-055). | `snapshot().liquid` | `available.liquidBalance` | `posted` seulement |
| « Si tout se passe comme prévu » (mois futur, petit) | Estimation ENCHAÎNÉE : fin prévue du mois courant + flux prévus de chaque mois intermédiaire (ADR-056). | `estimationEnchainee(y, m)` | `HomeTab.chainedEstimate(to:)` | conditionnel, jamais focal |
| « Reçu / Dépensé / Mis de côté » (trio) | Ce qui a réellement bougé ce mois. | `snapshot().income/.living/.savings+.invest` | `MonthlySnapshotService` | `posted` seulement |
| « Résultat du mois » (mois passé) | Revenus réels − sorties réelles du mois consulté. | `snapshot().cashFlow` | `snapshot.cashFlow` | `posted` du mois consulté |

## Les chiffres des Comptes

| Chiffre | Promesse | Source PWA | Source iOS |
|---|---|---|---|
| Solde d'un compte | Solde de départ + mouvements `posted` du compte (devise du compte). | `balance(accId)` | `AccountBalanceService.balance(of:)` |
| « Entrées / Sorties du mois » (fiche) | Ce qui est entré/sorti du compte ce mois, `posted` seulement — mêmes règles de flux que le solde (ADR-057). | `accountMonthFlows` | `AccountDetailView.currentMonthFlows` ← `signedEffect` |
| « Fortune totale » | Comptes inclus + biens inclus + prévoyance capitalisée − dettes. | `fortuneTotale()` | `NetWorthService.breakdown(...).netWorth` |
| « Épargne accessible » | STOCK des comptes d'épargne actifs. | `snapshot().savingsAccessible` | `NetWorthService.accessibleSavings` |
| « Fortune liquide » | Union cash + épargne, chaque franc UNE fois. | `snapshot().liquidWealth` | `NetWorthService.liquidWealth` |
| Solde historique (courbe) | Solde du compte à la fin d'un mois donné. | `balanceAt(accId, y, m)` | série `NetWorthSnapshot` |

## Budget, impôts, objectifs

| Chiffre | Promesse | Source PWA | Source iOS |
|---|---|---|---|
| Budget restant d'une enveloppe | Planifié − réel de la catégorie ; ne touche JAMAIS un solde (FI-20). | `budgetReport(y, m)` | services budget natifs |
| « Réserve d'impôts » | Somme SAISIE pour l'année — aucun calcul automatique (ADR-035). | `taxSummary(year).reserved` | `TaxProvision.reservedAmount` |
| Avancement d'un objectif | Fait sur visé, depuis le compte lié ou le montant manuel. | `goalCurrent(g)` | `GoalProgressService.currentAmount(of:)` |
| Versements d'un placement | Mis de côté cette année / en tout / retraits. | `contributions(accId)` | `ContributionService` |
| Performance d'un compte titres | Valeur − versements nets ; jamais un revenu du mois (FI-26). | calcul fiche compte | `AccountDetailView` |

## Écarts connus (consignés, traités par les lots)

1. **Deux moteurs.** Chaque ligne ci-dessus a DEUX implémentations. Les
   fixtures de parité couvrent des scénarios, pas le contrat entier →
   W1 (fixtures canoniques) puis W3 (journal unique).
2. **Devises.** `toCHF`/`convertAmount` utilisent des taux stockés sans date ni
   source par ligne ; le formatage impose la devise de base (FI-15/16/17) → W4.
3. **`posted` par déduction de date.** Le tableau dit « `posted` seulement »,
   mais l'entrée en `posted` peut venir de la seule date de saisie
   (constat n° 3) → W2 (confirmation explicite).
4. **Projection.** `endOfMonthForecast` mélange engagements et moyennes
   (revenus irréguliers) sans étiquette de composition ; la cible FI-22 exige
   « occurrences ouvertes seulement » → W2/W6.

## Règle d'usage

- Un nouvel écran qui veut montrer un de ces chiffres APPELLE la fonction du
  tableau — jamais une variante locale.
- Un nouveau chiffre = une entrée ici + une fixture W1 + les deux sources.
- Un chiffre dont la promesse change = ADR + fixture rouge d'abord.
