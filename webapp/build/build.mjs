// W9.1 — Build « à vide » (Budget Autonomie 100, Work Order W9).
// 1. Porte de TYPES : `tsc --noEmit` (version épinglée) sur webapp/src ;
//    une source cassée fait échouer le build en NOMMANT le fichier.
// 2. Artefact : webapp/dist/index.html, copie AU OCTET PRÈS du
//    monofichier servi — le comportement ne peut pas changer tant que
//    l'artefact est identique. Le monofichier reste LA source jusqu'à
//    W9.8. `--check` vérifie l'égalité et échoue à la moindre dérive.
import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const WEBAPP = path.resolve(HERE, "..");
const TSC = path.join(HERE, "node_modules", "typescript", "bin", "tsc");
const SRC = path.join(WEBAPP, "src");
const SOURCE = path.join(WEBAPP, "index.html");
const DIST_DIR = path.join(WEBAPP, "dist");
const DIST = path.join(DIST_DIR, "index.html");

if (!existsSync(TSC)) {
  console.error("build : typescript absent — lancez `npm install` dans webapp/build (version épinglée).");
  process.exit(1);
}

// 1. Porte de types — l'échec de tsc nomme les fichiers fautifs.
try {
  execFileSync("node", [TSC, "-p", path.join(SRC, "tsconfig.json"), "--noEmit", "--pretty", "false"], { encoding: "utf8" });
} catch (e) {
  console.error("build : la porte de types a mordu :");
  console.error(String(e.stdout || e.message).slice(0, 2000));
  process.exit(1);
}

// 1b. W9.2 — `--emit <dossier>` : transpiler le domaine pour les
// COMPARATEURS de tests (miroir TS ≡ monofichier). Rien de servi.
const emitIdx = process.argv.indexOf("--emit");
if (emitIdx >= 0) {
  const cible = process.argv[emitIdx + 1];
  if (!cible) { console.error("build --emit : dossier cible manquant."); process.exit(1); }
  try {
    execFileSync("node", [TSC, "-p", path.join(SRC, "tsconfig.json"),
      "--noEmit", "false", "--outDir", cible, "--module", "ES2022", "--pretty", "false"], { encoding: "utf8" });
  } catch (e) {
    console.error("build --emit : transpilation en échec :");
    console.error(String(e.stdout || e.message).slice(0, 2000));
    process.exit(1);
  }
  console.log(`build : domaine transpilé vers ${cible}.`);
  process.exit(0);
}

// 2. Artefact au octet près.
mkdirSync(DIST_DIR, { recursive: true });
const source = readFileSync(SOURCE);
writeFileSync(DIST, source);

// 3. --check : l'artefact doit être IDENTIQUE au monofichier.
if (process.argv.includes("--check")) {
  const dist = readFileSync(DIST);
  if (!source.equals(dist)) {
    console.error(`build --check : dist/index.html diffère du monofichier (${source.length} vs ${dist.length} octets).`);
    process.exit(1);
  }
}
console.log(`build : types OK, artefact ${DIST} identique au monofichier (${source.length} octets).`);
