import XCTest
@testable import Budget

/// PFOS-P7 : le pont app ↔ widget. Le miroir voyage en centimes entiers
/// et en JSON versionné ; une version inconnue ou un fichier absent
/// rendent nil — jamais un chiffre deviné.
final class WidgetSnapshotTests: XCTestCase {
    private func exemple(version: Int = WidgetMonthSummary.currentSchemaVersion) -> WidgetMonthSummary {
        WidgetMonthSummary(
            schemaVersion: version,
            monthLabel: "Septembre 2026",
            generatedAt: Date(timeIntervalSince1970: 1_788_600_000),
            currencyCode: "CHF",
            availableCents: 182_050,
            incomeCents: 545_000,
            livingExpensesCents: 289_450,
            setAsideCents: 118_700
        )
    }

    func testCentimesDepuisDecimalEtRetour() {
        XCTAssertEqual(WidgetMonthSummary.cents(Decimal(string: "1234.56")!), 123_456)
        XCTAssertEqual(WidgetMonthSummary.cents(Decimal(string: "-42.5")!), -4250)
        XCTAssertEqual(WidgetMonthSummary.cents(Decimal.zero), 0)
        // L'arrondi au centime le plus proche, demi vers l'extérieur.
        XCTAssertEqual(WidgetMonthSummary.cents(Decimal(string: "0.675")!), 68)
        XCTAssertEqual(WidgetMonthSummary.amount(fromCents: 123_456), Decimal(string: "1234.56")!)
        XCTAssertEqual(WidgetMonthSummary.amount(fromCents: -4250), Decimal(string: "-42.50")!)
    }

    func testAllerRetourJSON() throws {
        let original = exemple()
        let data = try XCTUnwrap(WidgetSnapshotStore.encode(original))
        let relu = try XCTUnwrap(WidgetSnapshotStore.decode(data))
        XCTAssertEqual(relu, original)
    }

    func testVersionInconnueRefusee() throws {
        let futur = exemple(version: WidgetMonthSummary.currentSchemaVersion + 1)
        let data = try XCTUnwrap(WidgetSnapshotStore.encode(futur))
        XCTAssertNil(WidgetSnapshotStore.decode(data), "une version future doit être refusée, pas devinée")
    }

    func testJSONInvalideRefuse() {
        XCTAssertNil(WidgetSnapshotStore.decode(Data("pas du JSON".utf8)))
        XCTAssertNil(WidgetSnapshotStore.decode(Data("{\"schemaVersion\":1}".utf8)))
    }

    func testFichierAbsentRendNil() {
        let inexistant = FileManager.default.temporaryDirectory
            .appendingPathComponent("widget-inexistant-\(UUID().uuidString).json")
        XCTAssertNil(WidgetSnapshotStore.load(from: inexistant))
    }

    func testLectureDepuisFichierReel() throws {
        let original = exemple()
        let data = try XCTUnwrap(WidgetSnapshotStore.encode(original))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("widget-test-\(UUID().uuidString).json")
        try data.write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(WidgetSnapshotStore.load(from: url), original)
    }
}
