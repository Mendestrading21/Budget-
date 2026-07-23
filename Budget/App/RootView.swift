import SwiftUI
import SwiftData

/// Routes between onboarding (no household yet) and the main experience.
/// L'identité sombre Obsidian est établie à la racine (BudgetApp) —
/// aucun écran ne gère l'apparence individuellement.
struct RootView: View {
    @Query private var households: [Household]
    @State private var router = AppRouter()

    var body: some View {
        Group {
            if ProcessInfo.processInfo.arguments.contains("-obsidianGallery") {
                // Galerie interne du design system (preuves L2) : jamais
                // atteignable sans cet argument de lancement — l'expérience
                // Release est inchangée.
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

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppContainer.self) private var appContainer

    /// Universal ＋ menu: the chosen type opens a prefilled movement form
    /// from anywhere in the app (web-parity, production-completion P2).
    @State private var quickCreateType: TransactionType?

    var body: some View {
        @Bindable var router = router
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
        .safeAreaInset(edge: .top, spacing: 0) {
            if appContainer.isDemoMode {
                DemoModeBanner()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            quickCreateButton
        }
        .sheet(item: $quickCreateType) { type in
            TransactionFormView(mode: .create(prefilledAccount: nil), prefilledType: type)
        }
    }

    /// Floating creation menu, always reachable above the tab bar.
    private var quickCreateButton: some View {
        Menu {
            Button {
                quickCreateType = .expense
            } label: {
                Label("Dépense", systemImage: "arrow.up.circle")
            }
            Button {
                quickCreateType = .income
            } label: {
                Label("Revenu", systemImage: "arrow.down.circle")
            }
            Button {
                quickCreateType = .saving
            } label: {
                Label("Épargne", systemImage: "building.columns")
            }
            Button {
                quickCreateType = .investment
            } label: {
                Label("Investissement", systemImage: "chart.line.uptrend.xyaxis")
            }
            Button {
                quickCreateType = .transfer
            } label: {
                Label("Virement interne", systemImage: "arrow.left.arrow.right")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(
                        colors: [BudgetColor.indigo, BudgetColor.violet],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(color: BudgetColor.indigo.opacity(0.45), radius: 10, y: 4)
        }
        .accessibilityLabel("Ajouter — dépense, revenu, épargne, investissement ou virement")
        .padding(.trailing, BudgetSpacing.screenMargin)
        .padding(.bottom, 62)
    }
}

/// "Mouvements" promoted to the tab bar (web-parity): the reusable list
/// wrapped in its own navigation stack.
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
