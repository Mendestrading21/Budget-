// Outillage REPRODUCTIBLE de capture de la galerie Neon Ultra (NU1).
// Capture la galerie isolée (jamais l'app publique) à 390 et 320 px,
// plus texte agrandi 200 % (320), transparence réduite (390) et un
// gros plan des états (sélectionné / erreur / désactivé).
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome OUT=/dossier/sortie \
//     node .claude/skills/budget-neon-ultra/assets/tools/capture-nu1.mjs
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(
  path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));

const OUT = process.env.OUT || path.join(ROOT, "docs/neon-ultra/foundations/nu1");
fs.mkdirSync(OUT, { recursive: true });
const GALLERY_URL = "file://" + path.join(ROOT, "webapp/design-system/neon-ultra-gallery.html");

const browser = await chromium.launch({
  executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"],
});
let failures = 0;

async function capture(name, { width, fullPage = true, prepare, reducedMotion } = {}) {
  const context = await browser.newContext({
    viewport: { width, height: 844 },
    ...(reducedMotion ? { reducedMotion: "reduce" } : {}),
  });
  const page = await context.newPage();
  page.on("pageerror", e => { console.error(`PAGEERROR (${name}):`, e.message); failures++; });
  page.on("console", m => { if (m.type() === "error") { console.error(`CONSOLE (${name}):`, m.text()); failures++; } });
  await page.goto(GALLERY_URL);
  await page.waitForSelector("#nuSwatches .swatch");
  if (prepare) await prepare(page);
  await page.waitForTimeout(200);
  await page.screenshot({ path: path.join(OUT, `${name}.png`), fullPage });
  await context.close();
}

await capture("nu1-pwa-390", { width: 390 });
await capture("nu1-pwa-320", { width: 320 });
await capture("nu1-pwa-320-texte-200", {
  width: 320,
  prepare: page => page.click("#nuToggleLargeText"),
});
await capture("nu1-pwa-390-transparence-reduite", {
  width: 390,
  prepare: page => page.click("#nuToggleTransparency"),
});
await capture("nu1-pwa-390-reduced-motion", { width: 390, reducedMotion: true, fullPage: false });
// Gros plan des états : chips + champs (sélectionné, erreur, désactivé).
await capture("nu1-pwa-390-etats", {
  width: 390, fullPage: false,
  prepare: page => page.evaluate(() => {
    document.querySelector('.nu-chip[aria-pressed="true"]')
      .scrollIntoView({ block: "start" });
    window.scrollBy(0, -12);
  }),
});

await browser.close();
console.log(`Captures NU1 écrites dans ${OUT} — ${failures} erreur(s) console/page.`);
process.exit(failures ? 1 : 0);
