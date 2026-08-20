import Foundation
import SwiftData

/// Manual tax picture for one year (ADR-035, décision propriétaire du
/// 20.08.2026). Every amount is USER-ENTERED (annual amount, reserved,
/// arrears) or the plain sum of posted taxPayment movements (paid).
/// Nothing is derived from a rate anymore: the app adds up what the user
/// noted, it never estimates taxes on their behalf.
struct TaxYearReport: Equatable {
    let year: Int
    /// Annual tax the user typed for the year — nil while unknown. The app
    /// never invents this number.
    let annualTax: Decimal?
    /// Posted taxPayment transactions of the year.
    let paid: Decimal
    /// Cash explicitly set aside by the user.
    let reserved: Decimal
    /// Previous years' tax debts (user-entered).
    let arrears: Decimal

    /// Still to pay for this year — meaningful only once the user gave the
    /// annual amount; zero (silent) while it is unknown.
    var outstanding: Decimal { max(.zero, (annualTax ?? paid) - paid) }
    /// Cash missing to cover what remains due (this year + arrears).
    var reserveGap: Decimal { max(.zero, outstanding + arrears - reserved) }
    /// Everything still owed, arrears included.
    var totalDue: Decimal { outstanding + arrears }
}

/// Manual tax bookkeeping + lazy profile/provision creation. The legacy
/// provision-rate fields (Household.taxProvisionRate, TaxProfile
/// .provisionRate) stay STORED for backup compatibility but are never read
/// by any computation anymore (ADR-035).
struct TaxService {
    let calendar: Calendar

    // MARK: - Derivations (pure)

    /// Posted tax payments of a calendar year.
    func paidTaxes(year: Int, transactions: [BudgetTransaction]) -> Decimal {
        transactions
            .filter {
                $0.status == .posted
                    && $0.type == .taxPayment
                    && calendar.component(.year, from: $0.date) == year
            }
            .reduce(.zero) { $0 + $1.amount }
    }

    func report(
        year: Int,
        provision: TaxProvision?,
        transactions: [BudgetTransaction]
    ) -> TaxYearReport {
        TaxYearReport(
            year: year,
            annualTax: provision?.estimatedAnnualTaxOverride,
            paid: paidTaxes(year: year, transactions: transactions),
            reserved: provision?.reservedAmount ?? .zero,
            arrears: provision?.arrearsAmount ?? .zero
        )
    }

    /// Due dates of the provision not yet in the past, soonest first.
    func upcomingDueDates(provision: TaxProvision?, now: Date) -> [TaxDueDate] {
        (provision?.dueDates ?? [])
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
    }

    /// Due dates already in the past (proposed as "à vérifier").
    func overdueDueDates(provision: TaxProvision?, now: Date) -> [TaxDueDate] {
        (provision?.dueDates ?? [])
            .filter { $0.date < now }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Lazy creation (context)

    /// The single profile of the store, created from the household's
    /// legacy rate on first access (ADR-008).
    @discardableResult
    func ensureProfile(context: ModelContext, household: Household?, now: Date) throws -> TaxProfile {
        if let existing = try context.fetch(FetchDescriptor<TaxProfile>()).first {
            return existing
        }
        let profile = TaxProfile(
            canton: household?.canton ?? "",
            municipality: household?.municipality ?? "",
            provisionRate: household?.taxProvisionRate ?? .zero,
            createdAt: now,
            updatedAt: now
        )
        context.insert(profile)
        try context.saveOrRollback()
        return profile
    }

    /// The provision of `year` under `profile`, created empty when absent.
    @discardableResult
    func ensureProvision(year: Int, profile: TaxProfile, context: ModelContext, now: Date) throws -> TaxProvision {
        if let existing = profile.provisions.first(where: { $0.year == year }) {
            return existing
        }
        let provision = TaxProvision(year: year, createdAt: now, updatedAt: now)
        provision.profile = profile
        context.insert(provision)
        try context.saveOrRollback()
        return provision
    }
}
