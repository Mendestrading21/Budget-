# Modules financiers Obsidian Glass — preuves L6 (PWA)

Captures de la VRAIE PWA rendue (`webapp/index.html`, Chromium headless,
`deviceScaleFactor: 2`) — jamais fabriquées. Données de démonstration
`seedState("CH")` (bannière « données fictives » visible). Date :
23.07.2026. Commit observé : le commit `feat(l6)` référencé dans
`OBSIDIAN_GLASS_STATUS.md` (branche `refonte/budget-obsidian-glass-v1`).

## Captures

| Fichier | Écran | État | Viewport | Accessibilité |
|---|---|---|---|---|
| `l6-390-factures-normal.png` | Factures | héros « Encore à payer », pill « 1 facture en retard » écrite, charges annuelles | 390×844 | — |
| `l6-390-factures-retard.png` | Factures | 2 factures en retard : pill au pluriel, section « En retard » | 390×844 | — |
| `l6-390-factures-vide.png` | Factures | aucune facture : `.empty-state` guidé + action | 390×844 | — |
| `l6-390-objectifs-normal.png` | Objectifs | pills écrites « À accélérer »/« En bonne voie »/« Prioritaire », réel ≠ scénario | 390×844 | — |
| `l6-390-objectifs-atteint.png` | Objectifs | objectif atteint : pill « Atteint », progression pleine | 390×844 | — |
| `l6-390-impots-normal.png` | Impôts | héros « — estimation », 4 stats distinctes (estimé/payé/réservé/reste), pill réserve | 390×844 | — |
| `l6-390-impots-incomplet.png` | Impôts | aucun revenu comptabilisé : carte « Estimation incomplète — rien n'est inventé » | 390×844 | — |
| `l6-390-patrimoine-normal.png` | Patrimoine | fortune nette, décomposition signée, composition accessible | 390×844 | — |
| `l6-390-patrimoine-negatif.png` | Patrimoine | dette dominante : héros NÉGATIF affiché honnêtement (signe + corail) | 390×844 | — |
| `l6-390-actifs-dettes.png` | Patrimoine (bas) | listes actifs et dettes, valeurs saisies, courbe 12 mois | 390×844 | — |
| `l6-390-assurances.png` | Assurances | héros équivalent mensuel + « par an » réconciliés, contrats | 390×844 | — |
| `l6-390-prevoyance.png` | Prévoyance | « Déjà constitué » (valeurs saisies, jamais calculées), position LPP avec projection DU CERTIFICAT | 390×844 | — |
| `l6-390-recurrents.png` | Récurrents | pills « Saisi ce mois » / « À venir » par ligne | 390×844 | — |
| `l6-320-impots.png` | Impôts | largeur étroite, zéro débordement | 320×844 | — |
| `l6-320-objectifs-texte-agrandi.png` | Objectifs | texte agrandi 130 % | 320×844 | `data-large-text` |
| `l6-390-patrimoine-transparence-reduite.png` | Patrimoine | surfaces graphite opaques | 390×844 | `data-reduced-transparency` |

## Méthode

Script Playwright (`playwright-core` + Chromium local), zéro erreur console
tolérée. États réels : démo semée par le VRAI parcours d'onboarding
(« Explorer avec des données d'exemple »), puis mutations temporaires en
mémoire (facture en retard, dette dominante, revenus retirés) restaurées
après chaque capture. Reproductible : Tests 52-55 de
`webapp/tests/e2e.test.mjs`.

## Comparaison avec le rendu précédent

- Factures : entrée directe dans les listes → héros « Encore à payer »
  qui répond d'abord à la question, retard ÉCRIT en pill (jamais couleur
  seule), « payé ce mois » séparé de l'ouvert, état vide guidé.
- Objectifs : états implicites (couleur de la barre) → pills écrites
  « Atteint / En bonne voie / À accélérer / Échéance passée ».
- Impôts : estimation présentée comme un chiffre → étiquetée
  « — estimation », et carte « Estimation incomplète » quand aucun revenu
  n'existe (avant : zéro silencieux qui ressemblait à un calcul).
- Patrimoine : héros sans contexte → caption de fraîcheur et de
  conversion explicite ; négatif désormais classé `neg` + signe.
- Assurances : liste seule → pill « Échéance dans N j » à ≤ 45 jours et
  carte « Déjà constitué » côté prévoyance, avec la SOURCE des valeurs.
- Récurrents : statut en texte gris → pill d'état par ligne.

## Hypothèses visibles (jamais cachées)

- Impôts : « Moyenne des N mois de revenus enregistrés × 12 × taux » est
  écrit sous l'estimation ; « Estimé = payé + encore dû, toujours » ;
  « pas un conseil fiscal ».
- Objectifs : « Le rythme réel vient de vos versements de l'année — une
  estimation, pas une promesse. »
- Patrimoine projeté : « … avec des hypothèses de rendement annualisées
  par classe — une simulation, jamais une promesse. »
- Prévoyance : « valeurs saisies, jamais calculées par l'app » ; « Selon
  certificat — jamais un calcul de l'app » ; aucune projection affichée
  pour une position dont le certificat n'en donne pas.

## Preuve native (iOS)

Le tour Demo asserté capture `06-objectifs`, `07-impots`,
`08-patrimoine`, `09-recurrents` et les NOUVELLES étapes
`14-assurances` + `15-prevoyance` — artefact `budget-demo` du run
référencé dans `OBSIDIAN_GLASS_STATUS.md`.

## Choix volontairement refusés

- Aucun barème fiscal officiel embarqué : l'app organise, elle ne taxe
  pas — l'estimation reste étiquetée et incomplète quand les données
  manquent.
- Aucun rendement inventé : pas de projection de prévoyance sans
  certificat, pas de somme partielle trompeuse (natif :
  `totalProjectedAtRetirement` rend nil si UNE position n'a pas de
  projection).
- Aucune promesse : simulations toujours étiquetées, jamais utilisées
  dans les totaux réels.
- Aucun double comptage : « Marquer payée » LIE la facture au mouvement
  créé (un seul mouvement) ; réservé / payé / dû restent trois nombres
  distincts qui se réconcilient.
- Intitulés longs encore tronqués dans certaines lignes : risque visuel
  NON bloquant conservé de L5, à traiter globalement (hors périmètre L6).
