#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, statSync } from "node:fs";
import { resolve } from "node:path";

const root = process.cwd();
const errors = [];
const notes = [];

function fail(message) {
  errors.push(message);
}

function pass(message) {
  notes.push(message);
}

function read(path) {
  return readFileSync(resolve(root, path), "utf8");
}

const requiredPaths = [
  "Budget",
  "BudgetTests",
  "BudgetUITests",
  "Budget.xcodeproj/project.pbxproj",
  "webapp",
  "webapp/tests/e2e.test.mjs",
  "webapp/tests/parity.test.mjs",
  "webapp/tests/design.test.mjs",
  "fixtures/parity-fixtures.json",
  "FINANCIAL_ENGINE_V2.md",
  ".claude/skills/budget-prisme/SKILL.md",
  ".claude/skills/README.md",
  ".github/workflows/ci.yml",
  ".github/workflows/pages.yml",
  ".github/workflows/testflight.yml",
  ".github/CODEOWNERS",
  "README.md",
  "CLAUDE.md",
  "BUDGET_1_0_READINESS.md",
  "MANUAL_QA_CHECKLIST.md",
  "APP_STORE_LISTING.md",
  "TESTFLIGHT_SETUP.md",
  "CONTRIBUTING.md",
  "SECURITY.md",
  "CHANGELOG.md",
  "docs/INDEX.md",
];

for (const path of requiredPaths) {
  if (!existsSync(resolve(root, path))) {
    fail(`Chemin requis absent : ${path}`);
  }
}

if (errors.length === 0) {
  pass(`${requiredPaths.length} chemins structurants présents`);
}

const projectPath = "Budget.xcodeproj/project.pbxproj";
if (existsSync(resolve(root, projectPath))) {
  const project = read(projectPath);
  const marketingVersions = [...project.matchAll(/MARKETING_VERSION = ([^;]+);/g)]
    .map((match) => match[1].trim());
  const buildVersions = [...project.matchAll(/CURRENT_PROJECT_VERSION = ([^;]+);/g)]
    .map((match) => match[1].trim());

  if (marketingVersions.length === 0) {
    fail("MARKETING_VERSION absent du projet Xcode");
  } else if (marketingVersions.some((version) => version !== "1.0")) {
    fail(`MARKETING_VERSION incohérente : ${[...new Set(marketingVersions)].join(", ")}`);
  } else {
    pass("MARKETING_VERSION = 1.0");
  }

  if (
    buildVersions.length === 0 ||
    buildVersions.some((version) => !/^[1-9]\d*$/.test(version))
  ) {
    fail(`CURRENT_PROJECT_VERSION invalide : ${buildVersions.join(", ") || "absent"}`);
  } else {
    pass(`CURRENT_PROJECT_VERSION numérique : ${[...new Set(buildVersions)].join(", ")}`);
  }
}

const authorityFiles = [
  ["README.md", "README"],
  ["CLAUDE.md", "CLAUDE"],
  [".claude/skills/README.md", "carte des skills"],
];

for (const [path, label] of authorityFiles) {
  if (!existsSync(resolve(root, path))) continue;
  const content = read(path);
  if (!content.includes("budget-prisme")) {
    fail(`${label} ne référence pas le skill actif budget-prisme`);
  }
}

if (existsSync(resolve(root, "README.md"))) {
  const readme = read("README.md");
  if (/Autorit[ée]s?.{0,120}budget-neon-ultra/is.test(readme)) {
    fail("README présente encore budget-neon-ultra comme autorité");
  }
}

if (existsSync(resolve(root, "CLAUDE.md"))) {
  const claude = read("CLAUDE.md");
  if (claude.includes("refonte/budget-neon-ultra-v1")) {
    fail("CLAUDE.md contient encore l’ancienne référence de publication Pages");
  }
  if (!claude.includes("BUDGET_1_0_READINESS.md")) {
    fail("CLAUDE.md ne référence pas la porte de sortie Budget 1.0");
  }
}

let trackedFiles = [];
try {
  trackedFiles = execFileSync("git", ["ls-files", "-z"], {
    cwd: root,
    encoding: "utf8",
  })
    .split("\0")
    .filter(Boolean);
} catch (error) {
  fail(`Impossible de lire les fichiers suivis par Git : ${error.message}`);
}

const forbidden = [
  { pattern: /(^|\/)\.DS_Store$/i, reason: ".DS_Store" },
  { pattern: /(^|\/)node_modules\//i, reason: "node_modules" },
  { pattern: /(^|\/)xcuserdata\//i, reason: "xcuserdata" },
  { pattern: /(^|\/)\.env(?:\.[^/]+)?$/i, reason: "fichier .env" },
  { pattern: /\.(p8|p12|cer|mobileprovision|ipa)$/i, reason: "clé/certificat/artefact iOS" },
  { pattern: /\.xcarchive(?:\/|$)/i, reason: "archive Xcode" },
];

for (const path of trackedFiles) {
  if (path.endsWith(".env.example")) continue;
  for (const rule of forbidden) {
    if (rule.pattern.test(path)) {
      fail(`Fichier interdit suivi (${rule.reason}) : ${path}`);
    }
  }
}

const privateKeyPattern =
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/;

for (const path of trackedFiles) {
  const absolute = resolve(root, path);
  if (!existsSync(absolute) || !statSync(absolute).isFile()) continue;
  if (statSync(absolute).size > 2_000_000) continue;

  let buffer;
  try {
    buffer = readFileSync(absolute);
  } catch {
    continue;
  }

  if (buffer.includes(0)) continue;
  const text = buffer.toString("utf8");
  if (privateKeyPattern.test(text)) {
    fail(`En-tête de clé privée détecté : ${path}`);
  }
}

if (trackedFiles.length > 0) {
  pass(`${trackedFiles.length} fichiers suivis inspectés pour les artefacts sensibles`);
}

console.log("Audit du dépôt Budget 1.0");
console.log("================================");

for (const message of notes) {
  console.log(`✓ ${message}`);
}

if (errors.length > 0) {
  console.error("");
  for (const message of errors) {
    console.error(`✗ ${message}`);
  }
  console.error(`\nAudit en échec : ${errors.length} problème(s).`);
  process.exit(1);
}

console.log("\nAudit vert.");
