// Demonstration only: fictional CHF amounts in integer centimes, no persistence.
export const families = {
  income: 'Rentrées', expense: 'Dépenses', subscription: 'Abonnements',
  savings: 'Mis de côté', transfer: 'Virement interne'
};

const transaction = (id, label, amountMinor, family, date, category, status = 'posted') => ({
  id, label, amountMinor, family, date, category, status, currency: 'CHF',
  ...(family === 'savings' ? { destination: 'savings' } : {})
});

export function createDemo() {
  return {
    '2026-09': {
      label: 'Septembre 2026', asOf: '2026-09-11', openingLiquidMinor: 780000,
      reserveIncludedMinor: 200000, savingsOpeningMinor: 1720000,
      pensionMinor: 3200000, debtMinor: 540000,
      budgets: { Logement: 145000, Quotidien: 95000, Abonnements: 20000, Famille: 140000 },
      transactions: [
        transaction('sep-salary', 'Salaire', 650000, 'income', '2026-09-02', 'Travail'),
        transaction('sep-rent', 'Loyer', 145000, 'expense', '2026-09-03', 'Logement'),
        transaction('sep-food', 'Courses de la semaine', 38510, 'expense', '2026-09-10', 'Quotidien'),
        transaction('sep-transport', 'Transports', 13000, 'expense', '2026-09-06', 'Quotidien'),
        transaction('sep-dinner', 'Restaurant', 10000, 'expense', '2026-09-08', 'Quotidien'),
        transaction('sep-music', 'Musique', 1490, 'subscription', '2026-09-05', 'Abonnements'),
        transaction('sep-cloud', 'Stockage en ligne', 1000, 'subscription', '2026-09-07', 'Abonnements'),
        transaction('sep-tools', 'Outils de travail', 15000, 'subscription', '2026-09-09', 'Abonnements'),
        transaction('sep-saving', 'Vers mon épargne', 120000, 'savings', '2026-09-04', 'Épargne'),
        transaction('sep-insurance', 'Assurance', 34000, 'expense', '2026-09-18', 'Famille', 'planned'),
        transaction('sep-charges', 'Charges du logement', 28000, 'expense', '2026-09-22', 'Logement', 'planned'),
        transaction('sep-care', 'Garde d’enfant', 86000, 'expense', '2026-09-28', 'Famille', 'planned'),
        transaction('sep-expected', 'Revenu attendu', 250000, 'income', '2026-09-25', 'Travail', 'planned')
      ]
    },
    '2026-08': {
      label: 'Août 2026', asOf: '2026-08-31', openingLiquidMinor: 710000,
      reserveIncludedMinor: 200000, savingsOpeningMinor: 1544900,
      pensionMinor: 3200000, debtMinor: 540000,
      budgets: { Logement: 145000, Quotidien: 95000, Abonnements: 20000, Famille: 140000 },
      transactions: [
        transaction('aug-salary', 'Salaire', 620000, 'income', '2026-08-02', 'Travail'),
        transaction('aug-rent', 'Loyer', 145000, 'expense', '2026-08-03', 'Logement'),
        transaction('aug-daily', 'Dépenses du quotidien', 80000, 'expense', '2026-08-20', 'Quotidien'),
        transaction('aug-family', 'Dépenses de famille', 140000, 'expense', '2026-08-24', 'Famille'),
        transaction('aug-sub', 'Abonnements', 9900, 'subscription', '2026-08-06', 'Abonnements'),
        transaction('aug-saving', 'Vers mon épargne', 175100, 'savings', '2026-08-29', 'Épargne')
      ]
    }
  };
}

function sum(values) {
  return values.reduce((a, b) => {
    const next = a + b;
    if (!Number.isSafeInteger(next)) throw new Error('Montant trop élevé pour cette démonstration.');
    return next;
  }, 0);
}

export function validDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '')) return false;
  const date = new Date(`${value}T12:00:00Z`);
  return !Number.isNaN(date.valueOf()) && date.toISOString().slice(0, 10) === value;
}

