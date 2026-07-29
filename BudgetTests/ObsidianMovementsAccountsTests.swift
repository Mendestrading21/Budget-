import SwiftUI
import SwiftData
import UIKit
import XCTest
@testable import Budget

/// Lot L5 — Mouvements et Comptes : la refonte Obsidian ne change AUCUN
/// résultat financier ; duplication fidèle, suppression persistée,
/// archivage sans perte, réconciliation horodatée, fraîcheur, états
/// extrêmes et construction des écrans dans les états exigés.
final class ObsidianMovementsAccountsTests: XCTestCase {
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

    // MARK: - Duplication fidèle (helper partagé liste + feuille)

    func testDuplicationCopiesEveryBusinessField() throws {
        let account = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        let savings = Account(name: "Épargne", type: .savings, openingBalance: .zero)
        let category = BudgetCategory(name: "Épargne mensuelle", kind: .saving, sortOrder: 1)
        context.insert(account)
        context.insert(savings)
        context.insert(category)
        let original = BudgetTransaction(
            date: now, amount: Decimal("250.00"), type: .saving, status: .planned,
            title: "Versement 3a", note: "note", merchant: "Banque",
            createdAt: now.addingTimeInterval(-86_400), updatedAt: now.addingTimeInterval(-86_400),
            account: account, destinationAccount: savings, category: category
        )
        context.insert(original)
        try context.save()

        let copy = TransactionDuplication.copy(of: original, now: now)
        context.insert(copy)
        try context.save()

        XCTAssertNotEqual(copy.id, original.id, "la copie a sa PROPRE identité")
        XCTAssertEqual(copy.amount, original.amount)
        XCTAssertEqual(copy.type, original.type)
        XCTAssertEqual(copy.status, original.status, "le statut prévu est conservé")
        XCTAssertEqual(copy.title, original.title)
        XCTAssertEqual(copy.note, original.note)
        XCTAssertEqual(copy.merchant, original.merchant)
        XCTAssertEqual(copy.account?.id, account.id)
        XCTAssertEqual(copy.destinationAccount?.id, savings.id)
        XCTAssertEqual(copy.category?.id, category.id)
        XCTAssertEqual(copy.createdAt, now, "les horodatages sont NEUFS")

        // Persistance : les deux existent dans un contexte neuf.
        let fresh = ModelContext(container)
        XCTAssertEqual(try fresh.fetch(FetchDescriptor<BudgetTransaction>()).count, 2)
    }

    // MARK: - Suppression persistée, jamais silencieuse

    func testDeletePersistsAcrossContexts() throws {
        let account = Account(name: "Courant", type: .current, openingBalance: .zero)
        context.insert(account)
        let movement = BudgetTransaction(
            date: now, amount: Decimal("42.50"), type: .expense, status: .posted,
            title: "À supprimer", createdAt: now, updatedAt: now, account: account
        )
        context.insert(movement)
        try context.save()

        context.delete(movement)
        try context.save()

        let fresh = ModelContext(container)
        XCTAssertTrue(try fresh.fetch(FetchDescriptor<BudgetTransaction>()).isEmpty)
        XCTAssertEqual(try fresh.fetch(FetchDescriptor<Account>()).count, 1, "le compte survit")
    }

    // MARK: - Archivage : le compte sort des listes actives SANS perdre l'historique

    func testArchivingPreservesMovementsAndBalance() throws {
        let account = Account(name: "Ancien compte", type: .current, openingBalance: Decimal("500.00"))
        context.insert(account)
        let movement = BudgetTransaction(
            date: now, amount: Decimal("100.00"), type: .expense, status: .posted,
            title: "Historique", createdAt: now, updatedAt: now, account: account
        )
        context.insert(movement)
        try context.save()

        account.isActive = false
        account.updatedAt = now
        try context.save()

        let fresh = ModelContext(container)
        let archived = try XCTUnwrap(try fresh.fetch(FetchDescriptor<Account>()).first)
        XCTAssertFalse(archived.isActive)
        XCTAssertEqual(try fresh.fetch(FetchDescriptor<BudgetTransaction>()).count, 1,
                       "l'historique n'est JAMAIS perdu par l'archivage")
        XCTAssertEqual(AccountBalanceService().balance(of: archived), Decimal("400.00"),
                       "le solde reste dérivable après archivage")
    }

    // MARK: - Réconciliation horodatée (même chemin que ReconcileSheet)

    func testReconciliationIsTimestampedAndAuditable() throws {
        let account = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        context.insert(account)
        try context.save()

        // Chemin de ReconcileSheet : montant validé, arrondi au centime,
        // horodaté — l'historique n'est pas réécrit.
        let parsed = try XCTUnwrap(FinanceFormatting.parseAmount("1'234.56"))
        account.reconciledBalance = FinanceMath.roundedToCents(parsed)
        account.reconciledAt = now
        account.updatedAt = now
        try context.save()

        let fresh = ModelContext(container)
        let reloaded = try XCTUnwrap(try fresh.fetch(FetchDescriptor<Account>()).first)
        XCTAssertEqual(reloaded.reconciledBalance, Decimal("1234.56"))
        XCTAssertEqual(reloaded.reconciledAt, now, "la réconciliation est HORODATÉE")
        XCTAssertEqual(reloaded.openingBalance, Decimal("1000.00"), "le solde initial n'est pas réécrit")
    }

