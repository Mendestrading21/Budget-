import Foundation
import SwiftData

/// W3.1 (Budget Autonomie 100, ADR-063) — la nature d'une écriture.
/// Même vocabulaire que les types de mouvements existants, plus
/// « opening » (le solde d'ouverture devient une écriture, FI-12 —
/// livré en W3.2).
enum JournalEntryKind: String, CaseIterable, Codable {
    case income
    case expense
    case refund
    case saving
    case investment
    case transfer
    case taxPayment
    case debtPayment
    case adjustment
    case opening
}

/// W3.1 — le cycle de VIE d'une écriture (FI-06) : en attente, posté,
/// passé en banque, rapproché. Une écriture rapprochée deviendra
/// immuable (FI-07, gardé en W3.5 par inversion/remplacement).
enum JournalLifecycle: String, CaseIterable, Codable {
    case pending
    case posted
    case cleared
    case reconciled

    var displayName: String {
        switch self {
        case .pending: "En attente"
        case .posted: "Posté"
        case .cleared: "Passé en banque"
        case .reconciled: "Rapproché"
        }
    }
}

/// W3.1 — un refus du journal est une erreur TYPÉE et nommée en
/// français — jamais un zéro, jamais un arrondi silencieux (FI-34).
enum JournalEntryError: Error, Equatable, LocalizedError {
    case postingsInsuffisants
    case compteManquant
    case montantInvalide
    case deviseInvalide(String)
    case desequilibre(devise: String, ecartMineur: Int64)

    var errorDescription: String? {
        switch self {
        case .postingsInsuffisants:
            "Une écriture a toujours deux jambes (deux postings au moins)."
        case .compteManquant:
            "Chaque posting nomme son compte."
        case .montantInvalide:
            "Montant invalide : des centimes entiers positifs — jamais arrondis en silence."
        case let .deviseInvalide(code):
            "Devise illisible : « \(code) »."
        case let .desequilibre(devise, ecart):
            "Écriture déséquilibrée : \(ecart > 0 ? "+" : "")\(ecart) centime(s) \(devise)."
        }
    }
}

/// W3.1 — le BROUILLON d'un posting, validé AVANT toute création de
/// modèle : rien n'entre dans le contexte tant que l'écriture entière
/// n'est pas équilibrée.
struct JournalPostingDraft {
    let accountKey: String
    let isDebit: Bool
    let amount: Money
    let categoryID: UUID?

    init(accountKey: String, isDebit: Bool, amount: Money, categoryID: UUID? = nil) {
        self.accountKey = accountKey
        self.isDebit = isDebit
        self.amount = amount
        self.categoryID = categoryID
    }
}

/// W3.1 — une JAMBE d'écriture : un compte (réel `compte:<uuid>` ou
/// analytique `depense:<catégorie>`), un sens, des centimes entiers,
/// une devise.
@Model
final class JournalPosting {
    @Attribute(.unique) var id: UUID
    var accountKey: String
    var isDebit: Bool
    var minorUnits: Int64
    var currency: String
    var categoryID: UUID?
    var entry: JournalEntry?

    var money: Money { Money(minorUnits: minorUnits, currency: currency) }

    init(
        id: UUID = UUID(),
        accountKey: String,
        isDebit: Bool,
        minorUnits: Int64,
        currency: String,
        categoryID: UUID? = nil
    ) {
        self.id = id
        self.accountKey = accountKey
        self.isDebit = isDebit
        self.minorUnits = minorUnits
        self.currency = currency
        self.categoryID = categoryID
    }
}

