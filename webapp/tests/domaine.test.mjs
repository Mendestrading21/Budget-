// W9.2 — Domaine extrait en MIROIR VÉRIFIÉ (Budget Autonomie 100).
// Mesuré : les tests e2e chargent l'app en file:// où les modules ES
// sont bloqués (CORS) — l'extraction ne peut donc pas être branchée
// dans la page avant le bundling de W9.8. Le contrat de ce lot : la
// SOURCE DE VÉRITÉ typée vit dans webapp/src/domaine/, et CE
// comparateur prouve à chaque CI que le miroir TypeScript et le
// monofichier produisent EXACTEMENT les mêmes sorties — toute dérive
// de l'un ou de l'autre est un échec nommé.
import { execFileSync } from "node:child_process";
import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";
import { chromium } from "playwright-core";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const WEBAPP = path.resolve(HERE, "..");
const BUILD = path.join(WEBAPP, "build", "build.mjs");
const APP_URL = "file://" + path.join(WEBAPP, "index.html");
const CHROMIUM = process.env.BUDGET_CHROMIUM
  || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";

const failures = [];
const check = (ok, msg) => { if (!ok) failures.push(msg); };

for (const f of ["domaine/monnaie.ts", "domaine/taux.ts"]) {
  if (!existsSync(path.join(WEBAPP, "src", f))) failures.push(`webapp/src/${f} absent — pas de source de vérité typée`);
}

let sortie = null;
if (!failures.length) {
  // 1. Transpiler le domaine (build --emit) puis l'importer côté Node.
  const out = mkdtempSync(path.join(tmpdir(), "domaine-"));
  try {
    try { execFileSync("node", [BUILD, "--emit", out], { encoding: "utf8" }); }
    catch (e) { failures.push("build --emit indisponible ou en échec : " + String(e.stdout || e.message).slice(0, 200)); }
    let monnaie = null, taux = null;
    if (!failures.length) {
      try {
        monnaie = await import(pathToFileURL(path.join(out, "domaine", "monnaie.js")).href);
        taux = await import(pathToFileURL(path.join(out, "domaine", "taux.js")).href);
      } catch (e) { failures.push("import du domaine transpilé impossible : " + String(e.message).slice(0, 200)); }
    }

    if (monnaie && taux) {
      // 2. Les MÊMES entrées passées aux deux implémentations.
      const montants = [0, 0.005, 0.1, 0.2, 0.30000000000000004, 1, 12.345, 745.6, 2150, 99999.99, 123456.78, -45.5, -0.005];
      const quotes = [
        { base: "CHF", quote: "EUR", taux: 0.9, observedAt: "2026-01-05", source: "t" },
        { base: "CHF", quote: "EUR", taux: 0.85, observedAt: "2026-08-01", source: "t" },
        { base: "CHF", quote: "USD", taux: 0.8, observedAt: "2026-03-15", source: "t" },
        { base: "EUR", quote: "USD", taux: 0.86, observedAt: "2026-02-02", source: "t" },
      ];
      const dates = ["2025-12-31", "2026-01-05", "2026-02-28", "2026-07-31", "2026-08-31", "2026-12-31"];
      const casTaux = [];
      for (const devise of ["EUR", "USD", "GBP", "CHF"]) for (const date of dates) casTaux.push({ devise, date });
      const casStock = [
        { montant: 1000, devise: "EUR", y: 2026, m: 2, cache: { EUR: 0.85 } },
        { montant: 1000, devise: "EUR", y: 2025, m: 10, cache: { EUR: 0.85 } },
        { montant: 1000, devise: "GBP", y: 2026, m: 5, cache: { GBP: 1.1 } },
        { montant: 1000, devise: "GBP", y: 2026, m: 5, cache: {} },
        { montant: 500, devise: "CHF", y: 2026, m: 5, cache: {} },
      ];

      const browser = await chromium.launch({ executablePath: CHROMIUM, args: ["--no-sandbox"] });
      const page = await (await browser.newContext()).newPage();
      await page.goto(APP_URL);
      await page.waitForFunction(() => typeof toCents === "function", null, { timeout: 10000 });
      const enPage = await page.evaluate(({ montants, quotes, casTaux, casStock }) => {
        S.baseCurrency = "CHF";
        S.fxQuotes = quotes;
        const stock = casStock.map(c => {
          S.fxRates = c.cache;
          return toCHFAuMois(c.montant, c.devise, c.y, c.m);
        });
        return {
          cents: montants.map(toCents),
          francs: montants.map(m => fromCents(Math.round(m * 100))),
          arrondis: montants.map(round2),
          taux: casTaux.map(c => tauxAuJour(c.devise, c.date)),
          stock,
        };
      }, { montants, quotes, casTaux, casStock });
      await browser.close();

      const enTS = {
        cents: montants.map(monnaie.toCents),
        francs: montants.map(m => monnaie.fromCents(Math.round(m * 100))),
        arrondis: montants.map(monnaie.round2),
        taux: casTaux.map(c => taux.tauxAuJour(quotes, "CHF", c.devise, c.date)),
        stock: casStock.map(c => taux.montantStockEnBase(quotes, c.cache, "CHF", c.montant, c.devise, c.y, c.m)),
      };

      for (const cle of ["cents", "francs", "arrondis", "taux", "stock"]) {
        const a = JSON.stringify(enPage[cle]);
        const b = JSON.stringify(enTS[cle]);
        check(a === b, `dérive du miroir « ${cle} » : page ${a.slice(0, 120)} ≠ TS ${b.slice(0, 120)}`);
      }
      sortie = true;
    }
  } finally {
    rmSync(out, { recursive: true, force: true });
  }
}

if (failures.length) {
  console.error("ÉCHECS DOMAINE (" + failures.length + ") :");
  for (const f of failures) console.error("  ✗ " + f);
  process.exit(1);
}
console.log("DOMAINE W9.2 : miroir TypeScript ≡ monofichier — monnaie (centimes, francs, arrondis) et taux datés identiques sur toutes les entrées, dérive impossible sans échec nommé ✓");
