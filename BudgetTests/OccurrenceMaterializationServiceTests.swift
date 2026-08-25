import XCTest
import SwiftData
@testable import Budget

/// W2.2 — la matérialisation des échéances : idempotente, honnête sur
/// l'état de naissance, sourde aux récurrences inactives, et elle ne
/// réécrit JAMAIS un état déjà vécu.
final class OccurrenceMaterializationServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private var service: OccurrenceMaterializationService!

    // 15.06.2026 12:00 UTC — même référence que les tests de snapshot.
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        service = OccurrenceMaterializationService(calendar: calendar)
    }

    override func tearDown() {
        service = nil; calendar = nil; context = nil; container = nil
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 10))!
    }

    private func interval(_ y: Int, _ m: Int) -> MonthInterval {
        MonthInterval(containing: date(y, m, 15), calendar: calendar)
    }

    private func loyer(premiere: Date) -> RecurringTransaction {
        let r = RecurringTransaction(
            title: "Loyer", amount: Decimal("1500.00"), type: .expense,
            firstOccurrence: premiere)
        context.insert(r)
        return r
    }

    // FI-03 : matérialiser deux fois = le MÊME nombre d'objets.
    func testMaterializationIsIdempotent() throws {
        let r = loyer(premiere: date(2026, 1, 1))
        let creees = try service.materialize(
            recurrings: [r], in: interval(2026, 6), now: now, context: context)
        XCTAssertEqual(creees.count, 1)

        let rejouees = try service.materialize(
            recurrings: [r], in: interval(2026, 6), now: now, context: context)
        XCTAssertTrue(rejouees.isEmpty, "re-matérialiser ne crée RIEN de neuf")
        XCTAssertEqual(try context.fetch(FetchDescriptor<ScheduledOccurrence>()).count, 1)
    }

    // FI-02 : l'état de naissance dit la vérité du calendrier — jamais
    // « confirmé ». Échéance passée → « À confirmer » ; future → « Prévu ».
    func testBirthStateIsDueForPastAndScheduledForFuture() throws {
        let r = loyer(premiere: date(2026, 1, 1))
        let juin = try service.materialize(
            recurrings: [r], in: interval(2026, 6), now: now, context: context)
        let juillet = try service.materialize(
            recurrings: [r], in: interval(2026, 7), now: now, context: context)
        XCTAssertEqual(juin.first?.state, .due, "le 1er juin est passé au 15 juin → à confirmer")
        XCTAssertEqual(juillet.first?.state, .scheduled, "juillet n'est pas arrivé → prévu")
        XCTAssertEqual(juin.first?.expectedAmount, Decimal("1500.00"), "montant attendu conservé (FI-05)")
        XCTAssertNil(juin.first?.matchedTransactionID, "naître ne lie aucun mouvement")
    }

    // Une échéance vécue (reportée) n'est JAMAIS réécrite par une
    // re-matérialisation : la clé existante la protège.
    func testRematerializationNeverRewritesALivedOccurrence() throws {
        let r = loyer(premiere: date(2026, 1, 1))
        let creees = try service.materialize(
            recurrings: [r], in: interval(2026, 6), now: now, context: context)
        let occurrence = try XCTUnwrap(creees.first)
        occurrence.state = .snoozed
        occurrence.dueDate = date(2026, 6, 20)
        try context.save()

        try service.materialize(
            recurrings: [r], in: interval(2026, 6), now: now, context: context)
        let relues = try context.fetch(FetchDescriptor<ScheduledOccurrence>())
        XCTAssertEqual(relues.count, 1)
        XCTAssertEqual(relues.first?.state, .snoozed, "l'état vécu survit")
        XCTAssertEqual(relues.first?.dueDate, date(2026, 6, 20), "le report survit")
        XCTAssertEqual(relues.first?.originalDueDate, date(2026, 6, 1), "l'origine ne bouge jamais")
    }

    // Une récurrence inactive ne matérialise rien.
    func testInactiveRecurringMaterializesNothing() throws {
        let r = loyer(premiere: date(2026, 1, 1))
        r.isActive = false
        let creees = try service.materialize(
            recurrings: [r], in: interval(2026, 6), now: now, context: context)
        XCTAssertTrue(creees.isEmpty)
    }

    // Un rythme à deux échéances dans le mois crée DEUX occurrences aux
    // deux dates réelles — clés distinctes, jamais fusionnées (REC2).
    func testTwoOccurrencesInOneMonthGetTwoDistinctKeys() throws {
        let r = RecurringTransaction(
            title: "Salaire aux deux semaines", amount: Decimal("2000.00"),
            type: .income, intervalUnit: .week, intervalCount: 2,
            firstOccurrence: date(2026, 6, 5))
        context.insert(r)
        let creees = try service.materialize(
            recurrings: [r], in: interval(2026, 6), now: now, context: context)
        XCTAssertEqual(creees.count, 2, "5 et 19 juin : deux échéances réelles")
        XCTAssertEqual(Set(creees.map(\.idempotencyKey)).count, 2)
    }
}
