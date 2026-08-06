// Génération REPRODUCTIBLE des icônes de l'app aux couleurs Neon Ultra
// (ADR-024). Le dessin est décrit en SVG ci-dessous : c'est LUI la source,
// les PNG n'en sont qu'un rendu. Aucun outil externe, aucune dépendance :
// Chromium rend le SVG et on capture aux trois tailles utiles.
//
// Palette employée, strictement celle de la constitution :
//   canvas #05060A · surface #11141C · magenta #D946EF
//   violet #7C3AED · cyan #38BDF8
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome \
//     node .claude/skills/budget-neon-ultra/assets/tools/generer-icones.mjs
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(
  path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));
const OUT = process.env.OUT || path.join(ROOT, "webapp");

// LE DESSIN
//
// L'icône précédente était une courbe boursière en zigzag avec un point :
// l'héritage direct de « Mendestrading ». Sur l'App Store, c'est la
// première chose qu'un acheteur voit, et elle promettait la Bourse alors
// que le produit promet de savoir où passe son argent. Elle était aussi
// presque noire sur noir — invisible sur un fond d'écran sombre — et son
// trait fin disparaissait à 40 px.
//
// Le nouveau dessin est l'ANNEAU DU BUDGET : l'élément signature de
// l'application, celui qu'on voit sur l'écran Budget avec « 73 % utilisé ».
// Une icône qui EST le composant central du produit est cohérente par
// construction, et elle dit la bonne chose : voilà la part de ton mois
// déjà partie, voilà ce qui reste.
//
// Décisions de lisibilité, toutes vérifiables sur le rendu :
//   · anneau ÉPAIS (68/512, soit 13 % du côté) — un trait fin se perd ;
//   · rempli à ~72 %, jamais fermé : un cercle complet ne raconte rien,
//     et le vide restant est l'information ;
//   · la piste restante reste VISIBLE (#293040) — sans elle on ne peut pas
//     lire une proportion, seulement un arc ;
//   · fond légèrement remonté au centre (#171C28 → #05060A) pour que
//     l'icône ne se dissolve pas sur un fond d'écran noir ;
//   · aucun texte, aucun coin arrondi dessiné, aucune ombre portée :
//     iOS et Android appliquent leur masque et leur ombre eux-mêmes.
const SVG = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="fond" cx="50%" cy="42%" r="72%">
      <stop offset="0%" stop-color="#171C28"/>
      <stop offset="100%" stop-color="#05060A"/>
    </radialGradient>
    <!-- userSpaceOnUse, pas objectBoundingBox : c'est le seul moyen de
         savoir OÙ chaque couleur tombe. Avec le dégradé par défaut, le
         cyan atterrissait dans le coin haut-droit du cadre, exactement là
         où l'anneau est OUVERT — la couleur n'apparaissait nulle part.
         L'axe va du bas-droit (départ de l'arc) au haut-gauche (sa tête). -->
    <linearGradient id="arc" gradientUnits="userSpaceOnUse"
                    x1="392" y1="404" x2="120" y2="108">
      <stop offset="0%" stop-color="#6E00E8"/>
      <stop offset="38%" stop-color="#7C3AED"/>
      <stop offset="74%" stop-color="#D946EF"/>
      <stop offset="100%" stop-color="#38BDF8"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" fill="url(#fond)"/>
  <!-- Piste : ce qui RESTE. Sans elle, l'arc ne serait qu'une forme. -->
  <circle cx="256" cy="256" r="150" fill="none" stroke="#293040" stroke-width="68"/>
  <!-- Part consommée : 72 % du tour. L'ouverture est CENTRÉE EN HAUT
       (28 % = 100,8° → ±50,4° autour de midi), sinon elle penche et l'icône
       a l'air de travers. Rotation = -90° + 50,4° = -39,6°.
       2πr = 942,48 → 72 % = 678,6. Bouts ronds, comme l'anneau de l'app. -->
  <circle cx="256" cy="256" r="150" fill="none" stroke="url(#arc)" stroke-width="68"
          stroke-linecap="round" stroke-dasharray="678.6 942.48"
          transform="rotate(-39.6 256 256)"/>
</svg>`;

const browser = await chromium.launch({
  executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"],
});
// PWA et iOS partagent le MÊME dessin : sans ça les deux plateformes
// divergeraient dès la première retouche.
const CIBLES = [
  [512, path.join(OUT, "icon-512.png")],
  [192, path.join(OUT, "icon-192.png")],
  [180, path.join(OUT, "apple-touch-icon.png")],
  [1024, path.join(ROOT, "Budget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png")],
];
for (const [taille, cible] of CIBLES) {
  if (!fs.existsSync(path.dirname(cible))) { console.log(`ignoré (dossier absent) : ${cible}`); continue; }
  const context = await browser.newContext({ viewport: { width: taille, height: taille } });
  const page = await context.newPage();
  await page.setContent(
    `<body style="margin:0;background:#05060A">${SVG.replace('width="512" height="512"', `width="${taille}" height="${taille}"`)}</body>`);
  await page.waitForTimeout(120);
  await page.screenshot({ path: cible, omitBackground: false });
  console.log(`${path.relative(ROOT, cible)} — ${taille}×${taille}`);
  await context.close();
}
await browser.close();
