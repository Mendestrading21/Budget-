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
        liabilities: [Liability],
        baseCurrency: String = "CHF",
        fxQuotes: [FxQuote] = [],
        asOf date: Date = Date()
    ) -> NetWorthBreakdown {
        // W4.2b (ADR-065, FI-16/17) : un compte dans une autre devise
        // n'entre dans le patrimoine qu'avec une quote datée — jamais
        // 1:1 ; sans quote il est EXCLU (l'état « incomplet » visible
        // arrive en W4.7).
        let conversion = CurrencyConversionService()
        return NetWorthBreakdown(
            accountsTotal: accounts
                .filter { $0.isActive && $0.includeInNetWorth }
                .reduce(.zero) { partial, compte in
                    let solde = balanceService.balance(of: compte)
                    guard let converti = conversion.convert(
                        solde, from: compte.currencyCode, to: baseCurrency,
                        quotes: fxQuotes, on: date) else { return partial }
                    return partial + converti
                },
            assetsTotal: assets
                .filter(\.includeInNetWorth)
                .reduce(.zero) { $0 + $1.currentValue },
            // ADR-036 : une estimation de rente (1er pilier) n'est pas un
            // capital — elle n'entre jamais dans le patrimoine.
            pensionTotal: pensions
                .filter { $0.isActive && !InsurancePensionService.isAnnuity($0) }
                .reduce(.zero) { $0 + $1.currentValue },
            liabilitiesTotal: liabilities
                .filter(\.includeInNetWorth)
                .reduce(.zero) { $0 + $1.outstandingAmount }
        )
    }

    /// FE2-4 : « Épargne accessible » — le STOCK des comptes d'épargne
    /// actifs, même définition que la PWA (les titres, la prévoyance et
    /// le quotidien n'en font pas partie).
    func accessibleSavings(accounts: [Account]) -> Decimal {
        accounts
            .filter { $0.isActive && $0.type == .savings }
            .reduce(.zero) { $0 + balanceService.balance(of: $1) }
    }

    /// FE2-4 : « Fortune liquide » — l'argent mobilisable vite :
    /// disponible au quotidien + épargne accessible. Un compte qui porte
    /// les deux qualités n'est compté qu'UNE fois.
    func liquidWealth(accounts: [Account]) -> Decimal {
        accounts
            .filter { $0.isActive && ($0.includeInAvailableCash || $0.type == .savings) }
            .reduce(.zero) { $0 + balanceService.balance(of: $1) }
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
