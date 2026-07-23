// Suite design system Obsidian Glass (L2).
// Exécution : node webapp/tests/design.test.mjs
// Vérifie : tokens canoniques et leur parité index.html ↔ obsidian.css,
// contrastes WCAG AA mesurés, galerie sans débordement à 320/390 px,
// cibles ≥ 44 px, focus clavier visible, reduced motion, fallback opaque
// en transparence réduite, zéro erreur console.
import { chromium } from "playwright-core";
import { fileURLToPath } from "node:url";
import fs from "node:fs";
import path from "node:path";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APP_URL = "file://" + path.resolve(HERE, "..", "index.html");
const GALLERY_URL = "file://" + path.resolve(HERE, "..", "design-system", "obsidian-gallery.html");
const CHROMIUM =
  process.env.BUDGET_CHROMIUM
  || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";

const failures = [];
let currentTest = "boot";
function check(condition, message) {
  if (!condition) failures.push(`[${currentTest}] ${message}`);
}

// ---------- D1 : tokens canoniques — index.html ↔ obsidian.css ----------
currentTest = "tokens canoniques";
const CANONICAL = {
  "--canvas": "#090C12",
  "--canvas-raised": "#0D1119",
  "--glass": "rgba(20, 25, 37, 0.72)",
  "--glass-strong": "rgba(27, 34, 48, 0.88)",
  "--glass-fallback": "#151B26",
  "--stroke": "rgba(255, 255, 255, 0.10)",
  "--stroke-active": "rgba(115, 103, 255, 0.48)",
  "--brand": "#7367FF",
  "--brand-bright": "#9188FF",
  "--text-primary": "#F6F7FB",
  "--text-secondary": "#A7B0C0",
  "--text-tertiary": "#758094",
  "--positive": "#36D399",
  "--negative": "#FF6B7A",
  "--warning": "#FFB454",
};
const indexSrc = fs.readFileSync(path.resolve(HERE, "..", "index.html"), "utf8");
const cssSrc = fs.readFileSync(path.resolve(HERE, "..", "design-system", "obsidian.css"), "utf8");
for (const [name, value] of Object.entries(CANONICAL)) {
  const re = new RegExp(name.replace(/[-]/g, "\\-") + "\\s*:\\s*([^;]+);");
  for (const [label, src] of [["index.html", indexSrc], ["obsidian.css", cssSrc]]) {
    const m = src.match(re);
    check(m, `${label} doit déclarer ${name}`);
    if (m) check(m[1].trim() === value,
      `${label} : ${name} doit valoir « ${value} » (obtenu « ${m[1].trim()} »)`);
  }
}
// Aucune ancienne palette active : les teintes héritées (teal, cyan, violet,
// bleu électrique, thème clair) ne doivent plus exister en valeur brute.
const BANNED = ["#4B5CFF", "#5AA7FF", "#8B5CF6", "#55DDE0", "#2DD4BF", "#0D9488",
  "#2563EB", "#7C3AED", "#4338CA", "#07090e", "#F4F6FB", "#0B8A57", "#D23B55",
  "#39D98A", "#FF667A", "#FFB24D", "#A96A10", 'data-theme="dark"]'];
for (const banned of BANNED) {
  check(!indexSrc.includes(banned), `index.html ne doit plus contenir « ${banned} »`);
  check(!cssSrc.includes(banned), `obsidian.css ne doit plus contenir « ${banned} »`);
}
// Les alias hérités doivent pointer vers les tokens Obsidian.
for (const [alias, target] of [
  ["--electric", "var(--brand-bright)"], ["--violet", "var(--brand-bright)"],
  ["--teal", "var(--brand-bright)"], ["--indigo", "var(--brand)"],
  ["--offwhite", "var(--text-primary)"], ["--coolgray", "var(--text-secondary)"],
  ["--amber", "var(--warning)"], ["--bg", "var(--canvas)"],
]) {
  const m = indexSrc.match(new RegExp(alias.replace(/[-]/g, "\\-") + "\\s*:\\s*([^;]+);"));
  check(m && m[1].trim() === target,
    `index.html : l'alias ${alias} doit pointer vers ${target} (obtenu « ${m ? m[1].trim() : "absent"} »)`);
}

