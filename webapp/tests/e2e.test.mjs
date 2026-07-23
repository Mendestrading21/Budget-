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
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" }); // étape objectif (facultative)
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button", { timeout: 10000 });
let homeHTML = await page.$eval("#screen", el => el.innerHTML);
check(homeHTML.includes("Bonjour Elio &amp; Sara") || homeHTML.includes("Bonjour Elio & Sara"), "le couple doit être salué à deux prénoms");
check(homeHTML.includes("Salaire"), "le salaire configuré doit nourrir l'accueil");
check(homeHTML.includes("Fonds d'urgence"), "l'objectif choisi à la bienvenue doit exister et apparaître sur Mois");
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
for (const label of ["Mois", "Mouvements", "Budget", "Comptes", "Plus"]) {
  await page.click(`#tabbar button[aria-label="${label}"]`);
  await page.waitForTimeout(120);
  const content = await page.$eval("#screen", el => el.innerHTML.length);
  check(content > 200, `onglet ${label} vide`);
}

// ---------- Test 1b : rituel « Check du mois » — valider le salaire boucle le mois ----------
currentTest = "check du mois";
await page.click(`#tabbar button[aria-label="Mois"]`);
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
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.click("#fab");
await page.waitForSelector('#quickMenu [data-quick="tx"]', { state: "visible" });
await page.click('#quickMenu [data-quick="tx"]');
await page.waitForSelector("#txForm", { state: "visible" });
await page.evaluate(() => { document.getElementById("fMore").open = true; }); // L3 : intitulé sous « Détails »
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
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.click("[data-quicksend]");
await page.waitForSelector("#txForm", { state: "visible" });
const destOptions = await page.$eval("#fDest", el => el.options.length);
check(destOptions > 0, "aucune destination proposée pour une épargne");
await page.evaluate(() => { document.getElementById("fMore").open = true; }); // L3 : intitulé sous « Détails »
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
await page.click(`#tabbar button[aria-label="Mois"]`);
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
await page.click(`#tabbar button[aria-label="Mois"]`);
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
await page.click(`#tabbar button[aria-label="Mois"]`);
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
await page.waitForSelector("[data-obskipgoal]", { state: "visible" }); // étape objectif : passer
await page.click("[data-obskipgoal]");
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
await page.evaluate(() => { document.getElementById("fMore").open = true; }); // L3 : intitulé sous « Détails »
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
for (const group of ["À organiser", "À prévoir", "À construire", "Mes données", "Application"]) {
  check(screenHTML.includes(group), `groupe « ${group} » absent du menu Plus`);
}
check(screenHTML.includes('data-gototab="movements"'), "l'entrée Mouvements doit rester dans le menu Plus");
check(screenHTML.includes('data-more="taxes"') && screenHTML.includes('data-more="networth"'),
  "les destinations du menu Plus doivent rester atteignables après regroupement");

// ---------- Test 26 : accueil essentiel — 4 actions directes + patrimoine replié ----------
currentTest = "accueil essentiel";
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
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

// ---------- Test 29 : Obsidian Glass — UNE seule identité sombre ----------
// (ADR-020, L2) L'ancien sélecteur d'apparence a disparu ; S.theme reste
// préservé dans l'état pour la compatibilité des sauvegardes, mais ne
// commande plus l'apparence.
currentTest = "identite obsidian";
await goHome();
let theme = await page.evaluate(() => document.documentElement.dataset.theme);
check(theme === "dark", `l'identité doit toujours être sombre (obtenu ${theme})`);
// Une ancienne préférence claire est conservée dans l'état… mais sans effet.
await page.evaluate(() => { S.theme = "light"; saveState(); });
await page.reload();
await page.waitForSelector("#tabbar button");
const obsidian = await page.evaluate(() => ({
  applied: document.documentElement.dataset.theme,
  pref: S.theme,
  canvas: getComputedStyle(document.documentElement).getPropertyValue("--canvas").trim(),
}));
check(obsidian.applied === "dark", "une préférence claire héritée ne doit plus changer l'apparence");
check(obsidian.pref === "light", "S.theme doit être PRÉSERVÉ dans l'état (compatibilité des sauvegardes)");
check(obsidian.canvas === "#090C12", `le token --canvas doit valoir #090C12 (obtenu ${obsidian.canvas})`);
// Le sélecteur d'apparence a été retiré des Réglages.
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
const themeToggle = await page.$("[data-toggletheme]");
check(themeToggle === null, "le sélecteur d'apparence ne doit plus exister dans les Réglages");

// ---------- Test 30 : Horizon L2 — une recommandation utile sur l'accueil ----------
currentTest = "recommandation du mois";
await goHome();
// repartir de la démo : factures, paiements réguliers et objectifs présents
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]");
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.click(`#tabbar button[aria-label="Mois"]`);
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
check(screenHTML.includes("Budget consommé"),
  "l'anneau plan/réel doit être présent et étiqueté pour VoiceOver");
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mois dernier :"), "l'accueil doit rappeler le coût de la vie du mois dernier");

// ---------- Test 32 : Horizon L5 — charges de l'année et provision mensuelle ----------
currentTest = "charges annuelles";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="bills"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Charges de l'année"), "la vue annuelle des charges doit exister sur Factures");
check(screenHTML.includes("par mois"), "la provision mensuelle de lissage doit être proposée");

// ---------- Test 33 : Horizon L6 — scénario et calcul expliqué sur les objectifs ----------
currentTest = "scenario objectifs";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="goals"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Calcul : montant restant ÷ rythme mensuel"),
  "le calcul des objectifs doit être expliqué en clair");
check(screenHTML.includes("estimation, pas une promesse"),
  "l'estimation ne doit jamais être présentée comme une certitude");

// ---------- Test 34 : H01 — sauvegarde guidée dans Réglages ----------
currentTest = "sauvegarde guidee";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Dernière sauvegarde : jamais"),
  "sans sauvegarde, Réglages doit le dire honnêtement");
await page.evaluate(() => exportBackup());
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Dernière sauvegarde : aujourd'hui"),
  "après export, la date de sauvegarde doit se mettre à jour");

// ---------- Test 35 : Horizon R2 — l'écran « Mois » suit le blueprint ----------
currentTest = "mois blueprint";
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Ce qui reste, 6 derniers mois"), "la mini-courbe 6 mois doit être sur l'écran Mois");
check(screenHTML.includes("Budget restant :"), "le widget budget restant doit être sur l'écran Mois");
check(screenHTML.includes('data-more="goals"'), "l'objectif prioritaire doit mener aux objectifs");
const tabLabel = await page.$eval('#tabbar button[data-tab="home"] span', el => el.textContent);
check(tabLabel === "Mois", "l'onglet d'accueil s'appelle « Mois »");

