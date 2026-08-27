# Gouvernance de release — Budget (W11.7)

Comment une version SORT, qui fait quoi, et ce que l'outillage
verrouille. Rien ici n'invente un nouveau chemin : c'est LE pipeline
prouvé lot après lot, écrit noir sur blanc.

## Versioning

- **Natif** : `MARKETING_VERSION` (sémantique : majeure.mineure, patch
  si correctif seul) + `CURRENT_PROJECT_VERSION` (build, entier
  croissant à chaque envoi TestFlight/App Store). Aujourd'hui :
  1.0 (build 1), « en préparation ».
- **PWA** : publication CONTINUE — chaque lot fusionné est publié par
  dispatch au SHA exact ; la version servie EST le dernier SHA publié
  (consigné au statut avec son run id). Pas de numéro séparé : le
  SHA fait foi.
- **Changelog** : `CHANGELOG.md` (racine), en français simple, une
  section par version native ; la section du haut porte TOUJOURS la
  `MARKETING_VERSION` du projet Xcode — l'audit vérifie l'accord.

## La seule voie de sortie (prouvée, jamais contournée)

1. Branche courte `agent/*` depuis `main` à jour — JAMAIS de push
   direct sur `main`.
2. Mesure → né-rouge → changement minimal → sabotage qui mord →
   batterie complète (e2e, build, domaine, parités, canon, design,
   catalogue, audits) → captures si l'UI bouge → statut consigné.
3. PR française non-draft → CI verte sur le HEAD EXACT → squash merge.
4. CI push verte sur `main` AVANT toute publication (leçon W8.3a).
5. PWA : dispatch `pages.yml` (ref `refonte/budget-neon-ultra-v1`,
   input `sha` = SHA de fusion) → poll du run → verdict consigné au
   statut avec le run id.
6. Natif : archive Release vérifiée à CHAQUE CI ; l'envoi
   TestFlight/App Store passe par `testflight.yml` et exige les
   4 secrets propriétaire (OWNER) — jamais simulé, jamais contourné.

## Qui fait quoi

| Geste | Qui |
|---|---|
| Lots, PR, fusion après CI verte, publication PWA au SHA, statut | Agent (autorisation permanente consignée) |
| Décisions produit (chiffrement, Android, allumages) | PROPRIÉTAIRE — via question posée, réponse consignée en ADR |
| Secrets TestFlight (APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_API_KEY_P8), clic environnement github-pages, URLs publiques, fiche App Store Connect | PROPRIÉTAIRE (HUMAN REQUIRED, nommés dans les fiches W11.5/W11.6) |
| Bump `MARKETING_VERSION`/build + section CHANGELOG à l'envoi d'une version native | Agent propose (PR), propriétaire déclenche l'envoi |

## Verrous d'outillage

- L'audit racine vérifie : `CHANGELOG.md` présent, en-tête de version
  ACCORDÉ à `MARKETING_VERSION` du projet Xcode, contenu substantiel.
- La CI vérifie déjà : `MARKETING_VERSION` présent, build Release +
  manifeste de confidentialité embarqué, schéma V14 figé, blocs
  générés, toutes suites.
- Le statut (`BUDGET_AUTONOMIE_100_STATUS.md`) consigne CHAQUE fusion
  (SHA, PR) et CHAQUE publication (run id, verdict) — c'est le
  registre de release de fait.

## Ce qui n'existe pas (et ne doit pas apparaître en douce)

Pas de tag sans version réelle envoyée, pas de release GitHub
décorative, pas de canal bêta parallèle, pas de publication PWA sans
CI push verte au même SHA.
