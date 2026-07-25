# Budget project status

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L9 (2026-07-25)

L9 « Audit final et préparation réelle » exécuté (`/budget-v1 execute
L9`) après validation humaine définitive de L8 (`240e4f4`). AUCUN code
applicatif modifié (aucun P0/P1 découvert) — passe d'audit et de
preuves uniquement, dossier `docs/obsidian-glass/final-audit/l9/` :
matrice écran/bouton PWA+iOS complète (preuves automatiques/visuelles/
humaines distinguées, PASS partout), invariants financiers chacun
rattaché à un test NOMMÉ (Decimal, fr-CH, planifié≠réel, virements
neutres ADR-016, patrimoine, mono-CHF ADR-017, historique figé, zéro
coercition, imports idempotents, fiscalité unifiée ADR-018), audit
store disque (création+relance par CHAQUE lancement Demo — le chemin
qui avait attrapé ADR-015 —, refus de restauration atomiques ADR-014),
audit navigateur 70/70 PASS (tous les écrans à 390 ET 320, exclusion du
＋, persistance, service worker + rechargement HORS LIGNE réel,
installabilité), 21 captures inspectées (montants 7 chiffres), audit
confidentialité/App Store (aucune donnée collectée vérifiée dans le
code, 9 décisions HUMAN REQUIRED), protocole iPhone réel + haptique
PENDING HUMAN. Suites locales : 71 e2e + 5 parité + design verts, zéro
erreur console. Défauts : P0 0 · P1 0 · P2 1 (PWA sans `<meta charset>`
— démontré, non bloquant sur les canaux réels, correctif d'une ligne
proposé) · P3 4. **L9 = VERIFYING** — validation finale = inspection
humaine + vibration haptique confirmée par le propriétaire.

**Refus L9 n°1 (2026-07-25)** — validation humaine REFUSÉE sur
`2ce7320` ; décisions définitives du propriétaire : V1 native iPhone
UNIQUEMENT (ADR-023), app jamais installée sur iPhone réel, aucun
compte Apple Developer, aucun TestFlight — aucune QA physique ne peut
être déclarée réussie. Défauts à corriger : cible iPad résiduelle
(`TARGETED_DEVICE_FAMILY "1,2"` + orientations iPad), test de
persistance disque inexistant (à créer : `DiskStoreLifecycleTests`),
P2 charset à corriger réellement (meta + test HTTP sans charset,
suite ≥ 72), écarts documentaires (21 captures pas 23, verrouillage
dans `AppLockManagerTests`, `BackupServiceTests` = 10 tests, PERF
recopiées d'un run antérieur). **L9 = IN_PROGRESS** (passe corrective).

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L8 (2026-07-24)

L8 « Widgets, graphiques et micro-interactions » exécuté
(`/budget-v1 execute L8`) après validation humaine définitive de L7.
PWA : courbes Patrimoine 12 mois et « Solde — 12 derniers mois » du
détail de compte SÉLECTIONNABLES — 12 boutons transparents pleine
hauteur par courbe (aria-label « Voir {mois} {année} : {montant} »,
aria-pressed, focus-visible), règle + point Indigo vif sur le mois
choisi, étiquette textuelle aria-live dont la valeur vient TOUJOURS de
la série existante (rien de recalculé), focus clavier restauré après
re-rendu ; aucune animation ajoutée. iOS : `chartXSelection` sur
l'Évolution du Patrimoine (RuleMark + PointMark, étiquette statique
testée `swissDate + chf + « de fortune nette »`), haptique
`.sensoryFeedback(.success)` UNIQUEMENT après un enregistrement de
mouvement réussi. Performance : 10 000 mouvements semés → rendu < 4 s,
DOM borné par le mois (< 1 500 lignes), navigation < 4 s. Suites :
**69 e2e** + 5 parité + design verts ; natifs `ObsidianMotionTests`
(étiquette fr-CH positive/négative, Patrimoine 320 pt transparence
réduite ; total 254 attendu) ; 5 captures inspectées + README
(`docs/obsidian-glass/widgets-motion/l8/` — cibles ≈ 30 × 96 px en
continuum de balayage documentées, personnalisation des widgets natifs
volontairement non ajoutée). Formules, migrations, clés localStorage,
format de sauvegarde, zone d'exclusion du ＋ : INCHANGÉS.
**L8 = VERIFYING**, L9 = BLOCKED.

**Validation L8 (2026-07-25)** — validation humaine DÉFINITIVE reçue
sur la référence `240e4f4` après trois passes correctives documentées.
**L8 = DONE, L9 = READY** (à lancer uniquement sur commande explicite ;
contrôle humain consigné pour L9 : vibration physique du haptique sur
iPhone réel).

**Micro-correction n°3 L8 (2026-07-25)** — 3e refus (unique défaut :
preuve 320-a11y illisible — axe superposé, étiquette coupée, largeur
artificielle) → `fix(l8): make the 320 accessibility chart fully
readable` + stabilisations : axe X adaptatif de PRODUCTION (deux
repères explicites premier/avant-dernier, libellés fixedSize
introncables, rendu normal automatique inchangé), preuve dans un
viewport réel 320 pt avec marges de production, assertions de géométrie
réelle (delta de hauteur mesurée, plancher, analyse pixel), pièces
ios-l8 en base64 dans les logs Demo et inspectées directement — pièce
finale 960 × 1212 px 100 % lisible. CI #209-#213 vertes (258 tests iOS
0 échec), Demo 30159052445 vert et inspecté. L8 reste VERIFYING.

