# Budget Autonomie 100 — statut

## Référence

- Programme créé le : 25 août 2026
- Audit de base : `main@bcef018218de6bb926708a88b655ed844d73a20f`
- Branche de création : `audit/budget-autonomie-100-2026-08-25`
- Autorité : `.claude/skills/budget-autonomie-100/SKILL.md`
- Audit : `docs/audit-total-2026-08-25/README.md`
- Incident release existant : issue #70
- Verdict actuel : **NO-GO public**

## Lot actif

### W0 — Gouvernance et contrat de vérité

**État : EN PR (brouillon, empilée sur #123 — ordre de fusion #123 → W0)**

Objectif : transformer l'audit en contrat exécutable sans modifier les
formules ni les écrans.

Instruction exacte à écrire dans Claude Code :

```text
Utilise le skill budget-autonomie-100 de ce dépôt. Exécute uniquement W0 —
Gouvernance et contrat de vérité. Lis d'abord le statut et toutes les références
requises par le skill, crée une branche dédiée et une PR brouillon, ne modifie
aucun calcul ni écran, ne fusionne rien et arrête-toi après le rapport W0 et le
Work Order W1.
```

Claude Code découvre les skills repo-locaux à partir du frontmatter de
`SKILL.md`; cette instruction naturelle est volontairement utilisée au lieu
d'une commande slash personnalisée qui pourrait ne pas exister dans
l'installation locale.

Livrables attendus :

- ADR de migration progressive ;
- glossaire des états ;
- dictionnaire des chiffres ;
- registre des invariants ;
- inventaire des calculs et mutations Web/iOS ;
- matrice de dépendances W0–W11 ;
- Page Work Order pour W1 ;
- PR ciblée, sans code métier.

## Backlog

| Lot | Sujet | État | Dépend de |
|---|---|---|---|
| W0 | Gouvernance et vérité | EN PR | — |
| W1 | Fixtures canoniques | BLOCKED | W0 |
| W2 | Occurrences persistées | BLOCKED | W1 |
| W3 | Journal financier | BLOCKED | W1, W2 |
| W4 | Comptes, devises, rapprochement | BLOCKED | W3 |
| W5 | Pages et inbox | BLOCKED | W2, W3, W4 |
| W6 | Plan, budgets, objectifs | BLOCKED | W2, W3, W5 |
| W7 | Import, règles, tags, splits | BLOCKED | W1, W3 |
| W8 | Investissements et modules régionaux | BLOCKED | W3, W4 |
| W9 | PWA modulaire et IndexedDB | BLOCKED | W1, W2, W3 |
| W10 | Sécurité, backup, migrations | BLOCKED | W3, W9 |
| W11 | Accessibilité, stores, Android, release | BLOCKED | W0–W10 |

## Invariants déjà décidés

- prévu ≠ réel ;
- une date n'est pas une preuve ;
- occurrence persistée et idempotente ;
- transfert équilibré et neutre ;
- correction par trace ;
- devise/taux/date explicites ;
- une source unique par valeur patrimoniale ;
- sauvegarde validée avant remplacement ;
- mêmes fixtures sur Web et iOS ;
- publication sur SHA exact et autorisation humaine séparée.

## Décisions en attente dans les lots futurs

- stockage interne en unités mineures versus Decimal canonique ;
- stratégie de migration du modèle actuel vers le journal ;
- politique multi-devise V1/V2 ;
- technologie Android ;
- fournisseur bancaire et marchés ;
- cloud/synchronisation multi-appareils ;
- politique de chiffrement et récupération de clé.

Aucune de ces décisions ne bloque W0.

## Journal

### 25.08.2026 — W0 exécuté (docs seulement)

Sur ordre propriétaire (« Exécute uniquement W0 »), branche
`agent/autonomie-w0-gouvernance` créée depuis la branche d'audit
(`4775372`, empilée sur #123). Livrables : ADR-058 (migration
progressive), `docs/autonomie/w0/` — glossaire des états, dictionnaire
des chiffres, inventaire mesuré des calculs/mutations Web+iOS, registre
des invariants FI-01…FI-40 (15 tenus · 12 partiels · 13 ouverts),
matrice de dépendances W0–W11, Page Work Order W1. Vérité courante
établie (`main` = `bcef018`, issue #70 lue, PR #123 identifiée). Aucun
calcul, modèle, écran, test produit ni workflow modifié. W1 reste
BLOCKED jusqu'à la fusion de W0.

### 25.08.2026 — Programme créé

Audit du code, des tests, workflows, incidents et deux plateformes ; recherche
externe ; moteur cible, architecture, roadmap, gates et skill Claude Code
rédigés sur branche dédiée. Aucun calcul, écran, modèle, migration, publication
ou donnée utilisateur modifié.
