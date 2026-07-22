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
page.on("download", () => {}); // les téléchargements (export, secours) sont ignorés en test

async function goHome() {
  await page.goto(APP_URL);
  await page.waitForSelector("#tabbar button", { timeout: 10000 });
}

// ---------- Test 0 : première ouverture = écran de bienvenue ----------
currentTest = "bienvenue";
await page.goto(APP_URL);
await page.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 }); // pas de démo imposée
let tabbarHidden = await page.$eval("#tabbar", el => el.style.display === "none");
check(tabbarHidden, "la barre d'onglets doit être cachée pendant la bienvenue");
await page.click('[data-obcountry="CH"]');
await page.waitForSelector('[data-obhh="couple"]', { state: "visible" });
await page.click('[data-obhh="couple"]');
await page.waitForSelector("#obName", { state: "visible" });
await page.fill("#obName", "Elio");
await page.fill("#obPartner", "Sara");
await page.click('#obForm1 button[type="submit"]');
await page.waitForSelector("#obSalary", { state: "visible" });
await page.fill("#obSalary", "5500");
await page.click('#obForm2 button[type="submit"]');
await page.waitForTimeout(150); // phase 2 : salaire de Sara
await page.fill("#obSalary", "4200");
await page.click('#obForm2 button[type="submit"]');
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "2000");
await page.click('#obForm3 button[type="submit"]');
await page.waitForSelector("#tabbar button", { timeout: 10000 });
let homeHTML = await page.$eval("#screen", el => el.innerHTML);
check(homeHTML.includes("Bonjour Elio &amp; Sara") || homeHTML.includes("Bonjour Elio & Sara"), "le couple doit être salué à deux prénoms");
check(homeHTML.includes("Salaire"), "le salaire configuré doit nourrir l'accueil");
const bannerHidden = await page.$eval(".demo-banner", el => el.style.display === "none");
check(bannerHidden, "pas de bannière « données fictives » après un vrai départ");
// persistance : recharger garde l'utilisateur onboardé
await page.reload();
await page.waitForSelector("#tabbar button");
homeHTML = await page.$eval("#screen", el => el.innerHTML);
check(homeHTML.includes("Elio") && homeHTML.includes("Sara"), "prénoms perdus après rechargement");

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
check(screenHTML.includes("0/2 validé"), "progression initiale 0/2 absente (deux salaires à valider)");
await page.click('[data-postrec]');
await page.waitForTimeout(200);
await page.click('[data-postrec]'); // le second salaire
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mois bouclé"), "« Mois bouclé » absent après validation des deux salaires");
check(screenHTML.includes("Mois bouclés récents"), "pastilles d'historique des mois absentes");
check(screenHTML.includes("à rattraper"), "l'invitation à rattraper le mois précédent doit apparaître");
await page.click('[data-gotomonth]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("0/2 validé"), "le rattrapage doit ouvrir le mois précédent avec ses éléments");
await page.click("#backToNow");
await page.waitForTimeout(150);
check(screenHTML.includes("9'700.00") || screenHTML.includes("5'500.00"), "les salaires validés doivent nourrir les revenus");

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
// Fiche de compte : historique, courbe, cumuls, retour
await page.click('#screen [data-accid]:has-text("Épargne")');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Historique"), "fiche de compte : historique absent");
check(screenHTML.includes("Solde — 12 derniers mois"), "fiche de compte : courbe absente");
check(screenHTML.includes("Épargne E2E"), "fiche de compte : le versement doit apparaître dans l'historique");
check(!screenHTML.includes("NaN"), "NaN dans la fiche de compte");
await page.click("[data-accback]");
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Argent disponible"), "retour à la liste des comptes cassé");

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
check(screenHTML.includes("Le chemin") && screenHTML.includes("Dans 10 ans"), "projection du patrimoine absente");
await page.goBack();
await page.waitForTimeout(150);
await page.click('#screen [data-more="year"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mis de côté") && screenHTML.includes("Mois bouclés"), "écran Année en revue incomplet");
check(!screenHTML.includes("NaN"), "NaN dans l'année en revue");
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(150);
await page.click('[data-projprofile="ambitious"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("NaN") && screenHTML.includes("Dans 20 ans"), "profil ambitieux : projection cassée");

// ---------- Test 10b : dette vivante — la mensualité décrémente ----------
currentTest = "dette vivante";
await page.click("[data-additem]");
await page.waitForSelector("#itemForm", { state: "visible" });
await page.selectOption("#iKind", "liability");
await page.fill("#iName", "Leasing E2E");
await page.fill("#iAmount", "1200");
await page.fill("#iMonthly", "100");
await page.click('#itemForm button[type="submit"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Leasing E2E") && screenHTML.includes("terminé vers"), "dette vivante : fin projetée absente");
const leasingId = await page.evaluate(() =>
  JSON.parse(localStorage.getItem("budget-app-state-v1")).liabilities.find(l => l.name === "Leasing E2E").id);
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.waitForTimeout(150);
await page.click(`[data-postrec="r-debt-${leasingId}"]`);
await page.waitForTimeout(200);
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("1'100.00"), "la mensualité payée doit décrémenter la dette (1200 → 1100)");

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
await page.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 }); // reload → bienvenue
const wiped = await page.evaluate(() => localStorage.getItem("budget-app-state-v1"));
check(wiped === null, "réinitialisation complète : le stockage doit être vidé");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Suisse") && screenHTML.includes("Belgique"), "le choix du pays doit rouvrir la bienvenue");

// ---------- Test 13 : devise de référence EUR de bout en bout ----------
currentTest = "devise de référence";
await page.click('[data-obcountry="FR"]');
await page.waitForSelector('[data-obhh="solo"]', { state: "visible" });
await page.click('[data-obhh="solo"]');
await page.waitForSelector("#obName", { state: "visible" });
await page.fill("#obName", "Eva");
await page.click('#obForm1 button[type="submit"]');
await page.waitForSelector("[data-obskip]", { state: "visible" });
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("(EUR)"), "la France doit passer l'app en euros");
await page.click("[data-obskip]");
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "1000");
await page.click('#obForm3 button[type="submit"]');
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Bonjour Eva"), "prénom absent après un départ en euros");
check(screenHTML.includes("€ 1'000.00"), "le solde de départ doit s'afficher en euros");
check(!screenHTML.includes("CHF "), "plus aucun total en CHF quand la référence est l'euro");

