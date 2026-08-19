# FE2-5 / FE2-9 — preuves visuelles de l'union de la fortune liquide

Captures 390 px de l'état DISCRIMINANT (lot FE2-9), prises sur l'app
réelle avec un état injecté — quatre comptes :

| Compte | Genre | Cash dispo | Solde |
|---|---|---|---|
| Courant hors quotidien | current | non | 1'000 |
| Quotidien | current | oui | 200 |
| Épargne | savings | non | 500 |
| Épargne au quotidien | savings | **oui** | 300 |

- `comptes-union-390.png` — Comptes : Disponible maintenant 500,
  carte « Ma fortune » : Épargne accessible 800, **Fortune liquide
  1'000** (l'ancienne formule aurait affiché 1'300 : le compte
  « Épargne au quotidien » compté deux fois), Fortune totale 2'000.
- `patrimoine-union-390.png` — Patrimoine : fortune totale 2'000
  décomposée, carte « Fortune liquide » : **1'000** — le MÊME chiffre
  que Comptes (l'ancienne formule par genres aurait affiché 2'000 en
  incluant le courant hors quotidien).

Vérité verrouillée par : parcours e2e 156, fixture de parité n° 7
(`fortune-liquide-union`), test natif
`testLiquidWealthCountsEachFrancExactlyOnce`. Le moteur a confirmé
`liquidWealth === 1000` en page avant chaque capture (la sonde échoue
sinon).
