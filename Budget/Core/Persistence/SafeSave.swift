import Foundation
import SwiftData

/// Small injectable boundary around persistence writes. Keeping the save and
/// rollback operations as closures lets tests exercise the failure path without
/// depending on undocumented SwiftData constraint behaviour.
enum PersistenceSaveGuard {
    static func perform(
        save: () throws -> Void,
        rollback: () -> Void
    ) throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }

    @discardableResult
    static func perform(
        save: () throws -> Void,
        rollback: () -> Void,
        onError: (String) -> Void
    ) -> Bool {
        do {
            try perform(save: save, rollback: rollback)
            return true
        } catch {
            onError("L'opération n'a pas pu être enregistrée. Réessayez.")
            return false
        }
    }
}

extension ModelContext {
    /// Throwing variant for domain services. It preserves the original
    /// typed error while guaranteeing that no pending mutation can leak
    /// into a later, unrelated save.
    func saveOrRollback() throws {
        try PersistenceSaveGuard.perform(
            save: { try save() },
            rollback: { rollback() }
        )
    }

    /// Saves the pending changes; on failure, ROLLS BACK and reports a
    /// user-facing French message. User mutations must never fail
    /// silently (production-completion contract) — the caller binds the
    /// message to an alert or inline banner. Logs stay amount-free.
    @discardableResult
    func saveOrRollback(onError: (String) -> Void) -> Bool {
        PersistenceSaveGuard.perform(
            save: { try save() },
            rollback: { rollback() },
            onError: onError
        )
    }
}
