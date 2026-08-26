import XCTest
import SwiftData
@testable import Budget

final class CSVImportServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: CSVImportService!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private var account: Account!

    private let sampleCSV = """
    Date;Montant;Nom;Catégorie
    01.06.2026;-2150.00;Loyer;Logement
    03.06.2026;-512.35;Courses;Alimentation
    25.06.2026;8450.00;Salaire;Salaire
    pas-une-date;-50.00;Mystère;Divers
    05.06.2026;zéro;Cassé;Divers
    """

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = CSVImportService(calendar: calendar)
        account = Account(name: "Courant", type: .current)
        context.insert(account)
    }

    override func tearDown() {
        account = nil
        service = nil
        calendar = nil
        context = nil
        container = nil
    }

    private func validated(_ csv: String, fileName: String = "export.csv") -> [ImportRowResult] {
        let parsed = service.parse(text: csv)!
        let mapping = service.suggestMapping(headers: parsed.headers)
        let existing = (try? service.existingFingerprints(context: context)) ?? []
        return service.validate(parsed: parsed, mapping: mapping, fileName: fileName, existingFingerprints: existing)
    }

    // MARK: - Parsing

    func testDelimiterAndHeaderDetection() throws {
        let parsed = try XCTUnwrap(service.parse(text: sampleCSV))
        XCTAssertEqual(parsed.delimiter, ";")
        XCTAssertEqual(parsed.headers, ["Date", "Montant", "Nom", "Catégorie"])
        XCTAssertEqual(parsed.rows.count, 5)
        XCTAssertEqual(parsed.rawLines.count, 5, "Le texte brut est conservé pour la file de réparation")
    }

    func testCommaDelimiterAndQuotedFields() throws {
        let csv = "Date,Amount,Name\n01.06.2026,-100.00,\"Restaurant, terrasse\""
        let parsed = try XCTUnwrap(service.parse(text: csv))
        XCTAssertEqual(parsed.delimiter, ",")
        XCTAssertEqual(parsed.rows[0][2], "Restaurant, terrasse", "Les guillemets protègent le délimiteur")
    }

    func testSuggestMappingFromHeaders() throws {
        let parsed = try XCTUnwrap(service.parse(text: sampleCSV))
        let mapping = service.suggestMapping(headers: parsed.headers)
        XCTAssertEqual(mapping.dateIndex, 0)
        XCTAssertEqual(mapping.amountIndex, 1)
        XCTAssertEqual(mapping.titleIndex, 2)
        XCTAssertEqual(mapping.categoryIndex, 3)
        XCTAssertTrue(mapping.isUsable)
    }

    func testSwissDateParsing() {
        XCTAssertNotNil(service.parseDate("31.12.2026"))
        XCTAssertNotNil(service.parseDate("31/12/2026"))
        XCTAssertNotNil(service.parseDate("2026-12-31"))
        XCTAssertNil(service.parseDate("31.13.2026"), "Mois 13 rejeté")
        XCTAssertNil(service.parseDate("bientôt"))
        let date = service.parseDate("01.06.2026")!
        XCTAssertEqual(calendar.component(.day, from: date), 1)
        XCTAssertEqual(calendar.component(.month, from: date), 6)
    }

    // MARK: - Validation and repair queue

    func testEveryRejectedRowIsVisibleWithItsReason() {
        let rows = validated(sampleCSV)
        XCTAssertEqual(rows.count, 5)
        XCTAssertEqual(rows.filter { $0.state.isImportable }.count, 3)

        let invalidRows = rows.filter { if case .invalid = $0.state { return true } else { return false } }
        XCTAssertEqual(invalidRows.count, 2, "Chaque ligne rejetée est présente")
        XCTAssertTrue(invalidRows.allSatisfy { !$0.rawLine.isEmpty }, "…avec son texte source")
        if case .invalid(let reason) = invalidRows[0].state {
            XCTAssertTrue(reason.contains("Date"), "…et sa raison en français")
        } else {
            XCTFail("État attendu : invalid")
        }
    }

    func testSignDecidesTypeWithoutTypeColumn() {
        let rows = validated(sampleCSV)
        XCTAssertEqual(rows[0].type, .expense, "Montant négatif → dépense")
        XCTAssertEqual(rows[2].type, .income, "Montant positif → revenu")
        XCTAssertEqual(rows[0].amount, Decimal("2150.00"), "Le montant stocké reste positif")
    }

    func testFutureImportedDatesStayPlannedAcrossMonthAndYearBoundaries() throws {
        let csv = """
        Date;Montant;Nom
        14.06.2026;-10.00;Passée
        01.07.2026;-20.00;Mois suivant
        01.01.2027;-30.00;Année suivante
        """
        _ = try service.apply(
            rows: validated(csv), fileName: "dates.csv", account: account,
            categories: [], confirmedNewCategories: [], now: now, context: context
        )

        let imported = try context.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(imported.first { $0.title == "Passée" }?.status, .posted)
        XCTAssertEqual(imported.first { $0.title == "Mois suivant" }?.status, .planned)
        XCTAssertEqual(imported.first { $0.title == "Année suivante" }?.status, .planned)
    }

    // MARK: - Idempotence (acceptance criterion)

    func testFingerprintIsStable() {
        let a = service.fingerprint(fileName: "Export.csv", rowIndex: 3, date: now, amount: Decimal("2150.00"), type: .expense, title: "Loyer")
        let b = service.fingerprint(fileName: "export.csv", rowIndex: 3, date: now, amount: Decimal("2150.00"), type: .expense, title: "loyer")
        let c = service.fingerprint(fileName: "export.csv", rowIndex: 4, date: now, amount: Decimal("2150.00"), type: .expense, title: "Loyer")
        XCTAssertEqual(a, b, "Casse du nom de fichier et de l'intitulé normalisée")
        XCTAssertNotEqual(a, c, "L'identité de ligne source compte")
        XCTAssertEqual(a.count, 64, "SHA-256 hexadécimal")
    }

    func testReimportCreatesZeroDuplicates() throws {
        // Premier import.
        let first = try service.apply(
            rows: validated(sampleCSV), fileName: "export.csv", account: account,
            categories: [], confirmedNewCategories: [], now: now, context: context
        )
        XCTAssertEqual(first.importedCount, 3)

        // Ré-import du même fichier : tout est doublon, rien n'est créé.
        let second = try service.apply(
            rows: validated(sampleCSV), fileName: "export.csv", account: account,
            categories: [], confirmedNewCategories: [], now: now, context: context
        )
        XCTAssertEqual(second.importedCount, 0, "Un ré-import ne duplique jamais")
        XCTAssertEqual(second.duplicateCount, 3)

        let transactions = try context.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(transactions.count, 3)
    }

    func testDuplicateRowsInsideTheSameFileAreCaughtOnce() {
        let csv = """
        Date;Montant;Nom
        01.06.2026;-100.00;Courses
        01.06.2026;-100.00;Courses
        """
        // W7.2 (FI-29) : l'identité NORMALISÉE fait foi — deux lignes
        // identiques d'un même fichier sont UN doublon, plus jamais deux
        // entrées (l'ancien comportement, empreintes par index, était le
        // défaut mesuré de l'audit ; fixture partagée import-doublons).
        let rows = validated(csv)
        XCTAssertEqual(rows.filter { $0.state.isImportable }.count, 1,
                       "la première ligne entre")
        XCTAssertEqual(rows.filter { $0.state == .duplicate }.count, 1,
                       "la seconde, identique, est un doublon nommé")
    }

    // MARK: - Categories

    func testMissingCategoriesRequireExplicitConfirmation() throws {
        let existing = BudgetCategory(name: "Logement", kind: .expense)
        context.insert(existing)

        let rows = validated(sampleCSV)
        let missing = service.missingCategoryNames(rows: rows, existing: [existing])
        XCTAssertEqual(Set(missing), ["Alimentation", "Salaire"], "Les catégories des lignes invalides ne comptent pas")

        // Sans confirmation : rien n'est créé.
        let report = try service.apply(
            rows: rows, fileName: "export.csv", account: account,
            categories: [existing], confirmedNewCategories: [], now: now, context: context
        )
        XCTAssertTrue(report.createdCategoryNames.isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BudgetCategory>()).count, 1)
    }

    func testConfirmedCategoriesAreCreatedAndLinked() throws {
        let rows = validated(sampleCSV)
        let report = try service.apply(
            rows: rows, fileName: "export.csv", account: account,
            categories: [], confirmedNewCategories: ["Logement"], now: now, context: context
        )
        XCTAssertEqual(report.createdCategoryNames, ["Logement"])
        let transactions = try context.fetch(FetchDescriptor<BudgetTransaction>())
        let rent = transactions.first { $0.title == "Loyer" }
        XCTAssertEqual(rent?.category?.name, "Logement")
        let groceries = transactions.first { $0.title == "Courses" }
        XCTAssertNil(groceries?.category, "Catégorie non confirmée → importée sans catégorie")
    }

    // MARK: - Report and rollback

    func testReportCountersReconcile() throws {
        let report = try service.apply(
            rows: validated(sampleCSV), fileName: "export.csv", account: account,
            categories: [], confirmedNewCategories: [], now: now, context: context
        )
        XCTAssertEqual(report.totalRows, 5)
        XCTAssertEqual(
            report.importedCount + report.duplicateCount + report.invalidCount,
            report.totalRows,
            "total = importées + doublons + invalides"
        )
        XCTAssertEqual(report.rejectedRows.count, report.duplicateCount + report.invalidCount)
    }

    func testRollbackRemovesOnlyTheBatch() throws {
        let untouched = BudgetTransaction(
            date: now, amount: Decimal("42.00"), type: .expense,
            title: "Hors lot", account: account
        )
        context.insert(untouched)

        let report = try service.apply(
            rows: validated(sampleCSV), fileName: "export.csv", account: account,
            categories: [], confirmedNewCategories: [], now: now, context: context
        )
        XCTAssertEqual(try context.fetch(FetchDescriptor<BudgetTransaction>()).count, 4)

        let removed = try service.rollback(batchID: report.batchID, context: context)
        XCTAssertEqual(removed, 3)

        let remaining = try context.fetch(FetchDescriptor<BudgetTransaction>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.title, "Hors lot")
        XCTAssertEqual(try context.fetch(FetchDescriptor<ImportBatch>()).count, 0)
    }

    // MARK: - Document store fake

    func testInMemoryDocumentStoreRoundTrip() throws {
        let store = InMemoryDocumentFileStore()
        store.store(Data("relevé".utf8), reference: "doc.pdf")
        XCTAssertNotNil(store.url(for: "doc.pdf"))
        try store.delete("doc.pdf")
        XCTAssertNil(store.url(for: "doc.pdf"))
    }
}
