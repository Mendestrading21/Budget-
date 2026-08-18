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

    /// Annonce ÉPHÉMÈRE de progrès d'objectif (« ☔️ Fonds d'urgence :
    /// 68 % → 71 % »), posée par un enregistrement réussi et affichée par
    /// la coquille (`MainTabView`) le temps d'une lecture. Vit ici — et pas
    /// dans un routeur — parce que l'écriture peut partir de n'importe
    /// quelle feuille et que la coquille est le seul endroit qui survit à
    /// leur fermeture.
    var goalProgressMessage: String?

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

    // FE2 (décision propriétaire, 18.08.2026) : la comptabilisation
    // automatique par date est SUPPRIMÉE. Une échéance arrivée devient
    // « à confirmer » — jamais comptabilisée sans geste.

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
