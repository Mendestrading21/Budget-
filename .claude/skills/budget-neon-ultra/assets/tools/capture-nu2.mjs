// Outillage REPRODUCTIBLE de capture des surfaces pilotes Neon Ultra (NU2).
// Données 100 % FICTIVES et déterministes : foyer « Alex & Charlie », jeu de
// démonstration de l'app, montants injectés explicitement. Aucune donnée
// réelle du propriétaire n'est utilisée.
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome OUT=/dossier/sortie \
//     node .claude/skills/budget-neon-ultra/assets/tools/capture-nu2.mjs
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(
  path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));

const OUT = process.env.OUT || path.join(ROOT, "docs/neon-ultra/pilot/nu2");
fs.mkdirSync(OUT, { recursive: true });
const APP_URL = "file://" + path.join(ROOT, "webapp/index.html");

const browser = await chromium.launch({
  executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"],
});
let failures = 0;

function watch(page, label) {
  page.on("pageerror", e => { console.error(`PAGEERROR (${label}) :`, e.message); failures++; });
  page.on("console", m => {
    if (m.type() === "error") { console.error(`CONSOLE (${label}) :`, m.text()); failures++; }
  });
  page.on("dialog", d => d.accept());
}

/** Foyer fictif Alex & Charlie + jeu de démonstration (données de l'app). */
async function seeded(width, height = 844, opts = {}) {
  const context = await browser.newContext({
    viewport: { width, height },
    ...(opts.reducedMotion ? { reducedMotion: "reduce" } : {}),
  });
  const page = await context.newPage();
  watch(page, `${width}×${height}`);
  await page.goto(APP_URL);
  await page.waitForSelector('[data-obcountry="CH"]');
  await page.click('[data-obcountry="CH"]');
  await page.click('[data-obhh="couple"]');
  await page.fill("#obName", "Alex");
  await page.fill("#obPartner", "Charlie");
  await page.click('#obForm1 button[type="submit"]');
  await page.fill("#obSalary", "5200");
  await page.click('#obForm2 button[type="submit"]');
  await page.waitForTimeout(150);
  await page.fill("#obSalary", "4100");
  await page.click('#obForm2 button[type="submit"]');
  await page.waitForSelector("#obOpening", { state: "visible" });
  await page.fill("#obOpening", "3400");
  await page.click('#obForm3 button[type="submit"]');
  await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await page.click('[data-obgoal="urgence"]');
  await page.waitForSelector("#tabbar button");
  if (!opts.empty) {
    // Jeu de démonstration de l'app : mouvements, budget, factures, objectifs.
    await page.click('#tabbar button[aria-label="Plus"]');
    await page.waitForTimeout(150);
    await page.click('#screen [data-more="settings"]');
    await page.waitForTimeout(200);
    await page.click("[data-resetdemo]");
    await page.waitForSelector("#tabbar button");
  }
  await page.waitForTimeout(6500); // hygiène des toasts
  return page;
}

async function shot(page, name, fullPage = true) {
  await page.waitForTimeout(250);
  await page.screenshot({ path: path.join(OUT, `${name}.png`), fullPage });
}

const goto = async (page, label) => {
  await page.click(`#tabbar button[aria-label="${label}"]`);
  await page.waitForTimeout(350);
};

// ---------- Mois : 390, 320 et montant EXTRÊME ----------
{
  const page = await seeded(390);
  await goto(page, "Mois");
  await shot(page, "nu2-pwa-390-mois");
  await goto(page, "Budget");
  await shot(page, "nu2-pwa-390-budget");
  // Menu Ajouter (feuille pilote) puis formulaire Nouveau mouvement.
  await goto(page, "Mois");
  await page.click("#fab");
  await page.waitForSelector("#quickMenu", { state: "visible" });
  await shot(page, "nu2-pwa-390-ajouter-menu", false);
  await page.click('#quickMenu [data-quick="tx"]');
  await page.waitForSelector("#txForm", { state: "visible" });
  await page.fill("#fAmount", "84.50");
  await page.evaluate(() => { document.getElementById("fMore").open = true; });
  await page.fill("#fTitle", "Courses de la semaine au marché couvert");
  await shot(page, "nu2-pwa-390-mouvement", false);
  // Erreur : montant vide → message CORAIL près du champ + aria-invalid.
  await page.fill("#fAmount", "");
  await page.click('#txForm button[type="submit"]');
  await page.waitForTimeout(300);
  await shot(page, "nu2-pwa-390-erreur", false);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(300);
  // Transparence réduite : surfaces pilotes opaques, aucun blur.
  await page.evaluate(() => { document.documentElement.dataset.reducedTransparency = "true"; });
  await goto(page, "Mois");
  await shot(page, "nu2-pwa-390-transparence-reduite");
  await page.context().close();
}

