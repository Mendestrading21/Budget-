# Page Work Order : W2 — Occurrences persistées

Écrit en mode `plan` (aucun code) pendant le train de fusion W1. Il
n'autorise ni implémentation, ni fusion : `execute W2` prendra W2.1
quand W1 (fixtures + runners) sera entièrement fusionné.

## Problème utilisateur

Aujourd'hui une échéance récurrente n'existe pas : elle est recalculée
en mémoire et « couverte » par comptage mensuel (constat n° 4 de
l'audit). Conséquences réelles : une date passée peut devenir un
mouvement comptabilisé par déduction (FI-02 OUVERT), un double tap peut
confirmer deux fois (FI-04 OUVERT), le montant attendu se perd quand on
confirme un autre montant (FI-05 PARTIEL).

## Résultat mesurable

Une échéance est un OBJET persisté avec identité, état
(`scheduled · due · matchProposed · confirmed · skipped · snoozed ·
cancelled · failed` — glossaire W0), lien vers son mouvement, montant
attendu conservé, clé d'idempotence — sur les DEUX plateformes, prouvé
par fixtures canoniques v2 et par les suites existantes inchangées.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Périmètre |
|---|---|---|
| W2.1 | Modèles : `ScheduledOccurrence` natif (SwiftData, migration additive V11) + forme miroir PWA (clé additive `occurrences`) ; AUCUNE lecture par les vues | modèles + migration + tests de persistance |
| W2.2 | Génération/calendrier : matérialiser les occurrences du mois depuis les récurrences (idempotent — régénérer ne duplique JAMAIS, FI-03) | services |
| W2.3 | États et transitions du glossaire W0 (machine à états testée, refus des transitions interdites) | domaine |
| W2.4 | Confirmation atomique : « Reçu/Payé » écrit mouvement + occurrence dans UNE transaction, avec idempotency key (double tap = une écriture, FI-04) ; montant attendu conservé à part du montant réel (FI-05) | domaine + persistance |
| W2.5 | match/skip/snooze/cancel : reporter/ignorer ne crée AUCUN mouvement | domaine + UI minimale |
| W2.6 | Factures ponctuelles = occurrences sans série (migration des `bills`) | modèles + migration |
| W2.7 | Pages et parité : l'inbox/le mois lisent les occurrences ; fixtures canoniques v2 (états) ; suites complètes | UI + fixtures |

## Stratégie de migration (ADR-058)

Modèle NOUVEAU en parallèle : les vues continuent de lire l'ancien
chemin pendant W2.1–W2.4 (shadow-write) ; un comparateur vérifie que
les occurrences matérialisées reproduisent exactement les compteurs
actuels (`recurringRemainingCount` ↔ occurrences ouvertes) avant toute
bascule de lecture (W2.7) ; rollback = feature flag, l'ancien chemin
reste intact jusqu'à preuve.

## Non-objectifs

Pas de journal (W3), pas de rapprochement bancaire (W4), pas de refonte
de « Ce qui revient », pas de notifications.

## Décisions à trancher (ADR attendues)

1. Politique de statut À LA SAISIE (FI-02) : une date passée saisie à
   la main propose « déjà payé ? » au lieu de le déduire — texte exact
   à valider propriétaire.
2. Fenêtre de matérialisation (combien de mois d'occurrences en
   avance).

## Preuves exigées

Chaque sous-lot : test rouge d'abord, contrôle négatif, fixtures des
deux côtés quand une vérité change, migration testée sur store disque,
suites complètes, CI sur HEAD exact, statut consigné.
