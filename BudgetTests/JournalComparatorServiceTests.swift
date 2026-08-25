import XCTest
import SwiftData
@testable import Budget

/// W3.6b — le comparateur natif et la porte de bascule : zéro écart
/// exigé, refus nommés, ouverture en chaîne corrigeable, rollback
/// toujours permis.
final class JournalComparatorServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var comparateur: JournalComparatorService!
    private var ombre: JournalShadowService!
    private var defaults: UserDefaults!
    private var courant: Account!
    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        comparateur = JournalComparatorService()
        ombre = JournalShadowService()
        defaults = UserDefaults(suiteName: "w36b-tests-\(UUID().uuidString)")
        courant = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        context.insert(courant)
    }

    override func tearDown() {
        courant = nil; defaults = nil; ombre = nil; comparateur = nil
        context = nil; container = nil
    }

    // ZÉRO écart : l'historique est complété (mouvement hérité +
    // ouverture) et chaque solde dérivé égale le solde vivant.
    func testCleanStoreComparesToZeroGap() throws {
        // Un mouvement HÉRITÉ : inséré sans passer par l'ombre.
        let herite = BudgetTransaction(
            date: now, amount: Decimal("84.30"), type: .expense,
            title: "Hérité", account: courant)
        context.insert(herite)
        try context.save()
        let ecarts = comparateur.comparer(now: now, context: context)
        XCTAssertEqual(ecarts, [])
        XCTAssertEqual(comparateur.soldeDerive(de: courant, context: context),
                       AccountBalanceService().balance(of: courant))
        XCTAssertEqual(comparateur.soldeDerive(de: courant, context: context), Decimal("4915.70"))
        XCTAssertNotNil(ombre.ecritureActive(cle: "ouverture:\(courant.id.uuidString)", context: context),
                        "l'ouverture est devenue une écriture (FI-12)")
        // Idempotent : re-comparer ne duplique rien.
        let taille = try context.fetch(FetchDescriptor<JournalEntry>()).count
        XCTAssertEqual(comparateur.comparer(now: now, context: context), [])
        XCTAssertEqual(try context.fetch(FetchDescriptor<JournalEntry>()).count, taille)
    }

    // Une écriture falsifiée fait un écart qui NOMME le compte.
    func testTamperedEntryYieldsANamedGap() throws {
        let mouvement = BudgetTransaction(
            date: now, amount: Decimal("100.00"), type: .expense,
            title: "Vrai", account: courant)
        context.insert(mouvement)
        try context.save()
        XCTAssertEqual(comparateur.comparer(now: now, context: context), [])
        let ecriture = try XCTUnwrap(ombre.ecritureActive(transactionID: mouvement.id, context: context))
        for posting in ecriture.postings { posting.minorUnits = 1 }
        try context.save()
        let ecarts = comparateur.comparer(now: now, context: context)
        XCTAssertTrue(ecarts.contains { $0.contains("Courant") },
                      "l'écart nomme le compte : \(ecarts)")
    }

    // Un compte assis sur un point de rapprochement est un écart
    // CONSIGNÉ — le journal ne modélise pas encore les relevés (W4).
    func testReconciledBaseIsAConsignedGap() throws {
        courant.reconciledBalance = Decimal("4000.00")
        courant.reconciledAt = now.addingTimeInterval(-86_400)
        try context.save()
        let ecarts = comparateur.comparer(now: now, context: context)
        XCTAssertTrue(ecarts.contains { $0.contains("rapprochement") && $0.contains("W4") },
                      "jamais deviné, toujours nommé : \(ecarts)")
    }

    // La porte : refus nommé tant qu'un écart existe (le drapeau ne
    // bouge pas), activation sur état propre, rollback toujours permis.
    func testSwitchIsGuardedAndRollbackAlwaysAllowed() throws {
        let perdu = BudgetTransaction(
            date: now, amount: Decimal("50.00"), type: .saving,
            title: "Sans destination", account: courant)
        context.insert(perdu)
        try context.save()
        let refus = JournalReadSwitch.activer(
            now: now, context: context, defaults: defaults, comparateur: comparateur)
        XCTAssertNotNil(refus)
        XCTAssertTrue(refus?.contains("Sans destination") == true, "le refus nomme l'écart")
        XCTAssertFalse(JournalReadSwitch.estActif(defaults: defaults))

        context.delete(perdu)
        try context.save()
        XCTAssertNil(JournalReadSwitch.activer(
            now: now, context: context, defaults: defaults, comparateur: comparateur))
        XCTAssertTrue(JournalReadSwitch.estActif(defaults: defaults))

        JournalReadSwitch.desactiver(defaults: defaults)
        XCTAssertFalse(JournalReadSwitch.estActif(defaults: defaults),
                       "éteindre est toujours permis — rollback documenté")
    }

    // FI-12 + FI-07 : éditer l'ouverture corrige la CHAÎNE — originale
    // intacte, inversion liée, remplaçante :r2 — et le solde dérivé suit.
    func testOpeningEditCorrectsTheChain() throws {
        try context.save()
        XCTAssertEqual(comparateur.comparer(now: now, context: context), [])
        let originale = try XCTUnwrap(
            ombre.ecritureActive(cle: "ouverture:\(courant.id.uuidString)", context: context))
        courant.openingBalance = Decimal("6000.00")
        ombre.deposerOuverture(courant, now: now, context: context)
        try context.save()
        let active = try XCTUnwrap(
            ombre.ecritureActive(cle: "ouverture:\(courant.id.uuidString)", context: context))
        XCTAssertTrue(active.idempotencyKey.hasSuffix(":r2"))
        XCTAssertEqual(active.replacesEntryID, originale.id)
        let toutes = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertTrue(toutes.contains { $0.reversesEntryID == originale.id },
                      "l'inversion trace l'ancienne ouverture")
        XCTAssertEqual(comparateur.soldeDerive(de: courant, context: context), Decimal("6000.00"))
        XCTAssertEqual(comparateur.comparer(now: now, context: context), [])
    }
}
