# Contribuer à Budget

Budget manipule des vérités financières. Une modification visuellement
correcte mais mathématiquement ambiguë n’est pas acceptable.

## Avant de commencer

1. Lire `CLAUDE.md`.
2. Lire `.claude/skills/budget-prisme/SKILL.md` et les références utiles.
3. Consulter `BUDGET_1_0_READINESS.md` et le journal
   `BUDGET_PRISME_STATUS.md`.
4. Baser le travail exclusivement sur la dernière version de `main`.
5. Utiliser uniquement des données fictives.

## Branches et portée

- Une branche courte par lot : `agent/prisme-<lot>` ou
  `agent/release-<lot>`.
- Une PR = un problème cohérent.
- Aucun push direct sur `main`.
- Aucun déplacement massif de fichiers sans ADR, migration et preuve.
- Aucun changement opportuniste non lié au titre de la PR.

## Définition minimale d’une PR acceptable

- le problème et son impact utilisateur sont décrits;
- les invariants financiers touchés sont nommés;
- un test rouge précède tout correctif de calcul;
- un contrôle négatif prouve que le test mord réellement;
- les suites concernées sont vertes sur le HEAD exact;
- les captures sont fournies pour tout changement visuel;
- migrations, sauvegardes, accessibilité et confidentialité sont évaluées;
- `node .github/scripts/repository-audit.mjs` est vert;
- la documentation vivante est mise à jour sans réécrire l’historique.

Le modèle `.github/PULL_REQUEST_TEMPLATE.md` doit être rempli
honnêtement. Une case non applicable porte une justification.

## Commandes de référence

```bash
node .github/scripts/repository-audit.mjs

cd webapp/tests
npm install --no-save --no-package-lock playwright@1.61.1
npx playwright install chromium
BUDGET_CHROMIUM="$(node -e 'console.log(require("playwright").chromium.executablePath())')" node e2e.test.mjs
BUDGET_CHROMIUM="$(node -e 'console.log(require("playwright").chromium.executablePath())')" node parity.test.mjs
BUDGET_CHROMIUM="$(node -e 'console.log(require("playwright").chromium.executablePath())')" node design.test.mjs
```

La CI GitHub Actions reste la preuve iOS de référence.

## Règles financières

- Ne jamais remplacer une valeur invalide par zéro silencieusement.
- Ne jamais fusionner réel, planifié et projection.
- Ne jamais compter un transfert interne comme entrée ou dépense.
- Ne jamais compter l’épargne ou l’investissement comme coût de vie.
- Ne jamais réécrire l’historique avec une donnée de marché actuelle.
- Conserver les identifiants et les migrations.
- Ajouter une fixture de parité lorsqu’une formule commune évolue.

## Interface

- Navigation stable :
  `Mois · Historique · Budget · Comptes · Gérer`.
- Une seule identité sombre Budget Prisme.
- Pas d’emoji fonctionnel, pas de bouton d’ajout flottant global.
- Cibles tactiles de 44 points, VoiceOver, Dynamic Type, contraste AA,
  réduction des animations et de la transparence.
- Les montants ne sont ni tronqués ni cassés au milieu.

## Données, secrets et artefacts

Ne jamais committer :

- données financières réelles, noms de clients ou captures personnelles;
- `.env`, clés `.p8`, certificats `.cer`/`.p12`, profils
  `.mobileprovision`;
- archives `.ipa`/`.xcarchive`, `node_modules`, `xcuserdata`, `.DS_Store`;
- jetons GitHub, Apple, bancaire ou analytique.

Un secret exposé doit être révoqué immédiatement, puis signalé selon
`SECURITY.md`; le supprimer du dernier commit ne suffit pas.

## Fusion et release

La PR exige une CI verte sur son HEAD exact. Après squash merge, la CI
`push` doit être verte sur le SHA de `main`. Pages et TestFlight reçoivent
ce SHA explicitement. Le tag final est interdit tant que
`BUDGET_1_0_READINESS.md` n’est pas entièrement validé.
