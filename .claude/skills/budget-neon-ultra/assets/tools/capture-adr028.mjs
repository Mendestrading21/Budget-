// Outillage REPRODUCTIBLE de capture des trois surfaces d'ADR-028 :
// page Année, écran Abonnements, tuiles d'accueil.
// Données 100 % FICTIVES et déterministes (foyer « Alex », jeu de
// démonstration de l'app + un abonnement annuel explicite).
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome OUT=/dossier \
//     node .claude/skills/budget-neon-ultra/assets/tools/capture-adr028.mjs
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(
  path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));

const OUT = process.env.OUT || path.join(ROOT, "docs/neon-ultra/features/adr-028");
fs.mkdirSync(OUT, { recursive: true });
const APP_URL = "file://" + path.join(ROOT, "webapp/index.html");

const browser = await chromium.launch({
  executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"],
});
let failures = 0;

async function seeded(width, height, opts = {}) {
  const context = await browser.newContext({
    viewport: { width, height },
    ...(opts.scale ? { deviceScaleFactor: opts.scale } : {}),
  });
  const page = await context.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR :", e.message); failures++; });
  page.on("console", m => {
    if (m.type() === "error") { console.error("CONSOLE :", m.text()); failures++; }
  });
  page.on("dialog", d => d.accept());
  await page.goto(APP_URL);
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
  await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await page.click('[data-obgoal="urgence"]');
  await page.waitForSelector("#tabbar button");
  await page.click('#tabbar button[aria-label="Gérer"]');
  await page.waitForTimeout(200);
  await page.click('#screen [data-more="settings"]');
  await page.waitForTimeout(250);
  await page.click("[data-resetdemo]");
  await page.waitForSelector("#tabbar button");
  await page.waitForTimeout(6500); // hygiène des toasts
  if (opts.months) {
    // Quelques mois bouclés et un mois négatif, pour montrer TOUS les états.
    await page.evaluate(() => {
      const mk = (m, d, type, amount, title) => ({
        id: ++txSeq, y: NOW.y, m, d, title, type,
        cat: type === "expense" ? "Logement" : null,
        acc: ACCOUNTS[0].id, dest: null, status: "posted", amount,
      });
      transactions.push(mk(1, 5, "income", 6000, "Salaire janvier"));
      transactions.push(mk(1, 8, "expense", 1500, "Loyer janvier"));
      transactions.push(mk(2, 5, "income", 4000, "Salaire février"));
      transactions.push(mk(2, 8, "expense", 5200, "Gros achat février"));
      S.monthChecks[`${NOW.y}-1`] = Date.now();
      saveState(); render();
    });
    await page.waitForTimeout(300);
  }
  if (opts.large) await page.evaluate(() => { document.documentElement.dataset.largeText = "true"; });
  return page;
}
const shot = async (page, name) => {
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
};
const openMore = async (page, view) => {
  await page.click('#tabbar button[aria-label="Gérer"]');
  await page.waitForTimeout(250);
  await page.click(`#screen [data-more="${view}"]`);
  await page.waitForTimeout(400);
};

// ---------- 390 : tuiles, Année (haut et liste), Abonnements ----------
{
  const page = await seeded(390, 844, { months: true });
  await page.click('#tabbar button[aria-label="Mois"]');
  await page.waitForTimeout(350);
  await page.evaluate(() => {
    const s = document.getElementById("screen");
    s.scrollTop = s.scrollHeight;
  });
  await shot(page, "adr028-390-accueil-tuiles");
  await openMore(page, "year");
  await shot(page, "adr028-390-annee-haut");
  await page.evaluate(() => {
    const s = document.getElementById("screen");
    s.scrollTop = s.scrollHeight * 0.45;
  });
  await shot(page, "adr028-390-annee-mois");
  await openMore(page, "subs");
  await shot(page, "adr028-390-abonnements");
  await page.context().close();
}

// ---------- 320 : le plancher supporté ----------
{
  const page = await seeded(320, 844, { months: true });
  await page.click('#tabbar button[aria-label="Mois"]');
  await page.waitForTimeout(350);
  await page.evaluate(() => {
    const s = document.getElementById("screen");
    s.scrollTop = s.scrollHeight;
  });
  await shot(page, "adr028-320-accueil-tuiles");
  await openMore(page, "year");
  await shot(page, "adr028-320-annee");
  await openMore(page, "subs");
  await shot(page, "adr028-320-abonnements");
  await page.context().close();
}

// ---------- 320 à 200 % de texte : aucune fonction perdue ----------
{
  const page = await seeded(320, 844, { months: true, large: true, scale: 2 });
  await openMore(page, "subs");
  await shot(page, "adr028-320-abonnements-texte-200");
  await openMore(page, "year");
  await shot(page, "adr028-320-annee-texte-200");
  await page.context().close();
}

await browser.close();
console.log(`Captures ADR-028 écrites dans ${OUT} — ${failures} erreur(s) console/page.`);
process.exit(failures ? 1 : 0);
