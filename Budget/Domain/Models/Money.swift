import Foundation

/// W3.1 (Budget Autonomie 100, ADR-063) — un montant du journal : des
/// CENTIMES ENTIERS + une devise (même représentation que les fixtures
/// canoniques, ADR-059). Le natif continue de CALCULER en `Decimal`
/// (invariant produit) et convertit aux frontières avec un arrondi
/// DÉTERMINISTE (FI-18). Un montant non représentable est un REFUS —
/// jamais un zéro silencieux (FI-34).
struct Money: Codable, Equatable, Hashable {
    /// Centimes entiers (unités mineures, échelle 2 pour les devises V1 :
    /// CHF, EUR, USD). 4 350.00 CHF = 435 000.
    let minorUnits: Int64
    let currency: String

    init(minorUnits: Int64, currency: String) {
        self.minorUnits = minorUnits
        self.currency = currency
    }

    /// Frontière `Decimal` → centimes : arrondi déterministe `.plain`
    /// à 2 décimales, puis conversion EXACTE — une valeur illisible
    /// (NaN) ou hors bornes retourne nil, jamais zéro.
    init?(amount: Decimal, currency: String) {
        guard !amount.isNaN, Money.isValidCurrencyCode(currency) else { return nil }
        var source = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, 2, .plain)
        let cents = rounded * Decimal(100)
        let converted = NSDecimalNumber(decimal: cents).int64Value
        // La conversion doit être EXACTE : si l'aller-retour diverge
        // (dépassement d'Int64), on refuse plutôt que de tronquer.
        guard Decimal(converted) == cents else { return nil }
        self.minorUnits = converted
        self.currency = currency
    }

    /// Valeur de CALCUL : `Decimal` exact (jamais un flottant binaire).
    var decimalValue: Decimal {
        Decimal(minorUnits) / Decimal(100)
    }

    /// Une devise du journal est un code ISO à trois lettres majuscules.
    static func isValidCurrencyCode(_ code: String) -> Bool {
        code.count == 3 && code.allSatisfy { $0.isUppercase && $0.isLetter && $0.isASCII }
    }
}
