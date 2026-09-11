---
name: budget-notion-glass
description: Concevoir, construire et vérifier une page de budget personnel noire et vitrée, organisée comme un espace Notion lisible. Utiliser pour le dashboard Budget, sa vue du mois, ses tableaux, filtres et formulaires associés, avec Claude Code ou Codex. Dans Budget, compléter budget-prisme sans remplacer ses règles financières ni sa navigation.
---

# Budget Notion Glass

Construire une page qui répond immédiatement à : **« Que me reste-t-il et que dois-je encore faire ce mois ? »**

Retenir la clarté de Notion : titres simples, tableau précis, navigation stable, détails ouverts à la demande. Donner à cette organisation une matière noire et vitrée : profondeur discrète, lumière sur les arêtes, montants blancs et lisibles. Employer un français naturel, le format fr-CH et le CHF par défaut.

## Interpréter la demande

- Si la demande porte sur la création ou l’amélioration du skill lui-même, livrer le skill ; cela ne demande pas de modifier l’application.
- `design P01` : produire une référence interactive et le contrat de la page.
- `execute P01` : mener un audit ciblé, rédiger le périmètre, implémenter puis vérifier la page. Employer ce mode si l’utilisateur demande de construire la page.
- `verify P01` : vérifier le comportement, les données et le rendu sans élargir la page.
- `prompt P01` : rédiger un ordre de travail autonome pour Claude Code.
- `continue` : reprendre le premier critère non rempli de la tâche active, depuis les sources actuelles.

Les choix ordinaires de composition, de code et de correction appartiennent à l’agent. Quand l’exécution de la page est demandée, ne pas s’arrêter au plan ou entre chaque petite correction. Un objectif large ne demande pas de réécrire toute l’application : achever la page et ses interactions directement associées.

## Lire les ressources utiles

| Besoin | Ressource |
| --- | --- |
| Concevoir l’écran | [DESIGN.md](references/DESIGN.md) et [PAGE.md](references/PAGE.md) |
| Afficher ou calculer de l’argent | [FINANCE.md](references/FINANCE.md) |
| Reprendre des données Notion | [NOTION.md](references/NOTION.md) |
| Coder, vérifier et livrer | [DELIVERY.md](references/DELIVERY.md) |
| Observer la direction visuelle | [dashboard-reference.html](assets/dashboard-reference.html), via un serveur local |
| Réutiliser les tokens | [black-glass.css](assets/black-glass.css), à adapter au système existant |
| Examiner la démonstration | [reference-model.mjs](assets/reference-model.mjs) et [reference-ui.mjs](assets/reference-ui.mjs) |
| Vérifier les règles de la référence | `node scripts/check-reference.mjs` depuis ce dossier |

La référence est une maquette interactive à données **entièrement fictives**. Ses changements restent en mémoire. Elle n’est ni un export Notion, ni un moteur bancaire, ni une application terminée. Dans une application existante, conserver son moteur et son stockage ; ne pas les remplacer par ceux de la démonstration.

## S’intégrer au vrai projet

Dans `Mendestrading21/Budget-` :

1. Cibler explicitement `main` distant, puis établir HEAD, diff et état du lot. Ne pas prendre la branche par défaut comme preuve de la bonne base. Préserver les changements locaux.
2. Lire `CLAUDE.md`, le statut vivant, le plan des quatre familles et les décisions pertinentes. Charger la copie locale de `budget-prisme` ainsi que ses références nécessaires. Charger `budget-identites-locales` pour comptes, services et cadences.
3. Traiter ce skill comme un compagnon de conception de **P01 — Mois** et de ses feuilles. Garder les cinq destinations `Mois`, `Historique`, `Budget`, `Comptes`, `Gérer`, et les quatre familles `Rentrées`, `Dépenses`, `Abonnements`, `Mis de côté`.
4. Conserver les protections de données, le calcul, les identifiants, les imports et les procédures de publication. Ne pas réactiver un ancien programme « Obsidian Glass » ou « Neon Ultra » parce que son nom ressemble au style demandé.
5. Appliquer la demande explicite noir/verre à la page concernée. Consigner l’écart visuel au design existant dans son ordre de travail ; cette préférence ne réécrit pas le thème global. Garder le contraste, les montants sans glow, les glyphes du produit et le mode sans transparence.

Hors de ce dépôt, lire les conventions réellement présentes. Pour une création indépendante explicitement demandée, adapter les contrats à son architecture. L’absence d’un skill facultatif ne bloque pas le travail : utiliser les références fournies. Ne pas imposer React, Next.js, shadcn/ui ou un serveur pour reproduire cette esthétique.

## Construire une seule vérité visible

- Donner à chaque indicateur une définition, une période, une devise, un statut de complétude et une source de détail.
- Partager la sélection de mois entre les indicateurs, listes, graphes et actions concernées.
- Séparer argent reçu et attendu, payé et dû, dépense et transfert, patrimoine et disponible.
- Expliquer un montant en ouvrant les éléments qui le composent. Une donnée absente s’affiche « À renseigner » ou « Calcul incomplet », jamais comme un zéro certain.
- Garder les réserves fiscales manuelles ; un paiement fiscal et l’argent réservé ne sont pas deux paiements.
- Lier chaque confirmation de paiement à l’opération ou l’occurrence existante. Un deuxième clic ne doit pas créer un second paiement.
- Préserver la signification et le signe des montants, y compris négatifs et élevés.

## Composer et faire fonctionner

Sur ordinateur, utiliser une colonne principale pour le disponible, les mouvements et les explications ; une colonne secondaire pour les échéances et la mise de côté. Sur téléphone, placer le disponible puis les actions avant les détails. Les tableaux se réorganisent en lignes lisibles quand l’espace manque.

Garder une action principale « Ajouter une opération ». Rendre le changement de mois, la recherche, les filtres, les ouvertures de détail, les formulaires, leurs annulations et les erreurs réellement fonctionnels. Ne pas dessiner de boutons sans comportement. Respecter les dates futures et les restrictions du moteur existant.

Utiliser le verre pour le cadre, le panneau principal et les feuilles ; garder le fond des données suffisamment opaque. Le contenu financier prime sur les reflets. Ne pas introduire de jargon technique, score financier inventé, conseil fiscal automatique ou analyse IA simulée dans le parcours.

## Vérifier avant de livrer

Exécuter les contrôles adaptés de DELIVERY.md. Inspecter les captures à 1440, 1024, 390 et 320 px lorsque la mise en page change. Vérifier clavier, focus, texte agrandi, réduction des animations et transparence. Prouver les cas financiers pertinents avec des données fictives, puis vérifier le vrai enregistrement et la relecture si la page modifie des données.

Une erreur trouvée doit conduire à une correction et à sa preuve dans le périmètre autorisé. Une modification de modèle nécessaire se traite comme un lot de données explicite ; elle ne se dissimule pas dans le style. Demander une précision uniquement lorsqu’une décision métier ou une autorisation réellement manquante empêche de poursuivre sans inventer.

Conclure avec : résultat utilisable, page et périmètre, fichiers, comportements vérifiés, calculs contrôlés, captures inspectées, limites restantes et état réel de la livraison. Distinguer référence, code implémenté, testé, fusionné et publié. La création du skill ou de la page n’autorise pas à elle seule sa fusion ou sa publication.
