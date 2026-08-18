import SwiftUI
import SwiftData
import UIKit
import XCTest
@testable import Budget

/// Pilote iOS Obsidian Glass (L4) : les trois parcours refondus — Mois,
/// Budget, Ajouter un mouvement — n'introduisent AUCUNE formule financière
/// et se construisent dans tous les états exigés (compact, montant extrême,
/// texte agrandi, transparence réduite).
final class ObsidianPilotTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!

    // 15.06.2026 12:00 UTC — même référence déterministe que les fixtures.
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
    }

    override func tearDown() {
        context = nil
        container = nil
        calendar = nil
    }

    private func makeSnapshot(
        household: Household?, accounts: [Account],
        transactions: [BudgetTransaction], recurrings: [RecurringTransaction] = []
    ) -> MonthSnapshot {
        MonthlySnapshotService(calendar: calendar).snapshot(
            monthOf: now, now: now, household: household,
            accounts: accounts, transactions: transactions,
            recurrings: recurrings, taxProfile: nil, taxProvisions: []
        )
    }

    // MARK: - « À payer » : agrégat d'affichage, aucune formule nouvelle

    func testToPayDisplayIsExactlyTheSumOfExistingComponents() throws {
        let household = Household(name: "Pilote")
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        context.insert(household)
        context.insert(current)
        // Une charge PLANIFIÉE du mois (engagée, pas encore comptabilisée).
        let planned = BudgetTransaction(
            date: now.addingTimeInterval(5 * 86_400), amount: Decimal("321.45"),
            type: .expense, status: .planned, title: "Facture prévue",
            createdAt: now, updatedAt: now, account: current
        )
        context.insert(planned)
        try context.save()

        let snapshot = makeSnapshot(household: household, accounts: [current], transactions: [planned])
        let toPay = HomePilotDisplay.toPay(snapshot.available)
        XCTAssertEqual(
            toPay,
            snapshot.available.committedCharges
                + snapshot.available.recurringCharges
                + snapshot.available.taxMonthlyEffort,
            "« À payer » doit être la somme EXACTE des composantes déjà calculées"
        )
        XCTAssertEqual(
            snapshot.available.committedCharges, Decimal("321.45"),
            "la charge planifiée nourrit les charges engagées, comme avant le pilote"
        )
    }

    /// Le pilote n'a modifié AUCUN résultat financier : l'identité du
    /// disponible (composantes → total) et la séparation épargne/vie
    /// tiennent exactement comme avant la refonte.
    func testFinancialResultsUnchangedByRedesign() throws {
        let household = Household(name: "Pilote")
        let current = Account(name: "Courant", type: .current, openingBalance: Decimal("4000.00"))
        let savings = Account(name: "Épargne", type: .savings, openingBalance: Decimal("1000.00"))
        context.insert(household)
        context.insert(current)
        context.insert(savings)
        let expense = BudgetTransaction(
            date: now, amount: Decimal("150.00"), type: .expense, status: .posted,
            title: "Courses", createdAt: now, updatedAt: now, account: current
        )
        let saving = BudgetTransaction(
            date: now, amount: Decimal("200.00"), type: .saving, status: .posted,
            title: "Mise de côté", createdAt: now, updatedAt: now,
            account: current, destinationAccount: savings
        )
        context.insert(expense)
        context.insert(saving)
        try context.save()

        let snapshot = makeSnapshot(
            household: household, accounts: [current, savings],
            transactions: [expense, saving]
        )
        // Identité du disponible : total = somme signée des composantes.
        let expected = snapshot.available.liquidBalance
            + snapshot.available.expectedIncome
            + snapshot.available.recurringIncome
            - snapshot.available.committedCharges
            - snapshot.available.recurringCharges
            - snapshot.available.taxMonthlyEffort
        XCTAssertEqual(snapshot.available.total, expected, "identité du disponible inchangée")
        // L'épargne n'est JAMAIS une dépense de vie.
        XCTAssertEqual(snapshot.totalLivingExpenses, Decimal("150.00"))
        XCTAssertEqual(snapshot.totalSavings, Decimal("200.00"))
    }

    // MARK: - Mouvement valide, erreur récupérable, virement, persistance

    func testValidMovementSavesAndSurvivesAFreshContext() throws {
        let account = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        let category = BudgetCategory(name: "Alimentation", kind: .expense, sortOrder: 1)
        context.insert(account)
        context.insert(category)
        try context.save()

        // Même chemin que la feuille : brouillon → validation → insertion.
        let service = TransactionValidationService()
        let draft = TransactionDraft(
            date: now, amount: FinanceFormatting.parseAmount("45.50"),
            type: .expense, status: .posted,
            title: "Alimentation", // défaut = catégorie (intitulé facultatif)
            account: account, destinationAccount: nil, category: category,
            adjustmentIncreasesBalance: true
        )
        XCTAssertTrue(service.validate(draft, now: now, allowInactiveAccounts: false).isEmpty)
        let transaction = BudgetTransaction(
            date: now, amount: FinanceMath.roundedToCents(draft.amount ?? .zero),
            type: .expense, status: .posted, title: draft.title,
            createdAt: now, updatedAt: now, account: account, category: category
        )
        context.insert(transaction)
        try context.save()

        // Persistance : un contexte NEUF sur le même store retrouve tout.
        let freshContext = ModelContext(container)
        let saved = try freshContext.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.amount, Decimal("45.50"))
        XCTAssertEqual(saved.first?.title, "Alimentation")
    }

    func testRecoverableValidationErrorLeavesNothingBehind() throws {
        let account = Account(name: "Courant", type: .current, openingBalance: .zero)
        context.insert(account)
        try context.save()

        let service = TransactionValidationService()
        // Montant illisible → erreur typée, AUCUNE écriture.
        let draft = TransactionDraft(
            date: now, amount: FinanceFormatting.parseAmount("abc"),
            type: .expense, status: .posted, title: "Essai",
            account: account, destinationAccount: nil, category: nil,
            adjustmentIncreasesBalance: true
        )
        let errors = service.validate(draft, now: now, allowInactiveAccounts: false)
        XCTAssertFalse(errors.isEmpty, "un montant illisible doit produire une erreur typée")
        let all = try context.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertTrue(all.isEmpty, "une validation en échec n'écrit jamais rien")
    }

    func testTransferStaysNeutralThroughThePilotPath() throws {
        let source = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        let destination = Account(name: "Épargne", type: .savings, openingBalance: Decimal("500.00"))
        context.insert(source)
        context.insert(destination)
        let transfer = BudgetTransaction(
            date: now, amount: Decimal("300.00"), type: .transfer, status: .posted,
            title: "Virement interne", createdAt: now, updatedAt: now,
            account: source, destinationAccount: destination
        )
        context.insert(transfer)
        try context.save()

        let snapshot = makeSnapshot(
            household: nil, accounts: [source, destination], transactions: [transfer]
        )
        XCTAssertEqual(snapshot.totalIncome, .zero, "un virement n'est pas un revenu")
        XCTAssertEqual(snapshot.totalLivingExpenses, .zero, "un virement n'est pas une dépense")
        XCTAssertEqual(snapshot.totalSavings, .zero, "un virement n'est pas une mise de côté")
        let balanceService = AccountBalanceService()
        XCTAssertEqual(
            balanceService.balance(of: source) + balanceService.balance(of: destination),
            Decimal("1500.00"),
            "la fortune totale ne bouge pas"
        )
    }

    // MARK: - Montant extrême

    func testExtremeAmountStaysExactInHeroFormatting() {
        let formatted = FinanceFormatting.chf(Decimal("-9999999.99"))
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        XCTAssertEqual(formatted, "-CHF 9'999'999.99")
    }

    // MARK: - Construction des trois écrans (états exigés)

    @MainActor
    private func host<V: View>(_ view: V, width: CGFloat) -> UIHostingController<V> {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 844)
        controller.view.layoutIfNeeded()
        return controller
    }

    @MainActor
    func testPilotScreensBuildInCompactWidth() {
        let preview = DemoDataFactory.previewAppContainer()
        let home = host(
            HomeTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer),
            width: 320
        )
        XCTAssertNotNil(home.view, "Mois doit se construire à 320 pt")
        let budget = host(
            BudgetTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer),
            width: 320
        )
        XCTAssertNotNil(budget.view, "Budget doit se construire à 320 pt")
        let form = host(
            TransactionFormView(mode: .create(prefilledAccount: nil))
                .environment(preview)
                .modelContainer(preview.modelContainer),
            width: 320
        )
        XCTAssertNotNil(form.view, "la feuille doit se construire à 320 pt")
    }

    @MainActor
    func testPilotScreensBuildWithAccessibilityTextAndReducedTransparency() {
        let preview = DemoDataFactory.previewAppContainer()
        let accessible = host(
            HomeTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.dynamicTypeSize, .accessibility3),
            width: 390
        )
        XCTAssertNotNil(accessible.view, "Mois doit se construire en texte accessibilité")
        let fallback = host(
            BudgetTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.obsidianForcedReducedTransparency, true),
            width: 390
        )
        XCTAssertNotNil(fallback.view, "Budget doit se construire en transparence réduite")
        let transferForm = host(
            TransactionFormView(mode: .create(prefilledAccount: nil), prefilledType: .transfer)
                .environment(preview)
                .modelContainer(preview.modelContainer)
                .environment(\.dynamicTypeSize, .accessibility3),
            width: 320
        )
        XCTAssertNotNil(transferForm.view, "la feuille virement doit se construire en texte agrandi")
    }
}
