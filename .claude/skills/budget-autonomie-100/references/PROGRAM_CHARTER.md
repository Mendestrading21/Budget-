# Program Charter — Budget Autonomie 100

## Vision

Budget devient une application de finances personnelles destinée au grand
public, locale par défaut, explicable, accessible et publiable. Elle répond aux
besoins simples sans sacrifier la justesse du moteur.

## Résultat attendu

Une personne peut :

- suivre plusieurs comptes ;
- distinguer argent réel, prévu et à confirmer ;
- confirmer revenus, factures et abonnements ;
- comprendre mois et année ;
- planifier budgets, réserves et objectifs ;
- suivre placements, actifs et dettes sans double compte ;
- importer, rapprocher, exporter, restaurer et supprimer ses données ;
- utiliser l'app avec assistance, hors ligne et sans connaissance comptable.

## Contraintes

- iOS et PWA existent déjà et doivent rester utilisables pendant la migration ;
- aucune donnée existante perdue ;
- aucune réécriture massive ;
- aucune fonction bancaire ou Android inventée ;
- modules suisses au-dessus d'un cœur universel ;
- confidentialité et accessibilité intégrées ;
- chaque vérité financière testée sur les deux plateformes.

## Mesures de succès

- zéro scénario connu où prévu change un solde ;
- zéro confirmation dupliquée sous retry ;
- 100 % des fixtures canoniques identiques Web/iOS ;
- 100 % des versions publiques migrables ;
- tous les transferts équilibrés ;
- aucune somme multi-devise sans conversion datée ;
- restauration corrompue non destructive ;
- aucune action critique sans résultat/erreur visible ;
- WCAG 2.2 AA Web et QA VoiceOver signée ;
- release gates vertes sur un SHA exact.

## Hors périmètre initial

- conseil financier ou fiscal officiel ;
- trading/exécution d'ordres ;
- initiation de paiement ;
- IA autonome ;
- publicité ;
- vente de données ;
- synchronisation cloud/collaboration avant chiffrement et conflits ;
- Android avant décision W11.

## Gouvernance

Le propriétaire décide : formule ambiguë, politique de devise, technologie
Android, fournisseur bancaire, cloud, clé de backup, fusion et publication.

Claude Code décide dans le cadre approuvé : implémentation minimale, tests,
refactor local, documentation et preuves.

Toute décision durable devient ADR. Toute preuve est liée à un SHA.
