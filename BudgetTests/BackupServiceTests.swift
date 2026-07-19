import XCTest
import SwiftData
@testable import Budget

final class BackupServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private let service = BackupService()

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
    }

    override func tearDown() {
        calendar = nil
        context = nil
        container = nil
    }

    /// Small but representative store touching every relationship kind.
    private func populateSampleStore() throws {
        DemoDataFactory.populate(container: container, now: now, calendar: calendar)
        try context.save()
    }

    private func counts(in someContext: ModelContext) throws -> [String: Int] {
        [
            "households": try someContext.fetch(FetchDescriptor<Household>()).count,
            "accounts": try someContext.fetch(FetchDescriptor<Account>()).count,
            "categories": try someContext.fetch(FetchDescriptor<BudgetCategory>()).count,
            "transactions": try someContext.fetch(FetchDescriptor<BudgetTransaction>()).count,
            "budgets": try someContext.fetch(FetchDescriptor<MonthlyBudget>()).count,
            "lines": try someContext.fetch(FetchDescriptor<BudgetLine>()).count,
            "recurrings": try someContext.fetch(FetchDescriptor<RecurringTransaction>()).count,
            "taxProfiles": try someContext.fetch(FetchDescriptor<TaxProfile>()).count,
            "provisions": try someContext.fetch(FetchDescriptor<TaxProvision>()).count,
            "goals": try someContext.fetch(FetchDescriptor<FinancialGoal>()).count,
            "insurance": try someContext.fetch(FetchDescriptor<InsuranceContract>()).count,
            "pensions": try someContext.fetch(FetchDescriptor<PensionAsset>()).count,
            "assets": try someContext.fetch(FetchDescriptor<Asset>()).count,
            "liabilities": try someContext.fetch(FetchDescriptor<Liability>()).count,
            "snapshots": try someContext.fetch(FetchDescriptor<NetWorthSnapshot>()).count,
            "documents": try someContext.fetch(FetchDescriptor<FinancialDocument>()).count,
        ]
    }

    // MARK: - CSV export

    func testTransactionsCSVFormatAndEscaping() {
        let account = Account(name: "Compte; principal", type: .current)
        context.insert(account)
        let transaction = BudgetTransaction(
            date: now, amount: Decimal("2150.00"), type: .expense,
            title: "Loyer \"juin\"", note: "ligne1\nligne2", account: account
        )
        context.insert(transaction)

        let csv = service.transactionsCSV([transaction], calendar: calendar)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertEqual(lines[0], "date;type;statut;montant;devise;compte;vers_compte;categorie;intitule;note")
        XCTAssertTrue(csv.contains("2026-06-15;expense;posted;2150"))
        XCTAssertTrue(csv.contains("\"Compte; principal\""), "Le séparateur dans un champ est protégé")
        XCTAssertTrue(csv.contains("\"Loyer \"\"juin\"\"\""), "Les guillemets sont doublés")
    }

    // MARK: - Backup round-trip (acceptance: restore works, versioned)

    func testBackupRestoreRoundTripPreservesEverything() throws {
        try populateSampleStore()
        let before = try counts(in: context)
        XCTAssertGreaterThan(before["transactions"] ?? 0, 0)

        let data = try service.makeBackup(context: context, now: now)

        // Restore into a completely fresh store.
        let freshContainer = try PersistenceFactory.makeInMemoryContainer()
        let freshContext = ModelContext(freshContainer)
        try service.restore(data: data, context: freshContext, documentFileStore: nil)

        let after = try counts(in: freshContext)
        XCTAssertEqual(after, before, "Chaque entité survit au round-trip")

        // Spot-check relationships and Decimal precision.
        let accounts = try freshContext.fetch(FetchDescriptor<Account>())
        let current = try XCTUnwrap(accounts.first { $0.name == "Compte ménage" })
        XCTAssertEqual(current.openingBalance, Decimal("4200.00"), "Les montants String round-trippent exactement")
        let transactions = try freshContext.fetch(FetchDescriptor<BudgetTransaction>())
        let rent = try XCTUnwrap(transactions.first { $0.title == "Loyer" })
        XCTAssertEqual(rent.account?.id, current.id, "Les relations sont recousues par UUID")
        let lines = try freshContext.fetch(FetchDescriptor<BudgetLine>())
        XCTAssertTrue(lines.allSatisfy { $0.budget != nil && $0.category != nil })
        let provisions = try freshContext.fetch(FetchDescriptor<TaxProvision>())
        XCTAssertEqual(provisions.first?.dueDates.count, 2, "Les échéances Codable voyagent aussi")
    }

    func testRestoreReplacesExistingData() throws {
        try populateSampleStore()
        let data = try service.makeBackup(context: context, now: now)

        // Pollute the store, then restore: pollution must vanish.
        let stray = Account(name: "Compte parasite", type: .cash)
        context.insert(stray)
        try context.save()

        try service.restore(data: data, context: context, documentFileStore: nil)
        let accounts = try context.fetch(FetchDescriptor<Account>())
        XCTAssertFalse(accounts.contains { $0.name == "Compte parasite" })
        XCTAssertEqual(accounts.count, 4)
    }

    func testRestoreRejectsNewerSchema() throws {
        try populateSampleStore()
        var json = try JSONSerialization.jsonObject(
            with: service.makeBackup(context: context, now: now)
        ) as! [String: Any]
        json["schemaVersion"] = BackupService.currentSchemaVersion + 1
        let tampered = try JSONSerialization.data(withJSONObject: json)

        XCTAssertThrowsError(try service.restore(data: tampered, context: context, documentFileStore: nil)) { error in
            guard case BackupError.newerSchema(let found, let supported) = error else {
                return XCTFail("Erreur attendue : newerSchema, reçu \(error)")
            }
            XCTAssertEqual(found, BackupService.currentSchemaVersion + 1)
            XCTAssertEqual(supported, BackupService.currentSchemaVersion)
        }
        // Le store n'a pas été touché.
        XCTAssertGreaterThan(try context.fetch(FetchDescriptor<BudgetTransaction>()).count, 0)
    }

    func testRestoreRejectsCorruptData() throws {
        try populateSampleStore()
        XCTAssertThrowsError(
            try service.restore(data: Data("pas du json".utf8), context: context, documentFileStore: nil)
        ) { error in
            XCTAssertEqual(error as? BackupError, .unreadable)
        }
        XCTAssertGreaterThan(try context.fetch(FetchDescriptor<Household>()).count, 0, "Rien n'est effacé sur échec de lecture")
    }

    // MARK: - Complete deletion

    func testDeleteAllEmptiesEveryEntityAndDocumentFiles() throws {
        try populateSampleStore()
        let fileStore = InMemoryDocumentFileStore()
        fileStore.store(Data("certificat".utf8), reference: "lpp.pdf")
        let documents = try context.fetch(FetchDescriptor<FinancialDocument>())
        documents.first?.fileReference = "lpp.pdf"
        try context.save()

        try service.deleteAll(context: context, documentFileStore: fileStore)

        let after = try counts(in: context)
        XCTAssertTrue(after.values.allSatisfy { $0 == 0 }, "Tout est vide : \(after)")
        XCTAssertNil(fileStore.url(for: "lpp.pdf"), "Les fichiers de documents sont effacés aussi")
    }
}

