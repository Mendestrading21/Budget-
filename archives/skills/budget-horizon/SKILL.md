---
name: budget-horizon
description: Auditer, repenser, refondre et finaliser entièrement Budget selon la vision Horizon, tout en conservant sa logique métier, ses données et ses fondations saines. Utiliser pour une refonte complète ou une modification importante du produit, de l'architecture UX, des écrans, widgets, animations, graphiques, textes, onboarding, PWA, app iOS SwiftUI, calculs financiers suisses, accessibilité, tests ou préparation à la publication.
---

# Budget Horizon — skill maître

## Mission

Faire de Budget l'application de finances personnelles la plus simple,
rassurante et désirable pour un foyer suisse, sans sacrifier la fiabilité.
Ne pas produire seulement un plan : inspecter, implémenter, tester et documenter.

L'utilisateur doit comprendre en moins de dix secondes :

1. combien il peut réellement utiliser ;
2. ce qui reste à payer ce mois ;
3. où part son argent ;
4. ce qu'il met de côté ;
5. sa prochaine action utile.

## Démarrage obligatoire

Avant toute modification :

1. Exécuter `git status --short --branch` et préserver tout travail existant.
2. Lire `CLAUDE.md`, `PROJECT_STATUS.md` et `DECISION_LOG.md`.
3. Inspecter le code, les tests et le diff réels ; ne jamais se fier uniquement
   aux documents.
4. Lire les références adaptées :
   - produit et parcours : [PRODUCT.md](references/PRODUCT.md) ;
   - identité Horizon : [HORIZON_DESIGN.md](references/HORIZON_DESIGN.md) ;
   - refonte complète : [FULL_REFACTOR.md](references/FULL_REFACTOR.md) ;
   - widgets et mouvement : [WIDGETS_AND_MOTION.md](references/WIDGETS_AND_MOTION.md) ;
   - écrans cibles : [SCREEN_BLUEPRINTS.md](references/SCREEN_BLUEPRINTS.md) ;
   - références visuelles : [VISUAL_REFERENCES.md](references/VISUAL_REFERENCES.md) ;
   - invariants financiers : [FINANCE_AND_DATA.md](references/FINANCE_AND_DATA.md) ;
   - exécution et gates : [DELIVERY.md](references/DELIVERY.md).
5. Pour une tâche spécialisée, compléter avec les documents de
   `.claude/skills/budget-v1/references/` et les références visuelles.
6. Déterminer le premier critère incomplet à forte valeur et commencer.

## Source de vérité et périmètre

- Le domaine financier natif iOS est la source de vérité des règles métier.
- La PWA est un produit réellement utilisable, installable et hors ligne ; elle
  ne doit pas promettre une capacité qu'elle ne possède pas.
- iOS et PWA partagent vocabulaire, hiérarchie, design tokens et invariants,
  sans imposer une copie pixel par pixel.
- Conserver l'architecture saine et les données existantes. Ne jamais
  recommencer l'application depuis zéro.
- La V1 est locale, privée, CHF et `fr-CH`. Toute expansion pays/devise doit être
  explicite, complète et approuvée.

## Contrat produit non négociable

- Une personne sans connaissance financière, y compris un enfant de dix ans,
  doit comprendre les actions principales.
- Une idée principale par écran ; chiffres avant explications ; détails à la
  demande.
- Accueil court : disponible réel, tendance, priorité, quatre actions rapides
  maximum, état du mois, budget, objectif et alertes importantes.
- Navigation cible : `Mois`, `Mouvements`, `Budget`, `Comptes`, `Plus`.
- Aucun bouton mort, écran inaccessible, faux chargement ou donnée de démo
  présentée comme réelle.
- Toute recommandation indique pourquoi elle apparaît et mène à une action.
- Préférer les mots quotidiens : « Disponible », « À payer », « Mis de côté »,
  « Patrimoine ». Garder le jargon dans la documentation technique.

## Direction Horizon

Appliquer l'identité « Swiss calm fintech » déjà engagée : claire par défaut,
sombre premium, lumineuse, calme, chaleureuse et précise.

- Utiliser exclusivement les tokens sémantiques partagés.
- Cartes arrondies, glass discret, ombres douces, respiration généreuse.
- Couleur = information : vert favorable, rouge alerte, accents maîtrisés.
- Graphiques pédagogiques avec résumé textuel et méthode compréhensible.
- Emojis ou illustrations seulement s'ils améliorent l'orientation ou le
  plaisir ; jamais comme décoration envahissante.
- Éviter l'esthétique crypto/casino, les dégradés agressifs, la densité de
  widgets et les effets sans fonction.