// ---------- Test 14 : Réglages essentiels — guide, pays, devise ----------
currentTest = "reglages";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Comment ça marche"), "guide « Comment ça marche » absent");
check(screenHTML.includes("Un envoi n'est pas une dépense"), "règle d'or absente du guide");
check(screenHTML.includes("Mon pays") && screenHTML.includes("France"), "réglage pays absent ou faux");
check(screenHTML.includes("Devise de référence") && screenHTML.includes("EUR"), "devise de référence absente");

// ---------- Test 15 : profil de projection persisté ----------
currentTest = "projection persistée";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(150);
await page.click('[data-projprofile="prudent"]');
await page.waitForTimeout(150);
await page.reload();
await page.waitForSelector("#tabbar button");
const storedProfile = await page.evaluate(() => JSON.parse(localStorage.getItem("budget-app-state-v1")).projectionProfile);
check(storedProfile === "prudent", "le profil de projection doit survivre au rechargement");

// ---------- Test 16 : activation au clavier (Entrée) ----------
currentTest = "clavier";
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(150);
await page.focus('#screen [data-accid]');
await page.keyboard.press("Enter");
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Historique"), "Entrée doit ouvrir la fiche de compte");
await page.click("[data-accback]");
await page.waitForTimeout(150);

// ---------- Test 17 : démo localisée France ----------
currentTest = "démo pays";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]"); // confirm auto-accepté → reload
await page.waitForSelector("#tabbar button", { timeout: 10000 });
const demoBanner = await page.$eval(".demo-banner", el => el.style.display !== "none");
check(demoBanner, "bannière démo absente après chargement de la démonstration");
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="insurance"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mutuelle santé"), "la démo française doit parler de mutuelle, pas de LAMal");
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Retraite (PER)") && screenHTML.includes("€"), "la démo française doit être en euros avec un PER");

