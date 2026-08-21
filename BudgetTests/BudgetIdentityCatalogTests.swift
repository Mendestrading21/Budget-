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

    // P05-C (ADR-043) : les institutions proposées sur « Comptes » —
    // banques, courtiers, prévoyance ; les assureurs attendent P13-C.
    func testInstitutionEntriesStayOnTheirDoor() {
        let entries = BudgetIdentityCatalog.institutionEntries
        XCTAssertTrue(entries.allSatisfy { $0.entityKind == "institution" })
        let senses = Set(entries.map(\.financialSense))
        XCTAssertEqual(senses.subtracting(["account", "broker", "pension"]), [],
                       "les assureurs attendent P13-C")
        let keys = Set(entries.map(\.key))
        XCTAssertTrue(keys.contains("ubs"), "les banques suisses sont proposées")
        XCTAssertFalse(keys.contains("netflix"), "un service n'est jamais une institution")
    }

    func testInstitutionMatchingIsExactNeverContains() {
        XCTAssertEqual(BudgetIdentityCatalog.institutionEntry(matching: "UBS")?.key, "ubs")
        XCTAssertEqual(BudgetIdentityCatalog.institutionEntry(matching: "  ubs ")?.key, "ubs",
                       "pliage casse + espaces : la reconnaissance reste exacte")
        XCTAssertNil(BudgetIdentityCatalog.institutionEntry(matching: "Netflix"),
                     "un service connu n'est pas une institution")
        XCTAssertNil(BudgetIdentityCatalog.institutionEntry(matching: "Ma petite banque"),
                     "un nom inconnu garde son glyphe de type de compte")
        XCTAssertNil(BudgetIdentityCatalog.institutionEntry(matching: ""),
                     "vide : jamais de correspondance")
    }

    // P13-C (ADR-045) : les assureurs proposés sur « Assurances » — les
    // institutions au sens insurance seulement, jamais une banque ni un
    // besoin générique. L'assureur reste distinct du type de contrat.
    func testInsurerEntriesStayOnTheirDoor() {
        let entries = BudgetIdentityCatalog.insurerEntries
        XCTAssertTrue(entries.allSatisfy { $0.entityKind == "institution" && $0.financialSense == "insurance" })
        let keys = Set(entries.map(\.key))
        XCTAssertTrue(keys.contains("css"), "les caisses maladie suisses sont proposées")
        XCTAssertFalse(keys.contains("ubs"), "une banque n'est jamais un assureur")
        XCTAssertFalse(keys.contains("household-insurance"),
                       "un besoin générique (« Assurance ménage ») n'est pas un assureur")
        XCTAssertEqual(
            BudgetIdentityCatalog.institutionEntry(matching: "CSS")?.key, "css",
            "la liste P13 retrouve l'assureur par correspondance exacte, comme les banques"
        )
    }

    func testSuggestionMappingNeverInventsACategory() {
        XCTAssertEqual(IdentityServicePickerView.appCategoryName(for: "video"), "Restaurants et sorties")
        XCTAssertEqual(IdentityServicePickerView.appCategoryName(for: "telecom"), "Logement")
        XCTAssertEqual(IdentityServicePickerView.appCategoryName(for: "pension"), "Pilier 3a")
        XCTAssertNil(IdentityServicePickerView.appCategoryName(for: "childcare"),
                     "sans correspondance sûre, AUCUNE suggestion — la personne choisit")
    }
}
