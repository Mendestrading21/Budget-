import Foundation
import SwiftData

/// Net worth with its full, reconciling decomposition:
/// `netWorth = accounts + assets + pension − liabilities`.
struct NetWorthBreakdown: Equatable {
    /// Signed balances of included active accounts (debt accounts are
    /// negative and therefore counted exactly once, here).
    let accountsTotal: Decimal
    /// Included non-account assets.
    let assetsTotal: Decimal
    /// Active pension capital.
    let pensionTotal: Decimal
    /// Included standalone debts, stored positive.
    let liabilitiesTotal: Decimal

    var netWorth: Decimal {
        accountsTotal + assetsTotal + pensionTotal - liabilitiesTotal
    }
}

/// Full-household net worth arithmetic and daily trend snapshots.
struct NetWorthService {
    let calendar: Calendar
    let balanceService: AccountBalanceService

    init(calendar: Calendar, balanceService: AccountBalanceService = AccountBalanceService()) {
        self.calendar = calendar
        self.balanceService = balanceService
    }

    func breakdown(
        accounts: [Account],
        assets: [Asset],
        pensions: [PensionAsset],
        liabilities: [Liability]
    ) -> NetWorthBreakdown {
        NetWorthBreakdown(
            accountsTotal: accounts
                .filter { $0.isActive && $0.includeInNetWorth }
                .reduce(.zero) { $0 + balanceService.balance(of: $1) },
            assetsTotal: assets
                .filter(\.includeInNetWorth)
                .reduce(.zero) { $0 + $1.currentValue },
            pensionTotal: pensions
                .filter(\.isActive)
                .reduce(.zero) { $0 + $1.currentValue },
            liabilitiesTotal: liabilities
                .filter(\.includeInNetWorth)
                .reduce(.zero) { $0 + $1.outstandingAmount }
        )
    }

    /// Records today's snapshot unless one already exists for this
    /// calendar day. Returns the recorded snapshot, or nil when today is
    /// already covered.
    @discardableResult
    func recordSnapshotIfNeeded(
        breakdown: NetWorthBreakdown,
        existing: [NetWorthSnapshot],
        now: Date,
        context: ModelContext
    ) throws -> NetWorthSnapshot? {
        let today = calendar.startOfDay(for: now)
        let alreadyRecorded = existing.contains {
            calendar.startOfDay(for: $0.date) == today
        }
        guard !alreadyRecorded else { return nil }

        let snapshot = NetWorthSnapshot(
            date: now,
            accountsTotal: breakdown.accountsTotal,
            assetsTotal: breakdown.assetsTotal,
            pensionTotal: breakdown.pensionTotal,
            liabilitiesTotal: breakdown.liabilitiesTotal,
            netWorth: breakdown.netWorth
        )
        context.insert(snapshot)
        try context.saveOrRollback()
        return snapshot
    }

    /// Chronological trend points for the chart.
    func trend(snapshots: [NetWorthSnapshot]) -> [NetWorthSnapshot] {
        snapshots.sorted { $0.date < $1.date }
    }
}
