import Foundation

/// Pure premium/pension arithmetic. Annual and monthly equivalents use
/// the same normalization as recurring charges so all totals reconcile.
struct InsurancePensionService {
    // MARK: - Premium equivalents

    /// Cost per year of a premium paid every `count` `unit`s.
    func annualPremium(of contract: InsuranceContract) -> Decimal {
        normalizedAnnual(
            amount: contract.premiumAmount,
            unit: contract.premiumUnit,
            count: contract.premiumIntervalCount
        )
    }

    /// Cost per month, rounded to cents.
    func monthlyPremium(of contract: InsuranceContract) -> Decimal {
        FinanceMath.roundedToCents(
            normalizedAnnual(
                amount: contract.premiumAmount,
                unit: contract.premiumUnit,
                count: contract.premiumIntervalCount
            ) / Decimal(12)
        )
    }

    private func normalizedAnnual(amount: Decimal, unit: RecurrenceUnit, count: Int) -> Decimal {
        let count = Decimal(max(1, count))
        let raw: Decimal
        switch unit {
        case .week: raw = amount * Decimal(52) / count
        case .month: raw = amount * Decimal(12) / count
        case .year: raw = amount / count
        }
        return FinanceMath.roundedToCents(raw)
    }

    /// Total annual premium of active contracts.
    func totalAnnualPremium(contracts: [InsuranceContract]) -> Decimal {
        contracts.filter(\.isActive).reduce(.zero) { $0 + annualPremium(of: $1) }
    }

    /// Monthly view of the same total — derived from the annual figure so
    /// the two always reconcile (monthly × 12 == annual ± rounding cent).
    func totalMonthlyPremium(contracts: [InsuranceContract]) -> Decimal {
        FinanceMath.roundedToCents(totalAnnualPremium(contracts: contracts) / Decimal(12))
    }

    /// Active contracts whose cancellation deadline falls within `days`.
    func contractsWithCloseDeadline(
        contracts: [InsuranceContract],
        now: Date,
        within days: Int = 60
    ) -> [InsuranceContract] {
        contracts
            .filter { contract in
                guard contract.isActive, let deadline = contract.cancellationDeadline else { return false }
                return deadline >= now && deadline.timeIntervalSince(now) < Double(days) * 86_400
            }
            .sorted { ($0.cancellationDeadline ?? now) < ($1.cancellationDeadline ?? now) }
    }

    // MARK: - Pension totals

    /// Capital per pillar (active positions), in pillar order.
    func pensionTotalsByPillar(assets: [PensionAsset]) -> [(pillar: PensionPillar, total: Decimal)] {
        PensionPillar.allCases.compactMap { pillar in
            let total = assets
                .filter { $0.isActive && $0.pillar == pillar }
                .reduce(Decimal.zero) { $0 + $1.currentValue }
            return total > 0 ? (pillar, total) : nil
        }
    }

    /// Grand total — by construction the exact sum of the pillar totals.
    func totalPensionCapital(assets: [PensionAsset]) -> Decimal {
        assets.filter(\.isActive).reduce(.zero) { $0 + $1.currentValue }
    }

    func totalAnnualContributions(assets: [PensionAsset]) -> Decimal {
        assets.filter(\.isActive).reduce(.zero) { $0 + $1.annualContribution }
    }

    /// Sum of certificate projections, only when EVERY active position has
    /// one — a partial sum would be misleading.
    func totalProjectedAtRetirement(assets: [PensionAsset]) -> Decimal? {
        let active = assets.filter(\.isActive)
        guard !active.isEmpty else { return nil }
        var total: Decimal = .zero
        for asset in active {
            guard let projected = asset.projectedValueAtRetirement else { return nil }
            total += projected
        }
        return total
    }
}
