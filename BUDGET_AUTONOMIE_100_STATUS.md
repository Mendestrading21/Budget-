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

**État : DONE** — PR #125 fusionnée (`main` = `4713a2b`) le 25.08.2026,
sur ordre propriétaire, après #123 (audit, `fd5fbac`).

### W1 — Fixtures canoniques (lot actif)

**État : W1.1 fusionné (ordre du 25.08) · W1.2 → W1.3 → W1.4 EN PR
(brouillons empilés, fusion dans l'ordre)** — W1.5–W1.7 BLOCKED.
Décisions propriétaire du 25.08.2026 : ADR-060 (parité patrimoine —
la PWA gagne le réglage, lot AUT-060) et ADR-061 (le résultat du mois
exclut l'épargne — lot AUT-061). Les deux implémentations passent
AVANT les runners W1.6.

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
| W0 | Gouvernance et vérité | DONE | — |
| W1 | Fixtures canoniques | W1.1 EN PR | W0 (fusionné) |
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

### 25.08.2026 — AUT-061 : le résultat du mois exclut l'épargne et le capital

Implémentation de l'ADR-061 (amendée : le capital de dette est exclu
comme l'épargne, FI-14/FI-21 — la mesure montrait d'ailleurs DEUX
formules : le natif soustrayait la dette, la PWA non). Contrat commun :
résultat = reçus − coût de vie − impôts, identique sur les deux
plateformes ; note du mois passé honnête (« mettre de côté ou
rembourser une dette n'est pas perdre »). Parcours 180 né rouge
(3 échecs nommés, 1600 lu), sabotage mordant, 180 e2e verts ; test
natif MonthlySnapshotServiceTests aligné (5000, commenté) — preuve
native = job simulateur CI. Fixture canonique `resultat-du-mois`
(210000) + champ optionnel `resultatMineures` au schéma.

### 25.08.2026 — W1.4 : fixtures patrimoine/dette/devise + ADR-060/061

Décisions propriétaire obtenues (questions posées, réponses
consignées) : exclusion d'un compte du patrimoine = PARITÉ (ADR-060) ;
résultat du mois SANS l'épargne (ADR-061). Trois fixtures :
`patrimoine-compte-exclu` (contrat cible — natif conforme, PWA après
AUT-060), `dette-capital-pas-un-cout` (FI-14), `devise-conversion-
datee` (FI-16 : 90000 × 0.95 = 85500 exactement). Implémentations
AUT-060/061 en lots séparés, test rouge d'abord, avant W1.6.

### 25.08.2026 — W1.3 : fixtures mois/transferts/épargne

Trois fixtures : `mois-transfert-neutre` (FI-09 — virement neutre au
centime), `mois-trio-reel-et-projection` (trio réel seul ; projection =
disponible + prévu − échéances non couvertes), `epargne-interne-pas-un-
cout` (FI-10 — mis de côté ≠ dépensé). Validateur durci avec les règles
produit mesurées : un virement/mis de côté exige une destination, un
virement vers soi-même est refusé. Sabotage mordant (virement sans
destination nommé). Arithmétique des attendus contre-vérifiée à la
main. Note : le « flux net » (FI-21) N'est PAS fixé ici — le
`cashFlow` mesuré soustrait l'épargne, l'invariant l'exclut ; la
définition contractuelle sera tranchée par ADR (W1 suite ou W6), pas
en douce.

### 25.08.2026 — W1.2 : fixtures Money/comptes

Trois fixtures canoniques : `comptes-solde-ouverture` (ouverture +
comptabilisé, prévu hors solde mais dans la projection, mise de côté
comptée une fois), `comptes-exclusions-liquide` (cash seul dans le
disponible, épargne accessible = stock), `comptes-par-devise` (soldes
dans la devise du compte ; agrégats convertis volontairement différés à
W1.4). Attendus contre-vérifiés à la main ; sabotage mordant
(référence de compte cassée nommée). **Écart consigné (mesuré)** : le
natif filtre `includeInNetWorth` par compte, la PWA additionne TOUS
les comptes dans `fortuneTotale()` — la fixture d'exclusion patrimoine
attendra l'ADR de W1.4 ; aucun côté n'est « aligné » sans décision
(règle du skill).

### 25.08.2026 — W0 fusionné, W1.1 exécuté

Sur « fusionne publie et fait tout » : #123 (audit) fusionnée
(`fd5fbac`), #125 (W0) rebasée à arbre byte-identique et fusionnée
(`main` = `4713a2b`), CI verte à chaque étape. W1 débloqué ; W1.1
livré : `fixtures/canon/SCHEMA.md` (schéma version 1), ADR-059 (unités
mineures entières ; taux en chaînes datées et sourcées), validateur
`canon-schema.test.mjs` né rouge puis vert, contrôle négatif mordant
(montant à virgule refusé en nommant le champ), étape CI dédiée,
fixture d'exemple. Aucun moteur touché.

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
