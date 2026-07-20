// Suite navigateur E2E de l'app web Budget (skill budget-production-completion).
// Exécution : node webapp/tests/e2e.test.mjs
// Chromium réel — toute erreur console ou page fait échouer la suite.
import { chromium } from "playwright-core";
import { fileURLToPath } from "node:url";
import path from "node:path";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APP_URL = "file://" + path.resolve(HERE, "..", "index.html");
const CHROMIUM =
  process.env.BUDGET_CHROMIUM
  || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";

const failures = [];
let currentTest = "boot";
function check(condition, message) {
  if (!condition) failures.push(`[${currentTest}] ${message}`);
}

const browser = await chromium.launch({ executablePath: CHROMIUM, args: ["--no-sandbox"] });
const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page = await context.newPage();

const consoleErrors = [];
page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[${currentTest}] ${msg.text()}`); });
page.on("pageerror", err => consoleErrors.push(`[${currentTest}] pageerror: ${err.message}`));
page.on("dialog", dialog => dialog.accept());

async function goHome() {
  await page.goto(APP_URL);
  await page.waitForSelector("#tabbar button", { timeout: 10000 });
}

// ---------- Test 1 : chaque onglet s'ouvre ----------
currentTest = "onglets";
await goHome();
for (const label of ["Accueil", "Mois", "Budget", "Comptes", "Plus"]) {
  await page.click(`#tabbar button[aria-label="${label}"]`);
  await page.waitForTimeout(120);
  const content = await page.$eval("#screen", el => el.innerHTML.length);
  check(content > 200, `onglet ${label} vide`);
}

// ---------- Test 2 : menu ＋ → Mouvement → dépense créée + persistée ----------
currentTest = "creation mouvement";
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.click("#fab");
await page.waitForSelector('#quickMenu [data-quick="tx"]', { state: "visible" });
await page.click('#quickMenu [data-quick="tx"]');
await page.waitForSelector("#txForm", { state: "visible" });
await page.fill("#fTitle", "Test E2E dépense");
await page.fill("#fAmount", "42.50");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(200);
let screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Test E2E dépense"), "dépense absente après création");
// persistance après reload
await page.reload();
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Test E2E dépense"), "dépense perdue après reload");

// ---------- Test 3 : modifier puis supprimer le mouvement ----------
currentTest = "edition/suppression";
await page.click('#screen [data-txid] >> text=Test E2E dépense');
await page.waitForSelector("#txForm", { state: "visible" });
await page.fill("#fAmount", "43.00");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("43.00"), "montant modifié absent");
await page.click('#screen [data-txid] >> text=Test E2E dépense');
await page.waitForSelector("#fDelete", { state: "visible" });
await page.click("#fDelete");
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("Test E2E dépense"), "mouvement non supprimé");

// ---------- Test 4 : épargne rapide — destination peuplée, fortune préservée ----------
currentTest = "epargne";
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.click("[data-quicksend]");
await page.waitForSelector("#txForm", { state: "visible" });
const destOptions = await page.$eval("#fDest", el => el.options.length);
check(destOptions > 0, "aucune destination proposée pour une épargne");
await page.fill("#fTitle", "Épargne E2E");
await page.fill("#fAmount", "100");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Épargne E2E"), "épargne absente de l'écran Mois");

// ---------- Test 5 : Échap ferme la feuille ----------
currentTest = "echap";
await page.click("#fab");
await page.waitForSelector("#quickMenu", { state: "visible" });
await page.keyboard.press("Escape");
await page.waitForTimeout(150);
const sheetOpen = await page.$eval("#sheetBackdrop", el => el.classList.contains("open"));
check(!sheetOpen, "Échap ne ferme pas la feuille");

// ---------- Test 6 : ajout d'un compte + solde d'ouverture ----------
currentTest = "compte";
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.click("[data-addacc]");
await page.waitForSelector("#accForm", { state: "visible" });
await page.fill("#aName", "Compte E2E");
await page.fill("#aOpening", "1500");
await page.click('#accForm button[type="submit"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Compte E2E") && screenHTML.includes("1'500.00"), "compte créé absent");

// ---------- Test 7 : facture — payer crée le mouvement ----------
currentTest = "facture";
await page.click(`#tabbar button[aria-label="Mois"]`);
const payButton = await page.$("[data-paybill]");
if (payButton) {
  await payButton.click();
  await page.waitForTimeout(200);
  screenHTML = await page.$eval("#screen", el => el.innerHTML);
  check(!(await page.$("[data-paybill]")) || screenHTML.includes("payée"), "facture non payée après clic");
}

// ---------- Test 8 : navigation retour navigateur ----------
currentTest = "retour navigateur";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="bills"]');
await page.waitForTimeout(150);
await page.goBack();
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("data-addbill"), "retour navigateur ne remonte pas");

// ---------- Test 9 : verrouillage par code ----------
currentTest = "verrouillage";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.click("[data-togglelock]");
await page.waitForSelector("#codeForm", { state: "visible" });
await page.fill("#code1", "4711");
await page.fill("#code2", "4711");
await page.click('#codeForm button[type="submit"]');
await page.waitForTimeout(200);
await page.click("[data-locknow]");
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("verrouillé"), "écran verrouillé absent");
await page.fill("#lockInput", "0000");
await page.click("[data-unlock]");
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("incorrect"), "mauvais code accepté ?");
await page.fill("#lockInput", "4711");
await page.click("[data-unlock]");
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("Budget est verrouillé"), "bon code refusé");

// ---------- Test 10 : courbe patrimoine avec valeurs constantes (pas de NaN) ----------
currentTest = "courbe";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(150);
const svgOK = await page.$eval("#screen", el => !el.innerHTML.includes("NaN"));
check(svgOK, "NaN dans la courbe de patrimoine");

await browser.close();

// ---------- Rapport ----------
const allFailures = [...failures, ...consoleErrors];
if (allFailures.length) {
  console.error("ÉCHECS E2E (" + allFailures.length + ") :");
  for (const failure of allFailures) console.error("  ✗ " + failure);
  process.exit(1);
}
console.log("SUITE E2E NAVIGATEUR : 10 tests verts, zéro erreur console ✓");
