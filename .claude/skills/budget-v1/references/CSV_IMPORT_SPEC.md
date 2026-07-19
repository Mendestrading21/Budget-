# Notion CSV import specification

## Goals

Import the existing Notion budget data without silent loss, duplicate creation, or irreversible guesswork.

## Wizard

1. Select CSV file.
2. Detect delimiter, encoding, headers, date and amount patterns.
3. Show column-mapping screen.
4. Preview normalized rows.
5. Map or create accounts and categories with explicit confirmation.
6. Validate every row.
7. Import valid rows in a controlled transaction/batch.
8. Present complete report and repair queue.

## Supported Swiss parsing

- Dates such as `31.12.2026`, `31/12/2026`, and documented ISO forms.
- Amounts such as `18’190.00`, `18'190.00`, `18 190,00`, `-420.50`.
- Currency symbols/codes stripped only after detection.
- Never infer decimal separators ambiguously without preview.

## Idempotence

Create a stable fingerprint from normalized source identity, date, amount, account mapping, type, description, and source-row identity. Store import batch and fingerprint. Re-importing the same source must skip or link existing records, not duplicate them.

## Row states

- Ready
- Warning requiring confirmation
- Duplicate
- Invalid
- Imported
- Failed

## Report

- Total rows.
- Imported rows.
- Duplicates skipped.
- Invalid and failed rows.
- Accounts/categories created.
- Normalizations performed.
- Manual actions required.

## Safety

- Preserve raw row text or a safe trace until the user dismisses/exports the report.
- Do not auto-create hundreds of categories from typos.
- Allow rollback of the current import batch when feasible.
- Never import into the production store from a preview.
