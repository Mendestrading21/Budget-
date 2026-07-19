import Foundation
import SwiftData

/// Positive-amount convention: `amount` is always > 0 and the direction
/// comes from `type` (see AccountBalanceService). The only signed exception
/// is `adjustment`, which carries `adjustmentIncreasesBalance`.
enum TransactionType: String, CaseIterable, Codable, Identifiable {
    case income
    case expense
    case saving
    case investment
    case transfer
    case taxPayment
    case debtPayment
    case refund
    case adjustment

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .income: "Revenu"
        case .expense: "Dépense"
        case .saving: "Épargne"
        case .investment: "Investissement"
        case .transfer: "Virement interne"
        case .taxPayment: "Paiement d'impôts"
        case .debtPayment: "Remboursement de dette"
        case .refund: "Remboursement reçu"
        case .adjustment: "Ajustement"
        }
    }

    var systemImage: String {
        switch self {
        case .income: "arrow.down.circle"
        case .expense: "arrow.up.circle"
        case .saving: "building.columns"
        case .investment: "chart.line.uptrend.xyaxis"
        case .transfer: "arrow.left.arrow.right"
        case .taxPayment: "doc.text"
        case .debtPayment: "creditcard.and.123"
        case .refund: "arrow.uturn.down.circle"
        case .adjustment: "slider.horizontal.3"
        }
    }

    // Direction arithmetic lives in one place only:
    // AccountBalanceService.signedEffect(of:on:).

    /// Types that may route money into another owned account.
    var supportsDestinationAccount: Bool {
        switch self {
        case .transfer, .saving, .investment: true
        default: false
        }
    }
}

enum TransactionStatus: String, CaseIterable, Codable, Identifiable {
    /// Expected movement, not yet effective — never included in balances.
    case planned
    /// Effective movement included in balances and actuals.
    case posted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .planned: "Prévu"
        case .posted: "Comptabilisé"
        }
    }
}

@Model
final class BudgetTransaction {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Always positive; see the type-based direction convention above.
    var amount: Decimal
    var typeRawValue: String
    var statusRawValue: String
    var title: String
    var note: String?
    var merchant: String?

    /// Only meaningful for `type == .adjustment`.
    var adjustmentIncreasesBalance: Bool

    /// Source of a CSV import; used for idempotence (Phase 11).
    var importFingerprint: String?

    var createdAt: Date
    var updatedAt: Date

    /// Source account (inverse: Account.transactions).
    var account: Account?
    /// Destination for transfers and internal savings/investment
    /// contributions (inverse: Account.incomingMovements).
    var destinationAccount: Account?
    var category: BudgetCategory?
    var member: HouseholdMember?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    var status: TransactionStatus {
        get { TransactionStatus(rawValue: statusRawValue) ?? .posted }
        set { statusRawValue = newValue.rawValue }
    }

    /// True when money only moves between two owned accounts.
    var isInternalMovement: Bool {
        destinationAccount != nil
    }

    init(
        id: UUID = UUID(),
        date: Date,
        amount: Decimal,
        type: TransactionType,
        status: TransactionStatus = .posted,
        title: String,
        note: String? = nil,
        merchant: String? = nil,
        adjustmentIncreasesBalance: Bool = true,
        importFingerprint: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        account: Account? = nil,
        destinationAccount: Account? = nil,
        category: BudgetCategory? = nil,
        member: HouseholdMember? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.typeRawValue = type.rawValue
        self.statusRawValue = status.rawValue
        self.title = title
        self.note = note
        self.merchant = merchant
        self.adjustmentIncreasesBalance = adjustmentIncreasesBalance
        self.importFingerprint = importFingerprint
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.account = account
        self.destinationAccount = destinationAccount
        self.category = category
        self.member = member
    }
}
