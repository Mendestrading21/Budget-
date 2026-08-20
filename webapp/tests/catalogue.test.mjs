// Contrat du catalogue des identités locales — IC0 (ADR-037).
// Suite Node PURE (aucun navigateur) : elle fige le contrat de données du
// catalogue partagé PWA/iOS et prouve la réconciliation des glyphes entre
// la fixture, le registre PWA (webapp/index.html) et le registre natif
// (BudgetGlyph.swift). Interdit : champ de prix/solde/date/statut, URL ou
// texte dangereux, clé hors alphabet, repli de glyphe divergent entre
// plateformes.
import { readFileSync } from "node:fs";
import path from "path";
import { fileURLToPath } from "url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "..", "..");
const read = p => readFileSync(path.join(ROOT, p), "utf8");

const failures = [];
const check = (ok, message) => { if (!ok) failures.push(message); };

// ---------- 1. Une seule autorité éditoriale ----------
const fixtureRaw = read("fixtures/catalogue-identites.json");
const seedRaw = read(".claude/skills/budget-identites-locales/assets/catalogue-identites.seed.json");
check(fixtureRaw === seedRaw,
  "fixtures/catalogue-identites.json doit rester l'octet-copie de la fixture éditoriale du skill (une seule autorité)");

// ---------- 2. Contrat de données (miroir du validateur du skill) ----------
const KEY_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const UNSAFE_RE = /(?:https?|data|javascript):|[<>\u0000-\u001f\u007f-\u009f\u061c\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]/i;
const MARKETS = new Set(["GLOBAL", "CH", "FR", "BE"]);
const ENTITY_KINDS = new Set(["generic", "service", "institution"]);
const SENSES = new Set(["subscription", "bill", "set_aside", "account", "broker", "insurance", "pension", "asset", "liability"]);
const CADENCES = new Set(["none", "week", "four_weeks", "month", "quarter", "semiannual", "year", "custom"]);
const CURRENCIES = new Set(["CHF", "EUR"]);
const MARK_POLICIES = new Set(["generic_glyph", "monogram", "approved_asset"]);
const FIELDS = new Set(["key", "displayName", "aliases", "markets", "entityKind",
  "financialSense", "category", "cadenceHints", "currencyHints", "glyphKey",
  "markPolicy", "monogram", "assetKey"]);

const catalogue = JSON.parse(fixtureRaw);
check(JSON.stringify(Object.keys(catalogue).sort()) === JSON.stringify(["identities", "version"]),
  "racine du catalogue : exactement { version, identities }");
const identities = catalogue.identities ?? [];
check(identities.length >= 164, `au moins 164 identités attendues (obtenu ${identities.length})`);

const seenKeys = new Set();
for (const id of identities) {
  const label = id?.key ?? "(sans clé)";
  const extra = Object.keys(id).filter(k => !FIELDS.has(k));
  check(extra.length === 0, `${label} : champs interdits ${extra.join(", ")} — jamais de prix, solde, date, statut ou URL`);
  check(KEY_RE.test(id.key ?? ""), `${label} : clé hors alphabet kebab-case`);
  check(!seenKeys.has(id.key), `${label} : clé dupliquée`);
  seenKeys.add(id.key);
  check(typeof id.displayName === "string" && id.displayName.length > 0 && !UNSAFE_RE.test(id.displayName),
    `${label} : displayName absent ou dangereux`);
  check(Array.isArray(id.aliases) && id.aliases.every(a => typeof a === "string" && !UNSAFE_RE.test(a)),
    `${label} : alias non sûrs`);
  check(Array.isArray(id.markets) && id.markets.length > 0 && id.markets.every(m => MARKETS.has(m)),
    `${label} : marchés invalides`);
  check(ENTITY_KINDS.has(id.entityKind), `${label} : entityKind invalide`);
  check(SENSES.has(id.financialSense), `${label} : financialSense invalide`);
  check(typeof id.category === "string" && KEY_RE.test(id.category.replaceAll("_", "-")), `${label} : catégorie invalide`);
  check(Array.isArray(id.cadenceHints) && id.cadenceHints.every(c => CADENCES.has(c)),
    `${label} : cadence hors registre (four_weeks ne devient jamais month)`);
  check(Array.isArray(id.currencyHints) && id.currencyHints.every(c => CURRENCIES.has(c)),
    `${label} : devise hors registre — jamais un montant`);
  check(MARK_POLICIES.has(id.markPolicy), `${label} : markPolicy invalide`);
  check(id.markPolicy !== "approved_asset" && id.assetKey === null,
    `${label} : V1 = glyphes et monogrammes seulement — aucun actif tiers approuvé (ADR-037)`);
  if (id.markPolicy === "monogram") {
    check(typeof id.monogram === "string" && /^[A-Z0-9ÉÈÀÇ&+]{1,3}$/u.test(id.monogram),
      `${label} : monogramme d'une à trois lettres exigé (obtenu ${JSON.stringify(id.monogram)})`);
  }
}

