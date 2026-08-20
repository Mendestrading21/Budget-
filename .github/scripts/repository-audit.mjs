#!/usr/bin/env node
// Audit release déterministe du dépôt Budget (Budget 1.0).
// Zéro dépendance externe. Chaque contrôle imprime PASS/FAIL ; le
// processus sort en erreur dès qu'un contrôle échoue. Le script LIT
// seulement — il ne modifie jamais le dépôt.
//
// Usage : node .github/scripts/repository-audit.mjs

import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join } from "node:path";

const root = new URL("../..", import.meta.url).pathname;
let failures = 0;

function check(label, ok, detail = "") {
  const mark = ok ? "PASS" : "FAIL";
  console.log(`${mark}  ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
}

function read(path) {
  return readFileSync(join(root, path), "utf8");
}

function* walk(dir, exts) {
  for (const entry of readdirSync(join(root, dir))) {
    // node_modules (liens symboliques en boucle) et dossiers cachés ne
    // font pas partie du code livré.
    if (entry === "node_modules" || entry.startsWith(".")) continue;
    const rel = join(dir, entry);
    const full = join(root, rel);
    const stats = statSync(full, { throwIfNoEntry: false });
    if (!stats) continue;
    if (stats.isDirectory()) {
      yield* walk(rel, exts);
    } else if (exts.some(ext => entry.endsWith(ext))) {
      yield rel;
    }
  }
}

// 1. Les fichiers porteurs doivent exister.
const required = [
  "CLAUDE.md",
  "BUDGET_PRISME_STATUS.md",
  "BUDGET_1_0_READINESS.md",
  "FINANCIAL_ENGINE_V2.md",
  "DECISION_LOG.md",
  "docs/INDEX.md",
  "webapp/index.html",
  "webapp/manifest.webmanifest",
  "webapp/sw.js",
  "webapp/tests/e2e.test.mjs",
  "webapp/tests/parity.test.mjs",
  "webapp/tests/design.test.mjs",
  "fixtures/parity-fixtures.json",
  "Budget/PrivacyInfo.xcprivacy",
  ".github/workflows/ci.yml",
  ".github/workflows/pages.yml",
  ".github/workflows/demo.yml",
  ".github/workflows/testflight.yml",
];
for (const path of required) {
  check(`présent : ${path}`, existsSync(join(root, path)));
}

// 2. Syntaxe des scripts de test (node --check).
for (const path of ["webapp/tests/e2e.test.mjs", "webapp/tests/parity.test.mjs", "webapp/tests/design.test.mjs"]) {
  let ok = true;
  let detail = "";
  try {
    execFileSync(process.execPath, ["--check", join(root, path)], { stdio: "pipe" });
  } catch (error) {
    ok = false;
    detail = String(error.stderr || error.message).split("\n")[0];
  }
  check(`node --check : ${path}`, ok, detail);
}

// 3. Fixtures de parité : JSON valide, ≥ 6 scénarios complets.
try {
  const fixtures = JSON.parse(read("fixtures/parity-fixtures.json"));
  const scenarios = fixtures.scenarios ?? [];
  check("fixtures de parité : ≥ 6 scénarios", scenarios.length >= 6, `${scenarios.length} scénarios`);
  // Chaque scénario porte un id et au moins UNE preuve attendue
  // (snapshot, balances ou invariants — « virement-devises » n'a pas de
  // snapshot, c'est voulu).
  const incomplete = scenarios.filter(s => !s.id || !s.expected || Object.keys(s.expected).length === 0);
  check("fixtures de parité : chaque scénario a id + preuves attendues", incomplete.length === 0,
    incomplete.map(s => s.id).join(", "));
} catch (error) {
  check("fixtures de parité : JSON valide", false, String(error.message));
}

// 4. Aucun TODO/FIXME/HACK dans le code livré.
{
  const offenders = [];
  const sources = [
    ...walk("Budget", [".swift"]),
    ...walk("BudgetTests", [".swift"]),
    ...walk("BudgetUITests", [".swift"]),
    "webapp/index.html",
    ...walk("webapp/tests", [".mjs"]),
  ];
  for (const path of sources) {
    const text = read(path);
    if (/\b(TODO|FIXME|HACK)\b/.test(text)) offenders.push(path);
  }
  check("aucun TODO/FIXME/HACK dans le code livré", offenders.length === 0, offenders.join(", "));
}

// 5. Aucun secret en dur (les références GitHub `${{ secrets.* }}` et les
//    champs de mot de passe de l'interface sont légitimes).
{
  const offenders = [];
  const pattern = /(ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|BEGIN (RSA|EC|OPENSSH) PRIVATE|AKIA[0-9A-Z]{16})/;
  const sources = [
    ...walk("Budget", [".swift", ".xcprivacy", ".plist"]),
    "webapp/index.html",
    "webapp/sw.js",
    ...walk("webapp/tests", [".mjs"]),
    ...walk(".github", [".yml", ".mjs"]),
    "fixtures/parity-fixtures.json",
  ];
  for (const path of sources) {
    if (pattern.test(read(path))) offenders.push(path);
  }
  check("aucun secret en dur", offenders.length === 0, offenders.join(", "));
}

// 6. Aucune donnée personnelle réelle dans le code, les tests ou les fixtures.
{
  const offenders = [];
  const pattern = /mendestrading|e\.mendes/i;
  const sources = [
    ...walk("Budget", [".swift"]),
    ...walk("BudgetTests", [".swift"]),
    "webapp/index.html",
    ...walk("webapp/tests", [".mjs"]),
    "fixtures/parity-fixtures.json",
  ];
  for (const path of sources) {
    if (pattern.test(read(path))) offenders.push(path);
  }
  check("aucune donnée personnelle réelle dans le code livré", offenders.length === 0, offenders.join(", "));
}

// 7. Réglages Xcode de release : iPhone seul (ADR-023), iOS 17, version posée.
{
  const pbxproj = read("Budget.xcodeproj/project.pbxproj");
  const families = [...pbxproj.matchAll(/TARGETED_DEVICE_FAMILY = ([^;]+);/g)].map(m => m[1].trim());
  check("Xcode : TARGETED_DEVICE_FAMILY toujours 1 (iPhone seul)", families.length > 0 && families.every(f => f === "1" || f === '"1"'), families.join(", "));
  const targets = [...pbxproj.matchAll(/IPHONEOS_DEPLOYMENT_TARGET = ([^;]+);/g)].map(m => m[1].trim());
  check("Xcode : cible iOS 17.0", targets.length > 0 && targets.every(t => t === "17.0"), targets.join(", "));
  check("Xcode : MARKETING_VERSION présent", /MARKETING_VERSION = [0-9.]+;/.test(pbxproj));
}

// 8. Manifeste de confidentialité honnête : aucun pistage, aucune collecte.
{
  const privacy = read("Budget/PrivacyInfo.xcprivacy");
  check("PrivacyInfo : NSPrivacyTracking = false", /<key>NSPrivacyTracking<\/key>\s*<false\/>/.test(privacy));
  check("PrivacyInfo : aucune donnée collectée", /<key>NSPrivacyCollectedDataTypes<\/key>\s*<array\/>/.test(privacy));
}

// 9. Autorité des skills : /budget-prisme actif, les anciens explicitement légacy.
{
  const claude = read("CLAUDE.md");
  check("CLAUDE.md : /budget-prisme est l'autorité", claude.includes("/budget-prisme"));
  check("CLAUDE.md : les anciens skills sont déclarés légacy", /legacy/i.test(claude));
  const skills = readdirSync(join(root, ".claude/skills")).sort();
  const expected = ["apple-design", "budget-identites-locales", "budget-neon-ultra", "budget-prisme"];
  check(
    "skills du dépôt : ensemble attendu (apple-design, budget-identites-locales [compagnon, PR #91], budget-neon-ultra [alias légacy], budget-prisme)",
    JSON.stringify(skills) === JSON.stringify(expected),
    skills.join(", ")
  );
}

// 10. La PWA reste honnête : service worker network-first et manifeste installable.
{
  const manifest = JSON.parse(read("webapp/manifest.webmanifest"));
  check("manifest : nom + icônes + display", Boolean(manifest.name && manifest.icons?.length && manifest.display));
  const sw = read("webapp/sw.js");
  check("service worker : stratégie network-first déclarée", /network[- ]first|fetch\(/i.test(sw));
}

console.log("");
if (failures > 0) {
  console.error(`AUDIT : ${failures} contrôle(s) en échec.`);
  process.exit(1);
}
console.log("AUDIT : tous les contrôles passent.");
