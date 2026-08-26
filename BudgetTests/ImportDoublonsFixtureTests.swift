import XCTest
import SwiftData
@testable import Budget

/// W7.2 (FI-29) — runner natif de la fixture PARTAGÉE
/// `fixtures/import-doublons.json` (différée depuis W1.5) : l'identité
/// d'une ligne d'import est NORMALISÉE — ni nom de fichier ni numéro
/// de ligne. Le même relevé renommé = doublons ; deux lignes
/// identiques d'un même fichier = un doublon ; la casse ne change pas
/// l'identité ; un montant différent est une autre opération.
final class ImportDoublonsFixtureTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: CSVImportService!
    private var account: Account!

    private struct Fixture: Decodable {
        struct Etape: Decodable {
            let fichier: String
            let verdicts: [String]
        }
        struct EtapeCSV: Decodable {
            let csv: String
            let fichier: String
            let verdicts: [String]
        }
        struct Ligne: Decodable {
            let ligne: String
            let verdict: String
        }
        let csv: String
        let premierImport: Etape
        let rejeuRenomme: Etape
        let memeFichierLigneDoublee: EtapeCSV
        let casseDifferente: Ligne
        let vraieNouvelle: Ligne
    }

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
        service = CSVImportService(calendar: calendar)
        account = Account(name: "Courant", type: .current, openingBalance: 3000)
        context.insert(account)
    }

    override func tearDown() {
        account = nil; service = nil; calendar = nil; context = nil; container = nil
    }

    private func fixture() throws -> Fixture {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("fixtures/import-doublons.json")
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    private func verdicts(_ csv: String, fileName: String,
                          existingNormalized: Set<String>) throws -> [String] {
        let parsed = try XCTUnwrap(service.parse(text: csv))
        let mapping = service.suggestMapping(headers: parsed.headers)
        let rows = service.validate(
            parsed: parsed, mapping: mapping, fileName: fileName,
            existingFingerprints: [],
            existingNormalizedFingerprints: existingNormalized
        )
        return rows.map { row in
            switch row.state {
            case .ready: "ready"
            case .duplicate: "duplicate"
            case .invalid: "invalid"
            }
        }
    }

    /// Simule l'application : les empreintes normalisées des lignes prêtes
    /// rejoignent la base, comme des mouvements enregistrés.
    private func normalizedOfReady(_ csv: String, fileName: String) throws -> Set<String> {
        let parsed = try XCTUnwrap(service.parse(text: csv))
        let mapping = service.suggestMapping(headers: parsed.headers)
        let rows = service.validate(
            parsed: parsed, mapping: mapping, fileName: fileName,
            existingFingerprints: []
        )
        return Set(rows.filter { $0.state.isImportable }.compactMap(\.normalizedFingerprint))
    }

    func testFixturePartageeDoublons() throws {
        let fx = try fixture()
        // 1. Premier import : tout entre.
        XCTAssertEqual(
            try verdicts(fx.csv, fileName: fx.premierImport.fichier, existingNormalized: []),
            fx.premierImport.verdicts, "premier import"
        )
        let base = try normalizedOfReady(fx.csv, fileName: fx.premierImport.fichier)
        // 2. Le même contenu sous un AUTRE nom : tout est doublon (FI-29).
        XCTAssertEqual(
            try verdicts(fx.csv, fileName: fx.rejeuRenomme.fichier, existingNormalized: base),
            fx.rejeuRenomme.verdicts, "relevé renommé"
        )
        // 3. Deux lignes identiques d'un MÊME fichier : la 2e est un doublon.
        XCTAssertEqual(
            try verdicts(fx.memeFichierLigneDoublee.csv,
                         fileName: fx.memeFichierLigneDoublee.fichier,
                         existingNormalized: []),
            fx.memeFichierLigneDoublee.verdicts, "ligne doublée en fichier"
        )
        // 4. La casse ne change pas l'identité.
        XCTAssertEqual(
            try verdicts("Date;Montant;Libellé\n" + fx.casseDifferente.ligne,
                         fileName: "autre.csv", existingNormalized: base),
            [fx.casseDifferente.verdict], "casse pliée"
        )
        // 5. Un montant différent est une autre opération.
        XCTAssertEqual(
            try verdicts("Date;Montant;Libellé\n" + fx.vraieNouvelle.ligne,
                         fileName: "autre.csv", existingNormalized: base),
            [fx.vraieNouvelle.verdict], "vraie nouvelle"
        )
    }

    /// La base normalisée se dérive aussi des MOUVEMENTS enregistrés —
    /// un mouvement saisi à la main bloque le doublon d'import.
    func testExistingTransactionsFeedNormalizedBase() throws {
        let transaction = BudgetTransaction(
            date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 5, hour: 10))!,
            amount: Decimal(string: "45.50")!, type: .expense, status: .posted,
            title: "Pharmacie", account: account
        )
        context.insert(transaction)
        let base = service.existingNormalizedFingerprints(transactions: [transaction])
        let fx = try fixture()
        let result = try verdicts(fx.csv, fileName: "premier.csv", existingNormalized: base)
        XCTAssertEqual(result.first, "duplicate",
                       "la ligne Pharmacie déjà saisie à la main est un doublon")
    }
}
