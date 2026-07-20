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

// ---------- Test 0 : première ouverture = écran de bienvenue ----------
currentTest = "bienvenue";
await page.goto(APP_URL);
await page.waitForSelector("#obName", { timeout: 10000 }); // pas de démo imposée
let tabbarHidden = await page.$eval("#tabbar", el => el.style.display === "none");
check(tabbarHidden, "la barre d'onglets doit être cachée pendant la bienvenue");
await page.fill("#obName", "Elio");
await page.click('#obForm1 button[type="submit"]');
await page.waitForSelector('[data-obcountry="CH"]', { state: "visible" });
await page.click('[data-obcountry="CH"]');
await page.waitForSelector('[data-obcur="CHF"]', { state: "visible" });
await page.click('[data-obcur="CHF"]');
await page.waitForSelector("#obSalary", { state: "visible" });
await page.fill("#obSalary", "5500");
await page.click('#obForm2 button[type="submit"]');
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "2000");
await page.click('#obForm3 button[type="submit"]');
await page.waitForSelector("#tabbar button", { timeout: 10000 });
let homeHTML = await page.$eval("#screen", el => el.innerHTML);
check(homeHTML.includes("Bonjour Elio"), "le prénom saisi doit apparaître sur l'accueil");
check(homeHTML.includes("Salaire"), "le salaire configuré doit nourrir l'accueil");
const bannerHidden = await page.$eval(".demo-banner", el => el.style.display === "none");
check(bannerHidden, "pas de bannière « données fictives » après un vrai départ");
// persistance : recharger garde l'utilisateur onboardé
await page.reload();
await page.waitForSelector("#tabbar button");
homeHTML = await page.$eval("#screen", el => el.innerHTML);
check(homeHTML.includes("Bonjour Elio"), "prénom perdu après rechargement");

// ---------- Test 1 : chaque onglet s'ouvre ----------
currentTest = "onglets";
await goHome();
for (const label of ["Accueil", "Mouvements", "Budget", "Comptes", "Plus"]) {
  await page.click(`#tabbar button[aria-label="${label}"]`);
  await page.waitForTimeout(120);
  const content = await page.$eval("#screen", el => el.innerHTML.length);
  check(content > 200, `onglet ${label} vide`);
}

// ---------- Test 1b : rituel « Check du mois » — valider le salaire boucle le mois ----------
currentTest = "check du mois";
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.waitForTimeout(150);
let screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Check du mois"), "carte « Check du mois » absente");
check(screenHTML.includes("0/1 validé"), "progression initiale 0/1 absente (salaire à valider)");
await page.click('[data-postrec]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mois bouclé"), "« Mois bouclé » absent après validation du salaire");
check(screenHTML.includes("Mois bouclés récents"), "pastilles d'historique des mois absentes");
check(screenHTML.includes("5'500.00"), "le salaire validé doit apparaître dans les revenus");

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
screenHTML = await page.$eval("#screen", el => el.innerHTML);
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
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.click("[data-quicksend]");
await page.waitForSelector("#txForm", { state: "visible" });
const destOptions = await page.$eval("#fDest", el => el.options.length);
check(destOptions > 0, "aucune destination proposée pour une épargne");
await page.fill("#fTitle", "Épargne E2E");
await page.fill("#fAmount", "100");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Épargne E2E"), "épargne absente de l'écran Accueil");

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

// ---------- Test 6b : cumuls Finary — chaque versement s'additionne ----------
currentTest = "cumuls";
screenHTML = await page.$eval("#screen", el => el.innerHTML); // toujours sur Comptes
check(screenHTML.includes("Versé cette année : CHF 100.00"), "cumul annuel absent sur le compte Épargne");
check(screenHTML.includes("total : CHF 100.00"), "cumul total absent sur le compte Épargne");

// ---------- Test 7 : facture — payer crée le mouvement ----------
currentTest = "facture";
await page.click(`#tabbar button[aria-label="Accueil"]`);
const payButton = await page.$("[data-paybill]");
if (payButton) {
  await payButton.click();
  await page.waitForTimeout(200);
  screenHTML = await page.$eval("#screen", el => el.innerHTML);
  check(!(await page.$("[data-paybill]")) || screenHTML.includes("payée"), "facture non payée après clic");
}

// ---------- Test 7b : échéance de contrat proche → alerte sur l'Accueil ----------
currentTest = "echeance contrat";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="insurance"]');
await page.waitForTimeout(150);
await page.click("[data-addins]");
await page.waitForSelector("#insForm", { state: "visible" });
await page.fill("#insName", "RC ménage E2E");
await page.fill("#insPremium", "390");
const dueSoon = new Date(Date.now() + 10 * 86400000).toISOString().slice(0, 10);
await page.fill("#insDue", dueSoon);
await page.click('#insForm button[type="submit"]');
await page.waitForTimeout(200);
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("RC ménage E2E") && screenHTML.includes("arrive à échéance"),
  "l'échéance de contrat à 10 jours doit alerter sur l'Accueil");

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
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Versé cette année"), "bilan annuel des versements absent du Patrimoine");
check(screenHTML.includes("Évolution sur 12 mois"), "courbe 12 mois par classe absente");

