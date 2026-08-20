---
name: budget-prisme
description: Piloter, auditer, simplifier, concevoir, développer, tester et publier l'application Budget PWA et iOS/SwiftUI page par page et détail par détail. Utiliser pour tout travail sur un écran, une feuille, un formulaire, un texte, un bouton, un parcours, un calcul, une sauvegarde, l'accessibilité, le design Budget Prisme, GitHub, la CI, Pages ou TestFlight, en gardant une langue française simple et la vérité financière intacte.
---

# Budget Prisme

## Mission

Faire progresser Budget par unités courtes, vérifiables et compréhensibles.
Traiter une page comme un produit complet : question utilisateur, données,
textes, contrôles, états, erreurs, accessibilité, persistance et preuves.

Ne jamais « refaire toute l'app » dans un diff massif. Transformer une demande
large en backlog ordonné, choisir une seule page, la terminer verticalement,
puis s'arrêter.

## Choisir le mode

- `audit <page>` : inspecter sans modifier; livrer défauts, risques et preuves.
- `plan <page>` : produire le Page Work Order et le diff prévu, sans coder.
- `execute <page>` : livrer une page et ses feuilles directement possédées.
- `continue` : reprendre le premier critère incomplet du statut courant.
- `verify <page>` : ne rien ajouter; tester, rendre, comparer et qualifier.
- `prompt <page>` : rédiger un prompt Claude Code autonome, sans exécuter.
- `release web` : suivre la CI du SHA exact, Pages puis l'app publique.
- `release testflight` : suivre le workflow natif et ses approbations propres.
- `release appstore` : préparer puis suivre la soumission App Store séparée.

Si la demande est ambiguë, commencer par `audit` puis `plan`. Une correction
financière ou de données reste un lot séparé d'une refonte visuelle.
Si le statut contient déjà un lot actif non bloqué, utiliser `continue` et ne
pas ouvrir une autre page. Un plan n'autorise pas automatiquement `execute` :
respecter le mode demandé et l'approbation indiquée dans le Page Work Order.

## Établir la vérité courante

Avant toute décision :

1. Résoudre le dépôt `Mendestrading21/Budget-`, la branche, le HEAD et la CI.
2. Afficher `pwd`, `git status --short --branch`, `git rev-parse HEAD` et le diff.
3. Lire `CLAUDE.md`, l'en-tête et la ligne active de
   `BUDGET_PRISME_STATUS.md`, puis les ADR du périmètre dans `DECISION_LOG.md`.
4. Lire le code, les tests et les workflows actuels; ne jamais se fier à un
   ancien SHA, un ancien total de tests ou une ancienne branche écrits ailleurs.
5. Préserver tout changement non lié dans le worktree.

Dans un dépôt qui possède `.claude/skills/budget-prisme/`, traiter cette copie
repo-locale comme l'autorité la plus récente pour Claude Code.

Pour les catalogues de services ou d'établissements, banques, courtiers,
assureurs, logos, monogrammes et cadences locales CH/FR/BE, charger aussi
`.claude/skills/budget-identites-locales/SKILL.md`. Ce compagnon complète le
travail; le présent skill conserve l'autorité sur la vérité financière, les
données, le design, les preuves et la publication.

## Charger seulement les références utiles

- Toujours pour une page : [PAGE_REGISTRY.md](references/PAGE_REGISTRY.md) et
  [PAGE_WORKFLOW.md](references/PAGE_WORKFLOW.md).
- Pour tout texte, état ou libellé : [LANGUAGE.md](references/LANGUAGE.md).
- Pour calcul, modèle, formulaire financier, import, restauration ou
  persistance : [FINANCE_DATA.md](references/FINANCE_DATA.md).
- Avant de clore un lot : [QUALITY_EVIDENCE.md](references/QUALITY_EVIDENCE.md).
- Pour branche, PR, fusion ou publication :
  [GITHUB_RELEASE.md](references/GITHUB_RELEASE.md).
- Pour une interface : lire aussi
  `docs/neon-ultra/budget-prisme/STYLE.md`, ADR-032 et la constitution active.
- Pour les règles visuelles affinées par ADR-032, `STYLE.md` prévaut sur les
  ratios historiques de la constitution; consigner toute autre contradiction.
- Pour un geste ou une animation : utiliser `/apple-design` comme compagnon;
  Budget Prisme garde l'autorité sur palette, hiérarchie, données et texte.

## Travailler page par page

Considérer comme une page : écran, sous-écran, feuille, formulaire, dialogue,
étape d'onboarding ou état de verrouillage. Une page principale peut inclure
uniquement ses feuilles directement déclenchées. Extraire une primitive
partagée dans un micro-lot Fondation si elle change plusieurs pages.

