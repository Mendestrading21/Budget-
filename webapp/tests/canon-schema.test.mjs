/* W1.1 (ADR-059) — Contrat du schéma des fixtures canoniques.
   Node seul, aucune dépendance. Valide que CHAQUE fixture de
   fixtures/canon/ respecte le schéma version 1 : montants en unités
   mineures ENTIÈRES, devises ISO, dates ISO, états du glossaire W0,
   références de comptes résolues, identifiants uniques, taux datés et
   sourcés. Un champ inconnu ou un montant à virgule est un ÉCHEC —
   aucun repli silencieux (FI-34). */
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = resolve(fileURLToPath(import.meta.url), "..");
const ROOT = resolve(HERE, "..", "..");
const CANON_DIR = join(ROOT, "fixtures", "canon");
const SCHEMA_DOC = join(CANON_DIR, "SCHEMA.md");

const failures = [];
const check = (ok, label) => { if (!ok) failures.push(label); };

// Le contrat de W0 (glossaire, dictionnaire) fixe ces vocabulaires.
const ETATS = new Set(["planned", "posted"]);
const TYPES = new Set(["income", "refund", "expense", "saving", "investment",
  "transfer", "taxPayment", "debtPayment", "adjustment"]);
const GENRES_COMPTE = new Set(["current", "cash", "savings", "brokerage",
  "pension", "lifeinsurance"]);
const RYTHMES = new Set(["month", "quarter", "semester", "year", "week",
  "twoWeeks", "fourWeeks"]);
const DEVISE = /^[A-Z]{3}$/;
const DATE_ISO = /^\d{4}-\d{2}-\d{2}$/;

const estEntierSur = (v) => Number.isSafeInteger(v);

