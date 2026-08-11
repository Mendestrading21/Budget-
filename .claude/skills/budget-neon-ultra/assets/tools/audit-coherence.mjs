// AUDIT DE COHÉRENCE — l'app parle-t-elle d'une seule voix ?
//
// Les trois outils existants mesurent la GÉOMÉTRIE (audit-total), le RENDU
// (audit-visuel) et les CHIFFRES (audit-final). Aucun ne mesure la LANGUE.
// Or c'est là que se cache le pire défaut pour un utilisateur de quinze ans :
// deux mots pour une même chose, deux emojis pour un même sens, une phrase
// de quarante mots, une question posée deux fois.
//
// Cet outil ne juge pas le goût. Il compte, compare et signale ce qui est
// mesurablement incohérent avec le reste de l'app.
//
// Données 100 % FICTIVES et déterministes (foyer « Alex », jeu de démo).
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome \
//     node .claude/skills/budget-neon-ultra/assets/tools/audit-coherence.mjs
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));
const SOURCE = fs.readFileSync(path.join(ROOT, "webapp/index.html"), "utf8");

let defauts = 0;
const signaler = (titre, lignes) => {
  defauts++;
  console.log(`\n✗ ${titre}`);
  for (const l of lignes) console.log(`    ${l}`);
};
const ok = (titre, detail) => console.log(`✓ ${titre}${detail ? ` — ${detail}` : ""}`);

/* ------------------------------------------------------------------ 1. LANGUE
   Un concept = un mot. Si l'app dit « mis de côté » ici et « épargne » là,
   l'utilisateur croit que ce sont deux choses différentes. */
