import Foundation
import SwiftData

/// W4.3 (Budget Autonomie 100) — l'état d'un relevé de rapprochement.
enum StatementState: String, CaseIterable, Codable {
    case draft
    case reconciled
    case reopened

    var displayName: String {
        switch self {
        case .draft: "Brouillon"
        case .reconciled: "Rapproché"
        case .reopened: "Rouvert"
        }
    }
}

/// W4.3 — le RELEVÉ : la preuve datée d'un solde constaté sur un
/// compte (période, solde de clôture, état, provenance). Il remplace à
/// terme le point nu `reconciledBalance` du compte — d'abord en
/// PARALLÈLE (additif, schéma V14) : `balance()` continue de lire le
/// point existant jusqu'au rapprochement complet (W4.4), consigné.
@Model
final class Statement {
    @Attribute(.unique) var id: UUID
    var accountID: UUID
    /// Début de période — nil pour un relevé ponctuel (photo d'un jour).
    var periodStart: Date?
    var periodEnd: Date
    var openingBalance: Decimal?
    var closingBalance: Decimal
    var stateRawValue: String
    /// Provenance honnête : « réconciliation manuelle », « point de
    /// rapprochement migré (avant W4.3) »… jamais devinée.
    var source: String
    var reconciledAt: Date?
    var createdAt: Date

    var state: StatementState {
        get { StatementState(rawValue: stateRawValue) ?? .draft }
        set { stateRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        accountID: UUID,
        periodStart: Date? = nil,
        periodEnd: Date,
        openingBalance: Decimal? = nil,
        closingBalance: Decimal,
        state: StatementState = .draft,
        source: String,
        reconciledAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.accountID = accountID
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.openingBalance = openingBalance
        self.closingBalance = closingBalance
        self.stateRawValue = state.rawValue
        self.source = source
        self.reconciledAt = reconciledAt
        self.createdAt = createdAt
    }
}

/// W4.3 — la migration du POINT NU : chaque compte portant un
/// `reconciledBalance`/`reconciledAt` reçoit un relevé synthétique
/// CLAIREMENT marqué (source explicite — jamais deviné, FI-34).
/// Idempotente : re-migrer ne duplique rien. Le point du compte reste
/// INTACT — `balance()` continue de le lire jusqu'à W4.4 (consigné).
struct StatementMigrationService {
    static let sourceMigration = "point de rapprochement migré (avant W4.3)"

    @discardableResult
    func migrerPointsDeRapprochement(now: Date, context: ModelContext) -> Int {
        let comptes = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let existants = (try? context.fetch(FetchDescriptor<Statement>())) ?? []
        let dejaMigres = Set(existants
            .filter { $0.source == Self.sourceMigration }
            .map(\.accountID))
        var crees = 0
        for compte in comptes {
            guard let solde = compte.reconciledBalance,
                  let date = compte.reconciledAt,
                  !dejaMigres.contains(compte.id) else { continue }
            context.insert(Statement(
                accountID: compte.id,
                periodEnd: date,
                closingBalance: solde,
                state: .reconciled,
                source: Self.sourceMigration,
                reconciledAt: date,
                createdAt: now
            ))
            crees += 1
        }
        return crees
    }
}
