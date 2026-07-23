---
name: budget-v1
description: Piloter, refondre, continuer, auditer et vérifier Budget sur iOS et PWA. Utiliser pour tout travail important sur l'application, notamment la refonte Obsidian Glass, les écrans, widgets, graphiques, interactions, règles financières, données, tests, accessibilité, confidentialité et préparation App Store.
argument-hint: "[plan|execute|continue|verify] [L0-L9 ou périmètre]"
disable-model-invocation: true
user-invocable: true
effort: max
allowed-tools: Read Write Edit Grep Glob Bash
---

# Budget V1 — directeur de produit et de refonte

## Mission

Faire de Budget une application de finances personnelles suisse simple,
fiable, désirable et compréhensible en moins de dix secondes. Conserver les
fonctions et les données existantes. Ne jamais recommencer le produit depuis
zéro pour obtenir un nouveau visuel.

Le programme actif est **Budget — Obsidian Glass**. Il remplace les anciennes
directions visuelles et constitue l'unique feuille de route opérationnelle.

Mode demandé : **$ARGUMENTS**

## Charger le contexte obligatoire

Avant toute action, lire :

1. `CLAUDE.md`
2. `OBSIDIAN_GLASS_STATUS.md`
3. `PROJECT_STATUS.md`
4. `DECISION_LOG.md`
5. [OBSIDIAN_GLASS_CONSTITUTION.md](references/OBSIDIAN_GLASS_CONSTITUTION.md)
6. [OBSIDIAN_GLASS_DELIVERY.md](references/OBSIDIAN_GLASS_DELIVERY.md)
7. [OBSIDIAN_GLASS_SCREEN_MATRIX.md](references/OBSIDIAN_GLASS_SCREEN_MATRIX.md)
8. [REFERENCE_INDEX.md](references/REFERENCE_INDEX.md)

Selon le lot, charger ensuite uniquement les références nécessaires :

- Produit : [PRODUCT_VISION.md](references/PRODUCT_VISION.md)
- Architecture : [ENGINEERING_CONTRACT.md](references/ENGINEERING_CONTRACT.md)
  et [ARCHITECTURE.md](references/ARCHITECTURE.md)
- Finance et données : [DATA_MODEL_AND_RULES.md](references/DATA_MODEL_AND_RULES.md)
- Parcours : [FUNCTIONAL_SPEC.md](references/FUNCTIONAL_SPEC.md)
- Qualité : [QUALITY_PLAN.md](references/QUALITY_PLAN.md)
- Publication : [RELEASE_AND_GROWTH.md](references/RELEASE_AND_GROWTH.md)

Pour tout travail d'interface, ouvrir réellement les images sélectionnées dans
`REFERENCE_INDEX.md`. Ne pas se contenter de leurs noms.

## Interpréter la commande

### `plan`

Inspecter le dépôt, les tests, les captures et le lot demandé. Produire les
critères d'acceptation et le diff prévu. Ne pas lancer une refonte générale.

### `execute Lx`

Exécuter uniquement le lot `Lx` décrit dans
`OBSIDIAN_GLASS_DELIVERY.md`. Terminer le lot verticalement : code, états,
tests, rendu, captures, documentation et commit. S'arrêter ensuite.

### `continue`

Lire `OBSIDIAN_GLASS_STATUS.md`, vérifier le code et la CI, puis reprendre le
premier critère incomplet du lot actif. Ne pas répéter un lot terminé.

### `verify`

Ne pas ajouter de fonction. Construire, tester, vérifier visuellement et
produire les preuves demandées pour le lot ou l'écran indiqué.

Si la commande est ambiguë, choisir l'action la plus conservatrice. Pour un
grand chantier inconnu, planifier. Si un lot est déjà actif, le terminer.

## Sécurité du dépôt

Avant chaque modification :

1. exécuter `pwd` et `git status --short --branch`;
2. confirmer la branche `refonte/budget-obsidian-glass-v1`;
3. inspecter le diff et préserver tout travail non lié;
4. lire le code, les tests et les décisions réelles;
5. identifier les commandes de build et de test depuis la CI;
6. annoncer les critères d'acceptation du lot.

Ne jamais utiliser de commande Git destructive. Ne jamais modifier la branche
par défaut, fusionner, déployer ou publier sans autorisation explicite.

## Contrat financier non négociable

