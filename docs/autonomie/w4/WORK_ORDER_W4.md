# Page Work Order : W4 — Comptes, devises, rapprochement

Écrit en mode `plan` (aucun code) à la fermeture de W3 (journal
complet, `main` inclut W3.1–W3.7). Il n'autorise ni implémentation, ni
fusion : `execute W4` prendra W4.1. La décision propriétaire
« politique multi-devise V1/V2 » (matrice W0.5) bloque W4.2 et sera
posée à ce moment-là.

## Problème utilisateur

Aujourd'hui un taux de change est un nombre nu dans `fxRates`, sans
date ni source (FI-16 OUVERT) ; un taux absent peut faire disparaître
une valeur au lieu de la marquer incomplète (FI-17 OUVERT) ; le
patrimoine natif additionne sans conversion datée (enAttenteNatif :
`devise-conversion-datee`, `comptes-par-devise`) ; le point de
rapprochement (`reconciledBalance`) est une propriété de compte sans
relevé ni preuve (le comparateur W3.6b le consigne « en attente
W4 ») ; un compte archivé ne verrouille pas ses rapports passés par un
test dédié (FI-13 PARTIEL) ; les biens et dettes n'affichent pas
systématiquement « valeur au… » (FI-27 PARTIEL).

## Résultat mesurable

Chaque conversion porte montant + devise + taux + source + date
(FI-15/16) ; un taux absent rend un état « incomplet » nommé, jamais 1
ni 0 (FI-17) ; l'historique garde ses taux (FI-19 — déjà protégé côté
PWA par l'estampille, à contractualiser en fixtures) ; le
rapprochement devient un RELEVÉ (statement) avec état
brouillon/rapproché et différence zéro ou ajustement explicite ; les
écritures rapprochées deviennent immuables (FI-07 complet) ; archivage
et patrimoine datés/sourcés — prouvé par fixtures canoniques v2 et les
deux runners.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Périmètre |
|---|---|---|
| W4.1 | Typologie des comptes : aligner les types cible (cash/checking/savings/creditCard/loan/brokerage/pension/wallet/other*) sur les deux plateformes, migration additive, aucun changement d'agrégat | modèles |
| W4.2 | FX : `FxQuote` (base, quote, taux décimal, observedAt, source) + politique V1/V2 (décision propriétaire) ; taux absent = état incomplet nommé (FI-17) ; fixtures `devise-conversion-datee` et `comptes-par-devise` sortent d'`enAttenteNatif` | domaine + fixtures |
| W4.3 | Statements : le relevé (période, soldes d'ouverture/clôture, état brouillon/rapproché) remplace le point nu `reconciledBalance` — migration du point existant en relevé synthétique marqué | modèles + migration |
| W4.4 | Réconciliation : rapprocher une écriture (lifecycle `cleared`/`reconciled` du journal W3), différence zéro ou ajustement explicite, écriture rapprochée immuable | domaine + journal |
| W4.5 | Dettes/cartes : le compte `creditCard`/`loan` raconte capital et interêts sans double compte (FI-14 gardé), lien avec les mensualités `r-debt-` | domaine |
| W4.6 | Archivage : un compte archivé garde l'histoire, rapports passés verrouillés par test (FI-13 → TENU) | domaine + tests |
| W4.7 | Patrimoine : chaque valeur datée/sourcée (« valeur au… », FI-27 → TENU), agrégats multi-devise via quotes datées seulement, état « incomplet » visible | agrégats + UI minimale |

## Stratégie de migration (ADR-058, reconduite)

Chaque nouveau modèle (quote, relevé) naît en PARALLÈLE et additif ;
les vues gardent l'ancien chemin jusqu'à preuve par comparateur ; le
point de rapprochement existant est migré en relevé synthétique
CLAIREMENT marqué (jamais deviné) ; rollback = clés additives + ancien
chemin intact.

## Non-objectifs

Pas d'allumage de la lecture des soldes journal (décision
propriétaire, ADR-064) ; pas de connexion bancaire ni de cours de
marché (FI-38) ; pas de refonte des pages (W5) ; pas de règles
d'import (W7) ; pas de positions d'investissement (W8).

## Décisions à trancher

1. **Politique multi-devise V1/V2 (bloque W4.2)** : V1 = devise de
   base unique + conversions datées affichées ; V2 = agrégats
   multi-devises complets. À poser au propriétaire au moment de W4.2.
2. Migration du point de rapprochement existant (W4.3) : relevé
   synthétique daté du `reconciledAt` — proposition par défaut,
   consignée à la PR.

## Preuves exigées

Chaque sous-lot : test rouge d'abord, contrôle négatif qui mord seul,
fixtures des deux côtés quand une vérité change (schema v2 si besoin),
migration testée sur store disque, suites complètes, CI verte sur HEAD
exact, statut consigné avec run ids.
