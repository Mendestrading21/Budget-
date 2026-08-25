# Fixtures canoniques — schéma version 1 (W1.1, ADR-059)

Une fixture canonique est le CONTRAT d'une vérité financière : les mêmes
entrées, les mêmes sorties attendues, exécutées par le moteur Web ET le moteur
Swift (runners W1.6). Ce document est l'autorité du format. Le validateur
`webapp/tests/canon-schema.test.mjs` le fait respecter mécaniquement.

## Règles de fond

1. **Unités mineures entières (ADR-059).** Tout montant est un ENTIER d'unités
   mineures de sa devise (exposant ISO 4217 : CHF, EUR, USD → 2 ; soit
   `123456` pour 1 234.56). Jamais de flottant : un montant à virgule est un
   échec de validation, pas un arrondi silencieux (FI-18, FI-34).
2. **Taux en chaîne décimale, datés et sourcés.** Un taux de change est une
   chaîne (`"0.9412"`), avec `date` et `source` obligatoires (FI-16). Un taux
   absent ne devient jamais 1 ni 0 (FI-17) : la fixture qui teste ce cas
   attend un résultat « incomplet », pas un nombre.
3. **Vocabulaire du glossaire W0.** Les états sont `planned`/`posted`
   (version 1 — les états du journal cible entreront au schéma version 2 avec
   W3, par ADR). Les types sont ceux du produit mesuré.
4. **Dates ISO** (`YYYY-MM-DD`), fuseau neutre : une fixture ne dépend jamais
   de l'horloge de la machine (`entrees.date` est LE jour de référence).
5. **Données fictives déterministes** — aucun nom, montant ou établissement
   réel d'une personne.
6. **Identifiants uniques et références résolues** : un mouvement pointe vers
   un compte déclaré, sinon échec (FI-34 — pas de repli).

## Format

```json
{
  "version": 1,
  "nom": "nom-court-du-scenario",
  "description": "Ce que cette fixture prouve, en français simple.",
  "entrees": {
    "deviseBase": "CHF",
    "date": "2026-05-15",
    "comptes": [
      { "id": "cur", "nom": "Compte courant", "genre": "current",
        "devise": "CHF", "ouvertureMineures": 100000,
        "cash": true, "patrimoine": true, "actif": true }
    ],
    "mouvements": [
      { "id": "m1", "date": "2026-05-02", "type": "income",
        "statut": "posted", "montantMineures": 200000, "devise": "CHF",
        "compte": "cur", "categorie": "Salaire", "titre": "Salaire" }
    ],
    "recurrences": [
      { "id": "r1", "titre": "Loyer", "type": "expense",
        "nature": "facture", "montantMineures": 150000, "devise": "CHF",
        "jour": 1, "rythme": "month", "compte": "cur" }
    ],
    "taux": [
      { "base": "EUR", "cote": "CHF", "taux": "0.9412",
        "date": "2026-05-15", "source": "fixture-fictive" }
    ]
  },
  "attendus": {
    "soldesMineures": { "cur": 300000 },
    "mois": { "annee": 2026, "mois": 5,
      "recuMineures": 200000, "depenseMineures": 0,
      "misDeCoteMineures": 0, "liquideMineures": 300000,
      "finDeMoisMineures": 150000 },
    "patrimoine": { "fortuneTotaleMineures": 300000,
      "epargneAccessibleMineures": 0 }
  }
}
```

## Champs

### `entrees.comptes[]`

| Champ | Type | Sens |
|---|---|---|
| `id` | chaîne unique | référence interne à la fixture |
| `genre` | `current · cash · savings · brokerage · pension · lifeinsurance` | typologie mesurée (la typologie cible W4 entrera par version de schéma) |
| `devise` | ISO 4217 | devise du compte |
| `ouvertureMineures` | entier | solde de départ en unités mineures |
| `cash` | booléen | compte dans l'argent disponible |
| `patrimoine` | booléen | compte dans la fortune totale |

### `entrees.mouvements[]`

`type` ∈ `income · refund · expense · saving · investment · transfer ·
taxPayment · debtPayment · adjustment` ; `statut` ∈ `planned · posted` ;
`montantMineures` entier strictement positif (le sens vient du type) ;
`destination` obligatoire pour les types qui déplacent l'argent vers un autre
compte ; `hausse` (booléen) obligatoire pour `adjustment` ; `titre` obligatoire
(jamais de libellé vide silencieux).

### `entrees.recurrences[]`

`rythme` ∈ `month · quarter · semester · year · week · twoWeeks · fourWeeks` ;
`jour` 1–31 ; `nature` libre (`facture`, `abonnement`, `revenu`, `reserve`).

### `attendus`

Uniquement des ENTIERS d'unités mineures. `soldesMineures` par compte (devise
du compte) ; `mois` dans la devise de base ; `patrimoine` dans la devise de
base. Un champ absent = non testé par cette fixture. Les agrégats correspondent
au dictionnaire des chiffres W0 (`docs/autonomie/w0/DICTIONNAIRE_CHIFFRES.md`).

## Versionnement

- `version` est un entier ; ce document décrit la version **1**.
- Un changement INCOMPATIBLE (nouvel état, nouveau champ obligatoire) →
  version + 1, ADR, et les runners acceptent les deux versions le temps de la
  migration des fixtures.
- Un ajout optionnel rétrocompatible → même version, entrée dans ce document.

## Ce que W1.1 ne fait pas

Aucun runner (W1.6), aucun branchement de parité en CI (W1.7), aucune
modification de moteur. Le validateur de schéma garantit seulement que les
fixtures écrites dans les sous-lots W1.2–W1.5 naîtront bien formées.