export function snapshot(data, period) {
  const m = data[period];
  if (!m) return { complete: false, issues: ['Période absente.'] };
  const issues = [];
  for (const key of ['openingLiquidMinor', 'reserveIncludedMinor', 'savingsOpeningMinor', 'pensionMinor', 'debtMinor']) {
    if (!Number.isSafeInteger(m[key])) issues.push(`Montant absent ou invalide : ${key}.`);
  }
  const ids = new Set();
  for (const row of m.transactions) {
    if (ids.has(row.id)) issues.push('Identifiant d’opération dupliqué.');
    ids.add(row.id);
    if (row.currency !== 'CHF') issues.push('Conversion manquante : cette référence ne consolide que le CHF.');
    if (!Number.isSafeInteger(row.amountMinor) || row.amountMinor < 0) issues.push('Montant d’opération absent ou invalide.');
    if (!Object.hasOwn(families, row.family) || !['planned', 'posted'].includes(row.status)) issues.push('Type ou statut inconnu.');
    if (row.family === 'savings' && row.destination !== 'savings') issues.push('Destination de mise de côté inconnue.');
    if (!validDate(row.date) || !row.date.startsWith(period)) issues.push('Date ou période invalide.');
    if (row.status === 'posted' && (row.postedDate || row.date) > m.asOf) issues.push('Opération comptabilisée après la date observée.');
  }
  if (issues.length) return { complete: false, issues: [...new Set(issues)] };
  try {
    const posted = m.transactions.filter(row => row.status === 'posted');
    const totals = Object.fromEntries(Object.keys(families).map(key => [key, sum(posted.filter(row => row.family === key).map(row => row.amountMinor))]));
    const spent = sum([totals.expense, totals.subscription]);
    const dueRows = m.transactions.filter(row => row.status === 'planned' && ['expense', 'subscription'].includes(row.family)).sort((a, b) => a.date.localeCompare(b.date));
    const due = sum(dueRows.map(row => row.amountMinor));
    const liquid = sum([m.openingLiquidMinor, totals.income, -spent, -totals.savings]);
    const savings = sum([m.savingsOpeningMinor, totals.savings]);
    const available = sum([liquid, -due, -m.reserveIncludedMinor]);
    const netWorth = sum([liquid, savings, m.pensionMinor, -m.debtMinor]);
    const categoryTotals = Object.fromEntries(Object.keys(m.budgets).map(category => [category, sum(posted.filter(row => ['expense', 'subscription'].includes(row.family) && row.category === category).map(row => row.amountMinor))]));
    const budget = sum(Object.values(m.budgets));
    return { complete: true, totals, spent, dueRows, due, liquid, savings, available, netWorth, posted, categoryTotals, budget, budgetRemaining: budget - spent };
  } catch (error) {
    return { complete: false, issues: [error.message] };
  }
}

export function pay(data, period, id) {
  const m = data[period];
  const row = m?.transactions.find(item => item.id === id);
  if (!row || !['expense', 'subscription'].includes(row.family)) throw new Error('Échéance introuvable.');
  if (row.status === 'posted') return false;
  if (!snapshot(data, period).complete) throw new Error('Corriger les données avant ce paiement.');
  row.status = 'posted';
  row.postedDate = m.asOf;
  return true;
}

export function parseMoney(value) {
  const text = String(value).trim();
  if (!/^\d+(?:[.,]\d{1,2})?$/.test(text)) throw new Error('Saisis un montant positif, avec deux décimales au maximum.');
  const [whole, decimal = ''] = text.replace(',', '.').split('.');
  const amount = Number(whole) * 100 + Number(decimal.padEnd(2, '0'));
  if (!Number.isSafeInteger(amount) || amount <= 0 || amount > 999999999) throw new Error('Saisis un montant entre 0,01 et 9’999’999,99 CHF.');
  return amount;
}

export function addTransaction(data, period, input) {
  const m = data[period];
  if (!m) throw new Error('Période absente.');
  const label = String(input.label || '').trim();
  if (!label || label.length > 80) throw new Error('Indique un libellé de 1 à 80 caractères.');
  if (!['expense', 'income'].includes(input.family)) throw new Error('Choisis une dépense ou une rentrée.');
  if (!validDate(input.date) || !input.date.startsWith(period) || input.date > m.asOf) throw new Error(`Choisis une date de ce mois, au plus tard le ${m.asOf}.`);
  if (!input.id || m.transactions.some(row => row.id === input.id)) throw new Error('Identifiant absent ou déjà utilisé.');
  const row = transaction(input.id, label, parseMoney(input.amount), input.family, input.date, input.family === 'income' ? 'Travail' : 'Quotidien');
  m.transactions.push(row);
  return row;
}
