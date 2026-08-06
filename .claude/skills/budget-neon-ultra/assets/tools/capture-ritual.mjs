// Outillage REPRODUCTIBLE de capture du RITUEL DU MOIS sur l'accueil :
// revenu attendu → encaissé, facture due → payée, tout réglé.
// Données 100 % FICTIVES et déterministes (foyer « Alex », jeu de démo).
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome OUT=/dossier \
//     node .claude/skills/budget-neon-ultra/assets/tools/capture-ritual.mjs
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(
  path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));
const OUT = process.env.OUT || path.join(ROOT, "docs/neon-ultra/features/month-ritual");
fs.mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch({
  executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"],
});
let failures = 0;

async function seeded(width) {
  const page = await (await browser.newContext({ viewport: { width, height: 844 } })).newPage();
  page.on("pageerror", e => { console.error("PAGEERROR :", e.message); failures++; });
  page.on("console", m => {
    if (m.type() === "error") { console.error("CONSOLE :", m.text()); failures++; }
  });
  page.on("dialog", d => d.accept());
  await page.goto("file://" + path.join(ROOT, "webapp/index.html"));
  await page.waitForSelector('[data-obcountry="CH"]');
  await page.click('[data-obcountry="CH"]');
  await page.click('[data-obhh="solo"]');
  await page.fill("#obName", "Alex");
  await page.click('#obForm1 button[type="submit"]');
  await page.fill("#obSalary", "5200");
  await page.click('#obForm2 button[type="submit"]');
  await page.waitForSelector("#obOpening", { state: "visible" });
  await page.fill("#obOpening", "3400");
  await page.click('#obForm3 button[type="submit"]');
  // Charges puis abonnements : deux écrans facultatifs, passés ici.
  await page.waitForSelector("#obFormCharges", { state: "visible" });
  await page.click("[data-obskipcharges]");
  await page.waitForSelector("#obFormSubs", { state: "visible" });
  await page.click("[data-obskipsubs]");
  await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await page.click('[data-obgoal="urgence"]');
  await page.waitForSelector("#tabbar button");
  await page.click('#tabbar button[aria-label="Gérer"]');
  await page.waitForTimeout(250);
  await page.click('#screen [data-more="settings"]');
  await page.waitForTimeout(250);
  await page.click("[data-resetdemo]");
  await page.waitForSelector("#tabbar button");
  await page.waitForTimeout(6500); // hygiène des toasts
  // Tout est dû aujourd'hui : on montre « Payer » et « ✓ Reçu ».
  await page.evaluate(() => { for (const r of RECURRINGS) r.day = 1; saveState(); render(); });
  await page.click('#tabbar button[aria-label="Mois"]');
  await page.waitForTimeout(400);
  return page;
}
const scrollTo = async (page, top) => {
  await page.evaluate(t => { document.getElementById("screen").scrollTop = t; }, top);
  await page.waitForTimeout(250);
};
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `${name}.png`) });

for (const width of [390, 320]) {
  const page = await seeded(width);
  await scrollTo(page, 300);
  await shot(page, `ritual-${width}-1-a-faire`);
  const recu = await page.$(".home-income-card .home-bill-action");
  if (recu) { await recu.click(); await page.waitForTimeout(500); }
  await scrollTo(page, 300);
  await shot(page, `ritual-${width}-2-salaire-recu`);
  for (let i = 0; i < 8; i++) {
    const b = await page.$(".home-bills-card .home-bill-action");
    if (!b) break;
    await b.click();
    await page.waitForTimeout(450);
  }
  await scrollTo(page, 300);
  await shot(page, `ritual-${width}-3-tout-regle`);
  await page.context().close();
}

await browser.close();
console.log(`Captures du rituel écrites dans ${OUT} — ${failures} erreur(s) console/page.`);
process.exit(failures ? 1 : 0);
