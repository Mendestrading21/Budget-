import Foundation

/// Editable transaction fields before persistence.
struct TransactionDraft {
    var date: Date?
    var amount: Decimal?
    var type: TransactionType = .expense
    var status: TransactionStatus = .posted
    var title: String = ""
    var account: Account?
    var destinationAccount: Account?
    var category: BudgetCategory?
    var adjustmentIncreasesBalance: Bool = true
}

/// Typed domain errors with actionable French messages.
enum TransactionValidationError: LocalizedError, Equatable {
    case missingDate
    case postedDateInFuture
    case missingAmount
    case nonPositiveAmount
    case missingTitle
    case missingAccount
    case inactiveAccount
    case missingCategory
    case missingTransferDestination
    case transferDestinationEqualsSource
    case inactiveDestination
    case destinationNotSupported

    var errorDescription: String? {
        switch self {
        case .missingDate:
            "Indiquez une date."
        case .postedDateInFuture:
            "Un mouvement comptabilisé ne peut pas être daté dans le futur. Utilisez le statut « Prévu »."
        case .missingAmount:
            "Indiquez un montant. Exemple : 45.50"
        case .nonPositiveAmount:
            "Le montant doit être supérieur à zéro ; le sens du mouvement vient de son type."
        case .missingTitle:
            "Donnez un intitulé à ce mouvement."
        case .missingAccount:
            "Choisissez le compte concerné."
        case .inactiveAccount:
            "Ce compte est archivé. Réactivez-le ou choisissez un compte actif."
        case .missingCategory:
            "Choisissez une catégorie."
        case .missingTransferDestination:
            "Choisissez le compte de destination du virement."
        case .transferDestinationEqualsSource:
            "Le compte de destination doit être différent du compte source."
        case .inactiveDestination:
            "Le compte de destination est archivé. Choisissez un compte actif."
        case .destinationNotSupported:
            "Ce type de mouvement n'a pas de compte de destination."
        }
    }
}

/// Pure validation of the mandatory rules from the data-model spec.
struct TransactionValidationService {
    /// `allowInactiveAccounts` permits historical edits on archived accounts.
    func validate(
        _ draft: TransactionDraft,
        now: Date,
        allowInactiveAccounts: Bool = false
    ) -> [TransactionValidationError] {
        var errors: [TransactionValidationError] = []

        if let date = draft.date {
            // Grace of one day absorbs time zones and midnight edits.
            if draft.status == .posted,
               let tomorrow = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: now),
               date > tomorrow {
                errors.append(.postedDateInFuture)
            }
        } else {
            errors.append(.missingDate)
        }

        if let amount = draft.amount {
            if amount <= 0 {
                errors.append(.nonPositiveAmount)
            }
        } else {
            errors.append(.missingAmount)
        }

        if draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.missingTitle)
        }

        if let account = draft.account {
            if !account.isActive && !allowInactiveAccounts {
                errors.append(.inactiveAccount)
            }
        } else {
            errors.append(.missingAccount)
        }

        if categoryRequired(for: draft.type) && draft.category == nil {
            errors.append(.missingCategory)
        }

        switch draft.type {
        case .transfer:
            if let destination = draft.destinationAccount {
                if destination.id == draft.account?.id {
                    errors.append(.transferDestinationEqualsSource)
                } else if !destination.isActive && !allowInactiveAccounts {
                    errors.append(.inactiveDestination)
                }
            } else {
                errors.append(.missingTransferDestination)
            }
        case .saving, .investment, .debtPayment:
            // Destination optional: internal contribution when set — for
            // .debtPayment it is the debt account being paid down.
            if let destination = draft.destinationAccount {
                if destination.id == draft.account?.id {
                    errors.append(.transferDestinationEqualsSource)
                } else if !destination.isActive && !allowInactiveAccounts {
                    errors.append(.inactiveDestination)
                }
            }
        default:
            if draft.destinationAccount != nil {
                errors.append(.destinationNotSupported)
            }
        }

        return errors
    }

    /// Transfers and adjustments describe pure money movements between own
    /// accounts; every household flow type needs a category.
    func categoryRequired(for type: TransactionType) -> Bool {
        switch type {
        case .transfer, .adjustment: false
        default: true
        }
    }
}
