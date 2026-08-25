import XCTest
import SwiftData
@testable import Budget

/// W2.1 — le modèle d'échéance persistée : identité, clé d'idempotence
/// UNIQUE, survie sur disque et migration additive V10 → V11 (les
/// données existantes gardent exactement le même sens).
final class ScheduledOccurrenceTests: XCTestCase {

    private var calendar: Calendar!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 10))!
    }

    // FI-03 : la clé canonique d'une échéance est STABLE — deux
    // matérialisations du même couple (série, date) donnent la même clé.
    func testSerieKeyIsDeterministic() {
        let serie = UUID()
        let a = ScheduledOccurrence.serieKey(seriesID: serie, originalDueDate: date(2026, 9, 1), calendar: calendar)
        let b = ScheduledOccurrence.serieKey(seriesID: serie, originalDueDate: date(2026, 9, 1), calendar: calendar)
        XCTAssertEqual(a, b)
        let autreMois = ScheduledOccurrence.serieKey(seriesID: serie, originalDueDate: date(2026, 10, 1), calendar: calendar)
        XCTAssertNotEqual(a, autreMois, "un autre mois est une AUTRE échéance")
    }

    // FI-04 : la clé d'idempotence est une contrainte UNIQUE du store —
    // insérer deux fois la même échéance ne crée pas deux objets.
    func testIdempotencyKeyIsUniqueInStore() throws {
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        let serie = UUID()
        let cle = ScheduledOccurrence.serieKey(seriesID: serie, originalDueDate: date(2026, 9, 1), calendar: calendar)

        context.insert(ScheduledOccurrence(
            seriesID: serie, dueDate: date(2026, 9, 1),
            expectedAmount: Decimal("150.00"), idempotencyKey: cle))
        try context.save()

        context.insert(ScheduledOccurrence(
            seriesID: serie, dueDate: date(2026, 9, 1),
            expectedAmount: Decimal("150.00"), idempotencyKey: cle))
        try context.save()

        // SwiftData applique l'unicité par upsert : jamais deux lignes.
        let occurrences = try context.fetch(FetchDescriptor<ScheduledOccurrence>())
        XCTAssertEqual(occurrences.count, 1,
            "la même clé d'idempotence ne peut pas produire deux échéances (FI-03/04)")
    }

    // Le reporter conserve la date D'ORIGINE (FI-05 en germe : rien ne
    // se perd) et l'état par défaut est « Prévu » du glossaire W0.
    func testSnoozeKeepsOriginalDueDate() {
        let occurrence = ScheduledOccurrence(
            seriesID: UUID(), dueDate: date(2026, 9, 1),
            expectedAmount: Decimal("25.00"),
            idempotencyKey: "test:1")
        XCTAssertEqual(occurrence.state, .scheduled)
        XCTAssertEqual(occurrence.originalDueDate, occurrence.dueDate)
        occurrence.dueDate = date(2026, 9, 8)
        occurrence.state = .snoozed
        XCTAssertEqual(occurrence.originalDueDate, date(2026, 9, 1),
            "reporter bouge dueDate, jamais la date d'origine")
        XCTAssertEqual(occurrence.state.displayName, "Reporté")
    }

    // Un rawValue inconnu (donnée future ou corrompue) retombe sur
    // « Prévu » — l'état LE PLUS PRUDENT : rien ne bouge tant que
    // personne ne confirme. Jamais un état qui prétend qu'un mouvement
    // a eu lieu.
    func testUnknownStateFallsBackToScheduledNeverConfirmed() {
        let occurrence = ScheduledOccurrence(
            seriesID: nil, dueDate: date(2026, 9, 1), idempotencyKey: "test:2")
        occurrence.stateRawValue = "etat-de-demain"
        XCTAssertEqual(occurrence.state, .scheduled)
    }

    // Migration additive V10 → V11 : un store écrit au schéma V10
    // s'ouvre en V11 avec TOUTES ses données intactes, et le nouveau
    // modèle est utilisable — aucune donnée existante ne change de sens.
    func testDiskStoreWrittenAtV10OpensAtV11WithDataIntact() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("w2-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Budget.store")

        // 1. Écrire un store au schéma V10 (l'ancien monde).
        do {
            let v10 = try ModelContainer(
                for: Schema(versionedSchema: BudgetSchemaV10.self),
                configurations: [ModelConfiguration(url: storeURL)]
            )
            let context = ModelContext(v10)
            let compte = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
            context.insert(compte)
            context.insert(BudgetTransaction(
                date: date(2026, 8, 1), amount: Decimal("42.50"),
                type: .expense, title: "Courses", account: compte))
            try context.save()
        }

        // 2. Rouvrir le MÊME fichier avec le schéma V11.
        let v11 = try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV11.self),
            configurations: [ModelConfiguration(url: storeURL)]
        )
        let context = ModelContext(v11)
        let comptes = try context.fetch(FetchDescriptor<Account>())
        let mouvements = try context.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(comptes.count, 1)
        XCTAssertEqual(comptes.first?.openingBalance, Decimal("1000.00"))
        XCTAssertEqual(mouvements.count, 1)
        XCTAssertEqual(mouvements.first?.amount, Decimal("42.50"),
            "aucun montant ne change pendant la migration (FI-35)")

        // 3. Le nouveau modèle vit dans le store migré.
        context.insert(ScheduledOccurrence(
            seriesID: nil, dueDate: date(2026, 9, 1), idempotencyKey: "migration:1"))
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<ScheduledOccurrence>()).count, 1)
    }
}
