// AUDIT FINAL — ce que les autres outils ne mesurent pas.
//
// `audit-total.mjs` mesure la géométrie (alignement, rayons, contrastes,
// cibles, débordement). `audit-visuel.mjs` mesure les pastilles d'icône.
// Il restait trois familles de défauts invisibles à tous les deux :
//
//   1. ÉMOJIS — un emoji peut s'afficher en NOIR ET BLANC si la police de
//      secours prend la main. À l'œil sur une capture, on ne le voit pas
//      toujours ; à l'écran d'un vrai iPhone, si. On teste la seule chose
//      qui tranche : un emoji COULEUR ignore `color`, un glyphe texte le
//      suit. On dessine donc chaque glyphe deux fois, en rouge puis en
//      bleu, et on compare les pixels.
//   2. ÉMOJIS ET VOIX — un emoji décoratif non masqué se fait lire à voix
//      haute (« sac d'argent »), ce que personne n'a demandé.
//   3. GRAPHIQUES — un graphique peut être joli et MENTIR. On recalcule
//      chaque valeur depuis l'état et on la compare au dessin.
//
// Données 100 % FICTIVES et déterministes (jeu de démonstration).
//
// Usage :
//   BUDGET_CHROMIUM=/chemin/vers/chrome \
//     node .claude/skills/budget-neon-ultra/assets/tools/audit-final.mjs
import path from "node:path";
import { fileURLToPath } from "node:url";
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../..");
const { chromium } = await import(path.join(ROOT, "webapp/tests/node_modules/playwright-core/index.mjs"));

const browser = await chromium.launch({ executablePath: process.env.BUDGET_CHROMIUM, args: ["--no-sandbox"] });
const page = await (await browser.newContext({ viewport: { width: 390, height: 844 } })).newPage();
const erreurs = [];
page.on("pageerror", e => erreurs.push("PAGEERROR: " + e.message));
page.on("console", m => { if (m.type() === "error") erreurs.push("CONSOLE: " + m.text()); });
page.on("dialog", d => d.accept());

await page.goto("file://" + path.join(ROOT, "webapp/index.html"));
await page.waitForSelector('[data-obcountry="CH"]');
await page.click('[data-obcountry="CH"]'); await page.click('[data-obhh="solo"]');
await page.fill("#obName", "Alex"); await page.click('#obForm1 button[type="submit"]');
await page.fill("#obSalary", "5200"); await page.click('#obForm2 button[type="submit"]');
await page.waitForSelector("#obOpening", { state: "visible" });
await page.fill("#obOpening", "3400"); await page.click('#obForm3 button[type="submit"]');
await page.waitForSelector("#obFormCharges", { state: "visible" });
await page.click("[data-obskipcharges]");
await page.waitForSelector("#obFormSubs", { state: "visible" });
await page.click("[data-obskipsubs]");
await page.waitForSelector('[data-obgoal="urgence"]', { state: "visible" });
await page.click('[data-obgoal="urgence"]');
await page.waitForSelector("#tabbar button");
// Jeu de démonstration : plus riche, donc plus de graphiques à contrôler.
await page.click('#tabbar button[aria-label="Gérer"]'); await page.waitForTimeout(250);
await page.click('#screen [data-more="settings"]'); await page.waitForTimeout(250);
await page.click("[data-resetdemo]"); await page.waitForSelector("#tabbar button");
await page.waitForTimeout(6500);

const defauts = [];
const ok = [];
const verifier = (condition, titre, detail = "") => {
  (condition ? ok : defauts).push(detail ? `${titre} — ${detail}` : titre);
};

const ECRANS = [
  ["Mois", 'activeTab="home";moreView=null'],
  ["Historique", 'activeTab="movements";moreView=null'],
  ["Budget", 'activeTab="budget";moreView=null'],
  ["Comptes", 'activeTab="accounts";moreView=null'],
  ["Gérer", 'activeTab="more";moreView=null'],
];
const VUES = ["year", "subs", "bills", "recurring", "goals", "taxes",
              "networth", "insurance", "settings", "importcsv", "assistant"];

