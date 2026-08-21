import Foundation

/// ID1 (ADR-042) : la clé d'identité optionnelle d'une ligne — une chaîne
/// kebab ASCII de 1 à 40 caractères, la MÊME règle que la PWA
/// (`sanitizeIdentityKey`) et que fixtures/identity-key-cases.json.
/// Tout le reste est RETIRÉ sans toucher la ligne : jamais de perte de
/// données, jamais de markup, jamais de chemin ni d'URL.
enum BudgetIdentityKey {
    /// ^[a-z0-9]+(?:-[a-z0-9]+)*$ — gardée en une seule source native.
    static let pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"

    static func sanitized(_ value: String?) -> String? {
        guard let value, (1...40).contains(value.count),
              value.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }
        return value
    }

    /// L'entrée du catalogue pour une clé stockée — nil pour une clé
    /// absente, inconnue ou retirée (le rendu retombe sur le monogramme
    /// du titre, sans erreur).
    static func catalogEntry(for value: String?) -> BudgetIdentityEntry? {
        guard let key = sanitized(value) else { return nil }
        return BudgetIdentityCatalog.all.first { $0.key == key }
    }
}
