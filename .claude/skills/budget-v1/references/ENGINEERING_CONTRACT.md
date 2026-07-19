# Engineering contract

## Platform

- Swift 5.10 or later.
- SwiftUI application lifecycle.
- SwiftData persistence; no direct Core Data model editing.
- Swift Charts for charts.
- iOS 17 minimum.
- iPhone first, adaptive layouts.
- No third-party dependency in V1 unless approved.

## Money and time

- Persist money as `Decimal` or a documented integer minor-unit representation that round-trips exactly; never use `Double` for financial state or calculations.
- Centralize currency rounding and formatting.
- Main locale `fr_CH`; currency `CHF`; date format `dd.MM.yyyy` where an explicit numeric date is appropriate.
- Inject `Calendar`, `Locale`, `TimeZone`, and current date into calculation services.
- Use half-open date intervals for monthly queries where practical.

## Persistence

- Stable `UUID` identifiers.
- Explicit delete behavior and relationship ownership.
- Unique import fingerprints.
- Schema versioning and migration notes from first release.
- No production model seeded with real user data.
- Demo content exists in an isolated in-memory container.

## Architecture

- Feature-oriented folders.
- SwiftData entities remain focused on persistence.
- Pure domain structs for snapshots and calculation results.
- Services for transaction validation, monthly aggregation, taxes, recurrence, net worth, import/export, and security.
- Thin views. Avoid calculation chains inside `body`.
- Use observable view models only where orchestration or temporary UI state warrants them; do not add a view model mechanically to every view.

## Error handling

- Use typed domain errors.
- Show actionable French messages to users.
- Preserve source data for import failures.
- Never swallow persistence or parsing errors.
- Log only non-sensitive diagnostic information.

## Git and safety

- Preserve existing work.
- Do not force-push, reset, clean, or delete user assets.
- Do not place secrets in source control.
- Do not commit derived data, archives, personal exports, or real financial CSVs.

## Performance

- Avoid loading all transactions for every render.
- Aggregate outside view bodies.
- Add indexes/queries that match month, account, category, status, and recurrence use cases.
- Use chart downsampling or monthly summaries for long histories.
- Avoid unbounded animation, blur, and shadow layers in scrolling lists.

## Privacy and security

- Use LocalAuthentication for optional Face ID/Touch ID lock.
- Store only appropriate small secrets in Keychain; financial records remain in the protected app container.
- Use iOS data protection APIs/default protected storage and document backup behavior.
- Include complete local deletion and export.
- Avoid analytics in V1 unless explicitly implemented with opt-in and privacy documentation.
