# Budget decision log

## ADR-067 — Le report budgétaire est opt-in par ligne, calculé en chaîne

Date: 2026-08-26
Status: accepted

### Contexte

Le budget était plat : une catégorie sous-dépensée repartait de zéro
chaque mois, sans mémoire de l'effort. W6.1 introduit le report
(« enveloppe »). Question posée au propriétaire le 26.08.2026 :
activer le report partout d'office, ou ligne par ligne ?

### Décision

Réponse du propriétaire : **opt-in par ligne**. Une ligne budgétaire
porte « Reporter le reste au mois suivant » (PWA : clé additive
`report: true` ; natif : `BudgetLine.rollover`). Défaut = comportement
historique intact. Le montant reporté est CALCULÉ en chaîne à la
lecture (on remonte les mois précédents tant que la ligne de la
catégorie reporte, puis reste = max(0, prévu + reporté − réel)) —
jamais stocké en double. Un dépassement ne se reporte JAMAIS (pas de
dette de budget cachée). Le report n'existe que sur les lignes de
DÉPENSE. FI-20 tenu : le budget ne touche aucun solde bancaire.
Décision jumelle du même jour (pour W6.4) : les fonds annuels seront
INFORMATIFS en V1 — aucune écriture automatique d'argent.

### Vérification

PWA : parcours 211 né rouge (5 échecs nommés) → vert ; sabotage (la
borne max(0, …) saute) → « un dépassement ne se reporte jamais » mord
seul — après DURCISSEMENT du scénario (une catégorie inconnue du
référentiel et une chaîne absorbante rendaient le contrôle inerte :
le sabotage a fait son travail en révélant le test faible, consigné).
Natif : `BudgetRolloverTests` (5 — chaîne 300, sans rollover rien ne
change, dépassement jamais négatif, appel sans historique inchangé,
FI-20), prouvés par le job simulateur CI.


## ADR-066 — Ignorer une échéance libère le disponible

Date: 2026-08-26
Status: accepted

### Contexte

W2.5 a donné à l'agenda ses gestes (reporter, ignorer, annuler) sans
surface à l'écran, et W5.2 a fait lire les échéances au rituel du mois
(« ignorer libère le compteur »). Restait une divergence mesurée et
consignée depuis W5.2/W5.2b : le « disponible » (« Prévu fin du
mois ») continuait de RÉSERVER une charge ignorée —
`recurringRemainingCount` (PWA) ne lisait pas les échéances
persistées, alors que le natif (`RecurringScheduleService`, W5.2b) les
soustrait déjà de sa prévision. Question posée au propriétaire le
26.08.2026 : « quand vous ignorez une échéance ce mois-ci, l'argent
qu'elle réservait doit-il redevenir disponible ? »

### Décision

Réponse du propriétaire : **« Oui, ignorer libère »**. Sur les deux
plateformes : une échéance IGNORÉE ou ANNULÉE (machine W2.3/W2.5) ne
pèse plus sur le disponible, la prévision de fin de mois ni la liste
« à faire » du mois — sans créer ni toucher aucun mouvement. REPORTER
garde l'échéance ouverte : reporté ≠ libéré. Les compteurs PWA
(`recurringRemainingCount`, `openBillsDue`) apprennent la même vérité
que les occurrences ; le comparateur W2.7a n'a plus d'écart à
compenser. Le geste vaut pour LE mois de l'échéance seulement — la
série continue les mois suivants.

### Vérification

Parcours 210 (né rouge) : gestes exposés dans les feuilles série et
facture, reporter garde la date d'origine et la réservation, ignorer
libère (1500 puis 400 rendus au disponible), la ligne quitte « à
faire », zéro mouvement créé, comparateur W2.7a à zéro écart.
Sabotage ciblé consigné dans le statut W5.7.


## ADR-065 — Devises V1 : base unique, taux datés et sourcés

Date: 2026-08-25
Status: accepted

### Contexte

Les taux de change étaient des nombres nus (`fxRates`) sans date ni
source (FI-16 OUVERT). La matrice W0.5 demandait de trancher la
politique multi-devise à W4.2. Question posée au propriétaire le
25.08.2026 ; réponse : « V1 : base unique ».

### Décision

1. Tout s'affiche dans la devise de BASE ; chaque compte étranger est
   converti ; l'historique estampillé à la saisie ne bouge jamais
   (FI-19, mécanique existante conservée).
2. CHAQUE écriture de taux passe par UNE porte (`enregistrerTaux`,
   PWA) qui consigne une quote datée et sourcée (FI-16) dans la clé
   additive `fxQuotes`, APPEND-ONLY — l'ancienne quote survit, le
   cache `fxRates` pointe la dernière.
3. Un taux illisible est un refus nommé — rien n'est consigné
   (FI-34) ; un taux absent reste un état « incomplet » visible,
   jamais 1:1 (FI-17, verrouillé par test).
4. Les défauts pays ne sont PAS des quotes (aucune observation
   réelle) ; les quotes commencent à la première écriture réelle.
5. Le multi-devise complet (V2 — totaux par devise, changement de
   base sans réécriture) est explicitement hors périmètre.

### Vérification

Parcours 198 né rouge (8 échecs nommés) ; sabotage (la porte écrase au
lieu d'ajouter) → le contrôle append-only mord seul ; FI-19 verrouillé
(l'estampille d'un mouvement survit au changement de taux) ; le miroir
natif (`FxQuote`, sortie d'`enAttenteNatif`) arrive en W4.2b.


## ADR-064 — La migration du journal prépare sans allumer

Date: 2026-08-25
Status: accepted

### Contexte

W3.7 migre l'historique des mouvements vers le journal (ADR-058
étape 5). Restait à décider si la lecture des soldes bascule en même
temps. Question posée au propriétaire le 25.08.2026 ; réponse :
« Préparer sans allumer ».

### Décision

1. La migration (PWA `migrerHistoriqueJournal`, natif
   `JournalHistoryMigrationService`) offre un ESSAI À BLANC qui
   raconte tout — créés, refus nommés, écarts prévus — sans rien
   écrire.
2. La migration réelle n'applique que si TOUT est propre (zéro refus,
   zéro écart) ; sinon RIEN ne change (atomique, FI-31) et le rapport
   dit pourquoi.
3. La migration n'allume JAMAIS la lecture des soldes
   (`S.journalActif` / `JournalReadSwitch`) : l'allumage attend les
   devises (W4) et une décision propriétaire distincte.
4. Rollback : le journal est additif — il se vide sans toucher un
   seul mouvement ; l'ancien chemin de lecture reste intact.

### Vérification