const aller = async (code) => {
  await page.evaluate(c => { eval(c); render(); }, code);
  await page.waitForTimeout(300);
};

// ---------------------------------------------------------------- ÉMOJIS
// Le relevé : tout caractère hors du plan latin, avec sa police effective,
// s'il est masqué à la voix, et où il se trouve.
const releverEmojis = () => page.evaluate(() => {
  const EMOJI = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{1F1E6}-\u{1F1FF}]/u;
  const s = document.getElementById("screen");
  const vus = [];
  const parcourir = (n) => {
    if (n.nodeType === 3) {
      const t = n.textContent;
      if (!EMOJI.test(t)) return;
      const el = n.parentElement;
      const b = el.getBoundingClientRect();
      // « Masqué à la voix » : soi-même ou n'importe quel ancêtre.
      let masque = false, p = el;
      while (p && p !== document.body) {
        if (p.getAttribute("aria-hidden") === "true") { masque = true; break; }
        p = p.parentElement;
      }
      // Le glyphe est-il SEUL dans son élément ? Si oui, il ne peut pas
      // porter du sens à lui tout seul sans être annoncé autrement.
      const seul = (el.textContent || "").replace(/[\s\u{FE0E}\u{FE0F}]/gu, "").length
        <= [...t.replace(/[\s\u{FE0E}\u{FE0F}]/gu, "")].length;
      // On garde la SÉQUENCE telle qu'elle est écrite (glyphe + sélecteur,
      // paire d'indicateurs régionaux pour un drapeau) : tester un demi-
      // drapeau ou un sélecteur seul n'a aucun sens, et c'est ce que faisait
      // la première version — elle accusait ⚙️ et ☁️ d'être en noir et blanc
      // alors qu'ils portaient déjà leur sélecteur couleur.
      const sequences = t.match(/\p{RI}\p{RI}|\p{Extended_Pictographic}[\u{FE0E}\u{FE0F}]?/gu) || [];
      for (const g of sequences) {
        vus.push({
          glyphe: g,
          police: getComputedStyle(el).fontFamily,
          taille: getComputedStyle(el).fontSize,
          masque, seul,
          etiquette: el.getAttribute("aria-label")
            || (el.closest("[aria-label]") || {}).getAttribute?.("aria-label") || null,
          visible: b.width > 0 && b.height > 0,
          balise: el.tagName + (el.className ? "." + String(el.className).split(" ")[0] : ""),
        });
      }
      return;
    }
    if (n.nodeType === 1) {
      if (n.tagName === "SCRIPT" || n.tagName === "STYLE") return;
      for (const enfant of n.childNodes) parcourir(enfant);
    }
  };
  parcourir(s);
  return vus;
});

// La preuve : un emoji COULEUR ignore `color`, un glyphe texte le suit.
const sontEnCouleur = (glyphes, police) => page.evaluate(([liste, font]) => {
  const c = document.createElement("canvas");
  c.width = 48; c.height = 48;
  const ctx = c.getContext("2d", { willReadFrequently: true });
  const rendre = (g, couleur) => {
    ctx.clearRect(0, 0, 48, 48);
    ctx.font = `32px ${font}`;
    ctx.fillStyle = couleur;
    ctx.textBaseline = "middle";
    ctx.fillText(g, 4, 24);
    return ctx.getImageData(0, 0, 48, 48).data;
  };
  return liste.map(g => {
    const rouge = rendre(g, "#ff0000");
    const bleu = rendre(g, "#0000ff");
    let differents = 0, dessines = 0;
    for (let i = 0; i < rouge.length; i += 4) {
      if (rouge[i + 3] > 8) dessines++;
      if (Math.abs(rouge[i] - bleu[i]) > 24 || Math.abs(rouge[i + 2] - bleu[i + 2]) > 24) differents++;
    }
    // Dessiné et INSENSIBLE à la couleur demandée = emoji couleur.
    return { glyphe: g, dessine: dessines > 0, couleur: dessines > 0 && differents === 0 };
  });
}, [glyphes, police]);

