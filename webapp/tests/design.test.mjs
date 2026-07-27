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

// ============================================================
// Section NU (NU1) — fondations Neon Ultra ISOLÉES (ADR-024).
// Additive : ne modifie ni n'affaiblit AUCUN contrôle Obsidian
// ci-dessus. Le tableau BANNED continue d'interdire les couleurs
// Neon Ultra dans index.html et obsidian.css tant que NU2 n'a
// pas commencé ; la vérification Neon Ultra est SÉPARÉE et
// limitée à neon-ultra.css / neon-ultra-gallery.html.
// ============================================================

// ---------- NU1 : tokens canoniques Neon Ultra ----------
currentTest = "NU tokens canoniques";
const NU_CSS_PATH = path.resolve(HERE, "..", "design-system", "neon-ultra.css");
const NU_GALLERY_PATH = path.resolve(HERE, "..", "design-system", "neon-ultra-gallery.html");
const NU_GALLERY_URL = "file://" + NU_GALLERY_PATH;
const nuCss = fs.readFileSync(NU_CSS_PATH, "utf8");
const nuGallery = fs.readFileSync(NU_GALLERY_PATH, "utf8");
const NU_CANONICAL = {
  "--nu-canvas": "#05060A",
  "--nu-navigation": "#0B0D13",
  "--nu-surface": "#11141C",
  "--nu-surface-elevated": "#181C26",
  "--nu-surface-fallback": "#151923",
  "--nu-border": "#293040",
  "--nu-magenta": "#D946EF",
  "--nu-violet": "#7C3AED",
  "--nu-cyan": "#38BDF8",
  "--nu-cta-start": "#C000A4",
  "--nu-cta-end": "#6E00E8",
  "--nu-text-primary": "#F5F7FA",
  "--nu-text-secondary": "#A3ACBA",
  "--nu-text-tertiary": "#7C8696",
  "--nu-text-on-cta": "#FFFFFF",
  "--nu-positive": "#35D39A",
  "--nu-negative": "#FF6577",
  "--nu-warning": "#F6C453",
};
for (const [name, value] of Object.entries(NU_CANONICAL)) {
  const m = nuCss.match(new RegExp(name.replace(/[-]/g, "\\-") + "\\s*:\\s*([^;]+);"));
  check(m, `neon-ultra.css doit déclarer ${name}`);
  if (m) check(m[1].trim() === value,
    `neon-ultra.css : ${name} doit valoir « ${value} » (obtenu « ${m[1].trim()} »)`);
}
check(nuCss.includes("linear-gradient(135deg, var(--nu-cta-start) 0%, var(--nu-cta-end) 100%)"),
  "le dégradé CTA doit être exactement 135deg, cta-start 0% → cta-end 100%");

// ---------- NU2 : ISOLATION — l'app publique ne connaît pas Neon Ultra ----------
currentTest = "NU isolation";
check(!indexSrc.includes("--nu-"), "index.html ne doit contenir AUCUNE variable --nu-");
check(!indexSrc.includes("neon-ultra"), "index.html ne doit pas référencer neon-ultra.css");
check(!cssSrc.includes("--nu-"), "obsidian.css ne doit contenir AUCUNE variable --nu-");
check(nuGallery.includes('href="neon-ultra.css"') && !nuGallery.includes("obsidian.css"),
  "la galerie Neon Ultra ne charge QUE neon-ultra.css");