/// W3.1 (Budget Autonomie 100, ADR-063) — une ÉCRITURE du journal :
/// un fait d'argent composé de postings équilibrés PAR DEVISE (FI-08).
/// Porte d'entrée UNIQUE : `JournalEntry.equilibree(...)` — personne ne
/// compose une écriture à la main. SHADOW : aucune vue ni aucun service
/// de calcul ne lit encore ce modèle (ADR-058) ; l'ombre des mutations
/// arrive en W3.3.
@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var lifecycleRawValue: String
    var effectiveDate: Date
    var title: String
    /// Unique dans son scope : réessayer la même écriture ne la
    /// duplique jamais (FI-31 en germe, contrat W3.3).
    @Attribute(.unique) var idempotencyKey: String
    /// Échéance (W2) que cette écriture confirme, si elle en vient.
    var occurrenceID: UUID?
    /// Correction par INVERSION : cette écriture annule une autre (W3.5).
    var reversesEntryID: UUID?
    /// Correction par REMPLACEMENT : cette écriture remplace une autre (W3.5).
    var replacesEntryID: UUID?
    @Relationship(deleteRule: .cascade, inverse: \JournalPosting.entry)
    var postings: [JournalPosting]
    var createdAt: Date
    var updatedAt: Date

    var kind: JournalEntryKind {
        get { JournalEntryKind(rawValue: kindRawValue) ?? .adjustment }
        set { kindRawValue = newValue.rawValue }
    }

    var lifecycle: JournalLifecycle {
        get { JournalLifecycle(rawValue: lifecycleRawValue) ?? .pending }
        set { lifecycleRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: JournalEntryKind,
        lifecycle: JournalLifecycle,
        effectiveDate: Date,
        title: String,
        idempotencyKey: String,
        occurrenceID: UUID? = nil,
        reversesEntryID: UUID? = nil,
        replacesEntryID: UUID? = nil,
        postings: [JournalPosting] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.lifecycleRawValue = lifecycle.rawValue
        self.effectiveDate = effectiveDate
        self.title = title
        self.idempotencyKey = idempotencyKey
        self.occurrenceID = occurrenceID
        self.reversesEntryID = reversesEntryID
        self.replacesEntryID = replacesEntryID
        self.postings = postings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// LA porte d'entrée du journal : valide chaque jambe puis
    /// l'équilibre PAR DEVISE avant de composer le moindre modèle.
    /// Un refus sort AVANT toute création — rien à nettoyer (FI-31).
    static func equilibree(
        kind: JournalEntryKind,
        lifecycle: JournalLifecycle = .posted,
        effectiveDate: Date,
        title: String,
        idempotencyKey: String,
        postings drafts: [JournalPostingDraft],
        occurrenceID: UUID? = nil,
        reversesEntryID: UUID? = nil,
        replacesEntryID: UUID? = nil,
        now: Date
    ) throws -> JournalEntry {
        guard drafts.count >= 2 else { throw JournalEntryError.postingsInsuffisants }
        for draft in drafts {
            guard !draft.accountKey.isEmpty else { throw JournalEntryError.compteManquant }
            guard draft.amount.minorUnits > 0 else { throw JournalEntryError.montantInvalide }
            guard Money.isValidCurrencyCode(draft.amount.currency) else {
                throw JournalEntryError.deviseInvalide(draft.amount.currency)
            }
        }
        var soldes: [String: Int64] = [:]
        for draft in drafts {
            let delta = draft.isDebit ? draft.amount.minorUnits : -draft.amount.minorUnits
            soldes[draft.amount.currency, default: 0] += delta
        }
        // Tri déterministe : le PREMIER écart alphabétique est nommé.
        if let ecart = soldes.sorted(by: { $0.key < $1.key }).first(where: { $0.value != 0 }) {
            throw JournalEntryError.desequilibre(devise: ecart.key, ecartMineur: ecart.value)
        }
        return JournalEntry(
            kind: kind,
            lifecycle: lifecycle,
            effectiveDate: effectiveDate,
            title: title,
            idempotencyKey: idempotencyKey,
            occurrenceID: occurrenceID,
            reversesEntryID: reversesEntryID,
            replacesEntryID: replacesEntryID,
            postings: drafts.map { JournalPosting(
                accountKey: $0.accountKey,
                isDebit: $0.isDebit,
                minorUnits: $0.amount.minorUnits,
                currency: $0.amount.currency,
                categoryID: $0.categoryID
            ) },
            createdAt: now,
            updatedAt: now
        )
    }
}