// ---------- Test 11 : onglet Mouvements — recherche et filtres ----------
currentTest = "mouvements";
await page.click(`#tabbar button[aria-label="Mouvements"]`);
await page.waitForTimeout(150);
check(await page.$("#moreSearchInput") !== null, "champ de recherche absent");
check((await page.$$("[data-morefilter]")).length >= 5, "filtres de type absents");
await page.fill("#moreSearchInput", "zzz-introuvable-e2e");
await page.waitForTimeout(250);
let listHTML = await page.$eval("#moreTxList", el => el.innerHTML);
check(listHTML.includes("Aucun résultat"), "recherche sans résultat n'affiche pas l'état vide");
await page.fill("#moreSearchInput", "");
await page.waitForTimeout(250);
listHTML = await page.$eval("#moreTxList", el => el.innerHTML);
check(!listHTML.includes("Aucun résultat pour cette recherche"), "recherche vidée ne réaffiche pas la liste");

// ---------- Test 12 : effacer les opérations ≠ réinitialisation complète ----------
currentTest = "double suppression";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
const budgetsBefore = await page.evaluate(() => Object.keys(JSON.parse(localStorage.getItem("budget-app-state-v1")).budgets || {}).length);
await page.click("[data-deleteall]"); // dialogs auto-acceptés
await page.waitForTimeout(250);
let stored = await page.evaluate(() => JSON.parse(localStorage.getItem("budget-app-state-v1")));
check(stored.transactions.length === 0, "opérations non effacées");
check(stored.accounts.length > 0, "les comptes doivent survivre à « Effacer les opérations »");
check(Object.keys(stored.budgets || {}).length === budgetsBefore, "les budgets doivent survivre");
await page.click('#screen [data-more="settings"]'); // deleteAllData ramène à la racine de Plus
await page.waitForTimeout(150);
await page.click("[data-fullreset]");
await page.waitForSelector("#obName", { timeout: 10000 }); // reload → écran de bienvenue
const wiped = await page.evaluate(() => localStorage.getItem("budget-app-state-v1"));
check(wiped === null, "réinitialisation complète : le stockage doit être vidé");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Commencer"), "l'écran de bienvenue doit réapparaître après la réinitialisation");

// ---------- Test 13 : devise de référence EUR de bout en bout ----------
currentTest = "devise de référence";
await page.fill("#obName", "Eva");
await page.click('#obForm1 button[type="submit"]');
await page.waitForSelector('[data-obcountry="FR"]', { state: "visible" });
await page.click('[data-obcountry="FR"]');
await page.waitForSelector('[data-obcur="EUR"]', { state: "visible" });
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Euro · conseillé"), "la France doit conseiller l'euro");
await page.click('[data-obcur="EUR"]');
await page.waitForSelector("[data-obskip]", { state: "visible" });
await page.click("[data-obskip]");
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "1000");
await page.click('#obForm3 button[type="submit"]');
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Bonjour Eva"), "prénom absent après un départ en euros");
check(screenHTML.includes("€ 1'000.00"), "le solde de départ doit s'afficher en euros");
check(!screenHTML.includes("CHF "), "plus aucun total en CHF quand la référence est l'euro");

await browser.close();

// ---------- Rapport ----------
const allFailures = [...failures, ...consoleErrors];
if (allFailures.length) {
  console.error("ÉCHECS E2E (" + allFailures.length + ") :");
  for (const failure of allFailures) console.error("  ✗ " + failure);
  process.exit(1);
}
console.log("SUITE E2E NAVIGATEUR : 18 tests verts, zéro erreur console ✓");
