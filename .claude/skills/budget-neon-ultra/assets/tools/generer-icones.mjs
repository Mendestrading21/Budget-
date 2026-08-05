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

// Le trait monte de gauche à droite avec un creux : la même forme
// reconnaissable qu'avant. Seule l'IDENTITÉ CHROMATIQUE change — le choix
// du symbole reste une décision du propriétaire.
const SVG = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="fond" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#11141C"/>
      <stop offset="100%" stop-color="#05060A"/>
    </linearGradient>
    <linearGradient id="trait" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0%" stop-color="#7C3AED"/>
      <stop offset="55%" stop-color="#D946EF"/>
      <stop offset="100%" stop-color="#38BDF8"/>
    </linearGradient>
  </defs>
  <!-- Pleine surface, SANS coin arrondi dessiné : iOS et Android appliquent
       déjà leur propre masque. Un arrondi en dur se verrait en double. -->
  <rect width="512" height="512" fill="url(#fond)"/>
  <path d="M 108 362 L 214 262 L 288 316 L 396 176"
        fill="none" stroke="url(#trait)" stroke-width="40"
        stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="396" cy="176" r="40" fill="#38BDF8"/>
  <circle cx="396" cy="176" r="17" fill="#F5F7FA"/>
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
