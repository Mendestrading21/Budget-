# Financial Engine V2 — cahier d'exécution

Décision propriétaire (18.08.2026, message d'audit complet). Ce document est
la transcription opérationnelle de son cahier « Financial Engine V2 ». Il
prime sur les anciens libellés de l'accueil. La règle d'or :

> Ne jamais présenter une projection comme de l'argent possédé.

## Les cinq chiffres (vocabulaire imposé)

| Vue | Signification | Formule (mouvements `posted` sauf mention) |
| --- | --- | --- |
| Disponible maintenant | Argent réellement présent, utilisable au quotidien | soldes des comptes `cash` (courant + espèces) |
| Épargne accessible | Argent réellement présent sur les comptes d'épargne | soldes des comptes `savings` |
| Fortune liquide | Disponible maintenant + épargne accessible | somme des deux |
| Prévu fin de mois | Projection : solde actuel + revenus attendus − sorties encore attendues − effort fiscal du mois | l'ancien `available`, corrigé (voir impôts) |
| Fortune totale actuelle | Tous les actifs réels − toutes les dettes réelles | formule du Patrimoine (comptes + biens + prévoyance − dettes) — source unique |

Stock ≠ flux : « Mis de côté ce mois » (flux) ne s'additionne jamais à
« Épargne actuelle » (stock).

## Les trois règles correctives

1. **Aucune comptabilisation automatique par date.** Une opération `planned`
   dont la date est passée devient « à confirmer » / « en retard » — jamais
   `posted` sans geste. `promoteDuePlannedTransactions` disparaît (PWA) ;
   même règle côté Swift (`TransactionPostingPolicy` reste pour le STATUT
   INITIAL d'une saisie manuelle datée d'aujourd'hui ou avant — saisir une
   dépense d'hier crée bien un mouvement comptabilisé, c'est un geste).
2. **L'écart fiscal ANNUEL ne pèse plus sur le mois.** La projection du mois
   soustrait seulement l'« effort fiscal du mois » : taux × revenus du mois
   (comptabilisés + attendus) − mises de côté « Impôts » du mois, plancher 0.
   L'écart annuel reste dans Impôts (et la priorité du mois peut le nommer).
3. **Un seul patrimoine.** La fortune totale a UNE formule (celle du
   Patrimoine / NetWorthService). Aucun autre agrégat ne s'appelle
   « patrimoine » ou « fortune » avec une autre formule.

## Écrans

- **Mois** : la grande carte a deux positions — « Maintenant » (Disponible
  maintenant, avec sous-titre « Sur vos comptes utilisables au quotidien »)
  et « Fin du mois » (Prévu fin de mois, avec la décomposition écrite :
  maintenant + à recevoir − à sortir). Le trio Reçu/Dépensé/Mis de côté reste
  strictement comptabilisé.
- **Comptes** : Disponible maintenant (héros), Fortune totale (carte
  cliquable → Patrimoine), répartition et groupes existants (épargne,
  placements, prévoyance), dettes visibles dans le Patrimoine.
- **Épargne (vue du Patrimoine/Comptes)** : Épargne actuelle (stock) ·
  mis de côté ce mois (flux) · mis de côté cette année (flux).
- **Patrimoine** : Fortune liquide ET Fortune totale ensemble.

## Lots

- **FE2-0** — Moteur PWA : agrégats explicites (`availableNow`,
  `savingsAccessible`, `liquidWealth`, `endOfMonthForecast`,
  `taxMonthlyEffort`), suppression de la promotion automatique par date,
  effort fiscal mensuel. Tests rouges d'abord ; les tests qui validaient
  l'ancien comportement sont réécrits EN MÊME TEMPS que le moteur.
- **FE2-1** — Écrans PWA : carte deux positions, Comptes, vue Épargne,
  Patrimoine (fortune liquide + totale). Captures avant/après.
- **FE2-2** — Parité Swift : mêmes agrégats dans MonthlySnapshotService,
  `NetWorthService` source unique (le champ `netWorth` du MonthSnapshot qui
  ne totalise que les comptes est retiré ou réaligné), suppression de la
  promotion automatique native, tests réécrits.
- **FE2-3** — Fixtures de parité : fixture n° 6 (revenu attendu + impôts +
  épargne) vérifiée à l'identique web et natif ; documentation du statut.

Chaque lot suit la discipline : test rouge → correctif → contrôle négatif →
suites complètes → captures → PR → CI verte sur le HEAD exact → squash →
publication au SHA exact.
