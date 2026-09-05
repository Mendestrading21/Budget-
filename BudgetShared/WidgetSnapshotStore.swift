import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// PFOS-P7 : le pont app ↔ widget. Un seul fichier JSON dans le conteneur
/// du groupe d'apps (`group.ch.budgetapp.Budget`). Si le groupe n'est pas
/// provisionné (profil sans la capacité App Groups), TOUT est silencieux
/// et honnête : l'app n'écrit rien, le widget dit qu'il attend l'app —
/// jamais un chiffre inventé, jamais un échec bloquant.
enum WidgetSnapshotStore {
    static let appGroupID = "group.ch.budgetapp.Budget"
    static let fileName = "widget-month-summary.json"

    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func encode(_ summary: WidgetMonthSummary) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(summary)
    }

    static func decode(_ data: Data) -> WidgetMonthSummary? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let summary = try? decoder.decode(WidgetMonthSummary.self, from: data),
              summary.schemaVersion == WidgetMonthSummary.currentSchemaVersion else {
            return nil
        }
        return summary
    }

    /// Écrit l'instantané et demande au widget de se rafraîchir. Jamais
    /// bloquant : le widget est un miroir, pas une donnée maîtresse.
    static func save(_ summary: WidgetMonthSummary) {
        guard let url = fileURL, let data = encode(summary) else { return }
        do {
            try data.write(to: url, options: .atomic)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            // Un widget qui rate une mise à jour affichera l'instantané
            // précédent, daté — jamais une erreur dans l'app.
        }
    }

    static func load() -> WidgetMonthSummary? {
        guard let url = fileURL else { return nil }
        return load(from: url)
    }

    static func load(from url: URL) -> WidgetMonthSummary? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    /// « Tout supprimer » vaut AUSSI pour le miroir du widget : aucune
    /// donnée financière ne doit survivre dans le conteneur partagé.
    static func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
