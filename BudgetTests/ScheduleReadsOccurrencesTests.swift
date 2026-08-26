import XCTest
import SwiftData
@testable import Budget

/// W5.2b — le miroir natif de W5.2 : le rituel du mois LIT les
/// échéances persistées. Une échéance IGNORÉE ou ANNULÉE (machine
/// W2.3/W2.5) est un choix — elle n'attend plus, sans créer aucun
/// mouvement ; une échéance REPORTÉE reste ouverte.
final class ScheduleReadsOccurrencesTests: XCTestCase {

    private var calendar: Calendar!
    private var service: RecurringScheduleService!
    private var interval: MonthInterval!
    private let ancre = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        service = RecurringScheduleService(calendar: calendar)
        interval = MonthInterval(containing: ancre, calendar: calendar)
    }

    private func loyer() -> RecurringTransaction {
        RecurringTransaction(
            title: "Loyer", amount: Decimal("1500.00"), type: .expense,
            intervalUnit: .month, intervalCount: 1,
            firstOccurrence: calendar.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 10))!
        )
    }

    private func echeance(_ serie: RecurringTransaction,
                          etat: ScheduledOccurrenceState) -> ScheduledOccurrence {
        let due = calendar.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: 10))!
        let o = ScheduledOccurrence(
            seriesID: serie.id, dueDate: due,
            expectedAmount: serie.amount,
            idempotencyKey: "w52b:\(etat.rawValue)")
        o.stateRawValue = etat.rawValue
        return o
    }

    // IGNORÉE : l'échéance n'attend plus — zéro mouvement, zéro attente.
    func testSkippedPersistedOccurrenceNoLongerWaits() {
        let serie = loyer()
        let avant = service.remainingOccurrences(of: serie, in: interval, transactions: [])
        XCTAssertEqual(avant.count, 1, "sans échéance persistée : la charge attend")
        let apres = service.remainingOccurrences(
            of: serie, in: interval, transactions: [],
            persistedOccurrences: [echeance(serie, etat: .skipped)])
        XCTAssertEqual(apres.count, 0, "ignorée = un choix — elle n'attend plus")
    }

    // ANNULÉE pareil ; REPORTÉE reste ouverte (elle reviendra).
    func testCancelledDropsAndSnoozedStaysOpen() {
        let serie = loyer()
        XCTAssertEqual(service.remainingOccurrences(
            of: serie, in: interval, transactions: [],
            persistedOccurrences: [echeance(serie, etat: .cancelled)]).count, 0)
        XCTAssertEqual(service.remainingOccurrences(
            of: serie, in: interval, transactions: [],
            persistedOccurrences: [echeance(serie, etat: .snoozed)]).count, 1,
            "reportée ≠ réglée : elle reste ouverte")
    }

    // Le « Check du mois » compte une série ignorée comme réglée.
    func testMonthCheckCountsSkippedAsDone() {
        let serie = loyer()
        let sans = service.monthCheck(recurrings: [serie], in: interval, transactions: [])
        XCTAssertEqual(sans.done, 0); XCTAssertEqual(sans.total, 1)
        let avec = service.monthCheck(
            recurrings: [serie], in: interval, transactions: [],
            persistedOccurrences: [echeance(serie, etat: .skipped)])
        XCTAssertEqual(avec.done, 1, "la série ignorée est réglée")
        XCTAssertEqual(avec.total, 1)
    }

    // Une échéance d'un AUTRE mois ou d'une AUTRE série ne réduit rien.
    func testForeignOccurrencesNeverReduce() {
        let serie = loyer()
        let autre = loyer()
        let horsMois = ScheduledOccurrence(
            seriesID: serie.id,
            dueDate: calendar.date(from: DateComponents(year: 2026, month: 7, day: 5))!,
            idempotencyKey: "w52b:hors-mois")
        horsMois.stateRawValue = ScheduledOccurrenceState.skipped.rawValue
        XCTAssertEqual(service.remainingOccurrences(
            of: serie, in: interval, transactions: [],
            persistedOccurrences: [horsMois, echeance(autre, etat: .skipped)]).count, 1,
            "ni un autre mois ni une autre série ne règlent CE mois")
    }
}
