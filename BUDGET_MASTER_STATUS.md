# BUDGET_MASTER_STATUS

## En-tête

- Date UTC : 2026-07-21
- Branche : `claude/budget-project-connection-link-mhaokm` — SHA de départ : `6f686b7`
- Jalon actif : J2 — Compréhension (lots B) ; J1 clos
- Lot actif : B05 Langage 10 ans (en cours) ; P0 corrigés
- Dernière CI verte : `ebf75ce` (docs J1) ; `f75bd81` (parité) et `426752a` (P0) en cours de vérification
- Bloqueurs humains : compte Apple Developer (H04+), QA appareil réel (H03), décision prix (H08), revue réglementaire FR/BE (H09)
- Environnement de session : Linux (pas de xcodebuild local) — les vérifications natives passent par la CI GitHub Actions (runner macos-15), conformément à « adapter la destination sans diminuer la couverture ».

## Tableau

| Lot | Statut | Commit | Tests | Résultat utilisateur | Risque |
|---|---|---|---|---|---|
| A01 Inventaire réel | DONE | 6677166 | — | Une carte exacte de ce qui existe | faible |
| A02 Baseline reproductible | DONE | a171898 | e2e 22✓ + parité 4✓ | On sait que tout marche avant de toucher | faible |
| A03 Audit boutons/routes | DONE | ebf75ce | — | 1 P0 (bouton mort) trouvé et corrigé | moyen |
| A04 Audit données | DONE | ebf75ce | — | 2 P0 (perte de données) trouvés et corrigés | moyen |
| A05 Fixtures financières | DONE | f75bd81 | parité 4✓ en CI | Web et natif calculent pareil | moyen |
| A06 Statut maître | DONE | ebf75ce | — | Ordre de travail verrouillé (voir audit) | faible |
| P0 données+bouton | DONE | 426752a | e2e 25✓ | Aucune perte silencieuse ; Annuler agit | résolu |
| B05 Langage 10 ans | IN_PROGRESS | — | — | Zéro jargon à l'écran | faible |
| B01–B08 (reste) | READY | — | — | App comprise en 10 secondes | — |
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
