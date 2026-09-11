import assert from 'node:assert/strict';
import { createDemo, snapshot, pay, addTransaction, parseMoney } from '../assets/reference-model.mjs';

let checks = 0;
function check(name, run) { run(); checks += 1; console.log(`OK ${name}`); }
const period = '2026-09';

check('Les champs fictifs se réconcilient sans le revenu prévu', () => {
  const s = snapshot(createDemo(), period);
  assert.equal(s.complete, true);
  assert.deepEqual(s.totals, { income: 650000, expense: 206510, subscription: 17490, savings: 120000, transfer: 0 });
  assert.equal(s.liquid, 1086000);
  assert.equal(s.available, 738000);
  assert.equal(s.netWorth, 5586000);
});
check('Un paiement prévu ne débite pas deux fois le disponible', () => {
  const d = createDemo(); const before = snapshot(d, period);
  assert.equal(pay(d, period, 'sep-insurance'), true);
  const after = snapshot(d, period);
  assert.equal(after.available, before.available);
  assert.equal(after.liquid, before.liquid - 34000);
  assert.equal(after.due, before.due - 34000);
  assert.equal(after.spent, before.spent + 34000);
  assert.equal(after.netWorth, before.netWorth - 34000);
});
check('Un deuxième paiement est inerte et conserve son identifiant', () => {
  const d = createDemo(); pay(d, period, 'sep-insurance'); const before = snapshot(d, period);
  assert.equal(pay(d, period, 'sep-insurance'), false);
  assert.deepEqual(snapshot(d, period), before);
  assert.equal(d[period].transactions.filter(row => row.id === 'sep-insurance').length, 1);
});
check('La mise de côté déplace les poches sans détruire le patrimoine', () => {
  const d = createDemo(); const withSavings = snapshot(d, period);
  d[period].transactions = d[period].transactions.filter(row => row.family !== 'savings');
  const without = snapshot(d, period);
  assert.equal(withSavings.netWorth, without.netWorth);
  assert.equal(withSavings.liquid, without.liquid - 120000);
  assert.equal(withSavings.savings, without.savings + 120000);
});
check('Un transfert interne est neutre', () => {
  const d = createDemo(); const before = snapshot(d, period);
  d[period].transactions.push({ id: 'transfer', label: 'Virement', amountMinor: 12345, family: 'transfer', currency: 'CHF', date: '2026-09-01', status: 'posted' });
  const after = snapshot(d, period);
  for (const key of ['available', 'liquid', 'spent', 'netWorth']) assert.equal(after[key], before[key]);
  assert.equal(after.totals.income, before.totals.income);
});
check('Le mois d’août conserve ses propres opérations', () => {
  const d = createDemo(); const august = snapshot(d, '2026-08');
  assert.equal(august.due, 0);
  assert.equal(august.liquid, d[period].openingLiquidMinor);
  assert.equal(august.savings, d[period].savingsOpeningMinor);
  pay(d, period, 'sep-insurance');
  assert.deepEqual(snapshot(d, '2026-08'), august);
});
check('Une devise sans conversion bloque le résultat', () => {
  const d = createDemo(); d[period].transactions[0].currency = 'USD';
  const s = snapshot(d, period); assert.equal(s.complete, false); assert.equal(s.available, undefined);
});
check('Inconnu et zéro sont distincts', () => {
  const d = createDemo(); d[period].reserveIncludedMinor = null;
  assert.equal(snapshot(d, period).complete, false);
  d[period].reserveIncludedMinor = 0;
  assert.equal(snapshot(d, period).available, 938000);
});
check('Un doublon ou une destination inconnue bloque le résultat', () => {
  const d = createDemo(); d[period].transactions.push({ ...d[period].transactions[0] });
  assert.equal(snapshot(d, period).complete, false);
  const other = createDemo(); other[period].transactions.find(row => row.family === 'savings').destination = null;
  assert.equal(snapshot(other, period).complete, false);
});
check('La saisie décimale est exacte et rejette les formats ambigus', () => {
  assert.equal(parseMoney('0,29'), 29); assert.equal(parseMoney('100.01'), 10001);
  for (const value of ['1.234', '-1', '1e3', '', 'NaN', '0', '1,200.00']) assert.throws(() => parseMoney(value));
});
check('Un ajout réel de la démonstration affecte les bons indicateurs', () => {
  const d = createDemo(); const before = snapshot(d, period);
  addTransaction(d, period, { id: 'extra', label: 'Café', amount: '4,50', family: 'expense', date: '2026-09-11' });
  const after = snapshot(d, period);
  assert.equal(after.spent, before.spent + 450); assert.equal(after.available, before.available - 450);
  assert.equal(after.categoryTotals.Quotidien, before.categoryTotals.Quotidien + 450);
  assert.throws(() => addTransaction(d, period, { id: 'extra2', label: 'Futur', amount: '10', family: 'income', date: '2026-09-20' }));
});
check('Le disponible négatif garde son signe', () => {
  const d = createDemo(); d[period].reserveIncludedMinor = 1200000;
  assert.equal(snapshot(d, period).available, -262000);
});
console.log(`${checks} scénarios vérifiés sur la référence fictive. Aucune preuve de production implicite.`);
