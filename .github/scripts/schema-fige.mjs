// W10.2 — Schéma V14 FIGÉ (Budget Autonomie 100, ADR-071).
// La forme des modèles SwiftData vivants est figée dans un manifeste
// (`Budget/Core/Persistence/schema-v14-fige.json`) : classes @Model,
// propriétés STOCKÉES (avec leurs annotations @Attribute/@Relationship)
// et composition des 14 versions déclarées dans BudgetSchema.swift.
// `--check` (CI + batterie locale) recompute l'extraction depuis les
// sources et NOMME toute dérive : modifier un modèle vivant sans créer
// de nouvelle version + instantané fait échouer la porte. `--generer`
// réécrit le manifeste (à ne faire QUE lors d'un changement de version
// assumé, ADR-071).
import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const MODELES_DIR = path.join(ROOT, "Budget", "Domain", "Models");
const SCHEMA = path.join(ROOT, "Budget", "Core", "Persistence", "BudgetSchema.swift");
const MANIFESTE = path.join(ROOT, "Budget", "Core", "Persistence", "schema-v14-fige.json");

// 1. Extraction des classes @Model et de leurs propriétés STOCKÉES.
// Règles : dans le corps de classe (profondeur 1), une ligne
// `var|let nom: Type` sans `{` final est stockée ; une annotation
// @Attribute/@Relationship immédiatement au-dessus lui appartient ;
// tout ce qui est computed (`{`), static ou func est ignoré.
function extraireModeles() {
  const modeles = {};
  for (const fichier of readdirSync(MODELES_DIR).filter(f => f.endsWith(".swift")).sort()) {
    const lignes = readFileSync(path.join(MODELES_DIR, fichier), "utf8").split("\n");
    for (let i = 0; i < lignes.length; i++) {
      if (lignes[i].trim() !== "@Model") continue;
      const entete = lignes[i + 1] ?? "";
      const m = entete.match(/(?:final\s+)?class\s+(\w+)/);
      if (!m) continue;
      const nom = m[1];
      const props = [];
      let profondeur = (entete.match(/{/g) || []).length - (entete.match(/}/g) || []).length;
      let annotation = "";
      let j = i + 2;
      for (; j < lignes.length && profondeur > 0; j++) {
        const brute = lignes[j];
        const ligne = brute.trim();
        if (profondeur === 1) {
          if (/^@(Attribute|Relationship)\b/.test(ligne) && !/\b(var|let)\b/.test(ligne)) {
            annotation = ligne.replace(/\s+/g, " ");
          } else {
            const p = ligne.match(/^(?:(@(?:Attribute|Relationship)\([^)]*\))\s+)?(var|let)\s+(\w+)\s*:\s*(.+)$/);
            if (p && !ligne.endsWith("{") && !p[4].includes("{") && !ligne.startsWith("static") && !ligne.startsWith("func")) {
              const type = p[4].replace(/\s*=.*$/, "").trim();
              const anno = p[1] ? p[1].replace(/\s+/g, " ") : annotation;
              props.push(`${anno ? anno + " " : ""}${p[2]} ${p[3]}: ${type}`);
            }
            if (ligne !== "") annotation = "";
          }
        }
        profondeur += (brute.match(/{/g) || []).length - (brute.match(/}/g) || []).length;
      }
      modeles[nom] = props;
      i = j - 1;
    }
  }
  return modeles;
}

// 2. Composition des versions depuis BudgetSchema.swift (listes
// littérales `X.self` et compositions `BudgetSchemaVn.models + [...]`).
function extraireVersions() {
  const texte = readFileSync(SCHEMA, "utf8");
  const versions = {};
  const blocs = [...texte.matchAll(/enum (BudgetSchemaV\d+): VersionedSchema[\s\S]*?static var models[^{]*{([\s\S]*?)\n    }/g)];
  for (const [, nom, corps] of blocs) {
    const base = corps.match(/(BudgetSchemaV\d+)\.models/);
    const litteraux = [...corps.matchAll(/(\w+)\.self/g)].map(m => m[1]);
    versions[nom] = { base: base ? base[1] : null, ajouts: litteraux };
  }
  const resolues = {};
  const resoudre = (nom) => {
    if (resolues[nom]) return resolues[nom];
    const v = versions[nom];
    if (!v) throw new Error(`version inconnue : ${nom}`);
    resolues[nom] = [...(v.base ? resoudre(v.base) : []), ...v.ajouts];
    return resolues[nom];
  };
  for (const nom of Object.keys(versions)) resoudre(nom);
  return resolues;
}

function calculer() {
  const modeles = extraireModeles();
  const versions = extraireVersions();
  // Contrôle croisé : V14 couvre TOUTES les classes @Model des sources
  // (un modèle ajouté sans version serait invisible), et aucune version
  // ne référence une classe inconnue.
  const orphelins = Object.keys(modeles).filter(nom => !(versions.BudgetSchemaV14 ?? []).includes(nom));
  const inconnues = [...new Set(Object.values(versions).flat())].filter(nom => !modeles[nom]);
  if (orphelins.length || inconnues.length) {
    if (orphelins.length) console.error(`schéma figé : classes @Model hors de BudgetSchemaV14 — ${orphelins.join(", ")}.`);
    if (inconnues.length) console.error(`schéma figé : classes référencées par une version mais introuvables dans les sources — ${inconnues.join(", ")}.`);
    process.exit(1);
  }
  return { modeles, versions };
}

const mode = process.argv[2];
if (mode === "--generer") {
  writeFileSync(MANIFESTE, JSON.stringify(calculer(), null, 2) + "\n");
  console.log(`schéma figé : manifeste régénéré (${MANIFESTE}). À ne faire QUE lors d'un changement de version assumé (ADR-071).`);
  process.exit(0);
}

// --check (défaut) : le manifeste existe et rien n'a dérivé.
if (!existsSync(MANIFESTE)) {
  console.error("schéma figé : manifeste absent — lancez `node .github/scripts/schema-fige.mjs --generer` (ADR-071).");
  process.exit(1);
}
const fige = JSON.parse(readFileSync(MANIFESTE, "utf8"));
const actuel = calculer();
const derives = [];
for (const nom of new Set([...Object.keys(fige.modeles), ...Object.keys(actuel.modeles)])) {
  const a = JSON.stringify(fige.modeles[nom] ?? null);
  const b = JSON.stringify(actuel.modeles[nom] ?? null);
  if (a !== b) derives.push(`modèle ${nom}`);
}
for (const nom of new Set([...Object.keys(fige.versions), ...Object.keys(actuel.versions)])) {
  if (JSON.stringify(fige.versions[nom] ?? null) !== JSON.stringify(actuel.versions[nom] ?? null)) derives.push(`version ${nom}`);
}
if (derives.length) {
  console.error("schéma figé : le schéma vivant a DÉRIVÉ du manifeste V14 — " + derives.join(", ") + ".");
  console.error("Un modèle SwiftData ne se modifie pas en place : créez BudgetSchemaV15 + l'instantané figé + la migration (ADR-071), puis régénérez le manifeste.");
  process.exit(1);
}
const nb = Object.keys(actuel.modeles).length;
console.log(`schéma figé : ${nb} modèles @Model et 14 versions conformes au manifeste V14 — aucune dérive ✓`);
