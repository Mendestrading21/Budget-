/* W9.2 — Domaine « taux datés » (ADR-065/ADR-070, FI-16/17/19).
   SOURCE DE VÉRITÉ typée de la lecture des quotes datées et de la
   conversion des STOCKS au taux du mois. Ici, l'état est un PARAMÈTRE
   explicite (quotes, cache, devise de base) — aucun global. Le
   monofichier garde son exemplaire (lié à S) jusqu'au branchement
   (W9.8) ; le comparateur prouve l'identité des sorties à chaque CI. */

/** Une quote de change datée et sourcée, append-only (ADR-065). */
export interface QuoteDeChange {
  base: string;
  quote: string;
  taux: number;
  observedAt: string;
  source: string;
}

/** Cache dérivé « dernière quote par devise » (S.fxRates). */
export type CacheTaux = Record<string, number>;

const DATE_ISO = /^\d{4}-\d{2}-\d{2}$/;

/** Dernière quote consignée le jour J ou avant — null si aucune
    n'existait encore à cette date : un défaut n'est pas une mesure. */
export function tauxAuJour(
  quotes: readonly QuoteDeChange[] | null | undefined,
  base: string,
  devise: string,
  dateISO: string,
): number | null {
  if (!devise || devise === base) return 1;
  if (typeof dateISO !== "string" || !DATE_ISO.test(dateISO)) return null;
  let derniere: QuoteDeChange | null = null;
  for (const q of quotes || []) {
    if (q.quote !== devise || q.base !== base) continue;
    if (typeof q.observedAt !== "string" || q.observedAt > dateISO) continue;
    if (!derniere || q.observedAt >= derniere.observedAt) derniere = q;
  }
  return derniere && Number.isFinite(derniere.taux) && derniere.taux > 0 ? derniere.taux : null;
}

/** Taux du cache pour une devise — null si absent ou illisible,
    jamais un 1:1 inventé (FI-17). */
export function tauxDuCache(cache: CacheTaux | null | undefined, base: string, devise: string): number | null {
  if (!devise || devise === base) return 1;
  const taux = Number((cache || {})[devise]);
  return Number.isFinite(taux) && taux > 0 ? taux : null;
}

/** Conversion DATÉE d'un STOCK en fin de mois (ADR-070) : la mesure du
    moment fait foi ; avant la première mesure, la première mesure ;
    sans aucune mesure consignée, le cache actuel (comportement
    historique, consigné). null = non convertible, jamais 0 inventé. */
export function montantStockEnBase(
  quotes: readonly QuoteDeChange[] | null | undefined,
  cache: CacheTaux | null | undefined,
  base: string,
  montant: number,
  devise: string,
  y: number,
  m: number,
): number | null {
  if (!devise || devise === base) return montant;
  const finDeMois = `${y}-${String(m).padStart(2, "0")}-31`;
  let taux = tauxAuJour(quotes, base, devise, finDeMois);
  if (taux == null) {
    const premiere = (quotes || []).find(q =>
      q.quote === devise && q.base === base && Number.isFinite(q.taux) && q.taux > 0);
    taux = premiere ? premiere.taux : tauxDuCache(cache, base, devise);
  }
  return taux == null ? null : montant * taux;
}
