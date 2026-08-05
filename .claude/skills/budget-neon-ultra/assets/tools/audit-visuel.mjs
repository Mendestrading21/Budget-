// AUDIT VISUEL REPRODUCTIBLE des 16 écrans de la PWA (5 onglets + 11 vues).
// Cherche mécaniquement les défauts qu'un œil rate : pastille d'icône non
// carrée ou non dimensionnée, débordement horizontal, cible sous 44 px,
// texte réellement tronqué. Écrit aussi une capture par écran.
// Données 100 % FICTIVES et déterministes (foyer « Alex », jeu de démo).
//
// Usage :
//   W=390 OUT=/dossier BUDGET_CHROMIUM=/chemin/vers/chrome \
//     node .claude/skills/budget-neon-ultra/assets/tools/audit-visuel.mjs
import path from "node:path";
import { fileURLToPath } from "node:url";
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const OUT = process.env.OUT || path.join(ROOT, "docs/neon-ultra/audit-visuel");
import fs from "node:fs"; fs.mkdirSync(OUT, { recursive: true });
const { chromium } = await import(path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));
const browser = await chromium.launch({ executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"] });
const W = Number(process.env.W || 390);
const page = await (await browser.newContext({ viewport: { width: W, height: 844 } })).newPage();
const errs = [];
page.on("pageerror", e => errs.push("PAGEERROR: " + e.message));
page.on("console", m => { if (m.type() === "error") errs.push("CONSOLE: " + m.text()); });
page.on("dialog", d => d.accept());
await page.goto("file://" + path.join(ROOT, "webapp/index.html"));
await page.waitForSelector('[data-obcountry="CH"]');
await page.click('[data-obcountry="CH"]'); await page.click('[data-obhh="solo"]');
await page.fill("#obName", "Alex"); await page.click('#obForm1 button[type="submit"]');
await page.fill("#obSalary", "5200"); await page.click('#obForm2 button[type="submit"]');
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "3400"); await page.click('#obForm3 button[type="submit"]');
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button");
await page.click('#tabbar button[aria-label="Gérer"]'); await page.waitForTimeout(250);
await page.click('#screen [data-more="settings"]'); await page.waitForTimeout(250);
await page.click("[data-resetdemo]"); await page.waitForSelector("#tabbar button");
await page.waitForTimeout(6500);

const audit = () => page.evaluate(() => {
  const vu = e => {
    if (e.getAttribute("aria-hidden") === "true" || e.tabIndex < 0) return false;
    const b = e.getBoundingClientRect();
    return b.width > 0 && b.height > 0;
  };
  const s = document.getElementById("screen");
  // Une pastille d'icône doit être CARRÉE, dimensionnée et centrée.
  const icones = [...s.querySelectorAll(".ico")].map(e => {
    const b = e.getBoundingClientRect(); const cs = getComputedStyle(e);
    return {
      cls: e.className,
      w: Math.round(b.width), h: Math.round(b.height),
      centre: cs.display === "grid" ? cs.placeItems || cs.alignItems : cs.display,
      fond: cs.backgroundColor,
      txt: (e.textContent || "").trim().slice(0, 3),
    };
  }).filter(i => i.w > 0);
  const mauvaises = icones.filter(i =>
    Math.abs(i.w - i.h) > 2 || i.h < 24 || (i.fond !== "rgba(0, 0, 0, 0)" && !/center/.test(i.centre)));
  return {
    icones: icones.length,
    iconesMauvaises: mauvaises,
    debordement: s.scrollWidth - s.clientWidth,
    petitesCibles: [...s.querySelectorAll('button,a,select,input,textarea,summary,[role="button"]')]
      .filter(e => vu(e) && Math.round(e.getBoundingClientRect().height) < 44)
      .map(e => (e.id || e.className || e.tagName) + "«" + (e.textContent || "").trim().slice(0, 20) + "»"),
    tronques: [...s.querySelectorAll(".meta .t, .card-label, .section-title, h2, h3")]
      .filter(e => e.scrollWidth > e.clientWidth + 1 && getComputedStyle(e).textOverflow === "ellipsis")
      .map(e => (e.textContent || "").trim().slice(0, 30)),
  };
});

const ECRANS = [
  ["mois", async () => { await page.click('#tabbar button[aria-label="Mois"]'); }],
  ["historique", async () => { await page.click('#tabbar button[aria-label="Historique"]'); }],
  ["budget", async () => { await page.click('#tabbar button[aria-label="Budget"]'); }],
  ["comptes", async () => { await page.click('#tabbar button[aria-label="Comptes"]'); }],
  ["gerer", async () => { await page.click('#tabbar button[aria-label="Gérer"]'); }],
];
const SOUS = ["year", "subs", "bills", "recurring", "goals", "taxes", "networth", "insurance", "settings", "importcsv", "assistant"];

for (const [nom, aller] of ECRANS) {
  await aller(); await page.waitForTimeout(400);
  const r = await audit();
  const pb = [];
  if (r.iconesMauvaises.length) pb.push("ICÔNES " + JSON.stringify(r.iconesMauvaises));
  if (r.debordement > 1) pb.push("DÉBORD " + r.debordement);
  if (r.petitesCibles.length) pb.push("CIBLES<44 " + JSON.stringify(r.petitesCibles));
  if (r.tronques.length) pb.push("TRONQUÉ " + JSON.stringify(r.tronques));
  console.log(`${pb.length ? "✗" : "✓"} ${nom}  (${r.icones} icônes)  ${pb.join(" | ")}`);
  await page.screenshot({ path: `${OUT}/${W}-${nom}.png`, fullPage: false });
}
for (const vue of SOUS) {
  await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
  await page.waitForTimeout(400);
  const r = await audit();
  const pb = [];
  if (r.iconesMauvaises.length) pb.push("ICÔNES " + JSON.stringify(r.iconesMauvaises));
  if (r.debordement > 1) pb.push("DÉBORD " + r.debordement);
  if (r.petitesCibles.length) pb.push("CIBLES<44 " + JSON.stringify(r.petitesCibles));
  if (r.tronques.length) pb.push("TRONQUÉ " + JSON.stringify(r.tronques));
  console.log(`${pb.length ? "✗" : "✓"} ${vue}  (${r.icones} icônes)  ${pb.join(" | ")}`);
  await page.screenshot({ path: `${OUT}/${W}-${vue}.png`, fullPage: false });
}
console.log(errs.length ? "ERREURS CONSOLE : " + errs.join(" | ") : "console propre");
await browser.close();
process.exit(0);
