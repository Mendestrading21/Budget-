# Quality Gates

## Avant édition

- dépôt/branche/HEAD/CI identifiés ;
- issue #70 et P0 lus ;
- lot READY ;
- worktree préservé ;
- code/tests/ADR actuels lus ;
- Page Work Order ;
- donnée réelle interdite.

## Domaine

- invariant nommé ;
- test rouge ;
- fixtures Web/iOS ;
- arrondi/devise/date injectés ;
- erreur typée ;
- contrôle négatif ;
- aucun fallback silencieux.

## Persistance

- transaction atomique ;
- rollback ;
- retry/idempotence ;
- contraintes uniques ;
- erreur de stockage visible ;
- migration testée ;
- backup/restore si modèle ;
- données existantes intactes sur rejet.

## UI

- une question/action focales ;
- états vide/partiel/normal/erreur/extrême ;
- textes simples et vrais ;
- aucun montant tronqué ;
- 320/390 et tailles cibles ;
- clair/sombre/système ;
- Dynamic Type/zoom ;
- clavier/VoiceOver ;
- mouvement/transparence réduits ;
- focus et undo.

## Web

- e2e navigateur réel ;
- zéro erreur console tolérée ;
- CSP ;
- offline première installation/mise à jour ;
- quota/échec persistance ;
- multi-onglets ;
- routes/retour/deep link ;
- aucune donnée sensible cache/URL/log.

## iOS

- build Debug et Release ;
- tests unitaires/UI applicables ;
- vrai store disque ;
- migration versions publiques ;
- manifeste de confidentialité ;
- app switcher ;
- verrou/ré-authentification ;
- appareil réel avant release.

## Sécurité

- secret/dependency scan ;
- threat model mis à jour ;
- import/backup hostile ;
- chiffrement standard ;
- fichiers protégés ;
- logs nettoyés ;
- suppression/export ;
- déclarations stores revues.

## GitHub

- diff ciblé ;
- pas de refonte + migration mélangées ;
- commit propre ;
- PR avec preuves ;
- threads résolus ;
- CI HEAD puis main ;
- tags immuables ;
- fusion autorisée ;
- publication autorisée séparément.

## Release NO-GO automatique

Échec si : prévu modifie solde, doublon possible, écritures déséquilibrées,
devise sans taux, mouvement rapproché mutable, migration non prouvée, backup
mensonger, restore destructif, persistance silencieuse, parité rouge,
accessibilité/sécurité/QA manquante, déclarations inexactes ou SHA ambigu.

## Rapport de preuve

```text
Lot / état
Base SHA / head SHA / branche / PR
Résultat utilisateur
Fichiers
Invariants
Migration / rollback
Tests ciblés
Suites complètes
Contrôle négatif
Captures / accessibilité
Sécurité / confidentialité
CI / publication
Risques humains
Prochaine action exacte
```
