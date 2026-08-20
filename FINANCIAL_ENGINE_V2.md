# Financial Engine V2 — cahier d'exécution

Décision propriétaire (18.08.2026, message d'audit complet). Ce document est
la transcription opérationnelle de son cahier « Financial Engine V2 ». Il
prime sur les anciens libellés de l'accueil.

**Amendement ADR-035 (20.08.2026)** : « ne calcule pas les impôts
automatiquement — toutes les données, c'est moi qui dois les rentrer. »
L'« effort fiscal du mois » du cahier initial est SUPPRIMÉ : la projection
n'a plus aucun terme fiscal automatique, et la page Impôts additionne ce que
l'utilisateur a noté (paiements, envois « Impôts », report, acomptes en
factures). Les règles ci-dessous se lisent avec cet amendement. La règle
d'or :

> Ne jamais présenter une projection comme de l'argent possédé.

## Les cinq chiffres (vocabulaire imposé)

| Vue | Signification | Formule (mouvements `posted` sauf mention) |
| --- | --- | --- |
| Disponible maintenant | Argent réellement présent, utilisable au quotidien | soldes des comptes `cash` (courant + espèces) |
| Épargne accessible | Argent réellement présent sur les comptes d'épargne | soldes des comptes `savings` |
| Fortune liquide | Disponible maintenant + épargne accessible | somme des deux |
| Prévu fin de mois | Projection : solde actuel + revenus attendus − sorties encore attendues (ADR-035 : aucun terme fiscal automatique) | l'ancien `available`, corrigé |
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
2. **Aucun impôt automatique (remplacée par ADR-035).** La version du
   18.08 soustrayait un « effort fiscal du mois » dérivé d'un taux. Depuis
   le 20.08, PLUS AUCUN montant d'impôts n'est dérivé : un acompte pèse sur
   le mois par sa facture ou son mouvement prévu, comme toute sortie
   saisie. Un taux hérité encore stocké est lettre morte.
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
  `savingsAccessible`, `liquidWealth`, `endOfMonthForecast`), suppression
  de la promotion automatique par date. Tests rouges d'abord ; les tests
  qui validaient l'ancien comportement sont réécrits EN MÊME TEMPS que le
  moteur. (L'agrégat `taxMonthlyEffort` du cahier initial a vécu du 18 au
  20.08, puis a été retiré par ADR-035.)
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
