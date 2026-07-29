import Foundation
import SwiftData
import Observation

/// Composition root: owns the model container, the injectable environment
/// (calendar, locale, current date) and the domain services.
@Observable
final class AppContainer {
    private(set) var modelContainer: ModelContainer

    let calendar: Calendar
    let dateProvider: DateProviding
    let balanceService: AccountBalanceService
    let documentFileStore: DocumentFileStoring
    let lockManager: AppLockManager

    /// Demo mode runs the whole app on an isolated in-memory store filled
    /// with fictional data. It never touches the production store.
    var isDemoMode: Bool {
        didSet {
            guard oldValue != isDemoMode, !isRevertingDemoToggle else { return }
            rebuildContainer()
        }
    }

    private var isRevertingDemoToggle = false

    /// `inMemory` keeps previews and tests away from the production store
    /// and from the real file system.
    init(dateProvider: DateProviding = SystemDateProvider(), inMemory: Bool = false) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = FinanceFormatting.locale
        self.calendar = calendar
        self.dateProvider = dateProvider
        self.balanceService = AccountBalanceService()
        self.documentFileStore = inMemory ? InMemoryDocumentFileStore() : LocalDocumentFileStore()
        self.lockManager = AppLockManager(
            authService: inMemory ? FakeAuthenticationService() : BiometricAuthenticationService()
        )
        self.isDemoMode = false
        self.modelContainer = inMemory
            ? try PersistenceFactory.makeInMemoryContainer()
            : try PersistenceFactory.makeProductionContainer()
    }

    /// Applies the canonical day-based posting rule when the app starts or
    /// returns to the foreground. A failed save is rolled back and retried
    /// on the next activation; existing balances are never partially changed.
    @MainActor
    @discardableResult
    func postDuePlannedTransactions() -> Bool {
        let context = modelContainer.mainContext
        do {
            let transactions = try context.fetch(FetchDescriptor<BudgetTransaction>())
            let promoted = TransactionPostingPolicy(calendar: calendar)
                .promoteDueTransactions(transactions, now: dateProvider.now)
            guard promoted > 0 else { return true }
            try context.saveOrRollback()
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    private func rebuildContainer() {
        do {
            if isDemoMode {
                let container = try PersistenceFactory.makeInMemoryContainer()
                DemoDataFactory.populate(container: container, now: dateProvider.now, calendar: calendar)
                modelContainer = container
            } else {
                modelContainer = try PersistenceFactory.makeProductionContainer()
            }
        } catch {
            // Keep the UI flag consistent with the store actually in use:
            // revert the toggle without triggering another rebuild.
            assertionFailure("Container rebuild failed: \(error)")
            isRevertingDemoToggle = true
            isDemoMode.toggle()
            isRevertingDemoToggle = false
        }
    }
}
