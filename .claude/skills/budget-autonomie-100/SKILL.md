---
name: budget-autonomie-100
description: Piloter la remise à niveau complète de Budget vers une application grand public fiable, simple, automatisable et publiable. Utiliser pour le moteur financier, les occurrences, les soldes, les devises, le rapprochement, les imports, les règles, les sauvegardes, les migrations, la parité PWA/iOS, l'accessibilité, la sécurité et la préparation App Store/Google Play. Ce skill ordonne les lots W0–W11 et interdit les refontes massives ou les affirmations financières sans preuve.
---

# Budget Autonomie 100

## Mission

Transformer Budget en cockpit financier personnel grand public : l'utilisateur
comprend ce qui est réellement sur ses comptes, ce qui est prévu, ce qui reste
à confirmer, ce que le mois coûte, ce qui a été mis de côté et comment son
patrimoine évolue.

Le moteur doit être plus rigoureux que l'interface. L'utilisateur ne doit pas
connaître le débit/crédit, mais le système doit empêcher doubles comptes,
écritures déséquilibrées, confirmations multiples, conversions sans taux,
corrections silencieuses et restaurations destructrices.

## Autorités

Lire dans cet ordre :

1. `BUDGET_AUTONOMIE_100_STATUS.md`
2. `docs/audit-total-2026-08-25/README.md`
3. `references/PROGRAM_CHARTER.md`
4. `references/FINANCIAL_INVARIANTS.md`
5. référence du lot dans `references/WORK_BREAKDOWN.md`
6. références complémentaires selon le périmètre
7. `CLAUDE.md`, `DECISION_LOG.md`, `BUDGET_PRISME_STATUS.md`
8. code, tests, workflows et historique actuels

Hiérarchie :

- ce skill décide l'ordre système, les invariants et la migration ;
- `budget-prisme` décide le workflow page par page et le design ;
- `budget-identites-locales` décide catalogues et identités locales ;
- une ADR acceptée tranche une décision durable ;
- le code et les tests du SHA actuel priment sur un ancien statut factuel.

En cas de contradiction non tranchée : arrêter le lot, consigner le conflit et
proposer une ADR. Ne jamais choisir silencieusement la formule qui « ressemble
le mieux » à l'écran.

## Modes

- `audit Wn` : inspecter, reproduire, mesurer, ne pas modifier.
- `plan Wn` : écrire le Page/Program Work Order, sans coder.
- `execute Wn` : exécuter seulement le premier sous-lot READY.
- `continue` : reprendre le critère incomplet du lot actif.
- `verify Wn` : tests, migrations, rendu, sécurité ; aucune fonction nouvelle.
- `incident <slug>` : créer une branche P0 et une fixture rouge.
- `prompt Wn` : produire un prompt autonome sans exécuter.
- `release web|testflight|appstore|play` : uniquement après W11 et autorisation
  explicite séparée.

Une demande large utilise `audit` puis `plan`. `execute W0` est autorisé par le
statut initial. Un plan n'autorise jamais automatiquement le code, la fusion ou
la publication.

## Établir la vérité courante

Avant toute modification :

```bash
pwd
git status --short --branch
git rev-parse HEAD
git log -1 --oneline
git diff --stat
git branch --show-current
```

Puis :

1. résoudre dépôt, branche par défaut, `main`, HEAD et CI ;
2. lire l'issue #70 et tout P0 ouvert ;
3. vérifier si une PR/branche du lot existe ;
4. préserver tous changements non liés ;
5. lire modèles, services, vues, stockage, tests et workflows du périmètre ;
6. ne jamais recopier un ancien total de tests sans l'observer ;
7. ne jamais utiliser des données réelles dans tests, captures, logs ou prompts.

## Règle centrale

**Une prévision peut informer, rappeler et proposer. Elle ne peut jamais
prouver qu'un mouvement d'argent a eu lieu.**

Sans transaction bancaire rapprochée ou confirmation humaine explicite :

- le salaire reste prévu ;
- la facture reste à confirmer ;
- le solde réel ne change pas ;
- la projection reste conditionnelle ;
- aucune notification ne dit « payé/reçu ».

## Invariants obligatoires

Conserver sans exception :

- prévu distinct du réel ;
- date attendue distincte de la preuve ;
- occurrence persistée et idempotente ;
- confirmation atomique ;
- journal équilibré par devise ;
- transfert et mise de côté internes neutres pour le patrimoine ;
- épargne/investissement distincts du coût de la vie ;
- correction par inversion/remplacement lié ;
- mouvement rapproché immuable ;
- montant + devise + taux + date explicites ;
- valeur patrimoniale à source unique ;
- import/sync réessayable sans doublon ;
- restauration validée avant mutation ;
- migration depuis chaque version publique ;
- même contrat financier sur Web et iOS ;
- erreur de persistance visible ;
- aucune fausse banque, IA, sécurité ou performance ;
- accessibilité et confidentialité comme gates, pas polish final.

Charger `references/FINANCIAL_INVARIANTS.md` pour les détails et exemples.

## Stratégie de migration

Ne jamais réécrire toute l'app en une PR.

1. figer fixtures et contrats ;
2. ajouter le nouveau modèle en parallèle ;
3. shadow-write sans changer l'interface ;
4. comparer ancien et nouveau moteur ;
5. migrer les données avec dry-run et backup ;
6. basculer une requête/vue derrière feature flag ;
7. observer les différences ;
8. supprimer l'ancien chemin seulement après preuve et rollback.

