# Page Work Order : W5 — Architecture de l'information

Écrit en mode `plan` (aucun code) à la fermeture de W4 (`main` inclut
W4.1–W4.7). Il n'autorise ni implémentation, ni fusion : `execute W5`
prend W5.1.

## Autorité de navigation

**ADR-026 prévaut** : cinq destinations stables — `Mois`, `Historique`,
`Budget`, `Comptes`, `Gérer` — sans bouton d'ajout global. Le
vocabulaire générique de la charte (« Activité », « Plan », « Plus »)
se LIT comme Historique/Budget/Gérer ; aucune destination n'est
renommée sans décision propriétaire.

## Problème utilisateur

Le moteur sait désormais des choses que les pages ne disent pas : les
ÉCHÉANCES persistées (W2) ne sont lues par aucun écran (consigné
depuis W2.7b — « lecture par les pages → W5 ») ; les gestes Reporter/
Ignorer (W2.5) n'ont aucune surface ; les comptes archivés (W4.6)
s'affichent comme les autres ; les relevés (W4.3) sont invisibles.
L'interface promet moins que ce que le moteur tient — l'inverse du
risque classique, mais un manque réel.

## Résultat mesurable

Chaque destination répond à sa question avec ce que le moteur SAIT :
le Mois montre les échéances à confirmer (boîte de réception) avec les
VRAIS gestes de la machine à états ; les comptes archivés ont leur
place discrète ; chaque écran garde UNE action contextuelle (ADR-026) ;
zéro code mort prouvé à la fin.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Périmètre |
|---|---|---|
| W5.1 | Routes/navigation : inventaire mesuré des routes des deux côtés, verrouillage par test (5 destinations ADR-026, une action contextuelle par écran, retours stables) | tests + consignation |
| W5.2 | Mois : la boîte de réception du mois — les échéances persistées (dues/en retard) LUES par l'écran, confirmation par le geste existant | UI + lecture W2 |
| W5.3 | Historique (« Activité ») : lecture seule cohérente, corrections tracées visibles (chaîne W3.5 lisible) | UI |
| W5.4 | Budget (« Plan ») : projections au conditionnel, réel d'abord (ADR-055/056 confirmés à l'écran) | UI |
| W5.5 | Comptes : les archivés rangés à part (consigné W4.6), les relevés visibles (W4.3), fraîcheur | UI |
| W5.6 | Gérer (« Plus ») : réglages progressifs, taux datés visibles (W4.2) | UI |
| W5.7 | Inbox : la boîte de réception complète — échéances multi-mois, gestes Reporter/Ignorer (W2.5) enfin exposés | UI + domaine lu |
| W5.8 | Nettoyage prouvé : code mort retiré avec preuve (grep + tests), zéro régression | hygiène |

## Stratégie (ADR-058, reconduite)

Les écrans LISENT les modèles persistés (occurrences, relevés,
archivage) sans jamais écrire hors des portes existantes
(confirmation W2.4b, gestes W2.5, réconciliation W4.4). Aucune
bascule de source de vérité : les compteurs existants restent la
lecture par défaut tant que le comparateur W2.7a garde zéro écart —
chaque écran qui passe aux occurrences est prouvé par ce comparateur.

## Non-objectifs

Pas de nouvelle destination ni renommage (ADR-026) ; pas d'allumage du
journal (ADR-064) ; pas de notifications ; pas de règles d'import
(W7) ; pas de refonte visuelle (l'identité Prisme est stable).

## Décisions à trancher

1. Présentation des comptes archivés (W5.5) : section repliée « 
   Archivés » en bas de Comptes — proposition par défaut, consignée à
   la PR.
2. La boîte de réception (W5.2/W5.7) affiche les échéances DUES du
   mois d'abord ; la fenêtre multi-mois (combien d'avance) reste la
   décision W2 existante (fenêtre de matérialisation).

## Preuves exigées

Chaque sous-lot : mesure d'abord (captures avant), test né rouge,
sabotage qui mord seul, captures 320/390 inspectées, suites complètes,
CI verte sur HEAD exact, statut consigné avec run ids.