**Micro-correction finale L8 (2026-07-25)** — 2e refus humain (fausse
pagination cumulative, marqueurs coupés aux extrêmes, preuve 320-a11y
sans courbe, geste Demo par regex, temps de rapport erronés) →
`fix(l8): bound transaction pages and expose edge selections` : vraie
pagination des Mouvements (page REMPLACÉE, ≤ 200 lignes DOM garanties
après chaque action, première/précédente/suivante/dernière, plage
« X–Y sur N », première/dernière lignes contrôlées par référence
indépendante), projection X 6…294 (cercles complets et règles
intérieures aux deux extrêmes, testés Origine/Fin sur les deux courbes
à 390/320), carte Évolution extraite en composant de production
`NetWorthTrendCard` et rendue EN ENTIER pour la preuve
320/a11y3/transparence réduite (étiquette littérale vérifiée avant
capture, rendu sélectionné ≠ invite), geste Demo asserté contre
l'instantané réel de la fixture démo (CHF 138'400.00 + valeur
accessible identique), 7 captures régénérées et inspectées. Suites :
71 e2e + 5 parité + design verts ; iOS 258 attendus. L8 reste
VERIFYING.

**Correctif L8 (2026-07-24)** — validation humaine refusée (échelle
cassée sur séries constantes négatives, cibles < 44 pt, sélection
fuyant entre comptes, perf partielle, sélection native jamais
parcourue, ＋ natif recouvrant en défilement, README survendu) →
`fix(l8): make chart interaction accessible and prove native
selection` : `chartYScale` commune sûre (capture solde constant −100 à
l'appui), scrubber `role="slider"` pleine courbe (glissement Pointer
Events réel, clavier ←/→/Home/End, ≥ 44 pt mesuré, aria-valuetext,
région live persistante), sélection par compte `{id, i}`, Mouvements
paginés (200 lignes fixes, « Afficher X de plus (Y encore repliés) »),
perf 10k répartis ET concentrés jusqu'à la peinture (temps loggés),
sélection native parcourue au tour Demo (glissement réel, étiquette
`networth.chart.selectionLabel` vérifiée, valeur accessible = sélection,
lecture conservée après le geste, captures ios-l8-*), rendu 320/a11y3/
transparence réduite attaché à l'artefact, haptique testable
(vibration physique = contrôle humain L9), zone d'exclusion du ＋
restaurée sur TOUS les écrans défilants + `.clipped()` + assertions à
chaque position intermédiaire. Suites : **71 e2e** + 5 parité + design ;
natifs 258 attendus (`ObsidianMotionTests` 7 tests, exécutés aussi par
le Demo) ; 6 captures + README honnête. L8 reste VERIFYING.

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L7 (2026-07-24)

L7 « Onboarding et confiance » exécuté (`/budget-v1 execute L7`) après
validation humaine de L6. PWA : promesse de confidentialité concrète à
l'étape 1, Retour partout (saisies conservées), part d'impôts MODIFIABLE
présentée comme estimation (« jamais un taux officiel »), erreur près du
champ, résumé RÉEL avant restauration (date, contenu, portée, absents).
iOS : hub Plus par intentions (5 groupes, sous-titres, zone FAB), étape
facultative « Revenus et logement » (RecurringTransaction, save
atomique, Passer), résumé de restauration via BackupService.summary
(refus illisible/version future AVANT confirmation), « D'abord créer une
sauvegarde » dans le dialogue de suppression, pill « Fichier absent »
sur les documents sans fichier, formulations non sourcées retirées.
Suites : 64 e2e + 5 parité + design verts ; ObsidianTrustTests (7 tests)
+ OnboardingViewModelTests adaptés (total 249 attendu) ; 19 captures PWA
+ README (`docs/obsidian-glass/onboarding-trust/l7/`) ; tour Demo 18
étapes (+16-documents, +17-suppression-annulee, dialogue destructif
ouvert puis ANNULÉ). Formules, migrations, persistance, format de
sauvegarde : INCHANGÉS. **L7 = VERIFYING**, L8 = BLOCKED.

**Correctif L7 (2026-07-24)** — 1er refus visuel : ＋ PWA recouvrant du
contenu (padding ≠ exclusion), toasts parasites, import sans
mapping/compte visibles, documents non modifiables, textes destructifs
discordants, bannière démo iOS sur la navigation, métadonnées tronquées,
titres sombres, zone noire Réglages, onboarding natif non capturé →
`fix(l7): complete trust flows and protect floating actions` : viewport
PWA `.fab-clear` s'arrêtant au-dessus du ＋ (rectangles réels testés,
＋ z-indexé toujours visible), assistant d'import complet en mémoire
(mapping modifiable, compte obligatoire, aperçu, confirmation distincte,
rollback), édition des métadonnées de documents, concordance exacte des
actions destructives, bannière démo dans sa propre bande (VStack), fond
appliqué APRÈS la zone du ＋, métadonnées Documents multilignes
(+membre+date), contraste des titres du hub (token), tour natif
onboarding+confiance (19 captures ios-l7-*, résumé de restauration réel
via BackupService.summary, import natif parcouru, suppression annulée).
Suites : 67 e2e + 5 parité + design ; +1 test natif (250 attendus) ;
captures PWA régénérées sans toast. L7 reste VERIFYING.

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L6 (2026-07-23)

