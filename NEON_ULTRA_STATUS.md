# Budget — Neon Ultra : état d'avancement

Programme actif (ADR-024) · branche `refonte/budget-neon-ultra-v1` · créée
depuis `26d186e8e31bbdf1bc41651afcaf7a1699988644` (dernier HEAD Obsidian à CI
verte prouvée — run CI #229 id 30221277893, success, jobs Web + iOS).

| Lot | Intitulé | État |
|---|---|---|
| NU0 | Gouvernance et baseline | **DONE** (validation définitive du propriétaire le 27.07.2026, CI #231 verte sur `828ea63`) |
| NU1 | Tokens et primitives | **DONE** (validation du propriétaire le 27.07.2026 sur `5796e3c`) |
| NU2 | Pilote PWA — Mois, Budget, Ajouter | **DONE** (validation du propriétaire le 27.07.2026 sur `ff029388`, publication Pages autorisée) |
| NU3 | Pilote SwiftUI équivalent | **READY** (non commencé) |
| NU4 | Mouvements, Comptes et shell | À VENIR |
| NU5 | Factures, Objectifs et Récurrents | À VENIR |
| NU6 | Patrimoine et graphiques | À VENIR |
| NU7 | Onboarding, confiance, réglages, identité | À VENIR |
| NU8 | Mouvement, accessibilité, performances | À VENIR |
| NU9 | Audit final | À VENIR |

## Correctif critique de fiabilité (29.07.2026) — VERIFYING

La poursuite visuelle reste gelée avant NU3 pendant la validation d'un lot
correctif transversal découvert par audit. Ce lot ne change pas la direction
Neon Ultra et ne clôt aucun lot visuel.

- dates futures centralisées : une date après aujourd'hui reste planifiée,
  y compris après import CSV et matérialisation d'une échéance, puis devient
  comptabilisée une seule fois le jour dû (chargement/rendu web et
  lancement/retour au premier plan iOS) ;
- factures et paiements réguliers liés au compte choisi, dédupliqués par
  échéance et conservant leur date réelle ;
- remboursements annuels comptés une seule fois ;
- accueil et écran Impôts alimentés par le même rapport fiscal annuel ;
- restauration PWA validée intégralement avant remplacement de l'état
  (collections secondaires, rapport d'import, IDs et relations), avec retour
  à l'ancien blob si l'écriture échoue ;
- historique multi-devise PWA estampillé avec sa devise et son taux source,
  sans repli silencieux 1:1 ; devise du compte et devise de référence
  verrouillées dès qu'un historique existe ;
- restauration native refusant avant purge les enums inconnus, UUID orphelins,
  identifiants dupliqués et montants illisibles ;
- mutations SwiftData sauvegardées avec rollback explicite en cas d'échec.

Les tests dédiés sont ajoutés au web et au natif. Validation locale web :
**86 parcours e2e** (78 conservés + 8 scénarios critiques), zéro erreur
console, et **5 fixtures de parité** vertes. L'état reste **VERIFYING**
jusqu'à réussite de la CI complète au SHA exact puis vérification du
déploiement GitHub Pages. **NU3 reste READY et non commencé.**

## NU2 — Pilote PWA : Mois, Budget, Ajouter, Nouveau mouvement (27.07.2026) — DONE

Quatre surfaces — et quatre seulement — portent désormais l'identité Neon
Ultra dans la PWA réelle : `renderHome()` (Mois), `renderBudget()` (Budget),
la feuille `#quickMenu` (Ajouter) et la feuille `#txForm`
(Nouveau mouvement). Le reste de l'app demeure Obsidian Glass.

### Stratégie d'isolation (le cœur du lot)

- `webapp/design-system/neon-ultra.css` est chargée **exactement une fois**
  depuis `index.html`. Chaque règle de production est enracinée dans
  `#screen.nu-pilot-screen` ou `.sheet.nu-pilot-sheet` — aucune ne peut
  atteindre un écran non piloté.
- `index.html` ne **déclare** aucun token `--nu-*` et ne contient **aucune**
  valeur brute Neon Ultra : les vues pilotes ne référencent que des rôles
  (`var(--nu-*)`). Le corps de production ne porte jamais `.nu-body`.
- Les modifications JavaScript se limitent au périmètre autorisé : une
  bascule de classe dans `render()` (Mois et Budget uniquement, hors
  onboarding et hors verrouillage) et la durée du compteur héros
  (`animateHeroAmount`, 200 ms, neutralisée sous mouvement réduit).
- Tous les tokens Obsidian d'`index.html` sont vérifiés **inchangés** par
  test, et le tableau BANNED historique reste intact.
- La vérification de clôture interdit désormais toute référence
  `var(--nu-*)` injectée hors des deux renderers pilotes. Elle ouvre aussi le
  détail Compte et mesure ses styles calculés : courbe Indigo et règle grise
  restent strictement Obsidian, sans classe pilote.

### Ce qui change à l'écran

- **Mois** : canvas `#05060A`, cartes de liste **mates** `#11141C` sans flou,
  héros seul en surface élevée `#181C26`, un **unique** point focal lumineux
  (CTA `#C000A4 → #6E00E8`, texte blanc dédié), aucun halo autour d'un
  montant, légendes remontées à 13 px.
- **Budget** : anneau et jauges plats, couleurs strictement sémantiques,
  état du plan toujours **écrit** (« Dans le plan » / « À surveiller » /
  « Dépassé »), planifié et réel jamais mélangés. L'état vide devient
  pédagogique : promesse, action unique, puis les trois étapes de
  « Comment ça marche ».
- **Ajouter** : feuille pilote opaque, huit destinations **strictement
  égales** entre elles (aucun faux point focal), cibles ≥ 44 px.
- **Nouveau mouvement** : le montant devient le champ dominant (20 px),
  les sept types sont des pastilles ≥ 44 px, l'intitulé est multiligne et
  reste entièrement lisible, le CTA « Enregistrer » est collant en pied,
  et le message d'erreur s'affiche **contre le champ fautif** (corail
  `#FF6577`, `aria-invalid`, focus déplacé).
- **Correctif d'accessibilité découvert par le lot** : la zone cliquable
  d'une facture (`.meta[role="button"]`) tombait à 29 px de haut à 320 px.
  Elle est ramenée à 44 px minimum dans la portée pilote.
- **Correctifs de clôture** : la cible repliable
  « Détails (facultatif) » mesure elle aussi au moins 44 px ; à 320 px, les
  montants héros, métriques et Budget s'adaptent aux polices système larges
  sans perdre un chiffre. Un Budget à sept chiffres réorganise son héros
  avant de réduire le montant.

### Preuves

- **Tests web** : 78 parcours e2e (72 conservés sans affaiblissement +
  **6 parcours NU2** : Mois piloté et isolation des écrans Obsidian, Budget
  vide puis chargé, ＋ → Ajouter → mouvement réellement enregistré au
  centime, erreur de formulaire, accessibilité 320 px / focus / mouvement
  réduit, HTTP + service worker + hors-ligne) · 5 fixtures de parité ·
  design system Obsidian **et** fondations NU1 **et** surfaces pilotes NU2
  verts · zéro erreur console. Le passage final mesure aussi tous les
  contrôles visibles du formulaire et inspecte le détail Compte.
- **HTTP, rechargement et hors-ligne** : serveur local réel, `sw.js` livré
  tel quel (aucune modification, nom de cache inchangé), page réellement
  **contrôlée** par le service worker, rechargement en ligne puis coupure
  réseau et vrai rechargement — l'app s'ouvre entière, les données du foyer
  survivent, `neon-ultra.css` est servie depuis le cache et parsée, le
  canvas, le héros et le CTA gardent leurs valeurs mesurées.
- **Captures** : `docs/neon-ultra/pilot/nu2/README.md` + **12 captures**
  générées par outillage reproductible sur données fictives et toutes
  réellement ouvertes (390, 320, montant extrême à sept chiffres, budget
  vide, menu Ajouter, formulaire, erreur, clavier simulé, texte 200 %,
  transparence réduite).
- **Non-régression financière** : aucune formule, conversion, validation,
  clé `localStorage`, structure de données ni destination de navigation
  n'est touchée — seules des règles de présentation et la bascule de classe
  changent.

### Limite connue, non corrigée par NU2

La PWA dimensionne ses textes en pixels (**P3-5**, ouverte depuis L9) : le
grossissement disponible est le zoom de page. La capture 200 % le reproduit
fidèlement plutôt que de simuler un mécanisme absent.

Validation du propriétaire reçue le **27.07.2026** sur
`ff029388d275798a98046a777e4f3389507c1399` : les quatre surfaces sont
acceptées et leur publication GitHub Pages est explicitement autorisée.
**NU2 est clos ; NU3 est autorisé mais n'est pas commencé.**

## NU1 — Tokens et primitives (27.07.2026) — DONE

Fondations Neon Ultra livrées en familles parallèles ISOLÉES (aucun écran
réel modifié ; la PWA publique et les écrans SwiftUI restent Obsidian
jusqu'à NU2/NU3) :

- **iOS** : `NeonUltraColor/Gradient/Radius/Motion/Typography` (ajout pur en
  fin de `DesignTokens.swift`), primitives `NeonUltraComponents.swift`
  (cartes mate/élevée, CTA gradient, secondaire, destructif sémantique,
  chip 3 états, badge ×4, montant sans glow via FinanceFormatting, focus
  cyan, résolveur Reduce Transparency → `#151923`),
  `NeonUltraComponentGallery.swift` (jamais reliée à la navigation ;
  harness `UIHostingController`), `BudgetTests/NeonUltraDesignSystemTests.swift`
  (**17 tests**, prouvés par CI : RGBA exacts, contrastes AA mesurés, CTA
  blanc pur 5,56/7,43, identité unique, sémantique ≠ marque,
  géométrie/mouvement, cibles tactiles MESURÉES ≥ 44×44 pt par rendu,
  Reduce Motion comportemental via `NeonUltraMotionResolver`, montant
  extrême, galerie 320/390/accessibility3/transparence réduite) —
  **276 tests iOS au total, 0 échec**.
- **PWA** : `webapp/design-system/neon-ultra.css` (variables `--nu-*`,
  valeurs brutes uniquement dans `:root`) + `neon-ultra-gallery.html`
  (seule page qui charge cette feuille). `webapp/index.html` : zéro octet
  modifié ; le tableau BANNED historique interdit toujours les teintes
  Neon Ultra dans l'app.
- **Tests web additifs** (`design.test.mjs` §NU1–NU9) : tokens exacts,
  isolation de l'app, parité Swift↔CSS (18 rôles + rayons + mouvement),
  contrastes complets (15 paires texte/surface + CTA + sémantique + focus),
  galerie 320/390, focus cyan ≥ 2 px, états sélectionné/erreur/désactivé,
  texte agrandi 200 %, reduced motion, transparence réduite opaque sans blur.
- **Preuves** : `docs/neon-ultra/foundations/nu1/README.md` + 7 captures
  inspectées (390, 320, 320@200 % — champ multiligne complet, transparence
  réduite, reduced motion, focus cyan réel, gros plan des états). Captures simulateur iOS : impossibles depuis cet
  environnement Linux — harness de test CI en attendant, PNG au plus tard
  avec NU3 (limitation documentée).
- **Inventaire d'identité** (manifest `#07090e`, theme-color `#090C12`,
  icônes PWA, AccentColor `#4B5CFF`, AppIcon) : consigné, AUCUNE
  modification — différé à NU7.

Validation du propriétaire reçue le **27.07.2026** sur
`5796e3c74bc44ae6a5f75c4e3e9f3eec526979ce` : NU1 est clos, NU2 autorisé.

## NU0 — Clôture (27.07.2026) — DONE

Validation propriétaire du contenu technique NU0 reçue, définitive après :

- **Image de référence intégrée** :
  `.claude/skills/budget-neon-ultra/assets/visual/neon-ultra-reference.jpeg`
  — reçue, copiée sous nom stable, décodage vérifié (JPEG valide,
  **736×1174 px**, 530 614 octets), réellement ouverte et inspectée.
  Éléments retenus : fond noir, profondeur graphite, éclairages
  magenta/violet/cyan, cartes superposées, énergie premium — aucun texte,
  personnage, nom, logo ni écran exact ne sera copié.
- **Correction AA du contrat** (mesures indépendantes reproduites) : texte
  discret `#747E8E` → **`#7C8696`** (l'ancien mesurait 4,49:1 / 4,15:1 /
  4,28:1 sur surface standard / élevée / fallback — sous AA ; le nouveau
  mesure canvas 5,50:1 · navigation 5,28:1 · surface standard 5,00:1 ·
  surface élevée 4,63:1 · fallback opaque 4,78:1). Constitution, résumé du
  skill et ADR-024 alignés.
- **Règle violet** ajoutée à la constitution : `#7C3AED` ≈ 3,41:1 sur la
  navigation — icônes grandes, bordures et indicateurs seulement, jamais
  seul pour un petit libellé actif (texte actif = `#F5F7FA` + indicateur
  violet, sauf paire mesurée ≥ 4,5:1).
- Aucun écran, token applicatif, rendu ni comportement modifiés ;
  `git diff --check` vert ; CI complète verte attendue sur le commit de
  clôture (rapportée en session).

## NU0 — Gouvernance et baseline (27.07.2026) — historique de la passe initiale

Livré (aucun écran, rendu, token ni logique modifiés) :

- **Skill** `.claude/skills/budget-neon-ultra/` : `SKILL.md` (plan / execute
  NU0–NU9 / continue / verify / prompt) + `NEON_ULTRA_CONSTITUTION.md`
  (palette et règles canoniques) + `NEON_ULTRA_DELIVERY.md` (10 lots) +
  `NEON_ULTRA_SCREEN_MATRIX.md` (écrans PWA/iOS + divergence navigation) +
  `REPOSITORY_CONTRACT.md` (protections, commandes, bases) +
  `REFERENCE_INDEX.md` + outillage reproductible de capture
  (`assets/tools/capture-baseline.mjs`).
- **ADR-024** (DECISION_LOG.md) : Neon Ultra remplace UNIQUEMENT les clauses
  visuelles d'ADR-020/022/CLAUDE.md/constitution Obsidian ; historique
  L0–L9 conservé tel quel, aucun rapport réécrit.
- **CLAUDE.md** aligné (programme actif, branche, autorités) ; **budget-v1**
  reçoit un bloc ROUTAGE (skill historique, ne plus l'invoquer).
- **Baseline prouvée** : `docs/neon-ultra/baseline/nu0/README.md` — 72 e2e ·
  5 parités · design system vert (contrastes mesurés) · 259 tests iOS,
  0 échec · builds Debug+Release SUCCEEDED · PrivacyInfo valide ·
  `UIDeviceFamily == [1]` · TARGETED_DEVICE_FAMILY = 1 (Debug+Release) ·
  zéro pageerror/erreur console · persistance disque
  (`DiskStoreLifecycleTests`) · sauvegarde/restauration
  (`BackupServiceTests` + e2e) · tests financiers nommés (FINANCIAL_AUDIT
  L9) · perf 10k mouvements (27–34 ms/peinture, DOM ≤ 200 lignes) ·
  13 captures PWA 390/320 générées et inspectées.
- **Divergence navigation documentée, NON réconciliée** : PWA 4 onglets +
  ＋ central (Mouvements dans Plus) vs iOS 5 onglets + ＋ flottant —
  décision produit séparée requise (baseline §5, matrice §1, ADR-024 §5).

### Inventaire de référence (HEAD source)

- PWA : `webapp/index.html` (≈ 305 Ko, app complète), `webapp/sw.js`,
  `webapp/manifest.webmanifest` (protégés hors lots visuels concernés).
- Tests web : `webapp/tests/e2e.test.mjs` (72 parcours),
  `webapp/tests/parity.test.mjs` (5 fixtures),
  `webapp/tests/design.test.mjs` (design system).
- iOS : `Budget/App/RootView.swift` (5 onglets + ＋ flottant),
  `Budget/Core/DesignSystem/DesignTokens.swift` + `GlassCard.swift` (tokens
  à faire évoluer en NU1), Features par onglet ; 259 tests
  (`BudgetTests`, dont `DiskStoreLifecycleTests`, `BackupServiceTests`,
  `AppLockManagerTests`, suites financières nommées).
- Workflows : `ci.yml` (Web + macOS iOS + contrôles produit), `demo.yml`
  (archive + IPA + captures simulateur en artefacts), `pages.yml`
  (déploiement Pages du propriétaire — sur la branche Obsidian, intouché).
- Fixtures : `fixtures/parity-fixtures.json` (protégées).

### En attente du propriétaire (HUMAN REQUIRED)

1. Décision produit navigation PWA/iOS (hors périmètre NU0–NU8) —
   divergence documentée, décision séparée en attente.
2. Héritage L9 inchangé : L9 Obsidian = VERIFYING (historique) ; QA iPhone
   réel, haptique, Face ID, VoiceOver physique, compte Apple/TestFlight —
   PENDING HUMAN.

### Prochaine action exacte

`/budget-neon-ultra execute NU3` — pilote SwiftUI équivalent, sans modifier
la navigation. La divergence de navigation PWA/iOS demeure une décision
produit séparée.
