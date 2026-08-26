// W9.1 — Build TypeScript « à vide » (Budget Autonomie 100).
// Mesuré : la PWA est un monofichier sans build ni typage. Ce test
// prouve le PIPELINE avant toute extraction : l'artefact construit est
// IDENTIQUE AU OCTET PRÈS au monofichier servi (le comportement ne
// peut pas changer), le build est reproductible, et la porte de types
// MORD sur une source cassée. Le monofichier reste la source servie
// jusqu'à W9.8.
import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync, rmSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const WEBAPP = path.resolve(HERE, "..");
const BUILD = path.join(WEBAPP, "build", "build.mjs");
const DIST = path.join(WEBAPP, "dist", "index.html");
const SOURCE = path.join(WEBAPP, "index.html");

const failures = [];
const check = (ok, msg) => { if (!ok) failures.push(msg); };

if (!existsSync(BUILD)) {
  failures.push("webapp/build/build.mjs absent — aucun pipeline de build");
} else {
  // 1. Le build tourne et sort en succès.
  let sortie = "";
  let code = 0;
  try { sortie = execFileSync("node", [BUILD, "--check"], { encoding: "utf8" }); }
  catch (e) { code = e.status ?? 1; sortie = String(e.stdout || "") + String(e.stderr || ""); }
  check(code === 0, `le build --check échoue (code ${code}) : ${sortie.slice(0, 200)}`);

  // 2. L'artefact est identique AU OCTET PRÈS au monofichier servi.
  check(existsSync(DIST), "webapp/dist/index.html absent après build");
  if (existsSync(DIST)) {
    const a = readFileSync(SOURCE);
    const b = readFileSync(DIST);
    check(a.equals(b), `dist/index.html diffère du monofichier (${a.length} vs ${b.length} octets)`);
  }

  // 3. Reproductible : un second build produit les mêmes octets.
  if (code === 0 && existsSync(DIST)) {
    const avant = readFileSync(DIST);
    try { execFileSync("node", [BUILD, "--check"], { encoding: "utf8" }); } catch (e) { check(false, "second build échoue"); }
    check(avant.equals(readFileSync(DIST)), "le build n'est pas reproductible (octets différents au 2e passage)");
  }

  // 4. La porte de TYPES mord seule : une source volontairement cassée
  //    fait échouer le build avec un message nommé.
  const casse = path.join(WEBAPP, "src", "casse-temporaire.ts");
  try {
    writeFileSync(casse, "export const oups: number = \"pas un nombre\";\n");
    let aMordu = false;
    try { execFileSync("node", [BUILD, "--check"], { encoding: "utf8" }); }
    catch (e) { aMordu = true; check(String(e.stdout || "") .includes("casse-temporaire") || String(e.stderr || "").includes("casse-temporaire"), "l'échec de types ne NOMME pas le fichier fautif"); }
    check(aMordu, "la porte de types ne mord pas : une source cassée passe le build");
  } finally {
    rmSync(casse, { force: true });
  }
}

if (failures.length) {
  console.error("ÉCHECS BUILD (" + failures.length + ") :");
  for (const f of failures) console.error("  ✗ " + f);
  process.exit(1);
}
console.log("BUILD W9.1 : artefact identique au octet près, reproductible, porte de types qui mord — le monofichier reste la source servie ✓");
