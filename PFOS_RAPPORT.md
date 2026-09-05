# Personal Finance OS — rapport final du programme (branche `agent/personal-finance-os-refactor`)

Rapport demandé par le prompt « PERSONAL FINANCE OPERATING SYSTEM »
(§73). Rien n'est fusionné, rien n'est publié, rien n'est poussé en
production : tout vit sur la branche, prêt pour la revue du
propriétaire.

## 1. L'audit d'abord — ce que le dépôt était déjà

Le prompt exigeait d'auditer avant de modifier. Verdict de l'audit :
l'application couvrait déjà ~80 % du périmètre demandé, souvent plus
strictement que le prompt lui-même :

- montants en centimes entiers (PWA) et `Decimal` (natif) — jamais un
  flottant pour l'argent ;
- multi-devise datée (les taux historiques ne réécrivent rien) ;
- scissions, remboursements, règles automatiques, détection de
  doublons, imports idempotents ;
- offline-first (IndexedDB + service worker), biométrie, écran de
  confidentialité, sauvegarde chiffrée (ADR-072) ;
- objectifs, patrimoine, abonnements, récurrents, prévisions séparées
  du réel ;
- schéma natif V14 figé (ADR-071) avec garde de version.

La transformation demandée s'est donc faite « en adaptant au dépôt »
(consigne du prompt) : sept lots réels, pas une réécriture.

## 2. Décisions propriétaire (posées et tranchées avant de coder)

| Question | Décision | Conséquence |
| --- | --- | --- |
| Thème clair ? | **Rester sombre unique** (ADR-024/074) | Aucun theming ajouté |
| Multilingue ? | **Français seul** (ADR-074) | Aucune i18n ajoutée |
| App Android native ? | **PWA seule** (ADR-073) | Pas de RN/Expo |
| Connexion bancaire ? | **Pas maintenant** | Aucun agrégateur, aucune simulation |

## 3. Les sept lots livrés

Chaque lot suit la même discipline : mesurer d'abord → test né rouge
(échecs nommés observés) → implémentation minimale → suite e2e complète
+ build + audits → captures 320/390 px réellement inspectées → commit →
deux sabotages qui mordent seuls (négatifs contrôlés) → restauration.

