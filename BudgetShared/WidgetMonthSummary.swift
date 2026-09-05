import Foundation

/// PFOS-P7 : l'instantané que l'app écrit pour son widget. Un MIROIR en
/// lecture seule du mois courant — jamais une donnée maîtresse : le
/// widget ne calcule rien, il affiche ce que l'app a réellement calculé
/// au dernier passage, avec l'heure de cet instantané écrite en clair.
/// Les montants voyagent en CENTIMES ENTIERS (jamais un Double) ; la
/// devise est celle du ménage. `schemaVersion` protège les relectures :
/// une version inconnue est refusée, jamais devinée.
struct WidgetMonthSummary: Codable, Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    /// Ex. « Septembre 2026 » — déjà formaté par l'app (fr-CH).
    let monthLabel: String
    /// L'instant où l'app a calculé cet instantané — affiché sur le
    /// widget pour dire honnêtement de quand datent les chiffres.
    let generatedAt: Date
    let currencyCode: String
    let availableCents: Int
    let incomeCents: Int
    let livingExpensesCents: Int
    let setAsideCents: Int

    /// Décimal → centimes entiers, arrondi au plus proche (demi vers
    /// l'extérieur, comme l'arrondi comptable de l'app).
    static func cents(_ amount: Decimal) -> Int {
        let behavior = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        return NSDecimalNumber(decimal: amount)
            .multiplying(byPowerOf10: 2)
            .rounding(accordingToBehavior: behavior)
            .intValue
    }

    static func amount(fromCents cents: Int) -> Decimal {
        Decimal(cents) / 100
    }
}