L6 « Modules financiers » exécuté (`/budget-v1 execute L6`) après
validation humaine de L5. Les 7 modules (Factures, Objectifs, Impôts,
Patrimoine, Actifs+dettes, Prévoyance, Assurances) refondus PWA + iOS.
PWA : héros Factures « Encore à payer » + paiement LIÉ sans double
comptage, pills d'état écrites partout (objectifs, réserve d'impôts,
échéance d'assurance ≤ 45 j, récurrents), carte « Estimation
incomplète » sans revenu (rien d'inventé), fortune nette négative
honnête + fraîcheur/conversion explicites, « Déjà constitué » sourcé.
iOS : héros en AmountText (unités « par an »/« par mois » séparées),
EmptyState L2 partout, caption de fraîcheur Patrimoine. Suites : 60 e2e
+ 5 parité + design verts ; ObsidianFinancialModulesTests (8 tests
natifs, total 239 attendu) ; 16 captures PWA + README
(`docs/obsidian-glass/financial-modules/l6/`) ; tour Demo 15 étapes
(+ 14-assurances, 15-prevoyance). Formules, migrations, persistance :
INCHANGÉES. **L6 = VERIFYING**, L7 = BLOCKED.

**Correctif L6 (2026-07-24)** — validation visuelle refusée (＋ flottant
masquant du contenu, libellés tronqués) → passe `fix(l6)` : zone
`fabClearance` (96 pt) réservée sous les 10 contenus défilants des 6
modules, libellés essentiels multilignes (plus d'ellipse), montants
`fixedSize` (jamais comprimés), stats fiscales en colonnes adaptatives
(1 colonne à 320 pt), projection Patrimoine arrondie au centime à
l'affichage (`FinanceMath.roundedToCents`, aucun calcul modifié),
VoiceOver inchangé. Tests : contrat géométrique du ＋, non-troncature
par hauteur de rendu, extrêmes 320 pt ; tour Demo asserte l'absence
d'intersection ＋/contenu et le dernier élément visible après
défilement sur les 6 modules. L6 reste VERIFYING.

**Correctif L6, 2e passe (2026-07-24)** — second refus visuel : le ＋
recouvrait encore graphique Évolution, montant Loyer, texte Prévoyance
et une échéance Impôts dans l'ÉTAT INITIAL (contentMargins ne protège
que la fin de défilement, et le tour capturait avant de contrôler) →
`fix(l6)` : zone d'exclusion PERMANENTE (`padding(.bottom,
fabExclusionHeight = 80)` sur les 10 ScrollView — le viewport s'arrête
au-dessus du ＋, contentMargins conservé en simple marge de fin) ;
identifiants d'accessibilité (graphique Patrimoine, lignes financières,
texte info Prévoyance) ; tour Demo : assertion AVANT la première
capture puis après défilement complet (textes + boutons + images +
éléments identifiés, jamais isHittable), preuves nommées (Loyer,
Évolution, footer Prévoyance, dernière échéance/carte/contrat), 12
captures `-initial`/`-fin`. Acquis de la 1re passe conservés. L6 reste
VERIFYING.

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L5 (2026-07-23)

L5 « Mouvements et Comptes » exécuté (`/budget-v1 execute L5`) après
validation humaine de L4. PWA : groupes par jour, chips de filtres
aria-pressed, « neutre »/« mis de côté » écrits, états vides guidés,
réconciliation directe depuis le détail de compte (« Mettre le solde à
jour… »), fraîcheur datée. iOS : LazyVStack, StatusPill Prévu/Dette/
Archivé, AmountText, EmptyState, boutons visibles Dupliquer/Supprimer
dans la feuille d'édition (pas de swipe hors List),
TransactionDuplication.copy factorisé, fraîcheur au dernier mouvement.
Suites : 56 e2e + 5 parité + design verts ;
ObsidianMovementsAccountsTests (9 tests natifs, total 231 attendu) ;
12 captures PWA + README (`docs/obsidian-glass/movements-accounts/l5/`) ;
tour Demo 13 étapes. Formules, migrations, persistance : INCHANGÉES.
**L5 = VERIFYING**, L6 = BLOCKED.

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L4 (2026-07-23)

L4 « Pilote iOS » exécuté (`/budget-v1 execute L4`) après validation
humaine de L3 (CI #173, run 30028514793). Trois écrans natifs refondus
avec les fondations L2, uniquement eux : **HomeTab** (héros « Argent
disponible » `AmountText` + jours restants secondaires + action
universelle `PrimaryActionButtonStyle`, 4 métriques Entré/Dépensé/À
payer/Mis de côté — « À payer » = `HomePilotDisplay.toPay`, somme
d'affichage testée de composantes existantes de `MonthlySnapshotService`
—, UNE priorité mise en avant avec pill, le reste dans « À faire »),
**BudgetTab** (`StatusPill` Dans le plan/À surveiller/Dépassé, « X % du
budget utilisé » écrit, barre plan/réel, lignes « réel/planifié » avec
pills — `BudgetVarianceService` intact), **TransactionFormView** (ordre
pilote, montant focalisé `decimalPad`, statut natif conservé, résumé
virement/épargne, intitulé facultatif défaut = catégorie injecté côté
vue, `TransactionValidationService` byte-identique, Enregistrer en barre
de navigation). `ObsidianPilotTests` (8 tests : agrégat À payer,
résultats financiers inchangés, persistance contexte neuf, erreur
récupérable, virement neutre, extrême, 320 pt/a11y/transparence
réduite) + 8 previews déterministes + 12e étape du tour Demo
(« Nouveau mouvement »). PWA, formules, modèles, migrations,
sauvegardes : INCHANGÉS. **L4 = VERIFYING** (CI + workflow Demo +
validation humaine), lot suivant BLOCKED.

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L3 (2026-07-23)

L3 « Pilote PWA » exécuté (`/budget-v1 execute L3`) après validation
humaine de L2 (CI #172 verte, run 30021212918). Trois parcours refondus,
uniquement eux : **Mois** (premier viewport au contrat — héros « Argent
disponible » dominant avec action universelle, 4 métriques Entré/Dépensé/
À payer/Mis de côté depuis les agrégats existants de `snapshot()`,
priorité multi-ligne jamais tronquée, zone de sécurité FAB à 320 px),
**Budget** (« X % du budget utilisé » en toutes lettres + pill Dans le
plan/À surveiller/Dépassé + badges textuels par catégorie + « Pas encore
classé » expliqué — `budgetReport()` intact), **Ajouter un mouvement**
(chips de type tactiles sur le `#fType` historique, montant d'abord avec
devise du compte, statut Prévu/Comptabilisé expliqué (logique inchangée),
intitulé facultatif replié, erreur près du champ avec `aria-invalid` et
saisie conservée, résumé de virement neutre, Enregistrer sticky sous
clavier, fermeture après sauvegarde seule). Suite e2e portée à **53
parcours verts** (48 conservés + 5 pilote L3), 5 parité ✓, design
system ✓, zéro erreur console ; 11 captures + README dans
`docs/obsidian-glass/pilot/l3/` (comparées à la baseline L1). Aucune
formule financière, migration, clé localStorage, route ni ligne Swift
modifiée ; service worker inchangé. **L3 = VERIFYING** (validation
humaine des parcours et captures), **L4 = BLOCKED**.

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L2 (2026-07-23)

