import { createDemo, snapshot, pay, addTransaction, families } from './reference-model.mjs';

// Fictional example, intentionally memory-only. No API, tracking, or storage.
const data = createDemo();
const state = { period: '2026-09', hidden: false, query: '', family: '', status: 'posted' };
const $ = selector => document.querySelector(selector);
const esc = value => String(value).replace(/[&<>"']/g, char => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[char]));
const icon = name => `<svg aria-hidden="true"><use href="#i-${name}"/></svg>`;
const number = new Intl.NumberFormat('fr-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const dateFormat = new Intl.DateTimeFormat('fr-CH', { day: 'numeric', month: 'short', timeZone: 'UTC' });
const date = value => dateFormat.format(new Date(`${value}T12:00:00Z`));
const money = (cents, currency = false) => state.hidden ? '••••' : `${number.format(cents / 100)}${currency ? ' CHF' : ''}`;
const moneySpan = (cents, currency = false, extra = '') => `<span class="bng-money ${extra}">${money(cents, currency)}</span>`;
const symbol = family => ({ income: 'in', expense: 'out', subscription: 'repeat', savings: 'goal', transfer: 'arrow' }[family]);
const statusName = row => row.status === 'planned' ? (row.family === 'income' ? 'Attendu' : 'À payer') : ({ income: 'Reçu', savings: 'Transféré', transfer: 'Transféré' }[row.family] || 'Payé');
const meter = (value, total, label) => state.hidden ? '<div class="bng-track" aria-hidden="true"></div>' : `<div class="bng-track" role="img" aria-label="${esc(label)} : ${money(value)} sur ${money(total)} CHF"><span style="width:${Math.min(100, Math.max(0, total > 0 ? value / total * 100 : 0))}%"></span></div>`;
let noticeTimer;
let lastFocus;
function notice(message) {
  clearTimeout(noticeTimer);
  $('#notice').textContent = message;
  noticeTimer = setTimeout(() => { $('#notice').textContent = ''; }, 5000);
}
function familyTile(key, amount, note) {
  return `<div><div class="bng-family-name">${icon(symbol(key))}${families[key]}</div>${moneySpan(amount, false, `bng-family-amount ${key === 'income' ? 'bng-positive' : key === 'savings' ? 'bng-accent' : ''}`)}<span class="bng-family-note">${note}</span></div>`;
}

function render() {
  const s = snapshot(data, state.period);
  const m = data[state.period];
  $('#asof').textContent = `situation au ${date(m.asOf)}`;
  $('#privacy').setAttribute('aria-pressed', String(state.hidden));
  $('#privacy').setAttribute('aria-label', state.hidden ? 'Afficher les montants' : 'Masquer les montants');
  if (!s.complete) {
    $('#dashboard').innerHTML = `<section class="bng-panel bng-panel-body"><h2>Calcul incomplet</h2><ul>${s.issues.map(issue => `<li>${esc(issue)}</li>`).join('')}</ul></section>`;
    return;
  }
  const disable = state.hidden ? 'disabled' : '';
  const dueMarkup = s.dueRows.map(row => `<div class="bng-due"><span class="bng-date-box">${row.date.slice(-2)}<small>${date(row.date).replace(/^\d+\s*/, '')}</small></span><div><p class="bng-due-title">${esc(row.label)}</p><p class="bng-due-sub">À payer · ${esc(row.category)}</p></div><button class="bng-pay" data-action="pay" data-id="${esc(row.id)}" aria-label="Payer ${esc(row.label)}" ${disable}>${moneySpan(row.amountMinor)}<small>Marquer payé →</small></button></div>`).join('');
  $('#dashboard').innerHTML = `
    <div class="bng-left-stack">
      <section class="bng-panel bng-hero" aria-labelledby="available-title">
        <div class="bng-hero-heading"><h2 id="available-title">Disponible pour ce mois</h2>${icon('wallet')}</div>
        <p class="bng-big-money bng-money ${s.available < 0 ? 'bng-negative' : ''}" id="available">${money(s.available)}${state.hidden ? '' : '<small>CHF</small>'}</p>
        <p class="bng-caption">Après les échéances et la réserve fiscale.</p>
        <button class="bng-link-button" data-action="available" ${disable}>Comprendre ce montant ${icon('arrow')}</button>
        <div class="bng-family-grid">${familyTile('income', s.totals.income, 'reçues ce mois')}${familyTile('expense', s.totals.expense, 'payées ce mois')}${familyTile('subscription', s.totals.subscription, 'payés ce mois')}${familyTile('savings', s.totals.savings, 'transféré ce mois')}</div>
      </section>
      <section class="bng-panel" id="movements" aria-labelledby="movements-title">
        <div class="bng-panel-head"><h2 id="movements-title">Les mouvements du mois</h2>${icon('clock')}</div>
        <div class="bng-tools"><label class="bng-search">${icon('search')}<span class="bng-sr-only">Rechercher un libellé</span><input id="query" type="search" placeholder="Rechercher un mouvement…" value="${esc(state.query)}"></label><label class="bng-sr-only" for="family">Filtrer par famille</label><select id="family"><option value="">Toutes les familles</option>${Object.entries(families).filter(([key]) => key !== 'transfer').map(([key, name]) => `<option value="${key}" ${state.family === key ? 'selected' : ''}>${name}</option>`).join('')}</select><label class="bng-sr-only" for="status">Filtrer par statut</label><select id="status"><option value="posted" ${state.status === 'posted' ? 'selected' : ''}>Réalisés</option><option value="planned" ${state.status === 'planned' ? 'selected' : ''}>Prévus</option><option value="" ${state.status === '' ? 'selected' : ''}>Tous les statuts</option></select></div>
        <table class="bng-table"><caption class="bng-sr-only">Opérations de ${esc(m.label)}, montants en CHF. La recherche filtre la liste et conserve les indicateurs du mois.</caption><thead><tr><th scope="col">Opération</th><th scope="col">Date</th><th scope="col">Montant · CHF</th><th scope="col">Statut</th></tr></thead><tbody id="rows"></tbody></table><div id="empty" hidden class="bng-empty">Aucun résultat pour ces filtres.</div>
        <div class="bng-list-foot"><span id="count" role="status"></span><button class="bng-link-button" data-action="reset-filters">Réinitialiser les filtres</button></div>
      </section>
      <section class="bng-panel" id="accounts" aria-labelledby="accounts-title"><div class="bng-panel-head"><h2 id="accounts-title">Mes comptes</h2><button class="bng-link-button" data-action="accounts" ${disable}>Voir le détail ${icon('arrow')}</button></div><div class="bng-account-list"><div class="bng-account"><p>Compte courant</p><strong>${moneySpan(s.liquid)}</strong><small>CHF · liquidités observées</small></div><div class="bng-account"><p>Épargne</p><strong>${moneySpan(s.savings)}</strong><small>CHF · hors disponible</small></div><div class="bng-account"><p>Prévoyance</p><strong>${moneySpan(m.pensionMinor)}</strong><small>CHF · hors disponible</small></div></div><div class="bng-total-line"><span>Patrimoine net · dettes déduites</span><strong>${moneySpan(s.netWorth, true)}</strong></div></section>
    </div>
    <div class="bng-right-stack">
      <section class="bng-panel bng-upcoming" aria-labelledby="upcoming-title"><div class="bng-panel-head"><h2 id="upcoming-title">À venir ce mois</h2><span class="bng-pill">${s.dueRows.length} ÉCHÉANCES</span></div>${s.dueRows.length ? `<div class="bng-due-list">${dueMarkup}</div>` : '<p class="bng-empty">Toutes les échéances sont réglées.</p>'}<div class="bng-total-line"><span>Encore à payer</span><strong>${moneySpan(s.due, true)}</strong></div></section>
      <section class="bng-panel" id="budget-plan" aria-labelledby="budget-title"><div class="bng-panel-head"><h2 id="budget-title">Mon budget du mois</h2>${icon('wallet')}</div><div class="bng-panel-body"><div class="bng-budget-summary"><strong>${moneySpan(s.spent)}</strong><span>sur ${moneySpan(s.budget)} CHF</span></div>${meter(s.spent, s.budget, 'Budget utilisé')}<div class="bng-budget-note"><span>${state.hidden ? '••••' : `${Math.round(s.spent / s.budget * 100)} % utilisé`}</span><span>${moneySpan(s.budgetRemaining)} ${s.budgetRemaining < 0 ? 'de dépassement' : 'restants'}</span></div>${Object.entries(m.budgets).map(([name, amount]) => `<div class="bng-category"><div class="bng-category-title"><span>${esc(name)}</span>${moneySpan(s.categoryTotals[name])} <span class="bng-sr-only">sur</span>${moneySpan(amount)}</div>${meter(s.categoryTotals[name], amount, name)}</div>`).join('')}<p class="bng-caption" style="margin-top:18px">Dépenses et abonnements payés.</p></div></section>
      <section class="bng-panel bng-goal" aria-labelledby="goal-title"><div class="bng-panel-head"><h2 id="goal-title">Mis de côté</h2>${icon('goal')}</div><div class="bng-panel-body"><div class="bng-goal-head"><span class="bng-goal-icon">${icon('goal')}</span><div><h3>Mon projet personnel</h3><small>Objectif fictif · ${money(2000000, true)}</small></div></div><div class="bng-budget-summary"><strong>${moneySpan(s.savings)}</strong><span>${state.hidden ? '••••' : `${Math.round(s.savings / 2000000 * 100)} %`}</span></div>${meter(s.savings, 2000000, 'Objectif d’épargne')}<p class="bng-caption" style="margin-top:12px">${moneySpan(s.totals.savings, true)} transférés ce mois.</p><button class="bng-link-button" data-action="savings" ${disable}>Voir la mise de côté ${icon('arrow')}</button></div></section>
    </div>`;
  renderRows();
}

function renderRows() {
  const rows = data[state.period].transactions.filter(row => (!state.family || row.family === state.family) && (!state.status || row.status === state.status) && row.label.toLocaleLowerCase('fr').includes(state.query.toLocaleLowerCase('fr'))).sort((a,b) => (b.postedDate || b.date).localeCompare(a.postedDate || a.date));
  $('#rows').innerHTML = rows.map(row => `<tr><td><button class="bng-row-button" data-action="transaction" data-id="${esc(row.id)}" ${state.hidden ? 'disabled' : ''}><span class="bng-row-icon">${icon(symbol(row.family))}</span><span>${esc(row.label)}<small>${families[row.family]}</small></span></button></td><td>${date(row.postedDate || row.date)}</td><td>${state.hidden ? moneySpan(0) : moneySpan(row.family === 'income' ? row.amountMinor : -row.amountMinor, false, row.family === 'income' ? 'bng-positive' : '')}</td><td><span class="bng-status ${row.status === 'planned' ? 'bng-planned' : ''}">${statusName(row)}</span></td></tr>`).join('');
  $('#empty').hidden = rows.length > 0;
  $('#count').textContent = `${rows.length} mouvement${rows.length === 1 ? '' : 's'} · indicateurs du mois conservés`;
}

function openSheet(title, html, monetary = true) {
  if (monetary && state.hidden) { notice('Affiche les montants pour ouvrir ce détail.'); return; }
  lastFocus = document.activeElement;
  $('#sheet-title').textContent = title;
  $('#sheet-content').innerHTML = html;
  $('#sheet').showModal();
}
const detail = rows => `<dl class="bng-detail">${rows.map(([label, value, final]) => `<dt ${final ? 'class="bng-final"' : ''}>${label}</dt><dd ${final ? 'class="bng-final"' : ''}>${value}</dd>`).join('')}</dl>`;
function showAvailable() {
  const s = snapshot(data,state.period), m = data[state.period];
  openSheet('Comprendre le disponible', `<p class="bng-caption">Situation fictive au ${date(m.asOf)}. Ce montant utilise le solde déjà mis à jour par les opérations réalisées.</p>${detail([['Liquidités observées', moneySpan(s.liquid,true)],['Échéances encore dues',moneySpan(-s.due,true)],['Réserve fiscale incluse',moneySpan(-m.reserveIncludedMinor,true)],['Disponible pour ce mois',moneySpan(s.available,true),true]])}<p class="bng-caption">La réserve fiscale est encore sur le compte courant. L’épargne et la prévoyance sont en dehors de ces liquidités. Les rentrées attendues ne sont pas ajoutées.</p>`);
}
function showAccounts() {
  const s = snapshot(data,state.period), m = data[state.period];
  openSheet('Comptes et patrimoine', `${detail([['Compte courant',moneySpan(s.liquid,true)],['Compte d’épargne',moneySpan(s.savings,true)],['Prévoyance',moneySpan(m.pensionMinor,true)],['Dettes',moneySpan(-m.debtMinor,true)],['Patrimoine net',moneySpan(s.netWorth,true),true]])}<p class="bng-caption">Tous les comptes de cette démonstration sont en CHF. La réserve fiscale reste incluse dans le compte courant. Le patrimoine et le disponible répondent à deux questions différentes.</p>`);
}
function showSavings() {
  const s = snapshot(data,state.period), m = data[state.period];
  openSheet('Ma mise de côté', `${detail([['Épargne au début du mois',moneySpan(m.savingsOpeningMinor,true)],['Transféré ce mois',moneySpan(s.totals.savings,true)],['Compte d’épargne',moneySpan(s.savings,true),true]])}<p class="bng-caption">Les transferts viennent du compte courant et sont affectés au compte d’épargne. Ils ne sont ni une dépense ni une perte de patrimoine.</p>`);
}
function showTransaction(id) {
  const row = data[state.period].transactions.find(item => item.id === id);
  if (!row) return;
  openSheet(row.label, `${detail([['Famille',families[row.family]],['Montant original',moneySpan(row.amountMinor,true)],['Statut',statusName(row)],['Date prévue / initiale',date(row.date)],...(row.status === 'posted' ? [['Date comptabilisée',date(row.postedDate || row.date)]] : []),['Catégorie',esc(row.category)]])}<p class="bng-caption">Opération fictive · ${row.family === 'savings' ? 'destination : compte d’épargne.' : row.status === 'planned' ? 'aucun encaissement ou paiement comptabilisé.' : 'déjà prise en compte dans les soldes affichés.'}</p>`);
}
function showPayment(id) {
  const m = data[state.period], row = m.transactions.find(item => item.id === id);
  if (!row || row.status !== 'planned') return;
  openSheet('Confirmer le paiement', `<p>${esc(row.label)}</p>${detail([['Montant',moneySpan(row.amountMinor,true)],['Échéance prévue',date(row.date)],['Date du paiement simulé',date(m.asOf)]])}<p class="bng-caption">Cette action marque l’échéance existante comme payée dans la démonstration. Elle ne crée pas une seconde opération.</p><div class="bng-form-actions"><button class="bng-button" data-action="close">Annuler</button><button class="bng-button bng-primary" data-action="confirm-pay" data-id="${esc(id)}">Confirmer le paiement</button></div>`);
}
function showAdd() {
  const m = data[state.period];
  openSheet('Ajouter une opération', `<form id="add-form"><label class="bng-field">Famille<select name="family"><option value="expense">Dépenses</option><option value="income">Rentrées</option></select></label><label class="bng-field">Libellé<input name="label" required maxlength="80" placeholder="Par exemple : courses" autocomplete="off"></label><label class="bng-field">Montant en CHF<input name="amount" required inputmode="decimal" placeholder="0.00" autocomplete="off"></label><label class="bng-field">Date réalisée<input name="date" type="date" required min="${state.period}-01" max="${m.asOf}" value="${m.asOf}"></label><p class="bng-caption">Exemple simplifié : les dépenses rejoignent « Quotidien », les rentrées « Travail ». L’ajout reste en mémoire et disparaît au rechargement.</p><p id="form-error" class="bng-error" role="alert"></p><div class="bng-form-actions"><button class="bng-button" type="button" data-action="close">Annuler</button><button class="bng-button bng-primary" type="submit">Ajouter à la démonstration</button></div></form>`);
}
function showSettings() {
  openSheet('Préférences de la référence', `<label class="bng-check-field"><input id="opaque" type="checkbox" ${document.body.hasAttribute('data-opaque') ? 'checked' : ''}>Réduire la transparence</label><p class="bng-caption">Les surfaces deviennent opaques. Ce réglage reste actif jusqu’au rechargement.</p><p class="bng-caption" style="margin-top:20px">Cette référence montre la page Mois et ses interactions. Les liens latéraux mènent aux sections de cet exemple ; ils ne représentent pas cinq pages terminées.</p>`, false);
}

document.addEventListener('click', event => {
  const button = event.target.closest('[data-action]');
  if (!button || button.disabled) return;
  const action = button.dataset.action;
  if (action === 'close') $('#sheet').close();
  else if (action === 'available') showAvailable();
  else if (action === 'accounts') showAccounts();
  else if (action === 'savings') showSavings();
  else if (action === 'transaction') showTransaction(button.dataset.id);
  else if (action === 'pay') showPayment(button.dataset.id);
  else if (action === 'add') showAdd();
  else if (action === 'settings') showSettings();
  else if (action === 'reset-filters') {
    state.query = ''; state.family = ''; state.status = 'posted';
    $('#query').value = ''; $('#family').value = ''; $('#status').value = 'posted'; renderRows();
  } else if (action === 'confirm-pay') {
    button.disabled = true;
    try {
      const changed = pay(data, state.period, button.dataset.id);
      $('#sheet').close(); render();
      notice(changed ? 'Paiement ajouté à la démonstration. Disponible préservé.' : 'Cette échéance est déjà payée.');
    } catch (error) { button.disabled = false; notice(error.message); }
  }
});
document.addEventListener('change', event => {
  if (event.target.id === 'period') { state.period = event.target.value; render(); }
  else if (event.target.id === 'family') { state.family = event.target.value; renderRows(); }
  else if (event.target.id === 'status') { state.status = event.target.value; renderRows(); }
  else if (event.target.id === 'opaque') document.body.toggleAttribute('data-opaque', event.target.checked);
});
document.addEventListener('input', event => {
  if (event.target.id === 'query') { state.query = event.target.value; renderRows(); }
});
document.addEventListener('submit', event => {
  if (event.target.id !== 'add-form') return;
  event.preventDefault();
  const form = event.target, input = Object.fromEntries(new FormData(form));
  try {
    addTransaction(data, state.period, { ...input, id: `demo-${crypto.randomUUID()}` });
    $('#sheet').close(); render(); notice('Opération ajoutée à la démonstration.');
  } catch (error) { $('#form-error').textContent = error.message; }
});
$('#sheet').addEventListener('close', () => {
  $('#sheet-content').replaceChildren(); $('#sheet-title').textContent = '';
  if (lastFocus?.isConnected) lastFocus.focus(); else $('#period').focus();
});
$('#privacy').addEventListener('click', () => {
  if ($('#sheet').open) $('#sheet').close();
  // Clear the sheet synchronously too: privacy must not wait for the close event.
  $('#sheet-content').replaceChildren(); $('#sheet-title').textContent = '';
  $('#notice').textContent = ''; clearTimeout(noticeTimer);
  state.hidden = !state.hidden; render();
});
render();
