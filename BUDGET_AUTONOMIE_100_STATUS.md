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
publication run `32874460073`, succès) · W3.4 fusionné (`main` =
`0145e8a`, PR #145, publication run `32876072008`, succès) · W3.5
fusionné et publié (`main` = `99f5fd0`, PR #146, publication run
`32879835694`, succès) · W3.5b fusionné (`main` = `ad82f42`, PR #147)
· W3.6 fusionné et publié (`main` = `1ba1d9c`, PR #148, publication
run `32882847907`, succès) · W3.6b fusionné et publié (`main` =
`bf2767f`, PR #149, publication run `32885036200`, succès) · W3.7
fusionné (`main` = `75c704b`, PR #150, publication run `32887978661`)
— **W3 est COMPLET** (ADR-064 : préparer sans allumer)** (Work Order :
`docs/autonomie/w3/WORK_ORDER_W3.md`).

### W4 — Comptes, devises, rapprochement (lot actif)

**État : W4.1 fusionné et publié (`main` = `5d6455f`, PR #151,
publication run `32891106635`, succès) · W4.2 fusionné et publié
(`main` = `ee3c68b`, PR #152, publication run `32900122934`, succès) ·
W4.2b fusionné et publié (`main` = `0522518`, PR #153, publication run
`32901342511`, succès) · W4.3 fusionné (`main` = `422f875`, PR #154,
publication run `32903417770`) · W4.4 fusionné et publié (`main` = `3407feb`, PR #155, publication
run `32905617064`) · W4.4b fusionné (`main` = `7a333a1`, PR #156) ·
W4.5 fusionné et publié (`main` = `162e1ff`, PR #157, publication run
`32907853689`, succès) · W4.6 fusionné et publié (`main` = `63d5140`,
PR #158, publication run `32909892236`, succès) · W4.7 fusionné
(`main` = `a08997f`, PR #159, publication run `32911953686`) — **W4
est COMPLET**** (Work Order :
`docs/autonomie/w4/WORK_ORDER_W4.md`). ADR-065 (« V1 base unique » —
décision propriétaire du 25.08.2026). ADR-063 (centimes entiers —
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
| W3 | Journal financier | DONE | W1, W2 (fusionnés) |
| W4 | Comptes, devises, rapprochement | DONE | W3 (fusionné) |
| W5 | Pages et inbox | DONE | W2, W3, W4 (fusionnés) |
| W6 | Plan, budgets, objectifs | DONE | W2, W3, W5 (fusionnés) |
| W7 | Import, règles, tags, splits | DONE (7 sous-lots fusionnés) | W1, W3, W6 (fusionnés) |
| W8 | Investissements et modules régionaux | W8.1–W8.5 fusionnés · W8.6 EN PR | W3, W4 (fusionnés) |
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

### 26.08.2026 — W8.6 : assurances & prévoyance — cadences réelles, genre, préavis, pilier, devise

Portés du natif `InsuranceContract`/`PensionAsset` (ADR-070). Mesuré :
l'écran PROMETTAIT « chaque trimestre » depuis L6 mais
`insuranceMonthly` ne connaissait que mois/année (une prime
trimestrielle comptait TROIS fois trop) — et le validateur de
restauration REJETAIT l'état entier sur une cadence inconnue (le
né-rouge du parcours 230 s'est manifesté ainsi : graine « corrupt »,
consigné) ; aucun genre de contrat ; aucun préavis ; aucun pilier
typé ; une prévoyance non liée en devise étrangère comptait comme du
CHF. Livré : cadences mois/trimestre/semestre/année (÷ 1/3/6/12,
DITES sur chaque ligne avec la prime), genre de contrat
(Santé/Ménage/Véhicule/Vie/Autre), « Résilier avant le … » CALCULÉ
(renouvellement − préavis, jamais un rappel vague), pilier typé
(1/2/3a/3b), devise des prévoyances non liées (sans taux → EXCLUE du
patrimoine, nommée au bandeau — désormais affiché sur cet écran —,
ligne dite en SA devise), restauration additive (cadence inconnue →
mois, champs illisibles retirés, les sains restent). Preuves : trois
sabotages qui mordent seuls (diviseurs neutralisés → 1 ; USD recompté
en CHF → 1 ; validateur redevenu intolérant → 1) ; captures 320/390
inspectées (`docs/neon-ultra/budget-prisme/w8-6/`) ; suites complètes
vertes (230 e2e, 9 parités, 14 canon + schéma, design, catalogue,
audits). Fusion W8.5 (`main` = `f6db489`, PR #188) et publication
**succès** consignées. INCIDENT de méthode consigné (W8.5) : le
commit avait d'abord été posé sur la branche W8.4 DÉJÀ fusionnée —
réparé par cherry-pick sur base `main` propre et restauration de la
branche fusionnée à son état exact ; leçon : vérifier
`git branch --show-current` avant chaque commit de lot.

### 26.08.2026 — W8.5 : impôts — retards nommés, provision par année (portés du natif)

Décision propriétaire (ADR-070) : porter échéances + provision du
modèle natif `TaxProvision`/`TaxService` — toujours AUCUN calcul
d'impôt (ADR-035 intact, verrou né vert). Mesuré : un acompte échu
s'affichait comme les autres (aucune alarme), et le report manuel
GLOBAL (`S.taxReserve`) s'affichait sur TOUTE année consultée avec la
même étiquette. Livré : section « En retard » nommée (pastille rouge,
bordure, « était à payer le … ») séparée de « Vos prochains
acomptes » ; provision PAR ANNÉE (`S.taxProvisions`, clé additive) via
la porte unique `definirProvisionImpots` (refus nommés : année
illisible, montant négatif/illisible) ; la feuille « Poser la
provision {année} » écrit l'année CONSULTÉE — le report hérité n'est
plus jamais réécrit et ne compte que pour l'année courante, étiqueté ;
restauration additive (entrée hostile écartée, les saines restent).
Test hérité 136 adapté au nouveau contrat (changement VOULU,
consigné : la feuille écrivait `taxReserve`, elle écrit désormais la
provision). Preuves : parcours 229 né rouge (5 échecs nommés) ; deux
sabotages qui mordent seuls (retards fondus dans les acomptes → 1 ;
report redevenu global → 1) ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w8-5/`) ; suites complètes vertes
(229 e2e, 9 parités, 14 canon + schéma, design, catalogue, audits).
Fusion W8.4 consignée (`main` = `59bcc5a`, PR #187) ; publication au
SHA exact : **succès**.

### 26.08.2026 — W8.4 : performance racontée — un chiffre, sa phrase, sa méthode

Décisions propriétaire (AskUserQuestion) : performance RACONTÉE simple
sans taux annualisé (ADR-070) ; et — question du jour — les FRAIS
payés depuis le compte titres restent des RETRAITS (statu quo : l'app
ne devine pas si une sortie est un frais ou une dépense personnelle,
elle ne catégorise rien en secret). Mesuré : la fiche disait
« Performance : ±P » et sa méthode, mais aucune phrase ne racontait
d'où vient le chiffre. Livré : « Depuis l'ouverture, vous avez versé X
et retiré Y — le compte vaut V aujourd'hui. La différence, c'est la
performance. » — la méthode reste, aucun pourcentage n'est promis, un
compte d'épargne ne porte pas de « Performance » (périmètre V1).
Preuves : parcours 228 né rouge (1 échec nommé ; verrous
méthode/sans-pourcent/hors-titres nés VERTS consignés) ; deux
sabotages qui mordent seuls (phrase retirée → 1 échec ; « 4.1 % par
an » inventé → le verrou sans-pourcent mord) ; captures 320/390
inspectées (`docs/neon-ultra/budget-prisme/w8-4/`) ; suites complètes
vertes (228 e2e, 9 parités, 14 canon + schéma, design, catalogue,
audits). Fusion W8.3c consignée (`main` = `39b909a`, PR #186) ;
publication au SHA exact : **succès** — **W8.3 FERMÉ**. Redémarrage de
conteneur en cours de lot : resynchronisation propre, PR #186 et
branche retrouvées intactes, rien de perdu.

### 26.08.2026 — W8.3c : le canon prouve les taux datés — FI-17 tenu jusque dans le moteur → W8.3 FERMÉ

Mesuré d'abord : le runner canon web APLATISSAIT les taux datés en un
cache (dates et sources perdues — le runner Swift sème des `FxQuote`
depuis W4.2b). La fixture née rouge a alors révélé une VRAIE
divergence de parité : le web injectait `FX_DEFAULTS` en silence quand
`fxRates` manquait (un compte USD compté à 0.80 codé en dur — un
défaut n'est pas une mesure) et le validateur de restauration
REJETAIT l'état entier au premier compte étranger sans taux, là où le
natif CHARGE et EXCLUT (`NetWorthService`). Livré : runner canon qui
sème les quotes datées telles quelles + auto-contrôle « quotes semées
= taux fournis » ; fixture `devise-taux-absent-incomplet` (FI-17,
différée depuis W1.5 — les 14 fixtures passent des DEUX côtés, le
natif excluait déjà) ; plus AUCUNE injection silencieuse de
`FX_DEFAULTS` (normalisation, restauration — les défauts restent des
choix explicites : pays, onboarding, pré-remplissage du formulaire) ;
un compte étranger sans taux charge, est exclu des totaux et NOMMÉ au
bandeau ; Réglages dit « à saisir » au lieu d'afficher un défaut comme
actif ; les devises des MOUVEMENTS gardent leurs exigences (taux
courant + estampille FI-19). Incident de sonde consigné : la première
suppression de garde a retiré `usedCurrencies` encore référencé plus
bas → 83 échecs canon (ReferenceError silencieuse en « corrupt ») —
corrigé, Set désormais alimenté par les seuls mouvements. Preuves :
né-rouge en DEUX temps (auto-contrôle runner : 2 échecs nommés ;
fixture FI-17 : rouge à 160000 — la divergence mesurée) ; deux
sabotages qui mordent seuls (runner qui cesse de semer → 2 échecs ;
`toCHF` qui invente du 1:1 → la fixture attrape 170000) ; captures
320/390 du Réglages inspectées
(`docs/neon-ultra/budget-prisme/w8-3c/`) ; suites complètes vertes
(227 e2e, 9 parités, **14** canon + schéma, design, catalogue,
audits). Publication W8.3b (`main` = `e170082`, PR #185) : **succès**
(dispatch APRÈS CI push verte — leçon W8.3a appliquée). **W8.3 est
FERMÉ** (a : conversion datée des stocks ; b : devise des biens +
historique ; c : preuve canon + FI-17 moteur).

### 26.08.2026 — W8.3b : devise des biens — conversion datée, historique de valorisations

Mesuré d'abord : actifs et dettes SANS devise (un bien en EUR compté
comme du CHF en silence) ; une seule valeur écrasée à chaque édition
(courbe fausse dès la première revalorisation) ; bandeau « non
convertibles » aveugle aux biens. Livré (ADR-070) : devise par bien
(défaut = devise de base, sélecteur dans la fiche) ;
`assetsTotalCHF`/`liabilitiesTotalCHF` (taux manquant → bien EXCLU et
NOMMÉ au bandeau, jamais de 1:1 inventé) ; historique de valorisations
APPEND-ONLY à l'édition (l'ancienne valeur garde sa date) ;
`valeurAuMois` ; la courbe de patrimoine date les biens (valeur ET
taux du moment ; le solde des dettes reste vivant — l'historique de
solde n'est pas modélisé, consigné) ; restauration additive (devise
illisible retirée → base, entrée d'historique hostile écartée, les
saines restent). La prévoyance suivra en W8.6 (divergence Work Order
consignée : lot gardé focalisé). Preuves : parcours 227 né rouge
(6 échecs nommés, après une garde d'existence de sonde) ; trois
sabotages qui mordent seuls (valeurAuMois sans dates → 1 ; biens
bruts → 1 ; bandeau aveugle → 1) ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w8-3b/`) ; suites complètes vertes
(227 e2e, 9 parités, 13 canon + schéma, design, catalogue, audits).
PUBLICATIONS consignées : le run W8.2 re-dispatché (`32984565895`)
est resté COINCÉ en file (dégradation GitHub Actions, annulation
refusée « not queued yet ») ; premier dispatch W8.3a (`32994684422`)
en échec de GATE (la CI push de `c76e183` tournait encore) ;
re-dispatch après CI push verte : run `32996084747`, **succès** — il
couvre W8.2 ET W8.3a (SHA `c76e183` inclut les deux). Le vieux run
reste surveillé : s'il aboutissait après coup, `c76e183` serait
re-dispatché pour que le dernier SHA gagne.

### 26.08.2026 — W8.3a : taux datés — la courbe de patrimoine ne se réécrit plus (ADR-070)

Mesuré d'abord : chaque point mensuel des courbes de patrimoine
convertissait les soldes au taux COURANT (`toCHF`) — changer un taux
réécrivait rétroactivement l'histoire des STOCKS, alors que
`S.fxQuotes` (daté, sourcé, append-only — W4.2) n'était JAMAIS lu pour
convertir. Décisions propriétaire du jour (AskUserQuestion, consignées
en ADR-070) : devise de BASE par défaut pour les biens existants
(W8.3b) ; performance V1 RACONTÉE sans taux annualisé (W8.4) ; port
des échéances d'acomptes et de la provision annuelle du natif (W8.5).
Livré : `tauxAuJour(devise, date)` (dernière quote consignée à la
date, null sinon — un défaut n'est pas une mesure) ; `toCHFAuMois`
(la mesure du moment fait foi ; avant la première mesure, la première
mesure — elle ne bouge plus ; sans aucune mesure, le cache actuel,
comportement historique consigné) ; les séries 12 mois (globale et par
classe) passent par la conversion datée. Preuves : parcours 226 né
rouge (6 échecs nommés) ; deux sabotages — le premier (classe repassée
au taux courant) INERTE au premier passage car le contrôle acceptait
UNE polyligne non plate (la globale suffisait) → contrôle DURCI (au
moins deux polylignes non plates, l'« Argent disponible » en CHF pur
restant le témoin plat), le sabotage mord ; `tauxAuJour` sans date →
5 échecs. Captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w8-3a/`) ; suites complètes vertes
(226 e2e, 9 parités, 13 canon + schéma, design, catalogue, audits).
INCIDENT de publication W8.2 (`main` = `efd16c1`, PR #183) : premier
run `32984252482` en `startup_failure` (échec AVANT tout job — côté
GitHub), re-dispatch au même SHA lancé, verdict consigné dès la fin.

### 26.08.2026 — W8.2 : positions — plus-value honnête, devise du prix enfin lue

Mesuré d'abord : `costBasis` stocké sans plus-value PAR POSITION ;
`priceCurrency` stocké et JAMAIS lu (une position au prix en USD était
affichée et ADDITIONNÉE comme du CHF — violation « aucune addition
sans conversion ») ; la devise d'un compte à positions SANS mouvement
restait modifiable (désynchro silencieuse) ; la date de saisie du
prix, elle, était déjà montrée (divergence avec le Work Order,
consignée). Livré : plus-value par position quand le prix d'achat est
connu ET comparable (même devise) — jamais de zéro inventé — dite avec
sa méthode (« valeur moins prix d'achat saisi ») ; prix et valeur dits
dans la devise du PRIX ; position en devise étrangère écartée du « non
réparti » avec écart NOMMÉ (la conversion datée viendra en W8.3) ;
devise du compte verrouillée dès qu'une position existe — à la feuille
ET à la soumission (le DOM ne fait pas foi). Preuves : parcours 225 né
rouge (4 échecs nommés ; verrous « pas de zéro inventé » et « les
positions expliquent le solde » nés verts, sabotages à l'appui) ;
TROIS sabotages — dont un INERTE au premier passage (le verrou de
soumission retiré ne mordait pas : le test ne contrôlait que
l'attribut `disabled`) → test DURCI (champ forcé + soumission réelle),
le sabotage mord ; addition étrangère rétablie → 1 échec ; zéro
inventé → 1 échec. Captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w8-2/`) ; suites complètes vertes
(225 e2e, 9 parités, 13 canon + schéma, design, catalogue, audits).
Publication W8.1 (`main` = `bb8fd30`, PR #182) : run `32980063152`,
**succès**.

### 26.08.2026 — W8.1 : cash flows — versements nets exposés, retraits datés

Mesuré d'abord : la fiche d'un compte de placement collait un CUMUL DE
TOUJOURS (« retraits ») à un chiffre annuel (« Mis de côté cette
année »), et le versement NET (versé − retiré) n'était dit nulle part.
DIVERGENCE consignée avec le Work Order : le cas « un achat de titres
depuis le compte titres compté en retrait » n'existe PAS dans le
modèle (aucun type d'achat, positions déconnectées des mouvements — la
formule actuelle, qui traite toute sortie comme un retrait, est
défendable) ; la question « frais de courtage : retrait ou coût qui
réduit la performance ? » est reportée à W8.4 comme décision
propriétaire. Livré : `contributions()` rend aussi `withdrawnYear` et
`net` (centimes entiers, clés additives) ; la fiche dit « retiré
cette année » (daté) et « Depuis l'ouverture : versé · retiré ·
Versements nets » ; la performance passe par `c.net` (même valeur,
même méthode affichée « Valeur − versements nets »). Preuves :
parcours 224 né rouge (4 échecs nommés ; verrou performance né VERT
consigné, sabotage à l'appui) ; deux sabotages qui mordent seuls
(retrait annuel redevenu cumul → 1 échec ; net qui oublie les
retraits → 2 échecs dont le verrou) ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w8-1/`) ; suites complètes vertes
(224 e2e, 9 parités, 13 canon + schéma, design, catalogue, audits).
Publication du plan W8 (`main` = `ba16218`, PR #181) : run
`32976120699`, **succès**.

### 26.08.2026 — W7.7 : revue d'import — écarter ligne par ligne, annuler lot par lot → W7 FERMÉ

Mesuré d'abord : l'aperçu d'import était TOUT-OU-RIEN (aucun refus
ligne par ligne) et le rollback ne visait que le DERNIER lot
(`rollbackLastImport`). Livré : `applyImport(analysis, fileName,
accountId, exclues = [])` — une ligne prête écartée à la revue n'est
JAMAIS écrite mais reste CONSIGNÉE au journal (verdict « refused »,
motif « Écartée à la revue », compteurs justes) ; `rollbackImport(id)`
CIBLÉ (n'importe quel lot du journal, `rollbackLastImport` devient un
cas particulier ; un lot hérité sans entrée au journal reste annulable) ;
restauration : `VERDICTS_IMPORT` admet « refused » (clé additive) ;
UI : toggle « Écarter/Reprendre » (`data-imprefuse`) sur chaque ligne
prête de l'aperçu (pastille « Écartée », décomptes nets, bouton de
confirmation au juste compte) + section « Journal des imports »
(8 derniers lots, reste annoncé, annulation par lot `data-rollbacklot`,
lots annulés marqués sans bouton). Deux pluriels codés en dur corrigés
(« 1 opération »). Preuves : parcours 223 né rouge (8 échecs NOMMÉS,
après correction d'un crash de sonde — `importDraft.mapping: null`
alors que le flux réel construit `{ ...analysis.columns }`) → vert ;
TROIS sabotages qui mordent seuls (l'exclusion écrit quand même → 3
échecs ; rollback non ciblé qui vide tous les lots → 2 échecs ;
restauration qui rejette « refused » → 1 échec) ; restauré vert ;
captures 320/390 inspectées (`docs/neon-ultra/budget-prisme/w7-7/`) ;
suites complètes vertes (223 e2e, 9 parités, 13 canon + schéma,
design, catalogue, audit dépôt, catalogue d'identités). INCIDENT de
méthode consigné : un `git checkout` de nettoyage de sabotage a
emporté l'implémentation non commitée (réappliquée à l'identique,
revalidée) — leçon : COMMIT AVANT sabotage, toujours. Consigné : le
natif suivra avec les écrans iOS de W7 (miroir des exclusions et du
rollback ciblé — `CSVImportService.rollback(batchID:)` existe déjà).
**W7 est FERMÉ** (7 sous-lots fusionnés). FUSIONNÉ (`main` = `6bd2199`,
PR #180, CI verte sur le HEAD exact `74391e9`) ; publication par
dispatch au SHA exact `6bd2199` : run `32973930646`, **succès**
(poll observé jusqu'à `completed success`).

### 26.08.2026 — W8 : Work Order écrit (mode plan)

`docs/autonomie/w8/WORK_ORDER_W8.md` — fondé sur une mesure complète
de l'existant (agent d'état des lieux, réconcilié avec le code).
Constats moteurs : la courbe de patrimoine convertit les STOCKS au
taux COURANT (rétroactif — FI-19 tenu pour les mouvements seulement) ;
`S.fxQuotes` datées jamais lues pour convertir ; actifs/dettes/
prévoyances/primes SANS devise ; plus-value PAR POSITION absente
(celle du compte titres existe et dit sa méthode — contre-mesure
consignée au Work Order) ; impôts/assurances :
modèles natifs riches non portés ; runner canon qui aplatit les taux
datés. Sept sous-lots ordonnés, trois décisions propriétaire à poser
(devise des actifs existants, forme de la performance V1, portée de
la provision fiscale). Non-objectifs tenus : pas de cours de marché,
pas de FIFO/PRU, pas de TWR/IRR, pas de nouveau pays/devise.

### 26.08.2026 — W7.6 : règles — « ce libellé → cette catégorie », le futur seulement

Décision propriétaire (AskUserQuestion, consignée avec ADR-069) :
**futur seulement** — le passé ne bouge jamais tout seul. Livré :
porte unique `creerRegle(motif, cat)` (refus nommés — motif vide,
catégorie inconnue, motif déjà pris ; motifs PLIÉS, bornés 40 car.) ;
`catParRegle(titre)` (première règle dont le motif est contenu dans
le libellé plié) ; la règle s'applique à l'ANALYSE d'import — donc
PRÉVISUALISÉE dans l'aperçu avant toute écriture — et seulement si
son sens (dépense/revenu) est celui de la ligne ; la colonne
catégorie de la SOURCE prime toujours ; la saisie manuelle garde la
main (aucune règle silencieuse au formulaire — consigné) ; UI sur
l'écran Import : « Règles de catégorisation » (liste + création +
suppression, honnêteté écrite « le passé ne bouge jamais tout
seul ») ; restauration : clé additive, règle hostile écartée (le
référentiel jugé est celui de l'état RESTAURÉ, catégories libres
comprises). Preuves : parcours 222 né rouge (9 échecs nommés ; un
faux rouge de route corrigé — la clé est `importcsv`, pas `import`) →
vert ; sabotage (une passe rétroactive silencieuse à la création) →
« l'histoire ne bouge pas » mord SEUL ; restauré vert ; captures
320/390 inspectées (`docs/neon-ultra/budget-prisme/w7-6/`) ; suites
complètes vertes (222 e2e, 9 parités, 13 canon + schéma, design,
catalogue, audit). Consigné : proposer la règle à la SAISIE (préremplissage
suggéré, jamais imposé) attendra un besoin mesuré ; miroir natif avec
les écrans iOS de W7. FUSIONNÉ (`main` = `739137a`, PR #179) ;
publication par dispatch au SHA exact : **succès** (elle couvre aussi
W7.5, dont la gate avait mordu — consigné ci-dessous).

### 26.08.2026 — W7.5 : splits — une dépense, plusieurs catégories, la somme exacte (ADR-069)

Fusionné (`main` = `4b439a6`, PR #178). INCIDENT CI consigné : la CI
de main sur ce SHA a mordu — le contrôle « rollback tracé » du
parcours 217 a échoué sur le coureur rapide : deux `applyImport` dans
la MÊME milliseconde partageaient un `batchId` (`Date.now()` seul) et
le rollback marquait le MAUVAIS lot. Vrai défaut d'unicité, corrigé
dans la PR W7.6 (id = temps + rang dans le journal, contrôle
`idsUniques` ajouté au 217, durci sur « le premier lot reste non
marqué ») ; la publication W7.5 (échec de gate, run `32966550667`)
est COUVERTE par la publication W7.6 au SHA suivant — consigné, rien
de silencieux.
Décision propriétaire (AskUserQuestion) : les parts vivent **dans le
mouvement** → ADR-069 (décision jumelle consignée : W7.6 règles =
futur seulement). Livré : porte unique `definirParts` (refus nommés —
somme fausse, moins de deux parts, catégorie inconnue, centimes non
entiers, devise étrangère V1) ; clé additive `parts` en centimes
ENTIERS, somme EXACTE ; le solde ne bouge pas d'un centime (un seul
flux bancaire) ; les rapports par catégorie VENTILENT (lignes du
Budget via `actualCentsForCat`, « Pas encore classé » part par
part) ; UI : « Scinder : une 2e catégorie » dans la feuille (le reste
garde la catégorie principale, calcul exact 89.99 → 59.99 + 30.00),
préremplie au retour, note « Scindé : … » ; ventilation périmée
(montant changé) retirée plutôt que mensongère ; restauration : des
parts qui mentent sont retirées, le mouvement reste vrai. Preuves :
parcours 221 né rouge (8 échecs nommés) → vert ; sabotage (la
ventilation des lignes coupée) d'abord INERTE — le contrôle ne
passait que par le hors-budget : durci (ligne budgétaire + hors-
budget + absence de doublon), il mord alors SEUL ; restauré vert ;
captures 320/390 feuille + Budget inspectées
(`docs/neon-ultra/budget-prisme/w7-5/`) ; suites complètes vertes
(221 e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : le miroir natif (parts sur BudgetTransaction +
BudgetVarianceService) suivra avec les écrans iOS de W7 ; l'UI à N
parts attendra un besoin mesuré.

### 26.08.2026 — W7.4 : « Imprévu » — le repli honnête, jamais une fausse catégorie

Fusionné (`main` = `e089f64`, PR #177) et publié par dispatch au SHA
(succès). Mesuré : la saisie forçait une catégorie existante ou l'écriture
libre — rien pour dire honnêtement « je ne sais pas encore », donc
une fausse catégorie silencieuse. Livré : « Imprévu » entre au
référentiel (`CATEGORIES`, dépense ordinaire — budgétable comme les
autres, une enveloppe « Imprévu » est possible) ; le sélecteur de
catégorie d'une DÉPENSE le propose en fin de liste avec son langage
honnête (« Imprévu — à reclasser plus tard ») — jamais en défaut
silencieux ; sans enveloppe, le Budget le nomme dans « Pas encore
classé » comme les autres (rien n'est perdu, rien n'est déguisé) ;
absent des impôts et des revenus (sens financier protégé). Preuves :
parcours 220 né rouge (6 échecs nommés) → vert ; sabotage (le
langage honnête se tait : « Imprévu » nu) → langageHonnete mord
SEUL ; restauré vert ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w7-4/`) ; suites complètes vertes
(220 e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : le reclassement guidé (retrouver les « Imprévu » du mois
et les ranger) est le geste naturel de la review queue W7.7 ; le
miroir natif suivra avec les écrans iOS de W7.

### 26.08.2026 — W7.3 : tags — vos mots sur un mouvement, retrouvables

Fusionné (`main` = `eaddaa0`, PR #176) et publié par dispatch au SHA.
Mesuré : un mouvement n'a qu'une catégorie ; aucun moyen d'y poser SES
mots (« vacances », « remboursable ») ni de les retrouver. Livré :
clé additive `tags` (esprit CAT1 — la personne écrit ses mots) —
champ « Tags (facultatif) » dans la feuille du mouvement (création et
édition, prérempli au retour), normalisation à la soumission (pliés,
dédupliqués insensible à la casse, vides retirés, bornés 5 × 24
caractères), stockés seulement s'il y en a (un mouvement sans tags ne
porte pas la clé) ; la recherche de l'Historique trouve par tag (le
placeholder le dit) ; restauration : tags hostiles ASSAINIS (types,
vides, longueurs) sans jamais bloquer — des mots ne refusent pas une
restauration. AUCUN agrégat ne lit les tags : des mots, pas de
l'argent. Preuves : parcours 219 né rouge (6 échecs nommés ; un crash
de sonde corrigé en garde — leçon connue) → vert ; sabotage (la
normalisation saute, tags bruts) → 3 contrôles du 219 mordent
(normalisation, préremplissage, re-soumission), rien d'autre ;
restauré vert ; captures 320/390 feuille + recherche inspectées
(`docs/neon-ultra/budget-prisme/w7-3/`) ; suites complètes vertes
(219 e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : le natif n'a pas de champ tags (BudgetTransaction) — le
miroir viendra avec les écrans iOS de W7 ; l'affichage d'un badge tag
sur la ligne de l'Historique attendra un besoin mesuré (la recherche
suffit à retrouver).

### 26.08.2026 — W7.2 : import — l'identité d'une ligne est normalisée (FI-29)

Fusionné (`main` = `6023507`, PR #175 — après un correctif consigné :
le test historique `testDuplicateRowsInsideTheSameFileAreCaughtOnce`
assertait l'ancien comportement bogué, aligné sur l'identité
normalisée, CI verte sur le HEAD exact `eec8909`) et publié par
dispatch au SHA. Les fixtures « doublons d'import » DIFFÉRÉES depuis W1.5 sont livrées :
la fixture PARTAGÉE `fixtures/import-doublons.json` est lue par les
DEUX plateformes. Mesuré : le web tenait déjà FI-29 (empreinte sans
nom de fichier, pliée, dédupliquée en fichier) — ses contrôles sont
des VERROUS ; le NATIF avait le défaut exact de l'audit : l'empreinte
`CSVImportService` incluait `fileName` + `rowIndex` → un relevé
RENOMMÉ créait des doublons, et deux lignes identiques d'un même
fichier n'étaient JAMAIS dédupliquées. Livré natif :
`normalizedFingerprint(date, montant, type, libellé plié)` — ni nom
de fichier ni numéro de ligne ; `existingNormalizedFingerprints
(transactions:)` (un mouvement saisi à la main bloque aussi le
doublon d'import) ; `validate(...)` gagne le paramètre additif
`existingNormalizedFingerprints` et marque doublon sur l'identité
NORMALISÉE (en fichier et contre l'existant) ; l'empreinte legacy
reste calculée (compatibilité) ; `ImportRowResult.normalizedFingerprint`
additif. `ImportDoublonsFixtureTests` (2) rejoue la fixture partagée —
sur l'ancienne implémentation, « rejeuRenomme » rendrait ready ≠
duplicate par construction (le rouge natif est le défaut mesuré ; la
CI verte sur le HEAD prouve le fix). Web : parcours 218 (verrous nés
verts assumés) ; DEUX sabotages : la casse cesse d'être pliée →
casseDifferente mord SEUL ; une séquence entre dans l'empreinte (le
défaut natif simulé) → 7 contrôles crient à travers TROIS parcours
(L7 historique, 217, 218) — le filet est multi-couches ; premier
sabotage « sel temporel » consigné INERTE (même milliseconde → même
sel) et remplacé. Suites complètes vertes (218 e2e, 9 parités, 13
canon + schéma, design, catalogue, audit) ; tests natifs prouvés par
le job simulateur CI. FI-29 passe d'OUVERT à TENU (registre W0 —
consigné ici, le registre est un document d'audit figé).

### 26.08.2026 — W7.1 : import — chaque ligne garde sa source et son verdict

Fusionné (`main` = `9483874`, PR #174, prête via curl) et publié par
dispatch au SHA exact (run consigné au poll). Mesuré : l'analyse CSV (ready/duplicate/invalid) et l'empreinte
existaient, mais RIEN n'était conservé — `S.lastImport` garde un
résumé, le verdict de chaque ligne se perdait, le rollback oubliait
tout. Livré (modèle intermédiaire, la porte existante reste LA
porte) : journal d'imports persisté `S.imports` (append-only) — un
LOT par application {id, fichier, compte, appliedAt ISO, total,
imported, records} ; un ENREGISTREMENT SOURCE par ligne {line,
verdict nommé, fingerprint (ready/duplicate), motif (invalid),
rawHash — JAMAIS le texte brut (vie privée, hash djb2), txId (lien
vers le mouvement créé)} ; rejouer un relevé n'écrit rien ET se
consigne (l'histoire des tentatives est complète) ; le rollback est
TRACÉ (`rolledBackAt`) — le journal survit ; restauration : clé
additive, lots illisibles écartés (verdict inconnu, brut présent),
lots sains gardés. Preuves : parcours 217 né rouge (8 échecs nommés ;
un crash de sonde corrigé en garde d'existence — leçon connue) →
vert ; sabotage (le brut fuit dans le journal) → les DEUX contrôles
vie-privée mordent (stockage + restauration), rien d'autre ; restauré
vert ; suites complètes vertes (217 e2e, 9 parités, 13 canon +
schéma, design, catalogue, audit). Aucune capture (aucun pixel — la
review queue arrive en W7.7). Consigné : le miroir natif
(CSVImportService : SourceRecord/fingerprints normalisés) suivra en
W7.2 avec les fixtures doublons W1.5.

### 26.08.2026 — W6 FERMÉ · Work Order W7 écrit

W6.5+W6.6 fusionnés (`main` = `e6144f6`, PR #173, prête via curl —
même contournement de jeton que #172) et publiés (run `32950092605`).
INCIDENT CI consigné : le premier HEAD `c2039ef` a échoué au
simulateur iOS (« Type 'GoalKind' has no member 'emergency' » — mon
test natif utilisait un cas inexistant, le vrai est `emergencyFund`) ;
correctif ciblé `95cbf83`, CI VERTE sur ce HEAD exact, fusion faite
sur lui. La CI a fait exactement son travail : le rouge a précédé la
fusion. Publications rattrapées : W6.4 au SHA `7d44aaa` (run
`32949155915`, succès). **W6 est COMPLET et publié.** Work Order W7
écrit en mode plan (`docs/autonomie/w7/WORK_ORDER_W7.md`) — les
fixtures doublons différées de W1.5 y reviennent (W7.2).

### 26.08.2026 — W6.6 : mois/année — chaque période consultée utilise SA période (FI-23)

Lot de VERROUILLAGE (tests + consignation, aucun code produit) :
l'invariant FI-23 (« aucune horloge courante dans un agrégat
historique ») est TENU aujourd'hui — le parcours 216 le fige : la
page Année 2024 raconte 2024 (rien du mois courant n'y fuit, chiffres
exacts), aucune année passée n'a de mois « En cours » ni de marqueur
« · ce mois », `snapshot(2024, 5)` et `budgetReport(2024, 5)` lisent
LEUR période. Né vert ASSUMÉ (c'est un verrou d'existant) — le
sabotage fait foi : la page Année lit l'horloge (`yearMonthRow(NOW.y,
…)`) → les DEUX contrôles d'année mordent, rien d'autre ; restauré
vert. Leçon de sonde consignée : le premier contrôle « ce mois » était
trop large (« Aucune opération ce mois » est une phrase descriptive
légitime) — resserré sur le marqueur exact « · ce mois ». Aucune
capture (aucun pixel ne change). **W6 est COMPLET** : W6.1 (report
opt-in, ADR-067), W6.2 (estimation nommée), W6.3 (part engagée),
W6.4 (fonds annuels informatifs, ADR-068), W6.5 (valeur manuelle
datée), W6.6 (périodes étanches).

### 26.08.2026 — W6.4 fusionné — note de flux

La PR brouillon #171 (CI verte sur le HEAD exact `e18a71a`) a été
fermée et recréée PRÊTE en #172 (même branche, même HEAD) puis
fusionnée (`main` = `7d44aaa`) : le jeton de l'outil GitHub était à
court de quota horaire pour la sortie de brouillon, et l'API REST ne
sait pas dé-brouilloner. Aucun contenu n'a changé — le HEAD fusionné
est celui que la CI a validé. Publication au SHA `7d44aaa` : EN
ATTENTE du retour du jeton (le dispatch pages.yml exige ce jeton ;
consigné, à lancer dès que possible). Le run `32949031563` visible
sur main est l'auto-déploiement bloqué ATTENDU (règle d'environnement
github-pages, documentée).

### 26.08.2026 — W6.5 : objectifs — la valeur manuelle est datée, la provenance se lit

Contrat DATA_MODEL_TARGET : « un objectif avance par affectation
réelle ou valeur manuelle explicitement DATÉE, jamais par projection
seule ». Mesuré : le solde lié fait foi (réel ✓) mais `manualCurrent`
était un chiffre NU, sans date. Livré DES DEUX CÔTÉS : PWA — clé
additive `manualCurrentDate` posée à la saisie (re-datée seulement si
la VALEUR change, règle W4.7/FI-27) ; un objectif lié n'en porte pas
(le solde fait foi) ; la carte Objectifs raconte (« Montant saisi le
26.08.2026 » / « Montant que vous avez saisi — non daté » pour
l'existant — jamais une date inventée) ; restauration : date
illisible RETIRÉE, restauration acceptée. Natif —
`FinancialGoal.manualCurrentDate: Date?` (additif, défaut nil,
migration légère) + `GoalProgressService.currentProvenance`
(linkedBalance / manualDated / manualUndated) ;
`GoalDatedManualValueTests` (3). Preuves : parcours 215 né rouge (4
échecs nommés ; verrous memeValeurGardeDate/lieSansDate nés verts) →
vert ; sabotage (le filtre de restauration saute) →
restaurationFiltre mord SEUL ; restauré vert ; captures 320/390
inspectées (`docs/neon-ultra/budget-prisme/w6-5/`) ; suites complètes
vertes (215 e2e, 9 parités, 13 canon + schéma, design, catalogue,
audit) ; tests natifs prouvés par le job simulateur CI. Consigné :
`GoalAllocation` (lien affectation ↔ écriture) attendra l'allumage du
journal (ADR-064) — le lien réel passe aujourd'hui par le compte lié.

### 26.08.2026 — W6.4 : fonds annuels — le lissage se lit, l'argent ne bouge pas (ADR-068)

Décision propriétaire (AskUserQuestion) : **informatif en V1** →
ADR-068. Mesuré : une charge annuelle tombait d'un coup, sans repère.
Livré : la feuille d'une charge annuelle de dépense porte « Fonds de
lissage (repère) » — douzième mensuel et cumul depuis la dernière
échéance (« CHF 27.92 par mois … il faudrait avoir CHF 223.33 de côté
(8/12) »), calculés sur le montant ANNUEL (G01) ; honnêteté écrite
(« Rien n'est viré automatiquement — un repère, pas un geste. ») ;
une charge mensuelle reste muette ; AUCUNE écriture (ni mouvement ni
échéance). Preuves : parcours 214 né rouge (3 échecs nommés :
blocVisible, repereJuste, honnete ; verrous mensuelleMuette/
aucuneEcriture nés verts) → vert ; sabotage (le repère se calcule sur
la mensualité arrondie : 223.36 ≠ 223.33) → repereJuste mord SEUL ;
restauré vert ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w6-4/`) ; suites complètes vertes
(214 e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Noté : la note de rythme existante dit déjà le douzième « à titre de
comparaison » — léger écho assumé, les deux phrases répondent à des
questions différentes (comparer un rythme / savoir où on en est).
Consigné : le miroir natif (feuille iOS d'une charge annuelle) suivra
avec les écrans natifs de W6.

### 26.08.2026 — W6.3 : Budget — la part engagée se voit, à part des enveloppes

Mesuré : l'écran Budget ne montrait que les enveloppes par catégorie —
les charges régulières et factures du mois (la part NON
discrétionnaire) n'y apparaissaient nulle part. Livré : la carte
« Engagements du mois » (mois courant seulement) — « CHF 2'200.00 ·
Charges régulières et factures encore à sortir — comptées à part de
vos enveloppes, jamais deux fois. » LECTURE des compteurs du Mois
(`plannedOut + recurringCharges`, déjà W5.7-aware) — zéro nouveau
compteur ; ADR-066 respecté (une échéance ignorée libère aussi cette
carte) ; sans engagement restant, la carte se tait ; un mois passé
n'en parle pas (le passé est réel). Preuves : parcours 213 né rouge
(2 échecs nommés : carteVisible, respecteIgnorer ; verrous
lectureSeule/sansEngagementMuet/passeMuet nés verts) → vert ;
sabotage (la carte calcule sur des compteurs BRUTS, aveugles à
« ignorer ») → les DEUX contrôles ADR-066 mordent (respecteIgnorer +
sansEngagementMuet), rien d'autre ; restauré vert ; captures 320/390
inspectées (`docs/neon-ultra/budget-prisme/w6-3/`) ; suites complètes
vertes (213 e2e, 9 parités, 13 canon + schéma, design, catalogue,
audit). Consigné : l'état vide du Budget ne porte pas la carte (elle
accompagne un budget existant) ; abonnements vs factures : la
distinction fine (sous-groupes) attendra un besoin mesuré.

### 26.08.2026 — W6.2 : revenus variables — l'estimation se nomme, rien n'est promis

Mesuré : pour un indépendant (aucun revenu récurrent), la prévision
« Fin du mois » utilise une moyenne des 3 derniers mois
(`irregularIncome`, mécanisme existant)… FONDUE dans « + CHF X à
recevoir », indistincte des revenus réellement planifiés — une
estimation statistique présentée comme une promesse. Livré (mots
seulement, aucun agrégat ne bouge) : « à recevoir » = uniquement le
planifié (mouvements prévus + récurrents) ; l'estimation se NOMME à
part — « + CHF 4'500.00 estimés d'après vos 3 derniers mois — rien
n'est promis » ; un salarié (revenu récurrent) ne voit jamais ce
terme. Preuves : parcours 212 né rouge (2 échecs nommés :
termeNomme, plusFondue ; verrous moyenneCalculee/calculIntact/
salarieMuet nés verts) → vert ; sabotage (l'estimation refond dans
« à recevoir ») → plusFondue mord SEUL ; restauré vert ; captures
320/390 inspectées (`docs/neon-ultra/budget-prisme/w6-2/`) ; suites
complètes vertes (212 e2e, 9 parités, 13 canon + schéma, design,
catalogue, audit). Consigné : le natif n'a PAS d'équivalent
`irregularIncome` (la prévision iOS ne devine pas les revenus
variables) — divergence mesurée, décision d'alignement à poser quand
W6 touchera les écrans natifs ; la fenêtre « 3 mois » reste la
décision existante (aucun changement). W6.2+W6.3 fusionnés ensemble
(`main` = `f2d5013`, PR #170, précédent W2.1–W2.3) et publiés (run
`32944750458`, succès).

### 26.08.2026 — W6.1 : le reste se reporte — opt-in par ligne (ADR-067)

Mesuré : le budget était plat, une catégorie sous-dépensée repartait
de zéro. Décision propriétaire (AskUserQuestion) : **opt-in par
ligne** → ADR-067. Livré DES DEUX CÔTÉS : PWA — clé additive
`report: true` par ligne (case « Reporter le reste au mois suivant »
dans la feuille de ligne, restauration normalise en booléen strict),
`carryInPourLigne` calcule le report en CHAÎNE (remonte tant que la
ligne du mois d'avant reporte ; reste = max(0, prévu + reporté −
réel) ; dépassement jamais reporté ; dépenses seulement),
`budgetReport` expose `carry`/`effectif` (sans report : effectif =
saisi, rien ne change), l'écran Budget raconte (« Prévu CHF 1'000.00
(dont CHF 150.00 reportés) », « dont … reportés du mois dernier » sur
la ligne) ; helper `actualCentsForCat` extrait (une seule règle du
réel par catégorie). Natif — `BudgetLine.rollover` (additif, défaut
false, migration légère), `BudgetLineReport.carry`/`effective`
(variance/dépassement/jauge basculent sur l'effectif ;
carry par défaut zéro : API et rapports existants inchangés),
`BudgetVarianceService.carryIn` + paramètre additif
`previousBudgets: [] = défaut` sur `report(...)` ;
`BudgetRolloverTests` (5). Preuves : parcours 211 né rouge (5 échecs
nommés ; verrous jamaisStocke/fi20 nés verts) → vert ; sabotage (la
borne max(0,…) saute) → « un dépassement ne se reporte jamais » mord
SEUL — après durcissement du scénario (catégorie inconnue du
référentiel + chaîne absorbante rendaient le contrôle inerte — le
sabotage a révélé le test faible, corrigé et consigné) ; captures
320/390 écran + feuille inspectées
(`docs/neon-ultra/budget-prisme/w6-1/`) ; suites complètes vertes
(211 e2e, 9 parités, 13 canon + schéma, design, catalogue, audit) ;
tests natifs prouvés par le job simulateur CI. Divergence mineure
PRÉ-EXISTANTE notée (pas de ce lot) : à 390 px, le comparateur « ce
mois -CHF 330.00 » peut couper entre le signe et le montant au retour
de ligne — candidat à un correctif dédié. Écran Budget natif
(affichage carry) consigné pour les écrans iOS de W6. Fusionné
(`main` = `843ffaa`, PR #169) et publié (run `32943851091`).

### 26.08.2026 — W5 FERMÉ · Work Order W6 écrit

W5.8 fusionné (`main` = `f7f27f3`, PR #168) et publié (run
`32936739858`, succès). Note honnête : le run de publication W5.7
(`32936249837`) a été ANNULÉ par le dispatch W5.8 qui l'a suivi de
près (concurrence Pages) — le contenu W5.7 est publié par le run
W5.8, dont le SHA `f7f27f3` contient `eec9627`. **W5 est fermé** :
les huit sous-lots du Work Order sont livrés et publiés. Work Order
W6 écrit en mode plan (`docs/autonomie/w6/WORK_ORDER_W6.md`).
Décisions propriétaire du 26.08.2026 (AskUserQuestion) : W6.1 report
**opt-in par ligne** (comportement actuel = défaut) ; W6.4 fonds
annuels **informatifs en V1** (aucune écriture automatique).

### 26.08.2026 — W5.8 : nettoyage prouvé — zéro code mort, et un verrou pour que ça dure

Mesure d'abord (inventaire outillé des 290 fonctions de la PWA,
usages comptés dans l'app ET les tests) : **aucune fonction sans
appelant** — il n'y a rien à retirer. Six fonctions vivent « tests
seulement », toutes justifiées : `annulerOccurrence` (API domaine
W2.5, surface à venir), `comparerOccurrencesEtCompteurs` (gate W2.7a
— son rôle est d'être appelée par les tests), `confirmerOccurrence`
(porte W2.4, contrat testé), `migrerHistoriqueJournal` (ADR-064 :
préparer sans allumer), `misDeCoteParDestination` et
`pensionDisplayTotal` (spécifications exécutables C4/C3, vérifiées au
centime). Livré : l'audit dépôt gagne le contrôle « CODE VIVANT » —
échec si une fonction n'a plus aucun appelant, échec si une fonction
« tests seulement » n'est pas dans la liste d'exceptions NOMMÉES et
JUSTIFIÉES, échec si la liste d'exceptions se périme (fonction
disparue ou redevenue appelée). Verrou né vert (le constat EST la
preuve) ; sabotage : une fonction fantôme injectée → l'audit crie
(`fonctionFantomeSabotage` nommée) ; restauré vert. Non-objectif
consigné : un audit des classes CSS mortes mentirait (classes
composées dynamiquement — un grep naïf produirait des faux
positifs) ; l'inventaire des fonctions est la surface mesurée
honnête. Zéro changement d'interface — pas de captures.

### 26.08.2026 — W5.7 : Inbox — Reporter et Ignorer existent, ignorer libère (ADR-066)

Mesuré : les gestes d'agenda W2.5 (`reporterOccurrence`,
`ignorerOccurrence`) n'avaient AUCUN appelant à l'écran, et une
échéance ignorée pesait encore sur le disponible
(`recurringRemainingCount` = dues − liées, sans lire les échéances) —
la divergence consignée depuis W5.2/W5.2b. Décision propriétaire du
26.08.2026 (AskUserQuestion) : **« Oui, ignorer libère »** → ADR-066.
Livré : (1) la feuille d'une série due porte les gestes « Ignorer ce
mois-ci » et « Reporter à… » (même condition d'apparition que « Régler
ce mois ») ; la feuille d'une facture non couverte porte « Ignorer
cette facture ce mois-ci » (reporter une facture = changer sa date,
déjà possible) ; (2) trois portes de lecture (`echeancesSauteesSerie`,
`factureSautee`, `echeanceOuverteSerie`) ; `recurringRemainingCount`
et `openBillsDue` soustraient les échéances sautées — disponible,
prévision de fin de mois, liste « à faire » et feuilles lisent la même
vérité ; le comparateur W2.7a n'a plus d'écart W5.2 à compenser
(attendu net = attendu) ; l'état `skipped` sort des obligations
ouvertes. Reporter garde l'échéance OUVERTE (date d'origine intacte,
argent toujours réservé : reporté ≠ libéré). Preuves : parcours 210 né
rouge (7 échecs nommés, dont un artefact de fenêtre corrigé —
matérialiser avant de comparer) → vert ; DEUX sabotages séquentiels :
le compteur oublie les sautées → 4 contrôles ADR-066 mordent ET la
gate comparateur W5.2 crie (la parité protège) ; les factures gardent
leur réserve → factureLiberee mord SEUL ; restauré vert ; verrou de
langue existant mordu en route (« mouvement » interdit dans un toast →
« opération », la fondation langue fait son travail) ; captures
320/390 feuille + mois-après-ignorer inspectées
(`docs/neon-ultra/budget-prisme/w5-7/`) ; suites complètes vertes (210
e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : le natif applique déjà « ignorer libère » à sa prévision
(W5.2b, `persistedOccurrences`) — les GESTES natifs à l'écran
(feuille iOS) suivront avec les écrans natifs de W5 ; la fenêtre
multi-mois reste la fenêtre de matérialisation W2 (aucune nouvelle
décision) ; reste W5.8 (nettoyage prouvé) pour fermer W5. Fusionné
(`main` = `eec9627`, PR #167) et publié (run `32936249837`).

### 26.08.2026 — W5.6 : Gérer — les taux datés se voient

Mesure d'abord : W4.2 consigne chaque taux avec sa date et sa
provenance (journal `fxQuotes`, append-only), mais Gérer n'en montrait
RIEN — la rangée « Taux de change manuels » listait les valeurs sans
dire de quand elles datent, la feuille non plus. Un taux sans date est
une promesse invérifiable (invariant « devise/taux/date explicites »).
Deux morceaux, lecture seule : (1) la rangée de Réglages date sa
lecture (« … — dernier taux consigné le 20.08.2026 · aucune connexion
réseau » ; sans journal : « taux par défaut, jamais mis à jour ») ;
(2) la feuille des taux raconte PAR devise (« Dernier taux consigné :
0.95 le 20.08.2026 — saisie manuelle. » ; devise restée au défaut :
« Encore jamais consigné — le taux affiché est le défaut de
départ. »). Helper unique `dernierTauxConsigne(devise)` (lit le
journal W4.2, date fr-CH, null si jamais consigné). Preuves :
parcours 209 né rouge (3 échecs nommés : rangeeDatee, feuilleRaconte,
defautHonnete ; verrous horsReseau et lectureSeule nés verts,
consignés) → vert ; sabotage chirurgical (la rangée ne date plus) →
rangeeDatee mord SEUL ; restauré vert ; captures 320/390
rangée + feuille inspectées (`docs/neon-ultra/budget-prisme/w5-6/`) ;
suites complètes vertes (209 e2e, 9 parités, 13 canon + schéma,
design, catalogue, audit). Consigné : « réglages progressifs » de la
charte = structure actuelle de Gérer, mesurée conforme (sections Mon
ménage / Sécurité / Vos données, portes read-row) ; le miroir natif
(Réglages iOS lisant FxQuote V13) suivra avec les écrans natifs de
W5 ; prochain lot W5.7 (inbox — gestes Reporter/Ignorer exposés,
décision produit « sauter libère-t-il le disponible ? »). Fusionné
(`main` = `86af62d`, PR #166) et publié (run `32933141071`, succès).

### 26.08.2026 — W5.4 : Budget — le futur parle au conditionnel, le passé au passé

ADR-055/056 confirmés sur la destination Budget. Mesure d'abord (sonde
navigateur) : un mois FUTUR avec budget disait « Il vous reste à
dépenser » + « Dans le plan » + « utilisé 0 % » (le présent de
l'indicatif sur un mois qui n'a pas commencé) et comparait son coût de
la vie VIDE au mois dernier (« ce mois −CHF 3'626.45 ») ; un mois
PASSÉ disait encore « reste à dépenser » alors qu'il est clos. Aucun
calcul ne change — seuls les mots et ce qui s'affiche : au FUTUR le
héros dit « Prévu pour ce mois », pastille « À venir », phrase au
conditionnel (« Si vous suivez le plan, vos dépenses resteront sous
CHF X »), anneau tu (rien n'a couru), comparaison tue ; au PASSÉ « Il
vous est resté », pastille « Budget tenu »/« Dépassé » (« À
surveiller » disparaît — un mois clos ne se surveille plus, sur le
héros comme sur les lignes) ; le mois COURANT garde ses mots (verrou).
Preuves : parcours 208 né rouge (5 échecs nommés : futurConditionnel,
futurSansPresent, comparaisonTue, passeAuPasse, passePille ; le verrou
passeSansSurveiller est né avec l'implémentation — le sabotage fait
foi) → vert ; sabotage double chirurgical (le futur reparle au présent
→ futurSansPresent mord seul ; « À surveiller » revient au passé →
passeSansSurveiller mord seul — exactement 2 échecs, rien d'autre) ;
restauré vert ; NU2 (test 74) aligné sans affaiblir : son budget vit
sur un mois futur (+6), la pastille attendue devient « À venir » et
l'anneau doit y être ABSENT (contrat renforcé) ; captures 320/390
futur+passé inspectées (`docs/neon-ultra/budget-prisme/w5-4/`) ;
suites complètes vertes (208 e2e, 9 parités, 13 canon + schéma,
design, catalogue, audit). Consigné : le miroir natif (BudgetTab au
conditionnel) suivra avec les écrans iOS de W5 ; prochain lot W5.6
(Gérer — taux datés visibles). Fusionné (`main` = `8dc2e2e`, PR #165)
et publié (run `32924842621`).

### 26.08.2026 — W5.5 : Comptes — les dettes ont leur groupe, les archivés leur place, les relevés se voient

Mesure d'abord : les comptes de dette créés en W4.1 (`creditCard`,
`loan`) étaient INVISIBLES sur l'écran Comptes — aucun groupe ne
couvrait leur `kind` (divergence consignée en W4.1, fermée ici). Trois
morceaux, lecture seule : (1) le groupe « Cartes et prêts » liste les
comptes `dette: true` actifs (solde dû négatif, coral) ; (2) les
comptes archivés (W4.6) quittent leurs groupes vivants et se rangent
sous « Archivés » (rangée atténuée, « archivé — l'histoire reste »,
consultables au détail) ; (3) le détail d'un compte montre « Dernier
relevé » quand `S.releves` en porte un (« Solde constaté X le
JJ.MM.AAAA — source. ») ; sans relevé la carte se tait. Preuves :
parcours 207 né rouge (3 échecs nommés : groupeDettes, archiveRange,
releveVisible) → vert ; sabotage (« Argent disponible » oublie
`compteActif` → l'archivé refuit dans son groupe) → le contrôle
archiveRange mord SEUL ; restauré vert ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w5-5/` — groupes « Argent
disponible » / « Cartes et prêts » (Carte Visa −CHF 250.00) /
« Archivés » (Ancien compte), zéro débordement) ; suites complètes
vertes (207 e2e, 9 parités, 13 canon + schéma, design, catalogue,
audit). Consigné : le formulaire compte natif (typologie + solde dû)
et la présentation archivés/relevés iOS suivront quand W5 touchera
les écrans natifs ; prochains lots W5.4 (Budget — projections au
conditionnel) et W5.6 (Gérer — taux datés visibles). Fusionné
(`main` = `d165fb0`, PR #164) et publié (run `32922555366`, succès).

### 26.08.2026 — W5.3 : l'Historique lit la chaîne — « corrigé » se voit

La chaîne de correction du journal (W3.5 — l'histoire jamais réécrite)
devient LISIBLE, en lecture SEULE : `traceCorrection(txId)` raconte
(révisions, dernier montant d'avant) ; la ligne de l'Historique porte
« · corrigé » (marqueur calculé UNE fois par état du journal —
`idsMouvementsCorriges` avec cache, l'Historique pagine à 200 lignes
sans balayer 200 fois le journal) ; la feuille du mouvement dit
« Corrigé une fois — le journal garde chaque version (avant :
CHF 84.30) ». INCIDENT attrapé en route : la note de la feuille
gardait l'état de la feuille PRÉCÉDENTE (une création après une
correction affichait une trace fantôme) — reset posé à l'ouverture,
verrouillé par le parcours (« pas d'état rancunier »). Preuves :
parcours 206 né rouge (6 échecs nommés) → vert ; sabotage (le
marqueur se tait) → le contrôle de ligne mord seul ; restauré vert ;
captures 320/390 inspectées (`docs/neon-ultra/budget-prisme/w5-3/` —
ligne marquée, note de feuille lisible) ; suites complètes vertes (206
e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : la trace natif (le détail iOS lisant la chaîne V12) suivra
quand W5 touchera les écrans natifs correspondants. Fusionné (`main` =
`a7524ec`, PR #163) et publié (run `32920731017`, succès).

### 26.08.2026 — W5.2b : l'accueil natif lit les échéances

Miroir natif de W5.2 : `RecurringScheduleService` gagne
`persistedOccurrences` (paramètre additif, `[]` par défaut — les
agrégats financiers ne bougent pas) sur `remainingOccurrences`,
`monthForecast` et `monthCheck` : une échéance PERSISTÉE ignorée ou
annulée (machine W2.3/W2.5) n'attend plus — sans mouvement ; une
reportée reste ouverte. `HomeTab` lit enfin `ScheduledOccurrence`
(@Query) et nourrit sa prévision du mois avec. Tests
(`ScheduleReadsOccurrencesTests`, 4) : ignorée n'attend plus, annulée
pareil et reportée reste ouverte, le Check du mois compte la série
ignorée comme réglée, ni un autre mois ni une autre série ne règlent
ce mois. Consigné : le « disponible » (engagements) continue de
réserver une charge sautée des DEUX côtés — la sémantique « sauter
libère-t-il le disponible ? » est une décision produit pour l'inbox
W5.7 ; les gestes à l'écran (Reporter/Ignorer) idem.

### 26.08.2026 — W5.2 : le bilan lit les échéances — ignorer libère le mois

Le morceau attendu depuis W2 : l'écran Mois LIT enfin les échéances
persistées. `monthCheckItems` matérialise (idempotent, W2.2/W2.6) puis
laisse la MACHINE À ÉTATS décider de « réglé » : confirmée, IGNORÉE ou
annulée — le geste `ignorerOccurrence` (W2.5) a enfin une surface : une
charge qu'on choisit de sauter ne bloque plus le mois et ne crée AUCUN
mouvement. L'histoire couverte par ses mouvements garde sa règle
d'avant (un mois passé reste « fait »). Le comparateur W2.7a APPREND
la nouvelle vérité : l'attendu se réduit des échéances sautées
volontairement (`attenduNet`) — les compteurs ne connaissent pas ce
choix, le comparateur le réconcilie. Preuves : parcours 205 né rouge
(5 échecs nommés, dont le comparateur — légitime : avant W5.2, rien ne
matérialisait la 2e série) → vert ; sabotage (« ignoré » ne règle
plus) → les 2 contrôles ciblés mordent ; restauré vert ; suites
complètes vertes (205 e2e, 9 parités, 13 canon + schéma, design,
catalogue, audit). Consigné : l'affichage du bilan reste
titre + compteur (« N à faire ») + liste d'obligations — la carte
détaillée et les gestes Reporter/Ignorer À L'ÉCRAN arrivent avec
l'inbox W5.7 ; le miroir natif (HomeTab lit `ScheduledOccurrence`) =
W5.2b.

### 26.08.2026 — W5.1 : les routes — la navigation ADR-026, verrouillée

W5 s'ouvre (Work Order : `docs/autonomie/w5/WORK_ORDER_W5.md` —
ADR-026 prévaut : les cinq destinations restent, le vocabulaire
générique de la charte se lit Historique/Budget/Gérer). W5.1 MESURE la
carte réelle (`docs/autonomie/w5/INVENTAIRE_ROUTES.md` : 5 onglets
identiques des deux côtés, 11 sous-vues de Gérer + 1 alias interne) et
la VERROUILLE (parcours 204) : destinations exactes, chaque écran
vivant par le vrai clic, chaque sous-vue ouvrable ET revenant à Gérer,
zéro route morte (menu ↔ rendeurs couverts, alias consignés), zéro
bouton d'ajout global. Né VERT (verrouillage d'un comportement déjà
conforme — consigné) : les contrôles négatifs font foi, et ils ont
mordu TROIS fois — rendeur retiré → un ancien parcours crashe (le
registre était déjà tenu par la suite historique), entrée de menu
retirée → un autre parcours attend sa carte, rendeur FANTÔME ajouté →
le contrôle « zéro route morte » de 204 mord SEUL. Leçon consignée
dans le test : la tabbar se re-rend à chaque navigation — un verrou de
navigation re-lit le DOM vivant, comme un doigt. Suites complètes
vertes (204 e2e, 9 parités, 13 canon + schéma, design, catalogue,
audit). Prochain : W5.2 — la boîte de réception du Mois (les échéances
persistées enfin LUES par un écran).

### 25.08.2026 — W4.7 : le patrimoine daté et sourcé — dernier sous-lot de W4

FI-27 prend corps : chaque bien/dette porte la DATE de son estimation
(`valueDate`, estampillée à la création et re-datée SEULEMENT quand la
VALEUR change — renommer ne re-date jamais) ; l'écran dit « valeur au
JJ.MM.AAAA » pour le daté et « valeur non datée » pour l'héritage —
jamais une date inventée ; la restauration RETIRE une date illisible
et garde le bien (FI-34). FI-17 : l'avertissement « montants non
convertibles » (devise sans taux) devient VISIBLE sur l'écran
Patrimoine aussi. Garde-fou W4.5 tenu : le formulaire dette met en
garde contre le double compte quand un compte de dette actif existe.
FI-13 fermé côté NATIF : `ArchivedAccountTests` verrouille que les
flux d'un mois passé sont IDENTIQUES après `isActive = false` (le
présent, lui, exclut le compte). Preuves : parcours 203 né rouge (7
échecs nommés) → vert ; sabotage (renommer re-date) → le contrôle
« la date suit la valeur » mord seul ; restauré vert ; captures
320/390 inspectées (`docs/neon-ultra/budget-prisme/w4-7/` — daté,
non daté, leasing daté, zéro débordement) ; suites complètes vertes
(203 e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : les pensions/positions gardent leur affichage de fraîcheur
existant ; source de la valeur (« votre estimation ») déjà dite à
l'écran — une provenance plus riche viendra avec les relevés
d'établissement (W8).

### 25.08.2026 — W4.6 : l'archivage — un compte se range, l'histoire reste

Divergence mesurée fermée : la PWA n'avait AUCUN archivage (le natif a
`isActive` depuis toujours). `compteActif(a)` (le drapeau additif
`archived`) + la case « Archiver ce compte (l'histoire reste) »,
visible en ÉDITION seulement. Un compte archivé sort des agrégats du
PRÉSENT — patrimoine (`compteDansPatrimoine` apprend l'archivage),
liquide/disponible (les 4 sites `a.cash`), épargne accessible — et des
choix de NOUVEAUX mouvements (les deux sélecteurs du formulaire ; 
l'édition d'un ancien mouvement garde son compte). Son HISTOIRE ne
bouge JAMAIS : solde intact, mouvements intacts, rapport d'un mois
passé IDENTIQUE avant/après (FI-13 → TENU côté PWA, verrouillé par
test). Désarchiver ramène tout ; la restauration préserve le drapeau.
Preuves : parcours 202 né rouge (7 échecs nommés) → vert ; sabotage
(le patrimoine ignore l'archivage) → le contrôle d'exclusion mord
seul ; restauré vert ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w4-6/`) ; suites complètes vertes (202
e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : le test natif dédié « rapports passés identiques après
`isActive = false` » viendra avec W4.7 (patrimoine) pour fermer FI-13
des deux côtés ; la liste Comptes garde les archivés visibles (W5
décidera leur présentation).

### 25.08.2026 — W4.5 : dettes et cartes — le dû existe, payer est neutre

Le trou consigné en W4.1 se ferme : un compte de dette peut enfin
NAÎTRE avec son dû. La case « C'est un solde dû (la dette part en
négatif) » n'apparaît QUE pour un type de dette (le pavé décimal iOS
n'a pas de touche moins — même motif que la réconciliation), cochée
d'elle-même, toujours décochable ; l'édition affiche la valeur absolue
et le signe vit dans la case. Sémantique verrouillée par test (FI-14) :
payer sa carte est un VIREMENT neutre (le mois ne bouge pas, deux
jambes de comptes réels au journal), les intérêts sont une DÉPENSE
depuis la carte (ils coûtent, eux), le patrimoine soustrait le dû
naturellement, la restauration préserve le négatif, comparateur à zéro
sur toute l'histoire de la carte. Preuves : parcours 201 né rouge (7
échecs nommés) → vert ; sabotage (la case ne fait rien) → 4 contrôles
mordent ; restauré vert ; captures 320/390 inspectées
(`docs/neon-ultra/budget-prisme/w4-5/`) ; suites complètes vertes (201
e2e, 9 parités, 13 canon + schéma, design, catalogue, audit).
Consigné : le natif accepte déjà une ouverture négative (Decimal
signé) — son formulaire de compte gagnera la même case quand W5
touchera ces écrans ; une dette suivie comme COMPTE ne doit pas être
doublée en Dette manuelle (garde-fou à l'écran → W4.7).

### 25.08.2026 — W4.4b : la porte de réconciliation native

Miroir natif : `JournalEntry.avancerCycle(vers:)` (machine à sens
unique, refus typé `JournalCycleError`, « reconciled » terminal) et
`ReconciliationService.reconcilier(...)` — les TROIS gestes ensemble
dans le même save : le point du compte (comportement historique que
`balance()` continue de lire), le RELEVÉ daté (W4.3, source
« réconciliation manuelle », append-only — chaque réconciliation
laisse SA preuve) et le FIGEAGE du journal (les écritures postées du
compte jusqu'à la date → « reconciled » ; prévu et autres comptes
intacts). `ReconcileSheet` passe par la porte. `memePhoto` natif
apprend (comme la PWA) que l'avancée du cycle n'est pas une différence
de contenu. Tests : cycle à sens unique (refus typé, terminal), trois
gestes ensemble, correction d'une écriture rapprochée TOUJOURS en
chaîne (l'écriture figée ne bouge ni d'état ni d'un centime),
double réconciliation = deux relevés. Consigné : la bascule de
`balance()` du point nu vers le relevé attend le rapprochement par
relevé complet (W4.5+ si utile) — dual-write d'ici là.

### 25.08.2026 — W4.4 : le rapprochement — réconcilier fige l'histoire

Le CYCLE DE VIE des écritures avance dans UN seul sens
(`avancerCycleEcriture` : pending → posted → cleared → reconciled,
retour = refus nommé, l'état ne bouge pas — FI-06). Réconcilier par le
vrai formulaire appelle `rapprocherJournal(compte, date)` : toutes les
écritures postées (ou passées en banque) du compte jusqu'à la date du
relevé deviennent « reconciled » — l'histoire confirmée par le solde
constaté est FIGÉE ; l'ajustement du jour est rapproché aussi ; l'autre
compte et le prévu ne bougent jamais (FI-01). Une écriture rapprochée
ne MUTE jamais : sa correction vit en chaîne (inversion + remplaçante,
W3.5), comparateur à zéro — FI-07 au complet. `memePhotoJournal`
apprend que l'avancée du cycle n'est PAS une différence de contenu
(un re-dépôt sans changement ne crée pas de chaîne). Preuves :
parcours 200 né rouge (6 échecs nommés) → vert ; sabotage (le cycle
autorise le retour) → le contrôle de machine mord seul ; restauré
vert ; suites complètes vertes (200 e2e, 9 parités, 13 canon + schéma,
design, catalogue, audit). Consigné : le miroir natif (transitions de
cycle sur `JournalEntry`, rapprochement lié aux `Statement`, bascule
de `balance()` du point nu vers le relevé) = W4.4b ; une écriture
multi-comptes (virement) rapprochée par UN compte fige l'écriture
entière — sémantique V1 consignée.

### 25.08.2026 — W4.3 : le relevé — réconcilier laisse une preuve datée

PWA : réconcilier garde son ajustement tracé (comportement historique
intact) ET consigne désormais un RELEVÉ daté — compte, solde visé en
CENTIMES, source « réconciliation manuelle », état `reconciled`, lien
vers l'ajustement — clé additive `releves`, append-only ; un solde
déjà exact ne consigne rien ; la restauration abandonne le relevé
hostile (FI-34) ; l'undo emporte l'ajustement ET sa preuve ensemble.
Natif : `Statement` (@Model, schéma V14 additif — période, soldes,
état brouillon/rapproché/rouvert, provenance) et
`StatementMigrationService` — chaque point nu
`reconciledBalance`/`reconciledAt` devient un relevé synthétique
MARQUÉ (« point de rapprochement migré (avant W4.3) »), idempotent, le
point du compte restant INTACT (`balance()` le lit jusqu'au
rapprochement complet W4.4, consigné). Preuves : parcours 199 né rouge
(6 échecs nommés) → vert ; sabotage (le relevé consigné AVANT
`pushUndo` — l'undo rendrait un état à moitié) → le contrôle
d'atomicité de l'undo mord seul ; restauré vert ; `StatementTests`
(migration marquée idempotente, état inconnu → brouillon, survie
disque V13 → V14 FI-35) ; suites complètes vertes (199 e2e, 9 parités,
13 canon + schéma, design, catalogue, audit).

### 25.08.2026 — W4.2b : le moteur FX natif — le constat n° 6 se ferme

Miroir natif d'ADR-065 : `FxQuote` (@Model, schéma V13 additif — base,
cote, taux `Decimal`, `observedAt`, source) et
`CurrencyConversionService` — paire EXACTE, dernière quote observée au
plus tard à la date demandée ; aucune quote = nil, JAMAIS 1 ni 0
(FI-17), la paire inverse n'est jamais inférée (un taux inventé).
`MonthlySnapshotService` (liquide) et `NetWorthService` (patrimoine)
convertissent désormais chaque compte étranger avec les quotes datées
— sans quote, le compte est EXCLU (même règle que la PWA ; l'état
« incomplet » visible arrive en W4.7). Le runner canonique Swift lit
les `taux` des fixtures : **`enAttenteNatif` est VIDE** — les 13
fixtures s'exécutent sur le moteur natif (constat n° 6 de l'audit
fermé, la gate exige désormais 13/13). Tests :
`CurrencyConversionServiceTests` (conversion exacte, la dernière quote
datée gagne et l'histoire garde son taux FI-19, quote future
invisible, nil jamais inventé, exclusion sans quote ↔ conversion avec,
migration disque V12 → V13 FI-35). Consigné : la restauration native
reste mono-devise (ADR-017) — revisite quand le produit ouvrira les
devises à l'utilisateur (W4.7+) ; l'affichage « incomplet » = W4.7.

### 25.08.2026 — W4.2 : les taux datés — chaque taux porte sa date et sa source

ADR-065 (« V1 base unique », décision propriétaire) : un taux de
change n'est plus un nombre nu. PWA : `enregistrerTaux(devise, taux,
source)` — LA porte d'écriture, qui consigne une quote datée et
sourcée (FI-16) dans la clé additive `fxQuotes`, APPEND-ONLY
(l'ancienne quote survit, idempotente le même jour) et met à jour le
CACHE dérivé `fxRates` (la dernière quote) ; refus nommé pour un taux
illisible (FI-34) ; le formulaire des réglages passe par la porte
(source « saisie manuelle »). L'historique estampillé (`t.fx`) ne
bouge jamais (FI-19, verrouillé). FI-17 verrouillé aussi : devise sans
taux = avertissement nommé (`fxWarningHTML`), jamais un 1:1. Plomberie
additive complète (seeds, chargement, restauration filtrante, undo) ;
« tout effacer » GARDE les quotes (les taux sont des réglages). Les
défauts pays ne sont PAS des quotes (aucune observation réelle,
consigné dans l'ADR). Preuves : parcours 198 né rouge (8 échecs
nommés) → vert ; sabotage (la porte écrase au lieu d'ajouter) → le
contrôle append-only mord seul ; restauré vert ; suites complètes
vertes (198 e2e, 9 parités, 13 canon + schéma, design, catalogue,
audit). Consigné : le miroir natif (`FxQuote`, conversion datée,
sortie des fixtures `devise-conversion-datee` et `comptes-par-devise`
d'`enAttenteNatif`) = W4.2b.

### 25.08.2026 — W4.1 : la typologie — les comptes de dette existent enfin

W4 s'ouvre (Work Order : `docs/autonomie/w4/WORK_ORDER_W4.md`) sur le
trou mesuré : la PWA n'avait AUCUN type de compte de dette — le natif
connaît `creditCard`/`loan`/`mortgage` depuis toujours. W4.1 (additif,
AUCUNE formule d'agrégat ne change) : `ACCOUNT_KINDS` gagne
`creditCard` (« Carte de crédit ») et `loan` (« Prêt / leasing »)
marqués `dette: true` ; le vrai formulaire les propose ; choisir un
type de dette DÉCOCHE « argent disponible » (une dette n'est pas du
cash — proposition modifiable, un autre type recoche pour un nouveau
compte seulement) ; la restauration préserve le type (le repli
`kind manquant → current` reste intact) ; un mouvement de carte passe
par le journal comme tout compte (solde négatif naturel, comparateur
zéro). Sémantique complète capital/intérêts et solde d'ouverture
négatif : consignés à W4.5. Preuves : parcours 197 né rouge (6 échecs
nommés) → vert ; sabotage (le type de dette ne décoche plus) → les 2
contrôles ciblés mordent ; restauré vert ; captures 320/390
inspectées (`docs/neon-ultra/budget-prisme/w4-1/` — formulaire, carte
sélectionnée, disponible décoché, patrimoine coché, zéro
débordement) ; suites complètes vertes (197 e2e, 9 parités, 13 canon +
schéma, design, catalogue, audit).

### 25.08.2026 — W3.7 : la migration de l'historique — préparer sans allumer

DERNIER sous-lot de W3 (ADR-064, décision propriétaire : « Préparer
sans allumer »). PWA `migrerHistoriqueJournal({essai})` : l'essai à
blanc raconte (créés, refus nommés, écarts) puis restaure TOUT (photo
du journal, refus rendus au rapport) ; la migration réelle n'applique
que si zéro refus ET zéro écart — sinon rien ne change (atomique) ;
`S.journalActif` n'est JAMAIS touché. Natif
`JournalHistoryMigrationService.migrer(essai:now:context:)` : les
brouillons d'écritures ne touchent JAMAIS le contexte pendant l'essai
(traduction pure + écarts PRÉVUS par addition des jambes), insertion +
`save` seulement quand tout est propre, `rollback` si le save échoue.
Preuves : parcours 196 né rouge (6 échecs nommés) → vert (essai
inerte, réel prouvé zéro écart, idempotent, jamais d'allumage, refus
atomique) ; sabotage (« le refus n'empêche plus rien ») → le contrôle
d'atomicité mord seul ; restauré vert ; tests natifs (essai inerte,
réel idempotent, refus atomique nommé, survie sur store DISQUE avec
réouverture et zéro écart, FI-35) ; suites complètes vertes (196 e2e,
9 parités, 13 canon + schéma, design, catalogue, audit). Consigné :
l'ALLUMAGE (lecture des soldes depuis le journal par défaut) attend
W4 et une décision propriétaire ; le déclenchement de la migration
dans l'app (au boot ou depuis Gérer) arrive avec l'allumage — les
portes existent et sont prouvées.

### 25.08.2026 — W3.6b : le comparateur natif et sa porte de bascule

Miroir natif de la gate : `JournalComparatorService` — complète
l'ombre (mouvements hérités via `deposer`, ouvertures via la nouvelle
`deposerOuverture` en CHAÎNE corrigeable FI-12/FI-07), dérive le solde
de chaque compte du journal (`soldeDerive`, pending exclu, centimes
entiers) et exige l'égalité EXACTE avec `AccountBalanceService` ; tout
mouvement sans écriture est un écart nommé portant son refus (FI-34) ;
un compte assis sur un `reconciledBalance` est un écart CONSIGNÉ — le
journal ne modélise pas encore les relevés (W4), jamais deviné.
`JournalReadSwitch` : activer EXIGE zéro écart (refus nommé sinon, le
drapeau `UserDefaults` ne bouge pas), éteindre toujours permis —
AUCUNE lecture native ne passe encore par le journal (consigné, comme
la PWA : bascule par défaut = décision propriétaire après W3.7).
Tests : store couvert à zéro écart idempotent, écriture falsifiée →
écart nommant le compte, base rapprochée → écart consigné W4, porte
gardée + rollback, chaîne d'ouverture (originale intacte, inversion,
`:r2`, solde dérivé suit).

### 25.08.2026 — W3.6 : la bascule des soldes — le drapeau gardé

`balance()` devient la PORTE (ADR-058 étape 6) : `S.journalActif`
allumé → les soldes lisent le JOURNAL (`soldeDepuisJournal`) ; éteint
(défaut) → le chemin vivant historique (`soldeVivant`), inchangé.
Allumer passe par `basculerJournal(true)` qui EXIGE le comparateur
W3.4 à zéro écart — refus nommé sinon, le drapeau ne bouge pas ;
éteindre est TOUJOURS permis (rollback documenté — l'ancien chemin est
intact, FI d'ADR-058). `ombreOuvertureDepot` : l'ouverture d'un compte
vit dans le journal comme une chaîne corrigeable (éditer le solde
d'ouverture inverse et remplace, FI-07 + FI-12 ; zéro laisse la trace)
— branchée au formulaire de compte (sous journal), au complètement du
comparateur et à « tout effacer » (les ouvertures renaissent). Drapeau
persistant : clé additive `journalActif` (seeds, chargement,
restauration booléen strict). Preuves : parcours 195 né rouge (8
échecs nommés) → vert (éteint par défaut identique, refus nommé sur
écart, bascule au centime près, gestes réels exacts sous journal,
édition d'ouverture par le VRAI formulaire → chaîne + solde,
tout-effacer aux ouvertures, rollback identique) ; sabotage (« la gate
n'arrête plus rien ») → le contrôle de refus mord seul ; restauré
vert ; suites complètes vertes (195 e2e, 9 parités, 13 canon + schéma,
design, catalogue, audit). Consigné : AUCUNE vue n'allume le drapeau —
la bascule par défaut attend la migration W3.7 et une décision
propriétaire ; miroir natif de la bascule = W3.6b (avec le comparateur
natif).

### 25.08.2026 — W3.5b : le miroir natif de l'inversion

`JournalShadowService` mûrit comme la PWA (les deux tests d'ombre
existants ÉVOLUENT, consigné) : `ecritureActive(transactionID:)` (la
tête de chaîne — jamais visée par une inversion), `deposer` — un POSTÉ
corrigé garde son originale INTACTE, gagne l'inversion liée
(`reversesEntryID`, jambes inversées, clé `inversion:<id>`) puis la
remplaçante liée (`replacesEntryID`, clé `:r<n>`) ; un PRÉVU se
remplace en place ; la même photo est un no-op (comparaison des jambes
en multiensemble — l'ordre d'une relation SwiftData n'est pas un
contrat) ; `retirer` — un POSTÉ supprimé laisse l'aller-retour net
zéro lisible, un PRÉVU s'efface (zéro posting orphelin). Tests :
chaîne tracée (originale intacte, r2, no-op), prévu
remplacé/effacé, posté supprimé → trace nette zéro. Même contrat des
deux côtés du miroir.

### 25.08.2026 — W3.5 : inversion/remplacement — corriger n'est jamais réécrire

FI-07 prend corps : le contrat d'ombre MÛRIT (évolution des parcours
192/193 consignée ici même). `ecritureActiveDuMouvement` (la tête de
chaîne : la seule écriture qu'aucune inversion ne vise) ;
`ombreJournalDepot` — un POSTÉ corrigé garde son originale INTACTE,
gagne une inversion liée (`reversesEntryId`, jambes inversées, datée du
jour de la correction, clé idempotente `inversion:<id>`) puis une
remplaçante liée (`replacesEntryId`, clé `mouvement:<id>:r<n>`) ; un
PRÉVU corrigé se remplace en place (un plan n'est pas de l'histoire) ;
redéposer la même photo est un no-op (`memePhotoJournal`).
`ombreJournalRetrait` — supprimer un POSTÉ pousse l'inversion tracée
(le journal raconte l'aller-retour net), supprimer un PRÉVU l'efface.
Le comparateur W3.4 lit désormais la tête de chaîne (couvert = une
écriture ACTIVE). Preuves : 11 échecs nommés à la naissance (3
contrats mûris du 192 + 8 du parcours 194) → verts ; sabotage (« tout
se réécrit ») → les 4 contrôles FI-07 mordent dans DEUX parcours
indépendants ; restauré vert ; suites complètes vertes (194 e2e, 9
parités, 13 canon + schéma, design, catalogue, audit). Consigné : le
miroir natif (inversion dans `JournalShadowService`) = W3.5b ; une
inversion refusée par la porte du journal serait consignée dans
`JOURNAL_OMBRE_REFUS`, jamais perdue.

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