function valideFixture(nomFichier, f) {
  const où = (msg) => `${nomFichier} : ${msg}`;
  check(f.version === 1, où("version doit être exactement 1"));
  check(typeof f.nom === "string" && f.nom.length > 0, où("nom obligatoire"));
  check(typeof f.description === "string" && f.description.length > 0, où("description obligatoire"));
  const e = f.entrees;
  check(e && typeof e === "object", où("bloc entrees obligatoire"));
  if (!e) return;
  check(DEVISE.test(e.deviseBase || ""), où("deviseBase ISO obligatoire"));
  check(DATE_ISO.test(e.date || ""), où("date de référence ISO obligatoire"));

  const idsComptes = new Set();
  for (const c of e.comptes || []) {
    check(typeof c.id === "string" && !idsComptes.has(c.id), où(`compte « ${c.id} » : id unique obligatoire`));
    idsComptes.add(c.id);
    check(GENRES_COMPTE.has(c.genre), où(`compte « ${c.id} » : genre inconnu « ${c.genre} »`));
    check(DEVISE.test(c.devise || ""), où(`compte « ${c.id} » : devise ISO obligatoire`));
    check(estEntierSur(c.ouvertureMineures), où(`compte « ${c.id} » : ouvertureMineures doit être un entier (unités mineures, ADR-059)`));
    check(typeof c.cash === "boolean" && typeof c.patrimoine === "boolean", où(`compte « ${c.id} » : cash et patrimoine booléens obligatoires`));
  }
  check((e.comptes || []).length > 0, où("au moins un compte"));

  const idsMouvements = new Set();
  for (const m of e.mouvements || []) {
    check(typeof m.id === "string" && !idsMouvements.has(m.id), où(`mouvement « ${m.id} » : id unique obligatoire`));
    idsMouvements.add(m.id);
    check(DATE_ISO.test(m.date || ""), où(`mouvement « ${m.id} » : date ISO obligatoire`));
    check(TYPES.has(m.type), où(`mouvement « ${m.id} » : type inconnu « ${m.type} »`));
    check(ETATS.has(m.statut), où(`mouvement « ${m.id} » : statut inconnu « ${m.statut} » (glossaire W0)`));
    check(estEntierSur(m.montantMineures) && m.montantMineures > 0, où(`mouvement « ${m.id} » : montantMineures doit être un entier positif (ADR-059)`));
    check(idsComptes.has(m.compte), où(`mouvement « ${m.id} » : compte « ${m.compte} » introuvable`));
    if (m.destination != null) check(idsComptes.has(m.destination), où(`mouvement « ${m.id} » : destination « ${m.destination} » introuvable`));
    // Règles produit mesurées (tests natifs) : l'argent ne disparaît jamais.
    if (m.type === "transfer" || m.type === "saving") check(typeof m.destination === "string", où(`mouvement « ${m.id} » : un ${m.type === "transfer" ? "virement" : "« mis de côté »"} exige une destination — l'argent ne disparaît pas`));
    if (m.type === "transfer") check(m.destination !== m.compte, où(`mouvement « ${m.id} » : un virement exige une destination DISTINCTE`));
    if (m.type === "adjustment") check(typeof m.hausse === "boolean", où(`mouvement « ${m.id} » : un ajustement porte hausse (booléen)`));
    check(typeof m.titre === "string" && m.titre.length > 0, où(`mouvement « ${m.id} » : titre obligatoire`));
    // W1.5 : un mouvement peut couvrir une échéance récurrente déclarée.
    if (m.recurrence != null) check((e.recurrences || []).some(r => r.id === m.recurrence), où(`mouvement « ${m.id} » : récurrence « ${m.recurrence} » introuvable`));
  }

  for (const r of e.recurrences || []) {
    check(typeof r.id === "string", où("récurrence : id obligatoire"));
    check(TYPES.has(r.type), où(`récurrence « ${r.id} » : type inconnu`));
    check(estEntierSur(r.montantMineures) && r.montantMineures > 0, où(`récurrence « ${r.id} » : montantMineures entier positif`));
    check(RYTHMES.has(r.rythme), où(`récurrence « ${r.id} » : rythme inconnu « ${r.rythme} »`));
    check(Number.isInteger(r.jour) && r.jour >= 1 && r.jour <= 31, où(`récurrence « ${r.id} » : jour 1–31`));
    check(idsComptes.has(r.compte), où(`récurrence « ${r.id} » : compte introuvable`));
  }

  for (const t of e.taux || []) {
    check(DEVISE.test(t.base || "") && DEVISE.test(t.cote || ""), où("taux : base et cote ISO"));
    check(typeof t.taux === "string" && /^\d+(\.\d+)?$/.test(t.taux), où("taux : valeur décimale en CHAÎNE (jamais un flottant binaire)"));
    check(DATE_ISO.test(t.date || ""), où("taux : date obligatoire (FI-16)"));
    check(typeof t.source === "string" && t.source.length > 0, où("taux : source obligatoire (FI-16)"));
  }

  const a = f.attendus;
  check(a && typeof a === "object", où("bloc attendus obligatoire"));
  if (!a) return;
  check(a.soldesMineures && typeof a.soldesMineures === "object", où("attendus.soldesMineures obligatoire"));
  for (const [cid, v] of Object.entries(a.soldesMineures || {})) {
    check(idsComptes.has(cid), où(`attendus : solde d'un compte introuvable « ${cid} »`));
    check(estEntierSur(v), où(`attendus : solde « ${cid} » doit être un entier (ADR-059)`));
  }
  if (a.mois) {
    for (const champ of ["recuMineures", "depenseMineures", "misDeCoteMineures", "liquideMineures", "finDeMoisMineures"]) {
      if (a.mois[champ] !== undefined) check(estEntierSur(a.mois[champ]), où(`attendus.mois.${champ} doit être un entier`));
    }
    check(Number.isInteger(a.mois.annee) && Number.isInteger(a.mois.mois), où("attendus.mois : annee et mois entiers obligatoires"));
  }
  if (a.patrimoine) {
    for (const champ of ["fortuneTotaleMineures", "epargneAccessibleMineures"]) {
      if (a.patrimoine[champ] !== undefined) check(estEntierSur(a.patrimoine[champ]), où(`attendus.patrimoine.${champ} doit être un entier`));
    }
  }
}

// 1. Le contrat écrit existe.
check(existsSync(SCHEMA_DOC), "fixtures/canon/SCHEMA.md manquant — le contrat W1.1 doit être écrit");

// 2. Au moins une fixture d'exemple existe et TOUTES valident.
const fichiers = existsSync(CANON_DIR)
  ? readdirSync(CANON_DIR).filter(n => n.endsWith(".json"))
  : [];
check(fichiers.length >= 1, "fixtures/canon/ doit contenir au moins une fixture .json");
for (const nom of fichiers) {
  let contenu;
  try { contenu = JSON.parse(readFileSync(join(CANON_DIR, nom), "utf8")); }
  catch (err) { check(false, `${nom} : JSON invalide (${err.message})`); continue; }
  valideFixture(nom, contenu);
}

if (failures.length) {
  console.error("ÉCHECS SCHÉMA CANON (" + failures.length + ") :");
  for (const f of failures) console.error("  ✗ " + f);
  process.exit(1);
}
console.log(`SCHÉMA CANON : ${fichiers.length} fixture(s) conformes au contrat version 1 — unités mineures entières, devises et dates ISO, états du glossaire, taux datés et sourcés ✓`);
