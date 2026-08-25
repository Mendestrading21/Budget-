import Foundation
import SwiftData

/// W4.2b (Budget Autonomie 100, ADR-065 — « V1 base unique ») : un taux
/// de change n'est plus un nombre nu — chaque taux est une QUOTE datée
/// et sourcée (FI-16). 1 `base` vaut `rate` `quote` (ex. 1 EUR =
/// 0.95 CHF), observée à `observedAt`, provenance `source`. Additif
/// (schéma V13) : aucun taux existant n'est réécrit — une nouvelle
/// observation S'AJOUTE.
@Model
final class FxQuote {
    @Attribute(.unique) var id: UUID
    /// Devise cotée (celle que l'on convertit) — ex. « EUR ».
    var base: String
    /// Devise d'arrivée — ex. « CHF ».
    var quote: String
    var rate: Decimal
    var observedAt: Date
    var source: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        base: String,
        quote: String,
        rate: Decimal,
        observedAt: Date,
        source: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.base = base
        self.quote = quote
        self.rate = rate
        self.observedAt = observedAt
        self.source = source
        self.createdAt = createdAt
    }
}

/// W4.2b — la conversion V1 : paire EXACTE, dernière quote observée au
/// plus tard à la date demandée. Aucune quote = nil — un taux absent ne
/// devient JAMAIS 1 ni 0 (FI-17), et la paire inverse n'est jamais
/// inférée (une inférence serait un taux inventé).
struct CurrencyConversionService {
    func convert(
        _ amount: Decimal,
        from: String,
        to: String,
        quotes: [FxQuote],
        on date: Date
    ) -> Decimal? {
        if from == to { return amount }
        let candidates = quotes.filter {
            $0.base == from && $0.quote == to && $0.observedAt <= date && $0.rate > 0
        }
        guard let derniere = candidates.max(by: { $0.observedAt < $1.observedAt }) else {
            return nil
        }
        return amount * derniere.rate
    }
}