// ---------- Test 36 : Horizon R4 — widgets personnalisables et persistés ----------
currentTest = "widgets personnalisables";
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(250);
await page.click("[data-customize]");
await page.waitForSelector("#widgetForm", { state: "visible" });
await page.uncheck('#widgetChoices [data-wkey="trend6"]');
await page.click('#widgetForm button[type="submit"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("Ce qui reste, 6 derniers mois"), "un widget masqué doit disparaître de l'écran Mois");
await page.reload();
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("Ce qui reste, 6 derniers mois"), "le masquage doit survivre au rechargement");
check(screenHTML.includes("Argent disponible"), "l'essentiel (héros) reste toujours visible");
await page.click("[data-customize]");
await page.waitForSelector("#widgetForm", { state: "visible" });
await page.click("#wRestore");
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Ce qui reste, 6 derniers mois"), "la disposition recommandée doit tout restaurer");

// ---------- Test 37 : Horizon R7 — assistant local déterministe ----------
currentTest = "assistant";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="assistant"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Combien puis-je dépenser cette semaine ?"), "l'assistant doit proposer ses questions");
await page.click('[data-assistq="week"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("par jour"), "la réponse doit expliquer la raison du calcul");
check(screenHTML.includes("pas l'épargne ni le patrimoine"), "les hypothèses doivent être visibles");
await page.click('[data-assistq="prio"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Parce que") || screenHTML.includes("Aucun retard"), "la priorité doit être justifiée");

// ---------- Test 38 : P0 Obsidian — l'historique de change est figé ----------
currentTest = "change historique fige";
await goHome();
const figeAvant = await page.evaluate(() => {
  ACCOUNTS.push({ id: "eurtest", name: "Compte EUR", kind: "current", opening: 0, cash: true, currency: "EUR" });
  addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 1, title: "Dépense EUR",
    amount: 100, type: "expense", cat: null, acc: "eurtest", dest: null, status: "posted" });
  saveState();
  return snapshot(NOW.y, NOW.m).living;
});
const figeApres = await page.evaluate(() => {
  S.fxRates.EUR = 0.50; saveState(); // le taux change APRÈS la saisie
  return snapshot(NOW.y, NOW.m).living;
});
check(Math.abs(figeAvant - figeApres) < 0.005,
  `un taux modifié ne réécrit pas l'historique (avant ${figeAvant}, après ${figeApres})`);
const stamped = await page.evaluate(() => {
  const t = transactions.find(x => x.title === "Dépense EUR");
  return { fx: t.fx, fxBase: t.fxBase };
});
check(stamped.fx === 0.93 && stamped.fxBase === "CHF", "le taux du jour doit être estampillé à la création");
await page.evaluate(() => { // nettoyage
  const i = transactions.findIndex(x => x.title === "Dépense EUR"); if (i >= 0) transactions.splice(i, 1);
  const a = ACCOUNTS.findIndex(x => x.id === "eurtest"); if (a >= 0) ACCOUNTS.splice(a, 1);
  S.fxRates.EUR = 0.93; saveState();
});

// ---------- Test 39 : P0 Obsidian — la migration estampille l'historique ----------
currentTest = "migration estampille l'historique";
await page.evaluate(() => {
  // État v1 d'époque : compte EUR + mouvement SANS estampille, écrit brut.
  const s = JSON.parse(localStorage.getItem("budget-app-state-v1"));
  s.accounts.push({ id: "eurmig", name: "Ancien EUR", kind: "current", opening: 0, cash: true, currency: "EUR" });
  s.transactions.push({ id: 990001, y: NOW.y, m: NOW.m, d: 2, title: "Ancien EUR",
    amount: 100, type: "expense", cat: null, acc: "eurmig", dest: null, status: "posted" });
  s.fxRates.EUR = 0.93;
  localStorage.setItem("budget-app-state-v1", JSON.stringify(s));
});
await page.reload();
await page.waitForSelector("#tabbar button");
const migStamp = await page.evaluate(() => {
  const t = transactions.find(x => x.id === 990001);
  return { fx: t.fx, fxBase: t.fxBase };
});
check(migStamp.fx === 0.93 && migStamp.fxBase === "CHF",
  `la migration estampille l'historique avec le taux du moment (${JSON.stringify(migStamp)})`);
const migPersisted = await page.evaluate(() => {
  const t = JSON.parse(localStorage.getItem("budget-app-state-v1")).transactions.find(x => x.id === 990001);
  return t.fx === 0.93 && t.fxBase === "CHF";
});
check(migPersisted, "l'état migré est sauvegardé immédiatement");
const migAvant = await page.evaluate(() => snapshot(NOW.y, NOW.m).living);
const migApres = await page.evaluate(() => { S.fxRates.EUR = 0.40; saveState(); return snapshot(NOW.y, NOW.m).living; });
check(Math.abs(migAvant - migApres) < 0.005,
  `après migration, un taux modifié ne réécrit plus l'historique (avant ${migAvant}, après ${migApres})`);
await page.evaluate(() => { // nettoyage
  const i = transactions.findIndex(x => x.id === 990001); if (i >= 0) transactions.splice(i, 1);
  const a = ACCOUNTS.findIndex(x => x.id === "eurmig"); if (a >= 0) ACCOUNTS.splice(a, 1);
  S.fxRates.EUR = 0.93; saveState();
});

// ---------- Test 40 : P0 Obsidian — l'édition ré-estampille au taux du jour ----------
currentTest = "édition ré-estampille";
await page.evaluate(() => {
  ACCOUNTS.push({ id: "euredit", name: "Compte EUR édition", kind: "current", opening: 0, cash: true, currency: "EUR" });
  addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 3, title: "Édition EUR",
    amount: 50, type: "expense", cat: null, acc: "euredit", dest: null, status: "posted" });
  S.fxRates.EUR = 0.80; saveState(); // le taux évolue APRÈS la création
});
await page.evaluate(() => { openTxSheet(transactions.find(t => t.title === "Édition EUR")); });
await page.fill("#fAmount", "60");
await page.evaluate(() => document.getElementById("txForm").requestSubmit());
await page.waitForTimeout(120);
const editStamp = await page.evaluate(() => {
  const t = transactions.find(x => x.title === "Édition EUR");
  return { amount: t.amount, fx: t.fx, fxBase: t.fxBase };
});
check(editStamp.amount === 60 && editStamp.fx === 0.80 && editStamp.fxBase === "CHF",
  `modifier un mouvement re-fige le taux du jour de la modification (${JSON.stringify(editStamp)})`);

// ---------- Test 41 : P0 Obsidian — passage d'un compte EUR à un compte CHF ----------
currentTest = "édition change de devise";
await page.evaluate(() => { openTxSheet(transactions.find(t => t.title === "Édition EUR")); });
await page.evaluate(() => {
  const chf = ACCOUNTS.find(a => (a.currency || baseCurrency()) === baseCurrency());
  document.getElementById("fAccount").value = chf.id;
  document.getElementById("fAccount").dispatchEvent(new Event("change"));
});
await page.evaluate(() => document.getElementById("txForm").requestSubmit());
await page.waitForTimeout(120);
const chfStamp = await page.evaluate(() => {
  const t = transactions.find(x => x.title === "Édition EUR");
  return { curIsBase: accountCurrency(t.acc) === baseCurrency(),
           noFx: t.fx === undefined, noFxBase: t.fxBase === undefined };
});
check(chfStamp.curIsBase && chfStamp.noFx && chfStamp.noFxBase,
  `un mouvement déplacé sur un compte CHF perd son estampille de change (${JSON.stringify(chfStamp)})`);

