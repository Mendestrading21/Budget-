import XCTest
import SwiftData
@testable import Budget

/// W3.1 — Money : la frontière Decimal ↔ centimes entiers est EXACTE
/// et déterministe ; une valeur illisible est refusée, jamais zéro.
final class MoneyTests: XCTestCase {

    func testDecimalToMinorUnitsIsExact() {
        XCTAssertEqual(Money(amount: Decimal(string: "97.50")!, currency: "CHF")?.minorUnits, 9750)
        XCTAssertEqual(Money(amount: Decimal(string: "4350.00")!, currency: "CHF")?.minorUnits, 435_000)
        XCTAssertEqual(Money(amount: Decimal(string: "-12.34")!, currency: "EUR")?.minorUnits, -1234)
        XCTAssertEqual(Money(amount: Decimal.zero, currency: "CHF")?.minorUnits, 0)
    }

    // FI-18 : l'arrondi est DÉTERMINISTE (.plain, 2 décimales) — le
    // même montant donne toujours les mêmes centimes.
    func testRoundingIsDeterministic() {
        XCTAssertEqual(Money(amount: Decimal(string: "1.005")!, currency: "CHF")?.minorUnits, 101)
        XCTAssertEqual(Money(amount: Decimal(string: "1.004")!, currency: "CHF")?.minorUnits, 100)
        XCTAssertEqual(Money(amount: Decimal(string: "2.675")!, currency: "CHF")?.minorUnits, 268)
    }

    // FI-34 : illisible = REFUS (nil), jamais un zéro silencieux.
    func testUnreadableAmountIsRefusedNeverZero() {
        XCTAssertNil(Money(amount: Decimal.nan, currency: "CHF"))
        XCTAssertNil(Money(amount: Decimal(string: "10.00")!, currency: "chf"),
                     "une devise minuscule n'est pas un code valide")
        XCTAssertNil(Money(amount: Decimal(string: "10.00")!, currency: "CHFX"))
    }

    // L'aller-retour centimes → Decimal → centimes est sans perte.
    func testRoundTripIsLossless() {
        let money = Money(minorUnits: 123_456_789, currency: "CHF")
        XCTAssertEqual(money.decimalValue, Decimal(string: "1234567.89")!)
        XCTAssertEqual(Money(amount: money.decimalValue, currency: "CHF"), money)
    }
}

