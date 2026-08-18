# FE2-1 — Les vues d'argent (écrans)

Cahier propriétaire « Financial Engine V2 » (18.08.2026). Règle d'or :
ne jamais présenter une projection comme de l'argent possédé. Données
fictives (Elio, salaire 4'800 attendu, solde 5'000, LAMal 450, loyer
1'200, taux 30 %).

- `mois-maintenant-390.png` — la grande carte, position **Maintenant** :
  « Disponible maintenant CHF 5'000.00 — Sur vos comptes utilisables au
  quotidien. » Le réel, rien que le réel.
- `mois-finmois-390.png` — position **Fin du mois** : « Prévu fin du
  mois CHF 6'710.00 — CHF 5'000 maintenant + CHF 4'800 à recevoir −
  CHF 3'090 à sortir » (3'090 = 1'650 de charges + 1'440 d'effort
  fiscal du mois), suivi du rythme par jour. La projection, décomposée.
- `comptes-390.png` — soldes réels classés : Disponible maintenant
  (héros), **Ma fortune** (épargne accessible / fortune liquide /
  fortune totale, cliquable → Patrimoine), **Épargne** (stock ≠ flux :
  actuelle / ce mois / cette année), puis les groupes.
- `patrimoine-390.png` — la **Fortune liquide** vit à côté de « Tout ce
  qui est à vous » (fortune totale, formule unique).

Tests : parcours 155 (les cinq vues, valeurs exactes du moteur) ;
parcours 36/54/55/104-région et suite design adaptés au nouveau héros.
Contrôles négatifs consignés dans le message de commit.
