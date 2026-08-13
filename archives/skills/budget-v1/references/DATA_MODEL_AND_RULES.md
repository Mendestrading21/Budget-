# Data model and financial rules

## Persisted entities

### Household

`id`, `name`, `baseCurrency`, `canton`, `municipality`, `createdAt`, `updatedAt`.

### HouseholdMember

`id`, `firstName`, `role`, optional `birthDate`, employment status, inclusion flags. Roles: owner, partner, child, dependent.

### Account

`id`, `name`, `institutionName`, `type`, `currencyCode`, `openingBalance`, `manualCurrentBalance`, `owner`, `isShared`, `isActive`, `includeInAvailableCash`, `includeInNetWorth`, timestamps.

Types: current, savings, creditCard, cash, broker, pillar3a, pillar3b, occupationalPension, mortgage, loan, other.

Prefer calculating balances from opening balance plus posted movements where feasible. A manually reconciled balance should be explicit, timestamped, and auditable.

### Transaction

Required: `id`, `date`, `amount`, `account`, `type`, `category`, `title` or description.

Optional: destination account, member, merchant, note, status, recurrence link, budget link, tax link, import source/fingerprint, timestamps.

Types: income, expense, saving, investment, transfer, taxPayment, debtPayment, refund, adjustment.

Use positive stored amounts plus explicit type/direction, or a rigorously documented signed convention. Never mix conventions.

### Category

Hierarchical, customizable, typed, ordered, icon token, essential/discretionary flag, active state.

### Budget and BudgetLine

A budget belongs to a period and household. A budget line stores planned amount; actual amount and variance are derived from matching transactions.

### RecurringTransaction and Subscription

Frequency, interval, next occurrence, account, category, active state, start/end, renewal/cancellation metadata, personal/professional flag.

### TaxProfile and TaxProvision

Tax location and assumptions belong to profile. Provision stores tax year, estimated tax, recommended reserve, reserved amount, paid amount, outstanding amount, arrears, due dates, status.

### FinancialGoal

Type, name, target amount/date, current or linked account value, monthly contribution, priority, status.

### InsuranceContract

Insurer, policy name/number, type, member, annual premium, deductible, dates, renewal, cancellation deadline, coverage summary, document reference, status.

### PensionAsset

Pillar type, institution, current value, annual contribution, projected value, retirement age, owner, source document date/reference.

### Asset and Liability

Assets include real estate, vehicle, business, precious metal, collectible, other. Liabilities include mortgage, loan, credit card debt, leasing, tax debt, private debt, other.

### FinancialDocument

Metadata and secure local file reference. Avoid storing large file blobs directly in the main SwiftData store unless justified.

## Derived MonthSnapshot

- `totalIncome`
- `totalLivingExpenses`
- `totalSavings`
- `totalInvestments`
- `totalTaxPayments`
- `plannedIncome`
- `plannedExpenses`
- `budgetVariance`
- `cashFlow`
- `savingsRate`
- `availableUntilEndOfMonth`
- `dailyAvailableBudget`
- `taxProvisionRequired`
- `taxProvisionGap`
- `netWorth`
- `previousMonthComparison`

## Core formulas

### Savings rate

`(savings + investments) / income`

Return zero when income is zero. Document whether refunds reduce expenses or increase income; default to reducing the original category when linked.

### Living cost

Include consumption expenses and relevant debt interest/fees according to category policy. Exclude savings, investments, internal transfers, and asset-value adjustments.

### Internal transfer

Source account decreases; destination account increases. Household income, expenses, cash flow classification, savings rate, and net worth remain unchanged. Cross-currency transfers may create a separately identified FX difference or fee.

### Tax provision

Default recommendation: taxable income × configured provision rate, normally 30%. Distinguish current-year recommendation, cash reserved, tax payments, outstanding estimate, and arrears.

### Available to spend

Define one canonical policy and expose its components. Recommended V1:

`included liquid balance + expected income - unpaid committed charges - required tax reserve gap - committed goal contributions - near-term debt payments`

Do not hide the breakdown. Avoid counting broker/pension accounts as spendable cash unless the user explicitly includes them.

### Net worth

Included account balances + assets + pension values − liabilities. Internal transfers are neutral. Show market value changes separately from contributions where data permits.

## Mandatory validation

- Date, amount, account, type, category required where applicable.
- Transfer destination required and different from source.
- Amount greater than zero under the positive-amount convention.
- Account and category must be active or explicitly allowed for historical edits.
- Currency code valid.
- Recurrence must have a valid interval and next date.
- Goal target and dates must be coherent.
- Annual insurance premium cannot be negative.