// MARK: - App lock

final class AppLockManagerTests: XCTestCase {
    private var auth: FakeAuthenticationService!
    private var manager: AppLockManager!
    private var defaults: UserDefaults!

    override func setUp() {
        auth = FakeAuthenticationService()
        defaults = UserDefaults(suiteName: "AppLockManagerTests-\(UUID().uuidString)")
        manager = AppLockManager(authService: auth, defaults: defaults)
    }

    override func tearDown() {
        manager = nil
        auth = nil
        defaults = nil
    }

    func testDisabledByDefaultAndUnlocked() {
        XCTAssertFalse(manager.isLockEnabled)
        XCTAssertFalse(manager.isLocked)
        manager.lockIfEnabled()
        XCTAssertFalse(manager.isLocked, "Sans activation, jamais verrouillé")
    }

    func testEnablingRequiresSuccessfulAuthentication() async {
        auth.nextOutcome = .cancelled
        await manager.setEnabled(true)
        XCTAssertFalse(manager.isLockEnabled, "Annulé → rien ne change")

        auth.nextOutcome = .success
        await manager.setEnabled(true)
        XCTAssertTrue(manager.isLockEnabled)
    }

    func testLocksOnBackgroundAndUnlocksOnlyOnSuccess() async {
        auth.nextOutcome = .success
        await manager.setEnabled(true)

        manager.lockIfEnabled()
        XCTAssertTrue(manager.isLocked)

        // Annulation : reste verrouillé, sans message d'erreur.
        auth.nextOutcome = .cancelled
        await manager.attemptUnlock()
        XCTAssertTrue(manager.isLocked)
        XCTAssertNil(manager.lastErrorMessage)

        // Échec : reste verrouillé, avec message.
        auth.nextOutcome = .failed("Visage non reconnu.")
        await manager.attemptUnlock()
        XCTAssertTrue(manager.isLocked)
        XCTAssertEqual(manager.lastErrorMessage, "Visage non reconnu.")

        // Succès : déverrouillé.
        auth.nextOutcome = .success
        await manager.attemptUnlock()
        XCTAssertFalse(manager.isLocked)
    }

    func testStateSurvivesRelaunchThroughDefaults() async {
        auth.nextOutcome = .success
        await manager.setEnabled(true)

        // Nouveau manager sur les mêmes defaults = relance de l'app.
        let relaunched = AppLockManager(authService: auth, defaults: defaults)
        XCTAssertTrue(relaunched.isLockEnabled)
        XCTAssertTrue(relaunched.isLocked, "Verrouillé dès le lancement quand activé")
    }
}