- `Decimal` de bout en bout dans l'app native; jamais `Double` pour l'argent.
- Format `fr-CH`, dates `dd.MM.yyyy`, montants explicables.
- Planifié et comptabilisé restent distincts.
- Épargne et investissement ne sont pas des dépenses de vie.
- Un virement interne est neutre pour revenu, dépense, cash-flow et patrimoine.
- Un remboursement de capital réduit le cash et la dette sans créer une dépense;
  intérêts et frais restent séparés.
- Aucune devise n'est additionnée sans conversion explicite et historisée.
- Un taux actuel ne réécrit jamais l'historique.
- Une restauration invalide ne modifie aucune donnée et ne transforme jamais
  silencieusement une valeur invalide en zéro.
- Aucun échec de persistance ne peut être ignoré.
- Aucun calcul fiscal, délai ou donnée réelle ne doit être inventé.
- Aucun conseil financier personnalisé ni promesse de connexion bancaire.

Tout P0 confirmé sur les données, la restauration, la confidentialité ou la
publication bloque le passage au lot visuel suivant.

## Contrat UX

Chaque écran doit répondre à une question principale et proposer une action
évidente. Utiliser les mots « Disponible », « À payer », « Dépensé », « Mis de
côté » et « Patrimoine ». Garder le jargon technique hors de l'interface.

L'Accueil doit permettre de comprendre en dix secondes :

1. l'argent réellement disponible;
2. ce qui est entré et sorti;
3. ce qui reste à payer ou à réserver;
4. l'état du budget;
5. la prochaine action utile.

Navigation cible : `Mois`, `Mouvements`, `Budget`, `Comptes`, `Plus`.
L'action la plus fréquente doit être accessible en un ou deux gestes. Aucun
bouton mort, faux chargement ou donnée de démonstration présentée comme réelle.

## Contrat Obsidian Glass

- Une seule identité sombre, sans thème clair décoratif.
- Fond Obsidienne `#090C12`.
- Surface verre Graphite autour de `rgba(20, 25, 37, 0.72)`.
- Accent de marque unique Indigo Aurora `#7367FF`.
- Vert, corail et ambre uniquement pour leur sens financier.
- Chiffres très lisibles, cartes aérées, profondeur mesurée.
- Graphiques pédagogiques avant les effets.
- Widgets utiles et persistants; jamais de gadget ou d'animation permanente.
- Emojis ou pictogrammes chaleureux en petites touches, jamais comme seul sens.
- VoiceOver, Dynamic Type, contrastes, cibles de 44 points, reduced motion et
  reduced transparency obligatoires.

La constitution détaillée prévaut sur toute ancienne référence Horizon ou
multi-thème.

## Boucle d'exécution obligatoire

Pour chaque lot :

1. observer l'état réel;
2. écrire le résultat utilisateur et les critères mesurables;
3. protéger les invariants et prévoir les migrations;
4. créer ou adapter les composants réutilisables;
5. implémenter tous les états utiles : vide, chargé, erreur, montant long,
   contenu long et clavier;
6. ajouter les tests ciblés;
7. exécuter les tests puis la suite applicable;
8. rendre et inspecter sur iPhone étroit et courant;
9. comparer avant/après;
10. vérifier accessibilité, mouvement et transparence réduits;
11. mettre à jour `OBSIDIAN_GLASS_STATUS.md` et les décisions;
12. produire un commit ciblé et s'arrêter.

## Gates de qualité

Un lot n'est terminé que si :

- l'app ou la PWA concernée fonctionne réellement;
- les tests ciblés et la suite applicable sont verts;
- aucune erreur console ni crash connu n'est introduit;
- les chiffres se réconcilient avec les fixtures existantes;
- le rendu est vérifié, pas seulement décrit;
- l'écran fonctionne à 320 px et sur un iPhone courant;
- les états vide, erreur et données extrêmes sont traités;
- VoiceOver/Dynamic Type ou équivalents web sont couverts;
- reduced motion et reduced transparency ont un comportement correct;
- les captures avant/après sont conservées;
- le statut indique preuves, risques et prochain lot exact.

Ne jamais déclarer « 10/10 », « terminé » ou « prêt App Store » tant qu'une
validation iPhone réel, une migration, la confidentialité ou une exigence de
publication reste non vérifiée.

## Rapport de fin de lot

Répondre avec :

1. résultat utilisateur livré;
2. fichiers modifiés;
3. tests et builds exécutés avec résultats;
4. captures produites;
5. invariants contrôlés;
6. risques ou blocages réels;
7. commit du lot;
8. prochain prompt exact, sans commencer le lot suivant.

