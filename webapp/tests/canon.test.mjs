// W1.6 — Runner Web des fixtures canoniques (ADR-059).
// Chaque fixture de fixtures/canon/ est convertie en état d'app, semée
// dans localStorage AVANT le chargement, puis le moteur RÉEL est appelé
// en page (balance / snapshot / fortuneTotale) et comparé aux attendus,
// EN UNITÉS MINEURES ENTIÈRES, champ par champ — jamais une comparaison
// de texte formaté. Le runner Swift (CanonicalFixtureTests) lit les
// MÊMES fichiers : c'est la gate de parité FI-40.
import { chromium } from "playwright-core";
import { fileURLToPath } from "node:url";
import { readFileSync, readdirSync } from "node:fs";
import path from "node:path";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APP_URL = "file://" + path.resolve(HERE, "..", "index.html");
const CANON_DIR = path.resolve(HERE, "..", "..", "fixtures", "canon");
const CHROMIUM = process.env.BUDGET_CHROMIUM
  || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";

const failures = [];
const fichiers = readdirSync(CANON_DIR).filter(n => n.endsWith(".json")).sort();

// Fixture canonique → état d'app PWA. Montants : unités mineures → francs.
function etatDepuisFixture(f) {
  const e = f.entrees;
  const francs = c => c / 100;
  const [y0, m0, d0] = [0, 0, 0];
  const parseDate = iso => ({ y: +iso.slice(0, 4), m: +iso.slice(5, 7), d: +iso.slice(8, 10) });
  // W8.3c : les taux de la fixture deviennent des quotes DATÉES et
  // sourcées (comme le runner Swift depuis W4.2b) ; le cache dérivé
  // fxRates reflète la DERNIÈRE quote par devise (par date d'observation,
  // pas par ordre du fichier).
  const fxQuotes = (e.taux || []).filter(t => t.cote === e.deviseBase).map(t => ({
    base: e.deviseBase, quote: t.base, taux: Number(t.taux), observedAt: t.date, source: t.source,
  }));
  const fxRates = {};
  for (const q of [...fxQuotes].sort((a, b) => (a.observedAt < b.observedAt ? -1 : 1))) {
    fxRates[q.quote] = q.taux;
  }
  let seq = 9000;
  return {
    version: 1, onboarded: true, isDemo: false, profile: { name: "Canon" },
    baseCurrency: e.deviseBase,
    ...(Object.keys(fxRates).length ? { fxRates } : {}),
    ...(fxQuotes.length ? { fxQuotes } : {}),
    accounts: (e.comptes || []).map(c => ({
      id: c.id, name: c.nom, kind: c.genre, opening: francs(c.ouvertureMineures),
      cash: c.cash, currency: c.devise,
      ...(c.patrimoine === false ? { netWorth: false } : {}),
    })),
    transactions: (e.mouvements || []).map(m => {
      const dt = parseDate(m.date);
      return {
        id: ++seq, y: dt.y, m: dt.m, d: dt.d, type: m.type, status: m.statut,
        amount: francs(m.montantMineures), cat: m.categorie || null,
        title: m.titre, acc: m.compte, dest: m.destination || null,
        ...(m.type === "adjustment" ? { up: m.hausse } : {}),
        ...(m.recurrence ? { recurringId: m.recurrence } : {}),
      };
    }),
    recurrings: (e.recurrences || []).map(r => ({
      id: r.id, title: r.titre, amount: francs(r.montantMineures), type: r.type,
      nature: r.nature || "facture", cat: "Autre", day: r.jour, every: r.rythme,
      accountId: r.compte, icon: "🧾",
    })),
    goals: [], assets: [], liabilities: [], pensions: [],
    insurances: [], bills: [], documents: [], budgets: {},
  };
}

const browser = await chromium.launch({ executablePath: CHROMIUM, args: ["--no-sandbox"] });
const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
const page = await context.newPage();
const consoleErrors = [];
page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(msg.text()); });
page.on("pageerror", err => consoleErrors.push("pageerror: " + err.message));

