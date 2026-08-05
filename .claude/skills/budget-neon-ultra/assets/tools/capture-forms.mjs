// Outillage REPRODUCTIBLE de capture des FEUILLES DE SAISIE au style unifié
// « Nouveau mouvement » : pied collant, action principale en dégradé, montant
// dominant, pastilles tactiles à la place des menus déroulants.
// Données 100 % FICTIVES et déterministes (foyer « Alex »).
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome OUT=/dossier \
//     node .claude/skills/budget-neon-ultra/assets/tools/capture-forms.mjs
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(
  path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));

const OUT = process.env.OUT || path.join(ROOT, "docs/neon-ultra/features/forms");
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
  await page.waitForTimeout(6500); // hygiène des toasts
  // Un mois libre : sinon « ligne budgétaire » refuse de s'ouvrir, toutes
  // les catégories du mois courant étant déjà prises (comportement voulu).
  await page.evaluate(() => { cursor = shiftMonth({ y: NOW.y, m: NOW.m }, 7); render(); });
  await page.waitForTimeout(250);
  if (opts.large) await page.evaluate(() => { document.documentElement.dataset.largeText = "true"; });
  return page;
}

const open = async (page, id, opener) => {
  await page.evaluate(f => eval(f), opener);
  await page.waitForSelector(`#${id}`, { state: "visible" });
  await page.waitForTimeout(320);
};
const close = async page => {
  await page.evaluate(() => document.getElementById("sheetBackdrop").classList.remove("open"));
  await page.waitForTimeout(160);
};
const shot = async (page, name) => {
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
};

// Les feuilles à capturer : celles où le propriétaire saisit vraiment, plus
// une feuille « réglage » pour prouver que le style ne laisse aucun trou.
const SHEETS = [
  ["txForm", "openTxSheet(null)", "mouvement"],
  ["recForm", "openRecSheet(null)", "facture-mensuelle"],
  ["itemForm", "openItemSheet('asset', null)", "actif-dette"],
  ["billForm", "openBillSheet(null)", "facture-ponctuelle"],
  ["goalForm", "openGoalSheet(null)", "objectif"],
  ["accForm", "openAccSheet(null)", "compte"],
  ["lineForm", "openLineSheet(null)", "ligne-budgetaire"],
  ["reconForm", "openSheet('reconForm')", "solde-compte"],
];

for (const [width, tag] of [[390, "390"], [320, "320"]]) {
  const page = await seeded(width, 844);
  for (const [id, opener, name] of SHEETS) {
    await open(page, id, opener);
    await shot(page, `forms-${tag}-${name}`);
    await close(page);
  }
  await page.context().close();
}

// 320 px à 200 % de texte : le pied collant et les pastilles tiennent.
{
  const page = await seeded(320, 844, { large: true, scale: 2 });
  for (const [id, opener, name] of [SHEETS[0], SHEETS[1], SHEETS[2]]) {
    await open(page, id, opener);
    await shot(page, `forms-320-${name}-texte-200`);
    await close(page);
  }
  await page.context().close();
}

await browser.close();
console.log(`Captures des feuilles écrites dans ${OUT} — ${failures} erreur(s) console/page.`);
process.exit(failures ? 1 : 0);