// ---------- Test 18 : état illisible/trop récent → mis de côté, jamais perdu (P0 données) ----------
currentTest = "sauvetage donnees";
const originalBlob = JSON.stringify({ version: 2, marqueur: "données-futures", transactions: [], accounts: [] });
await page.evaluate(blob => {
  localStorage.setItem("budget-app-state-v1", blob);
  localStorage.removeItem("budget-app-state-rescue");
}, originalBlob);
await page.reload();
await page.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 }); // écran de bienvenue, pas de crash
const rescued = await page.evaluate(() => localStorage.getItem("budget-app-state-rescue"));
check(rescued === originalBlob, "l'état trop récent doit être mis de côté intact, pas effacé");
// JSON corrompu : même protection
await page.evaluate(() => {
  localStorage.setItem("budget-app-state-v1", "{ceci n'est pas du JSON");
  localStorage.removeItem("budget-app-state-rescue");
});
await page.reload();
await page.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 });
const rescuedCorrupt = await page.evaluate(() => localStorage.getItem("budget-app-state-rescue"));
check(rescuedCorrupt === "{ceci n'est pas du JSON", "un état corrompu doit être mis de côté, pas effacé en silence");

// ---------- Test 19 : restauration refuse une version d'état incohérente (P0 données) ----------
currentTest = "restauration validée";
// D'abord un état sain et onboardé pour détecter tout remplacement indu.
await page.evaluate(() => {
  localStorage.setItem("budget-app-state-v1", JSON.stringify({
    version: 1, onboarded: true, isDemo: false, profile: { name: "Témoin" },
    baseCurrency: "CHF", transactions: [], accounts: [{ id: "cur", name: "C", kind: "current", opening: 1, cash: true, currency: "CHF" }],
    recurrings: [], goals: [], assets: [], liabilities: [], pensions: [], insurances: [], bills: [], documents: [], budgets: {},
  }));
  localStorage.removeItem("budget-app-state-rescue");
});
await page.reload();
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.evaluate(() => {
  const bad = JSON.stringify({ app: "budget-web", version: 1, state: { version: 2, transactions: [], accounts: [] } });
  restoreFromFile(new File([bad], "b.json", { type: "application/json" }));
});
await page.waitForTimeout(250);
const afterRestore = await page.evaluate(() => JSON.parse(localStorage.getItem("budget-app-state-v1")));
check(afterRestore.version === 1 && afterRestore.profile && afterRestore.profile.name === "Témoin",
  "une sauvegarde dont l'état n'est pas en version 1 doit être refusée sans rien remplacer");

// ---------- Test 20 : le bouton Annuler de « Devise de référence » agit (P0 bouton mort) ----------
currentTest = "annuler devise";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-editbase]");
await page.waitForSelector("#baseForm", { state: "visible" });
await page.click("#baseCancel");
await page.waitForTimeout(200);
const baseSheetOpen = await page.$eval("#sheetBackdrop", el => el.classList.contains("open"));
check(!baseSheetOpen, "le bouton Annuler de la devise de référence doit fermer la feuille");

// ---------- Test 21 : fermeture accidentelle d'une feuille avec saisie → garde-fou ----------
currentTest = "garde-fou saisie";
await goHome();
await page.click("#fab");
await page.waitForSelector('#quickMenu [data-quick="tx"]', { state: "visible" });
await page.click('#quickMenu [data-quick="tx"]');
await page.waitForSelector("#txForm", { state: "visible" });
await page.fill("#fTitle", "Saisie en cours");
await page.fill("#fAmount", "12.30");
// clic sur le fond = dismiss accidentel : confirm auto-accepté → se ferme
await page.evaluate(() => document.getElementById("sheetBackdrop").click());
await page.waitForTimeout(150);
let guardOpen = await page.$eval("#sheetBackdrop", el => el.classList.contains("open"));
check(!guardOpen, "après confirmation, la feuille doit se fermer");
// ouvrir sans rien changer et cliquer le fond : pas de saisie → fermeture directe
await page.click("#fab");
await page.waitForSelector('#quickMenu [data-quick="tx"]', { state: "visible" });
await page.click('#quickMenu [data-quick="tx"]');
await page.waitForSelector("#txForm", { state: "visible" });
const snapClean = await page.evaluate(() => serializeSheet("txForm") === openSheetSnapshot);
check(snapClean, "une feuille fraîchement ouverte ne doit pas être considérée comme modifiée");
await page.evaluate(() => document.getElementById("sheetBackdrop").click());
await page.waitForTimeout(120);
guardOpen = await page.$eval("#sheetBackdrop", el => el.classList.contains("open"));
check(!guardOpen, "sans saisie, le clic sur le fond ferme sans obstacle");

