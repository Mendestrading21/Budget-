import Foundation
import SwiftData

extension ModelContext {
    /// Saves the pending changes; on failure, ROLLS BACK and reports a
    /// user-facing French message. User mutations must never fail
    /// silently (production-completion contract) — the caller binds the
    /// message to an alert or inline banner. Logs stay amount-free.
    func saveOrRollback(onError: (String) -> Void) {
        do {
            try save()
        } catch {
            rollback()
            onError("L'opération n'a pas pu être enregistrée. Réessayez.")
        }
    }
}
