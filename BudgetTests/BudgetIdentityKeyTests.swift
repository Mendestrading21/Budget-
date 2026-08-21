import XCTest
@testable import Budget

/// ID1 (ADR-042) : la règle de clé native applique EXACTEMENT la même
/// liste que la PWA. Les cas ci-dessous sont la copie de
/// fixtures/identity-key-cases.json — le parcours e2e 163 prouve la même
/// liste côté PWA ; toute divergence casse l'une des deux suites.
final class BudgetIdentityKeyTests: XCTestCase {
    private let cases: [(value: String, kept: Bool)] = [
        ("netflix", true),
        ("pillar-3a-contribution", true),
        ("future-service", true),
        ("a", true),
        ("Netflix", false),
        ("net_flix", false),
        ("-netflix", false),
        ("netflix-", false),
        ("net flix", false),
        ("<img src=x onerror=alert(1)>", false),
        ("javascript:alert(1)", false),
        ("abcdefghij-abcdefghij-abcdefghij-abcdefghi", false),
    ]

    func testSharedFixtureCases() {
        for entry in cases {
            XCTAssertEqual(
                BudgetIdentityKey.sanitized(entry.value), entry.kept ? entry.value : nil,
                "clé \(entry.value)"
            )
        }
        XCTAssertNil(BudgetIdentityKey.sanitized(nil))
    }

    func testModelSanitizesAtConstruction() {
        // Une clé hostile ne peut même pas entrer dans le store : l'init
        // la retire, la ligne vit sans elle.
        let hostile = RecurringTransaction(
            title: "Ligne testée", amount: Decimal("10.00"), type: .expense,
            firstOccurrence: Date(timeIntervalSince1970: 1_781_524_800),
            identityKey: "<img src=x onerror=alert(1)>"
        )
        XCTAssertNil(hostile.identityKey)
        XCTAssertEqual(hostile.title, "Ligne testée", "la ligne n'est jamais perdue")

        let known = RecurringTransaction(
            title: "Mes films", amount: Decimal("17.90"), type: .expense,
            firstOccurrence: Date(timeIntervalSince1970: 1_781_524_800),
            identityKey: "netflix"
        )
        XCTAssertEqual(known.identityKey, "netflix",
                       "la clé survit au renommage : le titre dit « Mes films », l'identité reste Netflix")
        XCTAssertEqual(BudgetIdentityKey.catalogEntry(for: known.identityKey)?.displayName, "Netflix")
    }

    func testUnknownKeyFallsBackWithoutError() {
        XCTAssertNil(BudgetIdentityKey.catalogEntry(for: "future-service"),
                     "clé saine mais inconnue : catalogue extensible, repli monogramme au rendu")
        XCTAssertEqual(BudgetIdentityKey.sanitized("future-service"), "future-service",
                       "la clé inconnue n'est PAS détruite — elle redeviendra utile si le catalogue l'ajoute")
    }
}
