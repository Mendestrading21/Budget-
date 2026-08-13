# Modèle BUDGET_MASTER_STATUS.md

## En-tête

- Date UTC
- Branche et SHA
- Jalon actif
- Lot actif
- Dernière CI verte
- Bloqueurs humains

## Tableau

| Lot | Statut | Commit | Tests | Résultat utilisateur | Risque |
|---|---|---|---|---|---|

Statuts : BLOCKED, READY, IN_PROGRESS, VERIFYING, DONE.

## Fiche du lot actif

### Problème observé

Décrire comportement, fichier et preuve.

### Résultat utilisateur

Une phrase sans jargon.

### Périmètre

Lister inclus et exclus.

### Invariants

Lister les règles qui ne changent pas.

### Critères d'acceptation

Cases observables et testables.

### Fichiers touchés

Mettre à jour après implémentation.

### Vérifications

Commandes, résultats, captures et CI.

### Décisions et risques

Compromis, migrations, différences web/natif et validations humaines.

### Prochain lot

Un seul lot recommandé et la raison.
