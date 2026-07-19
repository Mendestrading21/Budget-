import SwiftUI
import SwiftData

@main
struct BudgetApp: App {
    @State private var appContainer: AppContainer?
    @State private var startupError: Error?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if let appContainer {
                ZStack {
                    RootView()
                        .environment(appContainer)
                        .modelContainer(appContainer.modelContainer)
                        // Rebuild the view hierarchy when switching between
                        // the real store and the isolated demo store.
                        .id(appContainer.isDemoMode)
                    if appContainer.lockManager.isLocked {
                        LockScreenView(lockManager: appContainer.lockManager)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        appContainer.lockManager.lockIfEnabled()
                    }
                }
            } else if let startupError {
                StartupErrorView(error: startupError)
            } else {
                Color.clear
                    .task {
                        do {
                            appContainer = try AppContainer()
                        } catch {
                            startupError = error
                        }
                    }
            }
        }
    }
}

/// Shown only if the local store cannot be opened at all. Data is never
/// deleted automatically; the user keeps control.
struct StartupErrorView: View {
    let error: Error

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            VStack(spacing: BudgetSpacing.medium) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(BudgetColor.warning)
                Text("Impossible d'ouvrir vos données")
                    .font(BudgetFont.sectionTitle)
                    .foregroundStyle(.primary)
                Text("Vos données locales n'ont pas pu être chargées. Redémarrez l'app ; si le problème persiste, contactez le support avant toute réinstallation afin de ne rien perdre.")
                    .font(BudgetFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(BudgetSpacing.extraLarge)
        }
    }
}
