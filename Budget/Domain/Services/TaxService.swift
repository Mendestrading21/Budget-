import Foundation
import SwiftData

/// Derived tax picture for one year. Every amount is either user-entered
/// (reserved, arrears, override) or derived from posted transactions.
/// `outstanding` is floored at zero, so an overpayment is represented by
/// `paid > estimatedTax` rather than by a negative outstanding balance.
struct TaxYearReport: Equatable {
    let year: Int
    /// Fraction used when no override is set.
    let rate: Decimal
    /// Posted income of the year (assumed taxable in V1).
    let taxableIncome: Decimal
    /// Override, or taxableIncome × rate.
    let estimatedTax: Decimal
    let isOverridden: Bool
    /// Posted taxPayment transactions of the year.
    let paid: Decimal
    /// Cash explicitly set aside by the user.
    let reserved: Decimal
    /// Previous years' tax debts (user-entered).
    let arrears: Decimal

    /// Still to pay for this year: estimate − paid, floored at zero.
    var outstanding: Decimal { max(.zero, estimatedTax - paid) }
    /// Cash missing to cover what remains due (this year + arrears).
    var reserveGap: Decimal { max(.zero, outstanding + arrears - reserved) }
    /// Everything still owed, arrears included.
    var totalDue: Decimal { outstanding + arrears }
}

/// Tax provisioning arithmetic + lazy profile/provision creation.
struct TaxService {
    let calendar: Calendar

    // MARK: - Derivations (pure)

    /// Posted income of a calendar year.
    func taxableIncome(year: Int, transactions: [BudgetTransaction]) -> Decimal {
        transactions
            .filter {
                $0.status == .posted
                    && $0.type == .income
                    && calendar.component(.year, from: $0.date) == year
            }
            .reduce(.zero) { $0 + $1.amount }
    }

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
        profile: TaxProfile?,
        provision: TaxProvision?,
        transactions: [BudgetTransaction],
        fallbackRate: Decimal = Decimal("0.30")
    ) -> TaxYearReport {
        let rate = profile?.provisionRate ?? fallbackRate
        let income = taxableIncome(year: year, transactions: transactions)
        let derived = FinanceMath.roundedToCents(income * rate)
        let override = provision?.estimatedAnnualTaxOverride
        return TaxYearReport(
            year: year,
            rate: rate,
            taxableIncome: income,
            estimatedTax: override ?? derived,
            isOverridden: override != nil,
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
            provisionRate: household?.taxProvisionRate ?? Decimal("0.30"),
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