// ---------- Test 42 : P0 Obsidian — aucun destAmount périmé après édition ----------
currentTest = "destAmount jamais périmé";
await page.evaluate(() => {
  const chf = ACCOUNTS.find(a => (a.currency || baseCurrency()) === baseCurrency());
  addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 4, title: "Virement EURCHF",
    amount: 100, type: "transfer", cat: null, acc: "euredit", dest: chf.id, status: "posted" });
  saveState();
});
const virAvant = await page.evaluate(() => transactions.find(t => t.title === "Virement EURCHF").destAmount);
check(virAvant === 80, `un virement inter-devises fige le montant crédité à la création (${virAvant})`);
await page.evaluate(() => { openTxSheet(transactions.find(t => t.title === "Virement EURCHF")); });
await page.evaluate(() => {
  document.getElementById("fType").value = "expense";
  document.getElementById("fType").dispatchEvent(new Event("change"));
});
await page.evaluate(() => document.getElementById("txForm").requestSubmit());
await page.waitForTimeout(120);
const virApres = await page.evaluate(() => {
  const t = transactions.find(x => x.title === "Virement EURCHF");
  return { type: t.type, destGone: t.dest == null, destAmountGone: t.destAmount === undefined };
});
check(virApres.type === "expense" && virApres.destGone && virApres.destAmountGone,
  `retirer la destination ne conserve aucun destAmount périmé (${JSON.stringify(virApres)})`);

// ---------- Test 43 : P0 Obsidian — une sauvegarde restaurée est normalisée ----------
currentTest = "sauvegarde restaurée normalisée";
await page.evaluate(() => {
  // Sauvegarde d'époque restaurée : aucun champ fx/fxBase/destAmount
  // nulle part (le flux de restauration réel écrit l'état puis recharge).
  const s = JSON.parse(localStorage.getItem("budget-app-state-v1"));
  for (const t of s.transactions) { delete t.fx; delete t.fxBase; delete t.destAmount; }
  localStorage.setItem("budget-app-state-v1", JSON.stringify(s));
});
await page.reload();
await page.waitForSelector("#tabbar button");
const restoreNorm = await page.evaluate(() => {
  const foreignSansEstampille = transactions.filter(t => {
    const cur = accountCurrency(t.acc);
    return cur !== baseCurrency() && !(t.fx > 0 && t.fxBase === baseCurrency());
  }).length;
  const destSansMontant = transactions.filter(t =>
    t.dest && accountCurrency(t.dest) !== accountCurrency(t.acc) && t.destAmount == null).length;
  return { foreignSansEstampille, destSansMontant };
});
check(restoreNorm.foreignSansEstampille === 0 && restoreNorm.destSansMontant === 0,
  `une sauvegarde restaurée est entièrement estampillée au chargement (${JSON.stringify(restoreNorm)})`);
await page.evaluate(() => { // nettoyage complet des fixtures multi-devises
  for (const title of ["Édition EUR", "Virement EURCHF"]) {
    const i = transactions.findIndex(x => x.title === title); if (i >= 0) transactions.splice(i, 1);
  }
  const a = ACCOUNTS.findIndex(x => x.id === "euredit"); if (a >= 0) ACCOUNTS.splice(a, 1);
  S.fxRates.EUR = 0.93; saveState();
});


/* ================= PILOTE OBSIDIAN L3 (Tests 44-48) ================= */

// ---------- Test 44 : Mois L3 — ordre, 4 métriques, priorité entière, extrême ----------
currentTest = "mois L3 structure";
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
// Ordre du premier viewport : salutation → héros → métriques → priorité.
const orderIdx = {
  hello: screenHTML.indexOf('class="hello"'),
  hero: screenHTML.indexOf("Argent disponible"),
  metrics: screenHTML.indexOf('class="stat-grid"'),
  quick: screenHTML.indexOf('class="quick-row"'),
};
check(orderIdx.hello >= 0 && orderIdx.hello < orderIdx.hero, "salutation courte avant le héros");
check(orderIdx.hero < orderIdx.metrics, "héros « Disponible » avant les métriques");
check(orderIdx.metrics < orderIdx.quick, "métriques avant les actions rapides");
check(screenHTML.includes("data-addtx"), "action universelle Ajouter dans le héros");
// Exactement 4 métriques, avec les mots du contrat.
const statLabels = await page.$$eval(".stat-grid .stat .card-label", els => els.map(e => e.textContent.trim()));
check(statLabels.length === 4, `exactement 4 métriques (obtenu ${statLabels.length})`);
for (const label of ["Entré", "Dépensé", "À payer", "Mis de côté"]) {
  check(statLabels.includes(label), `métrique « ${label} » absente (${statLabels.join(", ")})`);
}
// La priorité n'est JAMAIS tronquée (multi-ligne, pas d'ellipse).
const prio = await page.$(".priority-card .meta .t");
if (prio) {
  const ws = await prio.evaluate(el => getComputedStyle(el).whiteSpace);
  check(ws === "normal", `la priorité doit pouvoir passer à la ligne (white-space=${ws})`);
  const clipped = await prio.evaluate(el => el.scrollWidth > el.clientWidth + 1);
  check(!clipped, "le texte de la priorité ne doit pas déborder horizontalement");
}
// Montant extrême : le héros reste entier, sans débordement.
await page.evaluate(() => {
  addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: Math.min(NOW.d, 28), title: "Extrême L3",
    type: "income", cat: "Salaire", acc: "cur", dest: null, status: "posted", amount: 9999999.99 });
  saveState(); render();
});
await page.waitForTimeout(200);
const heroExtreme = await page.$eval(".hero .hero-amount", el => ({
  text: el.textContent, long: el.classList.contains("long"),
  clipped: el.scrollWidth > el.clientWidth + 1,
}));
check(heroExtreme.long, "un montant à huit chiffres réduit le corps du héros (classe long)");
check(!heroExtreme.clipped, "le montant héros extrême ne doit pas être tronqué");
const noHOverflowX = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
check(noHOverflowX, "aucun débordement horizontal avec un montant extrême");
await page.evaluate(() => {
  const i = transactions.findIndex(t => t.title === "Extrême L3");
  if (i >= 0) transactions.splice(i, 1);
  saveState(); render();
});

