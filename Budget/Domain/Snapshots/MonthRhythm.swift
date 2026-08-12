import Foundation

/// Où en est le mois : le rythme de l'argent comparé au rythme du temps.
///
/// « Est-ce que je peux sortir ce week-end ? » ne se répond pas avec un
/// solde : elle se répond avec un rythme. Le web porte cette carte depuis
/// le 10.08.2026 ; ce type en est l'équivalent natif, à partir des MÊMES
/// grandeurs du snapshot (`available.total`, `totalLivingExpenses`,
/// `dailyAvailableBudget`, `daysRemaining`) — jamais une seconde formule.
///
/// C'est un CONSTAT arithmétique sur les données de l'utilisateur, pas un
/// conseil : l'app ne dit jamais quoi faire, elle dit où on en est.
///
/// L'enveloppe libre = déjà dépensé + encore disponible. `available` a
/// DÉJÀ déduit ce qui doit encore sortir (charges engagées, récurrents,
/// réserve d'impôts), donc les deux parts ne se chevauchent pas et rien
/// n'est compté deux fois.
///
/// Les parts sont des `Double` : ce sont des géométries d'affichage
/// (largeur de barre, position de jalon), jamais des montants. L'argent
/// (`missing`, `daily`) reste en `Decimal`, conformément à l'invariant.
enum MonthRhythm: Equatable {
    /// À découvert : on dit le fait et le temps restant. Pas de barre —
    /// une jauge pleine ferait la morale, ce n'est pas le rôle de l'app.
    case overdrawn(missing: Decimal, daysRemaining: Int)

    /// Le rythme mesurable : part de l'enveloppe libre déjà dépensée,
    /// part du mois écoulée, et le budget du jour qui en découle.
    case pace(
        spentShare: Double,
        timeShare: Double,
        daily: Decimal,
        daysRemaining: Int,
        isAhead: Bool
    )

    /// Marge avant de déclarer « en avance » : un écart d'un franc ne doit
    /// pas faire clignoter un avertissement le 2 du mois. Mêmes trois
    /// points que le web.
    static let aheadMargin = 0.03

    /// Cœur du calcul, en grandeurs primitives : testable sans SwiftData.
    static func compute(
        available: Decimal,
        living: Decimal,
        daily: Decimal,
        daysRemaining: Int,
        isCurrentMonth: Bool,
        now: Date,
        calendar: Calendar
    ) -> MonthRhythm? {
        // Un mois passé ou futur n'a pas de rythme : il n'y a plus (ou pas
        // encore) de course entre l'argent et le temps.
        guard isCurrentMonth else { return nil }

        if available < 0 {
            return .overdrawn(missing: -available, daysRemaining: daysRemaining)
        }

        let envelope = living + available
        guard envelope > 0 else { return nil }

        let spentShare = min(1, max(0,
            NSDecimalNumber(decimal: living).doubleValue
                / NSDecimalNumber(decimal: envelope).doubleValue))
        let day = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let timeShare = min(1, Double(day) / Double(daysInMonth))

        return .pace(
            spentShare: spentShare,
            timeShare: timeShare,
            daily: daily,
            daysRemaining: daysRemaining,
            isAhead: spentShare > timeShare + aheadMargin
        )
    }

    /// Commodité pour l'écran d'accueil : mêmes grandeurs, lues du snapshot.
    static func compute(
        snapshot: MonthSnapshot,
        now: Date,
        calendar: Calendar
    ) -> MonthRhythm? {
        compute(
            available: snapshot.available.total,
            living: snapshot.totalLivingExpenses,
            daily: snapshot.dailyAvailableBudget,
            daysRemaining: snapshot.daysRemaining,
            isCurrentMonth: snapshot.interval.contains(now),
            now: now,
            calendar: calendar
        )
    }
}
