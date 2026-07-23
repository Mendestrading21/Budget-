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
        context.insert(ImportBatch(fileName: "notion.csv", importedAt: now, totalRows: 3,
                                   importedCount: 2, duplicateCount: 1, invalidCount: 0,
                                   createdCategories: 0))
        try context.save()
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
        let batches = try freshContext.fetch(FetchDescriptor<ImportBatch>())
        XCTAssertEqual(batches.count, 1, "L'historique d'import (et ses poignées de rollback) voyage aussi")
        XCTAssertEqual(batches.first?.duplicateCount, 1)
    }

    func testRestoreNeverDeletesDocumentFiles() throws {
        try populateSampleStore()
        let fileStore = InMemoryDocumentFileStore()
        fileStore.store(Data("certificat".utf8), reference: "lpp.pdf")
        let documents = try context.fetch(FetchDescriptor<FinancialDocument>())
        documents.first?.fileReference = "lpp.pdf"
        try context.save()

        let data = try service.makeBackup(context: context, now: now)
        try service.restore(data: data, context: context, documentFileStore: fileStore)

        XCTAssertNotNil(fileStore.url(for: "lpp.pdf"),
                        "Les fichiers ne voyagent pas dans le JSON : la restauration ne doit JAMAIS les détruire")
        let restored = try context.fetch(FetchDescriptor<FinancialDocument>())
        XCTAssertTrue(restored.contains { $0.fileReference == "lpp.pdf" },
                      "La référence restaurée pointe toujours sur le fichier encore présent")
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

    /// P0 Obsidian L1 : quel que soit le champ corrompu, la restauration
    /// échoue d'un seul bloc — chaque entité survit (comptage complet),
    /// le store PERSISTANT reste intact (vérifié via un contexte neuf) et
    /// aucun montant n'est coercé vers zéro.
    private func assertRestoreRejectsTamperedBackup(
        mutate: (inout [String: Any]) -> Void,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        var json = try JSONSerialization.jsonObject(
            with: service.makeBackup(context: context, now: now)
        ) as! [String: Any]
        mutate(&json)
        let tampered = try JSONSerialization.data(withJSONObject: json)

        let before = try counts(in: context)
        XCTAssertThrowsError(
            try service.restore(data: tampered, context: context, documentFileStore: nil),
            file: file, line: line
        ) { error in
            guard case BackupError.corruptAmount(let raw) = error else {
                return XCTFail("Erreur attendue : corruptAmount, reçu \(error)", file: file, line: line)
            }
            XCTAssertEqual(raw, "pas-un-montant", file: file, line: line)
        }
        XCTAssertEqual(try counts(in: context), before,
                       "Toutes les entités survivent, aucune n'est perdue", file: file, line: line)
        // Un contexte NEUF lit le store réellement persisté : la
        // transaction annulée ne doit y avoir laissé aucune trace.
        let freshContext = ModelContext(container)
        XCTAssertEqual(try counts(in: freshContext), before,
                       "Le store persistant est intact après rollback", file: file, line: line)
        let zeroAmounts = try freshContext.fetch(FetchDescriptor<BudgetTransaction>())
            .filter { $0.amount == .zero }.count
        XCTAssertEqual(zeroAmounts, 0, "Aucun montant coercé vers zéro", file: file, line: line)
    }

    func testRestoreRejectsCorruptAmountWithoutCoercingToZero() throws {
        // Champ OBLIGATOIRE corrompu (transaction.amount).
        try populateSampleStore()
        try assertRestoreRejectsTamperedBackup { json in
            var transactions = json["transactions"] as! [[String: Any]]
            XCTAssertFalse(transactions.isEmpty)
            transactions[0]["amount"] = "pas-un-montant"
            json["transactions"] = transactions
        }
    }

    func testRestoreRejectsCorruptOptionalAmount() throws {
        // Champ OPTIONNEL corrompu (account.reconciledBalance) : le chemin
        // Optional.map(decimal) doit propager l'erreur, pas l'avaler.
        try populateSampleStore()
        let account = try XCTUnwrap(context.fetch(FetchDescriptor<Account>()).first)
        account.reconciledBalance = Decimal("123.45")
        try context.save()
        try assertRestoreRejectsTamperedBackup { json in
            var accounts = json["accounts"] as! [[String: Any]]
            let index = accounts.firstIndex { $0["reconciledBalance"] != nil }
            XCTAssertNotNil(index)
            accounts[index!]["reconciledBalance"] = "pas-un-montant"
            json["accounts"] = accounts
        }
        // Le solde réconcilié d'origine est toujours là, valeur exacte.
        let freshContext = ModelContext(container)
        let restored = try XCTUnwrap(freshContext.fetch(FetchDescriptor<Account>())
            .first { $0.reconciledBalance != nil })
        XCTAssertEqual(restored.reconciledBalance, Decimal("123.45"))
    }

    func testRestoreRejectsCorruptAmountInLateEntity() throws {
        // Entité reconstruite TARDIVEMENT (NetWorthSnapshot, en fin de
        // reconstruction) : l'erreur doit annuler aussi tout ce qui a été
        // reconstruit avant elle.
        try populateSampleStore()
        context.insert(NetWorthSnapshot(date: now, accountsTotal: Decimal("100.00"),
                                        assetsTotal: .zero, pensionTotal: .zero,
                                        liabilitiesTotal: .zero, netWorth: Decimal("100.00")))
        try context.save()
        try assertRestoreRejectsTamperedBackup { json in
            var snapshots = json["netWorthSnapshots"] as! [[String: Any]]
            XCTAssertFalse(snapshots.isEmpty)
            snapshots[0]["netWorth"] = "pas-un-montant"
            json["netWorthSnapshots"] = snapshots
        }
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

    private var suiteName: String!

    override func setUp() {
        auth = FakeAuthenticationService()
        suiteName = "AppLockManagerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        manager = AppLockManager(authService: auth, defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        manager = nil
        auth = nil
        defaults = nil
        suiteName = nil
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
