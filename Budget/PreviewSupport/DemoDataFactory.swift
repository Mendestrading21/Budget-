import Foundation
import SwiftData

/// Fictional demo data for demo mode and deterministic previews.
/// Only ever inserted into isolated in-memory containers — never into the
/// production store, and no real personal data appears here.
enum DemoDataFactory {
    /// Populates `container` with a fictional household, accounts,
    /// categories and roughly three months of movements ending at `now`.
    static func populate(container: ModelContainer, now: Date, calendar: Calendar) {
        let context = ModelContext(container)

        let household = Household(
            name: "Ménage Exemple",
            canton: SwissCanton.VD.rawValue,
            municipality: "Lausanne"
        )
        let owner = HouseholdMember(firstName: "Alex", role: .owner)
        let partner = HouseholdMember(firstName: "Camille", role: .partner)
        household.members = [owner, partner]
        context.insert(household)

        let categories = DefaultCategories.makeCategories()
        for category in categories {
            context.insert(category)
        }
        func category(_ name: String) -> BudgetCategory? {
            categories.first { $0.name == name }
        }

        let currentAccount = Account(
            name: "Compte ménage",
            institutionName: "Banque Exemple",
            type: .current,
            openingBalance: Decimal("4200.00"),
            isShared: true,
            owner: owner
        )
        let savingsAccount = Account(
            name: "Épargne",
            institutionName: "Banque Exemple",
            type: .savings,
            openingBalance: Decimal("12500.00")
        )
        let pillar3a = Account(
            name: "Pilier 3a",
            institutionName: "Fondation Exemple",
            type: .pillar3a,
            openingBalance: Decimal("18190.00")
        )
        let cash = Account(
            name: "Espèces",
            type: .cash,
            openingBalance: Decimal("150.00")
        )
        for account in [currentAccount, savingsAccount, pillar3a, cash] {
            context.insert(account)
        }

        // Three months of representative movements, anchored on `now`.
        let monthStarts: [Date] = (0..<3).compactMap { offset in
            guard let start = calendar.dateInterval(of: .month, for: now)?.start else { return nil }
            return calendar.date(byAdding: .month, value: -offset, to: start)
        }

        for monthStart in monthStarts {
            func day(_ day: Int) -> Date {
                calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
            }
            // Only movements up to `now` are posted history.
            func insertIfPast(_ transaction: BudgetTransaction) {
                guard transaction.date <= now else { return }
                context.insert(transaction)
            }

            insertIfPast(BudgetTransaction(
                date: day(25), amount: Decimal("8450.00"), type: .income,
                title: "Salaire", account: currentAccount,
                category: category("Salaire"), member: owner
            ))
            insertIfPast(BudgetTransaction(
                date: day(1), amount: Decimal("2150.00"), type: .expense,
                title: "Loyer", account: currentAccount,
                category: category("Logement")
            ))
            insertIfPast(BudgetTransaction(
                date: day(3), amount: Decimal("745.60"), type: .expense,
                title: "Primes maladie", account: currentAccount,
                category: category("Assurance maladie")
            ))
            insertIfPast(BudgetTransaction(
                date: day(6), amount: Decimal("512.35"), type: .expense,
                title: "Courses de la semaine", merchant: "Supermarché",
                account: currentAccount, category: category("Alimentation")
            ))
            insertIfPast(BudgetTransaction(
                date: day(8), amount: Decimal("120.00"), type: .expense,
                title: "Abonnement transports", account: currentAccount,
                category: category("Transports")
            ))
            insertIfPast(BudgetTransaction(
                date: day(12), amount: Decimal("98.50"), type: .expense,
                title: "Restaurant en famille", account: currentAccount,
                category: category("Restaurants et sorties")
            ))
            insertIfPast(BudgetTransaction(
                date: day(15), amount: Decimal("600.00"), type: .saving,
                title: "Épargne mensuelle", account: currentAccount,
                destinationAccount: savingsAccount, category: category("Épargne")
            ))
            insertIfPast(BudgetTransaction(
                date: day(16), amount: Decimal("587.00"), type: .investment,
                title: "Versement 3a", account: currentAccount,
                destinationAccount: pillar3a, category: category("Pilier 3a")
            ))
            insertIfPast(BudgetTransaction(
                date: day(20), amount: Decimal("850.00"), type: .taxPayment,
                title: "Acompte d'impôts", account: currentAccount,
                category: category("Impôts")
            ))
            insertIfPast(BudgetTransaction(
                date: day(18), amount: Decimal("200.00"), type: .transfer,
                title: "Retrait espèces", account: currentAccount,
                destinationAccount: cash
            ))
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Demo data save failed: \(error)")
        }
    }

    /// Fixed reference date for deterministic previews: 15.06.2026 12:00 UTC.
    static let previewReferenceDate = Date(timeIntervalSince1970: 1_781_524_800)

    /// In-memory container pre-populated with demo data at the fixed date —
    /// use in previews so they stay deterministic.
    static func previewContainer() -> ModelContainer {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = FinanceFormatting.locale
        do {
            let container = try PersistenceFactory.makeInMemoryContainer()
            populate(container: container, now: previewReferenceDate, calendar: calendar)
            return container
        } catch {
            fatalError("Preview container creation failed: \(error)")
        }
    }

    /// Full preview composition root: fixed "now" aligned with the demo
    /// history, isolated in-memory store already populated.
    static func previewAppContainer() -> AppContainer {
        do {
            let appContainer = try AppContainer(
                dateProvider: FixedDateProvider(now: previewReferenceDate),
                inMemory: true
            )
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = FinanceFormatting.locale
            populate(container: appContainer.modelContainer, now: previewReferenceDate, calendar: calendar)
            return appContainer
        } catch {
            fatalError("Preview app container creation failed: \(error)")
        }
    }
}