| Lot | Livré | Commit | Test | Sabotages |
| --- | --- | --- | --- | --- |
| P1 Enseigne | `tx.merchant` à part entière : saisie, édition, recherche au pli, « Top enseignes du mois » au Budget | `d8b5f42` | 242 | 2 ✓ |
| P2 Calendrier | Historique en vue calendrier : grille lundi-premier, points par famille, montants entiers au lecteur d'écran, journée ouverte | `7ca29e3` | 243 (né-rouge non observé, consigné ; sabotages font foi) | 2 ✓ |
| P3 Cash-flow | Gérer → Cash-flow : 7J/1M/3M/6M/1A, opérations PAYÉES seulement, entrées/sorties/net, régulières vs ponctuelles, courbe du net cumulé décrite | `98b1c39` | 244 | 2 ✓ |
| P4 Recherche globale | Gérer → Recherche : tous les mois, comptes, objectifs, ce qui revient, factures — au pli ; lignes tapables ; bornes écrites | `103cf61` | 245 | 2 ✓ |
| P5 Rappels | Gérer → Rappels : retards AVANT ce qui vient (30 j), sans double compte ; notifications locales opt-in honnêtes (« quand l'app est ouverte ») | `e1ee3ab` | 246 | 2 ✓ |
| P6 Constats | Assistant : « Quelle catégorie bouge ? » (mois vs moyenne réelle) et « Combien pèsent mes abonnements ? » (% des rentrées payées) — marqués « un constat, pas une prévision » | `2a2b209` | 247 | 2 ✓ |
| P7 Widget iOS | Extension WidgetKit « Mois en cours » (small/medium) : miroir horodaté du mois courant, centimes entiers, App Group, démo exclue, purge incluse | `279b9a6` | 6 tests XCTest | CI : voir §7 |

Le hub Gérer est passé de onze à quatorze lignes (Recherche, Rappels,
Cash-flow) — le test P07 du hub a été mis à jour à chaque lot, échec
nommé observé à chaque fois.

## 4. Architecture (inchangée, étendue)

- **PWA** : monofichier `webapp/index.html` (vanilla JS, CSP stricte,
  zéro dépendance runtime), état global versionné dans localStorage,
  IndexedDB pour les documents. Les lots P1–P6 = ~600 lignes ajoutées
  dans les conventions existantes (renderers `MORE_RENDERERS`, handler
  délégué, jetons CSS, Budget Glyphs).
- **Natif** : SwiftUI + SwiftData, schéma V14 FIGÉ — P7 n'ajoute AUCUN
  modèle persistant. Le pont widget est un JSON versionné en centimes
  entiers dans le conteneur App Group (`BudgetShared/`, compilé dans
  l'app et l'extension). `project.pbxproj` édité à la main (objets
  `BD6E…30-3D`), cohérence vérifiée par script.
- **Navigation** (ADR-026) : cinq destinations stables intactes ; les
  nouveaux écrans vivent sous Gérer.

## 5. Bibliothèques étudiées → rejetées (avec raison)

Le prompt suggérait une stack React Native/Expo. Consigne du prompt
lui-même : « ne remplace pas un projet natif existant par Expo ».

| Suggestion du prompt | Décision | Raison |
| --- | --- | --- |
| React Native / Expo | Rejeté | Deux apps finies existent (PWA + SwiftUI) ; réécrire = perdre 247 parcours prouvés |
| Reanimated / Skia | Rejeté | Animations natives SwiftUI + CSS suffisent ; budget « max 10 % néon » |
| FlashList | Rejeté | Pagination DOM ≤ 200 lignes déjà prouvée (10 000 mouvements) |
| Zustand / MMKV | Rejeté | État PWA existant versionné ; SwiftData natif |
| Victory / charts JS | Rejeté | SVG maison (cash-flow) + Swift Charts natifs |
| SQLite / WatermelonDB | Rejeté | SwiftData (V14 figé) + IndexedDB/localStorage |

## 6. Sécurité et honnêteté (interdits du prompt, tous respectés)

- Aucun mot de passe bancaire nulle part ; aucun scraping ; aucune
  simulation de connexion bancaire (décision propriétaire : « Pas
  maintenant » → rien, pas même une maquette).
- Données typées : posted/planned partout ; le Cash-flow et les
  Rappels écrivent leur périmètre à l'écran ; les constats P6 sont
  marqués « un constat, pas une prévision » ; le widget est horodaté.
- Jamais de faux chiffres : états vides honnêtes (« Rien trouvé »,
  « Rien à rappeler », widget « Ouvrez l'app ») ; l'aperçu de la
  galerie de widgets est étiqueté « Exemple ».
- Aucune clé API, aucun secret dans le dépôt ; notifications P5
  locales (aucun réseau) ; « Tout supprimer » efface aussi le miroir
  du widget.

## 7. Preuves

- **Suite e2e navigateur réel : 247 parcours verts, zéro erreur
  console** (156 → 247 sur la vie du dépôt ; +6 sur ce programme).
- Build TypeScript `--check` : artefact identique à l'octet près à
  chaque lot. Audits racine (confidentialité, threat model, MASVS,
  WCAG 2.2, schéma V14, catalogue d'identités) : verts à chaque lot.
- 12 sabotages ciblés (2 par lot P1–P6) : chacun a produit son échec
  NOMMÉ puis la restauration a rendu la suite verte.
- Captures 320/390 px inspectées :
  `docs/neon-ultra/budget-prisme/pfos-p1/ … pfos-p6/`.
- **iOS (P7)** : CI dispatchée sur le SHA exact `279b9a6` —
  run `33936007107` (build Debug + suite XCTest avec les 6 nouveaux
  tests + build Release + vérifications UIDeviceFamily/PrivacyInfo).
  Verdict consigné ci-dessous.

### Verdict CI (P7 et branche)

- Run `33936007107` (SHA `279b9a6`) : **job iOS VERT** — build Debug,
  suite XCTest complète (dont les 6 tests du widget), build Release,
  PrivacyInfo embarqué, `UIDeviceFamily == [1]`. La cible WidgetKit
  ajoutée à la main compile et s'embarque proprement.
- Le job web du même run a échoué sur la suite design (2 échecs
  nommés) : le calendrier P2 employait `var(--nu-cyan, #38BDF8)` et
  `var(--nu-violet)` hors des renderers pilotes — le programme n'avait
  jamais relancé `design.test.mjs` localement (leçon consignée :
  cette suite fait partie du protocole de lot). Corrigé (jetons
  Obsidian `--electric` / `--violet`), suite design verte, e2e 247
  verts. Nouveau run CI dispatché sur le SHA du correctif — verdict
  final consigné au journal de la branche.

## 8. Risques et ce qui exige une validation humaine

1. **App Groups / TestFlight** : la capacité App Groups
   (`group.ch.budgetapp.Budget`) doit exister sur l'App ID au moment de
   la signature réelle (signature automatique attendue). Sur simulateur
   et en CI (`CODE_SIGNING_ALLOWED=NO`), rien ne bloque. PENDING HUMAN.
2. **Widget sur iPhone réel** : l'ajout du widget, son rendu sur écran
   d'accueil, la mise à jour après un passage dans l'app — à constater
   physiquement. PENDING HUMAN.
3. **Notifications locales (P5)** : l'invite système et l'affichage
   réel sur appareil — à constater physiquement (le refus/blocage est
   géré et écrit à l'écran). PENDING HUMAN.
4. Le fichier du widget vit HORS du chiffrement de l'app (conteneur
   partagé, contenu = 4 totaux + libellé du mois). C'est inhérent aux
   widgets (leurs chiffres s'affichent sur l'écran d'accueil) ; la
   personne choisit en ajoutant le widget. Documenté, pas caché.
5. La fusion vers `main` et la publication restent des GESTES
   PROPRIÉTAIRE — rien n'a été fusionné ni publié depuis cette branche.

## 9. Prochain geste

Revue de la branche par le propriétaire, puis (s'il approuve) PR vers
`main` selon le protocole du dépôt (CI verte sur le HEAD exact, squash,
publication par dispatch au SHA).
