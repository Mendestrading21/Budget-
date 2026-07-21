# État de référence du dépôt

## Résumé

Le dépôt contient une app iOS SwiftUI/SwiftData et une PWA installable. Le natif possède la meilleure architecture, précision monétaire et sécurité. La PWA est immédiatement utilisable et sert de laboratoire UX, mais repose sur un fichier monolithique et localStorage.

## Forces confirmées

- Cinq onglets : Accueil, Mouvements, Budget, Comptes, Plus.
- Onboarding progressif, foyer solo/couple/famille, pays CH/FR/BE.
- Comptes, transactions, budgets, paiements réguliers, factures, impôts, objectifs, assurances, prévoyance, actifs, dettes, documents et import/export.
- Virements neutres, épargne distincte des dépenses, dette décrémentée.
- SwiftData local, sauvegarde versionnée, biométrie native et fichiers protégés.
- CI web et native, tests unitaires, navigateur et tour simulateur.

## Problèmes structurants

1. L'accueil web enchaîne trop de sections.
2. Le vocabulaire contient encore liquidités, récurrents, comptabiliser, réconcilier, provision, variance et hors budget.
3. webapp/index.html dépasse 4 000 lignes et mélange état, calculs, rendu et interactions.
4. La PWA utilise des nombres JavaScript pour l'argent ; le natif utilise Decimal.
5. Les données PWA vivent dans localStorage, non chiffré.
6. Les deux implémentations peuvent diverger sans fixtures partagées.
7. La QA appareil réel et la migration d'un store existant restent humaines.
8. Sans connexion bancaire, saisie et import doivent être exceptionnellement simples.

## Risques prioritaires

| Niveau | Risque | Réponse |
|---|---|---|
| P0 | Perte lors d'une migration/restauration | Round-trip et store ancien |
| P0 | Résultat différent web/natif | Fixtures de parité |
| P1 | Arrondis flottants PWA | Centimes entiers |
| P1 | Abandon à cause de la densité | Accueil essentiel |
| P1 | Sécurité PWA mal comprise | Texte honnête + sauvegarde |
| P1 | Monolithe web fragile | Découpage progressif |
| P2 | Menu Plus trop long | Groupement par intention |
| P2 | Emojis hétérogènes | Glyphes + accents Unicode |
