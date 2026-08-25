# W0.2 — Glossaire des états

Contrat de vocabulaaire du programme Budget Autonomie 100. Chaque état a UN nom
technique, UN mot utilisateur français et UNE définition. Aucun écran, texte ou
test ne doit employer un autre mot pour le même état. Ce glossaire décrit le
présent (mesuré au SHA `bcef018`) et la cible (audit chapitre 03) — il ne
modifie aucun code.

## États d'un mouvement d'argent — AUJOURD'HUI (les deux plateformes)

| État technique | Mot à l'écran | Définition mesurée | Limite connue |
|---|---|---|---|
| `planned` | « Prévu » | Saisi ou engendré, l'argent n'a PAS bougé ; ne pèse sur aucun solde (`balance()` et `AccountBalanceService` ne lisent que `posted`). | Un seul état pour « prévu », « dû », « en retard » — la nuance vit dans les dates. |
| `posted` | « Reçu / Payé / Mis de côté / Transféré / Confirmé » (verbe par nature) | L'argent a bougé ; pèse sur le solde du compte. | La politique de saisie classe une date du jour ou passée directement `posted` (constat n° 3 de l'audit) : une date n'est pas une preuve. |

Il n'existe AUJOURD'HUI aucun état persisté pour : en attente bancaire, pointé,
rapproché, annulé, échoué. Une « occurrence » récurrente n'est pas un objet :
elle est recalculée en mémoire et considérée « couverte » par la présence d'un
mouvement portant son `recurringId` sur le mois (constat n° 4).

## États d'un mouvement — CIBLE (journal W3)

| État technique | Mot à l'écran | Définition |
|---|---|---|
| `draft`/`scheduled` | « Prévu » | Écrit, rien n'a bougé. |
| `pending` | « En attente » | Mouvement initié, preuve pas encore là. |
| `posted` | « Reçu / Payé » | Confirmé par action humaine explicite ou preuve. |
| `cleared` | « Pointé » | Vu sur le relevé bancaire. |
| `reconciled` | « Rapproché » | Attaché à un relevé clos ; IMMUABLE — correction par inversion/remplacement lié, jamais mutation. |
| `reversed` | « Annulé » | Inversé par une écriture liée qui garde l'histoire. |
| `failed` | « Échec » | Le mouvement n'a pas eu lieu ; visible, jamais silencieux. |

Transitions autorisées (audit ch. 03) : `draft → pending|posted|voided` ;
`pending → posted|failed|voided` ; `posted → cleared|reversed` ;
`cleared → reconciled|reversed` ; `reconciled → (reversal + nouvelle écriture)`.

## États d'une échéance récurrente — CIBLE (occurrences W2)

| État | Mot | Définition |
|---|---|---|
| `scheduled` | « Prévu » | Engendré par la série, pas encore dû. |
| `due` | « À confirmer » | La date est arrivée ; RIEN n'a bougé tant que personne ne confirme (règle centrale du skill). |
| `matchProposed` | « Proposé » | Un mouvement importé ressemble à l'échéance ; l'humain tranche. |
| `confirmed` | « Confirmé » | Lié à une écriture réelle, une seule fois (idempotent). |
| `skipped` | « Ignoré » | Passé volontairement, sans mouvement. |
| `snoozed` | « Reporté » | Décalé, sans mouvement. |
| `cancelled` | « Annulé » | La série s'arrête pour cette échéance. |
| `failed` | « Échec » | La confirmation n'a pas pu s'écrire ; l'échéance reste due. |

## Autres états existants (inchangés par W0)

| Objet | États mesurés | Notes |
|---|---|---|
| Facture ponctuelle (`bills`) | ouverte / couverte (`billIsCovered`) / en retard (`billIsOverdue`) | Cible : devient une occurrence sans série (W2.6). |
| Ajustement de solde | `adjustment` `up`/`down`, toujours `posted`, neutre | Déjà une correction traçable et datée ; conserve son sens dans le journal cible. |
| Compte | actif / archivé ; `cash` (disponible) ; `includeInNetWorth` | La typologie cible vit dans `DATA_MODEL_TARGET.md` (W4.1). |
| Mois | ouvert / bouclé (`monthChecks`) | Le bouclage est un rituel d'interface, pas un verrou comptable. |
| Objectif | actif / prioritaire / atteint / archivé | Inchangé. |

## Règle d'usage

- Un texte d'écran, un test ou une ADR qui parle d'un état DOIT employer le mot
  de ce glossaire.
- Introduire un nouvel état exige : ADR, entrée ici, fixtures W1 sur les deux
  plateformes.
- « Prévu » ne devient JAMAIS un mot de solde : un solde ne cite que des états
  `posted` ou plus avancés (FI-01, FI-11).
