import XCTest
@testable import Budget

/// IC1 (ADR-038) : le monogramme natif applique EXACTEMENT le même
/// algorithme que la PWA. Les cas ci-dessous sont la copie de
/// fixtures/monogram-cases.json — le parcours e2e 158 (IC1) prouve la
/// même liste côté PWA ; toute divergence casse l'une des deux suites.
final class BudgetMonogramTests: XCTestCase {
    private let cases: [(name: String, monogram: String)] = [
        ("Netflix", "N"),
        ("Basic-Fit", "BF"),
        ("la banque postale", "LB"),
        ("1Password", "1"),
        ("école du village", "ÉD"),
        ("  UBS  ", "U"),
        ("Caisse d'Épargne", "CD"),
        ("<img src=x onerror=alert(1)>", "IS"),
        ("— · —", ""),
        ("", ""),
    ]

    func testSharedFixtureCases() {
        for entry in cases {
            XCTAssertEqual(
                BudgetMonogram.letters(for: entry.name), entry.monogram,
                "monogramme de \(entry.name)"
            )
        }
    }

    func testMonogramIsAlwaysShortAndPlain() {
        for entry in cases {
            let letters = BudgetMonogram.letters(for: entry.name)
            XCTAssertLessThanOrEqual(letters.count, 2)
            XCTAssertFalse(letters.contains("<") || letters.contains(">"),
                           "jamais de balise dans une tuile")
        }
    }

    /// Les 14 clés de catégories d'IC1 existent dans le registre natif —
    /// le test Node catalogue.test.mjs vérifie la même chose par la carte.
    func testCatalogueCategoryGlyphsExist() {
        let keys: [BudgetGlyph] = [.bill, .video, .music, .cloud, .software,
                                   .ai, .gaming, .fitness, .health, .press,
                                   .telecom, .transport, .dating, .delivery]
        for glyph in keys {
            XCTAssertFalse(glyph.systemName.isEmpty)
        }
    }
}
