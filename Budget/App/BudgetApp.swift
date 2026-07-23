import SwiftUI
import SwiftData

@main
struct BudgetApp: App {
    @State private var appContainer: AppContainer?
    @State private var startupError: Error?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            appContent
                // Obsidian Glass (ADR-020, L2) : identité sombre unique,
                // établie ICI au niveau racine — aucun écran ne la gère.
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var appContent: some View {
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
                } else if scenePhase != .active && appContainer.lockManager.isLockEnabled {
                    // The app-switcher snapshot is taken while the scene
                    // is inactive: cover the financial content so it
                    // never appears there.
                    PrivacyShieldView()
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
                        let container = try AppContainer()
                        // Tour automatisé (workflow Demo) : démarre
                        // directement en mode démo — store in-memory,
                        // jamais les vraies données.
                        if ProcessInfo.processInfo.arguments.contains("-demoTour") {
                            container.isDemoMode = true
                        }
                        appContainer = container
                    } catch {
                        startupError = error
                    }
                }
        }
    }
}

/// Opaque cover shown while the scene is inactive and the lock is
/// enabled, so no amount leaks into the app-switcher snapshot.
struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            BudgetScreenBackground()
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
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