// ---------- D2 : contrastes WCAG mesurés ----------
currentTest = "contrastes";
function srgbToLinear(c) { return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
function luminance(hex) {
  const n = hex.replace("#", "");
  const r = parseInt(n.slice(0, 2), 16) / 255;
  const g = parseInt(n.slice(2, 4), 16) / 255;
  const b = parseInt(n.slice(4, 6), 16) / 255;
  return 0.2126 * srgbToLinear(r) + 0.7152 * srgbToLinear(g) + 0.0722 * srgbToLinear(b);
}
function contrast(fg, bg) {
  const [l1, l2] = [luminance(fg), luminance(bg)].sort((a, b) => b - a);
  return (l1 + 0.05) / (l2 + 0.05);
}
// Verre standard composité sur le fond : rgba(20,25,37,0.72) sur #090C12.
function composite(rgba, alpha, base) {
  const b = base.replace("#", "");
  const mix = (c, i) => Math.round(alpha * c + (1 - alpha) * parseInt(b.slice(i * 2, i * 2 + 2), 16));
  return "#" + [mix(20, 0), mix(25, 1), mix(37, 2)].map(v => v.toString(16).padStart(2, "0")).join("");
}
const GLASS_ON_CANVAS = composite([20, 25, 37], 0.72, "#090C12");
const CHECKS = [
  ["texte primaire / canvas", "#F6F7FB", "#090C12", 7],
  ["texte primaire / verre", "#F6F7FB", GLASS_ON_CANVAS, 7],
  ["texte primaire / fallback opaque", "#F6F7FB", "#151B26", 7],
  ["texte secondaire / verre", "#A7B0C0", GLASS_ON_CANVAS, 4.5],
  ["texte tertiaire / verre", "#758094", GLASS_ON_CANVAS, 4.5],
  ["brand (lien) / canvas", "#7367FF", "#090C12", 4.5],
  ["brand-bright (lien, focus) / canvas", "#9188FF", "#090C12", 4.5],
  ["blanc / bouton primaire (brand-deep)", "#FFFFFF", "#6457F0", 4.5],
  ["positive / canvas", "#36D399", "#090C12", 4.5],
  ["negative / canvas", "#FF6B7A", "#090C12", 4.5],
  ["warning / canvas", "#FFB454", "#090C12", 4.5],
];
const measured = [];
for (const [label, fg, bg, min] of CHECKS) {
  const ratio = contrast(fg, bg);
  measured.push(`${label} : ${ratio.toFixed(2)}:1 (exigé ≥ ${min})`);
  check(ratio >= min, `contraste insuffisant — ${label} : ${ratio.toFixed(2)} < ${min}`);
}

// ---------- D3 : galerie dans un vrai navigateur ----------
const browser = await chromium.launch({ executablePath: CHROMIUM, args: ["--no-sandbox"] });
const consoleErrors = [];
async function newPage(width) {
  const context = await browser.newContext({ viewport: { width, height: 844 } });
  const page = await context.newPage();
  page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[${currentTest}] ${msg.text()}`); });
  page.on("pageerror", err => consoleErrors.push(`[${currentTest}] pageerror: ${err.message}`));
  return page;
}

for (const width of [320, 390]) {
  currentTest = `galerie ${width}px`;
  const page = await newPage(width);
  await page.goto(GALLERY_URL);
  await page.waitForSelector("#swatches .swatch");
  // Aucun débordement horizontal.
  const overflow = await page.evaluate(() =>
    document.documentElement.scrollWidth - document.documentElement.clientWidth);
  check(overflow <= 0, `débordement horizontal de ${overflow}px`);
  // Le montant très long reste entier (pas de coupe de ligne dans le nombre).
  const longAmount = await page.evaluate(() => {
    const nodes = [...document.querySelectorAll(".os-amount, .os-amount-hero")];
    const el = nodes.find(n => n.textContent.includes("9'999'999.99"));
    return el ? { found: true, clipped: el.scrollWidth > el.clientWidth + 1 && getComputedStyle(el).overflow === "hidden" } : { found: false };
  });
  check(longAmount.found, "le montant CHF -9'999'999.99 doit être présenté");
  check(!longAmount.clipped, "le montant très long ne doit pas être tronqué");
  // Chiffres tabulaires sur les montants.
  const numeric = await page.$eval(".os-amount-hero", el => getComputedStyle(el).fontVariantNumeric);
  check(numeric.includes("tabular-nums"), `chiffres tabulaires requis (obtenu ${numeric})`);
  // Cibles interactives ≥ 44 px.
  const smallTargets = await page.evaluate(() =>
    [...document.querySelectorAll("button, input, [role='button']")]
      .filter(el => el.offsetParent !== null)
      .map(el => ({ h: el.getBoundingClientRect().height, label: (el.textContent || el.id || "?").trim().slice(0, 30) }))
      .filter(t => t.h < 43.5));
  check(smallTargets.length === 0,
    `cibles < 44px : ${smallTargets.map(t => `${t.label} (${t.h.toFixed(0)}px)`).join(", ")}`);
  await page.context().close();
}

// ---------- D4 : focus clavier visible ----------
currentTest = "focus clavier";
{
  const page = await newPage(390);
  await page.goto(GALLERY_URL);
  await page.waitForSelector("#focusDemo");
  await page.focus("#focusDemo");
  await page.keyboard.press("Tab"); // navigation clavier réelle
  const focusInfo = await page.evaluate(() => {
    const el = document.activeElement;
    el.blur(); el.focus(); // focus programmatique…
    const btn = document.getElementById("focusDemo");
    btn.focus();
    // :focus-visible est appliqué au clavier ; on force la pseudo-classe en
    // vérifiant la règle calculée après un Tab réel plus bas.
    return { tag: el.tagName };
  });
  check(["BUTTON", "INPUT"].includes(focusInfo.tag), "le Tab doit atteindre un élément interactif");
  // Un vrai parcours clavier : le premier Tab depuis le body doit produire
  // un anneau de focus visible (outline non nul).
  await page.evaluate(() => document.activeElement.blur());
  await page.keyboard.press("Tab");
  const outline = await page.evaluate(() => {
    const el = document.activeElement;
    const cs = getComputedStyle(el);
    return { width: cs.outlineWidth, style: cs.outlineStyle };
  });
  check(outline.style !== "none" && parseFloat(outline.width) >= 2,
    `focus-visible doit produire un anneau ≥ 2px (obtenu ${outline.style} ${outline.width})`);
  await page.context().close();
}

// ---------- D5 : transparence réduite = fallback OPAQUE ----------
currentTest = "transparence reduite";
{
  const page = await newPage(390);
  await page.goto(GALLERY_URL);
  await page.waitForSelector("#toggleTransparency");
  const before = await page.$eval(".os-card--strong", el => getComputedStyle(el).backgroundColor);
  check(before.includes("0.88") || before.startsWith("rgba"), `le verre fort doit être translucide par défaut (obtenu ${before})`);
  await page.click("#toggleTransparency");
  const after = await page.evaluate(() => ({
    strong: getComputedStyle(document.querySelector(".os-card--strong")).backgroundColor,
    std: getComputedStyle(document.querySelector(".os-card:not(.os-card--strong)")).backgroundColor,
    blur: getComputedStyle(document.querySelector(".os-sheet")).backdropFilter,
  }));
  // #151B26 = rgb(21, 27, 38)
  check(after.strong === "rgb(21, 27, 38)", `verre fort → glassFallback opaque attendu (obtenu ${after.strong})`);
  check(after.std === "rgb(21, 27, 38)", `verre standard → glassFallback opaque attendu (obtenu ${after.std})`);
  check(after.blur === "none", `le blur doit disparaître en transparence réduite (obtenu ${after.blur})`);
  await page.context().close();
}
// Le même mécanisme s'applique à l'APP elle-même.
{
  const page = await newPage(390);
  await page.goto(APP_URL);
  await page.waitForSelector("#phone", { state: "attached" });
  await page.evaluate(() => { document.documentElement.dataset.reducedTransparency = "true"; });
  const surface = await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--surface").trim());
  check(surface === "#151B26", `l'app doit basculer --surface sur glassFallback (obtenu ${surface})`);
  await page.context().close();
}

// ---------- D6 : reduced motion — aucune animation non essentielle ----------
currentTest = "reduced motion";
{
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    reducedMotion: "reduce",
  });
  const page = await context.newPage();
  page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[${currentTest}] ${msg.text()}`); });
  await page.goto(GALLERY_URL);
  await page.waitForSelector(".os-btn");
  const anim = await page.$eval(".os-btn", el => getComputedStyle(el).transitionDuration);
  check(anim === "0s" || parseFloat(anim) <= 0.011,
    `reduced motion doit neutraliser les transitions des boutons (obtenu ${anim})`);
  await context.close();
}

// ---------- D7 : texte agrandi sans débordement ----------
currentTest = "texte agrandi 320px";
{
  const page = await newPage(320);
  await page.goto(GALLERY_URL);
  await page.waitForSelector("#toggleLargeText");
  await page.click("#toggleLargeText");
  const overflow = await page.evaluate(() =>
    document.documentElement.scrollWidth - document.documentElement.clientWidth);
  check(overflow <= 0, `débordement horizontal en texte agrandi : ${overflow}px`);
  await page.context().close();
}

await browser.close();

// ---------- Bilan ----------
if (consoleErrors.length) {
  failures.push(...consoleErrors.map(e => `console: ${e}`));
}
console.log("Contrastes mesurés :");
for (const line of measured) console.log("  " + line);
if (failures.length) {
  console.error(`\n✗ ${failures.length} échec(s) design system :`);
  for (const f of failures) console.error("  - " + f);
  process.exit(1);
}
console.log("\n✓ Design system Obsidian : tokens, parité, contrastes, galerie 320/390, cibles 44px, focus, reduced motion/transparency — OK, zéro erreur console");