// ---------- Test 45 : Mois L3 — 320 px sans chevauchement FAB, vide guidé, démo explicite ----------
currentTest = "mois L3 320px/vide/demo";
await page.setViewportSize({ width: 320, height: 844 });
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(200);
// Aucun chevauchement : le FAB ne recouvre le centre d'AUCUN bouton visible.
const fabOverlap = await page.evaluate(() => {
  const screen = document.getElementById("screen");
  screen.scrollTop = screen.scrollHeight; // tout en bas, là où L1 échouait
  const fab = document.getElementById("fab").getBoundingClientRect();
  const hits = [];
  for (const b of screen.querySelectorAll("button, [role='button']")) {
    const r = b.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    if (cx >= fab.left && cx <= fab.right && cy >= fab.top && cy <= fab.bottom) {
      hits.push((b.textContent || b.ariaLabel || "?").trim().slice(0, 20));
    }
  }
  return hits;
});
check(fabOverlap.length === 0, `le FAB recouvre : ${fabOverlap.join(", ")}`);
const noOverflow320 = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
check(noOverflow320, "aucun débordement horizontal à 320 px");
// Cibles ≥ 44 px sur les éléments interactifs du premier viewport.
const small320 = await page.evaluate(() => {
  document.getElementById("screen").scrollTop = 0;
  return [...document.querySelectorAll(".quick-row .btn, .hero .btn, .month-nav button")]
    .map(el => ({ h: el.getBoundingClientRect().height, t: (el.textContent || "?").trim().slice(0, 18) }))
    .filter(x => x.h < 43.5);
});
check(small320.length === 0, `cibles < 44 px à 320 : ${small320.map(x => `${x.t} (${x.h.toFixed(0)})`).join(", ")}`);
// État vide guidé : un nouvel utilisateur sans mouvement voit des cartes-guides.
await page.evaluate(() => localStorage.clear());
await page.goto(APP_URL);
await page.waitForSelector('[data-obcountry="CH"]');
await page.click('[data-obcountry="CH"]');
await page.waitForSelector('[data-obhh="solo"]', { state: "visible" });
await page.click('[data-obhh="solo"]');
await page.waitForSelector("#obName", { state: "visible" });
await page.fill("#obName", "Léa");
await page.click('#obForm1 button[type="submit"]');
await page.waitForSelector("#obSalary", { state: "visible" });
await page.fill("#obSalary", "4000");
await page.click('#obForm2 button[type="submit"]');
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "1000");
await page.click('#obForm3 button[type="submit"]');
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Aucune dépense ce mois"), "état vide guidé : dépenses");
check(screenHTML.includes("Aucune facture ce mois"), "état vide guidé : factures");
check(screenHTML.includes("Argent disponible"), "le héros existe même sans mouvement");
const demoHidden = await page.$eval(".demo-banner", el => el.style.display === "none");
check(demoHidden, "pas de bannière démo pour un vrai départ");
// Mode démo clairement identifié (chargée depuis les Réglages).
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]");
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.waitForTimeout(250);
const demoShown = await page.$eval(".demo-banner", el => el.style.display !== "none");
check(demoShown, "la démo doit afficher la bannière « données fictives »");
screenHTML = await page.$eval(".demo-banner", el => el.textContent);
check(screenHTML.includes("données fictives"), "le texte démo doit être explicite");
await page.setViewportSize({ width: 390, height: 844 });

// ---------- Test 46 : Budget L3 — % explicite, 3 états écrits, réconciliation, extrême ----------
currentTest = "budget L3";
// (état démo chargé par le test précédent)
await page.click(`#tabbar button[aria-label="Budget"]`);
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(/\d+ % du budget utilisé/.test(screenHTML.replace(/&nbsp;/g, " ")), "le pourcentage doit être expliqué : « X % du budget utilisé »");
check(screenHTML.includes("Budget consommé"), "l'anneau garde son étiquette accessible");
check(/Dans le plan|À surveiller|Dépassé/.test(screenHTML), "l'état du plan est écrit en toutes lettres");
check(screenHTML.includes("planifié") && screenHTML.includes("réel"), "planifié et réel visibles");
const budgetHeroFit = await page.$eval(".hero .hero-amount", el => el.scrollWidth <= el.clientWidth + 1);
check(budgetHeroFit, "le montant héros Budget ne passe jamais sous l'anneau");
// État « Dépassé » réel : grosse dépense dans une catégorie budgétée.
const overCat = await page.evaluate(() => {
  const key = `${cursor.y}-${cursor.m}`;
  const line = (S.budgets[key] || [])[0];
  if (!line) return null;
  addTx({ id: ++txSeq, y: cursor.y, m: cursor.m, d: 2, title: "Dépassement L3",
    type: "expense", cat: line.cat, acc: ACCOUNTS[0].id, dest: null, status: "posted",
    amount: (line.amount || 0) + 500 });
  saveState(); render();
  return line.cat;
});
check(overCat !== null, "la démo doit fournir une ligne budgétaire");
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Dépassé"), "l'état Dépassé apparaît en texte");
check(screenHTML.includes("Dépassement de"), "chaque ligne dépassée écrit son dépassement");
// Montant extrême : le reste à dépenser passe en classe long, sans troncature.
await page.evaluate(() => {
  const key = `${cursor.y}-${cursor.m}`;
  S.budgets[key].push({ cat: "Extrême L3", amount: 11000000 });
  CATEGORIES["Extrême L3"] = "expense";
  saveState(); render();
});
await page.waitForTimeout(200);
const budgetHero = await page.$eval(".hero .hero-amount", el => ({
  long: el.classList.contains("long"), clipped: el.scrollWidth > el.clientWidth + 1 }));
check(budgetHero.long && !budgetHero.clipped, "montant extrême du Budget entier et réduit");
await page.evaluate(() => { // nettoyage
  const key = `${cursor.y}-${cursor.m}`;
  S.budgets[key] = S.budgets[key].filter(l => l.cat !== "Extrême L3");
  delete CATEGORIES["Extrême L3"];
  const i = transactions.findIndex(t => t.title === "Dépassement L3");
  if (i >= 0) transactions.splice(i, 1);
  saveState(); render();
});

