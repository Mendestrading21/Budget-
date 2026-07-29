---
name: budget-master-evolution
description: Auditer, planifier et faire évoluer le dépôt Mendestrading21/Budget- lot par lot avec Claude Code. Utiliser pour toute reprise, refonte, correction, simplification UX, évolution financière, design, test, migration, PWA, SwiftUI/SwiftData, TestFlight ou préparation App Store de Budget. Imposer une logique financière exacte, une interface compréhensible par un enfant de 10 ans, la parité contrôlée web/natif, un commit et une CI verte par lot, et un suivi durable de l'avancement.
---

# Budget Master Evolution

## Mission

Transformer Budget en tableau de bord financier grand public : simple au premier regard, puissant à la demande, fiable sur chaque montant. Faire travailler Claude Code par lots fermés et vérifiables. Ne jamais lancer une refonte globale non testée.

## Sources de vérité

Lire au début de chaque nouvelle session :

1. PROJECT_STATUS.md, DECISION_LOG.md et AUDIT_COMPLET_BUDGET_2026-07-21.md.
2. Le présent skill et references/01-current-audit.md.
3. references/06-lot-roadmap.md, puis uniquement les références nécessaires au lot actif.
4. Le code réel et les tests. En cas de contradiction, vérifier le comportement avant de modifier la documentation.

Considérer l'app native comme source de vérité pour les données, la sécurité et les règles financières. Considérer la PWA comme produit utilisable et laboratoire UX. Toute évolution doit déclarer : natif, web, ou les deux, avec une décision explicite de parité.

## Démarrage obligatoire

1. Inspecter le dépôt, la branche, le statut Git et les changements existants.
2. Préserver tout travail utilisateur non lié.
3. Exécuter les tests de référence avant modification, ou consigner précisément pourquoi ils ne peuvent pas tourner.
4. Créer ou reprendre BUDGET_MASTER_STATUS.md avec le modèle de references/08-progress-template.md.
5. Choisir exactement un lot READY dans references/06-lot-roadmap.md.
6. Écrire ses critères d'acceptation dans le statut avant de coder.

Ne pas demander à l'utilisateur de redéfinir les décisions déjà documentées. Demander seulement lorsqu'un choix commercial, réglementaire, bancaire, de prix ou de suppression de données change réellement la trajectoire.

## Boucle d'exécution d'un lot

Pour chaque lot :

1. **Observer** — ouvrir les fichiers, exécuter le parcours, relever les dépendances et risques.
2. **Cadrer** — limiter le lot à un résultat utilisateur cohérent ; écrire les invariants et critères.
3. **Concevoir** — appliquer les références produit, finance et design.
4. **Implémenter** — faire la plus petite modification complète. Ajouter une migration avant toute évolution persistée.
5. **Tester** — tests unitaires des règles, E2E du parcours, erreurs, vides, accessibilité et données existantes.
6. **Inspecter** — vérifier visuellement sur la taille iPhone cible ; contrôler boutons, libellés, graphiques et états.
7. **Documenter** — mettre à jour statut, décisions et audit seulement si le comportement réel a changé.
8. **Committer** — un commit dédié, message clair, aucun fichier sans rapport.
9. **Pousser et surveiller** — attendre tous les jobs CI ; corriger jusqu'au vert.
10. **Clore** — marquer le lot DONE avec preuves, risques résiduels et prochain lot recommandé.

Ne jamais annoncer « terminé » avec une CI rouge, un bouton factice, un test ignoré sans justification ou une validation appareil encore requise.

## Règles produit non négociables

- Répondre en moins de dix secondes à : reçu, dépensé, reste à payer, mis de côté, patrimoine.
- Garder cinq destinations principales maximum.
- Afficher l'essentiel d'abord ; replier les fonctions avancées.
- Permettre l'action principale en trois gestes maximum après ouverture.
- Employer des mots du quotidien. Appliquer le test « 10 ans ».
- Ne jamais confondre dépense, épargne, investissement, virement, impôt ou remboursement de dette.
- Ne jamais présenter une estimation comme une certitude.
- Ne jamais ajouter un bouton de connexion bancaire sans intégration réelle et gestion du consentement.
- Ne jamais utiliser un emoji aléatoire comme seul moyen de comprendre une donnée.

## Discipline financière

Lire references/03-finance-invariants.md avant tout changement de modèle, calcul, import, budget, impôt, devise, compte, dette, objectif ou patrimoine.

Bloquer le lot si un invariant n'est pas démontré par test. Utiliser Decimal dans le natif. Dans la PWA, migrer progressivement vers les centimes entiers ; ne pas étendre les calculs en nombres flottants.

## Design et pictogrammes

Lire references/04-design-icon-system.md pour tout travail UI.

- Utiliser des pictogrammes vectoriels propres à Budget pour navigation et opérations.
- Utiliser les emojis Unicode comme accents humains, catégories ou célébrations.
- Conserver vert positif, rouge négatif, orange attention, bleu action/information.
- Réutiliser tokens, composants, rayons, espacements, typographie et graphiques.

## Architecture

Lire references/05-technical-architecture.md avant un lot structurel.

- Ne pas continuer à grossir webapp/index.html sans décision de découpage.
- Garder les règles financières hors des vues.
- Partager des fixtures de parité entre web et natif.
- Versionner toute donnée persistée et tester la migration depuis l'état précédent.
- Ne pas sacrifier l'offline-first ni introduire une dépendance sans justification documentée.

## Vérifications minimales

Lire references/07-quality-gates.md. Au minimum :

- exécuter node webapp/tests/e2e.test.mjs pour un lot web ;
- exécuter build Debug, tests natifs et build Release pour un lot natif ;
- tolérer zéro erreur console ;
- vérifier sauvegarde/restauration et handlers interactifs ;
- vérifier VoiceOver, clavier, taille de texte et viewport iPhone.

## Choix du prochain lot

Suivre les dépendances de references/06-lot-roadmap.md. Prioriser :

1. perte de données, calcul faux, sécurité, crash ;
2. parcours quotidien et compréhension ;
3. cohérence web/natif et maintenabilité ;
4. design et rétention ;
5. croissance, connexions et monétisation.

Ne pas commencer deux lots simultanément. Ne pas ouvrir un lot de connexion bancaire avant les portes de décision prévues.

## Références

- references/01-current-audit.md — état réel et risques.
- references/02-product-ux.md — langage, navigation et test 10 ans.
- references/03-finance-invariants.md — conventions et cas limites.
- references/04-design-icon-system.md — identité, emojis et graphiques.
- references/05-technical-architecture.md — données, migrations et parité.
- references/06-lot-roadmap.md — programme détaillé.
- references/07-quality-gates.md — définition de fini.
- references/08-progress-template.md — pilotage durable.
- references/09-page-blueprints.md — contenu de chaque écran.