console.log("############ ÉMOJIS ############");
const tousEmojis = new Map();
for (const [nom, code] of [...ECRANS, ...VUES.map(v => [v, `activeTab="more";moreView="${v}"`])]) {
  await aller(code);
  for (const e of await releverEmojis()) {
    if (!tousEmojis.has(e.glyphe)) tousEmojis.set(e.glyphe, []);
    tousEmojis.get(e.glyphe).push({ ...e, ecran: nom });
  }
}
const glyphes = [...tousEmojis.keys()];
const police = await page.evaluate(() => {
  const ico = document.querySelector(".ico") || document.body;
  return getComputedStyle(ico).fontFamily;
});
const rendus = await sontEnCouleur(glyphes, police);
const noirEtBlanc = rendus.filter(r => r.dessine && !r.couleur && !r.glyphe.includes("\uFE0E"));
const texteVoulu = rendus.filter(r => r.glyphe.includes("\uFE0E"));
const invisibles = rendus.filter(r => !r.dessine);
console.log(`${glyphes.length} glyphes distincts : ${glyphes.join(" ")}`);
verifier(invisibles.length === 0, "aucun glyphe ne rend une case vide",
  invisibles.map(r => r.glyphe).join(" "));
console.log(`${texteVoulu.length} glyphes en présentation TEXTE assumée (︎) : ${texteVoulu.map(r => r.glyphe).join(" ")}`);
verifier(noirEtBlanc.length === 0, "tout emoji COULEUR le dit explicitement — rien n'est laissé à la police de l'appareil",
  noirEtBlanc.map(r => r.glyphe).join(" "));

const bavards = [];
for (const [g, occurrences] of tousEmojis) {
  for (const o of occurrences) {
    // Un emoji DÉCORATIF et SEUL, non masqué et sans étiquette : la voix
    // le lira, alors qu'il ne dit rien que le texte à côté ne dise déjà.
    if (o.seul && !o.masque && !o.etiquette) bavards.push(`${g} (${o.ecran}, ${o.balise})`);
  }
}
verifier(bavards.length === 0,
  "aucun emoji décoratif n'est lu à voix haute sans être annoncé",
  bavards.slice(0, 6).join(" · "));

// ------------------------------------------------------------ GRAPHIQUES
console.log("\n############ GRAPHIQUES ET DONNÉES ############");

