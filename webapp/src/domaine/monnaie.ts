/* W9.2 — Domaine « monnaie » : unités mineures (G01).
   SOURCE DE VÉRITÉ typée du trio centimes/francs/arrondi. Le
   monofichier garde son exemplaire jusqu'au branchement (W9.8) ; le
   comparateur webapp/tests/domaine.test.mjs prouve à chaque CI que les
   deux produisent EXACTEMENT les mêmes sorties — toute dérive est un
   échec nommé. Ne modifier l'un sans l'autre est donc impossible en
   silence. */

/** Francs (ou valeur composée) → centimes entiers ; illisible → 0. */
export function toCents(x: unknown): number {
  const value = Number(x);
  return x != null && Number.isFinite(value) ? Math.round(value * 100) : 0;
}

/** Centimes entiers → francs. */
export function fromCents(c: number): number { return c / 100; }

/** Arrondi au centime d'une valeur composée. */
export function round2(x: number): number { return fromCents(toCents(x)); }