for (const nom of fichiers) {
  const fixture = JSON.parse(readFileSync(path.join(CANON_DIR, nom), "utf8"));
  const attendus = fixture.attendus || {};
  await page.addInitScript(payload => {
    localStorage.setItem("budget-app-state-v1", payload);
  }, JSON.stringify(etatDepuisFixture(fixture)));
  await page.goto(APP_URL);
  await page.waitForFunction(() => typeof snapshot === "function", null, { timeout: 10000 }).catch(() => {});

  const mois = attendus.mois || null;
  const obtenu = await page.evaluate(({ mois }) => {
    const versMineures = v => Math.round(v * 100);
    const sortie = { soldes: {}, mois: null, patrimoine: null };
    for (const a of ACCOUNTS) sortie.soldes[a.id] = versMineures(balance(a.id));
    if (mois) {
      const s = snapshot(mois.annee, mois.mois);
      sortie.mois = {
        recuMineures: versMineures(s.income),
        depenseMineures: versMineures(s.living),
        misDeCoteMineures: versMineures(s.savings + s.invest),
        liquideMineures: versMineures(s.liquid),
        finDeMoisMineures: versMineures(s.endOfMonthForecast),
        resultatMineures: versMineures(s.cashFlow),
      };
    }
    const sNow = snapshot(NOW.y, NOW.m);
    sortie.patrimoine = {
      fortuneTotaleMineures: versMineures(fortuneTotale()),
      epargneAccessibleMineures: versMineures(sNow.savingsAccessible),
    };
    // W8.3c : les quotes DATÉES de la fixture doivent être semées telles
    // quelles (date + source) — le runner Swift le fait depuis W4.2b, le
    // runner web ne peut pas prouver FI-16 en aplatissant les dates.
    sortie.quotesSemees = (S.fxQuotes || []).length;
    return sortie;
  }, { mois });

  const tauxFournis = ((fixture.entrees || {}).taux || []).length;
  if (obtenu.quotesSemees !== tauxFournis) {
    failures.push(`[${fixture.nom}] quotes datées semées : ${obtenu.quotesSemees} ≠ ${tauxFournis} taux fournis — le runner aplatit les dates (FI-16 non prouvé)`);
  }

  for (const [cid, attendu] of Object.entries(attendus.soldesMineures || {})) {
    if (obtenu.soldes[cid] !== attendu) {
      failures.push(`[${fixture.nom}] solde ${cid} : attendu ${attendu}, obtenu ${obtenu.soldes[cid]}`);
    }
  }
  if (mois) {
    for (const champ of ["recuMineures", "depenseMineures", "misDeCoteMineures", "liquideMineures", "finDeMoisMineures", "resultatMineures"]) {
      if (mois[champ] !== undefined && obtenu.mois[champ] !== mois[champ]) {
        failures.push(`[${fixture.nom}] mois.${champ} : attendu ${mois[champ]}, obtenu ${obtenu.mois[champ]}`);
      }
    }
  }
  for (const champ of ["fortuneTotaleMineures", "epargneAccessibleMineures"]) {
    const attendu = (attendus.patrimoine || {})[champ];
    if (attendu !== undefined && obtenu.patrimoine[champ] !== attendu) {
      failures.push(`[${fixture.nom}] patrimoine.${champ} : attendu ${attendu}, obtenu ${obtenu.patrimoine[champ]}`);
    }
  }

  await page.evaluate(() => localStorage.clear());
}
await browser.close();

const allFailures = [...failures, ...consoleErrors];
if (allFailures.length) {
  console.error("ÉCHECS RUNNER CANON WEB (" + allFailures.length + ") :");
  for (const f of allFailures) console.error("  ✗ " + f);
  process.exit(1);
}
console.log(`RUNNER CANON WEB : ${fichiers.length} fixtures exécutées par le moteur réel — soldes, mois, patrimoine identiques aux attendus, en unités mineures entières, zéro erreur console ✓`);
