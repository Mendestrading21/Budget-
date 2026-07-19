import Foundation
import SwiftData
import Observation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case household
    case location
    case taxRate
    case firstAccount

    var progressIndex: Int { rawValue }

    static var progressTotal: Int { allCases.count }
}

/// Orchestrates the progressive onboarding flow and creates the initial
/// profile in one save when the user finishes.
@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome

    // Ménage
    var householdName: String = ""
    var ownerFirstName: String = ""
    var partnerFirstName: String = ""

    // Localisation
    var canton: SwissCanton = .VD
    var municipality: String = ""

    // Impôts — fraction (0.30 = 30 %)
    var taxProvisionRate: Decimal = Decimal("0.30")

    // Premier compte
    var accountName: String = "Compte courant"
    var accountType: AccountType = .current
    var openingBalanceText: String = ""

    var validationMessage: String?

    var openingBalance: Decimal? {
        let trimmed = openingBalanceText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .zero }
        return FinanceFormatting.parseAmount(trimmed)
    }

    /// Validates the current step; returns false and sets a French,
    /// actionable message when the user must correct something.
    func validateCurrentStep() -> Bool {
        validationMessage = nil
        switch step {
        case .welcome:
            return true
        case .household:
            if householdName.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage = "Donnez un nom à votre ménage, par exemple « Famille Martin »."
                return false
            }
            return true
        case .location:
            return true
        case .taxRate:
            if taxProvisionRate < 0 || taxProvisionRate > 1 {
                validationMessage = "Le taux doit être compris entre 0 % et 100 %."
                return false
            }
            return true
        case .firstAccount:
            if accountName.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage = "Donnez un nom à ce compte."
                return false
            }
            if openingBalance == nil {
                validationMessage = "Le solde initial n'est pas un montant valide. Exemple : 2'500.00"
                return false
            }
            return true
        }
    }

    func advance() {
        guard validateCurrentStep() else { return }
        if let next = OnboardingStep(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    func goBack() {
        validationMessage = nil
        if let previous = OnboardingStep(rawValue: step.rawValue - 1) {
            step = previous
        }
    }

    /// Creates the household, members, default categories and the first
    /// account. Called from the last step after validation.
    func finish(context: ModelContext, now: Date) throws {
        guard validateCurrentStep(), let openingBalance else { return }

        let household = Household(
            name: householdName.trimmingCharacters(in: .whitespaces),
            canton: canton.rawValue,
            municipality: municipality.trimmingCharacters(in: .whitespaces),
            taxProvisionRate: taxProvisionRate,
            createdAt: now,
            updatedAt: now
        )

        var members: [HouseholdMember] = []
        let trimmedOwner = ownerFirstName.trimmingCharacters(in: .whitespaces)
        if !trimmedOwner.isEmpty {
            members.append(HouseholdMember(firstName: trimmedOwner, role: .owner))
        }
        let trimmedPartner = partnerFirstName.trimmingCharacters(in: .whitespaces)
        if !trimmedPartner.isEmpty {
            members.append(HouseholdMember(firstName: trimmedPartner, role: .partner))
        }
        household.members = members
        context.insert(household)

        for category in DefaultCategories.makeCategories() {
            context.insert(category)
        }

        let account = Account(
            name: accountName.trimmingCharacters(in: .whitespaces),
            type: accountType,
            openingBalance: FinanceMath.roundedToCents(openingBalance),
            createdAt: now,
            updatedAt: now,
            owner: members.first
        )
        context.insert(account)

        try context.save()
    }
}
