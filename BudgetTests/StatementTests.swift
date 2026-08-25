import XCTest
import SwiftData
@testable import Budget

/// W4.3 — le relevé : migration du point nu en relevé synthétique
/// MARQUÉ, idempotence, données de compte intactes, survie V13 → V14.
final class StatementTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    // Le point nu devient un relevé synthétique clairement marqué —
    // le compte, lui, ne bouge pas (balance() le lit jusqu'à W4.4).
    func testNakedPointBecomesAMarkedSyntheticStatement() throws {
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        let compte = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
        compte.reconciledBalance = Decimal("4200.00")
        compte.reconciledAt = now.addingTimeInterval(-10 * 86_400)
        let sans = Account(name: "Épargne", type: .savings)
        context.insert(compte); context.insert(sans)
        try context.save()

        let service = StatementMigrationService()
        XCTAssertEqual(service.migrerPointsDeRapprochement(now: now, context: context), 1,
                       "un seul compte porte un point nu")
        try context.save()
        let releves = try context.fetch(FetchDescriptor<Statement>())
        XCTAssertEqual(releves.count, 1)
        let releve = try XCTUnwrap(releves.first)
        XCTAssertEqual(releve.accountID, compte.id)
        XCTAssertEqual(releve.closingBalance, Decimal("4200.00"))
        XCTAssertEqual(releve.state, .reconciled)
        XCTAssertEqual(releve.source, StatementMigrationService.sourceMigration,
                       "la provenance est MARQUÉE — jamais devinée")
        XCTAssertEqual(compte.reconciledBalance, Decimal("4200.00"),
                       "le point du compte reste INTACT jusqu'à W4.4")

        // Idempotente : re-migrer ne duplique rien.
        XCTAssertEqual(service.migrerPointsDeRapprochement(now: now, context: context), 0)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Statement>()).count, 1)
    }

    // Un état inconnu retombe sur « Brouillon » — jamais un crash ni un
    // rapproché inventé.
    func testUnknownStateFallsBackToDraft() {
        let releve = Statement(
            accountID: UUID(), periodEnd: now,
            closingBalance: Decimal("100.00"), source: "test-fictif")
        releve.stateRawValue = "etat-de-demain"
        XCTAssertEqual(releve.state, .draft)
    }

    // Migration additive V13 → V14 : un store V13 s'ouvre en V14 avec
    // toutes ses données intactes, et les relevés vivent dans le store
    // migré (FI-35).
    func testDiskStoreWrittenAtV13OpensAtV14WithDataIntact() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("w43-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Budget.store")

        var compteID: UUID!
        do {
            let v13 = try ModelContainer(
                for: Schema(versionedSchema: BudgetSchemaV13.self),
                configurations: [ModelConfiguration(url: storeURL)])
            let contexte = ModelContext(v13)
            let compte = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
            compte.reconciledBalance = Decimal("4200.00")
            compte.reconciledAt = now
            compteID = compte.id
            contexte.insert(compte)
            try contexte.save()
        }

        let v14 = try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV14.self),
            configurations: [ModelConfiguration(url: storeURL)])
        let contexte = ModelContext(v14)
        let comptes = try contexte.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(comptes.first?.openingBalance, Decimal("1000.00"),
                       "aucun montant ne change pendant la migration (FI-35)")
        XCTAssertEqual(StatementMigrationService().migrerPointsDeRapprochement(now: now, context: contexte), 1)
        try contexte.save()
        let releves = try contexte.fetch(FetchDescriptor<Statement>())
        XCTAssertEqual(releves.first?.accountID, compteID)
        XCTAssertEqual(releves.first?.closingBalance, Decimal("4200.00"))
    }
}