// ---------- Budget vide (aucune ligne budgétaire) ----------
{
  const page = await seeded(390, 844, { empty: true });
  await goto(page, "Budget");
  await shot(page, "nu2-pwa-390-budget-vide");
  await page.context().close();
}

// ---------- 320 px : Mois, Budget, montant extrême, texte 200 % ----------
{
  const page = await seeded(320);
  await goto(page, "Mois");
  await shot(page, "nu2-pwa-320-mois");
  await goto(page, "Budget");
  await shot(page, "nu2-pwa-320-budget");
  // Montant EXTRÊME (fictif) : sept chiffres, positif puis négatif.
  await page.evaluate(() => {
    transactions.push({
      id: ++txSeq, y: cursor.y, m: cursor.m, d: 3, title: "Vente fictive (capture NU2)",
      type: "income", cat: null, acc: ACCOUNTS[0].id, dest: null, status: "posted",
      amount: 9999999.99,
    });
    transactions.push({
      id: ++txSeq, y: cursor.y, m: cursor.m, d: 4, title: "Achat fictif (capture NU2)",
      type: "expense", cat: "Logement", acc: ACCOUNTS[0].id, dest: null, status: "posted",
      amount: 9999999.99,
    });
    saveState(); activeTab = "home"; render();
  });
  await goto(page, "Mois");
  await shot(page, "nu2-pwa-320-mois-extreme");
  await page.context().close();
}

// ---------- Texte agrandi 200 % ----------
// La PWA dimensionne ses textes en pixels (limite P3-5, ouverte depuis L9) :
// le grossissement réellement disponible pour l'utilisateur est le zoom de
// page. On le reproduit fidèlement — largeur utile au plancher supporté de
// 320 px, tout rendu deux fois plus grand, requêtes média correctes — puis
// on active EN PLUS la bascule déterministe `data-large-text` de l'app.
// Aucune perte de fonction ni troncature interne n'est tolérée.
{
  const context = await browser.newContext({
    viewport: { width: 320, height: 844 }, deviceScaleFactor: 2,
  });
  const page = await context.newPage();
  watch(page, "texte 200 %");
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
  await page.waitForTimeout(6500);
  await page.evaluate(() => { document.documentElement.dataset.largeText = "true"; });
  await page.click('#tabbar button[aria-label="Mois"]');
  await shot(page, "nu2-pwa-320-texte-200");
  await context.close();
}

// ---------- 320 × 480 : formulaire avec clavier simulé ----------
{
  const page = await seeded(320, 480);
  await page.click('#tabbar button[aria-label="Mois"]');
  await page.waitForTimeout(200);
  await page.click("#fab");
  await page.waitForSelector("#quickMenu", { state: "visible" });
  await page.click('#quickMenu [data-quick="tx"]');
  await page.waitForSelector("#txForm", { state: "visible" });
  await page.fill("#fAmount", "45.50");
  await page.focus("#fAmount");
  // Clavier logiciel simulé : la hauteur utile tombe à ~260 px. Le montant
  // reste atteignable et « Enregistrer » reste visible (pied collant).
  await page.setViewportSize({ width: 320, height: 260 });
  await page.waitForTimeout(200);
  await page.evaluate(() => document.getElementById("fAmount").scrollIntoView({ block: "center" }));
  await shot(page, "nu2-pwa-320-mouvement-clavier", false);
  await page.context().close();
}

await browser.close();
console.log(`Captures NU2 écrites dans ${OUT} — ${failures} erreur(s) console/page.`);
process.exit(failures ? 1 : 0);