- Vérifier clair, sombre, contraste, 320 px, Dynamic Type, VoiceOver,
  réduction des animations et de la transparence.

La simplicité ne doit jamais produire une interface vide, générique ou fade.
Chaque écran possède un point focal vivant, des micro-interactions cohérentes et
une profondeur maîtrisée. Les widgets doivent être utiles, manipulables et
personnalisables sans demander au nouvel utilisateur de construire son accueil.

Lire [HORIZON_DESIGN.md](references/HORIZON_DESIGN.md),
[WIDGETS_AND_MOTION.md](references/WIDGETS_AND_MOTION.md) et
[VISUAL_REFERENCES.md](references/VISUAL_REFERENCES.md) avant toute UI.

## Refonte totale sans régression

Une demande de refonte complète autorise à réorganiser navigation, pages,
composants, textes et présentation, mais jamais à jeter la logique existante.

1. Cartographier l'existant : écrans, actions, modèles, calculs, persistance,
   tests, PWA et SwiftUI.
2. Classer chaque élément : conserver, améliorer, fusionner, déplacer,
   remplacer ou supprimer avec preuve d'inutilité.
3. Définir l'architecture cible et les critères de migration avant les grandes
   suppressions.
4. Construire les fondations partagées avant de refaire les écrans.
5. Migrer verticalement un parcours complet à la fois.
6. Retirer l'ancien code seulement après preuve de parité, absence d'usage et
   tests verts.

Lire [FULL_REFACTOR.md](references/FULL_REFACTOR.md) pour exécuter une refonte
système de bout en bout.

## Invariants financiers et données

- Utiliser `Decimal` pour l'argent natif, jamais `Float` ou `Double`.
- Séparer planifié, comptabilisé, disponible, épargne, investissement,
  provisions, dettes et patrimoine.
- Un virement interne est neutre pour revenus, dépenses, cash-flow et
  patrimoine.
- Épargne et investissement ne sont pas des dépenses de vie.
- Un remboursement de capital diminue cash et dette ; seuls intérêts/frais sont
  des dépenses.
- Aucune double comptabilisation, aucun mélange de devises implicite, aucun
  `NaN` ou infini.
- Toute estimation affiche méthode, hypothèses et caractère non garanti.
- Toute mutation utilisateur doit gérer l'échec, restaurer un état cohérent et
  afficher un message honnête.
- Aucune suppression silencieuse. Sauvegardes, restaurations et migrations sont
  versionnées et testées transactionnellement.
- Ne jamais intégrer de données financières personnelles réelles dans le code,
  les previews, les captures ou les logs.

Lire [FINANCE_AND_DATA.md](references/FINANCE_AND_DATA.md) pour modifier modèles,
services, agrégats, import/export, impôts, dettes ou patrimoine.

## Boucle d'exécution

Travailler par tranche verticale courte : modèle/règle, interface, états,
accessibilité, tests et documentation.

Pour chaque lot :

1. écrire les critères d'acceptation observables ;
2. ajouter ou adapter les tests avant une règle financière sensible ;
3. implémenter sans étendre inutilement le périmètre ;
4. exécuter les tests ciblés puis la suite applicable ;
5. inspecter visuellement le parcours réel ;
6. vérifier vide, chargement, erreur, succès et données volumineuses ;
7. mettre à jour `PROJECT_STATUS.md` et, si nécessaire, `DECISION_LOG.md` ;
8. créer un commit cohérent si l'environnement et l'autorisation le permettent ;
9. poursuivre le lot suivant tant qu'aucun choix produit bloquant n'existe.

Ne jamais affirmer qu'un test, build, appareil ou déploiement est validé sans
preuve directe. Si Xcode est indisponible, le dire et utiliser la CI macOS ; ne
pas transformer l'absence d'outil en validation.

## Ordre de priorité

1. Perte de données, calcul faux, sécurité, crash, régression de persistance.
2. Parcours principal bloqué, bouton mort, incohérence iOS/PWA.
3. Compréhension, navigation, accessibilité et performance perceptible.
4. Cohérence Horizon et qualité visuelle.
5. Fonctionnalités nouvelles et préparation commerciale.

## Autorisations

Autonome pour analyser, coder, tester et documenter dans la branche de travail.
Demander une décision seulement pour : prix, conseil réglementé, service tiers,
collecte/synchronisation cloud, vraie multi-devise, suppression de données,
fusion, déploiement production, TestFlight ou App Store.

Ne jamais fusionner, publier, déployer, supprimer une branche ou effectuer une
action externe irréversible sans autorisation explicite.

## Fin de lot

Rendre un bilan bref et vérifiable : résultat, fichiers principaux, tests
réellement exécutés, risques restants et prochaine action exacte.
