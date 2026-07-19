# Functional specification

## 1. Onboarding

Progressive local onboarding:

- Welcome and privacy promise.
- Household name and optional member.
- Canton, municipality, base currency.
- Tax provision rate with a clear “estimate” explanation.
- First account and opening balance.
- Optional recurring salary and housing cost.
- Choose initial goals.
- Land on a meaningful dashboard; allow demo mode.

## 2. Dashboard

First viewport:

- Month selector.
- Truly available amount.
- Daily available amount and days remaining.
- Income, living expenses, savings/investments, tax reserve.
- Budget-versus-actual luminous line or bar chart.
- At most three priority actions.

Second section:

- Tax provision progress.
- Savings goal progress.
- Top categories.
- Recent or uncategorized transactions.
- Net-worth trend when enough data exists.

## 3. Accounts

- Cards for current, savings, broker, pension, cash, credit, and debts.
- Included-in-cash and included-in-net-worth controls.
- Opening balance and reconciliation.
- Account detail with history and monthly flow.
- Transfer flow with atomic validation.
- Archive rather than delete accounts with history.

## 4. Transactions

- Fast add sheet.
- Search and filters by month, type, account, category, member, status.
- Edit, duplicate, delete/void with confirmation.
- Split transaction may be a later V1 enhancement; design model compatibility now.
- Planned transactions visibly distinct from posted actuals.
- Uncategorized queue.

## 5. Budget

- Monthly category budget.
- Planned versus actual and variance.
- Annual 12-month grid.
- Copy previous month/year templates.
- Fixed/variable and essential/discretionary groupings.
- Clear overrun and remaining indicators.

## 6. Recurring and subscriptions

- Salary, rent, insurance, childcare, loans, subscriptions, savings contributions.
- Monthly and annualized cost.
- Personal/professional classification.
- Renewal and cancellation deadline.
- Generate forecast occurrences without duplicating posted transactions.

## 7. Taxes

- Tax profile and configured rate.
- Annual estimate, recommended reserve, reserved cash, payments, outstanding, arrears.
- Due dates and reminders.
- Explain assumptions and provide manual override.
- No official declaration claim.

## 8. Goals

- Emergency fund, taxes, travel, vehicle, property, children, retirement, pillar 3a, debt, custom.
- Target, current amount, target date, monthly contribution.
- Required monthly amount and schedule status.
- Celebrate meaningful progress tastefully.

## 9. Insurance

- Contract list and annual household premium.
- Coverage summary, deductible, insured person.
- Renewal, cancellation deadline, notice period.
- Document link.
- No commercial comparison in V1.

## 10. Pension

- Pillar 1 estimate/reference record.
- Pillar 2 certificate snapshot.
- Pillar 3a/3b balances and annual contribution.
- Retirement overview with explicit assumptions.
- Do not present projections as guaranteed.

## 11. Net worth

- Liquid, investment, pension, property/other assets.
- Mortgage, credit, leasing, tax debt, other liabilities.
- Historical trend and contribution/value-change distinction.

## 12. Documents

- Local metadata and secure file import.
- Type, year, provider, member, notes.
- Open/share/delete actions.
- Avoid cluttering the dashboard.

## 13. Import/export

- Notion CSV import wizard.
- Column mapping and preview.
- Idempotent import and duplicate report.
- Manual repair queue.
- CSV and JSON export.
- Local backup/restore with schema/version metadata.

## 14. Settings

- Face ID lock.
- Appearance and reduced glass option.
- Emoji warmth toggle if implemented.
- Categories and fiscal assumptions.
- Data export, backup, restore, and delete.
- Privacy, methodology, acknowledgements.