Pour chaque lot :

1. Identifier l'ID `P00`–`P18` et la question unique de la page.
2. Inventorier vues, fonctions, services, modèles, stockage et tests touchés.
3. Écrire un Page Work Order avant toute édition.
4. Lire la page de haut en bas et essayer chaque contrôle; ne jamais déduire
   son fonctionnement de son seul libellé.
5. Définir le résultat visible, les non-objectifs, les fichiers autorisés,
   les invariants et les critères mesurables.
6. Ajouter d'abord un test rouge pour tout défaut de vérité, de persistance ou
   de sécurité reproductible.
7. Implémenter le plus petit lot vertical; réutiliser tokens et composants.
8. Vérifier les états vide, partiel, normal, erreur et extrême.
9. Exécuter les tests ciblés puis toutes les suites applicables.
10. Ouvrir réellement le rendu, l'inspecter aux tailles imposées et conserver
    les preuves avant/après.
11. Mettre à jour le statut sans transformer les anciens rapports en journal.
12. Produire un commit/une PR ciblés, puis s'arrêter.

## Protéger le produit

Conserver sans exception :

- `Decimal` de bout en bout sur iOS et aucun zéro inventé;
- `fr-CH`, CHF natif, dates et signes explicites;
- planifié distinct de comptabilisé;
- épargne et investissement distincts du coût de la vie;
- transfert interne et mise de côté avec destination neutres pour le patrimoine;
- capital de dette distinct des intérêts et frais;
- occurrence récurrente liée et idempotente;
- fiscalité à source unique;
- historique monétaire figé selon le taux enregistré;
- validation complète avant remplacement d'une sauvegarde;
- données locales, confidentialité, offline et absence de fausse banque/IA;
- identifiants, migrations, clés, formats et historique utilisateur.

Si un lot visuel révèle un défaut financier, arrêter ce lot, consigner un P0
séparé et construire une fixture rouge. Ne jamais corriger une formule en
passant pour faire correspondre une maquette.

`P0` désigne ici un incident prioritaire transversal, jamais la page `P00`.
L'incident préempte tout lot actif : préserver le diff, marquer ce lot `BLOCKED`
avec la cause, puis ouvrir `agent/prisme-p0-<slug>`. Reprendre le visuel seulement
depuis le SHA de merge du P0, après approbation propriétaire et CI push verte.

## Appliquer Budget Prisme

- Une question principale et une action principale maximum par viewport.
- Graphite mat majoritaire; arête cyan-violet-magenta rare.
- Montants blancs, tabulaires, sans glow ni gradient.
- Vert, corail et ambre exclusivement sémantiques.
- Budget Glyphs, jamais un nouvel emoji fonctionnel ou une métaphore locale.
- Cartes répétées mates; pas de reflet, blur lourd ou carte dans la carte.
- Cibles de 44 px/pt, contraste AA, texte agrandi, VoiceOver/lecteur d'écran,
  Reduce Motion et Reduce Transparency.
- Composition originale Budget; ne copier aucun écran, texte, logo ou actif
  d'une application de référence.
- Pour toute référence tierce, consigner les principes généraux retenus, ce qui
  a été explicitement exclu, la provenance/licence des actifs éventuels et un
  contrôle final d'originalité.

## États de suivi

Utiliser exactement :

`READY → IN_PROGRESS → VERIFYING_AUTOMATED → WAITING_VISUAL → APPROVED`

Ajouter `PUBLISHED` seulement après vérification publique, ou `BLOCKED` avec
la cause exacte. Ne jamais confondre code écrit, PR verte, fusion et publication.

## Conditions d'arrêt

Arrêter et demander une décision si :

- la page exige de changer un modèle, une migration, une clé ou une formule
  hors du lot annoncé;
- deux plateformes racontent des vérités différentes et aucune ADR ne tranche;
- des données réelles seraient nécessaires dans un test, une capture ou un log;
- une permission GitHub, un secret, une signature ou une approbation manque;
- le rendu ne peut pas être inspecté ou la suite canonique ne peut pas être
  exécutée/confirmée par la CI;
- l'utilisateur n'a pas explicitement autorisé fusion ou publication.

## Rapport obligatoire

Terminer avec :

1. résultat utilisateur;
2. page et état de suivi;
3. fichiers modifiés;
4. textes, boutons et états contrôlés;
5. tests/builds et totaux réellement observés;
6. captures inspectées;
7. invariants financiers et données confirmés;
8. SHA/PR/déploiement exacts, s'ils existent;
9. risques et contrôles humains restants;
10. prochaine page précise, sans la commencer.
