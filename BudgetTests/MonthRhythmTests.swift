import XCTest
@testable import Budget

/// Le rythme du mois — parité avec la carte web du 10.08.2026.
/// Calcul PUR : aucun SwiftData, des grandeurs et un calendrier fixes.
final class MonthRhythmTests: XCTestCase {
    private var calendar: Calendar!
    // 15.06.2026 12:00 UTC — le 15 d'un mois de 30 jours : part du temps 0,5.
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    override func tearDown() {
        calendar = nil
    }

    private func compute(
        available: Decimal,
        living: Decimal,
        daily: Decimal = Decimal("40.00"),
        daysRemaining: Int = 16,
        isCurrentMonth: Bool = true
    ) -> MonthRhythm? {
        MonthRhythm.compute(
            available: available,
            living: living,
            daily: daily,
            daysRemaining: daysRemaining,
            isCurrentMonth: isCurrentMonth,
            now: now,
            calendar: calendar
        )
    }

    func testPastOrFutureMonthHasNoRhythm() {
        XCTAssertNil(compute(available: 600, living: 400, isCurrentMonth: false),
                     "Un mois passé n'a plus de course entre l'argent et le temps")
    }

    func testOnTrackWhenMoneyIsSlowerThanTime() {
        // 400 dépensés sur une enveloppe de 1000 → 40 % ; temps à 50 %.
        guard case .pace(let spent, let time, let daily, let days, let ahead)?
                = compute(available: 600, living: 400) else {
            return XCTFail("attendu .pace")
        }
        XCTAssertEqual(spent, 0.4, accuracy: 0.0001)
        XCTAssertEqual(time, 0.5, accuracy: 0.0001)
        XCTAssertEqual(daily, Decimal("40.00"))
        XCTAssertEqual(days, 16)
        XCTAssertFalse(ahead, "40 % d'argent pour 50 % du temps = dans le rythme")
    }

    func testAheadWhenMoneyOutrunsTime() {
        // 700 dépensés sur 1000 → 70 % ; temps à 50 %.
        guard case .pace(_, _, _, _, let ahead)? = compute(available: 300, living: 700) else {
            return XCTFail("attendu .pace")
        }
        XCTAssertTrue(ahead)
    }

    /// La marge de trois points, aux DEUX bords : un écart d'un franc ne
    /// fait pas clignoter un avertissement le 2 du mois.
    func testThreePointMarginBeforeWarning() {
        guard case .pace(_, _, _, _, let dansLaMarge)? = compute(available: 48, living: 52),
              case .pace(_, _, _, _, let horsMarge)? = compute(available: 46, living: 54) else {
            return XCTFail("attendu .pace")
        }
        XCTAssertFalse(dansLaMarge, "52 % d'argent pour 50 % du temps reste dans la marge")
        XCTAssertTrue(horsMarge, "54 % d'argent pour 50 % du temps la dépasse")
    }

    func testOverdrawnStatesTheFactWithoutABar() {
        guard case .overdrawn(let missing, let days)?
                = compute(available: Decimal("-800.00"), living: 3000) else {
            return XCTFail("attendu .overdrawn")
        }
        XCTAssertEqual(missing, Decimal("800.00"), "le manque est dit en positif")
        XCTAssertEqual(days, 16)
    }

    func testEmptyEnvelopeStaysSilent() {
        XCTAssertNil(compute(available: 0, living: 0),
                     "sans un franc dépensé ni disponible, il n'y a rien à rythmer")
    }

    func testSpentShareIsClampedAtOne() {
        // Tout est dépensé, rien ne reste : 100 %, jamais plus.
        guard case .pace(let spent, _, _, _, _)? = compute(available: 0, living: 500) else {
            return XCTFail("attendu .pace")
        }
        XCTAssertEqual(spent, 1.0, accuracy: 0.0001)
    }

    /// Le raccourci snapshot lit les MÊMES grandeurs que le cœur primitif :
    /// si quelqu'un change l'un sans l'autre, ce test le dit.
    func testSnapshotConvenienceMatchesPrimitiveCore() {
        let service = MonthlySnapshotService(calendar: calendar)
        let snapshot = service.snapshot(
            monthOf: now, now: now, household: nil,
            accounts: [], transactions: [], recurrings: []
        )
        let viaSnapshot = MonthRhythm.compute(snapshot: snapshot, now: now, calendar: calendar)
        let viaCore = MonthRhythm.compute(
            available: snapshot.available.total,
            living: snapshot.totalLivingExpenses,
            daily: snapshot.dailyAvailableBudget,
            daysRemaining: snapshot.daysRemaining,
            isCurrentMonth: snapshot.interval.contains(now),
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(viaSnapshot, viaCore)
    }
}
