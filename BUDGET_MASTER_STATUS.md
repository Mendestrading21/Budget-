# BUDGET_MASTER_STATUS

## En-tête

- Date UTC : 2026-07-21
- Branche : `claude/budget-project-connection-link-mhaokm` — SHA de départ : `6f686b7`
- Jalon actif : J5 amorcé (G01 étape 1 fait) ; jalon B soldé ; reste G01 étape 2 (budgetReport/contributions) + G02 migration centimes
- Lot actif : G01 (moteur d'agrégation en centimes) livré ; prochain G02 (migration stockage) ou lots C (rituel)
- Dernière CI verte : `0fce07b` (pipeline complet web+parité+iOS) ; commits B03→G01 web verts en local (33 e2e + 4 parité)
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
| B05 Langage 10 ans | DONE | 2e811b7 | e2e 25✓ | Zéro jargon à l'écran | faible |
| P1 réf./saisie/arrondis (A03-W2/W3, A04-W1..W4) | DONE | dab6418 | e2e 27✓ | Saisie protégée, soldes justes | résolu |
| A03-W4 retour ferme feuille | DONE | 6d1f40f | e2e 28✓ | Le retour ferme la feuille | résolu |
| B06 États vides guidés | DONE | bb5b0b4 | e2e 29✓ | Un vide propose une action réelle | faible |
| B07 Menu Plus regroupé | DONE | 2863de6 | e2e 30✓ | Plus lisible, état vivant factures | faible |
| B03 Accueil essentiel + B04 Ajout 3 gestes | DONE | 752f7b6 | e2e 31✓ | Héros + 4 actions ; détail replié | faible |
| B01 Navigation (5 onglets) | DONE (préexistant) | — | e2e | Cinq destinations, aucun doublon | faible |
| B02 Onboarding (5 écrans) | DONE (préexistant) | — | e2e | Départ en < 2 min | faible |
| B08 Erreurs récupérables | PARTIEL | dab6418 | e2e 27✓ | Saisie protégée (feuilles) | faible |
| Qualité/sécurité (NITs) | DONE | f8fd8b0 | e2e 32✓ | Sauvegarde sans code, code mort retiré | résolu |
| G01 Centimes (moteur d'agrégation) | DONE (étape 1) | 895afcf | e2e 33✓ + parité | Sommes exactes au centime | moyen |

### Audit soldé (voir AUDIT_COMPLET_BUDGET_2026-07-21.md)

Tous les constats A03 (B1 + W1..W4) et A04 (B1, B2, W1..W4) sont corrigés
et couverts par des tests e2e. Restent des NIT non bloquants (N1..N7 de
chaque audit) et les écarts de parité volontaires documentés (dette web
dans le coût de la vie → D04 ; flottants → G01).
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
