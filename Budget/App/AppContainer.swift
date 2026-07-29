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

    /// Amount-free maintenance error surfaced by the app shell. Promotion
    /// is retried on the next activation and can also be retried manually.
    private(set) var duePostingErrorMessage: String?

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
        calendar.timeZone = .autoupdatingCurrent
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
    /// returns to the foreground. The main context keeps already-rendered
    /// `@Query` values coherent. Promotion starts only when that context is
    /// clean, so it can never commit or cancel an unrelated form edit.
    @MainActor
    func postDuePlannedTransactions() {
        let context = modelContainer.mainContext
        guard !context.hasChanges else {
            duePostingErrorMessage = "Une modification est encore en cours. Terminez-la, puis réessayez la mise à jour des échéances."
            return
        }
        do {
            let transactions = try context.fetch(FetchDescriptor<BudgetTransaction>())
            let promoted = TransactionPostingPolicy(calendar: calendar)
                .promoteDueTransactions(transactions, now: dateProvider.now)
            if promoted > 0 {
                try context.saveOrRollback()
            }
            duePostingErrorMessage = nil
        } catch {
            context.rollback()
            duePostingErrorMessage = "Certaines échéances arrivées à leur date n'ont pas pu être comptabilisées. Vos données restent intactes ; réessayez."
        }
    }

    @MainActor
    func dismissDuePostingError() {
        duePostingErrorMessage = nil
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
