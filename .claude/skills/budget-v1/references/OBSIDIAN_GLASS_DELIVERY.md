# Budget — Livraison Obsidian Glass

## Règle de programme

Exécuter un seul lot à la fois. Chaque lot possède un commit, des tests, des
captures et une mise à jour de `OBSIDIAN_GLASS_STATUS.md`. Ne jamais commencer
le lot suivant dans la même session.

## Gates transverses

Avant toute refonte générale, revalider les cinq risques critiques du dernier
audit :

1. vérité Git et branche de release;
2. restauration native : aucune valeur invalide transformée en zéro;
3. historique PWA : aucun recalcul rétroactif par un taux actuel;
4. présence réelle de `PrivacyInfo.xcprivacy` dans le bundle;
5. URLs, bundle ID et métadonnées App Store réels et cohérents.

Un P0 confirmé concernant perte de données, confidentialité ou corruption bloque
la poursuite visuelle tant qu'il n'est pas corrigé et testé.

## L0 — Gouvernance et autorité

Objectif : créer une branche isolée, un seul skill canonique, une constitution,
une matrice d'écrans et un statut unique.

Acceptation :

- branche `refonte/budget-obsidian-glass-v1`;
- `CLAUDE.md` pointe uniquement vers `/budget-v1`;
- les anciens skills sont explicitement historiques;
- aucune logique applicative modifiée;
- prochain lot indiqué.

## L1 — Vérité, baseline et P0

Objectif : confirmer l'état réel avant de dessiner.

Actions :

- inventorier PWA, iOS, composants, tokens, routes, tests et workflows;
- vérifier les cinq P0 sur le code courant;
- corriger seulement les P0 confirmés, avec tests;
- produire des captures avant sur 320 px, iPhone courant et simulateur natif;
- mesurer contraste, densité, temps de rendu et erreurs console;
- remplir la matrice d'état des écrans;
- proposer le diff exact de L2.

Interdit : refondre les écrans pendant l'inventaire.

## L2 — Fondations Obsidian

Objectif : créer le système réutilisable sans dérouler toute l'application.

PWA :

- tokens CSS sémantiques;
- fond, glass, typographie, montants, boutons, champs, badges et feuilles;
- fallback reduced transparency;
- règles reduced motion et focus clavier.

iOS :

- tokens SwiftUI équivalents;
- primitives `GlassCard`, `AmountText`, `StatusPill`, boutons et feuilles;
- environnement accessibilité et réduction de transparence.

Acceptation :

- galerie ou preview déterministe des composants;
- aucune valeur brute répétée hors tokens;
- contraste vérifié;
- aucune régression fonctionnelle;
- tests et build verts.

## L3 — Pilote PWA

Objectif : valider la direction sur trois parcours avant tout déploiement large.

Écrans :

1. `Mois` / Accueil;
2. `Budget`;
3. feuille `Ajouter un mouvement`.

Acceptation :

- hiérarchie conforme à la matrice;
- états vide, rempli, erreur, montant long et clavier;
- parcours création + reload persistant;
- 320 px et mobile courant;
- screenshots avant/après;
- zéro erreur console;
- suite e2e et parité vertes;
- arrêt pour validation humaine.

## L4 — Pilote iOS

Objectif : porter le pilote validé sans modifier les règles financières.

Écrans :

1. `Mois` / Accueil;
2. `Budget`;
3. feuille `Ajouter un mouvement`.

Acceptation :

- composants SwiftUI partagés;
- previews déterministes;
- Dynamic Type, VoiceOver, reduced motion/transparency;
- build Debug et Release;
- tests financiers inchangés et verts;
- captures simulateur avant/après;
- arrêt pour validation humaine.

## L5 — Mouvements et Comptes

Objectif : rendre le quotidien rapide et tactile.

Inclut :

- liste, recherche, filtres et détail mouvement;
- création, édition, duplication, suppression et erreurs;
- liste et détail compte;
- réconciliation, archivage et fraîcheur du solde;
- action universelle contextuelle.

Acceptation : aucun bouton mort, actions en un ou deux gestes, historique
préservé, erreurs de sauvegarde visibles, tests CRUD/persistance verts.

## L6 — Factures, objectifs, impôts et patrimoine

Objectif : expliquer le futur et la situation globale sans surcharge.

Inclut :

- factures et charges annuelles;
- objectifs et scénarios;
- impôts avec hypothèses;
- patrimoine, actifs, dettes, prévoyance et assurances;
- graphiques pédagogiques et résumés accessibles.

Acceptation : calculs réconciliés, aucune double comptabilisation, aucune donnée
fiscale inventée, cas sans données et séries constantes traités.

## L7 — Onboarding, Plus, réglages et confiance

Objectif : guider un nouvel utilisateur et regrouper les fonctions secondaires.

Inclut :

- onboarding en moins de deux minutes;
- hub `Plus` par intentions;
- documents, import/export, sauvegarde/restauration;
- verrouillage, confidentialité, méthodologie;
- états destructifs et confirmations.

Acceptation : texte compréhensible à dix ans, comportement web/natif décrit
honnêtement, aucune suppression silencieuse, reprise après erreur.

## L8 — Widgets, graphiques et micro-interactions

Objectif : ajouter de la vie utile après stabilisation des parcours.

Inclut :

- composition de widgets;
- éventuelle personnalisation persistante et réversible;
- tooltips et sélection de graphiques;
- haptique et transitions;
- états de succès sobres;
- performance des listes et matériaux.

Acceptation : aucune animation infinie, aucune perte de lisibilité, reduced
motion/transparency vérifiés, 60 fps visés sur appareils supportés.

## L9 — Audit 10/10 et préparation réelle

Objectif : vérifier le produit complet sans auto-déclarer la perfection.

Inclut :

- audit écran par écran et bouton par bouton;
- suite web, native, UI, parité, Debug et Release;
- migration sur store disque;
- QA iPhone réel;
- privacy manifest et métadonnées App Store;
- captures finales;
- dette technique et risques résiduels;
- décision explicite sur ce qui dépend d'un humain.

Sortie :

- score détaillé avec preuves;
- aucun P0 ouvert;
- P1 corrigés ou justifiés;
- checklist humaine distincte;
- aucune publication sans autorisation.

## Format de preuve par lot

```text
Lot:
Résultat utilisateur:
Fichiers:
Tests/builds:
Captures:
Accessibilité:
Invariants:
Risques:
Commit:
Prochaine commande:
```

