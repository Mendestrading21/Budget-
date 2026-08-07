// AUDIT TOTAL de la PWA — cherche mécaniquement ce qu'un œil humain rate
// après trois heures : incohérences d'alignement, d'espacement, de taille,
// de rayon, de couleur, contrastes réels, cibles tactiles, boutons morts.
//
// Il ne juge PAS le goût. Il compte, mesure et compare — et ne signale que
// ce qui est mesurablement incohérent avec le reste de l'app.
//
// Données 100 % FICTIVES et déterministes (foyer « Alex », jeu de démo).
//
// Usage :
//   W=390 BUDGET_CHROMIUM=/chemin/vers/chrome \
//     node .claude/skills/budget-neon-ultra/assets/tools/audit-total.mjs
import path from "node:path";
import { fileURLToPath } from "node:url";
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));
const W = Number(process.env.W || 390);
const browser = await chromium.launch({ executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"] });
const page = await (await browser.newContext({ viewport: { width: W, height: 844 } })).newPage();
const erreurs = [];
page.on("pageerror", e => erreurs.push("PAGEERROR: " + e.message));
page.on("console", m => { if (m.type() === "error") erreurs.push("CONSOLE: " + m.text()); });
page.on("dialog", d => d.accept());

await page.goto("file://" + path.join(ROOT, "webapp/index.html"));
await page.waitForSelector('[data-obcountry="CH"]');
await page.click('[data-obcountry="CH"]'); await page.click('[data-obhh="solo"]');
await page.fill("#obName", "Alex"); await page.click('#obForm1 button[type="submit"]');
await page.fill("#obSalary", "5200"); await page.click('#obForm2 button[type="submit"]');
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "3400"); await page.click('#obForm3 button[type="submit"]');
// Charges puis abonnements : deux écrans facultatifs, passés ici.
await page.waitForSelector("#obFormCharges", { state: "visible" });
await page.click("[data-obskipcharges]");
await page.waitForSelector("#obFormSubs", { state: "visible" });
await page.click("[data-obskipsubs]");
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button");
await page.click('#tabbar button[aria-label="Gérer"]'); await page.waitForTimeout(250);
await page.click('#screen [data-more="settings"]'); await page.waitForTimeout(250);
await page.click("[data-resetdemo]"); await page.waitForSelector("#tabbar button");
await page.waitForTimeout(6500);

// Fonctions de mesure injectées une fois, réutilisées par écran.
await page.addInitScript(() => {});
const mesurer = () => page.evaluate(() => {
  const s = document.getElementById("screen");
  const vu = e => {
    const b = e.getBoundingClientRect();
    return b.width > 0 && b.height > 0 && e.getAttribute("aria-hidden") !== "true";
  };
  const lum = c => {
    const m = c.match(/[\d.]+/g); if (!m) return null;
    const [r, g, b, a] = m.map(Number);
    if (a === 0) return null;
    const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  };
  // Fond EFFECTIF : on remonte jusqu'au premier ancêtre opaque.
  const fondEffectif = e => {
    let n = e;
    while (n && n !== document.documentElement) {
      const bg = getComputedStyle(n).backgroundColor;
      const m = bg.match(/[\d.]+/g);
      if (m && (m.length < 4 || Number(m[3]) >= 0.95)) return bg;
      n = n.parentElement;
    }
    return getComputedStyle(document.body).backgroundColor;
  };
  const contraste = (t, f) => {
    const a = lum(t), b = lum(f);
    if (a === null || b === null) return null;
    return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
  };

  // Les cartes d'un carrousel horizontal sont posées CÔTE À CÔTE : leurs
  // bords gauches diffèrent par construction, sinon il n'y aurait pas de
  // carrousel. Les exclure de la mesure d'alignement, et elles seules —
  // un outil qui crie au loup est pire qu'aucun outil.
  const cartes = [...s.querySelectorAll(".card")].filter(c => vu(c) && !c.closest(".hero-track"));
  const textes = [...s.querySelectorAll("*")].filter(e =>
    vu(e) && e.children.length === 0 && (e.textContent || "").trim().length > 1);

  return {
    // ---- Alignement : le bord GAUCHE du contenu doit être unique.
    bordsGauches: [...new Set(cartes.map(c => Math.round(c.getBoundingClientRect().left)))],
    bordsDroits: [...new Set(cartes.map(c => Math.round(c.getBoundingClientRect().right)))],
    // ---- Géométrie : rayons et paddings des cartes.
    rayons: [...new Set(cartes.map(c => getComputedStyle(c).borderRadius))],
    paddings: [...new Set(cartes.map(c => getComputedStyle(c).padding))],
    // ---- Typographie : combien de tailles distinctes ?
    tailles: [...new Set(textes.map(e => getComputedStyle(e).fontSize))]
      .map(v => parseFloat(v)).sort((a, b) => a - b),
    // ---- Contraste réel de chaque texte sur son fond effectif.
    contrastesFaibles: textes.map(e => {
      const cs = getComputedStyle(e);
      const px = parseFloat(cs.fontSize);
      const gras = Number(cs.fontWeight) >= 700;
      const seuil = (px >= 24 || (px >= 18.66 && gras)) ? 3 : 4.5;
      const r = contraste(cs.color, fondEffectif(e));
      return r !== null && r < seuil
        ? { txt: (e.textContent || "").trim().slice(0, 34), px, ratio: +r.toFixed(2), seuil }
        : null;
    }).filter(Boolean),
    // ---- Cibles tactiles réellement interactives.
    petitesCibles: [...s.querySelectorAll('button,a,select,input,textarea,summary,[role="button"]')]
      .filter(e => vu(e) && e.getBoundingClientRect().height < 44)
      .map(e => ({ t: (e.textContent || e.getAttribute("aria-label") || e.tagName).trim().slice(0, 26),
                   h: Math.round(e.getBoundingClientRect().height) })),
    // ---- Contrôles sans destination : ni handler inline, ni attribut data-*
    //      reconnu, ni type=submit. Un bouton mort est pire qu'un absent.
    boutonsSansDestination: [...s.querySelectorAll("button")]
      .filter(e => vu(e) && e.type !== "submit" && !e.disabled)
      .filter(e => ![...e.attributes].some(a => /^data-/.test(a.name)) && !e.id && !e.onclick)
      .map(e => (e.textContent || "").trim().slice(0, 30)),
    // ---- Débordement horizontal.
    debordement: s.scrollWidth - s.clientWidth,
    // ---- Titres : un écran = un h2. Deux h2 = deux promesses.
    titres: [...s.querySelectorAll("h2")].filter(vu).map(e => (e.textContent || "").trim().slice(0, 30)),
  };
});

const ECRANS = [
  ["mois", 'activeTab="home";moreView=null'],
  ["historique", 'activeTab="movements";moreView=null'],
  ["budget", 'activeTab="budget";moreView=null'],
  ["comptes", 'activeTab="accounts";moreView=null'],
  ["gerer", 'activeTab="more";moreView=null'],
];
const VUES = ["year", "subs", "bills", "recurring", "goals", "taxes",
              "networth", "insurance", "settings", "importcsv", "assistant"];

// Les trois seuls rayons de l'app (ADR-024). Toute autre valeur signale
// une carte qui a échappé au système.
const RAYONS_AUTORISES = ["26px", "18px", "14px"];

const global = { tailles: new Set(), rayons: new Set(), paddings: new Set(), bords: new Set() };
let problemes = 0;

const rapporter = (nom, r) => {
  const pb = [];
  if (r.debordement > 1) pb.push(`DÉBORD ${r.debordement}px`);
  if (r.bordsGauches.length > 1) pb.push(`BORDS GAUCHES ${JSON.stringify(r.bordsGauches)}`);
  if (r.bordsDroits.length > 1) pb.push(`BORDS DROITS ${JSON.stringify(r.bordsDroits)}`);
  // Trois rayons, c'est le SYSTÈME (héros 26, carte 18, ligne 14) — pas un
  // défaut. Ce qui en est un, c'est une quatrième valeur venue d'ailleurs.
  const horsSysteme = r.rayons.filter(v => !RAYONS_AUTORISES.includes(v));
  if (horsSysteme.length) pb.push(`RAYON HORS SYSTÈME ${JSON.stringify(horsSysteme)} (autorisés ${RAYONS_AUTORISES.join(", ")})`);
  if (r.contrastesFaibles.length) pb.push(`CONTRASTE ${JSON.stringify(r.contrastesFaibles)}`);
  if (r.petitesCibles.length) pb.push(`CIBLES<44 ${JSON.stringify(r.petitesCibles)}`);
  if (r.boutonsSansDestination.length) pb.push(`BOUTON MORT ? ${JSON.stringify(r.boutonsSansDestination)}`);
  if (r.titres.length > 1) pb.push(`${r.titres.length} TITRES ${JSON.stringify(r.titres)}`);
  r.tailles.forEach(t => global.tailles.add(t));
  r.rayons.forEach(t => global.rayons.add(t));
  r.paddings.forEach(t => global.paddings.add(t));
  r.bordsGauches.forEach(t => global.bords.add(t));
  if (pb.length) problemes++;
  console.log(`${pb.length ? "✗" : "✓"} ${nom.padEnd(12)} ${pb.join("\n               ")}`);
};

for (const [nom, code] of ECRANS) {
  await page.evaluate(c => { eval(c); render(); }, code);
  await page.waitForTimeout(320);
  rapporter(nom, await mesurer());
}
for (const vue of VUES) {
  await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
  await page.waitForTimeout(320);
  rapporter(vue, await mesurer());
}

console.log(`\n— INVENTAIRE GLOBAL (${W} px) —`);
console.log(`tailles de texte  : ${[...global.tailles].sort((a, b) => a - b).join(", ")}`);
console.log(`rayons de carte   : ${[...global.rayons].join(" | ")}`);
console.log(`paddings de carte : ${[...global.paddings].join(" | ")}`);
console.log(`bords gauches     : ${[...global.bords].sort((a, b) => a - b).join(", ")}`);
console.log(erreurs.length ? "ERREURS CONSOLE : " + erreurs.join(" | ") : "console propre");
console.log(problemes ? `\n${problemes} écran(s) à corriger` : "\nAucun écran en défaut");
await browser.close();
process.exit(0);
