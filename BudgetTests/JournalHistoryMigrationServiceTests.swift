import XCTest
import SwiftData
@testable import Budget

/// W3.7 (ADR-064) — la migration de l'historique : essai à blanc
/// inerte, migration réelle prouvée et idempotente, refus atomique,
/// jamais d'allumage, survie sur store disque.
final class JournalHistoryMigrationServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: JournalHistoryMigrationService!
    private var courant: Account!
    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        service = JournalHistoryMigrationService()
        courant = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        context.insert(courant)
        context.insert(BudgetTransaction(
            date: now.addingTimeInterval(-60 * 86_400), amount: Decimal("6500.00"),
            type: .income, title: "Salaire ancien", account: courant))
        context.insert(BudgetTransaction(
            date: now.addingTimeInterval(-30 * 86_400), amount: Decimal("1500.00"),
            type: .expense, title: "Loyer ancien", account: courant))
        try context.save()
    }

    override func tearDown() {
        courant = nil; service = nil; context = nil; container = nil
    }

    // L'essai à blanc raconte tout et n'écrit RIEN.
    func testDryRunTellsEverythingAndWritesNothing() throws {
        let rapport = service.migrer(essai: true, now: now, context: context)
        XCTAssertTrue(rapport.essai)
        XCTAssertFalse(rapport.applique)
        XCTAssertEqual(rapport.creees, 3, "2 mouvements + 1 ouverture")
        XCTAssertEqual(rapport.refus, [])
        XCTAssertEqual(rapport.ecarts, [])
        XCTAssertTrue(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty,
                      "l'essai à blanc est INERTE")
    }

    // La migration réelle applique, prouve zéro écart, et re-migrer ne
    // crée rien.
    func testRealMigrationAppliesProvesAndIsIdempotent() throws {
        let reel = service.migrer(essai: false, now: now, context: context)
        XCTAssertTrue(reel.applique)
        XCTAssertEqual(reel.creees, 3)
        XCTAssertEqual(JournalComparatorService().comparer(now: now, context: context), [])
        let encore = service.migrer(essai: false, now: now, context: context)
        XCTAssertTrue(encore.applique)
        XCTAssertEqual(encore.creees, 0, "idempotent : rien de nouveau")
        // ADR-064 : jamais d'allumage — la migration ne touche pas la porte.
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "w37-tests-\(UUID().uuidString)"))
        XCTAssertFalse(JournalReadSwitch.estActif(defaults: defaults))
    }

    // Un historique intraduisible refuse TOUT — rapport nommé, rien ne
    // change (atomique).
    func testUntranslatableHistoryRefusesAtomically() throws {
        context.insert(BudgetTransaction(
            date: now, amount: Decimal("200.00"), type: .saving,
            title: "Perdu ancien", account: courant))
        try context.save()
        let rapport = service.migrer(essai: false, now: now, context: context)
        XCTAssertFalse(rapport.applique)
        XCTAssertTrue(rapport.refus.contains { $0.contains("Perdu ancien") },
                      "le refus est nommé : \(rapport.refus)")
        XCTAssertTrue(rapport.ecarts.contains { $0.contains("Courant") },
                      "l'écart prévu est nommé : \(rapport.ecarts)")
        XCTAssertTrue(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty,
                      "RIEN ne change — atomique")
    }

    // FI-35 : la migration survit sur store DISQUE — les écritures
    // migrées se relisent après réouverture, les données sont intactes.
    func testMigrationSurvivesOnDiskStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("w37-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Budget.store")

        var compteID: UUID!
        do {
            let disque = try ModelContainer(
                for: Schema(versionedSchema: BudgetSchemaV12.self),
                configurations: [ModelConfiguration(url: storeURL)])
            let contexte = ModelContext(disque)
            let compte = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
            compteID = compte.id
            contexte.insert(compte)
            contexte.insert(BudgetTransaction(
                date: now, amount: Decimal("42.50"), type: .expense,
                title: "Ancien", account: compte))
            try contexte.save()
            let rapport = JournalHistoryMigrationService().migrer(essai: false, now: now, context: contexte)
            XCTAssertTrue(rapport.applique)
        }

        let relu = try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV12.self),
            configurations: [ModelConfiguration(url: storeURL)])
        let contexte = ModelContext(relu)
        let entrees = try contexte.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(entrees.count, 2, "mouvement + ouverture, relus depuis le disque")
        let comptes = try contexte.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(comptes.first?.openingBalance, Decimal("1000.00"),
                       "aucun montant ne change pendant la migration (FI-35)")
        XCTAssertNotNil(compteID)
        XCTAssertEqual(JournalComparatorService().comparer(now: now, context: contexte), [],
                       "zéro écart après réouverture")
    }
}