// ---------- Test 22 : solde négatif saisissable via la case à cocher ----------
currentTest = "solde negatif";
// Repartir de la démo pour disposer d'un compte avec historique (le bouton
// « Mettre le solde à jour » n'apparaît que si le compte a des mouvements).
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]");
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-accid]'); // → fiche de compte
await page.waitForSelector("[data-editacc]", { state: "visible" });
await page.click("[data-editacc]"); // → feuille compte (avec « Mettre le solde à jour… » si historique)
await page.waitForSelector("#aReconcile", { state: "visible" });
await page.click("#aReconcile");
await page.waitForSelector("#reconForm", { state: "visible" });
await page.fill("#reconAmount", "250.00");
await page.check("#reconNegative");
await page.click('#reconForm button[type="submit"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("-") && screenHTML.includes("250.00"), "un solde négatif saisi via la case doit s'appliquer");

// ---------- Test 23 : le bouton « retour » ferme une feuille ouverte ----------
currentTest = "retour ferme feuille";
await page.click(`#tabbar button[aria-label="Budget"]`);
await page.waitForTimeout(150);
await page.click("#fab");
await page.waitForSelector('#quickMenu [data-quick="tx"]', { state: "visible" });
await page.click('#quickMenu [data-quick="tx"]'); // feuille propre (non modifiée)
await page.waitForSelector("#txForm", { state: "visible" });
await page.goBack();
await page.waitForTimeout(200);
const backClosed = await page.$eval("#sheetBackdrop", el => !el.classList.contains("open"));
check(backClosed, "le bouton retour doit fermer la feuille ouverte");
const stillBudget = await page.evaluate(() => activeTab);
check(stillBudget === "budget", "le retour qui ferme une feuille ne doit pas aussi changer d'onglet");

// ---------- Test 24 : état vide guidé des Mouvements → action directe ----------
currentTest = "vide guidé mouvements";
// État vierge onboardé (aucun mouvement), puis onglet Mouvements.
await page.evaluate(() => {
  localStorage.setItem("budget-app-state-v1", JSON.stringify({
    version: 1, onboarded: true, isDemo: false, profile: { name: "Vide" },
    baseCurrency: "CHF", transactions: [], accounts: [{ id: "cur", name: "C", kind: "current", opening: 100, cash: true, currency: "CHF" }],
    recurrings: [], goals: [], assets: [], liabilities: [], pensions: [], insurances: [], bills: [], documents: [], budgets: {},
  }));
  localStorage.removeItem("budget-app-state-rescue");
});
await page.reload();
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.click(`#tabbar button[aria-label="Mouvements"]`);
await page.waitForTimeout(150);
await page.waitForSelector("[data-addtx]", { state: "visible" });
await page.click("[data-addtx]");
await page.waitForSelector("#txForm", { state: "visible" });
const txSheetShown = await page.$eval("#txForm", el => el.style.display !== "none");
check(txSheetShown, "l'action de l'état vide des Mouvements doit ouvrir la feuille d'ajout");
await page.click("#fCancel");

// ---------- Test 25 : menu « Plus » regroupé par intention ----------
currentTest = "menu plus groupé";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
for (const group of ["Aujourd'hui", "Patrimoine", "Données", "Réglages"]) {
  check(screenHTML.includes(group), `groupe « ${group} » absent du menu Plus`);
}
check(screenHTML.includes('data-gototab="movements"'), "l'entrée Mouvements doit rester dans le menu Plus");
check(screenHTML.includes('data-more="taxes"') && screenHTML.includes('data-more="networth"'),
  "les destinations du menu Plus doivent rester atteignables après regroupement");

// ---------- Test 26 : accueil essentiel — 4 actions directes + patrimoine replié ----------
currentTest = "accueil essentiel";
await goHome();
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
for (const act of ["data-quickexp", "data-quickinc", "data-quicksend", "data-quickinv"]) {
  check(screenHTML.includes(act), `action rapide ${act} absente de l'accueil`);
}
// le patrimoine est replié (details fermé) mais son contenu reste dans le DOM
check(screenHTML.includes("home-fold") && screenHTML.includes("Fortune nette totale"),
  "le patrimoine doit être replié sur l'accueil sans disparaître");
// « Investir » ouvre la feuille pré-réglée sur investissement
await page.click("[data-quickinv]");
await page.waitForSelector("#txForm", { state: "visible" });
const presetInvest = await page.$eval("#fType", el => el.value);
check(presetInvest === "investment", "« Investir » doit pré-régler le type sur investissement");
await page.click("#fCancel");

// ---------- Test 27 : la sauvegarde n'emporte jamais le code de verrouillage ----------
currentTest = "sauvegarde sans code";
const leaked = await page.evaluate(() => {
  S.lockCode = "HASH_SECRET_123"; S.faceIDEnabled = true;
  let captured = "";
  const orig = downloadFile;
  downloadFile = (name, text) => { captured = text; };
  exportBackup();
  downloadFile = orig;
  return captured;
});
check(!leaked.includes("HASH_SECRET_123") && !leaked.includes("lockCode"),
  "le fichier de sauvegarde ne doit contenir ni le hash du code ni le champ lockCode");

// ---------- Test 28 : moteur en centimes — 0.10 + 0.20 = 0.30 EXACT (G01) ----------
currentTest = "precision centimes";
await page.evaluate(() => {
  localStorage.setItem("budget-app-state-v1", JSON.stringify({
    version: 1, onboarded: true, isDemo: false, profile: { name: "Cent" },
    baseCurrency: "CHF",
    accounts: [{ id: "cur", name: "C", kind: "current", opening: 1, cash: true, currency: "CHF" }],
    transactions: [
      { id: 1, title: "a", amount: 0.1, type: "expense", cat: "x", acc: "cur", dest: null, status: "posted", y: 2026, m: 5, d: 2 },
      { id: 2, title: "b", amount: 0.2, type: "expense", cat: "x", acc: "cur", dest: null, status: "posted", y: 2026, m: 5, d: 3 },
    ],
    recurrings: [], goals: [], assets: [], liabilities: [], pensions: [], insurances: [], bills: [], documents: [], budgets: {},
  }));
});
await page.reload();
await page.waitForSelector("#tabbar button", { timeout: 10000 });
const precision = await page.evaluate(() => ({ living: snapshot(2026, 5).living, bal: balance("cur") }));
check(Object.is(precision.living, 0.3), `0.10 + 0.20 doit valoir exactement 0.30 (obtenu ${precision.living})`);
check(Object.is(precision.bal, 0.7), `1 − 0.10 − 0.20 doit valoir exactement 0.70 (obtenu ${precision.bal})`);

// ---------- Test 29 : Horizon — clair par défaut, sombre persisté ----------
currentTest = "theme horizon";
await goHome();
let theme = await page.evaluate(() => document.documentElement.dataset.theme);
check(theme === "light", `le thème par défaut doit être clair (obtenu ${theme})`);
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-toggletheme]");
await page.waitForTimeout(150);
theme = await page.evaluate(() => document.documentElement.dataset.theme);
check(theme === "dark", "la bascule doit passer en sombre");
await page.reload();
await page.waitForSelector("#tabbar button");
theme = await page.evaluate(() => document.documentElement.dataset.theme);
check(theme === "dark", "le thème sombre doit survivre au rechargement");
await page.evaluate(() => { S.theme = "light"; saveState(); }); // remettre le défaut