Parcours 196 né rouge (6 échecs nommés) ; sabotage (le refus
n'empêche plus rien) → le contrôle d'atomicité mord seul ; tests
natifs `JournalHistoryMigrationServiceTests` (essai inerte, réel
prouvé et idempotent, refus atomique nommé, survie sur store disque
FI-35, jamais d'allumage).


## ADR-063 — Le journal stocke des centimes entiers (unités mineures)

Date: 2026-08-25
Status: accepted

### Contexte

W3.1 doit fixer la représentation de STOCKAGE des montants du journal,
identique sur les deux plateformes (matrice W0.5 : « unités mineures vs
`Decimal` canonique », décision attendue au Work Order W3). La question
a été posée au propriétaire le 25.08.2026, qui l'a écartée en ordonnant
de continuer ; les autorités déjà approuvées tranchent :
`DATA_MODEL_TARGET.md` définit `Money { minorUnits: Int64, currency }`
et l'ADR-059 a fixé les fixtures canoniques en unités mineures
entières.

### Décision

1. Le journal (PWA `S.journal`, natif `JournalEntry`/`JournalPosting`,
   schéma V12) stocke chaque montant en CENTIMES ENTIERS + devise —
   la même représentation que les fixtures canoniques.
2. Le natif continue de CALCULER en `Decimal` (invariant produit) ; la
   frontière `Decimal` ↔ centimes est EXACTE, avec arrondi déterministe
   `.plain` à 2 décimales (FI-18) ; une valeur illisible est refusée,
   jamais convertie en zéro (FI-34).
3. Chaque écriture est équilibrée PAR DEVISE en centimes entiers
   (FI-08) ; le déséquilibre est un refus nommé (devise + écart).
4. Porte d'entrée unique : `creerEcritureJournal` (PWA) et
   `JournalEntry.equilibree(...)` (natif) — personne ne compose une
   écriture à la main.

### Vérification

Parcours 190 né rouge (8 échecs nommés) ; sabotage (équilibre ignoré)
→ seuls les 2 contrôles d'équilibre échouent, la garde de restauration
reste indépendante ; tests natifs `MoneyTests` (frontière exacte,
arrondi déterministe, refus du NaN) et `JournalEntryTests` (équilibre
par devise, clé unique, migration disque V11 → V12, FI-35).


## ADR-062 — Une date n'est pas une preuve : la case « C'est déjà fait »

Date: 2026-08-25
Status: accepted

### Contexte

La saisie classait automatiquement toute date du jour ou passée en
« comptabilisé » (« dater, c'est le geste », FE2 du 18.08) — une
déduction invisible, en tension avec FI-02 (constat n° 3 de l'audit).
Question posée au propriétaire le 25.08.2026 ; réponse : « Case cochée
par défaut ».

### Décision

1. La feuille de saisie (PWA et iOS) montre une case « C'est déjà
   fait (payé ou reçu) », COCHÉE par défaut pour une date passée ou du
   jour — le geste habituel reste un seul tap — et DÉCOCHABLE : la
   personne décide, jamais la seule date.
2. Décochée, le mouvement naît « Prévu » et ne pèse sur aucun solde
   tant qu'il n'est pas confirmé (FI-01/02).
3. Une date FUTURE n'a pas de case : le futur est toujours prévu.
4. En édition, la case reflète le statut réel du mouvement.
5. Natif : `TransactionPostingPolicy.initialStatus(for:now:alreadyDone:)`
   devient la porte de la SAISIE ; `automaticStatus` reste pour les
   gestes explicites (confirmation d'échéance) et l'import (revisité
   en W7).

### Vérification

Parcours 184 né rouge (4 échecs nommés) ; sabotage (la case ignorée) →
le test mord seul (solde faussé nommé) ; test natif
`testInitialStatusFollowsTheCheckboxNeverTheDateAlone` ; captures
320/390 inspectées (`docs/neon-ultra/budget-prisme/w24a/`).


## ADR-061 — Le résultat du mois exclut l'épargne et l'investissement

Date: 2026-08-25
Status: accepted

### Contexte

Le « Résultat du mois » mesuré (PWA `snapshot().cashFlow`, natif
`snapshot.cashFlow`) soustrait l'épargne et l'investissement : mettre
500 CHF de côté baissait le résultat comme une dépense, en
contradiction avec le principe produit « mettre de côté n'est pas
dépenser » (FI-10) et l'invariant FI-21. Question posée au
propriétaire le 25.08.2026 ; réponse : « Exclure l'épargne ».

### Décision

1. Résultat du mois = reçus réels − vraiment dépensé (impôts et
   intérêts compris) ; l'argent mis de côté (épargne, investissement)
   n'y entre plus — il reste montré à part (« mis de côté »).
2. Le remboursement de CAPITAL d'une dette n'y entre pas non plus :
   comme l'épargne, il ne quitte pas votre patrimoine (FI-14, FI-21).
   La mesure a d'ailleurs montré que le natif le soustrayait et pas la
   PWA — deux formules pour le même mot ; le contrat commun est
   désormais : résultat = reçus − coût de vie − impôts, identique sur
   les deux plateformes.
3. La même convention vaut pour les agrégats annuels.
3. Contrat d'abord : la fixture canonique porte le champ optionnel
   `resultatMineures` ; l'implémentation (PWA + iOS, même PR, fixtures
   de parité mises à jour) vit dans un lot séparé AUT-061, test rouge
   d'abord, avant les runners W1.6.

### Vérification

Fixture canonique rouge par construction jusqu'à AUT-061 ; parité
prouvée par les runners W1.6 ; contrôle négatif par sabotage d'un seul
côté.


## ADR-060 — Un compte peut être exclu du patrimoine, sur les deux plateformes

Date: 2026-08-25
Status: accepted

### Contexte

Écart mesuré pendant W1.2 : le natif filtre `includeInNetWorth` par
compte dans `NetWorthService.breakdown`, la PWA additionne TOUS les
comptes dans `fortuneTotale()` — deux fortunes possibles pour les
mêmes données (contre FI-40). Question posée au propriétaire le
25.08.2026 ; réponse : « Parité : ajouter le réglage au site ».

### Décision

1. La PWA gagne le réglage « compte dans le patrimoine » (clé additive
   `netWorth`, défaut `true` — aucune donnée existante ne change de
   sens), et `fortuneTotale()` filtre comme le natif.
2. Le solde du compte exclu reste vrai et visible partout ; seul
   l'agrégat de fortune l'ignore (FI-25).
3. Contrat d'abord : fixture canonique `patrimoine-compte-exclu`
   (W1.4) ; l'implémentation PWA (formulaire de compte + filtre +
   test e2e rouge d'abord + captures) vit dans le lot séparé AUT-060.

### Vérification

Le natif passe la fixture sans changement ; la PWA la passera après
AUT-060 ; sabotage d'un côté → la gate W1.6/W1.7 mord.


## ADR-059 — W1.1 : les fixtures canoniques comptent en unités mineures

Date: 2026-08-25
Status: accepted

### Contexte

Le Work Order W1 (`docs/autonomie/w0/WORK_ORDER_W1.md`) exige de
trancher la représentation des montants DANS les fixtures canoniques :
unités mineures entières ou décimales en chaîne. L'audit recommande
les unités mineures ; la PWA compte déjà en centimes entiers (G01) et
l'iOS en `Decimal`.

### Décision

1. Dans les fixtures canoniques (`fixtures/canon/`), tout montant est
   un ENTIER d'unités mineures de sa devise (exposant ISO 4217) —
   champ suffixé `Mineures`. Un montant à virgule est un échec de
   validation, jamais un arrondi silencieux (FI-18, FI-34).
2. Les taux de change restent des CHAÎNES décimales, datées et
   sourcées (FI-16) — jamais un flottant binaire.
3. Cette décision porte sur le FORMAT D'ÉCHANGE des fixtures. Elle ne
   préjuge pas du stockage interne des moteurs (décision W3,
   propriétaire).
4. Le schéma version 1 est décrit dans `fixtures/canon/SCHEMA.md` et
   imposé par le validateur `webapp/tests/canon-schema.test.mjs`,
   branché en CI. Les états restent `planned/posted` (glossaire W0) ;
   les états du journal cible entreront au schéma version 2 avec W3.

### Vérification

Validateur né rouge (2 échecs nommés : contrat absent, fixture
absente) ; fixture d'exemple conforme → vert ; contrôle négatif :
montant `2000.5` injecté → échec nommant le mouvement, le champ et
l'ADR ; restauration → vert ; étape CI dédiée ajoutée.


## ADR-058 — Budget Autonomie 100 : migration progressive du moteur

Date: 2026-08-25
Status: accepted

### Contexte

L'audit total du 25.08.2026 (`docs/audit-total-2026-08-25/`, verdict
NO-GO public au SHA `bcef018`) montre que la complexité du produit a
progressé plus vite que son noyau : statut financier limité à
`planned/posted`, date passée assimilée à une preuve, occurrences non
persistées, corrections destructrices, deux moteurs indépendants,
devises sans taux datés, schémas historiques non figés. Le programme
**Budget Autonomie 100** (skill `budget-autonomie-100`, lots W0–W11)
remet le noyau à niveau.

### Décision

1. La remise à niveau est PROGRESSIVE — jamais de réécriture massive :
   figer fixtures et contrats (W1) → modèle nouveau EN PARALLÈLE →
   shadow-write sans changer l'interface → comparateur ancien/nouveau →
   migration avec dry-run et backup → bascule par vue derrière feature
   flag → retrait de l'ancien chemin seulement après preuve et
   rollback.
2. Les deux apps restent utilisables pendant toute la migration ;
   aucune donnée existante n'est perdue ; les invariants `TENUS` du
   registre W0 gardent leurs tests verts à chaque étape.
3. Une PR = un sous-lot du premier Wn READY. Modèle, formule et
   refonte visuelle vivent dans des PR séparées.
4. Le contrat de vérité W0 (glossaire des états, dictionnaire des
   chiffres, registre des invariants, matrice de dépendances —
   `docs/autonomie/w0/`) fait autorité : tout nouvel état, chiffre ou
   invariant passe par ces documents et une fixture W1.
5. Hiérarchie inchangée : `budget-autonomie-100` ordonne le système ;
   `budget-prisme` régit chaque surface d'écran ; l'issue #70 reste
   l'autorité release (W11 ne se ferme pas sans elle) ; fusion et
   publication exigent toujours une autorisation explicite séparée.

### Vérification

W0 est documentaire (aucun calcul, modèle, écran ni workflow modifié —
vérifiable au diff). La preuve du programme naît en W1 : runners
canoniques Web/Swift, sorties structurées identiques, sabotage d'un
côté qui mord, CI sur le HEAD exact.


## ADR-057 — CPT1 : la fiche compte raconte le mois (parité PWA)

Date: 2026-08-24
Status: accepted

### Contexte

Demande propriétaire du 24.08.2026 : « continue avec les ajustements
des comptes avec ce qu'il reste, les dépenses, les entrées ». Mesure :
la fiche compte iOS a déjà `monthFlowCard` (« Entrées du mois /
Sorties du mois », posté seulement, `signedEffect`) — la fiche PWA
montrait le solde, la courbe et l'historique mais AUCUN résumé du
mois. Défaut de parité, dans ce sens-là.

### Décision

La fiche compte PWA gagne la carte « Ce mois-ci sur ce compte » :
« Entrées du mois » (+, vert) et « Sorties du mois » (−, corail),
calculées par `accountMonthFlows` avec EXACTEMENT les règles de flux
de `balance()` (centimes, devise du compte, arrivées via `dest`
comprises), posté seulement — la légende l'écrit : « Seul l'argent
reçu ou payé compte ici — jamais le prévu. » Les mots sont ceux du
natif. Divergence assumée : la PWA tait la carte quand rien n'a bougé
(le natif l'affiche avec des zéros).

### Vérification

Parcours 178 : carte présente, 2'000 entrés / 800 sortis (dépense +
mis de côté), le prévu (999) ne compte JAMAIS, la fiche Épargne voit
l'argent arriver (300). Contrôle négatif : sabotage (le prévu compte)
→ le test mord seul (1'799 au lieu de 800). Captures 320/390
avant/après inspectées (`docs/neon-ultra/budget-prisme/cpt1/`) — la
mauvaise clé de libellé du fixture (« undefined » à l'écran) a été
attrapée par l'inspection réelle des captures, pas par les regex.


## ADR-056 — MF2 : « si tout se passe comme prévu » enchaîne les mois

Date: 2026-08-24
Status: accepted

### Contexte

Défaut résiduel des captures du 24.08 (après MF1/ADR-055) : la petite
ligne conditionnelle du mois futur repartait du solde actuel et
n'ajoutait que les flux du mois consulté. Résultat : le MÊME chiffre
répété sur tous les mois futurs (14'057.40 en septembre, en octobre,
en novembre…), comme si les mois intermédiaires n'existaient pas — la
phrase « si tout se passe comme prévu » était fausse sous ses propres
mots.

### Décision

Sur les deux plateformes, l'estimation du mois futur ENCHAÎNE : fin
prévue du mois courant (`endOfMonthForecast` / `available.total`),
puis + flux prévus de chaque mois intermédiaire jusqu'au mois
consulté (PWA : `estimationEnchainee(y, m)` ; natif : le flux d'un
mois est `available.total − available.liquidBalance` de son
instantané). Aucun agrégat existant ne change ; le grand chiffre du
mois futur reste l'argent réel (MF1). La ligne se tait toujours quand
rien n'est prévu.

### Vérification

Parcours 177 né rouge (2 échecs nommés : 28'114.80 attendu au mois
+1, 42'172.20 au mois +2, lu 14'057.40 répété) ; sabotage (les mois
intermédiaires ne pèsent plus) → le test mord seul ; parcours 176
aligné ; captures 320/390 avant/après inspectées
(`docs/neon-ultra/budget-prisme/mf2/`) ; natif prouvé par le job
simulateur CI.


## ADR-055 — MF1 : le mois futur montre le vrai argent d'abord

Date: 2026-08-24
Status: accepted

### Contexte

Demande propriétaire du 24.08.2026, captures à l'appui : app fraîche,
salaire saisi mais PAS encore reçu (bouton « Reçu » jamais pressé) —
le mois suivant affichait « Estimation du mois : CHF 14'057.40 » en
focal. « Tant que je n'ai pas appuyé sur le bouton, il ne faut rien me
mettre. » Le mois futur repartait du solde actuel et mettait la somme
des flux prévus en grand : le principe « l'argent prévu et l'argent
réel ne se mélangent jamais » était trahi visuellement. Trois options
proposées ; le propriétaire a choisi « le vrai argent d'abord ».

### Décision

Sur un mois FUTUR, des deux plateformes :

1. Le grand chiffre = l'argent RÉELLEMENT sur les comptes (`liquid` /
   `liquidBalance`), titre « Sur vos comptes maintenant ».
2. La note dit la règle : « L'argent prévu n'est pas compté ici tant
   qu'il n'est pas reçu ou payé. »
3. L'estimation reste écrite en dessous, en petit, au conditionnel —
   « Si tout se passe comme prévu : CHF X à la fin de ce mois. » — et
   se tait quand rien n'est prévu (estimation = réel).
4. Aucun calcul ne change : `endOfMonthForecast` et les blocs
   « prévu » du mois futur restent tels quels ; seule la hiérarchie
   visuelle change.

### Vérification

Parcours 176 né rouge (4 échecs nommés, chiffres exacts des captures
propriétaire) ; contrôle négatif par sabotage (estimation remise en
focal → le test mord seul) ; parcours 5487/5489/6433 alignés sur les
nouveaux mots ; natif prouvé par le job simulateur CI ; captures
320/390 avant/après inspectées (`docs/neon-ultra/budget-prisme/mf1/`).


## ADR-054 — PAR1 : parité native de « Tout » et « Mes abonnements »

Date: 2026-08-22
Status: accepted

### Contexte

VUE1 (ADR-053) et SUB1 (ADR-052) n'existaient que sur la PWA. L'app
native affichait la carte du mois avec deux positions seulement
(« Maintenant / Fin du mois ») et le hub Gérer n'avait aucune porte
« Mes abonnements ». Les deux plateformes doivent raconter la même
histoire (parité, même famille n° 3, même vue d'ensemble).

### Décision

1. `HomeTab` gagne la position `HeroPosition.everything` (« Tout »,
   mois courant seulement) : titre « Tout votre argent », focal =
   fortune totale lue par `NetWorthService.breakdown(...).netWorth` —
   le MÊME service que Comptes et Patrimoine, aucune nouvelle formule —
   puis les lignes écrites : Disponible maintenant, Épargne accessible
   (`accessibleSavings`), Mis de côté ce mois (épargne + investi du
   snapshot), Réserve d'impôts (`TaxProvision` de l'année courante),
   Objectif (prioritaire actif, sinon premier actif, sinon rien ; avancement
   via `GoalProgressService`). La jauge d'avancement du mois se tait sur
   « Tout » (un seul point focal lumineux).
2. `RecurringListView` gagne `onlySubscriptions` : même liste resserrée
   sur la section abonnements, titre « Mes abonnements », état vide
   honnête. `MoreTab` gagne la porte correspondante à sa place dans
   l'ordre des familles — aucun nouvel écran, aucun nouveau calcul.

### Vérification

Lot natif sans nouveau calcul (précédent A12) : la preuve est le job
simulateur de la CI (build + tests iOS) sur le HEAD exact ; les suites
web restent inchangées et vertes (175 parcours). Le test natif
`testHeroCardOffersExactlyTwoHonestPositions` a mordu tout seul sur la
troisième position (échec CI nommé) — il devient
`testHeroCardOffersExactlyThreeHonestPositions` et verrouille l'ordre
« Maintenant · Fin du mois · Tout » : c'est le contrôle négatif naturel
du lot.


## ADR-053 — VUE1 : « Tout » — la vue d'ensemble sur la carte du mois

Date: 2026-08-22
Status: accepted

### Contexte

Demande propriétaire du 22.08.2026, capture à l'appui : la carte du
mois (« Maintenant / Fin du mois ») ne montre que le quotidien — « il
manque épargne, investissements, mis de côté, impôts… un résumé, tout
sur une seule vue, avec plusieurs choix, et l'objectif ».

### Décision

1. La carte du mois gagne une TROISIÈME position « Tout » (mois courant
   seulement, comme les deux autres) : titre « Tout votre argent »,
   focal = FORTUNE TOTALE, puis les lignes écrites — Disponible
   maintenant, Épargne accessible, Mis de côté ce mois, Réserve
   d'impôts, Objectif prioritaire (nom · fait sur visé).
2. AUCUN nouveau calcul : uniquement les agrégats existants. La
   formule de fortune totale est EXTRAITE en une fonction unique
   `fortuneTotale()` servie à Comptes ET à la carte — jamais deux
   vérités (le test compare les deux affichages au franc près).
3. L'objectif montré : le prioritaire actif, sinon le premier actif,
   sinon rien. La jauge d'avancement du mois se tait sur « Tout »
   (un seul point focal lumineux) ; « Ajouter » reste la seule action.

### Vérification

Parcours 175 né rouge (5 échecs nommés) ; même chiffre carte↔Comptes ;
aucune promesse de connexion ; contrôle négatif par sabotage ; captures
320/390 inspectées.


## ADR-052 — SUB1 : « Mes abonnements » a sa porte dans Gérer

Date: 2026-08-21
Status: accepted

### Contexte

Demande propriétaire du 21.08.2026 : « il manque une page mes
abonnements ». La page existait — « Ce qui revient » filtré sur les
abonnements (coût par an, moyenne par mois, liste triée) — mais AUCUNE
entrée du hub Gérer n'y menait : introuvable sans connaître le filtre.

### Décision

Le groupe « Les quatre familles » du hub Gérer gagne la porte
« Mes abonnements » (famille n° 3, à sa place dans l'ordre des
familles), avec un sous-titre honnête : `N abonnements · CHF X / mois`
(revenus exclus, nature « abonnement » seulement), ou l'invitation
quand il n'y en a pas. La porte ouvre la vue existante déjà filtrée —
aucun nouveau calcul, aucun nouvel écran.

### Vérification

Parcours 174 né rouge (3 échecs nommés : porte absente, coût absent,
vue non filtrée) ; le compte de lignes du hub (parcours P07) passe de
dix à onze et le dit ; contrôle négatif par sabotage ; captures 320/390
inspectées.


## ADR-051 — CAT1 : la personne écrit sa catégorie — « IKEA », « Poulet »

Date: 2026-08-21
Status: accepted

### Contexte

Demande propriétaire du 21.08.2026, capture à l'appui : la liste fixe
de catégories ne suffit pas — « il faut aussi laisser la personne
mettre ce qu'elle veut, par exemple Poulet ou IKEA ». Le rapport de
budget avait de plus un repli silencieux : une catégorie inconnue
était traitée comme un revenu.

### Décision

1. PWA : clé d'état ADDITIVE `customCategories` (`{name ≤ 40, kind
   expense|income}`) — la catégorie libre naît sur la feuille de
   saisie (« Écrire ma catégorie… » + champ), garde le SENS de son
   type de naissance, est dédupliquée pliée (une existante — builtin
   comprise — est réutilisée), et réapparaît PARTOUT du même sens :
   saisie, récurrents, factures, lignes de budget. Épargne, pilier,
   impôts et virements gardent leurs listes (sens financier protégé).
2. `categoryKind(cat)` remplace les lectures directes de `CATEGORIES`
   (rapport de budget, import CSV) — le repli « income » silencieux
   est mort : une catégorie retenue compte selon SON sens.
3. Restauration tolérante : une entrée illisible est RETIRÉE sans faire
   échouer le fichier ; doublons pliés fusionnés ; ancien état → `[]`.
4. Natif (parité) : « Écrire ma catégorie… » sous le Picker de
   `TransactionFormView` — alerte avec champ, déduplication pliée,
   `BudgetCategory` existant réutilisé, sens du type courant ; le
   modèle, le schéma et la sauvegarde ne changent pas (les catégories
   personnalisées y vivaient déjà).

### Vérification

Parcours 173 né rouge (5 échecs nommés : option absente, vide accepté,
catégorie non portée, non reproposée, budget à 0) ; vide refusé sans
perdre la saisie ; « IKEA » jamais proposée en revenu ; budget sur
« IKEA » compte 50, pas 0 ; contrôle négatif par sabotage ; captures
320/390 inspectées.


## ADR-050 — INV1-C : le type d'un compte qui porte des positions ne change pas en silence

Date: 2026-08-21
Status: accepted

### Contexte

Suite de la chasse aux défauts INV1. Changer le type d'un compte
titres (« Bourse / titres » → autre) rendait ses positions INVISIBLES
— la section Positions ne vit que sur la fiche d'un compte titres —
alors que la suppression du compte restait bloquée (ADR-049) en
pointant une fiche qui ne les montrait plus : une impasse, sur les
DEUX plateformes.

### Décision

Le type reste la vérité (règle P05-C) : quitter « Bourse / titres »
avec des positions est BLOQUÉ en le disant — « Des positions
expliquent ce compte — supprimez-les avant de changer son type. » —
même règle PWA (`accForm` submit) et natif (`AccountFormView.save`).
Sans position, le changement de type reste libre.

### Vérification

Parcours 171 né rouge (« type savings » obtenu en silence) → vert ; le
même parcours prouve la liberté retrouvée sans position ; contrôle
négatif par sabotage ; captures 320/390 inspectées (message visible,
données intactes).

## ADR-049 — INV1-B : un compte qui porte des positions ne se supprime pas en silence

Date: 2026-08-21
Status: accepted

### Contexte

Chasse aux défauts après le programme Identités locales. INV1
(ADR-047) a donné la garde de suppression au natif
(`AccountDetailView.deletionBlocker`) mais PAS à la PWA :
`accountDeleteBlocker` ignorait les positions. Supprimer un compte
titres laissait ses positions ORPHELINES en silence — invisibles à
l'écran, puis retirées à la prochaine restauration (perte muette).
Second défaut d'honnêteté : « Effacer les opérations » efface les
positions depuis INV1 sans le dire (confirmation et texte de
confidentialité muets).

### Décision

1. `accountDeleteBlocker` gagne la même règle que le natif : « Des
   positions expliquent ce compte — supprimez-les d'abord sur sa
   fiche. » Les autres gardes ne changent pas.
2. La double confirmation d'« Effacer les opérations » et le texte de
   confidentialité disent désormais « positions » dans l'énumération.

### Vérification

Parcours 170 né rouge (2 échecs nommés : blocage absent, texte muet) ;
le même parcours prouve que SANS position la suppression redevient
possible ; contrôle négatif par sabotage (garde retirée → le parcours
170 mord seul) ; captures 320/390 inspectées (message visible dans la
feuille).

## ADR-048 — BR1 : la provenance des marques garde la porte, le monogramme reste la norme

Date: 2026-08-21
Status: accepted

### Contexte

Programme Identités locales, dernier lot BR1 (« ajouter un fournisseur
à la fois selon LOGO_POLICY.md, avec preuve, checksum, fallback et
captures ; aucun lot importer tous les logos »). La politique exige
pour tout `approved_asset` une source officielle aux conditions lues,
des SHA-256, un fallback sûr et une VALIDATION HUMAINE consignée
(`reviewedBy`/`reviewedAt`) AVANT le passage. Cette validation
appartient au propriétaire : aucun actif ne peut être approuvé par
l'agent seul.

### Décision

1. Le manifeste de provenance versionné existe :
   `fixtures/provenance-marques.json` (version 1, `entries: []`) — ZÉRO
   entrée est une couverture complète, le monogramme n'est pas un échec
   (`catalogCoverage` = 100 %, `verifiedLogoCoverage` = 0 %).
2. Le validateur vit dans la suite catalogue (CI, avant les suites
   navigateur) : toute identité `approved_asset` SANS entrée complète
   de manifeste échoue ; toute entrée exige les 13 champs de la
   politique, une clé existante au catalogue, un fallback sûr, des
   SHA-256 hexadécimaux et un CHECKSUM EXACT recalculé sur le fichier ;
   une entrée orpheline échoue aussi.
3. La mention légale de la politique est VISIBLE des deux côtés
   (réglages, « Marques et logos ») : « Les noms et marques
   appartiennent à leurs propriétaires respectifs… Budget n'est ni
   affilié, ni sponsorisé, ni connecté… » — et dit qu'aucun logo tiers
   n'est affiché aujourd'hui.
4. Approuver un premier actif reste un micro-lot futur DÉCLENCHÉ PAR LE
   PROPRIÉTAIRE : source officielle choisie, conditions lues, revue
   consignée — alors seulement `markPolicy` passe à `approved_asset`.
5. Correctif d'honnêteté au passage : la méthodologie native parlait
   encore d'un « taux configuré (30 % par défaut) » — texte aligné sur
   ADR-035 (aucun taux, les impôts se saisissent comme des paiements).

### Vérification

Suite catalogue née rouge (3 échecs nommés : manifeste absent, mention
PWA absente, mention native absente) ; parcours 169 (carte visible et
dépliée) ; contrôle négatif par sabotage (identité passée
`approved_asset` sans manifeste → la suite échoue en la nommant) ;
`testPrivacyAndMethodologyTextsStayHonest` reste vert (« Estimé = payé
+ encore dû » conservé) ; captures 320/390 inspectées.

## ADR-047 — INV1 : les positions expliquent le solde, elles ne s'y ajoutent jamais

Date: 2026-08-21
Status: accepted

### Contexte

Programme Identités locales, lot INV1 (« classe finance/données, projet
séparé — spécifier avant de coder »). Un compte titres n'avait que son
solde : rien ne disait CE qu'il contient. Le piège classique est le
double compte : additionner des positions à un solde qui les contient
déjà (44'000 + 40'000 = 84'000 de fortune fantôme).

### Décision

1. AUTORITÉ DE PATRIMOINE : le solde du compte titres. Les positions
   l'EXPLIQUENT — valeur des positions + espèces/non réparti = solde.
   Aucune fortune, aucun total, aucun agrégat ne lit jamais une
   position (44'000, jamais 84'000). Un dépassement s'affiche en
   espèces NÉGATIVES avec un avertissement — jamais ramené à zéro.
2. Contrat de données (champs du skill) : `instrumentName`,
   `tickerOrISIN?`, `quantity`, `manualPrice`, `priceCurrency`,
   `valuationDate`, `costBasis?`, compte porteur. La devise du prix est
   celle du compte (aucune addition multi-devises).
3. HONNÊTETÉ DU PRIX : une valeur manuelle dit « Prix saisi le … » —
   les mots « en direct », « cours actuel », « temps réel » sont
   interdits et testés. La date est celle de la SAISIE.
4. PWA : clé d'état ADDITIVE `positions` (ancien état normalisé à `[]`,
   restauration : une position illisible ou orpheline est RETIRÉE sans
   faire échouer le fichier — elle n'a aucun pouvoir financier) ;
   section « Positions » sur la fiche du compte titres, feuille
   `posForm` (nom, symbole facultatif, quantité, prix, date, prix
   d'achat facultatif).
5. Natif : `BrokeragePosition` (@Model additif, `BudgetSchemaV10`,
   doctrine ADR-015), `BrokeragePositionMath` (total expliqué +
   espèces, testable), section dans `AccountDetailView` (comptes
   `.broker`), `PositionFormView`, DTO de sauvegarde OPTIONNEL (un
   fichier d'avant les positions se restaure à l'identique), garde de
   suppression de compte (« des positions expliquent ce compte »).

### Vérification

Parcours 168 né rouge (6 échecs nommés : section absente, champs du
contrat, 40'000 + 4'000 = 44'000, fortune inchangée, « Prix saisi
le… », persistance) ; `BrokeragePositionTests` natif (math 44k/40k/4k,
dépassement négatif, round-trip Decimal exact, fichier ancien) ;
contrôle négatif par sabotage ; captures 320/390 inspectées.

## ADR-046 — P10/P12-C : l'icône choisie est préservée, jamais réécrite

Date: 2026-08-21
Status: accepted

### Contexte

Programme Identités locales, lot P10/P12-C (« P10 : préserver l'emoji
ou le glyphe explicitement choisi, ne pas le réécrire lors d'une
modification ; P12 : dériver une icône du type de bien/dette, les
marques commerciales ne sont pas nécessaires par défaut »). Mesure :
deux défauts réels sur P10 — la PWA imposait 🎯 à la modification d'un
objectif sans emoji (le glyphe neutre est pourtant un choix), et le
natif réécrivait TOUJOURS `goal.emoji = kind.defaultEmoji` à
l'enregistrement, détruisant un emoji restauré ou personnalisé
(BackupService transporte `goal.emoji`). P12 était déjà conforme des
deux côtés (glyphe `asset`/`liability` PWA, `kind.systemImage` natif).

### Décision

1. L'emoji d'un objectif est un CHOIX. PWA : le défaut 🎯 ne s'applique
   qu'à la CRÉATION ; à la modification, vide reste vide (glyphe
   neutre) et l'emoji saisi reste tel quel.
2. Natif : règle unique testable
   `FinancialGoal.emojiAfterEditing(current:from:to:)` — l'emoji ne
   suit le type que tant qu'il n'a jamais été personnalisé (nil ou
   égal au défaut de l'ANCIEN type) ; un emoji personnalisé survit à
   toute modification, y compris un changement de type.
3. P12 reste sur des icônes DÉRIVÉES du type : glyphes peints
   `asset`/`liability` (PWA) et `kind.systemImage` (natif) — jamais une
   marque, jamais un emoji stocké rendu à l'écran (les champs `icon`
   hérités des données restaurées restent inertes).

### Vérification

Parcours 167 né rouge sur le défaut PWA (« obtenu 🎯 ») ; le même
parcours verrouille la préservation de l'emoji choisi, le défaut à la
création seule, et les glyphes dérivés P12 (emoji stocké jamais rendu).
`FinancialGoalEmojiTests` natif (survie au changement de type, défaut
qui suit, emoji restauré préservé) ; contrôle négatif par sabotage ;
captures 320/390 inspectées.

## ADR-045 — P13-C : choisir son assureur remplit un nom, jamais une prime

Date: 2026-08-21
Status: accepted

### Contexte

Programme Identités locales, lot P13-C (« réutiliser le registre sans
nouvelle architecture ; garder assureur/institution distinct du type de
contrat ou de pilier »). Le catalogue compte 13 assureurs
(institutions, sens `insurance`) mais la feuille Assurance gardait un
champ libre anonyme et la liste n'affichait aucune identité.
L'ambiguïté rente/capital est déjà corrigée (P0 AVS, ADR-036).

### Décision

1. Le MÊME sélecteur gagne une TROISIÈME porte strictement séparée :
   mode `insurers` — `entityKind: institution` ET
   `financialSense: insurance` seulement. Jamais une banque (UBS),
   jamais un service (Netflix), jamais un besoin générique
   (« Assurance ménage et RC » reste `generic` et n'y apparaît pas).
2. Choisir remplit UNIQUEMENT le champ « Assureur » ; le nom du
   contrat, la prime, la fréquence et les dates reviennent tels quels
   (instantané/restauration `svcInsSnapshot`), rien n'est créé.
   L'assureur reste DISTINCT du type de contrat : le type (LAMal, RC,
   véhicule…) ne bouge pas quand l'assureur change.
3. La liste des assurances décore par la MÊME correspondance exacte
   nom/alias pliée que les banques (`institutionEntryFor` PWA,
   `institutionEntry(matching:)` natif — helper réutilisé, aucune
   nouvelle architecture) ; l'inconnu garde son bouclier (PWA) ou le
   glyphe du type (natif) ; aucun total ne change.
4. Générateur : `insurerEntries` ajouté à `BudgetIdentityCatalog`
   (toujours la seule source, garde de dérive en CI) ;
   `IdentityServicePickerView.Mode` gagne `.insurers` (titres,
   exemples et saisie libre propres) ; libellé de sens
   « Assureur » des deux côtés.

### Vérification

Parcours 166 né rouge (4 échecs nommés : bouton absent, filtre du mode,
remplissage seul, tuile/bouclier) ; `testInsurerEntriesStayOnTheirDoor`
natif ; contrôle négatif par sabotage ; captures 320/390 inspectées ;
l'écran Assurances ne dit jamais « connecté », « synchronisé » ni
« en direct » (assertion du parcours 166).

## ADR-044 — P06/P16 : la fiche réutilise l'identité, l'onboarding la propose en option

Date: 2026-08-21
Status: accepted

### Contexte

Programme Identités locales, lot P06/P16 (« après P05, réutiliser
exactement la même identité dans la fiche de compte, puis l'onboarding
en option facultative avec Passer et sauvegarde atomique »). La liste
des comptes décorait (ADR-043) mais la fiche P06 restait nue, et
l'onboarding P16 créait le premier compte sans établissement.

### Décision

1. La fiche de compte P06 porte la MÊME tuile d'identité que la liste :
   correspondance EXACTE nom/alias pliée via la même fonction
   (`institutionEntryFor` PWA, `institutionEntry(matching:)` natif) —
   un établissement inconnu garde sa fiche sans tuile, jamais de
   devinette, jamais d'effet sur le solde.
2. L'étape comptes de l'onboarding P16 gagne une OPTION banque : un
   champ libre « Banque (facultatif) » et « Choisir ma banque… » qui
   ouvre le sélecteur d'institutions (ADR-043). Annuler et « Je ne
   trouve pas » referment la feuille sans rien changer ; choisir
   remplit le champ et rend la main à l'étape.
3. La sauvegarde reste ATOMIQUE : rien n'est écrit avant « C'est
   parti » (PWA) / « Créer mon ménage » (natif) — le nom choisi vit
   dans l'état de l'onboarding et devient l'`inst` du premier compte à
   la fin, dans le même save que tout le reste.
4. Le sélecteur filtre par le pays choisi à l'ÉTAPE 1 de l'onboarding
   (`svcCountry()`) — `S.country` n'existe qu'à la fin ; après
   l'onboarding, le pays enregistré reprend la main.
5. Le sélecteur gagne un appelant explicite (`svcPickerCaller`
   rec/acc/ob) : chaque porte rend la main au bon endroit, sans jamais
   rouvrir une feuille qui n'était pas ouverte.

### Vérification

Parcours 165 né rouge (7 échecs nommés : tuile de fiche absente, champ
et bouton absents, Annuler, filtre pays, remplissage sans création,
compte final sans banque, tuile absente sur Comptes) ;
`testFinishCarriesOptionalInstitutionName` natif (nom plié dans le même
save, vide reste vide, correspondance retrouvée) ; contrôle négatif par
sabotage ; captures 320/390 inspectées.

## ADR-043 — P05-C : choisir sa banque remplit un nom, jamais un solde

Date: 2026-08-21
Status: accepted

### Contexte

Programme Identités locales, lot P05-C. Le catalogue compte 57
institutions (44 banques, courtiers et caisses de prévoyance,
13 assureurs) mais « Comptes »
ne proposait rien : l'établissement restait un champ libre anonyme, et
aucune identité ne décorait la liste des comptes.

### Décision

1. Le MÊME sélecteur sert deux portes STRICTEMENT séparées : mode
   `services` (« Ce qui revient », sens subscription/bill/set_aside)
   et mode `institutions` (« Comptes », entityKind `institution` et
   sens account/broker/pension). Netflix n'apparaît jamais parmi les
   banques, UBS jamais parmi les abonnements. Les assureurs (sens
   `insurance`) attendent P13-C.
2. Choisir un établissement remplit UNIQUEMENT le champ « Établissement »
   avec le nom du catalogue. Jamais un solde, un accès, une connexion,
   un nom de compte ni un montant — la légende du formulaire le dit.
   « Je ne trouve pas mon établissement » et Annuler ramènent la saisie
   telle quelle.
3. La liste des comptes reconnaît un établissement par correspondance
   EXACTE (nom ou alias, plié accents/casse/espaces — jamais un
   « contient » : « CA » ou « BP » ne devinent rien) et le décore par
   `BudgetIdentityIcon` ; sinon le glyphe du type de compte reste.
   L'identité décore : aucun agrégat, aucun solde ne change.
4. Natif : `BudgetIdentityCatalog` généré gagne `institutionEntries` et
   `institutionEntry(matching:)` (générateur = seule source) ;
   `IdentityServicePickerView` gagne `Mode` ; `AccountFormView` ouvre le
   sélecteur en mode institutions ; `AccountRow` décore. PWA : miroir
   exact (`INST_SENSES`, `svcPickerMode`, `institutionEntryFor`,
   snapshot/restauration du formulaire compte).
5. Les catégories d'institutions gagnent leurs libellés français des
   DEUX côtés (Banques, Courtiers, Banques en ligne) — aucun mot
   technique anglais en interface.

### Vérification

Parcours 164 né rouge (bouton absent, mode mélangé, champ non rempli,
tuile absente) ; `testInstitutionEntriesStayOnTheirDoor` et
`testInstitutionMatchingIsExactNeverContains` natifs ; garde de dérive du
générateur en CI ; l'écran compte ne dit jamais « connecté »,
« synchronisé » ni « en direct » (assertion du parcours 164) ; contrôle
négatif par sabotage ; captures 320/390 inspectées.

## ADR-042 — ID1 : une clé d'identité optionnelle, stable et inoffensive

Date: 2026-08-20
Status: accepted

### Contexte

P08-C (ADR-041) dérivait l'identité du titre : renommer « Netflix » en
« Mes films » perdait le choix. ID1 rend le choix STABLE sans jamais
créer de risque de données.

### Décision

1. Les lignes régulières gagnent une clé OPTIONNELLE `identityKey` —
   kebab ASCII 1-40 (`^[a-z0-9]+(?:-[a-z0-9]+)*$`), la même règle
   LITTÉRALE sur les deux plateformes (`sanitizeIdentityKey` PWA,
   `BudgetIdentityKey` natif), prouvée par la fixture partagée
   `fixtures/identity-key-cases.json` (12 cas) et une garde exécutable.
2. La clé n'est écrite qu'à l'ENREGISTREMENT du formulaire, jamais à la
   sélection ; « Je ne trouve pas », Annuler et l'édition la
   transportent avec le reste de la saisie.
3. Une clé absente, inconnue, hostile ou retirée RETOMBE sur le
   monogramme du titre — sans erreur, sans markup, sans perte : à la
   restauration, la clé invalide est retirée, la ligne est conservée ;
   une clé saine mais inconnue est CONSERVÉE (catalogue extensible).
   Le natif sanitise dès l'init du modèle : une clé hostile ne peut
   même pas entrer dans le store.
4. Schéma natif : `BudgetSchemaV9` (ajout additif du champ, mêmes
   modèles, doctrine ADR-015 de migration légère automatique) ; DTO de
   sauvegarde optionnel — un fichier d'avant ID1 se restaure à
   l'identique, un fichier trafiqué perd la clé, jamais la ligne.
5. Rendu : la tuile d'identité suit la CLÉ (displayName du catalogue),
   pas le titre — c'est la promesse « choix stable même si le nom
   change » ; sans clé, rien ne change.

### Vérification

Parcours 163 né rouge (clé non persistée, clés hostiles conservées) ;
`BudgetIdentityKeyTests` (mêmes 12 cas), sanitation à l'init,
`testIdentityKeySurvivesBackupAndHostileKeyIsDropped` (round-trip,
fichier trafiqué, fichier ancien) ; garde de règle partagée dans la
suite catalogue ; capture de la tuile stable inspectée.

## ADR-041 — P08-C : le catalogue des services suggère, il n'invente jamais

Date: 2026-08-20
Status: accepted

### Contexte

Programme Identités locales, lot P08-C. Le catalogue éditorial (164
identités, ADR-037) doit servir la saisie sur « Ce qui revient » sans
jamais inventer le budget de la personne.

### Décision

1. La PWA embarque une copie STRUCTURELLE de
   `fixtures/catalogue-identites.json` (`IDENTITY_CATALOG`, monofichier
   hors ligne) ; garde de synchronisation exécutable dans
   `catalogue.test.mjs`. iOS reçoit `BudgetIdentityCatalog.swift`
   GÉNÉRÉ depuis la même fixture
   (`.github/scripts/generate-identity-catalog.mjs`) avec garde de
   dérive en CI — une seule autorité éditoriale.
2. « Ce qui revient » gagne « Choisir un service du catalogue » :
   recherche locale pliée (accents, alias), sections par pays puis par
   catégorie, « Je ne trouve pas mon service » et Annuler qui
   RESTAURENT la saisie en cours. Sens proposés : abonnement, facture,
   mise de côté — les institutions attendent P05-C/P13-C.
3. Choisir remplit AU PLUS : nom, nature, catégorie App (table de
   correspondance sûre — sans correspondance, aucune suggestion),
   rythme compatible (première cadence suggérée). Montant, compte,
   date, statut : jamais préremplis ; aucune ligne créée sans
   confirmation.
4. Marchés : PWA filtrée par le pays du profil (CH/FR/BE + GLOBAL) ;
   iOS reste nativement CHF → entrées CH + GLOBAL seulement (garde-fou
   devises du skill).
5. Identité visuelle : monogramme/glyphe DÉRIVÉ du nom à l'affichage
   (IC1) — aucune clé persistée dans ce lot ; la persistance optionnelle
   est le lot ID1.
6. Sécurité inchangée : texte pur uniquement (esc/identityTile), aucune
   image, aucune requête réseau, une recherche hostile ne rend aucune
   balise.

### Vérification

Parcours 162 né rouge (7 contrôles : bouton absent, recherche, filtre
pays, injection, remplissage, montant vide, saisie libre conservée) ;
garde embarquée/fixture et garde de dérive Swift en CI ;
`BudgetIdentityCatalogTests` (164 entrées, marchés iOS, institutions
exclues, correspondances sûres) ; captures du sélecteur inspectées.

## ADR-040 — REC2 : « toutes les quatre semaines » exact côté PWA

Date: 2026-08-20
Status: accepted — complète ADR-039

### Contexte

ADR-039 a livré trimestriel et semestriel sur la grille mensuelle de la
PWA, mais « toutes les quatre semaines » (Basic-Fit, salles de sport) ne
tient pas dans une grille : 13 échéances par an, et un mois porte DEUX
échéances. Le natif savait déjà ((week, 4), occurrences par date,
couverture par comptage) ; la PWA convertie en mensuel aurait volé une
échéance sur treize.

### Décision

1. `every: "four_weeks"` avec une vraie DATE d'ancrage (`startOn`
   {y, m, d}) : contrairement au mensuel (décision du 06.08 — pas de
   « jour de paiement »), le jour fait PARTIE du rythme — la question
   « Prochaine échéance » est légitime et posée seulement pour ce rythme.
2. Le moteur passe au COMPTAGE d'échéances (`recurringDueCount`,
   `recurringRemainingCount`) : N mouvements liés du mois couvrent les N
   premières échéances — même règle que le natif. Un mois à double
   échéance engage deux fois le montant dans la projection, attend deux
   gestes dans le rituel (« (2 × ce mois) ») et refuse le troisième.
3. Coût annuel : 13 × le montant, jamais 12.
4. Les rythmes existants sont inchangés (dueCount 0/1 — comportements
   byte-identiques) ; les données anciennes gardent leur sens ;
   restauration : `four_weeks` sans date d'ancrage valide est refusé,
   comme tout rythme inconnu.
5. Fixture de parité « quatre-semaines-exactes » : juillet 2026 porte
   les échéances des 2 et 30 (ancrage 15.01.2026) — 90 = 2 × 45 engagés,
   prouvé côté PWA (fixture 9) ET côté natif (mêmes dates, mêmes francs).

### Vérification

Parcours 160 né rouge (moteur absent, 12 au lieu de 13, pas de champ
date) ; fixture 9 née rouge (état refusé au chargement) ; couverture par
comptage prouvée sur le mois double (2 gestes, 3e refusé) ; test natif
miroir des mêmes dates ; 160 e2e + 9 parités + design + catalogue verts.

## ADR-039 — REC1 : cadences exactes — trimestriel et semestriel sur la PWA

Date: 2026-08-20
Status: accepted

### Contexte

Le catalogue des identités suggère des rythmes réels (électricité
trimestrielle, assurances semestrielles, Basic-Fit toutes les 4
semaines). Le natif les exprime déjà exactement (RecurrenceUnit ×
intervalCount, occurrences par date, couverture par comptage). La PWA ne
connaissait que mensuel et annuel : un trimestriel saisi en mensuel
aurait pesé douze fois au lieu de quatre.

### Décision

1. La PWA gagne `every: "quarter"` et `"semiannual"` — grille mensuelle
   conservée : `dueM` devient le mois d'ANCRAGE, l'engagement tombe
   quand l'écart à l'ancrage est un multiple du pas (3 ou 6 ; l'annuel
   est le cas pas = 12 de la même formule). Jamais réparti sur les
   autres mois ; résilié = plus jamais engagé ; coût annuel exact
   (× 4, × 2).
2. Champs ADDITIFS : une récurrence sans `every` reste mensuelle — le
   sens des données déjà enregistrées ne bouge pas. La restauration
   refuse un rythme inconnu et un rythme non mensuel sans mois
   d'ancrage (jamais de valeur devinée).
3. Formulaire : quatre pastilles (mensuel, trimestriel, semestriel,
   annuel) ; le mois d'ancrage est demandé pour tout rythme non
   mensuel ; la note dit le nombre d'échéances par an et la comparaison
   mensuelle. Écran Abonnements : pilule et coût comparable par rythme ;
   « Vos charges du foyer » totalise désormais le coût ANNUEL exact
   (des rythmes différents ne s'additionnent pas tels quels).
4. `four_weeks` (toutes les 4 semaines) n'entre PAS dans ce lot côté
   PWA : 13 échéances par an dont un mois à DEUX échéances — la grille
   mensuelle (une occurrence liée par mois) ne peut pas l'exprimer sans
   identité d'occurrence par date. Le natif est déjà exact (prouvé par
   test : 13/an, un mois à 2). Lot dédié REC2, à livrer AVANT que
   P08-C ne suggère `four_weeks` ; en attendant, aucune conversion
   silencieuse vers mensuel, nulle part.
5. `week` et `custom` : non exposés (aucun besoin de la fixture pour
   `week` ; `custom` = 1 seule identité, suggestion facultative).

### Vérification

Parcours 159 né rouge (trimestriel compté 12 ×, 2160 au lieu de 720 ;
delta mensuel 420 au lieu de 180 ; pastilles absentes ; restauration
muette) ; fixture de parité 8 « cadences-exactes » (juin : 300 + 120
dus, semestriel silencieux, prévu 580) réconciliée web↔natif ; tests
natifs des ancrages (month,3)/(month,6) et de la preuve 13/an en
(week,4) ; contrôle négatif par sabotage du pas.

## ADR-038 — Fondation Présentation : glyphes de catégories et monogramme partagé

Date: 2026-08-20
Status: accepted

### Contexte

IC0 (ADR-037) a réconcilié les 22 `glyphKey` de la fixture avec les
registres réels : 8 étaient mappés, 14 vivaient sur un repli commun
`recurring` — utilisable mais muet. Le programme exige aussi un
monogramme local sûr pour toute saisie libre, identique sur les deux
plateformes.

### Décision

1. Les 14 clés de catégories reçoivent de VRAIS glyphes : 13 tracés
   originaux Budget côté PWA (stroke 1.75, viewBox 24, currentColor)
   et 14 cas `BudgetGlyph` natifs (SF Symbols de repli, même pratique
   que les catégories existantes). La carte
   `fixtures/catalogue-glyph-map.json` passe en mappage 100 % direct —
   le test catalogue casse si un glyphe manque d'un côté.
2. Monogramme déterministe PARTAGÉ (`monogramFor` PWA ↔
   `BudgetMonogram.letters` natif) : mots = suites de lettres/chiffres
   Unicode, première lettre des DEUX premiers mots, en majuscules ; un
   seul mot donne une lettre ; sans lettre → repli glyphe. La MÊME
   fixture `fixtures/monogram-cases.json` prouve les deux
   implémentations (e2e 158-IC1 et `BudgetMonogramTests`).
3. Tuile d'identité DÉCORATIVE (`identityTile` PWA,
   `BudgetIdentityIcon` natif) : texte pur dans le puits mat Budget,
   `aria-hidden`/`accessibilityHidden`, jamais un remplacement du
   libellé, jamais une image, jamais du HTML issu d'une valeur.
4. Aucune persistance, aucun écran modifié : IC1 est une fondation.
   La consommation de `BudgetIcon` par les lignes P05/P08/P12/P13 iOS
   est REPORTÉE aux lots d'écrans correspondants — changer le visuel de
   quatre écrans sans captures propres à chacun contredirait le plus
   petit lot vertical.

### Vérification

Carte passée en direct AVANT les glyphes : test catalogue rouge (28
échecs « absent du registre réel ») puis vert ; e2e 158-IC1 né rouge
(monogrammes « (absent) ») puis vert ; la fixture a corrigé une
attente fausse (« 1Password » → « 1 », un seul mot = une lettre) ;
planche des 13 tracés + tuiles inspectée
(`docs/neon-ultra/budget-prisme/ic1/`).

## ADR-037 — Identités locales : contrat du catalogue, clés et glyphes (IC0)

Date: 2026-08-20
Status: accepted
Note: l'ADR-036 (P0 AVS, rente ≠ capital) arrive par la PR #93 — la
numérotation reste chronologique après fusion des deux brouillons.

### Contexte

Le programme Identités locales (skill compagnon, PR #91) apporte une
fixture éditoriale de 164 identités CH/FR/BE. Avant tout code produit,
il faut figer le contrat de données, une seule autorité éditoriale et la
réconciliation des 22 `glyphKey` avec les registres RÉELS des deux
plateformes — sans repli silencieux divergent.

### Décision

1. **Contrat du catalogue** figé (champs exclusifs) : `key` (kebab-case
   ASCII), `displayName`, `aliases[]`, `markets[]` (GLOBAL/CH/FR/BE),
   `entityKind`, `financialSense`, `category`, `cadenceHints[]`
   (`four_weeks` ≠ `month`, toujours), `currencyHints[]` (devise, jamais
   un montant), `glyphKey`, `markPolicy`, `monogram`, `assetKey`.
   INTERDITS : prix, solde, quantité, date, statut actif, URL/HTML,
   rang de popularité, promesse de connexion.
2. **Une seule autorité éditoriale** : `fixtures/catalogue-identites.json`
   est l'octet-copie de la fixture du skill — la suite `catalogue.test.mjs`
   échoue si elles divergent. Le catalogue n'est PAS encore un bundle
   runtime : aucune copie dans l'app avant IC1/P08-C.
3. **V1 = glyphes et monogrammes seulement** : `markPolicy` ne peut pas
   valoir `approved_asset` (assetKey null partout) tant que BR1 n'a pas
   livré provenance, droits et checksums (LOGO_POLICY).
4. **Réconciliation des glyphes** : `fixtures/catalogue-glyph-map.json`
   est l'unique table `glyphKey → glyphe PWA / glyphe natif`. Règle :
   chaque plateforme rend sa clé directe si elle existe, sinon le repli —
   et un repli est LE MÊME nom canonique des deux côtés (`recurring`),
   jamais un repli différent par plateforme. État au 20.08.2026 :
   8 clés mappées des deux côtés (accounts, family→children,
   home→property, investment, liability→debt, saving→setAside,
   shield→pension, tax→taxPayment/taxes), 14 en repli commun — IC1 les
   remplace par de vrais glyphes de catégorie.
5. **Ordre de résolution d'une identité** (inchangé du skill) : choix
   explicite > clé locale validée > alias confirmé > monogramme
   déterministe > Budget Glyph générique. Seule une clé ASCII
   allowlistée sera un jour persistée (lot ID1) — jamais un nom d'asset,
   une URL ou du HTML.
6. **Garde-fous exécutables** : la suite Node `catalogue.test.mjs`
   (CI, avant les suites navigateur) valide contrat, unicité, textes
   sûrs, politique V1 et l'existence RÉELLE de chaque glyphe résolu dans
   `BUDGET_GLYPHS` (PWA) et `BudgetGlyph` (natif), par extraction des
   sources.

### Vérification

Suite verte observée : « 164 identités conformes au contrat ADR-037 ·
22 glyphKeys réconciliés sur les DEUX plateformes (8 mappés · 14 en
repli commun, à remplacer par IC1) ». Contrôles négatifs : champ
interdit injecté → contrat + garde de synchronisation mordent ; glyphe
inexistant dans la carte → registre mord. Validateur du skill : exit 0,
164 identités (CH 107 · FR 96 · BE 94).
## ADR-036 — P0 AVS : une rente n'est jamais un capital

Date: 2026-08-20
Status: accepted

### Contexte

Alerte préalable du programme Identités locales : sur iOS, une position
de prévoyance `pillar1` (AVS) porte une estimation de RENTE dans
`currentValue` — le commentaire du modèle le disait — et ce montant
était additionné au patrimoine (`NetWorthService.breakdown.pensionTotal`)
et au « Capital de prévoyance »
(`InsurancePensionService.totalPensionCapital`). Sur la PWA, une ligne
de prévoyance saisie librement comme « AVS » avec une rente en « Valeur
actuelle » entrait aussi au patrimoine. De l'argent qui n'existe pas
encore gonflait la fortune.

### Décision

1. Une rente n'entre JAMAIS dans le capital de prévoyance, les
   contributions, les projections, le patrimoine net ni les snapshots.
2. iOS : le 1er pilier est structurellement une rente
   (`InsurancePensionService.isAnnuity`) — exclu de tous les agrégats,
   affiché dans sa propre section « Rentes estimées — hors patrimoine »,
   « à confirmer » (par mois ou par an, précisé dans la note). Aucun
   champ nouveau, aucun schéma, aucune migration : pas de risque de
   données dans un P0.
3. PWA : les positions gagnent un drapeau optionnel `rente` (case
   « C'est une rente, pas un capital » dans la feuille) ; une position
   marquée sort de `pensionPositionsTotal()` (donc du patrimoine et de
   « Déjà mis de côté »), s'affiche « Rente estimée — hors patrimoine »
   et ne peut pas être liée à un compte.
4. Données anciennes ambiguës : JAMAIS réécrites ni recomptées en
   douce. Une ligne PWA non marquée dont le nom évoque l'AVS/une rente
   reste comptée telle quelle et porte « À confirmer : rente ou
   capital ? » — c'est la personne qui tranche dans la feuille. Sur
   iOS, `pillar1` n'est pas ambigu : le modèle documentait déjà la
   rente ; l'exclusion corrige l'agrégation, la valeur stockée reste
   intacte.
5. 2e pilier, 3a et 3b restent des capitaux — calculs inchangés.
6. Sauvegardes : aucune forme ne change côté iOS ; côté PWA le drapeau
   est additif (`rente !== true` = comportement historique), les
   anciennes sauvegardes se restaurent à l'identique, une valeur
   hostile dans le drapeau est inerte (comparaison stricte, jamais de
   markup).

### Vérification

Parcours e2e 158 né rouge (rente marquée comptée au patrimoine, aucune
case dans la feuille, aucun « À confirmer ») ; tests natifs
`testAnnuityEstimateNeverCountsAsCapital` et
`testPensionAnnuityIsExcludedFromNetWorth` ; démo native sans pilier 1
(tour inchangé) ; captures de la Prévoyance PWA inspectées.

## ADR-035 — Impôts 100 % manuels : le concept de taux disparaît, l'app additionne

Date: 2026-08-20
Status: accepted — remplace la partie « opt-in » d'ADR-034

### Contexte

Le lendemain d'ADR-034, la capture du propriétaire montrait toujours
« − CHF 600.00 d'impôts à mettre de côté » : son appareil portait encore
le taux 30 % stocké avant le changement de défaut (ADR-034 ne réécrivait
pas les données). Son ordre est devenu plus net : « Il faut que tu me
fasses une page impôts où c'est moi qui mets combien je verse, comme une
facture ponctuelle. Ne mets pas tout à jour automatiquement. Toutes les
données, c'est moi qui dois les rentrer. »

### Décision

1. Le CONCEPT de taux de provision disparaît du produit : plus aucune
   formule ne lit `S.taxRate` (web) ni `taxProvisionRate`/`provisionRate`
   (natif). Un taux hérité stocké devient lettre morte — c'est ce qui
   éteint le « − 600 » du propriétaire SANS réécrire ses données.
2. Le moteur perd tous ses champs fiscaux dérivés (`taxMonthlyEffort`,
   `taxSetAsideMonth`, `taxGapForecast`, `taxGap`, `taxRecommended` web ;
   `taxMonthlyEffort`, `taxReserveGap`, `TaxProvisionSummary` natif).
   Projection = argent présent + attendu − sorties saisies.
3. La page Impôts ADDITIONNE ce que l'utilisateur a noté : payé (ses
   `taxPayment`), mis de côté (envois « Impôts » + report saisi),
   prochains acomptes (factures « Impôts », bouton « Ajouter un
   acompte »). Natif : le montant annuel reste une SAISIE facultative
   (`estimatedAnnualTaxOverride`) — jamais une estimation.
4. La feuille web ne règle plus que le report ; la feuille de taux
   native disparaît ; l'assistant et la priorité du mois ne prescrivent
   plus de réserve fiscale.
5. Les champs stockés (`taxRate`, `taxReserve`, `taxProvisionRate`,
   `provisionRate`) RESTENT stockés et tolérés à la restauration —
   aucune donnée réécrite, aucune migration risquée ; ils ne sont plus
   jamais lus par un calcul.
6. Un acompte pèse sur le mois par sa facture ou son mouvement prévu,
   comme n'importe quelle sortie saisie — c'est déjà le canal P11
   (payer une facture « Impôts » crée un `taxPayment`).

### Vérification

Parcours 157 réécrit sur le scénario exact de la capture (taux hérité
0.3 + salaire attendu 2'000), né rouge : « − CHF 900.00 d'impôts à
mettre de côté » apparaissait encore. Tests 53/56/82/107/136/153/154
réécrits sur la nouvelle vérité (page manuelle, moteur sans champs
fiscaux, feuille sans taux). Fixture de parité renommée
`impots-manuels-taux-herite` : le state garde `taxRate: 0.3` EXPRÈS et
la projection ne le voit plus (107'160 → 108'300). Miroir natif complet
(TaxService manuel, snapshot sans terme fiscal, TaxesView additionneuse,
8 fichiers de tests réécrits). FINANCIAL_ENGINE_V2.md amendé.

## ADR-034 — La provision d'impôts est OPT-IN : aucun impôt calculé automatiquement

Date: 2026-08-19
Status: accepted

### Contexte

Ordre du propriétaire pendant sa QA de la v1.0.0 : « ne calcule pas les
impôts automatiquement — c'est moi qui les mets comme dépenses. » Depuis
A18, l'onboarding suisse posait silencieusement un taux de 30 % ; le
Moteur V2 en déduisait un effort mensuel de la projection (FE2-0) —
mathématiquement juste, mais de l'argent « sortait » sans qu'aucune
facture n'existe (incident de lisibilité FE2-10).

### Décision

1. AUCUN taux implicite nulle part : `COUNTRIES.CH.taxRate` 0,
   gabarit d'état vierge 0, assainisseur 0, fallback de `snapshot()` 0,
   restauration 0, `Household`/`TaxProfile`/`OnboardingViewModel`
   natifs à zéro, fallbacks de `TaxService`/`MonthlySnapshotService`/
   `TaxesView` à zéro.
2. La provision reste disponible en OPT-IN : l'utilisateur choisit un
   taux (0–60 %, borne A17) dans Gérer → Impôts ; toutes les formules
   FE2 (effort mensuel, écart anticipé) fonctionnent alors comme avant.
3. Les impôts payés se saisissent comme des mouvements (type
   « impôts » ou dépense) — la vérité vient des gestes de l'utilisateur.
4. La DÉMO garde un taux de 30 % : elle montre la fonction activée.
5. Les données existantes ne sont PAS réécrites (un taux déjà en place
   reste en place — le propriétaire passe le sien à 0 % d'un geste).

### Vérification

Parcours e2e 56 réécrit (né rouge : taux 0.3 appliqué, effort 1500
calculé sans consentement) ; tests natifs des défauts mis à zéro
(`OnboardingViewModelTests`, `PersistenceFoundationTests`) ; les tests
de comportement fiscal passent tous un taux EXPLICITE
(`UnifiedTaxReserveTests`, `MonthlySnapshotServiceTests`,
`TaxServiceTests`) — le moteur n'a pas changé, seul le défaut.

## ADR-033 — Budget 1.0 : les créances (« ce qu'on me doit ») sont exclues

Date: 2026-08-18
Status: accepted

### Contexte

Question propriétaire pour la release 1.0 : Budget possède-t-il un vrai
modèle de créances (argent que d'autres doivent au ménage), distinct des
dettes ? Audit du dépôt (natif + web) : AUCUN modèle, écran, type ou
migration « créance » n'existe — la fonctionnalité n'est pas inachevée,
elle est absente. Les seuls voisins sont le type de mouvement `refund`
(« Remboursement reçu » — un flux ponctuel, sans suivi d'encours) et les
actifs libres du Patrimoine.

### Décision

1. Les créances sont EXCLUES de Budget 1.0 : ajouter en fin de cycle un
   modèle financier avec migrations et parité web↔natif à prouver serait
   exactement la « fonctionnalité à moitié » que le propriétaire refuse.
2. Contournement honnête documenté : un prêt accordé se note comme actif
   libre du Patrimoine (« Prêt à … »), mis à jour à la main ; chaque
   remboursement reçu se saisit comme mouvement « Remboursement reçu ».
3. Un vrai module de créances (encours, échéances, lien avec les
   remboursements) est un candidat FE3, à spécifier par le propriétaire.

### Vérification

`grep -ri "créance|receivable|on me doit"` sur Budget/, BudgetTests/,
webapp/ : zéro occurrence applicative. `BUDGET_1_0_READINESS.md` § 3
porte la décision ; aucun modèle ni migration touché.

## ADR-032 — Budget Prisme : une matière et une iconographie propres

Date: 2026-08-14
Status: accepted

### Contexte

Le propriétaire fournit six nouvelles références de dashboards financiers
sombres et demande une identité plus propre, moins générique et immédiatement
reconnaissable. L'audit du produit courant explique le malaise : Neon Ultra
habille le parcours mensuel, tandis que les primitives Obsidian restent
visibles sur Historique, Comptes, Gérer et plusieurs modules. La PWA mélange
en plus SVG filaires, caractères Unicode et emojis ; une carte pilote conserve
encore un reflet diagonal hérité. Sur iOS, environ soixante `GlassCard`
coexistent avec dix cartes Neon Ultra et les icônes sont choisies localement
dans plus de cent sites.

Le problème n'est donc pas l'absence d'une nouvelle couleur. C'est l'absence
d'une seule autorité de matière, de géométrie et d'iconographie.

### Décision

1. La signature publique s'appelle **Budget Prisme** : graphite mat, montants
   blancs, une arête cyan-violet-magenta rare et une seule surface élevée par
   viewport. Elle affine ADR-024 sans créer une troisième famille de code :
   `NeonUltra*` et `--nu-*` restent les autorités techniques.
2. La palette canonique d'ADR-024 est conservée. Le dégradé reste réservé au
   CTA principal, à une sélection ou à l'arête prisme. Aucun montant ne reçoit
   de gradient ou de glow ; vert, corail et ambre restent strictement
   financiers.
3. Les cartes répétées deviennent entièrement mates. Elles ne portent plus de
   reflet diagonal, de blur lourd ou d'ombre colorée. Le héros seul peut
   recevoir une ombre noire diffuse et une arête prisme fine.
4. La géométrie unique reste `26 / 18 / 14` pour héros, carte et contrôle. La
   typographie financière emploie le dessin système standard et des chiffres
   tabulaires, sans variante arrondie ludique.
5. **Budget Glyphs** devient l'autorité iconographique : grille 24, trait 1,8,
   extrémités arrondies, monochrome, noms sémantiques partagés PWA/iOS. Les
   cinq onglets, les mouvements et les quatre intentions d'ajout utilisent le
   registre ; aucun emoji ne sert d'icône fonctionnelle par défaut.
6. Les emojis déjà persistés restent acceptés. La vue les traduit vers un
   glyphe sémantique ou un repli neutre ; aucune donnée ni sauvegarde n'est
   modifiée pour changer une apparence.
7. Les cinq destinations et leur ordre restent
   `Mois · Historique · Budget · Comptes · Gérer`. L'état actif possède une
   forme et un attribut accessible en plus de la couleur. Aucun bouton global
   central ou flottant n'est ajouté.
8. Le premier lot converge les primitives héritées et le parcours
   `Mois · Budget · Ajouter` ; il n'altère aucun modèle, service, calcul,
   validation, format de sauvegarde, clé de persistance, import ou route.
9. Les six références restent une inspiration de principes. Aucun écran,
   texte, avatar, marque, illustration ou actif tiers n'est copié.

Le contrat complet est versionné dans
`docs/neon-ultra/budget-prisme/STYLE.md` et devient la lecture détaillée de la
constitution ADR-024 pour les lots visuels suivants.

### Conséquences

- Les écrans hérités gagnent la même matière sans réécriture massive ni
  rupture d'API de leurs composants.
- Le parcours mensuel devient le pilote visuel de l'identité, avec des glyphes
  cohérents sur les deux plateformes.
- Une barre d'onglets native iOS totalement personnalisée reste hors lot : le
  `TabView` est conservé jusqu'à une passe dédiée de VoiceOver, safe area et
  restauration d'onglet.
- Les futures catégories d'icônes doivent étendre le registre, jamais ajouter
  un emoji ou une bibliothèque locale dans un écran.

### Vérification attendue

PWA : registre SVG `currentColor`, navigation avec `aria-current`, aucun emoji
fonctionnel sur Mois/Budget/Ajouter, cartes pilotes sans `::before`/`::after`,
un seul accent spectral, 320/390 px, texte agrandi, mouvement/transparence
réduits et trois suites web vertes. iOS : registre exhaustif pour onglets,
intentions et types, puits d'icône, matière héritée convergente, Dynamic Type,
Reduce Motion/Transparency, builds Debug/Release et tests. Les invariants
financiers et de persistance restent inchangés.

## ADR-031 — Un vrai bilan du mois : à faire et déjà fait

Date: 2026-08-14
Status: accepted

### Contexte

Après la simplification ADR-030, le montant principal et les trois repères
sont lisibles, mais une opération disparaît de l'accueil dès qu'elle est
confirmée. La personne voit donc ce qu'elle doit encore faire, jamais la
preuve que son salaire a été reçu, que son loyer a été payé ou que son argent
a été mis de côté. Le mot `Transactions mensuelles` est aussi faux puisque le
même écran accepte la semaine, le trimestre, le semestre et l'année.

Un benchmark de sources officielles — Finary (entrées/sorties et virements
neutres), Bankin' (prévision de fin de mois), YNAB (une priorité), Monarch
(fixe/flexible/non mensuel), Copilot (reste mensuel et éléments à vérifier),
Wallet (paiements planifiés) et Spendee (repère quotidien) — converge sur un
principe : un montant principal, trois résultats courts, puis ce qui arrive
ensuite. Budget en fait une synthèse originale ; aucun écran, texte, actif,
couleur ou comportement propriétaire n'est reproduit.

Sources officielles consultées : [Finary Budget](https://finary.com/fr/budget),
[Bankin' — créer son budget](https://support.bankin.com/hc/fr/articles/20540527131665-Cr%C3%A9er-et-personnaliser-son-budget-avec-Bankin),
[YNAB](https://www.ynab.com/features),
[Monarch](https://www.monarch.com/features/budgeting),
[Copilot](https://help.copilot.money/en/articles/6045480-dashboard-tab-overview),
[Wallet](https://budgetbakers.com/en/products/wallet/features/planned-payments/) et
[Spendee](https://help.spendee.com/article/114-what-is-spendee).

### Décision

1. Le héros courant s'appelle `Reste pour le mois`; un mois futur affiche
   `Estimation du mois`, explicitement calculée depuis le solde actuel, et un
   mois passé `Résultat du mois`. Les formules existantes restent strictement
   inchangées.
2. Les trois repères restent `Reçu · Dépensé · Mis de côté`. `Dépensé` décrit
   le coût de la vie ; il n'est pas remplacé par `Payé`, qui est un état de
   ligne et non un total financier.
3. La carte `À faire ce mois` devient `Bilan du mois`. Elle annonce
   `N à faire · M faits`, montre au maximum trois éléments `À faire`, puis au
   maximum trois éléments `Fait ce mois`. Une ligne confirmée change de
   section au lieu de disparaître. Pour un mois futur, elle dit à la place
   `N prévus` et `Prévu ce mois` : aucune action future n'est présentée comme
   une tâche immédiate.
4. Un élément n'est `fait` que s'il existe déjà comme mouvement régulier ou
   facture ponctuelle comptabilisé (`posted`) dans le mois. La PWA conserve
   aussi l'ancien marqueur explicite `payée` des sauvegardes historiques, sans
   lui inventer de date. Un mouvement `planned` reste prévu ; l'affichage ne
   crée, ne déduit et ne modifie rien. `Fait ce mois` n'invente pas non plus
   le jour exact du geste : les moteurs historiques ne portent pas tous cette
   information avec le même sens. Dès qu'un mouvement `planned` ou `posted`
   existe, son titre, son montant et son type gagnent sur une définition
   régulière modifiée ensuite : le bouton confirme exactement ce qui est
   affiché.
   Le rituel historique `Mois bouclé` suit la même règle : un mouvement
   seulement prévu ne ferme jamais le mois.
5. Le vocabulaire d'état est unique sur les deux plateformes :

   | Nature | Avant | Après |
   |---|---|---|
   | Revenu / salaire | `À recevoir` | `Reçu` |
   | Facture / dépense | `À payer` | `Payé` |
   | Épargne | `À mettre de côté` | `Mis de côté` |
   | Placement | `À investir` | `Investi` |
   | Virement interne | `À transférer` | `Transféré` |

6. L'intention d'ajout devient `Ça revient régulièrement`. Le menu, l'écran
   et la feuille utilisent le même nom humain : `Ce qui revient`. Les mots
   `chaque mois`, `chaque année` et leurs variantes ne servent plus qu'à
   décrire le vrai rythme choisi.
7. Une mise de côté régulière n'est jamais rouge, négative, `À payer` ou
   `Payé` dans l'interface. Elle reste visuellement et textuellement distincte
   d'une dépense, conformément à l'invariant ADR-029.
8. Ce lot remplace uniquement le vocabulaire et la présentation d'ADR-030
   §2, §4 et §7. Les cinq onglets, les modèles, SwiftData, `localStorage`, les
   formats de sauvegarde et tous les calculs financiers restent inchangés.

### Conséquences

- En moins de dix secondes, le même écran répond à : combien reste-t-il,
  combien ai-je reçu, dépensé et mis de côté, que reste-t-il à faire, et
  qu'ai-je déjà fait ?
- Le dashboard reste borné : aucun constructeur de widgets, graphique de
  patrimoine, objectif ou rapport expert n'est ajouté au premier niveau.
- Les analyses par catégorie, l'historique complet et le patrimoine gardent
  leurs destinations dédiées.

### Vérification attendue

PWA : passage réel `À faire → Fait ce mois` pour salaire, facture et réserve,
trois lignes maximum par section, état écrit sans dépendre de la couleur,
réserve jamais négative, cohérence `Ce qui revient`, 320/390 px et suites
navigateur. iOS : sélection pure des mouvements réguliers `posted`, matrice
des verbes, résumé singulier/pluriel, preuve UI d'au moins une ligne faite,
Dynamic Type, tests Debug/Release. La CI GitHub macOS et Chromium fait foi
quand ces outils ne sont pas disponibles localement.

## ADR-030 — « Mon mois en 10 secondes » et ajout par intention

Date: 2026-08-14
Status: accepted

### Contexte

L'audit complet et l'essai du propriétaire aboutissent au même constat :
l'application sait suivre beaucoup de choses, mais l'accueil oblige encore à
interpréter un carrousel de cinq montants, une carte de rythme, quatre cartes
mensuelles, deux listes et sept tuiles. Le bouton principal demande ensuite de
comprendre jusqu'à sept types comptables. Cette densité rend la tâche de base —
comprendre son mois puis enregistrer un geste — trop difficile, notamment pour
une personne jeune ou peu familière avec la finance.

### Décision

1. Les cinq destinations `Mois · Historique · Budget · Comptes · Gérer`
   restent stables. La simplification porte sur le premier niveau, pas sur une
   nouvelle navigation.
2. `Mois` montre, dans cet ordre : le mois, un seul héros « Disponible jusqu'à
   la fin du mois », une phrase de rythme, trois repères `Reçu · Dépensé · Mis
   de côté`, un CTA `Ajouter`, puis une liste unique `À faire ce mois`.
3. Le carrousel, la carte de rythme autonome et les tuiles d'analyse quittent
   l'accueil. Leurs informations restent disponibles dans les destinations
   dédiées. Cette décision remplace la présentation en tuiles d'ADR-028 §6 ;
   elle ne retire ni écran ni donnée.
4. `Ajouter` pose une seule question et propose exactement quatre intentions :
   `J'ai dépensé · J'ai reçu · J'ai mis de côté · Ça revient chaque mois`.
   Le type comptable est prérempli. Les opérations rares restent accessibles
   sous `Changer le type` / les parcours avancés.
5. Le formulaire courant commence par le montant. Date, compte source et
   texte sont préremplis ou rangés sous `Plus d'options`. La destination d'une
   épargne ou d'un investissement reste visible et obligatoire. L'intention
   `J'ai mis de côté` propose directement `Épargne · Pilier 3a · Impôts` et
   prépare le bon type ainsi que la poche d'arrivée.
6. Une ligne qui revient se décrit par quatre mots humains : `Facture ·
   Abonnement · Revenu · Mise de côté`. Épargne et placement restent deux
   destinations financières distinctes après ce choix. Sur iOS, sa prochaine
   date reste au premier niveau car elle détermine réellement le calendrier.
7. La liste mensuelle emploie le verbe réel : `Reçu`, `Payée`, `Mis de côté`,
   `Versé` ou `Effectué`. Sur iOS, une échéance future reste `Prévue` et ne
   peut plus être déclarée terminée avant sa date.
8. La PWA propose réellement `Épargne · Pilier 3a · Impôts` quand la personne
   choisit une mise de côté mensuelle. Ces trois choix passent par les modèles
   existants ; aucun format de sauvegarde ni calcul financier ne change.

### Conséquences

- L'accueil répond à une seule question principale et ne comporte qu'un point
  focal lumineux.
- Les revenus, factures, abonnements et réserves partagent une liste, sans être
  additionnés ni appelés tous « factures ».
- Les cinq onglets, SwiftData, `localStorage`, les sauvegardes et les services
  financiers restent inchangés.
- Les correctifs de vérité fiscale, CSV, restauration et dette identifiés par
  l'audit restent des lots séparés : cette ADR ne masque pas leur priorité.

### Vérification attendue

PWA : syntaxe des scripts, trois suites navigateur, 320/390 px, quatre
intentions, dialogue nommé/piège de focus, absence de carrousel/tuiles et
matrice réelle Épargne/3a/Impôts. iOS : tests des quatre intentions, des quatre
natures récurrentes, des verbes mensuels, de l'interdiction de confirmer une
date future et de la date du mois consulté ; tours UI du CTA jusqu'au
formulaire guidé. La CI GitHub macOS et Chromium fait foi lorsque les binaires
locaux ne sont pas disponibles.

## ADR-029 — Mettre de côté exige une poche d'arrivée, sur les deux plateformes

Date: 2026-08-10
Status: accepted

### Contexte

Le propriétaire demande que « Mettre de côté » soit une nature de **ligne
mensuelle** à part entière, au même rang qu'une facture : « pour moi, mettre
de côté, ça part de mes factures mensuelles… sans le virement : ce qui sort de
mon compte chaque mois ».

En allant remonter ce choix dans la feuille, un défaut d'argent est mesuré.
Sonde reproductible, données fictives, PWA :

```
patrimoine avant   3'400.00
patrimoine après   2'900.00
solde d'épargne        0.00
mouvement créé     type saving, dest: null
```

Une ligne mensuelle de nature « réserve » créait un mouvement
`saving` / `investment` **sans compte d'arrivée** : l'argent quittait le compte
source et n'atterrissait nulle part. Le patrimoine baissait du montant
réservé, **chaque mois**. Défaut introduit par le lot C1 (07.08.2026).

L'audit du natif montre une variante du même problème par une autre porte :
`RecurringScheduleService.makeTransaction` propageait bien la destination,
mais `TransactionValidationService` la déclarait **facultative** pour
`.saving` et `.investment` (commentaire « Destination optional »). Un
utilisateur pouvait donc créer nativement la même ligne qui évapore l'argent.

### Décision

Une mise de côté et un investissement ont **toujours** une poche d'arrivée.

1. **Web** : la nature devient un choix unique et visible dans la feuille
   d'une ligne mensuelle — `Facture · Abonnement · Mettre de côté · Revenu`,
   sans virement (une ligne mensuelle est ce qui *sort* du compte). La
   destination est un champ obligatoire, avec un défaut déduit de la
   catégorie (3e pilier → prévoyance, sinon épargne), jamais le compte de
   départ. `materializeRecurring` pose la destination et **refuse** de créer
   le mouvement quand aucune poche n'existe.
2. **Natif** : `TransactionValidationService` exige la destination pour
   `.saving` et `.investment` (nouvelle erreur
   `missingContributionDestination`). `.debtPayment` la garde facultative :
   elle désigne la dette remboursée, et rembourser une dette non suivie par
   l'app reste un cas réel. Les libellés des sélecteurs cessent d'annoncer
   « facultatif » pour ces deux types.
3. **Réparation bornée** des mouvements déjà créés : un mouvement
   `saving` / `investment` sans destination **et lié à une ligne mensuelle**
   retrouve la poche de sa ligne, valeur déduite jamais inventée. Un
   mouvement saisi à la main n'est jamais touché ; si aucune poche ne se
   déduit, rien n'est modifié.

### Conséquences

- L'invariant « une mise de côté est neutre pour le patrimoine » redevient
  vrai, et il est tenu par des tests des deux côtés.
- Un utilisateur sans second compte ne peut plus enregistrer une mise de
  côté : il reçoit un refus qui dit quoi faire, au lieu d'un patrimoine faux.
- Le natif perd une souplesse assumée (« réserve non suivie »). C'est
  volontaire : l'écran promet « il reste à vous », il doit tenir sa promesse.
  Le remboursement de dette conserve l'échappatoire.

### Preuves

Web : parcours e2e 114 et 115, contrôle négatif (4 assertions tombent, dont
`patrimoine 44963.95 → 44463.95`). Natif : `TransactionValidationTests`
(test inversé et renommé, avec la raison écrite) et
`RecurringScheduleServiceTests` (destination portée à la matérialisation,
refus à la saisie).

## ADR-028 — Rythme des charges régulières, page Année et tuiles d'accès

Date: 2026-07-29
Status: accepted

### Context

Le propriétaire tient son suivi de référence dans un tableur : une table par
année avec les douze mois et leur état, une table d'abonnements avec leur
échéance, et un tableau de bord fait de blocs. Trois écarts empêchaient l'app
de remplacer ce tableur.

1. Une charge régulière était forcément **mensuelle**. Un abonnement annuel
   devait être saisi soit comme mensuel — compté douze fois, donc faux — soit
   comme facture ponctuelle, donc jamais renouvelé. Aucune notion de
   résiliation non plus.
2. Aucune vue des douze mois : il fallait feuilleter l'écran Mois un mois à
   la fois avec les flèches.
3. Le tableur additionne des prix annuels et des prix mensuels dans une même
   colonne. Le total affiché ne veut rien dire : sur le jeu réel du
   propriétaire il annonce 995.75 CHF alors que le coût vrai est 3'106.65 CHF
   par an. L'app doit corriger cette erreur, pas la reproduire.

### Decision

1. Deux champs **additifs** sur les charges régulières : `every`
   (`"month"` par défaut, `"year"`), `dueM` (mois d'échéance, utile
   uniquement en annuel) et `endedOn` (`null` ou `{ y, m }` de résiliation).
   Absents, ils valent mensuel et actif : le sens des données déjà
   enregistrées est strictement préservé.
2. Une charge **annuelle** est engagée **uniquement sur son mois
   d'échéance**. Elle n'est jamais lissée sur douze mois : l'app n'affiche
   pas un prélèvement qui n'existe pas. Cette règle vaut partout où une
   récurrence pèse — argent disponible, obligations du mois, rituel de
   bouclage, revenus attendus.
3. Une charge **résiliée** quitte les prévisions dès le mois indiqué mais
   reste visible dans l'écran Abonnements. Résilier ne touche aucun
   mouvement : l'historique comptabilisé est intact.
4. Écran **Abonnements** : deux totaux jamais additionnés entre eux — coût
   réel annuel, et moyenne mensuelle nommée comme telle. « Factures
   mensuelles » ne montre que le mensuel, conforme à son titre.
5. Page **Année** : les douze mois, chacun avec son état écrit et ses
   montants entré/sorti, ouvrable d'un tap. Vue pure, aucune formule
   nouvelle.
6. **Tuiles d'accès** sur l'accueil, sous les factures : sept raccourcis
   portant chacun un chiffre réel. Ce sont des liens de navigation, pas des
   analyses — aucune jauge, aucune courbe, aucun dégradé. Le premier niveau
   de l'accueil reste celui d'ADR-026 (mois, disponible, quatre montants,
   factures) et les analyses restent dans leurs destinations dédiées.
7. Les écrans **nés** dans cette passe (Année, Abonnements) naissent dans
   l'identité Neon Ultra plutôt que dans l'ancienne peau : la portée pilote
   d'ADR-024 les accueille.

### Consequences

L'app remplace le tableur sans en hériter l'erreur de total. Un abonnement
annuel devient modélisable pour la première fois. Aucune formule financière,
clé de stockage, structure de données ni destination de navigation existante
n'est modifiée.

### Verification

Un annuel de 1200 dû en mars pèse 1300 en mars avec un mensuel de 100, 100 en
avril, et **2400 sur la somme des douze mois** — jamais 15'600. Rituel de
bouclage et obligations du mois vérifiés sur les deux mois. Deux totaux
d'abonnements comparés au recalcul depuis l'état. Résiliation chiffrée. Trois
refus de restauration (rythme inconnu, mois d'échéance hors 1-12, date de
résiliation illisible) avec données intactes. Sept tuiles, destinations
réellement ouvertes, cibles 44 px, point focal unique, aucune jauge.
91 parcours e2e, 5 parités, design system vert, zéro erreur console.

## ADR-027 — Récurrents en retard engagés et couverture stricte par `recurringId`

Date: 2026-07-29
Status: accepted

### Context

L'audit du lot d'accueil simplifié a révélé deux écarts financiers dans la
PWA. `snapshot()` ne conservait dans les prévisions que les récurrents dont le
jour était encore à venir (`day > aujourd'hui`) : une charge échue mais non
payée disparaissait donc du montant engagé et pouvait surestimer le
`Disponible`. En parallèle, `recurringOccurrence()` acceptait comme couverture
un mouvement sans lien ayant seulement le même intitulé et le même compte. Une
opération indépendante pouvait ainsi masquer à tort l'échéance récurrente.

### Decision

1. Toute occurrence récurrente applicable au mois et non couverte reste
   engagée, que son jour soit futur, présent ou déjà passé. Une échéance en
   retard ne disparaît jamais des prévisions avant sa matérialisation.
2. Une occurrence est couverte uniquement par un mouvement du même mois dont
   `recurringId` est strictement égal à l'identifiant de sa définition. Le
   rapprochement implicite par intitulé, montant ou compte n'est pas une preuve
   de couverture.
3. L'identité financière d'une occurrence mensuelle est
   `recurringId + année + mois`. Une action répétée, un double clic, un
   rechargement ou un nouveau rendu ne peut créer qu'un mouvement lié pour
   cette identité.
4. La matérialisation conserve le compte et la vraie date d'échéance. Une date
   future produit un mouvement `planned`; une date arrivée ou passée produit
   un mouvement `posted`, conformément à la politique de date d'ADR-025.
5. Le passage de prévision à mouvement est une substitution, jamais une
   addition : avant matérialisation la somme vit dans `recurringCharges` ou
   `recurringIncome`; après matérialisation elle vit soit dans `plannedOut`,
   soit dans le solde et les agrégats comptabilisés.
6. Les factures ponctuelles de `S.bills` restent distinctes des définitions
   récurrentes. Deux objets ne sont jamais fusionnés automatiquement sur leur
   intitulé ou leur montant.

### Consequences

- Une charge mensuelle impayée continue de réduire le disponible et apparaît
  explicitement en retard.
- Un mouvement manuel portant le même nom ne solde plus silencieusement une
  occurrence.
- Le widget mensuel de l'accueil peut agréger les obligations sans double
  comptage, tandis qu'ADR-026 reste limitée à la navigation et à la
  présentation.
- Les sauvegardes et identifiants existants restent lisibles ; aucun
  rapprochement historique ambigu n'est inventé.

### Verification

Tests dédiés : récurrent passé non payé présent exactement une fois dans le
snapshot ; mouvement homonyme non lié sans effet ; lien du mois précédent sans
effet sur le mois courant ; double matérialisation créant un seul mouvement ;
compte, montant, date et statut conservés ; `Disponible` identique avant/après
la substitution prévision→planifié/comptabilisé ; promotion d'une échéance
future une seule fois.

## ADR-026 — Navigation simple et accueil synthétique sur PWA et iPhone

Date: 2026-07-29
Status: accepted

### Context

Le propriétaire confirme que l'accueil doit cesser d'être un tableau de bord
technique : trop de boutons à gauche, à droite et au centre, trop de sections,
et les factures qui reviennent chaque mois ne sont pas assez évidentes. La
version iPhone a déjà adopté les libellés simples `Mois · Historique · Budget ·
Comptes · Gérer`, tandis que la PWA conserve encore quatre onglets, un bouton
central et les mouvements cachés dans `Plus`. Cette divergence contredit le
retour produit explicite et complique le lien de test public.

### Decision

1. Les deux plateformes convergent vers cinq destinations stables :
   `Mois · Historique · Budget · Comptes · Gérer`.
2. Le bouton global central ou flottant est supprimé. L'accueil conserve une
   seule action principale « Ajouter un mouvement » ; les autres créations
   vivent dans l'écran qui les concerne.
3. Le premier niveau de l'accueil montre uniquement le mois, le montant
   `Disponible`, les quatre montants `Entré · Dépensé · À payer · Mis de
   côté`, puis les factures mensuelles. Les analyses, courbes, objectifs,
   patrimoine, réglages et imports restent dans leurs destinations dédiées.
4. L'accueil regroupe les factures mensuelles dans un widget unique. Leur
   vérité financière et leur déduplication sont définies séparément par
   ADR-027 ; cette ADR ne les recalcule pas.
5. Cette décision change uniquement l'architecture de navigation et la
   présentation. Les formules, modèles, clés de stockage, sauvegardes,
   imports, devises et règles de persistance restent inchangés.

### Consequences

La PWA de test et l'app iPhone présentent la même logique. L'accueil répond en
quelques secondes aux questions essentielles, tandis que les fonctions
avancées restent disponibles sans concurrencer les montants du mois.

### Verification

Tests de destinations, absence du bouton global, ordre du premier viewport,
widget mensuel unique, 320 px, texte agrandi, cibles 44 px, zéro erreur
console et suites de parité. Les assertions financières des récurrents relèvent
d'ADR-027.

## ADR-025 — Correctif de fiabilité : dates, fiscalité, historique et restaurations

Date: 2026-07-29
Status: accepted

### Context

Un audit du code fusionné a invalidé plusieurs conclusions historiques :
les dates d'un mois ou d'une année future pouvaient être comptabilisées
immédiatement dans la PWA, le tableau mensuel comparait une recommandation
fiscale mensuelle à une réserve annuelle, les remboursements amélioraient
deux fois le bilan annuel, et une sauvegarde PWA insuffisamment validée
pouvait remplacer un état sain. La devise courante d'un compte pouvait aussi
réinterpréter son historique web, tandis que certaines erreurs SwiftData
restaient en attente après un échec de sauvegarde.

### Decision

1. Une politique de date unique compare les jours calendaires : toute date
   strictement future est `.planned`; elle est utilisée par la saisie, les
   imports et les échéances. Au premier chargement/rendu web et au
   lancement/retour au premier plan natif, les mouvements planifiés arrivés
   à échéance deviennent `.posted` une seule fois.
2. Une occurrence récurrente conserve sa date d'échéance et ne peut être
   matérialisée qu'une fois. Côté web, factures et récurrents portent
   explicitement leur compte.
3. Un remboursement réduit le coût de la vie, sans devenir également un
   revenu annuel.
4. `TaxService.report` est la seule vérité native annuelle. Le tableau de
   bord et l'écran Impôts exposent le même manque :
   `max(0, estimation − payé + arriérés − réserve)`. Cette décision remplace
   la formule mensuelle d'ADR-018.
5. La PWA estampille chaque mouvement avec sa devise source et son taux vers
   la devise de référence. Un taux absent rend le montant non convertible et
   visible comme tel ; aucun taux 1:1 n'est inventé. Les devises d'un compte
   et du profil sont verrouillées dès qu'un historique existe.
6. Une restauration est intégralement validée avant toute purge ou écriture.
   La PWA valide aussi les collections secondaires, l'historique d'import et
   les identifiants ; son compteur ignore sans ambiguïté les anciens IDs
   textuels, et elle restaure l'ancien blob si l'écriture échoue. Le natif
   refuse enums inconnus, UUID orphelins, identifiants dupliqués et montants
   illisibles avant de toucher au store.
7. Toute mutation SwiftData utilisateur utilise `saveOrRollback`; les deux
   sauvegardes directes restantes appartiennent aux transactions atomiques
   de restauration/suppression totale et possèdent leur rollback explicite.

### Consequences

- Les mouvements futurs ne réduisent plus le solde réel avant leur date.
- L'accueil ne peut plus annoncer une réserve fiscale couverte lorsque le
  rapport annuel expose encore un manque.
- Modifier un taux actuel ne réécrit plus un mouvement historique web.
- Une sauvegarde mal formée ou une erreur de persistance laisse les données
  précédentes intactes.
- NU3 reste gelé jusqu'à CI complète et publication vérifiée de ce correctif.

### Verification

Tests web dédiés de restauration, dates, impôts, remboursements, devises,
comptes et doublons ; tests Swift de politique de date, import CSV,
récurrences, fiscalité multi-mois, bilan annuel, validation de sauvegarde et
rollback. La CI macOS reste l'autorité pour le build et les tests SwiftData.

## ADR-024 — Direction visuelle « Budget Neon Ultra » (remplace les clauses visuelles Obsidian)

Date: 2026-07-27
Status: accepted

### Context

Autorisation explicite du propriétaire (27.07.2026) : « Je remplace
officiellement la direction visuelle "accent indigo unique" par la
direction "Budget Neon Ultra" : noir profond, magenta, violet et
cyan. » Les règles alors en vigueur (ADR-020 « identité sombre unique
et skill canonique », ADR-022 « fondations Obsidian, indigo profond
AA », CLAUDE.md « une seule teinte de marque Indigo Aurora #7367FF »,
constitution Obsidian) interdisaient magenta/cyan et les néons.

### Decision

1. La direction canonique devient « Budget Neon Ultra » : canvas
   `#05060A`, navigation `#0B0D13`, surfaces `#11141C`/`#181C26`,
   fallback opaque `#151923`, bordure `#293040`, néons magenta
   `#D946EF` / violet `#7C3AED` / cyan `#38BDF8`, CTA en dégradé
   `#C000A4 → #6E00E8`, textes `#F5F7FA`/`#A3ACBA`/`#7C8696`
   (texte discret : `#747E8E` initial corrigé le 27.07.2026 à la
   clôture NU0 — mesures AA insuffisantes sur surfaces 4,49/4,15/4,28 ;
   `#7C8696` mesure 5,50/5,28/5,00/4,63/4,78 sur canvas/navigation/
   surface/élevée/fallback ; le violet seul ne porte jamais un petit
   libellé actif, 3,41:1 sur navigation),
   sémantique `#35D39A`/`#FF6577`/`#F6C453`. Règles complètes :
   `.claude/skills/budget-neon-ultra/references/NEON_ULTRA_CONSTITUTION.md`
   (75 % noir, ≤ 10 % néon, un seul point focal par viewport, gradient
   réservé au CTA/sélection/marque, aucun glow sur les montants,
   sémantique exclusive pour vert/corail/ambre, pas d'esthétique
   casino, AA, 44 pt, Reduce Motion/Transparency).
2. Cette ADR remplace UNIQUEMENT les clauses visuelles incompatibles
   d'ADR-020/022, de CLAUDE.md et de la constitution Obsidian
   (accent indigo unique, interdiction des néons). Tout le reste
   d'ADR-020/022 (skill canonique par programme, un seul thème sombre,
   alias de tokens, contraintes AA mesurées) reste applicable dans son
   esprit au nouveau programme.
3. Aucune règle financière, technique, de confidentialité, de
   sauvegarde, d'accessibilité ou de publication n'est modifiée.
   ADR-001→019, ADR-021, ADR-023 : inchangées.
4. Le programme s'exécute sur la branche `refonte/budget-neon-ultra-v1`
   (créée depuis `26d186e`, dernier HEAD Obsidian à CI verte run #229).
   La branche `refonte/budget-obsidian-glass-v1` et tous les rapports
   L0–L9 sont conservés comme historique et ne sont pas réécrits.
5. La divergence de navigation constatée (PWA : 4 onglets + ＋ central,
   Mouvements dans Plus ; iOS : 5 onglets + ＋ flottant) N'EST PAS
   traitée par cette ADR — décision produit séparée à venir.

### Consequences

- Skill opérationnel : `/budget-neon-ultra` (NU0–NU9) ; `/budget-v1`
  et les skills antérieurs deviennent historiques.
- Les écrans ne changent qu'à partir de NU1/NU2, tokens d'abord,
  contrastes prouvés avant bascule ; NU0 est purement documentaire.

## ADR-023 — V1 native : prise en charge iPhone uniquement

Date: 2026-07-25
Status: accepted

### Context

Décision définitive du propriétaire (25.07.2026, refus de la première
passe L9) : la V1 native prend en charge uniquement l'iPhone ; aucune
prise en charge iPad native n'est demandée. Le projet portait pourtant
`TARGETED_DEVICE_FAMILY = "1,2"` (6 occurrences : Budget, BudgetTests,
BudgetUITests × Debug/Release) et deux réglages
`INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` — le binaire se
déclarait compatible iPad alors que la fiche App Store, les captures et
la QA ne couvrent que l'iPhone.

### Decision

1. `TARGETED_DEVICE_FAMILY = 1` sur les six configurations ; les deux
   réglages d'orientations iPad sont supprimés ; l'iPhone reste en
   portrait. Bundle identifier, version, build, cible iOS 17,
   signature, entitlements et icônes : inchangés.
2. `UIDeviceFamily` n'est PAS ajouté à la main dans l'Info.plist et
   `UIRequiredDeviceCapabilities` n'est PAS utilisé pour bloquer
   l'iPad : la valeur `[1]` doit découler du seul réglage de cible.
3. La CI exige la liste ENTIÈRE `UIDeviceFamily == [1]` (pas la simple
   présence de 1) dans : le `Budget.app` Release de la CI, le
   `Budget.app` de `Budget.xcarchive` du workflow Demo, et le
   `Budget.app` extrait de l'IPA non signée ; preuve secondaire via
   `xcodebuild -showBuildSettings` (Debug et Release).
4. La documentation parle de « prise en charge native iPhone
   uniquement » — sans prétendre empêcher un éventuel mode de
   compatibilité géré par Apple sur iPad.

### Consequences

Le binaire, la fiche App Store et la QA décrivent le même produit. Une
future prise en charge iPad serait une décision produit nouvelle
(layouts, captures, QA dédiées), pas un simple réglage.

### Verification

Étapes CI « iPhone uniquement » (job macOS) et étapes archive/IPA du
workflow Demo ; `xcodebuild -showBuildSettings` imprimé dans les logs.

## ADR-022 — L2 : fondations Obsidian livrées par alias, S.theme neutralisé, indigo profond AA

Date: 2026-07-23
Status: accepted

### Context

L2 doit livrer le système visuel réutilisable (tokens + primitives + galerie)
sans refondre les écrans Mois, Budget et Ajout d'un mouvement (L3/L4). La PWA
portait deux palettes (claire par défaut + sombre) commandées par `S.theme` ;
le natif résolvait ses couleurs selon l'apparence système et gardait des
teintes décoratives héritées (teal, cyan, violet, bleu électrique).

### Decision

1. **Identité unique par alias.** Les tokens canoniques Obsidian (constitution
   §2) deviennent la seule source : `:root` PWA et `BudgetColor` natif. Les
   anciens noms (`--indigo`, `--electric`, `--violet`, `--teal`, `--graphite`…
   / `indigo`, `electricBlue`, `violet`, `cyan`, `teal`, `informative`…) sont
   conservés comme ALIAS pointant vers `brand`, `brandBright` ou les rôles
   Obsidian — les écrans existants héritent de l'identité sans être réécrits.
   Ces alias sont temporaires, documentés, à retirer avec les lots L3+.
2. **`S.theme` neutralisé, jamais détruit.** Le champ reste lu/écrit dans
   l'état et les sauvegardes (compatibilité des restaurations) mais ne
   commande plus l'apparence ; `applyTheme()` applique toujours le sombre.
   La ligne « Apparence » des Réglages et son handler sont retirés. Sur iOS,
   `.preferredColorScheme(.dark)` est posé UNE fois à la racine (BudgetApp) ;
   `BudgetTint`/`BudgetTheme` gardent leurs signatures mais ignorent le
   paramètre `scheme`.
3. **Indigo profond dérivé `#6457F0` (`brandDeep`).** Le blanc sur `brand`
   `#7367FF` mesure 4.11:1 (< AA). Les boutons primaires utilisent donc un
   ton dérivé de la même teinte (permis par la constitution) : 5.04:1 mesuré.
   Vert/corail/ambre restent strictement sémantiques.
4. **Transparence réduite déterministe.** `prefers-reduced-transparency` ET
   l'attribut de test `html[data-reduced-transparency="true"]` (web), le
   réglage système ET l'environnement `obsidianForcedReducedTransparency`
   (SwiftUI, previews/tests) remplacent le verre par `glassFallback` opaque,
   suppriment halo et blurs.
5. **Galerie hors navigation.** `webapp/design-system/obsidian-gallery.html`
   (+ `obsidian.css`, source canonique des tokens, parité testée avec
   `index.html`) et `ObsidianComponentGallery` (previews + argument de
   lancement `-obsidianGallery`, sans effet Release). `index.html` reste
   auto-suffisant hors ligne : aucun nouvel asset de production chargé, le
   service worker est inchangé.

### Consequences

Les écrans existants s'affichent en Obsidian par héritage de tokens ; leurs
compositions, widgets, graphiques et logiques sont inchangés. Le Test 29 e2e
vérifie désormais l'identité unique (sombre appliqué, `S.theme` préservé,
sélecteur absent). Aucune formule financière, donnée, migration ou
persistance n'est touchée.

### Verification

`webapp/tests/design.test.mjs` (tokens canoniques + parité, contrastes AA
mesurés, galerie 320/390 sans débordement, cibles ≥ 44 px, focus clavier,
reduced motion, fallback opaque, zéro erreur console) ; `DesignSystemTests`
natifs (rôles, alias sans seconde palette, contrastes, géométrie, montants
extrêmes, construction de la galerie) ; 48 e2e + 5 parité + suite iOS
complète en CI ; captures `docs/obsidian-glass/foundations/l2/`.


## ADR-021 — L1 : montants historiques figés à la saisie, restauration refusant les montants corrompus

Date: 2026-07-23
Status: accepted

### Context

Audit L1 des cinq P0 Obsidian Glass. Deux étaient réellement présents dans le
code courant :

1. Natif : `BackupService.decimal(_:)` convertissait toute chaîne illisible en
   `.zero` (`Decimal(string:) ?? .zero`). Une sauvegarde corrompue pouvait donc
   restaurer silencieusement des montants à zéro — perte de données invisible.
2. PWA : `txCHF()` convertissait les mouvements en devise étrangère avec le taux
   ACTUEL (`S.fxRates`). Modifier un taux recalculait rétroactivement tout
   l'historique (coût de la vie, budgets, mois bouclés), en violation de
   l'invariant « les montants historiques ne changent jamais parce qu'un taux
   actuel a changé ».

### Decision

1. Natif : `decimal(_:)` devient `throws` et lève `BackupError.corruptAmount`
   avec le montant fautif — y compris sur les quatre champs OPTIONNELS
   (`reconciledBalance`, `override_`, `deductible`, `projected`, via
   `try Optional.map(decimal)`). La restauration entière (suppression,
   reconstruction, sauvegarde) forme UNE transaction : toute erreur à
   n'importe quelle étape appelle `context.rollback()` et relance l'erreur ;
   les fichiers de documents ne sont jamais touchés (ADR-014). Aucune
   coercition vers zéro, jamais.
2. PWA : l'estampillage financier passe par UNE seule fonction, `stampTx()`,
   utilisée par tous les chemins de création (`addTx()`) ET de modification.
   Elle purge d'abord `fx`/`fxBase`/`destAmount` (jamais d'estampille
   périmée), fige `fx` (taux du jour, repli 1:1 EXPLICITE si aucun taux
   valide — le mouvement ne dépend jamais d'un futur taux) et `fxBase`
   pour toute devise source ≠ devise de base, et fige `destAmount` quand la
   destination est dans une autre devise.
3. Migration additive au chargement : `stampAllTransactions(state)` détecte
   les mouvements historiques sans estampille (y compris ceux d'une
   sauvegarde JSON restaurée, qui recharge la page), les estampille UNE
   seule fois avec les taux présents au moment de la migration, calcule les
   `destAmount` manquants, purge les `destAmount` orphelins, puis l'état
   migré est immédiatement persisté. Identifiants, champs et sauvegardes
   préservés — rien de destructif.
4. Ces champs (`fx`, `fxBase`, `destAmount`) sont additifs dans l'état v1 ;
   ils ne cassent ni les sauvegardes existantes ni les fixtures de parité.

### Verification

Natif (`BudgetTests/BackupServiceTests`) : montant obligatoire corrompu,
montant OPTIONNEL corrompu (`reconciledBalance`), montant corrompu dans une
entité reconstruite tardivement (`NetWorthSnapshot`) — chaque cas vérifie le
comptage complet de TOUTES les entités avant/après, l'intégrité du store
persistant via un `ModelContext` neuf, et zéro montant coercé.
PWA (e2e Tests 38-43) : nouveau mouvement EUR + changement de taux ; ancien
mouvement non estampillé + rechargement/migration + changement de taux
(persistance immédiate vérifiée) ; édition ré-estampillée au taux du jour ;
passage d'un compte EUR à un compte CHF (estampille retirée) ; destination
retirée sans `destAmount` périmé ; sauvegarde restaurée entièrement
normalisée au chargement. Suites : 48 parcours e2e + 5 fixtures de parité.


## ADR-020 — Obsidian Glass : identité sombre unique et skill canonique

Date: 2026-07-23
Status: accepted

### Context

Le propriétaire valide la direction « Budget — Obsidian Glass » : une
application sombre, premium, simple, vivante et professionnelle, avec des
widgets transparents et une seule palette de marque. Les programmes précédents
ont laissé plusieurs skills et deux directions visuelles concurrentes
(Horizon clair/sombre et identité verre sombre).

### Decision

1. `/budget-v1` devient l'unique autorité opérationnelle pour Claude Code.
   Les autres skills Budget restent des archives et ne doivent plus être
   invoqués ou combinés.
2. Obsidian Glass utilise une seule identité sombre : fond `#090C12`, surfaces
   graphite translucides et accent Indigo Aurora `#7367FF`. Vert, corail et
   ambre restent strictement sémantiques.
3. Cette décision remplace uniquement la partie visuelle et multi-thème
   d'ADR-019. Les décisions financières d'ADR-019, notamment la parité dette,
   restent valides.
4. La refonte progresse par lots sur une branche dédiée. Le pilote porte sur
   Mois, Budget et Ajout d'un mouvement avant tout déploiement général.
5. PWA et iOS partagent les rôles, tokens, vocabulaire et invariants, sans
   obligation de copie pixel par pixel.
6. Un P0 de données, restauration, confidentialité ou publication confirmé
   bloque le lot visuel suivant jusqu'à correction et test.
7. Chaque lot produit tests, captures, mise à jour du statut et commit ciblé,
   puis s'arrête pour revue.

### Consequences

Le sélecteur de thème et l'ancien rendu ne sont pas supprimés pendant L0. Leur
migration contrôlée appartient aux lots de fondation et de pilote. Aucune
logique financière, donnée, route, migration ou persistance n'est modifiée par
cette décision de gouvernance.

### Verification

Branche `refonte/budget-obsidian-glass-v1`, `CLAUDE.md`, skill
`/budget-v1`, constitution, plan de livraison, matrice d'écrans et statut
créés. Aucun code applicatif modifié dans L0.


## ADR-019 — Horizon : thème clair par défaut (web), sombre premium conservé ; parité dette D04

Date: 2026-07-21
Status: accepted

### Context

Le programme « Budget Leader Refonte » impose une direction « Swiss calm
fintech » : interface claire par défaut, sombre premium fonctionnel. La
branche codex/budget-leader-refonte annoncée n'existe pas sur GitHub —
la spécification du propriétaire fait foi. Par ailleurs l'audit de
parité (fixtures A05) avait documenté que le web comptait les
mensualités de dette dans le coût de la vie, contrairement à ADR-016.

### Decision

1. PWA : tokens de thème (`--bg/--surface/--surface-2/--surface-3/--field/
   --line/--line-strong/--sheen/--hero-surface/--badge-ink`) ; clair par
   défaut dans `:root`, l'identité verre sombre historique intacte sous
   `html[data-theme="dark"]` ; préférence `S.theme` persistée, bascule
   dans Réglages, `meta theme-color` synchronisé. Le natif reprendra les
   mêmes rôles de tokens (DesignTokens) lors d'un lot dédié vérifié par CI.
2. Web : les mouvements `recurringId` préfixé `r-debt-` sont exclus du
   coût de la vie, du « pas encore classé » et des dépenses de l'accueil
   (capital ≠ dépense ; intérêts saisis à part) — aligné sur ADR-016.

### Consequences

Les montants du mois web et natif sont réconciliés par les fixtures de
parité (living 0 / cashFlow 0 / dette décrémentée sur le scénario
dette-vivante). Les utilisateurs existants du web basculent en clair au
prochain chargement (S.theme absent → light) ; le sombre se réactive en
deux gestes dans Réglages.

### Verification

38 parcours e2e Chromium + 4 fixtures de parité verts, zéro erreur
console ; captures clair/sombre 390 px et 320 px sans débordement.

## ADR-013 — Sécurité/portabilité : verrouillage authentifié dans les deux sens, sauvegarde en montants String

Date: 2026-07-19
Status: accepted

### Context

Phase 12. Critères : états de verrouillage, annulation, version de restauration et confirmations destructives corrects ; textes de confidentialité conformes à l'implémentation.

### Decision

- `AuthenticationProviding` (protocole, contrat architecture) : impl LAContext (`deviceOwnerAuthentication` = biométrie avec repli code) + fake scripté. `AppLockManager` : verrouillé au lancement et au passage en arrière-plan quand activé ; annulation/échec = reste verrouillé ; l'ACTIVATION ET la désactivation exigent une authentification (un passant ne désactive pas la protection). Préférence dans UserDefaults (pas un secret) ; `NSFaceIDUsageDescription` ajouté au projet.
- Sauvegarde JSON versionnée (`schemaVersion` = 8) : chaque montant voyage en **String** (`"2150.00"`) — le Codable de Decimal via JSON perdrait la précision ; relations recousues par UUID à la restauration ; une sauvegarde d'un schéma PLUS RÉCENT est refusée avec message clair ; un JSON corrompu est refusé AVANT tout effacement.
- Restauration = remplacement total (confirmation destructive) ; les fichiers de documents ne voyagent pas dans le JSON (métadonnées seulement, référence conservée).
- Export CSV machine-stable (dates ISO, décimales à point, `;`, guillemets doublés) — l'affichage fr-CH reste dans l'app, l'export vise la portabilité.
- Suppression totale : double confirmation, efface toutes les entités (transactions d'abord pour ne jamais heurter les règles .deny) ET les fichiers de documents.
- Écrans Confidentialité/Méthodologie : textes alignés sur le comportement réel (aucun réseau, aucune analyse, formules exactes du disponible/taux d'épargne/impôts).

### Consequences

L'export sur demande uniquement ; aucune écriture réseau nulle part.

### Verification

`BackupServiceTests` (round-trip complet sur les données démo, remplacement, rejet schéma plus récent sans effacement, rejet corruption, suppression totale fichiers compris, échappement CSV) et `AppLockManagerTests` (défaut déverrouillé, activation authentifiée, annulation/échec/succès, persistance à la relance).

## ADR-012 — Import CSV : empreintes SHA-256, écriture au dernier pas, fichiers derrière protocole

Date: 2026-07-19
Status: accepted

### Context

Phase 11. La spec CSV_IMPORT_SPEC exige : aucun doublon au ré-import, chaque ligne rejetée visible, jamais d'import depuis une préview, pas de création massive de catégories.

### Decision

- Empreinte = SHA-256 (CryptoKit, framework système) de l'identité normalisée `fichier|index|dateISO|montant|type|intitulé` → stockée dans `importFingerprint` (existant depuis V1) ; doublon si l'empreinte existe déjà (dans le store OU plus haut dans le même fichier). L'index de ligne fait partie de l'identité : deux lignes volontairement identiques dans le fichier restent deux mouvements.
- Le wizard est pur jusqu'au bout : parse/mapping/validation ne touchent jamais le store ; seul `apply` écrit, en lot (`ImportBatch` + `importBatchID` additif sur BudgetTransaction) → rollback exact du lot (les catégories créées survivent car potentiellement réutilisées).
- Catégories manquantes listées et créées UNIQUEMENT si cochées ; lignes non confirmées importées sans catégorie (file « non catégorisés » existante).
- Fichiers de documents : protocole `DocumentFileStoring` (contrat architecture), impl réelle FileManager avec `.completeFileProtection` dans le conteneur, fake in-memory pour tests/previews. Pas de blob SwiftData.
- Export CSV/JSON : Phase 12, conformément au découpage de la roadmap.

### Consequences

Le rapport réconcilie par construction (total = importées + doublons + invalides) ; le texte brut des lignes est conservé dans le rapport jusqu'à sa fermeture.

### Verification

`CSVImportServiceTests` : détection, guillemets, dates suisses, raisons visibles, ré-import 0 doublon, stabilité d'empreinte, confirmations de catégories, réconciliation, rollback ciblé, fake store.

## ADR-011 — Patrimoine : dettes positives soustraites, instantané quotidien

Date: 2026-07-19
Status: accepted

### Context

Phase 10. Les comptes de dette (carte, hypothèque tenue en compte) portent déjà un solde négatif ; il faut des dettes autonomes sans jamais double-compter, et une tendance historique.

### Decision

- Schéma V7 : `Asset`, `Liability` (montant TOUJOURS stocké positif, soustrait par le service — jamais de double négatif), `NetWorthSnapshot` (composantes figées).
- `NetWorthService.breakdown` : `net = comptes inclus actifs (convention signée existante) + actifs inclus + prévoyance active − dettes incluses`. Une dette portée par un compte reste sur ce compte (le formulaire le rappelle) ; les Liability couvrent les dettes hors comptes (leasing, dette fiscale…).
- Tendance : au plus UN instantané par jour calendaire, enregistré à l'ouverture de l'écran Patrimoine ; composantes figées pour que l'historique survive aux changements ultérieurs.
- `MonthSnapshot.netWorth` (comptes seuls) reste inchangé : le patrimoine complet vit dans NetWorthService ; le dashboard mensuel n'affiche pas de fortune totale.

### Consequences

La distinction contribution/variation de valeur (spec) attendra des données réelles multi-instantanés ; V1 montre la courbe totale.

### Verification

`NetWorthServiceTests` : réconciliation, signes, non-double-comptage des comptes de dette, toggles, neutralité des virements sur le patrimoine complet, unicité quotidienne des instantanés, tri de tendance, round-trip V7.

## ADR-010 — Assurances/prévoyance : prime au rythme réel, projections jamais inventées

Date: 2026-07-19
Status: accepted

### Context

Phase 9. Les primes suisses se paient à des rythmes variés (LAMal mensuelle, RC annuelle) et la prévoyance vient de relevés officiels.

### Decision

- Schéma V6 : `InsuranceContract` (prime stockée à son rythme réel via RecurrenceUnit + intervalle ; équivalents annuel/mensuel DÉRIVÉS par `InsurancePensionService` avec les mêmes formules que les récurrents → réconciliation garantie, le total mensuel dérive du total annuel) et `PensionAsset` (piliers 1/2/3a/3b, valeurs recopiées des certificats).
- L'app n'invente aucune croissance : la « projection à la retraite » est celle imprimée sur le certificat de l'institution, étiquetée comme hypothèse ; la somme des projections n'est affichée que si CHAQUE position en a une (une somme partielle serait trompeuse).
- Délais de résiliation surveillés à 60 jours (les résiliations d'assurance demandent plus d'anticipation que les abonnements à 30 j).
- Pas de comparaison commerciale d'assurances en V1 (contrat produit).

### Consequences

`documentReference` reste un champ libre jusqu'au module Documents (Phase 11).

### Verification

`InsurancePensionServiceTests` : équivalents mensuel/trimestriel/annuel, totaux ménage réconciliés, tri des délais, totaux par pilier = total général, refus de somme partielle, round-trip V6.

## ADR-009 — Objectifs : valeur courante exclusive, contributions non soustraites du disponible

Date: 2026-07-19
Status: accepted

### Context

Phase 8. La valeur courante d'un objectif peut venir d'un compte lié ou d'un suivi manuel ; et la formule « disponible » du spec mentionne « − contributions d'objectifs engagées ».

### Decision

- Schéma V5 : `FinancialGoal` (type, cible, date, compte lié OU montant manuel — jamais les deux, le formulaire remet le manuel à zéro quand un compte est lié ; contribution prévue, priorité, statut).
- Projections dérivées, jamais stockées : progrès borné [0,1] (cible ≤ 0 = atteint, sans division), mois restants comptés en jours entiers (un mois entamé compte), contribution requise = restant / mois (tout dû immédiatement si échéance passée ou dernier mois), statut En bonne voie/À accélérer selon prévu vs requis, projection par division plafond.
- Les contributions d'objectifs ne sont PAS soustraites du « vraiment disponible » : l'épargne planifiée est déjà modélisée par les récurrents (type saving/investment) — la soustraire une seconde fois via les objectifs double-compterait. Les objectifs mesurent le progrès, les récurrents engagent le cash.
- Célébration sobre : badge « Atteint » + coche, pas d'animation tapageuse (design system).

### Consequences

Un objectif alimenté par un récurrent lié au même compte se met à jour tout seul ; déviation documentée de la formule du spec (composant objectifs = 0 en V1).

### Verification

`GoalProjectionServiceTests` : bords sûrs, mois restants, requis vs prévu, division plafond, round-trip V5.

## ADR-008 — Impôts : profil paresseux, états dérivés, schéma V4

Date: 2026-07-19
Status: accepted

### Context

La Phase 7 doit distinguer recommandé / réservé / payé / encore dû / arriérés avec des états qui se réconcilient toujours, et solder l'ADR-003 (taux sur Household).

### Decision

- Schéma V4 : `TaxProfile` (localisation + taux, source de vérité) et `TaxProvision` par année (override d'estimation, réserve, arriérés, échéances `[TaxDueDate]` Codable). Migration légère, purement additive.
- Pas de stage de migration custom : `TaxService.ensureProfile` crée le profil **paresseusement** en le semant depuis `Household.taxProvisionRate` — couvre stores migrés ET installations neuves par le même chemin ; le champ Household devient un simple seed conservé cohérent quand le taux change.
- Payé et encore dû ne sont JAMAIS stockés : dérivés des mouvements `taxPayment` comptabilisés de l'année → `estimé = payé + encore dû` par construction ; `écart de réserve = max(0, encore dû + arriérés − réserve)`.
- Hypothèses visibles à l'écran (taux, revenus, base de calcul) + avertissement explicite « estimation d'organisation, pas un décompte officiel ».

### Alternatives considered

- Stage `MigrationStage.custom` copiant le taux : fragile avec le pattern de classes partagées et redondant avec la création paresseuse.
- Stocker paid/outstanding sur la provision : casse la réconciliation à la première divergence.

### Consequences

Un seul profil par store (garanti par ensureProfile) ; une provision par (profil, année) (garantie par ensureProvision).

### Verification

`TaxServiceTests` : réconciliation estimé/payé/dû, override, bornes d'années, écart de réserve avec arriérés, unicité, échéances, priorité du taux profil dans le snapshot, round-trip V4.

## ADR-007 — Récurrents : entité unique, occurrences par multiples d'ancre, schéma V3

Date: 2026-07-19
Status: accepted

### Context

La Phase 6 introduit charges récurrentes et abonnements, avec prévisions mensuelles qui ne doivent jamais dupliquer les mouvements réels.

### Decision

- Une seule entité `RecurringTransaction` couvre charges, revenus, contributions ET abonnements (`isSubscription` + renouvellement/résiliation), plutôt que deux entités quasi identiques.
- Rythme = (unité semaine/mois/année, intervalle N) : mensuel (mois,1), trimestriel (mois,3), annuel (année,1), personnalisé libre.
- La k-ième occurrence = `firstOccurrence + k·intervalle` (multiples de l'ancre, jamais d'addition incrémentale) : 31 janv → 28 févr → **31** mars, sans dérive ; 29 févr bissextile → 28 févr les années communes.
- Dédup prévision/réel par `BudgetTransaction.recurringID` : N mouvements liés dans le mois couvrent les N premières occurrences (couverture chronologique par comptage, tolérante aux jours décalés — un salaire versé le 24 couvre l'échéance du 25).
- Schéma V3 (3.0.0) : + `RecurringTransaction`, + `recurringID` optionnel sur `BudgetTransaction` ; migrations légères V1→V2→V3 (changements purement additifs).
- Le disponible intègre deux composantes visibles de plus : revenus récurrents à venir et charges récurrentes à venir ; les virements récurrents restent neutres.

### Alternatives considered

- Entité `Subscription` séparée : duplication de champs sans bénéfice V1.
- Dédup par date exacte : casse dès qu'un salaire tombe un jour plus tôt.

### Consequences

Toute occurrence comptabilisée doit passer par `makeTransaction(from:on:now:)` (ou poser `recurringID`) pour sortir des prévisions.

### Verification

`RecurringScheduleServiceTests` : bornes de mois, bissextiles, trimestriel/annuel/hebdo/personnalisé, dédup partielle, neutralité des virements, intégration snapshot.

## ADR-001 — Projet Xcode manuscrit au format « synchronized groups » (Xcode 16)

Date: 2026-07-19
Status: accepted

### Context

Le projet est bootstrappé depuis un environnement Linux sans Xcode. Il faut un `.xcodeproj` ouvrable directement sur Mac.

### Decision

Écrire `project.pbxproj` à la main en `objectVersion = 77` avec des `PBXFileSystemSynchronizedRootGroup` (`Budget/`, `BudgetTests/`) : les fichiers ajoutés sur disque rejoignent automatiquement les cibles, sans listes de fichiers fragiles dans le pbxproj.

### Alternatives considered

- XcodeGen/Tuist : dépendance d'outillage externe, contraire à l'esprit « aucune dépendance » du contrat V1.
- pbxproj classique (objectVersion 56) : chaque fichier devrait être référencé manuellement, très sujet aux erreurs hors Xcode.

### Consequences

Xcode 16+ requis. Aucune maintenance de liste de fichiers.

### Verification

Ouvrir le projet sur Mac ; compiler l'app et les tests.

## ADR-002 — Enums persistés en rawValue String

Date: 2026-07-19
Status: accepted

### Context

SwiftData sait persister des enums Codable, mais les prédicats et migrations sur enums restent fragiles.

### Decision

Persister `typeRawValue`/`statusRawValue`/etc. en `String` avec propriétés calculées typées (`type`, `status`, …). Les valeurs inconnues retombent sur un cas sûr.

### Consequences

Prédicats simples et migrations robustes ; discipline nécessaire pour passer par les propriétés typées.

## ADR-003 — Taux de provision fiscale sur Household jusqu'à la Phase 7

Date: 2026-07-19
Status: accepted

### Context

L'onboarding (Phase 1) et le dashboard (Phase 4) ont besoin du taux de provision (défaut 30 %), mais l'entité TaxProfile complète n'arrive qu'en Phase 7.

### Decision

Stocker `taxProvisionRate: Decimal` sur `Household` avec défaut `0.30`. Migration vers `TaxProfile` planifiée en Phase 7 (nouvelle version de schéma + stage de migration).

### Consequences

Pas d'entité prématurée ; une migration à écrire en Phase 7.

## ADR-004 — Convention de montants positifs + direction par type

Date: 2026-07-19
Status: accepted

### Context

Le spec impose une convention unique, jamais mélangée.

### Decision

`BudgetTransaction.amount > 0` toujours ; la direction vient du `type` (income/refund entrants ; expense/saving/investment/transfer/taxPayment/debtPayment sortants). Seul `adjustment` porte un drapeau explicite `adjustmentIncreasesBalance`. Les virements et contributions internes (saving/investment avec `destinationAccount`) créditent la destination — un seul enregistrement, effet atomique, jamais dupliqué en revenu+dépense.

### Consequences

Les invariants (neutralité des virements, patrimoine) se testent sur une seule source de vérité : `AccountBalanceService.signedEffect`.

## ADR-006 — Schéma V2 : budgets mensuels, migration légère

Date: 2026-07-19
Status: accepted

### Context

La Phase 5 introduit `MonthlyBudget` et `BudgetLine`. Les stores V1 existants (phases 0-4) doivent migrer sans perte.

### Decision

`BudgetSchemaV2` (2.0.0) = modèles V1 + les deux nouveaux ; `MigrationStage.lightweight(fromVersion: V1, toVersion: V2)` car le changement est purement additif. L'unicité d'un budget par (année, mois) est garantie par `BudgetPlanningService.findOrCreate` — unique chemin de création — plutôt que par une contrainte composite SwiftData (non disponible). Le réel n'est jamais stocké sur une ligne : il dérive des transactions comptabilisées via `BudgetVarianceService`, et les montants hors budget sont exposés séparément pour que la réconciliation soit totale.

### Alternatives considered

- Contrainte `#Unique` composite : non supportée sur iOS 17.
- Stocker le réel sur la ligne : violerait la séparation planifié/réel.

### Consequences

Migration à valider sur un appareil contenant des données V1 ; toute création de budget passe par le service.

### Verification

Tests `BudgetPlanningServiceTests` (unicité, round-trip V2, cascade) ; test manuel de migration sur simulateur avec store V1 existant.

## ADR-005 — Mode démo sur container in-memory séparé

Date: 2026-07-19
Status: accepted

### Context

Le contrat interdit toute donnée démo dans le store de production.

### Decision

`AppContainer.isDemoMode` bascule l'app entière sur un `ModelContainer` in-memory peuplé par `DemoDataFactory` ; bannière visible en permanence ; retour aux vraies données en quittant le mode.

### Consequences

Isolation totale ; l'interface est reconstruite au changement de mode (`.id(isDemoMode)`).

## ADR-014 — La restauration ne touche jamais aux fichiers de documents

Date: 2026-07-19
Status: accepted

### Context

L'audit de la Phase 13 a révélé un scénario de perte définitive : `restore()` appelait `deleteAll` avec le vrai `DocumentFileStore`, effaçait donc tous les fichiers de documents, puis réinsérait des métadonnées dont les `fileReference` ne pointaient plus sur rien. Les fichiers ne voyagent pas dans la sauvegarde JSON — rien ne pouvait les faire revenir.

### Decision

1. La restauration remplace les ENTITÉS uniquement (`wipeEntities`) et ne supprime jamais un fichier : une référence restaurée retrouve son fichier s'il est encore présent.
2. Aucune écriture n'est committée avant la fin de la reconstruction : la purge et les insertions partagent la même transaction, un échec fait `rollback()` et le store reste tel quel — le message « vos données actuelles sont intactes » est vrai dans tous les cas.
3. Dans la suppression totale, les fichiers ne sont effacés qu'APRÈS le commit de la purge des entités (jamais de fichiers perdus avec des enregistrements survivants).
4. La sauvegarde embarque désormais aussi `ImportBatch`, `employmentStatus` et les `updatedAt` (round-trip réellement sans perte) ; les nouveaux champs sont optionnels au décodage pour rester compatibles avec les sauvegardes antérieures.

### Consequences

Restaurer sur un appareil contenant des documents est sans danger ; l'historique d'import et ses poignées de rollback survivent au round-trip.

### Verification

`testRestoreNeverDeletesDocumentFiles`, round-trip étendu aux lots d'import (`BackupServiceTests`).

## ADR-015 — Migration V1 : légère automatique, plan étagé retiré

Date: 2026-07-20
Status: accepted

### Context

Le tour simulateur (workflow Demo) a fait planter l'app au premier lancement sur un store disque neuf : `NSStagedMigrationManager` abandonne (SIGABRT) dans `makeProductionContainer`. Cause : les huit `VersionedSchema` (V1→V8) référencent les MÊMES classes @Model vivantes — chaque étape du plan porte donc une empreinte de modèle identique et le gestionnaire de migration ne peut pas déterminer l'étape courante. Les tests unitaires n'ont jamais vu le crash : le conteneur in-memory n'entre pas dans ce chemin de code. L'app aurait planté au premier lancement sur n'importe quel iPhone.

### Decision

1. Retirer le `SchemaMigrationPlan` des deux fabriques de conteneur : chaque changement V1→V8 étant strictement additif, la migration légère AUTOMATIQUE de SwiftData couvre tous les stores existants (aucun n'a d'ailleurs été distribué).
2. Conserver les enums `BudgetSchemaV1…V8` comme documentation de l'historique du schéma.
3. Un vrai plan étagé (avec instantanés de modèles gelés par version) ne sera introduit qu'au premier changement RUPTEUR après la mise en production.

### Consequences

Le lancement sur appareil fonctionne ; la validation « migration V1→V8 sur un appareil » se réduit à la migration légère automatique d'Apple, couverte par leur runtime.

### Verification

Workflow Demo : la vraie app démarre dans le simulateur (tour complet capturé) ; suite unitaire inchangée.

## ADR-016 — Remboursement de dette atomique et fin des sauvegardes silencieuses

Date: 2026-07-20
Status: accepted

### Context

Audit externe (skill budget-production-completion) : `.debtPayment` débitait le compte source sans jamais réduire la dette — un remboursement faisait BAISSER la fortune nette au lieu de la laisser neutre. Par ailleurs six mutations utilisateur utilisaient `try? modelContext.save()` : un échec de persistance passait inaperçu et l'écran divergeait du store.

### Decision

1. `.debtPayment` accepte un compte de destination : le compte de dette remboursé (carte de crédit, prêt, hypothèque — soldes négatifs par convention ADR patrimoine). `supportsDestinationAccount` et la validation le traitent comme épargne/investissement (destination facultative, ≠ source, active) ; `signedEffect` créditait déjà toute destination — cash et dette bougent ensemble, fortune inchangée. Sans destination, le remboursement reste une sortie vers un créancier externe (dette du Patrimoine mise à jour manuellement). Intérêts et frais = dépenses séparées.
2. `ModelContext.saveOrRollback(onError:)` (Core/Persistence/SafeSave.swift) : do/catch + rollback + message français ; les six `try? save` sont remplacés, chaque vue affiche l'erreur (bannière ou alerte). Interdiction contractuelle de réintroduire `try? save` dans une mutation utilisateur.

### Verification

`DebtPaymentTests` (validation, effets signés, neutralité de fortune, partiel, trop-payé, sans destination) ; grep CI-able : zéro `try? modelContext.save()`.

## ADR-017 — V1 mono-devise : le CHF partout, garde à la restauration

Date: 2026-07-20
Status: accepted

### Context

`Account.currencyCode` existe dans le schéma (défaut "CHF") mais aucun service ne convertit : soldes, snapshot mensuel, budgets et fortune ADDITIONNENT les montants bruts. Un compte EUR restauré depuis une sauvegarde fausserait silencieusement tous les totaux. L'UI native n'expose nulle part le choix de devise — le seul chemin d'entrée d'un compte non-CHF est `BackupService.restore`.

### Decision

1. Budget V1 natif est STRICTEMENT mono-devise CHF. Aucun taux de change, aucune conversion, aucune promesse multi-devises dans l'app ni sur la fiche App Store.
2. Garde à l'entrée : `BackupService.restore` refuse toute sauvegarde contenant un compte ou un ménage non-CHF (`BackupError.unsupportedCurrency`, message listant les devises) AVANT de toucher au store — les données existantes restent intactes.
3. `currencyCode` reste dans le schéma comme réservation V2 ; le prototype web (multi-devises CHF/EUR/USD à taux manuels) sert de laboratoire pour la V2 native.

### Verification

`UnifiedTaxReserveTests.testRestoreRefusesNonCHFAccounts` : sauvegarde avec compte EUR → erreur dédiée, store intact.

## ADR-018 — Une seule vérité fiscale : le snapshot mensuel lit TaxService

Date: 2026-07-20
Status: accepted

### Context

Audit externe : le tableau de bord calculait sa « réserve d'impôts manquante » localement (revenus du mois × taux − impôts payés du mois) en IGNORANT la réserve annuelle constituée (`TaxProvision.reservedAmount`) et les arriérés saisis dans le module Impôts. Un utilisateur ayant déjà mis de côté sa provision voyait l'accueil réclamer une réserve déjà couverte — deux écrans, deux vérités.

### Decision

1. `TaxService.monthReserveGap(monthIncome:monthPaid:rate:provision:)` est la formule UNIQUE : manque du mois (plancher zéro) + arriérés − réserve annuelle constituée, plancher zéro.
2. `MonthlySnapshotService` reçoit les `TaxProvision` (année du mois affiché) et délègue le calcul — plus aucune formule fiscale locale ; `TaxProvisionSummary` transporte `reserved`, `arrears` et un `gap` figé.
3. Même principe côté web : `taxSummary(year)` est la seule source (fait en P0.2).

### Verification

`UnifiedTaxReserveTests` : réserve couvrante → écart nul ; arriérés → écart augmenté ; provision d'une autre année ignorée ; accueil et module Impôts produisent le MÊME `reserveGap` sur un mois isolé.