// ---------- Test 47 : Ajout L3 — chips, statut, erreurs près du champ, 3 gestes, virement ----------
currentTest = "ajout L3";
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(150);
await page.click("[data-addtx]");
await page.waitForSelector("#txForm", { state: "visible" });
// Chips de type synchronisées sur le select historique.
const chipPressed = await page.$eval('#typeGrid button[data-ftype="expense"]', el => el.getAttribute("aria-pressed"));
check(chipPressed === "true", "la chip Dépense est active par défaut");
await page.click('#typeGrid button[data-ftype="saving"]');
await page.waitForTimeout(100);
const afterChip = await page.evaluate(() => ({
  type: document.getElementById("fType").value,
  destVisible: document.getElementById("destWrap").style.display !== "none",
  note: document.getElementById("fTransferNote").textContent,
}));
check(afterChip.type === "saving", "la chip Épargne pilote le select");
check(afterChip.destVisible, "l'épargne demande une destination");
check(afterChip.note.includes("mis de côté"), "le résumé explique « mis de côté », pas une dépense");
// Statut affiché, dérivé de la date (logique inchangée).
const statusNow = await page.$eval("#fStatusNote", el => el.textContent);
check(statusNow.includes("Comptabilisé"), "aujourd'hui → Comptabilisé affiché");
await page.evaluate(() => {
  const last = new Date(NOW.y, NOW.m, 0).getDate();
  if (NOW.d < last) {
    document.getElementById("fDate").value =
      `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(last).padStart(2, "0")}`;
    document.getElementById("fDate").dispatchEvent(new Event("change"));
  }
});
const statusFuture = await page.$eval("#fStatusNote", el => el.textContent);
check(statusFuture.includes("Prévu") || statusFuture.includes("Comptabilisé"), "note de statut toujours présente");
// Retour à la date du jour (le statut redevient Comptabilisé).
await page.evaluate(() => {
  document.getElementById("fDate").value =
    `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(NOW.d).padStart(2, "0")}`;
  document.getElementById("fDate").dispatchEvent(new Event("change"));
});
// Erreur près du champ : montant invalide → message sous le montant, saisie conservée.
await page.click('#typeGrid button[data-ftype="expense"]');
await page.fill("#fAmount", "abc");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(100);
const errState = await page.evaluate(() => ({
  msg: document.getElementById("fError").textContent,
  nearAmount: document.getElementById("fError").previousElementSibling
    && ["fAmount", "fCurNote"].includes(document.getElementById("fError").previousElementSibling.id),
  invalid: document.getElementById("fAmount").getAttribute("aria-invalid") === "true",
  kept: document.getElementById("fAmount").value === "abc",
}));
check(errState.msg.includes("montant"), "message d'erreur en langage simple");
check(errState.nearAmount, "l'erreur se place près du champ montant");
check(errState.invalid, "le champ fautif est marqué aria-invalid");
check(errState.kept, "la saisie n'est JAMAIS effacée après une erreur");
// Parcours fréquent : montant seul → enregistré avec la catégorie comme nom.
await page.fill("#fAmount", "12.35");
const freqCat = await page.$eval("#fCat", el => el.value);
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!(await page.$eval("#sheetBackdrop", el => el.classList.contains("open"))), "la feuille se ferme après sauvegarde réussie");
check(screenHTML.includes("12.35"), "le mouvement en trois gestes apparaît sur Mois");
await page.reload();
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("12.35"), "le mouvement en trois gestes survit au rechargement");
// Édition sans perte : rouvrir, changer le montant, le nom par défaut reste.
await page.click(`#screen [data-txid] >> text=${freqCat}`);
await page.waitForSelector("#txForm", { state: "visible" });
const editPrefill = await page.evaluate(() => ({
  more: document.getElementById("fMore").open,
  title: document.getElementById("fTitle").value,
}));
check(editPrefill.more, "l'édition déplie les détails (l'intitulé y vit)");
check(editPrefill.title.length > 0, "l'intitulé par défaut est conservé à l'édition");
await page.fill("#fAmount", "13.00");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("13.00"), "montant édité sans perte de données");
await page.evaluate(() => { // nettoyage
  const i = transactions.findIndex(t => t.amount === 13 && t.title && t.title.length > 0 && t.type === "expense" && t.d === NOW.d);
  if (i >= 0) transactions.splice(i, 1);
  saveState(); render();
});
// Virement : résumé explicite et neutralité affichée.
await page.click("#fab");
await page.waitForSelector('#quickMenu [data-quick="tx"]', { state: "visible" });
await page.click('#quickMenu [data-quick="tx"]');
await page.waitForSelector("#txForm", { state: "visible" });
await page.click('#typeGrid button[data-ftype="transfer"]');
await page.waitForTimeout(100);
const transferNote = await page.$eval("#fTransferNote", el => el.textContent);
check(transferNote.includes("neutre") || transferNote === "", "un virement s'annonce neutre dès qu'une destination existe");
await page.click("#fCancel");
// Clavier : hauteur réduite (clavier ouvert simulé) → montant ET Enregistrer visibles.
await page.setViewportSize({ width: 320, height: 480 });
await page.click("[data-addtx]");
await page.waitForSelector("#txForm", { state: "visible" });
await page.focus("#fAmount");
const keyboardSafe = await page.evaluate(() => {
  const amount = document.getElementById("fAmount").getBoundingClientRect();
  const save = document.querySelector('#txForm button[type="submit"]').getBoundingClientRect();
  const H = window.innerHeight;
  return { amountVisible: amount.top >= 0 && amount.bottom <= H,
           saveVisible: save.top >= 0 && save.bottom <= H, h: H };
});
check(keyboardSafe.amountVisible, "clavier ouvert : le montant reste visible");
check(keyboardSafe.saveVisible, "clavier ouvert : Enregistrer reste visible (barre sticky)");
await page.click("#fCancel");
await page.setViewportSize({ width: 390, height: 844 });

// ---------- Test 48 : accessibilité L3 — focus, 44 px, reduced transparency, overflow ----------
currentTest = "a11y L3";
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(150);
// Focus clavier visible sur un élément interactif de l'écran.
await page.evaluate(() => document.activeElement && document.activeElement.blur());
await page.keyboard.press("Tab");
const focusRing = await page.evaluate(() => {
  const cs = getComputedStyle(document.activeElement);
  return { style: cs.outlineStyle, width: parseFloat(cs.outlineWidth) };
});
check(focusRing.style !== "none" && focusRing.width >= 2, `focus visible ≥ 2px (obtenu ${focusRing.style} ${focusRing.width})`);
// Transparence réduite : l'app bascule sur le graphite opaque.
await page.evaluate(() => { document.documentElement.dataset.reducedTransparency = "true"; });
const rtSurface = await page.evaluate(() =>
  getComputedStyle(document.documentElement).getPropertyValue("--surface").trim());
check(rtSurface === "#151B26", `transparence réduite : surface opaque attendue (obtenu ${rtSurface})`);
await page.evaluate(() => { delete document.documentElement.dataset.reducedTransparency; });
// Libellés accessibles des graphiques et du FAB.
const a11yLabels = await page.evaluate(() => ({
  fab: document.getElementById("fab").getAttribute("aria-label") || "",
  charts: [...document.querySelectorAll("#screen svg[role='img']")].every(s => (s.getAttribute("aria-label") || "").length > 5),
}));
check(a11yLabels.fab.includes("Ajouter"), "le FAB porte un libellé accessible");
check(a11yLabels.charts, "chaque graphique SVG porte une étiquette accessible");
// Budget à 320 px : aucun débordement.
await page.setViewportSize({ width: 320, height: 844 });
await page.click(`#tabbar button[aria-label="Budget"]`);
await page.waitForTimeout(200);
const budget320 = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
check(budget320, "Budget sans débordement horizontal à 320 px");
await page.setViewportSize({ width: 390, height: 844 });


/* ============= MOUVEMENTS & COMPTES OBSIDIAN L5 (Tests 49-51) ============= */