/// W3.1 — le journal : une écriture équilibrée PAR DEVISE en centimes
/// entiers, refus nommés, persistance V12 et migration additive.
final class JournalEntryTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil; container = nil
    }

    private func jambe(_ compte: String, debit: Bool, _ centimes: Int64,
                       _ devise: String = "CHF") -> JournalPostingDraft {
        JournalPostingDraft(accountKey: compte, isDebit: debit,
                            amount: Money(minorUnits: centimes, currency: devise))
    }

    // FI-08 : l'écriture équilibrée s'enregistre avec ses deux jambes.
    func testBalancedEntryPersistsWithItsPostings() throws {
        let ecriture = try JournalEntry.equilibree(
            kind: .expense, effectiveDate: now, title: "Loyer",
            idempotencyKey: "w31:loyer",
            postings: [
                jambe("compte:cur", debit: false, 150_000),
                jambe("depense:Logement", debit: true, 150_000),
            ], now: now)
        context.insert(ecriture)
        try context.save()
        let relues = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(relues.count, 1)
        XCTAssertEqual(relues.first?.postings.count, 2)
        XCTAssertEqual(relues.first?.lifecycle, .posted)
        XCTAssertEqual(relues.first?.postings.first?.money.currency, "CHF")
    }

    // FI-08 : un déséquilibre est un refus NOMMÉ (devise + écart) et
    // RIEN n'entre dans le contexte.
    func testUnbalancedEntryIsRefusedAndWritesNothing() throws {
        XCTAssertThrowsError(try JournalEntry.equilibree(
            kind: .expense, effectiveDate: now, title: "Faux",
            idempotencyKey: "w31:faux",
            postings: [
                jambe("compte:cur", debit: false, 150_000),
                jambe("depense:Logement", debit: true, 149_900),
            ], now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalEntryError,
                           .desequilibre(devise: "CHF", ecartMineur: -100))
        }
        XCTAssertTrue(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<JournalPosting>()).isEmpty,
                      "aucun posting orphelin après un refus")
    }

    // Une écriture a toujours deux jambes ; un montant nul ou négatif
    // est refusé (FI-34).
    func testSingleLegAndInvalidAmountsAreRefused() {
        XCTAssertThrowsError(try JournalEntry.equilibree(
            kind: .expense, effectiveDate: now, title: "Seul",
            idempotencyKey: "w31:seul",
            postings: [jambe("compte:cur", debit: false, 1000)], now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalEntryError, .postingsInsuffisants)
        }
        XCTAssertThrowsError(try JournalEntry.equilibree(
            kind: .expense, effectiveDate: now, title: "Zéro",
            idempotencyKey: "w31:zero",
            postings: [
                jambe("compte:cur", debit: false, 0),
                jambe("depense:Divers", debit: true, 0),
            ], now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalEntryError, .montantInvalide)
        }
    }

    // FI-08 : l'équilibre se juge PAR DEVISE — le change honnête (deux
    // paires équilibrées) passe, le déséquilibre caché est refusé même
    // si les totaux « semblent » bons.
    func testBalanceIsJudgedPerCurrency() throws {
        let change = try JournalEntry.equilibree(
            kind: .transfer, effectiveDate: now, title: "Change",
            idempotencyKey: "w31:change",
            postings: [
                jambe("compte:cur", debit: false, 10_000, "CHF"),
                jambe("attente:change", debit: true, 10_000, "CHF"),
                jambe("attente:change", debit: false, 9_300, "EUR"),
                jambe("compte:eur", debit: true, 9_300, "EUR"),
            ], now: now)
        XCTAssertEqual(change.postings.count, 4)

        XCTAssertThrowsError(try JournalEntry.equilibree(
            kind: .transfer, effectiveDate: now, title: "Triche",
            idempotencyKey: "w31:triche",
            postings: [
                jambe("compte:cur", debit: false, 10_000, "CHF"),
                jambe("compte:eur", debit: true, 10_000, "EUR"),
            ], now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalEntryError,
                           .desequilibre(devise: "CHF", ecartMineur: -10_000))
        }
    }

    // La clé d'idempotence est UNIQUE : réinsérer la même écriture ne
    // crée jamais un doublon (upsert SwiftData sur l'attribut unique).
    func testIdempotencyKeyIsUnique() throws {
        let premiere = try JournalEntry.equilibree(
            kind: .expense, effectiveDate: now, title: "Loyer",
            idempotencyKey: "w31:unique",
            postings: [
                jambe("compte:cur", debit: false, 150_000),
                jambe("depense:Logement", debit: true, 150_000),
            ], now: now)
        context.insert(premiere)
        try context.save()
        let seconde = try JournalEntry.equilibree(
            kind: .expense, effectiveDate: now, title: "Loyer bis",
            idempotencyKey: "w31:unique",
            postings: [
                jambe("compte:cur", debit: false, 150_000),
                jambe("depense:Logement", debit: true, 150_000),
            ], now: now)
        context.insert(seconde)
        try context.save()
        let relues = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(relues.count, 1, "jamais deux écritures pour la même clé")
    }

    // Migration additive V11 → V12 : un store écrit au schéma V11
    // s'ouvre en V12 avec TOUTES ses données intactes, et le journal
    // est utilisable — aucune donnée existante ne change de sens (FI-35).
    func testDiskStoreWrittenAtV11OpensAtV12WithDataIntact() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("w3-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Budget.store")

        // 1. Écrire un store au schéma V11 (le monde d'avant W3).
        do {
            let v11 = try ModelContainer(
                for: Schema(versionedSchema: BudgetSchemaV11.self),
                configurations: [ModelConfiguration(url: storeURL)]
            )
            let contexte = ModelContext(v11)
            let compte = Account(name: "Courant", type: .current, openingBalance: Decimal("1000.00"))
            contexte.insert(compte)
            contexte.insert(ScheduledOccurrence(
                seriesID: nil, dueDate: now, idempotencyKey: "w3-migration:occ"))
            try contexte.save()
        }

        // 2. Rouvrir le MÊME store au schéma V12.
        let v12 = try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV12.self),
            configurations: [ModelConfiguration(url: storeURL)]
        )
        let contexte = ModelContext(v12)
        let comptes = try contexte.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(comptes.count, 1)
        XCTAssertEqual(comptes.first?.openingBalance, Decimal("1000.00"),
                       "aucun montant ne change pendant la migration (FI-35)")
        XCTAssertEqual(try contexte.fetch(FetchDescriptor<ScheduledOccurrence>()).count, 1)

        // 3. Le journal vit dans le store migré.
        let ecriture = try JournalEntry.equilibree(
            kind: .expense, effectiveDate: now, title: "Après migration",
            idempotencyKey: "w3-migration:jrn",
            postings: [
                jambe("compte:cur", debit: false, 4_200),
                jambe("depense:Divers", debit: true, 4_200),
            ], now: now)
        contexte.insert(ecriture)
        try contexte.save()
        XCTAssertEqual(try contexte.fetch(FetchDescriptor<JournalEntry>()).count, 1)
    }
}
