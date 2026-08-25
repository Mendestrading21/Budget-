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

### W1 — Fixtures canoniques

**État : DONE** — W1 entièrement fusionné et publié le 25.08.2026 sur
ordre permanent : #128 (fixtures W1.2–W1.5, `84c331c`) → #129 (AUT-060,
`c76b222`) → #130 (AUT-061, `c931565`) → #131 (runners W1.6/7, `main`
= `7814cb8`), chaque HEAD à CI verte et arbre byte-identique après
squash ; publication par dispatch au SHA exact `7814cb8`
(run `32840603822`, succès).

### W2 — Occurrences persistées

**État : DONE** — W2 entièrement fusionné et publié le 25.08.2026 sur
ordre permanent : W2.1–W2.3 (`8d0b570`, run `32847580712`), W2.4a/b,
W2.5, W2.6, W2.7a (`45890c7`, publication run `32857974554` — logs :
`TARGET_SHA` exact, « CI verte confirmée », déploiement réussi), W2.7b
(#140, `main` = `01158b0`, publication run `32862223119`, succès).
(Work Order : `docs/autonomie/w2/WORK_ORDER_W2.md`.)

### W3 — Journal financier (lot actif)

**État : W3.1 fusionné et publié (`main` = `6a6cf02`, PR #141,
publication run `32866561627`, succès) · W3.2 fusionné et publié
(`main` = `2668c94`, PR #142, publication run `32869829266`, succès) ·
W3.3 fusionné et publié (`main` = `b093eb8`, PR #143, publication run
`32872986416`, succès) · W3.3b fusionné (`main` = `e8a0d47`, PR #144,
publication run `32874460073`) · W3.4 EN PR** (Work Order :
`docs/autonomie/w3/WORK_ORDER_W3.md`). ADR-063 (centimes entiers —
question posée au propriétaire le 25.08.2026, écartée « continue » ;
les autorités `DATA_MODEL_TARGET.md` + ADR-059 tranchent). W3.1 a
livré la porte d'entrée du journal des deux côtés ; W3.2 livre les
écritures TYPES (traducteur mouvement → écriture, ouverture FI-12) —
SHADOW : aucune vue ne lit, aucune mutation n'écrit (ADR-058, l'ombre
arrive en W3.3).
Les fixtures « doublons d'import » de W1.5 sont DIFFÉRÉES à W7 : le
modèle d'import intermédiaire n'existe pas encore, une fixture ne peut
pas attester un contrat sans forme (consigné, pas oublié).
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
| W1 | Fixtures canoniques | DONE | W0 |
| W2 | Occurrences persistées | DONE | W1 (fusionné) |
| W3 | Journal financier | W3.1–W3.3b fusionnés · W3.4 EN PR | W1, W2 (fusionnés) |
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

### 25.08.2026 — W3.4 : le comparateur — la gate de bascule des soldes

Le comparateur (ADR-058 étape 4) : `comparerJournalEtSoldes()` —
complète d'abord l'historique non couvert via le traducteur
(`completerOmbreJournal`, idempotent — même clé, jamais deux
écritures ; l'ouverture de chaque compte devient une écriture, FI-12),
puis exige que le solde de CHAQUE compte dérivé du journal
(`soldeDepuisJournal` — lifecycle `pending` exclu, FI-01) égale
EXACTEMENT `balance()` ; tout mouvement resté sans écriture est un
écart NOMMÉ portant son refus consigné (FI-34 — l'argent qui a bougé
sans que le journal sache le raconter reste VISIBLE). Preuves :
parcours 193 né rouge (7 échecs nommés) → vert (héritage couvert,
ouverture écrite, idempotence, falsification d'une écriture → écart
nommant le compte, mouvement intraduisible → écart visible) ; sabotage
(ouverture ignorée dans le complètement) → 3 contrôles mordent avec
écarts chiffrés (« compte cur : solde vivant 10903.35, journal
5903.35 ») ; restauré vert ; suites complètes vertes (193 e2e, 9
parités, 13 canon + schéma, design, catalogue, audit). Consigné : le
comparateur natif (soldes SwiftData ↔ journal V12) suivra la bascule
W3.6 ; les agrégats du mois se comparent à la bascule, pas avant.

### 25.08.2026 — W3.3b : l'ombre native — les mêmes gestes, le même journal

`JournalShadowService` (natif) : `deposer` (idempotent — la
modification REMPLACE, jamais deux écritures pour un mouvement) et
`retirer`, appelés AVANT le `save` de l'appelant pour que l'atomicité
du geste emporte l'ombre (FI-31 — `saveOrRollback`/`rollback`
existants). Branchés sur TOUS les sites de mutation mesurés :
`TransactionFormView` (création, édition, duplication, suppression),
`TransactionsListView` (duplication, suppression),
`HomeTab` (confirmation d'échéance du mois),
`CSVImportService` (chaque ligne importée + rollback du lot),
`OccurrenceConfirmationService` (le mouvement confirmé naît avec son
écriture dans la MÊME transaction). Un mouvement intraduisible ne
casse JAMAIS le geste : refus retourné et consigné (FI-34).
`JournalShadowServiceTests` (5 tests : dépôt persisté, remplacement
idempotent, retrait sans posting orphelin, geste survivant au refus,
confirmation atomique). Consigné : la restauration de sauvegarde
(`BackupService`) ne reconstruit pas d'écritures — historique = W3.7 ;
le lien `occurrenceID` du journal arrive avec la bascule W3.6.

### 25.08.2026 — W3.3 : l'ombre — chaque mutation écrit aussi son écriture

L'ombre PWA (ADR-058 étape 3) : `ombreJournalDepot` (idempotent —
redéposer REMPLACE, jamais deux écritures pour un mouvement) et
`ombreJournalRetrait`, branchés sur TOUS les sites de mutation mesurés :
`addTx` (création — formulaire, récurrences, factures, import),
l'édition du formulaire (remplacement de l'écriture, mêmes clés),
`fDelete`, `bUnpay`, `rollbackLastImport` (retraits) ; `deleteAllData`
et `undoLast` couvraient déjà le journal (W3.1). Un mouvement
intraduisible ne casse JAMAIS le geste : son refus est consigné dans
`JOURNAL_OMBRE_REFUS` (lisible par le comparateur W3.4), jamais perdu
en silence (FI-34). Incident réel attrapé par la suite : les `const`
du journal déclarées APRÈS le premier chargement cassaient le reload
(zone morte temporelle dans `validatedRestoreState`) — constantes
remontées avant `loadState`, reload verrouillé par le parcours 2
existant. Preuves : parcours 192 né rouge (7 échecs nommés) → vert ;
sabotage (retrait d'ombre supprimé dans `fDelete`) → le SEUL contrôle
de suppression mord ; restauré vert ; suites complètes vertes (192
e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : l'ombre NATIVE (services + saisie SwiftUI) = W3.3b ; les
mouvements HISTORIQUES (démo, legacy, états existants) n'ont pas
d'écriture avant la migration W3.7 — le comparateur W3.4 en tiendra
compte.

### 25.08.2026 — W3.2 : les écritures types — chaque mouvement se traduit

Le traducteur transforme CHAQUE type de mouvement existant en écriture
équilibrée SANS modifier le mouvement (SHADOW — l'ombre = W3.3). PWA :
`ecritureDepuisMouvement` (dépense, rentrée, remboursement FI-24,
impôts, ajustement directionnel, mensualité de dette `r-debt-` → jambe
`dette:` FI-14, virement/mise de côté/investissement = UNE écriture à
deux comptes réels FI-09, change = 4 jambes par devise depuis
l'ESTAMPILLE `destAmount` — jamais un taux recalculé FI-19) et
`ecritureOuverture` (FI-12 — zéro n'écrit rien, négatif inverse les
jambes) ; refus nommés : mouvement interne sans destination, change
sans estampille, montant à plus de deux décimales (`centimesStricts`,
jamais l'ancien `toCents` qui coerce en zéro). Natif :
`JournalTranslationService` (même contrat ; un change sans montant
estampillé est REFUSÉ — le natif n'estampille pas encore, consigné
pour W4 ; ouverture datée de `createdAt` — la PWA n'a pas de date de
création de compte et ancre à `1970-01-01`, divergence consignée à
raffiner en W3.7). Preuves : parcours 191 né rouge (10 échecs nommés)
→ vert ; sabotage (virement traduit en jambe `depense:Virement`) → le
SEUL contrôle FI-09 mord ; restauré vert ;
`JournalTranslationServiceTests` (8 tests) ; suites complètes vertes
(191 e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).

### 25.08.2026 — W3.1 : le journal naît — centimes entiers, équilibre par devise

W3 s'ouvre (Work Order : `docs/autonomie/w3/WORK_ORDER_W3.md`) sur la
porte d'entrée du journal, des deux côtés, en OMBRE totale (ADR-058 :
aucune vue ne lit, aucune mutation n'écrit — l'ombre arrive en W3.3).
ADR-063 : le journal stocke des CENTIMES ENTIERS + devise (la question
a été posée au propriétaire, écartée « continue » ; les autorités
`DATA_MODEL_TARGET.md` + ADR-059 tranchent). PWA :
`creerEcritureJournal` (porte unique), `equilibreParDevise`,
`validerPostingJournal`, clé additive `journal` (seeds, restauration
filtrante FI-34, `deleteAllData`, undo). Natif : `Money` (frontière
`Decimal` ↔ centimes EXACTE, arrondi déterministe `.plain`, refus du
NaN), `JournalEntry`/`JournalPosting` (fabrique `equilibree(...)`,
refus typés français, clé d'idempotence unique), schéma V12 additif.
Preuves : parcours 190 né rouge (8 échecs nommés) → vert ; sabotage
(équilibre ignoré) → SEULS les 2 contrôles d'équilibre mordent, la
garde de restauration reste indépendante ; restauré vert ; `MoneyTests`
+ `JournalEntryTests` (équilibre par devise, triche multi-devise
refusée, unicité de clé, migration disque V11 → V12, FI-35) ; suites
complètes vertes (190 e2e, 9 parités, 13 canon + schéma, design,
catalogue, audit dépôt). Consigné : l'écriture d'ouverture (FI-12) et
les écritures types arrivent en W3.2 ; la décision de migration de
l'historique reste ouverte pour W3.7.

### 25.08.2026 — W2.7b : le geste confirme l'échéance — W2 se ferme

Le MÊME geste, le MÊME mouvement qu'avant (aucune forme ne change,
aucun test verrouillé ne bouge) — mais l'échéance persistée est
désormais confirmée et LIÉE par la machine à états. Supprimer le
mouvement (feuille, facture remise à payer, retrait d'un import)
efface l'échéance — jamais un lien pendu — et elle renaît « À
confirmer » à la re-matérialisation ; l'undo restaure aussi les
occurrences. Parcours 189 (7 volets) né rouge (3 échecs nommés) ;
sabotage mordant DEUX FOIS (le contrôle direct ET le comparateur ont
attrapé le lien pendu indépendamment — la gate W2.7a est vivante).
CONSIGNÉ : la LECTURE des occurrences par les pages (inbox) arrive
avec W5 — les compteurs actuels restent la source affichée, prouvés
équivalents par le comparateur ; la correction traçable d'un mouvement
confirmé (au lieu de sa suppression) arrive avec le journal W3 ;
fixtures canoniques v2 (états) au schéma v2 avec W3. FI-03/04/05
passent à TENUS côté moteur.

### 25.08.2026 — W2.7a : le comparateur ancien/nouveau (ADR-058 étape 4)

Avant toute bascule de lecture : `comparerOccurrencesEtCompteurs`
prouve que les occurrences matérialisées racontent EXACTEMENT la même
histoire que les compteurs vivants (`recurringRemainingCount`), mois
par mois, couverture des mouvements liés simulée (la vraie liaison vit
en W2.7b). Parcours 188 : ZÉRO écart sur trois mois avec récurrences
mixtes et mouvement lié ; né rouge (comparateur absent) ; sabotage
mordant (couverture oubliée → écart nommé `r-loyer … compteur 0,
occurrences ouvertes 1`).

### 25.08.2026 — W2.6 : une facture est une occurrence sans série

PWA : `materialiserFactures(y, m)` — clé `facture:<id>` idempotente,
occurrence SANS série liée par `billId`, montant de la facture, état
honnête (courue → « À confirmer », future → « Prévu ») ; une facture
déjà couverte ne matérialise rien (sa liaison aux occurrences
confirmées arrive avec la bascule W2.7, consigné). Parcours 187 né
rouge (5 échecs nommés) ; sabotage mordant (la couverte matérialisée
nommée). CONSIGNÉ : le natif n'a PAS de modèle de facture ponctuelle —
son équivalent naîtra avec l'inbox (W5) sur le modèle d'occurrence
déjà partagé ; aucun faux miroir n'est créé en attendant.

### 25.08.2026 — W2.5 : reporter, ignorer, annuler — jamais d'argent

Des gestes d'AGENDA : aucun mouvement créé ni touché. Reporter déplace
l'échéance en gardant la date d'ORIGINE ; une date illisible et un
geste interdit (reporter une confirmée) sont refusés nommément, rien ne
bouge. Natif : `snooze(to:at:)`/`skip(at:)`/`cancel(at:)` par la
machine — 3 tests. PWA : `reporterOccurrence`/`ignorerOccurrence`/
`annulerOccurrence`. Parcours 186 né rouge (6 échecs nommés,
implémentation retirée puis restaurée). Toujours SHADOW (ADR-058).

### 25.08.2026 — W2.4b : la confirmation atomique

Un geste écrit LE mouvement lié ET l'état — jamais l'un sans l'autre.
Natif : `OccurrenceConfirmationService.confirm` (transition d'abord,
insertion, lien, save ; échec de save → rollback COMPLET, FI-31/32) ;
double tap retrouve le mouvement (FI-04) ; montant attendu conservé à
côté du montant réel (FI-05) ; montant manquant = erreur nommée, jamais
zéro (FI-34) ; le mouvement porte la date de l'ÉCHÉANCE — 5 tests.
PWA : `confirmerOccurrence` mêmes règles (validation avant écriture,
retour d'état sur échec d'estampillage). Parcours 185 né rouge
(5 échecs nommés) ; sabotage mordant (idempotence retirée → double
écriture nommée). Toujours SHADOW : les boutons « Reçu/Payé » actuels
basculeront en W2.7.

### 25.08.2026 — W2.4a : une date n'est pas une preuve (ADR-062)

Décision propriétaire (question posée, réponse consignée) : case
« C'est déjà fait (payé ou reçu) » cochée par défaut pour une date
passée, décochable — la personne décide, jamais la seule date ; le
futur n'a pas de case. PWA : case dans la feuille, statut suit la case,
note honnête qui suit la case ; édition = statut réel. Natif :
`initialStatus(for:now:alreadyDone:)` + Toggle dans les deux parcours ;
`automaticStatus` reste pour les gestes explicites et l'import (W7).
Parcours 184 né rouge (4 échecs nommés) ; sabotage mordant (case
ignorée → solde faussé nommé) ; test natif ajouté ; captures 320/390
inspectées.

### 25.08.2026 — W2.3 : la machine à états des échéances

Les MÊMES transitions sur les deux plateformes : « Confirmé » et
« Annulé » terminaux (une correction passera par le journal, jamais par
un retour d'état — FI-07 en germe), « Ignoré » se rouvre vers « À
confirmer » seulement, « Échec » se retente par la porte, le temps ne
recule pas, payer en avance est permis. Natif : `transition(to:at:)`
seule porte, erreur typée nommée, confirmation horodatée — 8 tests.
PWA : `transitionOccurrence` même table, erreur en français. Parcours
183 né rouge (5 échecs nommés) ; sabotage mordant (« Confirmé » rendu
réversible → refus disparu nommé). Toujours SHADOW (ADR-058).

### 25.08.2026 — W2.2 : matérialisation idempotente des échéances

Natif : `OccurrenceMaterializationService` — dates du service de
calendrier EXISTANT (aucune nouvelle arithmétique), clé canonique,
re-matérialiser ne duplique jamais et ne réécrit JAMAIS un état vécu
(un report survit, l'origine ne bouge pas) ; état de naissance honnête
(passé → « À confirmer », futur → « Prévu », jamais confirmé) ; deux
échéances dans un mois = deux clés (REC2). PWA :
`materialiserOccurrences(y, m)` — même idempotence, sémantique
d'échéance PWA (dû dans le mois, décision du 06.08.2026 — l'unification
des sémantiques de date passera par les fixtures W2.7, consigné).
Parcours 182 né rouge (6 échecs nommés), sabotage mordant (doublons) ;
les deux restent SHADOW : rien ne les lit (ADR-058). Publication W2.1
vérifiée (run `32843135559`, succès).

### 25.08.2026 — W1 fusionné et publié · W2.1 livré

Train de fusion exécuté (#128 → #131), publication au SHA exact
`7814cb8` (run `32840603822`, succès). W2.1 : `ScheduledOccurrence`
natif (identité, états du glossaire W0, montant attendu conservé,
clé d'idempotence UNIQUE, date d'origine immuable) + `BudgetSchemaV11`
additif + tests (unicité par upsert, report, état inconnu → « Prévu »
jamais « Confirmé », migration disque V10→V11 données intactes) ;
PWA : clé additive `occurrences` inerte (shadow-write ADR-058),
restauration entrée par entrée (l'hostile est abandonné — parcours 181
né rouge, sabotage mordant), « Tout effacer » la vide. AUCUNE vue ni
aucun agrégat ne lit encore les occurrences.

### 25.08.2026 — W1.6/W1.7 : les deux runners canoniques + gate CI

Runner Web (`webapp/tests/canon.test.mjs`) : chaque fixture est semée
dans l'app réelle (Chromium), le moteur est appelé en page et comparé
aux attendus en unités mineures entières — 13 fixtures vertes. Double
contrôle négatif : attendu faussé → échec nommé ; moteur saboté
(balance compte le prévu) → 12 échecs nommés (FI-01 mord). Runner
Swift (`BudgetTests/CanonicalFixtureTests.swift`) : mêmes fichiers,
services réels, comparaison champ par champ — preuve par le job
simulateur CI. Écarts natifs CONSIGNÉS dans `enAttenteNatif` (jamais
un skip silencieux) : conversion FX des agrégats et soldes
multi-devises → W4 (constat n° 6). Gate CI : étape « Runner canonique
Web » au job navigateur ; le runner Swift vit dans le job simulateur.
FI-40 a désormais sa gate mécanique.

### 25.08.2026 — AUT-061 : le résultat du mois exclut l'épargne et le capital

Implémentation de l'ADR-061 (amendée : le capital de dette est exclu
comme l'épargne, FI-14/FI-21 — la mesure montrait d'ailleurs DEUX
formules : le natif soustrayait la dette, la PWA non). Contrat commun :
résultat = reçus − coût de vie − impôts, identique sur les deux
plateformes ; note du mois passé honnête. Parcours 180 né rouge
(3 échecs nommés, 1600 lu), sabotage mordant, 180 e2e verts ; test
natif aligné (5000, commenté) — preuve native = job simulateur CI.
Fixture canonique `resultat-du-mois` (210000) + champ optionnel
`resultatMineures` au schéma.


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
