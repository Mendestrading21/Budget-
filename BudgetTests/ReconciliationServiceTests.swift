import XCTest
import SwiftData
@testable import Budget

/// W4.4b — la porte de réconciliation native : point + relevé +
/// figeage du journal ensemble ; cycle à sens unique ; correction d'une
/// écriture rapprochée toujours en chaîne (FI-06/07).
final class ReconciliationServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: ReconciliationService!
    private var ombre: JournalShadowService!
    private var compte: Account!
    private var autre: Account!
    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        service = ReconciliationService()
        ombre = JournalShadowService()
        compte = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        autre = Account(name: "Épargne", type: .savings, openingBalance: .zero)
        context.insert(compte); context.insert(autre)
    }

    override func tearDown() {
        autre = nil; compte = nil; ombre = nil; service = nil; context = nil; container = nil
    }

    private func mouvement(_ titre: String, sur lequel: Account, statut: TransactionStatus = .posted,
                           depuis joursAvant: Double = 2) -> BudgetTransaction {
        let m = BudgetTransaction(
            date: now.addingTimeInterval(-joursAvant * 86_400), amount: Decimal("84.30"),
            type: .expense, status: statut, title: titre, account: lequel)
        context.insert(m)
        ombre.deposer(m, now: now, context: context)
        return m
    }

    // FI-06 : le cycle avance dans UN sens — un retour est un refus
    // typé, « reconciled » est terminal.
    func testCycleIsOneWay() throws {
        let m = mouvement("Courses", sur: compte)
        try context.save()
        let entree = try XCTUnwrap(ombre.ecritureActive(transactionID: m.id, context: context))
        try entree.avancerCycle(vers: .cleared)
        XCTAssertThrowsError(try entree.avancerCycle(vers: .posted)) { erreur in
            XCTAssertEqual(erreur as? JournalCycleError,
                           .retourInterdit(de: .cleared, vers: .posted))
        }
        XCTAssertEqual(entree.lifecycle, .cleared, "un refus ne bouge RIEN")
        try entree.avancerCycle(vers: .reconciled)
        for cible in JournalLifecycle.allCases {
            XCTAssertThrowsError(try entree.avancerCycle(vers: cible),
                                 "« reconciled » est terminal (→ \(cible.rawValue))")
        }
    }

    // La porte fait les TROIS gestes ensemble : point, relevé daté,
    // figeage — le prévu et l'autre compte ne bougent jamais.
    func testReconcilingDoesTheThreeGesturesTogether() throws {
        let passee = mouvement("Courses", sur: compte)
        let ailleurs = mouvement("Autre compte", sur: autre)
        let prevu = mouvement("Prévu", sur: compte, statut: .planned)
        try context.save()

        service.reconcilier(compte: compte, soldeConstate: Decimal("4900.00"),
                            now: now, context: context)
        try context.save()

        XCTAssertEqual(compte.reconciledBalance, Decimal("4900.00"))
        XCTAssertEqual(compte.reconciledAt, now)
        let releves = try context.fetch(FetchDescriptor<Statement>())
        XCTAssertEqual(releves.count, 1)
        XCTAssertEqual(releves.first?.source, "réconciliation manuelle")
        XCTAssertEqual(releves.first?.closingBalance, Decimal("4900.00"))
        XCTAssertEqual(releves.first?.state, .reconciled)

        XCTAssertEqual(ombre.ecritureActive(transactionID: passee.id, context: context)?.lifecycle,
                       .reconciled, "l'histoire du compte est FIGÉE")
        XCTAssertEqual(ombre.ecritureActive(transactionID: ailleurs.id, context: context)?.lifecycle,
                       .posted, "l'autre compte ne bouge pas")
        XCTAssertEqual(ombre.ecritureActive(transactionID: prevu.id, context: context)?.lifecycle,
                       .pending, "le prévu ne se rapproche jamais (FI-01)")
    }

    // FI-07 : corriger un mouvement rapproché ne MUTE jamais l'écriture
    // rapprochée — la chaîne corrige (inversion + remplaçante).
    func testCorrectingAReconciledEntryStaysChainBased() throws {
        let m = mouvement("Courses", sur: compte)
        try context.save()
        service.reconcilier(compte: compte, soldeConstate: Decimal("4915.70"),
                            now: now, context: context)
        try context.save()
        let rapprochee = try XCTUnwrap(ombre.ecritureActive(transactionID: m.id, context: context))
        XCTAssertEqual(rapprochee.lifecycle, .reconciled)

        m.amount = Decimal("90.00")
        ombre.deposer(m, now: now, context: context)
        try context.save()

        XCTAssertEqual(rapprochee.lifecycle, .reconciled, "l'écriture rapprochée n'a pas bougé")
        XCTAssertEqual(rapprochee.postings.map(\.minorUnits), [8430, 8430],
                       "ses centimes non plus")
        let active = try XCTUnwrap(ombre.ecritureActive(transactionID: m.id, context: context))
        XCTAssertEqual(active.replacesEntryID, rapprochee.id)
        XCTAssertEqual(active.postings.map(\.minorUnits), [9000, 9000])
        XCTAssertTrue(try context.fetch(FetchDescriptor<JournalEntry>())
            .contains { $0.reversesEntryID == rapprochee.id },
            "l'inversion trace la correction")
    }

    // Réconcilier deux fois consigne DEUX relevés (append-only) et
    // reste stable.
    func testReconcilingTwiceAppendsTwoStatements() throws {
        _ = mouvement("Courses", sur: compte)
        try context.save()
        service.reconcilier(compte: compte, soldeConstate: Decimal("4915.70"),
                            now: now, context: context)
        try context.save()
        service.reconcilier(compte: compte, soldeConstate: Decimal("4915.70"),
                            now: now.addingTimeInterval(86_400), context: context)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Statement>()).count, 2,
                       "chaque réconciliation laisse SA preuve")
        XCTAssertEqual(compte.reconciledBalance, Decimal("4915.70"))
    }
}
