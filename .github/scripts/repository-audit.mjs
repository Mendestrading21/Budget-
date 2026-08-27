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
  "webapp/tests/catalogue.test.mjs",
  "fixtures/parity-fixtures.json",
  "fixtures/catalogue-identites.json",
  "fixtures/catalogue-glyph-map.json",
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
for (const path of ["webapp/tests/e2e.test.mjs", "webapp/tests/parity.test.mjs", "webapp/tests/design.test.mjs", "webapp/tests/catalogue.test.mjs"]) {
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
  const expected = ["apple-design", "budget-autonomie-100", "budget-identites-locales", "budget-neon-ultra", "budget-prisme"];
  check(
    "skills du dépôt : ensemble attendu (apple-design, budget-autonomie-100 [programme, PR #123], budget-identites-locales [compagnon, PR #91], budget-neon-ultra [alias légacy], budget-prisme)",
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

// 11. W5.8 : CODE VIVANT — chaque fonction de la PWA a un appelant
// (app ou tests). Une fonction sans aucun lecteur est du code mort :
// elle échoue l'audit au lieu de s'accumuler. Les exceptions sont
// NOMMÉES et justifiées — jamais silencieuses.
{
  // Fonctions volontairement sans appelant applicatif (leur existence
  // est un contrat, prouvé par les tests) :
  const contratsTestesSeulement = new Map([
    ["annulerOccurrence", "API domaine W2.5 — la surface « annuler » arrive avec les écrans natifs de W5"],
    ["comparerOccurrencesEtCompteurs", "gate de parité W2.7a — son rôle EST d'être appelée par les tests"],
    ["confirmerOccurrence", "porte de confirmation W2.4 — l'app confirme via transitionOccurrence, la porte reste le contrat testé"],
    ["migrerHistoriqueJournal", "ADR-064 « préparer sans allumer » — jamais d'appelant UI avant décision propriétaire"],
    ["misDeCoteParDestination", "spécification exécutable C4 (zéro double compte) — vérifiée au centime par les tests"],
    ["pensionDisplayTotal", "spécification exécutable C3 (prévoyance sans double compte) — vérifiée par les tests"],
    ["tauxAuJour", "délégation W9.8 vers le domaine extrait (domaineTauxAuJour) — contrat des taux datés vérifié par le test 226 ; l'app convertit via toCHFAuMois"],
  ]);
  const app = read("webapp/index.html");
  let tests = "";
  for (const rel of walk("webapp/tests", [".mjs"])) tests += read(rel);
  const noms = [...new Set([...app.matchAll(/^\s*function ([A-Za-z_$][\w$]*)\(/gm)].map(m => m[1]))];
  const mortes = [];
  const exceptionsInvalides = [];
  for (const nom of noms) {
    const usagesApp = (app.match(new RegExp(`\\b${nom}\\b`, "g")) || []).length - 1;
    const usagesTests = (tests.match(new RegExp(`\\b${nom}\\b`, "g")) || []).length;
    if (usagesApp === 0 && usagesTests === 0) mortes.push(nom);
    else if (usagesApp === 0 && !contratsTestesSeulement.has(nom)) exceptionsInvalides.push(nom);
  }
  check("code vivant : aucune fonction sans appelant (app + tests)", mortes.length === 0, mortes.join(", "));
  check(
    "code vivant : toute fonction « tests seulement » est une exception nommée et justifiée",
    exceptionsInvalides.length === 0,
    exceptionsInvalides.join(", ")
  );
  const perimees = [...contratsTestesSeulement.keys()].filter(nom => !noms.includes(nom)
    || (app.match(new RegExp(`\\b${nom}\\b`, "g")) || []).length - 1 > 0);
  check("code vivant : la liste d'exceptions ne contient rien de périmé", perimees.length === 0, perimees.join(", "));
}

// W10.7 — confidentialité OUTILLÉE (preuve par inspection, pas par
// affirmation) : aucun log dans le code natif livré (print/NSLog/os_log
// — « fingerprint » n'est pas un log), aucun console.* émis par la PWA
// livrée, écritures de fichiers PROTÉGÉES (.completeFileProtection), et
// PrivacyInfo déclare l'accès UserDefaults (CA92.1). Nés verts (état
// déjà propre) : le verrou est consigné, les sabotages font foi.
{
  const fautifs = [];
  for (const rel of walk("Budget", [".swift"])) {
    const sans = read(rel).replace(/\w*[Ff]ingerprint\w*\(/g, "(");
    if (/\bprint\(|\bNSLog\(|\bos_log\(|Logger\(subsystem/.test(sans)) fautifs.push(rel);
  }
  check("confidentialité : aucun log dans le code natif livré", fautifs.length === 0, fautifs.join(", "));
  const pwa = read("webapp/index.html") + read("webapp/sw.js");
  const consoles = pwa.match(/console\.(log|info|warn|error|debug)/g) || [];
  check("confidentialité : la PWA livrée n'émet aucun console.*", consoles.length === 0,
    [...new Set(consoles)].join(", "));
  const fichiers = read("Budget/Core/Security/DocumentFileStore.swift");
  const reglages = read("Budget/Features/Settings/SettingsView.swift");
  check("confidentialité : écritures de fichiers protégées (.completeFileProtection)",
    (fichiers.match(/completeFileProtection/g) || []).length >= 2
      && reglages.includes("completeFileProtection"));
  const privacy = read("Budget/PrivacyInfo.xcprivacy");
  check("PrivacyInfo : accès UserDefaults déclaré avec la raison CA92.1",
    privacy.includes("NSPrivacyAccessedAPICategoryUserDefaults") && privacy.includes("CA92.1"));
}

// W11.1 (ADR-074) — thème et langue VERROUILLÉS : l'identité sombre
// unique et le français fr-CH sont des choix produit, pas des défauts.
// Toute dérive (thème clair adaptatif, locale changée, déclarations
// retirées) fait échouer l'audit.
{
  const appNatif = read("Budget/App/BudgetApp.swift");
  check("thème : identité sombre unique déclarée au niveau racine natif (.preferredColorScheme(.dark))",
    appNatif.includes(".preferredColorScheme(.dark)"));
  const formatting = read("Budget/Core/Formatting/FinanceFormatting.swift");
  check("langue : le natif formate en fr_CH (FinanceFormatting)",
    formatting.includes('Locale(identifier: "fr_CH")'));
  const pwa = read("webapp/index.html");
  check("langue : la PWA déclare lang=\"fr\" aux lecteurs d'écran",
    pwa.includes('document.documentElement.lang = "fr"'));
  check("thème : la PWA déclare son identité sombre (meta color-scheme dark)",
    pwa.includes('<meta name="color-scheme" content="dark">'));
  check("thème : aucune bascule claire adaptative dans la PWA (prefers-color-scheme absent)",
    !pwa.includes("prefers-color-scheme"));
}

// W10.8 — revue MASVS : présente, COMPLÈTE (les 24 contrôles), chaque
// contrôle porte un verdict PASS/N-A/GAP, chaque verdict cite une
// preuve ou une justification substantielle, et chaque GAP nomme le
// lot qui le porte ou le refus assumé. Un PASS d'intention est
// impossible : l'audit mord.
{
  const M = "docs/autonomie/w10/REVUE_MASVS.md";
  if (!existsSync(join(root, M))) {
    check(`revue MASVS : ${M} présente`, false);
  } else {
    const doc = read(M);
    const controles = [
      "STORAGE-1", "STORAGE-2", "CRYPTO-1", "CRYPTO-2",
      "AUTH-1", "AUTH-2", "AUTH-3", "NETWORK-1", "NETWORK-2",
      "PLATFORM-1", "PLATFORM-2", "PLATFORM-3",
      "CODE-1", "CODE-2", "CODE-3", "CODE-4",
      "RESILIENCE-1", "RESILIENCE-2", "RESILIENCE-3", "RESILIENCE-4",
      "PRIVACY-1", "PRIVACY-2", "PRIVACY-3", "PRIVACY-4",
    ];
    const manquants = [];
    const sansVerdict = [];
    const sansPreuve = [];
    const gapsFlous = [];
    for (const c of controles) {
      const ligne = doc.split("\n").find(l => l.includes(`| ${c} :`));
      if (!ligne) { manquants.push(c); continue; }
      const cellules = ligne.split("|").map(x => x.trim());
      const verdict = cellules[2] || "";
      const preuve = cellules[3] || "";
      if (!/^(PASS|N-A|GAP)$/.test(verdict)) { sansVerdict.push(c); continue; }
      if (preuve.length < 30) sansPreuve.push(c);
      if (verdict === "GAP" && !/W\d+|refus assumé/i.test(preuve)) gapsFlous.push(c);
    }
    check("revue MASVS : les 24 contrôles sont présents", manquants.length === 0, manquants.join(", "));
    check("revue MASVS : chaque contrôle porte un verdict PASS/N-A/GAP", sansVerdict.length === 0, sansVerdict.join(", "));
    check("revue MASVS : chaque verdict cite une preuve ou justification substantielle", sansPreuve.length === 0, sansPreuve.join(", "));
    check("revue MASVS : chaque GAP nomme son lot ou son refus assumé", gapsFlous.length === 0, gapsFlous.join(", "));
  }
}

// W10.1 — threat model : le document existe et couvre CHAQUE surface de
// stockage réellement présente dans le code. La liste ci-dessous est
// vérifiée des deux côtés : si le motif disparaît du code, l'entrée est
// périmée et l'audit le dit ; si la mention manque au document, l'audit
// nomme la surface oubliée. Un nouveau stockage ajouté sans passer par
// le threat model ne peut donc pas rester invisible.
{
  const TM = "docs/autonomie/w10/THREAT_MODEL.md";
  if (!existsSync(join(root, TM))) {
    check(`threat model : ${TM} présent`, false);
  } else {
    const tm = read(TM);
    const surfaces = [
      // [surface, fichier porteur, motif dans le code, mention exigée dans le doc]
      ["localStorage état", "webapp/index.html", "budget-app-state-v1", "budget-app-state-v1"],
      ["localStorage secours", "webapp/index.html", "budget-app-state-rescue", "budget-app-state-rescue"],
      ["localStorage héritage", "webapp/index.html", "budget-proto-mouvements", "budget-proto-mouvements"],
      ["IndexedDB réserve", "webapp/index.html", 'IDB_NOM = "budget-app"', "IndexedDB"],
      ["sessionStorage multi-onglets", "webapp/index.html", "budget-onglet-suivi", "budget-onglet-suivi"],
      ["cache service worker", "webapp/sw.js", "budget-app-v", "cache du service worker"],
      ["store SwiftData disque", "Budget/Core/Persistence/BudgetSchema.swift", "makeProductionContainer", "SwiftData"],
      ["pièces jointes", "Budget/Core/Security/DocumentFileStore.swift", "DocumentFileStore", "DocumentFileStore"],
      ["sauvegarde exportée", "Budget/Domain/Services/BackupService.swift", "makeBackup", "sauvegarde exportée"],
    ];
    const perimees = surfaces.filter(([, fichier, motif]) => !read(fichier).includes(motif));
    check("threat model : la liste des surfaces ne contient rien de périmé",
      perimees.length === 0, perimees.map(s => s[0]).join(", "));
    const oubliees = surfaces.filter(([, , , mention]) => !tm.includes(mention));
    check("threat model : chaque surface de stockage du code est couverte",
      oubliees.length === 0, oubliees.map(s => s[0]).join(", "));
    for (const section of ["## Actifs", "## Surfaces d'attaque", "## Menaces retenues", "## Menaces écartées"]) {
      check(`threat model : section « ${section.replace("## ", "")} » présente`, tm.includes(section));
    }
  }
}

console.log("");
if (failures > 0) {
  console.error(`AUDIT : ${failures} contrôle(s) en échec.`);
  process.exit(1);
}
console.log("AUDIT : tous les contrôles passent.");
