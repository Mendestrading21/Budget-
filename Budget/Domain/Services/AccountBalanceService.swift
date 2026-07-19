import Foundation

/// Pure balance arithmetic. Balances derive from the opening balance (or the
/// latest explicit reconciliation point) plus the signed effect of every
/// posted movement — planned movements never touch balances.
struct AccountBalanceService {
    /// Signed effect of one transaction on one account, in the account's
    /// currency. Zero when the transaction does not involve the account or
    /// is only planned.
    func signedEffect(of transaction: BudgetTransaction, on account: Account) -> Decimal {
        guard transaction.status == .posted else { return .zero }

        var effect: Decimal = .zero

        if transaction.account?.id == account.id {
            switch transaction.type {
            case .income, .refund:
                effect += transaction.amount
            case .expense, .saving, .investment, .transfer, .taxPayment, .debtPayment:
                effect -= transaction.amount
            case .adjustment:
                effect += transaction.adjustmentIncreasesBalance
                    ? transaction.amount
                    : -transaction.amount
            }
        }

        if transaction.destinationAccount?.id == account.id {
            // Transfers and internal savings/investment contributions land here.
            effect += transaction.amount
        }

        return effect
    }

    /// Current balance from the account's own relationships.
    func balance(of account: Account) -> Decimal {
        balance(of: account, movements: account.transactions + account.incomingMovements)
    }

    /// Current balance given an explicit movement list (for tests and
    /// aggregate queries). Movements not touching the account are ignored.
    func balance(of account: Account, movements: [BudgetTransaction]) -> Decimal {
        let base: Decimal
        let since: Date?
        if let reconciledBalance = account.reconciledBalance, let reconciledAt = account.reconciledAt {
            base = reconciledBalance
            since = reconciledAt
        } else {
            base = account.openingBalance
            since = nil
        }

        var unique: [UUID: BudgetTransaction] = [:]
        for movement in movements {
            unique[movement.id] = movement
        }

        return unique.values.reduce(base) { partial, movement in
            if let since, movement.date <= since { return partial }
            return partial + signedEffect(of: movement, on: account)
        }
    }
}
