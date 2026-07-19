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
        let oldestMonthStart = monthStarts.last ?? now
        func anchorDay(_ day: Int) -> Date {
            calendar.date(byAdding: .day, value: day - 1, to: oldestMonthStart) ?? oldestMonthStart
        }

        // Recurring definitions matching the generated history, so the
        // month forecast dedupes against posted movements via recurringID.
        let salaryRecurring = RecurringTransaction(
            title: "Salaire", amount: Decimal("8450.00"), type: .income,
            firstOccurrence: anchorDay(25),
            account: currentAccount, category: category("Salaire"), member: owner
        )
        let rentRecurring = RecurringTransaction(
            title: "Loyer", amount: Decimal("2150.00"), type: .expense,
            firstOccurrence: anchorDay(1),
            account: currentAccount, category: category("Logement")
        )
        let healthRecurring = RecurringTransaction(
            title: "Primes maladie", amount: Decimal("745.60"), type: .expense,
            firstOccurrence: anchorDay(3),
            account: currentAccount, category: category("Assurance maladie")
        )
        let savingRecurring = RecurringTransaction(
            title: "Épargne mensuelle", amount: Decimal("600.00"), type: .saving,
            firstOccurrence: anchorDay(15),
            account: currentAccount, destinationAccount: savingsAccount,
            category: category("Épargne")
        )
        let streamingRecurring = RecurringTransaction(
            title: "Streaming vidéo", amount: Decimal("15.90"), type: .expense,
            firstOccurrence: anchorDay(10),
            isSubscription: true,
            renewalDate: calendar.date(byAdding: .day, value: 20, to: now),
            account: currentAccount, category: category("Abonnements")
        )
        let halfFareRecurring = RecurringTransaction(
            title: "Abonnement demi-tarif", amount: Decimal("190.00"), type: .expense,
            intervalUnit: .year, intervalCount: 1,
            firstOccurrence: calendar.date(byAdding: .month, value: -4, to: anchorDay(12)) ?? anchorDay(12),
            isSubscription: true,
            cancellationDeadline: calendar.date(byAdding: .day, value: 12, to: now),
            account: currentAccount, category: category("Transports")
        )
        let demoRecurrings = [
            salaryRecurring, rentRecurring, healthRecurring,
            savingRecurring, streamingRecurring, halfFareRecurring,
        ]
        for recurring in demoRecurrings {
            context.insert(recurring)
        }

        for monthStart in monthStarts {
            func day(_ day: Int) -> Date {
                calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
            }
            // Only movements up to `now` become history. The date guard runs
            // BEFORE constructing the model: linking a relationship to a
            // persisted account would auto-insert the object on save even
            // without an explicit context.insert.
            func addIfPast(day dayNumber: Int, _ build: (Date) -> BudgetTransaction) {
                let date = day(dayNumber)
                guard date <= now else { return }
                context.insert(build(date))
            }

            addIfPast(day: 25) { BudgetTransaction(
                date: $0, amount: Decimal("8450.00"), type: .income,
                title: "Salaire", recurringID: salaryRecurring.id,
                account: currentAccount,
                category: category("Salaire"), member: owner
            ) }
            addIfPast(day: 1) { BudgetTransaction(
                date: $0, amount: Decimal("2150.00"), type: .expense,
                title: "Loyer", recurringID: rentRecurring.id,
                account: currentAccount,
                category: category("Logement")
            ) }
            addIfPast(day: 3) { BudgetTransaction(
                date: $0, amount: Decimal("745.60"), type: .expense,
                title: "Primes maladie", recurringID: healthRecurring.id,
                account: currentAccount,
                category: category("Assurance maladie")
            ) }
            addIfPast(day: 10) { BudgetTransaction(
                date: $0, amount: Decimal("15.90"), type: .expense,
                title: "Streaming vidéo", recurringID: streamingRecurring.id,
                account: currentAccount,
                category: category("Abonnements")
            ) }
            addIfPast(day: 6) { BudgetTransaction(
                date: $0, amount: Decimal("512.35"), type: .expense,
                title: "Courses de la semaine", merchant: "Supermarché",
                account: currentAccount, category: category("Alimentation")
            ) }
            addIfPast(day: 8) { BudgetTransaction(
                date: $0, amount: Decimal("120.00"), type: .expense,
                title: "Abonnement transports", account: currentAccount,
                category: category("Transports")
            ) }
            addIfPast(day: 12) { BudgetTransaction(
                date: $0, amount: Decimal("98.50"), type: .expense,
                title: "Restaurant en famille", account: currentAccount,
                category: category("Restaurants et sorties")
            ) }
            addIfPast(day: 15) { BudgetTransaction(
                date: $0, amount: Decimal("600.00"), type: .saving,
                title: "Épargne mensuelle", recurringID: savingRecurring.id,
                account: currentAccount,
                destinationAccount: savingsAccount, category: category("Épargne")
            ) }
            addIfPast(day: 16) { BudgetTransaction(
                date: $0, amount: Decimal("587.00"), type: .investment,
                title: "Versement 3a", account: currentAccount,
                destinationAccount: pillar3a, category: category("Pilier 3a")
            ) }
            addIfPast(day: 20) { BudgetTransaction(
                date: $0, amount: Decimal("850.00"), type: .taxPayment,
                title: "Acompte d'impôts", account: currentAccount,
                category: category("Impôts")
            ) }
            addIfPast(day: 18) { BudgetTransaction(
                date: $0, amount: Decimal("200.00"), type: .transfer,
                title: "Retrait espèces", account: currentAccount,
                destinationAccount: cash
            ) }
        }

        // Monthly budgets mirroring the recurring demo movements, so the
        // budget tab and dashboard chart have planned-vs-actual content.
        let budgetTemplate: [(category: String, amount: Decimal)] = [
            ("Logement", Decimal("2150.00")),
            ("Assurance maladie", Decimal("750.00")),
            ("Alimentation", Decimal("650.00")),
            ("Transports", Decimal("150.00")),
            ("Restaurants et sorties", Decimal("250.00")),
            ("Épargne", Decimal("600.00")),
            ("Pilier 3a", Decimal("587.00")),
            ("Impôts", Decimal("850.00")),
        ]
        for monthStart in monthStarts {
            let components = calendar.dateComponents([.year, .month], from: monthStart)
            guard let year = components.year, let month = components.month else { continue }
            let budget = MonthlyBudget(year: year, month: month, createdAt: monthStart, updatedAt: monthStart)
            context.insert(budget)
            for entry in budgetTemplate {
                guard let matched = category(entry.category) else { continue }
                let line = BudgetLine(plannedAmount: entry.amount, category: matched, createdAt: monthStart, updatedAt: monthStart)
                line.budget = budget
                context.insert(line)
            }
        }

        // Tax profile and current-year provision with instalment deadlines.
        let taxProfile = TaxProfile(
            canton: SwissCanton.VD.rawValue,
            municipality: "Lausanne",
            provisionRate: Decimal("0.30"),
            createdAt: now,
            updatedAt: now
        )
        context.insert(taxProfile)
        let taxYear = calendar.component(.year, from: now)
        let provision = TaxProvision(
            year: taxYear,
            reservedAmount: Decimal("5200.00"),
            arrearsAmount: .zero,
            dueDates: [
                TaxDueDate(
                    date: calendar.date(byAdding: .day, value: 24, to: now) ?? now,
                    label: "Acompte cantonal"
                ),
                TaxDueDate(
                    date: calendar.date(byAdding: .day, value: 115, to: now) ?? now,
                    label: "Acompte cantonal"
                ),
            ],
            createdAt: now,
            updatedAt: now
        )
        provision.profile = taxProfile
        context.insert(provision)

        // Savings goals: linked, manual, and one tastefully achieved.
        let emergencyGoal = FinancialGoal(
            name: "Fonds d'urgence",
            kind: .emergencyFund,
            targetAmount: Decimal("20000.00"),
            plannedMonthlyContribution: Decimal("600.00"),
            priority: .high,
            createdAt: now, updatedAt: now,
            linkedAccount: savingsAccount
        )
        let holidayGoal = FinancialGoal(
            name: "Vacances d'été",
            kind: .travel,
            targetAmount: Decimal("3000.00"),
            targetDate: calendar.date(byAdding: .month, value: 8, to: now),
            manualCurrentAmount: Decimal("1200.00"),
            plannedMonthlyContribution: Decimal("150.00"),
            createdAt: now, updatedAt: now
        )
        // Tracks this year's contributions only, so no account link — the
        // 3a balance also contains previous years.
        let pillarGoal = FinancialGoal(
            name: "Pilier 3a 2026",
            kind: .pillar3a,
            targetAmount: Decimal("7056.00"),
            targetDate: calendar.date(from: DateComponents(
                year: calendar.component(.year, from: now), month: 12, day: 31
            )),
            manualCurrentAmount: Decimal("3522.00"),
            plannedMonthlyContribution: Decimal("587.00"),
            createdAt: now, updatedAt: now
        )
        let bikeGoal = FinancialGoal(
            name: "Nouveau vélo",
            kind: .custom,
            emoji: "🚲",
            targetAmount: Decimal("800.00"),
            manualCurrentAmount: Decimal("800.00"),
            status: .achieved,
            createdAt: now, updatedAt: now
        )
        for goal in [emergencyGoal, holidayGoal, pillarGoal, bikeGoal] {
            context.insert(goal)
        }

        // Insurance register and pension positions.
        let lamalContract = InsuranceContract(
            insurerName: "Caisse Exemple",
            policyName: "LAMal famille",
            kind: .healthBase,
            premiumAmount: Decimal("745.60"),
            premiumUnit: .month,
            deductible: Decimal("2500.00"),
            createdAt: now, updatedAt: now,
            member: owner
        )
        let liabilityContract = InsuranceContract(
            insurerName: "Assurance Exemple",
            policyName: "RC + ménage",
            kind: .householdContents,
            premiumAmount: Decimal("320.00"),
            premiumUnit: .year,
            deductible: Decimal("200.00"),
            renewalDate: calendar.date(byAdding: .month, value: 5, to: now),
            cancellationDeadline: calendar.date(byAdding: .day, value: 40, to: now),
            createdAt: now, updatedAt: now
        )
        context.insert(lamalContract)
        context.insert(liabilityContract)

        let lppAsset = PensionAsset(
            pillar: .pillar2,
            institutionName: "Caisse de pension Exemple",
            currentValue: Decimal("85000.00"),
            annualContribution: Decimal("9600.00"),
            projectedValueAtRetirement: Decimal("420000.00"),
            retirementAge: 65,
            sourceDocumentDate: calendar.date(byAdding: .month, value: -5, to: now),
            createdAt: now, updatedAt: now,
            owner: owner
        )
        let thirdPillarAsset = PensionAsset(
            pillar: .pillar3a,
            institutionName: "Fondation Exemple",
            currentValue: Decimal("18190.00"),
            annualContribution: Decimal("7044.00"),
            sourceDocumentDate: calendar.date(byAdding: .month, value: -1, to: now),
            createdAt: now, updatedAt: now,
            owner: owner
        )
        context.insert(lppAsset)
        context.insert(thirdPillarAsset)

        // Net worth: assets, one excluded to demo the toggle, a debt, and
        // six retroactive monthly snapshots for the trend chart.
        let car = Asset(
            name: "Voiture familiale", kind: .vehicle,
            currentValue: Decimal("12000.00"),
            valuationDate: calendar.date(byAdding: .month, value: -2, to: now),
            createdAt: now, updatedAt: now
        )
        let collection = Asset(
            name: "Collection de montres", kind: .collectible,
            currentValue: Decimal("3500.00"),
            includeInNetWorth: false,
            createdAt: now, updatedAt: now
        )
        let carLease = Liability(
            name: "Leasing voiture", kind: .leasing,
            outstandingAmount: Decimal("8400.00"),
            createdAt: now, updatedAt: now
        )
        context.insert(car)
        context.insert(collection)
        context.insert(carLease)

        for monthOffset in (1...6).reversed() {
            guard let snapshotDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
            // Accounts grow ~1'450/month; the other components stay flat,
            // so each snapshot reconciles: net = accounts + assets +
            // pension − liabilities.
            let accountsTotal = Decimal("34000.00") + Decimal((6 - monthOffset) * 1450)
            let assetsTotal = Decimal("12000.00")
            let pensionTotal = Decimal("95000.00")
            let liabilitiesTotal = Decimal("8400.00")
            context.insert(NetWorthSnapshot(
                date: snapshotDate,
                accountsTotal: accountsTotal,
                assetsTotal: assetsTotal,
                pensionTotal: pensionTotal,
                liabilitiesTotal: liabilitiesTotal,
                netWorth: accountsTotal + assetsTotal + pensionTotal - liabilitiesTotal
            ))
        }

        // Documents: metadata-only entries (no real files in demo).
        let lppDocument = FinancialDocument(
            title: "Certificat LPP 2026",
            kind: .pensionCertificate,
            year: calendar.component(.year, from: now),
            provider: "Caisse de pension Exemple",
            addedAt: now, updatedAt: now,
            member: owner
        )
        let policyDocument = FinancialDocument(
            title: "Police RC ménage",
            kind: .insurancePolicy,
            year: calendar.component(.year, from: now),
            provider: "Assurance Exemple",
            addedAt: now, updatedAt: now
        )
        context.insert(lppDocument)
        context.insert(policyDocument)

        do {
            try context.save()
        } catch {
            assertionFailure("Demo data save failed: \(error)")
        }
    }

    /// Fixed reference date for deterministic previews: 15.06.2026 12:00 UTC.
    static let previewReferenceDate = Date(timeIntervalSince1970: 1_781_524_800)

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