// ---------- 3. Réconciliation des glyphes entre les DEUX plateformes ----------
const glyphMap = JSON.parse(read("fixtures/catalogue-glyph-map.json"));
const usedGlyphKeys = [...new Set(identities.map(i => i.glyphKey))].sort();
const mappedKeys = Object.keys(glyphMap.glyphs).sort();
check(JSON.stringify(usedGlyphKeys) === JSON.stringify(mappedKeys),
  `la carte des glyphes couvre EXACTEMENT les clés utilisées par la fixture (fixture: ${usedGlyphKeys.join(",")} ; carte: ${mappedKeys.join(",")})`);

// Registre PWA : les clés de BUDGET_GLYPHS dans la source servie.
const html = read("webapp/index.html");
const pwaStart = html.indexOf("const BUDGET_GLYPHS");
check(pwaStart >= 0, "registre PWA BUDGET_GLYPHS introuvable");
const pwaBody = html.slice(pwaStart, html.indexOf("};", pwaStart));
const pwaKeys = new Set([...pwaBody.matchAll(/^\s*([A-Za-z]\w*):/gm)].map(m => m[1]));

// Registre natif : les `case` déclarés de l'enum BudgetGlyph (avant le
// premier membre calculé — les `switch` répètent les mêmes noms ensuite).
const swift = read("Budget/Core/DesignSystem/BudgetGlyph.swift");
const enumStart = swift.indexOf("enum BudgetGlyph");
check(enumStart >= 0, "registre natif BudgetGlyph introuvable");
const enumBody = swift.slice(enumStart, swift.indexOf("var ", enumStart));
const iosKeys = new Set([...enumBody.matchAll(/^\s*case\s+([a-zA-Z]\w*)/gm)].map(m => m[1]));

let fullyMapped = 0;
let viaFallback = 0;
for (const [key, entry] of Object.entries(glyphMap.glyphs)) {
  const pwaGlyph = entry.pwa ?? entry.fallback?.pwa;
  const iosGlyph = entry.ios ?? entry.fallback?.ios;
  check(Boolean(pwaGlyph) && Boolean(iosGlyph),
    `${key} : chaque plateforme doit résoudre un glyphe (direct ou repli)`);
  check(!pwaGlyph || pwaKeys.has(pwaGlyph),
    `${key} : « ${pwaGlyph} » absent du registre PWA réel`);
  check(!iosGlyph || iosKeys.has(iosGlyph),
    `${key} : « ${iosGlyph} » absent du registre natif réel`);
  // Jamais de repli silencieux DIFFÉRENT entre plateformes : un repli est
  // le même sens des deux côtés (ici, le même nom canonique).
  if (entry.fallback) {
    check(entry.fallback.pwa === entry.fallback.ios,
      `${key} : repli divergent entre plateformes (${entry.fallback.pwa} / ${entry.fallback.ios}) — interdit par ADR-037`);
  }
  if (entry.pwa && entry.ios) fullyMapped += 1;
  else viaFallback += 1;
}

// ---------- Rapport ----------
if (failures.length) {
  console.error(`CATALOGUE : ${failures.length} échec(s) :`);
  for (const f of failures) console.error("  ✗ " + f);
  process.exit(1);
}
console.log(`SUITE CATALOGUE : ${identities.length} identités conformes au contrat ADR-037 · ${usedGlyphKeys.length} glyphKeys réconciliés sur les DEUX plateformes (${fullyMapped} mappés · ${viaFallback} en repli commun, à remplacer par IC1) · fixture synchronisée avec le skill ✓`);