// 1. Anneau du Budget : le pourcentage écrit doit être celui des deux
//    montants écrits juste à côté — et le « dépensé » doit être le vrai.
//    La première version divisait par TOUTES les lignes de budget, épargne,
//    3e pilier et impôts compris. Elle trouvait 57 % là où l'app écrit 86 %,
//    et l'app avait raison : mettre de côté n'est pas une dépense de vie.
//    Un audit qui crie au loup est pire qu'aucun audit.
await aller('activeTab="budget";moreView=null');
const anneau = await page.evaluate(() => {
  const s = document.getElementById("screen");
  const carte = (s.querySelector("svg") || {}).closest?.(".card") || s;
  const txt = carte.innerText.replace(/\u00a0/g, " ");
  const pct = /utilisé\s+(\d+)\s*%/.exec(txt);
  const montants = [...txt.matchAll(/(Prévu|dépensé)\s+[A-Z]{0,3}\s*([\d'’]+\.\d\d)/gi)]
    .map(m => [m[1].toLowerCase(), Number(m[2].replace(/['’]/g, ""))]);
  const prevu = (montants.find(m => m[0] === "prévu") || [])[1];
  const depense = (montants.find(m => m[0] === "dépensé") || [])[1];
  return {
    ecrit: pct ? Number(pct[1]) : null, prevu, depense,
    coherent: prevu > 0 ? Math.round(depense / prevu * 100) : null,
    vraiDepense: Math.round(snapshot(cursor.y, cursor.m).living * 100) / 100,
  };
});
verifier(anneau.ecrit !== null && anneau.coherent !== null
  && Math.abs(anneau.ecrit - anneau.coherent) <= 1,
  "l'anneau du Budget : le % écrit est bien celui de ses deux montants",
  `écrit ${anneau.ecrit} %, ${anneau.depense} sur ${anneau.prevu} = ${anneau.coherent} %`);
verifier(anneau.depense !== undefined && Math.abs(anneau.depense - anneau.vraiDepense) < 0.02,
  "l'anneau du Budget : le « dépensé » est la vraie dépense de vie du mois",
  `affiché ${anneau.depense}, recalculé ${anneau.vraiDepense}`);

// 2. Barres des abonnements : la LARGEUR doit valoir le pourcentage écrit.
await aller('activeTab="more";moreView="subs"');
const barres = await page.evaluate(() => {
  return [...document.querySelectorAll(".sub-share")].map(bloc => {
    const piste = bloc.querySelector(".sub-share-track");
    const barre = piste.querySelector("span");
    const ecrit = Number((bloc.querySelector(".sub-share-pct").textContent || "").replace(/\D/g, ""));
    const largeur = piste.getBoundingClientRect().width;
    const dessine = barre.getBoundingClientRect().width;
    return { ecrit, dessinePct: largeur > 0 ? Math.round(dessine / largeur * 100) : null };
  });
});
const barresFausses = barres.filter(b => b.dessinePct === null || Math.abs(b.dessinePct - b.ecrit) > 3);
verifier(barres.length > 0 && barresFausses.length === 0,
  `les ${barres.length} barres d'abonnement sont dessinées à leur vraie proportion`,
  barresFausses.map(b => `écrit ${b.ecrit} % / dessiné ${b.dessinePct} %`).join(" · "));

// 3. Page Année : chaque mois écrit doit valoir le calcul de ce mois.
await aller('activeTab="more";moreView="year"');
const annee = await page.evaluate(() => {
  const cellules = [...document.querySelectorAll("#screen [data-gotomonth]")];
  return {
    nb: cellules.length,
    faux: cellules.map(c => {
      const m = Number(c.dataset.gotomonth.split("-")[1]);
      const attendu = snapshot(Number(c.dataset.gotomonth.split("-")[0]), m).cashFlow;
      const ecrit = (c.innerText.match(/-?[\d'’]+\.\d\d/g) || [])
        .map(v => Number(v.replace(/['’]/g, "")));
      // Le mois est correct si l'un des montants écrits est le sien.
      // Un mois sans aucun mouvement écrit « Vide », pas « 0.00 » — et
      // c'est mieux : zéro franc et rien du tout ne veulent pas dire la
      // même chose. La première version le comptait comme une erreur.
      const vide = /vide|aucun mouvement|à venir|rien d'enregistré/i.test(c.innerText);
      if (vide) return Math.abs(attendu) < 0.02 ? null : { m, attendu, ecrit: "« Vide » alors qu'il y a un résultat" };
      const trouve = ecrit.some(v => Math.abs(Math.abs(v) - Math.abs(attendu)) < 0.02);
      return trouve ? null : { m, attendu, ecrit };
    }).filter(Boolean),
  };
});
verifier(annee.nb === 12 && annee.faux.length === 0,
  `la page Année montre 12 mois, chacun avec son VRAI résultat (${annee.nb} cellules)`,
  annee.faux.map(f => `mois ${f.m} : attendu ${f.attendu}, écrit ${f.ecrit}`).join(" · "));

// 4. Héros qui tourne : chaque carte doit valoir son recalcul indépendant.
await aller('activeTab="home";moreView=null');
const heros = await page.evaluate(() => {
  const lire = cle => {
    const c = document.querySelector(`[data-heroslide="${cle}"]`);
    if (!c) return null;
    const m = (c.querySelector(".hero-amount").textContent.match(/-?[\d'’]+\.\d\d/) || [])[0];
    return m ? Number(m.replace(/['’]/g, "")) : null;
  };
  const cents = v => Math.round(v * 100);
  const placements = ACCOUNTS.filter(a => ["savings", "brokerage"].includes(a.kind))
    .reduce((s, a) => s + cents(toCHF(balance(a.id), a.currency)), 0);
  const prevoyance = ACCOUNTS.filter(a => ["pension", "lifeinsurance"].includes(a.kind))
      .reduce((s, a) => s + cents(toCHF(balance(a.id), a.currency)), 0)
    + PENSIONS.reduce((s, p) => s + cents(p.value), 0);
  const liquide = ACCOUNTS.filter(a => a.cash)
    .reduce((s, a) => s + cents(toCHF(balance(a.id), a.currency)), 0);
  const biens = ASSETS.filter(x => x.include !== false).reduce((s, x) => s + cents(x.value), 0);
  const snap = snapshot(cursor.y, cursor.m);
  return {
    disponible: [lire("disponible"), Math.round(snap.available * 100) / 100],
    misdecote: [lire("misdecote"), Math.round((snap.savings + snap.invest) * 100) / 100],
    placements: [lire("placements"), placements / 100],
    prevoyance: [lire("prevoyance"), prevoyance / 100],
    patrimoine: [lire("patrimoine"),
      (liquide + placements + prevoyance + biens - cents(liabilitiesTotal())) / 100],
  };
});
for (const [cle, [ecrit, attendu]] of Object.entries(heros)) {
  verifier(ecrit !== null && Math.abs(ecrit - attendu) < 0.02,
    `héros « ${cle} » : le montant affiché est le montant calculé`,
    `affiché ${ecrit}, recalculé ${attendu}`);
}

// 5. Tuile « À payer » = la somme de ce qui reste réellement dû.
const aPayer = await page.evaluate(() => {
  const tuiles = [...document.querySelectorAll(".home-metrics .stat")];
  const t = tuiles.find(x => /À payer/i.test(x.textContent));
  const m = t ? (t.textContent.match(/[\d'’]+\.\d\d/) || [])[0] : null;
  const snap = snapshot(cursor.y, cursor.m);
  return {
    ecrit: m ? Number(m.replace(/['’]/g, "")) : null,
    attendu: Math.round((snap.plannedOut + snap.recurringCharges + snap.taxGap) * 100) / 100,
  };
});
verifier(aPayer.ecrit !== null && Math.abs(aPayer.ecrit - aPayer.attendu) < 0.02,
  "tuile « À payer » : le montant affiché est le montant calculé",
  `affiché ${aPayer.ecrit}, recalculé ${aPayer.attendu}`);

// 6. Répartition des Comptes : les parts doivent totaliser 100 % et
//    correspondre aux soldes.
await aller('activeTab="accounts";moreView=null');
const repartition = await page.evaluate(() => {
  const lignes = [...document.querySelectorAll("#screen .breakdown div, #screen .compo-row")];
  const pourcents = lignes.map(l => {
    const m = /(\d+)\s*%/.exec(l.textContent);
    return m ? Number(m[1]) : null;
  }).filter(v => v !== null);
  return { nb: pourcents.length, somme: pourcents.reduce((a, b) => a + b, 0) };
});
verifier(repartition.nb === 0 || Math.abs(repartition.somme - 100) <= 2,
  "la répartition des comptes totalise 100 %",
  `${repartition.nb} parts, somme ${repartition.somme} %`);

// ------------------------------------------------------------- RAPPORT
console.log("\n############ RÉSULTAT ############");
for (const l of ok) console.log("  ✓ " + l);
for (const l of defauts) console.log("  ✗ " + l);
console.log(erreurs.length ? "ERREURS CONSOLE : " + erreurs.join(" | ") : "console propre");
console.log(defauts.length
  ? `\n${defauts.length} défaut(s) à corriger`
  : `\nAucun défaut — ${ok.length} contrôles passés`);
await browser.close();
process.exit(defauts.length ? 1 : 0);