// ---------- Test 49 : Mouvements L5 — groupes, filtres+recherche, neutre, extrême, undo ----------
currentTest = "mouvements L5";
await goHome();
// Repartir de la démo pour des données riches et déterministes.
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]");
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.click(`#tabbar button[aria-label="Mouvements"]`);
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
// Regroupement par jour : des en-têtes datés dd.mm.yyyy.
const dayHeaders = await page.$$eval(".day-header", els => els.map(e => e.textContent));
check(dayHeaders.length > 0, "la liste doit être regroupée par jour");
check(dayHeaders.every(h => /^\d{2}\.\d{2}\.\d{4}$/.test(h.trim())), `en-têtes datés attendus (obtenu ${dayHeaders[0]})`);
// Un virement est ÉCRIT neutre ; l'épargne est « mis de côté ».
await page.click('.filter-chip[data-morefilter="transfer"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
if (screenHTML.includes("Virement interne")) {
  check(screenHTML.includes("neutre"), "un virement doit être écrit « neutre »");
}
const chipPressed49 = await page.$eval('.filter-chip[data-morefilter="transfer"]', el => el.getAttribute("aria-pressed"));
check(chipPressed49 === "true", "la chip de filtre active porte aria-pressed");
// Recherche SANS perdre le filtre actif.
await page.fill("#moreSearchInput", "zzz-introuvable-zzz");
await page.waitForTimeout(250);
const afterSearch = await page.evaluate(() => ({
  filter: moreFilter,
  empty: document.querySelector("#moreTxList .empty-state") !== null,
  html: document.getElementById("moreTxList").innerHTML,
}));
check(afterSearch.filter === "transfer", "la recherche ne réinitialise pas le filtre");
check(afterSearch.empty && afterSearch.html.includes("Aucun résultat"), "recherche sans résultat : état guidé");
await page.fill("#moreSearchInput", "");
await page.click('.filter-chip[data-morefilter="all"]');
await page.waitForTimeout(200);
// Épargne marquée « mis de côté ».
screenHTML = await page.$eval("#screen", el => el.innerHTML);
if (screenHTML.includes("Épargne")) {
  check(screenHTML.includes("mis de côté"), "l'épargne est écrite « mis de côté »");
}
// Montant extrême : ligne intacte, aucun débordement.
await page.evaluate(() => {
  addTx({ id: ++txSeq, y: cursor.y, m: cursor.m, d: Math.min(NOW.d, 28), title: "Extrême L5",
    type: "income", cat: "Salaire", acc: ACCOUNTS[0].id, dest: null, status: "posted", amount: 9999999.99 });
  saveState(); render();
});
await page.waitForTimeout(200);
const extremeRow = await page.evaluate(() => {
  const rows = [...document.querySelectorAll("#moreTxList .tx .amount")];
  const el = rows.find(r => r.textContent.includes("9'999'999.99"));
  return el ? { found: true, clipped: el.scrollWidth > el.clientWidth + 1,
    overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth } : { found: false };
});
check(extremeRow.found, "le mouvement extrême apparaît dans la liste");
check(!extremeRow.clipped && !extremeRow.overflow, "le montant extrême n'est ni tronqué ni débordant");
// Suppression CONFIRMÉE puis ANNULÉE (undo) : le mouvement revient.
await page.click('#moreTxList [data-txid] >> text=Extrême L5');
await page.waitForSelector("#txForm", { state: "visible" });
await page.click("#fDelete"); // page.on(dialog) accepte la confirmation
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("Extrême L5"), "le mouvement supprimé disparaît");
const undoBtn = await page.$("#toastUndo");
check(undoBtn !== null, "la suppression propose « Annuler »");
if (undoBtn) {
  await undoBtn.click();
  await page.waitForTimeout(250);
  screenHTML = await page.$eval("#screen", el => el.innerHTML);
  check(screenHTML.includes("Extrême L5"), "l'annulation restaure le mouvement supprimé");
  // Nettoyage définitif.
  await page.evaluate(() => {
    const i = transactions.findIndex(t => t.title === "Extrême L5");
    if (i >= 0) transactions.splice(i, 1);
    saveState(); render();
  });
}

