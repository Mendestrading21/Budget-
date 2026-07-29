---
name: budget-neon-ultra
description: >
  Piloter le programme « Budget Neon Ultra » — refonte visuelle noir profond /
  magenta / violet / cyan de l'application Budget (PWA + iOS SwiftUI), lot par
  lot (NU0–NU9), en conservant intacts la logique financière, les données, les
  migrations, la confidentialité et l'accessibilité. Utiliser pour toute
  exécution, reprise ou vérification d'un lot Neon Ultra.
---

# Budget Neon Ultra — directeur de refonte visuelle

## Mission

Donner à Budget une identité « Neon Ultra » : noir profond, magenta, violet et
cyan — désirable, lisible en dix secondes, jamais casino. Conserver toutes les
fonctions, les données, l'historique financier et les invariants existants. Ne
jamais recommencer le produit depuis zéro pour obtenir un nouveau visuel.

Ce programme remplace la direction visuelle « Obsidian Glass / accent indigo
unique » (ADR-024). Il ne remplace AUCUNE règle financière, technique, de
confidentialité, de sauvegarde, d'accessibilité ou de publication.

## Dépôt et branche

- Dépôt exclusif : `Mendestrading21/Budget-`
- Branche de travail obligatoire : `refonte/budget-neon-ultra-v1`
- Branche source (figée, ne jamais modifier) : `refonte/budget-obsidian-glass-v1`
- HEAD source prouvé CI verte : `26d186e8e31bbdf1bc41651afcaf7a1699988644`

## Charger le contexte obligatoire

Avant toute action, lire :

1. `CLAUDE.md`
2. `NEON_ULTRA_STATUS.md`
3. `PROJECT_STATUS.md`
4. `DECISION_LOG.md` (au minimum ADR-024, ADR-023, ADR-016→018)
5. [NEON_ULTRA_CONSTITUTION.md](references/NEON_ULTRA_CONSTITUTION.md)
6. [NEON_ULTRA_DELIVERY.md](references/NEON_ULTRA_DELIVERY.md)
7. [NEON_ULTRA_SCREEN_MATRIX.md](references/NEON_ULTRA_SCREEN_MATRIX.md)
8. [REPOSITORY_CONTRACT.md](references/REPOSITORY_CONTRACT.md)
9. [REFERENCE_INDEX.md](references/REFERENCE_INDEX.md)

Pour tout travail d'interface, ouvrir réellement les images listées dans
`REFERENCE_INDEX.md` (inspiration artistique seulement — jamais de copie de
texte, nom, personnage, marque ou écran exact).

## Interpréter la commande

### `plan`

Inspecter le dépôt, les tests, les captures et le lot demandé. Produire les
critères d'acceptation et le diff prévu. Ne pas lancer une refonte générale.

### `execute NUx`

Exécuter uniquement le lot `NUx` décrit dans
`NEON_ULTRA_DELIVERY.md`. Terminer le lot verticalement : code, états, tests,
rendu, captures, documentation et commit. S'arrêter ensuite.

### `continue`

Lire `NEON_ULTRA_STATUS.md`, vérifier le code et la CI, puis reprendre le
premier critère incomplet du lot actif. Ne pas répéter un lot terminé.

### `verify`

Ne rien ajouter. Construire, tester, vérifier visuellement et produire les
preuves demandées pour le lot ou l'écran indiqué.

### `prompt`

Produire le prompt exact du prochain lot (état, HEAD attendu, critères,
interdits), sans l'exécuter.

Si la commande est ambiguë, choisir l'action la plus conservatrice. Si un lot
est actif, le terminer avant d'en ouvrir un autre.

## Sécurité du dépôt

Avant chaque modification :

1. `pwd` et `git status --short --branch` ;
2. confirmer la branche `refonte/budget-neon-ultra-v1` ;
3. worktree propre, diff inspecté, travail non lié préservé ;
4. lire le code, les tests et les décisions réelles ;
5. reprendre les commandes de build/test depuis les workflows CI existants ;
6. annoncer les critères d'acceptation du lot avant d'éditer.

Jamais de commande Git destructive. Jamais de merge, déploiement, publication,
tag, TestFlight ou App Store Connect sans autorisation explicite du
propriétaire. Ne jamais modifier `refonte/budget-obsidian-glass-v1` ni la
branche par défaut.

