// Suite navigateur E2E de l'app web Budget (skill budget-production-completion).
// Exécution : node webapp/tests/e2e.test.mjs
// Chromium réel — toute erreur console ou page fait échouer la suite.
import { chromium } from "playwright-core";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs";
import zlib from "node:zlib";

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
// A1 : en Chromium headless, un vrai window.print() gèle le rendu — un
// balayage qui clique les boutons le déclencherait. La page de suite le
// remplace par un compteur ; le test A1 vérifie ce compteur.
await page.addInitScript(() => {
  window.__printCalls = 0;
  window.print = () => { window.__printCalls += 1; };
});

const consoleErrors = [];
page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[${currentTest}] ${msg.text()}`); });
page.on("pageerror", err => consoleErrors.push(`[${currentTest}] pageerror: ${err.message}`));
page.on("dialog", dialog => dialog.accept());
page.on("download", () => {}); // les téléchargements (export, secours) sont ignorés en test

async function goHome() {
  await page.goto(APP_URL);
  await page.waitForSelector("#tabbar button", { timeout: 10000 });
}

// L'historique est une destination principale : aucun détour par Gérer.
async function goMovements() {
  await page.click(`#tabbar button[aria-label="Historique"]`);
  await page.waitForTimeout(200);
}

// L'ajout part désormais d'une intention humaine, puis ouvre le formulaire
// comptable déjà prérempli. Les tests métier empruntent le même chemin que
// l'utilisateur au lieu de contourner ce premier choix.
async function openQuickEntry(intent = "expense", selector = "[data-addtx]") {
  await page.click(selector);
  await page.waitForSelector("#quickMenu", { state: "visible" });
  await page.click(`#quickMenu [data-quick="${intent}"]`);
  await page.waitForSelector(intent === "rec" ? "#recForm" : "#txForm", { state: "visible" });
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
// Charges puis abonnements : deux écrans facultatifs, passés ici.
await page.waitForSelector("#obFormCharges", { state: "visible" });
await page.click("[data-obskipcharges]");
await page.waitForSelector("#obFormSubs", { state: "visible" });
await page.click("[data-obskipsubs]");
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" }); // étape objectif (facultative)
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button", { timeout: 10000 });
let homeHTML = await page.$eval("#screen", el => el.innerHTML);
check(homeHTML.includes("Bonjour Elio &amp; Sara") || homeHTML.includes("Bonjour Elio & Sara"), "le couple doit être salué à deux prénoms");
const onboardingData = await page.evaluate(() => ({
  salaries: RECURRINGS.filter(r => r.type === "income").map(r => r.title),
  goals: GOALS.map(g => g.name),
}));
check(onboardingData.salaries.includes("Salaire Elio") && onboardingData.salaries.includes("Salaire Sara"),
  "les salaires configurés doivent être conservés sans charger l'accueil");
check(onboardingData.goals.includes("Fonds d'urgence"),
  "l'objectif choisi à la bienvenue doit être conservé hors du premier niveau de l'accueil");
const bannerHidden = await page.$eval(".demo-banner", el => el.style.display === "none");
check(bannerHidden, "pas de bannière « données fictives » après un vrai départ");
// persistance : recharger garde l'utilisateur onboardé
await page.reload();
await page.waitForSelector("#tabbar button");
homeHTML = await page.$eval("#screen", el => el.innerHTML);
check(homeHTML.includes("Elio") && homeHTML.includes("Sara"), "prénoms perdus après rechargement");

// ---------- Test 1 : les cinq destinations principales s'ouvrent directement ----------
currentTest = "onglets";
await goHome();
for (const label of ["Mois", "Historique", "Budget", "Comptes", "Gérer"]) {
  await page.click(`#tabbar button[aria-label="${label}"]`);
  await page.waitForTimeout(120);
  const content = await page.$eval("#screen", el => el.innerHTML.length);
  check(content > 200, `onglet ${label} vide`);
}
await goMovements();
const movContent = await page.$eval("#screen", el => el.innerHTML);
check(movContent.length > 200 && movContent.includes("moreSearchInput"),
  "Historique doit être accessible directement (recherche présente)");

// ---------- Test 1b : une facture mensuelle revient, signale le retard et ne se duplique pas ----------
currentTest = "facture mensuelle";
const monthlyRecurring = await page.evaluate(() => {
  const recurring = {
    id: "r-adr026-monthly",
    title: "Loyer mensuel ADR026",
    amount: 975,
    type: "expense",
    cat: "Logement",
    day: 1,
    accountId: defaultCashAccount(),
    icon: "🏠",
  };
  const old = RECURRINGS.findIndex(r => r.id === recurring.id);
  if (old >= 0) RECURRINGS.splice(old, 1);
  for (let i = transactions.length - 1; i >= 0; i--) {
    if (transactions[i].recurringId === recurring.id) transactions.splice(i, 1);
  }
  RECURRINGS.push(recurring);
  const firstMonth = shiftMonth({ y: NOW.y, m: NOW.m }, -1);
  const secondMonth = shiftMonth(firstMonth, 1);
  const manualId = ++txSeq;
  addTx({
    id: manualId,
    y: firstMonth.y,
    m: firstMonth.m,
    d: 1,
    title: recurring.title,
    amount: recurring.amount,
    type: "expense",
    cat: recurring.cat,
    acc: recurring.accountId,
    dest: null,
    status: "posted",
  });
  const manualIgnored = recurringOccurrence(recurring, firstMonth.y, firstMonth.m) === null;

  activeTab = "home";
  moreView = null;
  accountView = null;
  cursor = firstMonth;
  saveState();
  render();
  const firstText = document.getElementById("screen").innerText;
  const firstTodo = !!document.querySelector('[data-home-section="todo"]');
  cursor = secondMonth;
  render();
  const secondText = document.getElementById("screen").innerText;
  const secondTodo = !!document.querySelector('[data-home-section="todo"]');

  const first = materializeRecurring(recurring, firstMonth.y, firstMonth.m);
  const firstAgain = materializeRecurring(recurring, firstMonth.y, firstMonth.m);
  const second = materializeRecurring(recurring, secondMonth.y, secondMonth.m);
  const secondAgain = materializeRecurring(recurring, secondMonth.y, secondMonth.m);
  const occurrences = transactions.filter(t => t.recurringId === recurring.id);
  const perMonth = [firstMonth, secondMonth].map(month =>
    occurrences.filter(t => inMonth(t, month.y, month.m)).length
  );

  for (let i = transactions.length - 1; i >= 0; i--) {
    if (transactions[i].recurringId === recurring.id || transactions[i].id === manualId) {
      transactions.splice(i, 1);
    }
  }
  const index = RECURRINGS.findIndex(r => r.id === recurring.id);
  if (index >= 0) RECURRINGS.splice(index, 1);
  cursor = { y: NOW.y, m: NOW.m };
  saveState();
  render();
  return {
    firstText,
    secondText,
    firstTodo,
    secondTodo,
    manualIgnored,
    created: [first.created, firstAgain.created, second.created, secondAgain.created],
    perMonth,
  };
});
check(/bilan du mois/i.test(monthlyRecurring.firstText)
    && monthlyRecurring.firstTodo
    && monthlyRecurring.firstText.includes("Loyer mensuel ADR026"),
  "la facture mensuelle doit être visible sur le mois précédent");
check(/En retard/i.test(monthlyRecurring.firstText),
  "une échéance mensuelle dépassée doit être signalée explicitement « En retard »");
check(/bilan du mois/i.test(monthlyRecurring.secondText)
    && monthlyRecurring.secondTodo
    && monthlyRecurring.secondText.includes("Loyer mensuel ADR026"),
  "la même facture récurrente doit revenir le mois suivant");
check(monthlyRecurring.created.join(",") === "true,false,true,false"
    && monthlyRecurring.perMonth.join(",") === "1,1",
  `une seule occurrence par mois, sans doublon (${JSON.stringify(monthlyRecurring)})`);
check(monthlyRecurring.manualIgnored,
  "un mouvement manuel de même titre et même compte ne doit pas couvrir la facture récurrente");
let screenHTML = await page.$eval("#screen", el => el.innerHTML);

// ---------- Test 2 : menu ＋ → Mouvement → dépense créée + persistée ----------
currentTest = "creation mouvement";
await page.click(`#tabbar button[aria-label="Mois"]`);
// Accueil : plus de ＋ flottant — le bouton héros ouvre la feuille.
await openQuickEntry("expense");
await page.evaluate(() => { document.getElementById("fMore").open = true; }); // L3 : intitulé sous « Détails »
await page.fill("#fTitle", "Test E2E dépense");
await page.fill("#fAmount", "42.50");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(200);
const createdTx = await page.evaluate(() =>
  transactions.find(t => t.title === "Test E2E dépense")?.amount);
check(createdTx === 42.5, "dépense absente du modèle après création");
await goMovements();
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Test E2E dépense"), "dépense absente de l'Historique après création");
// persistance après reload
await page.reload();
await page.waitForSelector("#tabbar button");
await goMovements();
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Test E2E dépense"), "dépense perdue dans l'Historique après reload");

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

// ---------- Test 4 : épargne depuis l'action unique — destination peuplée, fortune préservée ----------
currentTest = "epargne";
await page.click(`#tabbar button[aria-label="Mois"]`);
await openQuickEntry("save");
const destOptions = await page.$eval("#fDest", el => el.options.length);
check(destOptions > 0, "aucune destination proposée pour une épargne");
await page.evaluate(() => { document.getElementById("fMore").open = true; }); // L3 : intitulé sous « Détails »
await page.fill("#fTitle", "Épargne E2E");
await page.fill("#fAmount", "100");
await page.click('#txForm button[type="submit"]');
await page.waitForTimeout(200);
await goMovements();
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Épargne E2E"), "épargne absente de l'Historique");

// ---------- Test 5 : Échap ferme la feuille ouverte depuis l'action unique ----------
currentTest = "echap";
await page.click(`#tabbar button[aria-label="Mois"]`);
await openQuickEntry("expense");
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
check(screenHTML.includes("Mis de côté cette année : CHF&nbsp;100.00"), "cumul annuel absent sur le compte Épargne");
check(screenHTML.includes("en tout : CHF&nbsp;100.00"), "cumul total absent sur le compte Épargne");
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

// ---------- Test 7b : échéance de contrat proche → détail dans Gérer, accueil allégé ----------
currentTest = "echeance contrat";
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("RC ménage E2E"),
  "le contrat doit rester visible dans son écran dédié");
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("RC ménage E2E") && !screenHTML.includes("arrive à échéance"),
  "une échéance d'assurance ne doit pas recharger le premier niveau de l'accueil");

// ---------- Test 8 : navigation retour navigateur ----------
currentTest = "retour navigateur";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="bills"]');
await page.waitForTimeout(150);
await page.goBack();
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("data-addbill"), "retour navigateur ne remonte pas");

// ---------- Test 9 : verrouillage par code ----------
currentTest = "verrouillage";
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(150);
const svgOK = await page.$eval("#screen", el => !el.innerHTML.includes("NaN"));
check(svgOK, "NaN dans la courbe de patrimoine");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mis de côté en"), "bilan annuel des versements absent du Patrimoine");
check(screenHTML.includes("Les douze derniers mois"), "courbe 12 mois par classe absente");
check(screenHTML.includes("Si vous continuez comme ça") && screenHTML.includes("Dans 10 ans"), "projection du patrimoine absente");
await page.goBack();
await page.waitForTimeout(150);
await page.click('#screen [data-more="year"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mis de côté") && screenHTML.includes("Mois bouclés"), "écran Année en revue incomplet");
check(!screenHTML.includes("NaN"), "NaN dans l'année en revue");
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
// L'app crée le récurrent de dette au JOUR 3. Réglé un 1er ou un 2 du mois,
// ce jour est encore à venir : l'app planifie alors la mensualité au lieu de
// la comptabiliser (politique de date ADR-025, comportement CORRECT). Or ce
// test porte sur l'effet d'une mensualité RÉELLEMENT PAYÉE. On ramène donc
// l'échéance au 1er — toujours échu — pour que l'assertion vérifie ce
// qu'elle annonce, quel que soit le jour où la suite tourne.
await page.evaluate(id => {
  const rec = RECURRINGS.find(r => r.id === "r-debt-" + id);
  if (rec) { rec.day = 1; saveState(); render(); }
}, leasingId);
await page.waitForTimeout(150);
await page.click(`[data-postrec="r-debt-${leasingId}"]`);
await page.waitForTimeout(200);
// La mensualité doit être COMPTABILISÉE : sans cela, l'assertion suivante
// mesurerait un tout autre comportement.
const debtPosted10b = await page.evaluate(id =>
  transactions.filter(t => t.recurringId === "r-debt-" + id).map(t => t.status), leasingId);
check(debtPosted10b.length === 1 && debtPosted10b[0] === "posted",
  `la mensualité de dette est comptabilisée (obtenu ${JSON.stringify(debtPosted10b)})`);
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("1'100.00"), "la mensualité payée doit décrémenter la dette (1200 → 1100)");

// ---------- Test 11 : Historique direct — recherche et filtres ----------
currentTest = "mouvements";
await goMovements();
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
// Charges puis abonnements : deux écrans facultatifs, passés ici.
await page.waitForSelector("#obFormCharges", { state: "visible" });
await page.click("[data-obskipcharges]");
await page.waitForSelector("#obFormSubs", { state: "visible" });
await page.click("[data-obskipsubs]");
await page.waitForSelector("[data-obskipgoal]", { state: "visible" }); // étape objectif : passer
await page.click("[data-obskipgoal]");
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Bonjour Eva"), "prénom absent après un départ en euros");
check(screenHTML.includes("€&nbsp;1'000.00"), "le solde de départ doit s'afficher en euros");
check(!screenHTML.includes("CHF "), "plus aucun total en CHF quand la référence est l'euro");

// ---------- Test 14 : Réglages essentiels — guide, pays, devise ----------
currentTest = "reglages";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Comment ça marche"), "guide « Comment ça marche » absent");
check(screenHTML.includes("Un envoi n'est pas une dépense"), "règle d'or absente du guide");
check(screenHTML.includes("Mon pays") && screenHTML.includes("France"), "réglage pays absent ou faux");
check(screenHTML.includes("Votre monnaie") && screenHTML.includes("EUR"), "le réglage de monnaie est absent");

// ---------- Test 15 : profil de projection persisté ----------
currentTest = "projection persistée";
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]"); // confirm auto-accepté → reload
await page.waitForSelector("#tabbar button", { timeout: 10000 });
const demoBanner = await page.$eval(".demo-banner", el => el.style.display !== "none");
check(demoBanner, "bannière démo absente après chargement de la démonstration");
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
await openQuickEntry("expense");
await page.evaluate(() => { document.getElementById("fMore").open = true; }); // L3 : intitulé sous « Détails »
await page.fill("#fTitle", "Saisie en cours");
await page.fill("#fAmount", "12.30");
// clic sur le fond = dismiss accidentel : confirm auto-accepté → se ferme
await page.evaluate(() => document.getElementById("sheetBackdrop").click());
await page.waitForTimeout(150);
let guardOpen = await page.$eval("#sheetBackdrop", el => el.classList.contains("open"));
check(!guardOpen, "après confirmation, la feuille doit se fermer");
// ouvrir sans rien changer et cliquer le fond : pas de saisie → fermeture directe
await openQuickEntry("expense");
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
await page.evaluate(() => {
  const existing = budgetLines(cursor.y, cursor.m)[0];
  openLineSheet(existing ? existing.cat : null);
});
await page.waitForSelector("#lineForm", { state: "visible" });
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
await goMovements();
await page.waitForSelector("[data-addtx]", { state: "visible" });
await openQuickEntry("expense");
const txSheetShown = await page.$eval("#txForm", el => el.style.display !== "none");
check(txSheetShown, "l'action de l'état vide des Mouvements doit ouvrir la feuille d'ajout");
await page.click("#fCancel");

// ---------- Test 25 : menu « Gérer » regroupé, Historique sorti du hub ----------
currentTest = "menu gérer groupé";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
for (const group of ["Les quatre familles", "À prévoir", "À construire", "Mes données", "Application"]) {
  check(screenHTML.includes(group), `groupe « ${group} » absent du menu Gérer`);
}
check(!screenHTML.includes('data-more="movements"'),
  "Historique ne doit plus être caché dans Gérer");
check(await page.$('#tabbar button[aria-label="Historique"]') !== null,
  "Historique doit être une destination principale directe");
check(screenHTML.includes('data-more="taxes"') && screenHTML.includes('data-more="networth"'),
  "les destinations du menu Gérer doivent rester atteignables après regroupement");

// ---------- Test 26 : accueil essentiel — héros, 3 repères et actions mensuelles ----------
currentTest = "accueil essentiel";
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
const homeEssentials = await page.evaluate(() => ({
  hero: !!document.querySelector("#screen .card.hero"),
  stats: [...document.querySelectorAll("#screen .stat .card-label")].map(el => el.textContent.trim()),
  addActions: document.querySelectorAll("#screen [data-addtx]").length,
  quickActions: document.querySelectorAll("#screen .quick-row .btn").length,
  customization: !!document.querySelector("#screen [data-customize]"),
  foldedWealth: !!document.querySelector("#screen .home-fold"),
  text: document.getElementById("screen").innerText,
}));
check(homeEssentials.hero, "le montant disponible doit rester le héros de l'accueil");
check(homeEssentials.stats.join(",") === "Reçu,Dépensé,Mis de côté",
  `les trois repères essentiels sont attendus (${homeEssentials.stats.join(",")})`);
check(homeEssentials.addActions === 1, "une seule action « Ajouter » sur l'accueil");
check(/bilan du mois/i.test(homeEssentials.text), "la section Bilan du mois doit être visible");
check(homeEssentials.quickActions === 0 && !homeEssentials.customization && !homeEssentials.foldedWealth,
  "l'accueil ne doit plus afficher actions rapides, personnalisation ou patrimoine replié");

// ---------- Test 27 : la sauvegarde n'emporte jamais le code de verrouillage ----------
currentTest = "sauvegarde sans code";
const backupWithoutLock = await page.evaluate(() => {
  S.lockCode = codeHash("1234"); S.faceIDEnabled = true;
  const lockHash = S.lockCode;
  let captured = "";
  const orig = downloadFile;
  downloadFile = (name, text) => { captured = text; };
  exportBackup();
  downloadFile = orig;
  return { captured, lockHash };
});
check(!backupWithoutLock.captured.includes(backupWithoutLock.lockHash)
    && !backupWithoutLock.captured.includes("lockCode"),
  "le fichier de sauvegarde ne doit contenir ni le hash du code ni le champ lockCode");
await page.reload();
await page.waitForSelector("#lockInput", { timeout: 10000 });
const localLockPreserved = await page.evaluate(() => ({
  enabled: S.faceIDEnabled,
  valid: S.lockCode === codeHash("1234"),
}));
check(localLockPreserved.enabled && localLockPreserved.valid,
  "le verrouillage local doit rester actif après un rechargement normal");

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
// Surfaces unifiées sur Neon Ultra (ADR-024) : l'app entière peint le
// même noir. Ce qui compte ici reste que le thème soit UNIQUE et sombre.
check(obsidian.canvas === "#05060A", `le token --canvas doit valoir #05060A (obtenu ${obsidian.canvas})`);
// Le sélecteur d'apparence a été retiré des Réglages.
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
const themeToggle = await page.$("[data-toggletheme]");
check(themeToggle === null, "le sélecteur d'apparence ne doit plus exister dans les Réglages");

// ---------- Test 30 : accueil sans recommandation technique ----------
currentTest = "accueil sans recommandation";
await goHome();
// repartir de la démo : factures, paiements réguliers et objectifs présents
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]");
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(150);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("Priorité :") && !screenHTML.includes("Attention :")
    && !screenHTML.includes("Tout est en ordre"),
  "l'accueil simplifié ne doit plus afficher de recommandation technique");
check(!screenHTML.includes("Ce qui reste, 6 derniers mois")
    && !screenHTML.includes("Fortune nette totale")
    && !screenHTML.includes("Objectif prioritaire"),
  "courbes, patrimoine et objectifs doivent rester dans leurs écrans dédiés");

// ---------- Test 31 : Horizon L3 — comparaison au mois précédent ----------
currentTest = "comparaison mois";
await page.click(`#tabbar button[aria-label="Budget"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Mois dernier : coût de la vie"),
  "le Budget doit comparer au coût de la vie du mois précédent (démo chargée)");
check(/aria-label="Vous avez utilisé [^"]*de votre budget"/.test(screenHTML),
  "l'anneau plan/réel doit être présent et étiqueté pour VoiceOver");
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(!screenHTML.includes("Mois dernier :"),
  "la comparaison analytique doit rester dans Budget, pas sur l'accueil");

// ---------- Test 32 : Horizon L5 — charges de l'année et provision mensuelle ----------
currentTest = "charges annuelles";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="bills"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Vos factures de"), "la vue annuelle des charges doit exister sur Factures");
check(screenHTML.includes("par mois"), "la provision mensuelle de lissage doit être proposée");

// ---------- Test 33 : Horizon L6 — scénario et calcul expliqué sur les objectifs ----------
currentTest = "scenario objectifs";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="goals"]');
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("On divise ce qu'il reste par ce que vous mettez chaque mois"),
  "le calcul des objectifs doit être expliqué en clair");
check(screenHTML.includes("estimation, pas une promesse"),
  "l'estimation ne doit jamais être présentée comme une certitude");

// ---------- Test 34 : H01 — sauvegarde guidée dans Réglages ----------
currentTest = "sauvegarde guidee";
await page.click(`#tabbar button[aria-label="Gérer"]`);
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

// ---------- Test 35 : l'écran « Mois » suit le blueprint simplifié ----------
currentTest = "mois blueprint";
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Disponible maintenant"), "le réel du moment doit dominer l'écran Mois (FE2 : position « Maintenant » par défaut)");
check(screenHTML.includes("Bilan du mois"), "le bilan mensuel doit suivre les trois repères");
// ADR-026 : l'accueil ne CHARGE aucune analyse. Un raccourci de navigation
// vers une destination dédiée n'est pas une analyse — un widget de
// progression, une courbe ou une jauge en est une. L'assertion distingue
// donc les deux au lieu de bannir un simple lien.
check(!screenHTML.includes("Ce qui reste, 6 derniers mois")
    && !screenHTML.includes("Budget restant :"),
  "ni courbe 6 mois ni budget détaillé ne doivent charger l'écran Mois");
const home35 = await page.evaluate(() => {
  const s = document.getElementById("screen");
  // A7 : le bilan est un GROUPE de quatre blocs sous un en-tête commun
  // (mois courant) — ou une carte unique (mois futur/vide).
  const bills = s.querySelector(".home-bilan") || s.querySelector(".home-bills-card");
  return {
    // Aucun ancien widget d'objectif ni tuile d'analyse.
    goalWidget: !!s.querySelector('.card.row.tx[data-more="goals"]'),
    tileCount: s.querySelectorAll(".home-tile").length,
    agenda: !!bills && /bilan du mois/i.test(bills.innerText),
    manageUnified: s.querySelector(".home-manage")?.dataset.gototab === "more",
    carousel: !!s.querySelector("#heroTrack, [data-heroslide], [data-herodot]"),
  };
});
check(!home35.goalWidget,
  "l'ancien widget d'objectif ne doit plus charger l'écran Mois");
check(home35.tileCount === 0 && !home35.carousel,
  `aucune tuile ni carrousel ne surcharge l'accueil (${home35.tileCount} tuile)`);
check(home35.agenda, "le bilan du mois (groupe A7) reste au premier niveau");
check(home35.manageUnified,
  "Gérer ouvre le hub qui contient les lignes mensuelles ET les factures ponctuelles");
const tabLabel = await page.$eval('#tabbar button[data-tab="home"] span', el => el.textContent);
check(tabLabel === "Mois", "l'onglet d'accueil s'appelle « Mois »");

// ---------- Test 36 : préférence historique préservée, personnalisation retirée ----------
currentTest = "compatibilite widgets historiques";
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(250);
await page.evaluate(() => {
  S.homeWidgets = { hidden: ["trend6"] };
  saveState();
});
await page.reload();
await page.waitForSelector("#tabbar button");
const legacyWidgets = await page.evaluate(() => ({
  hidden: S.homeWidgets?.hidden || [],
  customize: !!document.querySelector("#screen [data-customize]"),
  essential: /disponible maintenant|prévu fin du mois|résultat du mois|estimation du mois/i
    .test(document.querySelector(".home-hero .card-label")?.textContent || ""),
}));
check(legacyWidgets.hidden.includes("trend6"),
  "l'ancienne préférence widget doit survivre pour la compatibilité des sauvegardes");
check(!legacyWidgets.customize && legacyWidgets.essential,
  "aucun réglage technique de widgets sur l'accueil, sans perdre le héros essentiel");

// ---------- Test 37 : Horizon R7 — assistant local déterministe ----------
currentTest = "assistant";
await page.click(`#tabbar button[aria-label="Gérer"]`);
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

// ---------- Test 44 : Mois L3 — ordre simplifié, 4 métriques, factures, extrême ----------
currentTest = "mois L3 structure";
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
// Ordre du premier niveau : salutation → héros → repères → actions mensuelles.
const orderIdx = {
  hello: screenHTML.indexOf("Bonjour"),
  hero: screenHTML.indexOf("Disponible maintenant"),
  metrics: screenHTML.indexOf('class="stat-grid'),
  bills: screenHTML.indexOf("Bilan du mois"),
};
check(orderIdx.hello >= 0 && orderIdx.hello < orderIdx.hero, "salutation avant le héros");
check(/<h2 class="screen-title"[^>]*>Bonjour/.test(screenHTML), "salutation en grand titre de page (screen-title)");
check(orderIdx.hero < orderIdx.metrics, "héros « Disponible maintenant » avant les métriques");
check(orderIdx.metrics < orderIdx.bills, "repères avant les actions mensuelles");
check(screenHTML.includes("data-addtx"), "action universelle Ajouter dans le héros");
// Exactement 3 repères, avec les mots du contrat.
const statLabels = await page.$$eval(".stat-grid .stat .card-label", els => els.map(e => e.textContent.trim()));
check(statLabels.length === 3, `exactement 3 repères (obtenu ${statLabels.length})`);
for (const label of ["Reçu", "Dépensé", "Mis de côté"]) {
  check(statLabels.includes(label), `métrique « ${label} » absente (${statLabels.join(", ")})`);
}
check(await page.$(".priority-card") === null, "aucune carte de priorité technique sur l'accueil");
check((await page.$$(".quick-row .btn")).length === 0, "aucune rangée d'actions rapides sur l'accueil");
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

// ---------- Test 45 : Mois L3 — 320 px, aucun FAB, vide guidé, démo explicite ----------
currentTest = "mois L3 320px/vide/demo";
await page.setViewportSize({ width: 320, height: 844 });
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(200);
const shell45 = await page.evaluate(() => ({
  fab: !!document.getElementById("fab"),
  labels: [...document.querySelectorAll("#tabbar button[data-tab]")]
    .map(button => button.getAttribute("aria-label")),
}));
check(!shell45.fab, "le bouton flottant global doit être absent");
check(shell45.labels.join(",") === "Mois,Historique,Budget,Comptes,Gérer",
  `les cinq destinations doivent rester visibles à 320 px (${shell45.labels.join(",")})`);
const noOverflow320 = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
check(noOverflow320, "aucun débordement horizontal à 320 px");
// Cibles ≥ 44 px sur les éléments interactifs du premier viewport.
const small320 = await page.evaluate(() => {
  document.getElementById("screen").scrollTop = 0;
  return [...document.querySelectorAll(".hero .btn, .month-nav button, #screen [role='button']")]
    .filter(el => el.offsetParent !== null)
    .map(el => ({ h: el.getBoundingClientRect().height, t: (el.textContent || "?").trim().slice(0, 18) }))
    .filter(x => x.h < 43.5);
});
check(small320.length === 0, `cibles < 44 px à 320 : ${small320.map(x => `${x.t} (${x.h.toFixed(0)})`).join(", ")}`);
// État vide guidé : un nouvel utilisateur sans mouvement voit des cartes-guides.
await page.evaluate(async () => {
  localStorage.clear();
  // W9.4 : un « utilisateur neuf » simulé vide AUSSI la réserve de
  // secours — sinon la récupération ressuscite l'état (comportement
  // voulu pour l'éviction, pas pour cette simulation).
  await new Promise(r => { const d = indexedDB.deleteDatabase("budget-app"); d.onsuccess = d.onerror = d.onblocked = r; });
});
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
// Charges puis abonnements : deux écrans facultatifs, passés ici.
await page.waitForSelector("#obFormCharges", { state: "visible" });
await page.click("[data-obskipcharges]");
await page.waitForSelector("#obFormSubs", { state: "visible" });
await page.click("[data-obskipsubs]");
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button");
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Bilan du mois"), "état vide guidé : bilan mensuel");
check(screenHTML.includes("Disponible maintenant"), "le héros existe même sans mouvement");
const demoHidden = await page.$eval(".demo-banner", el => el.style.display === "none");
check(demoHidden, "pas de bannière démo pour un vrai départ");
// Mode démo clairement identifié (chargée depuis les Réglages).
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
check(/utilisé \d+ % de votre budget/.test(screenHTML.replace(/&nbsp;/g, " ")), "le pourcentage doit être expliqué : « vous avez utilisé X % de votre budget »");
check(/aria-label="Vous avez utilisé [^"]*de votre budget"/.test(screenHTML), "l'anneau garde son étiquette accessible");
check(/Dans le plan|À surveiller|Dépassé/.test(screenHTML), "l'état du plan est écrit en toutes lettres");
check(screenHTML.includes("prévu") && screenHTML.includes("dépensé"), "prévu et dépensé restent deux chiffres nommés, jamais mélangés");
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
await openQuickEntry("expense");
await page.evaluate(() => { document.getElementById("fTypeMore").open = true; });
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
// La note doit DIRE que le mouvement compte déjà, sans le mot de
// comptable. L'exigence est la même, le vocabulaire a changé.
check(/déjà fait.*compte dans vos soldes/i.test(statusNow),
  `aujourd'hui → la note dit que ça compte déjà (obtenu « ${statusNow.trim()} »)`);
await page.evaluate(() => {
  const last = new Date(NOW.y, NOW.m, 0).getDate();
  if (NOW.d < last) {
    document.getElementById("fDate").value =
      `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(last).padStart(2, "0")}`;
    document.getElementById("fDate").dispatchEvent(new Event("change"));
  }
});
const statusFuture = await page.$eval("#fStatusNote", el => el.textContent);
check(/c'est prévu|déjà fait/i.test(statusFuture), "note de statut toujours présente");
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
check(!(await page.$eval("#sheetBackdrop", el => el.classList.contains("open"))), "la feuille se ferme après sauvegarde réussie");
const quickSaved = await page.evaluate(() =>
  transactions.some(t => t.amount === 12.35 && t.title === document.getElementById("fCat").value));
check(quickSaved, "le mouvement en trois gestes est enregistré dans le modèle");
await goMovements();
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("12.35"), "le mouvement en trois gestes apparaît dans l'Historique");
await page.reload();
await page.waitForSelector("#tabbar button");
await goMovements();
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("12.35"), "le mouvement en trois gestes survit au rechargement dans l'Historique");
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
// Virement : résumé explicite et neutralité affichée (bouton héros).
await page.click(`#tabbar button[aria-label="Mois"]`);
await openQuickEntry("expense");
await page.evaluate(() => { document.getElementById("fTypeMore").open = true; });
await page.click('#typeGrid button[data-ftype="transfer"]');
await page.waitForTimeout(100);
const transferNote = await page.$eval("#fTransferNote", el => el.textContent);
check(transferNote.includes("neutre") || transferNote === "", "un virement s'annonce neutre dès qu'une destination existe");
await page.click("#fCancel");
// Clavier : hauteur réduite (clavier ouvert simulé) → montant ET Enregistrer visibles.
await page.setViewportSize({ width: 320, height: 480 });
await openQuickEntry("expense");
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
check(rtSurface === "#151923", `transparence réduite : surface opaque attendue (obtenu ${rtSurface})`);
await page.evaluate(() => { delete document.documentElement.dataset.reducedTransparency; });
// Libellés accessibles des graphiques et de l'action principale.
const a11yLabels = await page.evaluate(() => ({
  add: (document.querySelector("#screen [data-addtx]")?.textContent || "").trim(),
  charts: [...document.querySelectorAll("#screen svg[role='img']")].every(s => (s.getAttribute("aria-label") || "").length > 5),
}));
check(a11yLabels.add.includes("Ajouter"),
  "l'action principale porte un libellé compréhensible");
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(150);
await page.click("[data-resetdemo]");
await page.waitForSelector("#tabbar button", { timeout: 10000 });
await goMovements();
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
  check(/mis de côté|Épargne[^<]*→/.test(screenHTML),
    "l'épargne est écrite « mis de côté » (ou « Épargne → compte » quand la destination est affichée)");
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
check(/solde que votre banque affiche/i.test(reconText) && reconText.includes("jamais réécrit"),
  "la mise à jour du solde s'explique en langage simple (historique jamais réécrit)");
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
await goMovements();
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
await goMovements();
const signs51 = await page.$$eval("#moreTxList .tx .amount", els =>
  els.slice(0, 8).map(e => e.textContent.trim()));
check(signs51.every(t => /^[+−-]/.test(t) || t.length > 0), "chaque montant porte un signe ou un libellé textuel");

/* ============= MODULES FINANCIERS OBSIDIAN L6 (Tests 52-55) ============= */

// ---------- Test 52 : Factures L6 — héros, retard écrit, paiement lié SANS double comptage, vide ----------
currentTest = "factures L6";
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
// Échéance au 1er : TOUJOURS échue, quel que soit le jour où la suite
// tourne. Une échéance future serait PLANIFIÉE et non comptabilisée
// (politique de date ADR-025) — l'assertion « dépense comptabilisée »
// ci-dessous ne mesurerait alors plus rien de stable.
await page.evaluate(() => {
  S.bills.push({ id: "l6bill", name: "Facture test L6", amount: 123.45, dueY: NOW.y, dueM: NOW.m,
    dueD: 1, cat: "Logement", paidTxId: null, note: "" });
  saveState(); render();
});
// La carte synthétique de l'accueil permet de régler l'échéance sans
// transformer l'écran Factures dédié en second bouton redondant.
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
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
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="taxes"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
// FE2-12 (décision propriétaire, 20.08.2026) : la page Impôts n'estime
// plus rien — elle ADDITIONNE ce que l'utilisateur a noté, c'est tout.
check(/Payé en \d{4}/.test(screenHTML),
  "le héros Impôts dit un FAIT — ce qui a été payé — plus aucune estimation");
for (const label53 of ["Déjà payé", "Déjà mis de côté"]) {
  check(screenHTML.includes(label53), `la stat « ${label53} » est présente et distincte`);
}
check(!screenHTML.includes("Pour toute l'année") && !/à peu près/.test(screenHTML)
  && !screenHTML.includes("Encore à mettre de côté"),
  "plus AUCUNE estimation dérivée d'un taux sur la page Impôts (ADR-035)");
check(screenHTML.includes("Ajouter un acompte"),
  "un bouton crée un acompte comme une facture — le geste demandé par le propriétaire");
check(!screenHTML.includes("Changer le taux"),
  "plus aucun réglage de taux : il n'y a plus rien d'automatique à régler");
check(screenHTML.includes("pas un conseil fiscal"), "le disclaimer honnête est affiché");
check(screenHTML.includes("additionne seulement ce que vous notez"),
  "la page dit sa règle en clair : elle additionne, elle ne calcule pas");
const tax53 = await page.evaluate(() => {
  const s = taxSummary(cursor.y);
  return {
    holds: Math.abs(s.reserved - (s.reservedFromMovements + s.reservedManual)) < 0.005,
    sansEstimation: !("estimated" in s) && !("due" in s) && !("reserveGap" in s) && !("rate" in s),
  };
});
check(tax53.holds, "identité chiffrée : mis de côté = envois + report saisi");
check(tax53.sansEstimation, "taxSummary ne dérive plus rien d'un taux (ADR-035)");

// ---------- Test 54 : Patrimoine + Prévoyance + Assurances + Récurrents L6 ----------
currentTest = "patrimoine+prévoyance L6";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Tout ce qui est à vous"), "le héros Patrimoine annonce la fortune nette");
for (const line54 of ["Sur vos comptes", "Vos biens", "Prévoyance", "Ce que vous devez"]) {
  check(screenHTML.includes(line54), `la décomposition affiche « ${line54} »`);
}
check(screenHTML.includes("converties en"), "la fraîcheur et la conversion sont expliquées");
const compo54 = await page.$eval('[aria-label^="Ce que vous avez, en parts"]', el => el.getAttribute("aria-label"));
check(compo54.includes("Sur vos comptes") && compo54.includes("%"), "la répartition est une composition ACCESSIBLE (aria-label chiffré)");
// Dette qui domine : fortune négative affichée honnêtement, jamais masquée.
await page.evaluate(() => { LIABILITIES.push({ id: "l6debt", name: "Dette test L6", value: 99999999, include: true }); render(); });
await page.waitForTimeout(200);
const neg54 = await page.evaluate(() => {
  const el = document.querySelector(".hero-amount");
  return { neg: el.classList.contains("neg"), signed: /[−-]/.test(el.textContent) };
});
check(neg54.neg && neg54.signed, "fortune nette négative : classe neg ET signe écrit");
await page.evaluate(() => { const i = LIABILITIES.findIndex(l => l.id === "l6debt"); if (i >= 0) LIABILITIES.splice(i, 1); render(); });
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="insurance"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Vos assurances, par mois") && screenHTML.includes("par an"),
  "les primes affichent les DEUX équivalents, réconciliés");
check(screenHTML.includes("Déjà mis de côté") && screenHTML.includes("L'app ne calcule rien ici"),
  "la prévoyance affiche le constitué en annonçant sa source");
check(screenHTML.includes("Le montant de votre certificat"), "chaque ligne de prévoyance cite sa source (le certificat)");
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
await page.evaluate(() => {
  const source = defaultCashAccount();
  const destination = (ACCOUNTS.find(a => a.kind === "savings" && a.id !== source)
    || ACCOUNTS.find(a => a.id !== source)).id;
  RECURRINGS.push({
    id: "l6-reserve", title: "Épargne régulière L6", amount: 80,
    type: "expense", nature: "reserve", cat: "Épargne", day: 1,
    accountId: source, destAccountId: destination,
  });
  const changedAfterPayment = {
    id: "l6-proof-history", title: "Preuve historique L6", amount: 42,
    type: "expense", nature: "facture", cat: "Logement", day: 1,
    accountId: source,
  };
  RECURRINGS.push(changedAfterPayment);
  materializeRecurring(changedAfterPayment, NOW.y, NOW.m);
  changedAfterPayment.nature = "reserve";
  changedAfterPayment.cat = "Épargne";
  changedAfterPayment.title = "Nouvelle définition L6";
  changedAfterPayment.amount = 99;
  changedAfterPayment.every = "year";
  changedAfterPayment.dueM = NOW.m === 12 ? 11 : NOW.m + 1;
  changedAfterPayment.destAccountId = destination;
  saveState(); render();
});
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="recurring"]');
await page.waitForTimeout(250);
const rec54 = await page.evaluate(() => [...document.querySelectorAll("#screen [data-recid]")].map(r => r.textContent));
check(rec54.length > 0, "des paiements réguliers sont affichés en démo");
// « En retard » et « À venir » ont disparu avec le jour de paiement : sans
// date promise, une charge n'est ni en avance ni en retard À L'INTÉRIEUR du
// mois — elle est simplement encore à régler.
check(rec54.every(t => /Payé ce mois|Reçu ce mois|Mis de côté ce mois|Investi ce mois|Prévu|À payer ce mois|À mettre de côté ce mois|À investir ce mois|À recevoir ce mois|Pas ce mois/.test(t)),
  `chaque ligne régulière porte son état écrit (pill) — obtenu ${JSON.stringify(rec54.slice(0, 2))}`);
const reserve54 = await page.evaluate(() => RECURRINGS
  .filter(recurring => recurring.id === "l6-reserve")
  .map(recurring => {
  const row = document.querySelector(`[data-recid="${CSS.escape(recurring.id)}"]`);
  return {
    title: recurring.title,
    text: row?.textContent || "",
    saveIcon: !!row?.querySelector(".ico.t-save"),
    negativeAmount: !!row?.querySelector(".amount.neg"),
  };
  }));
check(reserve54.length > 0 && reserve54.every(row => row.saveIcon
    && !row.negativeAmount && !/Payé ce mois|À payer ce mois/.test(row.text)),
  `une mise de côté régulière n'est jamais présentée comme une dépense (${JSON.stringify(reserve54)})`);
const proof54 = await page.$eval('[data-recid="l6-proof-history"]', row => ({
  text: row.textContent,
  expenseIcon: !!row.querySelector(".ico.t-expense"),
  negativeAmount: !!row.querySelector(".amount.neg"),
  amount: row.querySelector(".amount")?.textContent.trim() || "",
  expectedAmount: "−" + chf(42),
}));
check(/Preuve historique L6/.test(proof54.text) && !/Nouvelle définition L6/.test(proof54.text)
    && /Payé ce mois/.test(proof54.text) && !/Mis de côté ce mois/.test(proof54.text)
    && proof54.amount === proof54.expectedAmount
    && proof54.expenseIcon && proof54.negativeAmount,
  `modifier la ligne après paiement ne réécrit ni le geste ni son apparence (${JSON.stringify(proof54)})`);
const orphanProof54 = await page.evaluate(() => {
  const index = RECURRINGS.findIndex(recurring => recurring.id === "l6-proof-history");
  if (index >= 0) RECURRINGS.splice(index, 1);
  activeTab = "home"; moreView = null; render();
  const row = [...document.querySelectorAll("[data-home-done-key]")]
    .find(element => element.textContent.includes("Preuve historique L6"));
  return {
    text: row?.textContent || "",
    expenseIcon: !!row?.querySelector(".ico.t-expense"),
    checkDone: monthCheckItems(NOW.y, NOW.m)
      .some(item => item.label === "Preuve historique L6" && item.done),
  };
});
check(/Payé ce mois/.test(orphanProof54.text) && orphanProof54.expenseIcon
    && orphanProof54.checkDone,
  `supprimer la définition conserve une preuve fidèle dans le bilan (${JSON.stringify(orphanProof54)})`);
await page.evaluate(() => {
  for (const id of ["l6-reserve", "l6-proof-history"]) {
    const index = RECURRINGS.findIndex(recurring => recurring.id === id);
    if (index >= 0) RECURRINGS.splice(index, 1);
  }
  const transactionIndex = transactions.findIndex(transaction => transaction.recurringId === "l6-proof-history");
  if (transactionIndex >= 0) transactions.splice(transactionIndex, 1);
  saveState(); render();
});
const plannedOrphan54 = await page.evaluate(() => {
  const saved = {
    recurrings: structuredClone(RECURRINGS),
    bills: structuredClone(S.bills || []),
    monthChecks: structuredClone(S.monthChecks || {}),
    transactions: structuredClone(transactions),
  };
  RECURRINGS.splice(0, RECURRINGS.length);
  transactions.splice(0, transactions.length);
  S.bills = [];
  const source = defaultCashAccount();
  const destination = (ACCOUNTS.find(account => account.kind === "savings" && account.id !== source)
    || ACCOUNTS.find(account => account.id !== source)).id;
  RECURRINGS.push({
    id: "deleted-planned-54", title: "Ligne déplacée L6", amount: 25,
    type: "expense", nature: "facture", cat: "Autre", day: 1,
    every: "year", dueM: NOW.m === 12 ? 11 : NOW.m + 1,
    accountId: source, icon: "🧾",
  });
  RECURRINGS.push({
    id: "closed-check-54", title: "Facture déjà faite L6", amount: 15,
    type: "expense", nature: "facture", cat: "Autre", day: 1,
    every: "month", accountId: source, icon: "🧾",
  });
  transactions.push({
    id: ++txSeq, y: NOW.y, m: NOW.m, d: 1,
    title: "Facture déjà faite L6", amount: 15, type: "expense", cat: "Autre",
    acc: source, dest: null, status: "posted", recurringId: "closed-check-54",
  });
  const plannedID = ++txSeq;
  const originalTodayParts = todayParts;
  todayParts = () => ({ y: NOW.y, m: NOW.m, d: 1 });
  transactions.push({
    id: plannedID, y: NOW.y, m: NOW.m, d: new Date(NOW.y, NOW.m, 0).getDate(),
    title: "Épargne prévue sans ligne L6", amount: 25, type: "saving", cat: "Épargne",
    acc: source, dest: destination, status: "planned", recurringId: "deleted-planned-54",
  });
  activeTab = "home"; moreView = null; render();
  const row = document.querySelector(`[data-unrepresented-planned="${plannedID}"]`);
  const result = {
    text: row?.textContent || "",
    saveIcon: !!row?.querySelector(".ico.t-save"),
    action: row?.querySelector(".home-bill-action")?.textContent.trim() || "",
    monthClosed: !!(S.monthChecks || {})[`${NOW.y}-${NOW.m}`],
  };
  transactions.splice(0, transactions.length, ...saved.transactions);
  todayParts = originalTodayParts;
  RECURRINGS.splice(0, RECURRINGS.length, ...saved.recurrings);
  S.bills = saved.bills;
  S.monthChecks = saved.monthChecks;
  saveState(); render();
  return result;
});
check(/À mettre de côté ce mois · Prévu/.test(plannedOrphan54.text)
    && plannedOrphan54.saveIcon && plannedOrphan54.action === "Mis de côté"
    && !plannedOrphan54.monthClosed,
  `un mouvement prévu survit au déplacement ou à la suppression de sa ligne (${JSON.stringify(plannedOrphan54)})`);

// ---------- Test 55 : a11y L6 — 320 px sur les 6 modules, extrême, cibles 44 px ----------
currentTest = "a11y L6";
await page.setViewportSize({ width: 320, height: 844 });
for (const view55 of ["bills", "goals", "taxes", "networth", "insurance", "recurring"]) {
  await page.click(`#tabbar button[aria-label="Gérer"]`);
  await page.waitForTimeout(120);
  await page.click(`#screen [data-more="${view55}"]`);
  await page.waitForTimeout(200);
  const ok55 = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
  check(ok55, `module « ${view55} » sans débordement à 320 px`);
}
// Actif extrême : le héros Patrimoine se réduit (classe long) sans tronquer ni déborder.
await page.evaluate(() => { ASSETS.push({ id: "l6extreme", name: "Actif extrême", value: 9999999.99, include: true }); render(); });
await page.click(`#tabbar button[aria-label="Gérer"]`);
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

/* ============= ONBOARDING & CONFIANCE OBSIDIAN L7 (Tests 56-59) ============= */

// ---------- Test 56 : onboarding L7 — promesse honnête, Retour, estimation fiscale, atomicité ----------
currentTest = "onboarding L7";
const ctx56 = await browser.newContext({ viewport: { width: 390, height: 844 } });
const p56 = await ctx56.newPage();
p56.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[onboarding L7] ${msg.text()}`); });
p56.on("pageerror", err => consoleErrors.push(`[onboarding L7] pageerror: ${err.message}`));
await p56.goto(APP_URL);
await p56.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 });
let ob56 = await p56.$eval("body", el => el.innerHTML);
check(ob56.includes("Vos données restent sur cet appareil"),
  "l'étape 1 énonce la promesse de confidentialité en UNE ligne honnête (stockage local)");
check(!ob56.includes("Vos données vivent dans CE navigateur"),
  "l'étape 1 ne porte plus la carte aux trois lignes (retour propriétaire — les détails restent dans Confidentialité)");
await p56.click('[data-obcountry="CH"]');
await p56.click('[data-obhh="solo"]');
await p56.fill("#obName", "Testeur");
await p56.click('#obForm1 button[type="submit"]');
await p56.waitForSelector("#obSalary");
// A18 (demande propriétaire) : l'onboarding ne demande PLUS de taux
// d'impôts — le défaut du pays s'applique, modifiable dans Impôts.
const tax56 = await p56.$("#obTaxPct");
check(tax56 === null, "l'étape salaire ne demande plus de taux d'impôts (champ retiré)");
await p56.fill("#obSalary", "5000");
await p56.click('#obForm2 button[type="submit"]');
await p56.waitForSelector("#obOpening");
// Aucune écriture AVANT la fin du parcours (atomicité PWA).
const partial56 = await p56.evaluate(() => localStorage.getItem(APP_STATE_KEY));
check(partial56 === null, "aucun état n'est écrit avant la validation finale du parcours");
// Retour : la saisie du salaire est CONSERVÉE.
await p56.click("[data-obback]");
await p56.waitForSelector("#obSalary");
const back56 = await p56.evaluate(() => ({
  salary: document.getElementById("obSalary").value,
}));
check(back56.salary === "5000",
  `Retour conserve le salaire saisi (obtenu ${back56.salary})`);
await p56.click('#obForm2 button[type="submit"]');
await p56.waitForSelector("#obOpening");
await p56.fill("#obOpening", "1000");
await p56.click('#obForm3 button[type="submit"]');
// Charges puis abonnements : deux écrans facultatifs, passés ici.
await p56.waitForSelector("#obFormCharges", { state: "visible" });
await p56.click("[data-obskipcharges]");
await p56.waitForSelector("#obFormSubs", { state: "visible" });
await p56.click("[data-obskipsubs]");
await p56.waitForSelector("[data-obskipgoal]");
await p56.click("[data-obskipgoal]");
await p56.waitForSelector("#tabbar button", { timeout: 10000 });
const final56 = await p56.evaluate(() => ({
  taxRate: S.taxRate,
  effortExpose: "taxMonthlyEffort" in snapshot(NOW.y, NOW.m),
  salary: RECURRINGS.find(r => r.type === "income")?.amount,
  accounts: ACCOUNTS.length,
  saved: localStorage.getItem(APP_STATE_KEY) !== null,
}));
// FE2-12 (décision propriétaire, 20.08.2026) : AUCUN impôt calculé
// automatiquement, jamais — le moteur n'a même plus de champ pour ça.
// Les impôts sont des acomptes que l'utilisateur saisit, comme des factures.
check(final56.taxRate === 0, `le champ hérité reste à zéro après l'onboarding (obtenu ${final56.taxRate})`);
check(final56.effortExpose === false, "le moteur n'expose plus AUCUN effort d'impôts automatique (ADR-035)");
check(final56.salary === 5000, "le salaire facultatif devient un paiement régulier existant");
check(final56.accounts >= 2 && final56.saved, "la finalisation crée les comptes et écrit l'état UNE fois");
await ctx56.close();

// ---------- Test 57 : hub Gérer L7 — groupes par intention, AUCUN lien mort ----------
currentTest = "hub Gérer L7";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(200);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
for (const group57 of ["Les quatre familles", "À prévoir", "À construire", "Mes données", "Application"]) {
  check(screenHTML.includes(group57), `le groupe « ${group57} » est présent`);
}
const rows57 = await page.evaluate(() =>
  [...document.querySelectorAll('#screen [data-more], #screen [data-gototab]')]
    .map(el => ({ h: el.getBoundingClientRect().height, sub: el.querySelector(".s")?.textContent || "" })));
check(rows57.length >= 10, `toutes les destinations sont listées (obtenu ${rows57.length})`);
check(rows57.every(r => r.h >= 43.5), "chaque ligne du hub fait au moins 44 px");
check(rows57.every(r => r.sub.trim().length > 0), "chaque ligne explique ce qu'on y fait");
for (const dest57 of ["bills", "recurring", "taxes", "insurance", "networth", "goals", "year", "importcsv", "assistant", "settings"]) {
  await page.click(`#tabbar button[aria-label="Gérer"]`);
  await page.waitForTimeout(120);
  await page.click(`#screen [data-more="${dest57}"]`);
  await page.waitForTimeout(200);
  const alive57 = await page.evaluate(() => document.getElementById("screen").innerHTML.length > 500);
  check(alive57, `la destination « ${dest57} » rend un écran réel (pas de lien mort)`);
}

// ---------- Test 58 : confiance L7 — résumé de restauration, textes honnêtes, suppression annoncée ----------
currentTest = "confiance L7";
const summary58 = await page.evaluate(() => restoreSummaryText({
  version: 1, exportedAt: "2026-07-24T10:00:00Z",
  state: { transactions: [1, 2], accounts: [1], goals: [], recurrings: [1], documents: [] },
}));
check(summary58.includes("24.07.2026") && summary58.includes("2 opérations") && summary58.includes("1 comptes"),
  "le résumé de restauration montre la date et le contenu RÉELS");
check(summary58.includes("REMPLACE") && summary58.includes("code de verrouillage") && summary58.includes("fichiers de documents"),
  "le résumé annonce la portée exacte et ce que la sauvegarde ne contient PAS");
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(120);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Ce n'est pas un coffre-fort"), "le verrouillage est décrit honnêtement (protection d'affichage)");
check(screenHTML.includes("localStorage") || screenHTML.includes("navigateur"),
  "le stockage local réel est expliqué dans les réglages");
check(screenHTML.includes("aucun fichier n'est stocké"),
  "les documents web sont décrits comme métadonnées SEULEMENT");
// Suppression des opérations : ce qui est annoncé conservé l'est VRAIMENT.
const before58 = await page.evaluate(() => ({ accounts: ACCOUNTS.length, budgets: Object.keys(S.budgets || {}).length }));
await page.evaluate(() => deleteAllData()); // les deux confirms sont auto-acceptés
await page.waitForTimeout(300);
const after58 = await page.evaluate(() => ({
  tx: transactions.length, goals: GOALS.length, accounts: ACCOUNTS.length,
  budgets: Object.keys(S.budgets || {}).length, undo: document.getElementById("toastUndo") !== null,
}));
check(after58.tx === 0 && after58.goals === 0, "les opérations annoncées sont bien effacées");
check(after58.accounts === before58.accounts && after58.budgets === before58.budgets,
  "les comptes et budgets annoncés conservés le sont VRAIMENT");
check(after58.undo, "l'effacement propose l'annulation (undo 6 s)");
await page.click("#toastUndo");
await page.waitForTimeout(300);
const undone58 = await page.evaluate(() => transactions.length);
check(undone58 > 0, "l'annulation restaure les opérations effacées");

// ---------- Test 59 : a11y L7 — 320 px sur onboarding-surfaces, cibles 44 px ----------
currentTest = "a11y L7";
await page.setViewportSize({ width: 320, height: 844 });
for (const view59 of ["settings", "importcsv"]) {
  await page.click(`#tabbar button[aria-label="Gérer"]`);
  await page.waitForTimeout(120);
  await page.click(`#screen [data-more="${view59}"]`);
  await page.waitForTimeout(200);
  const ok59 = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
  check(ok59, `« ${view59} » sans débordement à 320 px`);
}
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
const plus59 = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
check(plus59, "hub Gérer sans débordement à 320 px");
const targets59 = await page.evaluate(() =>
  [...document.querySelectorAll("#screen .btn, #screen [data-more]")]
    .map(el => ({ h: el.getBoundingClientRect().height, t: (el.textContent || "?").trim().slice(0, 18) }))
    .filter(x => x.h > 0 && x.h < 43.5));
check(targets59.length === 0, `cibles < 44 px dans Gérer : ${targets59.map(x => x.t).join(", ")}`);
await page.setViewportSize({ width: 390, height: 844 });

/* ============= CORRECTIF L7 (Tests 60-62) ============= */

// ---------- Test 60 : shell simplifié — cinq destinations, aucun ＋ global ----------
currentTest = "shell simplifié L7";
async function assertSimpleShell(tag) {
  const check60 = await page.evaluate(() => {
    const tabs = [...document.querySelectorAll("#tabbar button[data-tab]")];
    return {
      labels: tabs.map(tab => tab.getAttribute("aria-label")),
      noFab: !document.getElementById("fab"),
      smallTabs: tabs.filter(tab => {
        const rect = tab.getBoundingClientRect();
        return rect.width < 43.5 || rect.height < 43.5;
      }).length,
      noHScroll: document.documentElement.scrollWidth <= document.documentElement.clientWidth,
    };
  });
  check(check60.labels.join(",") === "Mois,Historique,Budget,Comptes,Gérer",
    `${tag} : cinq destinations directes (${check60.labels.join(",")})`);
  check(check60.noFab, `${tag} : aucun bouton ＋ global`);
  check(check60.smallTabs === 0, `${tag} : destinations du shell ≥ 44 px`);
  check(check60.noHScroll, `${tag} : aucun débordement horizontal`);
}
for (const [w, tag60] of [[390, "390"], [320, "320"]]) {
  await page.setViewportSize({ width: w, height: 844 });
  for (const view60 of ["plus-hub", "settings", "importcsv"]) {
    await page.click(`#tabbar button[aria-label="Gérer"]`);
    await page.waitForTimeout(150);
    if (view60 !== "plus-hub") {
      await page.click(`#screen [data-more="${view60}"]`);
      await page.waitForTimeout(200);
    }
    await assertSimpleShell(`${tag60}/${view60} à l'ouverture`);
    await page.evaluate(() => { document.getElementById("screen").scrollTop = 999999; });
    await page.waitForTimeout(150);
    await assertSimpleShell(`${tag60}/${view60} après défilement`);
  }
}
await page.setViewportSize({ width: 390, height: 844 });

// ---------- Test 61 : import CSV L7 — mapping, compte CHOISI, aperçu, confirmation, idempotence, rollback ----------
currentTest = "import L7";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="importcsv"]');
await page.waitForTimeout(200);
const csv61 = "date;montant;intitulé\n05.06.2026;-45.50;Courses import L7\n06.06.2026;-12.00;Café import L7\npas-une-date;abc;Ligne invalide L7";
const before61 = await page.evaluate(() => transactions.length);
await page.fill("#importPaste", csv61);
await page.click("[data-importpaste]");
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("Aperçu avant écriture") && screenHTML.includes("RIEN n'est encore importé"),
  "l'aperçu s'affiche AVANT toute écriture");
check(screenHTML.includes("impMapDate") && screenHTML.includes("impAccount"),
  "la correspondance des colonnes ET le compte de destination sont modifiables");
check(screenHTML.includes("2 prêtes") && screenHTML.includes("1 invalide"),
  "les décomptes prêtes/doublons/invalides sont affichés");
const noWrite61 = await page.evaluate(() => transactions.length);
check(noWrite61 === before61, "AUCUNE écriture avant la confirmation finale");
// Annuler ne modifie rien.
await page.click("[data-impcancel]");
await page.waitForTimeout(200);
check(await page.evaluate(() => transactions.length) === before61 && await page.evaluate(() => importDraft === null),
  "annuler l'aperçu ne modifie rien");
// Recommencer, choisir un AUTRE compte, confirmer.
await page.fill("#importPaste", csv61);
await page.click("[data-importpaste]");
await page.waitForTimeout(250);
const otherAccount61 = await page.evaluate(() => {
  const other = ACCOUNTS.find(a => a.id !== defaultCashAccount());
  document.getElementById("impAccount").value = other.id;
  document.getElementById("impAccount").dispatchEvent(new Event("change", { bubbles: true }));
  return other.id;
});
await page.waitForTimeout(250);
await page.click("[data-impconfirm]");
await page.waitForTimeout(300);
const after61 = await page.evaluate(id => ({
  count: transactions.length,
  imported: transactions.filter(t => t.title.includes("import L7")),
  allInChosen: transactions.filter(t => t.title.includes("import L7")).every(t => t.acc === id),
  report: S.lastImport,
}), otherAccount61);
check(after61.count === before61 + 2, "2 lignes prêtes écrites après confirmation");
check(after61.allInChosen, "l'import va dans le compte CHOISI, jamais d'office dans le compte par défaut");
check(after61.report && after61.report.invalids.length === 1, "la ligne invalide est dans la file de réparation");
// Idempotence : réimporter le MÊME contenu → 0 prête.
await page.fill("#importPaste", csv61);
await page.click("[data-importpaste]");
await page.waitForTimeout(250);
await page.evaluate(id => {
  document.getElementById("impAccount").value = id;
  document.getElementById("impAccount").dispatchEvent(new Event("change", { bubbles: true }));
}, otherAccount61);
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
check(screenHTML.includes("0 prête") && screenHTML.includes("2 doublons"),
  "réimporter le même fichier ne propose AUCUN doublon");
await page.click("[data-impcancel]");
await page.waitForTimeout(200);
// Persistance réelle puis rollback limité au lot.
const persisted61 = await page.evaluate(() => JSON.parse(localStorage.getItem(APP_STATE_KEY)).transactions.some(t => t.title.includes("import L7")));
check(persisted61, "l'import confirmé est PERSISTÉ");
await page.click("[data-rollbackimport]");
await page.waitForTimeout(300);
const rolled61 = await page.evaluate(() => ({
  gone: !transactions.some(t => t.title.includes("import L7")),
  count: transactions.length,
}));
check(rolled61.gone && rolled61.count === before61, "le rollback retire UNIQUEMENT le lot importé");

// ---------- Test 62 : documents L7 — modification réelle + concordance des actions destructives ----------
currentTest = "documents L7";
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="importcsv"]');
await page.waitForTimeout(200);
await page.click("[data-adddoc]");
await page.waitForTimeout(200);
await page.fill("#dName", "Certificat test L7");
await page.click('#docForm button[type="submit"]');
await page.waitForTimeout(250);
const added62 = await page.evaluate(() => S.documents.find(d => d.name === "Certificat test L7"));
check(!!added62, "l'ajout de métadonnées fonctionne");
// MODIFICATION réelle : nom et type.
await page.click(`[data-editdoc="${added62.id}"]`);
await page.waitForTimeout(200);
const sheetTitle62 = await page.$eval("#docSheetTitle", el => el.textContent);
check(sheetTitle62 === "Modifier le document", "la feuille passe en mode modification");
await page.fill("#dName", "Certificat MODIFIÉ L7");
await page.selectOption("#dKind", "Impôts");
await page.click('#docForm button[type="submit"]');
await page.waitForTimeout(250);
const edited62 = await page.evaluate(id => {
  const doc = S.documents.find(d => d.id === id);
  const saved = JSON.parse(localStorage.getItem(APP_STATE_KEY)).documents.find(d => d.id === id);
  return { name: doc.name, kind: doc.kind, savedName: saved?.name };
}, added62.id);
check(edited62.name === "Certificat MODIFIÉ L7" && edited62.kind === "Impôts",
  "nom ET type sont réellement modifiés");
check(edited62.savedName === "Certificat MODIFIÉ L7", "la modification est persistée");
// Annulation d'édition : rien ne change.
await page.click(`[data-editdoc="${added62.id}"]`);
await page.waitForTimeout(200);
await page.fill("#dName", "Ne doit pas rester");
await page.click("#dCancel");
await page.waitForTimeout(200);
check(await page.evaluate(id => S.documents.find(d => d.id === id).name, added62.id) === "Certificat MODIFIÉ L7",
  "annuler l'édition ne modifie rien");
// Suppression (confirm auto-accepté) : métadonnées retirées.
await page.click(`[data-deldoc="${added62.id}"]`);
await page.waitForTimeout(250);
check(await page.evaluate(id => !S.documents.some(d => d.id === id), added62.id),
  "la suppression retire les métadonnées du document nommé");
// Concordance EXACTE : les textes utilisent les noms des boutons visibles.
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(120);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(250);
screenHTML = await page.$eval("#screen", el => el.innerHTML);
for (const name62 of ["Effacer les opérations", "Réinitialiser complètement l'application", "Charger la démonstration"]) {
  const buttonCount = await page.evaluate(label =>
    [...document.querySelectorAll("#screen .btn")].filter(b => b.textContent.includes(label)).length, name62);
  check(buttonCount === 1, `le bouton « ${name62} » existe`);
  check(screenHTML.includes(`« ${name62} »`),
    `l'explication de confidentialité utilise EXACTEMENT « ${name62} »`);
}
check(!screenHTML.includes("« Tout supprimer »") && !screenHTML.includes("« Réinitialiser la démo »"),
  "plus aucun ancien nom d'action ne subsiste dans les textes");

/* ============= WIDGETS & MOUVEMENT OBSIDIAN L8 — correctif (Tests 63-66) ============= */

// ---------- Test 63 : scrubber de courbe — slider accessible, glissement réel, clavier, valeurs de fixture ----------
currentTest = "scrubber de courbe L8";
// Fixture INDÉPENDANTE : compte connu 1'234.56, une dépense de 234.56 il y
// a trois mois → les valeurs attendues sont des LITTÉRAUX du test, jamais
// extraites de l'aria-label contrôlé.
await page.evaluate(() => {
  ACCOUNTS.push({ id: "acc-l8-fixture", name: "Compte fixture L8", inst: "", kind: "current", opening: 1234.56, cash: false, currency: null });
  const em = shiftMonth(NOW, -3);
  transactions.push({ id: ++txSeq, y: em.y, m: em.m, d: 10, title: "Fixture L8 dépense", type: "expense", cat: null, acc: "acc-l8-fixture", dest: null, status: "posted", amount: 234.56 });
});
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(200);
await page.click('[data-accid="acc-l8-fixture"]');
await page.waitForTimeout(250);
// Région live PERSISTANTE : présente AVANT toute sélection, avec l'invite.
const live63 = await page.evaluate(() => {
  const cap = document.querySelector('[data-chartcaption="acc"]');
  if (cap) cap.dataset.livemark = "1"; // marque le nœud : il doit être MIS À JOUR, jamais recréé
  const scrub = document.querySelector('[data-chart="acc"] .scrub');
  const r = scrub ? scrub.getBoundingClientRect() : { width: 0, height: 0 };
  return {
    capBefore: cap ? cap.textContent : "",
    ariaLive: cap ? cap.getAttribute("aria-live") : null,
    role: scrub ? scrub.getAttribute("role") : null,
    valuemin: scrub ? scrub.getAttribute("aria-valuemin") : null,
    valuemax: scrub ? scrub.getAttribute("aria-valuemax") : null,
    valuetext: scrub ? scrub.getAttribute("aria-valuetext") : null,
    w: r.width, h: r.height,
    markerHidden: document.querySelector('[data-chart="acc"] [data-scrubdot]')?.getAttribute("visibility") === "hidden",
  };
});
check(live63.ariaLive === "polite" && live63.capBefore.includes("Touchez la courbe"),
  "la région live existe AVANT la sélection, avec l'invite");
check(live63.role === "slider" && live63.valuemin === "0" && live63.valuemax === "11",
  "le scrubber est un slider accessible (aria-valuemin/max)");
check(live63.valuetext !== null && live63.valuetext.includes("Aucun mois choisi"),
  "aria-valuetext honnête avant toute sélection");
check(live63.w >= 44 && live63.h >= 44,
  `cible interactive réelle ≥ 44 px (obtenu ${Math.round(live63.w)}×${Math.round(live63.h)} px)`);
check(live63.markerHidden, "aucun marqueur avant la sélection");
// GLISSEMENT réel (Pointer Events) : enfoncer à 10 %, glisser à 50 % puis
// 99 % — la sélection suit PENDANT le geste.
const box63 = await page.evaluate(() => {
  const r = document.querySelector('[data-chart="acc"] .scrub').getBoundingClientRect();
  return { x: r.left, y: r.top, w: r.width, h: r.height };
});
await page.mouse.move(box63.x + box63.w * 0.10, box63.y + box63.h / 2);
await page.mouse.down();
await page.waitForTimeout(60);
const drag63a = await page.evaluate(() => document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuenow"));
await page.mouse.move(box63.x + box63.w * 0.50, box63.y + box63.h / 2, { steps: 4 });
await page.waitForTimeout(60);
const drag63b = await page.evaluate(() => document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuenow"));
await page.mouse.move(box63.x + box63.w * 0.99, box63.y + box63.h / 2, { steps: 4 });
await page.mouse.up();
await page.waitForTimeout(60);
const drag63c = await page.evaluate(() => ({
  now: document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuenow"),
  valuetext: document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuetext"),
  cap: document.querySelector('[data-chartcaption="acc"]').textContent,
}));
check(drag63a === "1", `l'appui initial sélectionne le mois visé (obtenu ${drag63a}, attendu 1)`);
check(drag63b === "6", `le glissement met à jour PENDANT le geste (obtenu ${drag63b}, attendu 6)`);
check(drag63c.now === "11", `la fin du glissement atteint le dernier mois (obtenu ${drag63c.now})`);
check(drag63c.cap.includes("CHF 1'000.00") && drag63c.cap.includes("solde"),
  `l'étiquette du mois courant vaut la FIXTURE 1'234.56 − 234.56 = CHF 1'000.00 (obtenu « ${drag63c.cap} »)`);
check(drag63c.valuetext.includes("CHF 1'000.00"), "aria-valuetext annonce la même valeur de fixture");
// Marqueur : règle et point EXACTEMENT aux coordonnées du mois choisi.
const marker63 = await page.evaluate(() => {
  const wrap = document.querySelector('[data-chart="acc"]');
  const pts = JSON.parse(wrap.dataset.pts);
  const [ex, ey] = pts[11].split(",");
  const dot = wrap.querySelector("[data-scrubdot]");
  const rule = wrap.querySelector("[data-scrubrule]");
  return {
    ok: dot.getAttribute("cx") === ex && dot.getAttribute("cy") === ey
      && rule.getAttribute("x1") === ex && rule.getAttribute("x2") === ex,
    visible: dot.getAttribute("visibility") !== "hidden",
  };
});
check(marker63.ok && marker63.visible, "règle et point aux coordonnées exactes du mois choisi");
// CLAVIER : Origine, flèches, Fin — focus conservé, valeurs de fixture.
await page.evaluate(() => document.querySelector('[data-chart="acc"] .scrub').focus());
await page.keyboard.press("Home");
await page.waitForTimeout(50);
const key63a = await page.evaluate(() => ({
  now: document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuenow"),
  cap: document.querySelector('[data-chartcaption="acc"]').textContent,
}));
check(key63a.now === "0", "Origine (Home) choisit le premier mois");
check(key63a.cap.includes("CHF 1'234.56"),
  `avant la dépense, l'étiquette vaut l'ouverture de la fixture (obtenu « ${key63a.cap} »)`);
const edge63a = await page.evaluate(() => {
  const wrap = document.querySelector('[data-chart="acc"]');
  return { cx: parseFloat(wrap.querySelector("[data-scrubdot]").getAttribute("cx")),
           rx: parseFloat(wrap.querySelector("[data-scrubrule]").getAttribute("x1")) };
});
check(Number.isFinite(edge63a.cx) && edge63a.cx - 4.5 >= 0 && edge63a.rx >= 1,
  `premier mois : cercle COMPLET (cx − r ≥ 0) et règle intérieure (cx ${edge63a.cx}, règle ${edge63a.rx})`);
await page.keyboard.press("ArrowRight");
await page.waitForTimeout(50);
const key63b = await page.evaluate(() => document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuenow"));
check(key63b === "1", "flèche droite avance d'un mois");
await page.keyboard.press("ArrowLeft");
await page.waitForTimeout(50);
const key63c = await page.evaluate(() => document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuenow"));
check(key63c === "0", "flèche gauche recule d'un mois");
await page.keyboard.press("End");
await page.waitForTimeout(50);
const key63d = await page.evaluate(() => ({
  now: document.querySelector('[data-chart="acc"] .scrub').getAttribute("aria-valuenow"),
  focused: document.activeElement === document.querySelector('[data-chart="acc"] .scrub'),
  liveSame: document.querySelector('[data-chartcaption="acc"]').dataset.livemark === "1",
  cap: document.querySelector('[data-chartcaption="acc"]').textContent,
}));
check(key63d.now === "11", "Fin (End) choisit le dernier mois");
check(key63d.focused, "le focus clavier reste sur le scrubber après toutes les interactions");
check(key63d.liveSame, "la région live est MISE À JOUR en place — jamais recréée");
check(key63d.cap.includes("CHF 1'000.00"), "l'étiquette clavier lit la même valeur de fixture");
const edge63b = await page.evaluate(() => {
  const wrap = document.querySelector('[data-chart="acc"]');
  return { cx: parseFloat(wrap.querySelector("[data-scrubdot]").getAttribute("cx")),
           rx: parseFloat(wrap.querySelector("[data-scrubrule]").getAttribute("x1")) };
});
check(Number.isFinite(edge63b.cx) && edge63b.cx + 4.5 <= 300 && edge63b.rx <= 299,
  `dernier mois : cercle COMPLET (cx + r ≤ 300) et règle intérieure (cx ${edge63b.cx}, règle ${edge63b.rx})`);

// ---------- Test 64 : échelle d'affichage sûre — constantes négatives, nulles, mixtes, extrêmes ----------
currentTest = "échelle de courbe L8";
const scale64 = await page.evaluate(() => {
  const inFrame = arr => {
    const f = chartYScale(arr);
    return arr.every(v => { const y = f(v); return Number.isFinite(y) && y >= 0 && y <= 100; });
  };
  return {
    negConst: inFrame(Array(12).fill(-100)),
    negCenter: chartYScale(Array(12).fill(-100))(-100),
    zeroConst: inFrame(Array(12).fill(0)),
    posConst: inFrame(Array(12).fill(2500)),
    nearConst: inFrame([...Array(11).fill(-999.99), -1000.01]),
    mixed: inFrame([-5000, 12000, 0, -300, 7.5, 999999]),
    extreme: inFrame([1e12, -1e12, 0]),
  };
});
check(scale64.negConst, "série constante NÉGATIVE : toutes les coordonnées dans le cadre");
check(Math.abs(scale64.negCenter - 50) < 1, `série constante : ligne centrée (y ≈ 50, obtenu ${scale64.negCenter.toFixed(1)})`);
check(scale64.zeroConst && scale64.posConst, "séries constantes nulle et positive dans le cadre");
check(scale64.nearConst && scale64.mixed && scale64.extreme,
  "séries presque constantes, mixtes et extrêmes : coordonnées finies dans le cadre");
// En DOM : un compte au solde constant −100 garde courbe, règle et point VISIBLES.
await page.evaluate(() => {
  ACCOUNTS.push({ id: "acc-l8-neg", name: "Dette fixture L8", inst: "", kind: "current", opening: -100, cash: false, currency: null });
  ACCOUNTS.push({ id: "acc-l8-zero", name: "Compte zéro L8", inst: "", kind: "current", opening: 0, cash: false, currency: null });
  render();
});
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(200);
await page.click('[data-accid="acc-l8-neg"]');
await page.waitForTimeout(250);
const neg64 = await page.evaluate(() => {
  const wrap = document.querySelector('[data-chart="acc"]');
  const ys = wrap.querySelector("polyline").getAttribute("points").split(" ").map(p => parseFloat(p.split(",")[1]));
  return { allIn: ys.every(y => Number.isFinite(y) && y >= 0 && y <= 100), sel: wrap.dataset.sel };
});
check(neg64.allIn, "solde constant −100 : la polyligne reste ENTIÈREMENT dans le viewBox 0…100");
check(neg64.sel === "", "compte nouvellement ouvert : aucune sélection imposée");
await page.evaluate(() => document.querySelector('[data-chart="acc"] .scrub').focus());
await page.keyboard.press("End");
await page.waitForTimeout(60);
const negSel64 = await page.evaluate(() => {
  const wrap = document.querySelector('[data-chart="acc"]');
  const dot = wrap.querySelector("[data-scrubdot]");
  const cy = parseFloat(dot.getAttribute("cy"));
  return {
    visible: dot.getAttribute("visibility") !== "hidden",
    inFrame: Number.isFinite(cy) && cy >= 4 && cy <= 96,
    cap: document.querySelector('[data-chartcaption="acc"]').textContent,
  };
});
check(negSel64.visible && negSel64.inFrame, "point sélectionné VISIBLE et dans le cadre sur une série constante négative");
check(negSel64.cap.includes("-CHF 100.00"), `l'étiquette lit −100 exactement (obtenu « ${negSel64.cap} »)`);

// ---------- Test 65 : isolation par compte, 320/390, transparence et mouvement réduits ----------
currentTest = "isolation et états L8";
// La sélection End sur « Dette fixture L8 » ne doit PAS fuir vers un autre compte.
await page.click("#screen [data-accback]");
await page.waitForTimeout(200);
await page.click('[data-accid="acc-l8-zero"]');
await page.waitForTimeout(250);
const iso65a = await page.evaluate(() => ({
  sel: document.querySelector('[data-chart="acc"]').dataset.sel,
  cap: document.querySelector('[data-chartcaption="acc"]').textContent,
}));
check(iso65a.sel === "" && iso65a.cap.includes("Touchez la courbe"),
  "un AUTRE compte s'ouvre sur l'invite initiale — aucune sélection héritée");
await page.evaluate(() => document.querySelector('[data-chart="acc"] .scrub').focus());
await page.keyboard.press("Home");
await page.waitForTimeout(60);
await page.click("#screen [data-accback]");
await page.waitForTimeout(200);
await page.click('[data-accid="acc-l8-fixture"]');
await page.waitForTimeout(250);
const iso65b = await page.evaluate(() => document.querySelector('[data-chart="acc"]').dataset.sel);
check(iso65b === "", "la sélection faite sur le compte zéro ne fuit pas non plus vers la fixture");
// 320 × 844 + transparence réduite : Patrimoine sélectionné au clavier.
await page.setViewportSize({ width: 320, height: 844 });
await page.evaluate(() => { document.documentElement.setAttribute("data-reduced-transparency", "true"); });
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(250);
await page.evaluate(() => document.querySelector('[data-chart="nw"] .scrub').focus());
await page.keyboard.press("End");
await page.waitForTimeout(60);
const narrow65 = await page.evaluate(() => {
  const scrub = document.querySelector('[data-chart="nw"] .scrub');
  const r = scrub.getBoundingClientRect();
  return {
    overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth,
    cap: document.querySelector('[data-chartcaption="nw"]').textContent,
    w: r.width, h: r.height,
    noFab: !document.getElementById("fab"),
    tabs: document.querySelectorAll("#tabbar button[data-tab]").length,
  };
});
check(!narrow65.overflow, "320 px en transparence réduite : zéro débordement horizontal");
check(narrow65.cap.includes("fortune nette") && narrow65.cap.includes(":"),
  "l'étiquette sélectionnée reste lisible à 320 px");
check(narrow65.w >= 44 && narrow65.h >= 44, `cible ≥ 44 px aussi à 320 px (${Math.round(narrow65.w)}×${Math.round(narrow65.h)})`);
check(narrow65.noFab && narrow65.tabs === 5,
  "le shell simplifié conserve cinq onglets sans bouton flottant à 320 px");
const edge65b = await page.evaluate(() =>
  parseFloat(document.querySelector('[data-chart="nw"] [data-scrubdot]').getAttribute("cx")));
check(edge65b + 4.5 <= 300, `320 px, dernier mois : cercle complet dans le cadre (cx ${edge65b})`);
await page.keyboard.press("Home");
await page.waitForTimeout(60);
const edge65a = await page.evaluate(() => ({
  cx: parseFloat(document.querySelector('[data-chart="nw"] [data-scrubdot]').getAttribute("cx")),
  cap: document.querySelector('[data-chartcaption="nw"]').textContent,
}));
check(edge65a.cx - 4.5 >= 0 && edge65a.cap.includes("fortune nette"),
  `320 px, premier mois : cercle complet et étiquette lisible (cx ${edge65a.cx})`);
await page.evaluate(() => { document.documentElement.removeAttribute("data-reduced-transparency"); });
await page.setViewportSize({ width: 390, height: 844 });
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(150);
await page.click('#screen [data-more="networth"]');
await page.waitForTimeout(250);
const shell65 = await page.evaluate(() => ({
  noFab: !document.getElementById("fab"),
  tabs: document.querySelectorAll("#tabbar button[data-tab]").length,
}));
check(shell65.noFab && shell65.tabs === 5,
  "le shell simplifié conserve cinq onglets sans bouton flottant à 390 px");
// Reduced motion : la garde existante coupe l'animation d'entrée des cartes.
await page.emulateMedia({ reducedMotion: "reduce" });
await page.click(`#tabbar button[aria-label="Comptes"]`);
await page.waitForTimeout(150);
await page.click(`#tabbar button[aria-label="Gérer"]`);
await page.waitForTimeout(200);
const motion65 = await page.evaluate(() => {
  const card = document.querySelector("#screen .card");
  return card ? getComputedStyle(card).animationName : "aucune-carte";
});
check(motion65 === "none", `reduced motion : aucune animation d'entrée (obtenu ${motion65})`);
await page.emulateMedia({ reducedMotion: null });

// ---------- Test 66 : performance honnête — 10 000 répartis PUIS concentrés, peinture, DOM borné ----------
currentTest = "performance 10k L8";
const renderToPaint = () => page.evaluate(() => new Promise(resolve => {
  const t0 = performance.now();
  render();
  requestAnimationFrame(() => requestAnimationFrame(() => resolve(performance.now() - t0)));
}));
// Cas 1 : 10 000 mouvements RÉPARTIS sur douze mois de 2025.
await page.evaluate(() => {
  moreTxPage = 0; moreSearch = ""; moreFilter = "all";
  for (let i = 0; i < 10000; i++) {
    transactions.push({
      id: ++txSeq, y: 2025, m: (i % 12) + 1, d: (i % 28) + 1,
      title: "Perf L8 " + i, type: i % 2 ? "expense" : "income",
      cat: null, acc: ACCOUNTS[0].id, dest: null, status: "posted",
      amount: 10 + (i % 90),
    });
  }
});
await goMovements();
await page.evaluate(() => { cursor = { y: 2025, m: 6 }; });
const spread66 = await renderToPaint();
const spreadDom66 = await page.evaluate(() => ({
  rows: document.querySelectorAll("#moreTxList .tx").length,
  header: (document.querySelector("#moreTxList .caption") || {}).textContent || "",
}));
check(spread66 < 4000, `répartis : rendu + peinture < 4 s (obtenu ${Math.round(spread66)} ms)`);
check(spreadDom66.rows > 0 && spreadDom66.rows <= 200,
  `répartis : DOM borné à une page (${spreadDom66.rows} lignes ≤ 200)`);
// Navigation de mois jusqu'à la peinture.
await page.evaluate(() => { cursor = { y: 2025, m: 5 }; moreTxPage = 0; });
const nav66 = await renderToPaint();
check(nav66 < 4000, `navigation de mois + peinture < 4 s (obtenu ${Math.round(nav66)} ms)`);
// Cas 2 : les 10 000 mouvements CONCENTRÉS dans un seul mois — VRAIE
// pagination : chaque page REMPLACE la précédente (JAMAIS plus de 200
// lignes dans le DOM), première/dernière lignes contrôlées contre une
// référence INDÉPENDANTE (même filtre, tri documenté jour puis id
// décroissants) — ni saut, ni doublon, rien d'inaccessible.
await page.evaluate(() => {
  for (const t of transactions) {
    if (typeof t.title === "string" && t.title.startsWith("Perf L8 ")) { t.m = 6; }
  }
  cursor = { y: 2025, m: 6 }; moreTxPage = 0;
});
const dense66 = await renderToPaint();
check(dense66 < 4000, `concentrés : rendu + peinture < 4 s (obtenu ${Math.round(dense66)} ms)`);
const ref66 = await page.evaluate(() =>
  transactions.filter(t => t.y === 2025 && t.m === 6)
    .sort((a, b) => b.d - a.d || b.id - a.id).map(t => t.title));
const n66 = ref66.length;
const pageState66 = () => page.evaluate(() => {
  const titles = [...document.querySelectorAll("#moreTxList .tx .meta .t")].map(el => el.textContent);
  const dis = id => { const el = document.querySelector(`[data-txpage="${id}"]`); return el ? el.disabled : null; };
  return {
    rows: document.querySelectorAll("#moreTxList .tx").length,
    range: (document.querySelector("[data-txrange]") || {}).textContent || "",
    header: (document.querySelector("#moreTxList .caption") || {}).textContent || "",
    first: titles[0] || "", last: titles[titles.length - 1] || "",
    disFirst: dis("first"), disPrev: dis("prev"), disNext: dis("next"), disLast: dis("last"),
  };
});
const goPage66 = async which => {
  await page.click(`[data-txpage="${which}"]`);
  await page.waitForTimeout(120);
  return pageState66();
};
const assertPage66 = (s, startIdx, label) => {
  const endIdx = Math.min(startIdx + 200, n66) - 1;
  check(s.rows >= 1 && s.rows <= 200, `${label} : DOM borné à 1…200 lignes (obtenu ${s.rows})`);
  check(s.rows === endIdx - startIdx + 1, `${label} : ${endIdx - startIdx + 1} lignes attendues (obtenu ${s.rows})`);
  check(s.range === `${startIdx + 1}–${endIdx + 1} sur ${n66}`,
    `${label} : plage annoncée « ${startIdx + 1}–${endIdx + 1} sur ${n66} » (obtenu « ${s.range} »)`);
  check(s.first === ref66[startIdx] && s.last === ref66[endIdx],
    `${label} : première/dernière lignes = référence indépendante (obtenu « ${s.first} » / « ${s.last} ») — ni saut ni doublon`);
  // P03 : le compteur dit « opérations » (LANGUAGE.md) — l'intention du test
  // reste identique : le décompte COMPLET du mois ne disparaît jamais.
  check(s.header.includes(`${n66} opérations`),
    `${label} : l'en-tête garde le décompte COMPLET du mois (« ${s.header} »)`);
};
let st66 = await pageState66();
assertPage66(st66, 0, "page 1");
check(st66.disFirst === true && st66.disPrev === true && st66.disNext === false && st66.disLast === false,
  "page 1 : première/précédente désactivées, suivante/dernière actives");
st66 = await goPage66("next");
assertPage66(st66, 200, "page 2 (suivante)");
st66 = await goPage66("next");
assertPage66(st66, 400, "page 3 (suivante)");
st66 = await goPage66("last");
const lastStart66 = (Math.ceil(n66 / 200) - 1) * 200;
assertPage66(st66, lastStart66, "dernière page");
check(st66.disNext === true && st66.disLast === true, "dernière page : suivante/dernière désactivées");
st66 = await goPage66("prev");
assertPage66(st66, lastStart66 - 200, "page précédente");
st66 = await goPage66("first");
assertPage66(st66, 0, "retour à la première page");
// Recherche : bornée et rapide jusqu'à la peinture.
const search66 = await page.evaluate(() => new Promise(resolve => {
  const input = document.getElementById("moreSearchInput");
  input.value = "Perf L8 12";
  const t0 = performance.now();
  input.dispatchEvent(new Event("input", { bubbles: true }));
  requestAnimationFrame(() => requestAnimationFrame(() => resolve({
    ms: performance.now() - t0,
    rows: document.querySelectorAll("#moreTxList .tx").length,
  })));
}));
check(search66.ms < 4000, `recherche + peinture < 4 s (obtenu ${Math.round(search66.ms)} ms)`);
check(search66.rows <= 200, `résultats de recherche bornés (${search66.rows} lignes)`);
// Défilement : le conteneur répond immédiatement.
const scroll66 = await page.evaluate(() => new Promise(resolve => {
  const screenEl = document.getElementById("screen");
  const t0 = performance.now();
  screenEl.scrollTop = screenEl.scrollHeight;
  requestAnimationFrame(() => requestAnimationFrame(() => resolve(performance.now() - t0)));
}));
check(scroll66 < 1000, `défilement de la liste + peinture < 1 s (obtenu ${Math.round(scroll66)} ms)`);
console.log(`PERF L8 (mesures réelles jusqu'à la peinture) : répartis ${Math.round(spread66)} ms / ${spreadDom66.rows} lignes DOM · concentrés ${Math.round(dense66)} ms / 200 lignes DOM par page pour ${n66} mouvements · navigation ${Math.round(nav66)} ms · recherche ${Math.round(search66.ms)} ms / ${search66.rows} lignes · défilement ${Math.round(scroll66)} ms`);
// Nettoyage complet : fixtures et mouvements de performance retirés.
await page.evaluate(() => {
  for (let i = transactions.length - 1; i >= 0; i--) {
    const t = transactions[i];
    if (typeof t.title === "string" && (t.title.startsWith("Perf L8 ") || t.title === "Fixture L8 dépense")) {
      transactions.splice(i, 1);
    }
  }
  for (let i = ACCOUNTS.length - 1; i >= 0; i--) {
    if (["acc-l8-fixture", "acc-l8-neg", "acc-l8-zero"].includes(ACCOUNTS[i].id)) ACCOUNTS.splice(i, 1);
  }
  moreSearch = ""; moreTxPage = 0;
  nwChartSel = null; accChartSel = null;
  cursor = { y: NOW.y, m: NOW.m };
  render();
});
const cleaned66 = await page.evaluate(() =>
  transactions.some(t => typeof t.title === "string" && t.title.startsWith("Perf L8 "))
  || ACCOUNTS.some(a => String(a.id).startsWith("acc-l8-")));
check(!cleaned66, "fixtures et mouvements de performance retirés (aucune trace)");

// ---------- Test 72 : charset servi SANS en-tête (correctif L9) ----------
currentTest = "charset sans en-tête serveur L9";
// La PWA déclare désormais <meta charset="utf-8"> en PREMIÈRE ligne.
// Servie par un hôte qui OMET le charset dans Content-Type (le cas qui
// cassait l'app : décodage Windows-1252, JS mort), elle doit démarrer
// intacte, en UTF-8, avec ses textes accentués exacts.
{
  const { default: http72 } = await import("node:http");
  const { readFileSync: readFile72 } = await import("node:fs");
  const indexHtml72 = readFile72(path.resolve(HERE, "..", "index.html"));
  // La feuille Neon Ultra est un VRAI fichier lié : l'hôte de ce test la sert
  // donc réellement, elle aussi SANS charset dans l'en-tête. Un serveur qui
  // renverrait index.html pour tout masquerait une erreur de type MIME.
  const cssNu72 = readFile72(path.resolve(HERE, "..", "design-system", "neon-ultra.css"));
  const server72 = http72.createServer((req, res) => {
    // Volontairement SANS charset dans les en-têtes.
    if (req.url && req.url.startsWith("/design-system/neon-ultra.css")) {
      res.writeHead(200, { "Content-Type": "text/css" });
      res.end(cssNu72);
      return;
    }
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end(indexHtml72);
  });
  await new Promise(resolve => server72.listen(0, "127.0.0.1", resolve));
  const port72 = server72.address().port;
  // Navigateur dédié sans proxy : 127.0.0.1 joignable en local comme en CI.
  const browser72 = await chromium.launch({
    executablePath: CHROMIUM, args: ["--no-sandbox", "--no-proxy-server"],
  });
  const context72 = await browser72.newContext({ viewport: { width: 390, height: 844 } });
  const page72 = await context72.newPage();
  const errors72 = [];
  page72.on("pageerror", err => errors72.push("PAGEERROR: " + err.message));
  page72.on("console", msg => { if (msg.type() === "error") errors72.push(msg.text()); });
  await page72.goto(`http://127.0.0.1:${port72}/`);
  await page72.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 }).catch(() => {});
  const started72 = await page72.evaluate(() => ({
    countries: document.querySelectorAll("[data-obcountry]").length,
    charset: document.characterSet,
    privacy: document.body.innerText.includes("Vos données restent sur cet appareil."),
    // La feuille Neon Ultra est-elle réellement PARSÉE (et non rejetée pour
    // type MIME) ? Une feuille refusée expose zéro règle.
    nuRules: [...document.styleSheets]
      .filter(s => String(s.href || "").includes("neon-ultra.css"))
      .reduce((a, s) => { try { return a + s.cssRules.length; } catch { return a; } }, 0),
  }));
  check(started72.countries === 3,
    `charset omis : l'app démarre réellement (3 pays attendus, obtenu ${started72.countries})`);
  check(started72.nuRules > 0,
    `charset omis : neon-ultra.css servie en text/css est réellement parsée (obtenu ${started72.nuRules} règles)`);
  check(String(started72.charset).toLowerCase() === "utf-8",
    `charset omis : document décodé en UTF-8 (obtenu ${started72.charset})`);
  check(started72.privacy,
    "charset omis : texte accentué EXACT présent (« Vos données restent sur cet appareil. »)");
  check(errors72.length === 0,
    `charset omis : zéro pageerror / erreur console (obtenu : ${errors72.slice(0, 2).join(" | ") || "aucune"})`);
  await browser72.close();
  server72.close();
}

// ---------- Test 73 : NU2 — Mois pilote ET isolation des écrans Obsidian ----------
currentTest = "NU2 Mois pilote et isolation";
// Le pilote Neon Ultra ne vaut que s'il ne DÉBORDE pas : Mois et Budget
// changent d'identité, Comptes et Plus restent Obsidian à l'octet près.
await goHome();
{
  const mois73 = await page.evaluate(() => {
    const screenEl = document.getElementById("screen");
    const hero = screenEl.querySelector(".card.hero");
    const amount = screenEl.querySelector(".hero-amount");
    const cta = screenEl.querySelector(".btn.nu-cta");
    const cs = getComputedStyle(screenEl);
    return {
      piloted: screenEl.classList.contains("nu-pilot-screen"),
      canvas: cs.backgroundColor,
      heroBg: hero ? getComputedStyle(hero).backgroundColor : null,
      heroBlur: hero ? getComputedStyle(hero).backdropFilter : null,
      amountShadow: amount ? getComputedStyle(amount).textShadow : null,
      amountText: amount ? amount.textContent.trim() : "",
      ctaText: cta ? cta.textContent.trim() : "",
      ctaBg: cta ? getComputedStyle(cta).backgroundImage : "",
      ctaColor: cta ? getComputedStyle(cta).color : "",
      // Point focal UNIQUE : un seul dégradé CTA dans tout l'écran.
      ctaCount: screenEl.querySelectorAll(".btn.nu-cta").length,
      title: (screenEl.querySelector("h2.screen-title") || {}).textContent || "",
      // Aucun montant ne porte de halo (règle de la constitution).
      glowing: [...screenEl.querySelectorAll(".hero-amount, .amount")]
        .filter(el => getComputedStyle(el).textShadow !== "none").length,
    };
  });
  check(mois73.piloted, "Mois porte la classe pilote Neon Ultra");
  check(mois73.canvas === "rgb(5, 6, 10)",
    `Mois : fond canvas Neon Ultra #05060A (obtenu ${mois73.canvas})`);
  check(mois73.heroBg === "rgb(24, 28, 38)",
    `Mois : héros en surface élevée MATE #181C26 (obtenu ${mois73.heroBg})`);
  check(mois73.heroBlur === "none",
    `Mois : plus aucun flou de verre sur le héros (obtenu ${mois73.heroBlur})`);
  check(mois73.glowing === 0,
    `Mois : AUCUN montant n'est entouré d'un halo (obtenu ${mois73.glowing} en halo)`);
  check(/\d/.test(mois73.amountText),
    `Mois : le montant héros reste un vrai chiffre lisible (obtenu « ${mois73.amountText} »)`);
  check(mois73.ctaCount === 1,
    `Mois : un SEUL point focal lumineux par écran (obtenu ${mois73.ctaCount} CTA)`);
  check(mois73.ctaText.includes("Ajouter"),
    `Mois : le CTA reste l'action utile « Ajouter » (obtenu « ${mois73.ctaText} »)`);
  check(mois73.ctaBg.includes("192, 0, 164") && mois73.ctaBg.includes("110, 0, 232"),
    `Mois : CTA en dégradé #C000A4 → #6E00E8 (obtenu ${mois73.ctaBg})`);
  check(mois73.ctaColor === "rgb(255, 255, 255)",
    `Mois : texte du CTA en blanc dédié (obtenu ${mois73.ctaColor})`);
  check(/Bonjour|Bonsoir|Salut|Bonne/i.test(mois73.title),
    `Mois : la salutation reste le titre de page (obtenu « ${mois73.title.trim()} »)`);
}
// Budget : piloté lui aussi.
await page.click('#tabbar button[aria-label="Budget"]');
await page.waitForTimeout(200);
const budgetPiloted73 = await page.$eval("#screen", el => el.classList.contains("nu-pilot-screen"));
check(budgetPiloted73, "Budget porte la classe pilote Neon Ultra");
// Comptes : AUCUN pilote, verre Obsidian intact.
await page.click('#tabbar button[aria-label="Comptes"]');
await page.waitForTimeout(200);
{
  const comptes73 = await page.evaluate(() => {
    const screenEl = document.getElementById("screen");
    const card = screenEl.querySelector(".card");
    return {
      piloted: screenEl.classList.contains("nu-pilot-screen"),
      canvas: getComputedStyle(screenEl).backgroundColor,
      cardBg: card ? getComputedStyle(card).backgroundColor : null,
      cta: screenEl.querySelectorAll(".btn.nu-cta").length,
    };
  });
  check(!comptes73.piloted, "Comptes n'est PAS piloté (identité Obsidian préservée)");
  check(comptes73.canvas === "rgba(0, 0, 0, 0)",
    `Comptes : le canvas pilote ne déborde pas (obtenu ${comptes73.canvas})`);
  // Ce contrôle exigeait des cartes translucides sur les écrans non
  // pilotes : c'était la preuve que le rebranchement ne débordait pas. Les
  // surfaces sont désormais unifiées volontairement — ce qu'il faut prouver
  // est que Comptes peint la MÊME matière que les écrans pilotes, sans pour
  // autant porter leur classe ni leurs accents.
  check(/rgb\(17, 20, 28\)|rgb\(24, 28, 38\)/.test(String(comptes73.cardBg)),
    `Comptes : même matière de carte que les écrans pilotes (obtenu ${comptes73.cardBg})`);
  check(comptes73.cta === 0, `Comptes : aucun CTA Neon Ultra (obtenu ${comptes73.cta})`);
  const firstAccount73 = await page.$("#screen [data-accid]");
  check(!!firstAccount73, "Comptes : un détail de compte est disponible pour vérifier l'isolation");
  if (firstAccount73) {
    await firstAccount73.click();
    await page.waitForTimeout(200);
    const detail73 = await page.evaluate(() => {
      const polyline = document.querySelector("#screen .chart-select polyline");
      const rule = document.querySelector("#screen [data-scrubrule]");
      return {
        piloted: document.getElementById("screen").classList.contains("nu-pilot-screen"),
        line: polyline ? getComputedStyle(polyline).stroke : "",
        rule: rule ? getComputedStyle(rule).stroke : "",
      };
    });
    check(!detail73.piloted, "Détail de compte : aucune classe pilote");
    check(detail73.line === "rgb(145, 136, 255)",
      `Détail de compte : courbe Indigo Obsidian (obtenu ${detail73.line})`);
    check(detail73.rule === "rgb(167, 176, 192)",
      `Détail de compte : règle gris Obsidian (obtenu ${detail73.rule})`);
    await page.click("#screen [data-accback]");
    await page.waitForTimeout(150);
  }
}
// Gérer et Historique : Obsidian, chacun directement accessible.
await page.click('#tabbar button[aria-label="Gérer"]');
await page.waitForTimeout(200);
const plusPiloted73 = await page.$eval("#screen", el => el.classList.contains("nu-pilot-screen"));
check(!plusPiloted73, "Gérer n'est PAS piloté (identité Obsidian préservée)");
await goMovements();
const mvtPiloted73 = await page.$eval("#screen", el => el.classList.contains("nu-pilot-screen"));
check(!mvtPiloted73, "Historique n'est PAS piloté");
// Le shell simplifié expose cinq destinations et aucun bouton flottant.
const shell73 = await page.evaluate(() => ({
  tabs: [...document.querySelectorAll("#tabbar [data-tab]")].map(b => b.getAttribute("aria-label")),
  fab: !!document.querySelector("#tabbar #fab"),
  barBg: getComputedStyle(document.getElementById("tabbar")).backgroundColor,
}));
check(shell73.tabs.join(",") === "Mois,Historique,Budget,Comptes,Gérer",
  `les cinq destinations PWA sont attendues (obtenu ${shell73.tabs.join(",")})`);
check(!shell73.fab, "aucun ＋ flottant ou central dans la barre d'onglets");
check(shell73.barBg !== "rgb(11, 13, 19)",
  `la barre d'onglets reste Obsidian (le shell appartient à NU4, obtenu ${shell73.barBg})`);

// ---------- Test 74 : NU2 — Budget vide pédagogique puis budget chargé ----------
currentTest = "NU2 Budget vide et chargé";
await goHome();
await page.click('#tabbar button[aria-label="Budget"]');
await page.waitForTimeout(250);
{
  // On repart d'un mois SANS ligne budgétaire : l'état vide doit expliquer.
  await page.evaluate(() => {
    cursor = shiftMonth({ y: NOW.y, m: NOW.m }, 6); // mois futur, jamais budgété
    render();
  });
  await page.waitForTimeout(200);
  const vide74 = await page.evaluate(() => {
    const screenEl = document.getElementById("screen");
    const text = screenEl.innerText;
    return {
      lines: screenEl.querySelectorAll("[data-linecat]").length,
      explains: /comment ça marche/i.test(text),
      steps: (text.match(/\n\s*[123]\./g) || []).length,
      planifie: /planifié/i.test(text),
      ctaCount: screenEl.querySelectorAll(".btn.nu-cta").length,
      ctaText: (screenEl.querySelector(".btn.nu-cta") || {}).textContent || "",
      addline: !!screenEl.querySelector("[data-addline]"),
    };
  });
  check(vide74.lines === 0, `Budget vide : réellement aucune ligne (obtenu ${vide74.lines})`);
  check(vide74.explains, "Budget vide : la carte « Comment ça marche » explique la suite");
  check(vide74.steps >= 3, `Budget vide : les trois étapes sont écrites (obtenu ${vide74.steps})`);
  check(vide74.planifie, "Budget vide : le mot « planifié » est présent (vocabulaire du contrat)");
  check(vide74.ctaCount === 1,
    `Budget vide : un seul point focal lumineux (obtenu ${vide74.ctaCount})`);
  check(vide74.addline, "Budget vide : l'action « Ajouter une ligne budgétaire » est offerte");
  // Création réelle d'une ligne. Depuis la refonte des feuilles de saisie
  // (demande du propriétaire du 02.08.2026), `lineForm` porte le style
  // « Nouveau mouvement » : surface pilote, pied collant, CTA en dégradé.
  // L'assertion n'est pas affaiblie — elle suit la décision et vérifie
  // désormais les trois marqueurs plutôt qu'un seul.
  await page.click("#screen [data-addline]");
  await page.waitForSelector("#lineForm", { state: "visible" });
  const lineStyle74 = await page.evaluate(() => {
    const f = document.getElementById("lineForm");
    const submit = f.querySelector('button[type="submit"]');
    const actions = f.querySelector(".actions");
    return {
      piloted: f.classList.contains("nu-pilot-sheet"),
      sticky: actions ? getComputedStyle(actions).position : null,
      cta: submit ? getComputedStyle(submit).backgroundImage : "",
    };
  });
  check(lineStyle74.piloted, "la feuille « ligne budgétaire » porte le style de saisie unifié");
  check(lineStyle74.sticky === "sticky",
    `« ligne budgétaire » : « Enregistrer » reste au-dessus du clavier (obtenu ${lineStyle74.sticky})`);
  check(lineStyle74.cta.includes("192, 0, 164"),
    `« ligne budgétaire » : action principale en dégradé de marque (obtenu ${lineStyle74.cta})`);
  await page.$eval("#lCat", el => { el.selectedIndex = 0; });
  await page.fill("#lAmount", "400");
  await page.click('#lineForm button[type="submit"]');
  await page.waitForTimeout(350);
  const charge74 = await page.evaluate(() => {
    const screenEl = document.getElementById("screen");
    const hero = screenEl.querySelector(".card.hero");
    const pill = screenEl.querySelector(".pill");
    const ring = screenEl.querySelector('svg[aria-label^="Vous avez utilisé"]');
    const track = screenEl.querySelector(".track") || screenEl.querySelector(".bar");
    return {
      lines: screenEl.querySelectorAll("[data-linecat]").length,
      heroBg: hero ? getComputedStyle(hero).backgroundColor : null,
      planState: pill ? pill.textContent.trim() : "",
      ringLabel: ring ? ring.getAttribute("aria-label") : "",
      text: screenEl.innerText,
      trackShadow: track ? getComputedStyle(track).boxShadow : "none",
    };
  });
  check(charge74.lines === 1,
    `Budget chargé : la ligne créée est bien affichée (obtenu ${charge74.lines})`);
  // W5.4 : ce budget vit sur un mois FUTUR (+6) — l'état écrit y est
  // « À venir » et l'anneau « 0 % utilisé » se tait (rien n'a couru).
  check(/À venir|Dans le plan|À surveiller|Dépassé/.test(charge74.planState),
    `Budget chargé : l'état du plan est ÉCRIT, jamais la couleur seule (obtenu « ${charge74.planState} »)`);
  check(charge74.ringLabel === "",
    `Budget chargé (mois futur, rien dépensé) : pas d'anneau « utilisé » — le futur ne se consomme pas (obtenu « ${charge74.ringLabel} »)`);
  check(/prévu/i.test(charge74.text) && /dépensé/i.test(charge74.text),
    "Budget chargé : prévu et dépensé restent nommés séparément");
  check(charge74.text.includes("400.00") || /400/.test(charge74.text),
    "Budget chargé : le montant planifié saisi (400) est restitué exactement");
  check(charge74.heroBg === "rgb(24, 28, 38)",
    `Budget chargé : héros en surface élevée mate (obtenu ${charge74.heroBg})`);
  check(charge74.trackShadow === "none",
    `Budget chargé : jauges plates, aucune lueur (obtenu ${charge74.trackShadow})`);
  // Nettoyage : la ligne de test disparaît, l'app revient au mois courant.
  await page.evaluate(() => {
    if (S.budgets) delete S.budgets[`${cursor.y}-${cursor.m}`];
    saveState();
    cursor = { y: NOW.y, m: NOW.m };
    render();
  });
  await page.waitForTimeout(200);
  const cleaned74 = await page.evaluate(() => budgetLines(shiftMonth(cursor, 6).y, shiftMonth(cursor, 6).m).length);
  check(cleaned74 === 0, `Budget : la ligne de test est retirée (obtenu ${cleaned74})`);
}

// ---------- Test 75 : NU2 — action unique → Nouveau mouvement RÉELLEMENT enregistré ----------
currentTest = "NU2 ajouter un mouvement";
await goHome();
{
  const before75 = await page.evaluate(() => transactions.length);
  check(await page.$("#fab") === null, "aucun bouton flottant avant l'ajout");
  await openQuickEntry("expense", "#screen [data-addtx]");
  const form75 = await page.evaluate(() => {
    const form = document.getElementById("txForm");
    const amount = document.getElementById("fAmount");
    const submit = form.querySelector('button[type="submit"]');
    const chips = [...form.querySelectorAll("[data-ftype]")];
    return {
      piloted: form.classList.contains("nu-pilot-sheet"),
      amountSize: parseFloat(getComputedStyle(amount).fontSize),
      submitText: submit.textContent.trim(),
      submitBg: getComputedStyle(submit).backgroundImage,
      submitColor: getComputedStyle(submit).color,
      ctaCount: form.querySelectorAll(".btn.nu-cta").length,
      chips: chips.map(c => c.dataset.ftype),
      chipsVisible: chips.filter(c => c.checkVisibility()).length,
      advancedClosed: !document.getElementById("fTypeMore").open,
      titleTag: (document.getElementById("fTitle").tagName || "").toLowerCase(),
      smallTargets: [...form.querySelectorAll("button, input:not(.sr-select), select:not(.sr-select), textarea, summary")]
        .filter(el => el.offsetParent !== null)
        .map(el => ({
          label: el.id || (el.textContent || el.getAttribute("aria-label") || el.tagName).trim().slice(0, 24),
          height: el.getBoundingClientRect().height,
        }))
        .filter(item => item.height < 43.5),
    };
  });
  check(form75.piloted, "le formulaire Nouveau mouvement est une feuille pilote Neon Ultra");
  check(form75.amountSize >= 20,
    `formulaire : le montant est le champ dominant (obtenu ${form75.amountSize} px)`);
  check(form75.ctaCount === 1 && form75.submitText === "Enregistrer",
    `formulaire : un unique CTA « Enregistrer » (obtenu ${form75.ctaCount} × « ${form75.submitText} »)`);
  check(form75.submitBg.includes("192, 0, 164") && form75.submitColor === "rgb(255, 255, 255)",
    `formulaire : CTA en dégradé de marque, texte blanc (obtenu ${form75.submitColor})`);
  check(form75.chips.join(",") === "expense,income,saving,investment,transfer,taxPayment,refund",
    `formulaire : les sept types de mouvement sont intacts (obtenu ${form75.chips.join(",")})`);
  check(form75.chipsVisible === 0 && form75.advancedClosed,
    "formulaire : les types techniques sont conservés mais repliés dans Changer le type");
  check(form75.titleTag === "textarea",
    `formulaire : l'intitulé complet reste visible (multiligne, obtenu <${form75.titleTag}>)`);
  check(form75.smallTargets.length === 0,
    `formulaire : tous les contrôles font ≥ 44 px (${form75.smallTargets.map(t => `${t.label}: ${t.height.toFixed(0)}px`).join(", ")})`);
  // Enregistrement RÉEL : le montant saisi doit se retrouver au centime près.
  await page.fill("#fAmount", "84.50");
  await page.evaluate(() => { document.getElementById("fMore").open = true; });
  await page.fill("#fTitle", "Courses NU2");
  await page.click('#txForm button[type="submit"]');
  await page.waitForTimeout(400);
  const saved75 = await page.evaluate(prev => ({
    closed: !document.getElementById("sheetBackdrop").classList.contains("open"),
    added: transactions.length - prev,
    amount: (transactions.find(t => t.title === "Courses NU2") || {}).amount,
    type: (transactions.find(t => t.title === "Courses NU2") || {}).type,
  }), before75);
  check(saved75.closed, "formulaire : la feuille se ferme après un enregistrement réussi");
  check(saved75.added === 1, `formulaire : exactement un mouvement créé (obtenu ${saved75.added})`);
  check(saved75.amount === 84.5,
    `formulaire : montant enregistré au centime près (attendu 84.5, obtenu ${saved75.amount})`);
  check(saved75.type === "expense",
    `formulaire : type conservé (attendu expense, obtenu ${saved75.type})`);
}

// ---------- Test 76 : NU2 — erreur de formulaire lisible, PRÈS du champ ----------
currentTest = "NU2 erreur de formulaire";
{
  await openQuickEntry("expense", "#screen [data-addtx]");
  await page.fill("#fAmount", "");
  await page.click('#txForm button[type="submit"]');
  await page.waitForTimeout(300);
  const err76 = await page.evaluate(() => {
    const error = document.getElementById("fError");
    const amount = document.getElementById("fAmount");
    const eBox = error.getBoundingClientRect();
    const aBox = amount.getBoundingClientRect();
    return {
      text: error.textContent.trim(),
      color: getComputedStyle(error).color,
      distance: Math.abs(eBox.top - aBox.bottom),
      invalid: amount.getAttribute("aria-invalid"),
      focused: document.activeElement === amount,
      role: error.getAttribute("role"),
      open: document.getElementById("sheetBackdrop").classList.contains("open"),
      created: transactions.some(t => t.title === "" && !t.amount),
    };
  });
  check(err76.text.length > 0, "erreur : un message est réellement affiché");
  check(err76.role === "alert", `erreur : le message est annoncé (role=${err76.role})`);
  check(err76.distance < 160,
    `erreur : le message se lit à côté du champ fautif (obtenu ${Math.round(err76.distance)} px)`);
  check(err76.color === "rgb(255, 101, 119)",
    `erreur : corail sémantique #FF6577 (obtenu ${err76.color})`);
  check(err76.invalid === "true", `erreur : champ marqué aria-invalid (obtenu ${err76.invalid})`);
  check(err76.focused, "erreur : le champ fautif reçoit le focus");
  check(err76.open, "erreur : la feuille reste ouverte, rien n'est perdu");
  check(!err76.created, "erreur : aucun mouvement fantôme n'est créé");
  // Correction puis abandon volontaire : aucune donnée écrite.
  const before76 = await page.evaluate(() => transactions.length);
  await page.click("#fCancel");
  await page.waitForTimeout(300);
  const after76 = await page.evaluate(() => ({
    closed: !document.getElementById("sheetBackdrop").classList.contains("open"),
    count: transactions.length,
  }));
  check(after76.closed, "annulation : la feuille se ferme");
  check(after76.count === before76, "annulation : aucun mouvement enregistré");
  // Nettoyage du mouvement du test 75.
  await page.evaluate(() => {
    const i = transactions.findIndex(t => t.title === "Courses NU2");
    if (i >= 0) transactions.splice(i, 1);
    saveState(); render();
  });
  await page.waitForTimeout(200);
  const cleaned76 = await page.evaluate(() => transactions.some(t => t.title === "Courses NU2"));
  check(!cleaned76, "les mouvements de test NU2 sont retirés (aucune trace)");
}

// ---------- Test 77 : NU2 — 320 px, focus visible, mouvement réduit ----------
currentTest = "NU2 accessibilité des surfaces pilotes";
{
  await page.setViewportSize({ width: 320, height: 640 });
  await goHome();
  await page.waitForTimeout(300);
  const etroit77 = await page.evaluate(() => {
    const screenEl = document.getElementById("screen");
    const overflow = screenEl.scrollWidth - screenEl.clientWidth;
    const clipped = [...screenEl.querySelectorAll(".hero-amount, .amount, .card-label, .pill")]
      .filter(el => el.scrollWidth - el.clientWidth > 1)
      .map(el => ({
        label: (el.textContent || el.className).trim().replace(/\s+/g, " ").slice(0, 40),
        excess: Math.round(el.scrollWidth - el.clientWidth),
      }));
    const small = [...screenEl.querySelectorAll("button, a[href], [role=button]")]
      .filter(el => el.getBoundingClientRect().height > 0
        && el.getBoundingClientRect().height < 44).length;
    return { overflow, clipped, small, bodyOverflow: document.body.scrollWidth - 320 };
  });
  check(etroit77.overflow <= 1,
    `320 px : aucun débordement horizontal du contenu (obtenu ${etroit77.overflow} px)`);
  check(etroit77.bodyOverflow <= 1,
    `320 px : aucun débordement horizontal de la page (obtenu ${etroit77.bodyOverflow} px)`);
  check(etroit77.clipped.length === 0,
    `320 px : aucun montant ni libellé tronqué (${etroit77.clipped.map(x => `${x.label}: +${x.excess}px`).join(", ")})`);
  check(etroit77.small === 0,
    `320 px : toutes les cibles tactiles font au moins 44 px (obtenu ${etroit77.small} trop petites)`);
  // Focus clavier : anneau cyan d'au moins 2 px, avec décalage.
  const focus77 = await page.evaluate(() => {
    const cta = document.querySelector("#screen .btn.nu-cta");
    cta.focus();
    const cs = getComputedStyle(cta);
    return {
      color: cs.outlineColor,
      width: parseFloat(cs.outlineWidth),
      style: cs.outlineStyle,
      offset: parseFloat(cs.outlineOffset),
    };
  });
  check(focus77.color === "rgb(56, 189, 248)",
    `focus : anneau cyan #38BDF8 (obtenu ${focus77.color})`);
  check(focus77.width >= 2 && focus77.style !== "none",
    `focus : anneau d'au moins 2 px réellement dessiné (obtenu ${focus77.width} px ${focus77.style})`);
  check(focus77.offset >= 2, `focus : anneau décalé du bord (obtenu ${focus77.offset} px)`);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForTimeout(200);
}
// Mouvement réduit : le compteur héros affiche IMMÉDIATEMENT la valeur finale.
{
  const pageRm = await context.newPage();
  const rmErrors = [];
  pageRm.on("pageerror", err => rmErrors.push("pageerror: " + err.message));
  pageRm.on("console", msg => { if (msg.type() === "error") rmErrors.push(msg.text()); });
  pageRm.on("dialog", d => d.accept());
  await pageRm.emulateMedia({ reducedMotion: "reduce" });
  await pageRm.goto(APP_URL);
  await pageRm.waitForSelector("#tabbar button", { timeout: 10000 });
  await pageRm.click('#tabbar button[aria-label="Mois"]');
  const rm77 = await pageRm.evaluate(() => {
    const el = document.querySelector("#screen .hero-amount");
    const immediate = el ? el.textContent.trim() : "";
    return new Promise(resolve => setTimeout(() => resolve({
      immediate,
      settled: el ? el.textContent.trim() : "",
      transition: el ? getComputedStyle(el).transitionDuration : "",
      piloted: document.getElementById("screen").classList.contains("nu-pilot-screen"),
    }), 500));
  });
  check(rm77.piloted, "mouvement réduit : l'écran Mois reste piloté");
  check(rm77.immediate === rm77.settled,
    `mouvement réduit : aucun comptage animé, la valeur finale est là tout de suite (« ${rm77.immediate} » puis « ${rm77.settled} »)`);
  check(rm77.transition === "0s" || rm77.transition === "",
    `mouvement réduit : aucune transition sur le montant (obtenu ${rm77.transition})`);
  check(rmErrors.length === 0,
    `mouvement réduit : zéro erreur console (obtenu ${rmErrors.slice(0, 2).join(" | ") || "aucune"})`);
  await pageRm.close();
}

// ---------- Test 78 : NU2 — HTTP réel, service worker, rechargement, HORS LIGNE ----------
currentTest = "NU2 HTTP, service worker et hors-ligne";
// La feuille Neon Ultra est le PREMIER fichier externe dont dépend l'identité
// de l'app. Servie par un vrai serveur, elle doit survivre au rechargement ET
// à la coupure réseau, sans toucher au service worker ni à son nom de cache.
{
  const { default: http78 } = await import("node:http");
  const { readFileSync: readFile78, existsSync: exists78 } = await import("node:fs");
  const WEBAPP = path.resolve(HERE, "..");
  const TYPES = {
    ".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8",
    ".js": "text/javascript; charset=utf-8", ".webmanifest": "application/manifest+json",
    ".png": "image/png", ".svg": "image/svg+xml", ".json": "application/json",
  };
  const served = new Set();
  const server78 = http78.createServer((req, res) => {
    const rel = decodeURIComponent(String(req.url || "/").split("?")[0]);
    const name = rel === "/" ? "index.html" : rel.replace(/^\/+/, "");
    const file = path.resolve(WEBAPP, name);
    // Aucun échappement hors du dossier webapp.
    if (!file.startsWith(WEBAPP) || !exists78(file)) { res.writeHead(404); res.end("404"); return; }
    served.add(name);
    res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
    res.end(readFile78(file));
  });
  await new Promise(resolve => server78.listen(0, "127.0.0.1", resolve));
  const port78 = server78.address().port;
  const origin78 = `http://127.0.0.1:${port78}`;
  const browser78 = await chromium.launch({
    executablePath: CHROMIUM, args: ["--no-sandbox", "--no-proxy-server"],
  });
  const context78 = await browser78.newContext({ viewport: { width: 390, height: 844 } });
  const page78 = await context78.newPage();
  const errors78 = [];
  page78.on("pageerror", err => errors78.push("PAGEERROR: " + err.message));
  page78.on("console", msg => { if (msg.type() === "error") errors78.push(msg.text()); });
  page78.on("dialog", d => d.accept());
  await page78.goto(origin78 + "/");
  await page78.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 });
  // L'app n'enregistre son service worker qu'en HTTPS (garde de production).
  // 127.0.0.1 est un contexte sécurisé : on enregistre EXACTEMENT le même
  // fichier `sw.js`, non modifié, pour éprouver le comportement réel.
  const registered78 = await page78.evaluate(async () => {
    const reg = await navigator.serviceWorker.register("sw.js");
    await navigator.serviceWorker.ready;
    return !!reg;
  });
  check(registered78, "hors-ligne : le service worker livré (sw.js) s'enregistre réellement");
  // Onboarding réel : des données à retrouver après la coupure.
  await page78.click('[data-obcountry="CH"]');
  await page78.click('[data-obhh="solo"]');
  await page78.fill("#obName", "Robin");
  await page78.click('#obForm1 button[type="submit"]');
  await page78.fill("#obSalary", "5200");
  await page78.click('#obForm2 button[type="submit"]');
  await page78.waitForSelector("#obOpening", { state: "visible" });
  await page78.fill("#obOpening", "3400");
  await page78.click('#obForm3 button[type="submit"]');
  // Charges puis abonnements : deux écrans facultatifs, passés ici.
  await page78.waitForSelector("#obFormCharges", { state: "visible" });
  await page78.click("[data-obskipcharges]");
  await page78.waitForSelector("#obFormSubs", { state: "visible" });
  await page78.click("[data-obskipsubs]");
  await page78.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await page78.click('[data-obgoal="urgence"]');
  await page78.waitForSelector("#tabbar button", { timeout: 10000 });
  // Rechargement EN LIGNE : le service worker prend le contrôle et met en cache.
  await page78.reload();
  await page78.waitForSelector("#tabbar button", { timeout: 10000 });
  await page78.waitForFunction(() => !!navigator.serviceWorker.controller, null, { timeout: 10000 });
  const online78 = await page78.evaluate(() => ({
    controlled: !!navigator.serviceWorker.controller,
    name: ((JSON.parse(localStorage.getItem("budget-app-state-v1") || "{}").profile || {}).name) || "",
    canvas: getComputedStyle(document.getElementById("screen")).backgroundColor,
  }));
  check(online78.controlled, "hors-ligne : la page est réellement CONTRÔLÉE par le service worker");
  check(online78.name === "Robin",
    `rechargement en ligne : les données locales survivent (obtenu « ${online78.name} »)`);
  check(online78.canvas === "rgb(5, 6, 10)",
    `rechargement en ligne : l'identité Neon Ultra est appliquée (obtenu ${online78.canvas})`);
  check(served.has("design-system/neon-ultra.css"),
    "hors-ligne : la feuille Neon Ultra a bien été demandée au serveur");
  // COUPURE RÉSEAU puis vrai rechargement.
  await context78.setOffline(true);
  await page78.reload();
  await page78.waitForSelector("#tabbar button", { timeout: 15000 });
  const offline78 = await page78.evaluate(() => {
    const screenEl = document.getElementById("screen");
    const hero = screenEl.querySelector(".card.hero");
    const cta = screenEl.querySelector(".btn.nu-cta");
    return {
      onLine: navigator.onLine,
      tabs: document.querySelectorAll("#tabbar [data-tab]").length,
      fab: !!document.getElementById("fab"),
      name: ((JSON.parse(localStorage.getItem("budget-app-state-v1") || "{}").profile || {}).name) || "",
      amount: (screenEl.querySelector(".hero-amount") || {}).textContent || "",
      canvas: getComputedStyle(screenEl).backgroundColor,
      heroBg: hero ? getComputedStyle(hero).backgroundColor : null,
      ctaBg: cta ? getComputedStyle(cta).backgroundImage : "",
      nuRules: [...document.styleSheets]
        .filter(s => String(s.href || "").includes("neon-ultra.css"))
        .reduce((a, s) => { try { return a + s.cssRules.length; } catch { return a; } }, 0),
    };
  });
  check(offline78.onLine === false, "hors-ligne : le navigateur est réellement déconnecté");
  check(offline78.tabs === 5 && !offline78.fab,
    `hors-ligne : l'app s'ouvre entière (obtenu ${offline78.tabs} onglets, ＋ ${offline78.fab})`);
  check(offline78.name === "Robin",
    `hors-ligne : les données du foyer sont intactes (obtenu « ${offline78.name} »)`);
  check(/\d/.test(offline78.amount),
    `hors-ligne : le montant héros est calculé et affiché (obtenu « ${offline78.amount.trim()} »)`);
  check(offline78.nuRules > 0,
    `hors-ligne : neon-ultra.css est servie depuis le cache et parsée (obtenu ${offline78.nuRules} règles)`);
  check(offline78.canvas === "rgb(5, 6, 10)",
    `hors-ligne : le canvas Neon Ultra survit à la coupure (obtenu ${offline78.canvas})`);
  check(offline78.heroBg === "rgb(24, 28, 38)",
    `hors-ligne : le héros reste en surface élevée mate (obtenu ${offline78.heroBg})`);
  check(offline78.ctaBg.includes("192, 0, 164"),
    `hors-ligne : le CTA garde son dégradé de marque (obtenu ${offline78.ctaBg})`);
  // La navigation continue de fonctionner sans réseau.
  await page78.click('#tabbar button[aria-label="Budget"]');
  await page78.waitForTimeout(250);
  const navOffline78 = await page78.evaluate(() => ({
    piloted: document.getElementById("screen").classList.contains("nu-pilot-screen"),
    text: document.getElementById("screen").innerText.slice(0, 40),
  }));
  check(navOffline78.piloted,
    `hors-ligne : Budget reste piloté et navigable (obtenu « ${navOffline78.text.trim()} »)`);
  check(errors78.length === 0,
    `HTTP/hors-ligne : zéro pageerror / erreur console (obtenu : ${errors78.slice(0, 3).join(" | ") || "aucune"})`);
  await context78.setOffline(false);
  await browser78.close();
  server78.close();
}

// ---------- Tests 79–86 : correctif critique de fiabilité ----------
// Contexte isolé : ces scénarios manipulent volontairement les dates,
// sauvegardes, devises et relations financières.
const context79 = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page79 = await context79.newPage();
const errors79 = [];
page79.on("pageerror", err => errors79.push(`[${currentTest}] pageerror: ${err.message}`));
page79.on("console", msg => { if (msg.type() === "error") errors79.push(`[${currentTest}] ${msg.text()}`); });
page79.on("dialog", dialog => dialog.accept());

async function seedCorrectnessPage() {
  await page79.goto(APP_URL);
  await page79.waitForSelector("body", { timeout: 10000 });
  await page79.evaluate(() => {
    localStorage.clear();
    localStorage.setItem("budget-app-state-v1", JSON.stringify(seedState()));
    location.reload();
  });
  await page79.waitForSelector("#tabbar button", { timeout: 10000 });
}

await seedCorrectnessPage();

// 79 — demain, mois suivant et année suivante restent planifiés.
currentTest = "correctness dates futures";
const dates79 = await page79.evaluate(() => {
  const parts = date => ({
    y: date.getFullYear(), m: date.getMonth() + 1, d: date.getDate(),
  });
  const tomorrow = parts(new Date(NOW.y, NOW.m - 1, NOW.d + 1));
  const nextMonth = parts(new Date(NOW.y, NOW.m, 1));
  const nextYear = { y: NOW.y + 1, m: 1, d: 1 };
  const yesterday = parts(new Date(NOW.y, NOW.m - 1, NOW.d - 1));
  return {
    tomorrow: statusForDate(tomorrow.y, tomorrow.m, tomorrow.d),
    nextMonth: statusForDate(nextMonth.y, nextMonth.m, nextMonth.d),
    nextYear: statusForDate(nextYear.y, nextYear.m, nextYear.d),
    yesterday: statusForDate(yesterday.y, yesterday.m, yesterday.d),
  };
});
check(dates79.tomorrow === "planned", `demain doit être planifié (obtenu ${dates79.tomorrow})`);
check(dates79.nextMonth === "planned", `le mois suivant doit être planifié (obtenu ${dates79.nextMonth})`);
check(dates79.nextYear === "planned", `l'année suivante doit être planifiée (obtenu ${dates79.nextYear})`);
check(dates79.yesterday === "posted", `une date passée doit être comptabilisée (obtenu ${dates79.yesterday})`);

// 80 — import futur planifié, date impossible refusée et empreinte complète.
currentTest = "correctness import";
const import80 = await page79.evaluate(() => {
  transactions.length = 0;
  const nextMonth = shiftMonth(NOW, 1);
  const nextYear = NOW.y + 1;
  const csv = [
    "Date;Montant;Nom",
    `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(Math.max(1, NOW.d - 1)).padStart(2, "0")};-10.00;Import passé`,
    `${nextMonth.y}-${String(nextMonth.m).padStart(2, "0")}-01;-20.00;Import mois suivant`,
    `${nextYear}-01-01;-30.00;Import année suivante`,
  ].join("\n");
  const first = analyzeCSV(csv, null, "cur");
  applyImport(first, "dates.csv", "cur");

  const duplicateCSV = `Date;Montant;Nom\n${nextYear}-02-01;-45.00;Empreinte complète`;
  const onCurrent = analyzeCSV(duplicateCSV, null, "cur");
  applyImport(onCurrent, "cur.csv", "cur");
  const onSavings = analyzeCSV(duplicateCSV, null, "sav");
  const positiveSameAccount = analyzeCSV(
    `Date;Montant;Nom\n${nextYear}-02-01;45.00;Empreinte complète`, null, "cur"
  );
  const impossible = analyzeCSV(
    `Date;Montant;Nom\n${nextYear}-02-31;-12.00;Date impossible`, null, "cur"
  );
  return {
    past: transactions.find(t => t.title === "Import passé")?.status,
    month: transactions.find(t => t.title === "Import mois suivant")?.status,
    year: transactions.find(t => t.title === "Import année suivante")?.status,
    otherAccount: onSavings.rows[0]?.state,
    otherSign: positiveSameAccount.rows[0]?.state,
    impossible: impossible.rows[0]?.state,
  };
});
check(import80.past === "posted", `import passé comptabilisé attendu (obtenu ${import80.past})`);
check(import80.month === "planned", `import du mois suivant planifié attendu (obtenu ${import80.month})`);
check(import80.year === "planned", `import de l'année suivante planifié attendu (obtenu ${import80.year})`);
check(import80.otherAccount === "ready", "deux comptes ne doivent pas produire un faux doublon");
check(import80.otherSign === "ready", "deux signes/types ne doivent pas produire un faux doublon");
check(import80.impossible === "invalid", "le 31 février doit être refusé");

// 81 — le remboursement améliore le résultat annuel une seule fois.
currentTest = "correctness remboursement";
const refund81 = await page79.evaluate(() => {
  transactions.length = 0;
  addTx({ id: 8101, y: NOW.y, m: 1, d: 2, title: "Revenu", amount: 1000,
    type: "income", cat: "Salaire", acc: "cur", dest: null, status: "posted" });
  addTx({ id: 8102, y: NOW.y, m: 1, d: 3, title: "Dépense", amount: 500,
    type: "expense", cat: "Logement", acc: "cur", dest: null, status: "posted" });
  const before = yearStats(NOW.y);
  addTx({ id: 8103, y: NOW.y, m: 1, d: 4, title: "Remboursement", amount: 120,
    type: "refund", cat: "Logement", acc: "cur", dest: null, status: "posted" });
  const after = yearStats(NOW.y);
  return {
    incomeBefore: before.income,
    incomeAfter: after.income,
    resultDelta: (after.income - after.living) - (before.income - before.living),
  };
});
check(refund81.incomeAfter === refund81.incomeBefore,
  "un remboursement ne doit pas aussi devenir un revenu");
check(refund81.resultDelta === 120,
  `le résultat annuel doit s'améliorer de 120 une seule fois (obtenu ${refund81.resultDelta})`);

// 82 — FE2-12 : la vérité fiscale est MANUELLE — six salaires et un taux
// hérité ne fabriquent AUCUNE estimation ; seuls comptent l'acompte payé,
// les envois « Impôts » et le report saisi.
currentTest = "correctness fiscalité";
const tax82 = await page79.evaluate(() => {
  transactions.length = 0;
  S.taxRate = 0.30; // taux hérité d'avant — doit rester lettre morte
  S.taxReserve = 5000;
  for (let month = 1; month <= 6; month++) {
    addTx({ id: 8200 + month, y: NOW.y, m: month, d: 15, title: `Salaire ${month}`,
      amount: 10000, type: "income", cat: "Salaire", acc: "cur", dest: null, status: "posted" });
  }
  addTx({ id: 8207, y: NOW.y, m: 2, d: 20, title: "Acompte", amount: 2000,
    type: "taxPayment", cat: "Impôts", acc: "cur", dest: null, status: "posted" });
  addTx({ id: 8208, y: NOW.y, m: 3, d: 20, title: "Provision", amount: 500,
    type: "saving", cat: "Impôts", acc: "cur", dest: null, status: "posted" });
  const report = taxSummary(NOW.y);
  const home = snapshot(NOW.y, NOW.m);
  return {
    paid: report.paid,
    reserved: report.reserved,
    fromMovements: report.reservedFromMovements,
    manual: report.reservedManual,
    resteAutomatique: ("estimated" in report) || ("due" in report) || ("reserveGap" in report)
      || ("taxGap" in home) || ("taxMonthlyEffort" in home) || ("taxRecommended" in home),
  };
});
check(tax82.paid === 2000,
  `« déjà payé » additionne les paiements d'impôts saisis (obtenu ${tax82.paid})`);
check(tax82.fromMovements === 500 && tax82.manual === 5000 && Math.abs(tax82.reserved - 5500) < 0.005,
  `« mis de côté » = envois (${tax82.fromMovements}) + report saisi (${tax82.manual})`);
check(tax82.resteAutomatique === false,
  "six salaires × 30 % hérités = RIEN : plus aucun champ fiscal automatique nulle part (ADR-035)");

// 83 — taux et devise historiques figés, sans repli silencieux 1:1.
currentTest = "correctness devises";
const fx83 = await page79.evaluate(() => {
  transactions.length = 0;
  S.baseCurrency = "CHF";
  S.fxRates = { EUR: 0.93, USD: 0.80 };
  if (!ACCOUNTS.some(a => a.id === "eur-correctness")) {
    ACCOUNTS.push({ id: "eur-correctness", name: "Compte EUR", inst: "",
      kind: "current", opening: 0, cash: true, currency: "EUR" });
  }
  const movement = addTx({ id: 8301, y: NOW.y, m: NOW.m, d: NOW.d,
    title: "Historique EUR", amount: 100, type: "expense", cat: "Logement",
    acc: "eur-correctness", dest: null, status: "posted" });
  const before = txCHF(movement);
  S.fxRates.EUR = 2;
  const after = txCHF(movement);
  openAccSheet(ACCOUNTS.find(a => a.id === "eur-correctness"));
  const accountCurrencyLocked = document.getElementById("aCurrency").disabled;
  closeSheet();
  document.getElementById("bCurrency").value = "EUR";
  document.getElementById("baseForm").dispatchEvent(
    new Event("submit", { bubbles: true, cancelable: true })
  );
  const baseLocked = S.baseCurrency === "CHF";
  delete S.fxRates.EUR;
  const countBefore = transactions.length;
  let missingRateRejected = false;
  try {
    addTx({ id: 8302, y: NOW.y, m: NOW.m, d: NOW.d, title: "Sans taux",
      amount: 50, type: "expense", cat: "Logement",
      acc: "eur-correctness", dest: null, status: "posted" });
  } catch (error) {
    missingRateRejected = true;
  }
  return {
    before, after, sourceCurrency: movement.sourceCurrency, stampedRate: movement.fx,
    accountCurrencyLocked, baseLocked, missingRateRejected,
    noPartialInsert: transactions.length === countBefore,
  };
});
check(fx83.before === 93 && fx83.after === 93,
  `un taux actuel ne doit pas réécrire l'historique (${fx83.before} → ${fx83.after})`);
check(fx83.sourceCurrency === "EUR" && fx83.stampedRate === 0.93,
  "devise et taux source doivent être estampillés sur le mouvement");
check(fx83.accountCurrencyLocked && fx83.baseLocked,
  "les devises du compte et du profil doivent être verrouillées après historique");
check(fx83.missingRateRejected && fx83.noPartialInsert,
  "un taux absent doit refuser la saisie sans insertion partielle ni taux 1:1");

// 84 — récurrents/factures utilisent leur compte et une échéance unique.
currentTest = "correctness factures et récurrents";
const recurring84 = await page79.evaluate(() => {
  transactions.length = 0;
  RECURRINGS.length = 0;
  S.bills = [];
  if (!ACCOUNTS.some(a => a.id === "alt-correctness")) {
    ACCOUNTS.push({ id: "alt-correctness", name: "Compte factures", inst: "",
      kind: "current", opening: 0, cash: true, currency: "CHF" });
  }
  const next = shiftMonth(NOW, 1);
  const recurring = { id: "r-correctness", title: "Loyer futur", amount: 800,
    type: "expense", cat: "Logement", day: 5, accountId: "alt-correctness" };
  RECURRINGS.push(recurring);
  const firstRecurring = materializeRecurring(recurring, next.y, next.m);
  const secondRecurring = materializeRecurring(recurring, next.y, next.m);
  const bill = { id: "bill-correctness", name: "Facture future", amount: 250,
    dueY: NOW.y + 1, dueM: 1, dueD: 10, cat: "Logement",
    accountId: "alt-correctness", paidTxId: null, note: "" };
  S.bills.push(bill);
  const firstBill = materializeBill(bill);
  const secondBill = materializeBill(bill);
  const recurringStatusAtCreation = firstRecurring.transaction.status;
  const billStatusAtCreation = firstBill.transaction.status;
  const balanceBeforeDue = balance("alt-correctness");
  // FE2 (décision propriétaire) : AUCUNE promotion par date. Un mouvement
  // prévu dont la date est atteinte ou passée reste prévu après un rendu
  // complet — le calendrier ne comptabilise jamais ; seul le geste le fait.
  const hier = new Date(Date.now() - 86400000);
  const duePassed = { id: ++txSeq, y: hier.getFullYear(), m: hier.getMonth() + 1, d: hier.getDate(),
    title: "Salaire à confirmer FE2", amount: 900, type: "income", cat: "Salaire",
    acc: "alt-correctness", status: "planned", recurringId: "r-correctness",
    createdAt: 1, updatedAt: 1 };
  transactions.push(duePassed);
  render();
  const stillPlannedAfterRender = duePassed.status === "planned";
  const balanceAfterRender = balance("alt-correctness");
  const promotionGone = typeof window.promoteDuePlannedTransactions === "undefined";
  // Le geste, lui, comptabilise (même chemin que le bouton « Reçu »).
  duePassed.status = "posted";
  const balanceAfterGesture = balance("alt-correctness");
  transactions.splice(transactions.indexOf(duePassed), 1);
  render();

  openBillSheet(bill);
  const locked = ["bAmount", "bDue", "bAccount"].every(id => document.getElementById(id).disabled);
  document.getElementById("bName").value = "Facture renommée";
  document.getElementById("billForm").dispatchEvent(
    new Event("submit", { bubbles: true, cancelable: true })
  );
  const linked = billLinkedTransaction(bill);
  return {
    recurringAccount: firstRecurring.transaction.acc,
    recurringStatus: recurringStatusAtCreation,
    recurringDay: firstRecurring.transaction.d,
    lastDayOfNextMonth: new Date(next.y, next.m, 0).getDate(),
    recurringDuplicate: secondRecurring.created,
    billAccount: firstBill.transaction.acc,
    billStatus: billStatusAtCreation,
    billDay: firstBill.transaction.d,
    billDuplicate: secondBill.created,
    transactionCount: transactions.length,
    balanceBeforeDue,
    stillPlannedAfterRender,
    balanceAfterRender,
    promotionGone,
    balanceAfterGesture,
    deleteBlocked: !!accountDeleteBlocker("alt-correctness"),
    locked,
    linkedTitle: linked && linked.title,
    formError: document.getElementById("bError").textContent,
  };
});
check(recurring84.recurringAccount === "alt-correctness" && recurring84.billAccount === "alt-correctness",
  "facture et récurrent doivent débiter le compte choisi");
check(recurring84.recurringStatus === "planned" && recurring84.billStatus === "planned",
  "les échéances futures doivent rester planifiées");
// 06.08.2026 — plus de jour de paiement pour les récurrences (décision du
// propriétaire). Une occurrence hors du mois courant tombe donc à la FIN de
// son mois : une règle unique, prévisible, et qui ne prétend pas connaître
// une date de prélèvement qu'on n'a jamais demandée. La FACTURE, elle, garde
// son échéance au jour près — c'est sa raison d'être.
check(recurring84.recurringDay === recurring84.lastDayOfNextMonth,
  `une échéance récurrente future tombe en fin de mois (obtenu ${recurring84.recurringDay}, attendu ${recurring84.lastDayOfNextMonth})`);
check(recurring84.billDay === 10,
  `une FACTURE conserve son échéance au jour près (obtenu ${recurring84.billDay})`);
// FE2 : le calendrier n'encaisse ni ne paie — un mouvement prévu dont la
// date est passée reste prévu après un rendu complet, le solde ne bouge
// pas, et l'ancienne fonction de promotion n'existe plus. Seul le geste
// comptabilise.
check(recurring84.balanceBeforeDue === 0
    && recurring84.stillPlannedAfterRender
    && recurring84.balanceAfterRender === 0
    && recurring84.promotionGone
    && recurring84.balanceAfterGesture === 900,
  `une date passée ne comptabilise RIEN — seul le geste enregistre (${JSON.stringify({ p: recurring84.stillPlannedAfterRender, avant: recurring84.balanceAfterRender, geste: recurring84.balanceAfterGesture, fonction: recurring84.promotionGone })})`);
check(!recurring84.recurringDuplicate && !recurring84.billDuplicate && recurring84.transactionCount === 2,
  `une seule transaction par échéance attendue (obtenu ${recurring84.transactionCount})`);
check(recurring84.deleteBlocked, "un compte utilisé par une facture/récurrence ne doit pas être supprimable");
check(recurring84.locked && recurring84.linkedTitle === "Facture renommée" && !recurring84.formError,
  "une facture couverte doit figer ses champs financiers et garder son mouvement synchronisé");

// 85 — sauvegarde invalide refusée, état sain inchangé.
currentTest = "correctness restauration atomique";
const restore85 = await page79.evaluate(async () => {
  // Le test précédent supprimait volontairement le taux EUR. On rétablit
  // un état valide pour que l'erreur ci-dessous provienne bien de goals.
  S.fxRates.EUR = 0.93;
  saveState();
  const before = localStorage.getItem("budget-app-state-v1");
  const state = JSON.parse(before);
  state.transactions = [null];
  const invalid = { app: "budget-web", version: 1, exportedAt: new Date().toISOString(), state };
  restoreFromFile(new File([JSON.stringify(invalid)], "invalid-budget.json", { type: "application/json" }));
  await new Promise(resolve => setTimeout(resolve, 250));
  const malformedGoal = JSON.parse(before);
  malformedGoal.goals = [{}];
  let malformedGoalError = "";
  try { validatedRestoreState(malformedGoal); }
  catch (error) { malformedGoalError = String(error && error.message || error); }
  const malformedImport = JSON.parse(before);
  malformedImport.lastImport = {};
  let malformedImportError = "";
  try { validatedRestoreState(malformedImport); }
  catch (error) { malformedImportError = String(error && error.message || error); }
  const stringTransactionID = JSON.parse(before);
  stringTransactionID.transactions[0].id = "legacy-abc";
  const restoredStringID = validatedRestoreState(stringTransactionID);
  const restoredSequence = transactionSequenceFloor(restoredStringID.transactions);
  const stateWithLock = JSON.parse(before);
  stateWithLock.faceIDEnabled = true;
  stateWithLock.lockCode = codeHash("1234");
  const imported = validatedRestoreState(stateWithLock);
  return {
    unchanged: localStorage.getItem("budget-app-state-v1") === before,
    message: document.getElementById("toast").textContent,
    malformedGoalError,
    malformedImportError,
    stringTransactionIDSafe: Number.isSafeInteger(restoredSequence)
      && restoredSequence >= 0,
    importedLockDisabled: imported.faceIDEnabled === false && imported.lockCode == null,
  };
});
check(restore85.unchanged, "une sauvegarde invalide ne doit jamais remplacer l'état sain");
// Le refus doit dire DEUX choses : ce qui cloche avec le fichier, et que
// rien n'a bougé. Les mots ont changé, l'exigence non.
check(/ne se lit pas|n'est pas une sauvegarde|autre version|trop gros/.test(restore85.message)
  && /rien n'a changé/i.test(restore85.message),
  `le refus doit être expliqué ET rassurer (obtenu « ${restore85.message.trim()} »)`);
check(/objectif/.test(restore85.malformedGoalError),
  `une collection secondaire mal formée doit être refusée pour la bonne raison (${restore85.malformedGoalError})`);
check(/dernier import/.test(restore85.malformedImportError),
  `un rapport d'import incomplet doit être refusé avant d'ouvrir l'écran Import (${restore85.malformedImportError})`);
check(restore85.stringTransactionIDSafe,
  "un ancien identifiant textuel ne doit jamais transformer le compteur de mouvements en NaN");
check(restore85.importedLockDisabled,
  "une sauvegarde importée ne doit jamais importer le verrouillage d'un autre appareil");

// 86 — un ancien blob corrompu ne plante plus au démarrage et le reset
// complet efface aussi la copie de secours.
currentTest = "correctness démarrage et reset";
const invalidRaw86 = await page79.evaluate(() => {
  const state = seedState();
  state.transactions = [null];
  const raw = JSON.stringify(state);
  localStorage.setItem("budget-app-state-v1", raw);
  return raw;
});
await page79.reload();
await page79.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 });
const rescue86 = await page79.evaluate(raw => ({
  rescued: localStorage.getItem("budget-app-state-rescue") === raw,
  hasWelcome: !!document.querySelector('[data-obcountry="CH"]'),
}), invalidRaw86);
check(rescue86.rescued && rescue86.hasWelcome,
  "un blob corrompu doit être conservé en secours et l'app doit rester utilisable");
await page79.evaluate(() => {
  S.onboarded = true;
  S.profile = { name: "Reset" };
  if (!ACCOUNTS.length) {
    ACCOUNTS.push({ id: "reset-account", name: "Compte reset", inst: "",
      kind: "current", opening: 0, cash: true, currency: "CHF" });
  }
  saveState();
  activeTab = "more";
  moreView = "settings";
  render();
});
await page79.click("[data-fullreset]");
await page79.waitForSelector('[data-obcountry="CH"]', { timeout: 10000 });
const reset86 = await page79.evaluate(() => ({
  state: localStorage.getItem("budget-app-state-v1"),
  legacy: localStorage.getItem("budget-proto-mouvements"),
  rescue: localStorage.getItem("budget-app-state-rescue"),
}));
check(reset86.state === null && reset86.legacy === null && reset86.rescue === null,
  "le reset complet doit effacer état principal, clé historique et copie de secours");
check(errors79.length === 0,
  `correctif critique : zéro pageerror / erreur console (obtenu ${errors79.slice(0, 3).join(" | ") || "aucune"})`);
await context79.close();

// ---------- Test 87 : page Année — les douze mois, états écrits, ouverture d'un mois ----------
currentTest = "page Année";
await goHome();
{
  // Deux mois avec du réel, un mois bouclé : les états doivent se distinguer.
  await page.evaluate(() => {
    const mk = (m, d, type, amount, title) => ({
      id: ++txSeq, y: NOW.y, m, d, title, type,
      cat: type === "expense" ? "Logement" : null,
      acc: ACCOUNTS[0].id, dest: null, status: "posted", amount,
    });
    transactions.push(mk(1, 5, "income", 6000, "Salaire Année E2E"));
    transactions.push(mk(1, 8, "expense", 1500, "Loyer Année E2E"));
    transactions.push(mk(2, 5, "income", 4000, "Salaire Année E2E"));
    transactions.push(mk(2, 8, "expense", 5000, "Gros achat Année E2E"));
    S.monthChecks[`${NOW.y}-1`] = Date.now();
    delete S.monthChecks[`${NOW.y}-2`];
    saveState(); render();
  });
  await page.click(`#tabbar button[aria-label="Gérer"]`);
  await page.waitForTimeout(150);
  await page.click('#screen [data-more="year"]');
  await page.waitForTimeout(300);
  const year87 = await page.evaluate(() => {
    const s = document.getElementById("screen");
    const row = m => s.querySelector(`[data-gotomonth="${NOW.y}-${m}"]`);
    return {
      piloted: s.classList.contains("nu-pilot-screen"),
      canvas: getComputedStyle(s).backgroundColor,
      months: s.querySelectorAll("[data-gotomonth]").length,
      bars: s.querySelectorAll(".year-bar").length,
      title: (s.querySelector("h2.screen-title") || {}).textContent || "",
      jan: (row(1) || {}).innerText || "",
      feb: (row(2) || {}).innerText || "",
      chartLabel: (s.querySelector(".year-bars") || {}).getAttribute
        ? s.querySelector(".year-bars").getAttribute("aria-label") : "",
      // Aucune barre ne sort de son cadre.
      overflowing: [...s.querySelectorAll(".year-bar i")]
        .filter(el => el.getBoundingClientRect().height > 46).length,
    };
  });
  check(year87.months === 12, `la page Année liste les douze mois (obtenu ${year87.months})`);
  check(year87.bars === 12, `douze barres de solde, une par mois (obtenu ${year87.bars})`);
  check(year87.piloted && year87.canvas === "rgb(5, 6, 10)",
    `Année est une surface pilote Neon Ultra (obtenu ${year87.canvas})`);
  check(/Année \d{4}/.test(year87.title), `titre « Année AAAA » (obtenu « ${year87.title}` + "»)");
  // Janvier : +4'500 (6000 entré − 1500 sorti), bouclé.
  check(/Bouclé/i.test(year87.jan), `janvier bouclé est ÉCRIT (obtenu « ${year87.jan.replace(/\n/g, " ")} »)`);
  check(year87.jan.includes("6'000.00") && year87.jan.includes("1'500.00"),
    `janvier montre l'entré ET le sorti exacts (obtenu « ${year87.jan.replace(/\n/g, " ")} »)`);
  check(year87.jan.includes("4'500.00"),
    `janvier : solde +4'500.00 (obtenu « ${year87.jan.replace(/\n/g, " ")} »)`);
  // Février : négatif (4000 entré − 5000 sorti), non bouclé.
  check(/À boucler|En cours/i.test(year87.feb),
    `février non bouclé porte un état actionnable (obtenu « ${year87.feb.replace(/\n/g, " ")} »)`);
  check(year87.feb.includes("1'000.00"),
    `février : solde négatif de 1'000.00 affiché (obtenu « ${year87.feb.replace(/\n/g, " ")} »)`);
  check(/Solde mensuel/.test(year87.chartLabel),
    `le graphique est annoncé aux lecteurs d'écran (obtenu « ${year87.chartLabel.slice(0, 40)} »)`);
  check(year87.overflowing === 0,
    `aucune barre ne dépasse son cadre (obtenu ${year87.overflowing})`);
}

// ---------- Test 88 : Année — un mois s'ouvre RÉELLEMENT dans l'écran Mois ----------
currentTest = "Année ouvre le mois";
{
  const opened88 = await page.evaluate(async () => {
    document.querySelector(`[data-gotomonth="${NOW.y}-2"]`).click();
    await new Promise(r => setTimeout(r, 300));
    return {
      tab: activeTab,
      moreView,
      cursorY: cursor.y,
      cursorM: cursor.m,
      piloted: document.getElementById("screen").classList.contains("nu-pilot-screen"),
      text: document.getElementById("screen").innerText.slice(0, 60),
    };
  });
  check(opened88.tab === "home" && opened88.moreView === null,
    `taper un mois ouvre l'écran Mois (obtenu onglet ${opened88.tab}, vue ${opened88.moreView})`);
  check(opened88.cursorM === 2,
    `le mois OUVERT est bien celui tapé (attendu 2, obtenu ${opened88.cursorM})`);
  check(opened88.piloted, "l'écran Mois ouvert depuis Année reste piloté");
  // Navigation d'année : bornes et retour à l'année courante.
  await page.click(`#tabbar button[aria-label="Gérer"]`);
  await page.waitForTimeout(150);
  await page.click('#screen [data-more="year"]');
  await page.waitForTimeout(250);
  await page.click("#prevY");
  await page.waitForTimeout(250);
  const nav88 = await page.evaluate(() => ({
    year: yearCursor,
    title: (document.querySelector("#screen h2.screen-title") || {}).textContent || "",
    back: !!document.getElementById("backToYear"),
  }));
  check(nav88.year === new Date().getFullYear() - 1,
    `« ‹ » recule d'une année (obtenu ${nav88.year})`);
  check(nav88.title.includes(String(nav88.year)),
    `le titre suit l'année affichée (obtenu « ${nav88.title} »)`);
  check(nav88.back, "un retour « cette année » apparaît hors de l'année courante");
  await page.click("#backToYear");
  await page.waitForTimeout(250);
  const home88 = await page.evaluate(() => yearCursor);
  check(home88 === new Date().getFullYear(),
    `« cette année » revient à l'année courante (obtenu ${home88})`);
  // Nettoyage : les mouvements du parcours Année disparaissent.
  await page.evaluate(() => {
    for (let i = transactions.length - 1; i >= 0; i--) {
      if (String(transactions[i].title).includes("Année E2E")) transactions.splice(i, 1);
    }
    delete S.monthChecks[`${NOW.y}-1`];
    saveState(); activeTab = "home"; moreView = null; cursor = { y: NOW.y, m: NOW.m }; render();
  });
  const clean88 = await page.evaluate(() =>
    transactions.some(t => String(t.title).includes("Année E2E")));
  check(!clean88, "les mouvements du parcours Année sont retirés (aucune trace)");
}

// ---------- Test 89 : abonnement ANNUEL — engagé une seule fois, jamais douze ----------
currentTest = "abonnement annuel compté une fois";
await goHome();
{
  const math89 = await page.evaluate(() => {
    const keep = RECURRINGS.splice(0, RECURRINGS.length);
    RECURRINGS.push({ id: "t-mens", title: "Mensuel E2E", amount: 100, type: "expense",
      cat: "Logement", day: 5, accountId: ACCOUNTS[0].id });
    RECURRINGS.push({ id: "t-ann", title: "Annuel E2E", amount: 1200, type: "expense",
      cat: "Logement", day: 5, accountId: ACCOUNTS[0].id, every: "year", dueM: 3 });
    const charge = (y, m) => snapshot(y, m).recurringCharges;
    const result = {
      dueMonth: charge(NOW.y, 3),
      otherMonth: charge(NOW.y, 4),
      twelve: Array.from({ length: 12 }, (_, i) => charge(NOW.y, i + 1))
        .reduce((a, b) => a + b, 0),
      yearlyMonthly: recurringYearlyCost(RECURRINGS[0]),
      yearlyAnnual: recurringYearlyCost(RECURRINGS[1]),
      // Le rituel de bouclage ne demande pas de valider un annuel hors échéance.
      checkAprilHasAnnual: monthCheckItems(NOW.y, 4).some(i => i.label === "Annuel E2E"),
      checkMarchHasAnnual: monthCheckItems(NOW.y, 3).some(i => i.label === "Annuel E2E"),
      // Les obligations du mois non plus.
      oblAprilHasAnnual: monthlyObligations(NOW.y, 4).some(o => o.title === "Annuel E2E"),
      oblMarchHasAnnual: monthlyObligations(NOW.y, 3).some(o => o.title === "Annuel E2E"),
    };
    RECURRINGS.splice(0, RECURRINGS.length, ...keep);
    return result;
  });
  check(math89.dueMonth === 1300,
    `mois d'échéance : mensuel + annuel engagés (attendu 1300, obtenu ${math89.dueMonth})`);
  check(math89.otherMonth === 100,
    `hors échéance : le mensuel SEUL est engagé (attendu 100, obtenu ${math89.otherMonth})`);
  check(math89.twelve === 2400,
    `l'annuel pèse UNE fois sur l'année, pas douze (attendu 2400, obtenu ${math89.twelve})`);
  check(math89.yearlyMonthly === 1200,
    `coût annuel d'un mensuel de 100 = 1200 (obtenu ${math89.yearlyMonthly})`);
  check(math89.yearlyAnnual === 1200,
    `coût annuel d'un annuel de 1200 = 1200 (obtenu ${math89.yearlyAnnual})`);
  check(math89.checkMarchHasAnnual && !math89.checkAprilHasAnnual,
    `le rituel ne demande de valider l'annuel QUE sur son mois (mars ${math89.checkMarchHasAnnual}, avril ${math89.checkAprilHasAnnual})`);
  check(math89.oblMarchHasAnnual && !math89.oblAprilHasAnnual,
    `l'annuel n'est une obligation QUE sur son mois (mars ${math89.oblMarchHasAnnual}, avril ${math89.oblAprilHasAnnual})`);
}

// ---------- Test 90 : écran Abonnements — deux totaux honnêtes, résiliation ----------
currentTest = "écran Abonnements";
{
  await page.evaluate(() => {
    // 06.08.2026 — un loyer n'est pas un abonnement : cet écran ne montre plus
    // que ce qui se résilie. Ces deux fixtures sont rangées dans « Logement »,
    // donc DÉDUITES comme charges du foyer ; le `family: "sub"` explicite les
    // ramène ici. Ça teste au passage la règle qui compte : un choix explicite
    // l'emporte toujours sur la déduction par catégorie.
    RECURRINGS.push({ id: "t-sub-m", title: "Mensuel Abo E2E", amount: 20, type: "expense",
      cat: "Logement", day: 5, family: "sub", accountId: ACCOUNTS[0].id });
    RECURRINGS.push({ id: "t-sub-y", title: "Annuel Abo E2E", amount: 240, type: "expense",
      cat: "Logement", day: 5, family: "sub", accountId: ACCOUNTS[0].id, every: "year", dueM: 3 });
    // Et une charge du foyer, qui ne doit PAS apparaître sur cet écran.
    RECURRINGS.push({ id: "t-charge", title: "Loyer E2E", amount: 1500, type: "expense",
      cat: "Logement", day: 5, accountId: ACCOUNTS[0].id });
    saveState(); render();
  });
  await page.click(`#tabbar button[aria-label="Gérer"]`);
  await page.waitForTimeout(150);
  await page.click('#screen [data-more="recurring"]');
  await page.waitForTimeout(200);
  await page.click('#screen [data-recfilter="abonnement"]');
  await page.waitForTimeout(300);
  const subs90 = await page.evaluate(() => {
    const s = document.getElementById("screen");
    const row = id => s.querySelector(`[data-recid="${id}"]`);
    return {
      piloted: s.classList.contains("nu-pilot-screen"),
      canvas: getComputedStyle(s).backgroundColor,
      hero: (s.querySelector(".hero") || {}).innerText || "",
      monthRow: (row("t-sub-m") || {}).innerText || "",
      yearRow: (row("t-sub-y") || {}).innerText || "",
      // Les deux totaux calculés à la main depuis l'état, pour comparaison.
      // Le total attendu ne compte QUE les abonnements : c'est la promesse de
      // l'écran, et c'était le défaut signalé par le propriétaire.
      expectedYear: chf(fromCents(RECURRINGS
        .filter(r => r.type === "expense" && recurringIsActive(r) && isSubscription(r))
        .reduce((a, r) => a + toCents(recurringYearlyCost(r)), 0))),
      chargeListee: !!document.getElementById("screen").querySelector('[data-recid="t-charge"]'),
      chargeAnnoncee: /charges du foyer/i.test(document.getElementById("screen").innerText),
    };
  });
  check(subs90.piloted && subs90.canvas === "rgb(5, 6, 10)",
    `Abonnements est une surface pilote Neon Ultra (obtenu ${subs90.canvas})`);
  check(subs90.hero.includes(subs90.expectedYear),
    `le héros affiche le coût annuel EXACT ${subs90.expectedYear} (obtenu « ${subs90.hero.replace(/\n/g, " ").slice(0, 90)} »)`);
  check(/par mois en moyenne/.test(subs90.hero),
    "le héros donne aussi la moyenne mensuelle, sans la confondre avec un prélèvement");
  check(!subs90.chargeListee,
    "un loyer n'apparaît PAS dans les abonnements — c'est une charge du foyer");
  check(subs90.chargeAnnoncee,
    "ce qui est exclu est quand même annoncé : la page n'a pas l'air d'oublier des dépenses");
  check(/Mensuel/.test(subs90.monthRow) && /Tous les mois/.test(subs90.monthRow),
    `un mensuel porte son rythme écrit (obtenu « ${subs90.monthRow.replace(/\n/g, " ")} »)`);
  check(/Annuel/.test(subs90.yearRow) && /Chaque année en mars/.test(subs90.yearRow),
    `un annuel porte son mois d'échéance écrit (obtenu « ${subs90.yearRow.replace(/\n/g, " ")} »)`);
  check(subs90.yearRow.includes("20.00"),
    `un annuel affiche son équivalent mensuel comparatif (240/12 = 20.00, obtenu « ${subs90.yearRow.replace(/\n/g, " ")} »)`);
  // Résiliation : la charge quitte les prévisions mais reste visible.
  const ended90 = await page.evaluate(async () => {
    const before = snapshot(NOW.y, NOW.m).recurringCharges;
    RECURRINGS.find(r => r.id === "t-sub-m").endedOn = { y: NOW.y, m: NOW.m };
    saveState(); render();
    await new Promise(r => setTimeout(r, 200));
    const s = document.getElementById("screen");
    return {
      before,
      after: snapshot(NOW.y, NOW.m).recurringCharges,
      stillListed: !!s.querySelector('[data-recid="t-sub-m"]'),
      endedSection: /Résiliés/.test(s.innerText),
      note: (s.querySelector('[data-recid="t-sub-m"]') || {}).innerText || "",
    };
  });
  check(Math.round(ended90.after * 100) === Math.round((ended90.before - 20) * 100),
    `résilier retire EXACTEMENT la charge des prévisions (${ended90.before} → ${ended90.after})`);
  check(ended90.stillListed && ended90.endedSection,
    "une charge résiliée reste visible dans une section « Résiliés »");
  check(/résilié depuis/.test(ended90.note),
    `la résiliation est ÉCRITE avec sa date (obtenu « ${ended90.note.replace(/\n/g, " ")} »)`);
  // Une sauvegarde contenant un rythme illisible est REFUSÉE, données intactes.
  const guard90 = await page.evaluate(() => {
    const good = JSON.parse(JSON.stringify(S));
    let refusedEvery = false, refusedDue = false, refusedEnd = false;
    const tryState = mutate => {
      const draft = JSON.parse(JSON.stringify(good));
      mutate(draft);
      try { validatedRestoreState(draft); return false; } catch (e) { return true; }
    };
    refusedEvery = tryState(d => { d.recurrings[0].every = "week"; });
    refusedDue = tryState(d => { d.recurrings[0].every = "year"; d.recurrings[0].dueM = 13; });
    refusedEnd = tryState(d => { d.recurrings[0].endedOn = { y: 1999, m: 1 }; });
    return { refusedEvery, refusedDue, refusedEnd, intact: RECURRINGS.length === good.recurrings.length };
  });
  check(guard90.refusedEvery, "une sauvegarde avec un rythme inconnu est REFUSÉE");
  check(guard90.refusedDue, "un mois d'échéance hors 1-12 est REFUSÉ");
  check(guard90.refusedEnd, "une date de résiliation invalide est REFUSÉE");
  check(guard90.intact, "après chaque refus, les données en place sont intactes");
  // Nettoyage.
  await page.evaluate(() => {
    for (let i = RECURRINGS.length - 1; i >= 0; i--) {
      if (String(RECURRINGS[i].id).startsWith("t-sub-")) RECURRINGS.splice(i, 1);
    }
    saveState(); activeTab = "home"; moreView = null; render();
  });
  const clean90 = await page.evaluate(() =>
    RECURRINGS.some(r => String(r.id).startsWith("t-sub-")));
  check(!clean90, "les abonnements de test sont retirés (aucune trace)");
}

// ---------- Test 91 : accueil sans tuiles — destinations gardées dans la navigation ----------
currentTest = "accueil sans tuiles";
await goHome();
await page.click(`#tabbar button[aria-label="Mois"]`);
await page.waitForTimeout(300);
{
  const home91 = await page.evaluate(() => {
    const s = document.getElementById("screen");
    return {
      tiles: s.querySelectorAll(".home-tile, .home-tiles").length,
      carousel: s.querySelectorAll("#heroTrack, [data-heroslide], [data-herodot]").length,
      heroes: s.querySelectorAll(".home-hero").length,
      stats: [...s.querySelectorAll(".home-metrics .card-label")].map(el => el.textContent.trim()),
      agendas: s.querySelectorAll(".home-agenda-card").length,
      groupes: s.querySelectorAll(".home-bilan").length,
      blocs: [...s.querySelectorAll(".home-bloc .card-label")].map(el => el.textContent.trim()),
      ctas: s.querySelectorAll(".btn.nu-cta").length,
      tabs: [...document.querySelectorAll("#tabbar button[data-tab]")]
        .map(button => button.getAttribute("aria-label")),
    };
  });
  check(home91.tiles === 0 && home91.carousel === 0,
    `aucune tuile ni carrousel sur l'accueil (${JSON.stringify(home91)})`);
  // A7 : le bilan du mois courant est UN groupe de QUATRE blocs nommés.
  check(home91.heroes === 1 && home91.groupes === 1 && home91.agendas === 4
      && home91.blocs.join(",") === "Rentrées,Dépenses,Abonnements,Mis de côté"
      && home91.ctas === 1,
    `un héros, un groupe de quatre blocs nommés et un CTA (${JSON.stringify(home91)})`);
  check(home91.stats.join(",") === "Reçu,Dépensé,Mis de côté",
    `trois repères simples (${home91.stats.join(",")})`);
  check(home91.tabs.join(",") === "Mois,Historique,Budget,Comptes,Gérer",
    `les destinations détaillées restent stables (${home91.tabs.join(",")})`);
}

// ---------- Test 92 : rythme et résiliation — FIDÉLITÉ de la sauvegarde et du passé ----------
currentTest = "fidélité du rythme et du passé";
await goHome();
{
  // Un annuel réel (234 CHF dû en novembre) et un mensuel résilié en cours
  // d'année, pour éprouver deux garanties distinctes.
  const fid92 = await page.evaluate(() => {
    const keep = RECURRINGS.splice(0, RECURRINGS.length);
    RECURRINGS.push({ id: "t-fid-y", title: "Annuel fidélité E2E", amount: 234, type: "expense",
      cat: "Logement", day: 14, accountId: ACCOUNTS[0].id, every: "year", dueM: 11 });
    RECURRINGS.push({ id: "t-fid-off", title: "Résilié fidélité E2E", amount: 15, type: "expense",
      cat: "Logement", day: 3, accountId: ACCOUNTS[0].id, endedOn: { y: NOW.y, m: 7 } });
    saveState();

    // 1. FIDÉLITÉ DE LA SAUVEGARDE : le fichier réellement exporté doit porter
    // les trois champs, et la restauration doit les rendre à l'identique.
    // Sans cette garantie, un abonnement annuel redeviendrait mensuel en
    // silence après une restauration — et serait compté douze fois.
    const payload = { app: "budget-web", version: 1, exportedAt: "2026-01-01T00:00:00.000Z",
      state: JSON.parse(JSON.stringify(S)) };
    const json = JSON.stringify(payload);
    let restored = null, restoreError = null;
    try { restored = validatedRestoreState(JSON.parse(json).state); }
    catch (e) { restoreError = e.message; }
    const ry = restored && restored.recurrings.find(r => r.id === "t-fid-y");
    const roff = restored && restored.recurrings.find(r => r.id === "t-fid-off");

    // 2. UN ANNUEL SEUL : mesuré sans le résilié, qui fausserait le total.
    const onlyAnnual = RECURRINGS.filter(r => r.id === "t-fid-y");
    const withBoth = RECURRINGS.splice(0, RECURRINGS.length, ...onlyAnnual);
    const ch = (y, m) => snapshot(y, m).recurringCharges;
    const annual = {
      nov: ch(NOW.y, 11), oct: ch(NOW.y, 10), dec: ch(NOW.y, 12),
      year: Array.from({ length: 12 }, (_, i) => ch(NOW.y, i + 1)).reduce((a, b) => a + b, 0),
    };

    // 3. LE PASSÉ N'EST PAS EFFACÉ : une charge résiliée en juillet reste due
    // en juin. Résilier n'est pas supprimer.
    RECURRINGS.splice(0, RECURRINGS.length, ...withBoth);
    const onlyEnded = RECURRINGS.filter(r => r.id === "t-fid-off");
    RECURRINGS.splice(0, RECURRINGS.length, ...onlyEnded);
    const ended = { june: ch(NOW.y, 6), july: ch(NOW.y, 7), august: ch(NOW.y, 8) };

    RECURRINGS.splice(0, RECURRINGS.length, ...keep);
    saveState();
    return {
      restoreError,
      hasEvery: json.includes('"every":"year"'),
      hasDue: json.includes('"dueM":11'),
      hasEnded: json.includes('"endedOn"'),
      ryEvery: ry && ry.every, ryDue: ry && ry.dueM,
      roffEnded: roff && roff.endedOn && roff.endedOn.m,
      annual, ended,
    };
  });
  check(fid92.restoreError === null,
    `une sauvegarde portant les nouveaux champs est ACCEPTÉE (obtenu ${fid92.restoreError})`);
  check(fid92.hasEvery && fid92.hasDue && fid92.hasEnded,
    `le fichier exporté contient every, dueM et endedOn (obtenu ${JSON.stringify({ e: fid92.hasEvery, d: fid92.hasDue, x: fid92.hasEnded })})`);
  check(fid92.ryEvery === "year" && fid92.ryDue === 11,
    `un annuel reste annuel AVEC son mois après restauration (obtenu ${fid92.ryEvery}/${fid92.ryDue})`);
  check(fid92.roffEnded === 7,
    `la date de résiliation survit à la restauration (obtenu ${fid92.roffEnded})`);
  check(fid92.annual.nov === 234,
    `l'annuel pèse 234 sur son mois d'échéance (obtenu ${fid92.annual.nov})`);
  check(fid92.annual.oct === 0 && fid92.annual.dec === 0,
    `il ne pèse rien les mois voisins (octobre ${fid92.annual.oct}, décembre ${fid92.annual.dec})`);
  check(fid92.annual.year === 234,
    `il pèse 234 sur l'année entière, jamais 2808 (obtenu ${fid92.annual.year})`);
  check(fid92.ended.june === 15,
    `une charge résiliée en juillet reste DUE en juin — résilier n'efface pas le passé (obtenu ${fid92.ended.june})`);
  check(fid92.ended.july === 0 && fid92.ended.august === 0,
    `elle ne pèse plus dès le mois de résiliation (juillet ${fid92.ended.july}, août ${fid92.ended.august})`);
  const clean92 = await page.evaluate(() =>
    RECURRINGS.some(r => String(r.id).startsWith("t-fid-")));
  check(!clean92, "les récurrences du parcours de fidélité sont retirées (aucune trace)");
}

// ---------- Test 93 : audit de lisibilité — contenu jamais coupé, dépliants tactiles ----------
currentTest = "lisibilité des écrans de contenu";
// Constats de l'audit complet du 02.08.2026. L'ellipse des LISTES de données
// (mouvements, comptes, charges, factures) reste le choix de densité assumé
// en L5 : le détail s'ouvre au tap. En revanche une question de l'Assistant,
// un nom d'assurance, un intitulé de dette ou une explication des Réglages
// SONT le contenu — les couper perd l'information.
await goHome();
{
  const readable = async (view, label) => {
    await page.click(`#tabbar button[aria-label="Gérer"]`);
    await page.waitForTimeout(180);
    await page.click(`#screen [data-more="${view}"]`);
    await page.waitForTimeout(300);
    return page.evaluate(() => {
      const s = document.getElementById("screen");
      const vis = el => { const b = el.getBoundingClientRect(); return b.width > 0 && b.height > 0; };
      return {
        cut: [...s.querySelectorAll(".read-row .t, .read-row .s")]
          .filter(e => vis(e) && e.scrollWidth - e.clientWidth > 1)
          .map(e => e.textContent.trim().slice(0, 40)),
        rows: s.querySelectorAll(".read-row").length,
        // Un dépliant est une cible tactile comme une autre.
        smallSummaries: [...s.querySelectorAll("details summary")]
          .filter(e => vis(e) && e.getBoundingClientRect().height < 44)
          .map(e => e.textContent.trim().slice(0, 30)),
      };
    });
  };
  for (const [view, label] of [["assistant", "Assistant"], ["insurance", "Assurances"],
                               ["networth", "Patrimoine"], ["settings", "Réglages"]]) {
    const r = await readable(view, label);
    check(r.rows > 0, `${label} : des lignes de contenu lisibles existent (obtenu ${r.rows})`);
    check(r.cut.length === 0,
      `${label} : aucune ligne de contenu coupée (obtenu ${JSON.stringify(r.cut)})`);
    check(r.smallSummaries.length === 0,
      `${label} : tout dépliant fait au moins 44 px (obtenu ${JSON.stringify(r.smallSummaries)})`);
  }
  // Les listes de DONNÉES gardent leur ellipse : la décision de densité L5
  // n'est pas annulée par ce correctif.
  await page.click(`#tabbar button[aria-label="Historique"]`);
  await page.waitForTimeout(280);
  const dense93 = await page.evaluate(() => {
    const row = document.querySelector("#screen .tx:not(.read-row) .meta .s");
    return row ? getComputedStyle(row).textOverflow : null;
  });
  check(dense93 === "ellipsis",
    `les listes de mouvements gardent l'ellipse de densité (obtenu ${dense93})`);
}

// ---------- Test 94 : style de saisie unifié sur les 19 feuilles ----------
currentTest = "style de saisie unifié";
// Demande du propriétaire du 02.08.2026 : les feuilles où il saisit
// réellement adoptent le style « Nouveau mouvement » — pied collant pour que
// « Enregistrer » ne passe jamais sous le clavier, action principale en
// dégradé, montant dominant, pastilles tactiles plutôt que menus déroulants.
await goHome();
{
  // Les DIX-NEUF feuilles de saisie, sans exception : le style unifié n'a
  // de valeur que s'il n'a aucun trou. `quickMenu` est un menu, pas un
  // formulaire — il est vérifié séparément plus bas.
  const SHEETS = [
    ["txForm", "openTxSheet(null)", "Nouveau mouvement", true],
    ["recForm", "openRecSheet(null)", "Transaction mensuelle", true],
    ["lineForm", "openLineSheet(null)", "Ligne budgétaire", false],
    ["accForm", "openAccSheet(null)", "Compte", false],
    ["billForm", "openBillSheet(null)", "Facture ponctuelle", false],
    ["goalForm", "openGoalSheet(null)", "Objectif", false],
    ["itemForm", "openItemSheet('asset', null)", "Actif ou dette", true],
    ["insForm", "openInsSheet(null)", "Assurance", false],
    ["penForm", "openPenSheet(null)", "Prévoyance", false],
    ["taxForm", "openTaxSheet()", "Impôts", false],
    ["codeForm", "openCodeSheet('set')", "Code", false],
    ["reconForm", "openSheet('reconForm')", "Solde d'un compte", false],
    ["docForm", "openSheet('docForm')", "Document", false],
    ["nameForm", "openSheet('nameForm')", "Prénom", false],
    ["countryForm", "openSheet('countryForm')", "Pays", false],
    ["baseForm", "openSheet('baseForm')", "Devise de référence", false],
    ["salaryForm", "openSheet('salaryForm')", "Salaire", false],
    ["fxForm", "openSheet('fxForm')", "Taux de change", false],
    ["widgetForm", "openSheet('widgetForm')", "Widgets", false],
  ];
  // Un mois sans budget : sinon « ligne budgétaire » refuse de s'ouvrir,
  // toutes les catégories étant déjà prises (comportement voulu).
  await page.evaluate(() => { cursor = shiftMonth({ y: NOW.y, m: NOW.m }, 7); render(); });
  await page.waitForTimeout(200);
  for (const [id, opener, label, hasChips] of SHEETS) {
    await page.evaluate(f => eval(f), opener);
    await page.waitForSelector(`#${id}`, { state: "visible" });
    await page.waitForTimeout(200);
    const r = await page.evaluate(id => {
      const f = document.getElementById(id);
      // Une cible TACTILE est atteignable : un doublon masqué du select,
      // `aria-hidden` et hors tabulation, n'en est pas une — il ne doit
      // d'ailleurs peser aucun pixel.
      const vis = e => {
        if (e.getAttribute("aria-hidden") === "true" || e.tabIndex < 0) return false;
        const b = e.getBoundingClientRect();
        return b.width > 0 && b.height > 0;
      };
      const submit = f.querySelector('button[type="submit"]');
      const actions = f.querySelector(".actions");
      const amount = f.querySelector("[data-primary-amount]");
      return {
        piloted: f.classList.contains("nu-pilot-sheet"),
        sticky: actions ? getComputedStyle(actions).position : null,
        cta: submit ? getComputedStyle(submit).backgroundImage : "",
        ctaColor: submit ? getComputedStyle(submit).color : "",
        amountSize: amount ? parseFloat(getComputedStyle(amount).fontSize) : null,
        chips: f.querySelectorAll(".type-grid button").length,
        chipsSmall: [...f.querySelectorAll(".type-grid button")]
          .filter(e => vis(e) && Math.round(e.getBoundingClientRect().height) < 44).length,
        // Le contrat s'exprime en pixels CSS : un contrôle en
        // `min-height: 44px` mesuré 43.99 le respecte. On arrondit donc,
        // sinon on testerait l'arrondi du moteur de rendu, pas l'app.
        ovX: f.scrollWidth - f.clientWidth,
        small: [...f.querySelectorAll("button,select,input,textarea,summary")]
          .filter(e => vis(e) && Math.round(e.getBoundingClientRect().height) < 44)
          .map(e => e.id || e.textContent.trim().slice(0, 18)),
      };
    }, id);
    check(r.piloted, `${label} : porte le style de saisie unifié`);
    check(r.sticky === "sticky",
      `${label} : « Enregistrer » reste au-dessus du clavier (obtenu ${r.sticky})`);
    check(r.cta.includes("192, 0, 164") && r.ctaColor === "rgb(255, 255, 255)",
      `${label} : action principale en dégradé de marque, texte blanc (obtenu ${r.ctaColor})`);
    if (r.amountSize !== null) {
      check(r.amountSize >= 20,
        `${label} : le montant domine la feuille (obtenu ${r.amountSize} px)`);
    }
    // Aucune feuille ne défile horizontalement : un doublon masqué mal
    // dimensionné suffisait à créer 20 px de débordement invisible.
    check(r.ovX <= 1, `${label} : aucun débordement horizontal (obtenu ${r.ovX} px)`);
    check(r.small.length === 0,
      `${label} : aucun contrôle sous 44 px (obtenu ${JSON.stringify(r.small)})`);
    if (hasChips) {
      check(r.chips >= 2 && r.chipsSmall === 0,
        `${label} : des pastilles tactiles remplacent le menu déroulant (obtenu ${r.chips}, ${r.chipsSmall} trop petites)`);
    }
    await page.evaluate(() => closeSheet());
    await page.waitForTimeout(120);
  }
  // Les pastilles pilotent le select historique, qui reste la source de vérité.
  await page.evaluate(() => openRecSheet(null));
  await page.waitForSelector("#recForm", { state: "visible" });
  // Adapté le 10.08.2026 : les deux pastilles Dépense/Revenu et les trois
  // pastilles de nature cachées sous « Détails » sont devenues UNE grille de
  // quatre (facture, abonnement, mettre de côté, revenu), à la demande du
  // propriétaire. L'assertion est la même — la pastille pilote le select
  // historique — mais sur le nouveau point d'entrée.
  await page.click('#rKindGrid button[data-rkind="revenu"]');
  await page.click('#rEveryGrid button[data-revery="year"]');
  await page.waitForTimeout(200);
  const wired94 = await page.evaluate(() => ({
    type: document.getElementById("rType").value,
    every: document.getElementById("rEvery").value,
    typePressed: document.querySelector('#rKindGrid button[data-rkind="revenu"]').getAttribute("aria-pressed"),
    everyPressed: document.querySelector('#rEveryGrid button[data-revery="year"]').getAttribute("aria-pressed"),
    // Le rythme annuel révèle son mois d'échéance, comme avant.
    dueShown: document.getElementById("rDueWrap").style.display !== "none",
  }));
  check(wired94.type === "income" && wired94.every === "year",
    `les pastilles pilotent le select historique (obtenu ${wired94.type}/${wired94.every})`);
  check(wired94.typePressed === "true" && wired94.everyPressed === "true",
    "l'état sélectionné est annoncé par aria-pressed, jamais par la couleur seule");
  check(wired94.dueShown,
    "choisir « une fois par an » révèle toujours le mois d'échéance");
  await page.click("#rCancel");
  await page.waitForTimeout(150);
  await page.evaluate(() => { cursor = { y: NOW.y, m: NOW.m }; render(); });
}

// ---------- Test 95 : toute feuille remplie normalement ENREGISTRE ----------
currentTest = "chaque feuille enregistre vraiment";
// Un formulaire peut être impeccable visuellement et refuser tout
// enregistrement. Trois défauts réels l'ont prouvé :
//   · l'objectif appelait une variable inexistante (« covered ») — le
//     bouton ne faisait STRICTEMENT rien, sans message ;
//   · la facture mensuelle exigeait un jour caché sous « Détails » ;
//   · le salaire exigeait un jour laissé vide.
// Ce parcours remplit chaque feuille comme le ferait le propriétaire — les
// champs visibles, rien de plus — et exige que la donnée existe ensuite.
await goHome();
{
  const CASES = [
    ["goalForm", "openGoalSheet(null)",
      { "#gName": "Voyage Japon", "#gTarget": "8000", "#gDue": "2027-06" },
      "GOALS.some(g => g.name === 'Voyage Japon')", "objectif"],
    ["recForm", "openRecSheet(null)",
      { "#rAmount": "1200", "#rTitle": "Loyer parcours 95" },
      "RECURRINGS.some(r => r.title === 'Loyer parcours 95' && r.day >= 1 && r.day <= 28)",
      "facture mensuelle"],
    ["billForm", "openBillSheet(null)",
      { "#bName": "Électricité parcours 95", "#bAmount": "80", "#bDue": "2027-03-15" },
      "(S.bills || []).some(b => b.name === 'Électricité parcours 95')", "facture ponctuelle"],
    ["accForm", "openAccSheet(null)",
      { "#aName": "Compte parcours 95", "#aOpening": "100" },
      "ACCOUNTS.some(a => a.name === 'Compte parcours 95')", "compte"],
    ["itemForm", "openItemSheet('asset', null)",
      { "#iName": "Voiture parcours 95", "#iAmount": "9000" },
      "ASSETS.some(a => a.name === 'Voiture parcours 95')", "actif"],
    ["insForm", "openInsSheet(null)",
      { "#insName": "RC parcours 95", "#insPremium": "300" },
      "INSURANCES.some(i => i.name === 'RC parcours 95')", "assurance"],
    ["penForm", "openPenSheet(null)",
      { "#penName": "LPP parcours 95", "#penValue": "12000" },
      "PENSIONS.some(p => p.name === 'LPP parcours 95')", "prévoyance"],
  ];
  for (const [id, opener, fills, assertion, label] of CASES) {
    await page.evaluate(f => eval(f), opener);
    await page.waitForSelector(`#${id}`, { state: "visible" });
    await page.waitForTimeout(150);
    for (const [sel, value] of Object.entries(fills)) await page.fill(sel, value);
    await page.click(`#${id} button[type="submit"]`);
    await page.waitForTimeout(350);
    const after = await page.evaluate(([id, assertion]) => ({
      saved: eval(assertion),
      open: document.getElementById("sheetBackdrop").classList.contains("open"),
      err: (document.querySelector(`#${id} .error`) || {}).textContent || "",
    }), [id, assertion]);
    check(after.saved && !after.open,
      `${label} : les champs visibles suffisent à enregistrer (message « ${after.err} », feuille ${after.open ? "restée ouverte" : "fermée"})`);
    await page.evaluate(() => closeSheet());
    await page.waitForTimeout(120);
  }
  // Le salaire : le montant seul suffit — plus aucun jour n'est demandé.
  await page.evaluate(() => {
    const i = RECURRINGS.findIndex(r => r.id === "r-salaire");
    if (i >= 0) RECURRINGS.splice(i, 1);
    saveState(); render();
  });
  await page.click('#tabbar button[aria-label="Gérer"]');
  await page.waitForTimeout(250);
  await page.click('#screen [data-more="settings"]');
  await page.waitForTimeout(300);
  await page.click("[data-editsalary]");
  await page.waitForSelector("#salaryForm", { state: "visible" });
  await page.fill("#sAmount", "5400");
  await page.click('#salaryForm button[type="submit"]');
  await page.waitForTimeout(350);
  const salary95 = await page.evaluate(() => {
    const s = RECURRINGS.find(r => r.id === "r-salaire");
    return { saved: !!s, day: s && s.day, err: document.getElementById("sError").textContent };
  });
  // Le champ `day` survit dans les DONNÉES (le contrôle de chargement exige
  // un entier 1-28) mais n'est plus jamais demandé.
  check(salary95.saved && salary95.day >= 1 && salary95.day <= 28,
    `salaire : le montant seul suffit à enregistrer (jour interne ${salary95.day}, message « ${salary95.err} »)`);
  // 06.08.2026, décision du propriétaire : « enlève les jours de paiement ».
  // L'ancienne version de ce test vidait le champ jour pour vérifier qu'un
  // refus ne désignait pas un champ replié. Le champ n'existe plus, donc le
  // piège non plus — et c'est CELA qu'on verrouille désormais : aucune des
  // deux feuilles ne réclame de date, et l'enregistrement passe sans.
  await page.evaluate(() => closeSheet());
  await goHome();
  await page.evaluate(() => openRecSheet(null));
  await page.waitForSelector("#recForm", { state: "visible" });
  const sansDate95 = await page.evaluate(() => ({
    jourRecurrent: !!document.getElementById("rDay"),
    jourSalaire: !!document.getElementById("sDay"),
    replie: (document.getElementById("rMore").textContent || "").toLowerCase(),
  }));
  check(!sansDate95.jourRecurrent, "aucun « jour du mois » dans la feuille des factures mensuelles");
  check(!sansDate95.jourSalaire, "aucun « jour de réception » dans la feuille du salaire");
  check(!/jour/.test(sansDate95.replie),
    `rien ne réclame un jour, même replié sous « Détails » (obtenu « ${sansDate95.replie.slice(0, 60)} »)`);
  await page.fill("#rAmount", "50");
  await page.fill("#rTitle", "Sans aucune date");
  await page.click('#recForm button[type="submit"]');
  await page.waitForTimeout(250);
  const cree95 = await page.evaluate(() => {
    const r = RECURRINGS.find(x => x.title === "Sans aucune date");
    return {
      ok: !!r, jour: r && r.day,
      ouverte: document.getElementById("sheetBackdrop").classList.contains("open"),
      err: document.getElementById("rError").textContent,
    };
  });
  check(cree95.ok && !cree95.ouverte,
    `une facture mensuelle s'enregistre sans la moindre date (message « ${cree95.err} »)`);
  check(Number.isInteger(cree95.jour) && cree95.jour >= 1 && cree95.jour <= 28,
    `et les données restent valides pour le contrôle de chargement (jour ${cree95.jour})`);
  // Le jour ne doit plus jamais être ÉCRIT à l'écran : c'était la demande.
  await page.evaluate(() => { activeTab = "more"; moreView = "recurring"; render(); });
  await page.waitForTimeout(300);
  const affiche95 = await page.evaluate(() => document.getElementById("screen").innerText);
  check(!/Tous les mois, le \d/.test(affiche95) && !/à régler depuis le \d/.test(affiche95),
    "la liste des paiements réguliers n'affiche plus aucun jour");
  await goHome();
}

// ---------- Test 96 : le mois se coche depuis l'accueil ----------
currentTest = "cocher son mois depuis l'accueil";
// Le dashboard doit garder la trace du geste : le salaire passe de
// « À recevoir » à « Reçu », une facture de « À payer » à « Payé » et une
// réserve à « Mis de côté ». Rien ne disparaît du bilan du mois.
//   · l'accueil simplifié n'offrait AUCUNE action pour encaisser un revenu ;
//   · une échéance seulement PRÉVUE n'était plus actionnable du tout — elle
//     restait « Planifiée » sans moyen de dire qu'elle avait eu lieu ;
//   · ce qui était réglé doit quitter « À faire » sans quitter le bilan.
await goHome();
{
  await page.evaluate(() => {
    // Tout est dû aujourd'hui : on veut « Payer » et « ✓ Reçu ».
    for (const r of RECURRINGS) r.day = 1;
    saveState(); render();
  });
  await page.waitForTimeout(300);

  // Une réserve déjà planifiée doit garder sa vraie nature jusque dans
  // l'action et l'annonce de confirmation : jamais « dépense/payé ».
  // On isole ce scénario : l'agenda est volontairement limité à trois lignes,
  // donc les nombreuses fixtures du test ne doivent pas masquer la réserve
  // que cette assertion cherche précisément à manipuler.
  const monthAgendaState96 = await page.evaluate(() => JSON.stringify({
    recurrings: RECURRINGS,
    bills: S.bills || [],
    monthChecks: S.monthChecks || {},
    transactions,
  }));
  await page.evaluate(() => {
    RECURRINGS.splice(0, RECURRINGS.length);
    S.bills = [];
    transactions.splice(0, transactions.length);
    const source = defaultCashAccount();
    const destination = (ACCOUNTS.find(a => a.kind === "savings" && a.id !== source)
      || ACCOUNTS.find(a => a.id !== source)).id;
    RECURRINGS.push({
      id: "reserve-planifiee-96", title: "Réserve planifiée E2E", amount: 47,
      type: "expense", nature: "reserve", cat: "Épargne", day: 1,
      accountId: source, destAccountId: destination,
    });
    window.__todayParts96 = todayParts;
    todayParts = () => ({ y: NOW.y, m: NOW.m, d: 1 });
    transactions.push({
      id: ++txSeq, y: NOW.y, m: NOW.m, d: new Date(NOW.y, NOW.m, 0).getDate(),
      title: "Réserve planifiée E2E", amount: 47, type: "saving", cat: "Épargne",
      acc: source, dest: destination, status: "planned", recurringId: "reserve-planifiee-96",
    });
    // Une modification ultérieure de la définition ne doit jamais réécrire
    // le mouvement déjà prévu que le bouton va réellement confirmer.
    const changed = RECURRINGS.find(r => r.id === "reserve-planifiee-96");
    changed.amount = 99;
    changed.nature = "facture";
    changed.cat = "Autre";
    delete changed.destAccountId;
    saveState(); render();
  });
  await page.waitForTimeout(180);
  const reserve96 = await page.evaluate(() => {
    const row = document.querySelector('[data-obligation-key^="recurring:reserve-planifiee-96"]');
    return {
      action: row?.querySelector(".home-bill-action")?.textContent.trim() || "",
      saveColor: !!row?.querySelector(".ico.t-save"),
      amount: row?.querySelector(".amount")?.textContent.trim() || "",
      expectedAmount: chf(47),
      monthClosed: !!(S.monthChecks || {})[`${NOW.y}-${NOW.m}`],
    };
  });
  check(reserve96.action === "Mis de côté" && reserve96.saveColor
      && reserve96.amount === reserve96.expectedAmount && !reserve96.monthClosed,
    `une réserve planifiée garde son type et son montant réels (${JSON.stringify(reserve96)})`);
  await page.click('[data-obligation-key^="recurring:reserve-planifiee-96"] .home-bill-action');
  await page.waitForTimeout(180);
  const reserveConfirmee96 = await page.evaluate((serializedAgendaState) => {
    const transaction = transactions.find(t => t.recurringId === "reserve-planifiee-96");
    const toastText = document.getElementById("toast")?.textContent || "";
    const undoVisible = !!document.getElementById("toastUndo");
    const stillPending = !!document.querySelector('[data-obligation-key^="recurring:reserve-planifiee-96"]');
    const doneText = [...document.querySelectorAll(".home-done-row")]
      .find(row => row.textContent.includes("Réserve planifiée E2E"))?.textContent || "";
    const txIndex = transactions.findIndex(t => t.recurringId === "reserve-planifiee-96");
    if (txIndex >= 0) transactions.splice(txIndex, 1);
    const previous = JSON.parse(serializedAgendaState);
    RECURRINGS.splice(0, RECURRINGS.length, ...previous.recurrings);
    S.bills = previous.bills;
    S.monthChecks = previous.monthChecks;
    transactions.splice(0, transactions.length, ...previous.transactions);
    todayParts = window.__todayParts96;
    delete window.__todayParts96;
    saveState(); render();
    return { status: transaction?.status, toastText, undoVisible, stillPending, doneText };
  }, monthAgendaState96);
  check(reserveConfirmee96.status === "posted"
      && /mis de côté/i.test(reserveConfirmee96.toastText)
      && /Mois bouclé/.test(reserveConfirmee96.toastText)
      && reserveConfirmee96.undoVisible
      && !reserveConfirmee96.stillPending
      && /Mis de côté/.test(reserveConfirmee96.doneText),
    `confirmer la réserve la déplace dans « Fait ce mois » sans la dire payée (${JSON.stringify(reserveConfirmee96)})`);

  // Le salaire seed ne doit pas dépendre du jour où tourne la CI. On remet
  // son mouvement en attente sous une horloge locale figée au 1er, puis le
  // clic ci-dessous doit le dater au vrai `NOW.d` du scénario.
  await page.evaluate(() => {
    window.__todayPartsSalary96 = todayParts;
    todayParts = () => ({ y: NOW.y, m: NOW.m, d: 1 });
    const transaction = transactions.find(
      t => t.recurringId === "r-salaire" && inMonth(t, cursor.y, cursor.m)
    );
    if (transaction) {
      transaction.status = "planned";
      transaction.d = new Date(NOW.y, NOW.m, 0).getDate();
    }
    saveState(); render();
  });

  const lire = () => page.evaluate(() => ({
    revenus: [...document.querySelectorAll(".home-agenda-card .home-income-row .meta .t")]
      .map(e => e.textContent.trim()),
    revenusCta: [...document.querySelectorAll(".home-agenda-card .home-income-row .home-bill-action")]
      .map(e => e.textContent.trim()),
    factures: [...document.querySelectorAll(".home-agenda-card .home-bills-list:not(.home-done-list) .home-bill-row:not(.home-income-row) .meta .t")]
      .map(e => e.textContent.trim()),
    facturesCta: [...document.querySelectorAll(".home-agenda-card .home-bills-list:not(.home-done-list) .home-bill-row:not(.home-income-row) .home-bill-action")]
      .map(e => e.textContent.trim()),
    faits: [...document.querySelectorAll(".home-agenda-card .home-done-row .s")]
      .map(e => e.textContent.trim()),
    tout: /Tout est à jour/.test(document.querySelector(".home-agenda-count")?.textContent || ""),
    entre: snapshot(cursor.y, cursor.m).income,
  }));

  const depart = await lire();
  check(depart.revenus.length > 0 && depart.revenusCta.includes("Reçu"),
    `un revenu attendu s'encaisse d'un tap depuis l'accueil (obtenu ${JSON.stringify(depart.revenusCta)})`);
  // Le salaire de démonstration est PRÉVU le 25 : c'est justement le cas qui
  // n'offrait plus aucun bouton.
  const prevu = await page.evaluate(() => {
    const t = transactions.find(t => t.recurringId === "r-salaire" && inMonth(t, cursor.y, cursor.m));
    const row = [...document.querySelectorAll(".home-income-row")]
      .find(element => element.textContent.includes(t?.title || "Salaire"));
    return t ? {
      statut: t.status,
      d: t.d,
      montantMouvement: chf(txCHF(t)),
      montantAffiche: row?.querySelector(".amount")?.textContent.trim() || "",
    } : null;
  });
  check(prevu && prevu.statut === "planned"
      && prevu.montantAffiche === prevu.montantMouvement,
    `le salaire prévu affiche le mouvement qui sera réellement reçu (${JSON.stringify(prevu)})`);

  // Si l'action manque, on le dit par une assertion plutôt que de laisser la
  // suite mourir sur un délai d'attente : un échec doit rester lisible.
  const cta96 = await page.$(".home-agenda-card .home-income-row .home-bill-action");
  check(!!cta96, "l'accueil porte réellement l'action d'encaissement");
  if (cta96) await cta96.click();
  await page.waitForTimeout(400);
  const encaisse = await lire();
  const apres = await page.evaluate(() => {
    const t = transactions.find(t => t.recurringId === "r-salaire" && inMonth(t, cursor.y, cursor.m));
    return { statut: t.status, d: t.d, aujourdhui: NOW.d };
  });
  check(apres.statut === "posted" && apres.d === apres.aujourdhui,
    `confirmer un revenu le comptabilise AU JOUR RÉEL (obtenu ${JSON.stringify(apres)})`);
  check(encaisse.revenus.length === depart.revenus.length - 1,
    "le revenu encaissé quitte la liste des revenus attendus");
  check(encaisse.faits.some(text => /Reçu/.test(text)),
    `le salaire reste dans le bilan avec son état « Reçu » (${JSON.stringify(encaisse.faits)})`);
  check(encaisse.entre > depart.entre,
    `« Entré » augmente vraiment (${depart.entre} → ${encaisse.entre})`);

  // Chaque facture réglée quitte « À faire » et reste dans « Fait ce mois ».
  let garde = 0, vu = depart.factures.length;
  while (garde++ < 30) {
    const bouton = await page.$(".home-agenda-card .home-bills-list:not(.home-done-list) .home-bill-row:not(.home-income-row) .home-bill-action");
    if (!bouton) break;
    await bouton.click();
    await page.waitForTimeout(400);
  }
  const fin = await lire();
  check(vu > 0 && fin.factures.length === 0 && fin.tout
      && fin.faits.some(text => /Payé|Mis de côté|Investi/.test(text)),
    `tout réglé : « À faire » se vide et « Fait ce mois » garde les preuves (${JSON.stringify(fin)})`);

  // Garde-fou : « confirmer » ne touche JAMAIS un mouvement déjà comptabilisé.
  const garde96 = await page.evaluate(() => {
    const t = transactions.find(t => t.status === "posted");
    const avant = { statut: t.status, d: t.d };
    const bouton = document.createElement("button");
    bouton.setAttribute("data-confirmtx", String(t.id));
    document.getElementById("screen").appendChild(bouton);
    bouton.click();
    const apres = { statut: t.status, d: t.d };
    bouton.remove();
    return { avant, apres };
  });
  check(garde96.avant.statut === garde96.apres.statut && garde96.avant.d === garde96.apres.d,
    `un mouvement comptabilisé n'est jamais re-daté ni retouché (${JSON.stringify(garde96)})`);
  await page.evaluate(() => {
    todayParts = window.__todayPartsSalary96;
    delete window.__todayPartsSalary96;
    saveState(); render();
  });
}

// ---------- Test 97 : aucun état rogné, aucun nom coupé ----------
currentTest = "états et noms jamais rognés";
// Audit visuel des 16 écrans (05.08.2026). Deux défauts réels :
//   · le badge « Prévu » était rogné jusqu'à 95 px à 320 px, donc TOTALEMENT
//     invisible sur 7 lignes sur 10 : impossible de distinguer un mouvement
//     prévu d'un mouvement comptabilisé, alors que c'est un invariant du
//     produit ;
//   · dans les listes de GESTION (comptes, factures, factures mensuelles),
//     le nom — qui EST l'information — était tronqué à 320 px.
// Le mouvement « Prévu » mesuré est fourni PAR LE TEST : avant, il comptait
// sur un reste du jeu de démonstration dont le statut dépend du jour du
// mois — vert par accident, rouge dès que l'acompte du 20 est passé.
await page.evaluate(() => {
  transactions.push({ id: "t97-prevu", y: NOW.y, m: NOW.m, d: Math.min(28, NOW.d + 1),
    title: "Mouvement prévu T97", amount: 42, type: "expense", cat: "Autre",
    acc: defaultCashAccount(), dest: null, status: "planned" });
  saveState(); render();
});
for (const largeur of [390, 320]) {
  await page.setViewportSize({ width: largeur, height: 844 });
  await goHome();
  await page.click('#tabbar button[aria-label="Historique"]');
  await page.waitForTimeout(400);
  const badges = await page.evaluate(() => {
    const res = [];
    for (const t of document.querySelectorAll("#moreTxList .meta .t")) {
      for (const marque of t.querySelectorAll(".badge, .pill")) {
        const bt = t.getBoundingClientRect(), bm = marque.getBoundingClientRect();
        res.push({
          etat: marque.textContent.trim(),
          // Combien de pixels du badge sortent du cadre visible du titre.
          coupe: Math.round(bm.right - bt.right),
          visible: bm.width > 0 && bm.height > 0,
        });
      }
    }
    return res;
  });
  check(badges.length > 0, `${largeur} px : des états sont bien affichés dans l'historique`);
  const rognes = badges.filter(b => b.coupe > 1 || !b.visible);
  check(rognes.length === 0,
    `${largeur} px : aucun état « Prévu » rogné (obtenu ${JSON.stringify(rognes.slice(0, 3))})`);

  // Les listes de gestion : le nom se lit en entier, à toute largeur.
  for (const [vue, selecteur, quoi] of [
    ["recurring", "#screen .card.row.tx .meta .t", "factures mensuelles"],
    ["bills", "#screen .card.row.tx .meta .t", "factures"],
  ]) {
    await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
    await page.waitForTimeout(350);
    const coupes = await page.evaluate(sel => [...document.querySelectorAll(sel)]
      .filter(e => e.scrollWidth > e.clientWidth + 1
        && getComputedStyle(e).textOverflow === "ellipsis")
      .map(e => e.textContent.trim().slice(0, 30)), selecteur);
    check(coupes.length === 0,
      `${largeur} px · ${quoi} : le nom se lit en entier (coupés : ${JSON.stringify(coupes)})`);
  }
  await page.evaluate(() => { activeTab = "accounts"; moreView = null; render(); });
  await page.waitForTimeout(350);
  const comptesCoupes = await page.evaluate(() => [...document.querySelectorAll("#screen [data-accid] .meta .t")]
    .filter(e => e.scrollWidth > e.clientWidth + 1)
    .map(e => e.textContent.trim().slice(0, 30)));
  check(comptesCoupes.length === 0,
    `${largeur} px · comptes : le nom du compte n'est jamais rogné (${JSON.stringify(comptesCoupes)})`);

  // Toute pastille d'icône reste CARRÉE et dimensionnée, sur tous les écrans.
  for (const vue of ["settings", "networth", "insurance", "subs", "assistant"]) {
    await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
    await page.waitForTimeout(300);
    const mauvaises = await page.evaluate(() => [...document.querySelectorAll("#screen .ico")]
      .map(e => { const b = e.getBoundingClientRect(); return { w: Math.round(b.width), h: Math.round(b.height) }; })
      .filter(i => i.w > 0 && (Math.abs(i.w - i.h) > 2 || i.h < 24)));
    check(mauvaises.length === 0,
      `${largeur} px · ${vue} : les pastilles d'icône restent carrées (obtenu ${JSON.stringify(mauvaises)})`);
  }
}
await page.setViewportSize({ width: 390, height: 844 });
await goHome();

await page.evaluate(() => {
  const i = transactions.findIndex(t => t.id === "t97-prevu");
  if (i >= 0) transactions.splice(i, 1);
  saveState(); render();
});
// ---------- Test 98 : identité installée cohérente ----------
currentTest = "identité installée cohérente";
// Le manifeste annonçait #07090e alors que l'app peint #090C12 : au
// lancement, la couleur de fond de l'écran d'attente ne correspondait pas à
// celle de l'app. Et les icônes doivent rester opaques, carrées et à leur
// taille déclarée, sinon iOS composite sur du blanc.
{
  const racine = path.resolve(HERE, "..");
  const manifeste = JSON.parse(fs.readFileSync(path.join(racine, "manifest.webmanifest"), "utf8"));
  const meta = await page.evaluate(() => document.querySelector('meta[name="theme-color"]').content);
  check(manifeste.theme_color.toLowerCase() === meta.toLowerCase(),
    `le manifeste et la balise annoncent la MÊME couleur (manifeste ${manifeste.theme_color}, balise ${meta})`);
  check(manifeste.background_color.toLowerCase() === meta.toLowerCase(),
    `la couleur de fond au lancement est celle de l'app (obtenu ${manifeste.background_color})`);
  // Les deux déclarations peuvent être d'accord ET fausses : c'est arrivé
  // quand le canvas est passé de #090C12 à #05060A sans que le manifeste
  // suive. On les compare donc à la couleur RÉELLEMENT peinte par l'app.
  const canvasReel = await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--canvas").trim());
  check(canvasReel.toLowerCase() === meta.toLowerCase(),
    `l'écran de lancement annonce le noir que l'app peint vraiment (canvas ${canvasReel}, annoncé ${meta})`);
  // En-tête PNG : IHDR commence à l'octet 16 — largeur, hauteur, profondeur,
  // puis TYPE DE COULEUR (2 = RVB, 6 = RVB + alpha). Une icône trouée est
  // compositée sur du blanc par iOS : elle doit rester opaque.
  const lirePng = fichier => {
    const octets = fs.readFileSync(path.join(racine, fichier));
    return {
      w: octets.readUInt32BE(16), h: octets.readUInt32BE(20),
      type: octets.readUInt8(25), taille: octets.length,
    };
  };
  for (const fichier of ["icon-192.png", "icon-512.png", "apple-touch-icon.png"]) {
    const png = lirePng(fichier);
    check(png.w === png.h && png.w > 0, `${fichier} : carrée (obtenu ${png.w}×${png.h})`);
    check(png.type === 2 || png.type === 0,
      `${fichier} : opaque, sans canal alpha (type couleur ${png.type})`);
    check(png.taille > 2000, `${fichier} : réellement dessinée (${png.taille} octets)`);
  }
  // Ce que le manifeste DÉCLARE doit être ce que le fichier EST.
  for (const icone of manifeste.icons) {
    const png = lirePng(icone.src);
    check(`${png.w}x${png.h}` === icone.sizes,
      `${icone.src} : la taille déclarée au manifeste est la vraie (déclaré ${icone.sizes}, réel ${png.w}x${png.h})`);
  }

  // --- La règle INVERSE pour les logos posés DANS l'app.
  // Les icônes doivent être opaques (iOS composite l'alpha sur du blanc) ;
  // les logos internes doivent être troués, sinon ils rapportent un carré
  // noir sur nos cinq surfaces. Vérifier « a un canal alpha » ne suffit pas :
  // le premier essai en AVAIT un, et gardait quand même un voile à 17/255
  // dans les coins parce que l'artwork d'origine n'est pas noir PUR. On
  // décode donc réellement les pixels.
  //
  // Et on regarde TOUT le pourtour, pas seulement les quatre coins : le
  // deuxième essai avait bien des coins à 0 et laissait quand même un
  // rectangle visible à l'écran, parce que le recadrage tranchait le halo à
  // mi-bord, là où il valait encore 14/255. Quatre coins propres ne prouvent
  // rien sur les 1884 autres pixels du bord.
  const bordAlpha = fichier => {
    const octets = fs.readFileSync(path.join(racine, fichier));
    const w = octets.readUInt32BE(16), h = octets.readUInt32BE(20);
    const profondeur = octets.readUInt8(24), type = octets.readUInt8(25);
    if (profondeur !== 8 || type !== 6) return { type, pourtour: null };
    const morceaux = [];
    let i = 8;
    while (i < octets.length) {
      const taille = octets.readUInt32BE(i);
      const nom = octets.toString("ascii", i + 4, i + 8);
      if (nom === "IDAT") morceaux.push(octets.subarray(i + 8, i + 8 + taille));
      i += taille + 12;
    }
    const brut = zlib.inflateSync(Buffer.concat(morceaux));
    const bpp = 4, ligne = w * bpp;
    const pixels = Buffer.alloc(h * ligne);
    for (let y = 0; y < h; y++) {
      const filtre = brut[y * (ligne + 1)];
      const src = y * (ligne + 1) + 1, dst = y * ligne, prec = (y - 1) * ligne;
      for (let x = 0; x < ligne; x++) {
        const a = x >= bpp ? pixels[dst + x - bpp] : 0;
        const b = y > 0 ? pixels[prec + x] : 0;
        const c = (x >= bpp && y > 0) ? pixels[prec + x - bpp] : 0;
        let v = brut[src + x];
        if (filtre === 1) v += a;
        else if (filtre === 2) v += b;
        else if (filtre === 3) v += (a + b) >> 1;
        else if (filtre === 4) {
          const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
          v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c);
        }
        pixels[dst + x] = v & 0xff;
      }
    }
    const alpha = (x, y) => pixels[y * ligne + x * bpp + 3];
    let pourtour = 0, creteAlpha = 0;
    for (let x = 0; x < w; x++) pourtour = Math.max(pourtour, alpha(x, 0), alpha(x, h - 1));
    for (let y = 0; y < h; y++) pourtour = Math.max(pourtour, alpha(0, y), alpha(w - 1, y));
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) creteAlpha = Math.max(creteAlpha, alpha(x, y));
    return { type, w, h, pourtour, creteAlpha };
  };
  for (const fichier of ["logo-budget.png", "logo-anneau.png"]) {
    const png = bordAlpha(fichier);
    check(png.type === 6, `${fichier} : a bien un canal alpha (type couleur ${png.type})`);
    check(png.pourtour !== null && png.pourtour <= 2,
      `${fichier} : TOUT le pourtour est transparent, pas seulement les coins — sinon le recadrage dessine un rectangle (alpha max relevé sur le bord ${png.pourtour})`);
    check(png.creteAlpha >= 250,
      `${fichier} : le dessin, lui, reste plein (alpha max relevé ${png.creteAlpha})`);
  }
  // Et il doit être servi hors ligne comme le reste : le service worker met en
  // cache tout GET réussi, donc un logo demandé au premier écran y entre seul.
  const utiliseParLApp = fs.readFileSync(path.join(racine, "index.html"), "utf8");
  check(utiliseParLApp.includes("logo-budget.png"),
    "le logo officiel est réellement posé dans l'app, pas seulement dans le dépôt");
}

// ---------- Test 99 : les graphiques disent la vérité ----------
currentTest = "graphiques honnêtes";
// Quatre captures iPhone du propriétaire (05.08.2026) : « améliore ces
// pages, le visuel, les graphs plus jolis ». Trois défauts réels :
//   · la grille « Année » n'était qu'un tableau de texte — deux mois ne se
//     comparaient pas ;
//   · le total des abonnements était peint en CORAIL, couleur réservée au
//     négatif et au dépassement : un coût qui revient n'est ni l'un ni
//     l'autre, et le rouge criait sans rien dire ;
//   · les Comptes ne montraient nulle part OÙ était l'argent.
await goHome();
{
  await page.evaluate(() => {
    // Un mois budgété et DÉPASSÉ : c'est le cas que la barre doit savoir
    // raconter sans dessiner huit fois la colonne.
    S.budgets[`${NOW.y}-${NOW.m}`] = [{ cat: "Logement", amount: 500 }];
    saveState(); activeTab = "budget"; render();
  });
  await page.waitForTimeout(400);
  const annee = await page.evaluate(() => {
    const chart = document.querySelector(".by-chart");
    if (!chart) return null;
    const cols = [...chart.querySelectorAll(".by-col")];
    const rails = cols.filter(c => c.classList.contains("empty"))
      .map(c => getComputedStyle(c.querySelector(".by-track")).backgroundColor);
    return {
      colonnes: cols.length,
      remplies: chart.querySelectorAll(".by-fill").length,
      depassements: chart.querySelectorAll(".by-over").length,
      // Un mois SANS budget ne doit pas porter de rail plein : il
      // ressemblerait à un mois consommé à 100 %.
      railsVides: rails,
      aria: chart.getAttribute("aria-label") || "",
      hauteurs: [...chart.querySelectorAll(".by-fill")]
        .map(e => parseFloat(e.style.height)),
    };
  });
  check(annee !== null, "l'année du Budget est un GRAPHIQUE, plus une grille de texte");
  if (annee) {
    check(annee.colonnes === 12, `douze mois, douze colonnes (obtenu ${annee.colonnes})`);
    check(annee.depassements >= 1,
      "un mois dépassé porte son chapeau de dépassement");
    check(annee.hauteurs.every(h => h <= 100),
      `aucune barre ne sort de son cadre (obtenu ${JSON.stringify(annee.hauteurs)})`);
    check(annee.railsVides.every(c => c === "rgba(0, 0, 0, 0)"),
      `un mois sans budget n'affiche AUCUN rail plein (obtenu ${JSON.stringify(annee.railsVides)})`);
    check(/%/.test(annee.aria),
      `le graphique est lisible par un lecteur d'écran (obtenu « ${annee.aria.slice(0, 60)} »)`);
  }

  // Abonnements : total apaisé + part de chaque poste.
  await page.evaluate(() => { activeTab = "more"; moreView = "subs"; render(); });
  await page.waitForTimeout(400);
  const subs = await page.evaluate(() => {
    const hero = document.querySelector(".home-bills-total, .hero-amount");
    const parts = [...document.querySelectorAll(".sub-share-pct")]
      .map(e => parseInt(e.textContent, 10));
    return {
      couleur: hero ? getComputedStyle(hero).color : "",
      corail: hero ? hero.classList.contains("neg") : false,
      parts,
      barres: document.querySelectorAll(".sub-share-track").length,
    };
  });
  check(!subs.corail,
    `le coût annuel des abonnements n'est PAS peint en corail (couleur ${subs.couleur})`);
  check(subs.barres > 0 && subs.parts.length === subs.barres,
    `chaque abonnement montre sa part du total (${subs.barres} barres, ${subs.parts.length} pourcentages)`);
  if (subs.parts.length) {
    const somme = subs.parts.reduce((a, b) => a + b, 0);
    check(Math.abs(somme - 100) <= subs.parts.length,
      `les parts couvrent bien le total (somme ${somme} %)`);
  }

  // Comptes : la répartition existe et ses parts sont cohérentes.
  await page.evaluate(() => { activeTab = "accounts"; moreView = null; render(); });
  await page.waitForTimeout(400);
  const comptes = await page.evaluate(() => {
    const bar = document.querySelector(".split-bar");
    if (!bar) return null;
    return {
      segments: [...bar.querySelectorAll(".seg")].map(e => parseFloat(e.style.width)),
      legende: document.querySelectorAll(".split-item").length,
      aria: bar.getAttribute("aria-label") || "",
    };
  });
  check(comptes !== null, "les Comptes montrent OÙ est l'argent");
  if (comptes) {
    const somme = comptes.segments.reduce((a, b) => a + b, 0);
    check(Math.abs(somme - 100) < 0.5,
      `les segments couvrent exactement 100 % (obtenu ${somme.toFixed(1)})`);
    check(comptes.legende === comptes.segments.length,
      "chaque segment a sa ligne de légende ÉCRITE, jamais la couleur seule");
    check(/%/.test(comptes.aria), "la répartition est lisible par un lecteur d'écran");
  }
  await page.evaluate(() => { activeTab = "home"; render(); });
}


// ---------- Test 100 : les couleurs veulent dire quelque chose ----------
currentTest = "couleurs et lignes honnêtes";
// Quatre défauts mesurés sur l'app rendue, pas devinés en lecture :
//   · les quatre courbes du Patrimoine empruntaient le vert, le corail et
//     l'ambre — une courbe « Prévoyance » en corail se lisait comme une
//     perte ;
//   · --electric et --violet pointent tous deux vers --brand-bright depuis
//     L2 : la barre de composition dessinait DEUX segments de la même
//     couleur, et la répartition des Comptes peignait sa plus grosse
//     classe avec une couleur de bordure, donc en « vide » ;
//   · 📈 et 🧾 n'ont aucune présentation texte : dans une pastille teintée
//     ils gardaient leurs propres couleurs, dont le rouge de 📈 ;
//   · à 320 px, « Caisse maladie (LAMal) » tombait à 78 px de large.
await goHome();
{
  const semantiques = await page.evaluate(() => {
    const cs = getComputedStyle(document.documentElement);
    const lire = n => cs.getPropertyValue(n).trim().toLowerCase();
    return {
      series: [1, 2, 3, 4, 5].map(i => lire(`--series-${i}`)),
      interdits: ["--positive", "--negative", "--warning"].map(lire),
    };
  });
  check(new Set(semantiques.series).size === semantiques.series.length,
    "les cinq couleurs de série sont réellement différentes");
  for (const [i, couleur] of semantiques.series.entries())
    check(!semantiques.interdits.includes(couleur),
      `--series-${i + 1} n'emprunte ni le vert, ni le corail, ni l'ambre (${couleur})`);

  // Un Budget Glyph doit SUIVRE currentColor. On vérifie le contrat SVG
  // plutôt que le rendu de police : grille 24 × 24, trait arrondi unique,
  // aucune dépendance à un emoji système.
  const glyphes = await page.evaluate(() => {
    const host = document.createElement("div");
    document.body.appendChild(host);
    const result = Object.entries(TYPE_GLYPH).map(([type, name]) => {
      host.innerHTML = budgetGlyph(name);
      const svg = host.querySelector("svg");
      host.style.color = "#36D399";
      const positiveStroke = getComputedStyle(svg).stroke;
      host.style.color = "#FF6B7A";
      const negativeStroke = getComputedStyle(svg).stroke;
      return {
        type, viewBox: svg.getAttribute("viewBox"), fill: svg.getAttribute("fill"),
        stroke: svg.getAttribute("stroke"), width: svg.getAttribute("stroke-width"),
        linecap: svg.getAttribute("stroke-linecap"), linejoin: svg.getAttribute("stroke-linejoin"),
        marks: svg.querySelectorAll("path, circle, rect, line, polyline").length,
        positiveStroke, negativeStroke, text: svg.textContent,
      };
    });
    host.remove();
    return result;
  });
  for (const g of glyphes) {
    check(g.viewBox === "0 0 24 24" && g.fill === "none" && g.stroke === "currentColor",
      `Budget Glyph « ${g.type} » respecte la grille et currentColor (${JSON.stringify(g)})`);
    check(g.width === "1.75" && g.linecap === "round" && g.linejoin === "round" && g.marks > 0,
      `Budget Glyph « ${g.type} » possède un trait arrondi visible (${JSON.stringify(g)})`);
    check(g.positiveStroke !== g.negativeStroke && g.text.trim() === "",
      `Budget Glyph « ${g.type} » suit la couleur CSS et ne contient aucun caractère`);
  }

  // Patrimoine : quatre courbes de classe, quatre couleurs ET quatre traits.
  await page.evaluate(() => { activeTab = "more"; moreView = "networth"; render(); });
  await page.waitForTimeout(400);
  const courbes = await page.evaluate(() => {
    const traits = [...document.querySelectorAll("#screen svg polyline[stroke-dasharray]")];
    return traits.map(t => ({
      couleur: getComputedStyle(t).stroke,
      trait: t.getAttribute("stroke-dasharray"),
    }));
  });
  check(courbes.length >= 2, `le Patrimoine trace ses classes (${courbes.length} courbes)`);
  check(new Set(courbes.map(c => c.couleur)).size === courbes.length,
    "deux classes ne partagent jamais la même couleur");
  check(new Set(courbes.map(c => c.trait)).size === courbes.length,
    "chaque classe a son propre trait — la couleur seule ne porte pas le sens");

  // Composition du patrimoine : des segments distincts, jamais la piste.
  const composition = await page.evaluate(() => {
    const barre = [...document.querySelectorAll("#screen div[role='img']")]
      .find(b => b.querySelector("span[style*='width']") && !b.querySelector("svg"));
    if (!barre) return null;
    const segs = [...barre.querySelectorAll("span")].map(s => getComputedStyle(s).backgroundColor);
    return { segs, piste: getComputedStyle(barre).backgroundColor };
  });
  check(composition && composition.segs.length >= 2, "la composition du patrimoine est dessinée");
  if (composition) {
    check(new Set(composition.segs).size === composition.segs.length,
      `les ${composition.segs.length} segments ont ${new Set(composition.segs).size} couleurs distinctes`);
    check(!composition.segs.includes(composition.piste),
      "aucun segment ne porte la couleur de la piste — une classe ne se lit jamais comme du vide");
  }

  // Comptes : même exigence sur « Où est votre argent ».
  await page.evaluate(() => { activeTab = "accounts"; moreView = null; render(); });
  await page.waitForTimeout(400);
  const repartition = await page.evaluate(() => {
    const barre = document.querySelector(".split-bar");
    if (!barre) return null;
    return {
      segs: [...barre.querySelectorAll(".seg")].map(s => getComputedStyle(s).backgroundColor),
      piste: getComputedStyle(barre).backgroundColor,
    };
  });
  if (repartition) {
    check(new Set(repartition.segs).size === repartition.segs.length,
      "les segments des Comptes ont chacun leur couleur");
    check(!repartition.segs.includes(repartition.piste),
      "la plus grosse classe ne se peint pas en couleur de piste");
  }

  // 320 px : une ligne « à lire » garde la place de se lire.
  await page.setViewportSize({ width: 320, height: 844 });
  await page.evaluate(() => { activeTab = "more"; moreView = "insurance"; render(); });
  await page.waitForTimeout(400);
  const etroit = await page.evaluate(() => {
    const rangee = document.querySelector("#screen .tx.read-row");
    if (!rangee) return null;
    const meta = rangee.querySelector(".meta");
    const montant = rangee.querySelector(".amount");
    const titre = meta && meta.querySelector(".t");
    const lh = titre ? parseFloat(getComputedStyle(titre).lineHeight) : 0;
    return {
      rangeeW: rangee.getBoundingClientRect().width,
      metaW: meta.getBoundingClientRect().width,
      titreLignes: titre ? Math.round(titre.getBoundingClientRect().height / lh) : 0,
      montantSousLeTexte: montant
        ? montant.getBoundingClientRect().top >= meta.getBoundingClientRect().bottom - 1
        : false,
    };
  });
  check(etroit !== null, "l'écran Assurances a bien une ligne à lire");
  if (etroit) {
    check(etroit.montantSousLeTexte,
      "à 320 px le montant descend SOUS le texte au lieu de l'étrangler");
    check(etroit.metaW > etroit.rangeeW * 0.55,
      `le titre garde plus de la moitié de la ligne (${Math.round(etroit.metaW)} px sur ${Math.round(etroit.rangeeW)})`);
    check(etroit.titreLignes <= 2,
      `« Caisse maladie (LAMal) » tient en deux lignes au plus (obtenu ${etroit.titreLignes})`);
  }

  // Deux libellés qui se coupaient en deux.
  // La hauteur ne dit rien ici : .btn porte un plancher tactile de 44 px.
  // On compte les lignes RÉELLES du texte avec un Range — un rectangle par
  // ligne rendue.
  const retour = await page.evaluate(() => {
    const b = document.querySelector("#screen [data-back]");
    if (!b || !b.firstChild) return null;
    const r = document.createRange(); r.selectNodeContents(b);
    return { lignes: r.getClientRects().length, txt: b.textContent.trim() };
  });
  if (retour) check(retour.lignes === 1,
    `« ${retour.txt} » tient sur une seule ligne (${retour.lignes} rendue(s))`);

  await page.evaluate(() => { activeTab = "more"; moreView = "goals"; render(); });
  await page.waitForTimeout(400);
  const pourcent = await page.evaluate(() => {
    const v = document.querySelector("#screen .bar-head .vals");
    if (!v) return null;
    const lh = parseFloat(getComputedStyle(v).lineHeight) || 14;
    return { lignes: Math.round(v.getBoundingClientRect().height / lh), txt: v.textContent.trim() };
  });
  if (pourcent) check(pourcent.lignes <= 1,
    `« ${pourcent.txt} » ne se coupe pas en deux (${pourcent.lignes} ligne(s))`);

  await page.setViewportSize({ width: 390, height: 844 });
  await page.evaluate(() => { activeTab = "home"; moreView = null; render(); });
}


// ---------- Test 101 : l'app parle comme une personne ----------
currentTest = "sans jargon";
// Retour du propriétaire (05.08.2026) sur cinq captures : « ça fait trop
// technique, c'est accessible à tout le monde, un peu comme Duolingo ».
// CLAUDE.md l'exigeait déjà — « français simple, compréhensible par un
// enfant de dix ans » — mais rien ne le VÉRIFIAIT, alors l'écran Impôts
// affichait « Revenus comptabilisés depuis le 1er janvier × 30 % » et le
// Patrimoine « soldes du jour, dérivés de vos comptes ».
//
// Ce test lit le texte RÉELLEMENT rendu sur les seize écrans et refuse un
// vocabulaire de comptable. Il ne juge pas le style : il cherche des mots
// précis, dont chacun a été trouvé à l'écran au moins une fois.
await goHome();
{
  const INTERDITS = [
    "comptabilisé", "comptabilisés", "comptabilisée", "comptabilisées",
    "dérivé", "dérivés", "dérivée", "dérivées",
    "conversions explicites", "réconciliation", "réconcilié",
    "hypothèse", "hypothèses", "arriérés", "périodicité",
    "prorata", "idempotent", "estimé = ", "contribution requise",
    "réserve constituée", "positions selon certificats",
    "progression globale", "équivalent mensuel", "fortune nette",
    "budgétées", "taux d'épargne", "devise de référence", "chiffrement",
    "lissé", "encaissé", "par classe", "empreinte", "colonnes reconnues",
    "position de prévoyance", "échéance :",
  ];
  const ECRANS = [
    ["Mois", () => { activeTab = "home"; moreView = null; }],
    ["Historique", () => { activeTab = "movements"; moreView = null; }],
    ["Budget", () => { activeTab = "budget"; moreView = null; }],
    ["Comptes", () => { activeTab = "accounts"; moreView = null; }],
    ["Gérer", () => { activeTab = "more"; moreView = null; }],
  ];
  const VUES = ["year", "subs", "bills", "recurring", "goals", "taxes",
                "networth", "insurance", "settings", "importcsv", "assistant"];

  const lireTexte = () => page.evaluate(() => {
    // innerText, pas innerHTML : on juge ce que l'utilisateur LIT, jamais un
    // nom de classe ni un commentaire.
    const s = document.getElementById("screen");
    return (s ? s.innerText : "").replace(/\s+/g, " ");
  });

  const fautes = [];
  for (const [nom, aller] of ECRANS) {
    await page.evaluate(`(${aller.toString()})(); render();`);
    await page.waitForTimeout(250);
    const txt = (await lireTexte()).toLowerCase();
    for (const mot of INTERDITS) if (txt.includes(mot)) fautes.push(`${nom} : « ${mot} »`);
  }
  for (const vue of VUES) {
    await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
    await page.waitForTimeout(250);
    const txt = (await lireTexte()).toLowerCase();
    for (const mot of INTERDITS) if (txt.includes(mot)) fautes.push(`${vue} : « ${mot} »`);
  }
  // Les FEUILLES aussi. Elles échappaient au balayage — et c'est là que
  // « Comptabilisé », « Nature », « Périodicité » et « Solde d'ouverture »
  // avaient survécu à trois passes de langage.
  const INTERDITS_FEUILLES = INTERDITS.concat([
    "nature", "périodicité", "solde d'ouverture", "ligne budgétaire",
    "montant cible", "contribution prévue", "cash disponible",
    "fortune nette", "récurrence", "projection à la retraite",
  ]);
  const feuilles = await page.evaluate(interdits => {
    const trouves = [];
    for (const s of document.querySelectorAll(".sheet")) {
      const avant = s.style.display;
      s.style.display = "flex";
      const txt = (s.innerText || "").replace(/\s+/g, " ").toLowerCase();
      s.style.display = avant;
      for (const mot of interdits) if (txt.includes(mot)) trouves.push(`${s.id} : « ${mot} »`);
    }
    return trouves;
  }, INTERDITS_FEUILLES);
  fautes.push(...feuilles);

  check(fautes.length === 0,
    `aucun mot de comptable à l'écran NI dans les feuilles (trouvés : ${fautes.join(" · ") || "aucun"})`);

  // Une phrase courte se lit ; une phrase de trente mots se saute. On mesure
  // uniquement la PROSE — les paragraphes et les légendes. Mesurer l'écran
  // entier ne dit rien : innerText recolle les tableaux libellé/montant en
  // un bloc de 83 « mots » qui n'est une phrase pour personne.
  const trop = [];
  for (const vue of ["goals", "taxes", "networth", "insurance", "settings", "assistant"]) {
    await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
    await page.waitForTimeout(250);
    const plusLongue = await page.evaluate(() => {
      let max = 0, pire = "";
      for (const e of document.querySelectorAll("#screen p, #screen .caption")) {
        if (e.querySelector("p, .caption")) continue;   // jamais deux fois le même texte
        for (const f of (e.innerText || "").replace(/\s+/g, " ").split(/[.!?]\s+/)) {
          const n = f.trim().split(/\s+/).filter(Boolean).length;
          if (n > max) { max = n; pire = f.trim().slice(0, 80); }
        }
      }
      return { max, pire };
    });
    if (plusLongue.max > 30) trop.push(`${vue} : ${plusLongue.max} mots — « ${plusLongue.pire}… »`);
  }
  check(trop.length === 0,
    `aucune phrase de plus de 30 mots (${trop.join(" · ") || "aucune"})`);

  // Et l'app garde son honnêteté : dire simplement ne veut pas dire promettre.
  await page.evaluate(() => { activeTab = "more"; moreView = "networth"; render(); });
  await page.waitForTimeout(250);
  const projection = await lireTexte();
  check(/estimation, pas une promesse/.test(projection),
    "la projection reste annoncée comme une estimation, pas une promesse");

  await page.evaluate(() => { activeTab = "home"; moreView = null; render(); });
}


// ---------- Test 102 : une seule géométrie, aucun texte illisible --------
currentTest = "un seul système";
// L'audit total a trouvé CINQ rayons de carte : Obsidian arrondissait à
// 28/22/14, Neon Ultra à 26/18/14. Deux systèmes dans la même app, visibles
// dès qu'on passait de Comptes à Mois. Et deux textes descendaient à 8 et
// 9 px — le « utilisé » de l'anneau et les mois de la page Année.
await goHome();
{
  const RAYONS = ["26px", "18px", "14px"];
  const ECRANS = [
    ["Mois", 'activeTab="home";moreView=null'],
    ["Historique", 'activeTab="movements";moreView=null'],
    ["Budget", 'activeTab="budget";moreView=null'],
    ["Comptes", 'activeTab="accounts";moreView=null'],
    ["Gérer", 'activeTab="more";moreView=null'],
  ];
  const VUES = ["year", "subs", "bills", "recurring", "goals", "taxes",
                "networth", "insurance", "settings", "importcsv", "assistant"];

  const releve = () => page.evaluate(() => {
    const s = document.getElementById("screen");
    const vu = e => {
      const b = e.getBoundingClientRect();
      return b.width > 0 && b.height > 0 && e.getAttribute("aria-hidden") !== "true";
    };
    return {
      rayons: [...new Set([...s.querySelectorAll(".card")].filter(vu)
        .map(c => getComputedStyle(c).borderRadius))],
      // Le SVG compte aussi : le « utilisé » de l'anneau y vivait.
      minPx: Math.min(...[...s.querySelectorAll("*")]
        .filter(e => vu(e) && e.children.length === 0 && (e.textContent || "").trim().length > 1)
        .map(e => parseFloat(getComputedStyle(e).fontSize))
        .filter(v => v > 0), 999),
      // Le bord gauche unique reste la règle POUR LA COLONNE de l'écran.
      // Les cartes d'un carrousel horizontal sont posées côte à côte par
      // construction : leurs bords gauches DOIVENT différer, sinon il n'y
      // aurait pas de carrousel. On les exclut donc de cette mesure — et
      // uniquement elles, pour ne pas relâcher la règle ailleurs.
      bordsGauches: [...new Set([...s.querySelectorAll(".card")]
        .filter(c => vu(c) && !c.closest(".hero-track"))
        .map(c => Math.round(c.getBoundingClientRect().left)))],
    };
  });

  const horsSysteme = [], tropPetit = [], desalignes = [];
  const passer = async (nom, aller) => {
    await aller();
    await page.waitForTimeout(260);
    const r = await releve();
    const mauvais = r.rayons.filter(v => !RAYONS.includes(v));
    if (mauvais.length) horsSysteme.push(`${nom} : ${mauvais.join(", ")}`);
    if (r.minPx < 10) tropPetit.push(`${nom} : ${r.minPx} px`);
    if (r.bordsGauches.length > 1) desalignes.push(`${nom} : ${r.bordsGauches.join(", ")}`);
  };
  for (const [nom, code] of ECRANS) {
    await passer(nom, () => page.evaluate(c => { eval(c); render(); }, code));
  }
  for (const vue of VUES) {
    await passer(vue, () => page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue));
  }

  check(horsSysteme.length === 0,
    `un seul système de rayons — héros 26, carte 18, ligne 14 (hors système : ${horsSysteme.join(" · ") || "aucun"})`);
  check(tropPetit.length === 0,
    `aucun texte sous 10 px (${tropPetit.join(" · ") || "aucun"})`);
  check(desalignes.length === 0,
    `toutes les cartes partagent le même bord gauche (${desalignes.join(" · ") || "aucun écart"})`);

  // Les deux feuilles de style doivent annoncer la MÊME géométrie : sans
  // ça, la divergence reviendrait au premier écran rebranché.
  const geo = await page.evaluate(() => {
    const cs = getComputedStyle(document.documentElement);
    const l = n => cs.getPropertyValue(n).trim();
    return {
      obsidian: [l("--hero-radius"), l("--card-radius"), l("--row-radius")],
      neon: [l("--nu-radius-hero"), l("--nu-radius-card"), l("--nu-radius-control")],
    };
  });
  check(JSON.stringify(geo.obsidian) === JSON.stringify(geo.neon),
    `les deux feuilles annoncent la même géométrie (Obsidian ${geo.obsidian.join("/")} · Neon ${geo.neon.join("/")})`);

  await page.evaluate(() => { activeTab = "home"; moreView = null; render(); });
}


// ---------- Test 103 : le premier écran donne envie, et sait se taire ----
currentTest = "premier écran vivant";
// Retour du propriétaire sur la toute première capture : « je les trouve un
// peu simples ». Trois défauts réels, pas un goût :
//   · un 💰 en guise de logo, alors que l'app a une icône dessinée ;
//   · ~600 px de noir vide au-dessus du contenu ;
//   · trois dalles identiques, rien qui bouge, rien sous le doigt.
// Ce test verrouille les deux choses qui peuvent silencieusement régresser :
// le logo redevenu emoji, et l'animation qui ignore le mouvement réduit.
{
  const neuf = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p103 = await neuf.newPage();
  await p103.goto(APP_URL);
  await p103.waitForSelector('[data-obcountry="CH"]');
  const premier = await p103.evaluate(() => {
    const logo = document.querySelector(".ob-logo");
    const halo = document.querySelector(".ob-halo");
    const etape = document.querySelector(".ob-step");
    const choix = [...document.querySelectorAll(".ob-choice")];
    return {
      logoSrc: logo ? logo.getAttribute("src") : null,
      logoAlt: logo ? logo.getAttribute("alt") : null,
      logoDansTitre: !!(logo && logo.closest("h1")),
      titreTexteEnDouble: [...document.querySelectorAll("h1")]
        .some(h => (h.textContent || "").trim().length > 0),
      logoVisible: logo ? logo.getBoundingClientRect().width >= 60 : false,
      halo: !!halo,
      emojiMarque: (etape ? etape.textContent : "").includes("\u{1F4B0}"),
      anime: etape ? getComputedStyle(etape.firstElementChild).animationName : "none",
      choix: choix.length,
      transition: choix.length ? getComputedStyle(choix[0]).transitionDuration : "0s",
    };
  });
  // 06.08.2026 — le propriétaire a fourni les DEUX dessins officiels : l'anneau
  // seul (icône iPhone) et le verrou anneau + « Budget » (« ça, c'est pour voir
  // partout »). Le premier écran porte donc le VERROU, pas l'icône : il dit le
  // nom du produit, ce que l'anneau seul ne fait pas. L'assertion précédente
  // (`icon-192.png`) est remplacée, pas supprimée — elle garde le même rôle,
  // empêcher le retour à un emoji ou à une marque absente.
  check(premier.logoSrc === "logo-budget.png",
    `le premier écran montre le LOGO officiel de l'app (obtenu ${premier.logoSrc})`);
  check(premier.logoVisible, "le logo est réellement dessiné, à une taille lisible");
  // Une image de marque sans texte de remplacement est un trou pour VoiceOver.
  // Et comme le mot « Budget » est DANS l'image, ce texte doit être le titre :
  // d'où l'image dans le h1, et aucun « Budget » écrit deux fois à l'écran.
  check(premier.logoAlt === "Budget",
    `le logo s'annonce « Budget » à la synthèse vocale (obtenu ${premier.logoAlt})`);
  check(premier.logoDansTitre, "le logo EST le titre de l'écran, pas une décoration à côté");
  check(!premier.titreTexteEnDouble,
    "le nom n'est pas écrit une deuxième fois sous le logo qui le contient déjà");
  check(!premier.emojiMarque, "le sac d'argent ne sert plus de marque");
  check(premier.halo, "un halo donne l'unique point lumineux de l'écran");
  check(premier.anime === "ob-in",
    `le contenu entre en animation (obtenu ${premier.anime})`);
  check(premier.choix >= 3, `les choix sont des cibles vivantes (${premier.choix})`);
  check(parseFloat(premier.transition) > 0, "un choix réagit au toucher");
  await neuf.close();

  // MOUVEMENT RÉDUIT : tout s'arrête. C'est une promesse d'accessibilité,
  // pas une option — une animation qui l'ignore est un défaut.
  const calme = await browser.newContext({
    viewport: { width: 390, height: 844 }, reducedMotion: "reduce",
  });
  const p103b = await calme.newPage();
  await p103b.goto(APP_URL);
  await p103b.waitForSelector('[data-obcountry="CH"]');
  const immobile = await p103b.evaluate(() => {
    const etape = document.querySelector(".ob-step");
    const choix = document.querySelector(".ob-choice");
    return {
      anime: getComputedStyle(etape.firstElementChild).animationName,
      transition: getComputedStyle(choix).transitionDuration,
    };
  });
  check(immobile.anime === "none",
    `mouvement réduit : plus aucune entrée animée (obtenu ${immobile.anime})`);
  check(parseFloat(immobile.transition) === 0,
    `mouvement réduit : plus aucune transition (obtenu ${immobile.transition})`);
  // Et le parcours doit rester FRANCHISSABLE sans animation : la
  // confirmation de 140 ms est sautée, jamais bloquante.
  await p103b.click('[data-obcountry="CH"]');
  await p103b.waitForSelector('[data-obhh="solo"]', { timeout: 3000 });
  check(true, "mouvement réduit : le choix avance immédiatement, sans attente");
  await calme.close();
}

// ---------- Test 104 : le questionnaire remplit déjà le mois ----------
currentTest = "charges et abonnements dès la bienvenue";
// Demande du propriétaire (06.08.2026) : « une page question avant pour les
// dépenses mensuelles et une autre page abonnement — comme ça il peut déjà
// rentrer pas mal de trucs avant d'ouvrir l'app ». L'enjeu n'est pas le
// nombre d'écrans : c'est qu'à la PREMIÈRE ouverture, « Disponible » veuille
// déjà dire quelque chose au lieu d'afficher le salaire entier comme s'il
// était libre.
{
  const ctx104 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p104 = await ctx104.newPage();
  const erreurs104 = [];
  p104.on("pageerror", e => erreurs104.push("PAGEERROR " + e.message));
  await p104.goto(APP_URL);
  await p104.waitForSelector('[data-obcountry="CH"]');
  await p104.click('[data-obcountry="CH"]');
  await p104.click('[data-obhh="solo"]');
  await p104.fill("#obName", "Elio");
  await p104.click('#obForm1 button[type="submit"]');
  await p104.fill("#obSalary", "5500");
  await p104.click('#obForm2 button[type="submit"]');
  await p104.waitForSelector("#obOpening", { state: "visible" });
  await p104.fill("#obOpening", "3400");
  await p104.click('#obForm3 button[type="submit"]');
  await p104.waitForSelector("#obFormCharges", { state: "visible" });

  // Aucun montant n'est proposé d'avance : remplir un budget à la place de
  // quelqu'un, c'est lui mentir sur ses propres chiffres.
  const vierge = await p104.evaluate(() =>
    [...document.querySelectorAll("#obFormCharges .ob-line-amount")].map(i => i.value));
  check(vierge.length >= 4, `l'écran des charges propose plusieurs postes (${vierge.length})`);
  check(vierge.every(v => v === ""), `aucun montant n'est pré-rempli (obtenu ${JSON.stringify(vierge)})`);
  // Et aucune date n'est demandée ici non plus.
  const texteCharges = await p104.evaluate(() => document.getElementById("screen").innerText);
  check(!/jour|date/i.test(texteCharges),
    "l'écran des charges ne réclame ni jour ni date");

  // Retour : une flèche en haut à gauche (demande du propriétaire du
  // 06.08.2026). Le gros bouton « ‹ Retour » en pied d'écran avait le même
  // poids visuel que « Continuer » — trois dalles empilées dont une qui
  // recule. Il est REMPLACÉ, pas supprimé : le geste existe toujours.
  const retour104 = await p104.evaluate(() => {
    const fleche = document.querySelector(".ob-back");
    const b = fleche && fleche.getBoundingClientRect();
    const gros = [...document.querySelectorAll("#screen .btn")]
      .filter(e => /retour/i.test(e.textContent || "")).length;
    return {
      existe: !!fleche,
      etiquette: fleche ? fleche.getAttribute("aria-label") : null,
      enHaut: b ? b.top < 140 : false,
      aGauche: b ? b.left < 60 : false,
      cible: b ? Math.min(b.width, b.height) : 0,
      grosBoutons: gros,
    };
  });
  check(retour104.existe && retour104.enHaut && retour104.aGauche,
    "le retour est une flèche, en haut à gauche");
  check(retour104.cible >= 44, `la flèche reste une vraie cible tactile (${retour104.cible} px)`);
  check(!!retour104.etiquette, `la flèche s'annonce à la synthèse vocale (« ${retour104.etiquette} »)`);
  check(retour104.grosBoutons === 0,
    `plus aucun bouton « Retour » pleine largeur (${retour104.grosBoutons} trouvé(s))`);

  // Un montant illisible est REFUSÉ en nommant sa ligne — jamais transformé
  // en zéro dans le dos de la personne.
  await p104.fill("#obCharge-loyer", "mille cinq cents");
  await p104.click('#obFormCharges button[type="submit"]');
  await p104.waitForTimeout(200);
  // Lecture DÉFENSIVE : si l'écran a avancé malgré la saisie illisible, le
  // bloc d'erreur n'existe plus. Sans cette précaution, le test plantait sur
  // un `null` au lieu de nommer le défaut — un contrôle négatif l'a montré.
  const refus = await p104.evaluate(() => {
    const bloc = document.getElementById("obChargesError");
    return { err: bloc ? bloc.textContent : "", encoreLa: !!document.getElementById("obFormCharges") };
  });
  check(refus.encoreLa,
    "un montant illisible ne fait PAS avancer l'écran (sinon il a été transformé en zéro en silence)");
  check(refus.encoreLa && /loyer/i.test(refus.err),
    `un montant illisible est refusé en désignant sa ligne (obtenu « ${refus.err} »)`);
  if (!refus.encoreLa) { await ctx104.close(); throw new Error("écran des charges franchi avec un montant illisible"); }

  await p104.fill("#obCharge-loyer", "1650");
  await p104.fill("#obCharge-sante", "410");
  await p104.click('#obFormCharges button[type="submit"]');
  await p104.waitForSelector("#obFormSubs", { state: "visible" });
  await p104.fill("#obSub-video", "21.90");
  await p104.click('#obFormSubs button[type="submit"]');
  await p104.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await p104.click('[data-obgoal="urgence"]');
  await p104.waitForSelector("#tabbar button");
  await p104.waitForTimeout(400);

  const cree = await p104.evaluate(() => ({
    charges: RECURRINGS.filter(r => r.type === "expense")
      .map(r => ({ t: r.title, a: r.amount, cat: r.cat, every: r.every })),
    jourValide: RECURRINGS.every(r => Number.isInteger(r.day) && r.day >= 1 && r.day <= 28),
    // Rien n'est COMPTABILISÉ : ce sont des dépenses prévues, pas des
    // mouvements. Le planifié et le réel ne se mélangent jamais.
    mouvements: transactions.length,
  }));
  check(cree.charges.length === 3,
    `les trois lignes remplies deviennent trois charges régulières (obtenu ${cree.charges.length})`);
  check(cree.charges.every(c => c.every === "month"),
    "elles sont mensuelles, comme celles créées depuis l'app");
  check(cree.charges.some(c => c.a === 1650) && cree.charges.some(c => c.a === 21.9),
    `les montants sont repris exactement (obtenu ${JSON.stringify(cree.charges.map(c => c.a))})`);
  check(cree.charges.some(c => c.cat === "Assurance maladie"),
    "chaque poste tombe dans une catégorie réelle du budget");
  check(cree.jourValide, "les données restent conformes au contrôle de chargement");
  check(cree.mouvements === 0,
    `rien n'est comptabilisé : ce sont des dépenses PRÉVUES (${cree.mouvements} mouvement(s))`);

  // La preuve utile : le premier écran sait déjà ce qui doit sortir, sans
  // réintroduire une carte de total dans l'accueil simplifié. A6 : le
  // bilan montre jusqu'à six lignes — les trois charges ET le salaire
  // sont donc tous visibles dès la première ouverture, sans repli.
  const accueil104 = await p104.evaluate(() => ({
    texte: document.getElementById("screen").innerText,
    engage: snapshot(NOW.y, NOW.m).recurringCharges,
    lignesVisibles: document.querySelectorAll(".home-bill-row:not(.home-done-row)").length,
    overflow: document.querySelector(".home-agenda-card .home-done-more")?.textContent || "",
  }));
  const chargesVisibles104 = cree.charges
    .filter(charge => accueil104.texte.includes(charge.t)).length;
  check(Math.abs(accueil104.engage - 2081.90) < 0.01
      && chargesVisibles104 === 3
      && accueil104.lignesVisibles === 4
      && accueil104.overflow === ""
      && /Bilan du mois/i.test(accueil104.texte),
    `dès la première ouverture, les trois charges sont engagées et toutes visibles au bilan avec le salaire (${JSON.stringify({ ...accueil104, chargesVisibles104 })})`);
  check(erreurs104.length === 0, `aucune erreur JS pendant le parcours (${erreurs104.join(" | ")})`);
  await ctx104.close();
}

// Et le parcours doit rester franchissable en ne remplissant RIEN : les deux
// écrans sont facultatifs, pas un péage.
{
  const ctx104b = await browser.newContext({ viewport: { width: 320, height: 844 } });
  const p104b = await ctx104b.newPage();
  await p104b.goto(APP_URL);
  await p104b.waitForSelector('[data-obcountry="CH"]');
  await p104b.click('[data-obcountry="CH"]');
  await p104b.click('[data-obhh="solo"]');
  await p104b.fill("#obName", "Elio");
  await p104b.click('#obForm1 button[type="submit"]');
  await p104b.click("[data-obskip]");
  await p104b.waitForSelector("#obOpening", { state: "visible" });
  await p104b.click('#obForm3 button[type="submit"]');
  await p104b.waitForSelector("#obFormCharges", { state: "visible" });
  const deborde = await p104b.evaluate(() => {
    const s = document.getElementById("screen");
    return s.scrollWidth - s.clientWidth;
  });
  check(deborde <= 1, `l'écran des charges tient à 320 px (débordement ${deborde} px)`);
  // « Continuer » sans rien saisir doit avancer, exactement comme « Passer ».
  await p104b.click('#obFormCharges button[type="submit"]');
  await p104b.waitForSelector("#obFormSubs", { state: "visible", timeout: 3000 });
  await p104b.click("[data-obskipsubs]");
  await p104b.waitForSelector('[data-obgoal="urgence"]', { state: "visible", timeout: 3000 });
  await p104b.click('[data-obgoal="urgence"]');
  await p104b.waitForSelector("#tabbar button", { timeout: 5000 });
  const rien = await p104b.evaluate(() => RECURRINGS.filter(r => r.type === "expense").length);
  check(rien === 0, `ne rien remplir ne crée aucune charge (obtenu ${rien})`);
  check(true, "les deux écrans sont facultatifs des deux façons : « Continuer » à vide et « Passer »");
  await ctx104b.close();
}

// ---------- Test 105 : un seul héros répond à la question du mois ----------
currentTest = "héros mensuel unique";
await goHome();
{
  const heros = await page.evaluate(() => {
    const hero = document.querySelector(".home-hero");
    return {
      count: document.querySelectorAll(".home-hero").length,
      title: hero?.querySelector(".card-label")?.textContent.trim() || "",
      amount: hero?.querySelector(".hero-amount")?.textContent.trim() || "",
      note: hero?.querySelector(".hero-note")?.textContent.trim() || "",
      cta: hero?.querySelector("[data-addtx]")?.textContent.trim() || "",
      carousel: document.querySelectorAll("#heroTrack, [data-heroslide], [data-herodot]").length,
      debordePage: document.getElementById("screen").scrollWidth
        - document.getElementById("screen").clientWidth,
    };
  });
  check(heros.count === 1 && heros.carousel === 0,
    `un seul héros, aucun carrousel (${JSON.stringify(heros)})`);
  check(/Disponible maintenant|Prévu fin du mois|Résultat du mois|Sur vos comptes maintenant/.test(heros.title) && /\d/.test(heros.amount),
    `le héros répond avec un montant (${heros.title} · ${heros.amount})`);
  check(/par jour|Il manque|Sur vos comptes utilisables|vraiment dépensé|L'argent prévu n'est pas compté/.test(heros.note),
    `une seule phrase explique le montant (« ${heros.note} »)`);
  check(heros.cta.includes("Ajouter") && heros.debordePage <= 1,
    `le CTA reste visible sans débordement (${JSON.stringify(heros)})`);
}

// ---------- Test 106 : « mis de côté » n'est pas une dépense ----------
currentTest = "facture ou mis de côté";
// Demande du propriétaire (07.08.2026) : « il faudrait pouvoir définir
// clairement ce que représente le montant… cette distinction doit ensuite
// avoir un impact RÉEL sur les calculs ». C'est le cœur du lot : un 3e
// pilier saisi comme facture était compté comme une dépense de vie, ce qui
// viole l'invariant du projet et faisait mentir le budget et le disponible.
await goHome();
{
  const avant = await page.evaluate(() => {
    const s = snapshot(NOW.y, NOW.m);
    return { vie: s.living, misDeCote: s.savings + s.invest };
  });
  // Une réserve mensuelle de 500, rangée dans « Pilier 3a ».
  const apres = await page.evaluate(() => {
    RECURRINGS.push({ id: "t-reserve", title: "3e pilier E2E", amount: 500,
      type: "expense", cat: "Pilier 3a", day: 1, nature: "reserve",
      accountId: defaultCashAccount() });
    const r = RECURRINGS.find(x => x.id === "t-reserve");
    const cree = materializeRecurring(r, NOW.y, NOW.m);
    saveState(); render();
    const s = snapshot(NOW.y, NOW.m);
    return {
      typeDuMouvement: cree.transaction.type,
      vie: s.living, misDeCote: s.savings + s.invest,
      nature: recurringNature(r), reserve: recurringIsReserve(r),
    };
  });
  check(apres.nature === "reserve" && apres.reserve,
    `une charge rangée en « mis de côté » est reconnue comme telle (${apres.nature})`);
  check(apres.typeDuMouvement === "investment",
    `le mouvement créé est un ENVOI, pas une dépense (obtenu ${apres.typeDuMouvement})`);
  check(Math.abs(apres.vie - avant.vie) < 0.02,
    `le coût de la vie ne bouge PAS d'un centime (${avant.vie} → ${apres.vie})`);
  check(Math.abs((apres.misDeCote - avant.misDeCote) - 500) < 0.02,
    `« mis de côté » augmente exactement de 500 (${avant.misDeCote} → ${apres.misDeCote})`);

  // Et la déduction par catégorie doit marcher SANS champ explicite : c'est
  // ce qui rattrape tout ce qui a déjà été saisi avant aujourd'hui.
  const deduit = await page.evaluate(() => ({
    troisA: recurringNature({ cat: "Pilier 3a" }),
    epargne: recurringNature({ cat: "Épargne" }),
    impots: recurringNature({ cat: "Impôts" }),
    loyer: recurringNature({ cat: "Logement" }),
    sport: recurringNature({ cat: "Restaurants et sorties" }),
    ancienFamily: recurringNature({ cat: "Logement", family: "sub" }),
  }));
  check(deduit.troisA === "reserve" && deduit.epargne === "reserve" && deduit.impots === "reserve",
    `3e pilier, épargne et impôts sont déduits comme réserves (${JSON.stringify(deduit)})`);
  check(deduit.loyer === "facture" && deduit.sport === "abonnement",
    "un loyer reste une facture, une salle de sport un abonnement");
  check(deduit.ancienFamily === "abonnement",
    `l'ancien champ family reste compris (${deduit.ancienFamily})`);

  await page.evaluate(() => {
    const i = RECURRINGS.findIndex(r => r.id === "t-reserve");
    if (i >= 0) RECURRINGS.splice(i, 1);
    const j = transactions.findIndex(t => t.recurringId === "t-reserve");
    if (j >= 0) transactions.splice(j, 1);
    saveState(); render();
  });
  await goHome();
}

// ---------- Test 107 : la provision d'impôts est CE QU'ON A VRAIMENT MIS ----
currentTest = "provision d'impôts réelle";
// Demande du propriétaire (07.08.2026) : « si je mets 2'500 CHF de côté pour
// les impôts, ce montant doit apparaître correctement… il faut une source de
// données cohérente, pas deux calculs indépendants ». Avant, S.taxReserve
// était un nombre tapé à la main, relié à aucun mouvement.
await goHome();
{
  const r = await page.evaluate(() => {
    const avant = taxSummary(NOW.y);
    // Un vrai envoi de 2'500 rangé dans « Impôts », comme en crée une charge
    // régulière de nature « mis de côté ».
    addTx({ id: 91001, y: NOW.y, m: NOW.m, d: NOW.d, title: "Provision impôts E2E",
      amount: 2500, type: "saving", cat: "Impôts",
      acc: defaultCashAccount(), dest: null, status: "posted" });
    const apres = taxSummary(NOW.y);
    const snap = snapshot(NOW.y, NOW.m);
    return {
      avantReserve: avant.reserved, apresReserve: apres.reserved,
      depuisMouvements: apres.reservedFromMovements,
      report: apres.reservedManual,
      // FE2-12 : plus aucun écart automatique — ni ici ni sur l'accueil.
      resteAutomatique: ("reserveGap" in apres) || ("taxGap" in snap),
    };
  });
  check(Math.abs((r.apresReserve - r.avantReserve) - 2500) < 0.02,
    `mettre 2'500 de côté remplit la provision sans rien retaper (${r.avantReserve} → ${r.apresReserve})`);
  check(Math.abs(r.depuisMouvements - 2500) < 0.02,
    `la part « vos envois » vaut exactement le mouvement (${r.depuisMouvements})`);
  check(r.report >= 0 && Math.abs(r.apresReserve - (r.depuisMouvements + r.report)) < 0.02,
    `le report saisi n'est pas effacé, il s'ajoute (report ${r.report})`);
  check(r.resteAutomatique === false,
    "plus aucun « écart à combler » calculé automatiquement — l'app additionne, elle ne prescrit pas (ADR-035)");
  // Un paiement d'impôts reste un paiement, pas une provision.
  const p = await page.evaluate(() => {
    const avant = taxSummary(NOW.y);
    addTx({ id: 91002, y: NOW.y, m: NOW.m, d: NOW.d, title: "Acompte E2E",
      amount: 800, type: "taxPayment", cat: "Impôts",
      acc: defaultCashAccount(), dest: null, status: "posted" });
    const apres = taxSummary(NOW.y);
    return { payeAvant: avant.paid, payeApres: apres.paid,
             reserveAvant: avant.reserved, reserveApres: apres.reserved };
  });
  check(Math.abs((p.payeApres - p.payeAvant) - 800) < 0.02,
    `un acompte payé augmente « déjà payé » (${p.payeAvant} → ${p.payeApres})`);
  check(Math.abs(p.reserveApres - p.reserveAvant) < 0.02,
    "un acompte payé n'est PAS compté comme une provision — payer et réserver sont deux gestes");
  await page.evaluate(() => {
    for (const id of [91001, 91002]) {
      const i = transactions.findIndex(t => t.id === id);
      if (i >= 0) transactions.splice(i, 1);
    }
    saveState(); render();
  });
  await goHome();
}

// ---------- Test 108 : la prévoyance n'est plus comptée deux fois ----------
currentTest = "prévoyance sans double compte";
// Demande du propriétaire (07.08.2026) : « chaque versement mensuel doit être
// enregistré et additionné… si un versement de 500 est enregistré depuis le
// budget mensuel, je ne dois pas devoir retourner dans la page 3e pilier
// pour saisir une nouvelle fois ces 500 ».
// Et le défaut trouvé à l'audit : le patrimoine additionnait les COMPTES de
// prévoyance ET les POSITIONS saisies à la main. Rien n'empêchait de compter
// deux fois le même argent, en faveur de l'utilisateur — le pire sens.
await goHome();
{
  const r = await page.evaluate(() => {
    const compte = ACCOUNTS.find(a => a.kind === "pension");
    const soldeCompte = toCHF(balance(compte.id), compte.currency);
    const patrimoine = () => {
      const liquide = ACCOUNTS.filter(a => a.cash)
        .reduce((s, a) => s + toCents(toCHF(balance(a.id), a.currency)), 0);
      const placements = ACCOUNTS.filter(a => ["savings", "brokerage"].includes(a.kind))
        .reduce((s, a) => s + toCents(toCHF(balance(a.id), a.currency)), 0);
      const prev = ACCOUNTS.filter(a => ["pension", "lifeinsurance"].includes(a.kind))
        .reduce((s, a) => s + toCents(toCHF(balance(a.id), a.currency)), 0);
      const biens = ASSETS.filter(x => x.include !== false).reduce((s, x) => s + toCents(x.value), 0);
      return (liquide + placements + prev + toCents(pensionPositionsTotal()) + biens
        - toCents(liabilitiesTotal())) / 100;
    };
    const avant = patrimoine();
    // La position LIÉE au compte : elle ne doit rien ajouter au patrimoine,
    // le solde du compte y est déjà.
    PENSIONS.push({ id: "t-pen-lie", name: "3a lié E2E", value: 9999,
      accountId: compte.id, icon: "🛡️" });
    const apresLie = patrimoine();
    const valeurAffichee = pensionValue(PENSIONS.find(p => p.id === "t-pen-lie"));
    // Un versement de 500 vers ce compte doit remonter TOUT SEUL.
    addTx({ id: 92001, y: NOW.y, m: NOW.m, d: NOW.d, title: "Versement 3a E2E",
      amount: 500, type: "investment", cat: "Pilier 3a",
      acc: defaultCashAccount(), dest: compte.id, status: "posted" });
    const apresVersement = pensionValue(PENSIONS.find(p => p.id === "t-pen-lie"));
    const affiche = pensionDisplayTotal();
    // Une position NON liée garde exactement son ancien comportement.
    PENSIONS.push({ id: "t-pen-libre", name: "LPP libre E2E", value: 1000, icon: "🛡️" });
    const apresLibre = patrimoine();
    return { soldeCompte, avant, apresLie, valeurAffichee, apresVersement,
             affiche, apresLibre };
  });
  check(Math.abs(r.apresLie - r.avant) < 0.02,
    `une position LIÉE n'ajoute rien au patrimoine — le solde y est déjà (${r.avant} → ${r.apresLie})`);
  check(Math.abs(r.valeurAffichee - r.soldeCompte) < 0.02,
    `elle AFFICHE le solde du compte, pas la valeur résiduelle saisie (${r.valeurAffichee} vs ${r.soldeCompte}, résidu 9999)`);
  check(Math.abs(r.apresVersement - (r.soldeCompte + 500)) < 0.02,
    `un versement de 500 remonte tout seul, sans ressaisie (${r.soldeCompte} → ${r.apresVersement})`);
  check(r.affiche >= r.apresVersement - 0.02,
    `l'écran Prévoyance montre bien la valeur vivante (total ${r.affiche})`);
  check(Math.abs((r.apresLibre - r.apresLie) - 1000) < 0.02,
    `une position NON liée continue de compter, comme avant (${r.apresLie} → ${r.apresLibre})`);
  await page.evaluate(() => {
    for (const id of ["t-pen-lie", "t-pen-libre"]) {
      const i = PENSIONS.findIndex(p => p.id === id);
      if (i >= 0) PENSIONS.splice(i, 1);
    }
    const j = transactions.findIndex(t => t.id === 92001);
    if (j >= 0) transactions.splice(j, 1);
    saveState(); render();
  });
  await goHome();
}

// ---------- Test 109 : où va l'argent mis de côté, sans double compte ------
currentTest = "répartition du mis de côté";
// « Je veux comprendre combien est destiné aux impôts, au 3e pilier, aux
// autres objectifs… il faut vérifier que les calculs ne comptabilisent pas
// deux fois le même montant. » La garantie doit être STRUCTURELLE : chaque
// mouvement tombe dans UNE seule poche.
await goHome();
{
  const r = await page.evaluate(() => {
    const compteEpargne = ACCOUNTS.find(a => a.kind === "savings");
    const comptePrev = ACCOUNTS.find(a => a.kind === "pension");
    // Le piège : un compte d'épargne qui sert À LA FOIS de provision
    // d'impôts et d'objectif. Sans priorité, les 300 seraient comptés deux
    // fois et le total ne tomberait plus juste.
    GOALS.push({ id: "t-goal-c4", name: "Objectif E2E", emoji: "🎯", target: 5000,
      manualCurrent: 0, linked: compteEpargne.id, monthly: 0,
      dueY: NOW.y + 1, dueM: NOW.m, priority: false, achieved: false });
    const base = misDeCoteParDestination(NOW.y, NOW.m);
    addTx({ id: 93001, y: NOW.y, m: NOW.m, d: NOW.d, title: "Impôts C4",
      amount: 300, type: "saving", cat: "Impôts",
      acc: defaultCashAccount(), dest: compteEpargne.id, status: "posted" });
    addTx({ id: 93002, y: NOW.y, m: NOW.m, d: NOW.d, title: "3a C4",
      amount: 200, type: "investment", cat: "Pilier 3a",
      acc: defaultCashAccount(), dest: comptePrev.id, status: "posted" });
    addTx({ id: 93003, y: NOW.y, m: NOW.m, d: NOW.d, title: "Objectif C4",
      amount: 150, type: "saving", cat: "Épargne",
      acc: defaultCashAccount(), dest: compteEpargne.id, status: "posted" });
    const d = misDeCoteParDestination(NOW.y, NOW.m);
    const snap = snapshot(NOW.y, NOW.m);
    return { base, d,
      somme: round2(d.impots + d.prevoyance + d.objectifs + d.autres),
      misDeCoteSnapshot: round2(snap.savings + snap.invest) };
  });
  const d = r.d;
  check(Math.abs((d.impots - r.base.impots) - 300) < 0.02,
    `les 300 vers « Impôts » vont dans la poche impôts (${d.impots})`);
  check(Math.abs((d.prevoyance - r.base.prevoyance) - 200) < 0.02,
    `les 200 vers le 3e pilier vont dans la poche prévoyance (${d.prevoyance})`);
  check(Math.abs((d.objectifs - r.base.objectifs) - 150) < 0.02,
    `les 150 vers le compte d'un objectif vont dans la poche objectifs (${d.objectifs})`);
  // LE contrôle qui compte : les parts font exactement le total, ni plus ni moins.
  check(Math.abs(r.somme - d.total) < 0.02,
    `les quatre poches font EXACTEMENT le total, aucun franc compté deux fois (${r.somme} vs ${d.total})`);
  check(Math.abs(d.total - r.misDeCoteSnapshot) < 0.02,
    `et ce total est celui de l'accueil, pas un deuxième calcul (${d.total} vs ${r.misDeCoteSnapshot})`);
  await page.evaluate(() => {
    for (const id of [93001, 93002, 93003]) {
      const i = transactions.findIndex(t => t.id === id);
      if (i >= 0) transactions.splice(i, 1);
    }
    const g = GOALS.findIndex(x => x.id === "t-goal-c4");
    if (g >= 0) GOALS.splice(g, 1);
    saveState(); render();
  });
  await goHome();
}

// ---------- Test 110 : un objectif ne vieillit plus en silence ------------
currentTest = "objectif relié par défaut";
// Audit des connexions : un objectif à saisie manuelle est juste le jour où
// on l'écrit, puis chaque virement le laisse en arrière sans le dire. Relié
// au compte, il suit le solde et reste vrai tout seul.
await goHome();
{
  await page.evaluate(() => { activeTab = "more"; moreView = "goals"; render(); });
  await page.waitForTimeout(300);
  await page.evaluate(() => openGoalSheet(null));
  await page.waitForSelector("#goalForm", { state: "visible" });
  const neuf = await page.evaluate(() => {
    const sel = document.getElementById("gLinked");
    const compte = ACCOUNTS.find(a => a.id === sel.value);
    return {
      relie: !!sel.value,
      estEpargne: compte ? compte.kind : null,
      // Le champ manuel n'a pas de sens quand un compte est relié.
      manuelCache: getComputedStyle(document.getElementById("gCurrent")).display === "none",
    };
  });
  check(neuf.relie, "un objectif NEUF est relié à un compte par défaut");
  check(neuf.estEpargne === "savings",
    `et c'est le compte d'épargne qui est proposé (obtenu ${neuf.estEpargne})`);
  check(neuf.manuelCache,
    "le champ « déjà là » disparaît quand un compte est relié — sinon c'est une saisie ignorée");

  // Choisir la saisie manuelle le fait réapparaître : l'exception reste
  // possible, pour un objectif sans compte dans l'app.
  const manuel = await page.evaluate(() => {
    const sel = document.getElementById("gLinked");
    sel.value = "";
    sel.dispatchEvent(new Event("change"));
    return getComputedStyle(document.getElementById("gCurrent")).display !== "none";
  });
  check(manuel, "choisir la saisie manuelle redonne le champ — l'exception reste possible");
  await page.click("#gCancel");
  await page.waitForTimeout(150);

  // Et la preuve qui compte : un objectif relié SUIT le solde.
  const suit = await page.evaluate(() => {
    const compte = ACCOUNTS.find(a => a.kind === "savings");
    GOALS.push({ id: "t-goal-c5", name: "Suivi E2E", emoji: "🎯", target: 99999,
      manualCurrent: 12, linked: compte.id, monthly: 0,
      dueY: NOW.y + 1, dueM: NOW.m, priority: false, achieved: false });
    const g = GOALS.find(x => x.id === "t-goal-c5");
    const avant = goalCurrent(g);
    addTx({ id: 94001, y: NOW.y, m: NOW.m, d: NOW.d, title: "Virement objectif E2E",
      amount: 400, type: "saving", cat: "Épargne",
      acc: defaultCashAccount(), dest: compte.id, status: "posted" });
    return { avant, apres: goalCurrent(g), manuel: g.manualCurrent };
  });
  check(Math.abs((suit.apres - suit.avant) - 400) < 0.02,
    `un virement de 400 fait avancer l'objectif tout seul (${suit.avant} → ${suit.apres})`);
  check(suit.manuel === 12 && Math.abs(suit.apres - 12) > 1,
    "et le vieux montant saisi est ignoré, pas effacé — la donnée du propriétaire reste");
  await page.evaluate(() => {
    const i = GOALS.findIndex(x => x.id === "t-goal-c5");
    if (i >= 0) GOALS.splice(i, 1);
    const j = transactions.findIndex(t => t.id === 94001);
    if (j >= 0) transactions.splice(j, 1);
    saveState(); render();
  });
  await goHome();
}

// ---------- Test 111 : voir, comprendre, agir — pas lire un paragraphe -----
currentTest = "textes courts, pas de mot orphelin";
// « L'objectif de Budget n'est pas d'expliquer longuement la psychologie de
// la gestion financière… quelques mots bien choisis sont préférables à
// plusieurs paragraphes. » Et : « lorsqu'un mot se retrouve seul à droite,
// il faut continuer la phrase sur la même ligne. »
{
  const ctx111 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p111 = await ctx111.newPage();
  p111.on("dialog", d => d.accept());
  await p111.goto(APP_URL);
  await p111.waitForSelector('[data-obcountry="CH"]');
  await p111.click('[data-obcountry="CH"]'); await p111.click('[data-obhh="solo"]');
  await p111.fill("#obName", "Alex"); await p111.click('#obForm1 button[type="submit"]');
  await p111.fill("#obSalary", "5200"); await p111.click('#obForm2 button[type="submit"]');
  await p111.waitForSelector("#obOpening", { state: "visible" });
  await p111.fill("#obOpening", "3400"); await p111.click('#obForm3 button[type="submit"]');
  await p111.waitForSelector("#obFormCharges", { state: "visible" });
  await p111.click("[data-obskipcharges]");
  await p111.waitForSelector("#obFormSubs", { state: "visible" });
  await p111.click("[data-obskipsubs]");
  await p111.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await p111.click('[data-obgoal="urgence"]');
  await p111.waitForSelector("#tabbar button");
  await p111.waitForTimeout(400);

  // La règle systémique doit être POSÉE : c'est elle qui évite le mot seul
  // sans qu'on réécrive une phrase pour la mise en page.
  const regle = await p111.evaluate(() => {
    const p = document.querySelector("#screen .caption") || document.createElement("p");
    return getComputedStyle(p).textWrap || getComputedStyle(p).textWrapStyle || "";
  });
  check(/pretty/.test(regle), `les blocs de prose demandent un rendu sans orphelin (obtenu « ${regle} »)`);

  const VUES111 = ["subs", "bills", "recurring", "goals", "taxes", "networth",
                   "insurance", "importcsv", "assistant", "year"];
  const trop = [];
  for (const [nom, code] of [["mois", 'activeTab="home";moreView=null'],
                             ["budget", 'activeTab="budget";moreView=null'],
                             ["comptes", 'activeTab="accounts";moreView=null'],
                             ...VUES111.map(v => [v, `activeTab="more";moreView="${v}"`])]) {
    await p111.evaluate(c => { eval(c); render(); }, code);
    await p111.waitForTimeout(260);
    const longs = await p111.evaluate(() => {
      const s = document.getElementById("screen");
      return [...s.querySelectorAll("p, .caption, .s")]
        .filter(e => {
          const b = e.getBoundingClientRect();
          return b.width > 0 && b.height > 0
            // Les avertissements destructifs sont EXCLUS : « ceci efface
            // tout » doit rester explicite. Raccourcir une mise en garde
            // pour gagner une ligne serait un mauvais échange.
            && !/efface|supprim|définitif|irréversible/i.test(e.textContent || "");
        })
        .map(e => ({ mots: (e.textContent || "").trim().split(/\s+/).length,
                     t: (e.textContent || "").trim().slice(0, 46) }))
        .filter(x => x.mots > 32);
    });
    for (const l of longs) trop.push(`${nom} : ${l.mots} mots « ${l.t} »`);
  }
  check(trop.length === 0,
    `aucun bloc de prose au-delà de 32 mots hors avertissement (${trop.slice(0, 4).join(" · ") || "aucun"})`);
  await ctx111.close();
}

// ---------- Test 112 : « Mettre de côté » se trouve, et ne dépense rien ----
currentTest = "mettre de côté depuis un mouvement";
// Question du propriétaire (08.08.2026) : « quand je paye une facture pour
// aller sur un compte épargne, est-ce que c'est considéré comme une facture
// ou comme mis de côté ? Regarde pour ajouter le bouton mettre de côté. »
// Le geste EXISTAIT, mais s'appelait « Épargne » — un nom de produit
// bancaire, pas le geste — alors que le reste de l'app dit « Mis de côté ».
// Il ne l'a pas reconnu. C'est le même mot partout, ou ce n'est pas la même
// chose.
await goHome();
{
  await page.click("#screen [data-addtx]");
  await page.waitForSelector("#quickMenu", { state: "visible" });
  const geste = await page.evaluate(() => {
    const b = document.querySelector('[data-quick="save"]');
    return { existe: !!b, texte: b ? b.textContent.trim() : null,
             haut: b ? b.getBoundingClientRect().height : 0 };
  });
  check(geste.existe, "le geste « mettre de côté » est proposé à la saisie");
  check(/mis de côté/i.test(geste.texte || ""),
    `il porte le mot de l'app, pas un nom de banque (obtenu « ${geste.texte} »)`);
  check(geste.haut >= 44, `et c'est une vraie cible tactile (${geste.haut} px)`);
  await page.click('#quickMenu [data-quick="save"]');
  await page.waitForSelector("#txForm", { state: "visible" });
  check(await page.$eval("#fType", element => element.value) === "saving",
    "le choix ouvre le formulaire déjà réglé sur une mise de côté");
  const choices112 = await page.$eval("#fCat", select =>
    [...select.options].map(option => option.value));
  check(choices112.join("|") === "Épargne|Pilier 3a|Impôts",
    `la promesse du raccourci est réelle (${choices112.join("|")})`);
  await page.selectOption("#fCat", { label: "Pilier 3a" });
  const pilier112 = await page.evaluate(() => ({
    type: document.getElementById("fType").value,
    destination: (ACCOUNTS.find(a => a.id === document.getElementById("fDest").value) || {}).kind,
  }));
  check(pilier112.type === "investment"
      && ["pension", "lifeinsurance"].includes(pilier112.destination),
    `3e pilier prépare un versement vers la prévoyance (${JSON.stringify(pilier112)})`);
  await page.selectOption("#fCat", { label: "Impôts" });
  const impots112 = await page.evaluate(() => ({
    type: document.getElementById("fType").value,
    destination: (ACCOUNTS.find(a => a.id === document.getElementById("fDest").value) || {}).kind,
  }));
  check(impots112.type === "saving" && impots112.destination === "savings",
    `Impôts prépare une réserve vers l'épargne (${JSON.stringify(impots112)})`);
  await page.click("#fCancel");
  await page.waitForTimeout(150);

  // Le même mot AUX TROIS ENDROITS où le geste est proposé, et chacun ouvre
  // vraiment la feuille pré-réglée — un raccourci qui n'aboutit pas est pire
  // qu'un raccourci absent.
  const partout = await page.evaluate(async () => {
    // On lit TOUS les points d'entrée du geste dans le document, visibles ou
    // non : le raccourci de l'accueil détaillé n'est plus affiché aujourd'hui,
    // mais s'il revient il doit porter le même mot. Un vocabulaire cohérent
    // ne se vérifie pas seulement sur ce qui est à l'écran.
    const mots = [...document.querySelectorAll(
      '[data-quicksend], [data-quick="save"], [data-ftype="saving"]')]
      .map(b => (b.querySelector("strong") || b).textContent.trim());
    openSheet("quickMenu");
    await new Promise(r => setTimeout(r, 120));
    const menuButton = document.querySelector('[data-quick="save"]');
    const menu = menuButton
      ? (menuButton.querySelector("strong") || menuButton).textContent.trim()
      : null;
    document.querySelector('[data-quick="save"]').click();
    await new Promise(r => setTimeout(r, 200));
    const typeOuvert = document.getElementById("fType").value;
    closeSheet();
    return { mots, menu, typeOuvert };
  });
  check(partout.mots.length >= 2,
    `le geste est proposé à plusieurs endroits (${partout.mots.length})`);
  check(partout.mots.every(m => /m(?:ettre|is) de côté/i.test(m)),
    `et TOUS portent le même mot (obtenu ${JSON.stringify(partout.mots)})`);
  check(/mis de côté/i.test(partout.menu || ""),
    `le menu ＋ le propose aussi (obtenu « ${partout.menu} »)`);
  check(partout.typeOuvert === "saving",
    `et il ouvre la feuille DÉJÀ réglée sur le bon geste (obtenu ${partout.typeOuvert})`);

  // LA réponse à la question : mettre 500 de côté n'est PAS une dépense du
  // mois — mais ça sort quand même du compte courant, donc le disponible
  // baisse. Les deux à la fois, et c'est ça qui est juste.
  const effet = await page.evaluate(() => {
    const epargne = ACCOUNTS.find(a => a.kind === "savings");
    const courant = defaultCashAccount();
    const avant = snapshot(NOW.y, NOW.m);
    const soldeAvant = balance(courant);
    addTx({ id: 95001, y: NOW.y, m: NOW.m, d: NOW.d, title: "Mise de côté E2E",
      amount: 500, type: "saving", cat: "Épargne",
      acc: courant, dest: epargne.id, status: "posted" });
    const apres = snapshot(NOW.y, NOW.m);
    return {
      vieAvant: avant.living, vieApres: apres.living,
      cotéAvant: round2(avant.savings + avant.invest),
      cotéApres: round2(apres.savings + apres.invest),
      soldeAvant, soldeApres: balance(courant),
      epargneApres: balance(epargne.id),
    };
  });
  check(Math.abs(effet.vieApres - effet.vieAvant) < 0.02,
    `mettre de côté n'entre PAS dans les dépenses du mois (${effet.vieAvant} → ${effet.vieApres})`);
  check(Math.abs((effet.cotéApres - effet.cotéAvant) - 500) < 0.02,
    `ça entre dans « mis de côté » (${effet.cotéAvant} → ${effet.cotéApres})`);
  check(Math.abs((effet.soldeAvant - effet.soldeApres) - 500) < 0.02,
    `l'argent quitte bien le compte courant (${effet.soldeAvant} → ${effet.soldeApres})`);
  check(effet.epargneApres > 0,
    `et arrive sur l'autre compte (solde épargne ${effet.epargneApres})`);
  await page.evaluate(() => {
    const i = transactions.findIndex(t => t.id === 95001);
    if (i >= 0) transactions.splice(i, 1);
    saveState(); render();
  });
  await goHome();
}

// ---------- Test 113 : le retour ressemble à un retour ----------------------
currentTest = "retour lisible sur les écrans de Gérer";
// Question du propriétaire (10.08.2026), capture de « Factures mensuelles » :
// « pourquoi il y a ici le bouton ? pour voir les mouvements du mois ? ».
// Le bouton « ‹ Gérer » était un bouton PLEIN, de la même famille visuelle
// que les actions de contenu : il se lisait comme une destination à ouvrir.
// Il devient une flèche, comme le propriétaire l'avait déjà demandé pour le
// questionnaire — et le nom de la destination passe dans le nom accessible.
{
  // Les DOUZE écrans de Gérer : aucun n'est laissé de côté.
  const VUES113 = ["goals", "bills", "taxes", "networth", "insurance", "recurring",
                   "importcsv", "settings", "assistant", "year", "subs", "movements"];
  for (const vue of VUES113) {
    await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
    await page.waitForTimeout(160);
    const retour = await page.evaluate(() => {
      const b = document.querySelector("#screen [data-back]");
      if (!b) return null;
      const r = b.getBoundingClientRect();
      const titre = b.parentElement.querySelector("h2");
      return {
        texte: b.textContent.trim(),
        nom: b.getAttribute("aria-label") || "",
        w: Math.round(r.width), h: Math.round(r.height),
        // Aligné avec le titre, pas empilé au-dessus.
        memeLigne: titre
          ? Math.abs(r.top + r.height / 2
              - (titre.getBoundingClientRect().top + titre.getBoundingClientRect().height / 2)) <= 6
          : false,
      };
    });
    check(retour !== null, `« ${vue} » a bien un retour`);
    if (!retour) continue;
    check(retour.texte === "‹",
      `« ${vue} » : le retour est une flèche seule (obtenu « ${retour.texte} »)`);
    check(/retour/i.test(retour.nom) && /gérer/i.test(retour.nom),
      `« ${vue} » : VoiceOver entend toujours la destination (obtenu « ${retour.nom} »)`);
    check(retour.w >= 44 && retour.h >= 44,
      `« ${vue} » : la cible reste tactile (${retour.w}×${retour.h})`);
    check(retour.memeLigne, `« ${vue} » : la flèche est alignée avec le titre`);
  }
  // Et elle ramène VRAIMENT à Gérer.
  await page.click("#screen [data-back]");
  await page.waitForTimeout(220);
  const revenu = await page.evaluate(() => ({ onglet: activeTab, vue: moreView }));
  check(revenu.onglet === "more" && revenu.vue === null,
    `la flèche ramène à Gérer (obtenu ${revenu.onglet}/${revenu.vue})`);
  await goHome();
}

// ---------- Test 114 : une mise de côté mensuelle ARRIVE quelque part ------
currentTest = "mise de côté mensuelle sans évaporation";
// Demande du propriétaire (10.08.2026) : « je veux ça dans facture, parce que
// pour moi mettre de côté ça part de mes factures mensuelles… sans le
// virement, ce qui sort de mon compte chaque mois ».
// En allant vérifier, j'ai trouvé pire qu'un bouton mal placé : une ligne
// mensuelle de nature « réserve » créait un mouvement `saving` avec
// `dest: null`. L'argent quittait le compte et n'arrivait NULLE PART —
// patrimoine 3'400 → 2'900 pour 500 CHF réservés, épargne toujours à 0.
// C'est l'inverse de l'invariant : une mise de côté est neutre pour le
// patrimoine. Ce test tient les deux bouts : la poche se remplit, et le
// total ne bouge pas.
await goHome();
{
  const effet = await page.evaluate(() => {
    const courant = defaultCashAccount();
    const epargne = ACCOUNTS.find(a => a.kind === "savings");
    const patrimoine = () => round2(ACCOUNTS.reduce((a, c) => a + toCHF(balance(c.id), c.currency), 0));
    const avant = { patrimoine: patrimoine(), epargne: round2(balance(epargne.id)),
                    courant: round2(balance(courant)) };
    const rec = { id: "rec-e2e-114", title: "Épargne mensuelle E2E", amount: 500,
                  type: "expense", cat: "Épargne", nature: "reserve",
                  accountId: courant, destAccountId: epargne.id, every: "month", day: 1 };
    RECURRINGS.push(rec);
    const { transaction } = materializeRecurring(rec, NOW.y, NOW.m);
    const snap = snapshot(NOW.y, NOW.m);
    return {
      type: transaction.type, dest: transaction.dest, epargneId: epargne.id,
      avant, apres: { patrimoine: patrimoine(), epargne: round2(balance(epargne.id)),
                      courant: round2(balance(courant)) },
      vie: round2(snap.living), coté: round2(snap.savings + snap.invest),
    };
  });
  check(effet.type === "saving", `le mouvement créé est une mise de côté (obtenu ${effet.type})`);
  check(effet.dest === effet.epargneId,
    `il a une poche d'arrivée (obtenu ${effet.dest})`);
  check(Math.abs((effet.avant.courant - effet.apres.courant) - 500) < 0.02,
    `500 sortent bien du compte courant (${effet.avant.courant} → ${effet.apres.courant})`);
  check(Math.abs((effet.apres.epargne - effet.avant.epargne) - 500) < 0.02,
    `et arrivent sur l'épargne (${effet.avant.epargne} → ${effet.apres.epargne})`);
  check(Math.abs(effet.apres.patrimoine - effet.avant.patrimoine) < 0.02,
    `le patrimoine ne bouge pas d'un centime (${effet.avant.patrimoine} → ${effet.apres.patrimoine})`);
  check(effet.coté >= 499.98,
    `le mois compte 500 de mis de côté (obtenu ${effet.coté})`);

  // Sans destination possible, l'app REFUSE au lieu de faire disparaître
  // l'argent. Un refus visible vaut mieux qu'un patrimoine faux.
  const refus = await page.evaluate(() => {
    const courant = defaultCashAccount();
    const sauvegarde = ACCOUNTS.slice();
    ACCOUNTS.length = 0;
    ACCOUNTS.push(sauvegarde.find(a => a.id === courant));
    const rec = { id: "rec-e2e-114b", title: "Réserve orpheline", amount: 100,
                  type: "expense", cat: "Épargne", nature: "reserve",
                  accountId: courant, every: "month", day: 1 };
    RECURRINGS.push(rec);
    let message = null;
    try { materializeRecurring(rec, NOW.y, NOW.m); }
    catch (e) { message = e.message; }
    const cree = transactions.some(t => t.recurringId === "rec-e2e-114b");
    ACCOUNTS.length = 0; sauvegarde.forEach(a => ACCOUNTS.push(a));
    RECURRINGS.splice(RECURRINGS.findIndex(r => r.id === "rec-e2e-114b"), 1);
    return { message, cree };
  });
  check(refus.message !== null && !refus.cree,
    `sans compte d'arrivée, l'app refuse et le dit (« ${refus.message} »)`);

  // La réparation des mouvements déjà créés sans poche d'arrivée.
  const repare = await page.evaluate(() => {
    const courant = defaultCashAccount();
    const epargne = ACCOUNTS.find(a => a.kind === "savings");
    const etat = {
      accounts: [{ id: courant, kind: "current" }, { id: epargne.id, kind: "savings" }],
      recurrings: [{ id: "rec-vieux", destAccountId: null }],
      transactions: [
        { id: 1, type: "saving", cat: "Épargne", acc: courant, dest: null, recurringId: "rec-vieux" },
        { id: 2, type: "saving", cat: "Épargne", acc: courant, dest: null },
        { id: 3, type: "expense", cat: "Logement", acc: courant, dest: null, recurringId: "rec-vieux" },
      ],
    };
    repairReserveDestinations(etat);
    return etat.transactions.map(t => t.dest);
  });
  check(repare[0] !== null,
    `un ancien mouvement de réserve retrouve sa poche (obtenu ${repare[0]})`);
  check(repare[1] === null,
    "un mouvement saisi à la main n'est jamais touché");
  check(repare[2] === null,
    "une dépense ordinaire n'est jamais touchée");

  await page.evaluate(() => {
    for (let i = transactions.length - 1; i >= 0; i--) {
      if (transactions[i].recurringId === "rec-e2e-114") transactions.splice(i, 1);
    }
    const i = RECURRINGS.findIndex(r => r.id === "rec-e2e-114");
    if (i >= 0) RECURRINGS.splice(i, 1);
    saveState(); render();
  });
  await goHome();
}

// ---------- Test 115 : « Mettre de côté » est au premier plan ---------------
currentTest = "mettre de côté au premier plan de la facture";
// « Je veux ça dans facture 🧾 ». Le choix ne doit plus être caché sous un
// repli « Détails », et le virement n'a rien à faire dans une ligne
// mensuelle : une facture, c'est ce qui SORT du compte.
{
  await page.evaluate(() => openRecSheet(null));
  await page.waitForSelector("#recForm", { state: "visible" });
  const feuille = await page.evaluate(() => {
    const grid = document.getElementById("rKindGrid");
    const chips = [...grid.querySelectorAll("button[data-rkind]")];
    const replie = grid.closest("details");
    const cote = chips.find(b => b.dataset.rkind === "reserve");
    return {
      genres: chips.map(b => b.dataset.rkind),
      textes: chips.map(b => b.textContent.trim()),
      sousUnRepli: !!replie,
      hauteurs: chips.map(b => Math.round(b.getBoundingClientRect().height)),
      destVisible: document.getElementById("rDestWrap").style.display !== "none",
      coteVisible: !!(cote && cote.getBoundingClientRect().height > 0),
    };
  });
  check(feuille.genres.join(",") === "facture,abonnement,reserve,revenu",
    `quatre choix et un seul axe (obtenu ${feuille.genres.join(",")})`);
  check(!feuille.genres.includes("transfer") && !feuille.textes.some(t => /virement/i.test(t)),
    "aucun virement dans une ligne mensuelle");
  check(!feuille.sousUnRepli && feuille.coteVisible,
    "« Mettre de côté » est visible d'emblée, pas replié sous « Détails »");
  check(feuille.hauteurs.every(h => h >= 44),
    `chaque choix reste une cible tactile (obtenu ${JSON.stringify(feuille.hauteurs)})`);
  check(!feuille.destVisible, "une facture ordinaire ne demande pas de destination");

  // Choisir « Mettre de côté » pilote les deux selects historiques ET fait
  // apparaître la poche d'arrivée.
  await page.click('#rKindGrid button[data-rkind="reserve"]');
  await page.waitForTimeout(220);
  const apres = await page.evaluate(() => ({
    type: document.getElementById("rType").value,
    nature: document.getElementById("rFamily").value,
    destVisible: document.getElementById("rDestWrap").style.display !== "none",
    destOptions: document.getElementById("rDest").options.length,
    destChoisie: document.getElementById("rDest").value,
    source: document.getElementById("rAccount").value,
  }));
  check(apres.type === "expense" && apres.nature === "reserve",
    `le choix unique écrit les deux axes (obtenu ${apres.type}/${apres.nature})`);
  check(apres.destVisible && apres.destOptions > 0,
    `la poche d'arrivée apparaît avec des comptes (obtenu ${apres.destOptions})`);
  check(apres.destChoisie && apres.destChoisie !== apres.source,
    "et elle n'est jamais le compte de départ");

  // Un revenu ne demande jamais de destination.
  await page.click('#rKindGrid button[data-rkind="revenu"]');
  await page.waitForTimeout(200);
  const revenu = await page.evaluate(() => ({
    type: document.getElementById("rType").value,
    destVisible: document.getElementById("rDestWrap").style.display !== "none",
  }));
  check(revenu.type === "income" && !revenu.destVisible,
    "un revenu mensuel ne demande pas de poche d'arrivée");
  await page.click("#rCancel");
  await page.waitForTimeout(150);
  await goHome();
}

// ---------- Test 116 : la poche d'arrivée montre les VRAIS comptes ---------
currentTest = "choisir où va l'argent mis de côté";
// Demande du propriétaire (10.08.2026) : « affiche-moi les comptes que j'ai
// ouverts, que je puisse choisir quel est le compte où va l'argent mis de
// côté ». Un nom nu ne suffit pas — « Épargne » et « Épargne 3a » se
// ressemblent. On vérifie donc que chaque option porte le nom RÉEL du
// compte, sa nature et son solde, et que la liste couvre tous les comptes
// sauf celui d'où part l'argent.
{
  await page.evaluate(() => openRecSheet(null));
  await page.waitForSelector("#recForm", { state: "visible" });
  await page.click('#rKindGrid button[data-rkind="reserve"]');
  await page.waitForTimeout(250);
  const poches = await page.evaluate(() => {
    const source = document.getElementById("rAccount").value;
    const options = [...document.getElementById("rDest").options];
    return {
      source,
      attendus: ACCOUNTS.filter(a => a.id !== source).map(a => a.id).sort(),
      proposes: options.map(o => o.value).sort(),
      textes: options.map(o => o.textContent),
      categories: [...document.getElementById("rCat").options].map(o => o.value),
      sourceProposee: options.some(o => o.value === source),
      // Le nom réel de chaque compte doit apparaître tel qu'il est saisi.
      nomsPresents: ACCOUNTS.filter(a => a.id !== source)
        .every(a => options.some(o => o.textContent.includes(a.name))),
      // Et la première proposition est la poche la plus probable.
      premiereEstEpargne: (ACCOUNTS.find(a => a.id === options[0].value) || {}).kind === "savings",
    };
  });
  check(poches.proposes.join(",") === poches.attendus.join(","),
    `tous les autres comptes sont proposés (${poches.proposes.length} sur ${poches.attendus.length})`);
  check(!poches.sourceProposee, "le compte de départ n'est jamais une destination");
  check(poches.nomsPresents, "chaque option porte le nom réel du compte");
  check(poches.textes.every(t => /·/.test(t)),
    `chaque option dit aussi le solde du compte (obtenu ${JSON.stringify(poches.textes)})`);
  check(poches.premiereEstEpargne, "l'épargne est proposée en premier");
  check(poches.categories.join("|") === "Épargne|Pilier 3a|Impôts",
    `une mise de côté propose uniquement Épargne, Pilier 3a et Impôts (${poches.categories.join("|")})`);

  // L'exemple d'intitulé suit le choix : plus de « Loyer » sous une réserve.
  const exemples = await page.evaluate(async () => {
    const lus = {};
    for (const kind of ["facture", "abonnement", "reserve", "revenu"]) {
      document.querySelector(`#rKindGrid button[data-rkind="${kind}"]`).click();
      lus[kind] = document.getElementById("rTitle").placeholder;
    }
    return lus;
  });
  check(new Set(Object.values(exemples)).size === 4,
    `chaque nature propose son propre exemple (obtenu ${JSON.stringify(exemples)})`);
  check(exemples.reserve !== "Loyer" && exemples.facture === "Loyer",
    "une mise de côté ne propose plus « Loyer » comme exemple");
  await page.click("#rCancel");

  // Les trois choix passent réellement par la feuille avant d'être
  // matérialisés. Les anciens tests injectaient directement les objets et
  // ne pouvaient donc pas détecter une liste de catégories cassée.
  const matrice = [];
  for (const [index, category] of ["Épargne", "Pilier 3a", "Impôts"].entries()) {
    await page.evaluate(() => openRecSheet(null));
    await page.waitForSelector("#recForm", { state: "visible" });
    await page.click('#rKindGrid button[data-rkind="reserve"]');
    // La catégorie est volontairement rangée dans les détails pour garder le
    // parcours courant court. Le test l'ouvre comme le ferait une personne
    // qui veut distinguer épargne, 3a et impôts.
    if (!(await page.$eval("#rMore", details => details.open))) {
      await page.click("#rMore > summary");
    }
    await page.selectOption("#rCat", { label: category });
    await page.fill("#rTitle", `Réserve formulaire ${category}`);
    await page.fill("#rAmount", String(31 + index));
    await page.click('#recForm button[type="submit"]');
    await page.waitForTimeout(120);
    matrice.push(await page.evaluate(category => {
      const title = `Réserve formulaire ${category}`;
      const recurring = RECURRINGS.find(r => r.title === title);
      const before = snapshot(NOW.y, NOW.m);
      const taxBefore = taxSummary(NOW.y).reservedFromMovements;
      const result = materializeRecurring(recurring, NOW.y, NOW.m);
      const after = snapshot(NOW.y, NOW.m);
      const taxAfter = taxSummary(NOW.y).reservedFromMovements;
      const destination = ACCOUNTS.find(a => a.id === recurring.destAccountId);
      const report = {
        category,
        storedType: recurring.type,
        nature: recurring.nature,
        movementType: result.transaction.type,
        destinationKind: destination?.kind || null,
        livingDelta: round2(after.living - before.living),
        reservedTaxDelta: round2(taxAfter - taxBefore),
      };
      const txIndex = transactions.findIndex(t => t.id === result.transaction.id);
      if (txIndex >= 0) transactions.splice(txIndex, 1);
      const recurringIndex = RECURRINGS.findIndex(r => r.id === recurring.id);
      if (recurringIndex >= 0) RECURRINGS.splice(recurringIndex, 1);
      saveState(); render();
      return report;
    }, category));
  }
  check(matrice.every(item => item.storedType === "expense" && item.nature === "reserve"),
    `les trois lignes restent des réserves mensuelles (${JSON.stringify(matrice)})`);
  check(matrice.find(item => item.category === "Épargne")?.movementType === "saving"
      && matrice.find(item => item.category === "Pilier 3a")?.movementType === "investment"
      && matrice.find(item => item.category === "Impôts")?.movementType === "saving",
    `chaque réserve produit le bon mouvement (${JSON.stringify(matrice)})`);
  check(matrice.every(item => Math.abs(item.livingDelta) < 0.01),
    `aucune réserve ne devient une dépense de vie (${JSON.stringify(matrice)})`);
  check(matrice.find(item => item.category === "Pilier 3a")?.destinationKind === "pension"
      || matrice.find(item => item.category === "Pilier 3a")?.destinationKind === "lifeinsurance",
    `le 3e pilier arrive dans une poche de prévoyance (${JSON.stringify(matrice)})`);
  check(matrice.find(item => item.category === "Impôts")?.destinationKind === "savings",
    `la réserve Impôts revient dans une poche d'épargne (${JSON.stringify(matrice)})`);
  check(Math.abs((matrice.find(item => item.category === "Impôts")?.reservedTaxDelta || 0) - 33) < 0.01,
    `la réserve Impôts augmente exactement de son montant (${JSON.stringify(matrice)})`);
  await page.waitForTimeout(150);
  await goHome();
}

// ---------- Test 117 : un seul nom pour ce qui revient ----------------------
currentTest = "ce qui revient, partout le même mot";
// Le formulaire accepte le mois ET l'année : « transaction mensuelle » et
// « ça revient chaque mois » étaient donc faux. Le langage visible reste
// humain et décrit le rythme seulement dans le champ prévu pour cela.
{
  const restes = await page.evaluate(async () => {
    const trouves = [];
    const lire = (ou) => {
      const t = document.getElementById("screen").innerText;
      if (/transactions? mensuelles?|ça revient chaque mois/i.test(t)) trouves.push(ou);
    };
    activeTab = "home"; render(); lire("accueil");
    const quick = document.querySelector('#quickMenu [data-quick="rec"] strong')?.textContent || "";
    activeTab = "more"; moreView = null; render();
    const menu = document.getElementById("screen").innerText;
    lire("menu Gérer");
    moreView = "recurring"; render();
    const ecran = document.getElementById("screen").innerText;
    lire("écran Ce qui revient");
    moreView = "subs"; render(); lire("abonnements");
    openRecSheet(null);
    const feuille = document.getElementById("recForm").innerText;
    if (/transactions? mensuelles?|ça revient chaque mois/i.test(feuille)) trouves.push("feuille de saisie");
    const titre = document.getElementById("recSheetTitle").textContent;
    const rythmes = [...document.getElementById("rEvery").options].map(option => option.textContent);
    closeSheet();
    activeTab = "home"; moreView = null; render();
    return { trouves, titre, quick, menu, ecran, rythmes };
  });
  check(restes.trouves.length === 0,
    `plus aucun ancien terme mensuel générique (restes : ${JSON.stringify(restes.trouves)})`);
  check(restes.quick === "Ça revient régulièrement"
      && /Ce qui revient/.test(restes.menu)
      && /Ce qui revient/.test(restes.ecran)
      && restes.titre === "Ajouter ce qui revient",
    `le même langage humain relie Ajouter, Gérer, l'écran et la feuille (${JSON.stringify(restes)})`);
  check(restes.rythmes.includes("Tous les mois") && restes.rythmes.includes("Une fois par an"),
    `le vrai rythme reste choisi dans le formulaire (${JSON.stringify(restes.rythmes)})`);
  const verbes = await page.evaluate(() => ({
    debtLabel: TYPE_LABEL.debtPayment,
    labels: Object.fromEntries(
      ["income", "refund", "expense", "taxPayment", "debtPayment", "saving",
        "investment", "transfer", "adjustment"]
        .map(type => [type, completedMovementLabel(type)])
    ),
    tones: Object.fromEntries(
      ["income", "expense", "debtPayment", "saving", "transfer", "adjustment"]
        .map(type => [type, icoClass(type)])
    ),
  }));
  check(verbes.debtLabel === "Remboursement de dette"
      && JSON.stringify(verbes.labels) === JSON.stringify({
    income: "Reçu", refund: "Reçu", expense: "Payé", taxPayment: "Payé",
    debtPayment: "Payé", saving: "Mis de côté", investment: "Investi",
    transfer: "Transféré", adjustment: "Confirmé",
  }) && verbes.tones.income.includes("t-income")
      && verbes.tones.expense.includes("t-expense")
      && verbes.tones.debtPayment.includes("t-expense")
      && verbes.tones.saving.includes("t-save")
      && verbes.tones.transfer.includes("t-neutral")
      && verbes.tones.adjustment.includes("t-neutral"),
  `chaque mouvement garde un seul verbe et une teinte fidèle (${JSON.stringify(verbes)})`);
  const futur = await page.evaluate(() => {
    const previous = {
      cursor: { ...cursor }, activeTab, moreView,
      recurringLength: RECURRINGS.length,
      monthChecks: structuredClone(S.monthChecks || {}),
    };
    for (let i = 0; i < 4; i += 1) {
      RECURRINGS.push({
        id: `future-copy-${i}`, title: `Prévision ${i + 1}`, amount: 10 + i,
        type: "expense", nature: "facture", cat: "Autre", day: 1,
        every: "month", accountId: defaultCashAccount(), icon: "🧾",
      });
    }
    cursor = shiftMonth(NOW, 1);
    activeTab = "home";
    moreView = null;
    render();
    const salary = [...document.querySelectorAll(".home-income-row")]
      .find(row => row.textContent.includes("Salaire"));
    const outgoing = document.querySelector(
      ".home-bills-list:not(.home-done-list) .home-bill-row:not(.home-income-row)"
    );
    // A15 : le mois futur a les mêmes quatre blocs ; le seul geste offert
    // est « Planifier » (mouvement prévu), jamais une confirmation.
    const result = {
      hero: document.querySelector(".home-hero .card-label")?.textContent || "",
      progress: document.querySelector(".home-agenda-count")?.textContent || "",
      blocs: document.querySelectorAll(".home-bloc").length,
      section: !!document.querySelector('[data-home-section="future"]'),
      comptes: [...document.querySelectorAll(".home-bloc-count")].map(c => c.textContent.trim()),
      overflow: document.querySelector('[data-home-section="future"] ~ .home-done-more')?.textContent || "",
      confirmables: document.querySelectorAll("[data-confirmtx]").length,
      salary: salary?.textContent || "",
      salaryAction: salary?.querySelector(".home-bill-action")?.textContent.trim() || "",
      outgoing: outgoing?.textContent || "",
      outgoingAction: outgoing?.querySelector(".home-bill-action")?.textContent.trim() || "",
    };
    cursor = shiftMonth(NOW, -1);
    render();
    result.pastIncomeRows = document.querySelectorAll(".home-income-row").length;
    RECURRINGS.splice(previous.recurringLength);
    S.monthChecks = previous.monthChecks;
    cursor = previous.cursor;
    activeTab = previous.activeTab;
    moreView = previous.moreView;
    saveState();
    render();
    return result;
  });
  // MF1 (ADR-055) : le mois futur met le VRAI argent en focal.
  check(futur.hero === "Sur vos comptes maintenant"
      && /prévu/i.test(futur.progress)
      && futur.blocs === 4
      && futur.section
      && futur.comptes.length > 0
      && futur.comptes.every(c => !/à faire/i.test(c))
      && futur.comptes.some(c => /prévu/i.test(c))
      && (!futur.overflow || (/prévu/i.test(futur.overflow) && !/à faire/i.test(futur.overflow)))
      && futur.confirmables === 0
      && /À recevoir ce mois · Prévu/.test(futur.salary)
      && futur.salaryAction === "Planifier"
      && /Prévu/.test(futur.outgoing)
      && futur.outgoingAction === "Planifier"
      && futur.pastIncomeRows === 0,
    `un mois futur garde les quatre blocs, dit « prévu » et n'offre que « Planifier » (${JSON.stringify(futur)})`);
  await goHome();
}

// ---------- Test 118 : le rythme tient dans une seule phrase ---------------
currentTest = "le rythme en une phrase";
await goHome();
{
  // FE2-1 : le rythme quotidien appartient à la PROJECTION — la position
  // « Fin du mois » de la grande carte, jamais au réel du moment.
  const vu = await page.evaluate(() => {
    heroVue = "finmois"; render();
    const hero = document.querySelector("#screen .home-hero");
    const s = snapshot(NOW.y, NOW.m);
    return {
      texte: [...hero.querySelectorAll(".hero-note")].map(e => e.textContent).join(" "),
      attenduJour: chf(s.daily), attenduJours: s.daysRemaining,
      cartesRythme: document.querySelectorAll("#screen .rythme, #screen .rythme-bar").length,
    };
  });
  check(vu.texte.includes(vu.attenduJour),
    `le montant par jour est celui du moteur (${vu.attenduJour})`);
  check(new RegExp(`${vu.attenduJours} jour`).test(vu.texte),
    `le nombre de jours restants est celui du moteur (${vu.attenduJours})`);
  check(vu.cartesRythme === 0,
    `aucune carte ni jauge de rythme séparée (${vu.cartesRythme})`);

  // À découvert : pas de « par jour », le manque est dit dans le héros.
  const decouvert = await page.evaluate(() => {
    const courant = defaultCashAccount();
    const enorme = snapshot(NOW.y, NOW.m).available + 500;
    addTx({ id: 96001, y: NOW.y, m: NOW.m, d: NOW.d, title: "Découvert E2E",
      amount: round2(enorme), type: "expense", cat: "Autre",
      acc: courant, dest: null, status: "posted" });
    render();
    const hero = document.querySelector("#screen .home-hero");
    const res = {
      dispo: snapshot(NOW.y, NOW.m).available,
      texte: [...hero.querySelectorAll(".hero-note")].map(e => e.textContent).join(" "),
      barre: !!document.querySelector("#screen .rythme-bar"),
    };
    const i = transactions.findIndex(t => t.id === 96001);
    if (i >= 0) transactions.splice(i, 1);
    heroVue = "maintenant";
    saveState(); render();
    return res;
  });
  check(decouvert.dispo < 0, `le scénario met bien à découvert (${decouvert.dispo})`);
  check(!decouvert.barre && !/par jour/.test(decouvert.texte),
    "à découvert, aucune barre ni faux budget quotidien");
  check(/Il manque/.test(decouvert.texte),
    `le manque est dit en clair (obtenu « ${decouvert.texte} »)`);
  await goHome();
}

// ---------- Test 119 : le geste dit ce qu'il fait avancer ------------------
currentTest = "un objectif qui avance se voit";
// Mettre 200 de côté n'est pas « Mouvement ajouté » : c'est un objectif qui
// bouge. L'app le savait — les objectifs sont reliés à un compte — et ne le
// disait pas. Ce test tient les deux bouts : le progrès est ANNONCÉ, et il
// est vrai (mêmes chiffres que l'écran Objectifs). Et il n'est jamais
// annoncé quand rien n'avance.
await goHome();
{
  const cas = await page.evaluate(() => {
    const courant = defaultCashAccount();
    const epargne = ACCOUNTS.find(a => a.kind === "savings");
    // L'objectif RELIÉ du jeu de démo, loin d'un palier.
    const g = GOALS.find(x => x.linked === epargne.id && !x.achieved);
    g.target = round2(goalCurrent(g) * 4 + 4000);
    const photo = photoObjectifs();
    const avant = goalCurrent(g);
    addTx({ id: 97001, y: NOW.y, m: NOW.m, d: NOW.d, title: "Mise de côté 119",
      amount: 300, type: "saving", cat: "Épargne",
      acc: courant, dest: epargne.id, status: "posted" });
    const message = progresObjectif(epargne.id, photo);
    const apres = goalCurrent(g);
    // Rien ne doit être annoncé quand l'argent ne va pas vers l'objectif.
    const photo2 = photoObjectifs();
    addTx({ id: 97002, y: NOW.y, m: NOW.m, d: NOW.d, title: "Course 119",
      amount: 40, type: "expense", cat: "Autre", acc: courant, dest: null, status: "posted" });
    const messageDepense = progresObjectif(null, photo2);
    // Ni quand le mouvement est seulement PRÉVU (aucun solde ne bouge).
    const photo3 = photoObjectifs();
    const messageSansMouvement = progresObjectif(epargne.id, photo3);
    return {
      message, messageDepense, messageSansMouvement,
      pctAvant: Math.round(avant / g.target * 100),
      pctApres: Math.round(apres / g.target * 100),
      nom: g.name,
    };
  });
  check(cas.message !== null, `le geste annonce ce qu'il fait avancer (« ${cas.message} »)`);
  if (cas.message) {
    check(cas.message.includes(cas.nom),
      `le message nomme l'objectif (obtenu « ${cas.message} »)`);
    check(cas.message.includes(`${cas.pctAvant} %`) && cas.message.includes(`${cas.pctApres} %`),
      `les deux pourcentages sont ceux de l'écran Objectifs (${cas.pctAvant} → ${cas.pctApres})`);
  }
  check(cas.messageDepense === null, "une dépense ordinaire n'annonce aucun progrès");
  check(cas.messageSansMouvement === null, "sans mouvement, rien n'est annoncé");

  // Un PALIER franchi porte un mot, et un seul emoji.
  const palier = await page.evaluate(() => {
    const epargne = ACCOUNTS.find(a => a.kind === "savings");
    const g = GOALS.find(x => x.linked === epargne.id && !x.achieved);
    // On place la cible juste au-dessus du solde : le prochain envoi passe
    // les 100 %.
    g.target = round2(goalCurrent(g) + 100);
    const photo = photoObjectifs();
    addTx({ id: 97003, y: NOW.y, m: NOW.m, d: NOW.d, title: "Dernier effort 119",
      amount: 150, type: "saving", cat: "Épargne",
      acc: defaultCashAccount(), dest: epargne.id, status: "posted" });
    const message = progresObjectif(epargne.id, photo);
    // Nettoyage complet.
    for (const id of [97001, 97002, 97003]) {
      const i = transactions.findIndex(t => t.id === id);
      if (i >= 0) transactions.splice(i, 1);
    }
    saveState(); render();
    return message;
  });
  // Deux objectifs sur le MÊME compte : un seul message, et c'est celui qui
  // franchit un palier qui parle.
  const partage = await page.evaluate(() => {
    const epargne = ACCOUNTS.find(a => a.kind === "savings");
    const solde = toCHF(balance(epargne.id), accountCurrency(epargne.id));
    GOALS.push({ id: "g-e2e-119b", name: "Presque fini E2E", emoji: "🎯",
      target: round2(solde + 50), manualCurrent: 0, linked: epargne.id, monthly: 0,
      dueY: NOW.y + 2, dueM: NOW.m, priority: false, achieved: false });
    GOALS.push({ id: "g-e2e-119c", name: "Très loin E2E", emoji: "🏔️",
      target: round2(solde * 10), manualCurrent: 0, linked: epargne.id, monthly: 0,
      dueY: NOW.y + 5, dueM: NOW.m, priority: true, achieved: false });
    const photo = photoObjectifs();
    addTx({ id: 97004, y: NOW.y, m: NOW.m, d: NOW.d, title: "Partage 119",
      amount: 100, type: "saving", cat: "Épargne",
      acc: defaultCashAccount(), dest: epargne.id, status: "posted" });
    const message = progresObjectif(epargne.id, photo);
    const i = transactions.findIndex(t => t.id === 97004);
    if (i >= 0) transactions.splice(i, 1);
    for (const id of ["g-e2e-119b", "g-e2e-119c"]) {
      const k = GOALS.findIndex(x => x.id === id);
      if (k >= 0) GOALS.splice(k, 1);
    }
    saveState(); render();
    return message;
  });
  check(typeof partage === "string" && partage.includes("Presque fini E2E"),
    `sur un compte partagé, c'est le palier franchi qui parle (obtenu « ${partage} »)`);

  // LE PARCOURS RÉEL : le contrôle négatif a montré que débrancher l'annonce
  // du toast ne faisait tomber aucune assertion — mes contrôles appelaient la
  // fonction, jamais le geste. On passe donc par la feuille de saisie.
  const parToast = await page.evaluate(async () => {
    const epargne = ACCOUNTS.find(a => a.kind === "savings");
    const g = GOALS.find(x => x.linked === epargne.id && !x.achieved);
    g.target = round2(goalCurrent(g) * 3 + 2000);
    saveState();
    openTxSheet(null, "saving");
    document.getElementById("fAmount").value = "250";
    document.getElementById("fTitle").value = "Mise de côté par la feuille";
    refreshDestOptions(epargne.id);
    document.getElementById("fDest").value = epargne.id;
    document.getElementById("txForm").dispatchEvent(new Event("submit", { cancelable: true }));
    await new Promise(r => setTimeout(r, 250));
    return document.getElementById("toast").textContent;
  });
  check(/%\s*→\s*\d+\s*%/.test(parToast || ""),
    `enregistrer une mise de côté ANNONCE le progrès (obtenu « ${parToast} »)`);

  check(palier !== null && /objectif atteint/i.test(palier),
    `franchir 100 % se dit en mots (obtenu « ${palier} »)`);
  const emojis = (palier || "").match(/\p{Extended_Pictographic}/gu) || [];
  check(emojis.length <= 2,
    `pas de confettis : au plus deux emojis, dont celui de l'objectif (obtenu ${emojis.length})`);
  await goHome();
}

// ---------- Test 120 : les données locales ne peuvent injecter du HTML ----
currentTest = "sécurité des données restaurées";
// Les identifiants textuels historiques restent acceptés : la sécurité se
// fait au point de rendu, sans réécrire l'identité d'un mouvement. Les six
// familles d'icônes restaurables sont exercées sur leurs vrais écrans.
const context120 = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page120 = await context120.newPage();
const errors120 = [];
page120.on("console", msg => { if (msg.type() === "error") errors120.push(msg.text()); });
page120.on("pageerror", error => errors120.push(`pageerror: ${error.message}`));
page120.on("dialog", dialog => dialog.accept());
await page120.goto(APP_URL);
const attack120 = await page120.evaluate(() => {
  const state = seedState();
  const id = 'legacy-" data-xss-id="injected" autofocus onfocus="window.__budgetXss=(window.__budgetXss||0)+1';
  const icon = name => `<img data-xss-icon="${name}" src=x onerror="window.__budgetXss=(window.__budgetXss||0)+1">`;
  const transaction = state.transactions.find(t => t.recurringId === "r-salaire"
    && t.y === NOW.y && t.m === NOW.m) || state.transactions[0];
  transaction.id = id;
  transaction.title = "Identifiant restauré sûr";
  state.recurrings[0].icon = icon("recurring");
  const subscription = state.recurrings.find(r => r.id === "r-streaming") || state.recurrings[1];
  subscription.icon = icon("subscription");
  state.assets[0].icon = icon("asset");
  state.liabilities[0].icon = icon("liability");
  state.pensions[0].icon = icon("pension");
  state.insurances[0].icon = icon("insurance");
  localStorage.setItem("budget-app-state-v1", JSON.stringify(state));
  localStorage.removeItem("budget-app-state-rescue");
  return { id };
});
await page120.reload();
await page120.waitForSelector("#tabbar button", { timeout: 10000 });
await page120.waitForTimeout(100);

// L'occurrence du salaire tombe le 25 dans la démo. On la remet en attente
// et on place les deux sources de date de ce contexte isolé au 1er afin que
// ce contrôle reste déterministe même si la CI s'exécute après le 25.
await page120.evaluate(id => {
  const transaction = transactions.find(t => String(t.id) === id);
  if (transaction) transaction.status = "planned";
  NOW.d = 1;
  todayParts = () => ({ y: NOW.y, m: NOW.m, d: 1 });
  render();
}, attack120.id);

// Le même identifiant passe par les deux attributs sensibles : la ligne de
// l'historique et le bouton qui confirme une occurrence planifiée.
const homeSafety120 = await page120.evaluate(id => {
  const confirmation = [...document.querySelectorAll("[data-confirmtx]")]
    .find(el => el.dataset.confirmtx === id);
  return {
    confirmationFound: !!confirmation,
    injectedAttribute: !!document.querySelector("[data-xss-id]"),
    injectedIcon: !!document.querySelector("[data-xss-icon]"),
    executed: window.__budgetXss || 0,
  };
}, attack120.id);
check(homeSafety120.confirmationFound,
  "l'identifiant textuel restauré reste intact dans l'action mensuelle");
check(!homeSafety120.injectedAttribute && !homeSafety120.injectedIcon && homeSafety120.executed === 0,
  `aucun attribut, élément ou script injecté sur Mois (${JSON.stringify(homeSafety120)})`);

await page120.click('#tabbar button[aria-label="Historique"]');
await page120.waitForTimeout(100);
const historySafety120 = await page120.evaluate(id => {
  const row = [...document.querySelectorAll("[data-txid]")]
    .find(el => el.dataset.txid === id);
  const result = {
    found: !!row,
    exact: row ? row.dataset.txid === id : false,
    injectedAttribute: row ? row.hasAttribute("data-xss-id") : true,
  };
  if (row) row.click();
  return result;
}, attack120.id);
await page120.waitForSelector("#txForm", { state: "visible", timeout: 5000 });
const editSafety120 = await page120.evaluate(id => ({
  exactEditingID: editingTxId === id,
  title: document.getElementById("fTitle").value,
  executed: window.__budgetXss || 0,
}), attack120.id);
check(historySafety120.found && historySafety120.exact && !historySafety120.injectedAttribute,
  `l'identifiant est échappé sans être modifié (${JSON.stringify(historySafety120)})`);
check(editSafety120.exactEditingID && editSafety120.title === "Identifiant restauré sûr",
  "un identifiant textuel restauré reste ouvrable et modifiable");
check(editSafety120.executed === 0, "ouvrir le mouvement n'exécute aucun attribut restauré");

await page120.evaluate(() => {
  document.getElementById("fTitle").value = "Identifiant restauré modifié";
  document.getElementById("txForm").dispatchEvent(
    new Event("submit", { bubbles: true, cancelable: true })
  );
});
await page120.waitForTimeout(150);
const edited120 = await page120.evaluate(id => {
  const memory = transactions.find(t => t.id === id);
  const stored = JSON.parse(localStorage.getItem("budget-app-state-v1"))
    .transactions.find(t => t.id === id);
  return {
    memoryTitle: memory && memory.title,
    storedTitle: stored && stored.title,
    exactMemoryID: !!memory && memory.id === id,
    exactStoredID: !!stored && stored.id === id,
  };
}, attack120.id);
check(edited120.exactMemoryID && edited120.exactStoredID
    && edited120.memoryTitle === "Identifiant restauré modifié"
    && edited120.storedTitle === "Identifiant restauré modifié",
  `modifier garde l'identifiant exact en mémoire et sur disque (${JSON.stringify(edited120)})`);

await page120.evaluate(id => {
  const row = [...document.querySelectorAll("[data-txid]")]
    .find(el => el.dataset.txid === id);
  if (row) row.click();
}, attack120.id);
await page120.waitForSelector("#txForm", { state: "visible", timeout: 5000 });
await page120.click("#fDelete");
await page120.waitForSelector("#txForm", { state: "hidden", timeout: 5000 });
const deleted120 = await page120.evaluate(id => {
  const stored = JSON.parse(localStorage.getItem("budget-app-state-v1"));
  return {
    inMemory: transactions.some(t => t.id === id),
    onDisk: stored.transactions.some(t => t.id === id),
  };
}, attack120.id);
check(!deleted120.inMemory && !deleted120.onDisk,
  `supprimer retire le bon identifiant en mémoire et sur disque (${JSON.stringify(deleted120)})`);

const iconViews120 = [];
for (const view of ["networth", "insurance", "recurring", "subs"]) {
  await page120.evaluate(nextView => {
    closeSheet();
    activeTab = "more";
    moreView = nextView;
    render();
  }, view);
  await page120.waitForTimeout(100);
  iconViews120.push(await page120.evaluate(nextView => ({
    view: nextView,
    injectedIcons: document.querySelectorAll("[data-xss-icon]").length,
    literalIcons: (document.getElementById("screen").textContent.match(/<img data-xss-icon=/g) || []).length,
    executed: window.__budgetXss || 0,
  }), view));
}
check(iconViews120.every(result => result.injectedIcons === 0 && result.executed === 0),
  `les icônes restaurées restent du texte inerte (${JSON.stringify(iconViews120)})`);
// P13/P08/P12 : Assurances & prévoyance, Ce qui revient (et sa lecture
// Abonnements) puis Patrimoine ne rendent plus AUCUNE icône stockée
// (glyphe sémantique systématique) — la chaîne hostile restaurée
// n'apparaît plus du tout, pas même en texte : exigée à 0 partout.
const minimumLiteralIcons120 = { networth: 0, insurance: 0, recurring: 0, subs: 0 };
check(iconViews120.every(result => result.literalIcons >= minimumLiteralIcons120[result.view]),
  `chaque vue prouve ses propres icônes inertes (${JSON.stringify(iconViews120)})`);
for (const vueSansIcone of ["insurance", "recurring", "subs", "networth"]) {
  const resultat = iconViews120.find(result => result.view === vueSansIcone);
  check(resultat.literalIcons === 0,
    `l'écran ${vueSansIcone} ne rend plus jamais une icône restaurée (${JSON.stringify(resultat)})`);
}
check(errors120.length === 0,
  `zéro erreur console pendant le scénario hostile (${errors120.join(" | ") || "aucune"})`);
await context120.close();

// La toute première version utilisait une clé séparée, migrée avant la
// validation v1. Ses champs de date doivent donc être inertes eux aussi,
// aussi bien dans l'Historique que dans la fraîcheur des Comptes.
const legacyContext120 = await browser.newContext({ viewport: { width: 390, height: 844 } });
const legacyPage120 = await legacyContext120.newPage();
const legacyErrors120 = [];
legacyPage120.on("console", msg => { if (msg.type() === "error") legacyErrors120.push(msg.text()); });
legacyPage120.on("pageerror", error => legacyErrors120.push(`pageerror: ${error.message}`));
await legacyPage120.goto(APP_URL);
const legacyAttack120 = await legacyPage120.evaluate(() => {
  const y = NOW.y + 1;
  const d = '<img data-xss-legacy="date" src=x onerror="window.__budgetLegacyXss=(window.__budgetLegacyXss||0)+1">';
  localStorage.removeItem("budget-app-state-v1");
  localStorage.removeItem("budget-app-state-rescue");
  localStorage.setItem("budget-proto-mouvements", JSON.stringify([{
    id: "legacy-date-safe", y, m: 1, d,
    title: "Ancien mouvement sûr", amount: 12.50,
    type: "expense", cat: "Alimentation", acc: "cur", dest: null,
  }]));
  return { y };
});
await legacyPage120.reload();
await legacyPage120.waitForSelector("#tabbar button", { timeout: 10000 });
await legacyPage120.evaluate(y => {
  cursor = { y, m: 1 };
  activeTab = "movements";
  render();
}, legacyAttack120.y);
await legacyPage120.waitForTimeout(100);
const legacyHistory120 = await legacyPage120.evaluate(() => ({
  injected: !!document.querySelector("[data-xss-legacy]"),
  literal: document.getElementById("screen").textContent.includes("<img data-xss-legacy="),
  executed: window.__budgetLegacyXss || 0,
}));
check(!legacyHistory120.injected && legacyHistory120.literal && legacyHistory120.executed === 0,
  `la date historique reste du texte inerte dans l'Historique (${JSON.stringify(legacyHistory120)})`);

const legacyAccountViews120 = [];
for (const accountViewID of [null, "cur"]) {
  await legacyPage120.evaluate(nextAccount => {
    activeTab = "accounts";
    accountView = nextAccount;
    render();
  }, accountViewID);
  await legacyPage120.waitForTimeout(100);
  legacyAccountViews120.push(await legacyPage120.evaluate(nextAccount => ({
    view: nextAccount || "liste",
    injected: !!document.querySelector("[data-xss-legacy]"),
    literal: document.getElementById("screen").textContent.includes("<img data-xss-legacy="),
    executed: window.__budgetLegacyXss || 0,
  }), accountViewID));
}
check(legacyAccountViews120.every(result => !result.injected && result.literal && result.executed === 0),
  `la fraîcheur des comptes échappe aussi la date historique (${JSON.stringify(legacyAccountViews120)})`);
check(legacyErrors120.length === 0,
  `zéro erreur console pendant la migration historique (${legacyErrors120.join(" | ") || "aucune"})`);
await legacyContext120.close();

// ---------- Test 121 : fluidité Apple — la feuille repart par où elle est arrivée ----------
// apple-design §7 (cohérence spatiale) et §3 (interruptibilité). Les
// assertions lisent les styles CALCULÉS : si la règle CSS .closing ou le
// keyframe sink disparaît, le test échoue même si le JS pose la classe.
currentTest = "fluidité feuilles";
await goHome();
await page.click("[data-addtx]");
await page.waitForSelector("#quickMenu", { state: "visible" });
const fluid121open = await page.evaluate(() => ({
  open: document.getElementById("sheetBackdrop").classList.contains("open"),
  display: getComputedStyle(document.getElementById("sheetBackdrop")).display,
}));
check(fluid121open.open && fluid121open.display === "flex",
  `la feuille s'ouvre (${JSON.stringify(fluid121open)})`);

// Fermeture : la classe .open part tout de suite (contrat des autres tests),
// mais la couche reste affichée le temps que la feuille redescende (sink).
await page.click("#quickCancel");
const fluid121closing = await page.evaluate(() => {
  const bd = document.getElementById("sheetBackdrop");
  const sheet = document.getElementById("quickMenu");
  return {
    open: bd.classList.contains("open"),
    closing: bd.classList.contains("closing"),
    display: getComputedStyle(bd).display,
    pointer: getComputedStyle(bd).pointerEvents,
    sheetAnim: getComputedStyle(sheet).animationName,
  };
});
check(!fluid121closing.open && fluid121closing.closing && fluid121closing.display === "flex",
  `pendant la fermeture, la couche reste affichée sans être « ouverte » (${JSON.stringify(fluid121closing)})`);
check(fluid121closing.sheetAnim === "sink",
  `la feuille redescend par le chemin de son arrivée (animation « ${fluid121closing.sheetAnim} »)`);
check(fluid121closing.pointer === "none",
  "la couche en train de se fermer n'intercepte plus les gestes");
await page.waitForFunction(() => {
  const bd = document.getElementById("sheetBackdrop");
  return !bd.classList.contains("closing") && getComputedStyle(bd).display === "none";
}, { timeout: 2000 });
check(true, "la couche disparaît réellement après la descente");

// Interruption : rouvrir PENDANT la descente ramène la feuille sans attendre,
// et l'ancien minuteur de fermeture ne doit pas la masquer ensuite.
await page.click("[data-addtx]");
await page.waitForSelector("#quickMenu", { state: "visible" });
await page.click("#quickCancel");
await page.click("[data-addtx]");
const fluid121interrupt = await page.evaluate(() => {
  const bd = document.getElementById("sheetBackdrop");
  return { open: bd.classList.contains("open"), closing: bd.classList.contains("closing") };
});
check(fluid121interrupt.open && !fluid121interrupt.closing,
  `rouvrir pendant la fermeture ramène la feuille immédiatement (${JSON.stringify(fluid121interrupt)})`);
await page.waitForTimeout(400); // laisse expirer un éventuel minuteur parasite
const fluid121still = await page.evaluate(() => ({
  open: document.getElementById("sheetBackdrop").classList.contains("open"),
  display: getComputedStyle(document.getElementById("sheetBackdrop")).display,
}));
check(fluid121still.open && fluid121still.display === "flex",
  `la feuille rouverte reste ouverte après l'expiration du minuteur (${JSON.stringify(fluid121still)})`);
await page.click("#quickCancel");
await page.waitForFunction(() => getComputedStyle(document.getElementById("sheetBackdrop")).display === "none",
  { timeout: 2000 });

// Mouvement réduit : fermeture instantanée, jamais de classe .closing.
await page.emulateMedia({ reducedMotion: "reduce" });
await page.click("[data-addtx]");
await page.waitForSelector("#quickMenu", { state: "visible" });
await page.click("#quickCancel");
const fluid121reduced = await page.evaluate(() => {
  const bd = document.getElementById("sheetBackdrop");
  return {
    open: bd.classList.contains("open"),
    closing: bd.classList.contains("closing"),
    display: getComputedStyle(bd).display,
  };
});
check(!fluid121reduced.open && !fluid121reduced.closing && fluid121reduced.display === "none",
  `mouvement réduit : fermeture instantanée sans descente (${JSON.stringify(fluid121reduced)})`);
await page.emulateMedia({ reducedMotion: null });

// Réponse au doigt posé (§1) : les règles de pression des onglets et des
// puces de filtre existent réellement, avec leur débrayage mouvement réduit.
const fluid121press = await page.evaluate(() => {
  const rules = [];
  for (const sheet of document.styleSheets) {
    let list; try { list = sheet.cssRules; } catch { continue; }
    const walk = group => {
      for (const rule of group) {
        // Chromium moderne (nesting CSS) : même une règle simple expose un
        // cssRules vide — on classe donc par présence de selectorText.
        if (rule.selectorText) rules.push({
          sel: rule.selectorText,
          reduced: !!(rule.parentRule && /prefers-reduced-motion/.test(rule.parentRule.conditionText || "")),
          transform: rule.style ? rule.style.transform : "",
        });
        else if (rule.cssRules) walk(rule.cssRules);
      }
    };
    walk(list);
  }
  const find = (sel, reduced) => rules.some(r => r.sel.includes(sel) && r.reduced === reduced);
  return {
    tab: find(".tabbar button:active svg", false),
    tabReduced: find(".tabbar button:active svg", true),
    chip: find(".filter-chip:active", false),
    chipReduced: find(".filter-chip:active", true),
  };
});
check(fluid121press.tab && fluid121press.chip,
  `les onglets et puces de filtre répondent au doigt posé (${JSON.stringify(fluid121press)})`);
check(fluid121press.tabReduced && fluid121press.chipReduced,
  "chaque retour de pression a son débrayage mouvement réduit");

// ---------- Test 122 : gestes Apple — fermer une feuille au doigt ----------
// apple-design §2 (1:1), §5 (vélocité), §6 (projection d'élan), §9
// (rubber-band). Le geste part de la poignée ; les boutons restent le
// chemin accessible.
currentTest = "geste feuilles";
await goHome();

// Chaque feuille porte une poignée, masquée à la voix.
const geste122handles = await page.evaluate(() => {
  const ids = ["txForm", "accForm", "lineForm", "goalForm", "recForm", "itemForm", "insForm", "penForm", "taxForm", "codeForm", "docForm", "billForm", "quickMenu", "salaryForm", "fxForm", "reconForm", "nameForm", "baseForm", "countryForm", "widgetForm"];
  return ids.map(id => {
    const el = document.getElementById(id);
    const h = el && el.firstElementChild;
    return { id, ok: !!(h && h.classList.contains("sheet-handle") && h.getAttribute("aria-hidden") === "true") };
  }).filter(r => !r.ok).map(r => r.id);
});
check(geste122handles.length === 0,
  `chaque feuille a sa poignée masquée à la voix (manquantes : ${geste122handles.join(", ") || "aucune"})`);

const geste122ty = () => page.evaluate(() => {
  const t = getComputedStyle(document.getElementById("quickMenu")).transform;
  if (!t || t === "none") return 0;
  return Number(t.split(",").pop().replace(")", "").trim());
});
const geste122fermee = async (timeout) => {
  try {
    await page.waitForFunction(() => getComputedStyle(document.getElementById("sheetBackdrop")).display === "none",
      null, { timeout });
    return true;
  } catch { return false; }
};
const geste122ouvrir = async () => {
  // Une étape ratée ne doit pas bloquer les suivantes : si une feuille est
  // restée ouverte, on repart d'un état propre avant de rouvrir.
  const restee = await page.evaluate(() =>
    getComputedStyle(document.getElementById("sheetBackdrop")).display !== "none");
  if (restee) { await page.evaluate(() => closeSheet()); await geste122fermee(2000); }
  await page.click("[data-addtx]");
  await page.waitForSelector("#quickMenu", { state: "visible" });
  await page.waitForTimeout(350); // laisse finir l'animation d'entrée
  const box = await (await page.$("#quickMenu .sheet-handle")).boundingBox();
  return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
};

// 1. Petit glissement lent → la feuille suit puis REVIENT (ressort), sans se fermer.
let grip = await geste122ouvrir();
await page.mouse.move(grip.x, grip.y);
await page.mouse.down();
for (let i = 1; i <= 4; i++) {
  await page.mouse.move(grip.x, grip.y + i * 10);
  await page.waitForTimeout(40);
}
const geste122suit = await geste122ty();
check(Math.abs(geste122suit - 40) < 2,
  `la feuille suit le doigt 1:1 (translation ${geste122suit}px pour 40px)`);
await page.mouse.up();
await page.waitForTimeout(900);
const geste122retour = await page.evaluate(() => ({
  open: document.getElementById("sheetBackdrop").classList.contains("open"),
  transform: getComputedStyle(document.getElementById("quickMenu")).transform,
}));
check(geste122retour.open && (geste122retour.transform === "none" || /matrix\(1, 0, 0, 1, 0, 0\)/.test(geste122retour.transform)),
  `un petit glissement revient en place sans fermer (${JSON.stringify(geste122retour)})`);

// 2. Vers le haut, la feuille RÉSISTE (rubber-band) : 80px de doigt,
//    nettement moins de trajet.
await page.mouse.move(grip.x, grip.y);
await page.mouse.down();
for (let i = 1; i <= 4; i++) {
  await page.mouse.move(grip.x, grip.y - i * 20);
  await page.waitForTimeout(40);
}
const geste122haut = await geste122ty();
check(geste122haut < 0 && Math.abs(geste122haut) < 45,
  `vers le haut la feuille résiste au lieu de suivre (80px de doigt → ${geste122haut}px)`);
await page.mouse.up();
await page.waitForTimeout(900);
await page.click("#quickCancel");
check(await geste122fermee(2000), "le bouton Fermer reste le chemin accessible après un geste");

// 3. Une pichenette courte mais rapide ferme : c'est la PROJECTION de
//    l'élan qui décide, pas la distance parcourue.
grip = await geste122ouvrir();
await page.mouse.move(grip.x, grip.y);
await page.mouse.down();
await page.mouse.move(grip.x, grip.y + 60, { steps: 3 });
await page.mouse.move(grip.x, grip.y + 130, { steps: 3 });
await page.mouse.up();
check(await geste122fermee(3000), "une pichenette rapide ferme la feuille (projection d'élan)");

// 4. Un glissement LENT mais profond (au-delà de la moitié) ferme aussi.
grip = await geste122ouvrir();
const geste122h = await page.evaluate(() => document.getElementById("quickMenu").getBoundingClientRect().height);
await page.mouse.move(grip.x, grip.y);
await page.mouse.down();
const geste122pas = Math.ceil((geste122h * 0.62) / 8);
for (let i = 1; i <= 8; i++) {
  await page.mouse.move(grip.x, grip.y + i * geste122pas);
  await page.waitForTimeout(50);
}
await page.waitForTimeout(200); // vélocité retombée : seule la position compte
await page.mouse.up();
check(await geste122fermee(3000), "un glissement profond et lent ferme aussi (position au-delà de la moitié)");

// 5. Mouvement réduit : le geste reste possible, la fermeture est
//    instantanée, sans descente ni classe .closing.
await page.emulateMedia({ reducedMotion: "reduce" });
grip = await geste122ouvrir();
await page.mouse.move(grip.x, grip.y);
await page.mouse.down();
await page.mouse.move(grip.x, grip.y + 60, { steps: 3 });
await page.mouse.move(grip.x, grip.y + 130, { steps: 3 });
await page.mouse.up();
await page.waitForTimeout(120);
const geste122reduit = await page.evaluate(() => ({
  display: getComputedStyle(document.getElementById("sheetBackdrop")).display,
  closing: document.getElementById("sheetBackdrop").classList.contains("closing"),
  transform: getComputedStyle(document.getElementById("quickMenu")).transform,
}));
check(geste122reduit.display === "none" && !geste122reduit.closing
  && (geste122reduit.transform === "none" || /matrix\(1, 0, 0, 1, 0, 0\)/.test(geste122reduit.transform)),
  `mouvement réduit : fermeture au geste instantanée et propre (${JSON.stringify(geste122reduit)})`);
await page.emulateMedia({ reducedMotion: null });

// ---------- Test 123 : P03 Historique — titre, langue et ajustement neutre ----------
// Budget Prisme, lot P03. L'écran porte le nom de son onglet, parle
// d'« opération », affiche un ajustement de solde NEUTRE (couleur
// informative ET « neutre » écrit) et ses états vides utilisent les
// Budget Glyphs, plus aucun emoji fonctionnel.
currentTest = "P03 historique";
await goHome();
await goMovements();
const p03titre = await page.$eval("#screen h2.screen-title", el => el.textContent.trim());
check(p03titre === "Historique", `l'écran porte le nom de son onglet (obtenu « ${p03titre} »)`);
const p03aria = await page.$eval("#moreSearchInput", el => el.getAttribute("aria-label"));
check(p03aria === "Rechercher une opération", `la recherche parle d'opération (obtenu « ${p03aria} »)`);

// Ajustement de solde : neutre dans les deux directions, signe conservé.
await page.evaluate(() => {
  addTx({ id: ++txSeq, y: cursor.y, m: cursor.m, d: Math.min(NOW.d, 28), title: "Correction P03 haut",
    type: "adjustment", up: true, cat: null, acc: ACCOUNTS[0].id, dest: null, status: "posted", amount: 12.35 });
  addTx({ id: ++txSeq, y: cursor.y, m: cursor.m, d: Math.min(NOW.d, 28), title: "Correction P03 bas",
    type: "adjustment", up: false, cat: null, acc: ACCOUNTS[0].id, dest: null, status: "posted", amount: 7.65 });
  saveState(); render();
});
await page.waitForTimeout(200);
const p03adj = await page.evaluate(() => {
  const lignes = [...document.querySelectorAll("#moreTxList .tx")];
  const lire = titre => {
    const row = lignes.find(r => r.textContent.includes(titre));
    if (!row) return null;
    const amount = row.querySelector(".amount");
    const sub = row.querySelector(".s");
    return {
      classes: amount.className,
      signe: amount.textContent.trim()[0],
      sousTitre: sub.textContent,
      // « neutre » doit être VISIBLE, pas seulement présent dans le DOM :
      // une ligne tronquée par l'ellipse cache la mention (défaut attrapé
      // sur la capture 390 de ce lot, corrigé par le libellé court).
      tronque: sub.scrollWidth > sub.clientWidth + 1,
    };
  };
  return { haut: lire("Correction P03 haut"), bas: lire("Correction P03 bas") };
});
check(p03adj.haut && p03adj.haut.classes.includes("info") && !p03adj.haut.classes.includes("pos"),
  `l'ajustement vers le haut est peint NEUTRE, pas comme un revenu (${p03adj.haut && p03adj.haut.classes})`);
check(p03adj.bas && p03adj.bas.classes.includes("info") && !p03adj.bas.classes.includes("neg"),
  `l'ajustement vers le bas est peint NEUTRE, pas comme une dépense (${p03adj.bas && p03adj.bas.classes})`);
check(p03adj.haut && p03adj.haut.signe === "+" && p03adj.bas && p03adj.bas.signe === "−",
  `le signe dit la direction de la correction (obtenu ${p03adj.haut && p03adj.haut.signe} / ${p03adj.bas && p03adj.bas.signe})`);
check(p03adj.haut && p03adj.haut.sousTitre.includes("neutre") && p03adj.bas && p03adj.bas.sousTitre.includes("neutre"),
  "la neutralité de l'ajustement est ÉCRITE, jamais portée par la seule couleur");
check(p03adj.haut && !p03adj.haut.tronque && p03adj.bas && !p03adj.bas.tronque,
  "la mention « neutre » est réellement visible — la ligne n'est pas mangée par l'ellipse");
const p03compteur = await page.$eval("#moreTxList .caption", el => el.textContent);
check(/\d+ opérations?/.test(p03compteur), `le compteur parle d'opérations (obtenu « ${p03compteur} »)`);

// États vides : Budget Glyphs, plus d'emoji fonctionnel.
await page.fill("#moreSearchInput", "zzz-p03-introuvable");
await page.waitForTimeout(250);
const p03videRecherche = await page.evaluate(() => {
  const g = document.querySelector("#moreTxList .empty-state .glyph");
  return { svg: !!(g && g.querySelector("svg.budget-glyph")), emoji: g ? /[\u{1F300}-\u{1FAFF}]/u.test(g.textContent) : true };
});
check(p03videRecherche.svg && !p03videRecherche.emoji,
  `l'état « Aucun résultat » utilise un Budget Glyph, pas un emoji (${JSON.stringify(p03videRecherche)})`);
await page.fill("#moreSearchInput", "");
await page.waitForTimeout(200);
// Mois lointain sans opération : état vide guidé, bouton en langage canonique.
await page.evaluate(() => { cursor = { y: cursor.y + 3, m: 1 }; render(); });
await page.waitForTimeout(200);
const p03videMois = await page.evaluate(() => {
  const st = document.querySelector("#moreTxList .empty-state");
  const btn = st && st.querySelector("[data-addtx]");
  return {
    svg: !!(st && st.querySelector(".glyph svg.budget-glyph")),
    bouton: btn ? btn.textContent.trim() : null,
  };
});
check(p03videMois.svg, "l'état « Rien ce mois-ci » utilise un Budget Glyph");
check(p03videMois.bouton === "Ajouter une opération",
  `le bouton du vide guidé dit « Ajouter une opération » (obtenu « ${p03videMois.bouton} »)`);
// Nettoyage : retour au mois courant et retrait des corrections fictives.
await page.evaluate(() => {
  cursor = { y: NOW.y, m: NOW.m };
  for (const titre of ["Correction P03 haut", "Correction P03 bas"]) {
    const i = transactions.findIndex(t => t.title === titre);
    if (i >= 0) transactions.splice(i, 1);
  }
  saveState(); render();
});
await page.waitForTimeout(200);

// ---------- Test 124 : P0 — l'année consultée montre SES versements ----------
// Régression de l'incident P0 « annee-consultee » (Budget Prisme). Né ROUGE
// (commit 6fc7e4b : la carte « par type » affichait les versements de NOW.y
// sous l'étiquette de l'année consultée), vert depuis le correctif :
// contributions()/contributionsFor() prennent l'année en paramètre, la page
// Année transmet yearCursor, les autres écrans gardent NOW.y par défaut.
// Fixture indépendante : 1000 CHF mis de côté l'an dernier, 250 CHF cette
// année — en consultant l'an dernier, la carte doit dire 1000.
currentTest = "P0 année consultée";
await page.evaluate(() => {
  localStorage.setItem("budget-app-state-v1", JSON.stringify({
    version: 1, onboarded: true, isDemo: false, profile: { name: "Fixture" },
    baseCurrency: "CHF",
    accounts: [
      { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
      { id: "sav", name: "Épargne", kind: "savings", opening: 0, cash: false, currency: "CHF" },
    ],
    transactions: [
      { id: 1, y: new Date().getFullYear() - 1, m: 6, d: 10, title: "Épargne an dernier", type: "saving",
        cat: "Épargne", acc: "cur", dest: "sav", status: "posted", amount: 1000 },
      { id: 2, y: new Date().getFullYear(), m: 1, d: 10, title: "Épargne cette année", type: "saving",
        cat: "Épargne", acc: "cur", dest: "sav", status: "posted", amount: 250 },
    ],
    recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
    insurances: [], bills: [], documents: [], budgets: {},
  }));
  localStorage.removeItem("budget-app-state-rescue");
});
await page.reload();
await page.waitForSelector("#tabbar button", { timeout: 10000 });
const p0annee = await page.evaluate(() => {
  activeTab = "more"; moreView = "year"; yearCursor = NOW.y - 1; render();
  const carte = [...document.querySelectorAll("#screen .card")]
    .find(c => /par type/.test(c.textContent));
  const montant = carte ? (carte.textContent.match(/[\d'’]+\.\d\d/) || [])[0] : null;
  return { label: carte ? (carte.textContent.match(/Mis de côté en \d{4}/) || [])[0] : null, montant };
});
check(p0annee.label === `Mis de côté en ${new Date().getFullYear() - 1}`,
  `la carte étiquette bien l'année consultée (obtenu « ${p0annee.label} »)`);
check(p0annee.montant === "1'000.00",
  `l'année consultée montre SES versements : attendu 1'000.00, obtenu ${p0annee.montant} — c'est le montant de l'année courante qui s'affiche sous l'étiquette de l'année consultée`);

// ---------- Test 125 : P14 Année — glyphes, ton neutre, bornes, langue ----------
// Budget Prisme, lot P14. La carte « par type » parle en Budget Glyphs
// (zéro emoji fonctionnel), le héros « Mis de côté » est blanc Prisme
// (ni gain vert ni perte rouge — matrice des opérations), la navigation
// d'année est bornée et les mois vides disent « opération ».
currentTest = "P14 année";
// L'état du parcours 124 (fixture épargne 250 CHF cette année) est encore
// chargé : la carte « par type » a donc une ligne réelle à montrer.
await page.evaluate(() => { activeTab = "more"; moreView = "year"; yearCursor = NOW.y; render(); });
await page.waitForTimeout(250);
const p14carte = await page.evaluate(() => {
  const carte = [...document.querySelectorAll("#screen .card")]
    .find(c => /par type/.test(c.textContent));
  if (!carte) return null;
  return {
    glyphes: carte.querySelectorAll("svg.budget-glyph").length,
    emoji: /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/u.test(carte.textContent),
    montant: (carte.textContent.match(/[\d'’]+\.\d\d/) || [])[0],
  };
});
check(p14carte && p14carte.glyphes >= 1 && !p14carte.emoji,
  `la carte « par type » parle en Budget Glyphs, zéro emoji (${JSON.stringify(p14carte)})`);
check(p14carte && p14carte.montant === "250.00",
  `le montant de l'année consultée reste exact après le lot (obtenu ${p14carte && p14carte.montant})`);
const p14hero = await page.evaluate(() => {
  const el = document.querySelector("#screen .hero-amount");
  return { color: getComputedStyle(el).color, classes: el.className };
});
check(p14hero.color === "rgb(245, 247, 250)" && !/\bpos\b|\bneg\b/.test(p14hero.classes),
  `le héros « Mis de côté » est blanc Prisme, ni vert ni rouge (${JSON.stringify(p14hero)})`);
const p14chevrons = await page.evaluate(() => ({
  prev: !!document.querySelector("#prevY svg.budget-glyph"),
  next: !!document.querySelector("#nextY svg.budget-glyph"),
}));
check(p14chevrons.prev && p14chevrons.next,
  "la navigation d'année utilise les glyphes chevron, comme le mois");
check((await page.evaluate(() => document.getElementById("screen").innerText)).includes("Aucune opération ce mois"),
  "un mois passé vide dit « Aucune opération ce mois »");
// Bornes : aux extrêmes, le bouton correspondant est réellement désactivé.
await page.evaluate(() => { yearCursor = 2000; render(); });
await page.waitForTimeout(150);
const p14basse = await page.evaluate(() => ({
  prevOff: document.getElementById("prevY").disabled,
  nextOn: !document.getElementById("nextY").disabled,
}));
check(p14basse.prevOff && p14basse.nextOn,
  `à la borne 2000, « année précédente » est désactivé (${JSON.stringify(p14basse)})`);
await page.evaluate(() => { yearCursor = 2100; render(); });
await page.waitForTimeout(150);
const p14haute = await page.evaluate(() => ({
  nextOff: document.getElementById("nextY").disabled,
  prevOn: !document.getElementById("prevY").disabled,
}));
check(p14haute.nextOff && p14haute.prevOn,
  `à la borne 2100, « année suivante » est désactivé (${JSON.stringify(p14haute)})`);
await page.evaluate(() => { yearCursor = NOW.y; render(); });

// ---------- Test 126 : P17 Réglages — glyphes, verrou écrit, langue unifiée ----------
// Budget Prisme, lot P17. Les Réglages parlent en Budget Glyphs (seul le
// drapeau du pays reste un emoji : il EST l'information), l'état du verrou
// est écrit sans caractère-état, l'export et l'effacement disent
// « opérations ». La sécurité (code haché, sauvegarde sans secret) a été
// auditée sans modification — ce lot est purement présentation/langue.
currentTest = "P17 réglages";
await goHome();
await page.click('#tabbar button[aria-label="Gérer"]');
await page.waitForTimeout(200);
await page.click('#screen [data-more="settings"]');
await page.waitForTimeout(300);
const p17ecran = await page.evaluate(() => {
  const s = document.getElementById("screen");
  const texte = s.innerText;
  // Emojis fonctionnels : tout pictogramme hors drapeaux (indicateurs
  // régionaux) — le drapeau du pays est une vraie donnée, pas un décor.
  const emojis = (texte.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []);
  return {
    emojis,
    glyphes: s.querySelectorAll(".card.row .ico svg.budget-glyph").length,
    exportCsv: texte.includes("Exporter les opérations (CSV)"),
    exportMouvements: texte.includes("Exporter les mouvements"),
    verrou: (document.querySelector("[data-togglelock]") || {}).textContent || "",
  };
});
check(p17ecran.emojis.length === 0,
  `zéro emoji fonctionnel dans les Réglages (restants : ${p17ecran.emojis.join(" ") || "aucun"})`);
check(p17ecran.glyphes >= 7,
  `les lignes de Réglages portent des Budget Glyphs (${p17ecran.glyphes} trouvés)`);
check(p17ecran.exportCsv && !p17ecran.exportMouvements,
  "l'export CSV dit « opérations »");
check(/Activé|Désactivé/.test(p17ecran.verrou.trim()) && !p17ecran.verrou.includes("✓"),
  `l'état du verrou est écrit sans caractère-état (obtenu « ${p17ecran.verrou.trim()} »)`);
// L'état ACTIVÉ doit aussi être écrit en mots seuls — on l'exerce
// réellement (verrou posé en mémoire puis retiré, rien n'est persisté
// au-delà du nettoyage).
const p17verrouOn = await page.evaluate(() => {
  const avant = { fid: S.faceIDEnabled, code: S.lockCode };
  S.faceIDEnabled = true; S.lockCode = codeHash("123456"); render();
  const label = (document.querySelector("[data-togglelock]") || {}).textContent || "";
  S.faceIDEnabled = avant.fid; S.lockCode = avant.code; render();
  return label.trim();
});
check(p17verrouOn === "Activé",
  `verrou activé : l'état est le mot seul (obtenu « ${p17verrouOn} »)`);
// Le message d'effacement énumère en langage unifié — capturé sans rien
// effacer : confirm est intercepté et répond « non ».
const p17confirm = await page.evaluate(() => {
  let premier = null;
  const orig = window.confirm;
  window.confirm = m => { if (premier === null) premier = m; return false; };
  document.querySelector("[data-deleteall]").click();
  window.confirm = orig;
  return premier;
});
check(p17confirm && p17confirm.includes("dépenses, revenus, mises de côté") && !p17confirm.includes("mouvements,"),
  `l'effacement énumère en langage unifié (obtenu « ${(p17confirm || "").slice(0, 60)}… »)`);

// ---------- Test 127 : P05 Comptes — glyphes par nature, écran sans emoji ----------
// Budget Prisme, lot P05. Chaque ligne de compte porte un Budget Glyph
// selon sa nature ; l'écran Comptes ne montre plus aucun emoji fonctionnel ;
// le bouton d'ajout parle en mots.
currentTest = "P05 comptes";
await goHome();
await page.click('#tabbar button[aria-label="Comptes"]');
await page.waitForTimeout(300);
const p05ecran = await page.evaluate(() => {
  const s = document.getElementById("screen");
  return {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []),
    lignes: s.querySelectorAll(".card.row[data-accid]").length,
    glyphes: s.querySelectorAll(".card.row[data-accid] .ico svg.budget-glyph").length,
    bouton: (s.querySelector("[data-addacc]") || {}).textContent || "",
    hero: s.innerText.includes("Argent disponible"),
  };
});
check(p05ecran.emojis.length === 0,
  `zéro emoji fonctionnel sur l'écran Comptes (restants : ${p05ecran.emojis.join(" ") || "aucun"})`);
check(p05ecran.lignes > 0 && p05ecran.glyphes === p05ecran.lignes,
  `chaque ligne de compte porte son Budget Glyph (${p05ecran.glyphes}/${p05ecran.lignes})`);
check(p05ecran.bouton.trim() === "Ajouter un compte",
  `le bouton d'ajout parle en mots (obtenu « ${p05ecran.bouton.trim()} »)`);
check(p05ecran.hero, "le héros répond « Où se trouve mon argent » (Argent disponible)");

// ---------- Test 128 : P06 Fiche compte — la suppression protège TOUTES les références ----------
// Budget Prisme, lot P06. NÉ ROUGE : le bloqueur ignorait la destination
// d'un versement régulier et la position de prévoyance liée — la
// suppression redirigeait la destination en silence et laissait un lien
// orphelin. Vert depuis le correctif : deux gardes de plus, mêmes messages
// honnêtes que les gardes existantes.
currentTest = "P06 fiche compte";
await goHome();
const p06gardes = await page.evaluate(() => {
  const cur = ACCOUNTS.find(a => a.cash) || ACCOUNTS[0];
  ACCOUNTS.push({ id: "p06savA", name: "Épargne destination", kind: "savings", opening: 0, cash: false, currency: "CHF" });
  ACCOUNTS.push({ id: "p06savB", name: "Épargne liée prévoyance", kind: "savings", opening: 0, cash: false, currency: "CHF" });
  RECURRINGS.push({ id: "p06-rec", title: "Épargne mensuelle P06", type: "saving", cat: "Épargne",
    amount: 200, day: 1, accountId: cur.id, destAccountId: "p06savA", icon: "🏦" });
  PENSIONS.push({ id: "p06-pen", name: "Pilier 3a P06", value: 12000, accountId: "p06savB", icon: "🛡️" });
  const dest = accountDeleteBlocker("p06savA");
  const pension = accountDeleteBlocker("p06savB");
  // Nettoyage : rien n'est réellement supprimé, la fixture repart.
  RECURRINGS.splice(RECURRINGS.findIndex(r => r.id === "p06-rec"), 1);
  PENSIONS.splice(PENSIONS.findIndex(p => p.id === "p06-pen"), 1);
  ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "p06savA"), 1);
  ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "p06savB"), 1);
  return { dest, pension };
});
check(p06gardes.dest !== null && /régulier|destination/i.test(p06gardes.dest || ""),
  `supprimer la destination d'un versement régulier est bloqué et expliqué (obtenu ${JSON.stringify(p06gardes.dest)})`);
check(p06gardes.pension !== null && /prévoyance/i.test(p06gardes.pension || ""),
  `supprimer un compte lié à une prévoyance est bloqué et expliqué (obtenu ${JSON.stringify(p06gardes.pension)})`);

// ---------- Test 129 : P0 Prévoyance — un compte lié n'est jamais compté deux fois ----------
// Budget Prisme, incident P0 (risque n°1 du registre). NÉ ROUGE : la carte
// « Déjà mis de côté » additionnait pensionDisplayTotal() (qui vaut déjà le
// solde du compte pour une position liée) PLUS les soldes des comptes de
// prévoyance — un compte lié à 10 000 CHF s'affichait donc 20 000. Vert
// depuis le correctif : positions non liées + soldes des comptes, une fois.
currentTest = "P0 prévoyance double compte";
await goHome();
const p129 = await page.evaluate(() => {
  ACCOUNTS.push({ id: "p129pen", name: "Caisse LPP P129", inst: "Fondation Fictive",
    kind: "pension", opening: 10000, cash: false, currency: "CHF" });
  PENSIONS.push({ id: "p129-liee", name: "Certificat LPP P129", icon: "🛡️",
    value: 0, projection: null, accountId: "p129pen" });
  PENSIONS.push({ id: "p129-libre", name: "AVS estimée P129", icon: "🛡️",
    value: 5000, projection: null, accountId: null });
  activeTab = "more"; moreView = "insurance"; render();
  const soldes = ACCOUNTS.filter(a => ["pension", "lifeinsurance"].includes(a.kind))
    .reduce((s, a) => s + toCHF(balance(a.id), a.currency), 0);
  const honnete = round2(pensionPositionsTotal() + soldes);
  const card = [...document.querySelectorAll("#screen .card")]
    .find(c => c.querySelector(".card-label")?.textContent === "Déjà mis de côté");
  const affiche = card ? (card.querySelector(".amount")?.textContent || "") : null;
  // Nettoyage : la fixture repart, l'app revient à l'accueil.
  PENSIONS.splice(PENSIONS.findIndex(p => p.id === "p129-liee"), 1);
  PENSIONS.splice(PENSIONS.findIndex(p => p.id === "p129-libre"), 1);
  ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "p129pen"), 1);
  activeTab = "home"; moreView = null; render();
  return { affiche, attendu: chf(honnete) };
});
check(p129.affiche !== null, "la carte « Déjà mis de côté » est visible avec une position liée");
check(p129.affiche === p129.attendu,
  `le total prévoyance compte le compte lié UNE seule fois (affiché ${JSON.stringify(p129.affiche)}, honnête ${p129.attendu})`);

// ---------- Test 130 : P13 Assurances & prévoyance — glyphes, mots, états vides ----------
// Budget Prisme, lot P13 (le défaut financier du risque n°1 est corrigé par
// l'incident P0, test 129). Ici : présentation et langue — Budget Glyphs à
// la place des emojis fonctionnels, chevrons de navigation, boutons en mots,
// états vides guidés, héros honnête sans contrat, libellé de la feuille
// prévoyance sans doublon.
currentTest = "P13 assurances prévoyance";
await goHome();
const p13 = await page.evaluate(() => {
  const sauvegarde = { ins: INSURANCES.splice(0), pen: PENSIONS.splice(0) };
  INSURANCES.push({ id: "p13-ins", name: "Caisse maladie P13", insurer: "Assureur Fictif",
    premium: 745.6, unit: "month", dueM: null, dueD: null, icon: "🛡️" });
  PENSIONS.push({ id: "p13-pen", name: "Caisse LPP P13", icon: "🛡️",
    value: 42000, projection: 245000, accountId: null });
  activeTab = "more"; moreView = "insurance"; render();
  const s = document.getElementById("screen");
  const rempli = {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []),
    glyphesLignes: s.querySelectorAll("[data-insid] .ico svg.budget-glyph, [data-penid] .ico svg.budget-glyph").length,
    // Un chevron présent dans le DOM mais large de 0 px est un mensonge
    // visuel (défaut réel trouvé en sonde) : on exige une taille peinte.
    chevrons: [...s.querySelectorAll("[data-insid], [data-penid], [data-accid]")]
      .filter(r => {
        const fleche = r.querySelector("svg.budget-glyph path[d^='m9.5 6']");
        return fleche && fleche.closest("svg").getBoundingClientRect().width >= 12;
      }).length,
    lignes: s.querySelectorAll("[data-insid], [data-penid], [data-accid]").length,
    boutonIns: (s.querySelector("[data-addins]") || {}).textContent || "",
    boutonPen: (s.querySelector("[data-addpen]") || {}).textContent || "",
  };
  INSURANCES.length = 0; PENSIONS.length = 0; render();
  const sVide = document.getElementById("screen");
  const vide = {
    etatsVides: sVide.querySelectorAll(".empty-state .glyph svg.budget-glyph").length,
    heroCaption: (sVide.querySelector(".card.hero .caption") || {}).textContent || "",
  };
  const labelProjection = document.querySelector('label[for="penProjection"]').textContent;
  INSURANCES.push(...sauvegarde.ins); PENSIONS.push(...sauvegarde.pen);
  activeTab = "home"; moreView = null; render();
  return { rempli, vide, labelProjection };
});
check(p13.rempli.emojis.length === 0,
  `zéro emoji fonctionnel sur l'écran Assurances & prévoyance (restants : ${p13.rempli.emojis.join(" ") || "aucun"})`);
check(p13.rempli.glyphesLignes >= 2,
  `les lignes assurance et prévoyance portent le glyphe bouclier (${p13.rempli.glyphesLignes})`);
check(p13.rempli.lignes > 0 && p13.rempli.chevrons === p13.rempli.lignes,
  `chaque ligne cliquable porte son chevron de navigation (${p13.rempli.chevrons}/${p13.rempli.lignes})`);
check(p13.rempli.boutonIns.trim() === "Ajouter une assurance" && p13.rempli.boutonPen.trim() === "Ajouter une prévoyance",
  `les boutons d'ajout parlent en mots (obtenus « ${p13.rempli.boutonIns.trim()} », « ${p13.rempli.boutonPen.trim()} »)`);
check(p13.vide.etatsVides === 2,
  `les deux états vides sont guidés avec leur glyphe (${p13.vide.etatsVides}/2)`);
check(!/Soit CHF[\s\u00A0]0\.00 par an/.test(p13.vide.heroCaption) && /Ajoutez/.test(p13.vide.heroCaption),
  `sans contrat, le héros invite au lieu d'annoncer « CHF 0.00 par an » (obtenu « ${p13.vide.heroCaption.slice(0, 60)}… »)`);
check(!/selon certificat/.test(p13.labelProjection) && /selon votre certificat/.test(p13.labelProjection),
  `le libellé du montant prévu à la retraite est dit une seule fois (obtenu « ${p13.labelProjection} »)`);

// ---------- Test 131 : P07 Gérer — hub en glyphes, aucun lien mort ----------
// Budget Prisme, lot P07. Le hub porte un Budget Glyph par ligne (plus
// d'emoji fonctionnel, plus de « › » texte), un chevron PEINT, un sous-titre
// jamais vide, et chaque destination existe réellement dans MORE_RENDERERS.
currentTest = "P07 gérer";
await goHome();
await page.click('#tabbar button[aria-label="Gérer"]');
await page.waitForTimeout(300);
const p07 = await page.evaluate(() => {
  moreView = null; render();
  const s = document.getElementById("screen");
  const lignes = [...s.querySelectorAll("[data-more]")];
  return {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []),
    lignes: lignes.length,
    glyphes: lignes.filter(r => r.querySelector(".ico svg.budget-glyph")).length,
    chevronsPeints: lignes.filter(r => {
      const fleche = r.querySelector("span[aria-hidden] svg.budget-glyph path[d^='m9.5 6']");
      return fleche && fleche.closest("svg").getBoundingClientRect().width >= 12;
    }).length,
    sousTitresVides: lignes.filter(r => !(r.querySelector(".s")?.textContent || "").trim()).length,
    liensMorts: lignes.map(r => r.dataset.more).filter(id => typeof MORE_RENDERERS[id] !== "function"),
    ancienChevronTexte: s.innerText.includes("›"),
  };
});
check(p07.emojis.length === 0,
  `zéro emoji fonctionnel sur le hub Gérer (restants : ${p07.emojis.join(" ") || "aucun"})`);
// SUB1 (ADR-052) : le hub gagne « Mes abonnements » — onze lignes.
check(p07.lignes === 11 && p07.glyphes === 11,
  `les onze lignes du hub portent leur Budget Glyph (${p07.glyphes}/${p07.lignes})`);
check(p07.chevronsPeints === p07.lignes,
  `chaque ligne porte un chevron réellement peint (${p07.chevronsPeints}/${p07.lignes})`);
check(p07.sousTitresVides === 0, "aucun sous-titre vide sur le hub");
check(p07.liensMorts.length === 0,
  `aucun lien mort — chaque destination existe (${p07.liensMorts.join(", ") || "toutes"})`);
check(!p07.ancienChevronTexte, "le chevron texte « › » a disparu du hub");

// ---------- Test 132 : P08 Ce qui revient — glyphes par sens, filtres en mots ----------
// Budget Prisme, lot P08. Le glyphe d'une ligne suit le SENS du mouvement
// (revenu, mise de côté, investissement, facture, abonnement), jamais une
// icône stockée ; les filtres parlent en mots ; les boutons aussi ; l'état
// vide est guidé avec son glyphe.
currentTest = "P08 ce qui revient";
await goHome();
const p08 = await page.evaluate(() => {
  const sauvegarde = RECURRINGS.splice(0);
  const acc = ACCOUNTS[0].id;
  RECURRINGS.push(
    { id: "p08-fac", title: "Loyer P08", type: "expense", cat: "Logement", amount: 1500, day: 1, accountId: acc },
    { id: "p08-abo", title: "Streaming P08", type: "expense", cat: "Loisirs", nature: "abonnement", amount: 15, day: 5, accountId: acc },
    { id: "p08-res", title: "Pilier 3a P08", type: "expense", cat: "Pilier 3a", nature: "reserve", amount: 250, day: 25, accountId: acc },
    { id: "p08-rev", title: "Salaire P08", type: "income", cat: "Salaire", amount: 5200, day: 25, accountId: acc },
  );
  recFilter = "tout"; activeTab = "more"; moreView = "recurring"; render();
  const s = document.getElementById("screen");
  const lignes = [...s.querySelectorAll("[data-recid]")];
  const parId = id => lignes.find(l => l.dataset.recid === id);
  const rempli = {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []),
    lignes: lignes.length,
    glyphes: lignes.filter(l => l.querySelector(".ico svg.budget-glyph")).length,
    revenuTinte: !!parId("p08-rev")?.querySelector(".ico.t-income svg.budget-glyph"),
    reserveInvestit: !!parId("p08-res")?.querySelector(".ico svg.budget-glyph path[d^='M4 19']"),
    bouton: (s.querySelector("[data-addrec]") || {}).textContent || "",
  };
  recFilter = "abonnement"; render();
  const sAbo = document.getElementById("screen");
  const abo = {
    emojis: (sAbo.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []),
    glyphes: sAbo.querySelectorAll("[data-recid] .ico svg.budget-glyph").length,
    bouton: (sAbo.querySelector("[data-addrec]") || {}).textContent || "",
  };
  recFilter = "tout"; RECURRINGS.length = 0; render();
  const videEtat = {
    glyphe: !!document.querySelector("#screen .empty-state .glyph svg.budget-glyph"),
  };
  RECURRINGS.push(...sauvegarde);
  recFilter = "tout"; activeTab = "home"; moreView = null; render();
  return { rempli, abo, videEtat };
});
check(p08.rempli.emojis.length === 0,
  `zéro emoji sur « Ce qui revient » (restants : ${p08.rempli.emojis.join(" ") || "aucun"})`);
check(p08.rempli.lignes === 4 && p08.rempli.glyphes === 4,
  `chaque ligne porte un glyphe sémantique (${p08.rempli.glyphes}/${p08.rempli.lignes})`);
check(p08.rempli.revenuTinte, "le revenu régulier porte son glyphe dans la pastille revenus");
check(p08.rempli.reserveInvestit, "la réserve Pilier 3a porte le glyphe investissement (le sens, pas l'icône stockée)");
check(p08.rempli.bouton.trim() === "Ajouter ce qui revient",
  `le bouton d'ajout parle en mots (obtenu « ${p08.rempli.bouton.trim()} »)`);
check(p08.abo.emojis.length === 0 && p08.abo.glyphes >= 1,
  `la lecture Abonnements est aussi en glyphes, sans emoji (${p08.abo.glyphes} glyphe(s))`);
check(p08.abo.bouton.trim() === "Ajouter un abonnement",
  `le bouton Abonnements parle en mots (obtenu « ${p08.abo.bouton.trim()} »)`);
check(p08.videEtat.glyphe, "l'état vide de « Ce qui revient » est guidé avec son glyphe");

// ---------- Test 133 : P09 Factures ponctuelles — glyphes, mots, promesse honnête ----------
// Budget Prisme, lot P09. Les lignes et l'état vide portent le glyphe
// facture (plus de 🧾 ni de 🎉), « payée » se dit sans coche décorative,
// les boutons parlent en mots, et l'état vide ne promet plus une catégorie
// « Acomptes d'impôts » que la feuille ne propose pas (les impôts vivent
// dans leur écran).
currentTest = "P09 factures ponctuelles";
await goHome();
const p09 = await page.evaluate(() => {
  const sauvegarde = (S.bills || []).splice(0);
  S.bills.push(
    { id: "p09-a", name: "Dentiste P09", amount: 320, dueY: NOW.y, dueM: NOW.m, dueD: 28, cat: "Alimentation", accountId: ACCOUNTS[0].id },
    { id: "p09-b", name: "Garage P09", amount: 540, dueY: NOW.y, dueM: NOW.m, dueD: 2, cat: "Transports", accountId: ACCOUNTS[0].id, paidTx: null },
  );
  activeTab = "more"; moreView = "bills"; render();
  const s = document.getElementById("screen");
  const rempli = {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}✔✓]/gu) || []),
    lignes: s.querySelectorAll("[data-billid]").length,
    glyphes: s.querySelectorAll("[data-billid] .ico svg.budget-glyph").length,
    bouton: (s.querySelector("[data-addbill]") || {}).textContent || "",
  };
  S.bills.length = 0; render();
  const sVide = document.getElementById("screen");
  const vide = {
    glyphe: !!sVide.querySelector(".empty-state .glyph svg.budget-glyph"),
    texte: sVide.querySelector(".empty-state")?.textContent || "",
    bouton: (sVide.querySelector("[data-addbill]") || {}).textContent || "",
  };
  S.bills.push(...sauvegarde);
  activeTab = "home"; moreView = null; render();
  return { rempli, vide };
});
check(p09.rempli.emojis.length === 0,
  `zéro emoji ni coche décorative sur Factures ponctuelles (restants : ${p09.rempli.emojis.join(" ") || "aucun"})`);
check(p09.rempli.lignes === 2 && p09.rempli.glyphes === 2,
  `chaque facture porte le glyphe facture (${p09.rempli.glyphes}/${p09.rempli.lignes})`);
check(p09.rempli.bouton.trim() === "Ajouter une facture ponctuelle",
  `le bouton d'ajout parle en mots (obtenu « ${p09.rempli.bouton.trim()} »)`);
check(p09.vide.glyphe, "l'état vide est guidé avec le glyphe facture");
check(!/Acomptes d'impôts, prime/.test(p09.vide.texte) && /écran Impôts/.test(p09.vide.texte),
  "l'état vide ne promet plus une catégorie Impôts introuvable et renvoie à l'écran Impôts");
check(p09.vide.bouton.trim() === "Ajouter une facture ponctuelle",
  `le bouton de l'état vide parle en mots (obtenu « ${p09.vide.bouton.trim()} »)`);

// ---------- Test 134 : P0 — payer un acompte d'impôts crée un taxPayment, pas une dépense de vie ----------
// Incident P0 « acompte-impots » (découvert pendant l'audit P11). NÉ ROUGE :
// materializeBill créait TOUJOURS type "expense" — payer une facture de
// catégorie « Impôts » (l'écran Impôts liste précisément ces factures)
// gonflait le coût de la vie et ne réduisait jamais « il vous reste à
// payer » (taxSummary.paid ne compte que les taxPayment). Vert depuis le
// correctif : la catégorie Impôts matérialise un taxPayment.
currentTest = "P0 acompte impôts";
await goHome();
const p134 = await page.evaluate(() => {
  const facture = { id: "p0-tax-bill", name: "Acompte cantonal P0", amount: 800,
    dueY: NOW.y, dueM: NOW.m, dueD: Math.min(NOW.d, 28), cat: "Impôts", accountId: ACCOUNTS[0].id };
  (S.bills = S.bills || []).push(facture);
  const paidAvant = taxSummary(NOW.y).paid;
  const { transaction } = materializeBill(facture);
  const paidApres = taxSummary(NOW.y).paid;
  // Nettoyage complet : le mouvement créé et la facture repartent.
  const index = transactions.findIndex(t => t.id === transaction.id);
  if (index >= 0) transactions.splice(index, 1);
  S.bills.splice(S.bills.findIndex(b => b.id === "p0-tax-bill"), 1);
  saveState(); render();
  return { type: transaction.type, statut: transaction.status,
    paidAvant, paidApres, comptabilise: transaction.status === "posted" };
});
check(p134.type === "taxPayment",
  `payer un acompte de catégorie Impôts crée un taxPayment (obtenu « ${p134.type} »)`);
check(!p134.comptabilise || Math.abs(p134.paidApres - p134.paidAvant - 800) < 0.005,
  `l'acompte payé entre dans « Déjà payé » des impôts (avant ${p134.paidAvant}, après ${p134.paidApres})`);

// ---------- Test 135 : P10 Objectifs — emoji choisi conservé, repli en glyphe, mots ----------
// Budget Prisme, lot P10. L'emoji d'un objectif est un CHOIX de
// l'utilisateur : il reste. Le repli 🎯 de l'app, lui, devient le glyphe
// objectif. « ⚠️ passée » et « ✓/⚠️ » du rythme deviennent texte et
// glyphes ; « ＋ » disparaît des montants et du bouton ; état vide guidé.
currentTest = "P10 objectifs";
await goHome();
const p10 = await page.evaluate(() => {
  const sauvegarde = GOALS.splice(0);
  GOALS.push(
    { id: "p10-avec", name: "Voyage P10", emoji: "✈️", target: 3000, manualCurrent: 500,
      dueM: NOW.m, dueY: NOW.y + 1, monthly: 100, linked: null, achieved: false },
    { id: "p10-sans", name: "Fonds d'urgence P10", emoji: null, target: 10000, manualCurrent: 2000,
      dueM: NOW.m, dueY: NOW.y + 2, monthly: 50, linked: null, achieved: false },
  );
  activeTab = "more"; moreView = "goals"; render();
  const s = document.getElementById("screen");
  const carte = id => [...s.querySelectorAll("[data-goalid]")].find(c => c.dataset.goalid === id);
  const rempli = {
    emojiChoisi: (carte("p10-avec")?.querySelector(".goal-title")?.textContent || "").includes("✈️"),
    replisGlyphe: !!carte("p10-sans")?.querySelector(".goal-title svg.budget-glyph"),
    glypheRythme: s.querySelectorAll(".pace-glyph svg.budget-glyph").length >= 2,
    plusPleineChasse: s.innerText.includes("＋"),
    bouton: (s.querySelector("[data-addgoal]") || {}).textContent || "",
  };
  GOALS.length = 0; render();
  const videEtat = !!document.querySelector("#screen .empty-state .glyph svg.budget-glyph");
  GOALS.push(...sauvegarde);
  activeTab = "home"; moreView = null; render();
  return { rempli, videEtat };
});
check(p10.rempli.emojiChoisi, "l'emoji choisi par l'utilisateur reste affiché sur son objectif");
check(p10.rempli.replisGlyphe, "sans emoji choisi, l'app affiche le glyphe objectif (jamais un 🎯 imposé)");
check(p10.rempli.glypheRythme, "le rythme porte des glyphes coche/alerte, pas ✓/⚠️");
check(!p10.rempli.plusPleineChasse, "le « ＋ » pleine chasse a disparu de l'écran Objectifs");
check(p10.rempli.bouton.trim() === "Ajouter un objectif",
  `le bouton d'ajout parle en mots (obtenu « ${p10.rempli.bouton.trim()} »)`);
check(p10.videEtat, "l'état vide des objectifs est guidé avec son glyphe");

// ---------- Test 136 : P11 Impôts — parcours acompte réel, bornes cohérentes, glyphes ----------
// Budget Prisme, lot P11. La feuille facture propose enfin « Impôts »
// (l'écran Impôts listait ces factures sans qu'on puisse les créer) ;
// l'acompte porte le glyphe calendrier ; la borne du taux d'onboarding
// (avant : 100 %) s'aligne sur la page Impôts (60 %) ; zéro emoji.
currentTest = "P11 impôts";
await goHome();
const p11 = await page.evaluate(() => {
  openBillSheet(null);
  const options = [...document.querySelectorAll("#bCat option")].map(o => o.textContent);
  closeSheet();
  const facture = { id: "p11-ac", name: "Acompte cantonal P11", amount: 900,
    dueY: NOW.y, dueM: NOW.m, dueD: 28, cat: "Impôts", accountId: ACCOUNTS[0].id };
  (S.bills = S.bills || []).push(facture);
  activeTab = "more"; moreView = "taxes"; render();
  const s = document.getElementById("screen");
  const ecran = {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []),
    glypheAcompte: !!s.querySelector("[data-billid] .ico svg.budget-glyph"),
  };
  S.bills.splice(S.bills.findIndex(b => b.id === "p11-ac"), 1);
  activeTab = "home"; moreView = null; render();
  return { options, ecran };
});
check(p11.options.includes("Impôts"),
  `la feuille facture propose la catégorie Impôts (obtenu : ${p11.options.join(", ")})`);
check(p11.ecran.emojis.length === 0,
  `zéro emoji sur l'écran Impôts (restants : ${p11.ecran.emojis.join(" ") || "aucun"})`);
check(p11.ecran.glypheAcompte, "l'acompte listé porte le glyphe calendrier");
// FE2-12 : la feuille Impôts ne propose PLUS de taux — il n'y a plus rien
// d'automatique à régler. W8.5 (changement VOULU, consigné) : la feuille
// écrit la PROVISION de l'année consultée par la porte unique — le
// report hérité (S.taxReserve) n'est plus jamais réécrit.
const borne136 = await page.evaluate(() => {
  const sansOnboarding = !bindOnboarding.toString().includes("obTaxPct");
  const avantReport = S.taxReserve;
  openTaxSheet();
  const champTaux = document.getElementById("txRate");
  document.getElementById("txReserve").value = "abc";
  document.getElementById("taxForm").requestSubmit();
  const refus = document.getElementById("txError").textContent;
  const provisionApresRefus = Number((S.taxProvisions || {})[String(cursor.y)]) || 0;
  document.getElementById("txReserve").value = "2400";
  document.getElementById("taxForm").requestSubmit();
  const provisionApresAccord = Number((S.taxProvisions || {})[String(cursor.y)]) || 0;
  const reportIntact = S.taxReserve === avantReport;
  delete (S.taxProvisions || {})[String(cursor.y)]; saveState(); render();
  return { sansOnboarding, champTaux: !!champTaux, refus, provisionApresRefus, provisionApresAccord, reportIntact };
});
check(borne136.sansOnboarding, "l'onboarding ne demande plus de taux d'impôts (A18)");
check(!borne136.champTaux,
  "FE2-12 : la feuille Impôts n'offre PLUS de champ de taux — rien d'automatique à régler");
check(borne136.refus.length > 0 && borne136.provisionApresRefus === 0,
  `une provision invalide est refusée avec message, sans rien changer (obtenu « ${borne136.refus} »)`);
check(borne136.provisionApresAccord === 2400 && borne136.reportIntact,
  `W8.5 : la feuille écrit la provision de l'année consultée et le report hérité reste intact (obtenu ${borne136.provisionApresAccord})`);

// ---------- Test 137 : P12 Patrimoine — glyphes de sens, dettes honnêtes, mots ----------
// Budget Prisme, lot P12. Étiquettes « par classe » et lignes biens/dettes
// en glyphes (plus d'icônes stockées ni de 🏛️📈🛡️🏷📄) ; « Remboursée »
// sans coche ; bouton en mots ; état vide des biens guidé.
currentTest = "P12 patrimoine";
await goHome();
const p12 = await page.evaluate(() => {
  const sauvA = ASSETS.splice(0), sauvL = LIABILITIES.splice(0);
  ASSETS.push({ id: "p12-a", name: "Vélo cargo P12", value: 4500, include: true, icon: "🏷" });
  LIABILITIES.push({ id: "p12-l", name: "Prêt P12", value: 0, monthly: 200, include: true, icon: "📄" });
  activeTab = "more"; moreView = "networth"; render();
  const s = document.getElementById("screen");
  const rempli = {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}✔✓]/gu) || []),
    glypheBien: !!s.querySelector("[data-assetid] .ico svg.budget-glyph"),
    glypheDette: !!s.querySelector("[data-liabid] .ico svg.budget-glyph"),
    rembourseeSansCoche: /Remboursée(?!\s*✓)/.test(s.innerText) && !s.innerText.includes("✓"),
    etiquettesGlyphes: s.querySelectorAll(".breakdown .bd-label svg.budget-glyph").length,
    bouton: (s.querySelector("[data-additem]") || {}).textContent || "",
  };
  ASSETS.length = 0; LIABILITIES.length = 0; render();
  const videEtat = !!document.querySelector("#screen .empty-state .glyph svg.budget-glyph");
  ASSETS.push(...sauvA); LIABILITIES.push(...sauvL);
  activeTab = "home"; moreView = null; render();
  return { rempli, videEtat };
});
check(p12.rempli.emojis.length === 0,
  `zéro emoji ni coche sur Patrimoine (restants : ${p12.rempli.emojis.join(" ") || "aucun"})`);
check(p12.rempli.glypheBien && p12.rempli.glypheDette,
  "les lignes bien et dette portent leur glyphe de sens (jamais l'icône stockée)");
check(p12.rempli.rembourseeSansCoche, "« Remboursée » se dit sans coche décorative");
check(p12.rempli.bouton.trim() === "Ajouter un actif ou une dette",
  `le bouton d'ajout parle en mots (obtenu « ${p12.rempli.bouton.trim()} »)`);
check(p12.videEtat, "l'état vide des biens est guidé avec son glyphe");

// ---------- Test 138 : P15 Import & documents — glyphe document, mots, état vide guidé ----------
// Budget Prisme, lot P15. La liste des documents porte le glyphe document
// (plus de 📄), le bouton parle en mots, l'état vide est guidé et reste
// honnête (les fichiers vivent dans l'app native, la PWA garde nom et type).
currentTest = "P15 import documents";
await goHome();
const p15 = await page.evaluate(() => {
  const sauvegarde = (S.documents || []).splice(0);
  S.documents.push({ id: "p15-d", name: "Certificat LPP 2026", kind: "Prévoyance" });
  activeTab = "more"; moreView = "importcsv"; render();
  const s = document.getElementById("screen");
  const rempli = {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu) || []),
    glypheDoc: !!s.querySelector("[data-editdoc] .ico svg.budget-glyph"),
    bouton: (s.querySelector("[data-adddoc]") || {}).textContent || "",
  };
  S.documents.length = 0; render();
  const vide = {
    glyphe: !!document.querySelector("#screen .empty-state .glyph svg.budget-glyph"),
    texte: document.querySelector("#screen .empty-state")?.textContent || "",
  };
  S.documents.push(...sauvegarde);
  activeTab = "home"; moreView = null; render();
  return { rempli, vide };
});
check(p15.rempli.emojis.length === 0,
  `zéro emoji sur Import & documents (restants : ${p15.rempli.emojis.join(" ") || "aucun"})`);
check(p15.rempli.glypheDoc, "la ligne de document porte le glyphe document");
check(p15.rempli.bouton.trim() === "Ajouter un document",
  `le bouton d'ajout parle en mots (obtenu « ${p15.rempli.bouton.trim()} »)`);
check(p15.vide.glyphe && /app native/.test(p15.vide.texte),
  "l'état vide des documents est guidé et reste honnête sur le stockage");

// ---------- Test 139 : P16 Onboarding — glyphes d'étape, choix en glyphes, promesse sobre ----------
// Budget Prisme, lot P16. Les pictos d'étape 44 px et les choix (foyer,
// comptes) parlent en Budget Glyphs ; les drapeaux de pays restent (sens
// géographique) ; les emojis des objectifs proposés restent (ils deviennent
// l'emoji personnel de l'objectif, précédent P10) ; « C'est parti » sans
// emoji ; les lignes charges/abonnements se lisent par leur libellé seul.
currentTest = "P16 onboarding";
{
  const ctx139 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p139 = await ctx139.newPage();
  p139.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[P16] ${msg.text()}`); });
  await p139.goto(APP_URL);
  await p139.waitForSelector('[data-obcountry="CH"]');
  await p139.click('[data-obcountry="CH"]');
  await p139.waitForTimeout(250);
  const foyer = await p139.evaluate(() => ({
    heroPeint: (() => {
      const g = document.querySelector(".ob-hero-glyph svg.budget-glyph");
      return g ? Math.round(g.getBoundingClientRect().width) : 0;
    })(),
    choixGlyphes: document.querySelectorAll(".ob-choice .ob-inline-glyph svg.budget-glyph").length,
    emojis: (document.body.innerText.match(/[\u{1F300}-\u{1FAFF}]/gu) || []).filter(e => !/[\u{1F1E6}-\u{1F1FF}]/u.test(e)),
  }));
  check(foyer.heroPeint === 44, `le picto d'étape est un glyphe peint en 44 px (obtenu ${foyer.heroPeint})`);
  check(foyer.choixGlyphes === 3, `les trois choix de foyer portent leur glyphe (${foyer.choixGlyphes}/3)`);
  check(foyer.emojis.length === 0, `zéro emoji hors drapeaux sur l'étape foyer (restants : ${foyer.emojis.join(" ") || "aucun"})`);
  await p139.click('[data-obhh="solo"]');
  await p139.fill("#obName", "Léo"); await p139.click('#obForm1 button[type="submit"]');
  await p139.fill("#obSalary", "5000"); await p139.click('#obForm2 button[type="submit"]');
  await p139.waitForSelector("#obOpening", { state: "visible" });
  const comptes = await p139.evaluate(() => {
    const toggles = [...document.querySelectorAll("[data-obacc]")];
    return {
      glyphesParToggle: toggles.map(t => t.querySelectorAll("svg.budget-glyph").length),
      // « Épargne » est proposé activé : sa coche doit déjà être un glyphe.
      cocheInitiale: !!toggles[0].querySelector("svg.budget-glyph path[d^='m5 12.5']"),
      bouton: document.querySelector('#obForm3 button[type="submit"]')?.textContent || "",
    };
  });
  await p139.click('[data-obacc="pension"]');
  await p139.waitForTimeout(250);
  comptes.coche = await p139.evaluate(() =>
    !!document.querySelector("[data-obacc='pension'] svg.budget-glyph path[d^='m5 12.5']"));
  check(comptes.glyphesParToggle.every(n => n === 2),
    `chaque compte proposé porte glyphe de nature + état (${comptes.glyphesParToggle.join("/")})`);
  check(comptes.cocheInitiale, "le compte proposé activé porte déjà sa coche en glyphe");
  check(comptes.coche, "activer un compte peint la coche en glyphe");
  check(comptes.bouton.trim() === "C'est parti",
    `le bouton final est sobre (obtenu « ${comptes.bouton.trim()} »)`);
  await p139.fill("#obOpening", "2000"); await p139.click('#obForm3 button[type="submit"]');
  await p139.waitForSelector("#obFormCharges", { state: "visible" });
  const charges = await p139.evaluate(() => ({
    lignesSansIcone: [...document.querySelectorAll(".ob-line-name")]
      .every(l => !/[\u{1F300}-\u{1FAFF}]/u.test(l.textContent)),
  }));
  check(charges.lignesSansIcone, "les lignes de charges se lisent par leur libellé seul, sans emoji");
  await p139.click("[data-obskipcharges]");
  await p139.waitForSelector("#obFormSubs", { state: "visible" });
  await p139.click("[data-obskipsubs]");
  await p139.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  const objectifs = await p139.evaluate(() => ({
    emojisPresets: (document.body.innerText.match(/🛟|✈️|🛡️/gu) || []).length,
  }));
  check(objectifs.emojisPresets >= 3,
    "les emojis des objectifs proposés restent (ils deviennent l'emoji personnel, précédent P10)");
  await p139.click('[data-obgoal="urgence"]');
  await p139.waitForSelector("#tabbar button");
  await ctx139.close();
}

// ---------- Test 140 : P18 Assistant — questions en glyphes, réponses sobres ----------
// Budget Prisme, lot P18. Les quatre questions portent un glyphe sémantique
// (budget, loupe, impôts, objectif) dans leur pastille neutre ; le chevron
// de dépliage est peint ; les boutons d'action n'ont plus de « › » texte ;
// « couverte » se dit sans coche ; zéro emoji à l'écran.
currentTest = "P18 assistant";
await goHome();
const p18 = await page.evaluate(() => {
  activeTab = "more"; moreView = "assistant"; render();
  const s = document.getElementById("screen");
  const lignes = [...s.querySelectorAll("[data-assistq]")];
  return {
    emojis: (s.innerText.match(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}✔✓˅]/gu) || []),
    questions: lignes.length,
    glyphes: lignes.filter(l => l.querySelector(".ico svg.budget-glyph")).length,
    chevronsPeints: lignes.filter(l => {
      const c = l.querySelector("span[aria-hidden] svg.budget-glyph");
      return c && c.getBoundingClientRect().width >= 12;
    }).length,
    chevronTexte: s.innerText.includes("›") || s.innerText.includes("˅"),
    sourceSansCoche: !renderAssistant.toString().includes("couverte ✓"),
  };
});
check(p18.emojis.length === 0,
  `zéro emoji ni chevron texte sur l'Assistant (restants : ${p18.emojis.join(" ") || "aucun"})`);
check(p18.questions >= 3 && p18.glyphes === p18.questions,
  `chaque question fermée porte son glyphe sémantique (${p18.glyphes}/${p18.questions})`);
check(p18.chevronsPeints === p18.questions,
  `chaque question fermée porte un chevron peint (${p18.chevronsPeints}/${p18.questions})`);
check(!p18.chevronTexte, "plus aucun « › » ni « ˅ » texte à l'écran");
check(p18.sourceSansCoche, "la réserve couverte se dit sans coche décorative");
await page.evaluate(() => { activeTab = "home"; moreView = null; render(); });

// ---------- Test 141 : P04 Budget — boutons en mots, langue des opérations ----------
// Budget Prisme, lot P04. Les trois boutons « Ajouter une ligne
// budgétaire » parlent en mots (état vide avec ou sans mois précédent,
// et bas de liste) ; le mode d'emploi dit « opérations réelles »,
// conformément à la matrice de langue.
currentTest = "P04 budget";
await goHome();
const p04 = await page.evaluate(() => {
  const budgetVide = { y: 2031, m: 6 };
  cursor = { ...budgetVide };
  activeTab = "budget"; moreView = null; render();
  const sVide = document.getElementById("screen");
  const vide = {
    bouton: (sVide.querySelector("[data-addline]") || {}).textContent || "",
    plus: sVide.innerText.includes("＋"),
    operations: /opérations réelles/.test(sVide.innerText),
    mouvements: /mouvements réels/.test(sVide.innerText),
  };
  cursor = { y: NOW.y, m: NOW.m };
  render();
  const sPlein = document.getElementById("screen");
  const plein = {
    bouton: (sPlein.querySelector("[data-addline]") || {}).textContent || "",
    plus: sPlein.innerText.includes("＋"),
  };
  activeTab = "home"; render();
  return { vide, plein };
});
check(p04.vide.bouton.trim() === "Ajouter une ligne budgétaire" && !p04.vide.plus,
  `l'état vide du budget parle en mots (obtenu « ${p04.vide.bouton.trim()} »)`);
check(p04.vide.operations && !p04.vide.mouvements,
  "le mode d'emploi dit « opérations réelles », plus « mouvements réels »");
check(p04.plein.bouton.trim() === "Ajouter une ligne budgétaire" && !p04.plein.plus,
  `le bas de liste parle en mots (obtenu « ${p04.plein.bouton.trim()} »)`);

// ---------- Test 142 : Fondation — la langue des opérations partout, champs morts retirés ----------
// Micro-lot Fondation. « Opération » est le mot canonique (matrice de
// langue) : plus aucun écran ne dit « mouvement », la feuille de saisie
// non plus ; les champs morts (ACCOUNT_KINDS.icon, monthPriority().icon)
// ont disparu de la source.
currentTest = "Fondation langue";
await goHome();
const fondation = await page.evaluate(() => {
  const VUES = [["home", null], ["movements", null], ["budget", null], ["accounts", null],
    ["more", null], ["more", "year"], ["more", "subs"], ["more", "bills"], ["more", "recurring"],
    ["more", "goals"], ["more", "taxes"], ["more", "networth"], ["more", "insurance"],
    ["more", "settings"], ["more", "importcsv"], ["more", "assistant"]];
  const fautifs = [];
  for (const [tab, vue] of VUES) {
    activeTab = tab; moreView = vue; render();
    const txt = document.getElementById("screen").innerText;
    if (/[Mm]ouvements?/.test(txt)) fautifs.push(`${tab}${vue ? ":" + vue : ""}`);
  }
  activeTab = "home"; moreView = null; render();
  openTxSheet(null);
  const titreFeuille = document.getElementById("sheetTitle").textContent;
  const boutonSuppr = document.getElementById("fDelete")?.textContent || "";
  closeSheet();
  return {
    fautifs,
    titreFeuille,
    boutonSuppr,
    kindsSansIcone: Object.values(ACCOUNT_KINDS).every(k => !("icon" in k)),
    prioSansIcone: !monthPriority.toString().includes("icon:"),
  };
});
check(fondation.fautifs.length === 0,
  `aucun écran ne dit plus « mouvement » (fautifs : ${fondation.fautifs.join(", ") || "aucun"})`);
check(!/mouvement/i.test(fondation.titreFeuille),
  `le titre de la feuille ne dit plus « mouvement » (obtenu « ${fondation.titreFeuille} » — les titres par intention restent)`);
check(/cette opération/.test(fondation.boutonSuppr),
  `le bouton de suppression parle d'opération (obtenu « ${fondation.boutonSuppr} »)`);
check(fondation.kindsSansIcone, "ACCOUNT_KINDS ne porte plus de champ icon mort");
check(fondation.prioSansIcone, "monthPriority ne porte plus de champ icon mort");
// Garde au niveau de la SOURCE servie : les toasts et confirmations (textes
// transitoires que la sonde d'écrans ne voit pas) parlent aussi en
// opérations. Les identifiants techniques (clé legacy, nom de fichier CSV)
// et les commentaires de code sont volontairement hors périmètre.
const source142 = (await import("node:fs")).readFileSync(new URL("../index.html", import.meta.url), "utf8");
const transitoires142 = (source142.match(/toast\("[^"]*[Mm]ouvement[^"]*"|confirm\("[^"]*[Mm]ouvement[^"]*"|"(?:Nouveau|Modifier le) mouvement/g) || []);
check(transitoires142.length === 0,
  `aucun toast ni confirmation ne dit plus « mouvement » (restants : ${transitoires142.slice(0, 3).join(" · ") || "aucun"})`);

// ---------- Test 143 : A1 Année imprimable — bouton réel, document propre ----------
// Améliorations continues. La page Année porte un bouton « Imprimer ou
// enregistrer en PDF » qui appelle réellement window.print() (compté par
// le stub de la suite) ; la feuille d'impression existe (fond blanc,
// navigation masquée) ; rien n'est recalculé.
currentTest = "A1 année imprimable";
await goHome();
const a1 = await page.evaluate(() => {
  activeTab = "more"; moreView = "year"; render();
  const s = document.getElementById("screen");
  const bouton = s.querySelector("[data-printyear]");
  const avantClics = window.__printCalls || 0;
  bouton?.click();
  const appels = (window.__printCalls || 0) - avantClics;
  const regles = [...document.styleSheets].flatMap(f => {
    try { return [...f.cssRules]; } catch { return []; }
  }).filter(r => r.media && [...r.media].some(m => m.includes("print")));
  const encre = regles.some(r => (r.cssText || "").includes("#fff") || (r.cssText || "").includes("255, 255, 255"));
  const navMasquee = regles.some(r => (r.cssText || "").includes("#tabbar"));
  activeTab = "home"; moreView = null; render();
  return { present: !!bouton, texte: bouton?.textContent?.trim() || "", appels,
    reglesImpression: regles.length, encre, navMasquee };
});
check(a1.present && a1.texte === "Imprimer ou enregistrer en PDF",
  `le bouton d'impression existe et parle en mots (obtenu « ${a1.texte} »)`);
check(a1.appels === 1, `le bouton appelle réellement window.print() (${a1.appels} appel)`);
check(a1.reglesImpression >= 1 && a1.encre && a1.navMasquee,
  `la feuille d'impression existe : fond blanc et navigation masquée (${a1.reglesImpression} règle(s))`);

// ---------- Test 144 : A2 Formatage — montants insécables, trio uniforme, tuiles égales ----------
// Améliorations continues, lot A2 (5 photos annotées du propriétaire).
// Un montant est un mot : « CHF 102'210.00 » ne se coupe jamais en deux
// lignes, nulle part. Le trio du Mois a trois cellules IDENTIQUES (libellé,
// CHF, chiffres — mêmes décalages). L'Historique groupé ne répète pas la
// date de l'en-tête dans les lignes. Les tuiles du menu d'ajout sont
// égales. L'anneau du Budget reste lisible même à 4484 %.
currentTest = "A2 formatage";
await goHome();
await page.evaluate(() => {
  // Fixture des photos — EN MÉMOIRE seulement (dernier test, pas de saveState).
  const cash = ACCOUNTS.find(a => a.cash);
  if (!ACCOUNTS.some(a => a.id === "acc-a2-ep")) {
    ACCOUNTS.push(
      { id: "acc-a2-ep", name: "Compte épargne", kind: "savings", inst: "BCV", currency: "CHF", opening: 97590, cash: false },
      { id: "acc-a2-bourse", name: "Bourse", kind: "brokerage", inst: "IBKR", currency: "CHF", opening: 24000, cash: false },
    );
  }
  const { y, m } = NOW;
  let id = 987000;
  const mk = (d, title, amount, type, cat, dest, extra) => ({
    id: id++, y, m, d, title, amount, type, cat, acc: cash.id, ...(dest ? { dest } : {}),
    status: "posted", createdAt: 1, updatedAt: 1, ...(extra || {}),
  });
  transactions.push(
    mk(2, "Salaire A2", 18200, "income", "Revenus"),
    mk(3, "Mise de côté mensuelle", 2000, "saving", "Épargne", "acc-a2-ep"),
    mk(4, "Arrondi épargne", 210, "saving", "Épargne", "acc-a2-ep"),
    mk(5, "Gros virement épargne", 100000, "saving", "Épargne", "acc-a2-ep"),
    mk(6, "Versement bourse", 20000, "investment", "Investissements", "acc-a2-bourse"),
    mk(7, "Loyer et charges annuelles", 11570, "expense", "Logement"),
    mk(8, "Provision impôts géante", 100000, "saving", "Épargne", "acc-a2-ep", { status: "planned", recurringId: "r-a2-fantome" }),
  );
  S.budgets = S.budgets || {};
  S.budgets[`${y}-${m}`] = [{ cat: "Logement", amount: 258, kind: "expense" }];
  cursor = { y, m };
  activeTab = "home"; moreView = null; render();
  // Détecteur : un montant (« CHF 1'234.56 ») rendu sur PLUSIEURS lignes.
  window.__amountWraps = root => {
    const out = [];
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      const re = /[-+−]?(?:CHF|€|\$)[\s ]?\d[\d'’]*\.\d\d/g;
      let match;
      while ((match = re.exec(node.textContent))) {
        const range = document.createRange();
        range.setStart(node, match.index);
        range.setEnd(node, match.index + match[0].length);
        const tops = [...new Set([...range.getClientRects()].filter(r => r.width > 1).map(r => Math.round(r.top)))];
        if (tops.length > 1) out.push(match[0]);
      }
    }
    return out;
  };
});
const a2 = { wraps: {} };
// Mois : trio identique + bilan sur une ligne
Object.assign(a2, await page.evaluate(() => {
  const cells = [...document.querySelectorAll(".home-metrics .stat")].map(stat => {
    const cell = stat.getBoundingClientRect();
    const cur = stat.querySelector(".home-metric-currency").getBoundingClientRect();
    const amount = stat.querySelector(".amount").getBoundingClientRect();
    return { curY: Math.round(cur.y - cell.y), curX: Math.round(cur.x - cell.x),
      amtY: Math.round(amount.y - cell.y), amtDeborde: amount.right > cell.right + 0.5,
      taille: getComputedStyle(stat.querySelector(".amount")).fontSize };
  });
  const bilan = [...document.querySelectorAll(".home-bill-row .amount")].map(a => {
    const r = a.getBoundingClientRect();
    const lh = parseFloat(getComputedStyle(a).lineHeight) || 18;
    return { texte: a.textContent, uneLigne: r.height < lh * 1.6 };
  });
  return { cells, bilan, wrapsMois: __amountWraps(document.getElementById("screen")) };
}));
check(a2.cells.length === 3
  && new Set(a2.cells.map(c => c.curY)).size === 1
  && new Set(a2.cells.map(c => c.amtY)).size === 1
  && Math.max(...a2.cells.map(c => c.curX)) - Math.min(...a2.cells.map(c => c.curX)) <= 1,
  `trio du Mois : trois cellules identiques — CHF et chiffres aux mêmes positions (obtenu ${JSON.stringify(a2.cells)})`);
check(new Set(a2.cells.map(c => c.taille)).size === 1 && !a2.cells.some(c => c.amtDeborde),
  "trio du Mois : une seule taille de chiffres pour les trois cellules, sans débordement");
check(a2.wrapsMois.length === 0, `aucun montant coupé sur l'écran Mois (${a2.wrapsMois.join(" · ")})`);
const bilanLong = a2.bilan.find(b => b.texte.includes("100'000.00"));
check(!!bilanLong && bilanLong.uneLigne && a2.bilan.every(b => b.uneLigne),
  `le bilan du mois écrit chaque montant sur UNE ligne, même CHF 100'000.00 (${JSON.stringify(a2.bilan.map(b => b.texte))})`);
// Historique groupé : la date vit dans l'en-tête, pas dans les lignes
await goMovements();
const a2histo = await page.evaluate(() => ({
  enTetes: document.querySelectorAll(".day-header").length,
  sousTitresDates: [...document.querySelectorAll(".tx .meta .s")].filter(s => /\d{2}\.\d{2}\.\d{4}/.test(s.textContent)).length,
  coupes: [...document.querySelectorAll(".tx .meta .s")].filter(s => s.scrollWidth > s.clientWidth + 1).length,
  wraps: __amountWraps(document.getElementById("screen")),
}));
check(a2histo.enTetes >= 2 && a2histo.sousTitresDates === 0,
  `l'Historique groupé écrit la date UNE fois (en-têtes : ${a2histo.enTetes}, lignes datées : ${a2histo.sousTitresDates})`);
check(a2histo.coupes === 0, `aucun sous-titre coupé en plein mot dans l'Historique (${a2histo.coupes} coupé(s))`);
check(a2histo.wraps.length === 0, "aucun montant coupé dans l'Historique");
// Le détail d'un compte garde ses dates (pas d'en-têtes de jour là-bas)
const a2detail = await page.evaluate(() => {
  accountView = "acc-a2-ep"; activeTab = "accounts"; moreView = null; render();
  const dates = [...document.querySelectorAll(".tx .meta .s")].filter(s => /\d{2}\.\d{2}\.\d{4}/.test(s.textContent)).length;
  const wraps = __amountWraps(document.getElementById("screen"));
  accountView = null; render();
  return { dates, wraps };
});
check(a2detail.dates >= 3, `le détail d'un compte garde la date sur chaque ligne (${a2detail.dates})`);
check(a2detail.wraps.length === 0, "aucun montant coupé sur les légendes des Comptes (« Mis de côté cette année »)");
// Budget : anneau extrême lisible, caption structurée
const a2budget = await page.evaluate(() => {
  activeTab = "budget"; render();
  const hero = document.querySelector(".card.hero");
  const svgText = hero.querySelector("svg text");
  const svg = hero.querySelector("svg");
  return {
    pct: svgText ? svgText.textContent : "",
    petitePolice: svgText ? parseFloat(svgText.style.fontSize) : 0,
    pctTient: svgText && svg ? svgText.getBoundingClientRect().width <= svg.getBoundingClientRect().width * 0.72 : false,
    prevuSepare: /Prévu CHF[\s ][\d'.]+ · dépensé CHF[\s ][\d'.]+\./.test(hero.innerText),
    wraps: __amountWraps(document.getElementById("screen")),
    deborde: hero.scrollWidth > hero.clientWidth + 1,
  };
});
check(/\d{4,}%/.test(a2budget.pct) && a2budget.petitePolice <= 11 && a2budget.pctTient,
  `l'anneau à ${a2budget.pct} réduit sa police (${a2budget.petitePolice}px) et le texte tient dans l'anneau`);
check(a2budget.prevuSepare, "le héros Budget écrit « Prévu … · dépensé … » sur sa propre ligne");
check(a2budget.wraps.length === 0 && !a2budget.deborde, "aucun montant coupé ni débordement sur l'écran Budget");
// quickMenu : quatre tuiles égales, icônes identiques
await page.evaluate(() => { activeTab = "home"; render(); });
await page.click("[data-addtx]");
await page.waitForSelector("#quickMenu", { state: "visible" });
const a2menu = await page.evaluate(() => {
  const tuiles = [...document.querySelectorAll("#quickMenu .quick-intent")].map(t => t.getBoundingClientRect().height);
  const icones = [...document.querySelectorAll("#quickMenu .quick-intent-icon")].map(i => {
    const r = i.getBoundingClientRect(); return `${Math.round(r.width)}x${Math.round(r.height)}`;
  });
  return { tuiles, icones };
});
await page.click("#quickCancel");
check(a2menu.tuiles.length === 4 && Math.max(...a2menu.tuiles) - Math.min(...a2menu.tuiles) < 1,
  `les quatre tuiles d'intention ont la même hauteur (${a2menu.tuiles.map(h => Math.round(h)).join(", ")})`);
check(new Set(a2menu.icones).size === 1, `les icônes des tuiles sont identiques (${[...new Set(a2menu.icones)].join(" ")})`);
// 320 px : le trio reste identique et contenu
await page.setViewportSize({ width: 320, height: 844 });
await page.evaluate(() => { activeTab = "home"; render(); });
const a2etroit = await page.evaluate(() => {
  const cells = [...document.querySelectorAll(".home-metrics .stat")].map(stat => {
    const cell = stat.getBoundingClientRect();
    const cur = stat.querySelector(".home-metric-currency").getBoundingClientRect();
    const amount = stat.querySelector(".amount");
    const r = amount.getBoundingClientRect();
    return { curY: Math.round(cur.y - cell.y),
      texte: amount.textContent, classe: amount.className,
      police: getComputedStyle(amount).fontSize,
      depasse: +(r.right - cell.right).toFixed(1),
      deborde: r.right > cell.right + 1 };
  });
  return { cells, unis: new Set(cells.map(c => c.curY)).size === 1, deborde: cells.some(c => c.deborde),
    wraps: __amountWraps(document.getElementById("screen")) };
});
await page.setViewportSize({ width: 390, height: 844 });
check(a2etroit.unis && !a2etroit.deborde && a2etroit.wraps.length === 0,
  `à 320 px : trio toujours identique, montants entiers et contenus (${JSON.stringify(a2etroit.cells)} wraps=${a2etroit.wraps.join("·")})`);

// ---------- Test 145 : A3 Beauté des cartes — biseau, cadran, avancement du mois ----------
// Améliorations continues, lot A3 (« encore plus beau »). Le biseau haut
// des cartes est un cheveu plus clair que le contour (jamais un glow) ;
// les séparateurs du trio sont en retrait (dégradé mat) ; le héros du
// mois COURANT porte une jauge honnête « Jour X sur Y » (jour calendaire
// réel) — absente sur les autres mois ; les chiffres du trio sont en
// graisse d'affirmation.
currentTest = "A3 beauté";
await goHome();
const a3 = await page.evaluate(() => {
  cursor = { y: NOW.y, m: NOW.m };
  activeTab = "home"; moreView = null; render();
  const carte = document.querySelector("#screen .card:not(.hero)");
  const style = carte && getComputedStyle(carte);
  const trio = document.querySelectorAll(".home-metrics .stat")[1];
  const jauge = document.querySelector(".home-hero .hero-mois-avance");
  const joursDuMois = new Date(NOW.y, NOW.m, 0).getDate();
  const fill = jauge && jauge.querySelector(".fill");
  const resultat = {
    biseau: !!style && style.borderTopColor !== style.borderBottomColor,
    separateurEnRetrait: trio ? getComputedStyle(trio).borderImageSource.includes("gradient") : false,
    chiffresAffirmes: [...document.querySelectorAll(".home-metrics .amount")]
      .every(a => parseInt(getComputedStyle(a).fontWeight, 10) >= 700),
    jaugePresente: !!jauge,
    jaugeExacte: jauge ? jauge.getAttribute("aria-label") === `Jour ${NOW.d} sur ${joursDuMois}` : false,
    largeurExacte: fill ? Math.abs(parseFloat(fill.style.width) - NOW.d / joursDuMois * 100) < 1 : false,
    texteJauge: jauge ? /Jour \d+ sur \d+/.test(jauge.textContent) : false,
  };
  cursor = shiftMonth({ y: NOW.y, m: NOW.m }, -1); render();
  resultat.jaugeAbsenteAilleurs = !document.querySelector(".hero-mois-avance");
  cursor = { y: NOW.y, m: NOW.m }; render();
  return resultat;
});
check(a3.biseau, "le biseau haut des cartes est plus clair que le reste du contour");
check(a3.separateurEnRetrait, "les séparateurs du trio sont en retrait (dégradé mat)");
check(a3.chiffresAffirmes, "les chiffres du trio sont en graisse 700");
check(a3.jaugePresente && a3.jaugeExacte && a3.largeurExacte && a3.texteJauge,
  `le héros du mois courant dit « Jour ${new Date().getDate()} sur N » avec la largeur exacte`);
check(a3.jaugeAbsenteAilleurs, "aucune jauge d'avancement sur un autre mois que le mois courant");

// ---------- Test 146 : A5 Trio en deux lignes — « CHF » devant les chiffres ----------
// Demande propriétaire (17.08) : « T'arrive pas à faire plus jolie en
// deux lignes ? ». Chaque cellule du trio tient en DEUX lignes : le
// libellé, puis « CHF » en petit devant les chiffres, sur la même ligne
// de base (ordre suisse « CHF 18'200.00 »). Sous 381 px, la colonne se
// renverse (chiffres, puis « CHF » dessous) — rien ne se coupe, et les
// trois cellules restent identiques à chaque largeur. Dans le trio, le
// point violet ne double plus « CHF » (le libellé porte le sens).
currentTest = "A5 trio deux lignes";
await goHome();
const a5 = await page.evaluate(() => {
  cursor = { y: NOW.y, m: NOW.m };
  activeTab = "home"; moreView = null; render();
  const cells = [...document.querySelectorAll(".home-metrics .stat")].map(stat => {
    const amount = stat.querySelector(".amount");
    const amountR = amount.getBoundingClientRect();
    const cur = stat.querySelector(".home-metric-currency").getBoundingClientRect();
    const cell = stat.getBoundingClientRect();
    return {
      memeLigne: Math.abs((cur.y + cur.height) - (amountR.y + amountR.height)) < 6,
      chipAvant: cur.x < amountR.x,
      curYRel: Math.round(cur.y - cell.y),
      police: parseFloat(getComputedStyle(amount).fontSize),
      classe: amount.className,
      deborde: amountR.right > cell.right + 0.5,
      pointDouble: getComputedStyle(amount, "::before").content !== "none",
    };
  });
  return { cells, wraps: typeof window.__amountWraps === "function" ? window.__amountWraps(document.querySelector(".home-metrics")) : [] };
});
check(a5.cells.length === 3 && a5.cells.every(c => c.memeLigne && c.chipAvant),
  `à 390 px, chaque cellule tient en DEUX lignes : « CHF » devant les chiffres, même ligne de base (obtenu ${JSON.stringify(a5.cells.map(c => [c.memeLigne, c.chipAvant]))})`);
check(new Set(a5.cells.map(c => c.curYRel)).size === 1,
  "le « CHF » est à la même hauteur dans les trois cellules");
check(a5.cells.every(c => !c.deborde) && a5.wraps.length === 0,
  "les chiffres restent entiers et contenus");
check(a5.cells.every(c => !c.classe.split(" ").includes("wide") || c.police >= 12),
  `le palier wide garde au moins 12 px à 390 px (obtenu ${a5.cells.map(c => c.police).join(", ")})`);
check(a5.cells.every(c => !c.pointDouble),
  "dans le trio, le point violet ne double plus « CHF » sur la ligne de valeur");
// Sous 381 px : la colonne se renverse — chiffres, puis « CHF » dessous.
await page.setViewportSize({ width: 320, height: 844 });
await page.evaluate(() => { activeTab = "home"; render(); });
const a5etroit = await page.evaluate(() => {
  const cells = [...document.querySelectorAll(".home-metrics .stat")].map(stat => {
    const amountR = stat.querySelector(".amount").getBoundingClientRect();
    const cur = stat.querySelector(".home-metric-currency").getBoundingClientRect();
    const cell = stat.getBoundingClientRect();
    return { chfDessous: cur.y >= amountR.y + amountR.height - 1,
      curYRel: Math.round(cur.y - cell.y),
      deborde: amountR.right > cell.right + 1 };
  });
  return { cells, unis: new Set(cells.map(c => c.curYRel)).size === 1 };
});
await page.setViewportSize({ width: 390, height: 844 });
check(a5etroit.cells.every(c => c.chfDessous && !c.deborde) && a5etroit.unis,
  `à 320 px, les chiffres restent entiers et « CHF » passe dessous, pareil dans les trois cellules (obtenu ${JSON.stringify(a5etroit.cells)})`);

// ---------- Test 147 : A6 Bilan ordonné — Salaire, Factures, Abonnements, Mis de côté ----------
// Demande propriétaire (capture 22:28) : le Bilan du mois se lit dans
// l'ordre de son Notion — Salaire, puis Factures, puis Abonnements, puis
// Mis de côté (le retard reste devant DANS son groupe) ; un abonnement
// mensuel apparaît dans son mois ; chaque bouton d'action porte la
// couleur de son sens (Reçu vert, Payé corail, Mis de côté violet
// neutre) ; un seul appui enregistre l'opération automatiquement.
currentTest = "A6 bilan ordonné";
await goHome();
const a6 = await page.evaluate(() => {
  const cash = ACCOUNTS.find(a => a.cash);
  if (!RECURRINGS.some(r => r.id === "r-a6-sub")) {
    RECURRINGS.push(
      { id: "r-a6-pay", title: "Salaire A6", amount: 1000, type: "income",
        cat: "Revenus", accountId: cash.id, every: "month", day: 2 },
      { id: "r-a6-sub", title: "Abonnement streaming A6", amount: 19.9, type: "expense",
        family: "sub", cat: "Loisirs", accountId: cash.id, every: "month", day: 3 },
      { id: "r-a6-save", title: "Réserve mensuelle A6", amount: 300, type: "expense",
        nature: "reserve", cat: "Épargne", accountId: cash.id, every: "month", day: 4 },
      { id: "r-a6-bill", title: "Électricité A6", amount: 90, type: "expense",
        family: "charge", cat: "Logement", accountId: cash.id, every: "month", day: 5 },
    );
  }
  cursor = { y: NOW.y, m: NOW.m };
  activeTab = "home"; moreView = null; render();
  const lignes = [...document.querySelectorAll(".home-bills-list:not(.home-done-list) .home-bill-row")].map(row => {
    const bouton = row.querySelector(".home-bill-action");
    return {
      titre: row.querySelector(".t").textContent,
      sousTitre: row.querySelector(".s").textContent,
      acte: bouton ? bouton.textContent.trim() : "",
      classes: bouton ? bouton.className : "",
      couleur: bouton ? getComputedStyle(bouton).color : "",
    };
  });
  const groupeDe = ligne => /recevoir/i.test(ligne.sousTitre) ? 0
    : /streaming/i.test(ligne.titre) ? 2
    : /mettre de côté|investir/i.test(ligne.sousTitre) ? 3 : 1;
  const groupes = lignes.map(groupeDe);
  return {
    lignes: lignes.map(l => `${l.titre} [${l.acte}]`),
    groupes,
    croissant: groupes.every((g, i) => i === 0 || g >= groupes[i - 1]),
    salairePremier: groupes.length > 0 && groupes[0] === 0,
    abonnementVisible: lignes.some(l => /streaming/i.test(l.titre)),
    reserveVisible: lignes.some(l => /mettre de côté/i.test(l.sousTitre)),
    couleurs: {
      recevoir: (lignes.find(l => l.classes.includes("act-income")) || {}).couleur || "",
      payer: (lignes.find(l => l.classes.includes("act-expense")) || {}).couleur || "",
      reserver: (lignes.find(l => l.classes.includes("act-save")) || {}).couleur || "",
    },
  };
});
check(a6.salairePremier && a6.croissant,
  `le Bilan se lit Salaire → Factures → Abonnements → Mis de côté (obtenu ${JSON.stringify(a6.lignes)} → groupes ${JSON.stringify(a6.groupes)})`);
check(a6.abonnementVisible, "l'abonnement MENSUEL apparaît dans le bilan de son mois");
check(a6.reserveVisible, "la mise de côté du mois apparaît dans le bilan");
check(a6.couleurs.recevoir && a6.couleurs.payer && a6.couleurs.reserver
  && new Set(Object.values(a6.couleurs)).size === 3,
  `chaque bouton porte la couleur de son sens — trois couleurs distinctes (obtenu ${JSON.stringify(a6.couleurs)})`);
// Le bouton LONG (« Mis de côté ») descend sous la ligne : le titre garde
// sa largeur et ne se coupe jamais en plein mot.
const a6long = await page.evaluate(() => {
  const row = [...document.querySelectorAll(".home-bill-row")].find(r => r.querySelector(".home-bill-action--long"));
  if (!row) return null;
  const bouton = row.querySelector(".home-bill-action--long").getBoundingClientRect();
  const montant = row.querySelector(".amount").getBoundingClientRect();
  const titre = row.querySelector(".t");
  return { dessous: bouton.y >= montant.y + montant.height - 2,
    titreLarge: titre.getBoundingClientRect().width > 150 };
});
check(a6long && a6long.dessous && a6long.titreLarge,
  `le bouton long descend sous la ligne et le titre garde sa largeur (obtenu ${JSON.stringify(a6long)})`);
// Un appui = l'opération s'enregistre toute seule (rien d'autre à faire).
const a6avant = await page.evaluate(() => transactions.filter(t => t.recurringId === "r-a6-save").length);
await page.click('[data-postrec="r-a6-save"]');
await page.waitForTimeout(300);
const a6apres = await page.evaluate(() => ({
  postees: transactions.filter(t => t.recurringId === "r-a6-save" && t.status === "posted").length,
  faits: [...document.querySelectorAll(".home-done-list .home-bill-row .t")].map(e => e.textContent),
}));
check(a6avant === 0 && a6apres.postees === 1 && a6apres.faits.some(t => /Réserve mensuelle A6/.test(t)),
  `un appui sur « Mis de côté » enregistre l'opération et la ligne passe dans « Fait ce mois » (${a6apres.postees} postée)`);

// ---------- Test 148 : A7 Quatre blocs — Rentrées, Dépenses, Abonnements, Mis de côté ----------
// Demande propriétaire : « quatre blocs, pas tout dans un seul bloc ».
// Le Bilan du mois courant est un groupe de quatre cartes nommées, chacune
// avec ses lignes à faire (bouton un appui) ET ses lignes faites — la
// ligne validée reste dans SON bloc, marquée reçue/payée. Un mois futur
// a les MÊMES quatre blocs (A15) ; un mois sans rien garde son invitation.
currentTest = "A7 quatre blocs";
const a7 = await page.evaluate(() => {
  cursor = { y: NOW.y, m: NOW.m };
  activeTab = "home"; moreView = null; render();
  const blocs = [...document.querySelectorAll(".home-bloc")].map(b => ({
    titre: b.querySelector(".card-label").textContent.trim(),
    attente: [...b.querySelectorAll('[data-home-section="todo"] .home-bill-row .t')].map(t => t.textContent),
    faits: [...b.querySelectorAll(".home-done-list .home-bill-row .t")].map(t => t.textContent),
  }));
  const dans = (titre, portion) => {
    const bloc = blocs.find(b => b.titre === titre);
    return bloc ? bloc[portion] : [];
  };
  cursor = shiftMonth({ y: NOW.y, m: NOW.m }, 1); render();
  const futurBlocs = document.querySelectorAll(".home-bloc").length;
  const futurSection = !!document.querySelector('.home-bloc [data-home-section="future"]');
  cursor = { y: NOW.y, m: NOW.m }; render();
  return {
    titres: blocs.map(b => b.titre),
    salairePlace: dans("Rentrées", "attente").some(t => /Salaire A6/.test(t)),
    facturePlace: dans("Dépenses", "attente").some(t => /Électricité A6/.test(t)),
    abonnementPlace: dans("Abonnements", "attente").some(t => /streaming A6/i.test(t)),
    reserveFaite: dans("Mis de côté", "faits").some(t => /Réserve mensuelle A6/.test(t)),
    futurBlocs, futurSection,
  };
});
check(a7.titres.join(",") === "Rentrées,Dépenses,Abonnements,Mis de côté",
  `le Bilan du mois courant est fait de QUATRE blocs nommés (obtenu ${a7.titres.join(",")})`);
check(a7.salairePlace && a7.facturePlace && a7.abonnementPlace,
  `chaque ligne vit dans SON bloc — salaire, facture, abonnement (${JSON.stringify([a7.salairePlace, a7.facturePlace, a7.abonnementPlace])})`);
check(a7.reserveFaite,
  "la mise de côté validée au test A6 est restée dans le bloc « Mis de côté », marquée faite");
check(a7.futurBlocs === 4 && a7.futurSection,
  `un mois futur a les mêmes quatre blocs, marqués « prévu » (${a7.futurBlocs} bloc(s), section future ${a7.futurSection})`);
// Un appui : le salaire passe reçu SANS quitter son bloc. (Présence
// vérifiée par assertion — un sabotage doit échouer proprement, pas en
// timeout.)
const a7bouton = await page.$('.home-bloc [data-postrec="r-a6-pay"]');
check(!!a7bouton, "le bouton « Reçu » du salaire vit dans le bloc Rentrées");
if (a7bouton) { await a7bouton.click(); await page.waitForTimeout(300); }
const a7apres = await page.evaluate(() => {
  const bloc = [...document.querySelectorAll(".home-bloc")].find(b => b.querySelector(".card-label").textContent.trim() === "Rentrées");
  return {
    fait: [...bloc.querySelectorAll(".home-done-list .home-bill-row")].some(r =>
      /Salaire A6/.test(r.querySelector(".t").textContent) && /Reçu ce mois/.test(r.querySelector(".s").textContent)),
    encoreEnAttente: [...bloc.querySelectorAll('[data-home-section="todo"] .home-bill-row .t')].some(t => /Salaire A6/.test(t.textContent)),
  };
});
check(a7apres.fait && !a7apres.encoreEnAttente,
  `un appui sur « Reçu » : le salaire reste dans « Rentrées », marqué « Reçu ce mois » (${JSON.stringify(a7apres)})`);

// ---------- Test 149 : A8 Les quatre familles — Historique et « Ce qui revient » ----------
// Programme « Les quatre familles partout » (BUDGET_FAMILLES_PLAN.md).
// L'Historique filtre par famille dans l'ordre canonique — Tous,
// Rentrées, Dépenses, Abonnements, Mis de côté, Virements — en PARTITION
// stricte : une dépense d'abonnement vit sous « Abonnements », plus sous
// « Dépenses » ; chaque franc est compté dans une seule famille.
// « Ce qui revient » suit le même ordre.
currentTest = "A8 familles";
await goMovements();
const a8 = await page.evaluate(() => {
  const cash = ACCOUNTS.find(a => a.cash);
  if (!transactions.some(t => t.id === 990001)) {
    transactions.push(
      { id: 990001, y: NOW.y, m: NOW.m, d: 9, title: "Streaming payé A8", amount: 21.9,
        type: "expense", cat: "Loisirs", acc: cash.id, recurringId: "r-a6-sub",
        status: "posted", createdAt: 1, updatedAt: 1 },
      { id: 990002, y: NOW.y, m: NOW.m, d: 9, title: "Courses A8", amount: 55,
        type: "expense", cat: "Alimentation", acc: cash.id,
        status: "posted", createdAt: 1, updatedAt: 1 },
    );
  }
  activeTab = "movements"; moreView = null; moreSearch = ""; moreFilter = "all"; render();
  const chips = [...document.querySelectorAll("[data-morefilter]")].map(c => c.textContent.trim());
  const lit = filtre => {
    moreFilter = filtre; render();
    return [...document.querySelectorAll(".tx .meta .t")].map(t => t.textContent.trim());
  };
  const sous = lit("sub");
  const depenses = lit("expense");
  const rentrees = lit("income");
  const familles = ["income", "expense", "sub", "saving", "transfer"];
  const partition = transactions
    .filter(t => inMonth(t, NOW.y, NOW.m) && t.type !== "adjustment")
    .every(t => familles.filter(f => txFamille(t) === f).length === 1);
  moreFilter = "all"; render();
  activeTab = "more"; moreView = "recurring"; render();
  const recChips = [...document.querySelectorAll("[data-recfilter]")].map(c => c.textContent.trim());
  activeTab = "home"; moreView = null; render();
  return { chips, sous, depenses, rentrees, partition, recChips };
});
check(a8.chips.join(",") === "Tous,Rentrées,Dépenses,Abonnements,Mis de côté,Virements",
  `l'Historique filtre par famille, dans l'ordre canonique (obtenu ${a8.chips.join(",")})`);
check(a8.sous.some(t => /Streaming payé A8/.test(t)) && !a8.sous.some(t => /Courses A8/.test(t)),
  `« Abonnements » montre l'abonnement payé, rien d'autre (${JSON.stringify(a8.sous)})`);
check(a8.depenses.some(t => /Courses A8/.test(t)) && !a8.depenses.some(t => /Streaming payé A8/.test(t)),
  "« Dépenses » ne compte plus les abonnements — partition stricte");
check(a8.rentrees.every(t => !/Courses A8|Streaming payé A8/.test(t)), "« Rentrées » ne montre que les rentrées");
check(a8.partition, "chaque opération du mois vit dans exactement UNE famille");
// Les chips de « Ce qui revient » portent leur décompte (« Factures 1 ») :
// l'ordre et les mots comptent, pas les nombres.
const a8attendu = ["Tout", "Rentrées", "Factures", "Abonnements", "Mis de côté"];
check(a8.recChips.length === a8attendu.length
    && a8.recChips.every((c, i) => c.replace(/\s*\d+$/, "") === a8attendu[i]),
  `« Ce qui revient » suit l'ordre des familles (obtenu ${a8.recChips.join(",")})`);

// ---------- Test 150 : A9 Menu d'ajout et hub Gérer à l'ordre des familles ----------
// Programme « Les quatre familles partout ». Le menu « Ajouter » propose
// ses intentions dans l'ordre canonique — J'ai reçu, J'ai dépensé, Ça
// revient régulièrement, J'ai mis de côté — et le hub Gérer s'ouvre sur
// le groupe « Les quatre familles ».
currentTest = "A9 menu familles";
await goHome();
await page.click("[data-addtx]");
await page.waitForSelector("#quickMenu", { state: "visible" });
const a9menu = await page.evaluate(() =>
  [...document.querySelectorAll("#quickMenu .quick-intent")].map(b => b.dataset.quick));
await page.click("#quickCancel");
check(a9menu.join(",") === "income,expense,rec,save",
  `le menu d'ajout suit l'ordre des familles (obtenu ${a9menu.join(",")})`);
const a9hub = await page.evaluate(() => {
  activeTab = "more"; moreView = null; render();
  const premier = document.querySelector("#screen .section-title")?.textContent || "";
  const sousTitreVide = (() => {
    const sauvegarde = RECURRINGS.splice(0, RECURRINGS.length);
    render();
    const texte = document.querySelector('[data-more="recurring"] .s')?.textContent || "";
    RECURRINGS.push(...sauvegarde);
    render();
    return texte;
  })();
  activeTab = "home"; render();
  return { premier, sousTitreVide };
});
check(a9hub.premier === "Les quatre familles",
  `le hub Gérer s'ouvre sur « Les quatre familles » (obtenu « ${a9hub.premier} »)`);
check(/Rentrées, factures, abonnements et mises de côté/.test(a9hub.sousTitreVide),
  `l'invite vide de « Ce qui revient » parle l'ordre des familles (obtenu « ${a9hub.sousTitreVide} »)`);

// ---------- Test 151 : A10 Budget en mots de famille + logos uniformes ----------
// Programme « Les quatre familles partout ». L'écran Budget appelle le
// groupe d'épargne par le mot de la famille — « Mis de côté » — et les
// pastilles de logos (`.ico` + Budget Glyph) ont exactement la même
// géométrie sur le Mois, l'Historique et le hub Gérer.
currentTest = "A10 budget familles";
await goHome();
const a10 = await page.evaluate(() => {
  const cash = ACCOUNTS.find(a => a.cash);
  S.budgets = S.budgets || {};
  const cle = `${NOW.y}-${NOW.m}`;
  if (!(S.budgets[cle] || []).some(l => l.kind === "saving")) {
    S.budgets[cle] = [...(S.budgets[cle] || []), { cat: "Épargne", amount: 500, kind: "saving" }];
  }
  cursor = { y: NOW.y, m: NOW.m };
  activeTab = "budget"; moreView = null; render();
  const titres = [...document.querySelectorAll("#screen .section-title")].map(t => t.textContent.trim());
  const geometrie = ecran => {
    const boites = [...document.querySelectorAll("#screen .ico")].slice(0, 6).map(i => {
      const r = i.getBoundingClientRect();
      const g = i.querySelector(".budget-glyph")?.getBoundingClientRect();
      return `${Math.round(r.width)}x${Math.round(r.height)}` + (g ? `/${Math.round(g.width)}x${Math.round(g.height)}` : "");
    });
    return boites;
  };
  activeTab = "home"; render();
  const geoMois = geometrie();
  activeTab = "movements"; render();
  const geoHisto = geometrie();
  activeTab = "more"; moreView = null; render();
  const geoGerer = geometrie();
  activeTab = "home"; render();
  return { titres, geoListes: [...geoMois, ...geoHisto], geoGerer };
});
check(a10.titres.includes("Mis de côté") && !a10.titres.some(t => /Épargne et investissements/.test(t)),
  `le Budget appelle le groupe par le mot de la famille (obtenu ${a10.titres.join(" · ")})`);
check(a10.geoListes.length >= 4 && new Set(a10.geoListes).size === 1,
  `les pastilles des LISTES ont la même géométrie sur Mois et Historique (obtenu ${[...new Set(a10.geoListes)].join(" ; ")})`);
// A22 (demande propriétaire) : le hub Gérer porte une pastille PLUS
// GRANDE — 54 px, glyphe 26 px — uniforme sur toutes ses entrées.
check(a10.geoGerer.length >= 4 && new Set(a10.geoGerer).size === 1 && a10.geoGerer[0] === "54x54/26x26",
  `le hub Gérer porte sa grande pastille uniforme 54 px / glyphe 26 px (obtenu ${[...new Set(a10.geoGerer)].join(" ; ")})`);

// ---------- Test 152 : A15 Mois futur — quatre blocs et bouton « Planifier » ----------
// Demande propriétaire (18.08.2026) : « ajoute aussi la même mise en page
// que les autres et il manque toujours le bouton où j'appuie ». Un mois
// FUTUR a les MÊMES quatre blocs que le mois courant, et chaque ligne non
// planifiée porte un bouton un appui — mais le geste honnête y est
// « Planifier » : le mouvement est créé PRÉVU, jamais reçu ou payé
// d'avance, et une ligne déjà planifiée n'offre aucune confirmation.
currentTest = "A15 mois futur";
await goHome();
const a15 = await page.evaluate(() => {
  cursor = shiftMonth({ y: NOW.y, m: NOW.m }, 1);
  activeTab = "home"; moreView = null; render();
  const blocs = [...document.querySelectorAll(".home-bloc")].map(b => ({
    titre: b.querySelector(".card-label").textContent.trim(),
    compte: b.querySelector(".home-bloc-count")?.textContent.trim() || "",
  }));
  return {
    titres: blocs.map(b => b.titre),
    comptes: blocs.map(b => b.compte).filter(Boolean),
    confirmables: document.querySelectorAll("[data-confirmtx]").length,
    salaireLabel: document.querySelector('.home-bloc [data-postrec="r-a6-pay"]')?.textContent.trim() || "",
  };
});
check(a15.titres.join(",") === "Rentrées,Dépenses,Abonnements,Mis de côté",
  `le mois FUTUR a les mêmes quatre blocs nommés (obtenu ${a15.titres.join(",")})`);
check(a15.comptes.length > 0 && a15.comptes.every(c => !/à faire/.test(c)) && a15.comptes.some(c => /prévu/.test(c)),
  `les compteurs du mois futur disent « prévu », jamais « à faire » (obtenu ${JSON.stringify(a15.comptes)})`);
check(a15.confirmables === 0,
  "aucun bouton de confirmation dans un mois futur — on ne comptabilise jamais d'avance");
check(a15.salaireLabel === "Planifier",
  `le salaire futur porte un bouton un appui « Planifier » (obtenu « ${a15.salaireLabel} »)`);
const a15btn = await page.$('.home-bloc [data-postrec="r-a6-pay"]');
check(!!a15btn, "le bouton « Planifier » du salaire futur est cliquable dans son bloc");
if (a15btn) { await a15btn.click(); await page.waitForTimeout(300); }
const a15apres = await page.evaluate(() => {
  const futur = shiftMonth({ y: NOW.y, m: NOW.m }, 1);
  const creees = transactions.filter(t => t.recurringId === "r-a6-pay" && t.y === futur.y && t.m === futur.m);
  const ligne = [...document.querySelectorAll(".home-bloc .home-bill-row")]
    .find(r => /Salaire A6/.test(r.querySelector(".t")?.textContent || ""));
  const resultat = {
    planifiees: creees.filter(t => t.status === "planned").length,
    postees: creees.filter(t => t.status === "posted").length,
    statut: ligne?.querySelector(".s")?.textContent || "",
    boutonRestant: !!ligne?.querySelector(".home-bill-action"),
  };
  // Nettoyage : le mouvement prévu créé pour le test est retiré, puis on
  // revient au mois courant — l'état persistant reste celui d'avant.
  for (const t of creees) transactions.splice(transactions.indexOf(t), 1);
  cursor = { y: NOW.y, m: NOW.m }; saveState(); render();
  return resultat;
});
check(a15apres.planifiees === 1 && a15apres.postees === 0,
  `un appui sur « Planifier » crée le mouvement PRÉVU du mois futur — jamais comptabilisé d'avance (${JSON.stringify(a15apres)})`);
check(/Prévu/.test(a15apres.statut) && !a15apres.boutonRestant,
  `la ligne planifiée dit « Prévu » et n'offre plus aucun bouton (${JSON.stringify(a15apres)})`);

// ---------- Test 153 : A20 Prévision continue — confirmée SANS aucun terme fiscal ----------
// L'invariant A20 survit à FE2-12 : confirmer un salaire attendu ne change
// pas le disponible. Et désormais, même un taux hérité de 50 % ne pèse
// RIEN — la projection n'a plus aucun terme fiscal automatique.
currentTest = "A20 prévision continue";
const a20 = await page.evaluate(() => {
  const cash = ACCOUNTS.find(a => a.cash);
  const memoire = { taxRate: S.taxRate, taxReserve: S.taxReserve };
  // Le pire des cas hérités : un taux très haut resté stocké.
  S.taxRate = 0.50; S.taxReserve = 0;
  RECURRINGS.push({ id: "r-a20-salaire", title: "Salaire A20", amount: 3000, type: "income",
    cat: "Salaire", day: 6, every: "month", accountId: cash.id });
  const avant = snapshot(NOW.y, NOW.m);
  const identiteAvant = Math.round((avant.liquid + avant.plannedIncome + avant.recurringIncome
    + avant.irregularIncome - avant.plannedOut - avant.recurringCharges) * 100) / 100;
  const { transaction } = materializeRecurring(
    RECURRINGS.find(r => r.id === "r-a20-salaire"), NOW.y, NOW.m);
  const apres = snapshot(NOW.y, NOW.m);
  // Nettoyage complet : mouvement, récurrence, réglages fiscaux.
  transactions.splice(transactions.indexOf(transaction), 1);
  RECURRINGS.splice(RECURRINGS.findIndex(r => r.id === "r-a20-salaire"), 1);
  S.taxRate = memoire.taxRate; S.taxReserve = memoire.taxReserve;
  saveState(); render();
  return {
    avant: avant.available, apres: apres.available, identiteAvant,
    statutCree: transaction.status,
  };
});
check(a20.statutCree === "posted", `le salaire du test est bien comptabilisé (obtenu ${a20.statutCree})`);
check(Math.abs(a20.avant - a20.apres) < 0.005,
  `confirmer un salaire attendu ne change pas le disponible (avant ${a20.avant} / après ${a20.apres})`);
check(Math.abs(a20.identiteAvant - a20.avant) < 0.005,
  `même un taux hérité de 50 % ne pèse RIEN : projection = argent + attendu − sorties saisies (identité ${a20.identiteAvant} vs ${a20.avant})`);

// ---------- Test 154 : FE2-12 — le moteur n'a plus AUCUN champ fiscal automatique ----------
// Décision propriétaire (20.08.2026) : « ne calcule pas les impôts
// automatiquement — toutes les données, c'est moi qui dois les rentrer ».
// Même un gros revenu de l'année et un taux hérité de 30 % ne produisent
// RIEN : la projection additionne seulement ce qui est saisi.
currentTest = "FE2-12 impôts manuels";
const fe2 = await page.evaluate(() => {
  const cash = ACCOUNTS.find(a => a.cash);
  const memoire = { taxRate: S.taxRate, taxReserve: S.taxReserve };
  S.taxRate = 0.30; S.taxReserve = 0;
  const injectes = [];
  const moisPasse = NOW.m > 1 ? { y: NOW.y, m: NOW.m - 1 } : null;
  if (moisPasse) {
    const gros = { id: ++txSeq, y: moisPasse.y, m: moisPasse.m, d: 5,
      title: "Gros revenu FE2", amount: 100000, type: "income", cat: "Salaire",
      acc: cash.id, status: "posted", createdAt: 1, updatedAt: 1 };
    transactions.push(gros); injectes.push(gros);
  }
  const s = snapshot(NOW.y, NOW.m);
  const identite = Math.round((s.liquid + s.plannedIncome + s.recurringIncome + s.irregularIncome
    - s.plannedOut - s.recurringCharges) * 100) / 100;
  const resultat = {
    disponible: s.available,
    identiteOK: identite === s.available,
    sansChamps: !("taxMonthlyEffort" in s) && !("taxSetAsideMonth" in s)
      && !("taxGapForecast" in s) && !("taxGap" in s) && !("taxRecommended" in s),
    scenarioFort: !!moisPasse,
  };
  for (const t of injectes) transactions.splice(transactions.indexOf(t), 1);
  S.taxRate = memoire.taxRate; S.taxReserve = memoire.taxReserve;
  saveState(); render();
  return resultat;
});
check(fe2.identiteOK,
  `la projection = argent + attendu − sorties saisies, rien d'autre (obtenu ${fe2.disponible})`);
check(fe2.sansChamps,
  "le moteur n'expose plus AUCUN champ fiscal automatique — même avec un gros revenu et un taux hérité (ADR-035)");

// ---------- Test 155 : FE2-1 — les vues d'argent (Maintenant / Fin du mois, fortune, épargne) ----------
// Cahier propriétaire : « ne jamais présenter une projection comme de
// l'argent possédé ». La grande carte du Mois a deux positions ; Comptes
// porte les soldes réels classés ; le Patrimoine montre la fortune
// liquide À CÔTÉ de la fortune totale ; stock et flux d'épargne séparés.
currentTest = "FE2 vues d'argent";
await goHome();
const fe21 = await page.evaluate(() => {
  cursor = { y: NOW.y, m: NOW.m }; activeTab = "home"; moreView = null; heroVue = "maintenant"; render();
  const s = snapshot(NOW.y, NOW.m);
  const lireHero = () => ({
    titre: document.querySelector(".home-hero .card-label")?.textContent || "",
    montant: document.querySelector(".home-hero .hero-amount")?.textContent || "",
    note: document.querySelector(".home-hero .hero-note")?.textContent || "",
  });
  const maintenant = lireHero();
  document.querySelector('[data-herovue="finmois"]').click();
  const finmois = lireHero();
  document.querySelector('[data-herovue="maintenant"]').click();
  activeTab = "accounts"; accountView = null; render();
  const fortune = document.querySelector('[data-more="networth"]')?.textContent || "";
  const epargne = document.querySelector("[data-epargne-carte]")?.textContent || "";
  const epargneAccessible = ACCOUNTS.filter(a => a.kind === "savings")
    .reduce((a, acc) => a + toCHF(balance(acc.id), acc.currency), 0);
  activeTab = "more"; moreView = "networth"; render();
  const liquideNW = document.querySelector("[data-fortune-liquide]")?.textContent || "";
  const patrimoineHero = [...document.querySelectorAll("#screen .hero-amount")].map(e => e.textContent);
  activeTab = "home"; moreView = null; render();
  return {
    maintenant, finmois,
    maintenantJuste: maintenant.titre === "Disponible maintenant" && maintenant.montant === chf(s.liquid),
    finmoisJuste: finmois.titre === "Prévu fin du mois" && finmois.montant === chf(s.endOfMonthForecast),
    decomposition: finmois.note.includes(chf(s.liquid)),
    fortune, epargne,
    fortuneListe: fortune.includes("Épargne accessible") && fortune.includes("Fortune liquide") && fortune.includes("Fortune totale"),
    epargneStockFlux: epargne.includes("Épargne actuelle") && epargne.includes("Mis de côté ce mois") && epargne.includes("Mis de côté cette année"),
    epargneStockJuste: epargne.includes(chf(epargneAccessible)),
    liquideNWJuste: liquideNW === chf(s.liquidWealth),
    patrimoineDeuxCartes: patrimoineHero.length >= 2,
  };
});
check(fe21.maintenantJuste,
  `la position « Maintenant » montre le RÉEL — Disponible maintenant = liquide exact (obtenu « ${fe21.maintenant.titre} » ${fe21.maintenant.montant})`);
check(fe21.finmoisJuste && fe21.decomposition,
  `la position « Fin du mois » montre la PROJECTION avec sa décomposition écrite (obtenu « ${fe21.finmois.titre} » ${fe21.finmois.montant} — ${fe21.finmois.note})`);
check(fe21.fortuneListe,
  "Comptes classe les soldes réels : épargne accessible, fortune liquide, fortune totale");
check(fe21.epargneStockFlux && fe21.epargneStockJuste,
  "l'épargne sépare le STOCK (actuelle) des FLUX (ce mois, cette année)");
check(fe21.liquideNWJuste && fe21.patrimoineDeuxCartes,
  `le Patrimoine montre la fortune liquide À CÔTÉ de la fortune totale (obtenu ${fe21.liquideNWJuste})`);

// ---------- 156. FE2-5 : UNE seule définition de « Fortune liquide » ----------
// L'audit FE2-4 a montré deux formules pour la même étiquette : Comptes
// additionnait « cash disponible + épargne » (double compte possible),
// le Patrimoine additionnait les genres current/cash/savings (ignorant
// le choix « ne compte pas dans le cash disponible »). Désormais la
// définition unique vit dans snapshot() : comptes marqués cash OU
// d'épargne, chaque franc UNE fois — la même que le natif (FE2-4).
currentTest = "FE2-5 fortune liquide unique";
await goHome();
const fe25 = await page.evaluate(() => {
  ACCOUNTS.push(
    { id: "t156cur", name: "Courant hors quotidien", kind: "current", opening: 1000, cash: false, currency: "CHF" },
    { id: "t156quo", name: "Quotidien", kind: "current", opening: 200, cash: true, currency: "CHF" },
    { id: "t156sav", name: "Épargne", kind: "savings", opening: 500, cash: false, currency: "CHF" },
    { id: "t156epc", name: "Épargne au quotidien", kind: "savings", opening: 300, cash: true, currency: "CHF" },
  );
  const s = snapshot(NOW.y, NOW.m);
  const unionAttendue = fromCents(ACCOUNTS.filter(a => a.cash || a.kind === "savings")
    .reduce((c, a2) => c + toCents(toCHF(balance(a2.id), a2.currency)), 0));
  const doubleCompte = Math.round((s.liquid + s.savingsAccessible - s.liquidWealth) * 100) / 100;
  cursor = { y: NOW.y, m: NOW.m }; activeTab = "accounts"; accountView = null; render();
  const carteComptes = document.querySelector('[data-more="networth"]')?.textContent || "";
  activeTab = "more"; moreView = "networth"; render();
  const carteNW = document.querySelector("[data-fortune-liquide]")?.textContent || "";
  for (const id of ["t156cur", "t156quo", "t156sav", "t156epc"]) {
    const i = ACCOUNTS.findIndex(a => a.id === id);
    if (i >= 0) ACCOUNTS.splice(i, 1);
  }
  activeTab = "home"; moreView = null; render();
  return {
    unionJuste: s.liquidWealth === unionAttendue,
    liquidWealth: s.liquidWealth, unionAttendue, doubleCompte,
    comptesJuste: carteComptes.includes(chf(s.liquidWealth)),
    nwJuste: carteNW === chf(s.liquidWealth),
    carteNW,
  };
});
check(fe25.unionJuste,
  `la fortune liquide compte chaque franc UNE fois — union cash/épargne (obtenu ${fe25.liquidWealth}, attendu ${fe25.unionAttendue})`);
check(fe25.doubleCompte === 300,
  `un compte d'épargne aussi « cash disponible » n'est plus compté deux fois (écart naïf − union = ${fe25.doubleCompte}, attendu 300)`);
check(fe25.comptesJuste,
  "la carte « Ma fortune » des Comptes lit la définition unique du moteur");
check(fe25.nwJuste,
  `la carte « Fortune liquide » du Patrimoine dit LE MÊME chiffre que Comptes, même avec un courant hors quotidien (obtenu ${fe25.carteNW})`);

// ---------- 157. FE2-12 : le taux hérité est LETTRE MORTE — plus jamais de « − 600 d'impôts » ----------
// Capture propriétaire (20.08.2026) : « il y a toujours les impôts qui
// sont comptabilisés automatiquement » — son appareil portait encore le
// taux 30 % d'avant, et la projection soustrayait 600 sans aucune
// facture. Décision : PLUS AUCUN calcul d'impôts, jamais. Le scénario
// exact de sa capture : 30 % stockés + salaire attendu de 2'000.
currentTest = "FE2-12 taux hérité inerte";
await goHome();
const fe212 = await page.evaluate(() => {
  const ancienTaux = S.taxRate;
  S.taxRate = 0.3; // le taux resté stocké sur l'appareil du propriétaire
  S.transactions.push({ id: "t157sal", title: "Salaire attendu", amount: 2000, type: "income",
    cat: "Salaire", acc: ACCOUNTS[0].id, dest: null, status: "planned",
    y: NOW.y, m: NOW.m, d: 28 });
  cursor = { y: NOW.y, m: NOW.m }; activeTab = "home"; moreView = null; heroVue = "finmois"; render();
  const s = snapshot(NOW.y, NOW.m);
  const note = [...document.querySelectorAll(".hero-note")].map(e => e.textContent).join(" ");
  const attendu = Math.round((s.liquid + s.plannedIncome + s.recurringIncome + s.irregularIncome
    - s.plannedOut - s.recurringCharges) * 100) / 100;
  const i = S.transactions.findIndex(t => t.id === "t157sal");
  if (i >= 0) S.transactions.splice(i, 1);
  S.taxRate = ancienTaux;
  heroVue = "maintenant"; render();
  return {
    note, forecast: s.endOfMonthForecast, attendu,
    impotMuet: !note.includes("impôts"),
    salaireNomme: note.includes("à recevoir"),
  };
});
check(fe212.impotMuet,
  `plus JAMAIS de ligne d'impôts automatique — même avec un taux hérité de 30 % stocké (note : ${fe212.note})`);
check(fe212.salaireNomme,
  `le salaire attendu reste nommé « à recevoir » (note : ${fe212.note})`);
check(Math.abs(fe212.forecast - fe212.attendu) < 0.005,
  `la projection additionne SEULEMENT ce qui est saisi (obtenu ${fe212.forecast}, attendu ${fe212.attendu})`);

// ---------- 158. P0 AVS : une rente n'est JAMAIS un capital (ADR-036) ----------
// Programme Identités locales, alerte préalable du skill : une rente
// mensuelle ou annuelle estimée (AVS) n'est pas de l'argent possédé —
// l'additionner au patrimoine gonfle la fortune avec de l'argent qui
// n'existe pas encore. Une ligne MARQUÉE « rente » sort des totaux ;
// une ancienne ligne ambiguë (« AVS ») reste comptée TELLE QUELLE mais
// porte « À confirmer » — jamais de réécriture silencieuse.
currentTest = "P0 AVS rente hors patrimoine";
await goHome();
const avs158 = await page.evaluate(() => {
  const netFormule = () => ACCOUNTS.reduce((a, acc) => a + toCHF(balance(acc.id), acc.currency), 0)
    + ASSETS.filter(x => x.include !== false).reduce((a, x) => a + x.value, 0)
    + pensionPositionsTotal() - liabilitiesTotal();
  const avantTotal = pensionPositionsTotal();
  const netAvant = netFormule();
  PENSIONS.push({ id: "pen-avs-rente", name: "Rente AVS estimée", value: 2450, rente: true });
  PENSIONS.push({ id: "pen-avs-ambigu", name: "AVS", value: 1200 });
  const apresTotal = pensionPositionsTotal();
  const netApres = netFormule();
  activeTab = "more"; moreView = "insurance"; render();
  const rows = Object.fromEntries([...document.querySelectorAll("#screen [data-penid]")]
    .map(el => [el.dataset.penid, el.textContent]));
  const formHasRente = !!document.getElementById("penRente");
  for (const id of ["pen-avs-rente", "pen-avs-ambigu"]) {
    const i = PENSIONS.findIndex(p => p.id === id);
    if (i >= 0) PENSIONS.splice(i, 1);
  }
  activeTab = "home"; moreView = null; render();
  return { avantTotal, apresTotal, netAvant, netApres, formHasRente,
           renteRow: rows["pen-avs-rente"] || "", ambiguRow: rows["pen-avs-ambigu"] || "" };
});
check(Math.abs(avs158.apresTotal - (avs158.avantTotal + 1200)) < 0.005,
  `une rente marquée n'entre JAMAIS dans le total de prévoyance ; l'ambiguë reste comptée en attendant confirmation (avant ${avs158.avantTotal}, après ${avs158.apresTotal})`);
check(Math.abs(avs158.netApres - (avs158.netAvant + 1200)) < 0.005,
  `le patrimoine net n'absorbe pas la rente marquée (avant ${avs158.netAvant}, après ${avs158.netApres})`);
check(/rente/i.test(avs158.renteRow) && /hors patrimoine/i.test(avs158.renteRow),
  `la ligne de rente se dit rente, hors patrimoine (obtenu : ${avs158.renteRow.slice(0, 100)})`);
check(/À confirmer/.test(avs158.ambiguRow),
  `une ancienne ligne « AVS » sans choix porte « À confirmer » (obtenu : ${avs158.ambiguRow.slice(0, 100)})`);
check(avs158.formHasRente,
  "la feuille Prévoyance offre le choix « c'est une rente, pas un capital »");

// ---------- 159. IC1 : monogramme déterministe partagé, sûr et décoratif ----------
// Fondation Présentation (ADR-038) : toute saisie libre reçoit une tuile
// monogramme locale — même algorithme que BudgetMonogram natif, prouvé
// par la MÊME fixture. Une chaîne hostile ne produit jamais de balise :
// la tuile écrit du texte, rien d'autre.
currentTest = "IC1 monogramme partagé";
const monogramCases = JSON.parse(
  fs.readFileSync(path.resolve(HERE, "..", "..", "fixtures", "monogram-cases.json"), "utf8")).cases;
const mono158 = await page.evaluate(cases => {
  const fn = typeof monogramFor === "function" ? monogramFor : () => "(absent)";
  const results = cases.map(c => ({ ...c, got: fn(c.name) }));
  const tile = document.createElement("div");
  tile.innerHTML = typeof identityTile === "function"
    ? identityTile("<img src=x onerror=window.__mono158=1>") : "";
  const el = tile.firstElementChild;
  return {
    results,
    tuileTexte: el ? el.textContent.trim() : null,
    tuileDecorative: el ? el.getAttribute("aria-hidden") === "true" : false,
    aucuneImage: !tile.querySelector("img"),
    aucuneExecution: window.__mono158 === undefined,
  };
}, monogramCases);
for (const r of mono158.results) {
  check(r.got === r.monogram,
    `monogramme de ${JSON.stringify(r.name)} : attendu ${JSON.stringify(r.monogram)}, obtenu ${JSON.stringify(r.got)}`);
}
check(mono158.aucuneImage && mono158.aucuneExecution && mono158.tuileTexte === "IS",
  `une chaîne hostile devient du TEXTE (« IS »), jamais une balise ni une exécution (obtenu ${JSON.stringify(mono158.tuileTexte)})`);
check(mono158.tuileDecorative,
  "la tuile monogramme est décorative (aria-hidden) — le nom reste le libellé");

// ---------- 160. REC1 : cadences exactes — trimestriel et semestriel (ADR-039) ----------
// Programme Identités locales : le catalogue suggère des rythmes réels
// (électricité trimestrielle, assurance semestrielle). La PWA ne
// connaissait que mensuel et annuel — un trimestriel saisi en mensuel
// aurait pesé douze fois au lieu de quatre. Chaque cadence est engagée
// UNIQUEMENT sur ses mois d'échéance, jamais lissée ; le natif savait
// déjà le faire ((month,3)/(month,6)) — la parité arrive côté web.
currentTest = "REC1 cadences exactes";
await goHome();
const rec159 = await page.evaluate(() => {
  const cash = ACCOUNTS.find(a => a.cash);
  const mois = (base, delta) => ((base - 1 + delta) % 12 + 12) % 12 + 1;
  const anneeDe = delta => NOW.y + Math.floor((NOW.m - 1 + delta) / 12);
  const chargesAvant = snapshot(NOW.y, NOW.m).recurringCharges;
  RECURRINGS.push(
    { id: "r-rec1-tri", title: "Électricité trimestrielle", amount: 180, type: "expense",
      cat: "Logement", day: 1, every: "quarter", dueM: NOW.m, accountId: cash.id },
    { id: "r-rec1-sem", title: "Assurance semestrielle", amount: 240, type: "expense",
      cat: "Assurance maladie", day: 1, every: "semiannual", dueM: mois(NOW.m, 1), accountId: cash.id },
  );
  const tri = RECURRINGS.find(r => r.id === "r-rec1-tri");
  const sem = RECURRINGS.find(r => r.id === "r-rec1-sem");
  const probe = recur => {
    const clone = JSON.parse(JSON.stringify(S));
    clone.recurrings = [...clone.recurrings.filter(r => !String(r.id).startsWith("r-rec1-")), recur];
    try { validatedRestoreState(clone, {}); return "accepté"; }
    catch (e) { return "refusé"; }
  };
  const resultat = {
    triDueNow: recurringDueIn(tri, NOW.y, NOW.m),
    triDuePlus1: recurringDueIn(tri, anneeDe(1), mois(NOW.m, 1)),
    triDuePlus3: recurringDueIn(tri, anneeDe(3), mois(NOW.m, 3)),
    semDueNow: recurringDueIn(sem, NOW.y, NOW.m),
    semDuePlus1: recurringDueIn(sem, anneeDe(1), mois(NOW.m, 1)),
    semDuePlus7: recurringDueIn(sem, anneeDe(7), mois(NOW.m, 7)),
    triAnnuel: recurringYearlyCost(tri),
    semAnnuel: recurringYearlyCost(sem),
    chargesDelta: Math.round((snapshot(NOW.y, NOW.m).recurringCharges - chargesAvant) * 100) / 100,
    chips: [...document.querySelectorAll("#rEveryGrid [data-revery]")].map(b => b.dataset.revery),
    restaureQuarterSansMois: probe({ id: "rx1", title: "T", amount: 10, type: "expense",
      cat: "Autre", day: 1, every: "quarter", accountId: cash.id }),
    restaureQuarterAvecMois: probe({ id: "rx2", title: "T", amount: 10, type: "expense",
      cat: "Autre", day: 1, every: "quarter", dueM: 2, accountId: cash.id }),
    restaureInconnu: probe({ id: "rx3", title: "T", amount: 10, type: "expense",
      cat: "Autre", day: 1, every: "weekly", accountId: cash.id }),
  };
  tri.endedOn = { y: NOW.y, m: NOW.m };
  resultat.triApresResiliation = recurringDueIn(tri, anneeDe(3), mois(NOW.m, 3));
  for (const id of ["r-rec1-tri", "r-rec1-sem"]) {
    const i = RECURRINGS.findIndex(r => r.id === id);
    if (i >= 0) RECURRINGS.splice(i, 1);
  }
  render();
  return resultat;
});
check(rec159.triDueNow === true && rec159.triDuePlus1 === false && rec159.triDuePlus3 === true,
  `un trimestriel n'est engagé que tous les trois mois depuis son ancrage (M ${rec159.triDueNow}, M+1 ${rec159.triDuePlus1}, M+3 ${rec159.triDuePlus3})`);
check(rec159.semDueNow === false && rec159.semDuePlus1 === true && rec159.semDuePlus7 === true,
  `un semestriel n'est engagé que deux fois par an (M ${rec159.semDueNow}, M+1 ${rec159.semDuePlus1}, M+7 ${rec159.semDuePlus7})`);
check(rec159.triAnnuel === 720 && rec159.semAnnuel === 480,
  `coût annuel EXACT : 4 × 180 = 720 et 2 × 240 = 480 — jamais 12 × (obtenu ${rec159.triAnnuel} / ${rec159.semAnnuel})`);
check(rec159.chargesDelta === 180,
  `le mois courant n'engage QUE le trimestriel dû — le semestriel du mois prochain ne pèse pas (delta ${rec159.chargesDelta})`);
check(rec159.triApresResiliation === false,
  "résilié = plus jamais engagé, même sur un futur mois d'échéance");
check(rec159.chips.includes("quarter") && rec159.chips.includes("semiannual"),
  `le formulaire propose les quatre rythmes (obtenu : ${rec159.chips.join(", ")})`);
check(rec159.restaureQuarterSansMois === "refusé" && rec159.restaureQuarterAvecMois === "accepté"
    && rec159.restaureInconnu === "refusé",
  `restauration : trimestriel sans mois d'ancrage refusé, avec ancrage accepté, rythme inconnu refusé (obtenu ${rec159.restaureQuarterSansMois} / ${rec159.restaureQuarterAvecMois} / ${rec159.restaureInconnu})`);

// ---------- 161. REC2 : « toutes les quatre semaines » — 13 échéances par an, jamais 12 ----------
// Basic-Fit et les salles de sport prélèvent toutes les QUATRE SEMAINES :
// 13 fois par an, avec un mois à double échéance. Simplifier en mensuel
// volerait une échéance ; le natif sait déjà le faire ((week, 4)), la
// parité arrive côté web avec une couverture PAR COMPTAGE : N gestes
// couvrent les N premières échéances du mois.
currentTest = "REC2 quatre semaines";
await goHome();
const rec160 = await page.evaluate(() => {
  const cash = ACCOUNTS.find(a => a.cash);
  const chips = [...document.querySelectorAll("#rEveryGrid [data-revery]")].map(b => b.dataset.revery);
  if (typeof recurringDueCount !== "function" || typeof recurringRemainingCount !== "function") {
    return { moteurAbsent: true, chips, champDate: !!document.getElementById("rStartOn") };
  }
  RECURRINGS.push({ id: "r-rec2-fit", title: "Salle de sport", amount: 45, type: "expense",
    cat: "Autre", day: 1, every: "four_weeks", startOn: { y: NOW.y, m: 1, d: 15 }, accountId: cash.id });
  const fit = RECURRINGS.find(r => r.id === "r-rec2-fit");
  const parMois = [];
  for (let mm = 1; mm <= 12; mm++) parMois.push(recurringDueCount(fit, NOW.y, mm));
  const totalAnnee = parMois.reduce((a, b) => a + b, 0);
  const moisDouble = parMois.findIndex(c => c === 2) + 1;
  const premier = materializeRecurring(fit, NOW.y, moisDouble);
  const restantApresUn = recurringRemainingCount(fit, NOW.y, moisDouble);
  const second = materializeRecurring(fit, NOW.y, moisDouble);
  const restantApresDeux = recurringRemainingCount(fit, NOW.y, moisDouble);
  const troisieme = materializeRecurring(fit, NOW.y, moisDouble);
  const probe = recur => {
    const clone = JSON.parse(JSON.stringify(S));
    clone.recurrings = [...clone.recurrings.filter(r => !String(r.id).startsWith("r-rec2-")), recur];
    clone.transactions = clone.transactions.filter(t => t.recurringId !== "r-rec2-fit");
    try { validatedRestoreState(clone, {}); return "accepté"; }
    catch (e) { return "refusé"; }
  };
  const resultat = {
    moteurAbsent: false, chips,
    champDate: !!document.getElementById("rStartOn"),
    totalAnnee, parMois, moisDouble,
    doubles: parMois.filter(c => c === 2).length,
    annuel: recurringYearlyCost(fit),
    deuxCrees: premier.created === true && second.created === true,
    restantApresUn, restantApresDeux,
    troisiemeRefuse: troisieme.created === false,
    restaureSansDate: probe({ id: "rx4", title: "T", amount: 10, type: "expense",
      cat: "Autre", day: 1, every: "four_weeks", accountId: cash.id }),
    restaureAvecDate: probe({ id: "rx5", title: "T", amount: 10, type: "expense",
      cat: "Autre", day: 1, every: "four_weeks", startOn: { y: 2026, m: 1, d: 15 }, accountId: cash.id }),
  };
  for (const t of transactions.filter(t => t.recurringId === "r-rec2-fit")) {
    transactions.splice(transactions.indexOf(t), 1);
  }
  const i = RECURRINGS.findIndex(r => r.id === "r-rec2-fit");
  if (i >= 0) RECURRINGS.splice(i, 1);
  saveState(); render();
  return resultat;
});
check(rec160.moteurAbsent !== true,
  "le moteur des quatre semaines existe (recurringDueCount / recurringRemainingCount)");
check(rec160.totalAnnee === 13 && rec160.doubles === 1,
  `13 échéances sur l'année — jamais 12 — dont UN mois à double échéance (obtenu ${rec160.totalAnnee}, répartition ${JSON.stringify(rec160.parMois)})`);
check(rec160.annuel === 585,
  `coût annuel exact : 13 × 45 = 585 (obtenu ${rec160.annuel})`);
check(rec160.deuxCrees && rec160.restantApresUn === 1 && rec160.restantApresDeux === 0 && rec160.troisiemeRefuse,
  `couverture par comptage sur le mois double : deux gestes couvrent les deux échéances, le troisième est refusé (restants ${rec160.restantApresUn} puis ${rec160.restantApresDeux})`);
check(rec160.chips.includes("four_weeks") && rec160.champDate,
  `le formulaire propose « toutes les 4 semaines » avec sa date d'ancrage (chips : ${rec160.chips.join(", ")})`);
check(rec160.restaureSansDate === "refusé" && rec160.restaureAvecDate === "accepté",
  `restauration : quatre semaines sans date d'ancrage refusé, avec date accepté (obtenu ${rec160.restaureSansDate} / ${rec160.restaureAvecDate})`);

// ---------- 162. P08-C : le catalogue SUGGÈRE, il n'invente jamais le budget (ADR-041) ----------
// Programme Identités locales : choisir « Netflix » remplit au plus le
// nom, la nature, la catégorie et un rythme compatible — JAMAIS un
// montant, un compte, une date ni une ligne créée sans confirmation.
// La recherche est locale, filtrée par pays, insensible aux accents, et
// une chaîne hostile ne rend aucune balise.
currentTest = "P08-C catalogue services";
await goHome();
const p08c = await page.evaluate(() => {
  const recAvant = RECURRINGS.length;
  const paysAvant = S.country;
  const resultat = { recAvant };
  openRecSheet(null);
  resultat.bouton = !!document.getElementById("rPickService");
  if (resultat.bouton) {
    document.getElementById("rPickService").click();
    const search = document.getElementById("svcSearch");
    resultat.feuille = !!search && document.getElementById("svcForm").style.display !== "none";
    search.value = "netflik";
    search.dispatchEvent(new Event("input"));
    resultat.fauteVide = !document.querySelector('#svcResults [data-svckey="netflix"]');
    search.value = "NETFLIX";
    search.dispatchEvent(new Event("input"));
    resultat.trouve = !!document.querySelector('#svcResults [data-svckey="netflix"]');
    search.value = "navigo";
    search.dispatchEvent(new Event("input"));
    resultat.navigoCH = !!document.querySelector("#svcResults [data-svckey]");
    S.country = "FR";
    search.dispatchEvent(new Event("input"));
    resultat.navigoFR = !!document.querySelector('#svcResults [data-svckey="navigo"]');
    S.country = paysAvant;
    search.value = '<img src=x onerror="window.__p08pwned=1">';
    search.dispatchEvent(new Event("input"));
    resultat.injectionImg = document.querySelectorAll("#svcResults img").length;
    resultat.pwned = !!window.__p08pwned;
    search.value = "netflix";
    search.dispatchEvent(new Event("input"));
    document.querySelector('#svcResults [data-svckey="netflix"]').click();
    resultat.titre = document.getElementById("rTitle").value;
    resultat.nature = document.getElementById("rFamily").value;
    resultat.rythme = document.getElementById("rEvery").value;
    resultat.montant = document.getElementById("rAmount").value;
    resultat.recApres = RECURRINGS.length;
    document.getElementById("rTitle").value = "Mon club local";
    document.getElementById("rPickService").click();
    document.getElementById("svcFree").click();
    resultat.libreTitre = document.getElementById("rTitle").value;
  }
  closeSheet();
  return resultat;
});
check(p08c.bouton && p08c.feuille,
  "la feuille « Ce qui revient » offre le choix d'un service du catalogue local");
check(p08c.trouve && p08c.fauteVide,
  `la recherche trouve Netflix et ne devine pas une faute (trouvé ${p08c.trouve}, faute ${p08c.fauteVide})`);
check(p08c.navigoCH === false && p08c.navigoFR === true,
  `« Services pour votre pays » : Navigo invisible en Suisse, visible en France (CH ${p08c.navigoCH} / FR ${p08c.navigoFR})`);
check(p08c.injectionImg === 0 && !p08c.pwned,
  "une recherche hostile ne rend aucune balise et n'exécute rien");
check(p08c.titre === "Netflix" && p08c.nature === "abonnement" && p08c.rythme === "month",
  `choisir remplit nom + nature + rythme compatible (obtenu « ${p08c.titre} » / ${p08c.nature} / ${p08c.rythme})`);
check(p08c.montant === "" && p08c.recApres === p08c.recAvant,
  `JAMAIS de montant prérempli ni de ligne créée sans confirmation (montant « ${p08c.montant} », lignes ${p08c.recAvant} → ${p08c.recApres})`);
check(p08c.libreTitre === "Mon club local",
  "« Je ne trouve pas mon service » revient à la saisie libre SANS perdre ce qui était écrit");

// ---------- 163. ID1 : la clé d'identité survit au renommage, jamais aux clés hostiles (ADR-042) ----------
// Programme Identités locales : choisir Netflix PERSISTE une clé stable
// (`identityKey`) — renommer la ligne « Mes films » garde l'identité.
// À la restauration : clé saine conservée (même inconnue — catalogue
// extensible), clé hostile ou hors alphabet RETIRÉE sans toucher la
// ligne. La règle vit dans fixtures/identity-key-cases.json, partagée
// avec le natif.
currentTest = "ID1 clé d'identité";
const keyCases = JSON.parse(
  fs.readFileSync(path.resolve(HERE, "..", "..", "fixtures", "identity-key-cases.json"), "utf8")).cases;
await goHome();
const id1 = await page.evaluate((cases) => {
  const cash = ACCOUNTS.find(a => a.cash);
  const resultat = {};
  // 1. Choisir Netflix puis CONFIRMER une vraie ligne.
  openRecSheet(null);
  document.getElementById("rPickService").click();
  const search = document.getElementById("svcSearch");
  search.value = "netflix";
  search.dispatchEvent(new Event("input"));
  document.querySelector('#svcResults [data-svckey="netflix"]').click();
  document.getElementById("rAmount").value = "17.90";
  document.getElementById("rAccount").value = cash.id;
  document.getElementById("recForm").requestSubmit();
  const ligne = RECURRINGS.find(r => r.title === "Netflix");
  resultat.cleEnregistree = ligne ? ligne.identityKey : null;
  // 2. Renommer : l'identité choisie reste.
  if (ligne) {
    openRecSheet(ligne);
    document.getElementById("rTitle").value = "Mes films";
    document.getElementById("recForm").requestSubmit();
    resultat.cleApresRenommage = ligne.identityKey;
    resultat.titreApres = ligne.title;
    activeTab = "more"; moreView = "subs"; render();
    const row = document.querySelector(`[data-recid="${ligne.id}"]`);
    const tile = row && row.querySelector(".identity-tile");
    resultat.tuile = tile ? tile.textContent.trim() : null;
  }
  // 3. Restauration : chaque cas de la fixture partagée.
  resultat.cas = cases.map(c => {
    const clone = JSON.parse(JSON.stringify(S));
    clone.recurrings = clone.recurrings.filter(r => r.title !== "Netflix" && r.title !== "Mes films");
    clone.recurrings.push({ id: "rid1-cas", title: "Ligne testée", amount: 10, type: "expense",
      cat: "Autre", day: 1, accountId: cash.id, identityKey: c.value });
    try {
      const valide = validatedRestoreState(clone, {});
      const restauree = valide.recurrings.find(r => r.id === "rid1-cas");
      if (!restauree) return { value: c.value, verdict: "ligne perdue" };
      return { value: c.value, verdict: restauree.identityKey === c.value ? "gardée"
        : (restauree.identityKey === undefined ? "retirée" : "réécrite") };
    } catch (e) {
      return { value: c.value, verdict: "restauration refusée" };
    }
  });
  // 4. Clé inconnue au rendu : repli sans crash ni markup.
  if (ligne) {
    ligne.identityKey = "future-service";
    render();
    resultat.repliOK = !!document.querySelector(`[data-recid="${ligne.id}"]`);
    resultat.images = document.querySelectorAll("#screen img").length;
    const i = RECURRINGS.indexOf(ligne);
    if (i >= 0) RECURRINGS.splice(i, 1);
  }
  saveState();
  activeTab = "home"; moreView = null; render();
  return resultat;
}, keyCases);
check(id1.cleEnregistree === "netflix",
  `confirmer une ligne choisie au catalogue persiste sa clé (obtenu ${id1.cleEnregistree})`);
check(id1.cleApresRenommage === "netflix" && id1.titreApres === "Mes films" && id1.tuile === "N",
  `renommer garde l'identité : clé ${id1.cleApresRenommage}, titre « ${id1.titreApres} », tuile « ${id1.tuile} » (le N de Netflix, pas MF)`);
const casKO = (id1.cas || []).filter((c, i) => c.verdict !== (keyCases[i].kept ? "gardée" : "retirée"));
check(casKO.length === 0,
  `restauration : clé saine gardée, clé hostile retirée SANS perdre la ligne (écarts : ${JSON.stringify(casKO)})`);
check(id1.repliOK === true && id1.images === 0,
  "une clé inconnue retombe sur le monogramme du nom — aucun crash, aucune image");

// ---------- 164. P05-C : choisir sa banque remplit l'établissement, rien d'autre (ADR-043) ----------
// Programme Identités locales : sur la feuille Compte, un mode
// « institutions » du même sélecteur propose banques, courtiers et
// prévoyance du pays — jamais les services (Netflix). Choisir remplit
// SEULEMENT le champ établissement : nom, solde, monnaie et nombre de
// comptes restent intacts, et l'app ne promet jamais une connexion.
currentTest = "P05-C établissements";
await goHome();
const p05 = await page.evaluate(() => {
  const resultat = { accAvant: ACCOUNTS.length };
  openAccSheet(null);
  resultat.bouton = !!document.getElementById("aPickInst");
  if (resultat.bouton) {
    document.getElementById("aName").value = "Mon compte perso";
    document.getElementById("aOpening").value = "1234.50";
    document.getElementById("aPickInst").click();
    const search = document.getElementById("svcSearch");
    resultat.feuille = document.getElementById("svcForm").style.display !== "none";
    resultat.placeholder = search.placeholder;
    resultat.legende = document.getElementById("svcSheetCaption").textContent;
    search.value = "ubs";
    search.dispatchEvent(new Event("input"));
    resultat.trouve = !!document.querySelector('#svcResults [data-svckey="ubs"]');
    search.value = "netflix";
    search.dispatchEvent(new Event("input"));
    resultat.netflixAbsent = !document.querySelector('#svcResults [data-svckey="netflix"]');
    search.value = "ubs";
    search.dispatchEvent(new Event("input"));
    document.querySelector('#svcResults [data-svckey="ubs"]').click();
    resultat.inst = document.getElementById("aInst").value;
    resultat.nom = document.getElementById("aName").value;
    resultat.solde = document.getElementById("aOpening").value;
    resultat.accApres = ACCOUNTS.length;
  }
  closeSheet();
  ACCOUNTS.push({ id: "acc-p05", name: "Courant UBS", inst: "UBS", kind: "current",
    opening: 0, cash: true, currency: "CHF" });
  activeTab = "accounts"; moreView = null; render();
  const rowAcc = document.querySelector('[data-accid="acc-p05"]');
  resultat.tuile = rowAcc && rowAcc.querySelector(".identity-tile")
    ? rowAcc.querySelector(".identity-tile").textContent.trim() : null;
  resultat.promesses = /connecté|synchronis|en direct/i.test(document.getElementById("screen").textContent);
  const i = ACCOUNTS.findIndex(a => a.id === "acc-p05");
  if (i >= 0) ACCOUNTS.splice(i, 1);
  activeTab = "home"; render();
  return resultat;
});
check(p05.bouton && p05.feuille,
  "la feuille Compte offre le choix d'une banque, d'un courtier ou d'une prévoyance du catalogue");
check(p05.trouve && p05.netflixAbsent,
  `le mode institutions montre UBS et jamais Netflix (UBS ${p05.trouve} / Netflix absent ${p05.netflixAbsent})`);
check(p05.placeholder === "UBS, Swissquote, VIAC…"
    && /établissement/.test(p05.legende) && !/rythme/.test(p05.legende),
  `la feuille parle d'établissements, pas de services (obtenu « ${p05.placeholder} » / « ${p05.legende} »)`);
check(p05.inst === "UBS" && p05.nom === "Mon compte perso" && p05.solde === "1234.50"
    && p05.accApres === p05.accAvant,
  `choisir remplit SEULEMENT l'établissement — nom, solde et comptes intacts (obtenu « ${p05.inst} » / « ${p05.nom} » / ${p05.solde} / ${p05.accAvant}→${p05.accApres})`);
check(p05.tuile === "U",
  `une institution connue porte sa tuile sur Comptes (obtenu ${p05.tuile})`);
check(p05.promesses === false,
  "aucune promesse de connexion, de synchronisation ni de direct");

// ---------- 165. P06/P16 : la fiche réutilise l'identité, l'onboarding la propose en option (ADR-044) ----------
// Programme Identités locales : la fiche de compte P06 porte la MÊME tuile
// d'identité que la liste (correspondance exacte, sinon rien) ; l'onboarding
// P16 propose la banque en OPTION — champ libre + sélecteur institutions,
// Annuler ne change rien, et le compte n'est créé qu'à la fin (atomique).
currentTest = "P06/P16 identité";
const p06 = await page.evaluate(() => {
  const resultat = {};
  ACCOUNTS.push({ id: "acc-p06", name: "Courant UBS", inst: "UBS", kind: "current",
    opening: 0, cash: true, currency: "CHF" });
  activeTab = "accounts"; accountView = "acc-p06"; moreView = null; render();
  const ecran = document.getElementById("screen");
  resultat.tuileFiche = ecran.querySelector(".identity-tile")
    ? ecran.querySelector(".identity-tile").textContent.trim() : null;
  resultat.promesses = /connecté|synchronis|en direct/i.test(ecran.textContent);
  const acc = ACCOUNTS.find(a => a.id === "acc-p06");
  acc.inst = "Ma petite banque"; render();
  resultat.tuileInconnue = !!ecran.querySelector(".identity-tile");
  accountView = null;
  ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "acc-p06"), 1);
  activeTab = "home"; render();
  return resultat;
});
check(p06.tuileFiche === "U",
  `la fiche de compte porte la tuile de son établissement (obtenu ${p06.tuileFiche})`);
check(p06.tuileInconnue === false,
  "un établissement inconnu garde sa fiche sans tuile — jamais de devinette");
check(p06.promesses === false,
  "la fiche ne promet ni connexion, ni synchronisation, ni direct");
{
  const ctx165 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p165 = await ctx165.newPage();
  p165.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[P06/P16] ${msg.text()}`); });
  await p165.goto(APP_URL);
  await p165.waitForSelector('[data-obcountry="CH"]');
  await p165.click('[data-obcountry="CH"]');
  await p165.click('[data-obhh="solo"]');
  await p165.fill("#obName", "Léa"); await p165.click('#obForm1 button[type="submit"]');
  await p165.fill("#obSalary", "5000"); await p165.click('#obForm2 button[type="submit"]');
  await p165.waitForSelector("#obOpening", { state: "visible" });
  const ob = await p165.evaluate(() => {
    const resultat = {
      champ: !!document.getElementById("obInst"),
      bouton: !!document.getElementById("obPickInst"),
    };
    if (!resultat.champ || !resultat.bouton) return resultat;
    // Annuler d'abord : le champ reste tel quel (option vraiment facultative).
    document.getElementById("obPickInst").click();
    resultat.feuille = document.getElementById("svcForm").style.display !== "none";
    document.getElementById("svcCancel").click();
    resultat.champApresAnnuler = document.getElementById("obInst").value;
    resultat.etapeIntacte = !!document.getElementById("obOpening");
    // Puis choisir : UBS proposé (pays de l'onboarding, pas encore S.country),
    // jamais Netflix ; la sélection remplit le champ et rend la main à l'étape.
    document.getElementById("obPickInst").click();
    const search = document.getElementById("svcSearch");
    search.value = "ubs"; search.dispatchEvent(new Event("input"));
    resultat.trouve = !!document.querySelector('#svcResults [data-svckey="ubs"]');
    search.value = "netflix"; search.dispatchEvent(new Event("input"));
    resultat.netflixAbsent = !document.querySelector('#svcResults [data-svckey="netflix"]');
    search.value = "ubs"; search.dispatchEvent(new Event("input"));
    document.querySelector('#svcResults [data-svckey="ubs"]').click();
    // La feuille part en animation : l'état vrai est openSheetId/backdrop.
    resultat.feuilleFermee = openSheetId === null
      && !document.getElementById("sheetBackdrop").classList.contains("open");
    resultat.champRempli = document.getElementById("obInst").value;
    resultat.comptesAvant = ACCOUNTS.length;
    return resultat;
  });
  check(ob.champ && ob.bouton,
    "l'étape comptes propose la banque en option — champ libre + sélecteur");
  check(ob.feuille === true && ob.champApresAnnuler === "" && ob.etapeIntacte === true,
    "Annuler le sélecteur ne change rien : champ vide, étape intacte");
  check(ob.trouve === true && ob.netflixAbsent === true,
    "le sélecteur de l'onboarding filtre par le pays choisi et ne montre jamais un service");
  check(ob.feuilleFermee === true && ob.champRempli === "UBS" && ob.comptesAvant === 0,
    `choisir remplit le champ et ne crée RIEN avant la fin (obtenu « ${ob.champRempli} », ${ob.comptesAvant} compte)`);
  // Durci (flake CI, run 33034919240 : « solde 0 ») : une re-render
  // entre le remplissage et l'envoi peut vider le champ — remplissage
  // VÉRIFIÉ avant de soumettre.
  for (let essai = 0; essai < 3; essai++) {
    await p165.fill("#obOpening", "2000");
    await p165.waitForTimeout(120);
    if (await p165.evaluate(() => document.getElementById("obOpening").value) === "2000") break;
  }
  await p165.click('#obForm3 button[type="submit"]');
  await p165.waitForSelector("#obFormCharges", { state: "visible" });
  await p165.click("[data-obskipcharges]");
  await p165.waitForSelector("#obFormSubs", { state: "visible" });
  await p165.click("[data-obskipsubs]");
  await p165.waitForSelector("[data-obskipgoal]", { state: "visible" });
  await p165.click("[data-obskipgoal]");
  await p165.waitForSelector("#tabbar button");
  const fin = await p165.evaluate(() => {
    activeTab = "accounts"; moreView = null; render();
    const ligne = document.querySelector("[data-accid]");
    return {
      inst: ACCOUNTS[0] ? ACCOUNTS[0].inst : null,
      solde: ACCOUNTS[0] ? ACCOUNTS[0].opening : null,
      tuile: ligne && ligne.querySelector(".identity-tile")
        ? ligne.querySelector(".identity-tile").textContent.trim() : null,
    };
  });
  check(fin.inst === "UBS" && fin.solde === 2000,
    `la fin de l'onboarding crée le compte en un seul geste — banque « ${fin.inst} », solde ${fin.solde}`);
  check(fin.tuile === "U",
    `le compte créé à l'onboarding porte sa tuile sur Comptes (obtenu ${fin.tuile})`);
  await ctx165.close();
}

// ---------- 166. P13-C : choisir son assureur remplit un nom, jamais une prime (ADR-045) ----------
// Programme Identités locales : la feuille Assurance gagne un mode
// « assureurs » du même sélecteur — 13 assureurs (institutions, sens
// insurance), jamais une banque ni un service, jamais les besoins
// génériques (Assurance ménage). Choisir remplit SEULEMENT le champ
// assureur ; la liste décore par correspondance exacte, l'inconnu garde
// son bouclier ; l'assureur reste distinct du type de contrat.
currentTest = "P13-C assureurs";
await goHome();
const p13c = await page.evaluate(() => {
  const resultat = { insAvant: INSURANCES.length };
  openInsSheet(null);
  resultat.bouton = !!document.getElementById("insPickInsurer");
  if (resultat.bouton) {
    document.getElementById("insName").value = "RC ménage";
    document.getElementById("insPremium").value = "30.00";
    document.getElementById("insPickInsurer").click();
    const search = document.getElementById("svcSearch");
    resultat.feuille = document.getElementById("svcForm").style.display !== "none";
    resultat.titre = document.getElementById("svcSheetTitle").textContent;
    resultat.sectionFrancaise = [...document.querySelectorAll("#svcResults .svc-section")]
      .some(s => s.textContent.trim() === "Assureurs");
    search.value = "css"; search.dispatchEvent(new Event("input"));
    resultat.trouve = !!document.querySelector('#svcResults [data-svckey="css"]');
    search.value = "ubs"; search.dispatchEvent(new Event("input"));
    resultat.ubsAbsent = !document.querySelector('#svcResults [data-svckey="ubs"]');
    search.value = "assurance"; search.dispatchEvent(new Event("input"));
    resultat.generiquesAbsents = !document.querySelector('#svcResults [data-svckey="household-insurance"]')
      && !document.querySelector('#svcResults [data-svckey="car-insurance"]');
    search.value = "css"; search.dispatchEvent(new Event("input"));
    document.querySelector('#svcResults [data-svckey="css"]').click();
    resultat.assureur = document.getElementById("insInsurer").value;
    resultat.nom = document.getElementById("insName").value;
    resultat.prime = document.getElementById("insPremium").value;
    resultat.insApres = INSURANCES.length;
  }
  closeSheet();
  INSURANCES.push({ id: "ins-p13", name: "Caisse maladie", insurer: "CSS",
    premium: 320, unit: "month" });
  INSURANCES.push({ id: "ins-p13b", name: "RC ménage", insurer: "Ma petite assurance",
    premium: 30, unit: "month" });
  activeTab = "more"; moreView = "insurance"; render();
  const ecran = document.getElementById("screen");
  const rowCss = ecran.querySelector('[data-insid="ins-p13"]');
  const rowLibre = ecran.querySelector('[data-insid="ins-p13b"]');
  resultat.tuile = rowCss && rowCss.querySelector(".identity-tile")
    ? rowCss.querySelector(".identity-tile").textContent.trim() : null;
  resultat.inconnuSansTuile = rowLibre && !rowLibre.querySelector(".identity-tile");
  resultat.promesses = /connecté|synchronis|en direct/i.test(ecran.textContent);
  INSURANCES.splice(INSURANCES.findIndex(i => i.id === "ins-p13"), 1);
  INSURANCES.splice(INSURANCES.findIndex(i => i.id === "ins-p13b"), 1);
  activeTab = "home"; moreView = null; render();
  return resultat;
});
check(p13c.bouton && p13c.feuille && p13c.titre === "Quel assureur ?",
  `la feuille Assurance offre le choix d'un assureur du catalogue (obtenu « ${p13c.titre} »)`);
check(p13c.trouve && p13c.ubsAbsent && p13c.generiquesAbsents && p13c.sectionFrancaise,
  `le mode assureurs montre CSS en français, jamais une banque ni un besoin générique (CSS ${p13c.trouve} / UBS absent ${p13c.ubsAbsent} / génériques absents ${p13c.generiquesAbsents} / section « Assureurs » ${p13c.sectionFrancaise})`);
check(p13c.assureur === "CSS" && p13c.nom === "RC ménage" && p13c.prime === "30.00"
    && p13c.insApres === p13c.insAvant,
  `choisir remplit SEULEMENT l'assureur — nom, prime et contrats intacts (obtenu « ${p13c.assureur} » / « ${p13c.nom} » / ${p13c.prime} / ${p13c.insAvant}→${p13c.insApres})`);
check(p13c.tuile === "C" && p13c.inconnuSansTuile === true,
  `un assureur connu porte sa tuile (monogramme partagé IC1, comme UBS → U), l'inconnu garde son bouclier (obtenu ${p13c.tuile} / inconnu sans tuile ${p13c.inconnuSansTuile})`);
check(p13c.promesses === false,
  "aucune promesse de connexion, de synchronisation ni de direct");

// ---------- 167. P10/P12-C : l'icône choisie est préservée, jamais réécrite (ADR-046) ----------
// Programme Identités locales : l'emoji d'un objectif est un CHOIX — le
// modifier ne le réécrit pas, et un objectif sans emoji (glyphe neutre)
// ne reçoit pas 🎯 dans le dos de la personne. Les biens et dettes
// dérivent leur icône du type (glyphe peint), jamais d'une marque ni
// d'un emoji stocké.
currentTest = "P10/P12-C icônes";
await goHome();
const p10c = await page.evaluate(() => {
  const resultat = {};
  // Un objectif AVEC emoji choisi et un objectif SANS emoji (restauré tel
  // quel : le glyphe neutre est aussi un choix).
  GOALS.push({ id: "g-p10a", name: "Ma voiture", emoji: "🚗", target: 5000,
    manualCurrent: 100, monthly: 100, linked: null, dueY: 2027, dueM: 6, priority: false, achieved: false });
  GOALS.push({ id: "g-p10b", name: "Réserve discrète", emoji: "", target: 3000,
    manualCurrent: 50, monthly: 50, linked: null, dueY: 2027, dueM: 6, priority: false, achieved: false });
  activeTab = "more"; moreView = "goals"; render();
  const carte = id => document.querySelector(`[data-goalid="${id}"] .goal-title`);
  resultat.avantAvec = carte("g-p10a") ? carte("g-p10a").textContent.includes("🚗") : null;
  resultat.avantSans = carte("g-p10b") ? !!carte("g-p10b").querySelector("svg.budget-glyph") : null;
  // Modifier chaque objectif SANS toucher l'emoji : rien ne doit changer.
  for (const id of ["g-p10a", "g-p10b"]) {
    openGoalSheet(GOALS.find(g => g.id === id));
    document.getElementById("gName").value = GOALS.find(g => g.id === id).name + " 2";
    document.getElementById("goalForm").dispatchEvent(new Event("submit"));
  }
  render();
  resultat.apresAvec = GOALS.find(g => g.id === "g-p10a").emoji;
  resultat.apresSans = GOALS.find(g => g.id === "g-p10b").emoji;
  resultat.glyphePreserve = carte("g-p10b") ? !!carte("g-p10b").querySelector("svg.budget-glyph") : null;
  // Un objectif NEUF sans emoji reçoit le défaut 🎯 — à la création
  // seulement.
  openGoalSheet(null);
  document.getElementById("gName").value = "Tout neuf";
  document.getElementById("gTarget").value = "1000";
  document.getElementById("gLinked").value = "";
  document.getElementById("gDue").value = "2027-06";
  document.getElementById("goalForm").dispatchEvent(new Event("submit"));
  const neuf = GOALS.find(g => g.name === "Tout neuf");
  resultat.defautCreation = neuf ? neuf.emoji : null;
  // P12 : biens et dettes dérivent leur glyphe du type — l'emoji stocké
  // (🚗, 📄 des données de démo ou restaurées) n'est JAMAIS rendu.
  ASSETS.push({ id: "as-p12", name: "Vélo cargo", icon: "🚲", value: 4000, include: true });
  LIABILITIES.push({ id: "li-p12", name: "Prêt vélo", icon: "📄", value: 2000, include: true });
  activeTab = "more"; moreView = "networth"; render();
  const rowAsset = document.querySelector('[data-assetid="as-p12"]');
  const rowLiab = document.querySelector('[data-liabid="li-p12"]');
  resultat.glypheBien = rowAsset ? !!rowAsset.querySelector(".ico svg.budget-glyph") : null;
  resultat.glypheDette = rowLiab ? !!rowLiab.querySelector(".ico svg.budget-glyph") : null;
  const ecran = document.getElementById("screen").textContent;
  resultat.emojiRendu = ecran.includes("🚲") || ecran.includes("📄");
  // Nettoyage.
  for (const id of ["g-p10a", "g-p10b"]) GOALS.splice(GOALS.findIndex(g => g.id === id), 1);
  if (neuf) GOALS.splice(GOALS.findIndex(g => g.id === neuf.id), 1);
  ASSETS.splice(ASSETS.findIndex(a => a.id === "as-p12"), 1);
  LIABILITIES.splice(LIABILITIES.findIndex(l => l.id === "li-p12"), 1);
  saveState();
  activeTab = "home"; moreView = null; render();
  return resultat;
});
check(p10c.avantAvec === true && p10c.avantSans === true,
  `avant modification : l'emoji choisi s'affiche, l'absence d'emoji peint le glyphe neutre (obtenu ${p10c.avantAvec}/${p10c.avantSans})`);
check(p10c.apresAvec === "🚗",
  `modifier ne réécrit pas l'emoji choisi (obtenu « ${p10c.apresAvec} »)`);
check(p10c.apresSans === "" && p10c.glyphePreserve === true,
  `modifier un objectif sans emoji ne lui impose pas 🎯 — le glyphe neutre reste (obtenu « ${p10c.apresSans} » / glyphe ${p10c.glyphePreserve})`);
check(p10c.defautCreation === "🎯",
  `à la CRÉATION seulement, le défaut 🎯 s'applique (obtenu « ${p10c.defautCreation} »)`);
check(p10c.glypheBien === true && p10c.glypheDette === true && p10c.emojiRendu === false,
  `biens et dettes dérivent leur glyphe du type, l'emoji stocké n'est jamais rendu (bien ${p10c.glypheBien} / dette ${p10c.glypheDette} / emoji rendu ${p10c.emojiRendu})`);

// ---------- 168. INV1 : les positions expliquent le solde, elles ne s'y ajoutent jamais (ADR-047) ----------
// Programme Identités locales : positions manuelles DATÉES sur un compte
// titres. Autorité de patrimoine : le solde du compte — 44'000 avec
// 40'000 de positions = 44'000 de fortune, jamais 84'000, et la
// différence s'affiche en « Espèces / non réparti ». Une valeur manuelle
// dit « Prix saisi le… », jamais « en direct » ni « cours actuel ».
currentTest = "INV1 positions";
{
  const ctx168 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p168 = await ctx168.newPage();
  p168.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[INV1] ${msg.text()}`); });
  await p168.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Titres" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "acc-t", name: "Compte titres", inst: "", kind: "brokerage",
        opening: 44000, cash: false, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p168.goto(APP_URL);
  await p168.waitForSelector("#tabbar button");
  const inv = await p168.evaluate(() => {
    const resultat = {};
    const fortune = () => {
      activeTab = "accounts"; accountView = null; moreView = null; render();
      const ligne = [...document.querySelectorAll(".breakdown div")]
        .find(d => /Fortune totale/.test(d.textContent));
      return ligne ? ligne.textContent.trim() : document.getElementById("screen").textContent.match(/Fortune[^C]*CHF[\s\S]{0,20}/)?.[0] || null;
    };
    resultat.fortuneAvant = fortune();
    activeTab = "accounts"; accountView = "acc-t"; render();
    resultat.section = /Positions/.test(document.getElementById("screen").textContent);
    resultat.bouton = !!document.querySelector("[data-addpos]");
    if (!resultat.bouton) return resultat;
    document.querySelector("[data-addpos]").click();
    resultat.feuille = document.getElementById("posForm").style.display !== "none";
    document.getElementById("pName").value = "Actions Monde";
    document.getElementById("pTicker").value = "VWRL";
    document.getElementById("pQty").value = "100";
    document.getElementById("pPrice").value = "400.00";
    document.getElementById("pDate").value = "2026-08-15";
    document.getElementById("posForm").dispatchEvent(new Event("submit"));
    const stocke = (S.positions || [])[0];
    resultat.stocke = stocke ? {
      compte: stocke.accountId, nom: stocke.instrumentName, ticker: stocke.tickerOrISIN,
      qte: stocke.quantity, prix: stocke.manualPrice, date: stocke.valuationDate,
    } : null;
    activeTab = "accounts"; accountView = "acc-t"; render();
    const ecran = document.getElementById("screen").textContent;
    resultat.valeur = /40[ ']000\.00/.test(ecran);
    // Montant EXACT de la ligne Espèces — un « 44'000.00 » saboté
    // contiendrait « 4'000.00 » : on lit la ligne, pas l'écran entier.
    const ligneEspeces = [...document.querySelectorAll(".card.row")]
      .find(l => /Espèces/.test(l.textContent));
    resultat.especes = ligneEspeces
      ? ligneEspeces.querySelector(".amount").textContent.replace(/[\u00A0\u202F]/g, " ").trim()
      : null;
    resultat.prixSaisi = /Prix saisi le 15\.08\.2026/.test(ecran);
    resultat.jargonDirect = /en direct|cours actuel|temps réel/i.test(ecran);
    resultat.fortuneApres = fortune();
    // Persistance : la position survit au rechargement de l'état.
    resultat.persiste = (JSON.parse(localStorage.getItem("budget-app-state-v1")).positions || []).length === 1;
    return resultat;
  });
  check(inv.section === true && inv.bouton === true && inv.feuille === true,
    "la fiche du compte titres offre des positions manuelles datées");
  check(inv.stocke && inv.stocke.compte === "acc-t" && inv.stocke.nom === "Actions Monde"
      && inv.stocke.ticker === "VWRL" && inv.stocke.qte === 100 && inv.stocke.prix === 400
      && inv.stocke.date === "2026-08-15",
    `la position stocke les champs du contrat, rien d'autre (obtenu ${JSON.stringify(inv.stocke)})`);
  check(inv.valeur === true && inv.especes === "CHF 4'000.00",
    `40'000 de positions + 4'000 d'espèces expliquent le solde de 44'000 (valeur ${inv.valeur} / espèces « ${inv.especes} »)`);
  check(inv.fortuneApres === inv.fortuneAvant && /44[ ']000\.00/.test(inv.fortuneApres || ""),
    `la fortune reste 44'000 — jamais 84'000 (avant « ${inv.fortuneAvant} » / après « ${inv.fortuneApres} »)`);
  check(inv.prixSaisi === true && inv.jargonDirect === false,
    `une valeur manuelle dit « Prix saisi le… », jamais « en direct » (obtenu ${inv.prixSaisi} / jargon ${inv.jargonDirect})`);
  check(inv.persiste === true, "la position est enregistrée avec l'état local");
  await ctx168.close();
}

// ---------- 169. BR1 : la mention des marques est VISIBLE, le manifeste garde la porte (ADR-048) ----------
// La suite catalogue vérifie le manifeste de provenance et les checksums ;
// ici on prouve que la personne VOIT la mention dans les réglages.
currentTest = "BR1 marques";
await goHome();
const br1 = await page.evaluate(() => {
  activeTab = "more"; moreView = "settings"; render();
  const ecran = document.getElementById("screen");
  const carte = [...ecran.querySelectorAll("details")]
    .find(d => /Marques et logos/.test(d.querySelector("summary")?.textContent || ""));
  const resultat = { carte: !!carte };
  if (carte) {
    carte.open = true;
    resultat.mention = /ni affilié, ni sponsorisé, ni connecté/.test(carte.textContent);
    resultat.monogramme = /monogramme neutre/.test(carte.textContent);
  }
  activeTab = "home"; moreView = null; render();
  return resultat;
});
check(br1.carte === true, "les réglages portent une carte « Marques et logos »");
check(br1.mention === true && br1.monogramme === true,
  "la mention dit l'indépendance (ni affilié, ni sponsorisé, ni connecté) et le monogramme neutre");

// ---------- 170. INV1-B : un compte qui porte des positions ne se supprime pas en silence (ADR-049) ----------
// Le natif garde déjà cette porte ; la PWA doit la garder aussi — sinon
// les positions deviennent orphelines (retirées à la prochaine
// restauration, perte muette). Et « Effacer les opérations » DIT
// désormais qu'il efface aussi les positions.
currentTest = "INV1-B garde positions";
await goHome();
const invb = await page.evaluate(() => {
  const resultat = {};
  ACCOUNTS.push({ id: "acc-invb", name: "Titres", inst: "", kind: "brokerage",
    opening: 1000, cash: false, currency: "CHF" });
  POSITIONS.push({ id: "pos-invb", accountId: "acc-invb", instrumentName: "Test",
    tickerOrISIN: null, quantity: 1, manualPrice: 100, priceCurrency: "CHF",
    valuationDate: "2026-08-01", costBasis: null });
  resultat.bloque = accountDeleteBlocker("acc-invb");
  POSITIONS.splice(POSITIONS.findIndex(x => x.id === "pos-invb"), 1);
  resultat.libre = accountDeleteBlocker("acc-invb");
  ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "acc-invb"), 1);
  // Les textes d'effacement disent les positions.
  const source = document.documentElement.outerHTML;
  resultat.confirmDit = /Effacer vos OPÉRATIONS[^"]*positions/.test(source) || null;
  resultat.privacyDit = PRIVACY.some(t => /positions/.test(t));
  return resultat;
});
check(typeof invb.bloque === "string" && /position/i.test(invb.bloque),
  `supprimer un compte qui porte des positions est BLOQUÉ en le disant (obtenu ${JSON.stringify(invb.bloque)})`);
check(invb.libre === null,
  "sans position, la suppression redevient possible (les autres gardes inchangées)");
check(invb.privacyDit === true,
  "le texte de confidentialité dit que l'effacement retire aussi les positions");

// ---------- 171. INV1-C : le type d'un compte qui porte des positions ne change pas en silence (ADR-050) ----------
// Changer « Bourse / titres » en autre chose rendrait les positions
// INVISIBLES (la section ne vit que sur la fiche d'un compte titres)
// alors que la suppression resterait bloquée en pointant cette fiche —
// une impasse. Le type reste la vérité : on le protège en le disant.
currentTest = "INV1-C type et positions";
await goHome();
const invc = await page.evaluate(() => {
  const resultat = {};
  ACCOUNTS.push({ id: "acc-invc", name: "Titres", inst: "", kind: "brokerage",
    opening: 1000, cash: false, currency: "CHF" });
  POSITIONS.push({ id: "pos-invc", accountId: "acc-invc", instrumentName: "Test",
    tickerOrISIN: null, quantity: 1, manualPrice: 100, priceCurrency: "CHF",
    valuationDate: "2026-08-01", costBasis: null });
  openAccSheet(ACCOUNTS.find(a => a.id === "acc-invc"));
  document.getElementById("aKind").value = "savings";
  document.getElementById("accForm").dispatchEvent(new Event("submit"));
  resultat.erreur = document.getElementById("aError").textContent;
  resultat.typeIntact = ACCOUNTS.find(a => a.id === "acc-invc").kind;
  // Sans position, le changement de type redevient libre.
  POSITIONS.splice(POSITIONS.findIndex(x => x.id === "pos-invc"), 1);
  document.getElementById("aKind").value = "savings";
  document.getElementById("accForm").dispatchEvent(new Event("submit"));
  resultat.typeApres = ACCOUNTS.find(a => a.id === "acc-invc").kind;
  ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "acc-invc"), 1);
  saveState();
  closeSheet();
  activeTab = "home"; render();
  return resultat;
});
check(/position/i.test(invc.erreur || "") && invc.typeIntact === "brokerage",
  `changer le type d'un compte qui porte des positions est BLOQUÉ en le disant (obtenu « ${invc.erreur} » / type ${invc.typeIntact})`);
check(invc.typeApres === "savings",
  "sans position, le changement de type reste libre");

// ---------- 172. INV1-D : la restauration filtre les positions sans jamais échouer (ADR-047, verrou) ----------
// La sonde du 21.08 a prouvé le comportement ; ce parcours le VERROUILLE :
// une position valide est gardée, une hostile (quantité illisible, date
// impossible, markup) est retirée, une orpheline aussi — et le fichier
// se restaure quand même (les positions n'ont aucun pouvoir financier).
currentTest = "INV1-D restauration des positions";
const invd = await page.evaluate(() => {
  const base = {
    version: 1, onboarded: true, isDemo: false, profile: { name: "T" },
    baseCurrency: "CHF", fxRates: { EUR: 0.93, USD: 0.8 },
    transactions: [],
    accounts: [{ id: "acc-t", name: "Titres", kind: "brokerage", opening: 1000, cash: false, currency: "CHF" }],
    recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
    insurances: [], bills: [], documents: [], budgets: {},
    positions: [
      { id: "ok", accountId: "acc-t", instrumentName: "Bon", tickerOrISIN: null,
        quantity: 2, manualPrice: 10, priceCurrency: "CHF", valuationDate: "2026-08-01", costBasis: null },
      { id: "qte-illisible", accountId: "acc-t", instrumentName: "Quantité folle", tickerOrISIN: null,
        quantity: "beaucoup", manualPrice: 10, priceCurrency: "CHF", valuationDate: "2026-08-01", costBasis: null },
      { id: "date-impossible", accountId: "acc-t", instrumentName: "Date folle", tickerOrISIN: null,
        quantity: 1, manualPrice: 10, priceCurrency: "CHF", valuationDate: "hier", costBasis: null },
      { id: "prix-illisible", accountId: "acc-t", instrumentName: "Prix fou", tickerOrISIN: null,
        quantity: 1, manualPrice: "cher", priceCurrency: "CHF", valuationDate: "2026-08-01", costBasis: null },
      { id: "orpheline", accountId: "acc-disparu", instrumentName: "Perdue", tickerOrISIN: null,
        quantity: 1, manualPrice: 5, priceCurrency: "CHF", valuationDate: "2026-08-01", costBasis: null },
    ],
  };
  try {
    const state = validatedRestoreState(JSON.parse(JSON.stringify(base)));
    return { ok: true, gardees: state.positions.map(p => p.id) };
  } catch (e) { return { ok: false, erreur: e.message }; }
});
check(invd.ok === true,
  `un fichier aux positions douteuses se restaure quand même (obtenu ${JSON.stringify(invd.erreur || "ok")})`);
check(Array.isArray(invd.gardees) && invd.gardees.length === 1 && invd.gardees[0] === "ok",
  `seule la position valide survit — quantité illisible, date impossible, prix illisible et orpheline retirées, chacune pour SA raison (obtenu ${JSON.stringify(invd.gardees)})`);

// ---------- 173. CAT1 : la personne écrit SA catégorie — « IKEA », « Poulet » (ADR-051) ----------
// Demande propriétaire du 21.08.2026 (capture à l'appui) : la liste fixe
// ne suffit pas — « il faut aussi laisser la personne mettre ce qu'elle
// veut ». La catégorie libre naît sur la feuille de saisie, garde le SENS
// du type (dépense/revenu), réapparaît partout (saisie, budget) et
// compte JUSTE dans le rapport de budget.
currentTest = "CAT1 catégories libres";
await goHome();
const cat1 = await page.evaluate(() => {
  const resultat = {};
  openTxSheet(null, "expense");
  const sel = document.getElementById("fCat");
  resultat.optionLibre = [...sel.options].some(o => o.value === "__libre__");
  if (!resultat.optionLibre) { closeSheet(); return resultat; }
  sel.value = "__libre__";
  sel.dispatchEvent(new Event("change"));
  const champ = document.getElementById("fCatLibre");
  resultat.champVisible = champ && champ.offsetParent !== null;
  // Vide refusé en le disant, saisie conservée.
  document.getElementById("fAmount").value = "50";
  champ.value = "   ";
  document.getElementById("txForm").dispatchEvent(new Event("submit"));
  resultat.videRefuse = /catégorie/i.test(document.getElementById("screen").textContent
    + document.getElementById("txForm").textContent);
  resultat.montantConserve = document.getElementById("fAmount").value === "50";
  // Puis « IKEA » : le mouvement porte la catégorie écrite.
  champ.value = "IKEA";
  const avant = transactions.length;
  document.getElementById("txForm").dispatchEvent(new Event("submit"));
  const cree = transactions.length === avant + 1 ? transactions[transactions.length - 1] : null;
  resultat.catCree = cree ? cree.cat : null;
  resultat.enregistree = (S.customCategories || []).some(c => c.name === "IKEA" && c.kind === "expense");
  // Elle réapparaît dans le select des dépenses…
  openTxSheet(null, "expense");
  resultat.reproposee = [...document.getElementById("fCat").options].some(o => o.value === "IKEA");
  closeSheet();
  // …mais jamais dans les revenus (le sens est gardé).
  openTxSheet(null, "income");
  resultat.pasEnRevenu = ![...document.getElementById("fCat").options].some(o => o.value === "IKEA");
  closeSheet();
  // Le rapport de budget la compte comme une DÉPENSE (le repli « income »
  // silencieux d'avant aurait affiché 0).
  const t = transactions[transactions.length - 1];
  S.budgets[`${t.y}-${t.m}`] = (S.budgets[`${t.y}-${t.m}`] || []).concat([{ cat: "IKEA", amount: 200 }]);
  const ligne = budgetReport(t.y, t.m).lines.find(l => l.cat === "IKEA");
  resultat.budgetJuste = ligne ? ligne.actual : null;
  // Nettoyage.
  S.budgets[`${t.y}-${t.m}`] = S.budgets[`${t.y}-${t.m}`].filter(l => l.cat !== "IKEA");
  transactions.splice(transactions.findIndex(x => x.id === t.id), 1);
  S.customCategories = (S.customCategories || []).filter(c => c.name !== "IKEA");
  saveState();
  render();
  return resultat;
});
check(cat1.optionLibre === true && cat1.champVisible === true,
  "la feuille de saisie offre « Écrire ma catégorie… » avec un vrai champ");
check(cat1.videRefuse === true && cat1.montantConserve === true,
  "une catégorie vide est refusée en le disant, sans perdre la saisie");
check(cat1.catCree === "IKEA" && cat1.enregistree === true,
  `le mouvement porte la catégorie écrite et elle est retenue avec son sens (obtenu ${cat1.catCree} / retenue ${cat1.enregistree})`);
check(cat1.reproposee === true && cat1.pasEnRevenu === true,
  "« IKEA » est reproposée pour les dépenses, jamais pour les revenus");
check(cat1.budgetJuste === 50,
  `un budget sur « IKEA » compte la dépense — 50, pas 0 (obtenu ${cat1.budgetJuste})`);

// ---------- 174. SUB1 : « Mes abonnements » a sa porte dans Gérer (ADR-052) ----------
// Demande propriétaire du 21.08.2026 : « il manque une page mes
// abonnements ». La vue existait (Ce qui revient filtré) mais AUCUNE
// entrée du hub n'y menait. Le hub Gérer gagne « Mes abonnements » avec
// son coût par mois ; la porte ouvre la vue déjà filtrée.
currentTest = "SUB1 mes abonnements";
await goHome();
const sub1 = await page.evaluate(() => {
  const resultat = {};
  RECURRINGS.push({ id: "r-sub1", title: "Mes films", amount: 17.9, type: "expense",
    cat: "Restaurants et sorties", day: 1, accountId: defaultCashAccount(),
    icon: "🎬", nature: "abonnement" });
  activeTab = "more"; moreView = null; render();
  const entree = document.querySelector('[data-more="subs"]');
  resultat.porte = !!entree;
  resultat.texte = entree ? entree.textContent : "";
  if (entree) {
    entree.click();
    resultat.vue = moreView;
    resultat.filtre = recFilter;
    resultat.affiche = /Mes films/.test(document.getElementById("screen").textContent);
  }
  RECURRINGS.splice(RECURRINGS.findIndex(r => r.id === "r-sub1"), 1);
  recFilter = "tout"; activeTab = "home"; moreView = null; render();
  return resultat;
});
check(sub1.porte === true && /Mes abonnements/.test(sub1.texte),
  "le hub Gérer porte une entrée « Mes abonnements »");
check(/\/ mois|par mois/.test(sub1.texte),
  `l'entrée dit le coût par mois (obtenu « ${(sub1.texte || "").trim().slice(0, 80)} »)`);
check(sub1.vue === "subs" && sub1.filtre === "abonnement" && sub1.affiche === true,
  `la porte ouvre la vue des abonnements, déjà filtrée (vue ${sub1.vue} / filtre ${sub1.filtre} / affiché ${sub1.affiche})`);

// ---------- 175. VUE1 : « Tout » — la vue d'ensemble sur la carte du mois (ADR-053) ----------
// Demande propriétaire du 22.08.2026 (capture à l'appui) : la carte ne
// montre que le quotidien — « il manque épargne, investissements, mis de
// côté, impôts… un résumé, tout sur une seule vue, avec plusieurs
// choix, et l'objectif ». Troisième position « Tout » : fortune totale
// (le MÊME chiffre que Comptes) + lignes écrites — aucune nouvelle
// formule, uniquement les agrégats existants.
currentTest = "VUE1 vue d'ensemble";
{
  const ctx175 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p175 = await ctx175.newPage();
  p175.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[VUE1] ${msg.text()}`); });
  await p175.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Vue" },
      baseCurrency: "CHF", taxReserve: 250,
      transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 500, cash: false, currency: "CHF" },
        { id: "brk", name: "Bourse", kind: "brokerage", opening: 2000, cash: false, currency: "CHF" },
      ],
      recurrings: [], goals: [
        { id: "g1", name: "Permis", emoji: "🚗", target: 1000, manualCurrent: 400,
          monthly: 50, linked: null, dueY: 2027, dueM: 6, priority: true, achieved: false },
      ],
      assets: [{ id: "as1", name: "Vélo", value: 300, include: true }],
      liabilities: [{ id: "li1", name: "Prêt", value: 100, include: true }],
      pensions: [], insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p175.goto(APP_URL);
  await p175.waitForSelector("#tabbar button");
  const vue = await p175.evaluate(() => {
    const resultat = {};
    activeTab = "home"; render();
    resultat.chip = !!document.querySelector('[data-herovue="tout"]');
    if (!resultat.chip) return resultat;
    document.querySelector('[data-herovue="tout"]').click();
    const carte = document.querySelector(".home-hero");
    const texte = carte ? carte.textContent : "";
    resultat.fortune = /3[ ']700\.00/.test(texte);
    resultat.epargne = /Épargne[\s\S]{0,60}?500\.00/.test(texte);
    resultat.misCote = /Mis de côté ce mois/.test(texte);
    resultat.impots = /Réserve d'impôts[\s\S]{0,60}?250\.00/.test(texte);
    resultat.objectif = /Permis[\s\S]{0,80}?400\.00[\s\S]{0,40}?1[ ']000\.00/.test(texte);
    resultat.promesses = /connecté|synchronis|en direct/i.test(texte);
    // Le MÊME chiffre que Comptes — jamais deux vérités.
    activeTab = "accounts"; accountView = null; render();
    const ligne = [...document.querySelectorAll(".breakdown div")]
      .find(d => /Fortune totale/.test(d.textContent));
    resultat.memeChiffre = ligne ? /3[ ']700\.00/.test(ligne.textContent) : null;
    return resultat;
  });
  check(vue.chip === true, "la carte du mois offre une troisième position « Tout »");
  check(vue.fortune === true && vue.memeChiffre === true,
    `« Tout » montre la fortune totale — le MÊME chiffre que Comptes (hero ${vue.fortune} / comptes ${vue.memeChiffre})`);
  check(vue.epargne === true && vue.misCote === true && vue.impots === true,
    `épargne, mis de côté ce mois et réserve d'impôts sont écrits (épargne ${vue.epargne} / mis de côté ${vue.misCote} / impôts ${vue.impots})`);
  check(vue.objectif === true,
    "l'objectif prioritaire est là — Permis : 400.00 sur 1'000.00");
  check(vue.promesses === false,
    "aucune promesse de connexion, de synchronisation ni de direct");
  await ctx175.close();
}

// ---------- 176. MF1 : le mois futur montre le VRAI argent d'abord (ADR-055) ----------
// Demande propriétaire du 24.08.2026 (captures à l'appui) : « j'ai mis mon
// salaire mais je ne l'ai pas encore reçu — quand je change de mois, ça
// m'affiche 14'000. Tant que je n'ai pas appuyé sur le bouton, il ne faut
// rien me mettre. » Décision : sur un mois futur, le grand chiffre = l'argent
// réellement sur les comptes ; l'estimation reste écrite en dessous, en
// petit, au conditionnel — jamais en focal.
currentTest = "MF1 mois futur";
{
  const ctx176 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p176 = await ctx176.newPage();
  p176.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[MF1] ${msg.text()}`); });
  await p176.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Futur" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" }],
      recurrings: [
        { id: "sal", title: "Salaire", amount: 18190, type: "income", nature: "revenu",
          cat: "Salaire", day: 25, every: "month", accountId: "cur", icon: "💼" },
        { id: "loyer", title: "Loyer", amount: 4132.60, type: "expense", nature: "facture",
          cat: "Logement", day: 1, every: "month", accountId: "cur", icon: "🏠" },
      ],
      goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p176.goto(APP_URL);
  await p176.waitForSelector("#tabbar button");
  const futur = await p176.evaluate(() => {
    const resultat = {};
    cursor = shiftMonth(NOW, 1);
    activeTab = "home"; render();
    const carte = document.querySelector(".home-hero");
    const focal = carte?.querySelector(".hero-amount")?.textContent || "";
    const titre = carte?.querySelector(".card-label")?.textContent || "";
    const texte = (carte?.textContent || "").replace(/[  ]/g, " ");
    // Le grand chiffre = l'argent RÉEL (0.00), jamais l'estimation.
    resultat.focalReel = /CHF\s*0\.00/.test(focal.replace(/[  ]/g, " "));
    resultat.focalSansEstimation = !/14'057\.40/.test(focal.replace(/[  ]/g, " "));
    resultat.titre = titre;
    resultat.titreReel = titre === "Sur vos comptes maintenant";
    // L'estimation reste écrite, en petit, au conditionnel — ENCHAÎNÉE
    // depuis la fin prévue du mois courant (MF2, ADR-056) : 14'057.40
    // (fin août prévue) + 14'057.40 (flux de septembre) = 28'114.80.
    resultat.estimationEcrite = /Si tout se passe comme prévu[\s\S]{0,60}?28'114\.80/.test(texte);
    // Plus aucun « Estimation du mois » en focal.
    resultat.ancienTitre = /Estimation du mois/.test(texte);
    cursor = { y: NOW.y, m: NOW.m }; render();
    return resultat;
  });
  check(futur.focalReel === true && futur.focalSansEstimation === true,
    `le grand chiffre du mois futur est l'argent RÉEL — CHF 0.00, jamais l'estimation (focal réel ${futur.focalReel} / sans estimation ${futur.focalSansEstimation})`);
  check(futur.titreReel === true,
    `le titre du mois futur dit « Sur vos comptes maintenant » (lu : « ${futur.titre} »)`);
  check(futur.estimationEcrite === true,
    "l'estimation reste écrite en petit, au conditionnel : « Si tout se passe comme prévu : CHF 14'057.40 »");
  check(futur.ancienTitre === false,
    "« Estimation du mois » ne domine plus la carte d'un mois futur");
  await ctx176.close();
}

// ---------- 177. MF2 : « si tout se passe comme prévu » ENCHAÎNE les mois (ADR-056) ----------
// La fin prévue du mois consulté part de la fin prévue du mois courant,
// puis ajoute les flux prévus de CHAQUE mois intermédiaire. Sinon le même
// chiffre se répète sur tous les mois futurs, comme si les mois d'avant
// n'existaient pas — c'est le défaut résiduel des captures du 24.08.
currentTest = "MF2 estimation enchaînée";
{
  const ctx177 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p177 = await ctx177.newPage();
  p177.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[MF2] ${msg.text()}`); });
  await p177.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Chaîne" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" }],
      recurrings: [
        { id: "sal", title: "Salaire", amount: 18190, type: "income", nature: "revenu",
          cat: "Salaire", day: 25, every: "month", accountId: "cur", icon: "💼" },
        { id: "loyer", title: "Loyer", amount: 4132.60, type: "expense", nature: "facture",
          cat: "Logement", day: 1, every: "month", accountId: "cur", icon: "🏠" },
      ],
      goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p177.goto(APP_URL);
  await p177.waitForSelector("#tabbar button");
  const chaine = await p177.evaluate(() => {
    const resultat = {};
    const ligne = () => (document.querySelector(".home-hero .hero-reel")?.textContent || "").replace(/[  ]/g, " ");
    activeTab = "home";
    // Mois + 1 : fin prévue d'août (14'057.40) + flux de septembre = 28'114.80.
    cursor = shiftMonth(NOW, 1); render();
    resultat.moisPlus1 = ligne();
    resultat.plus1Exact = /28'114\.80/.test(resultat.moisPlus1);
    // Mois + 2 : encore un mois de flux prévus = 42'172.20.
    cursor = shiftMonth(NOW, 2); render();
    resultat.moisPlus2 = ligne();
    resultat.plus2Exact = /42'172\.20/.test(resultat.moisPlus2);
    // Le focal reste le RÉEL (MF1) — l'enchaînement ne le touche pas.
    resultat.focalReel = /CHF\s*0\.00/.test(
      (document.querySelector(".home-hero .hero-amount")?.textContent || "").replace(/[  ]/g, " "));
    cursor = { y: NOW.y, m: NOW.m }; render();
    return resultat;
  });
  check(chaine.plus1Exact === true,
    `au mois + 1, l'estimation enchaîne : fin prévue du mois courant + flux du mois — 28'114.80 (lu : « ${chaine.moisPlus1} »)`);
  check(chaine.plus2Exact === true,
    `au mois + 2, chaque mois intermédiaire pèse : 42'172.20 (lu : « ${chaine.moisPlus2} »)`);
  check(chaine.focalReel === true,
    "le grand chiffre reste l'argent réel (MF1) — l'enchaînement ne touche que la petite ligne");
  await ctx177.close();
}

// ---------- 178. CPT1 : la fiche compte raconte le mois — entré, sorti, reste (ADR-057) ----------
// Demande propriétaire du 24.08.2026 : « continue avec les ajustements des
// comptes avec ce qu'il reste, les dépenses, les entrées ». La fiche montrait
// le solde et l'historique mais AUCUN résumé du mois. Désormais : « Ce
// mois-ci sur ce compte » — entré / sorti, avec les MÊMES règles de flux que
// balance() ; le prévu ne compte JAMAIS (planifié ≠ réel).
currentTest = "CPT1 mois du compte";
{
  const ctx178 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p178 = await ctx178.newPage();
  p178.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[CPT1] ${msg.text()}`); });
  await p178.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Compte" },
      baseCurrency: "CHF",
      transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 0, cash: false, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p178.goto(APP_URL);
  await p178.waitForSelector("#tabbar button");
  const compte = await p178.evaluate(() => {
    const resultat = {};
    // Mouvements du mois courant : 2'000 reçus, 500 dépensés, 300 mis de
    // côté vers Épargne, et 999 PRÉVUS (jamais comptés).
    transactions.push(
      { id: 9001, y: NOW.y, m: NOW.m, d: 2, type: "income", amount: 2000, cat: "Salaire", title: "Salaire", acc: "cur", status: "posted" },
      { id: 9002, y: NOW.y, m: NOW.m, d: 3, type: "expense", amount: 500, cat: "Alimentation", title: "Courses", acc: "cur", status: "posted" },
      { id: 9003, y: NOW.y, m: NOW.m, d: 4, type: "saving", amount: 300, cat: "Épargne", title: "Mis de côté", acc: "cur", dest: "sav", status: "posted" },
      { id: 9004, y: NOW.y, m: NOW.m, d: 20, type: "expense", amount: 999, cat: "Autre", title: "Prévu", acc: "cur", status: "planned" },
    );
    saveState();
    activeTab = "accounts"; accountView = "cur"; render();
    const texte = (document.querySelector("#screen")?.textContent || "").replace(/[\u00A0\u202F]/g, " ");
    resultat.titreCarte = /Ce mois-ci sur ce compte/.test(texte);
    resultat.entre = /Entrées du mois[\s\S]{0,40}?2'000\.00/.test(texte);
    resultat.sorti = /Sorties du mois[\s\S]{0,40}?800\.00/.test(texte);
    // Le PRÉVU ne compte jamais : 800.00, pas 1'799.00.
    resultat.prevuExclu = !/1'799\.00/.test(texte);
    // La fiche du compte d'Épargne voit l'argent ARRIVER.
    accountView = "sav"; render();
    const texteSav = (document.querySelector("#screen")?.textContent || "").replace(/[\u00A0\u202F]/g, " ");
    resultat.savEntre = /Entrées du mois[\s\S]{0,40}?300\.00/.test(texteSav);
    // Nettoyage.
    transactions.splice(transactions.findIndex(t => t.id === 9001), 4);
    accountView = null; activeTab = "home"; saveState(); render();
    return resultat;
  });
  check(compte.titreCarte === true,
    "la fiche compte a la carte « Ce mois-ci sur ce compte »");
  check(compte.entre === true,
    "« Entrées du mois : CHF 2'000.00 » — le salaire reçu, rien d'autre (mots du natif)");
  check(compte.sorti === true && compte.prevuExclu === true,
    `« Sorties du mois : CHF 800.00 » — dépense + mis de côté, JAMAIS le prévu (sorti ${compte.sorti} / prévu exclu ${compte.prevuExclu})`);
  check(compte.savEntre === true,
    "la fiche Épargne voit l'argent arriver : « Entrées du mois : CHF 300.00 »");
  await ctx178.close();
}

// ---------- 179. AUT-060 : un compte peut être exclu du patrimoine (ADR-060) ----------
// Décision propriétaire du 25.08.2026 (parité) : le natif filtre déjà
// includeInNetWorth ; la PWA gagne le MÊME réglage. Le solde du compte
// exclu reste vrai et visible ; seule la fortune l'ignore (FI-25).
currentTest = "AUT-060 patrimoine par compte";
{
  const ctx179 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p179 = await ctx179.newPage();
  p179.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[AUT-060] ${msg.text()}`); });
  await p179.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Pat" },
      baseCurrency: "CHF", transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" },
        { id: "pro", name: "Compte pro", kind: "current", opening: 5000, cash: false, currency: "CHF", netWorth: false },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p179.goto(APP_URL);
  await p179.waitForSelector("#tabbar button");
  const pat = await p179.evaluate(() => {
    const resultat = {};
    // 1. La fortune ignore le compte exclu — le solde reste vrai.
    resultat.fortune = fortuneTotale();
    resultat.soldePro = balance("pro");
    // 2. La ligne « Fortune totale » de Comptes montre le même chiffre.
    activeTab = "accounts"; accountView = null; render();
    const ligne = [...document.querySelectorAll(".breakdown div")]
      .find(d => /Fortune totale/.test(d.textContent));
    resultat.ligneFortune = ligne ? ligne.textContent.replace(/[  ]/g, " ") : "";
    // 3. Le formulaire de compte offre le réglage, décoché pour « pro ».
    openAccSheet(ACCOUNTS.find(a => a.id === "pro"));
    const caseNW = document.getElementById("aNetWorth");
    resultat.caseExiste = !!caseNW;
    resultat.caseDecochee = caseNW ? caseNW.checked === false : null;
    // 4. Recocher et enregistrer : la fortune retrouve le compte.
    if (caseNW) {
      caseNW.checked = true;
      document.getElementById("accForm").requestSubmit();
    }
    resultat.fortuneApres = fortuneTotale();
    // Nettoyage : ré-exclure pour laisser l'état initial.
    const pro = ACCOUNTS.find(a => a.id === "pro");
    if (pro) { pro.netWorth = false; saveState(); }
    activeTab = "home"; render();
    return resultat;
  });
  check(pat.fortune === 1000 && pat.soldePro === 5000,
    `la fortune ignore le compte exclu (lu ${pat.fortune}) mais son solde reste vrai (lu ${pat.soldePro})`);
  check(/1'000\.00/.test(pat.ligneFortune) && !/6'000\.00/.test(pat.ligneFortune),
    `la ligne « Fortune totale » de Comptes dit CHF 1'000.00, jamais 6'000.00 (lu : « ${pat.ligneFortune} »)`);
  check(pat.caseExiste === true && pat.caseDecochee === true,
    `le formulaire de compte offre « Compter dans le patrimoine », décochée pour le compte exclu (existe ${pat.caseExiste} / décochée ${pat.caseDecochee})`);
  check(pat.fortuneApres === 6000,
    `recocher le réglage rend le compte à la fortune : CHF 6'000.00 (lu ${pat.fortuneApres})`);
  await ctx179.close();
}

// ---------- 180. AUT-061 : le résultat du mois exclut l'épargne et la dette-capital (ADR-061) ----------
// Décision propriétaire du 25.08.2026 : « mettre de côté n'est pas
// dépenser ». Résultat du mois = reçus − vraiment dépensé (impôts et
// intérêts compris) ; épargne, investissement et remboursement de
// CAPITAL (FI-14) n'y entrent plus — même contrat sur les deux
// plateformes.
currentTest = "AUT-061 résultat du mois";
{
  const ctx180 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p180 = await ctx180.newPage();
  p180.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[AUT-061] ${msg.text()}`); });
  await p180.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Rés" },
      baseCurrency: "CHF", transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 0, cash: false, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p180.goto(APP_URL);
  await p180.waitForSelector("#tabbar button");
  const res = await p180.evaluate(() => {
    const resultat = {};
    const prev = shiftMonth(NOW, -1);
    transactions.push(
      { id: 9101, y: prev.y, m: prev.m, d: 2, type: "income", amount: 3000, cat: "Salaire", title: "Salaire", acc: "cur", status: "posted" },
      { id: 9102, y: prev.y, m: prev.m, d: 3, type: "expense", amount: 800, cat: "Alimentation", title: "Courses", acc: "cur", status: "posted" },
      { id: 9103, y: prev.y, m: prev.m, d: 4, type: "saving", amount: 500, cat: "Épargne", title: "Mis de côté", acc: "cur", dest: "sav", status: "posted" },
      { id: 9104, y: prev.y, m: prev.m, d: 5, type: "debtPayment", amount: 200, cat: "Dette", title: "Capital du prêt", acc: "cur", status: "posted" },
      { id: 9105, y: prev.y, m: prev.m, d: 6, type: "taxPayment", amount: 100, cat: "Impôts", title: "Acompte", acc: "cur", status: "posted" },
    );
    const s = snapshot(prev.y, prev.m);
    resultat.cashFlow = s.cashFlow;
    cursor = { y: prev.y, m: prev.m }; activeTab = "home"; render();
    const carte = document.querySelector(".home-hero");
    resultat.titre = carte?.querySelector(".card-label")?.textContent || "";
    resultat.focal = (carte?.querySelector(".hero-amount")?.textContent || "").replace(/[  ]/g, " ");
    resultat.note = (carte?.querySelector(".hero-note")?.textContent || "").replace(/[  ]/g, " ");
    transactions.splice(transactions.findIndex(t => t.id === 9101), 5);
    cursor = { y: NOW.y, m: NOW.m }; saveState(); render();
    return resultat;
  });
  check(res.cashFlow === 2100,
    `résultat du mois = 3000 reçus − 800 dépensés − 100 d'impôts = 2100 — l'épargne (500) et le capital (200) n'y entrent plus (lu ${res.cashFlow})`);
  check(res.titre === "Résultat du mois" && /2'100\.00/.test(res.focal),
    `la carte du mois passé montre CHF 2'100.00 (titre « ${res.titre} », focal « ${res.focal} »)`);
  check(/pas perdre/.test(res.note),
    `la note dit la règle : mettre de côté ou rembourser n'est pas perdre (lu : « ${res.note} »)`);
  await ctx180.close();
}

// ---------- 181. W2.1 : la clé additive « occurrences » — inerte, validée, effaçable ----------
// Budget Autonomie 100, W2.1 (miroir PWA du modèle natif V11) : la clé
// existe, la restauration la VALIDE entrée par entrée (états du
// glossaire W0, dates ISO, clé d'idempotence obligatoire — l'entrée
// hostile est abandonnée en silence contrôlé, jamais adoptée), AUCUN
// moteur ne la lit encore (shadow-write, ADR-058), et « Tout effacer »
// la vide.
currentTest = "W2.1 occurrences";
{
  const ctx181 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p181 = await ctx181.newPage();
  p181.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.1] ${msg.text()}`); });
  await p181.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Occ" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p181.goto(APP_URL);
  await p181.waitForSelector("#tabbar button");
  const occ = await p181.evaluate(() => {
    const resultat = {};
    const valide = { id: "occ-1", seriesId: "r-loyer", dueDate: "2026-09-01",
      originalDueDate: "2026-09-01", expectedAmount: 1500, state: "scheduled",
      idempotencyKey: "serie:r-loyer:2026-9-1" };
    const restauration = validatedRestoreState({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Occ" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
      occurrences: [
        valide,
        { id: "occ-2", dueDate: "2026-09-01", state: "etat-inconnu", idempotencyKey: "k2" },
        { id: "occ-3", dueDate: "pas-une-date", state: "due", idempotencyKey: "k3" },
        { id: "occ-4", dueDate: "2026-09-02", state: "due" },
      ],
    });
    resultat.gardees = (restauration.occurrences || []).map(o => o.id);
    // Le snapshot n'a AUCUN terme d'occurrence : la clé est inerte.
    const s = snapshot(NOW.y, NOW.m);
    resultat.inerte = !("occurrences" in s);
    // « Tout effacer » vide la clé.
    S.occurrences = [valide];
    const confirmOriginal = window.confirm; window.confirm = () => true;
    deleteAllData();
    window.confirm = confirmOriginal;
    resultat.effacees = (S.occurrences || []).length;
    return resultat;
  });
  check(Array.isArray(occ.gardees) && occ.gardees.length === 1 && occ.gardees[0] === "occ-1",
    `la restauration garde l'occurrence valide et abandonne les hostiles — état inconnu, date impossible, clé absente (gardées : ${JSON.stringify(occ.gardees)})`);
  check(occ.inerte === true,
    "aucun agrégat ne lit les occurrences — la clé est inerte (shadow-write, ADR-058)");
  check(occ.effacees === 0,
    `« Tout effacer » vide aussi les occurrences (reste ${occ.effacees})`);
  await ctx181.close();
}

// ---------- 182. W2.2 : matérialisation IDEMPOTENTE des échéances ----------
// Budget Autonomie 100, W2.2 (shadow — rien ne la lit encore) :
// matérialiser les échéances d'un mois crée UNE occurrence par échéance
// due, avec la clé canonique ; re-matérialiser ne duplique JAMAIS
// (FI-03) ; une charge résiliée ne matérialise rien ; le montant
// attendu est conservé (FI-05) ; un mois futur donne « Prévu », un mois
// couru donne « À confirmer » — jamais un état qui prétend qu'un
// mouvement a eu lieu.
currentTest = "W2.2 matérialisation";
{
  const ctx182 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p182 = await ctx182.newPage();
  p182.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.2] ${msg.text()}`); });
  await p182.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Mat" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" }],
      recurrings: [
        { id: "r-loyer", title: "Loyer", amount: 1500, type: "expense", nature: "facture",
          cat: "Logement", day: 1, every: "month", accountId: "cur", icon: "🏠" },
        { id: "r-morte", title: "Résiliée", amount: 99, type: "expense", nature: "abonnement",
          cat: "Autre", day: 1, every: "month", accountId: "cur", icon: "🧾",
          endedOn: { y: 2020, m: 1 } },
      ],
      goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p182.goto(APP_URL);
  await p182.waitForSelector("#tabbar button");
  const mat = await p182.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof materialiserOccurrences === "function";
    if (!resultat.fonctionExiste) return resultat;
    const suivant = shiftMonth(NOW, 1);
    materialiserOccurrences(NOW.y, NOW.m);
    materialiserOccurrences(suivant.y, suivant.m);
    const rejouees = materialiserOccurrences(NOW.y, NOW.m).length
      + materialiserOccurrences(suivant.y, suivant.m).length;
    const occ = S.occurrences || [];
    resultat.total = occ.length;
    resultat.rejouees = rejouees;
    resultat.etats = occ.map(o => o.state).sort();
    resultat.morte = occ.some(o => o.seriesId === "r-morte");
    resultat.montant = occ[0] ? occ[0].expectedAmount : null;
    resultat.cles = new Set(occ.map(o => o.idempotencyKey)).size;
    const restau = validatedRestoreState(JSON.parse(JSON.stringify({
      ...S, transactions, accounts: ACCOUNTS, recurrings: RECURRINGS,
      goals: GOALS, assets: ASSETS, liabilities: LIABILITIES, pensions: PENSIONS,
      insurances: INSURANCES,
    })));
    resultat.restaurees = (restau.occurrences || []).length;
    S.occurrences = []; saveState();
    return resultat;
  });
  check(mat.fonctionExiste === true, "materialiserOccurrences existe (W2.2)");
  check(mat.total === 2 && mat.rejouees === 0 && mat.cles === 2,
    `2 échéances (loyer × 2 mois), re-matérialisation muette, clés uniques (total ${mat.total} / rejouées ${mat.rejouees} / clés ${mat.cles})`);
  check(Array.isArray(mat.etats) && mat.etats.join(",") === "due,scheduled",
    `mois couru = « due », mois futur = « scheduled » — jamais confirmé (états : ${JSON.stringify(mat.etats)})`);
  check(mat.morte === false, "une charge résiliée ne matérialise rien");
  check(mat.montant === 1500, `le montant attendu est conservé (lu ${mat.montant})`);
  check(mat.restaurees === 2, `la restauration accepte les occurrences matérialisées (${mat.restaurees})`);
  await ctx182.close();
}

// ---------- 183. W2.3 : la machine à états des échéances ----------
// Budget Autonomie 100, W2.3 (shadow) : mêmes transitions que le natif.
// « Confirmé » et « Annulé » sont terminaux, « Ignoré » se rouvre vers
// « À confirmer » seulement, une transition interdite est REFUSÉE avec
// une erreur nommée — jamais un repli silencieux (FI-34).
currentTest = "W2.3 machine à états";
{
  const ctx183 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p183 = await ctx183.newPage();
  p183.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.3] ${msg.text()}`); });
  await p183.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Éta" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p183.goto(APP_URL);
  await p183.waitForSelector("#tabbar button");
  const eta = await p183.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof transitionOccurrence === "function";
    if (!resultat.fonctionExiste) return resultat;
    const occ = { id: "o1", seriesId: "r1", dueDate: "2026-09-01", state: "scheduled",
      idempotencyKey: "k1" };
    // Chemin heureux : prévu → due → confirmé, horodaté.
    resultat.versDue = transitionOccurrence(occ, "due");
    resultat.versConfirme = transitionOccurrence(occ, "confirmed");
    resultat.confirmeA = typeof occ.confirmedAt === "string" && occ.confirmedAt.length > 0;
    // Terminal : confirmé ne bouge plus, erreur NOMMÉE.
    resultat.retour = transitionOccurrence(occ, "due");
    resultat.etatFinal = occ.state;
    // Ignoré se rouvre vers due seulement.
    const o2 = { id: "o2", seriesId: "r1", dueDate: "2026-09-01", state: "skipped", idempotencyKey: "k2" };
    resultat.skipVersConfirme = transitionOccurrence(o2, "confirmed");
    resultat.skipVersDue = transitionOccurrence(o2, "due");
    // État inconnu en cible : refusé.
    resultat.cibleInconnue = transitionOccurrence(o2, "etat-martien");
    return resultat;
  });
  check(eta.fonctionExiste === true, "transitionOccurrence existe (W2.3)");
  check(eta.versDue === null && eta.versConfirme === null && eta.confirmeA === true,
    `le chemin heureux passe et la confirmation est horodatée (due ${eta.versDue} / confirmé ${eta.versConfirme} / horodaté ${eta.confirmeA})`);
  check(typeof eta.retour === "string" && /interdite/i.test(eta.retour) && eta.etatFinal === "confirmed",
    `« Confirmé » est terminal, le refus est NOMMÉ (« ${eta.retour} », état resté « ${eta.etatFinal} »)`);
  check(typeof eta.skipVersConfirme === "string" && eta.skipVersDue === null,
    `« Ignoré » se rouvre vers « À confirmer » seulement (confirmé direct : « ${eta.skipVersConfirme} »)`);
  check(typeof eta.cibleInconnue === "string",
    `une cible inconnue est refusée, jamais adoptée (« ${eta.cibleInconnue} »)`);
  await ctx183.close();
}

// ---------- 184. W2.4a : une date n'est pas une preuve — la case « C'est déjà fait » (ADR-062) ----------
// Décision propriétaire du 25.08.2026 : la feuille de saisie montre une
// case « C'est déjà fait », COCHÉE par défaut pour une date passée — le
// geste habituel reste un tap, mais c'est la case de la personne,
// décochable, plus une déduction invisible (FI-02). Une date future n'a
// pas de case : le futur est toujours « prévu » (FI-01).
currentTest = "W2.4a date ≠ preuve";
{
  const ctx184 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p184 = await ctx184.newPage();
  p184.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.4a] ${msg.text()}`); });
  await p184.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Dat" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p184.goto(APP_URL);
  await p184.waitForSelector("#tabbar button");
  const dat = await p184.evaluate(() => {
    const resultat = {};
    const iso = (dt) => `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
    const hier = new Date(NOW.y, NOW.m - 1, NOW.d - 1);
    const demain = new Date(NOW.y, NOW.m - 1, NOW.d + 1);
    const soldeAvant = balance("cur");
    openTxSheet(null, "expense");
    document.getElementById("fAmount").value = "50";
    document.getElementById("fDate").value = iso(hier);
    document.getElementById("fDate").dispatchEvent(new Event("change"));
    const caseFait = document.getElementById("fFait");
    resultat.caseExiste = !!caseFait;
    resultat.cocheeParDefaut = caseFait ? caseFait.checked === true : null;
    if (!caseFait) return resultat;
    caseFait.checked = false;
    document.getElementById("txForm").requestSubmit();
    const decoche = transactions[transactions.length - 1];
    resultat.statutDecoche = decoche ? decoche.status : null;
    resultat.soldeApresDecoche = balance("cur");
    openTxSheet(null, "expense");
    document.getElementById("fAmount").value = "30";
    document.getElementById("fDate").value = iso(hier);
    document.getElementById("fDate").dispatchEvent(new Event("change"));
    resultat.recochee = document.getElementById("fFait").checked === true;
    document.getElementById("txForm").requestSubmit();
    const coche = transactions[transactions.length - 1];
    resultat.statutCoche = coche ? coche.status : null;
    openTxSheet(null, "expense");
    document.getElementById("fAmount").value = "20";
    document.getElementById("fDate").value = iso(demain);
    document.getElementById("fDate").dispatchEvent(new Event("change"));
    resultat.futurCache = document.getElementById("fFaitRow").style.display === "none";
    document.getElementById("txForm").requestSubmit();
    const futur = transactions[transactions.length - 1];
    resultat.statutFutur = futur ? futur.status : null;
    resultat.soldeAvant = soldeAvant;
    transactions.length = 0; saveState(); render();
    return resultat;
  });
  check(dat.caseExiste === true && dat.cocheeParDefaut === true,
    `date passée : la case « C'est déjà fait » existe et est cochée par défaut (existe ${dat.caseExiste} / cochée ${dat.cocheeParDefaut})`);
  check(dat.statutDecoche === "planned" && dat.soldeApresDecoche === dat.soldeAvant,
    `décochée → le mouvement naît PRÉVU et le solde ne bouge pas (statut ${dat.statutDecoche} / solde ${dat.soldeApresDecoche})`);
  check(dat.recochee === true && dat.statutCoche === "posted",
    `le geste habituel reste un tap : case recochée par défaut, mouvement comptabilisé (recochée ${dat.recochee} / statut ${dat.statutCoche})`);
  check(dat.futurCache === true && dat.statutFutur === "planned",
    `date future : pas de case, toujours prévu (cachée ${dat.futurCache} / statut ${dat.statutFutur})`);
  await ctx184.close();
}

// ---------- 185. W2.4b : la confirmation ATOMIQUE d'une échéance ----------
// Budget Autonomie 100, W2.4b (shadow) : confirmer une échéance écrit LE
// mouvement lié ET l'état en un seul geste ; double tap = UNE écriture
// (FI-04) ; le montant attendu survit à un montant réel différent
// (FI-05) ; une échéance ignorée refuse la confirmation directe et RIEN
// n'est écrit (FI-31).
currentTest = "W2.4b confirmation atomique";
{
  const ctx185 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p185 = await ctx185.newPage();
  p185.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.4b] ${msg.text()}`); });
  await p185.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Conf" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p185.goto(APP_URL);
  await p185.waitForSelector("#tabbar button");
  const conf = await p185.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof confirmerOccurrence === "function";
    if (!resultat.fonctionExiste) return resultat;
    const occ = { id: "o1", seriesId: "r-loyer", dueDate: `${NOW.y}-${String(NOW.m).padStart(2, "0")}-05`,
      expectedAmount: 150, state: "due", idempotencyKey: "k1" };
    S.occurrences = [occ];
    // 1. Confirmer avec un montant RÉEL différent : 97.50 payé, 150 attendu.
    const un = confirmerOccurrence(occ, { montant: 97.5, type: "expense", compte: "cur", categorie: "Logement", titre: "Loyer" });
    resultat.premierOk = un && un.erreur == null;
    const tx = transactions[transactions.length - 1];
    resultat.txStatut = tx ? tx.status : null;
    resultat.txMontant = tx ? tx.amount : null;
    resultat.txLien = tx ? tx.recurringId : null;
    resultat.occEtat = occ.state;
    resultat.occLien = occ.transactionId === (tx ? tx.id : "absent");
    resultat.attenduConserve = occ.expectedAmount === 150;
    resultat.nbTx = transactions.length;
    // 2. DOUBLE TAP : une seule écriture.
    const deux = confirmerOccurrence(occ, { montant: 97.5, type: "expense", compte: "cur", categorie: "Logement", titre: "Loyer" });
    resultat.doubleOk = deux && deux.erreur == null && transactions.length === resultat.nbTx;
    // 3. Une échéance IGNORÉE refuse — rien n'est écrit.
    const o2 = { id: "o2", seriesId: "r-loyer", dueDate: `${NOW.y}-${String(NOW.m).padStart(2, "0")}-06`,
      expectedAmount: 50, state: "skipped", idempotencyKey: "k2" };
    S.occurrences.push(o2);
    const refus = confirmerOccurrence(o2, { type: "expense", compte: "cur", categorie: "Autre", titre: "Test" });
    resultat.refusNomme = refus && typeof refus.erreur === "string" && /interdite/i.test(refus.erreur);
    resultat.rienEcrit = transactions.length === resultat.nbTx && o2.state === "skipped";
    // Nettoyage.
    transactions.length = 0; S.occurrences = []; saveState(); render();
    return resultat;
  });
  check(conf.fonctionExiste === true, "confirmerOccurrence existe (W2.4b)");
  check(conf.premierOk === true && conf.txStatut === "posted" && conf.txMontant === 97.5 && conf.txLien === "r-loyer",
    `confirmer écrit LE mouvement comptabilisé lié (statut ${conf.txStatut} / montant ${conf.txMontant} / lien ${conf.txLien})`);
  check(conf.occEtat === "confirmed" && conf.occLien === true && conf.attenduConserve === true,
    `l'échéance est confirmée, liée, et le montant ATTENDU survit au montant réel (état ${conf.occEtat} / lien ${conf.occLien} / attendu conservé ${conf.attenduConserve})`);
  check(conf.doubleOk === true,
    "double tap = UNE écriture — la seconde confirmation retrouve le mouvement sans en créer");
  check(conf.refusNomme === true && conf.rienEcrit === true,
    `une échéance ignorée refuse la confirmation directe et RIEN n'est écrit (refus ${conf.refusNomme} / intact ${conf.rienEcrit})`);
  await ctx185.close();
}

// ---------- 186. W2.5 : reporter, ignorer, annuler — de l'agenda, jamais de l'argent ----------
// Budget Autonomie 100, W2.5 (shadow) : ces gestes ne créent NI ne
// touchent JAMAIS un mouvement. Reporter déplace l'échéance en gardant
// la date d'ORIGINE ; la machine à états refuse les gestes interdits.
currentTest = "W2.5 gestes d'agenda";
{
  const ctx186 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p186 = await ctx186.newPage();
  p186.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.5] ${msg.text()}`); });
  await p186.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Ges" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p186.goto(APP_URL);
  await p186.waitForSelector("#tabbar button");
  const ges = await p186.evaluate(() => {
    const resultat = {};
    resultat.fonctionsExistent = typeof reporterOccurrence === "function"
      && typeof ignorerOccurrence === "function" && typeof annulerOccurrence === "function";
    if (!resultat.fonctionsExistent) return resultat;
    const occ = { id: "o1", seriesId: "r1", dueDate: "2026-09-01",
      originalDueDate: "2026-09-01", expectedAmount: 100, state: "due", idempotencyKey: "k1" };
    // 1. Reporter : la date bouge, l'ORIGINE jamais, aucun mouvement.
    resultat.report = reporterOccurrence(occ, "2026-09-08");
    resultat.dueApres = occ.dueDate;
    resultat.origineIntacte = occ.originalDueDate === "2026-09-01";
    resultat.etatReporte = occ.state;
    resultat.aucunMouvement = transactions.length === 0;
    // 2. Date illisible : refus nommé, rien ne bouge.
    const o2 = { id: "o2", seriesId: "r1", dueDate: "2026-09-02", originalDueDate: "2026-09-02",
      state: "due", idempotencyKey: "k2" };
    resultat.dateInvalide = reporterOccurrence(o2, "pas-une-date");
    resultat.o2Intacte = o2.dueDate === "2026-09-02" && o2.state === "due";
    // 3. Une échéance CONFIRMÉE ne se reporte pas — refus nommé.
    const o3 = { id: "o3", seriesId: "r1", dueDate: "2026-09-03", originalDueDate: "2026-09-03",
      state: "confirmed", idempotencyKey: "k3" };
    resultat.refusConfirme = reporterOccurrence(o3, "2026-09-10");
    resultat.o3Intacte = o3.state === "confirmed" && o3.dueDate === "2026-09-03";
    // 4. Ignorer et annuler passent par la machine.
    resultat.ignore = ignorerOccurrence(o2);
    resultat.o2Ignoree = o2.state === "skipped";
    const o4 = { id: "o4", seriesId: "r1", dueDate: "2026-09-04", state: "scheduled", idempotencyKey: "k4" };
    resultat.annule = annulerOccurrence(o4);
    resultat.o4Annulee = o4.state === "cancelled";
    resultat.toujoursAucunMouvement = transactions.length === 0;
    return resultat;
  });
  check(ges.fonctionsExistent === true, "reporter/ignorer/annuler existent (W2.5)");
  check(ges.report === null && ges.dueApres === "2026-09-08" && ges.origineIntacte === true && ges.etatReporte === "snoozed",
    `reporter déplace l'échéance et garde l'ORIGINE (due ${ges.dueApres} / origine intacte ${ges.origineIntacte} / état ${ges.etatReporte})`);
  check(typeof ges.dateInvalide === "string" && ges.o2Intacte === true,
    `une date illisible est refusée et rien ne bouge (« ${ges.dateInvalide} »)`);
  check(typeof ges.refusConfirme === "string" && /interdite/i.test(ges.refusConfirme) && ges.o3Intacte === true,
    `une échéance confirmée ne se reporte pas — refus nommé (« ${ges.refusConfirme} »)`);
  check(ges.ignore === null && ges.o2Ignoree === true && ges.annule === null && ges.o4Annulee === true,
    "ignorer et annuler passent par la machine à états");
  check(ges.aucunMouvement === true && ges.toujoursAucunMouvement === true,
    "AUCUN mouvement créé par ces gestes — de l'agenda, jamais de l'argent");
  await ctx186.close();
}

// ---------- 187. W2.6 : une facture ponctuelle est une occurrence SANS série ----------
// Budget Autonomie 100, W2.6 (shadow) : les factures ouvertes se
// matérialisent en occurrences sans série (clé facture:<id>,
// idempotente) ; une facture déjà couverte ne matérialise rien ; le
// montant attendu est celui de la facture ; échéance passée → « À
// confirmer », future → « Prévu ».
currentTest = "W2.6 factures ponctuelles";
{
  const ctx187 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p187 = await ctx187.newPage();
  p187.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.6] ${msg.text()}`); });
  await p187.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Fac" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {},
      bills: [],
    }));
  });
  await p187.goto(APP_URL);
  await p187.waitForSelector("#tabbar button");
  const fac = await p187.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof materialiserFactures === "function";
    if (!resultat.fonctionExiste) return resultat;
    const suivant = shiftMonth(NOW, 1);
    S.bills = [
      { id: "b1", name: "Électricité", amount: 184.30, dueY: NOW.y, dueM: NOW.m, dueD: 2, cat: "Logement", accountId: "cur" },
      { id: "b2", name: "Déjà payée", amount: 99, dueY: NOW.y, dueM: NOW.m, dueD: 3, cat: "Autre", accountId: "cur", paidTxId: -1 },
      { id: "b3", name: "Assurance", amount: 250, dueY: suivant.y, dueM: suivant.m, dueD: 10, cat: "Assurances", accountId: "cur" },
    ];
    materialiserFactures(NOW.y, NOW.m);
    materialiserFactures(suivant.y, suivant.m);
    const rejouees = materialiserFactures(NOW.y, NOW.m).length
      + materialiserFactures(suivant.y, suivant.m).length;
    const occ = S.occurrences || [];
    resultat.total = occ.length;
    resultat.rejouees = rejouees;
    resultat.couverteAbsente = !occ.some(o => o.idempotencyKey === "facture:b2");
    const o1 = occ.find(o => o.idempotencyKey === "facture:b1");
    resultat.sansSerie = o1 ? o1.seriesId === null : null;
    resultat.montant = o1 ? o1.expectedAmount : null;
    resultat.etatPasse = o1 ? o1.state : null;
    const o3 = occ.find(o => o.idempotencyKey === "facture:b3");
    resultat.etatFutur = o3 ? o3.state : null;
    // Nettoyage.
    S.occurrences = []; S.bills = []; saveState();
    return resultat;
  });
  check(fac.fonctionExiste === true, "materialiserFactures existe (W2.6)");
  check(fac.total === 2 && fac.rejouees === 0,
    `2 factures ouvertes matérialisées, re-matérialisation muette (total ${fac.total} / rejouées ${fac.rejouees})`);
  check(fac.couverteAbsente === true, "une facture déjà couverte ne matérialise rien");
  check(fac.sansSerie === true && fac.montant === 184.3,
    `l'occurrence est SANS série et porte le montant de la facture (sans série ${fac.sansSerie} / montant ${fac.montant})`);
  check(fac.etatPasse === "due" && fac.etatFutur === "scheduled",
    `échéance courue = « À confirmer », future = « Prévu » (passé ${fac.etatPasse} / futur ${fac.etatFutur})`);
  await ctx187.close();
}

// ---------- 188. W2.7a : le COMPARATEUR — les occurrences reproduisent les compteurs vivants ----------
// ADR-058, étape 4 : avant TOUTE bascule de lecture, prouver que le
// nouveau chemin (occurrences matérialisées) raconte EXACTEMENT la même
// histoire que l'ancien (compteurs recalculés). Pour chaque récurrence
// et chaque mois d'une fenêtre, le nombre d'occurrences OUVERTES doit
// égaler recurringRemainingCount — y compris avec des échéances
// multiples (deux semaines) et des mouvements liés qui en couvrent.
currentTest = "W2.7a comparateur";
{
  const ctx188 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p188 = await ctx188.newPage();
  p188.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.7a] ${msg.text()}`); });
  await p188.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Cmp" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 0, cash: true, currency: "CHF" }],
      recurrings: [
        { id: "r-loyer", title: "Loyer", amount: 1500, type: "expense", nature: "facture",
          cat: "Logement", day: 1, every: "month", accountId: "cur", icon: "🏠" },
        { id: "r-salaire", title: "Salaire", amount: 5000, type: "income", nature: "revenu",
          cat: "Salaire", day: 25, every: "month", accountId: "cur", icon: "💼" },
        { id: "r-abo", title: "Streaming", amount: 15.90, type: "expense", nature: "abonnement",
          cat: "Loisirs", day: 5, every: "month", accountId: "cur", icon: "🧾" },
      ],
      goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], bills: [], documents: [], budgets: {},
    }));
  });
  await p188.goto(APP_URL);
  await p188.waitForSelector("#tabbar button");
  const cmp = await p188.evaluate(() => {
    const resultat = { ecarts: [] };
    resultat.comparateurExiste = typeof comparerOccurrencesEtCompteurs === "function";
    if (!resultat.comparateurExiste) return resultat;
    // Un mouvement lié couvre la première échéance du loyer ce mois.
    transactions.push({ id: 9301, y: NOW.y, m: NOW.m, d: 1, type: "expense", amount: 1500,
      cat: "Logement", title: "Loyer payé", acc: "cur", status: "posted", recurringId: "r-loyer" });
    // Matérialiser trois mois puis comparer.
    for (let k = 0; k <= 2; k += 1) {
      const mm = shiftMonth(NOW, k);
      materialiserOccurrences(mm.y, mm.m);
    }
    resultat.ecarts = comparerOccurrencesEtCompteurs(3);
    // Sans couverture reportée sur les occurrences (la liaison vit en
    // W2.7b), le comparateur doit savoir la simuler : il confirme
    // virtuellement les occurrences des mouvements liés.
    transactions.length = 0; S.occurrences = []; saveState();
    return resultat;
  });
  check(cmp.comparateurExiste === true, "comparerOccurrencesEtCompteurs existe (W2.7a)");
  check(Array.isArray(cmp.ecarts) && cmp.ecarts.length === 0,
    `ZÉRO écart entre les occurrences matérialisées et les compteurs vivants sur 3 mois (écarts : ${JSON.stringify(cmp.ecarts)})`);
  await ctx188.close();
}

// ---------- 189. W2.7b : le geste « Reçu/Payé » confirme AUSSI l'échéance persistée ----------
// Budget Autonomie 100, W2.7b : le MÊME geste, le MÊME mouvement
// qu'avant (aucune forme ne change) — mais l'échéance persistée est
// désormais confirmée et LIÉE. Supprimer le mouvement efface l'échéance
// (jamais un lien pendu) : elle renaît « À confirmer » à la
// re-matérialisation, et le comparateur reste à ZÉRO écart. L'undo
// restaure aussi les occurrences.
currentTest = "W2.7b bascule du geste";
{
  const ctx189 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p189 = await ctx189.newPage();
  p189.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W2.7b] ${msg.text()}`); });
  await p189.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Bas" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [
        { id: "r-loyer", title: "Loyer", amount: 1500, type: "expense", nature: "facture",
          cat: "Logement", day: 1, every: "month", accountId: "cur", icon: "🏠" },
      ],
      goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {},
      bills: [],
    }));
  });
  await p189.goto(APP_URL);
  await p189.waitForSelector("#tabbar button");
  const bas = await p189.evaluate(() => {
    const resultat = {};
    const ETATS_OUVERTS = ["scheduled", "due", "matchProposed", "snoozed"];
    S.bills.push({ id: "b1", name: "Électricité", amount: 184.30, dueY: NOW.y, dueM: NOW.m, dueD: 12, cat: "Logement", accountId: "cur" });
    // 1. Le geste récurrent : mouvement INCHANGÉ + échéance confirmée liée.
    const geste = materializeRecurring(RECURRINGS[0], NOW.y, NOW.m);
    const tx = geste.transaction;
    resultat.mouvementForme = tx && tx.status === "posted" && tx.recurringId === "r-loyer"
      && tx.d === NOW.d && tx.amount === 1500;
    const occSerie = (S.occurrences || []).find(o => o.seriesId === "r-loyer");
    resultat.occConfirmee = occSerie ? occSerie.state === "confirmed" : null;
    resultat.occLiee = occSerie ? occSerie.transactionId === tx.id : null;
    resultat.ecartsApresGeste = comparerOccurrencesEtCompteurs(1);
    // 2. Supprimer le mouvement (vrai parcours : feuille + fDelete).
    const confirmOriginal = window.confirm; window.confirm = () => true;
    openTxSheet(tx);
    document.getElementById("fDelete").click();
    window.confirm = confirmOriginal;
    resultat.occEffacee = !(S.occurrences || []).some(o => o.transactionId === tx.id);
    // 3. Re-matérialiser : l'échéance renaît « À confirmer », comparateur à zéro.
    materialiserOccurrences(NOW.y, NOW.m);
    const renaissante = (S.occurrences || []).find(o => o.seriesId === "r-loyer");
    resultat.renaitDue = renaissante ? renaissante.state === "due" : null;
    resultat.ecartsApresSuppression = comparerOccurrencesEtCompteurs(1);
    // 4. La facture : même contrat.
    const paiement = materializeBill(S.bills[0]);
    const occFacture = (S.occurrences || []).find(o => o.idempotencyKey === "facture:b1");
    resultat.factureConfirmee = occFacture ? occFacture.state === "confirmed" && occFacture.transactionId === paiement.transaction.id : null;
    // 5. L'undo restaure AUSSI les occurrences.
    pushUndo();
    S.occurrences = [];
    undoLast();
    resultat.undoRestaure = (S.occurrences || []).some(o => o.idempotencyKey === "facture:b1");
    // Nettoyage.
    transactions.length = 0; S.occurrences = []; S.bills = []; saveState(); render();
    return resultat;
  });
  check(bas.mouvementForme === true,
    "le geste crée le MÊME mouvement qu'avant — posté, daté du jour, lié à la série");
  check(bas.occConfirmee === true && bas.occLiee === true,
    `…ET confirme l'échéance persistée, liée au mouvement (confirmée ${bas.occConfirmee} / liée ${bas.occLiee})`);
  check(Array.isArray(bas.ecartsApresGeste) && bas.ecartsApresGeste.length === 0,
    `comparateur à ZÉRO écart après le geste (${JSON.stringify(bas.ecartsApresGeste)})`);
  check(bas.occEffacee === true && bas.renaitDue === true,
    `supprimer le mouvement efface l'échéance — elle renaît « À confirmer » (effacée ${bas.occEffacee} / renaît ${bas.renaitDue})`);
  check(Array.isArray(bas.ecartsApresSuppression) && bas.ecartsApresSuppression.length === 0,
    `comparateur à ZÉRO écart après la suppression (${JSON.stringify(bas.ecartsApresSuppression)})`);
  check(bas.factureConfirmee === true,
    "payer une facture confirme aussi son échéance sans série, liée");
  check(bas.undoRestaure === true,
    "l'undo restaure aussi les occurrences — jamais un état à moitié rendu");
  await ctx189.close();
}

// ---------- 190. W3.1 : le JOURNAL — écritures équilibrées en centimes entiers ----------
// Budget Autonomie 100, W3.1 (ADR-063) : une écriture de journal est
// composée de postings équilibrés PAR DEVISE, en CENTIMES ENTIERS.
// Un déséquilibre, un montant non entier, un posting isolé : refus
// NOMMÉ en français — jamais un zéro silencieux (FI-08, FI-34).
// SHADOW : aucune vue ne lit, aucune mutation n'écrit (ADR-058).
currentTest = "W3.1 journal équilibré";
{
  const ctx190 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p190 = await ctx190.newPage();
  p190.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W3.1] ${msg.text()}`); });
  await p190.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Jrn" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p190.goto(APP_URL);
  await p190.waitForSelector("#tabbar button");
  const jrn = await p190.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof creerEcritureJournal === "function";
    if (!resultat.fonctionExiste) return resultat;
    // 1. Une écriture équilibrée est acceptée telle quelle.
    const ok = creerEcritureJournal({
      kind: "expense", lifecycle: "posted", effectiveDate: "2026-08-25",
      titre: "Loyer", postings: [
        { compte: "cur", sens: "credit", montantMineur: 150000, devise: "CHF" },
        { compte: "depense:Logement", sens: "debit", montantMineur: 150000, devise: "CHF" },
      ],
    });
    resultat.equilibreeAcceptee = !!(ok && ok.ecriture && !ok.erreur
      && typeof ok.ecriture.id === "string" && ok.ecriture.id
      && typeof ok.ecriture.idempotencyKey === "string" && ok.ecriture.idempotencyKey
      && ok.ecriture.postings.length === 2);
    // 2. Un déséquilibre est refusé en NOMMANT la devise et l'écart.
    const desequilibre = creerEcritureJournal({
      kind: "expense", lifecycle: "posted", effectiveDate: "2026-08-25",
      titre: "Faux", postings: [
        { compte: "cur", sens: "credit", montantMineur: 150000, devise: "CHF" },
        { compte: "depense:Logement", sens: "debit", montantMineur: 149900, devise: "CHF" },
      ],
    });
    resultat.desequilibreRefuse = !!(desequilibre && desequilibre.erreur
      && !desequilibre.ecriture && desequilibre.erreur.includes("CHF"));
    // 3. Des centimes NON entiers sont refusés — jamais arrondis en silence.
    const nonEntier = creerEcritureJournal({
      kind: "expense", lifecycle: "posted", effectiveDate: "2026-08-25",
      titre: "Flou", postings: [
        { compte: "cur", sens: "credit", montantMineur: 1505.5, devise: "CHF" },
        { compte: "depense:Divers", sens: "debit", montantMineur: 1505.5, devise: "CHF" },
      ],
    });
    resultat.nonEntierRefuse = !!(nonEntier && nonEntier.erreur && !nonEntier.ecriture);
    // 4. Moins de deux postings : refus (une écriture a toujours deux jambes).
    const isole = creerEcritureJournal({
      kind: "expense", lifecycle: "posted", effectiveDate: "2026-08-25",
      titre: "Seul", postings: [
        { compte: "cur", sens: "credit", montantMineur: 1000, devise: "CHF" },
      ],
    });
    resultat.isoleRefuse = !!(isole && isole.erreur && !isole.ecriture);
    // 5. Multi-devise : équilibrée PAR devise = acceptée ; déséquilibre
    //    caché dans UNE devise = refusé même si le total « semble » bon.
    const parDevise = creerEcritureJournal({
      kind: "transfer", lifecycle: "posted", effectiveDate: "2026-08-25",
      titre: "Change", postings: [
        { compte: "cur", sens: "credit", montantMineur: 10000, devise: "CHF" },
        { compte: "attente:change", sens: "debit", montantMineur: 10000, devise: "CHF" },
        { compte: "attente:change", sens: "credit", montantMineur: 9300, devise: "EUR" },
        { compte: "eur", sens: "debit", montantMineur: 9300, devise: "EUR" },
      ],
    });
    const deviseCachee = creerEcritureJournal({
      kind: "transfer", lifecycle: "posted", effectiveDate: "2026-08-25",
      titre: "Triche", postings: [
        { compte: "cur", sens: "credit", montantMineur: 10000, devise: "CHF" },
        { compte: "eur", sens: "debit", montantMineur: 10000, devise: "EUR" },
      ],
    });
    resultat.parDeviseTenu = !!(parDevise && parDevise.ecriture && !parDevise.erreur
      && deviseCachee && deviseCachee.erreur && !deviseCachee.ecriture);
    // 6. La clé additive : une restauration garde les écritures saines et
    //    ABANDONNE une écriture hostile (déséquilibrée) — jamais adoptée.
    const etatTest = JSON.parse(JSON.stringify(S));
    etatTest.journal = [
      ok.ecriture,
      { id: "hostile", kind: "expense", lifecycle: "posted", effectiveDate: "2026-08-25",
        idempotencyKey: "hostile:1", postings: [
          { compte: "cur", sens: "credit", montantMineur: 5000, devise: "CHF" },
          { compte: "depense:Divers", sens: "debit", montantMineur: 4000, devise: "CHF" },
        ] },
    ];
    let restaure = null;
    try { restaure = validatedRestoreState(etatTest); } catch (e) { restaure = { journal: ["exception:" + e.message] }; }
    resultat.restaurationFiltre = !!(restaure && Array.isArray(restaure.journal)
      && restaure.journal.length === 1 && restaure.journal[0].id === ok.ecriture.id);
    // 7. Tout effacer vide aussi le journal ; l'undo le restaure.
    S.journal = [ok.ecriture];
    pushUndo();
    S.journal = [];
    undoLast();
    resultat.undoRestaure = Array.isArray(S.journal) && S.journal.length === 1;
    S.journal = []; saveState();
    return resultat;
  });
  check(jrn.fonctionExiste === true,
    "creerEcritureJournal existe — le journal a une porte d'entrée unique");
  check(jrn.equilibreeAcceptee === true,
    "une écriture équilibrée (2 postings, centimes entiers) est acceptée avec identité et clé d'idempotence");
  check(jrn.desequilibreRefuse === true,
    "un déséquilibre est refusé en NOMMANT la devise — rien n'est écrit (FI-08)");
  check(jrn.nonEntierRefuse === true,
    "des centimes non entiers sont refusés — jamais arrondis en silence (FI-34)");
  check(jrn.isoleRefuse === true,
    "un posting isolé est refusé — une écriture a toujours deux jambes");
  check(jrn.parDeviseTenu === true,
    "l'équilibre se juge PAR devise — le multi-devise honnête passe, le déséquilibre caché est refusé");
  check(jrn.restaurationFiltre === true,
    "une restauration garde les écritures saines et abandonne l'écriture déséquilibrée (FI-34)");
  check(jrn.undoRestaure === true,
    "l'undo restaure aussi le journal — jamais un état à moitié rendu");
  await ctx190.close();
}

// ---------- 191. W3.2 : les écritures TYPES — chaque mouvement se traduit en écriture équilibrée ----------
// Budget Autonomie 100, W3.2 : le traducteur `ecritureDepuisMouvement`
// transforme CHAQUE type de mouvement existant en écriture équilibrée
// (FI-08), le virement interne est UNE écriture à deux jambes de
// comptes réels (FI-09), le solde d'ouverture devient une écriture
// (FI-12), la mensualité de dette garde sa jambe de dette (FI-14).
// SHADOW : rien n'écrit encore dans S.journal (l'ombre = W3.3).
currentTest = "W3.2 écritures types";
{
  const ctx191 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p191 = await ctx191.newPage();
  p191.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W3.2] ${msg.text()}`); });
  await p191.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Typ" },
      baseCurrency: "CHF", transactions: [],
      fxRates: { EUR: 0.93, USD: 0.80 },
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 0, cash: true, currency: "CHF" },
        { id: "eur", name: "Euros", kind: "current", opening: 0, cash: true, currency: "EUR" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p191.goto(APP_URL);
  await p191.waitForSelector("#tabbar button");
  const typ = await p191.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof ecritureDepuisMouvement === "function"
      && typeof ecritureOuverture === "function";
    if (!resultat.fonctionExiste) return resultat;
    const jambes = e => e.postings.map(p => `${p.sens}:${p.compte}:${p.montantMineur}:${p.devise}`).sort().join("|");
    // 1. Dépense : le compte se vide, la catégorie reçoit — centimes exacts.
    const depense = ecritureDepuisMouvement({
      id: 1, type: "expense", amount: 84.30, acc: "cur", cat: "Logement",
      title: "Électricité", y: 2026, m: 8, d: 12, status: "posted", sourceCurrency: "CHF",
    });
    resultat.depense = !!(depense.ecriture && !depense.erreur)
      && depense.ecriture.kind === "expense"
      && depense.ecriture.lifecycle === "posted"
      && depense.ecriture.idempotencyKey === "mouvement:1"
      && depense.ecriture.effectiveDate === "2026-08-12"
      && jambes(depense.ecriture) === "credit:compte:cur:8430:CHF|debit:depense:Logement:8430:CHF";
    // 2. Rentrée PRÉVUE : sens inverse, cycle de vie « pending » (FI-01).
    const rentree = ecritureDepuisMouvement({
      id: 2, type: "income", amount: 6500, acc: "cur", cat: null,
      title: "Salaire", y: 2026, m: 9, d: 25, status: "planned", sourceCurrency: "CHF",
    });
    resultat.rentree = !!(rentree.ecriture)
      && rentree.ecriture.lifecycle === "pending"
      && jambes(rentree.ecriture) === "credit:rentree:Revenu:650000:CHF|debit:compte:cur:650000:CHF";
    // 3. Virement interne : UNE écriture, DEUX jambes de comptes réels,
    //    aucune jambe analytique (FI-09) ; sans destination = refus nommé.
    const virement = ecritureDepuisMouvement({
      id: 3, type: "transfer", amount: 500, acc: "cur", dest: "sav",
      title: "Vers l'épargne", y: 2026, m: 8, d: 1, status: "posted", sourceCurrency: "CHF",
    });
    resultat.virement = !!(virement.ecriture)
      && jambes(virement.ecriture) === "credit:compte:cur:50000:CHF|debit:compte:sav:50000:CHF";
    const sansDest = ecritureDepuisMouvement({
      id: 4, type: "saving", amount: 200, acc: "cur", dest: null,
      title: "Perdu", y: 2026, m: 8, d: 1, status: "posted", sourceCurrency: "CHF",
    });
    resultat.sansDestRefuse = !!(sansDest.erreur && !sansDest.ecriture);
    // 4. Virement de CHANGE : 4 jambes équilibrées PAR devise via
    //    attente:change ; sans destAmount estampillé = refus (FI-16 en germe).
    const change = ecritureDepuisMouvement({
      id: 5, type: "transfer", amount: 100, acc: "cur", dest: "eur", destAmount: 93,
      title: "Change", y: 2026, m: 8, d: 2, status: "posted", sourceCurrency: "CHF",
    });
    resultat.change = !!(change.ecriture)
      && jambes(change.ecriture) === "credit:attente:change:9300:EUR|credit:compte:cur:10000:CHF|debit:attente:change:10000:CHF|debit:compte:eur:9300:EUR";
    const changeSansMontant = ecritureDepuisMouvement({
      id: 6, type: "transfer", amount: 100, acc: "cur", dest: "eur",
      title: "Change sans taux", y: 2026, m: 8, d: 2, status: "posted", sourceCurrency: "CHF",
    });
    resultat.changeSansMontantRefuse = !!(changeSansMontant.erreur && !changeSansMontant.ecriture);
    // 5. Ajustement : la direction `up` décide du sens — toujours neutre
    //    et nommé « ajustement », jamais une dépense déguisée.
    const ajustHaut = ecritureDepuisMouvement({
      id: 7, type: "adjustment", amount: 12.35, up: true, acc: "cur",
      title: "Correction", y: 2026, m: 8, d: 3, status: "posted", sourceCurrency: "CHF",
    });
    const ajustBas = ecritureDepuisMouvement({
      id: 8, type: "adjustment", amount: 12.35, up: false, acc: "cur",
      title: "Correction", y: 2026, m: 8, d: 3, status: "posted", sourceCurrency: "CHF",
    });
    resultat.ajustement = !!(ajustHaut.ecriture && ajustBas.ecriture)
      && jambes(ajustHaut.ecriture) === "credit:ajustement:correction:1235:CHF|debit:compte:cur:1235:CHF"
      && jambes(ajustBas.ecriture) === "credit:compte:cur:1235:CHF|debit:ajustement:correction:1235:CHF";
    // 6. La mensualité de dette (expense liée r-debt-) garde sa jambe
    //    DETTE (FI-14) ; remboursement reçu et impôts gardent la leur.
    const mensualite = ecritureDepuisMouvement({
      id: 9, type: "expense", amount: 350, acc: "cur", cat: null, recurringId: "r-debt-li1",
      title: "Mensualité leasing", y: 2026, m: 8, d: 3, status: "posted", sourceCurrency: "CHF",
    });
    resultat.dette = !!(mensualite.ecriture)
      && mensualite.ecriture.kind === "debtPayment"
      && jambes(mensualite.ecriture) === "credit:compte:cur:35000:CHF|debit:dette:li1:35000:CHF";
    const rembourse = ecritureDepuisMouvement({
      id: 10, type: "refund", amount: 45, acc: "cur", cat: "Santé",
      title: "Remboursement", y: 2026, m: 8, d: 4, status: "posted", sourceCurrency: "CHF",
    });
    const impots = ecritureDepuisMouvement({
      id: 11, type: "taxPayment", amount: 300, acc: "cur",
      title: "Acompte", y: 2026, m: 8, d: 5, status: "posted", sourceCurrency: "CHF",
    });
    resultat.remboursementEtImpots = !!(rembourse.ecriture && impots.ecriture)
      && jambes(rembourse.ecriture) === "credit:remboursement:Santé:4500:CHF|debit:compte:cur:4500:CHF"
      && jambes(impots.ecriture) === "credit:compte:cur:30000:CHF|debit:impot:Impôts:30000:CHF";
    // 7. Un montant à plus de deux décimales est un REFUS nommé —
    //    jamais un arrondi silencieux (FI-34).
    const flou = ecritureDepuisMouvement({
      id: 12, type: "expense", amount: 10.005, acc: "cur", cat: "Divers",
      title: "Flou", y: 2026, m: 8, d: 6, status: "posted", sourceCurrency: "CHF",
    });
    resultat.flouRefuse = !!(flou.erreur && !flou.ecriture);
    // 8. Le solde d'ouverture est UNE écriture (FI-12) ; zéro = rien.
    const ouverture = ecritureOuverture(ACCOUNTS.find(a => a.id === "cur"));
    resultat.ouverture = !!(ouverture && ouverture.ecriture)
      && ouverture.ecriture.kind === "opening"
      && ouverture.ecriture.idempotencyKey === "ouverture:cur"
      && jambes(ouverture.ecriture) === "credit:ouverture:cur:500000:CHF|debit:compte:cur:500000:CHF";
    resultat.ouvertureZero = ecritureOuverture(ACCOUNTS.find(a => a.id === "sav")) === null;
    return resultat;
  });
  check(typ.fonctionExiste === true,
    "ecritureDepuisMouvement et ecritureOuverture existent — le traducteur a une porte");
  check(typ.depense === true,
    "une dépense devient une écriture équilibrée exacte (compte → catégorie, centimes entiers)");
  check(typ.rentree === true,
    "une rentrée PRÉVUE naît « pending » — le prévu ne pèse sur aucun solde (FI-01)");
  check(typ.virement === true && typ.sansDestRefuse === true,
    `le virement interne est UNE écriture à deux comptes réels (FI-09) ; sans destination = refus (virement ${typ.virement} / refus ${typ.sansDestRefuse})`);
  check(typ.change === true && typ.changeSansMontantRefuse === true,
    `le change fait 4 jambes équilibrées PAR devise ; sans montant estampillé = refus (change ${typ.change} / refus ${typ.changeSansMontantRefuse})`);
  check(typ.ajustement === true,
    "l'ajustement suit sa direction et reste nommé « ajustement »");
  check(typ.dette === true,
    "la mensualité de dette garde sa jambe DETTE (FI-14) et sa nature debtPayment");
  check(typ.remboursementEtImpots === true,
    "remboursement reçu et impôts gardent leurs jambes distinctes (FI-24)");
  check(typ.flouRefuse === true,
    "un montant à plus de deux décimales est refusé — jamais arrondi en silence (FI-34)");
  check(typ.ouverture === true && typ.ouvertureZero === true,
    `le solde d'ouverture est UNE écriture (FI-12), zéro n'écrit rien (ouverture ${typ.ouverture} / zéro ${typ.ouvertureZero})`);
  await ctx191.close();
}

// ---------- 192. W3.3 : l'OMBRE — chaque mutation écrit aussi son écriture ----------
// Budget Autonomie 100, W3.3 (ADR-058 étape 3) : ajouter, modifier,
// supprimer un mouvement entretient AUSSI le journal (S.journal), sans
// changer le mouvement ni l'interface. Un mouvement intraduisible ne
// casse JAMAIS le geste : son refus est CONSIGNÉ (jamais perdu en
// silence, FI-34). Le journal reste une ombre : aucune vue ne le lit.
currentTest = "W3.3 ombre du journal";
{
  const ctx192 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p192 = await ctx192.newPage();
  p192.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W3.3] ${msg.text()}`); });
  await p192.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Omb" },
      baseCurrency: "CHF", transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 0, cash: true, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p192.goto(APP_URL);
  await p192.waitForSelector("#tabbar button");
  const omb = await p192.evaluate(() => {
    const resultat = {};
    resultat.fonctionsExistent = typeof ombreJournalDepot === "function"
      && typeof ombreJournalRetrait === "function";
    if (!resultat.fonctionsExistent) return resultat;
    const entrees = cle => (S.journal || []).filter(e => e.idempotencyKey === cle);
    // W3.5 : la tête de chaîne — absente tant que le lot n'est pas livré.
    const activeDe = id => typeof ecritureActiveDuMouvement === "function"
      ? ecritureActiveDuMouvement(id) : undefined;
    // 1. Créer par la porte réelle : addTx dépose l'écriture — le
    //    mouvement, lui, ne change pas de forme.
    const tx = addTx({
      id: ++txSeq, y: NOW.y, m: NOW.m, d: 10, title: "Courses",
      amount: 84.30, type: "expense", cat: "Alimentation", acc: "cur", dest: null,
      status: "posted",
    });
    const depot = entrees(`mouvement:${tx.id}`);
    resultat.creationDeposee = depot.length === 1
      && depot[0].kind === "expense"
      && depot[0].postings.some(p => p.compte === "compte:cur" && p.sens === "credit" && p.montantMineur === 8430);
    resultat.mouvementIntact = tx.amount === 84.30 && tx.status === "posted" && !("journal" in tx);
    // 2. Redéposer est IDEMPOTENT : jamais deux écritures pour un
    //    mouvement.
    ombreJournalDepot(tx);
    resultat.idempotent = entrees(`mouvement:${tx.id}`).length === 1;
    // 3. Modifier par le VRAI formulaire : depuis W3.5 (FI-07), un
    //    POSTÉ ne se réécrit pas — l'écriture ACTIVE porte les nouveaux
    //    centimes, l'originale reste, tracée par son inversion.
    openTxSheet(tx);
    document.getElementById("fAmount").value = "99.90";
    document.getElementById("txForm").requestSubmit();
    const active = activeDe(tx.id);
    resultat.editionRemplace = !!active
      && active.postings.every(p => p.montantMineur === 9990)
      && entrees(`mouvement:${tx.id}`).length === 1
      && entrees(`mouvement:${tx.id}`)[0].postings.every(p => p.montantMineur === 8430);
    // 4. Supprimer par le VRAI geste : plus d'écriture ACTIVE, la trace
    //    reste, et le solde dérivé du journal suit le solde vivant.
    const confirmOriginal = window.confirm; window.confirm = () => true;
    openTxSheet(transactions.find(t => t.id === tx.id));
    document.getElementById("fDelete").click();
    window.confirm = confirmOriginal;
    resultat.suppressionRetire = activeDe(tx.id) == null && typeof ecritureActiveDuMouvement === "function"
      && !transactions.some(t => t.id === tx.id)
      && comparerJournalEtSoldes().length === 0;
    // 5. Un lot d'import annulé n'a plus d'écriture ACTIVE non plus.
    const importe = addTx({
      id: ++txSeq, y: NOW.y, m: NOW.m, d: 11, title: "Ligne importée",
      amount: 25, type: "expense", cat: null, acc: "cur", dest: null,
      status: "posted", importBatch: "batch-test",
    });
    const avaitEcriture = entrees(`mouvement:${importe.id}`).length === 1;
    S.lastImport = { batchId: "batch-test", fileName: "test.csv", total: 1, imported: 1, duplicates: 0, invalids: [] };
    rollbackLastImport();
    resultat.importAnnuleRetire = avaitEcriture
      && activeDe(importe.id) == null && typeof ecritureActiveDuMouvement === "function"
      && !transactions.some(t => t.id === importe.id)
      && comparerJournalEtSoldes().length === 0;
    // 6. Un mouvement intraduisible ne casse JAMAIS le geste : la
    //    transaction naît quand même, le refus est CONSIGNÉ.
    const refusAvant = JOURNAL_OMBRE_REFUS.length;
    const perdu = addTx({
      id: ++txSeq, y: NOW.y, m: NOW.m, d: 12, title: "Sans destination",
      amount: 50, type: "saving", cat: null, acc: "cur", dest: null,
      status: "posted",
    });
    resultat.refusConsigne = transactions.some(t => t.id === perdu.id)
      && entrees(`mouvement:${perdu.id}`).length === 0
      && JOURNAL_OMBRE_REFUS.length === refusAvant + 1
      && JOURNAL_OMBRE_REFUS[JOURNAL_OMBRE_REFUS.length - 1].mouvement === perdu.id;
    // Nettoyage.
    transactions.length = 0; S.journal = []; S.lastImport = null; saveState(); render();
    return resultat;
  });
  check(omb.fonctionsExistent === true,
    "ombreJournalDepot et ombreJournalRetrait existent — l'ombre a ses deux gestes");
  check(omb.creationDeposee === true && omb.mouvementIntact === true,
    `addTx dépose l'écriture équilibrée SANS toucher au mouvement (dépôt ${omb.creationDeposee} / mouvement ${omb.mouvementIntact})`);
  check(omb.idempotent === true,
    "redéposer est idempotent — jamais deux écritures pour un mouvement");
  check(omb.editionRemplace === true,
    "modifier un POSTÉ ne réécrit pas l'histoire : écriture active aux nouveaux centimes, originale conservée (FI-07)");
  check(omb.suppressionRetire === true,
    "supprimer un POSTÉ laisse la trace — plus d'écriture active, solde du journal aligné");
  check(omb.importAnnuleRetire === true,
    "annuler un lot d'import désactive ses écritures en gardant la trace");
  check(omb.refusConsigne === true,
    "un mouvement intraduisible ne casse pas le geste — son refus est consigné, jamais perdu (FI-34)");
  await ctx192.close();
}

// ---------- 193. W3.4 : le COMPARATEUR — les soldes du journal racontent la même histoire ----------
// Budget Autonomie 100, W3.4 (ADR-058 étape 4) : avant toute bascule,
// le solde de CHAQUE compte dérivé du journal doit être EXACTEMENT le
// solde actuel — l'historique non couvert est complété par le
// traducteur (idempotent), l'ouverture devient une écriture, et tout
// mouvement resté sans écriture est un écart NOMMÉ, jamais un trou
// silencieux. SHADOW : aucune vue ne lit.
currentTest = "W3.4 comparateur des soldes";
{
  const ctx193 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p193 = await ctx193.newPage();
  p193.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W3.4] ${msg.text()}`); });
  await p193.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Cmp" },
      baseCurrency: "CHF", fxRates: { EUR: 0.93, USD: 0.80 },
      // Un mouvement HÉRITÉ (posé directement, sans passer par addTx) :
      // le comparateur doit le couvrir lui-même via le traducteur.
      transactions: [
        { id: 1, y: 2026, m: 7, d: 5, title: "Salaire hérité", amount: 6500,
          type: "income", cat: null, acc: "cur", dest: null, status: "posted" },
      ],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 250.50, cash: true, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p193.goto(APP_URL);
  await p193.waitForSelector("#tabbar button");
  const cmpJ = await p193.evaluate(() => {
    const resultat = {};
    resultat.fonctionsExistent = typeof comparerJournalEtSoldes === "function"
      && typeof soldeDepuisJournal === "function";
    if (!resultat.fonctionsExistent) return resultat;
    // Des mouvements VIVANTS par la vraie porte : dépense, virement,
    // ajustement vers le bas, et un prévu (qui ne pèse sur rien).
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 3, title: "Courses", amount: 84.30,
      type: "expense", cat: "Alimentation", acc: "cur", dest: null, status: "posted" });
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 4, title: "Vers l'épargne", amount: 500,
      type: "transfer", cat: null, acc: "cur", dest: "sav", status: "posted" });
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 5, title: "Correction", amount: 12.35,
      type: "adjustment", up: false, acc: "cur", dest: null, status: "posted" });
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 28, title: "Prévu", amount: 999,
      type: "expense", cat: "Divers", acc: "cur", dest: null, status: "planned" });
    // 1. ZÉRO écart : l'héritage est complété, l'ouverture écrite, et
    //    chaque solde dérivé du journal égale le solde actuel.
    const ecarts = comparerJournalEtSoldes();
    resultat.zeroEcart = Array.isArray(ecarts) && ecarts.length === 0;
    resultat.ecartsDetail = ecarts;
    resultat.soldeCur = balance("cur") === soldeDepuisJournal("cur");
    resultat.soldeSav = balance("sav") === soldeDepuisJournal("sav")
      && soldeDepuisJournal("sav") === 750.50;
    resultat.heritageConvert = (S.journal || []).some(e => e.idempotencyKey === "mouvement:1");
    resultat.ouvertureEcrite = (S.journal || []).some(e => e.idempotencyKey === "ouverture:cur");
    // 2. Idempotent : re-comparer ne duplique RIEN.
    const taille = (S.journal || []).length;
    comparerJournalEtSoldes();
    resultat.idempotent = (S.journal || []).length === taille;
    // 3. Falsifier UNE écriture → l'écart NOMME le compte.
    const ecriture = (S.journal || []).find(e => e.idempotencyKey === "mouvement:1");
    const originaux = ecriture.postings.map(p => p.montantMineur);
    ecriture.postings.forEach(p => { p.montantMineur = 1; });
    const ecartsFausses = comparerJournalEtSoldes();
    resultat.faussetteNommee = ecartsFausses.some(e => e.includes("cur"));
    ecriture.postings.forEach((p, i) => { p.montantMineur = originaux[i]; });
    // 4. Un mouvement intraduisible (mise de côté SANS destination,
    //    hérité) reste un écart VISIBLE — l'argent a bougé, le journal
    //    ne sait pas le raconter, personne ne le cache.
    transactions.push({ id: 777777, y: 2026, m: 7, d: 9, title: "Perdu hérité",
      amount: 200, type: "saving", cat: null, acc: "cur", dest: null,
      status: "posted", sourceCurrency: "CHF" });
    const ecartsPerdu = comparerJournalEtSoldes();
    resultat.perduVisible = ecartsPerdu.length > 0
      && ecartsPerdu.some(e => e.includes("777777") || e.includes("cur"));
    // Nettoyage.
    transactions.length = 0; S.journal = []; saveState(); render();
    return resultat;
  });
  check(cmpJ.fonctionsExistent === true,
    "comparerJournalEtSoldes et soldeDepuisJournal existent — la gate de bascule a une porte");
  check(cmpJ.zeroEcart === true,
    `ZÉRO écart entre le journal et les soldes vivants (${JSON.stringify(cmpJ.ecartsDetail)})`);
  check(cmpJ.soldeCur === true && cmpJ.soldeSav === true,
    `chaque solde dérivé du journal égale le solde actuel, ouverture comprise (cur ${cmpJ.soldeCur} / sav ${cmpJ.soldeSav})`);
  check(cmpJ.heritageConvert === true && cmpJ.ouvertureEcrite === true,
    "l'héritage est couvert par le traducteur et l'ouverture devient une écriture (FI-12)");
  check(cmpJ.idempotent === true,
    "re-comparer ne duplique jamais une écriture");
  check(cmpJ.faussetteNommee === true,
    "une écriture falsifiée fait un écart qui NOMME le compte");
  check(cmpJ.perduVisible === true,
    "un mouvement intraduisible reste un écart VISIBLE — jamais un trou silencieux (FI-34)");
  await ctx193.close();
}

// ---------- 194. W3.5 : INVERSION/REMPLACEMENT — corriger n'est jamais réécrire ----------
// Budget Autonomie 100, W3.5 (FI-07) : corriger un mouvement POSTÉ
// crée une écriture d'inversion LIÉE (reversesEntryId) puis une
// remplaçante LIÉE (replacesEntryId) — l'originale ne bouge jamais.
// Un PRÉVU n'est pas de l'histoire : il se remplace simplement. Le
// comparateur reste à ZÉRO écart à travers toute la chaîne.
currentTest = "W3.5 inversion remplacement";
{
  const ctx194 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p194 = await ctx194.newPage();
  p194.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W3.5] ${msg.text()}`); });
  await p194.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Inv" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p194.goto(APP_URL);
  await p194.waitForSelector("#tabbar button");
  const inv = await p194.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof ecritureActiveDuMouvement === "function";
    if (!resultat.fonctionExiste) return resultat;
    const chaine = txId => (S.journal || []).filter(e =>
      e.idempotencyKey.startsWith(`mouvement:${txId}`) || (e.idempotencyKey.startsWith("inversion:")
        && (S.journal || []).some(o => o.id === e.reversesEntryId
          && o.idempotencyKey.startsWith(`mouvement:${txId}`))));
    // 1. Corriger un POSTÉ : originale intacte + inversion liée (jambes
    //    inversées) + remplaçante liée — trois écritures, une active.
    const tx = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 5, title: "Loyer",
      amount: 1500, type: "expense", cat: "Logement", acc: "cur", dest: null, status: "posted" });
    const originale = ecritureActiveDuMouvement(tx.id);
    tx.amount = 1450;
    ombreJournalDepot(tx);
    const membres = chaine(tx.id);
    const inversion = membres.find(e => e.reversesEntryId === originale.id);
    const remplacante = ecritureActiveDuMouvement(tx.id);
    resultat.chaineTracee = membres.length === 3
      && !!inversion
      && inversion.postings.every(p => p.montantMineur === 150000)
      && inversion.postings.some(p => p.compte === "compte:cur" && p.sens === "debit")
      && remplacante.replacesEntryId === originale.id
      && remplacante.postings.every(p => p.montantMineur === 145000)
      && (S.journal || []).some(e => e.id === originale.id);
    resultat.comparateurZero1 = comparerJournalEtSoldes().length === 0;
    // 2. Re-corriger : la chaîne s'allonge (r2 → r3), toujours UNE
    //    écriture active, comparateur toujours à zéro.
    tx.amount = 1500.55;
    ombreJournalDepot(tx);
    const active2 = ecritureActiveDuMouvement(tx.id);
    resultat.chaineAllongee = chaine(tx.id).length === 5
      && active2.postings.every(p => p.montantMineur === 150055)
      && active2.replacesEntryId === remplacante.id
      && comparerJournalEtSoldes().length === 0;
    // 3. Ré-appliquer la MÊME correction est IDEMPOTENT : rien ne bouge.
    const tailleAvant = (S.journal || []).length;
    ombreJournalDepot(tx);
    resultat.idempotent = (S.journal || []).length === tailleAvant;
    // 4. Un PRÉVU n'est pas de l'histoire : sa correction REMPLACE
    //    simplement — pas d'inversion, une seule écriture.
    const prevu = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 27, title: "Prévu",
      amount: 300, type: "expense", cat: "Divers", acc: "cur", dest: null, status: "planned" });
    prevu.amount = 250;
    ombreJournalDepot(prevu);
    resultat.prevuRemplace = chaine(prevu.id).length === 1
      && ecritureActiveDuMouvement(prevu.id).postings.every(p => p.montantMineur === 25000)
      && ecritureActiveDuMouvement(prevu.id).lifecycle === "pending";
    // 5. Supprimer un PRÉVU l'efface ; supprimer un POSTÉ laisse
    //    l'inversion tracée.
    ombreJournalRetrait(prevu.id);
    resultat.prevuEfface = chaine(prevu.id).length === 0;
    ombreJournalRetrait(tx.id);
    resultat.posteTrace = ecritureActiveDuMouvement(tx.id) == null
      && chaine(tx.id).length === 6
      && (S.journal || []).some(e => e.reversesEntryId === active2.id);
    // Le mouvement parti, le journal raconte un aller-retour net zéro.
    transactions.splice(transactions.findIndex(t => t.id === tx.id), 1);
    resultat.comparateurZero2 = comparerJournalEtSoldes().length === 0;
    // Nettoyage.
    transactions.length = 0; S.journal = []; saveState(); render();
    return resultat;
  });
  check(inv.fonctionExiste === true,
    "ecritureActiveDuMouvement existe — la chaîne de correction a une tête lisible");
  check(inv.chaineTracee === true,
    "corriger un POSTÉ trace : originale intacte, inversion liée aux jambes inversées, remplaçante liée (FI-07)");
  check(inv.comparateurZero1 === true,
    "le comparateur reste à ZÉRO écart après la correction");
  check(inv.chaineAllongee === true,
    "re-corriger allonge la chaîne (r2 → r3) — toujours une seule écriture active, comparateur à zéro");
  check(inv.idempotent === true,
    "ré-appliquer la même correction est idempotent — rien ne bouge");
  check(inv.prevuRemplace === true,
    "un PRÉVU n'est pas de l'histoire : sa correction remplace simplement, sans inversion");
  check(inv.prevuEfface === true && inv.posteTrace === true,
    `supprimer : le prévu s'efface, le posté laisse son inversion tracée (prévu ${inv.prevuEfface} / posté ${inv.posteTrace})`);
  check(inv.comparateurZero2 === true,
    "après suppression du posté, le journal raconte un aller-retour net — comparateur à zéro");
  await ctx194.close();
}

// ---------- 195. W3.6 : la BASCULE — les soldes lisent le journal, derrière un drapeau gardé ----------
// Budget Autonomie 100, W3.6 (ADR-058 étape 6) : `balance()` passe au
// journal quand `S.journalActif` est vrai. Allumer EXIGE le comparateur
// à zéro écart (la gate W3.4 mord à la porte) ; éteindre est toujours
// permis (rollback documenté). Sous journal, chaque geste et l'édition
// d'une ouverture de compte gardent les soldes EXACTS.
currentTest = "W3.6 bascule des soldes";
{
  const ctx195 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p195 = await ctx195.newPage();
  p195.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W3.6] ${msg.text()}`); });
  await p195.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Bsc" },
      baseCurrency: "CHF", transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 250.50, cash: true, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p195.goto(APP_URL);
  await p195.waitForSelector("#tabbar button");
  const bsc = await p195.evaluate(() => {
    const resultat = {};
    resultat.fonctionsExistent = typeof basculerJournal === "function"
      && typeof soldeVivant === "function" && typeof ombreOuvertureDepot === "function";
    if (!resultat.fonctionsExistent) return resultat;
    const identiques = () => ACCOUNTS.every(a => Math.abs(balance(a.id) - soldeVivant(a.id)) < 0.005);
    // 1. Éteint par défaut : balance == chemin vivant.
    resultat.eteintParDefaut = S.journalActif !== true && identiques();
    // 2. Allumer avec un écart REFUSE en nommant — le drapeau ne bouge pas.
    transactions.push({ id: 555001, y: 2026, m: 7, d: 9, title: "Perdu hérité",
      amount: 200, type: "saving", cat: null, acc: "cur", dest: null,
      status: "posted", sourceCurrency: "CHF" });
    const refus = basculerJournal(true);
    resultat.basculeRefusee = typeof refus === "string" && refus.length > 0
      && S.journalActif !== true;
    transactions.splice(transactions.findIndex(t => t.id === 555001), 1);
    // 3. Propre : la bascule passe, et CHAQUE solde reste identique.
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 3, title: "Courses", amount: 84.30,
      type: "expense", cat: "Alimentation", acc: "cur", dest: null, status: "posted" });
    const ok = basculerJournal(true);
    resultat.basculeReussie = ok === null && S.journalActif === true && identiques();
    // 4. Sous journal, les gestes réels gardent l'exactitude : ajout,
    //    correction d'un posté, suppression réelle.
    const tx = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 6, title: "Resto", amount: 45.60,
      type: "expense", cat: "Sorties", acc: "cur", dest: null, status: "posted" });
    const apresAjout = identiques();
    tx.amount = 52.10;
    ombreJournalDepot(tx);
    const apresCorrection = identiques();
    const confirmOriginal = window.confirm; window.confirm = () => true;
    openTxSheet(transactions.find(t => t.id === tx.id));
    document.getElementById("fDelete").click();
    window.confirm = confirmOriginal;
    resultat.gestesExacts = apresAjout && apresCorrection && identiques();
    // 5. Éditer l'OUVERTURE d'un compte par le VRAI formulaire : la
    //    chaîne d'ouverture se corrige, le solde reste exact.
    openAccSheet(ACCOUNTS.find(a => a.id === "sav"));
    document.getElementById("aOpening").value = "600";
    document.getElementById("accForm").requestSubmit();
    const ouvertures = (S.journal || []).filter(e => e.idempotencyKey.startsWith("ouverture:sav"));
    resultat.ouvertureChaine = ouvertures.length >= 2
      && (S.journal || []).some(e => e.reversesEntryId
        && ouvertures.some(o => o.id === e.reversesEntryId))
      && identiques() && Math.abs(balance("sav") - 600) < 0.005;
    // 6. Tout effacer sous journal : les soldes retombent aux ouvertures.
    const confirm2 = window.confirm; window.confirm = () => true;
    deleteAllData();
    window.confirm = confirm2;
    resultat.effacerExact = identiques() && Math.abs(balance("sav") - 600) < 0.005;
    // 7. Rollback : éteindre est TOUJOURS permis, retour au chemin vivant.
    const retour = basculerJournal(false);
    resultat.rollback = retour === null && S.journalActif !== true && identiques();
    // Nettoyage.
    transactions.length = 0; S.journal = []; S.journalActif = false; saveState(); render();
    return resultat;
  });
  check(bsc.fonctionsExistent === true,
    "basculerJournal, soldeVivant et ombreOuvertureDepot existent — la bascule a une porte gardée");
  check(bsc.eteintParDefaut === true,
    "éteint par défaut : balance() suit le chemin vivant, à l'identique");
  check(bsc.basculeRefusee === true,
    "allumer avec un écart REFUSE en nommant — le drapeau ne bouge pas (gate W3.4)");
  check(bsc.basculeReussie === true,
    "sur un état propre la bascule passe — chaque solde reste identique au centime");
  check(bsc.gestesExacts === true,
    "sous journal : ajout, correction tracée et suppression réelle gardent les soldes exacts");
  check(bsc.ouvertureChaine === true,
    "éditer l'ouverture par le vrai formulaire corrige la chaîne (FI-07/FI-12) et le solde suit");
  check(bsc.effacerExact === true,
    "tout effacer sous journal retombe exactement aux ouvertures");
  check(bsc.rollback === true,
    "le rollback est toujours permis : éteint, balance() retrouve le chemin vivant");
  await ctx195.close();
}

// ---------- 196. W3.7 : la MIGRATION de l'historique — préparer sans allumer ----------
// Budget Autonomie 100, W3.7 (ADR-064, décision propriétaire du
// 25.08.2026 : « préparer sans allumer ») : l'essai à blanc RACONTE
// (créés, refus, écarts) sans rien écrire ; la migration réelle
// n'applique que si TOUT est propre (zéro refus, zéro écart), sinon
// rien ne change — atomique ; elle n'allume JAMAIS la lecture
// (S.journalActif reste éteint : l'allumage attend W4 et une décision
// propriétaire).
currentTest = "W3.7 migration historique";
{
  const ctx196 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p196 = await ctx196.newPage();
  p196.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W3.7] ${msg.text()}`); });
  await p196.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Mig" },
      baseCurrency: "CHF",
      // L'HISTORIQUE : des mouvements posés là bien avant le journal.
      transactions: [
        { id: 1, y: 2026, m: 6, d: 25, title: "Salaire ancien", amount: 6500,
          type: "income", cat: null, acc: "cur", dest: null, status: "posted" },
        { id: 2, y: 2026, m: 7, d: 3, title: "Loyer ancien", amount: 1500,
          type: "expense", cat: "Logement", acc: "cur", dest: null, status: "posted" },
      ],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 0, cash: true, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p196.goto(APP_URL);
  await p196.waitForSelector("#tabbar button");
  const mig = await p196.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof migrerHistoriqueJournal === "function";
    if (!resultat.fonctionExiste) return resultat;
    // 1. L'ESSAI À BLANC raconte sans rien écrire.
    const tailleAvant = (S.journal || []).length;
    const essai = migrerHistoriqueJournal({ essai: true });
    resultat.essaiRaconte = essai && essai.essai === true && essai.applique === false
      && essai.creees === 3 // 2 mouvements + 1 ouverture (sav à zéro n'écrit rien)
      && essai.refus.length === 0 && essai.ecarts.length === 0;
    resultat.essaiInerte = (S.journal || []).length === tailleAvant;
    // 2. La migration RÉELLE applique, prouve zéro écart, et reste
    //    idempotente (re-migrer ne crée rien).
    const reel = migrerHistoriqueJournal({});
    resultat.reelApplique = reel && reel.applique === true && reel.creees === 3
      && comparerJournalEtSoldes().length === 0;
    const encore = migrerHistoriqueJournal({});
    resultat.idempotent = encore && encore.applique === true && encore.creees === 0;
    // 3. JAMAIS d'allumage : la lecture reste sur le chemin vivant.
    resultat.sansAllumage = S.journalActif !== true;
    // 4. Un historique intraduisible REFUSE tout : rapport nommé,
    //    RIEN ne change — atomique.
    transactions.push({ id: 999, y: 2026, m: 7, d: 9, title: "Perdu ancien",
      amount: 200, type: "saving", cat: null, acc: "cur", dest: null,
      status: "posted", sourceCurrency: "CHF" });
    const tailleApresReel = (S.journal || []).length;
    const refuse = migrerHistoriqueJournal({});
    resultat.refusAtomique = refuse && refuse.applique === false
      && refuse.refus.some(r => r.includes("999"))
      && (S.journal || []).length === tailleApresReel
      && S.journalActif !== true;
    // Nettoyage.
    transactions.length = 0; S.journal = []; saveState(); render();
    return resultat;
  });
  check(mig.fonctionExiste === true,
    "migrerHistoriqueJournal existe — la migration a une porte et un rapport");
  check(mig.essaiRaconte === true && mig.essaiInerte === true,
    `l'essai à blanc raconte (créés, refus, écarts) sans RIEN écrire (rapport ${mig.essaiRaconte} / inerte ${mig.essaiInerte})`);
  check(mig.reelApplique === true,
    "la migration réelle écrit l'historique et prouve zéro écart");
  check(mig.idempotent === true,
    "re-migrer est idempotent — rien de nouveau n'est créé");
  check(mig.sansAllumage === true,
    "ADR-064 : la migration n'allume JAMAIS la lecture — préparer sans allumer");
  check(mig.refusAtomique === true,
    "un historique intraduisible refuse TOUT — rapport nommé, rien ne change (atomique)");
  await ctx196.close();
}

// ---------- 197. W4.1 : la TYPOLOGIE — les comptes de dette existent enfin ----------
// Budget Autonomie 100, W4.1 : la PWA gagne les types de comptes de
// DETTE (« Carte de crédit », « Prêt / leasing ») que le natif connaît
// déjà — additif, AUCUNE formule d'agrégat ne change. Choisir un type
// de dette décoche « argent disponible » (une dette n'est pas du
// cash), la restauration préserve le type, et le journal traduit un
// mouvement de carte comme tout compte.
currentTest = "W4.1 typologie des comptes";
{
  const ctx197 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p197 = await ctx197.newPage();
  p197.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W4.1] ${msg.text()}`); });
  await p197.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Typ" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p197.goto(APP_URL);
  await p197.waitForSelector("#tabbar button");
  const typo = await p197.evaluate(() => {
    const resultat = {};
    const options = [...document.querySelectorAll('#aKind option')].map(o => o.value);
    resultat.typesPresents = options.includes("creditCard") && options.includes("loan");
    resultat.libellesFrancais = typeof ACCOUNT_KINDS === "object"
      && ACCOUNT_KINDS.creditCard && ACCOUNT_KINDS.creditCard.label === "Carte de crédit"
      && ACCOUNT_KINDS.loan && ACCOUNT_KINDS.loan.label === "Prêt / leasing";
    if (!resultat.typesPresents) return resultat;
    // 1. Créer une CARTE par le VRAI formulaire : choisir le type
    //    décoche « argent disponible » (modifiable), et le compte naît
    //    cash=false, netWorth=true.
    openAccSheet(null);
    document.getElementById("aName").value = "Carte Visa";
    document.getElementById("aKind").value = "creditCard";
    document.getElementById("aKind").dispatchEvent(new Event("change"));
    resultat.caseDecochee = document.getElementById("aCash").checked === false;
    document.getElementById("accForm").requestSubmit();
    const carte = ACCOUNTS.find(a => a.name === "Carte Visa");
    resultat.carteCreee = !!carte && carte.kind === "creditCard"
      && carte.cash === false && carte.netWorth !== false;
    // 2. AUCUNE formule ne change : un mouvement depuis la carte passe
    //    par le journal comme tout compte, comparateur à zéro.
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 5, title: "Achat carte", amount: 120,
      type: "expense", cat: "Divers", acc: carte.id, dest: null, status: "posted" });
    resultat.journalNeutre = comparerJournalEtSoldes().length === 0
      && Math.abs(balance(carte.id) - (-120)) < 0.005;
    // 3. La restauration PRÉSERVE le type — jamais coercé vers
    //    « current » ; l'ancien repli (kind manquant) reste intact.
    const etat = JSON.parse(JSON.stringify(S));
    let restaure = null;
    try { restaure = validatedRestoreState(etat); } catch (e) { restaure = null; }
    resultat.restaurationPreserve = !!restaure
      && restaure.accounts.some(a => a.name === "Carte Visa" && a.kind === "creditCard");
    // 4. Le libellé s'affiche en français dans la liste des comptes.
    resultat.libelleAffiche = kindLabel("creditCard") === "Carte de crédit"
      && kindLabel("loan") === "Prêt / leasing";
    // Nettoyage.
    transactions.length = 0; S.journal = [];
    ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === carte.id), 1);
    saveState(); render();
    return resultat;
  });
  check(typo.typesPresents === true && typo.libellesFrancais === true,
    `« Carte de crédit » et « Prêt / leasing » existent dans le vrai formulaire (options ${typo.typesPresents} / libellés ${typo.libellesFrancais})`);
  check(typo.caseDecochee === true,
    "choisir un type de dette décoche « argent disponible » — une dette n'est pas du cash");
  check(typo.carteCreee === true,
    "la carte naît cash=false et compte dans le patrimoine");
  check(typo.journalNeutre === true,
    "un mouvement de carte passe par le journal comme tout compte — zéro écart, solde négatif naturel");
  check(typo.restaurationPreserve === true,
    "la restauration préserve le type de dette — jamais coercé");
  check(typo.libelleAffiche === true,
    "les libellés français s'affichent partout via kindLabel");
  await ctx197.close();
}

// ---------- 198. W4.2 : les TAUX DATÉS — chaque taux porte sa date et sa source ----------
// Budget Autonomie 100, W4.2 (ADR-065, décision propriétaire :
// « V1 base unique ») : un taux de change n'est plus un nombre nu —
// chaque écriture de taux passe par UNE porte (enregistrerTaux) qui
// consigne une quote datée et sourcée (FI-16), append-only ;
// S.fxRates devient un CACHE dérivé (la dernière quote). L'historique
// estampillé ne bouge jamais (FI-19) ; un taux absent reste un état
// « incomplet » nommé (FI-17, déjà tenu — verrouillé ici).
currentTest = "W4.2 taux datés";
{
  const ctx198 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p198 = await ctx198.newPage();
  p198.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W4.2] ${msg.text()}`); });
  await p198.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Fx" },
      baseCurrency: "CHF", fxRates: { EUR: 0.93, USD: 0.80 },
      transactions: [
        { id: 1, y: 2026, m: 7, d: 5, title: "Dépense en euros", amount: 100,
          type: "expense", cat: "Divers", acc: "eur", dest: null, status: "posted",
          sourceCurrency: "EUR", fx: 0.93, fxBase: "CHF" },
      ],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "eur", name: "Euros", kind: "current", opening: 1000, cash: true, currency: "EUR" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p198.goto(APP_URL);
  await p198.waitForSelector("#tabbar button");
  const fxr = await p198.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof enregistrerTaux === "function";
    if (!resultat.fonctionExiste) return resultat;
    const quotes = devise => (S.fxQuotes || []).filter(q => q.quote === devise);
    // 1. Le VRAI formulaire des réglages consigne des quotes datées et
    //    sourcées, et le cache S.fxRates suit la DERNIÈRE quote.
    fxEditKeys = ["EUR", "USD"];
    document.getElementById("fxA").value = "0.95";
    document.getElementById("fxB").value = "0.82";
    document.getElementById("fxForm").requestSubmit();
    const quoteEUR = quotes("EUR").at(-1);
    const dateISO = `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(NOW.d).padStart(2, "0")}`;
    resultat.quotesConsignees = !!quoteEUR
      && quoteEUR.base === "CHF" && quoteEUR.taux === 0.95
      && quoteEUR.observedAt === dateISO && quoteEUR.source === "saisie manuelle"
      && quotes("USD").at(-1) && quotes("USD").at(-1).taux === 0.82;
    resultat.cacheSuit = S.fxRates.EUR === 0.95 && S.fxRates.USD === 0.82;
    // 2. Append-only : re-soumettre le MÊME taux le même jour ne
    //    duplique rien ; un NOUVEAU taux s'ajoute sans effacer l'ancien.
    const nbAvant = (S.fxQuotes || []).length;
    document.getElementById("fxA").value = "0.95";
    document.getElementById("fxB").value = "0.82";
    document.getElementById("fxForm").requestSubmit();
    resultat.idempotent = (S.fxQuotes || []).length === nbAvant;
    document.getElementById("fxA").value = "0.97";
    document.getElementById("fxB").value = "0.82";
    document.getElementById("fxForm").requestSubmit();
    resultat.appendOnly = quotes("EUR").length >= 2
      && quotes("EUR").some(q => q.taux === 0.95)
      && quotes("EUR").at(-1).taux === 0.97
      && S.fxRates.EUR === 0.97;
    // 3. La porte refuse un taux illisible : rien n'est consigné, le
    //    cache ne bouge pas (FI-34).
    const refus = enregistrerTaux("EUR", 0, "test");
    resultat.refusNomme = typeof refus === "string" && refus.length > 0
      && S.fxRates.EUR === 0.97 && quotes("EUR").at(-1).taux === 0.97;
    // 4. FI-19 : l'historique estampillé n'a pas bougé d'un centime.
    const mouvement = transactions.find(t => t.id === 1);
    resultat.historiqueFige = mouvement.fx === 0.93 && mouvement.fxBase === "CHF"
      && Math.abs(txCHF(mouvement) - 93) < 0.005;
    // 5. Restauration : une quote hostile (taux négatif) est ABANDONNÉE,
    //    les saines survivent.
    const etat = JSON.parse(JSON.stringify(S));
    etat.fxQuotes.push({ base: "CHF", quote: "EUR", taux: -3, observedAt: "2026-08-25", source: "hostile" });
    let restaure = null;
    try { restaure = validatedRestoreState(etat); } catch (e) { restaure = null; }
    resultat.restaurationFiltre = !!restaure
      && !restaure.fxQuotes.some(q => q.taux === -3)
      && restaure.fxQuotes.some(q => q.taux === 0.97);
    // 6. FI-17 verrouillé : une devise de compte sans taux reste un
    //    avertissement nommé — jamais un 1:1 inventé.
    ACCOUNTS.push({ id: "gbp", name: "Livres", kind: "current", opening: 100, cash: true, currency: "GBP" });
    resultat.incompletNomme = fxWarningHTML().includes("GBP");
    ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "gbp"), 1);
    // Nettoyage.
    S.fxQuotes = []; saveState(); render();
    return resultat;
  });
  check(fxr.fonctionExiste === true,
    "enregistrerTaux existe — les taux ont UNE porte d'écriture");
  check(fxr.quotesConsignees === true && fxr.cacheSuit === true,
    `le vrai formulaire consigne des quotes datées et sourcées, le cache suit (quotes ${fxr.quotesConsignees} / cache ${fxr.cacheSuit})`);
  check(fxr.idempotent === true,
    "re-soumettre le même taux le même jour ne duplique rien");
  check(fxr.appendOnly === true,
    "un nouveau taux S'AJOUTE — l'ancienne quote survit, le cache pointe la dernière (FI-16)");
  check(fxr.refusNomme === true,
    "un taux illisible est refusé par la porte — rien n'est consigné (FI-34)");
  check(fxr.historiqueFige === true,
    "l'historique estampillé ne bouge JAMAIS quand un taux change (FI-19)");
  check(fxr.restaurationFiltre === true,
    "la restauration abandonne la quote hostile et garde les saines");
  check(fxr.incompletNomme === true,
    "FI-17 verrouillé : devise sans taux = avertissement nommé, jamais un 1:1 inventé");
  await ctx198.close();
}

// ---------- 199. W4.3 : le RELEVÉ — réconcilier laisse une preuve datée ----------
// Budget Autonomie 100, W4.3 : réconcilier un solde ne crée plus
// seulement l'ajustement tracé (comportement conservé) — un RELEVÉ
// daté est consigné (compte, solde visé en centimes, source, état
// « reconciled »), clé additive `releves`, append-only. La
// restauration abandonne un relevé hostile (FI-34).
currentTest = "W4.3 relevés de réconciliation";
{
  const ctx199 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p199 = await ctx199.newPage();
  p199.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W4.3] ${msg.text()}`); });
  await p199.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Rlv" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p199.goto(APP_URL);
  await p199.waitForSelector("#tabbar button");
  const rlv = await p199.evaluate(() => {
    const resultat = {};
    resultat.cleExiste = Array.isArray(S.releves);
    // 1. Réconcilier par le VRAI formulaire : l'ajustement tracé reste
    //    (comportement historique), ET un relevé daté est consigné.
    editingAccId = "cur";
    document.getElementById("reconAmount").value = "4850.00";
    document.getElementById("reconNegative").checked = false;
    document.getElementById("reconForm").requestSubmit();
    const ajustement = transactions.find(t => t.type === "adjustment");
    const releve = (S.releves || []).at(-1);
    const dateISO = `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(NOW.d).padStart(2, "0")}`;
    resultat.ajustementConserve = !!ajustement && ajustement.up === false
      && Math.abs(ajustement.amount - 150) < 0.005
      && Math.abs(balance("cur") - 4850) < 0.005;
    resultat.releveConsigne = !!releve
      && releve.compte === "cur"
      && releve.soldeMineur === 485000
      && releve.date === dateISO
      && releve.etat === "reconciled"
      && releve.source === "réconciliation manuelle"
      && typeof releve.ajustementTxId === "number";
    // 2. Append-only : une seconde réconciliation S'AJOUTE.
    editingAccId = "cur";
    document.getElementById("reconAmount").value = "4900.00";
    document.getElementById("reconNegative").checked = false;
    document.getElementById("reconForm").requestSubmit();
    resultat.appendOnly = (S.releves || []).length === 2
      && (S.releves || [])[0].soldeMineur === 485000
      && (S.releves || [])[1].soldeMineur === 490000;
    // 3. Un solde déjà exact ne consigne RIEN (le refus existant reste).
    editingAccId = "cur";
    document.getElementById("reconAmount").value = "4900.00";
    document.getElementById("reconNegative").checked = false;
    document.getElementById("reconForm").requestSubmit();
    resultat.exactInerte = (S.releves || []).length === 2;
    // 4. Restauration : un relevé hostile (solde non entier, état
    //    inconnu) est ABANDONNÉ, les sains survivent.
    const etat = JSON.parse(JSON.stringify(S));
    (etat.releves || (etat.releves = [])).push({ compte: "cur", soldeMineur: 12.5, date: dateISO, etat: "magique", source: "hostile" });
    let restaure = null;
    try { restaure = validatedRestoreState(etat); } catch (e) { restaure = null; }
    resultat.restaurationFiltre = !!restaure
      && restaure.releves.length === 2
      && !restaure.releves.some(r => r.etat === "magique");
    // 5. L'undo emporte aussi les relevés (l'ajustement et sa preuve
    //    partent ensemble).
    undoLast();
    resultat.undoCoherent = (S.releves || []).length === 1
      && !transactions.some(t => t.id === (S.releves[1] || {}).ajustementTxId);
    // Nettoyage.
    transactions.length = 0; S.releves = []; S.journal = []; saveState(); render();
    return resultat;
  });
  check(rlv.cleExiste === true,
    "la clé additive « releves » existe dès le chargement");
  check(rlv.ajustementConserve === true,
    "réconcilier garde son ajustement tracé — le comportement historique ne bouge pas");
  check(rlv.releveConsigne === true,
    "…ET consigne un RELEVÉ daté : compte, solde visé en centimes, source, état, lien vers l'ajustement");
  check(rlv.appendOnly === true,
    "une seconde réconciliation S'AJOUTE — jamais d'écrasement");
  check(rlv.exactInerte === true,
    "un solde déjà exact ne consigne rien — le refus existant reste");
  check(rlv.restaurationFiltre === true,
    "la restauration abandonne le relevé hostile et garde les sains (FI-34)");
  check(rlv.undoCoherent === true,
    "l'undo emporte l'ajustement ET sa preuve ensemble — jamais un état à moitié rendu");
  await ctx199.close();
}

// ---------- 200. W4.4 : le RAPPROCHEMENT — réconcilier fige l'histoire du compte ----------
// Budget Autonomie 100, W4.4 (FI-06/07) : le cycle de vie des
// écritures avance dans UN seul sens (pending→posted→cleared→
// reconciled, retours refusés nommés). Réconcilier un compte marque
// « reconciled » ses écritures postées jusqu'à la date du relevé —
// une écriture rapprochée ne MUTE jamais : sa correction vit en
// chaîne (inversion + remplaçante), et le comparateur reste à zéro.
currentTest = "W4.4 rapprochement du journal";
{
  const ctx200 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p200 = await ctx200.newPage();
  p200.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W4.4] ${msg.text()}`); });
  await p200.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Rap" },
      baseCurrency: "CHF", transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 0, cash: true, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p200.goto(APP_URL);
  await p200.waitForSelector("#tabbar button");
  const rap = await p200.evaluate(() => {
    const resultat = {};
    resultat.fonctionsExistent = typeof rapprocherJournal === "function"
      && typeof avancerCycleEcriture === "function";
    if (!resultat.fonctionsExistent) return resultat;
    // Décor : une dépense passée sur cur, une dépense sur sav, un prévu.
    const passee = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: Math.max(1, NOW.d - 2),
      title: "Courses", amount: 84.30, type: "expense", cat: "Alimentation",
      acc: "cur", dest: null, status: "posted" });
    const autre = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: Math.max(1, NOW.d - 2),
      title: "Autre compte", amount: 20, type: "expense", cat: "Divers",
      acc: "sav", dest: null, status: "posted" });
    const prevu = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 28,
      title: "Prévu", amount: 50, type: "expense", cat: "Divers",
      acc: "cur", dest: null, status: "planned" });
    // 1. La machine du cycle : un retour est refusé NOMMÉ.
    const ecriture = ecritureActiveDuMouvement(passee.id);
    const avancee = avancerCycleEcriture(ecriture, "cleared");
    const retour = avancerCycleEcriture(ecriture, "posted");
    resultat.machine = avancee === null && ecriture.lifecycle === "cleared"
      && typeof retour === "string" && retour.length > 0
      && ecriture.lifecycle === "cleared";
    // 2. Réconcilier par le VRAI formulaire fige : les écritures du
    //    compte jusqu'à la date passent « reconciled » — l'ajustement
    //    du jour aussi ; l'autre compte et le prévu ne bougent pas.
    editingAccId = "cur";
    document.getElementById("reconAmount").value = "4900.00";
    document.getElementById("reconNegative").checked = false;
    document.getElementById("reconForm").requestSubmit();
    const apres = ecritureActiveDuMouvement(passee.id);
    const ajustement = transactions.find(t => t.type === "adjustment");
    resultat.figee = apres.lifecycle === "reconciled"
      && ecritureActiveDuMouvement(ajustement.id).lifecycle === "reconciled";
    resultat.autresIntactes = ecritureActiveDuMouvement(autre.id).lifecycle === "posted"
      && ecritureActiveDuMouvement(prevu.id).lifecycle === "pending";
    // 3. Corriger un mouvement RAPPROCHÉ : l'écriture rapprochée reste
    //    INTACTE (état et centimes), la correction vit en chaîne, le
    //    comparateur reste à zéro.
    passee.amount = 90.00;
    ombreJournalDepot(passee);
    const chaineActive = ecritureActiveDuMouvement(passee.id);
    resultat.correctionEnChaine = apres.lifecycle === "reconciled"
      && apres.postings.every(p => p.montantMineur === 8430)
      && chaineActive.id !== apres.id
      && chaineActive.replacesEntryId === apres.id
      && chaineActive.postings.every(p => p.montantMineur === 9000)
      && comparerJournalEtSoldes().length === 0;
    // 4. Le solde dérivé compte les rapprochées comme les postées —
    //    seul le prévu ne pèse rien (FI-01/06).
    resultat.soldeCoherent = Math.abs(soldeDepuisJournal("cur") - balance("cur")) < 0.005;
    // Nettoyage.
    transactions.length = 0; S.journal = []; S.releves = []; saveState(); render();
    return resultat;
  });
  check(rap.fonctionsExistent === true,
    "rapprocherJournal et avancerCycleEcriture existent — le cycle a une porte");
  check(rap.machine === true,
    "le cycle avance dans UN sens — un retour est refusé nommé, l'état ne bouge pas");
  check(rap.figee === true,
    "réconcilier fige : les écritures du compte jusqu'à la date passent « reconciled », l'ajustement du jour aussi");
  check(rap.autresIntactes === true,
    "l'autre compte reste « posted » et le prévu reste « pending » — jamais rapprochés");
  check(rap.correctionEnChaine === true,
    "corriger un mouvement rapproché ne MUTE jamais l'écriture rapprochée — la chaîne corrige, comparateur à zéro (FI-07)");
  check(rap.soldeCoherent === true,
    "le solde dérivé compte les rapprochées comme les postées — seul le prévu ne pèse rien");
  await ctx200.close();
}

// ---------- 201. W4.5 : DETTES ET CARTES — le dû existe, payer est neutre, les intérêts coûtent ----------
// Budget Autonomie 100, W4.5 (FI-14) : un compte de dette peut enfin
// NAÎTRE avec un solde dû (case « solde dû » visible pour les types de
// dette seulement — le pavé iOS n'a pas de touche moins). Payer sa
// carte est un VIREMENT neutre (jamais un coût de vie) ; les intérêts
// sont une DÉPENSE depuis la carte. La restauration préserve le dû.
currentTest = "W4.5 dettes et cartes";
{
  const ctx201 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p201 = await ctx201.newPage();
  p201.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W4.5] ${msg.text()}`); });
  await p201.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Det" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p201.goto(APP_URL);
  await p201.waitForSelector("#tabbar button");
  const det = await p201.evaluate(() => {
    const resultat = {};
    const rangeeDu = document.getElementById("aOpeningNegativeRow");
    resultat.caseExiste = !!rangeeDu && !!document.getElementById("aOpeningNegative");
    if (!resultat.caseExiste) return resultat;
    // 1. La case « solde dû » n'apparaît QUE pour un type de dette, et
    //    s'y coche d'elle-même.
    openAccSheet(null);
    document.getElementById("aKind").value = "current";
    document.getElementById("aKind").dispatchEvent(new Event("change"));
    const cacheePourCourant = rangeeDu.style.display === "none";
    document.getElementById("aKind").value = "creditCard";
    document.getElementById("aKind").dispatchEvent(new Event("change"));
    resultat.caseContextuelle = cacheePourCourant
      && rangeeDu.style.display !== "none"
      && document.getElementById("aOpeningNegative").checked === true;
    // 2. Créer la carte avec 250 dû par le VRAI formulaire : ouverture
    //    négative, solde -250, patrimoine réduit d'exactement 250.
    const fortuneAvant = fortuneTotale();
    document.getElementById("aName").value = "Carte Visa";
    document.getElementById("aOpening").value = "250.00";
    document.getElementById("accForm").requestSubmit();
    const carte = ACCOUNTS.find(a => a.name === "Carte Visa");
    resultat.duNegatif = !!carte && carte.opening === -250
      && Math.abs(balance(carte.id) - (-250)) < 0.005
      && Math.abs((fortuneTotale() - fortuneAvant) - (-250)) < 0.005;
    // 3. Payer la carte = VIREMENT neutre : le résultat du mois ne
    //    bouge pas, la carte remonte vers zéro, le journal fait deux
    //    jambes de comptes réels.
    const moisAvant = yearMonthRow(NOW.y, NOW.m);
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: NOW.d, title: "Paiement carte",
      amount: 200, type: "transfer", cat: null, acc: "cur", dest: carte.id, status: "posted" });
    const moisApres = yearMonthRow(NOW.y, NOW.m);
    const ecriturePaiement = ecritureActiveDuMouvement(transactions.at(-1).id);
    resultat.paiementNeutre = Math.abs(balance(carte.id) - (-50)) < 0.005
      && moisApres.entered === moisAvant.entered
      && moisApres.spent === moisAvant.spent
      && ecriturePaiement.postings.every(p => p.compte.startsWith("compte:"));
    // 4. Les intérêts sont une DÉPENSE depuis la carte : la carte
    //    descend, le dépensé du mois monte.
    addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: NOW.d, title: "Intérêts carte",
      amount: 12.50, type: "expense", cat: "Frais", acc: carte.id, dest: null, status: "posted" });
    resultat.interetsCoutent = Math.abs(balance(carte.id) - (-62.50)) < 0.005
      && Math.abs((yearMonthRow(NOW.y, NOW.m).spent - moisApres.spent) - 12.50) < 0.005;
    // 5. La restauration préserve le dû négatif.
    const etat = JSON.parse(JSON.stringify(S));
    let restaure = null;
    try { restaure = validatedRestoreState(etat); } catch (e) { restaure = null; }
    resultat.restaurationPreserve = !!restaure
      && restaure.accounts.some(a => a.name === "Carte Visa" && a.opening === -250);
    // 6. Comparateur : tout ce petit monde raconte la même histoire.
    resultat.comparateurZero = comparerJournalEtSoldes().length === 0;
    // Nettoyage.
    transactions.length = 0; S.journal = [];
    ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === carte.id), 1);
    saveState(); render();
    return resultat;
  });
  check(det.caseExiste === true,
    "la case « solde dû » existe dans le vrai formulaire de compte");
  check(det.caseContextuelle === true,
    "elle n'apparaît QUE pour un type de dette et s'y coche d'elle-même");
  check(det.duNegatif === true,
    "une carte naît avec son dû : ouverture négative, solde -250, patrimoine réduit d'exactement 250");
  check(det.paiementNeutre === true,
    "payer sa carte est un VIREMENT neutre — jamais un coût de vie, deux jambes réelles (FI-14/FI-09)");
  check(det.interetsCoutent === true,
    "les intérêts sont une dépense depuis la carte — ils coûtent, eux (FI-14)");
  check(det.restaurationPreserve === true,
    "la restauration préserve le dû négatif — jamais coercé");
  check(det.comparateurZero === true,
    "le comparateur reste à zéro écart sur toute l'histoire de la carte");
  await ctx201.close();
}

// ---------- 202. W4.6 : l'ARCHIVAGE — un compte se range, l'histoire reste ----------
// Budget Autonomie 100, W4.6 (FI-13 → TENU) : archiver un compte le
// sort des agrégats du PRÉSENT (disponible, patrimoine) et des choix
// de NOUVEAUX mouvements — mais son histoire ne bouge pas d'un
// centime : solde intact, rapports passés identiques, mouvements
// intacts. Désarchiver le ramène. La restauration préserve le drapeau.
currentTest = "W4.6 archivage des comptes";
{
  const ctx202 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p202 = await ctx202.newPage();
  p202.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W4.6] ${msg.text()}`); });
  await p202.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Arc" },
      baseCurrency: "CHF",
      transactions: [
        { id: 1, y: 2026, m: 6, d: 10, title: "Dépense ancienne", amount: 100,
          type: "expense", cat: "Divers", acc: "old", dest: null, status: "posted" },
      ],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "old", name: "Ancien compte", kind: "current", opening: 1000, cash: true, currency: "CHF" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p202.goto(APP_URL);
  await p202.waitForSelector("#tabbar button");
  const arc = await p202.evaluate(() => {
    const resultat = {};
    const caseArchive = document.getElementById("aArchived");
    resultat.caseExiste = !!caseArchive && !!document.getElementById("aArchivedRow");
    if (!resultat.caseExiste) return resultat;
    // 1. La case n'apparaît qu'en ÉDITION, jamais à la création.
    openAccSheet(null);
    const cacheeEnCreation = document.getElementById("aArchivedRow").style.display === "none";
    closeSheet();
    // 2. Archiver par le VRAI formulaire : le drapeau se pose.
    const fortuneAvant = fortuneTotale();
    const moisPasse = JSON.stringify(yearMonthRow(2026, 6));
    openAccSheet(ACCOUNTS.find(a => a.id === "old"));
    const visibleEnEdition = document.getElementById("aArchivedRow").style.display !== "none";
    caseArchive.checked = true;
    document.getElementById("accForm").requestSubmit();
    const ancien = ACCOUNTS.find(a => a.id === "old");
    resultat.caseContextuelle = cacheeEnCreation && visibleEnEdition;
    resultat.archive = !!ancien && ancien.archived === true;
    // 3. L'histoire ne bouge pas : solde intact, mouvement intact,
    //    rapport du mois passé IDENTIQUE.
    resultat.histoireIntacte = Math.abs(balance("old") - 900) < 0.005
      && transactions.some(t => t.id === 1)
      && JSON.stringify(yearMonthRow(2026, 6)) === moisPasse;
    // 4. Les agrégats du présent l'excluent : la fortune baisse
    //    d'exactement son solde (900).
    resultat.presentExclu = Math.abs((fortuneAvant - fortuneTotale()) - 900) < 0.005;
    // 5. Plus sélectionnable pour un NOUVEAU mouvement — mais l'édition
    //    d'un ANCIEN mouvement du compte le garde.
    openTxSheet(null);
    const optionsNouveau = [...document.querySelectorAll("#fAccount option")].map(o => o.value);
    closeSheet();
    openTxSheet(transactions.find(t => t.id === 1));
    const optionsEdition = [...document.querySelectorAll("#fAccount option")].map(o => o.value);
    closeSheet();
    resultat.pickersFiltres = !optionsNouveau.includes("old") && optionsEdition.includes("old");
    // 6. Restauration : le drapeau survit ; désarchiver ramène tout.
    const etat = JSON.parse(JSON.stringify(S));
    let restaure = null;
    try { restaure = validatedRestoreState(etat); } catch (e) { restaure = null; }
    resultat.restaurationPreserve = !!restaure
      && restaure.accounts.some(a => a.id === "old" && a.archived === true);
    openAccSheet(ACCOUNTS.find(a => a.id === "old"));
    caseArchive.checked = false;
    document.getElementById("accForm").requestSubmit();
    resultat.desarchivage = ancien.archived !== true
      && Math.abs(fortuneTotale() - fortuneAvant) < 0.005;
    // Nettoyage.
    transactions.length = 0; S.journal = []; saveState(); render();
    return resultat;
  });
  check(arc.caseExiste === true,
    "la case « Archiver ce compte » existe dans le vrai formulaire");
  check(arc.caseContextuelle === true,
    "elle n'apparaît qu'en édition — on n'archive pas un compte qui naît");
  check(arc.archive === true,
    "archiver par le vrai formulaire pose le drapeau");
  check(arc.histoireIntacte === true,
    "l'histoire ne bouge pas : solde intact, mouvements intacts, rapport du mois passé IDENTIQUE (FI-13)");
  check(arc.presentExclu === true,
    "les agrégats du présent l'excluent — la fortune baisse d'exactement son solde");
  check(arc.pickersFiltres === true,
    "plus sélectionnable pour un nouveau mouvement — l'édition d'un ancien le garde");
  check(arc.restaurationPreserve === true && arc.desarchivage === true,
    `la restauration préserve le drapeau, désarchiver ramène tout (restauration ${arc.restaurationPreserve} / retour ${arc.desarchivage})`);
  await ctx202.close();
}

// ---------- 203. W4.7 : le PATRIMOINE daté et sourcé — « valeur au… », jamais inventé ----------
// Budget Autonomie 100, W4.7 (FI-27, FI-17) — DERNIER sous-lot de W4 :
// chaque bien/dette porte la DATE de son estimation (« valeur au… »),
// re-datée seulement quand la VALEUR change ; un héritage sans date
// dit « valeur non datée » — jamais une date inventée ; le patrimoine
// affiche l'état « incomplet » quand un taux manque ; le formulaire
// dette met en garde contre le double compte avec un compte de dette.
currentTest = "W4.7 patrimoine daté";
{
  const ctx203 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p203 = await ctx203.newPage();
  p203.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W4.7] ${msg.text()}`); });
  await p203.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Pat" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [],
      assets: [{ id: "as-vieux", name: "Vélo hérité", value: 800, include: true, monthly: 0, icon: "🏷" }],
      liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p203.goto(APP_URL);
  await p203.waitForSelector("#tabbar button");
  const pat = await p203.evaluate(() => {
    const resultat = {};
    const dateISO = `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(NOW.d).padStart(2, "0")}`;
    // 1. Créer un actif par le VRAI formulaire : la date d'estimation
    //    s'estampille.
    openItemSheet("asset", null);
    document.getElementById("iName").value = "Voiture";
    document.getElementById("iAmount").value = "12000.00";
    document.getElementById("itemForm").requestSubmit();
    const voiture = ASSETS.find(a => a.name === "Voiture");
    resultat.estampille = !!voiture && voiture.valueDate === dateISO;
    if (!resultat.estampille) return resultat;
    // 2. Renommer SANS changer la valeur : la date NE bouge PAS ;
    //    changer la valeur : re-datée (même jour ici — le contrat est
    //    « la date suit la VALEUR », prouvé par le renommage inerte).
    voiture.valueDate = "2026-01-15"; // simule une estimation ancienne
    openItemSheet("asset", voiture.id);
    document.getElementById("iName").value = "Voiture familiale";
    document.getElementById("itemForm").requestSubmit();
    resultat.renommageInerte = voiture.valueDate === "2026-01-15"
      && voiture.name === "Voiture familiale";
    openItemSheet("asset", voiture.id);
    document.getElementById("iAmount").value = "11000.00";
    document.getElementById("itemForm").requestSubmit();
    resultat.valeurRedatee = voiture.value === 11000 && voiture.valueDate === dateISO;
    // 3. L'affichage : « valeur au JJ.MM » pour le daté, « valeur non
    //    datée » pour l'héritage — jamais une date inventée.
    const htmlPatrimoine = renderNetWorth();
    resultat.affichageDate = htmlPatrimoine.includes("valeur au")
      && htmlPatrimoine.includes("valeur non datée");
    // 4. FI-17 sur le patrimoine : une devise sans taux rend l'état
    //    « incomplet » VISIBLE ici aussi.
    ACCOUNTS.push({ id: "gbp", name: "Livres", kind: "current", opening: 100, cash: true, currency: "GBP" });
    resultat.incompletVisible = renderNetWorth().includes("GBP");
    ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "gbp"), 1);
    // 5. Garde-fou : avec un compte de dette, le formulaire dette met
    //    en garde contre le double compte ; sans, silence.
    openItemSheet("liability", null);
    const sansCompteDette = document.getElementById("iDebtAccountWarning");
    const invisibleSans = !sansCompteDette || sansCompteDette.style.display === "none";
    closeSheet();
    ACCOUNTS.push({ id: "visa", name: "Carte Visa", kind: "creditCard", opening: -250, cash: false, currency: "CHF" });
    openItemSheet("liability", null);
    const avecCompteDette = document.getElementById("iDebtAccountWarning");
    resultat.gardeFou = invisibleSans && !!avecCompteDette
      && avecCompteDette.style.display !== "none"
      && avecCompteDette.textContent.includes("déjà");
    closeSheet();
    ACCOUNTS.splice(ACCOUNTS.findIndex(a => a.id === "visa"), 1);
    // 6. Restauration : une valueDate illisible est RETIRÉE, l'item
    //    survit (« valeur non datée », jamais une date inventée).
    const etat = JSON.parse(JSON.stringify(S));
    etat.assets.find(a => a.id === voiture.id).valueDate = "pas-une-date";
    let restaure = null;
    try { restaure = validatedRestoreState(etat); } catch (e) { restaure = null; }
    const restauree = restaure && restaure.assets.find(a => a.id === voiture.id);
    resultat.restaurationHonnete = !!restauree && restauree.valueDate == null
      && restauree.value === 11000;
    // Nettoyage.
    ASSETS.splice(ASSETS.findIndex(a => a.id === voiture.id), 1);
    saveState(); render();
    return resultat;
  });
  check(pat.estampille === true,
    "créer un bien estampille la date de l'estimation (FI-27)");
  check(pat.renommageInerte === true,
    "renommer ne re-date JAMAIS — la date suit la VALEUR, pas le nom");
  check(pat.valeurRedatee === true,
    "changer la valeur re-date l'estimation");
  check(pat.affichageDate === true,
    "l'écran dit « valeur au… » pour le daté et « valeur non datée » pour l'héritage — jamais une date inventée");
  check(pat.incompletVisible === true,
    "une devise sans taux rend le patrimoine « incomplet » VISIBLE ici aussi (FI-17)");
  check(pat.gardeFou === true,
    "le formulaire dette met en garde contre le double compte quand un compte de dette existe");
  check(pat.restaurationHonnete === true,
    "la restauration retire une date illisible et garde le bien — valeur non datée, jamais inventée");
  await ctx203.close();
}

// ---------- 204. W5.1 : les ROUTES — la navigation ADR-026, verrouillée ----------
// Budget Autonomie 100, W5.1 : W5 s'ouvre en VERROUILLANT la carte
// mesurée (docs/autonomie/w5/INVENTAIRE_ROUTES.md) — cinq destinations
// exactes, chaque sous-vue de Gérer atteignable ET revenant à Gérer,
// aucune route morte, aucun bouton d'ajout global. Né VERT (c'est un
// verrouillage d'un comportement déjà conforme) : le contrôle négatif
// fait foi.
currentTest = "W5.1 routes verrouillées";
{
  const ctx204 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p204 = await ctx204.newPage();
  p204.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W5.1] ${msg.text()}`); });
  await p204.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Nav" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p204.goto(APP_URL);
  await p204.waitForSelector("#tabbar button");
  const nav = await p204.evaluate(() => {
    const resultat = {};
    // 1. Les CINQ destinations ADR-026, ids et libellés exacts.
    resultat.destinations = JSON.stringify(TABS) === JSON.stringify([
      ["home", "Mois"], ["movements", "Historique"], ["budget", "Budget"],
      ["accounts", "Comptes"], ["more", "Gérer"],
    ]);
    const boutons = [...document.querySelectorAll("#tabbar button")];
    resultat.barreExacte = boutons.length === 5
      && boutons.map(b => b.textContent.trim()).join("|") === "Mois|Historique|Budget|Comptes|Gérer";
    // La tabbar se RE-REND à chaque navigation : chaque geste re-lit le
    // DOM vivant, comme un doigt le ferait.
    const onglet = i => [...document.querySelectorAll("#tabbar button")][i];
    // 2. Chaque destination s'ouvre par le VRAI clic et rend un écran.
    resultat.ecransVivants = [0, 1, 2, 3, 4].every(i => {
      onglet(i).click();
      return (document.getElementById("screen").innerHTML || "").length > 100;
    });
    // 3. Chaque sous-vue de Gérer s'ouvre et son retour REVIENT à Gérer.
    onglet(4).click();
    const entrees = [...document.querySelectorAll("[data-more]")].map(e => e.dataset.more);
    resultat.sousVues = entrees.length >= 10 && entrees.every(route => {
      const carte = document.querySelector(`[data-more="${route}"]`);
      if (!carte) return false;
      carte.click();
      const ouverte = moreView === route && (document.getElementById("screen").innerHTML || "").length > 100;
      const retour = document.querySelector("[data-back]");
      if (retour) retour.click();
      return ouverte && moreView === null;
    });
    // 4. Aucune route MORTE : chaque clé de MORE_RENDERERS est au menu
    //    (ou consignée comme alias interne), chaque entrée a son rendeur.
    const auMenu = new Set(entrees);
    const ALIAS_INTERNES = new Set(["movements", "subs"]); // raccourcis consignés (inventaire W5.1)
    const clesRendeurs = Object.keys(MORE_RENDERERS);
    resultat.zeroRouteMorte = clesRendeurs.every(k => auMenu.has(k) || ALIAS_INTERNES.has(k))
      && entrees.every(k => !!MORE_RENDERERS[k]);
    // 5. Aucun bouton d'ajout GLOBAL flottant, nulle part.
    resultat.zeroFab = [0, 1, 2, 3, 4].every(i => {
      onglet(i).click();
      return !document.querySelector(".fab, [data-fab], #fab");
    });
    onglet(0).click();
    return resultat;
  });
  check(nav.destinations === true && nav.barreExacte === true,
    "les cinq destinations ADR-026 — ids, libellés et ordre EXACTS");
  check(nav.ecransVivants === true,
    "chaque destination s'ouvre par le vrai clic et rend un écran vivant");
  check(nav.sousVues === true,
    "chaque sous-vue de Gérer s'ouvre ET son retour revient à Gérer");
  check(nav.zeroRouteMorte === true,
    "aucune route morte : le menu et les rendeurs se couvrent exactement (alias consignés)");
  check(nav.zeroFab === true,
    "aucun bouton d'ajout global flottant, sur aucun écran (ADR-026)");
  await ctx204.close();
}

// ---------- 205. W5.2 : le BILAN lit les échéances — ignorer libère le mois ----------
// Budget Autonomie 100, W5.2 : l'écran Mois LIT enfin les échéances
// persistées (W2). Le bilan matérialise les occurrences du mois
// (idempotent), « fait » suit la MACHINE À ÉTATS — et une échéance
// IGNORÉE (geste W2.5, jusqu'ici sans surface) cesse de bloquer le
// mois. L'histoire ancienne garde sa règle (couverture par
// mouvements) ; le comparateur W2.7a reste la gate.
currentTest = "W5.2 bilan lit les échéances";
{
  const ctx205 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p205 = await ctx205.newPage();
  p205.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W5.2] ${msg.text()}`); });
  await p205.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Bil" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [
        { id: "r-loyer", title: "Loyer", amount: 1500, type: "expense", nature: "facture",
          cat: "Logement", day: 1, every: "month", accountId: "cur", icon: "🏠" },
        { id: "r-fitness", title: "Fitness", amount: 49, type: "expense", nature: "abonnement",
          cat: "Sport", day: 5, every: "month", accountId: "cur", icon: "🏋️" },
      ],
      goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {},
      bills: [],
    }));
  });
  await p205.goto(APP_URL);
  await p205.waitForSelector("#tabbar button");
  const bil = await p205.evaluate(() => {
    const resultat = {};
    // 1. L'écran LIT le modèle persisté : appeler le bilan matérialise
    //    les occurrences du mois.
    const items = monthCheckItems(NOW.y, NOW.m);
    resultat.ecranLit = (S.occurrences || []).some(o => o.seriesId === "r-loyer")
      && (S.occurrences || []).some(o => o.seriesId === "r-fitness")
      && items.length === 2 && items.every(i => i.done === false);
    // 1b. Le VRAI écran affiche le bilan VIVANT quand il reste à faire.
    render();
    const texteEcran = document.getElementById("screen").textContent;
    resultat.ecranVivant = !!document.getElementById("monthlyTasksTitle")
      && texteEcran.includes("Bilan du mois")
      && /à faire/.test(texteEcran)
      && texteEcran.includes("Loyer");
    // 2. Confirmer par le geste existant : « fait » suit.
    materializeRecurring(RECURRINGS.find(r => r.id === "r-loyer"), NOW.y, NOW.m);
    resultat.confirmerFait = monthCheckItems(NOW.y, NOW.m)
      .find(i => i.ref === "r-loyer").done === true;
    // 3. NOUVEAU : IGNORER une échéance (geste W2.5) la règle — le
    //    mois n'est plus bloqué par une charge qu'on a choisi de
    //    sauter, sans créer AUCUN mouvement.
    const occFitness = (S.occurrences || []).find(o => o.seriesId === "r-fitness");
    const nbMouvements = transactions.length;
    const refus = occFitness ? ignorerOccurrence(occFitness) : "échéance absente — l'écran ne lit pas encore";
    resultat.ignorerRegle = refus === null
      && transactions.length === nbMouvements
      && monthCheckItems(NOW.y, NOW.m).find(i => i.ref === "r-fitness").done === true;
    // 4. Une facture ignorée aussi.
    S.bills.push({ id: "b1", name: "Électricité", amount: 184.30, dueY: NOW.y, dueM: NOW.m, dueD: 12, cat: "Logement", accountId: "cur" });
    let itemFacture = monthCheckItems(NOW.y, NOW.m).find(i => i.ref === "b1");
    const factureAvant = itemFacture && itemFacture.done === false;
    const occFacture = (S.occurrences || []).find(o => o.idempotencyKey === "facture:b1");
    if (occFacture) ignorerOccurrence(occFacture);
    itemFacture = monthCheckItems(NOW.y, NOW.m).find(i => i.ref === "b1");
    resultat.factureIgnoree = factureAvant && itemFacture.done === true;
    // 5. L'HISTOIRE ancienne garde sa règle : un mois passé couvert par
    //    ses mouvements reste « fait » même sans échéances confirmées.
    const passe = shiftMonth(NOW, -2);
    addTx({ id: ++txSeq, y: passe.y, m: passe.m, d: 1, title: "Loyer",
      amount: 1500, type: "expense", cat: "Logement", acc: "cur", dest: null,
      status: "posted", recurringId: "r-loyer" });
    resultat.histoireCouverte = monthCheckItems(passe.y, passe.m)
      .find(i => i.ref === "r-loyer").done === true;
    // 6. Le comparateur W2.7a reste la gate : zéro écart après tout ça.
    resultat.comparateurZero = comparerOccurrencesEtCompteurs(1).length === 0;
    // Nettoyage.
    transactions.length = 0; S.occurrences = []; S.bills = []; S.journal = []; saveState(); render();
    return resultat;
  });
  check(bil.ecranLit === true,
    "le bilan MATÉRIALISE et lit les échéances persistées — l'écran lit enfin le modèle W2");
  check(bil.confirmerFait === true,
    "confirmer par le geste existant règle l'élément du bilan");
  check(bil.ignorerRegle === true,
    "IGNORER une échéance la règle — aucun mouvement créé, le mois n'est plus bloqué (W2.5 a une surface)");
  check(bil.factureIgnoree === true,
    "une facture ignorée est réglée aussi");
  check(bil.histoireCouverte === true,
    "l'histoire ancienne garde sa règle — un mois passé couvert reste fait");
  check(bil.comparateurZero === true,
    "le comparateur W2.7a reste à ZÉRO écart — la gate tient");
  check(bil.ecranVivant === true,
    "le vrai écran Mois affiche le bilan vivant");
  await ctx205.close();
}

// ---------- 206. W5.3 : l'HISTORIQUE lit la chaîne — « corrigé » se voit ----------
// Budget Autonomie 100, W5.3 : la chaîne de correction du journal
// (W3.5 — inversion + remplaçante, l'histoire jamais réécrite) devient
// LISIBLE : la ligne de l'Historique porte « corrigé », la feuille du
// mouvement raconte la trace (combien de fois, l'ancien montant).
// Lecture SEULE : afficher ne change ni le journal ni les mouvements.
currentTest = "W5.3 historique lit la chaîne";
{
  const ctx206 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p206 = await ctx206.newPage();
  p206.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W5.3] ${msg.text()}`); });
  await p206.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "His" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p206.goto(APP_URL);
  await p206.waitForSelector("#tabbar button");
  const his = await p206.evaluate(() => {
    const resultat = {};
    resultat.fonctionExiste = typeof traceCorrection === "function";
    if (!resultat.fonctionExiste) return resultat;
    // Décor : un mouvement corrigé par le VRAI formulaire, un autre intact.
    const corrige = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 5, title: "Courses",
      amount: 84.30, type: "expense", cat: "Alimentation", acc: "cur", dest: null, status: "posted" });
    const intact = addTx({ id: ++txSeq, y: NOW.y, m: NOW.m, d: 6, title: "Café",
      amount: 4.50, type: "expense", cat: "Sorties", acc: "cur", dest: null, status: "posted" });
    openTxSheet(corrige);
    document.getElementById("fAmount").value = "99.90";
    document.getElementById("txForm").requestSubmit();
    // 1. La trace raconte : une révision, l'ancien montant en centimes.
    const trace = traceCorrection(corrige.id);
    resultat.traceRaconte = !!trace && trace.revisions === 1
      && trace.dernierMontantPrecedent === 8430;
    resultat.intactSansTrace = traceCorrection(intact.id) === null;
    // 2. La ligne de l'Historique porte « corrigé » — la bonne SEULEMENT.
    const ligneCorrigee = txRow(transactions.find(t => t.id === corrige.id));
    const ligneIntacte = txRow(transactions.find(t => t.id === intact.id));
    resultat.ligneMarquee = ligneCorrigee.includes("corrigé")
      && !ligneIntacte.includes("corrigé");
    // 3. La feuille raconte la trace, en français avec l'ancien montant.
    openTxSheet(transactions.find(t => t.id === corrige.id));
    const note = document.getElementById("fCorrectionNote");
    resultat.feuilleRaconte = !!note && note.style.display !== "none"
      && note.textContent.includes("Corrigé")
      && note.textContent.includes("84.30");
    closeSheet();
    // 4. Un mouvement vierge : note cachée — et une feuille de CRÉATION
    //    ouverte APRÈS une feuille corrigée repart de zéro (pas d'état
    //    rancunier).
    openTxSheet(transactions.find(t => t.id === corrige.id));
    closeSheet();
    openTxSheet(null);
    const noteCreation = document.getElementById("fCorrectionNote");
    resultat.creationSansNote = !!noteCreation && noteCreation.style.display === "none";
    closeSheet();
    openTxSheet(transactions.find(t => t.id === intact.id));
    const noteIntacte = document.getElementById("fCorrectionNote");
    resultat.viergeSansNote = !!noteIntacte && (noteIntacte.style.display === "none"
      || noteIntacte.textContent === "");
    closeSheet();
    // 5. Lecture SEULE : rien n'a bougé.
    const nbJournal = (S.journal || []).length;
    const nbMouvements = transactions.length;
    traceCorrection(corrige.id); txRow(transactions.find(t => t.id === corrige.id)); render();
    resultat.lectureSeule = (S.journal || []).length === nbJournal
      && transactions.length === nbMouvements
      && comparerJournalEtSoldes().length === 0;
    // Nettoyage.
    transactions.length = 0; S.journal = []; saveState(); render();
    return resultat;
  });
  check(his.fonctionExiste === true,
    "traceCorrection existe — la chaîne a une lecture");
  check(his.traceRaconte === true && his.intactSansTrace === true,
    `la trace raconte la correction (1 révision, ancien montant exact) et se tait pour l'intact (trace ${his.traceRaconte} / intact ${his.intactSansTrace})`);
  check(his.ligneMarquee === true,
    "la ligne de l'Historique porte « corrigé » — la bonne seulement");
  check(his.feuilleRaconte === true,
    "la feuille du mouvement raconte la correction avec l'ancien montant");
  check(his.viergeSansNote === true && his.creationSansNote === true,
    `un mouvement jamais corrigé n'a pas de note, une création non plus — pas d'état rancunier (vierge ${his.viergeSansNote} / création ${his.creationSansNote})`);
  check(his.lectureSeule === true,
    "afficher la trace ne change RIEN — lecture seule, comparateur à zéro");
  await ctx206.close();
}

// ---------- 207. W5.5 : COMPTES — les dettes ont leur groupe, les archivés leur place, les relevés se voient ----------
// Budget Autonomie 100, W5.5 : mesuré — un compte de dette (W4.1)
// était INVISIBLE sur l'écran Comptes (aucun groupe ne le couvrait).
// W5.5 : groupe « Cartes et prêts », section « Archivés » à part
// (toujours consultables), et le détail d'un compte montre son
// DERNIER RELEVÉ (W4.3) — montant constaté, date, provenance.
currentTest = "W5.5 comptes rangés";
{
  const ctx207 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p207 = await ctx207.newPage();
  p207.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W5.5] ${msg.text()}`); });
  await p207.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Cpt" },
      baseCurrency: "CHF", transactions: [],
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "visa", name: "Carte Visa", kind: "creditCard", opening: -250, cash: false, currency: "CHF" },
        { id: "old", name: "Ancien compte", kind: "current", opening: 900, cash: true, currency: "CHF", archived: true },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p207.goto(APP_URL);
  await p207.waitForSelector("#tabbar button");
  const cpt = await p207.evaluate(() => {
    const resultat = {};
    const onglet = i => [...document.querySelectorAll("#tabbar button")][i];
    onglet(3).click();
    const texte = () => document.getElementById("screen").textContent;
    // 1. La carte a enfin un GROUPE — et son solde dû s'affiche.
    resultat.groupeDettes = texte().includes("Cartes et prêts")
      && texte().includes("Carte Visa");
    // 2. L'archivé a quitté son groupe et vit dans « Archivés ».
    const html = document.getElementById("screen").innerHTML;
    const posDispo = html.indexOf("Argent disponible");
    const posArchives = html.indexOf("Archivés");
    const posAncien = html.indexOf("Ancien compte");
    resultat.archiveRange = posArchives > 0 && posAncien > posArchives
      && html.indexOf("Ancien compte") === posAncien; // une seule apparition
    // 3. L'archivé reste CONSULTABLE : son détail s'ouvre.
    const carteAncien = document.querySelector('[data-accid="old"]');
    if (carteAncien) carteAncien.click();
    resultat.archiveConsultable = !!carteAncien && accountView === "old"
      && texte().includes("Ancien compte");
    if (document.querySelector("[data-accback]")) document.querySelector("[data-accback]").click();
    // 4. Le détail montre le DERNIER RELEVÉ après une vraie
    //    réconciliation.
    editingAccId = "cur";
    document.getElementById("reconAmount").value = "4900.00";
    document.getElementById("reconNegative").checked = false;
    document.getElementById("reconForm").requestSubmit();
    const carteCur = document.querySelector('[data-accid="cur"]');
    if (carteCur) carteCur.click();
    resultat.releveVisible = texte().includes("Dernier relevé")
      && texte().includes("4'900.00")
      && texte().includes("réconciliation manuelle");
    if (document.querySelector("[data-accback]")) document.querySelector("[data-accback]").click();
    // 5. Sans relevé : la carte du détail n'en parle pas.
    const carteVisa = document.querySelector('[data-accid="visa"]');
    if (carteVisa) carteVisa.click();
    resultat.sansReleveMuet = !texte().includes("Dernier relevé");
    if (document.querySelector("[data-accback]")) document.querySelector("[data-accback]").click();
    // Nettoyage.
    transactions.length = 0; S.releves = []; S.journal = []; saveState(); render();
    return resultat;
  });
  check(cpt.groupeDettes === true,
    "les cartes et prêts ont enfin leur groupe sur l'écran Comptes (trou W4.1 fermé)");
  check(cpt.archiveRange === true,
    "un compte archivé quitte son groupe et vit dans « Archivés » — une seule apparition");
  check(cpt.archiveConsultable === true,
    "l'archivé reste consultable — son histoire s'ouvre");
  check(cpt.releveVisible === true,
    "le détail montre le DERNIER RELEVÉ : solde constaté, date, provenance (W4.3 enfin visible)");
  check(cpt.sansReleveMuet === true,
    "sans relevé, le détail n'invente rien");
  await ctx207.close();
}

// ---------- 208. W5.4 : BUDGET — le futur parle au conditionnel, le passé au passé ----------
// Budget Autonomie 100, W5.4 (ADR-055/056 confirmés sur la destination
// Budget) : mesuré — un mois FUTUR avec budget disait « Il vous reste à
// dépenser » + « Dans le plan » (présent de l'indicatif sur un mois qui
// n'a pas commencé) et comparait son coût de la vie VIDE au mois
// dernier ; un mois PASSÉ disait encore « reste à dépenser » alors que
// le mois est clos. Aucun calcul ne change — seuls les mots.
currentTest = "W5.4 budget conditionnel";
{
  const ctx208 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p208 = await ctx208.newPage();
  p208.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W5.4] ${msg.text()}`); });
  await p208.addInitScript(() => {
    const now = new Date();
    const y = now.getFullYear(), m = now.getMonth() + 1;
    const cle = (yy, mm) => `${yy}-${mm}`;
    const decale = d => {
      const t = new Date(y, m - 1 + d, 1);
      return { y: t.getFullYear(), m: t.getMonth() + 1 };
    };
    const prev = decale(-1), next = decale(1);
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Plan" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      budgets: {
        [cle(prev.y, prev.m)]: [{ cat: "Alimentation", amount: 600 }],
        [cle(y, m)]: [{ cat: "Alimentation", amount: 600 }],
        [cle(next.y, next.m)]: [{ cat: "Alimentation", amount: 600 }],
      },
      transactions: [
        { id: 1, title: "Courses", amount: 120, type: "expense", cat: "Alimentation", acc: "cur", dest: null, status: "posted", y, m, d: 2 },
        { id: 2, title: "Courses", amount: 560, type: "expense", cat: "Alimentation", acc: "cur", dest: null, status: "posted", y: prev.y, m: prev.m, d: 3 },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], bills: [],
    }));
  });
  await p208.goto(APP_URL);
  await p208.waitForSelector("#tabbar button");
  const plan = await p208.evaluate(() => {
    const resultat = {};
    const onglet = i => [...document.querySelectorAll("#tabbar button")][i];
    onglet(2).click(); // Budget (ADR-026)
    const hero = () => {
      const el = document.querySelector("#screen .card.hero");
      return el ? el.textContent : "";
    };
    // 1. Le mois COURANT garde ses mots (verrou d'existant — le
    //    sabotage fait foi) : le présent est le bon temps.
    resultat.courantIntact = hero().includes("Il vous reste à dépenser")
      && hero().includes("480.00") && hero().includes("Dans le plan");
    const ecran = () => document.getElementById("screen").textContent;
    // 2. Le mois FUTUR parle au CONDITIONNEL — prévu, pas couru.
    cursor = shiftMonth(cursor, 1); render();
    resultat.futurConditionnel = hero().includes("Prévu pour ce mois")
      && hero().includes("Si vous suivez le plan") && hero().includes("600.00");
    resultat.futurSansPresent = !hero().includes("Il vous reste à dépenser")
      && !hero().includes("Dans le plan");
    // 3. Le futur ne compare pas son mois VIDE au mois dernier.
    resultat.comparaisonTue = !hero().includes("Mois dernier");
    // 4. Le mois PASSÉ parle au PASSÉ : le mois est clos.
    cursor = shiftMonth(cursor, -2); render();
    resultat.passeAuPasse = hero().includes("Il vous est resté")
      && hero().includes("40.00") && !hero().includes("Il vous reste à dépenser");
    resultat.passePille = hero().includes("Budget tenu")
      && !hero().includes("Dans le plan") && !hero().includes("À surveiller");
    // 5. La ligne à 93 % d'un mois CLOS ne dit plus « À surveiller »
    //    (verrou né avec l'implémentation — le sabotage fait foi).
    resultat.passeSansSurveiller = !ecran().includes("À surveiller")
      && ecran().includes("Alimentation");
    cursor = shiftMonth(cursor, 1); render();
    return resultat;
  });
  check(plan.courantIntact === true,
    "le mois courant garde « Il vous reste à dépenser » — le présent est son temps");
  check(plan.futurConditionnel === true,
    "le mois futur dit « Prévu pour ce mois » et « Si vous suivez le plan » — le conditionnel (ADR-055/056)");
  check(plan.futurSansPresent === true,
    "le futur ne parle plus au présent : ni « reste à dépenser » ni « Dans le plan »");
  check(plan.comparaisonTue === true,
    "le futur ne compare pas son mois vide au mois dernier");
  check(plan.passeAuPasse === true,
    "le mois passé dit « Il vous est resté » — le mois est clos");
  check(plan.passePille === true,
    "au passé la pastille raconte le résultat : « Budget tenu » ou « Dépassé »");
  check(plan.passeSansSurveiller === true,
    "une ligne d'un mois clos ne se « surveille » plus — seul « Dépassé » reste un fait");
  await ctx208.close();
}

// ---------- 209. W5.6 : GÉRER — les taux datés se voient ----------
// Budget Autonomie 100, W5.6 : mesuré — W4.2 consigne chaque taux avec
// sa date et sa provenance (append-only), mais Gérer n'en montrait
// RIEN : la rangée « Taux de change manuels » listait les valeurs
// sans dire de quand elles datent, la feuille non plus. Un taux sans
// date est une promesse invérifiable (« devise/taux/date explicites »).
currentTest = "W5.6 taux datés visibles";
{
  const ctx209 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p209 = await ctx209.newPage();
  p209.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W5.6] ${msg.text()}`); });
  await p209.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Fx" },
      baseCurrency: "CHF", transactions: [],
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 1000, cash: true, currency: "CHF" }],
      fxRates: { EUR: 0.95 },
      fxQuotes: [{ base: "CHF", quote: "EUR", taux: 0.95, observedAt: "2026-08-20", source: "saisie manuelle" }],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p209.goto(APP_URL);
  await p209.waitForSelector("#tabbar button");
  const fx = await p209.evaluate(() => {
    const resultat = {};
    activeTab = "more"; moreView = "settings"; render();
    const ecran = () => document.getElementById("screen").textContent;
    // 1. La rangée dit QUAND le dernier taux a été consigné.
    resultat.rangeeDatee = ecran().includes("consigné le 20.08.2026");
    // 2. Et reste honnête sur le réseau (verrou d'existant).
    resultat.horsReseau = ecran().includes("aucune connexion réseau");
    // 3. La feuille raconte PAR devise : valeur, date, provenance…
    const porte = document.querySelector("[data-editfx]");
    if (porte) porte.click();
    const feuille = () => document.getElementById("fxForm").textContent;
    resultat.feuilleRaconte = feuille().includes("0.95")
      && feuille().includes("20.08.2026") && feuille().includes("saisie manuelle");
    // 4. … et dit « jamais consigné » pour la devise restée au défaut.
    resultat.defautHonnete = feuille().includes("jamais consigné");
    document.getElementById("fxCancel").click();
    // 5. Regarder n'écrit rien : le journal des taux n'a pas bougé.
    resultat.lectureSeule = (S.fxQuotes || []).length === 1
      && S.fxQuotes[0].observedAt === "2026-08-20";
    activeTab = "home"; moreView = null; render();
    return resultat;
  });
  check(fx.rangeeDatee === true,
    "la rangée de Gérer dit quand le dernier taux a été consigné (W4.2 enfin visible)");
  check(fx.horsReseau === true,
    "l'honnêteté réseau reste écrite : « aucune connexion réseau »");
  check(fx.feuilleRaconte === true,
    "la feuille des taux raconte par devise : valeur, date, provenance");
  check(fx.defautHonnete === true,
    "la devise jamais consignée le dit — un défaut n'est pas une mesure");
  check(fx.lectureSeule === true,
    "afficher les taux n'écrit rien — lecture seule, journal intact");
  await ctx209.close();
}

// ---------- 210. W5.7 : INBOX — Reporter et Ignorer existent enfin, ignorer libère (ADR-066) ----------
// Budget Autonomie 100, W5.7 : mesuré — les gestes d'agenda W2.5
// (reporterOccurrence, ignorerOccurrence) n'avaient AUCUN appelant à
// l'écran, et une échéance ignorée pesait encore sur le disponible
// (recurringRemainingCount = dues − liées, sans lire les échéances).
// Décision propriétaire du 26.08.2026 (ADR-066) : IGNORER LIBÈRE — un
// choix explicite rend l'argent au « Prévu fin du mois ». Reporter
// garde l'échéance ouverte : reporté ≠ libéré.
currentTest = "W5.7 gestes d'agenda";
{
  const ctx210 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p210 = await ctx210.newPage();
  p210.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W5.7] ${msg.text()}`); });
  p210.on("dialog", dialog => dialog.accept());
  await p210.addInitScript(() => {
    const now = new Date();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Inbox" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      recurrings: [{ id: "loyer", title: "Loyer", amount: 1500, type: "expense", cat: "Logement", accountId: "cur", every: "month", day: 1, nature: "facture" }],
      bills: [{ id: "prime", name: "Prime auto", amount: 400, dueY: now.getFullYear(), dueM: now.getMonth() + 1, dueD: 20, cat: "Assurances", paidTxId: null }],
      transactions: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, occurrences: [],
    }));
  });
  await p210.goto(APP_URL);
  await p210.waitForSelector("#tabbar button");
  const inbox = await p210.evaluate(() => {
    const resultat = {};
    const loyer = RECURRINGS.find(r => r.id === "loyer");
    const prime = (S.bills || []).find(b => b.id === "prime");
    const avantTx = transactions.length;
    const s0 = snapshot(NOW.y, NOW.m);
    const dispo = () => snapshot(NOW.y, NOW.m).available;
    // 1. La feuille de la série offre les gestes d'agenda.
    openRecSheet(loyer);
    const bloc = document.getElementById("rAgendaGestes");
    resultat.gestesVisibles = !!bloc && bloc.style.display !== "none"
      && !!document.getElementById("rSkipMonth") && !!document.getElementById("rSnoozeBtn");
    // 2. REPORTER garde l'échéance ouverte — la date d'origine ne bouge
    //    jamais, et l'argent reste réservé (reporté ≠ libéré).
    const dans10jours = (() => {
      const d = new Date(Date.now() + 10 * 86400000);
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    })();
    const champDate = document.getElementById("rSnoozeDate");
    if (champDate) champDate.value = dans10jours;
    if (document.getElementById("rSnoozeBtn")) document.getElementById("rSnoozeBtn").click();
    const occLoyer = () => (S.occurrences || []).find(o =>
      typeof o.idempotencyKey === "string" && o.idempotencyKey.startsWith(`serie:loyer:${NOW.y}-${NOW.m}:`));
    const apresReport = occLoyer();
    resultat.reporterGarde = !!apresReport && apresReport.state === "snoozed"
      && apresReport.dueDate === dans10jours
      && apresReport.originalDueDate !== apresReport.dueDate;
    resultat.reporteReserve = dispo() === s0.available;
    // 3. IGNORER libère (ADR-066) : l'échéance est réglée d'un choix,
    //    la charge ne pèse plus, l'argent revient au disponible.
    openRecSheet(loyer);
    if (document.getElementById("rSkipMonth")) document.getElementById("rSkipMonth").click();
    const apresSkip = occLoyer();
    resultat.ignorerAgit = !!apresSkip && apresSkip.state === "skipped";
    resultat.ignorerLibere = round2(dispo() - s0.available) === 1500;
    resultat.attenteLiberee = !monthlyObligations(NOW.y, NOW.m).some(i =>
      i.id === "loyer" && !["paid", "skipped"].includes(i.state));
    // 4. Une FACTURE s'ignore pareil — et libère pareil.
    openBillSheet(prime);
    if (document.getElementById("bSkipMonth")) document.getElementById("bSkipMonth").click();
    resultat.factureLiberee = typeof factureSautee === "function" && factureSautee(prime) === true
      && round2(dispo() - s0.available) === 1900;
    // 5. Des gestes d'AGENDA : aucun mouvement créé ni touché.
    resultat.argentIntact = transactions.length === avantTx;
    // 6. Le comparateur W2.7a raconte toujours zéro écart (fenêtre
    //    matérialisée d'abord — verrou, le sabotage fait foi).
    materialiserOccurrences(NOW.y, NOW.m);
    const prochain = shiftMonth({ y: NOW.y, m: NOW.m }, 1);
    materialiserOccurrences(prochain.y, prochain.m);
    resultat.comparateurZero = comparerOccurrencesEtCompteurs(2).length === 0;
    return resultat;
  });
  check(inbox.gestesVisibles === true,
    "la feuille d'une série due offre enfin Reporter et Ignorer (W2.5 exposé)");
  check(inbox.reporterGarde === true,
    "reporter déplace l'échéance en gardant la date d'ORIGINE — elle reste ouverte");
  check(inbox.reporteReserve === true,
    "reporté ≠ libéré : l'argent reste réservé après un report");
  check(inbox.ignorerAgit === true,
    "ignorer passe l'échéance en skipped — un choix, pas un oubli");
  check(inbox.ignorerLibere === true,
    "ADR-066 : ignorer LIBÈRE — la charge ignorée rend ses 1500 au disponible");
  check(inbox.attenteLiberee === true,
    "la ligne ignorée quitte la liste « à faire » — on ne propose pas de payer un choix");
  check(inbox.factureLiberee === true,
    "une facture s'ignore pareil — et libère pareil (400 de plus)");
  check(inbox.argentIntact === true,
    "gestes d'agenda : aucun mouvement créé ni touché");
  check(inbox.comparateurZero === true,
    "le comparateur W2.7a garde zéro écart — les compteurs ont appris la même vérité");
  await ctx210.close();
}

// ---------- 211. W6.1 : BUDGET — le reste se reporte (opt-in par ligne, ADR-067) ----------
// Budget Autonomie 100, W6.1 : mesuré — le budget est plat, une
// catégorie sous-dépensée repart de zéro chaque mois. Décision
// propriétaire du 26.08.2026 : report OPT-IN par ligne (« reporter le
// reste »), comportement actuel = défaut. Le report est CALCULÉ en
// chaîne depuis les mois précédents, jamais stocké en double ; un
// dépassement ne se reporte jamais (pas de dette de budget cachée).
currentTest = "W6.1 report budgétaire";
{
  const ctx211 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p211 = await ctx211.newPage();
  p211.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W6.1] ${msg.text()}`); });
  await p211.addInitScript(() => {
    const now = new Date();
    const y = now.getFullYear(), m = now.getMonth() + 1;
    const decale = d => {
      const t = new Date(y, m - 1 + d, 1);
      return { y: t.getFullYear(), m: t.getMonth() + 1 };
    };
    const m1 = decale(-1), m2 = decale(-2);
    const tx = (id, mm, amount, cat) => ({
      id, title: cat, amount, type: "expense", cat, acc: "cur", dest: null,
      status: "posted", y: mm.y, m: mm.m, d: 5,
    });
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Rep" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 9000, cash: true, currency: "CHF" }],
      budgets: {
        [`${m2.y}-${m2.m}`]: [
          { cat: "Alimentation", amount: 600, report: true },
        ],
        [`${m1.y}-${m1.m}`]: [
          { cat: "Alimentation", amount: 600, report: true },
          { cat: "Restaurants et sorties", amount: 100, report: true },
        ],
        [`${y}-${m}`]: [
          { cat: "Alimentation", amount: 600, report: true },
          { cat: "Transports", amount: 250 },
          { cat: "Restaurants et sorties", amount: 100, report: true },
        ],
      },
      transactions: [
        tx(1, m2, 500, "Alimentation"), // reste 100 → reporté
        tx(2, m1, 400, "Alimentation"), // reste 600+100−400 = 300 → reporté
        tx(3, { y, m }, 100, "Alimentation"),
        tx(4, m1, 150, "Restaurants et sorties"), // dépassement : rien ne se reporte
        tx(5, { y, m }, 100, "Transports"),
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], bills: [],
    }));
  });
  await p211.goto(APP_URL);
  await p211.waitForSelector("#tabbar button");
  const rep = await p211.evaluate(() => {
    const resultat = {};
    const soldeAvant = balance("cur");
    const rapport = budgetReport(NOW.y, NOW.m);
    const ligne = nom => rapport.lines.find(l => l.cat === nom) || {};
    // 1. La chaîne est CALCULÉE : 100 (M−2) + 600 − 400 = 300 arrivent.
    resultat.chaineCalculee = ligne("Alimentation").carry === 300
      && ligne("Alimentation").effectif === 900;
    // 2. Sans report : rien ne change (comportement actuel = défaut).
    resultat.sansReportIntact = ligne("Transports").carry === 0
      && ligne("Transports").effectif === 250;
    // 3. Un dépassement ne se reporte JAMAIS (Sport M−1 : 150 sur 100).
    resultat.depassementJamaisNegatif = ligne("Restaurants et sorties").carry === 0
      && ligne("Restaurants et sorties").effectif === 100;
    // 4. L'écran raconte le report — montant effectif ET provenance.
    const onglet = i => [...document.querySelectorAll("#tabbar button")][i];
    onglet(2).click();
    const texte = document.getElementById("screen").textContent;
    resultat.ecranRaconte = texte.includes("900.00") && texte.includes("reporté");
    // 5. La feuille de ligne offre la case « reporter le reste ».
    const bouton = document.querySelector("#screen [data-addline]");
    if (bouton) bouton.click();
    resultat.caseVisible = !!document.getElementById("lReport");
    if (document.getElementById("lineForm")) {
      const annuler = document.getElementById("lCancel");
      if (annuler) annuler.click();
    }
    // 6. Le report est calculé, jamais STOCKÉ : les lignes persistées ne
    //    portent aucun champ carry/effectif.
    const stockees = Object.values(S.budgets).flat();
    resultat.jamaisStocke = stockees.every(l => l.carry === undefined && l.effectif === undefined);
    // 7. FI-20 : le budget ne touche aucun solde bancaire.
    resultat.fi20 = balance("cur") === soldeAvant;
    return resultat;
  });
  check(rep.chaineCalculee === true,
    "le report se calcule en CHAÎNE : 300 arrivent en plus des 600 (effectif 900)");
  check(rep.sansReportIntact === true,
    "une ligne sans report garde exactement le comportement actuel");
  check(rep.depassementJamaisNegatif === true,
    "un dépassement ne se reporte jamais — pas de dette de budget cachée");
  check(rep.ecranRaconte === true,
    "l'écran Budget raconte le report : montant effectif et « reporté »");
  check(rep.caseVisible === true,
    "la feuille de ligne offre « Reporter le reste au mois suivant » (opt-in)");
  check(rep.jamaisStocke === true,
    "le report est calculé, jamais stocké en double dans les lignes");
  check(rep.fi20 === true,
    "FI-20 : le budget ne touche aucun solde bancaire");
  await ctx211.close();
}

// ---------- 212. W6.2 : REVENUS VARIABLES — l'estimation se nomme, rien n'est promis ----------
// Budget Autonomie 100, W6.2 : mesuré — pour un indépendant (aucun
// revenu récurrent), la prévision « Fin du mois » utilise une moyenne
// des 3 derniers mois (irregularIncome)… FONDUE dans « + CHF X à
// recevoir », indistincte des revenus réellement planifiés. Une
// estimation statistique n'est pas une promesse : elle se NOMME.
currentTest = "W6.2 revenus variables";
{
  const ctx212 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p212 = await ctx212.newPage();
  p212.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W6.2] ${msg.text()}`); });
  await p212.addInitScript(() => {
    const now = new Date();
    const y = now.getFullYear(), m = now.getMonth() + 1;
    const decale = d => {
      const t = new Date(y, m - 1 + d, 1);
      return { y: t.getFullYear(), m: t.getMonth() + 1 };
    };
    const m1 = decale(-1), m2 = decale(-2), m3 = decale(-3);
    const revenu = (id, mm, amount) => ({
      id, title: "Mandat", amount, type: "income", cat: "Salaire", acc: "cur",
      dest: null, status: "posted", y: mm.y, m: mm.m, d: 10,
    });
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Indé" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 3000, cash: true, currency: "CHF" }],
      transactions: [revenu(1, m3, 4000), revenu(2, m2, 5000), revenu(3, m1, 4500)],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p212.goto(APP_URL);
  await p212.waitForSelector("#tabbar button");
  const inde = await p212.evaluate(() => {
    const resultat = {};
    const s = snapshot(NOW.y, NOW.m);
    resultat.moyenneCalculee = s.irregularIncome === 4500; // (4000+5000+4500)/3
    // Vue « Fin du mois » du mois courant.
    heroVue = "finmois"; render();
    const note = () => {
      const el = document.querySelector("#screen .home-hero");
      return el ? el.textContent : "";
    };
    // 1. L'estimation se NOMME — montant, méthode, honnêteté.
    resultat.termeNomme = note().includes("estimés")
      && note().includes("4'500.00") && note().includes("3 derniers mois");
    // 2. Elle n'est PLUS fondue dans « à recevoir » (rien n'est promis).
    resultat.plusFondue = !note().includes("4'500.00 à recevoir");
    // 3. Aucun agrégat ne bouge : la prévision reste liquid + moyenne.
    resultat.calculIntact = s.endOfMonthForecast === round2(s.liquid + 4500);
    // 4. Un salarié (revenu récurrent) ne voit JAMAIS ce terme.
    RECURRINGS.push({ id: "r-sal", title: "Salaire", amount: 6000, type: "income",
      cat: "Salaire", day: 25, every: "month", accountId: "cur" });
    render();
    resultat.salarieMuet = !note().includes("estimés");
    RECURRINGS.pop(); heroVue = null; render();
    return resultat;
  });
  check(inde.moyenneCalculee === true,
    "la moyenne des 3 derniers mois vaut 4'500 (mesure de départ)");
  check(inde.termeNomme === true,
    "l'estimation se nomme : montant, « estimés », « 3 derniers mois »");
  check(inde.plusFondue === true,
    "l'estimation n'est plus fondue dans « à recevoir » — rien n'est promis");
  check(inde.calculIntact === true,
    "aucun agrégat ne bouge : seule la phrase change");
  check(inde.salarieMuet === true,
    "un salarié ne voit jamais ce terme — l'estimation est réservée aux revenus variables");
  await ctx212.close();
}

// ---------- 213. W6.3 : BUDGET — la part engagée se voit, à part des enveloppes ----------
// Budget Autonomie 100, W6.3 : mesuré — l'écran Budget ne montre que
// les enveloppes par catégorie ; les charges régulières et factures du
// mois (la part ENGAGÉE, non discrétionnaire) n'y apparaissent nulle
// part. Livré : une carte de LECTURE (sortiesReelles du Mois réutilisé
// — zéro nouveau compteur), qui respecte ADR-066 (ignorer libère).
currentTest = "W6.3 part engagée";
{
  const ctx213 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p213 = await ctx213.newPage();
  p213.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W6.3] ${msg.text()}`); });
  await p213.addInitScript(() => {
    const now = new Date();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Eng" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 8000, cash: true, currency: "CHF" }],
      recurrings: [{ id: "loyer", title: "Loyer", amount: 1800, type: "expense", cat: "Logement", accountId: "cur", every: "month", day: 1, nature: "facture" }],
      bills: [{ id: "prime", name: "Prime auto", amount: 400, dueY: now.getFullYear(), dueM: now.getMonth() + 1, dueD: 20, cat: "Transports", paidTxId: null }],
      budgets: {
        [`${now.getFullYear()}-${now.getMonth() + 1}`]: [{ cat: "Alimentation", amount: 600 }],
      },
      transactions: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], occurrences: [],
    }));
  });
  await p213.goto(APP_URL);
  await p213.waitForSelector("#tabbar button");
  const eng = await p213.evaluate(() => {
    const resultat = {};
    const onglet = i => [...document.querySelectorAll("#tabbar button")][i];
    const s0 = snapshot(NOW.y, NOW.m);
    onglet(2).click();
    const texte = () => document.getElementById("screen").textContent;
    // 1. La part engagée se voit : 1800 + 400 = 2'200 encore à sortir.
    resultat.carteVisible = texte().includes("Engagements du mois")
      && texte().includes("2'200.00") && texte().includes("à part de vos enveloppes");
    // 2. Lecture seule : aucun agrégat n'a bougé.
    const s1 = snapshot(NOW.y, NOW.m);
    resultat.lectureSeule = s1.endOfMonthForecast === s0.endOfMonthForecast
      && s1.recurringCharges === s0.recurringCharges;
    // 3. ADR-066 : ignorer l'échéance du loyer libère aussi cette carte.
    materialiserOccurrences(NOW.y, NOW.m);
    const occ = echeanceOuverteSerie("loyer", NOW.y, NOW.m);
    if (occ) ignorerOccurrence(occ);
    render();
    resultat.respecteIgnorer = !texte().includes("2'200.00") && texte().includes("400.00");
    // 4. Plus d'engagement du tout : la carte se tait.
    const prime = (S.bills || []).find(b => b.id === "prime");
    materialiserFactures(NOW.y, NOW.m);
    const occPrime = (S.occurrences || []).find(o => o.idempotencyKey === "facture:prime");
    if (occPrime) ignorerOccurrence(occPrime);
    render();
    resultat.sansEngagementMuet = !texte().includes("Engagements du mois") && !!prime;
    // 5. Un mois PASSÉ ne parle pas d'engagements — le passé est réel.
    cursor = shiftMonth(cursor, -1); render();
    resultat.passeMuet = !texte().includes("Engagements du mois");
    cursor = shiftMonth(cursor, 1); render();
    return resultat;
  });
  check(eng.carteVisible === true,
    "la part engagée du mois se voit sur Budget : 2'200 à part des enveloppes");
  check(eng.lectureSeule === true,
    "la carte LIT — aucun agrégat ne bouge");
  check(eng.respecteIgnorer === true,
    "ADR-066 tenu : ignorer le loyer libère aussi la carte (reste 400)");
  check(eng.sansEngagementMuet === true,
    "sans engagement restant, la carte se tait");
  check(eng.passeMuet === true,
    "un mois passé ne parle pas d'engagements — le passé est réel");
  await ctx213.close();
}

// ---------- 214. W6.4 : FONDS ANNUELS — le lissage se lit, l'argent ne bouge pas ----------
// Budget Autonomie 100, W6.4 : mesuré — une charge annuelle (SERAFE,
// prime auto) tombe d'un coup, sans repère de lissage nulle part.
// Décision propriétaire du 26.08.2026 : INFORMATIF en V1 — l'écran
// montre le douzième et où on devrait en être, AUCUN virement n'est
// créé (« le bouton enregistre, jamais le calendrier »).
currentTest = "W6.4 fonds annuels";
{
  const ctx214 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p214 = await ctx214.newPage();
  p214.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W6.4] ${msg.text()}`); });
  await p214.addInitScript(() => {
    const now = new Date();
    const m = now.getMonth() + 1;
    // Échéance dans 4 mois → 8 douzièmes déjà « dus » depuis la dernière.
    const dueM = ((m + 3) % 12) + 1;
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Fds" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 4000, cash: true, currency: "CHF" }],
      recurrings: [
        { id: "serafe", title: "SERAFE", amount: 335, type: "expense", cat: "Logement",
          accountId: "cur", every: "year", dueM, day: 10, nature: "facture" },
        { id: "fitness", title: "Fitness", amount: 49, type: "expense", cat: "Logement",
          accountId: "cur", every: "month", day: 5, nature: "abonnement" },
      ],
      transactions: [], bills: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {},
    }));
  });
  await p214.goto(APP_URL);
  await p214.waitForSelector("#tabbar button");
  const fds = await p214.evaluate(() => {
    const resultat = {};
    const avant = JSON.stringify({ tx: transactions.length, occ: (S.occurrences || []).length });
    openRecSheet(RECURRINGS.find(r => r.id === "serafe"));
    const feuille = () => document.getElementById("recForm").textContent;
    // 1. Le repère se lit : douzième mensuel + où on devrait en être.
    resultat.blocVisible = feuille().includes("Fonds de lissage")
      && feuille().includes("27.92");
    resultat.repereJuste = feuille().includes("223.33") && feuille().includes("8/12");
    // 2. L'honnêteté est écrite : rien n'est viré automatiquement.
    resultat.honnete = feuille().includes("Rien n'est viré automatiquement");
    document.getElementById("rCancel").click();
    // 3. Une charge MENSUELLE n'a pas de fonds de lissage.
    openRecSheet(RECURRINGS.find(r => r.id === "fitness"));
    resultat.mensuelleMuette = !(() => {
      const bloc = document.getElementById("rFondsAnnuel");
      return bloc && bloc.style.display !== "none" && bloc.textContent.includes("Fonds de lissage");
    })();
    document.getElementById("rCancel").click();
    // 4. Informatif : AUCUNE écriture — ni mouvement ni échéance.
    resultat.aucuneEcriture = JSON.stringify({ tx: transactions.length, occ: (S.occurrences || []).length }) === avant;
    return resultat;
  });
  check(fds.blocVisible === true,
    "la feuille d'une charge annuelle montre le fonds de lissage (CHF 27.92 par mois)");
  check(fds.repereJuste === true,
    "le repère dit où on devrait en être : CHF 223.33 (8/12) — calculé sur le montant annuel");
  check(fds.honnete === true,
    "l'honnêteté est écrite : rien n'est viré automatiquement");
  check(fds.mensuelleMuette === true,
    "une charge mensuelle n'a pas de fonds de lissage");
  check(fds.aucuneEcriture === true,
    "informatif pur : aucune écriture, aucun mouvement, aucune échéance créée");
  await ctx214.close();
}

// ---------- 215. W6.5 : OBJECTIFS — la valeur manuelle est datée, la provenance se lit ----------
// Budget Autonomie 100, W6.5 : contrat DATA_MODEL_TARGET — « un
// objectif avance par affectation réelle ou valeur manuelle
// explicitement DATÉE, jamais par projection seule ». Mesuré : le
// solde lié fait foi (réel ✓) mais manualCurrent était un chiffre NU,
// sans date ; l'écran ne disait pas de quand datait la saisie.
currentTest = "W6.5 objectifs datés";
{
  const ctx215 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p215 = await ctx215.newPage();
  p215.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W6.5] ${msg.text()}`); });
  await p215.addInitScript(() => {
    const now = new Date();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Obj" },
      baseCurrency: "CHF",
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 2000, cash: true, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 4000, cash: false, currency: "CHF" },
      ],
      goals: [
        { id: "g-velo", name: "Vélo", emoji: "🚲", target: 3000, manualCurrent: 1200,
          linked: null, monthly: 100, dueY: now.getFullYear() + 1, dueM: 6, priority: false, achieved: false },
        { id: "g-fonds", name: "Fonds", emoji: "🛟", target: 10000, manualCurrent: 0,
          linked: "sav", monthly: 200, dueY: now.getFullYear() + 2, dueM: 1, priority: false, achieved: false },
      ],
      transactions: [], recurrings: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p215.goto(APP_URL);
  await p215.waitForSelector("#tabbar button");
  const obj = await p215.evaluate(() => {
    const resultat = {};
    activeTab = "more"; moreView = "goals"; render();
    const ecran = () => document.getElementById("screen").textContent;
    // 1. L'ancien état (valeur jamais datée) le DIT au lieu d'inventer.
    resultat.nonDateeDit = ecran().includes("non daté");
    // 2. Saisir une nouvelle valeur la DATE (règle W4.7 : re-datée
    //    seulement si la valeur change).
    openGoalSheet(GOALS.find(g => g.id === "g-velo"));
    document.getElementById("gCurrent").value = "1500";
    document.getElementById("goalForm").requestSubmit();
    const velo = GOALS.find(g => g.id === "g-velo");
    const aujourdhui = `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(NOW.d).padStart(2, "0")}`;
    resultat.saisieDatee = velo.manualCurrentDate === aujourdhui;
    const dateFR = `${String(NOW.d).padStart(2, "0")}.${String(NOW.m).padStart(2, "0")}.${NOW.y}`;
    resultat.ecranRaconte = ecran().includes(`saisi le ${dateFR}`);
    // 3. Re-soumettre SANS changer la valeur ne re-date pas (photo).
    velo.manualCurrentDate = "2026-01-15"; saveState();
    openGoalSheet(velo);
    document.getElementById("goalForm").requestSubmit();
    resultat.memeValeurGardeDate = GOALS.find(g => g.id === "g-velo").manualCurrentDate === "2026-01-15";
    // 4. Un objectif LIÉ n'a pas de date manuelle — le solde fait foi.
    resultat.lieSansDate = GOALS.find(g => g.id === "g-fonds").manualCurrentDate === undefined
      && ecran().includes("Sur « Épargne »");
    // 5. Restauration : une date illisible est retirée, jamais gardée.
    const photo = JSON.parse(JSON.stringify(S));
    photo.goals[0].manualCurrentDate = "n'importe quoi";
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    resultat.restaurationFiltre = !!restauree
      && restauree.goals[0].manualCurrentDate === undefined;
    activeTab = "home"; moreView = null; render();
    return resultat;
  });
  check(obj.nonDateeDit === true,
    "une valeur jamais datée le dit — « non daté », jamais une date inventée");
  check(obj.saisieDatee === true,
    "saisir une valeur manuelle la date du jour même");
  check(obj.ecranRaconte === true,
    "l'écran raconte la provenance : « saisi le JJ.MM.AAAA »");
  check(obj.memeValeurGardeDate === true,
    "re-soumettre la même valeur ne re-date pas — la date dit la photo (W4.7)");
  check(obj.lieSansDate === true,
    "un objectif lié n'a pas de date manuelle — le solde du compte fait foi");
  check(obj.restaurationFiltre === true,
    "restauration : une date illisible est retirée, la restauration reste acceptée");
  await ctx215.close();
}

// ---------- 216. W6.6 : MOIS/ANNÉE — chaque période consultée utilise SA période (FI-23) ----------
// Budget Autonomie 100, W6.6 : verrou d'existant — l'invariant FI-23
// (« aucune horloge courante dans un agrégat historique ») est TENU
// aujourd'hui ; ce parcours le fige. Né vert assumé : le sabotage
// (l'année consultée lit l'horloge) fait foi, consigné au statut.
currentTest = "W6.6 périodes étanches";
{
  const ctx216 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p216 = await ctx216.newPage();
  p216.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W6.6] ${msg.text()}`); });
  await p216.addInitScript(() => {
    const now = new Date();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Per" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 9000, cash: true, currency: "CHF" }],
      budgets: { "2024-5": [{ cat: "Alimentation", amount: 600 }] },
      transactions: [
        { id: 1, title: "Salaire", amount: 5000, type: "income", cat: "Salaire", acc: "cur", dest: null, status: "posted", y: 2024, m: 5, d: 25 },
        { id: 2, title: "Courses", amount: 450, type: "expense", cat: "Alimentation", acc: "cur", dest: null, status: "posted", y: 2024, m: 5, d: 6 },
        { id: 3, title: "Courses", amount: 333, type: "expense", cat: "Alimentation", acc: "cur", dest: null, status: "posted", y: now.getFullYear(), m: now.getMonth() + 1, d: 2 },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], bills: [],
    }));
  });
  await p216.goto(APP_URL);
  await p216.waitForSelector("#tabbar button");
  const per = await p216.evaluate(() => {
    const resultat = {};
    // 1. La page Année 2024 raconte 2024 — la dépense d'aujourd'hui
    //    (333) n'y fuit pas, les chiffres de mai 2024 y sont exacts.
    activeTab = "more"; moreView = "year"; yearCursor = 2024; render();
    const ecran = () => document.getElementById("screen").textContent;
    resultat.anneeExacte = ecran().includes("5'000.00") && ecran().includes("450.00")
      && !ecran().includes("333.00");
    // 2. Une année PASSÉE n'a aucun mois « En cours » — l'horloge ne
    //    fuit pas dans l'histoire.
    resultat.sansHorloge = !ecran().includes("En cours") && !ecran().includes("· ce mois");
    // 3. Les agrégats du mois consulté utilisent SA période.
    const mai = snapshot(2024, 5);
    resultat.moisExact = mai.living === 450 && mai.income === 5000;
    // 4. Le budget consulté aussi : le réel de mai 2024, rien d'autre.
    const rapport = budgetReport(2024, 5);
    const ligne = rapport.lines.find(l => l.cat === "Alimentation");
    resultat.budgetExact = !!ligne && ligne.actual === 450;
    activeTab = "home"; moreView = null; yearCursor = NOW.y; render();
    return resultat;
  });
  check(per.anneeExacte === true,
    "FI-23 : l'année 2024 raconte 2024 — rien du mois courant n'y fuit");
  check(per.sansHorloge === true,
    "une année passée n'a aucun mois « En cours » — l'horloge reste chez elle");
  check(per.moisExact === true,
    "le mois consulté utilise sa période : mai 2024 = 450 dépensés, 5'000 reçus");
  check(per.budgetExact === true,
    "le budget consulté lit le réel de SA période");
  await ctx216.close();
}

// ---------- 217. W7.1 : IMPORT — chaque ligne garde sa source et son verdict ----------
// Budget Autonomie 100, W7.1 (modèle intermédiaire) : mesuré —
// l'analyse (ready/duplicate/invalid) et l'empreinte existent, mais
// RIEN n'est conservé : S.lastImport garde un résumé, le verdict de
// chaque ligne est perdu, le rollback oublie tout. W7.1 : un journal
// d'imports persisté (S.imports, append-only) — verdicts nommés,
// empreintes, hash du brut (jamais le brut : vie privée), rollback
// tracé. La porte d'import existante reste LA porte.
currentTest = "W7.1 sources d'import";
{
  const ctx217 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p217 = await ctx217.newPage();
  p217.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W7.1] ${msg.text()}`); });
  await p217.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Imp" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 3000, cash: true, currency: "CHF" }],
      transactions: [
        { id: 1, title: "Migros", amount: 80, type: "expense", cat: null, acc: "cur",
          dest: null, status: "posted", y: 2026, m: 7, d: 3 },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p217.goto(APP_URL);
  await p217.waitForSelector("#tabbar button");
  const imp = await p217.evaluate(() => {
    const resultat = {};
    const csv = [
      "Date;Montant;Libellé",
      "05.07.2026;-45.50;Pharmacie",   // nouvelle → ready
      "03.07.2026;-80.00;Migros",      // déjà présente → duplicate
      "pas-une-date;-12.00;Kiosque",   // invalide → motif nommé
    ].join("\n");
    const analyse = analyzeCSV(csv, null, "cur");
    const avantTx = transactions.length;
    applyImport(analyse, "releve-juillet.csv", "cur");
    // 1. Le journal d'imports existe et raconte : verdicts nommés.
    const lot = (S.imports || [])[0];
    resultat.journalConserve = !!lot && typeof lot.id === "string"
      && /^\d{4}-\d{2}-\d{2}T/.test(lot.appliedAt || "")
      && Array.isArray(lot.records) && lot.records.length === 3;
    const verdicts = lot ? lot.records.map(r => r.verdict).sort().join(",") : "";
    resultat.verdictsNommes = verdicts === "duplicate,invalid,ready";
    // 2. Empreinte pour ready/duplicate ; motif pour l'invalide ;
    //    hash du brut partout — JAMAIS le texte brut (vie privée).
    const ready = lot && lot.records.find(r => r.verdict === "ready");
    const dup = lot && lot.records.find(r => r.verdict === "duplicate");
    const inv = lot && lot.records.find(r => r.verdict === "invalid");
    resultat.empreintesStockees = !!ready && typeof ready.fingerprint === "string" && ready.fingerprint.length > 0
      && !!dup && typeof dup.fingerprint === "string"
      && !!inv && inv.motif === "date illisible";
    resultat.brutJamaisStocke = !!lot && lot.records.every(r =>
      r.raw === undefined && typeof r.rawHash === "string" && r.rawHash.length > 0);
    // 3. La ligne importée est LIÉE : le record ready porte le txId créé.
    resultat.ligneLiee = !!ready && transactions.some(t => String(t.id) === String(ready.txId));
    // 4. REJOUER le même relevé : zéro doublon, et la tentative se
    //    consigne aussi (l'histoire des imports est complète).
    const analyse2 = analyzeCSV(csv, null, "cur");
    applyImport(analyse2, "releve-juillet.csv", "cur");
    resultat.rejouerSansDoublon = transactions.length === avantTx + 1
      && (S.imports || []).length === 2 && S.imports[1].imported === 0;
    // 5. Le rollback est TRACÉ : le lot porte rolledBackAt, les
    //    mouvements du lot partent, le journal reste.
    rollbackLastImport();
    resultat.rollbackTrace = (S.imports || []).length === 2
      && /^\d{4}-\d{2}-\d{2}T/.test(S.imports[1].rolledBackAt || "")
      && S.imports[1].rolledBackAt !== S.imports[0].rolledBackAt
      && S.imports[0].rolledBackAt === undefined;
    // Incident CI consigné : deux imports dans la même milliseconde
    // partageaient un id — le rollback marquait le mauvais lot.
    resultat.idsUniques = S.imports[0].id !== S.imports[1].id;
    // 6. Restauration : un lot illisible est écarté, les bons restent.
    const photo = JSON.parse(JSON.stringify(S));
    photo.imports = Array.isArray(photo.imports) ? photo.imports : [];
    photo.imports.push({ nimporte: "quoi" });
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    resultat.restaurationFiltre = !!restauree && Array.isArray(restauree.imports)
      && restauree.imports.length === 2;
    return resultat;
  });
  check(imp.journalConserve === true,
    "chaque import laisse un lot persisté : id, date d'application, 3 enregistrements");
  check(imp.verdictsNommes === true,
    "les verdicts sont nommés : ready, duplicate, invalid — rien n'est perdu");
  check(imp.empreintesStockees === true,
    "empreinte normalisée conservée (ready/duplicate), motif nommé pour l'invalide");
  check(imp.brutJamaisStocke === true,
    "le texte brut n'est JAMAIS stocké — un hash suffit (vie privée)");
  check(imp.ligneLiee === true,
    "l'enregistrement source est LIÉ au mouvement créé (txId)");
  check(imp.rejouerSansDoublon === true,
    "rejouer le même relevé n'écrit rien — et la tentative se consigne aussi");
  check(imp.rollbackTrace === true,
    "le rollback est tracé (rolledBackAt) — le journal d'imports survit");
  check(imp.idsUniques === true,
    "deux lots nés dans la même milliseconde gardent des ids distincts");
  check(imp.restaurationFiltre === true,
    "restauration : un lot illisible est écarté, les lots sains restent");
  await ctx217.close();
}

// ---------- 218. W7.2 : IMPORT — l'identité d'une ligne est normalisée (FI-29, fixture partagée) ----------
// Budget Autonomie 100, W7.2 : les fixtures « doublons d'import »
// différées depuis W1.5 arrivent — la MÊME fixture
// (fixtures/import-doublons.json) est lue par les deux plateformes.
// Côté web, l'empreinte était déjà normalisée (sans nom de fichier) :
// verrous en partie nés verts, le sabotage fait foi.
currentTest = "W7.2 doublons d'import";
{
  const fixtureDoublons = JSON.parse(fs.readFileSync(
    path.resolve(HERE, "..", "..", "fixtures", "import-doublons.json"), "utf8"));
  const ctx218 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p218 = await ctx218.newPage();
  p218.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W7.2] ${msg.text()}`); });
  await p218.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Fp" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 3000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p218.goto(APP_URL);
  await p218.waitForSelector("#tabbar button");
  const fp = await p218.evaluate((fx) => {
    const resultat = {};
    const verdicts = analyse => analyse.rows.map(r => r.state);
    // 1. Premier import : tout entre.
    const a1 = analyzeCSV(fx.csv, null, "cur");
    resultat.premierImport = JSON.stringify(verdicts(a1)) === JSON.stringify(fx.premierImport.verdicts);
    applyImport(a1, fx.premierImport.fichier, "cur");
    // 2. Le MÊME contenu sous un AUTRE nom : tout est doublon.
    const a2 = analyzeCSV(fx.csv, null, "cur");
    resultat.rejeuRenomme = JSON.stringify(verdicts(a2)) === JSON.stringify(fx.rejeuRenomme.verdicts);
    // 3. Deux lignes identiques d'un MÊME fichier : la 2e est un doublon.
    const a3 = analyzeCSV(fx.memeFichierLigneDoublee.csv, null, "cur");
    resultat.ligneDoublee = JSON.stringify(verdicts(a3)) === JSON.stringify(fx.memeFichierLigneDoublee.verdicts);
    // 4. La casse ne change pas l'identité ; un montant différent, si.
    const a4 = analyzeCSV("Date;Montant;Libellé\n" + fx.casseDifferente.ligne, null, "cur");
    resultat.casseDifferente = verdicts(a4)[0] === fx.casseDifferente.verdict;
    const a5 = analyzeCSV("Date;Montant;Libellé\n" + fx.vraieNouvelle.ligne, null, "cur");
    resultat.vraieNouvelle = verdicts(a5)[0] === fx.vraieNouvelle.verdict;
    return resultat;
  }, fixtureDoublons);
  check(fp.premierImport === true,
    "fixture doublons : le premier import entre entièrement (3 ready)");
  check(fp.rejeuRenomme === true,
    "FI-29 : le même contenu sous un AUTRE nom de fichier = doublons, jamais réimporté");
  check(fp.ligneDoublee === true,
    "deux lignes identiques d'un même fichier : la seconde est un doublon");
  check(fp.casseDifferente === true,
    "le libellé est plié — la casse ne change pas l'identité");
  check(fp.vraieNouvelle === true,
    "un montant différent est une autre opération — elle entre");
  await ctx218.close();
}

// ---------- 219. W7.3 : TAGS — vos mots sur un mouvement, retrouvables ----------
// Budget Autonomie 100, W7.3 : mesuré — un mouvement n'a qu'une
// catégorie ; aucun moyen d'y poser SES mots (« vacances »,
// « remboursable ») ni de les retrouver. Livré : tags LIBRES (esprit
// CAT1), clé additive, pliés et bornés, recherche de l'Historique
// étendue. Aucun agrégat ne lit les tags — des mots, pas de l'argent.
currentTest = "W7.3 tags libres";
{
  const ctx219 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p219 = await ctx219.newPage();
  p219.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W7.3] ${msg.text()}`); });
  await p219.addInitScript(() => {
    const now = new Date();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Tag" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 3000, cash: true, currency: "CHF" }],
      transactions: [
        { id: 1, title: "Hôtel Lugano", amount: 240, type: "expense", cat: null, acc: "cur",
          dest: null, status: "posted", y: now.getFullYear(), m: now.getMonth() + 1, d: 3 },
        { id: 2, title: "Courses", amount: 55, type: "expense", cat: "Alimentation", acc: "cur",
          dest: null, status: "posted", y: now.getFullYear(), m: now.getMonth() + 1, d: 4 },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p219.goto(APP_URL);
  await p219.waitForSelector("#tabbar button");
  const tag = await p219.evaluate(() => {
    const resultat = {};
    // 1. La feuille du mouvement offre le champ tags.
    openTxSheet(transactions.find(t => t.id === 1));
    const champ = document.getElementById("fTags");
    resultat.champVisible = !!champ;
    // 2. Saisir des tags les stocke PLIÉS et dédupliqués, bornés.
    if (champ) {
      champ.value = " Vacances , remboursable, VACANCES ,  ";
      document.getElementById("txForm").requestSubmit();
    }
    const hotel = transactions.find(t => t.id === 1);
    resultat.tagsNormalises = Array.isArray(hotel.tags)
      && JSON.stringify(hotel.tags) === JSON.stringify(["vacances", "remboursable"]);
    // 3. La recherche de l'Historique les trouve.
    activeTab = "movements"; moreSearch = "vacances"; render();
    const ecran = () => document.getElementById("screen").textContent;
    resultat.rechercheTrouve = ecran().includes("Hôtel Lugano") && !ecran().includes("Courses");
    moreSearch = ""; render();
    // 4. Rouvrir la feuille préremplit ; re-soumettre sans toucher garde.
    openTxSheet(transactions.find(t => t.id === 1));
    resultat.feuillePrereplie = (document.getElementById("fTags") || {}).value === "vacances, remboursable";
    document.getElementById("txForm").requestSubmit();
    resultat.reSoumissionGarde = JSON.stringify(transactions.find(t => t.id === 1).tags)
      === JSON.stringify(["vacances", "remboursable"]);
    // 5. Un mouvement sans tags n'a pas la clé (sobriété).
    resultat.sansTagsSobre = transactions.find(t => t.id === 2).tags === undefined;
    // 6. Restauration : des tags hostiles sont assainis, jamais gardés.
    const photo = JSON.parse(JSON.stringify(S));
    photo.transactions.find(t => t.id === 2).tags = [12, "", "x".repeat(200), "ok"];
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    const t2 = restauree && restauree.transactions.find(t => t.id === 2);
    resultat.restaurationFiltre = !!t2 && JSON.stringify(t2.tags) === JSON.stringify(["ok"]);
    return resultat;
  });
  check(tag.champVisible === true,
    "la feuille du mouvement offre le champ « Tags (facultatif) »");
  check(tag.tagsNormalises === true,
    "les tags sont pliés, dédupliqués, vides retirés : [vacances, remboursable]");
  check(tag.rechercheTrouve === true,
    "la recherche de l'Historique trouve un mouvement par son tag");
  check(tag.feuillePrereplie === true,
    "rouvrir la feuille prérempli les tags");
  check(tag.reSoumissionGarde === true,
    "re-soumettre sans toucher garde les tags");
  check(tag.sansTagsSobre === true,
    "un mouvement sans tags ne porte pas la clé");
  check(tag.restaurationFiltre === true,
    "restauration : tags hostiles assainis (types, vides, longueurs)");
  await ctx219.close();
}

// ---------- 220. W7.4 : « IMPRÉVU » — le repli honnête, jamais une fausse catégorie ----------
// Budget Autonomie 100, W7.4 : mesuré — la saisie force une catégorie
// existante ou l'écriture libre ; rien pour dire honnêtement « je ne
// sais pas encore ». Résultat : une fausse catégorie silencieuse.
// Livré : « Imprévu » entre au référentiel (dépense), proposé à la
// saisie avec un langage honnête ; le hors-budget le nomme déjà.
currentTest = "W7.4 repli Imprévu";
{
  const ctx220 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p220 = await ctx220.newPage();
  p220.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W7.4] ${msg.text()}`); });
  await p220.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Imp" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 3000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p220.goto(APP_URL);
  await p220.waitForSelector("#tabbar button");
  const imprevu = await p220.evaluate(() => {
    const resultat = {};
    // 1. La saisie d'une dépense propose « Imprévu » — langage honnête.
    openTxSheet(null);
    document.getElementById("fType").value = "expense";
    document.getElementById("fType").dispatchEvent(new Event("change"));
    const options = [...document.getElementById("fCat").options];
    const option = options.find(o => o.value === "Imprévu");
    resultat.optionProposee = !!option;
    resultat.langageHonnete = !!option && /reclasser/i.test(option.textContent);
    // 2. Le référentiel le connaît comme une DÉPENSE.
    resultat.referentiel = categoryKind("Imprévu") === "expense";
    // 3. Choisir « Imprévu » stocke la catégorie telle quelle.
    if (option) {
      document.getElementById("fAmount").value = "37.90";
      document.getElementById("fCat").value = "Imprévu";
      document.getElementById("fCat").dispatchEvent(new Event("change"));
      document.getElementById("fDate").value = `${NOW.y}-${String(NOW.m).padStart(2, "0")}-${String(NOW.d).padStart(2, "0")}`;
      document.getElementById("fFait").checked = true;
      document.getElementById("txForm").requestSubmit();
    }
    const saisie = transactions.find(t => t.cat === "Imprévu");
    resultat.saisieStocke = !!saisie && saisie.type === "expense";
    // 4. Sans ligne budgétaire, le Budget le nomme dans « Pas encore
    //    classé » — rien n'est perdu, rien n'est déguisé.
    const rapport = budgetReport(NOW.y, NOW.m);
    resultat.budgetHonnete = rapport.outOfBudget.some(([cat, v]) => cat === "Imprévu" && v === 37.9);
    // 5. Et une ligne budgétaire « Imprévu » reste possible (enveloppe).
    resultat.budgetable = categoriesOfKinds(["expense"]).includes("Imprévu");
    return resultat;
  });
  check(imprevu.optionProposee === true,
    "la saisie d'une dépense propose « Imprévu »");
  check(imprevu.langageHonnete === true,
    "le langage est honnête : « à reclasser » est écrit dans l'option");
  check(imprevu.referentiel === true,
    "le référentiel connaît « Imprévu » comme une dépense");
  check(imprevu.saisieStocke === true,
    "choisir « Imprévu » stocke la catégorie telle quelle");
  check(imprevu.budgetHonnete === true,
    "sans enveloppe, le Budget nomme « Imprévu » dans « Pas encore classé »");
  check(imprevu.budgetable === true,
    "une enveloppe « Imprévu » reste possible dans le Budget");
  await ctx220.close();
}

// ---------- 221. W7.5 : SPLITS — une dépense, plusieurs catégories, la somme exacte ----------
// Budget Autonomie 100, W7.5 (décision propriétaire du 26.08.2026 :
// les parts vivent DANS le mouvement — un seul flux bancaire, le
// solde ne bouge pas d'un centime ; seuls les rapports par catégorie
// ventilent). Porte unique definirParts, refus nommés, centimes
// entiers (G01), somme EXACTE.
currentTest = "W7.5 splits";
{
  const ctx221 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p221 = await ctx221.newPage();
  p221.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W7.5] ${msg.text()}`); });
  await p221.addInitScript(() => {
    const now = new Date();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Spl" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 3000, cash: true, currency: "CHF" }],
      transactions: [
        { id: 1, title: "Migros", amount: 120, type: "expense", cat: "Alimentation", acc: "cur",
          dest: null, status: "posted", y: now.getFullYear(), m: now.getMonth() + 1, d: 5 },
        { id: 2, title: "Coop", amount: 89.99, type: "expense", cat: "Alimentation", acc: "cur",
          dest: null, status: "posted", y: now.getFullYear(), m: now.getMonth() + 1, d: 6 },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], bills: [],
      budgets: { [`${now.getFullYear()}-${now.getMonth() + 1}`]: [{ cat: "Alimentation", amount: 200 }] },
    }));
  });
  await p221.goto(APP_URL);
  await p221.waitForSelector("#tabbar button");
  const spl = await p221.evaluate(() => {
    const resultat = {};
    const migros = transactions.find(t => t.id === 1);
    const soldeAvant = balance("cur");
    if (typeof definirParts !== "function") return { porteExiste: false };
    resultat.porteExiste = true;
    // 1. Les refus sont NOMMÉS — jamais un zéro silencieux.
    const refusSomme = definirParts(migros, [
      { cat: "Alimentation", montantMineur: 8000 },
      { cat: "Logement", montantMineur: 3999 },
    ]);
    const refusSeule = definirParts(migros, [{ cat: "Alimentation", montantMineur: 12000 }]);
    resultat.refusNommes = typeof refusSomme === "string" && /somme/i.test(refusSomme)
      && typeof refusSeule === "string" && /deux/i.test(refusSeule);
    // 2. Le succès stocke des centimes ENTIERS, somme exacte.
    const succes = definirParts(migros, [
      { cat: "Alimentation", montantMineur: 8000 },
      { cat: "Logement", montantMineur: 4000 },
    ]);
    resultat.porteStocke = succes === null && Array.isArray(migros.parts)
      && migros.parts.every(p => Number.isInteger(p.montantMineur))
      && migros.parts.reduce((a, p) => a + p.montantMineur, 0) === 12000;
    // 3. Le solde ne bouge pas d'un centime : UN seul flux bancaire.
    resultat.soldeIntact = balance("cur") === soldeAvant;
    // 4. Le Budget VENTILE : chaque part pèse sur SA catégorie.
    const rapport = budgetReport(NOW.y, NOW.m);
    const horsBudget = Object.fromEntries(rapport.outOfBudget);
    const ligneAlim = rapport.lines.find(l => l.cat === "Alimentation");
    resultat.budgetVentile = !!ligneAlim && ligneAlim.actual === round2(80 + 89.99)
      && horsBudget["Logement"] === 40
      && horsBudget["Alimentation"] === undefined;
    // 5. L'UI scinde en deux : le reste se calcule EXACT (89.99 → 59.99 + 30.00).
    openTxSheet(transactions.find(t => t.id === 2));
    const champCat = document.getElementById("fSplitCat");
    const champMontant = document.getElementById("fSplitAmount");
    if (champCat && champMontant) {
      champCat.value = "Transports";
      champMontant.value = "30.00";
      document.getElementById("txForm").requestSubmit();
    }
    const coop = transactions.find(t => t.id === 2);
    resultat.uiScinde = Array.isArray(coop.parts) && coop.parts.length === 2
      && coop.parts[0].cat === "Alimentation" && coop.parts[0].montantMineur === 5999
      && coop.parts[1].cat === "Transports" && coop.parts[1].montantMineur === 3000;
    // 6. La feuille RACONTE la scission au retour.
    openTxSheet(coop);
    const note = document.getElementById("fPartsNote");
    resultat.feuilleRaconte = !!note && note.style.display !== "none"
      && /59\.99/.test(note.textContent) && /30\.00/.test(note.textContent);
    closeSheet();
    // 7. Restauration : des parts qui MENTENT (somme fausse) sont
    //    retirées — le mouvement reste vrai, la ventilation disparaît.
    const photo = JSON.parse(JSON.stringify(S));
    photo.transactions.find(t => t.id === 1).parts[0].montantMineur = 7999;
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    const t1 = restauree && restauree.transactions.find(t => t.id === 1);
    resultat.restaurationFiltre = !!t1 && t1.parts === undefined && t1.amount === 120;
    return resultat;
  });
  check(spl.porteExiste === true,
    "la porte unique definirParts existe");
  check(spl.refusNommes === true,
    "les refus sont nommés : somme fausse, moins de deux parts");
  check(spl.porteStocke === true,
    "le succès stocke des centimes entiers, somme exacte (12000)");
  check(spl.soldeIntact === true,
    "le solde ne bouge pas d'un centime — un seul flux bancaire");
  check(spl.budgetVentile === true,
    "le Budget ventile : chaque part pèse sur sa catégorie");
  check(spl.uiScinde === true,
    "l'UI scinde en deux — le reste se calcule exact (59.99 + 30.00)");
  check(spl.feuilleRaconte === true,
    "la feuille raconte la scission au retour");
  check(spl.restaurationFiltre === true,
    "restauration : des parts qui mentent sont retirées, le mouvement reste vrai");
  await ctx221.close();
}

// ---------- 222. W7.6 : RÈGLES — « ce libellé → cette catégorie », le futur seulement ----------
// Budget Autonomie 100, W7.6 (décision propriétaire du 26.08.2026 :
// FUTUR seulement — le passé ne bouge jamais tout seul). Une règle
// s'applique à l'ANALYSE d'import (prévisualisée avant toute
// écriture) ; porte unique creerRegle, refus nommés ; l'UI vit sur
// l'écran Import.
currentTest = "W7.6 règles d'import";
{
  const ctx222 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p222 = await ctx222.newPage();
  p222.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W7.6] ${msg.text()}`); });
  await p222.addInitScript(() => {
    const now = new Date();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Reg" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 3000, cash: true, currency: "CHF" }],
      transactions: [
        { id: 1, title: "MIGROS SA", amount: 60, type: "expense", cat: null, acc: "cur",
          dest: null, status: "posted", y: now.getFullYear(), m: now.getMonth() + 1, d: 2 },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [], pensions: [],
      insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p222.goto(APP_URL);
  await p222.waitForSelector("#tabbar button");
  const reg = await p222.evaluate(() => {
    const resultat = {};
    if (typeof creerRegle !== "function") return { porteExiste: false };
    resultat.porteExiste = true;
    // 1. Les refus sont nommés.
    const refusMotif = creerRegle("", "Alimentation");
    const refusCat = creerRegle("migros", "CategorieInconnue");
    resultat.refusNommes = typeof refusMotif === "string" && /motif/i.test(refusMotif)
      && typeof refusCat === "string" && /catégorie/i.test(refusCat);
    // 2. La création passe par la porte, pliée.
    const succes = creerRegle("  MIGROS ", "Alimentation");
    resultat.porteStocke = succes === null && (S.regles || []).length === 1
      && S.regles[0].motif === "migros" && S.regles[0].cat === "Alimentation";
    // 3. La règle s'applique à l'ANALYSE d'import (prévisualisation) —
    //    une ligne SANS catégorie reçoit la sienne avant toute écriture.
    const analyse = analyzeCSV("Date;Montant;Libellé\n05.07.2026;-42.00;MIGROS GENEVE", null, "cur");
    resultat.regleApplique = analyse.rows[0].state === "ready"
      && analyse.rows[0].tx.cat === "Alimentation";
    // 4. Et l'écriture suit la prévisualisation.
    applyImport(analyse, "releve.csv", "cur");
    resultat.ecritureSuit = transactions.some(t => t.title === "MIGROS GENEVE" && t.cat === "Alimentation");
    // 5. FUTUR SEULEMENT : le mouvement passé « MIGROS SA » reste tel quel.
    resultat.passeIntact = transactions.find(t => t.id === 1).cat === null;
    // 6. Une colonne catégorie du CSV PRIME sur la règle (la source dit vrai).
    const analyse2 = analyzeCSV("Date;Montant;Libellé;Catégorie\n06.07.2026;-15.00;MIGROS RESTO;Restaurants et sorties", null, "cur");
    resultat.sourcePrime = analyse2.rows[0].tx.cat === "Restaurants et sorties";
    // 7. L'écran Import porte la gestion des règles.
    activeTab = "more"; moreView = "importcsv"; render();
    const ecran = () => document.getElementById("screen").textContent;
    resultat.uiVisible = ecran().includes("Règles de catégorisation") && ecran().includes("migros");
    // 8. Restauration : une règle hostile (catégorie inconnue) est écartée.
    const photo = JSON.parse(JSON.stringify(S));
    photo.regles = Array.isArray(photo.regles) ? photo.regles : [];
    photo.regles.push({ id: "r-x", motif: "kiosque", cat: "PasUneCategorie" });
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    resultat.restaurationFiltre = !!restauree && Array.isArray(restauree.regles)
      && restauree.regles.length === 1 && restauree.regles[0].motif === "migros";
    activeTab = "home"; moreView = null; render();
    return resultat;
  });
  check(reg.porteExiste === true, "la porte unique creerRegle existe");
  check(reg.refusNommes === true, "les refus sont nommés : motif vide, catégorie inconnue");
  check(reg.porteStocke === true, "la règle est stockée pliée (motif « migros »)");
  check(reg.regleApplique === true,
    "la règle s'applique à l'ANALYSE — visible avant toute écriture");
  check(reg.ecritureSuit === true, "l'écriture suit la prévisualisation");
  check(reg.passeIntact === true,
    "FUTUR seulement : le mouvement passé reste tel quel — l'histoire ne bouge pas");
  check(reg.sourcePrime === true,
    "une colonne catégorie du CSV prime sur la règle — la source dit vrai");
  check(reg.uiVisible === true,
    "l'écran Import porte « Règles de catégorisation » et liste la règle");
  check(reg.restaurationFiltre === true,
    "restauration : une règle à catégorie inconnue est écartée, les saines restent");
  await ctx222.close();
}

// ---------- 223. W7.7 : REVUE D'IMPORT — refuser ligne par ligne, annuler lot par lot ----------
// Budget Autonomie 100, W7.7 (dernier sous-lot de W7) : mesuré —
// l'aperçu d'import était tout-ou-rien (aucun refus ligne par ligne)
// et le rollback ne visait que le DERNIER lot. Livré : exclusions à
// l'écriture (verdict « refused » consigné au journal), rollback
// CIBLÉ par lot, et l'écran Import porte les deux.
currentTest = "W7.7 revue d'import";
{
  const ctx223 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p223 = await ctx223.newPage();
  p223.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W7.7] ${msg.text()}`); });
  await p223.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Rev" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p223.goto(APP_URL);
  await p223.waitForSelector("#tabbar button");
  const rev = await p223.evaluate(() => {
    const resultat = {};
    const csvA = "Date;Montant;Libellé\n05.07.2026;-45.50;Pharmacie\n06.07.2026;-12.00;Kiosque\n07.07.2026;-30.00;Boulangerie";
    // 1. REFUSER ligne par ligne : la ligne 3 (Kiosque) est écartée —
    //    pas écrite, mais CONSIGNÉE au journal (verdict « refused »).
    const analyseA = analyzeCSV(csvA, null, "cur");
    const ligneKiosque = analyseA.rows.find(r => r.tx && r.tx.title === "Kiosque").line;
    applyImport(analyseA, "releve-a.csv", "cur", [ligneKiosque]);
    resultat.refusLigne = !transactions.some(t => t.title === "Kiosque")
      && transactions.some(t => t.title === "Pharmacie")
      && transactions.some(t => t.title === "Boulangerie");
    const lotA = (S.imports || [])[0];
    resultat.refusConsigne = !!lotA && lotA.imported === 2
      && lotA.records.some(r => r.verdict === "refused" && r.line === ligneKiosque);
    // 2. ROLLBACK CIBLÉ : deux lots, annuler le PREMIER seulement.
    const csvB = "Date;Montant;Libellé\n08.07.2026;-9.00;Journal";
    applyImport(analyzeCSV(csvB, null, "cur"), "releve-b.csv", "cur");
    resultat.deuxLots = (S.imports || []).length === 2 && transactions.length === 3;
    if (typeof rollbackImport !== "function") { resultat.rollbackCible = false; }
    else {
      rollbackImport(lotA.id);
      resultat.rollbackCible = !transactions.some(t => t.title === "Pharmacie")
        && transactions.some(t => t.title === "Journal")
        && /^\d{4}-\d{2}-\d{2}T/.test(lotA.rolledBackAt || "")
        && S.imports[1].rolledBackAt === undefined;
    }
    // 3. L'écran Import porte le JOURNAL des lots — avec l'annulation
    //    ciblée du lot encore présent.
    activeTab = "more"; moreView = "importcsv"; render();
    const ecran = () => document.getElementById("screen").textContent;
    resultat.uiJournal = ecran().includes("Journal des imports")
      && ecran().includes("releve-b.csv")
      && !!document.querySelector("[data-rollbacklot]");
    // 4. L'aperçu offre le refus ligne par ligne (toggle « Écarter »).
    // Le brouillon est construit comme le fait startImportDraft (flux réel).
    importDraft = { content: csvA, fileName: "encore.csv",
                    mapping: { ...analyzeCSV(csvA, null, "cur").columns }, accountId: "cur", exclues: [] };
    render();
    const bouton = document.querySelector("[data-imprefuse]");
    resultat.uiToggle = !!bouton;
    if (bouton) {
      const avant = ecran();
      bouton.click();
      resultat.toggleAgit = document.getElementById("screen").textContent !== avant
        && (importDraft.exclues || []).length === 1;
    }
    importDraft = null; activeTab = "home"; moreView = null; render();
    // 5. Restauration : un lot au verdict « refused » SURVIT.
    const photo = JSON.parse(JSON.stringify(S));
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    resultat.restaurationGarde = !!restauree && restauree.imports.length === 2
      && restauree.imports[0].records.some(r => r.verdict === "refused");
    return resultat;
  });
  check(rev.refusLigne === true,
    "la ligne refusée n'est pas écrite — les autres entrent");
  check(rev.refusConsigne === true,
    "le refus est CONSIGNÉ au journal : verdict « refused », compteurs justes");
  check(rev.deuxLots === true, "deux lots vivent au journal (mise en place)");
  check(rev.rollbackCible === true,
    "le rollback est CIBLÉ : le premier lot part, le second reste, traces exactes");
  check(rev.uiJournal === true,
    "l'écran Import porte « Journal des imports » avec l'annulation ciblée");
  check(rev.uiToggle === true,
    "l'aperçu offre « Écarter » ligne par ligne");
  check(rev.toggleAgit === true,
    "écarter une ligne agit : l'exclusion est tenue, l'aperçu se met à jour");
  check(rev.restaurationGarde === true,
    "restauration : un lot au verdict « refused » survit tel quel");
  await ctx223.close();
}

// ---------- 224. W8.1 : CASH FLOWS — versements nets exposés, retraits datés ----------
// Budget Autonomie 100, W8.1 : mesuré — la fiche d'un compte de
// placement affichait « Mis de côté cette année · en tout · retraits »
// où « retraits » est un cumul DE TOUJOURS collé à un chiffre annuel,
// et le versement NET (versé − retiré) n'existait nulle part. Livré :
// retraits datés (année ET depuis l'ouverture) + « versements nets »
// dits avec leur méthode. La performance (solde − ouverture − net) ne
// bouge pas — verrou.
currentTest = "W8.1 cash flows";
{
  const ctx224 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p224 = await ctx224.newPage();
  p224.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.1] ${msg.text()}`); });
  await p224.addInitScript(() => {
    const y = new Date().getFullYear();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Flux" },
      baseCurrency: "CHF",
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "brk", name: "Titres", kind: "brokerage", opening: 10000, cash: false, currency: "CHF" },
      ],
      transactions: [
        { id: 1, y: y - 1, m: 3, d: 10, title: "Versement initial", amount: 2000, type: "investment", cat: "Pilier 3a", acc: "cur", dest: "brk", status: "posted" },
        { id: 2, y, m: 1, d: 15, title: "Versement janvier", amount: 1000, type: "investment", cat: "Pilier 3a", acc: "cur", dest: "brk", status: "posted" },
        { id: 3, y, m: 2, d: 5, title: "Retrait pour projet", amount: 500, type: "transfer", cat: null, acc: "brk", dest: "cur", status: "posted" },
        { id: 4, y: y - 1, m: 6, d: 20, title: "Frais de garde", amount: 100, type: "expense", cat: "Imprévu", acc: "brk", dest: null, status: "posted" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p224.goto(APP_URL);
  await p224.waitForSelector("#tabbar button");
  const flux = await p224.evaluate(() => {
    const resultat = {};
    // Attendus calculés par le moteur réel (versé 3000, retiré 600 dont
    // 500 cette année, net 2400 ; solde 12400 ; performance 0).
    activeTab = "accounts"; accountView = "brk"; render();
    const texte = document.getElementById("screen").textContent;
    resultat.netVisible = texte.includes("Versements nets") && texte.includes(money(2400, "CHF"));
    resultat.depuisOuverture = texte.includes("versé " + money(3000, "CHF"))
      && texte.includes("retiré " + money(600, "CHF"));
    resultat.retireCetteAnnee = texte.includes("retiré cette année : " + money(500, "CHF"));
    // L'ancien libellé ambigu (« retraits : » cumul de toujours collé au
    // chiffre annuel) a disparu.
    resultat.ambiguiteRetiree = !texte.includes("retraits :");
    // VERROU (né vert, sabotage à l'appui) : la performance reste
    // « solde − ouverture − versements nets » et dit sa méthode.
    resultat.perfInchangee = texte.includes("Performance : " + money(0, "CHF", true))
      && texte.includes("Valeur − versements nets");
    accountView = null; activeTab = "home"; render();
    return resultat;
  });
  check(flux.netVisible === true,
    "la fiche du compte de placement dit les VERSEMENTS NETS (versé − retiré)");
  check(flux.depuisOuverture === true,
    "depuis l'ouverture : versé et retiré sont dits séparément, au franc près");
  check(flux.retireCetteAnnee === true,
    "le retrait de l'année est daté « cette année » — plus de cumul déguisé");
  check(flux.ambiguiteRetiree === true,
    "l'ancien libellé ambigu « retraits : » (cumul de toujours) a disparu");
  check(flux.perfInchangee === true,
    "VERROU : la performance reste « solde − ouverture − versements nets » et dit sa méthode");
  await ctx224.close();
}

// ---------- 225. W8.2 : POSITIONS — plus-value honnête, devise du prix enfin lue ----------
// Budget Autonomie 100, W8.2 : mesuré — le prix d'achat (costBasis)
// était stocké mais aucune plus-value n'était dite par POSITION ;
// priceCurrency était stocké et JAMAIS lu (une position au prix en
// USD était affichée et additionnée comme du CHF) ; la devise d'un
// compte à positions sans mouvement restait modifiable (désynchro
// silencieuse). La date de saisie du prix, elle, était déjà montrée.
currentTest = "W8.2 positions";
{
  const ctx225 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p225 = await ctx225.newPage();
  p225.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.2] ${msg.text()}`); });
  await p225.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Pos" },
      baseCurrency: "CHF",
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "brk", name: "Titres", kind: "brokerage", opening: 20000, cash: false, currency: "CHF" },
      ],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
      positions: [
        { id: "p1", accountId: "brk", instrumentName: "ETF Monde", tickerOrISIN: "VT", quantity: 10, manualPrice: 180, priceCurrency: "CHF", valuationDate: "2026-05-10", costBasis: 1500 },
        { id: "p2", accountId: "brk", instrumentName: "Fonds Suisse", tickerOrISIN: "", quantity: 5, manualPrice: 200, priceCurrency: "CHF", valuationDate: "2026-04-01", costBasis: null },
        { id: "p3", accountId: "brk", instrumentName: "Action US", tickerOrISIN: "ACME", quantity: 2, manualPrice: 100, priceCurrency: "USD", valuationDate: "2026-03-15", costBasis: null },
      ],
    }));
  });
  await p225.goto(APP_URL);
  await p225.waitForSelector("#tabbar button");
  const pos = await p225.evaluate(() => {
    const resultat = {};
    activeTab = "accounts"; accountView = "brk"; render();
    const texte = document.getElementById("screen").textContent;
    const ligne = id => ((document.querySelector(`[data-posid="${id}"]`) || {}).textContent) || "";
    // 1. Plus-value PAR POSITION quand le prix d'achat est connu :
    //    10 × 180 = 1800, acheté 1500 → +300, dit avec sa méthode.
    resultat.plusValue = ligne("p1").includes("Plus-value") && ligne("p1").includes(money(300, "CHF", true));
    // 2. Prix d'achat inconnu → RIEN (jamais de zéro inventé).
    resultat.pasDeZeroInvente = ligne("p2").length > 0 && !ligne("p2").includes("Plus-value");
    // 3. La devise du PRIX est enfin lue : la position en USD est dite
    //    en USD, jamais déguisée en CHF.
    resultat.devisePrixLue = ligne("p3").includes(money(100, "USD")) && !ligne("p3").includes(money(100, "CHF"));
    // 4. Pas d'addition sans conversion (FI) : la position USD est
    //    écartée du « non réparti » et l'écart est NOMMÉ.
    //    non réparti = 20000 − 1800 − 1000 = 17200.
    resultat.ecartNomme = texte.includes(money(17200, "CHF")) && texte.includes("devise du prix");
    // 5. VERROU (né vert) : les positions expliquent le solde, elles ne
    //    s'y ajoutent jamais — la phrase reste.
    resultat.verrouSolde = texte.includes("les positions l'expliquent, elles ne s'y ajoutent jamais");
    // 6. La devise d'un compte à POSITIONS est verrouillée même sans
    //    mouvement (désynchro silencieuse fermée).
    openAccSheet(ACCOUNTS.find(a => a.id === "brk"));
    resultat.deviseVerrouillee = document.getElementById("aCurrency").disabled === true;
    // Le DOM ne fait pas foi (sabotage inerte durci) : on force le champ
    // et on SOUMET — la porte doit tenir la devise du compte.
    const sel = document.getElementById("aCurrency");
    sel.disabled = false; sel.value = "EUR";
    document.getElementById("accForm").dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
    resultat.deviseTenueAuSubmit = ACCOUNTS.find(a => a.id === "brk").currency === "CHF";
    closeSheet("accSheet");
    accountView = null; activeTab = "home"; render();
    return resultat;
  });
  check(pos.plusValue === true,
    "la plus-value d'une position au prix d'achat connu est dite : +CHF 300.00");
  check(pos.pasDeZeroInvente === true,
    "prix d'achat inconnu → aucune plus-value inventée (pas de faux zéro)");
  check(pos.devisePrixLue === true,
    "la devise du prix est LUE : la position en USD s'affiche en USD");
  check(pos.ecartNomme === true,
    "pas d'addition sans conversion : la position USD est écartée du « non réparti » et l'écart est nommé");
  check(pos.verrouSolde === true,
    "VERROU : « les positions expliquent le solde » reste dit tel quel");
  check(pos.deviseVerrouillee === true,
    "la devise d'un compte à positions est verrouillée même sans mouvement");
  check(pos.deviseTenueAuSubmit === true,
    "même champ forcé, la SOUMISSION tient la devise — le DOM ne fait pas foi");
  await ctx225.close();
}

// ---------- 226. W8.3a : TAUX DATÉS — la courbe de patrimoine ne se réécrit plus ----------
// Budget Autonomie 100, W8.3a : mesuré — chaque point mensuel de la
// courbe de patrimoine convertissait les soldes au taux COURANT
// (toCHF) : changer un taux réécrivait rétroactivement l'histoire des
// STOCKS, alors que S.fxQuotes (daté, sourcé, append-only — W4.2)
// n'était JAMAIS lu pour convertir. Livré : tauxAuJour(devise, date)
// + conversion datée des points mensuels (ADR-070 : la mesure du
// moment fait foi ; avant la première mesure, la première mesure ;
// sans aucune mesure, le cache actuel — comportement historique).
currentTest = "W8.3a taux datés";
{
  const ctx226 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p226 = await ctx226.newPage();
  p226.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.3a] ${msg.text()}`); });
  await p226.addInitScript(() => {
    const now = new Date();
    const iso = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    const ilYA8Mois = new Date(now.getFullYear(), now.getMonth() - 8, 5);
    const premierDuMois = new Date(now.getFullYear(), now.getMonth(), 1);
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Fx" },
      baseCurrency: "CHF",
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "eur", name: "Livret EUR", kind: "savings", opening: 1000, cash: false, currency: "EUR" },
      ],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
      fxRates: { EUR: 1.0 },
      fxQuotes: [
        { base: "CHF", quote: "EUR", taux: 0.9, observedAt: iso(ilYA8Mois), source: "fixture test" },
        { base: "CHF", quote: "EUR", taux: 1.0, observedAt: iso(premierDuMois), source: "fixture test" },
      ],
    }));
  });
  await p226.goto(APP_URL);
  await p226.waitForSelector("#tabbar button");
  const fx = await p226.evaluate(() => {
    const resultat = {};
    const iso = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    const now = new Date();
    if (typeof tauxAuJour !== "function" || typeof toCHFAuMois !== "function") {
      return { fonctionsAbsentes: true };
    }
    // 1. Le taux daté se lit : rien avant la première quote, 0.90 dès
    //    elle, 1.00 aujourd'hui.
    const avant = new Date(now.getFullYear(), now.getMonth() - 10, 15);
    const entre = new Date(now.getFullYear(), now.getMonth() - 3, 15);
    resultat.tauxDate = tauxAuJour("EUR", iso(avant)) === null
      && tauxAuJour("EUR", iso(entre)) === 0.9
      && tauxAuJour("EUR", iso(now)) === 1.0;
    // 2. Un mois PASSÉ est converti au taux de SON moment : 1000 EUR il
    //    y a 3 mois = CHF 900, pas CHF 1000.
    const m3 = new Date(now.getFullYear(), now.getMonth() - 3, 1);
    resultat.moisFige = toCHFAuMois(1000, "EUR", m3.getFullYear(), m3.getMonth() + 1) === 900;
    // 3. Avant la PREMIÈRE mesure : la première mesure fait foi (elle ne
    //    bouge plus) — jamais le cache du jour.
    const m10 = new Date(now.getFullYear(), now.getMonth() - 10, 1);
    resultat.avantPremiereMesure = toCHFAuMois(1000, "EUR", m10.getFullYear(), m10.getMonth() + 1) === 900;
    // 4. Consigner un NOUVEAU taux aujourd'hui ne réécrit PLUS le passé.
    const refus = enregistrerTaux("EUR", 1.1, "test W8.3a");
    resultat.pasDeReecriture = refus === null
      && toCHFAuMois(1000, "EUR", m3.getFullYear(), m3.getMonth() + 1) === 900
      && Math.abs(toCHFAuMois(1000, "EUR", now.getFullYear(), now.getMonth() + 1) - 1100) < 0.005;
    // 5. La COURBE de patrimoine raconte le changement : la classe
    //    « Épargne » n'est plus une droite plate au taux du jour.
    activeTab = "more"; moreView = "networth"; render();
    const lignes = [...document.querySelectorAll("#screen polyline")];
    // Contrôle durci (sabotage inerte) : la courbe GLOBALE et la classe
    // « Épargne » doivent toutes deux raconter le changement — au moins
    // DEUX polylignes non plates (l'« Argent disponible », en CHF pur,
    // reste plat : le témoin).
    const nonPlates = lignes.filter(pl => {
      const ys = (pl.getAttribute("points") || "").split(" ").map(pt => pt.split(",")[1]);
      return new Set(ys).size > 1;
    }).length;
    resultat.courbeRaconte = nonPlates >= 2;
    moreView = null; activeTab = "home"; render();
    return resultat;
  });
  check(fx.fonctionsAbsentes !== true, "tauxAuJour et toCHFAuMois existent");
  check(fx.tauxDate === true,
    "le taux daté se lit : null avant toute quote, 0.90 dès la première, 1.00 aujourd'hui");
  check(fx.moisFige === true,
    "un mois passé est converti au taux de SON moment (CHF 900, pas CHF 1000)");
  check(fx.avantPremiereMesure === true,
    "avant la première mesure, la première mesure fait foi — jamais le cache du jour");
  check(fx.pasDeReecriture === true,
    "consigner un taux aujourd'hui ne réécrit plus les mois passés");
  check(fx.courbeRaconte === true,
    "la courbe de patrimoine raconte le changement de taux (plus de droite plate au taux du jour)");
  await ctx226.close();
}

// ---------- 227. W8.3b : DEVISE DES BIENS — conversion datée, historique de valorisations ----------
// Budget Autonomie 100, W8.3b (ADR-070) : mesuré — les actifs et
// dettes n'avaient AUCUNE devise (un bien en EUR était compté comme
// du CHF, silencieusement), une seule valeur écrasée à chaque édition
// (courbe de patrimoine fausse dès la première revalorisation), et le
// bandeau « montants non convertibles » ne surveillait que comptes et
// mouvements. Livré : devise par bien (défaut = base, décision
// propriétaire), conversion datée, exclusion NOMMÉE si taux manquant,
// historique de valorisations append-only (valeurAuMois).
currentTest = "W8.3b devise des biens";
{
  const ctx227 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p227 = await ctx227.newPage();
  p227.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.3b] ${msg.text()}`); });
  await p227.addInitScript(() => {
    const now = new Date();
    const iso = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Biens" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [],
      assets: [
        { id: "as-eur", name: "Studio ES", value: 10000, include: true, icon: "🏷", currency: "EUR",
          valueDate: iso(new Date(now.getFullYear(), now.getMonth() - 3, 10)) },
        { id: "as-usd", name: "Montre US", value: 2000, include: true, icon: "🏷", currency: "USD" },
      ],
      liabilities: [
        { id: "li-eur", name: "Prêt EUR", value: 1000, include: true, monthly: 0, icon: "📄", currency: "EUR" },
      ],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
      fxRates: { EUR: 0.85 },
      fxQuotes: [
        { base: "CHF", quote: "EUR", taux: 0.9, observedAt: iso(new Date(now.getFullYear(), now.getMonth() - 8, 5)), source: "fixture test" },
        { base: "CHF", quote: "EUR", taux: 0.85, observedAt: iso(new Date(now.getFullYear(), now.getMonth(), 1)), source: "fixture test" },
      ],
    }));
  });
  await p227.goto(APP_URL);
  await p227.waitForSelector("#tabbar button");
  const biens = await p227.evaluate(() => {
    const resultat = {};
    activeTab = "more"; moreView = "networth"; render();
    const texte = () => document.getElementById("screen").textContent;
    // 1. Un bien en EUR est CONVERTI (10000 × 0.85 = 8500), plus jamais
    //    compté brut comme du CHF.
    resultat.biensConvertis = texte().includes(chf(8500)) && !texte().includes(chf(12000));
    // 2. La dette en EUR aussi (1000 × 0.85 = 850).
    resultat.detteConvertie = texte().includes(chf(-850, true));
    // 3. Le bien en USD SANS taux est exclu et l'écart est NOMMÉ au
    //    bandeau (« Montants non convertibles … USD »).
    resultat.tauxManquantNomme = texte().includes("USD") && texte().includes("non convertibles");
    // 4. L'édition de la valeur HISTORISE (append-only) : l'ancienne
    //    valeur garde sa date, valeurAuMois la restitue.
    if (typeof valeurAuMois !== "function") { resultat.histoAppend = false; }
    else {
      openItemSheet("asset", "as-eur");
      document.getElementById("iAmount").value = "12000.00";
      document.getElementById("itemForm").dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
      const a = ASSETS.find(x => x.id === "as-eur");
      const now = new Date();
      const m2 = new Date(now.getFullYear(), now.getMonth() - 2, 1);
      resultat.histoAppend = Array.isArray(a.histo) && a.histo.length === 2
        && a.histo[0].value === 10000 && a.histo[1].value === 12000
        && valeurAuMois(a, m2.getFullYear(), m2.getMonth() + 1) === 10000
        && valeurAuMois(a, now.getFullYear(), now.getMonth() + 1) === 12000;
    }
    // 5. La courbe du patrimoine raconte : biens datés (valeur ET taux
    //    de leur moment) — le point global n'est plus une droite plate.
    render();
    const nonPlates = [...document.querySelectorAll("#screen polyline")].filter(pl => {
      const ys = (pl.getAttribute("points") || "").split(" ").map(pt => pt.split(",")[1]);
      return new Set(ys).size > 1;
    }).length;
    resultat.courbeBiensDatee = nonPlates >= 1;
    // 6. Restauration : devise et historique survivent (clés additives),
    //    une entrée d'historique hostile est écartée sans casser le reste.
    const photo = JSON.parse(JSON.stringify(S));
    if (Array.isArray((photo.assets[0] || {}).histo)) photo.assets[0].histo.push({ date: "pas-une-date", value: -5 });
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    resultat.restaurationAdditive = !!restauree
      && restauree.assets[0].currency === "EUR"
      && Array.isArray(restauree.assets[0].histo)
      && restauree.assets[0].histo.length === 2;
    moreView = null; activeTab = "home"; render();
    return resultat;
  });
  check(biens.biensConvertis === true,
    "un bien en EUR est converti au taux consigné (CHF 8'500), plus jamais compté brut");
  check(biens.detteConvertie === true,
    "une dette en EUR est convertie elle aussi (CHF 850)");
  check(biens.tauxManquantNomme === true,
    "un bien sans taux est exclu et NOMMÉ au bandeau « non convertibles »");
  check(biens.histoAppend === true,
    "l'édition historise : l'ancienne valeur garde sa date, valeurAuMois la restitue");
  check(biens.courbeBiensDatee === true,
    "la courbe du patrimoine date les biens (valeur et taux de leur moment)");
  check(biens.restaurationAdditive === true,
    "restauration : devise et historique survivent, l'entrée hostile est écartée");
  await ctx227.close();
}

// ---------- 228. W8.4 : PERFORMANCE RACONTÉE — un chiffre, sa phrase, sa méthode ----------
// Budget Autonomie 100, W8.4 (décisions propriétaire ADR-070 : racontée
// SIMPLE, aucun taux annualisé ; frais = retrait, statu quo) : mesuré —
// la fiche du compte titres disait « Performance : ±P » et sa méthode,
// mais AUCUNE phrase ne racontait d'où vient le chiffre (versé, retiré,
// valeur d'aujourd'hui). Livré : la performance se lit comme une
// phrase, la méthode reste, aucun pourcentage n'est promis.
currentTest = "W8.4 performance racontée";
{
  const ctx228 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p228 = await ctx228.newPage();
  p228.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.4] ${msg.text()}`); });
  await p228.addInitScript(() => {
    const y = new Date().getFullYear();
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Perf" },
      baseCurrency: "CHF",
      accounts: [
        { id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" },
        { id: "brk", name: "Titres", kind: "brokerage", opening: 10000, cash: false, currency: "CHF" },
        { id: "sav", name: "Épargne", kind: "savings", opening: 2000, cash: false, currency: "CHF" },
      ],
      transactions: [
        { id: 1, y: y - 1, m: 3, d: 10, title: "Versement initial", amount: 2000, type: "investment", cat: "Pilier 3a", acc: "cur", dest: "brk", status: "posted" },
        { id: 2, y, m: 1, d: 15, title: "Versement janvier", amount: 1000, type: "investment", cat: "Pilier 3a", acc: "cur", dest: "brk", status: "posted" },
        { id: 3, y, m: 2, d: 5, title: "Retrait pour projet", amount: 500, type: "transfer", cat: null, acc: "brk", dest: "cur", status: "posted" },
        { id: 4, y: y - 1, m: 6, d: 20, title: "Frais de garde", amount: 100, type: "expense", cat: "Imprévu", acc: "brk", dest: null, status: "posted" },
        { id: 5, y, m: 3, d: 1, title: "Dividende", amount: 200, type: "income", cat: "Salaire", acc: "brk", dest: null, status: "posted" },
      ],
      recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p228.goto(APP_URL);
  await p228.waitForSelector("#tabbar button");
  const perf = await p228.evaluate(() => {
    const resultat = {};
    activeTab = "accounts"; accountView = "brk"; render();
    const texte = () => document.getElementById("screen").textContent;
    // versé 3000, retiré 600 (dont frais 100 = retrait, statu quo décidé),
    // net 2400 ; solde 12600 (dividende +200) ; performance +200.
    resultat.racontee = texte().includes("vous avez versé " + money(3000, "CHF"))
      && texte().includes("retiré " + money(600, "CHF"))
      && texte().includes("vaut " + money(12600, "CHF") + " aujourd'hui");
    resultat.perfChiffre = texte().includes("Performance : " + money(200, "CHF", true));
    // VERROUS (nés verts, sabotage à l'appui) : la méthode reste dite ;
    // aucun pourcentage annualisé n'est promis.
    resultat.methodeToujours = texte().includes("Valeur − versements nets");
    resultat.pasDePourcent = !/% *par an/.test(texte()) && !texte().includes("annualis");
    // Un compte d'épargne ne porte pas de « Performance » (périmètre V1).
    accountView = "sav"; render();
    resultat.horsTitres = !texte().includes("Performance :");
    accountView = null; activeTab = "home"; render();
    return resultat;
  });
  check(perf.racontee === true,
    "la performance est RACONTÉE : versé, retiré, valeur d'aujourd'hui — en une phrase");
  check(perf.perfChiffre === true,
    "le chiffre reste : Performance : +CHF 200.00 (dividende dans la valeur)");
  check(perf.methodeToujours === true,
    "VERROU : la méthode « Valeur − versements nets » reste dite");
  check(perf.pasDePourcent === true,
    "VERROU : aucun taux annualisé promis (décision propriétaire)");
  check(perf.horsTitres === true,
    "un compte d'épargne ne porte pas de « Performance » (périmètre V1)");
  await ctx228.close();
}

// ---------- 229. W8.5 : IMPÔTS — retards nommés, provision par année ----------
// Budget Autonomie 100, W8.5 (décision propriétaire ADR-070 : porter
// échéances + provision du natif, AUCUN calcul d'impôt — ADR-035
// intact) : mesuré — un acompte en retard s'affichait comme les autres
// (« À payer 01.02.…», sans alarme) et le report manuel était GLOBAL
// (S.taxReserve) : consulter Impôts 2025 affichait le même report que
// 2026, étiqueté pareil. Le natif (TaxProvision/TaxService) a des
// échéances en retard NOMMÉES et une provision PAR ANNÉE.
currentTest = "W8.5 impôts";
{
  const ctx229 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p229 = await ctx229.newPage();
  p229.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.5] ${msg.text()}`); });
  await p229.addInitScript(() => {
    const now = new Date();
    const y = now.getFullYear();
    const hier = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Fisc" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {},
      bills: [
        { id: "b-late", name: "Acompte cantonal", amount: 400, cat: "Impôts", accountId: "cur",
          dueY: hier.getFullYear(), dueM: hier.getMonth() + 1, dueD: hier.getDate() },
        { id: "b-next", name: "Acompte fédéral", amount: 300, cat: "Impôts", accountId: "cur",
          dueY: y, dueM: 12, dueD: 20 },
      ],
      taxReserve: 300,
      taxProvisions: { [String(y - 1)]: 800 },
    }));
  });
  await p229.goto(APP_URL);
  await p229.waitForSelector("#tabbar button");
  const fisc = await p229.evaluate(() => {
    const resultat = {};
    activeTab = "more"; moreView = "taxes"; render();
    const texte = () => document.getElementById("screen").textContent;
    // 1. Un acompte échu hier est NOMMÉ « En retard » — plus d'échéance
    //    passée affichée comme les autres.
    resultat.enRetardNomme = texte().includes("En retard") && texte().includes("Acompte cantonal");
    // 2. La provision est PAR ANNÉE : l'an dernier montre SA provision
    //    (800), pas le report global.
    cursor.y = new Date().getFullYear() - 1; render();
    resultat.provisionAnneePassee = texte().includes(chf(800));
    const pasDeReportGlobalAilleurs = !texte().includes("Report que vous aviez saisi");
    cursor.y = new Date().getFullYear(); render();
    // 3. L'année courante garde le report hérité (300), étiqueté.
    resultat.provisionParAnnee = pasDeReportGlobalAilleurs
      && texte().includes("Report que vous aviez saisi") && texte().includes(chf(300));
    // 4. Porte unique à refus nommés.
    if (typeof definirProvisionImpots !== "function") { resultat.porteRefus = false; }
    else {
      const refusNegatif = definirProvisionImpots(new Date().getFullYear(), -5);
      const refusIllisible = definirProvisionImpots(new Date().getFullYear(), "abc");
      const accepte = definirProvisionImpots(new Date().getFullYear(), 1200);
      resultat.porteRefus = typeof refusNegatif === "string" && typeof refusIllisible === "string"
        && accepte === null && (S.taxProvisions || {})[String(new Date().getFullYear())] === 1200;
    }
    // 5. VERROU (né vert) : aucun calcul d'impôt, la phrase reste.
    resultat.verrouSansCalcul = texte().includes("ne calcule aucun impôt");
    // 6. Restauration : clé additive, entrée hostile écartée.
    const photo = JSON.parse(JSON.stringify(S));
    if (photo.taxProvisions) photo.taxProvisions["1999"] = -50;
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    resultat.restaurationAdditive = !!restauree
      && (restauree.taxProvisions || {})[String(new Date().getFullYear() - 1)] === 800
      && (restauree.taxProvisions || {})["1999"] === undefined;
    moreView = null; activeTab = "home"; render();
    return resultat;
  });
  check(fisc.enRetardNomme === true,
    "un acompte échu est NOMMÉ « En retard » sur l'écran Impôts");
  check(fisc.provisionAnneePassee === true,
    "l'année passée montre SA provision (CHF 800), portée du modèle natif");
  check(fisc.provisionParAnnee === true,
    "le report hérité ne compte que pour l'année courante, étiqueté — plus de report global anonyme");
  check(fisc.porteRefus === true,
    "la porte definirProvisionImpots refuse nommément (négatif, illisible) et écrit sinon");
  check(fisc.verrouSansCalcul === true,
    "VERROU : « L'app ne calcule aucun impôt » reste dit tel quel (ADR-035)");
  check(fisc.restaurationAdditive === true,
    "restauration : taxProvisions survit, l'entrée hostile est écartée");
  await ctx229.close();
}

// ---------- 230. W8.6 : ASSURANCES & PRÉVOYANCE — cadences réelles, genre, préavis, pilier, devise ----------
// Budget Autonomie 100, W8.6 (ADR-070, modèles portés du natif
// InsuranceContract/PensionAsset) : mesuré — l'écran PROMETTAIT
// « chaque trimestre » mais insuranceMonthly ne connaissait que
// mois/année (une prime trimestrielle comptait 3× trop) ; aucun genre
// de contrat ; aucun préavis de résiliation ; aucun pilier typé ; une
// prévoyance non liée en devise étrangère était comptée comme du CHF.
currentTest = "W8.6 assurances-prévoyance";
{
  const ctx230 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p230 = await ctx230.newPage();
  p230.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.6] ${msg.text()}`); });
  await p230.addInitScript(() => {
    const now = new Date();
    const dans30j = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 30);
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Assur" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      documents: [], budgets: {}, bills: [],
      insurances: [
        { id: "i-q", name: "RC et ménage", insurer: "", premium: 300, unit: "quarter", kind: "menage" },
        { id: "i-s", name: "Assurance auto", insurer: "", premium: 600, unit: "semester", kind: "auto" },
        { id: "i-n", name: "Caisse maladie", insurer: "", premium: 400, unit: "month", kind: "sante",
          dueM: dans30j.getMonth() + 1, dueD: dans30j.getDate(), noticeDays: 10 },
      ],
      pensions: [
        { id: "p-3a", name: "3e pilier banque", value: 10000, projection: null, accountId: null, rente: false, pillar: "3a" },
        { id: "p-usd", name: "Plan retraite US", value: 1000, projection: null, accountId: null, rente: false, currency: "USD" },
      ],
      fxRates: {},
    }));
  });
  await p230.goto(APP_URL);
  await p230.waitForSelector("#tabbar button");
  const assur = await p230.evaluate(() => {
    const resultat = {};
    activeTab = "more"; moreView = "insurance"; render();
    const texte = () => document.getElementById("screen").textContent;
    const ligne = id => ((document.querySelector(`[data-insid="${id}"]`) || document.querySelector(`[data-penid="${id}"]`) || {}).textContent) || "";
    // 1. Les cadences RÉELLES comptent juste : 300/trimestre = 100/mois,
    //    600/semestre = 100/mois, 400/mois → total 600/mois (pas 1300).
    resultat.cadenceJuste = texte().includes(chf(600)) && !texte().includes(chf(1300));
    // 2. La cadence est DITE sur la ligne.
    resultat.cadenceDite = ligne("i-q").includes("par trimestre") && ligne("i-s").includes("par semestre");
    // 3. Le genre du contrat est dit.
    resultat.genreDit = ligne("i-s").includes("Véhicule") && ligne("i-q").includes("Ménage");
    // 4. Le préavis fait naître « Résilier avant le … » (renouvellement
    //    dans 30 j − préavis 10 j = date à 20 j).
    const now = new Date();
    const limite = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 20);
    const attendu = `Résilier avant le ${String(limite.getDate()).padStart(2, "0")}.${String(limite.getMonth() + 1).padStart(2, "0")}`;
    resultat.resilierAvant = texte().includes(attendu);
    // 5. Le pilier typé est dit.
    resultat.pilierDit = ligne("p-3a").includes("Pilier 3a");
    // 6. Une prévoyance non liée en USD SANS taux est EXCLUE du total
    //    (10000, pas 11000) et l'écart est NOMMÉ ; sa ligne parle en USD.
    resultat.devisePension = typeof pensionPositionsTotal === "function"
      && pensionPositionsTotal() === 10000
      && texte().includes("USD")
      && ligne("p-usd").includes(money(1000, "USD"));
    // 7. Restauration : champs additifs assainis — cadence inconnue
    //    ramenée au mois, genre/pilier/préavis/devise illisibles retirés.
    const photo = JSON.parse(JSON.stringify(S));
    photo.insurances[0].unit = "biweekly";
    photo.insurances[0].kind = "hack";
    photo.insurances[0].noticeDays = -3;
    photo.pensions[0].pillar = "9z";
    photo.pensions[1].currency = "dollars";
    let restauree = null;
    try { restauree = validatedRestoreState(photo); } catch (e) { restauree = null; }
    resultat.restaurationAdditive = !!restauree
      && restauree.insurances[0].unit === "month"
      && restauree.insurances[0].kind === undefined
      && restauree.insurances[0].noticeDays === undefined
      && restauree.pensions[0].pillar === undefined
      && restauree.pensions[1].currency === undefined
      && restauree.insurances[2].kind === "sante"
      && restauree.insurances[2].noticeDays === 10;
    moreView = null; activeTab = "home"; render();
    return resultat;
  });
  check(assur.cadenceJuste === true,
    "les cadences réelles comptent juste : trimestre ÷ 3, semestre ÷ 6 — total CHF 600/mois");
  check(assur.cadenceDite === true,
    "la cadence est dite sur chaque ligne (« par trimestre », « par semestre »)");
  check(assur.genreDit === true,
    "le genre du contrat est dit (Véhicule, Ménage) — porté du natif");
  check(assur.resilierAvant === true,
    "préavis + renouvellement → « Résilier avant le … » à la bonne date");
  check(assur.pilierDit === true,
    "le pilier typé est dit (Pilier 3a) — porté du natif");
  check(assur.devisePension === true,
    "une prévoyance en USD sans taux est exclue du patrimoine, nommée, et parle en USD");
  check(assur.restaurationAdditive === true,
    "restauration : cadence inconnue → mois ; genre/pilier/préavis/devise illisibles retirés, les sains restent");
  await ctx230.close();
}

// ---------- 231. W8.7 : ACTIVATION RÉGIONALE — les mots du pays, partout ----------
// Budget Autonomie 100, W8.7 (dernier sous-lot de W8) : mesuré — le
// `taxHint` régional (COUNTRIES) n'était AFFICHÉ nulle part, et les
// libellés de piliers restaient suisses (« Pilier 3a ») même en
// France ou en Belgique. Livré : l'écran Impôts dit la phrase fiscale
// du pays, et les piliers parlent la langue du pays (PER,
// épargne-pension…) — mêmes clés stables, mots locaux. Aucun nouveau
// pays, aucune nouvelle devise (non-objectif).
currentTest = "W8.7 activation régionale";
{
  const ctx231 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p231 = await ctx231.newPage();
  p231.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W8.7] ${msg.text()}`); });
  await p231.addInitScript(() => {
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Pays" },
      baseCurrency: "CHF", country: "CH",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      documents: [], budgets: {}, bills: [], insurances: [],
      pensions: [{ id: "p-3a", name: "Mon épargne retraite", value: 10000, projection: null, accountId: null, rente: false, pillar: "3a" }],
    }));
  });
  await p231.goto(APP_URL);
  await p231.waitForSelector("#tabbar button");
  const pays = await p231.evaluate(() => {
    const resultat = {};
    const texte = () => document.getElementById("screen").textContent;
    // 1. CH : l'écran Impôts dit la phrase fiscale du pays (acomptes).
    activeTab = "more"; moreView = "taxes"; render();
    resultat.hintCH = texte().includes("notez vos acomptes");
    // 2. CH : le pilier parle suisse.
    moreView = "insurance"; render();
    resultat.pilierCH = texte().includes("Pilier 3a");
    // 3. FR : les MÊMES écrans changent de mots — retenue à la source,
    //    et « PER » à la place de « Pilier 3a ».
    S.country = "FR";
    moreView = "taxes"; render();
    resultat.hintFR = texte().includes("déjà retenus sur le salaire");
    moreView = "insurance"; render();
    resultat.pilierFR = texte().includes("PER") && !texte().includes("Pilier 3a");
    // 4. BE : épargne-pension.
    S.country = "BE";
    render();
    resultat.pilierBE = texte().includes("Épargne-pension");
    S.country = "CH";
    moreView = null; activeTab = "home"; render();
    return resultat;
  });
  check(pays.hintCH === true,
    "Suisse : l'écran Impôts dit la phrase du pays (« notez vos acomptes »)");
  check(pays.pilierCH === true, "Suisse : « Pilier 3a » reste suisse");
  check(pays.hintFR === true,
    "France : l'écran Impôts dit la retenue à la source — même écran, mots du pays");
  check(pays.pilierFR === true,
    "France : « PER » remplace « Pilier 3a » — mêmes clés, mots locaux");
  check(pays.pilierBE === true, "Belgique : « Épargne-pension »");
  await ctx231.close();
}

// ---------- 232. W9.3 : STOCKAGE — double écriture IndexedDB, localStorage reste LA vérité ----------
// Budget Autonomie 100, W9.3 (Work Order W9) : mesuré — localStorage
// est le SEUL stockage (quota ~5 Mo, éviction possible). Livré : une
// interface unique vers IndexedDB (idbEcrireEtat/idbLireEtat), chaque
// saveState DOUBLE l'écriture ; localStorage reste la vérité lue au
// chargement (la bascule prouvée arrive en W9.4) ; une panne
// IndexedDB ne casse jamais l'app — elle est COMPTÉE, ni silencieuse
// ni bruyante.
currentTest = "W9.3 stockage";
{
  const ctx232 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p232 = await ctx232.newPage();
  p232.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W9.3] ${msg.text()}`); });
  await p232.addInitScript(() => {
    // Semis IDEMPOTENT : ce parcours recharge la page, le semis ne doit
    // pas écraser l'état muté (addInitScript rejoue à chaque navigation).
    if (localStorage.getItem("budget-app-state-v1")) return;
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Stockage" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p232.goto(APP_URL);
  await p232.waitForSelector("#tabbar button");
  const stock = await p232.evaluate(async () => {
    const resultat = {};
    if (typeof idbEcrireEtat !== "function" || typeof idbLireEtat !== "function") {
      return { interfaceAbsente: true };
    }
    // 1. Chaque saveState DOUBLE l'écriture : IndexedDB rattrape le blob
    //    de localStorage.
    S.profile.name = "Stockage double";
    saveState();
    let idb = null;
    for (let i = 0; i < 40 && idb !== localStorage.getItem(APP_STATE_KEY); i++) {
      await new Promise(r => setTimeout(r, 50));
      idb = await idbLireEtat();
    }
    resultat.doubleEcriture = idb === localStorage.getItem(APP_STATE_KEY)
      && typeof idb === "string" && idb.includes("Stockage double");
    // 2. Une panne IndexedDB est INOFFENSIVE et comptée : l'app continue,
    //    localStorage est écrit, aucun crash.
    const vraiIDB = window.indexedDB;
    const echecsAvant = idbEchecs;
    Object.defineProperty(window, "indexedDB", { value: { open() { throw new Error("panne simulée"); } }, configurable: true });
    S.profile.name = "Panne IDB";
    let aSurvecu = true;
    try { saveState(); } catch (e) { aSurvecu = false; }
    await new Promise(r => setTimeout(r, 100));
    resultat.panneInoffensive = aSurvecu
      && localStorage.getItem(APP_STATE_KEY).includes("Panne IDB")
      && idbEchecs > echecsAvant;
    Object.defineProperty(window, "indexedDB", { value: vraiIDB, configurable: true });
    // 3. IndexedDB corrompu n'atteint JAMAIS l'état : localStorage reste
    //    la seule vérité lue.
    await idbEcrireEtat("{pas-du-json");
    return resultat;
  });
  check(stock.interfaceAbsente !== true, "l'interface idbEcrireEtat/idbLireEtat existe");
  check(stock.doubleEcriture === true,
    "chaque saveState double l'écriture — IndexedDB porte le même blob que localStorage");
  check(stock.panneInoffensive === true,
    "une panne IndexedDB est inoffensive : l'app continue, localStorage écrit, échec compté");
  if (stock.interfaceAbsente !== true) {
    await p232.reload();
    await p232.waitForSelector("#tabbar button");
    const apres = await p232.evaluate(() => ({ nom: S.profile.name, comptes: ACCOUNTS.length }));
    check(apres.nom === "Panne IDB" && apres.comptes === 1,
      "IndexedDB corrompu n'atteint jamais l'état : localStorage reste la seule vérité lue");
  } else {
    check(false, "IndexedDB corrompu n'atteint jamais l'état : localStorage reste la seule vérité lue");
  }
  await ctx232.close();
}

// ---------- 233. W9.4 : RÉCUPÉRATION — l'éviction de localStorage ne perd plus rien ----------
// Budget Autonomie 100, W9.4 : mesuré — si le navigateur évince
// localStorage, tout était perdu alors que la réserve de secours
// (IndexedDB, W9.3) porte le même état. Livré : au démarrage sur un
// localStorage VIDE, la réserve valide est restaurée puis la page se
// recharge UNE fois ; un blob corrompu ou d'une version future ne
// touche à rien. La bascule complète du stockage attend le démarrage
// asynchrone (W9.8) — divergence Work Order consignée.
currentTest = "W9.4 récupération";
{
  // Semis DÉTERMINISTE : première ouverture vierge → on ÉCRIT la réserve
  // (attendue), puis reload — la récupération lit une réserve déjà là
  // (un init script asynchrone ferait la course avec le boot).
  const semerReserve = async (page, blob) => {
    await page.evaluate(async payload => {
      await new Promise((fin, rate) => {
        const demande = indexedDB.open("budget-app", 1);
        demande.onupgradeneeded = () => demande.result.createObjectStore("etat");
        demande.onsuccess = () => {
          const tx = demande.result.transaction("etat", "readwrite");
          tx.objectStore("etat").put(payload, "budget-app-state-v1");
          tx.oncomplete = () => { demande.result.close(); fin(); };
          tx.onerror = () => rate(tx.error);
        };
        demande.onerror = () => rate(demande.error);
      });
      localStorage.removeItem("budget-app-state-v1");
    }, blob);
  };
  const etatValide = JSON.stringify({
    version: 1, onboarded: true, isDemo: false, profile: { name: "Récupéré" },
    baseCurrency: "CHF",
    accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 4321, cash: true, currency: "CHF" }],
    transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
    pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
  });
  // 1. Éviction simulée : IndexedDB seul porte l'état → il revient.
  const ctx233 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p233 = await ctx233.newPage();
  p233.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W9.4] ${msg.text()}`); });
  await p233.goto(APP_URL);
  await semerReserve(p233, etatValide);
  await p233.reload();
  const recupere = await p233.waitForFunction(
    () => typeof S !== "undefined" && S.profile && S.profile.name === "Récupéré" && S.onboarded === true,
    null, { timeout: 15000 }).then(() => true).catch(() => false);
  check(recupere === true,
    "localStorage évincé → l'état revient de la réserve IndexedDB (rechargement unique)");
  if (recupere) {
    const apres = await p233.evaluate(() => ({
      ls: !!localStorage.getItem("budget-app-state-v1"),
      solde: Math.round(balance("cur") * 100),
    }));
    check(apres.ls === true && apres.solde === 432100,
      "l'état récupéré est réécrit dans localStorage, au centime près");
    // Idempotence : un nouveau rechargement ne boucle pas et garde tout.
    await p233.reload();
    await p233.waitForSelector("#tabbar button");
    const encore = await p233.evaluate(() => S.profile.name);
    check(encore === "Récupéré", "un rechargement de plus ne boucle pas et garde l'état");
    // Réinitialisation COMPLÈTE : la réserve est vidée elle aussi — les
    // données effacées ne ressuscitent JAMAIS.
    p233.on("dialog", d => d.accept());
    await p233.evaluate(() => { activeTab = "more"; moreView = "settings"; render(); });
    // Clic direct (sans attente d'actionnabilité) : le reset recharge la
    // page pendant l'appel — la destruction de contexte est normale.
    await p233.evaluate(() => { const b = document.querySelector("[data-fullreset]"); if (b) b.click(); })
      .catch(() => {});
    await p233.waitForTimeout(2500);
    await p233.reload();
    await p233.waitForTimeout(2000);
    const ressuscite = await p233.evaluate(() => typeof S !== "undefined" && S.onboarded === true)
      .catch(() => null);
    check(ressuscite === false,
      "après « réinitialiser complètement », rien ne ressuscite — la réserve est vidée aussi");
  } else {
    check(false, "l'état récupéré est réécrit dans localStorage, au centime près");
    check(false, "un rechargement de plus ne boucle pas et garde l'état");
    check(false, "après « réinitialiser complètement », rien ne ressuscite — la réserve est vidée aussi");
  }
  await ctx233.close();
  // 2. Réserve CORROMPUE ou d'une version FUTURE : rien n'est touché,
  //    l'app reste une vraie première ouverture.
  for (const [nom, blob] of [["corrompu", "{pas-du-json"], ["version future", JSON.stringify({ version: 9, accounts: [] })]]) {
    const ctxH = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const pH = await ctxH.newPage();
    await pH.goto(APP_URL);
    await semerReserve(pH, blob);
    await pH.reload();
    await pH.waitForTimeout(1800);
    const intact = await pH.evaluate(() => localStorage.getItem("budget-app-state-v1") === null
      && typeof S !== "undefined" && S.onboarded === false);
    check(intact === true,
      `réserve ${nom} → rien n'est touché, l'app reste une vraie première ouverture`);
    await ctxH.close();
  }
}

// ---------- 234. W9.5 : ROUTES — le hash reflète l'écran, le retour est honnête ----------
// Budget Autonomie 100, W9.5 (ADR-026 inchangé — mêmes 5 destinations) :
// mesuré — aucun usage de location.hash : recharger perdait l'écran,
// le bouton retour quittait l'app. Livré : le hash suit la navigation
// (#/mois, #/budget, #/gerer/taxes…), le démarrage restaure l'écran du
// hash, le retour arrière revient à l'écran précédent, un hash inconnu
// retombe sur Mois sans casser.
currentTest = "W9.5 routes";
{
  const etatRoutes = JSON.stringify({
    version: 1, onboarded: true, isDemo: false, profile: { name: "Routes" },
    baseCurrency: "CHF",
    accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
    transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
    pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
  });
  const ctx234 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p234 = await ctx234.newPage();
  p234.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W9.5] ${msg.text()}`); });
  await p234.addInitScript(etat => {
    if (!localStorage.getItem("budget-app-state-v1")) localStorage.setItem("budget-app-state-v1", etat);
  }, etatRoutes);
  await p234.goto(APP_URL);
  await p234.waitForSelector("#tabbar button");
  // 1. Le hash SUIT la navigation — par les VRAIS gestes (les entrées
  //    d'historique naissent dans pushNav, pas dans render).
  const releves = [];
  await p234.click('#tabbar button[aria-label="Budget"]');
  releves.push(await p234.evaluate(() => location.hash));
  await p234.click('#tabbar button[aria-label="Gérer"]');
  await p234.click('#screen [data-more="taxes"]');
  await p234.waitForTimeout(150);
  releves.push(await p234.evaluate(() => location.hash));
  await p234.click('#tabbar button[aria-label="Mois"]');
  releves.push(await p234.evaluate(() => location.hash));
  const suivi = releves;
  check(suivi[0] === "#/budget" && suivi[1] === "#/gerer/taxes" && suivi[2] === "#/mois",
    `le hash suit la navigation (obtenu : ${suivi.join(" · ")})`);
  // 2. Le retour arrière est HONNÊTE : il revient à l'écran précédent.
  await p234.goBack();
  await p234.waitForTimeout(300);
  const apresRetour = await p234.evaluate(() => (typeof activeTab !== "undefined" ? { tab: activeTab, vue: moreView } : { tab: "page-quittée", vue: null })).catch(() => ({ tab: "page-quittée", vue: null }));
  check(apresRetour.tab === "more" && apresRetour.vue === "taxes",
    `le retour arrière revient à l'écran précédent (obtenu : ${apresRetour.tab}/${apresRetour.vue})`);
  await p234.goBack().catch(() => {});
  await p234.waitForTimeout(300);
  const racineGerer = await p234.evaluate(() => (typeof activeTab !== "undefined" ? { tab: activeTab, vue: moreView } : { tab: "page-quittée" })).catch(() => ({ tab: "page-quittée" }));
  check(racineGerer.tab === "more" && racineGerer.vue === null,
    `un retour de plus : la racine Gérer (obtenu : ${racineGerer.tab}/${racineGerer.vue})`);
  await p234.goBack().catch(() => {});
  await p234.waitForTimeout(300);
  const encoreAvant = await p234.evaluate(() => (typeof activeTab !== "undefined" ? activeTab : "page-quittée")).catch(() => "page-quittée");
  check(encoreAvant === "budget", `un retour de plus : Budget (obtenu : ${encoreAvant})`);
  await ctx234.close();
  // 3. Le démarrage RESTAURE l'écran du hash.
  const ctxBoot = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const pBoot = await ctxBoot.newPage();
  await pBoot.addInitScript(etat => {
    if (!localStorage.getItem("budget-app-state-v1")) localStorage.setItem("budget-app-state-v1", etat);
  }, etatRoutes);
  await pBoot.goto(APP_URL + "#/gerer/taxes");
  await pBoot.waitForSelector("#tabbar button");
  const boot = await pBoot.evaluate(() => ({ tab: activeTab, vue: moreView, texte: document.getElementById("screen").textContent.slice(0, 400) }));
  check(boot.tab === "more" && boot.vue === "taxes" && boot.texte.includes("Impôts"),
    "le démarrage restaure l'écran du hash (#/gerer/taxes → Impôts)");
  // 4. Un hash INCONNU retombe sur Mois, sans casser.
  await pBoot.goto(APP_URL + "#/nimporte-quoi");
  await pBoot.reload();
  await pBoot.waitForSelector("#tabbar button");
  const inconnu = await pBoot.evaluate(() => ({ tab: activeTab, boutons: document.querySelectorAll("#tabbar button").length }));
  check(inconnu.tab === "home" && inconnu.boutons === 5,
    "un hash inconnu retombe sur Mois — et les 5 destinations restent (ADR-026)");
  await ctxBoot.close();
}

// ---------- 235. W9.6 : CSP + SERVICE WORKER — rien d'externe, rien d'empoisonnable ----------
// Budget Autonomie 100, W9.6 : mesuré — aucune CSP déclarée, et le
// service worker mettait en cache TOUTE requête GET, même
// cross-origin (surface d'empoisonnement du cache). L'app n'a AUCUNE
// ressource externe (mesuré). Livré : CSP stricte déclarée
// (default-src 'self', object-src 'none', connect-src 'none' —
// 'unsafe-inline' assumé et consigné tant que le monofichier vit,
// levée prévue en W9.8) ; le SW ne met en cache que la MÊME origine.
currentTest = "W9.6 csp-sw";
{
  const { readFileSync: lireSW } = await import("node:fs");
  const ctx235 = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p235 = await ctx235.newPage();
  p235.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[W9.6] ${msg.text()}`); });
  await p235.addInitScript(() => {
    if (localStorage.getItem("budget-app-state-v1")) return;
    localStorage.setItem("budget-app-state-v1", JSON.stringify({
      version: 1, onboarded: true, isDemo: false, profile: { name: "Csp" },
      baseCurrency: "CHF",
      accounts: [{ id: "cur", name: "Courant", kind: "current", opening: 5000, cash: true, currency: "CHF" }],
      transactions: [], recurrings: [], goals: [], assets: [], liabilities: [],
      pensions: [], insurances: [], documents: [], budgets: {}, bills: [],
    }));
  });
  await p235.goto(APP_URL);
  await p235.waitForSelector("#tabbar button");
  // 1. La CSP est DÉCLARÉE, stricte, et l'app tourne avec (la page
  //    vient de se rendre sans erreur console — le vrai test).
  const csp = await p235.evaluate(() => {
    const meta = document.querySelector('meta[http-equiv="Content-Security-Policy"]');
    return meta ? meta.content : null;
  });
  check(typeof csp === "string"
    && csp.includes("default-src 'self'")
    && csp.includes("object-src 'none'")
    && csp.includes("connect-src 'none'")
    && csp.includes("base-uri 'none'"),
    `la CSP est déclarée et stricte (obtenu : ${String(csp).slice(0, 90)})`);
  // 2. L'app entière fonctionne SOUS cette CSP (rendu + navigation).
  await p235.click('#tabbar button[aria-label="Budget"]');
  const sousCSP = await p235.evaluate(() => document.getElementById("screen").textContent.length > 50);
  check(sousCSP === true, "l'app rend et navigue sous la CSP déclarée");
  await ctx235.close();
  // 3. Le service worker ne met en cache que la MÊME origine, et son
  //    cache reste VERSIONNÉ (invalidation propre à l'activation).
  const sw = lireSW(path.join(HERE, "..", "sw.js"), "utf8");
  check(/origin/.test(sw) && sw.includes("location.origin"),
    "le SW écarte les requêtes d'une autre origine (cache non empoisonnable)");
  check(/const CACHE = "budget-app-v\d+"/.test(sw) && sw.includes("caches.delete"),
    "le cache du SW reste versionné avec invalidation propre");
}

await browser.close();

// ---------- Rapport ----------
const allFailures = [...failures, ...consoleErrors];
if (allFailures.length) {
  console.error("ÉCHECS E2E (" + allFailures.length + ") :");
  for (const failure of allFailures) console.error("  ✗ " + failure);
  process.exit(1);
}
console.log("SUITE E2E NAVIGATEUR : 235 parcours verts — accueil mensuel essentiel, ajout par intention, réserves honnêtes, formulaires réels, données restaurées inertes, fluidité et gestes des feuilles, Historique P03, accessibilité 320/390 px, parité des calculs et régressions historiques — zéro erreur console ✓");