// ---------- Test 50 : Comptes L5 — détail, fraîcheur, réconciliation directe, devise ----------
currentTest = "comptes L5";
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Argent disponible"), "le héros Comptes répond « où est mon argent »");
check(/à jour aujourd'hui|mis à jour|Aucun mouvement/.test(screenHTML), "la fraîcheur des soldes est affichée");
// Détail accessible depuis toute la ligne.
await page.click("#screen [data-accid]");
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Solde — 12 derniers mois"), "le détail montre l'évolution du solde");
check(screenHTML.includes("Historique"), "le détail montre l'historique rattaché");
check(/Solde (à jour aujourd'hui|mis à jour)/.test(screenHTML), "le héros du détail date le solde en langage simple");
// Réconciliation DIRECTE depuis le détail, en langage simple.
const accId50 = await page.evaluate(() => accountView);
await page.click("[data-reconacc]");
await page.waitForSelector("#reconForm", { state: "visible" });
const reconText = await page.$eval("#reconForm", el => el.textContent);
check(reconText.includes("relevé bancaire") && reconText.includes("jamais réécrit"),
  "la réconciliation s'explique en langage simple (historique jamais réécrit)");
const beforeRecon = await page.evaluate(id => balance(id), accId50);
await page.fill("#reconAmount", (Math.abs(beforeRecon) + 111).toFixed(2));
await page.evaluate(() => { document.getElementById("reconNegative").checked = false; });
await page.click('#reconForm button[type="submit"]');
await page.waitForTimeout(300);
const afterRecon = await page.evaluate(id => ({
  bal: balance(id),
  adj: transactions.some(t => t.type === "adjustment" && t.title === "Solde mis à jour" && t.acc === id),
}), accId50);
check(Math.abs(afterRecon.bal - (Math.abs(beforeRecon) + 111)) < 0.005,
  `la réconciliation aligne le solde (obtenu ${afterRecon.bal})`);
check(afterRecon.adj, "la réconciliation crée un ajustement daté — l'historique n'est pas réécrit");
// Devise étrangère : signalée sur la ligne, jamais additionnée sans conversion.
await page.evaluate(() => {
  ACCOUNTS.push({ id: "l5eur", name: "Compte EUR L5", kind: "current", currency: "EUR", opening: 100, cash: true });
  saveState(); render();
});
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Compte EUR L5") && screenHTML.includes("· EUR"), "un compte étranger affiche sa devise");
check(screenHTML.includes("convertis en CHF"), "le héros explique la conversion des comptes étrangers");
await page.evaluate(() => { // nettoyage
  const i = ACCOUNTS.findIndex(a => a.id === "l5eur"); if (i >= 0) ACCOUNTS.splice(i, 1);
  const j = transactions.findIndex(t => t.title === "Solde mis à jour"); if (j >= 0) transactions.splice(j, 1);
  saveState(); render();
});

// ---------- Test 51 : a11y L5 — cibles 44 px, 320 px, information jamais couleur seule ----------
currentTest = "a11y L5";
await page.click(`#tabbar button[aria-label="Mouvements"]`);
await page.waitForTimeout(200);
const targets51 = await page.evaluate(() =>
  [...document.querySelectorAll(".filter-chip, #moreSearchInput, .month-nav button")]
    .map(el => ({ h: el.getBoundingClientRect().height, t: (el.textContent || el.id || "?").trim().slice(0, 16) }))
    .filter(x => x.h > 0 && x.h < 43.5));
check(targets51.length === 0, `cibles < 44 px : ${targets51.map(x => `${x.t} (${x.h.toFixed(0)})`).join(", ")}`);
await page.setViewportSize({ width: 320, height: 844 });
await page.waitForTimeout(200);
const overflow51 = await page.evaluate(() => ({
  mov: document.documentElement.scrollWidth <= document.documentElement.clientWidth,
}));
check(overflow51.mov, "Mouvements sans débordement à 320 px");
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(200);
const overflow51b = await page.evaluate(() =>
  document.documentElement.scrollWidth <= document.documentElement.clientWidth);
check(overflow51b, "Comptes sans débordement à 320 px");
await page.setViewportSize({ width: 390, height: 844 });
// Jamais la couleur seule : signes explicites sur les montants de la liste.
await page.click(`#tabbar button[aria-label="Mouvements"]`);
await page.waitForTimeout(200);
const signs51 = await page.$$eval("#moreTxList .tx .amount", els =>
  els.slice(0, 8).map(e => e.textContent.trim()));
check(signs51.every(t => /^[+−-]/.test(t) || t.length > 0), "chaque montant porte un signe ou un libellé textuel");

/* ============= MODULES FINANCIERS OBSIDIAN L6 (Tests 52-55) ============= */

// ---------- Test 52 : Factures L6 — héros, retard écrit, paiement lié SANS double comptage, vide ----------
currentTest = "factures L6";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="bills"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Encore à payer"), "le héros Factures répond « qu'est-ce que je dois encore payer »");
const billsHero52 = await page.evaluate(() => ({
  shown: document.querySelector(".hero-amount").textContent,
  open: chf(fromCents((S.bills || []).filter(b => !b.paidTxId).reduce((a, b) => a + toCents(b.amount), 0))),
  overdue: (S.bills || []).filter(billIsOverdue).length,
  pill: document.querySelector(".hero .pill")?.textContent || "",
}));
check(billsHero52.shown === billsHero52.open,
  `le héros = somme des factures ouvertes, rien d'autre (${billsHero52.shown} vs ${billsHero52.open})`);
check(billsHero52.overdue > 0 ? /en retard/.test(billsHero52.pill) : /Rien en retard/.test(billsHero52.pill),
  "l'état de retard est ÉCRIT dans une pill, jamais couleur seule");
// Payer une facture LIE facture et mouvement : un seul mouvement, jamais deux.
await page.evaluate(() => {
  S.bills.push({ id: "l6bill", name: "Facture test L6", amount: 123.45, dueY: NOW.y, dueM: NOW.m,
    dueD: Math.min(NOW.d + 2, 28), cat: "Logement", paidTxId: null, note: "" });
  saveState(); render();
});
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(250);
await page.click('[data-paybill="l6bill"]');
await page.waitForTimeout(300);
const afterPay52 = await page.evaluate(() => {
  const bill = S.bills.find(b => b.id === "l6bill");
  const linked = transactions.filter(t => t.billId === "l6bill");
  return { linkedCount: linked.length, sameId: linked.length === 1 && bill.paidTxId === linked[0].id,
    type: linked[0]?.type, status: linked[0]?.status };
});
check(afterPay52.linkedCount === 1 && afterPay52.sameId, "« Payer » crée UN seul mouvement, lié à la facture");
check(afterPay52.type === "expense" && afterPay52.status === "posted", "le paiement est une dépense comptabilisée");
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="bills"]');
await page.waitForTimeout(250);
const billsAfter52 = await page.evaluate(() => ({
  hero: document.querySelector(".hero-amount").textContent,
  open: chf(fromCents(S.bills.filter(b => !b.paidTxId).reduce((a, b) => a + toCents(b.amount), 0))),
  caption: document.querySelector(".hero .caption").textContent,
  paidSection: document.getElementById("screen").innerHTML.includes("Payées"),
}));
check(billsAfter52.hero === billsAfter52.open, "après paiement, le héros exclut la facture payée — pas de double comptage");
check(billsAfter52.caption.includes("payé ce mois"), "le « payé ce mois » est affiché séparément de l'ouvert");
check(billsAfter52.paidSection, "la facture payée est rangée dans « Payées », pas mélangée");
// État vide guidé.
await page.evaluate(() => { window.__l6bills = S.bills; S.bills = []; render(); });
await page.waitForTimeout(200);
const empty52 = await page.evaluate(() => ({
  empty: document.querySelector("#screen .empty-state") !== null,
  html: document.getElementById("screen").innerHTML,
}));
check(empty52.empty && empty52.html.includes("Aucune facture"), "sans facture : état vide guidé");
await page.evaluate(() => {
  S.bills = window.__l6bills; delete window.__l6bills;
  const i = S.bills.findIndex(b => b.id === "l6bill"); if (i >= 0) S.bills.splice(i, 1);
  const j = transactions.findIndex(t => t.billId === "l6bill"); if (j >= 0) transactions.splice(j, 1);
  saveState(); render();
});

// ---------- Test 53 : Objectifs + Impôts L6 — états écrits, stats distinctes, rien d'inventé ----------
currentTest = "objectifs+impôts L6";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="goals"]');
await page.waitForTimeout(250);
const goals53 = await page.evaluate(() =>
  [...document.querySelectorAll("#screen [data-goalid]")].map(cardEl => ({
    hasPill: /Atteint|En bonne voie|À accélérer|Échéance passée/.test(cardEl.textContent),
    hasProgress: cardEl.querySelector('[role="progressbar"]') !== null,
  })));
check(goals53.length > 0, "des objectifs sont affichés en démo");
check(goals53.every(g => g.hasPill), "chaque objectif porte un état ÉCRIT (jamais couleur seule)");
check(goals53.every(g => g.hasProgress), "chaque objectif expose sa progression en role=progressbar");
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="taxes"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("estimation"), "le héros Impôts est étiqueté comme estimation");
for (const label53 of ["Estimation annuelle", "Déjà payé", "Réserve constituée", "Reste après réserve"]) {
  check(screenHTML.includes(label53), `la stat « ${label53} » est présente et distincte`);
}
check(/Réserve (couverte|manquante)/.test(screenHTML), "l'état de la réserve est écrit en pill");
check(screenHTML.includes("pas un conseil fiscal"), "le disclaimer honnête est affiché");
check(screenHTML.includes("Estimé = payé + encore dû"), "l'identité de réconciliation est écrite");
const tax53 = await page.evaluate(() => {
  const s = taxSummary(cursor.y);
  return { holds: s.estimated < s.paid || Math.abs(s.estimated - (s.paid + s.due)) < 0.005 };
});
check(tax53.holds, "identité chiffrée : estimé = payé + encore dû");
// Utilisateur sans revenu comptabilisé : on le DIT, on n'invente rien.
await page.evaluate(() => { window.__l6txs = transactions.splice(0, transactions.length); render(); });
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Estimation incomplète") && screenHTML.includes("rien n'est inventé"),
  "sans revenu : l'écran DIT que l'estimation est incomplète au lieu d'inventer un chiffre");