L2 « Fondations Obsidian » exécuté (`/budget-v1 execute L2`, ADR-022) :
identité sombre UNIQUE livrée par tokens canoniques + alias (PWA `:root` et
`DesignTokens.swift`) — les ex-teintes teal/cyan/violet/bleu électrique ne
sont plus que des alias de `brand`/`brandBright` ; `S.theme` préservé dans
les sauvegardes mais sans effet, sélecteur d'apparence retiré ; sombre posé
à la racine iOS. Primitives : cartes verre (28/22/14, fallback opaque
déterministe web `data-reduced-transparency` / SwiftUI
`obsidianForcedReducedTransparency`), montants jamais tronqués
(`AmountText`, clamp web), `StatusPill`/`.pill` (jamais couleur seule),
boutons 44 pt blanc-AA sur `brandDeep` #6457F0 (5.04:1), feuilles, états
vide/erreur, focus-visible global. Galeries déterministes hors navigation
(web + previews natives + argument `-obsidianGallery`). Tests : nouveau
`design.test.mjs` en CI (tokens+parité, 11 contrastes AA mesurés, 320/390,
44 px, clavier, reduced motion/transparency, zéro erreur console),
`DesignSystemTests` natifs, Test 29 e2e réécrit (identité unique). Local :
48 e2e + 5 parité + design verts ; captures
`docs/obsidian-glass/foundations/l2/` + README. Écrans, formules
financières, données et service worker inchangés. **L2 = VERIFYING**
(validation humaine composants/captures + preuve native visuelle au
pilote L4), **L3 = BLOCKED**.

## Branche `refonte/budget-obsidian-glass-v1` — Obsidian Glass L1 (2026-07-23)

