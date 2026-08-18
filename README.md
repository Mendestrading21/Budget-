# Budget 1.0

**Comprendre l’argent réellement disponible aujourd’hui, ce qui arrivera
d’ici la fin du mois et l’évolution du patrimoine — sans mélanger les
trois.**

Budget est une application suisse de finances personnelles destinée au
foyer. Elle existe en deux interfaces qui partagent les mêmes règles
financières :

| Interface | Technologie | Cible |
|---|---|---|
| **iPhone** | SwiftUI · SwiftData · Swift Charts | iOS 17+, iPhone uniquement |
| **Web installable** | PWA hors ligne | Safari/Chromium, données locales |

PWA : <https://mendestrading21.github.io/Budget-/>

> **État de publication : candidat Budget 1.0.** Le projet Xcode porte la
> version marketing `1.0`. La publication finale reste conditionnée aux
> critères de `BUDGET_1_0_READINESS.md`, à une CI verte sur le SHA exact,
> à la QA sur un iPhone réel et à la validation TestFlight.

## Ce que Budget organise

- **Mois** : argent disponible maintenant, projection de fin de mois,
  entrées, dépenses, abonnements, sommes mises de côté et éléments à venir.
- **Historique** : opérations recherchables et filtrables, sans perdre le
  contexte du mois.
- **Budget** : enveloppes, écarts, hors-budget et lecture annuelle.
- **Comptes** : comptes courants, épargne, investissements, prévoyance,
  actifs, dettes, patrimoine et fortune nette. Les remboursements de
  capital déplacent le cash et l’encours sans créer un faux coût de vie.
- **Gérer** : catégories, récurrences, impôts, objectifs, sauvegarde,
  import/export, confidentialité et réglages utiles.
- **Deux horizons explicites** : une opération planifiée ne devient jamais
  silencieusement de l’argent réellement reçu ou payé.

## Vérités financières non négociables

1. Les montants natifs utilisent `Decimal`; une valeur invalide n’est
   jamais transformée en zéro en silence.
2. Le réel, le planifié et la projection restent séparés.
3. L’épargne et l’investissement ne sont pas des dépenses de vie.
4. Un virement interne est neutre pour les revenus, les dépenses et la
   fortune nette.
5. Un même franc ne peut appartenir qu’à une seule famille métier.
6. L’historique ne change pas à cause d’un taux de change actuel.
7. Aucun compte bancaire, cours en direct ou conseil réglementé n’est
   simulé.
8. Les libellés et nombres suivent le français suisse (`fr-CH`).

## Arborescence autoritative

```text
Budget/                         application iOS de production
BudgetTests/                    tests unitaires et d’intégration natifs
BudgetUITests/                  tests d’interface natifs
Budget.xcodeproj/               projet Xcode, version et cibles
webapp/                         PWA de production
webapp/tests/                   e2e navigateur, parité et design
fixtures/                       données canoniques de test
.claude/skills/budget-prisme/   skill maître du projet
docs/                           index, preuves et historique documenté
.github/workflows/              CI, Pages, démonstration et TestFlight
```

Les répertoires applicatifs ne doivent pas être déplacés pour un simple
nettoyage. Les changements structurels exigent une raison technique, une
migration et des tests prouvant l’absence de régression.

## Sources de vérité

| Fichier | Autorité |
|---|---|
| `CLAUDE.md` | protocole de travail et invariants |
| `.claude/skills/budget-prisme/SKILL.md` | méthode active de développement |
| `BUDGET_1_0_READINESS.md` | porte de sortie de la version 1.0 |
| `BUDGET_PRISME_STATUS.md` | journal détaillé des lots et preuves |
| `BUDGET_FAMILLES_PLAN.md` | modèle des quatre familles |
| `FINANCIAL_ENGINE_V2.md` | contrat Maintenant / Fin du mois et formules FE2 |
| `DECISION_LOG.md` | décisions d’architecture |
| `docs/INDEX.md` | carte documentaire complète |

`budget-neon-ultra` est conservé comme historique. Il ne doit plus être
utilisé comme autorité active.

## Vérifications locales

### Audit du dépôt

```bash
node .github/scripts/repository-audit.mjs
```

### PWA

```bash
cd webapp/tests
npm install --no-save --no-package-lock playwright@1.61.1
npx playwright install chromium

BUDGET_CHROMIUM="$(node -e 'console.log(require("playwright").chromium.executablePath())')" node e2e.test.mjs
BUDGET_CHROMIUM="$(node -e 'console.log(require("playwright").chromium.executablePath())')" node parity.test.mjs
BUDGET_CHROMIUM="$(node -e 'console.log(require("playwright").chromium.executablePath())')" node design.test.mjs
```

### iOS

```bash
xcodebuild \
  -project Budget.xcodeproj \
  -scheme Budget \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project Budget.xcodeproj \
  -scheme Budget \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  -skip-testing:BudgetUITests \
  test
```

La CI reste la preuve de référence, car elle vérifie également le build
Release, le manifeste de confidentialité et la cible iPhone uniquement.

## Flux de livraison

1. Créer une branche courte `agent/prisme-*` depuis `main`.
2. Ouvrir une PR ciblée, avec preuves et risques financiers explicités.
3. Exiger la CI verte sur le **HEAD exact** de la PR.
4. Fusionner par squash dans `main`.
5. Exiger la CI `push` verte sur le **SHA exact** de `main`.
6. Déployer Pages ou TestFlight en fournissant explicitement ce SHA.
7. Exécuter `MANUAL_QA_CHECKLIST.md` sur l’artefact distribué.
8. Créer le tag `v1.0.0` uniquement quand tous les critères de sortie sont
   cochés.

Aucun push direct, aucun déploiement depuis une branche historique et
aucune publication basée sur le simple nom d’une branche.

## Contribution et sécurité

- Règles de contribution : `CONTRIBUTING.md`
- Signalement de vulnérabilité : `SECURITY.md`
- Historique des changements : `CHANGELOG.md`
- Cartographie des skills : `.claude/skills/README.md`

Aucune licence open source n’est publiée dans le dépôt à ce jour. Le choix
d’une licence reste une décision explicite du propriétaire avant toute
réutilisation externe du code.