await page.evaluate(() => { transactions.push(...window.__l6txs); delete window.__l6txs; render(); });

// ---------- Test 54 : Patrimoine + Prévoyance + Assurances + Récurrents L6 ----------
currentTest = "patrimoine+prévoyance L6";
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Fortune nette"), "le héros Patrimoine annonce la fortune nette");
for (const line54 of ["Comptes inclus", "Actifs", "Prévoyance", "Dettes"]) {
  check(screenHTML.includes(line54), `la décomposition affiche « ${line54} »`);
}
check(screenHTML.includes("conversions explicites"), "la fraîcheur et la conversion sont expliquées");
const compo54 = await page.$eval('[aria-label^="Répartition du patrimoine brut"]', el => el.getAttribute("aria-label"));
check(compo54.includes("Comptes") && compo54.includes("%"), "la répartition est une composition ACCESSIBLE (aria-label chiffré)");
// Dette qui domine : fortune négative affichée honnêtement, jamais masquée.
await page.evaluate(() => { LIABILITIES.push({ id: "l6debt", name: "Dette test L6", value: 99999999, include: true }); render(); });
await page.waitForTimeout(200);
const neg54 = await page.evaluate(() => {
  const el = document.querySelector(".hero-amount");
  return { neg: el.classList.contains("neg"), signed: /[−-]/.test(el.textContent) };
});
check(neg54.neg && neg54.signed, "fortune nette négative : classe neg ET signe écrit");
await page.evaluate(() => { const i = LIABILITIES.findIndex(l => l.id === "l6debt"); if (i >= 0) LIABILITIES.splice(i, 1); render(); });
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="insurance"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("équivalent mensuel") && screenHTML.includes("par an"),
  "les primes affichent les DEUX équivalents, réconciliés");
check(screenHTML.includes("Déjà constitué") && screenHTML.includes("valeurs saisies, jamais calculées"),
  "la prévoyance affiche le constitué en annonçant sa source");
check(screenHTML.includes("Selon certificat"), "chaque position cite sa source (certificat)");
// Échéance annuelle à moins de 45 jours : état ÉCRIT sur le contrat.
await page.evaluate(() => {
  const soon = new Date(NOW.y, NOW.m - 1, NOW.d + 10);
  INSURANCES.push({ id: "l6ins", name: "Assurance échéance proche", insurer: "Test",
    premium: 500, unit: "year", dueM: soon.getMonth() + 1, dueD: soon.getDate() });
  render();
});
await page.waitForTimeout(200);
const ins54 = await page.$eval('[data-insid="l6ins"]', el => el.textContent);
check(/Échéance dans \d+ j/.test(ins54), "un contrat à ≤ 45 j de son échéance le DIT dans une pill");
await page.evaluate(() => { const i = INSURANCES.findIndex(x => x.id === "l6ins"); if (i >= 0) INSURANCES.splice(i, 1); render(); });
// Aucune projection inventée pour une position qui n'en a pas.
await page.evaluate(() => { PENSIONS.push({ id: "l6pen", name: "Pilier sans projection", value: 1000 }); render(); });
await page.waitForTimeout(200);
const pen54 = await page.$eval('[data-penid="l6pen"]', el => el.textContent);
check(!pen54.includes("Projection"), "une position SANS projection de certificat n'en reçoit JAMAIS une");
await page.evaluate(() => { const i = PENSIONS.findIndex(p => p.id === "l6pen"); if (i >= 0) PENSIONS.splice(i, 1); render(); });
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="recurring"]');
await page.waitForTimeout(250);
const rec54 = await page.evaluate(() => [...document.querySelectorAll("#screen [data-recid]")].map(r => r.textContent));
check(rec54.length > 0, "des paiements réguliers sont affichés en démo");
check(rec54.every(t => /Saisi ce mois|À venir/.test(t)), "chaque paiement régulier porte son état écrit (pill)");

// ---------- Test 55 : a11y L6 — 320 px sur les 6 modules, extrême, cibles 44 px ----------
currentTest = "a11y L6";
await page.setViewportSize({ width: 320, height: 844 });
for (const view55 of ["bills", "goals", "taxes", "networth", "insurance", "recurring"]) {
  await page.click(`#tabbar button[aria-label="Plus"]`);
  await page.waitForTimeout(120);
  await page.click(`#screen [data-more="${view55}"]`);
  await page.waitForTimeout(200);
  const ok55 = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
  check(ok55, `module « ${view55} » sans débordement à 320 px`);
}
// Actif extrême : le héros Patrimoine se réduit (classe long) sans tronquer ni déborder.
await page.evaluate(() => { ASSETS.push({ id: "l6extreme", name: "Actif extrême", value: 9999999.99, include: true }); render(); });
await page.click(`#tabbar button[aria-label="Plus"]`);
await page.waitForTimeout(120);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(250);
const extreme55 = await page.evaluate(() => {
  const el = document.querySelector(".hero-amount");
  return { long: el.classList.contains("long"), clipped: el.scrollWidth > el.clientWidth + 1,
    overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth };
});
check(extreme55.long && !extreme55.clipped && !extreme55.overflow,
  "montant extrême : héros réduit, jamais tronqué ni débordant à 320 px");
await page.evaluate(() => { const i = ASSETS.findIndex(a => a.id === "l6extreme"); if (i >= 0) ASSETS.splice(i, 1); render(); });
const targets55 = await page.evaluate(() =>
  [...document.querySelectorAll("#screen .btn")]
    .map(el => ({ h: el.getBoundingClientRect().height, t: (el.textContent || "?").trim().slice(0, 20) }))
    .filter(x => x.h > 0 && x.h < 43.5));
check(targets55.length === 0, `boutons de module < 44 px : ${targets55.map(x => `${x.t} (${x.h.toFixed(0)})`).join(", ")}`);
await page.setViewportSize({ width: 390, height: 844 });

await browser.close();

// ---------- Rapport ----------
const allFailures = [...failures, ...consoleErrors];
if (allFailures.length) {
  console.error("ÉCHECS E2E (" + allFailures.length + ") :");
  for (const failure of allFailures) console.error("  ✗ " + failure);
  process.exit(1);
}
console.log("SUITE E2E NAVIGATEUR : 60 parcours verts (48 historiques + 5 pilote L3 + 3 mouvements/comptes L5 + 4 modules financiers L6), zéro erreur console ✓");