L1 « Vérité, baseline et P0 » exécuté (`/budget-v1 execute L1`), puis passe
corrective `fix(l1)` après contrôle humain : la première passe ne compilait
pas côté iOS (4 `try` manquants sur `Optional.map(decimal)`, run CI 167
rouge). Corrections : restauration native en UNE transaction
(wipe+rebuild+save, rollback sur toute erreur, fichiers de documents jamais
touchés) avec tests renforcés (champ obligatoire/optionnel/entité tardive
corrompus, comptages complets, store persistant vérifié via contexte neuf) ;
PWA : `stampTx()` unique (création ET édition, purge avant recalcul, repli
1:1 explicite) + migration additive `stampAllTransactions` au chargement,
persistée immédiatement (ADR-021, e2e 38-43) ; CI déclenchée sur `refonte/**`
avec vérification déterministe de `PrivacyInfo.xcprivacy` dans le produit
Release (plutil + derivedDataPath connu, échec sinon) ;
`APP_STORE_LISTING.md` corrigé (`ch.budgetapp.Budget` canonique,
URLs = RELEASE_BLOCKER humain) ; captures baseline versionnées dans
`docs/obsidian-glass/baseline/l1/`. Micro-clôture `test(l1)` (fe374f6) :
la couverture transactionnelle de restauration compte les **18 modèles
persistants** (HouseholdMember et ImportBatch ajoutés au comptage,
sentinelles survivant au rollback vérifiées par identifiant).
**L1 = DONE, L2 = READY.** Preuves CI : run 167 échec constaté →
run 168 vert (48 e2e + 5 parité, build Debug, 206 tests iOS 0 échec,
build Release, « PrivacyInfo.xcprivacy présent et valide dans
Budget.app ✓ ») → run 170 vert (idem, 206 tests, BackupServiceTests
passed) — liens dans `OBSIDIAN_GLASS_STATUS.md`. Risques humains
ouverts : branche GitHub par défaut obsolète, URLs support/
confidentialité `VOTRE-DOMAINE`, configuration GitHub Pages. Prochaine
étape : `/budget-v1 execute L2` (fondations, sans refonte d'écrans).

## Branche `codex/budget-leader-refonte` (2026-07-22)

Créée et publiée depuis l'état vérifié de `claude/budget-project-connection-link-mhaokm`
(la branche Codex locale du même nom n'a jamais atteint GitHub — ADR-019).
CI activée sur `codex/**`. Lots livrés ici, un commit chacun, suites vertes :

- Import CSV : vraie confirmation avant toute écriture (résumé
  prêtes/doublons/invalides ; annuler n'écrit rien) — texte honnête (A04-N4).
- Apparence « Système » : Clair → Sombre → Système (suit l'appareil en
  direct via prefers-color-scheme), persistée ; clair reste le défaut.
- Anneau plan/réel sur le héros Budget (indigo / ambre ≥85 % / rouge >100 %,
  pourcentage au centre, aria-label), vérifié par captures clair/sombre.

État : refonte Horizon PWA R1→R7 livrée (skill budget-horizon installé,
8 références + 13 images) : design system vivant (pastilles teintées,
teal, tactile, entrée d'écran), écran « Mois » au blueprint (courbe
6 mois, budget restant, objectif prioritaire), hub Plus par intentions,
widgets personnalisables persistés, fraîcheur des soldes, composition
du patrimoine, bienvenue réécrite + objectif optionnel, Assistant local
déterministe. 42 parcours e2e + 5 fixtures de parité verts, zéro erreur
console. **CI 18/18 verte sur la branche (runs 143→160)** — chaque commit
de la refonte a passé e2e web + parité + build/tests iOS + Release.
**Natif : R8 ✓ (tokens teal + BudgetTint, run 162 vert) et R9 étape 1 ✓
(pastilles teintées dans la liste des mouvements, run 163 vert)** —
build + ~190 tests + Release à chaque commit. Pages : bascule vers cette
branche committée (9b12f24) mais le déploiement échoue — l'environnement
github-pages doit autoriser la branche (Settings → Environments →
github-pages → Deployment branches). Reste : lot K durcissement (audit
final), R9 finitions éventuelles, retrait contrôlé (rien identifié).
CI GitHub Actions : **7/7 runs verts sur la branche (143→149)** — web e2e +
parité + build/tests iOS macOS + Release à chaque commit ; tous les
constats d'audit (P0/P1/NITs) sont soldés. Reste : G02 (effort dédié),
QA humaine iPhone, TestFlight/prix.

## Programme Horizon — Budget Leader Refonte (2026-07-21)

Exécuté sur `claude/budget-project-connection-link-mhaokm` (la branche
`codex/budget-leader-refonte` n'existe pas — ADR-019). Lots L0→L8 web
livrés, un commit par lot, 38 parcours e2e + 4 fixtures de parité verts :

- **L1** thème clair par défaut « Swiss calm fintech » + sombre premium
  (tokens, bascule persistée dans Réglages, contrastes vérifiés sur
  captures 390/320 px, zéro débordement horizontal).
- **L2** recommandation du mois sur l'accueil (une seule priorité :
  rattrapage > facture en retard > réserve d'impôts > dépassement >
  objectif). **L3** comparaison au coût de la vie du mois précédent
  (Budget + accueil). **L4** parité dette D04 alignée sur ADR-016.
  **L5** « Charges de l'année » sur Factures + provision de lissage.
  **L6** scénario ＋50/mois et calcul expliqué sur chaque objectif.
- Précédé le même jour par : jalons J1/J2 du programme master-evolution
  (audits soldés — 3 P0 dont 2 pertes de données, langage « 10 ans »,
  accueil essentiel, menu Plus regroupé) et moteur G01 en centimes
  entiers. Voir BUDGET_MASTER_STATUS.md et AUDIT_COMPLET_BUDGET_2026-07-21.md.
- Reste (natif) : reprendre les tokens Horizon dans DesignTokens.swift
  (lot dédié, vérifié par la CI macOS) ; G02 migration stockage centimes.

Last updated: 2026-07-19
Current branch: claude/execute-tbkhsd
Current phase: Phases 0 à 12 terminées — prochaine : Phase 13 (Polish produit)
Invocation mode: build (session Claude Code sur Linux, vérification via CI GitHub Actions)

## Product goal (confirmé par l'utilisateur, 2026-07-19)

1. **Court terme** : usage personnel par l'utilisateur sur son propre iPhone (via TestFlight dès qu'un compte Apple Developer existe).
2. **Moyen terme** : publication sur l'App Store pour la **vendre** — la Phase 14 (release) devra inclure le choix du modèle de prix (app payante vs achat intégré), les métadonnées store et la conformité App Review.

## Product state

- App launches: phases 0-11 compilées et testées en CI GitHub Actions (dernier run vert : 29704772603)
- Persistence: SwiftData, schéma versionné V8 (`BudgetSchemaV8` : + FinancialDocument/ImportBatch, + importBatchID), migrations légères V1→…→V8 (ADR-006..012)
- Demo data: `DemoDataFactory` — mode démo isolé + previews déterministes (date fixe 15.06.2026)
- Onboarding: flux complet 5 étapes (confidentialité, ménage, canton, taux d'impôts 30 %, premier compte) + catégories suisses par défaut
- Accounts: liste groupée, détail, formulaire, réconciliation horodatée, archivage, flags cash/patrimoine, solde dérivé
- Transactions: 9 types, validation typée FR, virements internes atomiques et neutres, liste avec mois/recherche/filtres/file non catégorisée, dupliquer/supprimer
- Dashboard: `MonthlySnapshotService` (pur, calendrier + « now » injectés), montant vraiment disponible avec décomposition, budget quotidien, 4 cartes, graphique 6 mois (Swift Charts) avec résumé accessible, 3 actions prioritaires, mouvements récents
- Budget: onglet complet — lignes par catégorie (groupes essentiel/discrétionnaire/épargne/impôts), planifié vs réel avec badge de dépassement, section « Hors budget » (réconciliation totale), copie du mois précédent, grille annuelle 12 mois, graphique dashboard budget-vs-réel avec fallback 6 mois
- Recurring/subscriptions: entité unique (charges/revenus/abonnements), occurrences par multiples d'ancre sans dérive, dédup prévision/réel par recurringID, équivalents mensuel/annualisé, échéances de résiliation (badge + action prioritaire), section « À venir ce mois » avec comptabilisation en un geste, liste + formulaire complets (ADR-007)
- Taxes: module complet — TaxProfile (taux, source de vérité, seedé depuis Household), TaxProvision par année (réserve, arriérés, override, échéances), états dérivés toujours réconciliés (estimé = payé + dû), écran avec hypothèses visibles + disclaimer, échéances en action prioritaire du dashboard (ADR-008)
- Goals: onglet complet — types suisses (fonds d'urgence, 3a, voyage…), progrès via compte lié ou montant manuel, contribution mensuelle requise vs prévue, statuts En bonne voie/À accélérer/Échéance dépassée/Atteint (célébration sobre), projection au rythme prévu, action prioritaire dashboard (ADR-009)
- Insurance/pension: registre de contrats (prime + fréquence réelle, équivalents annuel/mensuel réconciliés, franchise, renouvellement, délais de résiliation à 60 j) ; prévoyance par piliers 1/2/3a/3b (valeurs des relevés officiels, contributions, projections des institutions jamais présentées comme garanties, somme partielle refusée) (ADR-010)
- Net worth: écran Patrimoine complet — décomposition réconciliée (comptes signés + actifs + prévoyance − dettes stockées positives), toggles d'inclusion respectés partout, instantané quotidien automatique, courbe de tendance Swift Charts avec résumé accessible, CRUD actifs/dettes (ADR-011)
- Import/export: wizard CSV Notion complet (détection délimiteur/en-têtes, mappage corrigeable, parsing dates/montants suisses, états ready/doublon/invalide, empreintes SHA-256 → ré-import 0 doublon, catégories créées uniquement sur confirmation, rapport réconcilié + file de réparation avec texte brut, rollback de lot) ; export en Phase 12 (ADR-012)
- Documents: registre local — fichiers copiés dans le conteneur protégé (completeFileProtection) via protocole DocumentFileStoring (impl réelle + fake), métadonnées typées, partage ShareLink, suppression fichier+métadonnées
- Security: verrouillage Face ID/Touch ID derrière protocole (activation/désactivation authentifiées, verrouillage au passage en arrière-plan, annulation = reste verrouillé), export CSV machine-stable, sauvegarde JSON complète versionnée (montants en String, relations par UUID), restauration avec confirmation destructive et rejet des schémas plus récents, suppression totale à double confirmation (données + fichiers), écrans Confidentialité et Méthodologie conformes à l'implémentation (ADR-013)
- Release readiness: non commencé

## Current acceptance criteria (Phases 0-10)

- [x] Phase 0 : fondation compilable en principe (projet Xcode 16, thème, formatage fr-CH, modèles, démo, tests)
- [x] Phase 1 : un nouvel utilisateur crée un profil local valide et retombe dans l'app au relancement (test de persistance inclus)
- [x] Phase 2 : types de comptes multiples, formatage CHF, soldes persistants, archivage sans perte d'historique
- [x] Phase 3 : tests de neutralité des virements et de rejets de transactions invalides ; liste gère vide et volume
- [x] Phase 4 : toutes les valeurs du dashboard dérivent des données persistées via des tests d'invariants
- [x] Phase 5 : planifié et réel restent séparés ; toutes les variances se réconcilient (tests) ; copie de mois sans doublons ; grille annuelle
- [x] Phase 6 : toute charge active apparaît exactement une fois dans les prévisions du mois ; les inactives jamais (tests d'échéancier + dédup) — CI verte (run 29702260574)
- [x] Phase 7 : tous les états fiscaux se réconcilient (estimé = payé + dû, tests) et les hypothèses sont visibles à l'écran
- [x] Build + tests des phases 0-4 validés sur Mac par l'utilisateur (« Ça fonctionne ✓ »)
- [x] Build + 82 tests de la phase 5 VERTS en CI GitHub Actions (run 29701802089)
- [x] CI verte sur la phase 7 (run 29702569987)
- [x] Phase 8 : contribution requise et bords cible-zéro/date passée sûrs (tests) — CI verte (run 29702937482)
- [x] Phase 9 : équivalents annuel/mensuel et totaux de prévoyance se réconcilient (tests) — CI verte (run 29703182761)
- [x] Phase 10 : neutralité des virements, signes des dettes et toggles inclus/exclus corrects (tests) — CI verte (run 29704249404)
- [x] Phase 11 : un ré-import ne duplique jamais ; chaque ligne rejetée est visible avec sa raison (tests) — CI verte (run 29704772603)
- [x] Phase 12 : états de verrouillage, annulation, version de restauration et confirmations destructives corrects (tests) — run 29704984445 rouge (l'API batch `context.delete(model:)` est incompatible avec les règles `.deny` de Account), corrigé par des suppressions individuelles dans `BackupService.deleteAll` — CI verte (run 29705302551)

- [x] Phase 13 : perf (un seul calcul de snapshot/rapport par rendu, préfiltre annuel), mode clair/mouvement réduit/a11y, checklist QA manuelle ; audit par agent → 1 bloqueur corrigé (la restauration effaçait définitivement les fichiers de documents, ADR-014) + restauration transactionnelle avec rollback, round-trip complet (ImportBatch, employmentStatus, updatedAt), voile de confidentialité dans le sélecteur d'apps, contraste carte impôts en mode clair — CI verte (runs 29705322894 puis 29705497072, ~168 tests)

- [x] Phase 14 : paquet App Store préparé sans publication — icône 1024 générée (monogramme B, identité verre sombre) et câblée dans AppIcon.appiconset, écran de lancement généré (clé INFOPLIST déjà en place), APP_STORE_LISTING.md (nom/sous-titre, description fr-CH, mots-clés, nutrition de confidentialité « aucune donnée collectée », storyboard des 6 captures en mode démo, placeholders support/confidentialité, recommandation de prix CHF 6.00 à l'achat), vérification d'archive = étape Build Release ajoutée à la CI — CI verte (run 29705804198 : suite complète + build Release sans erreur)

- [x] Le tour simulateur a attrapé un crash au premier lancement sur store disque (plan de migration étagé avec empreintes identiques → SIGABRT) — plan retiré, migration légère automatique (ADR-015)
- [x] Workflow Demo VERT (run 29724935362) : la vraie app démarre dans le simulateur, tour complet des 9 écrans capturé (captures + vidéo + .ipa non signée dans l'artefact « budget-demo ») ; CI verte sur le correctif (run 29724933695)
- [ ] Dérouler MANUAL_QA_CHECKLIST.md sur un appareil réel
- [ ] Décision de prix à valider par l'utilisateur (recommandation : CHF 6.00 à l'achat, sans IAP — APP_STORE_LISTING.md)

## Build and test evidence

- CI GitHub Actions (`.github/workflows/ci.yml`, runner macos-15, simulateur iPhone 16) : build + `xcodebuild test` à chaque push.
- **Derniers runs verts** : phases 5→14 (dernier : 29705804198, paquet App Store) — build Debug + Release OK, suite complète (~168 tests) sans échec.
  https://github.com/Mendestrading21/Budget-/actions
- Historique : le run 29701528788 (rouge) a attrapé un vrai bug SwiftData dans les données de démo (mouvements futurs persistés via le graphe de relations), corrigé en `5f22ec4`.
- Reste à vérifier sur appareil : la migration V1→V8 par-dessus un store réel existant, et le parcours manuel complet (la CI ne couvre que build + tests unitaires).

## Decisions made

Voir DECISION_LOG.md (ADR-001 à ADR-018). Convention patrimoine : soldes signés, un compte de dette (carte, prêt, hypothèque) porte un solde négatif.

## Audit externe soldé (2026-07-20, skill budget-production-completion)

Un audit tiers a été vérifié contre le code puis corrigé en P0→P2,
un commit par correctif, CI verte à chaque étape :

- **Natif** : `.debtPayment` transfer-like — cash et dette bougent
  ensemble, fortune neutre (ADR-016, `DebtPaymentTests`) ; plus aucun
  `try? modelContext.save()` — `saveOrRollback` + alerte utilisateur ;
  réserve d'impôts UNIFIÉE accueil↔module via
  `TaxService.monthReserveGap` (ADR-018, `UnifiedTaxReserveTests`) ;
  V1 mono-devise CHF avec garde à la restauration (ADR-017) ;
  ＋ universel flottant, onglet « Mouvements » dans la barre (Objectifs
  → Plus), actions prioritaires → formulaires préremplis.
- **Web** : `openTxSheet` réparé (P0 bloquant), impôts par année/statut,
  suppression scindée (opérations vs réinitialisation complète),
  confidentialité honnête, cockpit unique Accueil, onglet Mouvements —
  détail dans `webapp/AUDIT_W1.md`.
- **Tests** : suite navigateur réelle `webapp/tests/e2e.test.mjs`
  (Chromium, 12 parcours, zéro erreur console) exécutée par le nouveau
  job CI `web-tests` ; suite native enrichie (dette, réserve unifiée,
  garde devise).

## Known risks or blockers

- Migration V1→V8 : à valider sur un simulateur/appareil contenant déjà des données réelles (aucune perte attendue, changements additifs).
- Filtres et rapports calculés en mémoire (volumes V1 acceptables) — indexation/#Predicate à revisiter en Phase 13 (performance).

## Vague produit post-audit (2026-07-20, après-midi)

L'app web est devenue LE produit utilisable aujourd'hui, installée sur
l'iPhone de l'utilisateur :

- **Distribution** : PWA sur GitHub Pages
  (https://mendestrading21.github.io/Budget-/) — workflow `pages.yml`
  auto-déployé à chaque évolution de `webapp/` ; icône d'app, plein
  écran, service worker hors-ligne (réseau d'abord, cache en secours).
- **Première ouverture** : écran de bienvenue 4 étapes (prénom, devise
  de référence CHF/EUR/USD, salaire facultatif, compte principal) — la
  démo est un choix, plus jamais imposée ; « Réinitialiser
  complètement » ramène à la bienvenue.
- **Rituel « Check du mois »** : carte de progression (salaire,
  récurrents, factures validables d'un geste), « Mois bouclé »
  persistant et réversible, frise des 6 derniers mois. Porté en natif
  (RecurringScheduleService.monthCheck + carte HomeTab, dérivé pur).
- **Cumuls façon Finary** : contributions par compte de placement
  (versé année/total, retraits, perf. des comptes titres) — web ET
  natif (ContributionService + carte sur la fiche de compte) ;
  assurance vie (3b) suivie comme placement ; bilan « Versé cette
  année » et évolution 12 mois par classe dans Patrimoine ; échéances
  de contrats d'assurance avec alertes ≤ 45 jours sur l'Accueil.
- **Qualité** : second audit par agent → 23 correctifs (XSS échappé,
  ajustements cohérents, devise de référence partout, clavier complet,
  restauration d'état exhaustive) — zéro bouton mort vérifié (51 hooks
  ↔ 51 handlers). Suite navigateur : 18 parcours Chromium en CI (job
  `web-tests`) + suite native ~190 tests.

## Programme BUDGET 2027 (2026-07-20, soirée) — 20 lots livrés

Skill `.claude/skills/budget-2027/SKILL.md` exécuté de bout en bout,
un commit par lot, CI + Pages verts à chaque étape :

- **A. Marque** : logo original « le chemin du patrimoine » (SVG +
  icônes 1024/512/192/180), palette AA mesurée, épure (compteur animé,
  retour tactile, libellés raccourcis).
- **B. Public** : pays 🇨🇭🇫🇷🇧🇪 à la bienvenue (devise/impôts/
  vocabulaire), moteur de labels L() (3a ↔ PER ↔ épargne-pension),
  profils seul/couple/famille avec deux prénoms et deux salaires.
- **C. Chemin** : projection 5/10/20 ans (profils prudent/équilibré/
  ambitieux, Decimal itératif côté natif), objectifs projetés
  (« Atteint vers… », « ＋X/mois »), Année en revue, streak 🔥 +
  rattrapage des mois ouverts.
- **D. Comptes** : fiche de compte (courbe 12 mois, cumuls, historique),
  multi-revenus + moyenne 3 mois pour l'irrégulier, dettes vivantes
  (mensualité → décrément dérivé, fin projetée).
- **E. Simplicité** : bienvenue 5 écrans avec comptes en un tap, démo
  localisée par pays, guide « Comment ça marche » en 3 cartes.
- **F. Qualité** : suite navigateur à 22 parcours, audit agent final
  (zéro bouton mort sur 61 hooks ; 3 majeurs + 7 mineurs corrigés —
  commit b0eaac2), WealthProjectionService natif testé, ce bilan.

Validations humaines restantes : usage réel sur iPhone (seul juge du
produit), compte Apple Developer pour TestFlight/App Store, choix du
prix, et — avant tout lancement public FR/BE — une revue réglementaire
humaine des textes (l'app ne donne aucun conseil financier, mais la
formulation doit être validée par pays).

## Next exact action

Le code V1 est terminé (phases 0-14) et le pipeline TestFlight est prêt : `.github/workflows/testflight.yml` (déclenchement manuel, signature cloud via clé API App Store Connect, aucun Mac requis) + guide `TESTFLIGHT_SETUP.md` (100 % faisable depuis l'iPhone). Exemption de chiffrement déclarée (`ITSAppUsesNonExemptEncryption = NO`). Il reste ce qui exige un humain ou un compte Apple Developer (~99 $/an) :

**App web (skill /budget-web)** : W1-W4 livrées sur l'artifact unique — état persistant complet (localStorage), CRUD intégral (mouvements, comptes, budget par mois avec copie, objectifs liés aux comptes, récurrents avec « Comptabiliser », actifs/dettes, assurances, prévoyance, documents), import CSV réel avec empreintes et rollback, export CSV/JSON + restauration, impôts réglables, verrouillage par code, History API. Audit initial (5 BLOCKER dont un XSS et une perte de fortune sur l'épargne) intégralement soldé — webapp/AUDIT_W1.md. Source : webapp/index.html, vérifiée par suite headless Node à chaque phase.

En attendant le compte Apple, le workflow **Demo** (Actions → Demo → Run workflow, aucun secret) fait tourner la vraie app dans le simulateur iPhone via `BudgetUITests/DemoTourUITests` (argument de lancement `-demoTour` → mode démo in-memory) et livre l'artefact « budget-demo » : captures de chaque écran, vidéo du tour, .ipa non signée. La CI ordinaire saute les tests UI (`-skip-testing:BudgetUITests`).

1. Suivre TESTFLIGHT_SETUP.md : adhésion Apple Developer, App ID `ch.budgetapp.Budget`, fiche App Store Connect, clé API, 4 secrets GitHub, puis « Run workflow ».
2. Valider la décision de prix (APP_STORE_LISTING.md).
3. Sur appareil : MANUAL_QA_CHECKLIST.md + migration V1→V8 sur un store existant.