Une migration de modèle, une formule et une refonte visuelle vivent dans des
PR séparées, sauf si l'unité verticale est impossible et explicitement
approuvée.

## Unité de travail

Une PR traite un sous-lot du premier Wn READY. Elle possède :

- un problème utilisateur ;
- une reproduction ou fixture ;
- un résultat visible/mesurable ;
- un périmètre de fichiers ;
- des non-objectifs ;
- des invariants ;
- une stratégie migration/rollback ;
- un test rouge ou preuve initiale ;
- un contrôle négatif ;
- tests ciblés puis complets ;
- rendu/accessibilité si UI ;
- statut et rapport.

Taille : viser le plus petit lot qui traverse domaine → persistance → UI →
preuve, sans modifier plusieurs pages indépendantes.

## Données et erreurs

- Aucun montant invalide ne devient zéro.
- Aucun enum inconnu ne prend une valeur par défaut silencieuse.
- Aucun lien absent n'est ignoré pendant une restauration.
- Aucun `save` échoué n'affiche succès.
- Toute mutation multi-objet est atomique.
- Toute commande réessayable possède une idempotency key.
- Le rollback ne dépend pas d'un état UI éphémère.
- Une erreur utilisateur est en français simple ; les logs restent sans montant.

## Parité interplateformes

Avant de modifier une formule :

1. ajouter/modifier une fixture canonique versionnée ;
2. faire échouer le runner concerné ;
3. implémenter Swift et Web ;
4. comparer les sorties structurées ;
5. saboter un côté pour prouver que la gate mord ;
6. restaurer et exécuter toutes les suites.

Ne jamais « aligner » les plateformes en copiant un bug connu.

## Expérience utilisateur

- un chiffre focal par viewport ;
- réel en premier, projection au conditionnel ;
- période et devise visibles ;
- bouton avec verbe réel : Reçu, Payé, Rapprocher, Reporter, Ignorer ;
- action importante annulable ;
- catégorie `Autre` et tag `Imprévu` ;
- réglages avancés progressifs ;
- mots simples, aucune comptabilité imposée ;
- aucune couleur seule ;
- 44 pt/px, Dynamic Type/zoom, lecteurs d'écran et clavier ;
- thème système et préférences d'animation/transparence.

Pour tout écran, charger `budget-prisme` et `references/SCREEN_CONTRACTS.md`.

## Recherche externe

Utiliser uniquement des sources actuelles et primaires pour standards,
réglementation, stores, sécurité, open banking et APIs. Documenter :

- principe retenu ;
- adaptation à Budget ;
- ce qui est exclu ;
- provenance/licence d'un actif ;
- date de vérification.

Ne copier ni écran, texte, marque, actif ou méthode propriétaire.

## Tests et preuve

Charger `references/QUALITY_GATES.md` avant tout commit final.

Minimum :

- domaine ;
- fixture interplateforme ;
- persistance/rollback/idempotence ;
- migration si schéma ;
- e2e ;
- build Debug/Release ;
- rendu réel si UI ;
- accessibilité ;
- sécurité/confidentialité ;
- SHA et CI exacts.

Une CI verte n'est jamais une preuve d'absence de défaut non couvert.

## Gestion des incidents P0

P0 si risque de :

- montant, solde ou patrimoine faux ;
- doublon/perte d'écriture ;
- corruption/migration destructive ;
- fuite de données ;
- restauration mensongère ;
- release d'un mauvais SHA.

Procédure :

1. arrêter ;
2. marquer lot `BLOCKED` ;
3. préserver le diff ;
4. créer fixture rouge ;
5. branche `agent/autonomie-p0-<slug>` ;
6. corriger minimalement ;
7. parité, rollback et contrôle négatif ;
8. PR séparée ;
9. reprendre seulement depuis son merge approuvé.

## Conditions d'arrêt

Arrêter et demander une décision propriétaire si :

- une formule produit légitime a plusieurs interprétations ;
- un modèle/migration hors lot est nécessaire ;
- une différence Web/iOS n'a pas d'ADR ;
- une clé, un secret, une permission, une signature ou une approbation manque ;
- une intégration externe exige contrat/certification ;
- des données réelles seraient nécessaires ;
- le rendu/QA requis ne peut pas être observé ;
- fusion ou publication n'est pas explicitement autorisée.

Ne pas bloquer pour un détail résoluble par le code, les tests ou les documents.

## Fusion et publication

Ce skill peut créer branche, commits et PR brouillon lorsque demandé par le
mode. Il ne fusionne ni ne publie sans instruction explicite contenant la
destination.

Même après autorisation : vérifier HEAD, CI push, reviews, migrations, QA et
gates. Fusion et publication sont deux actions séparées.

## Rapport obligatoire

Terminer avec :

1. résultat utilisateur ;
2. lot/sous-lot et état ;
3. référence avant/après ;
4. fichiers ;
5. invariants et décisions ;
6. migration/rollback ;
7. tests observés et contrôle négatif ;
8. rendu/accessibilité/sécurité ;
9. SHA/PR/CI ;
10. risques humains ;
11. prochaine action exacte, sans la commencer.
