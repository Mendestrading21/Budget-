# L8 — Widgets, graphiques et micro-interactions (preuves, passe corrective)

Captures régénérées le 24.07.2026 (Chromium réel, deviceScaleFactor 2,
zéro erreur console, onboarding réel « Elio + Sara », aucun toast).

## Trois familles de preuves — jamais confondues

- **Preuves automatiques** : tests e2e 63-66 (scrubber, échelle,
  isolation, performance), tests unitaires `ObsidianMotionTests`,
  assertions géométriques du tour Demo. Elles tournent en CI.
- **Preuves visuelles** : les captures de ce dossier et les pièces
  jointes de l'artefact Demo (`ios-l8-*`). Elles se REGARDENT — un test
  qui construit une vue sans la regarder ne prouve pas son rendu.
- **Contrôle sur iPhone réel** (humain, consigné pour L9) : la vibration
  physique du retour haptique. Le simulateur et la CI prouvent le
  DÉCLENCHEUR (exactement un pas après un enregistrement réussi, zéro
  sur refus ou erreur), pas la sensation.

## Ce que montre chaque capture

| Fichier | Preuve |
| --- | --- |
| `l8-390-patrimoine-avant-selection.png` | État initial : invite dans la région live (déjà présente AVANT toute sélection), aucun marqueur, aucune sélection imposée. |
| `l8-390-patrimoine-selection.png` | Mois lu au scrubber : règle + point Indigo vif, étiquette `avril 2026 : CHF 2'000.00 de fortune nette` — la valeur vient de la série EXISTANTE. |
| `l8-390-compte-detail-selection.png` | Même patron sur la courbe du solde d'un compte : `avril 2026 : solde CHF 2'000.00`. |
| `l8-390-compte-negatif-constant-selection.png` | **Série CONSTANTE NÉGATIVE (−100)** : courbe centrée, règle et point VISIBLES, étiquette `juillet 2026 : solde -CHF 100.00` — le défaut d'échelle (coordonnées hors cadre) est corrigé et prouvé. L'anneau de focus du scrubber est visible (sélection au clavier). |
| `l8-320-patrimoine-selection.png` | 320 px : sélection au clavier (Fin), étiquette lisible, zéro débordement horizontal. |
| `l8-390-patrimoine-selection-transparence-reduite.png` | `data-reduced-transparency` : surfaces opaques, sélection intacte. |

## Le scrubber (PWA) — remplace les 12 boutons de la première livraison

- **Une seule surface interactive** `role="slider"` couvre toute la
  courbe : ~354 × 96-110 px à 390 px de large, ~284 px de large à
  320 px — **≥ 44 px dans les deux dimensions, mesuré par le test 63**.
  (La première livraison découpait 12 boutons de ~30 px de large :
  c'était en dessous de la cible minimale — corrigé.)
- **Glissement réel** : Pointer Events avec capture du pointeur —
  l'index suit le doigt PENDANT le geste (prouvé par le test 63 :
  valeur intermédiaire lue en cours de glissement). `touch-action:
  pan-y` laisse le défilement vertical au navigateur : aucun conflit.
- **Clavier** : flèches ← / → (mois précédent/suivant), Origine (Home)
  et Fin (End) ; focus visible (anneau `--brand-bright`) et conservé.
- **Annonce accessible** : `aria-valuemin/max/now` + `aria-valuetext`
  (« {mois} {année} : {montant} ») ; la région `aria-live="polite"`
  existe AVANT la sélection (invite) et est mise à jour EN PLACE —
  jamais recréée déjà remplie (prouvé : le nœud marqué reste le même).
- **Isolation** : la sélection d'un compte est stockée avec SON
  identifiant — un autre compte s'ouvre sur l'invite, jamais sur un
  mois hérité (test 65).
- Les mises à jour du marqueur, du slider et de l'étiquette sont
  CIBLÉES (aucun re-rendu complet pendant le geste). Valeurs affichées :
  TOUJOURS `series[i]` / `points[i]` déjà calculés pour la courbe.

## Échelle d'affichage sûre (`chartYScale`)

La marge est prise sur l'ÉTENDUE de la série, jamais en multipliant les
valeurs (l'ancien `min × 0.995 / max × 1.005` inversait les bornes d'une
série constante négative : douze mois à −100 sortaient du cadre).
Vérifié par tests unitaires en page (test 64) : constantes positives,
négatives, nulles, presque constantes, mixtes, extrêmes (±10¹²) — toutes
les coordonnées finies et dans le viewBox ; et par la capture négative
ci-dessus. Les valeurs financières ne sont jamais modifiées — seule leur
projection l'est.

## Mouvement sobre

- Aucune animation infinie ; l'état sélectionné est instantané.
- `prefers-reduced-motion` : garde existante vérifiée (test 65).
- Haptique natif : un seul `.sensoryFeedback(.success…)`, déclencheur
  extrait et testé (`hapticTriggerAdvances` : validation passée ET
  enregistrement réussi — sinon rien ; jamais pour une navigation, une
  suppression ou une sélection).

## Performance honnête (test 66, temps réels loggés en CI)

- 10 000 mouvements **répartis** sur douze mois PUIS **concentrés dans
  un seul mois** : rendu mesuré **jusqu'à la peinture** (double
  requestAnimationFrame), < 4 s exigé (mesuré : ~40 ms).
- **DOM borné par pages fixes de 200 lignes** même à 10 000 mouvements
  dans le mois. Rien de masqué en silence : l'en-tête donne le décompte
  TOTAL et le net du mois complet ; le bouton « Afficher X mouvements de
  plus (Y encore repliés sur Z) » annonce exactement le reste, page par
  page. Navigation de mois, recherche et défilement mesurés aussi.

## Côté natif

- **Sélection réellement parcourue** (tour Demo) : glissement réel sur
  `networth.chart.evolution`, étiquette `networth.chart.selectionLabel`
  au format suisse attendue et VÉRIFIÉE, valeur accessible de la courbe
  annonçant le mois et le montant choisis, captures
  `ios-l8-patrimoine-avant-selection` / `ios-l8-patrimoine-selection`
  dans l'artefact Demo. La dernière lecture reste AFFICHÉE quand le
  doigt se lève (même contrat que la PWA).
- **320 pt + accessibility3 + transparence réduite** : rendu RÉEL de
  l'écran sélectionné attaché à l'artefact Demo
  (`ios-l8-patrimoine-selection-320-a11y`, via
  `ObsidianMotionTests`) — preuve visuelle à inspecter ; les assertions
  automatiques garantissent que le rendu n'est pas vide, que l'étiquette
  passe à la ligne en tailles accessibilité (jamais tronquée) et que la
  sélection résout vers le véritable instantané le plus proche.
- **Zone d'exclusion du ＋** : restaurée sur TOUS les écrans défilants
  (Accueil, Mouvements, Budget, Comptes, détail de compte, budget
  annuel, année en revue — en plus des modules L6) ; `.clipped()`
  explicite en ceinture ; le tour Demo vérifie les rectangles réels du
  ＋ contre chaque élément visible à CHAQUE position intermédiaire du
  défilement, plus l'état sélectionné du graphique.

## Décision de périmètre (inchangée)

La personnalisation des widgets natifs (« éventuelle » dans
OBSIDIAN_GLASS_DELIVERY.md) n'est PAS ajoutée : la PWA possède déjà la
personnalisation de l'écran Mois, aucun besoin utilisateur validé ne
justifie une nouvelle surface de réglages native dans ce lot. Décision
consignée, réversible sur demande.
