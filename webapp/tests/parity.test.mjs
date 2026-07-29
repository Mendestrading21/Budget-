// Suite de PARITÉ web/natif (lot A05, Budget Master Evolution).
// Injecte chaque fixture canonique dans localStorage, recharge l'app réelle
// (Chromium), puis appelle le moteur en page (snapshot / balance /
// liabilityBalance) et compare aux valeurs attendues, au centime près.
// Le natif est la source de vérité ; les fixtures et les attendus vivent
// dans fixtures/parity-fixtures.json.
import { chromium } from "playwright-core";
import { fileURLToPath } from "node:url";
import { readFileSync } from "node:fs";
import path from "node:path";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APP_URL = "file://" + path.resolve(HERE, "..", "index.html");
const FIXTURES = JSON.parse(
  readFileSync(path.resolve(HERE, "..", "..", "fixtures", "parity-fixtures.json"), "utf8")
);
const CHROMIUM =
  process.env.BUDGET_CHROMIUM
  || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";

// Tolérance d'un demi-centime : le moteur web est encore en flottants
// (lot G01 le rendra exact au centime entier) ; la parité se vérifie donc
// à l'affichage arrondi, comme le voit l'utilisateur.
const EPS = 0.005;
const failures = [];
const near = (a, b) => typeof a === "number" && typeof b === "number" && Math.abs(a - b) < EPS;

const browser = await chromium.launch({ executablePath: CHROMIUM, args: ["--no-sandbox"] });
const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page = await context.newPage();
const consoleErrors = [];
page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(msg.text()); });
page.on("pageerror", err => consoleErrors.push("pageerror: " + err.message));

for (const sc of FIXTURES.scenarios) {
  const state = { version: 1, ...sc.state };
  // Poser l'état AVANT le chargement du script de l'app (loadState lit
  // localStorage à l'initialisation du module).
  await page.addInitScript(payload => {
    localStorage.setItem("budget-app-state-v1", payload);
  }, JSON.stringify(state));
  await page.goto(APP_URL);
  await page.waitForFunction(() => typeof window.snapshot === "function" || typeof snapshot === "function", null, { timeout: 10000 })
    .catch(() => {});

  const got = await page.evaluate(({ y, m }) => {
    const snap = snapshot(y, m);
    const bal = {};
    for (const a of ACCOUNTS) bal[a.id] = balance(a.id);
    const liab = {};
    for (const l of (S.liabilities || [])) liab[l.id] = liabilityBalance(l);
    return { snap, bal, liab };
  }, sc.month);

  const exp = sc.expected;
  if (exp.snapshot) {
    for (const [k, v] of Object.entries(exp.snapshot)) {
      if (!near(got.snap[k], v)) failures.push(`[${sc.id}] snapshot.${k} attendu ${v}, obtenu ${got.snap[k]}`);
    }
  }
  if (exp.balances) {
    for (const [k, v] of Object.entries(exp.balances)) {
      if (!near(got.bal[k], v)) failures.push(`[${sc.id}] balance.${k} attendu ${v}, obtenu ${got.bal[k]}`);
    }
  }
  if (exp.liabilityBalances) {
    for (const [k, v] of Object.entries(exp.liabilityBalances)) {
      if (!near(got.liab[k], v)) failures.push(`[${sc.id}] dette.${k} attendu ${v}, obtenu ${got.liab[k]}`);
    }
  }
  if (exp.allFinite) {
    for (const [k, v] of Object.entries(got.snap)) {
      if (typeof v === "number" && !Number.isFinite(v)) failures.push(`[${sc.id}] snapshot.${k} n'est pas fini (${v})`);
    }
  }

  // Repartir d'un contexte propre pour la fixture suivante.
  await context.clearCookies();
  await page.evaluate(() => localStorage.clear());
}

await browser.close();

if (consoleErrors.length) {
  console.error("Erreurs console pendant la parité :");
  for (const e of consoleErrors) console.error("  " + e);
}
if (failures.length || consoleErrors.length) {
  console.error(`ÉCHEC PARITÉ : ${failures.length} écart(s), ${consoleErrors.length} erreur(s) console`);
  for (const f of failures) console.error("  " + f);
  process.exit(1);
}
console.log(`SUITE PARITÉ : ${FIXTURES.scenarios.length} fixtures réconciliées web↔attendus (natif), zéro erreur console ✓`);
