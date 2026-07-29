import Foundation
import SwiftData

extension ModelContext {
    /// Throwing variant for domain services. It preserves the original
    /// typed error while guaranteeing that no pending mutation can leak
    /// into a later, unrelated save.
    func saveOrRollback() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }

    /// Saves the pending changes; on failure, ROLLS BACK and reports a
    /// user-facing French message. User mutations must never fail
    /// silently (production-completion contract) — the caller binds the
    /// message to an alert or inline banner. Logs stay amount-free.
    @discardableResult
    func saveOrRollback(onError: (String) -> Void) -> Bool {
        do {
            try saveOrRollback()
            return true
        } catch {
            onError("L'opération n'a pas pu être enregistrée. Réessayez.")
            return false
        }
    }
}
