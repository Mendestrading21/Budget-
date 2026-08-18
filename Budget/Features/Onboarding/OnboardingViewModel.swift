import Foundation
import SwiftData
import Observation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case household
    case location
    // A19 (parité PWA, lot A18) : plus d'étape « Provision d'impôts » —
    // le taux garde son défaut (30 %) et se règle dans Impôts, borné par
    // TaxService.maximumProvisionRate.
    case firstAccount
    /// Facultatif : salaire et loyer via les RecurringTransaction
    /// existantes — aucune nouvelle structure, même save atomique.
    case income

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

    // Revenus et logement — FACULTATIFS (vides = rien n'est créé).
    var salaryText: String = ""
    var salaryDay: Int = 25
    var rentText: String = ""
    var rentDay: Int = 1

    var validationMessage: String?

    var openingBalance: Decimal? {
        let trimmed = openingBalanceText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .zero }
        return FinanceFormatting.parseAmount(trimmed)
    }

    /// Champ de montant FACULTATIF : vide = rien, invalide = erreur
    /// visible (jamais transformé en zéro), valide = montant.
    enum OptionalAmount: Equatable {
        case empty
        case invalid
        case value(Decimal)
    }

    static func parseOptionalAmount(_ text: String) -> OptionalAmount {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .empty }
        guard let amount = FinanceFormatting.parseAmount(trimmed), amount > 0 else { return .invalid }
        return .value(amount)
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
        case .income:
            if Self.parseOptionalAmount(salaryText) == .invalid {
                validationMessage = "Le salaire n'est pas un montant valide. Exemple : 5'500.00 — ou laissez vide."
                return false
            }
            if Self.parseOptionalAmount(rentText) == .invalid {
                validationMessage = "Le loyer n'est pas un montant valide. Exemple : 1'800.00 — ou laissez vide."
                return false
            }
            return true
        }
    }

    /// « Passer » l'étape facultative : oublie les saisies partielles puis
    /// termine — aucune donnée facultative n'est créée.
    func skipIncome() {
        salaryText = ""
        rentText = ""
        validationMessage = nil
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

    /// Creates the household, members, default categories, the first
    /// account and the optional salary/rent recurrings — in ONE atomic
    /// save. Called from the last step after validation.
    func finish(context: ModelContext, calendar: Calendar, now: Date) throws {
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

        // Facultatif : salaire et loyer via RecurringTransaction — dans le
        // MÊME save. Un échec annule tout : aucune donnée partielle.
        func firstOccurrence(day: Int) -> Date {
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = min(max(1, day), 28)
            return calendar.date(from: components) ?? now
        }
        if case .value(let salary) = Self.parseOptionalAmount(salaryText) {
            context.insert(RecurringTransaction(
                title: "Salaire", amount: FinanceMath.roundedToCents(salary), type: .income,
                firstOccurrence: firstOccurrence(day: salaryDay),
                createdAt: now, updatedAt: now, account: account
            ))
        }
        if case .value(let rent) = Self.parseOptionalAmount(rentText) {
            context.insert(RecurringTransaction(
                title: "Loyer", amount: FinanceMath.roundedToCents(rent), type: .expense,
                firstOccurrence: firstOccurrence(day: rentDay),
                createdAt: now, updatedAt: now, account: account
            ))
        }

        try context.saveOrRollback()
    }
}
