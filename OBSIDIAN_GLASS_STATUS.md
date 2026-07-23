# Budget — Statut Obsidian Glass

## Source de vérité

- Programme : Budget — Obsidian Glass
- Branche : `refonte/budget-obsidian-glass-v1`
- Branche source : `codex/budget-leader-refonte`
- Autorité Claude : `.claude/skills/budget-v1/SKILL.md`
- Dernière mise à jour : 23.07.2026

Les anciens fichiers de statut et skills restent des archives de programmes
précédents. Ils ne définissent pas le prochain travail Obsidian Glass.

## Avancement

| Lot | Statut | Preuve | Prochaine condition |
|---|---|---|---|
| L0 Gouvernance | DONE | branche, skill, constitution, matrice et livraison | vérifier les fichiers distants |
| L1 Vérité/baseline/P0 | READY | — | audit réel + captures avant |
| L2 Fondations | BLOCKED | — | L1 validé |
| L3 Pilote PWA | BLOCKED | — | L2 validé |
| L4 Pilote iOS | BLOCKED | — | validation humaine de L3 |
| L5 Mouvements/Comptes | BLOCKED | — | L4 validé |
| L6 Modules financiers | BLOCKED | — | L5 validé |
| L7 Onboarding/Confiance | BLOCKED | — | L6 validé |
| L8 Widgets/Mouvement | BLOCKED | — | L7 validé |
| L9 Audit final | BLOCKED | — | L8 validé |

Statuts autorisés : `BLOCKED`, `READY`, `IN_PROGRESS`, `VERIFYING`, `DONE`.

## P0 à revalider dans L1

- [ ] branche et vérité de release cohérentes;
- [ ] restauration native : aucune conversion invalide vers zéro;
- [ ] PWA : historique de change figé;
- [ ] `PrivacyInfo.xcprivacy` présent dans le produit archivé;
- [ ] URLs, bundle ID et métadonnées App Store cohérents.

## Invariants de programme

- Aucun changement de logique financière pour servir le visuel.
- Aucun écran général avant validation du pilote.
- Un lot, un commit, des tests, des captures, puis arrêt.
- Une seule identité sombre Obsidian Glass.
- Un seul accent de marque indigo.
- Vert, corail et ambre uniquement sémantiques.
- PWA et iOS partagent rôles, vocabulaire et composants, pas une copie pixel par pixel.
- Aucun merge, déploiement ou publication sans autorisation.

## Prochaine commande exacte

```text
/budget-v1 execute L1
```

Résultat attendu : audit réel, confirmation ou correction des P0, captures
baseline et proposition précise du diff L2. Ne pas commencer la refonte visuelle
générale.

