import Foundation
import SwiftData

/// W2.2 (Budget Autonomie 100) — matérialise les échéances persistées
/// d'un intervalle depuis les récurrences, de façon IDEMPOTENTE : la
/// clé canonique (`ScheduledOccurrence.serieKey`) retombe sur l'objet
/// existant — re-matérialiser ne duplique jamais et ne réécrit jamais
/// un état déjà vécu (FI-03). SHADOW : aucune vue ni aucun agrégat ne
/// lit encore ces objets (ADR-058) ; les dates viennent du service de
/// calendrier existant (`RecurringScheduleService.occurrenceDates`),
/// aucune nouvelle arithmétique de récurrence.
struct OccurrenceMaterializationService {
    let calendar: Calendar
    private let scheduleService: RecurringScheduleService

    init(calendar: Calendar) {
        self.calendar = calendar
        self.scheduleService = RecurringScheduleService(calendar: calendar)
    }

    /// Matérialise les échéances de `interval`. Retourne UNIQUEMENT les
    /// occurrences créées par cet appel (vide si tout existait déjà).
    /// `now` décide l'état de naissance : échéance passée ou du jour →
    /// « À confirmer » (`due`) ; future → « Prévu » (`scheduled`).
    /// Jamais un état qui prétend qu'un mouvement a eu lieu (FI-02).
    @discardableResult
    func materialize(
        recurrings: [RecurringTransaction],
        in interval: MonthInterval,
        now: Date,
        context: ModelContext
    ) throws -> [ScheduledOccurrence] {
        let existantes = try context.fetch(FetchDescriptor<ScheduledOccurrence>())
        var cles = Set(existantes.map(\.idempotencyKey))
        var creees: [ScheduledOccurrence] = []
        for recurring in recurrings where recurring.isActive {
            for date in scheduleService.occurrenceDates(of: recurring, in: interval) {
                let cle = ScheduledOccurrence.serieKey(
                    seriesID: recurring.id, originalDueDate: date, calendar: calendar)
                guard !cles.contains(cle) else { continue }
                let occurrence = ScheduledOccurrence(
                    seriesID: recurring.id,
                    dueDate: date,
                    expectedAmount: recurring.amount,
                    state: date <= now ? .due : .scheduled,
                    idempotencyKey: cle
                )
                context.insert(occurrence)
                cles.insert(cle)
                creees.append(occurrence)
            }
        }
        if !creees.isEmpty { try context.save() }
        return creees
    }
}