// Aucun hex brut hors du bloc :root dans les RÈGLES (les primitives
// référencent les rôles ; les commentaires documentaires sont ignorés).
{
  const rootEnd = nuCss.indexOf("}", nuCss.indexOf(":root"));
  const afterRoot = nuCss.slice(rootEnd).replace(/\/\*[\s\S]*?\*\//g, "");
  const rawHex = afterRoot.match(/#[0-9A-Fa-f]{3,8}\b/g) || [];
  check(rawHex.length === 0,
    `aucun hex brut hors :root dans les règles de neon-ultra.css (trouvé : ${rawHex.join(", ")})`);
}

// ---------- NU3 : parité des rôles avec DesignTokens.swift ----------
currentTest = "NU parité Swift";
const swiftSrc = fs.readFileSync(
  path.resolve(HERE, "..", "..", "Budget", "Core", "DesignSystem", "DesignTokens.swift"), "utf8");
const nuSwiftBlock = swiftSrc.slice(swiftSrc.indexOf("enum NeonUltraColor"));
const SWIFT_ROLES = {
  canvas: "--nu-canvas", navigation: "--nu-navigation", surface: "--nu-surface",
  surfaceElevated: "--nu-surface-elevated", surfaceFallback: "--nu-surface-fallback",
  border: "--nu-border", magenta: "--nu-magenta", violet: "--nu-violet", cyan: "--nu-cyan",
  ctaStart: "--nu-cta-start", ctaEnd: "--nu-cta-end", textPrimary: "--nu-text-primary",
  textSecondary: "--nu-text-secondary", textTertiary: "--nu-text-tertiary",
  textOnCta: "--nu-text-on-cta",
  positive: "--nu-positive", negative: "--nu-negative", warning: "--nu-warning",
};
const hexToRgb = hex => [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16));
for (const [swiftName, cssVar] of Object.entries(SWIFT_ROLES)) {
  const m = nuSwiftBlock.match(new RegExp(
    `static let ${swiftName} = rgb\\((\\d+), (\\d+), (\\d+)\\)`));
  check(m, `DesignTokens.swift doit déclarer NeonUltraColor.${swiftName}`);
  if (m) {
    const expected = hexToRgb(NU_CANONICAL[cssVar]);
    const got = [Number(m[1]), Number(m[2]), Number(m[3])];
    check(got.join(",") === expected.join(","),
      `parité ${swiftName} ↔ ${cssVar} : Swift rgb(${got}) ≠ CSS ${NU_CANONICAL[cssVar]}`);
  }
}
// Parité géométrie et mouvement.
for (const [swiftDecl, cssDecl] of [
  ["static let hero: CGFloat = 26", "--nu-radius-hero: 26px"],
  ["static let card: CGFloat = 18", "--nu-radius-card: 18px"],
  ["static let control: CGFloat = 14", "--nu-radius-control: 14px"],
  ["static let press: Double = 0.14", "--nu-motion-press: 140ms"],
  ["static let state: Double = 0.24", "--nu-motion-state: 240ms"],
]) {
  check(swiftSrc.includes(swiftDecl), `DesignTokens.swift doit déclarer « ${swiftDecl} »`);
  check(nuCss.includes(cssDecl), `neon-ultra.css doit déclarer « ${cssDecl} »`);
}
check(nuSwiftBlock.includes("pressScale: CGFloat = 0.98") && nuCss.includes("scale(0.98)"),
  "la pression 0,98 doit être identique sur les deux plateformes");

// ---------- NU4 : contrastes Neon Ultra mesurés (jamais estimés) ----------
currentTest = "NU contrastes";
const NU_SURFACES = {
  canvas: "#05060A", navigation: "#0B0D13", "surface standard": "#11141C",
  "surface élevée": "#181C26", "fallback opaque": "#151923",
};
const NU_TEXTS = {
  textPrimary: "#F5F7FA", textSecondary: "#A3ACBA", textTertiary: "#7C8696",
};
// Minimums contractuels du texte discret (clôture NU0, re-mesurés).
const NU_TERTIARY_MIN = {
  canvas: 5.50, navigation: 5.28, "surface standard": 5.00,
  "surface élevée": 4.63, "fallback opaque": 4.78,
};
const nuMeasured = [];
for (const [textName, textHex] of Object.entries(NU_TEXTS)) {
  for (const [surfName, surfHex] of Object.entries(NU_SURFACES)) {
    const ratio = contrast(textHex, surfHex);
    nuMeasured.push(`NU ${textName} / ${surfName} : ${ratio.toFixed(2)}:1`);
    check(ratio >= 4.5,
      `NU contraste insuffisant — ${textName} / ${surfName} : ${ratio.toFixed(2)} < 4.5`);
    if (textName === "textTertiary") {
      const min = NU_TERTIARY_MIN[surfName];
      check(ratio >= min - 0.02,
        `NU textTertiary / ${surfName} : ${ratio.toFixed(2)} < minimum contractuel ${min}`);
    }
  }
}
// CTA : le texte BLANC PUR reste AA sur les DEUX extrémités du dégradé
// (mesures contractuelles ≈ 5,56 et 7,43).
for (const [end, hex, floor] of [["cta-start", "#C000A4", 5.3], ["cta-end", "#6E00E8", 7.2]]) {
  const ratio = contrast("#FFFFFF", hex);
  nuMeasured.push(`NU textOnCta (blanc) / ${end} : ${ratio.toFixed(2)}:1`);
  check(ratio >= 4.5, `NU CTA ${end} : ${ratio.toFixed(2)} < 4.5`);
  check(ratio >= floor, `NU CTA ${end} : ${ratio.toFixed(2)} sous le plancher contractuel ${floor}`);
}
// Sémantique sur canvas — planchers contractuels.
for (const [name, hex, min] of [
  ["positive", "#35D39A", 10.5], ["negative", "#FF6577", 7.1], ["warning", "#F6C453", 12.4],
]) {
  const ratio = contrast(hex, "#05060A");
  nuMeasured.push(`NU ${name} / canvas : ${ratio.toFixed(2)}:1`);
  check(ratio >= min, `NU ${name} / canvas : ${ratio.toFixed(2)} < ${min}`);
}
// Focus cyan : contraste NON TEXTUEL ≥ 3:1 sur toutes les surfaces.
for (const [surfName, surfHex] of Object.entries(NU_SURFACES)) {
  const ratio = contrast("#38BDF8", surfHex);
  check(ratio >= 3, `NU focus cyan / ${surfName} : ${ratio.toFixed(2)} < 3`);
}
// Le violet ne porte jamais seul un petit libellé actif : la règle est
// documentée ET le chip sélectionné garde le texte en text-primary.
check(contrast("#7C3AED", "#0B0D13") < 4.5,
  "garde de réalité : le violet mesure bien < 4,5 sur la navigation (d'où la règle)");
check(nuCss.includes("JAMAIS seul") || nuCss.includes("jamais un libellé"),
  "neon-ultra.css doit documenter la règle du violet");

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

// ---------- NU5 : galerie Neon Ultra dans un vrai navigateur ----------
for (const width of [320, 390]) {
  currentTest = `NU galerie ${width}px`;
  const page = await newPage(width);
  await page.goto(NU_GALLERY_URL);
  await page.waitForSelector("#nuSwatches .swatch");
  const overflow = await page.evaluate(() =>
    document.documentElement.scrollWidth - document.documentElement.clientWidth);
  check(overflow <= 0, `débordement horizontal de ${overflow}px`);
  // Nuancier complet : 17 rôles.
  const swatchCount = await page.$$eval("#nuSwatches .swatch", els => els.length);
  check(swatchCount === 17, `17 rôles attendus au nuancier (obtenu ${swatchCount})`);
  // Montant extrême entier.
  const longAmount = await page.evaluate(() => {
    const nodes = [...document.querySelectorAll(".nu-amount, .nu-amount-hero")];
    const el = nodes.find(n => n.textContent.includes("9'999'999.99"));
    return el ? { found: true, clipped: el.scrollWidth > el.clientWidth + 1 && getComputedStyle(el).overflow === "hidden" } : { found: false };
  });
  check(longAmount.found, "le montant CHF -9'999'999.99 doit être présenté");
  check(!longAmount.clipped, "le montant extrême ne doit pas être tronqué");
  // Chiffres tabulaires + AUCUN glow sur les montants.
  const heroStyle = await page.$eval(".nu-amount-hero", el => {
    const cs = getComputedStyle(el);
    return { numeric: cs.fontVariantNumeric, shadow: cs.textShadow };
  });
  check(heroStyle.numeric.includes("tabular-nums"), `chiffres tabulaires requis (obtenu ${heroStyle.numeric})`);
  check(heroStyle.shadow === "none", `aucun glow sur un montant (obtenu ${heroStyle.shadow})`);
  // Cibles ≥ 44 px.
  const smallTargets = await page.evaluate(() =>
    [...document.querySelectorAll("button, input, [role='button']")]
      .filter(el => el.offsetParent !== null)
      .map(el => ({ h: el.getBoundingClientRect().height, label: (el.textContent || el.id || "?").trim().slice(0, 30) }))
      .filter(t => t.h < 43.5));
  check(smallTargets.length === 0,
    `cibles < 44px : ${smallTargets.map(t => `${t.label} (${t.h.toFixed(0)}px)`).join(", ")}`);
  // États réellement présents : sélectionné, erreur, désactivé.
  const states = await page.evaluate(() => ({
    chipSelected: !!document.querySelector('.nu-chip[aria-pressed="true"]'),
    chipSelectedBorder: getComputedStyle(document.querySelector('.nu-chip[aria-pressed="true"]')).borderColor,
    rowSelected: !!document.querySelector(".nu-card--selected"),
    error: !!document.querySelector('.nu-field[aria-invalid="true"]'),
    errorMsg: (document.getElementById("nuFieldErrorMsg") || {}).textContent || "",
    disabledBtn: getComputedStyle(document.querySelector(".nu-button:disabled")).opacity,
    disabledChip: !!document.querySelector(".nu-chip:disabled"),
  }));
  check(states.chipSelected && states.rowSelected, "états sélectionnés présents (chip + ligne)");
  check(states.chipSelectedBorder === "rgb(124, 58, 237)",
    `le chip sélectionné porte l'indicateur violet en bordure (obtenu ${states.chipSelectedBorder})`);
  check(states.error && states.errorMsg.includes("chiffres"), "état d'erreur avec message textuel");
  check(Number(states.disabledBtn) <= 0.45 && states.disabledChip,
    "états désactivés identifiables (opacité réduite)");
  await page.context().close();
}

// ---------- NU6 : focus clavier cyan ≥ 2 px ----------
currentTest = "NU focus clavier";
{
  const page = await newPage(390);
  await page.goto(NU_GALLERY_URL);
  await page.waitForSelector("#nuFocusDemo");
  await page.evaluate(() => document.activeElement && document.activeElement.blur());
  await page.keyboard.press("Tab");
  const outline = await page.evaluate(() => {
    const cs = getComputedStyle(document.activeElement);
    return { width: cs.outlineWidth, style: cs.outlineStyle, color: cs.outlineColor };
  });
  check(outline.style !== "none" && parseFloat(outline.width) >= 2,
    `focus-visible ≥ 2px requis (obtenu ${outline.style} ${outline.width})`);
  check(outline.color === "rgb(56, 189, 248)",
    `anneau de focus CYAN attendu (obtenu ${outline.color})`);
  await page.context().close();
}

// ---------- NU7 : transparence réduite réellement OPAQUE ----------
currentTest = "NU transparence reduite";
{
  const page = await newPage(390);
  await page.goto(NU_GALLERY_URL);
  await page.waitForSelector("#nuToggleTransparency");
  await page.click("#nuToggleTransparency");
  const after = await page.evaluate(() => ({
    card: getComputedStyle(document.querySelector(".nu-card:not(.nu-card--elevated)")).backgroundColor,
    elevated: getComputedStyle(document.querySelector(".nu-card--elevated")).backgroundColor,
    shadow: getComputedStyle(document.querySelector(".nu-card--elevated")).boxShadow,
    blur: [...document.querySelectorAll(".nu-card, .nu-card--elevated")]
      .map(el => getComputedStyle(el).backdropFilter)
      .filter(v => v && v !== "none").length,
  }));
  // #151923 = rgb(21, 25, 35)
  check(after.card === "rgb(21, 25, 35)", `carte mate → fallback opaque attendu (obtenu ${after.card})`);
  check(after.elevated === "rgb(21, 25, 35)", `carte élevée → fallback opaque attendu (obtenu ${after.elevated})`);
  check(after.shadow === "none", `l'ombre de profondeur doit disparaître (obtenu ${after.shadow})`);
  check(after.blur === 0, "aucun blur résiduel en transparence réduite");
  await page.context().close();
}

// ---------- NU8 : reduced motion ----------
currentTest = "NU reduced motion";
{
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    reducedMotion: "reduce",
  });
  const page = await context.newPage();
  page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[${currentTest}] ${msg.text()}`); });
  page.on("pageerror", err => consoleErrors.push(`[${currentTest}] pageerror: ${err.message}`));
  await page.goto(NU_GALLERY_URL);
  await page.waitForSelector(".nu-button");
  const anim = await page.$eval(".nu-button", el => getComputedStyle(el).transitionDuration);
  check(anim === "0s" || parseFloat(anim) <= 0.011,
    `reduced motion doit neutraliser les transitions (obtenu ${anim})`);
  await context.close();
}

// ---------- NU9 : texte agrandi 200 % sans débordement ----------
currentTest = "NU texte agrandi 320px";
{
  const page = await newPage(320);
  await page.goto(NU_GALLERY_URL);
  await page.waitForSelector("#nuToggleLargeText");
  await page.click("#nuToggleLargeText");
  const state = await page.evaluate(() => ({
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    scale: getComputedStyle(document.documentElement).fontSize,
  }));
  check(state.scale === "32px", `texte agrandi à 200 % attendu (obtenu ${state.scale})`);
  check(state.overflow <= 0, `débordement horizontal en texte agrandi : ${state.overflow}px`);
  await page.context().close();
}

await browser.close();

// ---------- Bilan ----------
if (consoleErrors.length) {
  failures.push(...consoleErrors.map(e => `console: ${e}`));
}
console.log("Contrastes mesurés :");
for (const line of measured) console.log("  " + line);
console.log("Contrastes Neon Ultra mesurés :");
for (const line of nuMeasured) console.log("  " + line);
if (failures.length) {
  console.error(`\n✗ ${failures.length} échec(s) design system :`);
  for (const f of failures) console.error("  - " + f);
  process.exit(1);
}
console.log("\n✓ Design system Obsidian : tokens, parité, contrastes, galerie 320/390, cibles 44px, focus, reduced motion/transparency — OK, zéro erreur console");
console.log("✓ Fondations Neon Ultra (NU1) : tokens exacts, isolation de l'app, parité Swift, contrastes AA, galerie 320/390, focus cyan, états, texte 200 %, reduced motion/transparency — OK");
