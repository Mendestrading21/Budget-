// Outillage REPRODUCTIBLE de capture de baseline PWA (NU0).
// Parcourt l'onboarding avec des données 100 % fictives (Alex/Charlie),
// puis capture les écrans principaux à 390 px et 320 px.
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome OUT=/dossier/sortie \
//     node .claude/skills/budget-neon-ultra/assets/tools/capture-baseline.mjs
//
// Prérequis : playwright-core (déjà présent dans webapp/tests/node_modules).
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(
  path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));

const OUT = process.env.OUT || path.join(ROOT, "docs/neon-ultra/baseline/nu0");
fs.mkdirSync(OUT, { recursive: true });
const APP_URL = "file://" + path.join(ROOT, "webapp/index.html");

const browser = await chromium.launch({
  executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"],
});
let failures = 0;
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
page.on("pageerror", e => { console.error("PAGEERROR:", e.message); failures++; });
page.on("console", m => { if (m.type() === "error") { console.error("CONSOLE:", m.text()); failures++; } });
page.on("dialog", d => d.accept());

// Onboarding complet avec données fictives.
await page.goto(APP_URL);
await page.waitForSelector('[data-obcountry="CH"]');
await page.screenshot({ path: path.join(OUT, "pwa-390-onboarding-bienvenue.png") });
await page.click('[data-obcountry="CH"]');
await page.click('[data-obhh="couple"]');
await page.fill("#obName", "Alex");
await page.fill("#obPartner", "Charlie");
await page.click('#obForm1 button[type="submit"]');
await page.fill("#obSalary", "5000");
await page.click('#obForm2 button[type="submit"]');
await page.waitForTimeout(150);
await page.fill("#obSalary", "4000");
await page.click('#obForm2 button[type="submit"]');
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "1000");
await page.click('#obForm3 button[type="submit"]');
// Charges puis abonnements : deux écrans facultatifs, passés ici.
await page.waitForSelector("#obFormCharges", { state: "visible" });
await page.click("[data-obskipcharges]");
await page.waitForSelector("#obFormSubs", { state: "visible" });
await page.click("[data-obskipsubs]");
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button");
await page.waitForTimeout(6500); // hygiène des toasts

// Écrans principaux, aux deux largeurs contractuelles.
async function shoot(width) {
  await page.setViewportSize({ width, height: 844 });
  const go = async (label, nav) => {
    await nav();
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(OUT, `pwa-${width}-${label}.png`) });
  };
  await go("mois", () => page.click('#tabbar button[aria-label="Mois"]'));
  await go("budget", () => page.click('#tabbar button[aria-label="Budget"]'));
  await go("comptes", () => page.click('#tabbar button[aria-label="Comptes"]'));
  await go("plus", () => page.click('#tabbar button[aria-label="Plus"]'));
  await go("mouvements", async () => {
    await page.click('#tabbar button[aria-label="Plus"]');
    await page.waitForTimeout(150);
    await page.click('#screen [data-more="movements"]');
  });
  await go("ajouter", async () => {
    await page.click('#tabbar button[aria-label="Mois"]');
    await page.waitForTimeout(150);
    await page.click("#fab");
    await page.waitForSelector("#quickMenu", { state: "visible" });
  });
  await page.keyboard.press("Escape");
  await page.waitForTimeout(200);
}
await shoot(390);
await shoot(320);

await browser.close();
console.log(`Captures écrites dans ${OUT} — ${failures} erreur(s) console/page.`);
process.exit(failures ? 1 : 0);
