# Quality plan

## Unit tests — mandatory invariants

- Valid and invalid transaction creation.
- Source and destination transfer requirements.
- Transfer neutrality for income, expense, savings rate, cash flow, and net worth.
- Savings/investments excluded from cost of living.
- Investments included in savings rate.
- Zero income returns a safe ratio.
- Configured tax rate and default 30% provision.
- Recommended, reserved, paid, outstanding, and arrears reconciliation.
- Active/inactive recurrence behavior.
- Monthly, quarterly, annual, and leap/date-boundary recurrence.
- Net worth assets minus liabilities.
- Included/excluded account policy.
- CSV amount/date/category parsing.
- Import idempotence and duplicate detection.
- Available-to-spend component reconciliation.
- Decimal rounding and CHF formatting.

## Integration tests

- SwiftData insert/edit/delete and relaunch persistence.
- Transfer atomicity.
- Migration from each shipped schema.
- Import to persisted entities.
- Backup then restore to an isolated store.
- Document metadata lifecycle.

## UI tests or manual scripted verification

- Fresh onboarding.
- Add account, salary, expense, savings, transfer.
- Dashboard changes correctly.
- Add budget and observe variance.
- Add recurring charge and forecast.
- Add tax payment and reserve.
- Add goal and contribution.
- Lock/unlock with authentication cancellation path.
- Export and delete confirmation.

## Accessibility

- VoiceOver labels for charts, amounts, progress, and icon-only controls.
- Dynamic Type through accessibility sizes.
- Sufficient contrast with transparency reduced.
- Status never conveyed by color alone.
- Minimum touch targets.
- Reduced motion and reduced transparency behavior.
- Logical focus order.

## Visual review

- Compare each key screen with canonical reference.
- Check small and large iPhones.
- Check portrait first; no clipped sheets or keyboards.
- Verify chart labels and selection.
- Verify empty states remain elegant, not barren.
- Ensure emojis remain sparse and aligned.

## Security/privacy

- No sensitive values in logs or crash breadcrumbs.
- No bundled real CSV/export files.
- Authentication failure/cancel handled.
- Data export explicitly initiated.
- Full local deletion requires confirmation and is testable.
- Privacy/methodology text matches actual implementation.

## Performance

- Smooth scrolling with realistic transaction counts.
- Dashboard aggregation measured with large demo data.
- No repeated heavy calculation in `body`.
- Chart history bounded or summarized.
- Material/blur count controlled.
- App launch and first dashboard render inspected.

## Release gate evidence

Record:

- Exact build command and result.
- Exact test command and result.
- Tested simulator/device and OS.
- Known warnings.
- Manual scenarios completed.
- Data migration/backup status.
- Accessibility and privacy review status.
- Remaining limitations, with severity.
