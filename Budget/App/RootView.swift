import SwiftUI
import SwiftData

/// Routes between onboarding (no household yet) and the main experience.
struct RootView: View {
    @Query private var households: [Household]
    @State private var router = AppRouter()

    var body: some View {
        Group {
            if ProcessInfo.processInfo.arguments.contains("-obsidianGallery") {
                ObsidianComponentGallery()
            } else if households.isEmpty {
                OnboardingFlowView()
            } else {
                MainTabView()
                    .environment(router)
            }
        }
    }
}

/// Navigation principale : cinq destinations stables, sans bouton flottant
/// concurrent. Chaque écran porte uniquement son action utile (ajouter un
/// mouvement, une facture, un compte, etc.).
struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppContainer.self) private var appContainer

    var body: some View {
        @Bindable var router = router
        VStack(spacing: 0) {
            if appContainer.isDemoMode {
                DemoModeBanner()
            }
            TabView(selection: $router.selectedTab) {
                HomeTab()
                    .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }
                    .tag(AppTab.home)

                TransactionsTab()
                    .tabItem { Label(AppTab.transactions.title, systemImage: AppTab.transactions.systemImage) }
                    .tag(AppTab.transactions)

                BudgetTab()
                    .tabItem { Label(AppTab.budget.title, systemImage: AppTab.budget.systemImage) }
                    .tag(AppTab.budget)

                AccountsTab()
                    .tabItem { Label(AppTab.accounts.title, systemImage: AppTab.accounts.systemImage) }
                    .tag(AppTab.accounts)

                MoreTab()
                    .tabItem { Label(AppTab.more.title, systemImage: AppTab.more.systemImage) }
                    .tag(AppTab.more)
            }
            .tint(BudgetColor.indigo)
        }
    }
}

/// "Mouvements" promoted to the tab bar: the reusable list wrapped in its
/// own navigation stack.
struct TransactionsTab: View {
    var body: some View {
        NavigationStack {
            TransactionsListView()
        }
    }
}

/// Visible reminder that the app is running on fictional demo data.
struct DemoModeBanner: View {
    @Environment(AppContainer.self) private var appContainer

    var body: some View {
        HStack(spacing: BudgetSpacing.small) {
            Image(systemName: "sparkles")
            Text("Mode démonstration — données fictives")
                .font(BudgetFont.caption)
            Spacer()
            Button("Quitter") {
                appContainer.isDemoMode = false
            }
            .font(BudgetFont.caption.weight(.semibold))
        }
        .padding(.horizontal, BudgetSpacing.medium)
        .padding(.vertical, BudgetSpacing.small)
        .background(BudgetColor.indigo.opacity(0.9))
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mode démonstration actif, données fictives. Bouton Quitter pour revenir à vos données.")
    }
}
