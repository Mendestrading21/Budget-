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

    /// Demo mode runs the whole app on an isolated in-memory store filled
    /// with fictional data. It never touches the production store.
    var isDemoMode: Bool {
        didSet {
            guard oldValue != isDemoMode, !isRevertingDemoToggle else { return }
            rebuildContainer()
        }
    }

    private var isRevertingDemoToggle = false

    /// `inMemory` keeps previews and tests away from the production store.
    init(dateProvider: DateProviding = SystemDateProvider(), inMemory: Bool = false) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = FinanceFormatting.locale
        self.calendar = calendar
        self.dateProvider = dateProvider
        self.balanceService = AccountBalanceService()
        self.isDemoMode = false
        self.modelContainer = inMemory
            ? try PersistenceFactory.makeInMemoryContainer()
            : try PersistenceFactory.makeProductionContainer()
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