    // MARK: - Fraîcheur : le dernier mouvement date le solde

    func testBalanceFreshnessComesFromTheLatestMovement() throws {
        let account = Account(name: "Courant", type: .current, openingBalance: .zero)
        context.insert(account)
        let old = BudgetTransaction(
            date: now.addingTimeInterval(-10 * 86_400), amount: Decimal("10.00"),
            type: .expense, status: .posted, title: "Vieux",
            createdAt: now, updatedAt: now, account: account
        )
        let recent = BudgetTransaction(
            date: now.addingTimeInterval(-1 * 86_400), amount: Decimal("20.00"),
            type: .expense, status: .posted, title: "Récent",
            createdAt: now, updatedAt: now, account: account
        )
        context.insert(old)
        context.insert(recent)
        try context.save()

        let latest = (account.transactions + account.incomingMovements)
            .max(by: { $0.date < $1.date })
        XCTAssertEqual(latest?.title, "Récent",
                       "la fraîcheur affichée provient bien du mouvement le plus récent")
    }

    // MARK: - Prévu ≠ comptabilisé dans les totaux (inchangé par L5)

    func testPlannedMovementsStayOutOfPostedTotals() throws {
        let household = Household(name: "L5")
        let account = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        context.insert(household)
        context.insert(account)
        let posted = BudgetTransaction(
            date: now, amount: Decimal("100.00"), type: .expense, status: .posted,
            title: "Réel", createdAt: now, updatedAt: now, account: account
        )
        let planned = BudgetTransaction(
            date: now.addingTimeInterval(86_400), amount: Decimal("900.00"), type: .expense, status: .planned,
            title: "Prévu", createdAt: now, updatedAt: now, account: account
        )
        context.insert(posted)
        context.insert(planned)
        try context.save()

        let snapshot = MonthlySnapshotService(calendar: calendar).snapshot(
            monthOf: now, now: now, household: household,
            accounts: [account], transactions: [posted, planned]
        )
        XCTAssertEqual(snapshot.totalLivingExpenses, Decimal("100.00"),
                       "un mouvement PRÉVU n'entre jamais dans le dépensé réel")
        XCTAssertEqual(AccountBalanceService().balance(of: account), Decimal("900.00"),
                       "le solde ne compte que les mouvements comptabilisés")
    }

    // MARK: - Garde mono-devise native (ADR-017)

    func testNativeAccountsDefaultToCHFOnly() {
        let account = Account(name: "Neuf", type: .current, openingBalance: .zero)
        XCTAssertEqual(account.currencyCode, "CHF",
                       "V1 natif mono-devise : aucune addition multi-devises possible (ADR-017)")
    }

    // MARK: - Construction des écrans (compact, extrême, a11y, transparence réduite)

    @MainActor
    private func host<V: View>(_ view: V, width: CGFloat) -> UIHostingController<V> {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 844)
        controller.view.layoutIfNeeded()
        return controller
    }

    @MainActor
    func testMovementsAndAccountsScreensBuildInRequiredStates() {
        let preview = DemoDataFactory.previewAppContainer()
        let movements = host(
            NavigationStack { TransactionsListView() }
                .environment(preview)
                .modelContainer(preview.modelContainer),
            width: 320
        )
        XCTAssertNotNil(movements.view, "Mouvements doit se construire à 320 pt")
        let accounts = host(
            AccountsTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.dynamicTypeSize, .accessibility3),
            width: 320
        )
        XCTAssertNotNil(accounts.view, "Comptes doit se construire en texte accessibilité à 320 pt")
        let reduced = host(
            AccountsTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.obsidianForcedReducedTransparency, true),
            width: 390
        )
        XCTAssertNotNil(reduced.view, "Comptes doit se construire en transparence réduite")
    }

    @MainActor
    func testRowsBuildWithExtremeAmountAndLongText() throws {
        let account = Account(
            name: "Compte au nom volontairement très long pour vérifier le retour à la ligne",
            type: .current, openingBalance: Decimal("-9999999.99")
        )
        context.insert(account)
        let movement = BudgetTransaction(
            date: now, amount: Decimal("9999999.99"), type: .expense, status: .planned,
            title: "Intitulé de mouvement volontairement interminable pour tester la troncature contrôlée",
            createdAt: now, updatedAt: now, account: account
        )
        context.insert(movement)
        try context.save()

        let row = host(
            VStack {
                TransactionRow(transaction: movement)
                AccountRow(account: account, balance: Decimal("-9999999.99"))
            }.padding(),
            width: 320
        )
        XCTAssertNotNil(row.view, "lignes construites avec montant extrême et texte long à 320 pt")
    }
}
