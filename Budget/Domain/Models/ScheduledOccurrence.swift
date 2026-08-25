import Foundation
import SwiftData

/// W2.1 (Budget Autonomie 100) — l'état d'une échéance planifiée.
/// Vocabulaire du glossaire W0 (`docs/autonomie/w0/GLOSSAIRE_ETATS.md`) :
/// une échéance N'EST PAS un mouvement — tant que personne ne confirme,
/// rien ne bouge (règle centrale du skill, FI-02).
enum ScheduledOccurrenceState: String, CaseIterable, Codable {
    case scheduled
    case due
    case matchProposed
    case confirmed
    case skipped
    case snoozed
    case cancelled
    case failed

    var displayName: String {
        switch self {
        case .scheduled: "Prévu"
        case .due: "À confirmer"
        case .matchProposed: "Proposé"
        case .confirmed: "Confirmé"
        case .skipped: "Ignoré"
        case .snoozed: "Reporté"
        case .cancelled: "Annulé"
        case .failed: "Échec"
        }
    }
}

/// W2.1 — une échéance récurrente PERSISTÉE : identité stable, état,
/// montant attendu conservé (FI-05), lien vers le mouvement qui la
/// confirme (FI-03) et clé d'idempotence (FI-04 — régénérer ou
/// confirmer deux fois ne crée jamais une seconde échéance ni une
/// seconde écriture).
///
/// W2.1 est un lot de MODÈLE : aucune vue ni aucun service de calcul ne
/// lit encore ces objets (stratégie shadow-write, ADR-058). La
/// matérialisation arrive en W2.2, la machine à états en W2.3.
@Model
final class ScheduledOccurrence {
    @Attribute(.unique) var id: UUID
    /// Série d'origine (RecurringTransaction.id) — nil pour une facture
    /// ponctuelle (W2.6 : une facture est une occurrence sans série).
    var seriesID: UUID?
    /// Révision de la série au moment de la matérialisation : modifier
    /// la série ne réécrit jamais une échéance déjà vécue.
    var seriesRevision: Int
    var dueDate: Date
    /// Date d'échéance d'origine — `dueDate` bouge quand on reporte,
    /// `originalDueDate` jamais.
    var originalDueDate: Date
    /// Montant ATTENDU, conservé même quand le montant réellement payé
    /// diffère (FI-05). Nil = série à montant variable.
    var expectedAmount: Decimal?
    var stateRawValue: String
    /// Mouvement qui confirme cette échéance (BudgetTransaction.id).
    var matchedTransactionID: UUID?
    var confirmedAt: Date?
    /// Clé d'idempotence de la matérialisation ET de la confirmation :
    /// unique par (série, échéance d'origine) — la régénération retombe
    /// dessus au lieu de dupliquer (FI-03/04).
    @Attribute(.unique) var idempotencyKey: String
    var createdAt: Date
    var updatedAt: Date

    var state: ScheduledOccurrenceState {
        get { ScheduledOccurrenceState(rawValue: stateRawValue) ?? .scheduled }
        set { stateRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        seriesID: UUID?,
        seriesRevision: Int = 1,
        dueDate: Date,
        originalDueDate: Date? = nil,
        expectedAmount: Decimal? = nil,
        state: ScheduledOccurrenceState = .scheduled,
        matchedTransactionID: UUID? = nil,
        confirmedAt: Date? = nil,
        idempotencyKey: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.seriesID = seriesID
        self.seriesRevision = seriesRevision
        self.dueDate = dueDate
        self.originalDueDate = originalDueDate ?? dueDate
        self.expectedAmount = expectedAmount
        self.stateRawValue = state.rawValue
        self.matchedTransactionID = matchedTransactionID
        self.confirmedAt = confirmedAt
        self.idempotencyKey = idempotencyKey
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// La clé canonique d'une échéance de série : stable pour un couple
    /// (série, date d'origine) — deux matérialisations du même mois
    /// produisent la MÊME clé, donc jamais deux objets.
    static func serieKey(seriesID: UUID, originalDueDate: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: originalDueDate)
        return "serie:\(seriesID.uuidString):\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}
