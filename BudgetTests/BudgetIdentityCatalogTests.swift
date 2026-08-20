import XCTest
@testable import Budget

/// P08-C (ADR-041) : le catalogue natif généré reste fidèle à la fixture
/// éditoriale et ne peut par CONSTRUCTION rien inventer — aucun champ de
/// prix, de solde, de compte, de date ni de statut n'existe dans le type.
final class BudgetIdentityCatalogTests: XCTestCase {
    func testCatalogMatchesEditorialFixtureShape() {
        let all = BudgetIdentityCatalog.all
        XCTAssertEqual(all.count, 164, "la fixture V1 compte 164 identités")
        XCTAssertEqual(Set(all.map(\.key)).count, all.count, "clés uniques")
        XCTAssertTrue(all.allSatisfy { !$0.displayName.isEmpty })
        let senses: Set<String> = ["subscription", "bill", "set_aside", "account",
                                   "broker", "insurance", "pension"]
        XCTAssertTrue(all.allSatisfy { senses.contains($0.financialSense) },
                      "aucun sens financier hors registre")
        let cadences: Set<String> = ["none", "week", "four_weeks", "month",
                                     "quarter", "semiannual", "year", "custom"]
        XCTAssertTrue(all.allSatisfy { $0.cadenceHints.allSatisfy(cadences.contains) },
                      "four_weeks ne devient jamais month — cadences du registre seulement")
    }

    func testIOSMarketStaysSwissAndGlobal() {
        // Garde-fou devises du skill : la base iOS reste nativement CHF —
        // un service uniquement FR/BE (Navigo) n'est pas proposé.
        let keys = Set(BudgetIdentityCatalog.iosMarketEntries.map(\.key))
        XCTAssertTrue(keys.contains("netflix"), "les services proposés en Suisse restent là")
        XCTAssertTrue(keys.contains("swisscom"), "les services suisses restent proposés")
        XCTAssertFalse(keys.contains("navigo"), "un service uniquement français n'apparaît pas sur iOS")
    }

    func testServiceEntriesExcludeInstitutions() {
        let senses = Set(BudgetIdentityCatalog.serviceEntries.map(\.financialSense))
        XCTAssertEqual(senses.subtracting(["subscription", "bill", "set_aside"]), [],
                       "les banques et assureurs attendent P05-C/P13-C")
        XCTAssertFalse(BudgetIdentityCatalog.serviceEntries.contains { $0.key == "ubs" },
                       "choisir une banque ne se fait pas depuis « Ce qui revient »")
    }

    func testSuggestionMappingNeverInventsACategory() {
        XCTAssertEqual(IdentityServicePickerView.appCategoryName(for: "video"), "Restaurants et sorties")
        XCTAssertEqual(IdentityServicePickerView.appCategoryName(for: "telecom"), "Logement")
        XCTAssertEqual(IdentityServicePickerView.appCategoryName(for: "pension"), "Pilier 3a")
        XCTAssertNil(IdentityServicePickerView.appCategoryName(for: "childcare"),
                     "sans correspondance sûre, AUCUNE suggestion — la personne choisit")
    }
}
