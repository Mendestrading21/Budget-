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

// ---------- NU2 : CHARGEMENT UNIQUE + isolation des valeurs ----------
// (Remplace l'assertion NU1 « index.html ne connaît pas Neon Ultra » : la
// feuille est désormais PARTAGÉE entre la galerie et les surfaces pilotes.)
currentTest = "NU isolation";
{
  const links = indexSrc.match(/<link[^>]+href="design-system\/neon-ultra\.css"[^>]*>/g) || [];
  check(links.length === 1,
    `index.html doit charger neon-ultra.css EXACTEMENT une fois (obtenu ${links.length})`);
}
// Aucune VALEUR canonique Neon Ultra recopiée dans l'app : uniquement des rôles.
for (const [name, value] of Object.entries(NU_CANONICAL)) {
  check(!indexSrc.includes(value),
    `index.html ne doit contenir AUCUNE valeur brute Neon Ultra (${name} = ${value})`);
}
check(!/--nu-[a-z-]+\s*:/.test(indexSrc),
  "index.html ne doit DÉCLARER aucun token --nu- (les tokens vivent dans neon-ultra.css)");
check(!cssSrc.includes("--nu-"), "obsidian.css ne doit contenir AUCUNE variable --nu-");
check(!indexSrc.includes("nu-body"), "le body de production ne porte jamais .nu-body");
check(nuGallery.includes('href="neon-ultra.css"') && !nuGallery.includes("obsidian.css"),
  "la galerie Neon Ultra ne charge QUE neon-ultra.css");