const CONCEPTS = [
  {
    nom: "l'argent réservé",
    canonique: "mis de côté",
    // Variantes tolérées : conjugaisons et accords du MÊME mot.
    tolere: [/mis de côté/i, /mise de côté/i, /mettre de côté/i, /mises de côté/i],
    // Synonymes interdits dans l'interface visible.
    interdits: [/\bréserve d'argent\b/i, /\bmis en réserve\b/i, /\bprovisionn/i],
  },
  {
    nom: "ce qui sort vraiment",
    canonique: "dépensé / dépense",
    tolere: [/dépens/i],
    interdits: [/\bdébours/i, /\bsortie de fonds\b/i, /\bdécaissement/i],
  },
  {
    nom: "l'argent qui reste",
    canonique: "disponible",
    tolere: [/disponible/i],
    interdits: [/\breliquat\b/i, /\bsolde résiduel\b/i, /\breste à vivre\b/i],
  },
  {
    nom: "ce qu'on possède",
    canonique: "patrimoine",
    tolere: [/patrimoine/i],
    interdits: [/\bactif net\b/i, /\bnet worth\b/i, /\bvaleur nette\b/i],
  },
];

/* Jargon : mots qu'un adolescent ne comprend pas sans explication. */
const JARGON = [
  "amortissement", "lissé", "lissage", "provisionner", "récurrence",
  "occurrence", "matérialis", "instancier", "agrégat", "cash-flow",
  "net worth", "burn rate", "runway", "prorata", "itératif",
  "métadonnée", "sérialis", "persistance", "idempotent", "delta",
];

/* ------------------------------------------------------------------ 2. EMOJI
   Un sens = un emoji. Deux emojis pour « mettre de côté » et l'utilisateur
   ne fait plus le lien entre deux écrans. */
const SENS_EMOJI = [
  { sens: "mettre de côté", motifs: [/mettre de côté/i, /mis de côté/i] },
  { sens: "revenu", motifs: [/\bRevenu\b/] },
  { sens: "abonnement", motifs: [/\bAbonnement\b/] },
  { sens: "facture", motifs: [/\bFacture\b/] },
];
const EMOJI_RE = /(\p{Extended_Pictographic}(️|︎)?)/gu;

async function main() {
  const browser = await chromium.launch({
    executablePath: process.env.BUDGET_CHROMIUM,
    args: ["--no-sandbox"],
  });
  const page = await (await browser.newContext({
    viewport: { width: 390, height: 844 },
  })).newPage();
  const erreurs = [];
  page.on("pageerror", e => erreurs.push("PAGEERROR: " + e.message));
  page.on("console", m => { if (m.type() === "error") erreurs.push("CONSOLE: " + m.text()); });
  page.on("dialog", d => d.accept());

  await page.goto("file://" + path.join(ROOT, "webapp/index.html"));

  /* --------------------------------------------- 3. ONBOARDING : combien ?
     Le propriétaire craint « cent cinquante questions ». On compte les
     étapes RÉELLES et les champs obligatoires avant d'entrer dans l'app. */
  await page.waitForSelector('[data-obcountry="CH"]');
  const etapes = [];
  const noterEtape = async (nom) => {
    const mesure = await page.evaluate(() => {
      const s = document.getElementById("screen");
      const visible = (el) => el && el.getBoundingClientRect().height > 0;
      const champs = [...s.querySelectorAll("input, select")].filter(visible);
      const boutons = [...s.querySelectorAll("button")].filter(visible);
      const passable = boutons.some(b => /passer|plus tard|ignorer/i.test(b.textContent));
      return {
        mots: s.innerText.trim().split(/\s+/).filter(Boolean).length,
        champs: champs.length,
        boutons: boutons.length,
        passable,
      };
    });
    etapes.push({ nom, ...mesure });
  };

  await noterEtape("pays et foyer");
  await page.click('[data-obcountry="CH"]'); await page.click('[data-obhh="solo"]');
  await page.fill("#obName", "Alex"); await page.click('#obForm1 button[type="submit"]');
  await page.waitForTimeout(200); await noterEtape("salaire");
  await page.fill("#obSalary", "5200"); await page.click('#obForm2 button[type="submit"]');
  await page.waitForSelector("#obOpening", { state: "visible" });
  await noterEtape("comptes");
  await page.fill("#obOpening", "3400"); await page.click('#obForm3 button[type="submit"]');
  await page.waitForSelector("#obFormCharges", { state: "visible" });
  await noterEtape("charges");
  await page.click("[data-obskipcharges]");
  await page.waitForSelector("#obFormSubs", { state: "visible" });
  await noterEtape("abonnements");
  await page.click("[data-obskipsubs]");
  await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
  await noterEtape("objectif");
  await page.click('[data-obgoal="urgence"]');
  await page.waitForSelector("#tabbar button");

  const champsObligatoires = etapes.reduce((a, e) => a + (e.passable ? 0 : e.champs), 0);
  const detailEtapes = etapes.map(e =>
    `${e.nom} : ${e.champs} champ(s), ${e.mots} mots${e.passable ? ", passable" : ""}`);
  if (etapes.length > 8) {
    signaler(`L'accueil pose ${etapes.length} écrans avant d'entrer`, detailEtapes);
  } else {
    ok(`Accueil : ${etapes.length} écrans, ${champsObligatoires} champs vraiment obligatoires`,
       detailEtapes.join(" | "));
  }

  // Jeu de démo pour explorer des écrans remplis.
  await page.click('#tabbar button[aria-label="Gérer"]'); await page.waitForTimeout(250);
  await page.click('#screen [data-more="settings"]'); await page.waitForTimeout(250);
  await page.click("[data-resetdemo]"); await page.waitForSelector("#tabbar button");
  await page.waitForTimeout(4000);

  /* --------------------------------------------- 4. CHARGE DE TEXTE PAR ÉCRAN */
  const ECRANS = [
    ["Mois", 'activeTab="home"'],
    ["Historique", 'activeTab="tx"'],
    ["Budget", 'activeTab="budget"'],
    ["Comptes", 'activeTab="accounts"'],
    ["Gérer", 'activeTab="more";moreView=null'],
  ];
  const VUES = ["year", "subs", "bills", "recurring", "goals", "taxes",
                "networth", "insurance", "settings", "importcsv", "assistant", "movements"];

  const lourds = [];
  const phrasesLongues = [];
  const jargonTrouve = [];
  const parEcran = [];

  const mesurerEcran = async (nom) => {
    const m = await page.evaluate(() => {
      const t = document.getElementById("screen").innerText;
      const phrases = t.split(/(?<=[.!?])\s+|\n+/).map(s => s.trim()).filter(s => s.length > 12);
      const mots = t.trim().split(/\s+/).filter(Boolean).length;
      let pire = "";
      for (const p of phrases) {
        if (p.split(/\s+/).length > pire.split(/\s+/).filter(Boolean).length) pire = p;
      }
      return { mots, pire, pireMots: pire.split(/\s+/).filter(Boolean).length, texte: t };
    });
    parEcran.push({ nom, mots: m.mots, pireMots: m.pireMots });
    // Seuil : au-delà de 220 mots, l'écran se lit comme une notice.
    if (m.mots > 220) lourds.push(`${nom} : ${m.mots} mots`);
    // Une phrase de plus de 28 mots décroche un lecteur de quinze ans.
    if (m.pireMots > 28) phrasesLongues.push(`${nom} (${m.pireMots} mots) : « ${m.pire.slice(0, 110)}… »`);
    for (const j of JARGON) {
      if (new RegExp(j, "i").test(m.texte)) jargonTrouve.push(`${nom} : « ${j} »`);
    }
    for (const c of CONCEPTS) {
      for (const interdit of c.interdits) {
        if (interdit.test(m.texte)) {
          jargonTrouve.push(`${nom} : synonyme de « ${c.canonique} » → ${interdit}`);
        }
      }
    }
  };

  for (const [nom, code] of ECRANS) {
    await page.evaluate(c => { eval(c); render(); }, code);
    await page.waitForTimeout(280);
    await mesurerEcran(nom);
  }
  for (const vue of VUES) {
    await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
    await page.waitForTimeout(280);
    await mesurerEcran(vue);
  }

  if (lourds.length) signaler("Écrans qui se lisent comme une notice (> 220 mots)", lourds);
  else ok(`Charge de texte tenue sur ${parEcran.length} écrans`,
          `max ${Math.max(...parEcran.map(e => e.mots))} mots`);

  if (phrasesLongues.length) signaler("Phrases trop longues pour un lecteur de 15 ans (> 28 mots)", phrasesLongues);
  else ok("Aucune phrase au-dessus de 28 mots",
          `plus longue : ${Math.max(...parEcran.map(e => e.pireMots))} mots`);

  if (jargonTrouve.length) signaler("Jargon ou synonyme concurrent à l'écran", [...new Set(jargonTrouve)]);
  else ok("Aucun jargon ni synonyme concurrent à l'écran");

  /* --------------------------------------------- 5. UN SENS = UN EMOJI */
  const incoherences = [];
  for (const { sens, motifs } of SENS_EMOJI) {
    const trouves = new Set();
    for (const motif of motifs) {
      const re = new RegExp(`(\\p{Extended_Pictographic}(?:\\uFE0F|\\uFE0E)?)\\s*(?=[^<>]{0,4}${motif.source})`, "gu");
      for (const m of SOURCE.matchAll(re)) trouves.add(m[1]);
    }
    if (trouves.size > 1) {
      incoherences.push(`« ${sens} » porte ${trouves.size} emojis : ${[...trouves].join(" ")}`);
    }
  }
  if (incoherences.length) signaler("Un même sens porte plusieurs emojis", incoherences);
  else ok(`Un sens = un emoji sur ${SENS_EMOJI.length} concepts contrôlés`);

  /* --------------------------------------------- 6. DOUBLONS DE NAVIGATION
     Deux chemins vers le même écran, c'est utile. Deux ÉCRANS qui montrent
     la même chose, c'est un doublon qui perd l'utilisateur. */
  const empreintes = new Map();
  const destinations = await page.evaluate(() => {
    activeTab = "more"; moreView = null; render();
    return [...document.querySelectorAll("#screen [data-more]")].map(e => e.dataset.more);
  });
  for (const vue of destinations) {
    await page.evaluate(v => { activeTab = "more"; moreView = v; render(); }, vue);
    await page.waitForTimeout(240);
    const e = await page.evaluate(() => {
      const lignes = [...document.querySelectorAll("#screen .card.row .t")]
        .map(x => x.textContent.trim()).sort();
      return lignes.join("|");
    });
    if (e.length > 40) {
      if (empreintes.has(e)) {
        incoherences.push(`« ${vue} » montre exactement les mêmes lignes que « ${empreintes.get(e)} »`);
      } else empreintes.set(e, vue);
    }
  }
  const doublons = incoherences.filter(x => x.includes("mêmes lignes"));
  if (doublons.length) signaler("Deux écrans montrent la même liste", doublons);
  else ok(`Aucun écran doublon sur ${destinations.length} destinations du menu`);

  /* --------------------------------------------- 6bis. DOUBLONS DE MENU
     Deux entrées de menu qui promettent la même chose obligent l'utilisateur
     à choisir avant de comprendre. On cherche les mots-clés partagés entre
     deux entrées, et le recouvrement réel entre deux écrans de liste. */
  const menu = await page.evaluate(() => {
    activeTab = "more"; moreView = null; render();
    return [...document.querySelectorAll("#screen [data-more]")].map(el => ({
      id: el.dataset.more,
      titre: el.querySelector(".t").textContent.trim(),
      sous: el.querySelector(".s").textContent.trim(),
    }));
  });
  const MOTS_CLES = ["3e pilier", "abonnement", "facture", "épargne", "prévoyance", "impôt"];
  const partages = [];
  for (const mot of MOTS_CLES) {
    const entrees = menu.filter(m =>
      new RegExp(mot, "i").test(m.titre) || new RegExp(mot, "i").test(m.sous));
    if (entrees.length > 1) {
      partages.push(`« ${mot} » promis par ${entrees.length} entrées : ${entrees.map(e => e.titre).join(" / ")}`);
    }
  }
  if (partages.length) signaler("Deux entrées de menu promettent la même chose", partages);
  else ok(`Chaque entrée de menu promet une chose distincte (${menu.length} entrées)`);

  console.log(`  → ${menu.length} destinations dans Gérer, plus 5 onglets = ${menu.length + 5} au total`);

  /* Recouvrement réel entre écrans de liste : deux destinations qui
     montrent la même ligne obligent l'utilisateur à comprendre pourquoi. */
  const listeDe = async (vue) => page.evaluate(v => {
    activeTab = "more"; moreView = v; render();
    return [...document.querySelectorAll("#screen [data-recid]")].map(e => e.dataset.recid);
  }, vue);
  const listes = new Map();
  for (const vue of destinations) listes.set(vue, await listeDe(vue));
  const recouvrements = [];
  const noms = [...listes.keys()];
  for (let i = 0; i < noms.length; i++) {
    for (let j = i + 1; j < noms.length; j++) {
      const a2 = listes.get(noms[i]), b2 = listes.get(noms[j]);
      const communs2 = a2.filter(id => b2.includes(id));
      if (communs2.length) {
        recouvrements.push(`« ${noms[i]} » (${a2.length}) et « ${noms[j]} » (${b2.length}) partagent ${communs2.length} ligne(s)`);
      }
    }
  }
  if (recouvrements.length) signaler("Deux destinations montrent les mêmes lignes", recouvrements);
  else ok(`Aucun recouvrement entre les ${noms.length} destinations du menu`);

  /* --------------------------------------------- 7. CONSOLE */
  if (erreurs.length) signaler("Erreurs console", erreurs.slice(0, 8));
  else ok("Console propre");

  await browser.close();

  console.log(`\n${defauts ? `${defauts} FAMILLE(S) DE DÉFAUTS` : "Aucun défaut de cohérence"}`);
  console.log("Écrans mesurés : " + parEcran.map(e => `${e.nom}(${e.mots})`).join(" "));
}

await main();
