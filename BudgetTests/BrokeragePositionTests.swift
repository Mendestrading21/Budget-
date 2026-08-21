import XCTest
import SwiftData
@testable import Budget

/// INV1 (ADR-047) : les positions manuelles datées EXPLIQUENT le solde du
/// compte titres — jamais elles ne s'y ajoutent. 44'000 de solde et
/// 40'000 de positions font 4'000 d'espèces et une fortune de 44'000 —
/// jamais 84'000. Le parcours e2e 168 prouve la même règle côté PWA.
final class BrokeragePositionTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = BackupService()
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    private func makeBrokerAccount(opening: Decimal) -> Account {
        Account(name: "Compte titres", type: .broker, openingBalance: opening,
                createdAt: now, updatedAt: now)
    }

    func testPositionsExplainTheBalanceNeverAddToIt() {
        let account = makeBrokerAccount(opening: Decimal(44000))
        let position = BrokeragePosition(
            instrumentName: "Actions Monde", tickerOrISIN: "VWRL",
            quantity: Decimal(100), manualPrice: Decimal(400),
            valuationDate: now, account: account
        )
        XCTAssertEqual(position.value, Decimal(40000), "100 × 400 = 40'000")
        XCTAssertEqual(BrokeragePositionMath.explainedTotal([position]), Decimal(40000))
        XCTAssertEqual(
            BrokeragePositionMath.unallocated(balance: Decimal(44000), positions: [position]),
            Decimal(4000),
            "44'000 de solde − 40'000 de positions = 4'000 d'espèces — la fortune reste 44'000, jamais 84'000"
        )
        XCTAssertEqual(account.openingBalance, Decimal(44000),
                       "enregistrer une position ne touche JAMAIS le solde")
    }

    func testUnallocatedGoesNegativeInsteadOfLying() {
        let position = BrokeragePosition(
            instrumentName: "Trop gros", quantity: Decimal(200),
            manualPrice: Decimal(400), valuationDate: now
        )
        XCTAssertEqual(
            BrokeragePositionMath.unallocated(balance: Decimal(44000), positions: [position]),
            Decimal(-36000),
            "un dépassement s'affiche en négatif avec un avertissement — jamais ramené à zéro en silence"
        )
    }

    func testBackupRoundTripCarriesPositions() throws {
        let account = makeBrokerAccount(opening: Decimal(44000))
        context.insert(account)
        context.insert(BrokeragePosition(
            instrumentName: "Actions Monde", tickerOrISIN: "VWRL",
            quantity: Decimal(100), manualPrice: Decimal("400.55"),
            priceCurrency: "CHF", valuationDate: now,
            costBasis: Decimal("36000.00"), account: account
        ))
        try context.save()

        let data = try service.makeBackup(context: context, now: now)
        let fresh = try PersistenceFactory.makeInMemoryContainer()
        let freshContext = ModelContext(fresh)
        try service.restore(data: data, context: freshContext, documentFileStore: nil)

        let restored = try XCTUnwrap(
            try freshContext.fetch(FetchDescriptor<BrokeragePosition>()).first
        )
        XCTAssertEqual(restored.instrumentName, "Actions Monde")
        XCTAssertEqual(restored.tickerOrISIN, "VWRL")
        XCTAssertEqual(restored.quantity, Decimal(100))
        XCTAssertEqual(restored.manualPrice, Decimal("400.55"), "le Decimal survit au JSON, exactement")
        XCTAssertEqual(restored.costBasis, Decimal("36000.00"))
        XCTAssertEqual(restored.account?.name, "Compte titres", "la position retrouve SON compte")
    }

    func testOldBackupWithoutPositionsRestoresIdentically() throws {
        let account = makeBrokerAccount(opening: Decimal(1000))
        context.insert(account)
        try context.save()
        var payload = try JSONSerialization.jsonObject(
            with: service.makeBackup(context: context, now: now)
        ) as! [String: Any]
        payload.removeValue(forKey: "positions")
        let legacy = try JSONSerialization.data(withJSONObject: payload)

        let fresh = try PersistenceFactory.makeInMemoryContainer()
        let freshContext = ModelContext(fresh)
        try service.restore(data: legacy, context: freshContext, documentFileStore: nil)
        XCTAssertEqual(try freshContext.fetch(FetchDescriptor<BrokeragePosition>()).count, 0,
                       "un fichier d'avant les positions se restaure à l'identique, sans erreur")
        XCTAssertEqual(try freshContext.fetch(FetchDescriptor<Account>()).count, 1)
    }
}