// Les références de rôles dans le markup de production sont elles aussi
// isolées : seules les fonctions pilotes peuvent employer `var(--nu-*)`.
// Un sélecteur CSS bien scopé ne compense pas une couleur NU injectée en
// ligne dans Comptes, Plus, Mouvements ou une fonction graphique partagée.
// Le contrôle attribue chaque occurrence à sa FONCTION englobante plutôt
// qu'à une tranche de source : renommer ou déplacer une fonction ne peut
// plus élargir la portée en silence, et le message nomme les fuyards.
// Liste blanche = exactement les renderers des surfaces pilotes.
const PILOT_RENDERERS = new Set([
  "renderHome",        // Mois
  "renderSimpleHome",  // Mois (accueil essentiel, ADR-026)
  "renderBudget",      // Budget
  "renderYearReview",  // Année (née dans l'identité Neon Ultra)
  "yearMonthRow",      // ligne de la page Année
  "renderSubs",        // Abonnements (née dans l'identité Neon Ultra)
]);
{
  const lines = indexSrc.split("\n");
  const starts = lines
    .map((l, i) => ({ i, m: /^function ([A-Za-z_$][\w$]*)/.exec(l) }))
    .filter(x => x.m)
    .map(x => ({ line: x.i, name: x.m[1] }));
  const ownerOf = (lineIndex) => {
    let owner = "<balisage HTML>";
    for (const s of starts) {
      if (s.line <= lineIndex) owner = s.name; else break;
    }
    return owner;
  };
  const leaks = new Map();
  lines.forEach((line, i) => {
    if (!line.includes("var(--nu-")) return;
    const owner = ownerOf(i);
    if (PILOT_RENDERERS.has(owner)) return;
    leaks.set(owner, (leaks.get(owner) || 0) + 1);
  });
  check(starts.some(s => s.name === "renderBudget"),
    "les fonctions de premier niveau doivent rester détectables");
  const detail = [...leaks].map(([fn, n]) => `${fn} ×${n}`).join(" | ") || "aucune";
  check(leaks.size === 0,
    `aucun rôle NU en ligne hors des renderers pilotes (fuite : ${detail})`);
}
// Portée STRICTE : hors :root et bascules d'accessibilité déterministes,
// chaque règle est enracinée dans une classe NU.
{
  const rules = nuCss.replace(/\/\*[\s\S]*?\*\//g, "").split("}")
    .map(r => r.split("{")[0].trim()).filter(Boolean)
    .flatMap(r => r.split(",").map(s => s.trim()))
    .filter(s => s && !s.startsWith("@") && s !== ":root" && s !== "from" && s !== "to");
  const leaking = rules.filter(sel =>
    !/\.nu-/.test(sel) && !/^html\[data-(nu-)?(reduced-transparency|large-text)/.test(sel));
  check(leaking.length === 0,
    `aucune règle Neon Ultra hors classe NU (fuite : ${leaking.slice(0, 4).join(" | ")})`);
}
// Les tokens Obsidian de l'app restent intacts (aucun n'est réécrit en NU).
for (const [name, value] of Object.entries(CANONICAL)) {
  const m = indexSrc.match(new RegExp(name.replace(/[-]/g, "\\-") + "\\s*:\\s*([^;]+);"));
  check(m && m[1].trim() === value, `token Obsidian ${name} INCHANGÉ dans index.html`);
}
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
  // Nuancier complet : 18 rôles (17 initiaux + textOnCta).
  const swatchCount = await page.$$eval("#nuSwatches .swatch", els => els.length);
  check(swatchCount === 18, `18 rôles attendus au nuancier (obtenu ${swatchCount})`);
  const hasOnCta = await page.evaluate(() =>
    [...document.querySelectorAll("#nuSwatches .swatch b")].some(b => b.textContent === "text-on-cta"));
  check(hasOnCta, "le rôle text-on-cta doit figurer au nuancier");
  // Un SEUL CTA primaire actif par section (point focal unique).
  const primariesPerSection = await page.evaluate(() =>
    [...document.querySelectorAll("main > section, main > .grid")].map(sec =>
      sec.querySelectorAll(".nu-button:not(.nu-button--secondary):not(.nu-button--destructive):not([disabled])").length));
  check(primariesPerSection.every(n => n <= 1),
    `chaque section porte AU PLUS un CTA primaire actif (obtenu ${primariesPerSection.join(",")})`);
  // Aucune troncature INTERNE d'un champ ou contrôle (pas seulement
  // l'absence de débordement de page).
  const clippedControls = await page.evaluate(() =>
    [...document.querySelectorAll(".nu-field, .nu-button, .nu-chip")]
      .filter(el => el.offsetParent !== null)
      .map(el => ({
        id: el.id || el.textContent.trim().slice(0, 20),
        w: el.scrollWidth - el.clientWidth,
        h: el.scrollHeight - el.clientHeight,
      }))
      .filter(c => c.w > 1 || c.h > 1));
  check(clippedControls.length === 0,
    `troncature interne détectée : ${clippedControls.map(c => `${c.id} (+${c.w}/${c.h}px)`).join(", ")}`);
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
  // La démonstration de focus est un bouton SECONDAIRE sombre (jamais un
  // deuxième CTA gradient) et reçoit réellement le focus clavier.
  const focusDemo = await page.evaluate(() => {
    const el = document.getElementById("nuFocusDemo");
    return { secondary: el.classList.contains("nu-button--secondary") };
  });
  check(focusDemo.secondary, "le bouton de démonstration du focus doit être secondaire");
  let reached = false;
  for (let i = 0; i < 20 && !reached; i++) {
    await page.keyboard.press("Tab");
    reached = await page.evaluate(() => document.activeElement.id === "nuFocusDemo");
  }
  const demoOutline = await page.evaluate(() => {
    const cs = getComputedStyle(document.getElementById("nuFocusDemo"));
    return { width: cs.outlineWidth, style: cs.outlineStyle, color: cs.outlineColor, offset: cs.outlineOffset };
  });
  check(reached, "le parcours clavier doit atteindre nuFocusDemo");
  check(demoOutline.style !== "none" && parseFloat(demoOutline.width) >= 2
    && demoOutline.color === "rgb(56, 189, 248)" && parseFloat(demoOutline.offset) >= 2,
    `focus cyan ≥ 2px avec offset attendu sur nuFocusDemo (obtenu ${JSON.stringify(demoOutline)})`);
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
  const state = await page.evaluate(() => {
    const viewportWidth = document.documentElement.clientWidth;
    const offenders = [...document.body.querySelectorAll("*")]
      .filter(el => el.offsetParent !== null)
      .map(el => {
        const rect = el.getBoundingClientRect();
        return {
          id: el.id || el.className || el.tagName,
          right: Math.round(rect.right - viewportWidth),
          width: Math.round(rect.width),
        };
      })
      .filter(item => item.right > 1)
      .sort((a, b) => b.right - a.right)
      .slice(0, 5);
    return {
      overflow: document.documentElement.scrollWidth - viewportWidth,
      scale: getComputedStyle(document.documentElement).fontSize,
      offenders,
    };
  });
  check(state.scale === "32px", `texte agrandi à 200 % attendu (obtenu ${state.scale})`);
  check(state.overflow <= 0,
    `débordement horizontal en texte agrandi : ${state.overflow}px (${state.offenders.map(x => `${x.id}: +${x.right}px/${x.width}px`).join(", ")})`);
  // La valeur complète du champ reste VISIBLE à 320 px / 200 % :
  // aucune troncature interne du champ multiligne ni des contrôles.
  const clipped200 = await page.evaluate(() =>
    [...document.querySelectorAll(".nu-field, .nu-button, .nu-chip")]
      .filter(el => el.offsetParent !== null)
      .map(el => ({
        id: el.id || el.textContent.trim().slice(0, 20),
        w: el.scrollWidth - el.clientWidth,
        h: el.scrollHeight - el.clientHeight,
      }))
      .filter(c => c.w > 1 || c.h > 1));
  check(clipped200.length === 0,
    `troncature interne à 200 % : ${clipped200.map(c => `${c.id} (+${c.w}/${c.h}px)`).join(", ")}`);
  const fieldFull = await page.evaluate(() => {
    const f = document.getElementById("nuFieldNormal");
    return { value: f.value, visible: f.scrollHeight <= f.clientHeight + 1 };
  });
  check(fieldFull.value === "Courses de la semaine" && fieldFull.visible,
    "la valeur « Courses de la semaine » reste complète et visible à 200 %");
  await page.context().close();
}

// ---------- NU2 : surfaces PILOTES de l'application ----------
// Scoping réel (Mois/Budget seulement), styles calculés Neon Ultra, CTA
// unique, cartes mates, montants sans glow, cibles, focus, états réduits —
// et ISOLATION prouvée sur les écrans restés Obsidian.
currentTest = "NU2 surfaces pilotes";
async function onboardApp(page) {
  await page.goto(APP_URL);
  await page.waitForSelector('[data-obcountry="CH"]');
  await page.click('[data-obcountry="CH"]');
  await page.click('[data-obhh="solo"]');
  await page.fill("#obName", "Alex");
  await page.click('#obForm1 button[type="submit"]');
  await page.fill("#obSalary", "5200");
  await page.click('#obForm2 button[type="submit"]');
  await page.waitForSelector("#obOpening", { state: "visible" });
  await page.fill("#obOpening", "3400");
  await page.click('#obForm3 button[type="submit"]');
  await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await page.click('[data-obgoal="urgence"]');
  await page.waitForSelector("#tabbar button");
  await page.waitForTimeout(6500);
}
const clippedIn = root => root.evaluate === undefined ? null : null; // (marqueur : helper page ci-dessous)
async function internallyClipped(page, selector) {
  return page.evaluate(sel => [...document.querySelectorAll(sel)]
    .filter(el => el.offsetParent !== null)
    .map(el => ({
      id: el.id || (el.textContent || "?").trim().slice(0, 22),
      w: el.scrollWidth - el.clientWidth, h: el.scrollHeight - el.clientHeight,
    }))
    .filter(c => c.w > 1 || c.h > 1), selector);
}
void clippedIn;
{
  const page = await newPage(390);
  await onboardApp(page);
  // Mois : classe pilote + styles calculés Neon Ultra.
  const mois = await page.evaluate(() => {
    const s = document.getElementById("screen");
    const hero = document.querySelector("#screen .card.hero");
    const cta = document.querySelector("#screen [data-addtx]");
    const stat = document.querySelector("#screen .stat");
    const amt = document.querySelector("#screen .hero-amount");
    const html = s.innerHTML;
    return {
      pilot: s.classList.contains("nu-pilot-screen"),
      screenBg: getComputedStyle(s).backgroundColor,
      heroBg: getComputedStyle(hero).backgroundColor,
      heroBlur: getComputedStyle(hero).backdropFilter,
      statBg: getComputedStyle(stat).backgroundColor,
      ctaGradient: getComputedStyle(cta).backgroundImage,
      ctaColor: getComputedStyle(cta).color,
      amountShadow: getComputedStyle(amt).textShadow,
      metrics: document.querySelectorAll("#screen .stat").length,
      priorities: document.querySelectorAll("#screen .priority-card").length,
      quick: document.querySelectorAll("#screen .quick-row .btn").length,
      bills: /factures mensuelles/i.test(s.innerText),
      // Ordre du premier niveau : salutation → héros → métriques → factures.
      order: [html.indexOf("Bonjour"), html.indexOf("Disponible"),
              html.indexOf('class="stat-grid'), html.indexOf("Factures mensuelles")],
      gradientCtas: [...document.querySelectorAll("#screen .btn")]
        .filter(b => getComputedStyle(b).backgroundImage.includes("gradient")).length,
      blurred: [...document.querySelectorAll("#screen .card")]
        .filter(c => getComputedStyle(c).backdropFilter !== "none").length,
      glowing: [...document.querySelectorAll("#screen .amount, #screen .hero-amount")]
        .filter(a => getComputedStyle(a).textShadow !== "none").length,
    };
  });
  check(mois.pilot, "Mois porte la classe nu-pilot-screen");
  check(mois.screenBg === "rgb(5, 6, 10)", `canvas Neon Ultra attendu (obtenu ${mois.screenBg})`);
  check(mois.heroBg === "rgb(24, 28, 38)", `héros sur surface élevée (obtenu ${mois.heroBg})`);
  check(mois.heroBlur === "none", "aucun blur sur le héros pilote");
  check(mois.statBg === "rgb(17, 20, 28)", `métriques sur surface mate (obtenu ${mois.statBg})`);
  check(mois.ctaGradient.includes("gradient") && mois.ctaGradient.includes("192, 0, 164"),
    "l'action « Ajouter un mouvement » porte le dégradé CTA canonique");
  check(mois.ctaColor === "rgb(255, 255, 255)", "texte du CTA en blanc pur");
  check(mois.amountShadow === "none" && mois.glowing === 0, "AUCUN glow autour d'un montant");
  check(mois.metrics === 4, `exactement 4 métriques (obtenu ${mois.metrics})`);
  check(mois.priorities === 0, `aucune priorité technique sur l'accueil (obtenu ${mois.priorities})`);
  check(mois.quick === 0, `aucune rangée d'actions rapides (obtenu ${mois.quick})`);
  check(mois.bills, "la section « Factures mensuelles » est visible");
  check(mois.order.every(i => i >= 0) && mois.order[0] < mois.order[1]
    && mois.order[1] < mois.order[2] && mois.order[2] < mois.order[3],
    `ordre du premier niveau : salutation → héros → métriques → factures (${mois.order})`);
  check(mois.gradientCtas === 1, `UN SEUL CTA gradient sur Mois (obtenu ${mois.gradientCtas})`);
  check(mois.blurred === 0, "aucune carte de liste floutée sur une surface pilote");
  // Cibles ≥ 44 px et aucune troncature interne.
  for (const width of [390, 320]) {
    await page.setViewportSize({ width, height: 844 });
    await page.waitForTimeout(200);
    const small = await page.evaluate(() =>
      [...document.querySelectorAll("#screen .btn, #screen [role='button']")]
        .filter(el => el.offsetParent !== null)
        .filter(el => el.getBoundingClientRect().height < 43.5).length);
    check(small === 0, `Mois ${width}px : toutes les cibles ≥ 44 px (obtenu ${small} trop petites)`);
    const over = await page.evaluate(() =>
      document.documentElement.scrollWidth - document.documentElement.clientWidth);
    check(over <= 0, `Mois ${width}px : aucun débordement horizontal (${over}px)`);
    const clipped = await internallyClipped(page, "#screen .btn, #screen .stat, #screen .card-label");
    check(clipped.length === 0,
      `Mois ${width}px : aucune troncature interne (${clipped.map(c => c.id).join(", ")})`);
  }
  await page.setViewportSize({ width: 390, height: 844 });
  // Montant extrême (fictif) : sept chiffres, positif et négatif, ENTIERS.
  await page.evaluate(() => {
    transactions.push({ id: ++txSeq, y: cursor.y, m: cursor.m, d: 2, title: "Extrême NU2 +",
      type: "income", cat: null, acc: ACCOUNTS[0].id, dest: null, status: "posted", amount: 9999999.99 });
    saveState(); render();
  });
  await page.waitForTimeout(250);
  const extreme = await page.evaluate(() => {
    const el = document.querySelector("#screen .hero-amount");
    return { text: el.textContent, clipped: el.scrollWidth > el.clientWidth + 1 };
  });
  check(/\d'\d{3}'\d{3}/.test(extreme.text) && !extreme.clipped,
    `montant extrême entier et non tronqué (obtenu « ${extreme.text} »)`);

  // Budget : héros, statut ÉCRIT, anneau accessible, lignes mates.
  await page.click(`#tabbar button[aria-label="Budget"]`);
  await page.waitForTimeout(300);
  const budget = await page.evaluate(() => {
    const s = document.getElementById("screen");
    const ring = document.querySelector('#screen svg[role="img"]');
    return {
      pilot: s.classList.contains("nu-pilot-screen"),
      screenBg: getComputedStyle(s).backgroundColor,
      // `innerText` reflète `text-transform` : comparaison insensible à la casse.
      empty: /aucun budget/i.test(s.innerText),
      explained: /comment ça marche/i.test(s.innerText) && /planifié/i.test(s.innerText),
      ringLabel: ring ? ring.getAttribute("aria-label") || "" : "",
      gradientCtas: [...document.querySelectorAll("#screen .btn")]
        .filter(b => getComputedStyle(b).backgroundImage.includes("gradient")).length,
      overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    };
  });
  check(budget.pilot && budget.screenBg === "rgb(5, 6, 10)", "Budget est une surface pilote Neon Ultra");
  check(budget.gradientCtas === 1,
    `Budget vide : UNE action principale évidente en CTA gradient (obtenu ${budget.gradientCtas})`);
  check(budget.empty && budget.explained,
    "Budget vide : explication simple présente (aucun écran qui paraît cassé)");
  check(budget.overflow <= 0, `Budget vide : aucun débordement horizontal (${budget.overflow}px)`);
  // État CHARGÉ : une vraie ligne budgétaire est créée par le parcours réel.
  await page.click("#screen [data-addline]");
  await page.waitForSelector("#lineForm", { state: "visible" });
  await page.fill("#lAmount", "650");
  await page.click('#lineForm button[type="submit"]');
  await page.waitForTimeout(350);
  const loaded = await page.evaluate(() => {
    const s = document.getElementById("screen");
    const ring = document.querySelector('#screen svg[role="img"]');
    const line = document.querySelector("#screen .card .bar-row");
    return {
      states: ["Dans le plan", "À surveiller", "Dépassé"].filter(t => s.innerText.includes(t)),
      ringLabel: ring ? ring.getAttribute("aria-label") || "" : "",
      values: s.innerText.includes("dépensé") && s.innerText.includes("prévu"),
      lineBg: line ? getComputedStyle(line.closest(".card")).backgroundColor : "",
      fill: line ? getComputedStyle(line.querySelector(".fill")).backgroundImage : "",
      gradientCtas: [...document.querySelectorAll("#screen .btn")]
        .filter(b => getComputedStyle(b).backgroundImage.includes("gradient")).length,
      overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    };
  });
  check(loaded.states.length >= 1,
    `Budget chargé : l'état du plan est ÉCRIT (obtenu ${loaded.states.join(",") || "aucun"})`);
  check(loaded.ringLabel.includes("%") || loaded.ringLabel.toLowerCase().includes("budget"),
    `l'anneau plan/réel porte une étiquette accessible (obtenu « ${loaded.ringLabel} »)`);
  check(loaded.values, "le dépensé et le prévu restent DEUX chiffres nommés, jamais mélangés");
  check(loaded.lineBg === "rgb(17, 20, 28)", `lignes de catégories MATES (obtenu ${loaded.lineBg})`);
  check(loaded.fill === "none", `barres simples, sans gradient décoratif (obtenu ${loaded.fill})`);
  check(loaded.gradientCtas <= 1, `Budget chargé : au plus un CTA gradient (obtenu ${loaded.gradientCtas})`);
  check(loaded.overflow <= 0, `Budget chargé : aucun débordement horizontal (${loaded.overflow}px)`);

  // Feuille pilote : l'action unique ouvre directement Nouveau mouvement.
  await page.click(`#tabbar button[aria-label="Mois"]`);
  await page.waitForTimeout(200);
  check(await page.$("#fab") === null, "aucun bouton flottant global");
  await page.click("#screen [data-addtx]");
  await page.waitForSelector("#txForm", { state: "visible" });
  const form = await page.evaluate(() => {
    const f = document.getElementById("txForm");
    const chip = f.querySelector('[data-ftype="expense"]');
    const submit = f.querySelector('button[type="submit"]');
    return {
      pilot: f.classList.contains("nu-pilot-sheet"),
      bg: getComputedStyle(f).backgroundColor,
      fieldBg: getComputedStyle(document.getElementById("fAmount")).backgroundColor,
      chipPressed: chip.getAttribute("aria-pressed"),
      chipBorder: getComputedStyle(chip).borderTopColor,
      submitGradient: getComputedStyle(submit).backgroundImage.includes("gradient"),
      gradientCount: [...f.querySelectorAll(".btn")]
        .filter(b => getComputedStyle(b).backgroundImage.includes("gradient")).length,
      stickyBg: getComputedStyle(f.querySelector(".actions.sticky")).backgroundColor,
      titleTag: document.getElementById("fTitle").tagName,
      smallTargets: [...f.querySelectorAll("button, input:not(.sr-select), select:not(.sr-select), textarea, summary")]
        .filter(el => el.offsetParent !== null)
        .map(el => ({
          label: el.id || (el.textContent || el.getAttribute("aria-label") || el.tagName).trim().slice(0, 24),
          h: el.getBoundingClientRect().height,
        }))
        .filter(item => item.h < 43.5),
    };
  });
  check(form.pilot && form.bg === "rgb(24, 28, 38)", "le formulaire est une feuille pilote élevée");
  check(form.fieldBg === "rgb(11, 13, 19)", `champs OPAQUES (obtenu ${form.fieldBg})`);
  check(form.chipPressed === "true" && form.chipBorder === "rgb(124, 58, 237)",
    "la chip sélectionnée porte le bord violet (texte principal conservé)");
  check(form.submitGradient && form.gradientCount === 1,
    `« Enregistrer » est le SEUL CTA gradient de la feuille (obtenu ${form.gradientCount})`);
  check(form.stickyBg === "rgb(24, 28, 38)", "le pied collant reste sur la surface élevée");
  check(form.titleTag === "TEXTAREA", "l'intitulé est multiligne (aucune troncature à 200 %)");
  check(form.smallTargets.length === 0,
    `tous les contrôles du formulaire font ≥ 44 px (${form.smallTargets.map(t => `${t.label}: ${t.h.toFixed(0)}px`).join(", ")})`);
  // Erreur : message corail PRÈS du champ + aria-invalid + saisie conservée.
  await page.evaluate(() => { document.getElementById("fMore").open = true; });
  await page.fill("#fTitle", "Courses de la semaine au marché couvert");
  await page.fill("#fAmount", "");
  await page.click('#txForm button[type="submit"]');
  await page.waitForTimeout(250);
  const errState = await page.evaluate(() => {
    const err = document.getElementById("fError");
    const amount = document.getElementById("fAmount");
    return {
      text: err.textContent, color: getComputedStyle(err).color,
      nextToField: amount.nextElementSibling === err,
      invalid: amount.getAttribute("aria-invalid"),
      keptTitle: document.getElementById("fTitle").value,
      saveVisible: document.querySelector('#txForm button[type="submit"]').getBoundingClientRect().height > 0,
    };
  });
  check(errState.text.length > 0 && errState.color === "rgb(255, 101, 119)",
    `message d'erreur CORAIL (obtenu ${errState.color})`);
  check(errState.nextToField && errState.invalid === "true",
    "erreur placée près du champ concerné, marqué aria-invalid");
  check(errState.keptTitle === "Courses de la semaine au marché couvert",
    "la saisie est CONSERVÉE après une erreur");
  check(errState.saveVisible, "« Enregistrer » reste visible après l'erreur");
  await page.click("#fCancel"); // fermeture sans garde-fou de saisie
  await page.waitForTimeout(250);

  // ISOLATION : les écrans restants gardent EXACTEMENT leur rendu Obsidian.
  const OBSIDIAN_SURFACES = ["rgba(20, 25, 37, 0.72)", "rgba(27, 34, 48, 0.88)"];
  for (const label of ["Comptes", "Gérer"]) {
    await page.click(`#tabbar button[aria-label="${label}"]`);
    await page.waitForTimeout(250);
    const iso = await page.evaluate(() => {
      const s = document.getElementById("screen");
      const card = document.querySelector("#screen .card");
      return {
        pilot: s.classList.contains("nu-pilot-screen"),
        bg: getComputedStyle(s).backgroundColor,
        card: card ? getComputedStyle(card).backgroundColor : "(aucune)",
      };
    });
    check(!iso.pilot, `${label} ne porte AUCUNE classe pilote`);
    check(iso.bg === "rgba(0, 0, 0, 0)", `${label} garde le fond Obsidian (obtenu ${iso.bg})`);
    check(OBSIDIAN_SURFACES.includes(iso.card),
      `${label} garde ses cartes Obsidian translucides (obtenu ${iso.card})`);
    if (label === "Comptes") {
      const accountTrigger = await page.$("#screen [data-accid]");
      check(!!accountTrigger, "Comptes expose au moins un détail de compte testable");
      if (accountTrigger) {
        await accountTrigger.click();
        await page.waitForTimeout(200);
        const chart = await page.evaluate(() => {
          const polyline = document.querySelector("#screen .chart-select polyline");
          const rule = document.querySelector("#screen [data-scrubrule]");
          return {
            pilot: document.getElementById("screen").classList.contains("nu-pilot-screen"),
            line: polyline ? getComputedStyle(polyline).stroke : "",
            rule: rule ? getComputedStyle(rule).stroke : "",
          };
        });
        check(!chart.pilot, "le détail de compte reste hors pilote");
        check(chart.line === "rgb(145, 136, 255)",
          `la courbe de compte garde l'Indigo Obsidian (obtenu ${chart.line})`);
        check(chart.rule === "rgb(167, 176, 192)",
          `la règle de lecture garde le gris Obsidian (obtenu ${chart.rule})`);
        await page.click("#screen [data-accback]");
        await page.waitForTimeout(150);
      }
    }
  }
  // Historique : destination principale Obsidian.
  await page.click('#tabbar button[aria-label="Historique"]');
  await page.waitForTimeout(250);
  const mov = await page.evaluate(() => ({
    pilot: document.getElementById("screen").classList.contains("nu-pilot-screen"),
    labels: [...document.querySelectorAll("#tabbar button[data-tab]")]
      .map(button => button.getAttribute("aria-label")),
    fab: !!document.getElementById("fab"),
  }));
  check(!mov.pilot, "Historique reste Obsidian");
  check(mov.labels.join(",") === "Mois,Historique,Budget,Comptes,Gérer" && !mov.fab,
    `barre à 5 destinations sans ＋ (${mov.labels.join(",")}, fab=${mov.fab})`);
  await page.context().close();
}

// ---------- NU2 : transparence réduite et mouvement réduit sur les pilotes ----------
currentTest = "NU2 accessibilité";
{
  const page = await newPage(390);
  await onboardApp(page);
  await page.evaluate(() => { document.documentElement.dataset.reducedTransparency = "true"; });
  await page.waitForTimeout(200);
  const rt = await page.evaluate(() => {
    const hero = document.querySelector("#screen .card.hero");
    const card = document.querySelector("#screen .card:not(.hero)");
    return {
      hero: getComputedStyle(hero).backgroundColor,
      card: card ? getComputedStyle(card).backgroundColor : "rgb(21, 25, 35)",
      shadow: getComputedStyle(hero).boxShadow,
      blur: getComputedStyle(hero).backdropFilter,
    };
  });
  check(rt.hero === "rgb(21, 25, 35)", `transparence réduite : héros opaque #151923 (obtenu ${rt.hero})`);
  check(rt.card === "rgb(21, 25, 35)", `transparence réduite : cartes opaques (obtenu ${rt.card})`);
  check(rt.shadow === "none" && rt.blur === "none", "transparence réduite : ni ombre ni blur résiduels");
  await page.context().close();
}
{
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, reducedMotion: "reduce" });
  const page = await context.newPage();
  page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[${currentTest}] ${msg.text()}`); });
  page.on("pageerror", err => consoleErrors.push(`[${currentTest}] pageerror: ${err.message}`));
  await onboardApp(page);
  const rm = await page.evaluate(() => {
    const cta = document.querySelector("#screen [data-addtx]");
    return { btn: getComputedStyle(cta).transitionDuration };
  });
  check(rm.btn === "0s" || parseFloat(rm.btn) <= 0.011,
    `mouvement réduit : transitions neutralisées sur les pilotes (obtenu ${rm.btn})`);
  await context.close();
}

// ---------- NU2 : texte agrandi — aucune perte de fonction ni troncature ----------
currentTest = "NU2 texte agrandi";
{
  const context = await browser.newContext({ viewport: { width: 320, height: 844 }, deviceScaleFactor: 2 });
  const page = await context.newPage();
  page.on("console", msg => { if (msg.type() === "error") consoleErrors.push(`[${currentTest}] ${msg.text()}`); });
  page.on("pageerror", err => consoleErrors.push(`[${currentTest}] pageerror: ${err.message}`));
  await onboardApp(page);
  await page.evaluate(() => { document.documentElement.dataset.largeText = "true"; });
  await page.waitForTimeout(250);
  const big = await page.evaluate(() => ({
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    cta: !!document.querySelector("#screen [data-addtx]"),
    amount: (document.querySelector("#screen .hero-amount") || {}).textContent || "",
  }));
  const clippedBig = await internallyClipped(page, "#screen .btn, #screen .stat, #screen .card-label, #screen .hero-amount");
  check(big.overflow <= 0, `texte agrandi : aucun débordement horizontal (${big.overflow}px)`);
  check(big.cta && /CHF/.test(big.amount), "texte agrandi : aucune perte de fonction (CTA et montant présents)");
  check(clippedBig.length === 0,
    `texte agrandi : aucune troncature interne (${clippedBig.map(c => c.id).join(", ")})`);
  await context.close();
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
console.log("✓ Surfaces pilotes Neon Ultra (NU2) : chargement unique, aucune valeur brute dans l'app, tokens Obsidian intacts, scoping Mois/Budget + txForm, accueil simplifié, 5 destinations sans FAB, CTA unique, cartes mates, montants sans glow, 44 px, focus cyan, états vide/erreur/extrême, texte agrandi, reduced motion/transparency, isolation des écrans Obsidian — OK");
