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

**État : READY**

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
| W0 | Gouvernance et vérité | READY | — |
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

### 25.08.2026 — Programme créé

Audit du code, des tests, workflows, incidents et deux plateformes ; recherche
externe ; moteur cible, architecture, roadmap, gates et skill Claude Code
rédigés sur branche dédiée. Aucun calcul, écran, modèle, migration, publication
ou donnée utilisateur modifié.
