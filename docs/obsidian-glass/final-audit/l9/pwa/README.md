# Captures de l'audit final L9 — PWA (25.07.2026, inspectées)

Générées par le script d'audit (Chromium réel, deviceScaleFactor 2,
onboarding fictif « Elio + Sara » rejoué, zéro erreur console sur tout
le parcours). Données EXTRÊMES semées exprès : revenu fictif de
CHF 1'234'567.89 avec intitulé très long, compte « Carte de crédit
(audit) » à solde négatif constant. `audit-results.json` contient les
70 verdicts (débordement horizontal, zone d'exclusion du ＋ à
l'ouverture ET après défilement — géométrie du test e2e 60 —,
persistance, service worker, installabilité, hors-ligne).

| Capture | Ce qu'elle prouve (vu, pas supposé) |
|---|---|
| `l9-390-mois.png` | héros 7 chiffres SANS troncature (CHF 866'197.52), métriques Entré/Dépensé/À payer/Mis de côté, priorité, ＋ dans sa bande |
| `l9-390-mouvements.png` / `l9-390-budget.png` / `l9-390-comptes.png` | les 3 onglets pleins, zéro débordement |
| `l9-390-compte-detail.png` | solde 7 chiffres, courbe + invite scrubber, montant complet dans l'historique (intitulé long en ellipse — comportement de liste assumé, détail complet à l'ouverture) |
| `l9-390-plus.png` | hub par intentions, 11 destinations vivantes |
| `l9-390-bills/recurring/taxes/insurance/networth/goals/year/importcsv/assistant/settings.png` | les 10 destinations du hub ouvertes une à une |
| `l9-390-action-universelle.png` | menu du ＋ (choix rapides) au-dessus de l'Accueil |
| `l9-390-ajouter-montant-long.png` | feuille avec 1234567.89 saisi : champ lisible, 7 types, statut « Comptabilisé », Annuler/Enregistrer persistants |
| `l9-320-mois.png` / `l9-320-networth.png` | 320 px : héros et Patrimoine 7 chiffres lisibles, décomposition, projection, zéro débordement |
| `l9-390-hors-ligne.png` | rechargement HORS LIGNE réussi (service worker actif sur https local) : l'app se rend entièrement depuis le cache |

Note d'environnement (pas un défaut de l'app) : le sélecteur natif
`<input type="date">` du navigateur d'audit s'affiche en locale en-US
(« 07/25/2026 ») faute de locale fr installée dans le conteneur ; tous
les textes RENDUS PAR L'APP restent dd.MM.yyyy (visible dans
l'historique : « 25.07.2026 »). Sur un iPhone réglé fr-CH, ce sélecteur
suit la locale de l'appareil.
