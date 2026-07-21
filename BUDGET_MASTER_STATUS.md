# BUDGET_MASTER_STATUS

## En-tête

- Date UTC : 2026-07-21
- Branche : `claude/budget-project-connection-link-mhaokm` — SHA de départ : `6f686b7`
- Jalon actif : J1 — Confiance (A01–A06)
- Lot actif : A01 Inventaire réel
- Dernière CI verte : voir Actions (baseline : suite web 22 parcours verte localement le 2026-07-21 ; native verte au dernier push `6f686b7`)
- Bloqueurs humains : compte Apple Developer (H04+), QA appareil réel (H03), décision prix (H08), revue réglementaire FR/BE (H09)
- Environnement de session : Linux (pas de xcodebuild local) — les vérifications natives passent par la CI GitHub Actions (runner macos-15), conformément à « adapter la destination sans diminuer la couverture ».

## Tableau

| Lot | Statut | Commit | Tests | Résultat utilisateur | Risque |
|---|---|---|---|---|---|
| A01 Inventaire réel | IN_PROGRESS | — | — | Une carte exacte de ce qui existe | faible |
| A02 Baseline reproductible | READY | — | e2e web 22✓ local | On sait que tout marche avant de toucher | faible |
| A03 Audit boutons/routes | READY | — | — | Zéro bouton mort prouvé | moyen |
| A04 Audit données | READY | — | — | Aucune perte de données possible connue | moyen |
| A05 Fixtures financières | READY | — | — | Web et natif calculent pareil | moyen |
| A06 Statut maître | READY | — | — | Ordre de travail verrouillé | faible |
| B01–B08 Simplicité | BLOCKED (A06) | — | — | App comprise en 10 secondes | — |
| C01–C08 Rituel mensuel | BLOCKED (B) | — | — | Un check mensuel sans doublon | — |
| D01–D08 Patrimoine | BLOCKED (C) | — | — | Fortune nette fiable | — |
| E01–E06 Suisse/foyer | BLOCKED (D) | — | — | Vocabulaire et impôts justes par pays | — |
| F01–F07 Identité | BLOCKED (B) | — | — | Une seule identité visuelle | — |
| G01–G07 Architecture | BLOCKED (A05) | — | — | Centimes exacts, code découpé | — |
| H01–H02, H06 Confiance | BLOCKED (G) | — | — | Sauvegarde et sécurité guidées | — |
| H03–H05, H07–H10 Marché | BLOCKED (humain) | — | — | TestFlight, pilote, prix, release | décisions humaines |

Statuts : BLOCKED, READY, IN_PROGRESS, VERIFYING, DONE.

## Fiche du lot actif — A01 Inventaire réel

### Problème observé

Le dépôt a traversé trois programmes (phases 0-14, audit production, BUDGET 2027) ; aucune carte unique ne relie écrans, modèles, services, tests, workflows et docs.

### Résultat utilisateur

On sait exactement ce qui existe, où, et ce qui est déjà vérifié.

### Périmètre

Inclus : inventaire natif + web + CI + docs, consigné ici. Exclus : toute modification de code.

### Invariants

Aucun code modifié pendant l'inventaire.

### Critères d'acceptation

- [ ] Écrans natifs et web listés avec fichiers sources.
- [ ] Modèles/services/tests dénombrés.
- [ ] Workflows CI et leur rôle décrits.
- [ ] Constats P0/P1/P2 initiaux repris de l'audit de référence.

### Vérifications

- `node webapp/tests/e2e.test.mjs` (baseline avant modification) : **22 parcours verts, zéro erreur console** (2026-07-21, Chromium /opt/pw-browsers).

### Décisions et risques

Session Linux : vérification native déléguée à la CI macOS à chaque push.

### Prochain lot

A02 — figer la baseline avec preuves avant tout changement.