## Contrat financier non négociable (inchangé)

- `Decimal` de bout en bout dans l'app native ; jamais `Double` pour l'argent.
- Format `fr-CH`, dates `dd.MM.yyyy`, montants explicables.
- Planifié et comptabilisé restent distincts.
- Épargne et investissement ne sont pas des dépenses de vie.
- Un virement interne est neutre pour revenu, dépense, cash-flow, patrimoine.
- Remboursement de capital ≠ intérêts ≠ frais.
- Aucune devise additionnée sans conversion explicite et historisée ;
  un taux actuel ne réécrit jamais l'historique.
- Restauration invalide refusée atomiquement ; jamais de coercition vers zéro.
- Aucun échec de persistance ignoré ; import idempotent.
- Aucune donnée personnelle réelle dans tests, captures ou logs.
- Aucun conseil financier personnalisé, aucune fausse connexion bancaire.

## Contrat visuel Neon Ultra

La constitution détaillée prévaut ; résumé opérationnel :

- Palette canonique (voir `NEON_ULTRA_CONSTITUTION.md`) : canvas `#05060A`,
  navigation `#0B0D13`, surfaces `#11141C` / `#181C26`, fallback opaque
  `#151923`, bordure `#293040` ; néons magenta `#D946EF`, violet `#7C3AED`,
  cyan `#38BDF8` ; CTA profond `#C000A4 → #6E00E8` ; textes `#F5F7FA` /
  `#A3ACBA` / `#7C8696` (texte discret corrigé AA le 27.07.2026) ;
  sémantique : positif `#35D39A`, négatif `#FF6577`, alerte `#F6C453`.
  Le violet seul ne porte jamais un petit libellé actif (3,41:1 sur la
  navigation) : texte actif en `#F5F7FA` + indicateur violet.
- 75 % noir/graphite, 15 % neutres, 10 % maximum de néon.
- Un seul point focal lumineux majeur par viewport.
- Gradient réservé au CTA, à la sélection et aux moments de marque.
- Aucun glow autour des montants ; cartes de listes mates, sans blur lourd.
- Vert, corail et ambre exclusivement sémantiques.
- Aucun clignotement, pulsation infinie, confetti, esthétique casino/crypto.
- Animations courtes et utiles ; supprimées ou réduites avec Reduce Motion.
- Rendu opaque sans blur avec Reduce Transparency.
- Texte courant WCAG AA ; cibles tactiles ≥ 44 pt ; montants CHF longs,
  négatifs et à sept chiffres toujours lisibles.

## Boucle d'exécution obligatoire (par lot)

1. observer l'état réel ; 2. écrire le résultat utilisateur et les critères
mesurables ; 3. protéger les invariants ; 4. composants réutilisables d'abord ;
5. tous les états utiles (vide, chargé, erreur, montant long, clavier) ;
6. tests ciblés ajoutés/adaptés (jamais supprimés ni affaiblis) ; 7. suites
complètes vertes ; 8. rendu inspecté à 390 et 320 px (PWA) et sur simulateur
courant (iOS) ; 9. avant/après conservés ; 10. accessibilité (VoiceOver/
lecteur d'écran, Dynamic Type, contrastes, reduced motion/transparency) ;
11. `NEON_ULTRA_STATUS.md` + décisions mises à jour ; 12. un commit ciblé,
puis s'arrêter.

## Gates de qualité

Un lot n'est terminé que si les suites applicables sont vertes (jamais moins
que les bases du `REPOSITORY_CONTRACT.md`), zéro erreur console, chiffres
réconciliés avec les fixtures, rendu réellement vérifié, 320 px sans
débordement, états vide/erreur/extrêmes traités, captures conservées, statut à
jour avec preuves et prochain lot exact. Ne jamais déclarer « terminé »,
« 10/10 » ou « prêt App Store » tant qu'une validation humaine reste due ;
les lots se terminent en VERIFYING jusqu'à validation du propriétaire.

## Rapport de fin de lot

1. résultat utilisateur livré ; 2. fichiers modifiés ; 3. tests/builds et
résultats exacts ; 4. captures produites et inspectées ; 5. invariants
contrôlés ; 6. risques réels ; 7. commit du lot ; 8. prochain prompt exact,
sans commencer le lot suivant.