// ---------- Test 30 : Horizon L2 — une recommandation utile sur l'accueil ----------
currentTest = "recommandation du mois";
await goHome();
// repartir de la démo : factures, paiements réguliers et objectifs présents
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]");
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Priorité :") || screenHTML.includes("Attention :") || screenHTML.includes("Tout est en ordre"),
  "l'accueil doit afficher une recommandation du mois");
const recCount = (screenHTML.match(/Priorité :|Attention :|Tout est en ordre/g) || []).length;
check(recCount === 1, `une SEULE recommandation à la fois (obtenu ${recCount})`);

// ---------- Test 31 : Horizon L3 — comparaison au mois précédent ----------
currentTest = "comparaison mois";
await page.click(`#tabbar button[aria-label="Budget"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mois dernier : coût de la vie"),
  "le Budget doit comparer au coût de la vie du mois précédent (démo chargée)");
await page.click(`#tabbar button[aria-label="Accueil"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mois dernier :"), "l'accueil doit rappeler le coût de la vie du mois dernier");

await browser.close();

// ---------- Rapport ----------
const allFailures = [...failures, ...consoleErrors];
if (allFailures.length) {
  console.error("ÉCHECS E2E (" + allFailures.length + ") :");
  for (const failure of allFailures) console.error("  ✗ " + failure);
  process.exit(1);
}
console.log("SUITE E2E NAVIGATEUR : 36 parcours verts, zéro erreur console ✓");
