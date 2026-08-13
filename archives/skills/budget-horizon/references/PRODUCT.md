# Produit Budget

## Promesse

Budget transforme les finances du foyer en un rituel mensuel simple : voir,
valider, agir et progresser. L'application n'est ni une banque, ni un outil de
trading, ni un tableau comptable.

## Questions essentielles

Chaque écran doit servir au moins une question :

1. Que puis-je utiliser sans risque aujourd'hui ?
2. Qu'est-ce qui entre et sort encore ce mois ?
3. Mon budget est-il respecté ?
4. Que construis-je avec mon épargne et mes investissements ?
5. Quelle action améliore maintenant ma situation ?

## Architecture d'expérience

### Mois

- Disponible réel et décomposition accessible.
- Tendance courte, jamais une décoration.
- Check du mois : revenus, récurrents, factures, provisions.
- Une priorité explicable et actionnable.
- Quatre raccourcis maximum.
- Budget et objectif résumés.

### Mouvements

- Ajouter, modifier, dupliquer, supprimer avec confirmation adaptée.
- Recherche et filtres simples.
- Prévu/comptabilisé visuellement distinct.
- Source et destination explicites.
- Catégorisation rapide et file des non classés.

### Budget

- Planifié, réel, reste et hors budget réconciliés.
- Catégories compréhensibles et comparaisons utiles.
- Copie de mois sans doublon.
- Dépassement visible sans culpabilisation.

### Comptes

- Banque, espèces, épargne, courtier, 3a, actifs et dettes.
- Solde explicable, fraîcheur visible, historique et réconciliation.
- Transferts neutres ; contributions et performance séparées.

### Plus

Objectifs, factures, récurrents, impôts, patrimoine, assurances,
prévoyance, documents, import/export et réglages, groupés par intention.

## Onboarding

Maximum cinq étapes utiles : confidentialité, foyer, revenus principaux,
comptes initiaux et préférence essentielle. Toute étape doit pouvoir être
corrigée plus tard. Les données de démonstration sont un choix explicite.

## Intelligence honnête

Une recommandation doit être déterministe, expliquée et liée aux données
locales. Prioriser : échéance proche, déficit, provision manquante, mouvement
non catégorisé, objectif en retard. Ne jamais promettre un rendement ni imiter
un conseil financier personnalisé.

## Définition de terminé

Un module n'est terminé que lorsque ses parcours création/lecture/modification/
suppression pertinents, états vides, erreurs, persistance, accessibilité et tests
sont complets. Une jolie carte sans action ou sans données fiables n'est pas une
fonctionnalité.

