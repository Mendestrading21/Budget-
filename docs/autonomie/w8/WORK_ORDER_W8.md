# Page Work Order : W8 — Investissements et modules régionaux

Écrit en mode `plan` (aucun code) à la fermeture de W7 (`main` inclut
W7.1–W7.7). Il n'autorise ni implémentation, ni fusion : `execute W8`
prend W8.1.

## Autorités

`WORK_BREAKDOWN.md` (W8.1–W8.7), `FINANCIAL_INVARIANTS.md` (FI-16
taux datés et sourcés, FI-17 jamais de 1:1 inventé, FI-19 l'historique
ne bouge pas quand un taux change, FI-18/FI-34 unités mineures),
ADR-047/INV1 (les positions EXPLIQUENT le solde du compte titres,
jamais additionnées), ADR-036 (rente ≠ capital), ADR-035 (aucune
estimation fiscale dérivée d'un taux), ADR-060 (patrimoine par compte),
ADR-065 (porte unique `enregistrerTaux`), C3/C4 (prévoyance liée,
poches disjointes). Mesure complète de l'existant : agent d'état des
lieux du 26.08.2026 (résumée ci-dessous, réconciliée avec le code).

## Problème utilisateur (mesuré)

- La courbe de patrimoine convertit les soldes des 12 derniers mois
  au taux de change COURANT (`renderNetWorth`, `fortuneTotale`) :
  changer un taux réécrit rétroactivement l'histoire des STOCKS,
  alors que les mouvements, eux, sont estampillés (FI-19 respecté
  seulement à moitié). `S.fxQuotes` (append-only, daté, sourcé)
  existe depuis W4.2 mais n'est JAMAIS lu pour convertir.
- Actifs, dettes, prévoyances et primes d'assurance n'ont AUCUNE
  devise : un bien en EUR est silencieusement compté comme du CHF.
- Un actif n'a qu'un couple `(value, valueDate)` écrasé à chaque
  édition : la courbe 12 mois le traite comme constant — fausse dès
  la première revalorisation.
- Les positions de titres sont saines (INV1, parité native) mais
  aveugles : `priceCurrency` stocké jamais lu, `costBasis` manuel,
  aucune plus-value affichée (la formule n'existe qu'en commentaire),
  aucun lien avec les mouvements.
- L'écran Impôts est un additionneur honnête (revendiqué : « L'app ne
  calcule aucun impôt à votre place ») mais le modèle natif
  (`TaxProfile`/`TaxProvision`/`TaxService` : échéances, arriérés,
  provision) n'est pas porté côté web.
- Assurances : 5 champs web contre 13 natifs ; l'UI annonce « chaque
  trimestre » mais `insuranceMonthly` ne connaît que mois/année ;
  aucun lien prime ↔ engagements du mois.
- Activation régionale : semis + 4 étiquettes + 1 phrase fiscale +
  filtre catalogue. Aucun module activable par pays.
- Le runner canon aplatit les taux datés (`canon.test.mjs` : dernier
  taux gagne, date ignorée, `Number()` flottant) : FI-16 n'est prouvé
  qu'au niveau du schéma, pas du moteur.

## Résultat mesurable

Un taux consigné un jour donné convertit les stocks À PARTIR de ce
jour et jamais avant (courbe de patrimoine datée, `tauxAuJour`) ; un
actif/une prévoyance/une prime porte sa devise ou est compté honnête
(bandeau d'incomplétude, jamais de 1:1 inventé) ; un actif garde son
HISTORIQUE de valorisations (append-only) et la courbe le raconte ;
une position affiche sa plus-value HONNÊTE (valeur − prix d'achat
saisi, jamais une promesse de cours) ; l'écran Impôts porte échéances
et provision à la manière du natif SANS calculer d'impôt ; les
assurances connaissent leur genre et leur vraie cadence ; le canon
prouve les taux datés dans le MOTEUR.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Périmètre |
|---|---|---|
| W8.1 | Cash flows d'investissement : `contributions()` réconcilié (un achat de titres depuis le compte titres n'est pas un « retrait »), versements nets par compte exposés à l'écran du compte | domaine + UI |
| W8.2 | Positions : plus-value affichée (valeur − `costBasis` saisi, absente si `costBasis` absent — jamais de zéro inventé) ; date de saisie du prix TOUJOURS montrée ; `priceCurrency` enfin lu | domaine + UI |
| W8.3 | Valorisations/FX datés : `tauxAuJour(devise, date)` lit `S.fxQuotes` ; courbes de patrimoine converties au taux DU MOIS ; historique de valorisations d'actif (clé additive append-only) ; devise sur actif/dette/prévoyance (additif, défaut = base) ; runner canon durci (dates lues, unités mineures) + fixture « taux absent → incomplet » différée depuis W1.5 | domaine + fixtures |
| W8.4 | Performance honnête : par compte d'investissement, « versé − retiré − valeur actuelle » raconté en français simple ; AUCUN TWR/IRR ni annualisation V1 ; jamais un chiffre sans sa méthode écrite | domaine + UI |
| W8.5 | Impôts : échéances datées (acomptes à venir/en retard) et provision de l'année portées du natif (`TaxProvision`), additionneur conservé, ADR-035 intact (aucun barème, aucun calcul) | modèle + UI |
| W8.6 | Assurances/prévoyance : genre de contrat, cadence réelle (mois/trimestre/semestre/année, `premiumIntervalCount` du natif), échéance de résiliation ; pilier typé côté prévoyance ; C3/ADR-036 intacts | modèle + UI |
| W8.7 | Activation régionale : les écrans nomment les véhicules du pays (3a/LPP vs PER vs épargne-pension) via `L()` étendu ; le catalogue et les semis suivent ; PAS de nouveau pays ni de nouvelle devise V1 | langage + UI |

## Stratégie (ADR-058, reconduite)

Clés et modèles ADDITIFS (un état d'avant W8 se charge tel quel, une
sauvegarde W8 restaurée sur l'existant écarte proprement les clés
inconnues via la restauration additive) ; portes uniques avec refus
nommés ; chaque sous-lot : mesure, test né rouge, sabotage qui mord
seul, suites, captures si UI, statut. Le natif est la RÉFÉRENCE de
modèle pour W8.5/W8.6 (on porte, on n'invente pas) ; pour W8.3 le web
ouvre la voie et le natif consigne l'écart s'il ne suit pas dans le
lot.

## Non-objectifs

Pas de connexion bancaire ni de cours de marché (aucun fournisseur,
« no fake live data ») ; pas de lots FIFO/PRU ni de fiscalité des
placements V1 ; pas de TWR/IRR ; pas de nouveau pays ni de nouvelle
devise ; pas de conseil fiscal ou d'assurance personnalisé ; les
montants historiques ne bougent JAMAIS rétroactivement.

## Décisions propriétaire à poser

1. W8.3 : la devise d'un actif existant reste-t-elle la devise de
   base par défaut (recommandé, honnête et additif) ou faut-il forcer
   une confirmation par actif au premier chargement ?
2. W8.4 : la performance V1 = « versé − retiré − valeur actuelle »
   racontée (recommandé) ou faut-il déjà un taux annualisé ?
3. W8.5 : porter la provision fiscale du natif (échéances + montant
   réservé, recommandé) ou garder l'additionneur seul ?

## Preuves exigées

Chaque sous-lot : mesure d'abord, test né rouge (échecs nommés),
sabotage qui mord seul, captures 320/390 inspectées si UI, suites
complètes vertes (e2e, parités, canon + schéma, design, catalogue,
audits), CI verte sur HEAD exact, fusion squash, publication au SHA,
statut consigné avec run ids.
