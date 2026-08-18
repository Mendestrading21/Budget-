import Foundation

/// One canonical rule for deciding whether a movement belongs to actuals.
///
/// Financial dates are day-based: a movement dated after today's calendar
/// day is planned, regardless of whether it is created manually, imported or
/// materialized from a recurring definition.
struct TransactionPostingPolicy {
    let calendar: Calendar

    func isFuture(_ date: Date, relativeTo now: Date) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: now)
    }

    func automaticStatus(for date: Date, now: Date) -> TransactionStatus {
        isFuture(date, relativeTo: now) ? .planned : .posted
    }

    // FE2 (décision propriétaire, 18.08.2026) : `promoteDueTransactions`
    // est supprimée — une date atteinte rend un mouvement prévu
    // « à confirmer », elle ne prouve jamais que l'argent a bougé.
    // `automaticStatus` reste : c'est le statut INITIAL d'une saisie datée
    // (saisir une dépense d'hier crée bien un mouvement comptabilisé).
}

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
    case missingContributionDestination
    case transferDestinationEqualsSource
    case inactiveDestination
    case destinationNotSupported

    var errorDescription: String? {
        switch self {
        case .missingDate:
            "Indiquez une date."
        case .postedDateInFuture:
            "Un mouvement déjà fait ne peut pas être daté dans le futur. Choisissez plutôt « Prévu »."
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
        case .missingContributionDestination:
            "Choisissez le compte qui reçoit cet argent. Mis de côté, il reste à vous."
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
    let postingPolicy: TransactionPostingPolicy

    init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        postingPolicy = TransactionPostingPolicy(calendar: calendar)
    }

    /// `allowInactiveAccounts` permits historical edits on archived accounts.
    func validate(
        _ draft: TransactionDraft,
        now: Date,
        allowInactiveAccounts: Bool = false
    ) -> [TransactionValidationError] {
        var errors: [TransactionValidationError] = []

        if let date = draft.date {
            if draft.status == .posted,
               postingPolicy.isFuture(date, relativeTo: now) {
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
        case .saving, .investment:
            // La destination est OBLIGATOIRE, et c'est un changement assumé
            // du 10.08.2026. « Mettre de côté » promet à l'utilisateur que
            // l'argent reste à lui ; sans compte d'arrivée, il sort du
            // compte source et n'atterrit nulle part, donc le patrimoine
            // baisse du montant réservé — l'exact contraire de la promesse.
            // Le web applique déjà cette règle ; les deux plateformes disent
            // désormais la même chose.
            if let destination = draft.destinationAccount {
                if destination.id == draft.account?.id {
                    errors.append(.transferDestinationEqualsSource)
                } else if !destination.isActive && !allowInactiveAccounts {
                    errors.append(.inactiveDestination)
                }
            } else {
                errors.append(.missingContributionDestination)
            }
        case .debtPayment:
            // Reste facultative : la destination est ici la dette remboursée,
            // et un remboursement sans dette suivie reste un cas réel.
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
