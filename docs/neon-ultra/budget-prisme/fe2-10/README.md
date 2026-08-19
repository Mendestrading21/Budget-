# FE2-10 — la décomposition nomme l'impôt à mettre de côté

Retour propriétaire (capture du 19.08.2026, son vrai état : 10'000 sur
le compte, salaire attendu 2'000, aucune facture) : « pourquoi sortir
600 alors que je n'ai même pas de facture ? ». La ligne « à sortir »
fondait l'effort d'impôts du mois (30 % × 2'000 = 600, le taux par
défaut de l'onboarding suisse) avec les vraies sorties — chiffre juste,
étiquette mensongère.

- `mois-finmois-impots-nommes-390.png` — le même état que sa capture,
  après correctif : « CHF 10'000.00 maintenant + CHF 2'000.00 à
  recevoir − CHF 600.00 **d'impôts à mettre de côté**. » Aucun terme
  « à sortir » : il n'y a aucune vraie sortie, le terme se tait.

Règles : chaque terme réel est NOMMÉ ; un terme à zéro disparaît ;
même phrase sur les deux plateformes
(`HomePilotDisplay.forecastDecomposition`). Verrous : parcours e2e 157
(né rouge : « 1'009.90 à sortir » fondait 109.90 réels + 900 d'impôts),
test natif `testForecastDecompositionNamesTheTaxAndSilencesZeroTerms`.
L'utilisateur qui ne veut aucune provision règle son taux à 0 % dans
Gérer → Impôts — le terme disparaît partout.
