import SwiftUI
import SwiftData

/// Comptes tab: account list grouped by nature, with totals and creation.
struct AccountsTab: View {
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    @State private var isPresentingNewAccount = false
    @State private var showsArchived = false

    private var activeAccounts: [Account] { accounts.filter(\.isActive) }
    private var archivedAccounts: [Account] { accounts.filter { !$0.isActive } }

    private var groups: [(title: String, accounts: [Account])] {
        let liquid = activeAccounts.filter { [.current, .cash].contains($0.type) }
        let savings = activeAccounts.filter { [.savings, .broker].contains($0.type) }
        let pension = activeAccounts.filter { [.pillar3a, .pillar3b, .occupationalPension].contains($0.type) }
        let debts = activeAccounts.filter { $0.type.isLiability }
        let others = activeAccounts.filter { $0.type == .other }
        return [
            ("Liquidités", liquid),
            ("Épargne et placements", savings),
            ("Prévoyance", pension),
            ("Dettes", debts),
            ("Autres", others),
        ].filter { !$0.1.isEmpty }
    }

    private func balance(of account: Account) -> Decimal {
        appContainer.balanceService.balance(of: account)
    }

    private var totalIncludedInCash: Decimal {
        activeAccounts
            .filter(\.includeInAvailableCash)
            .reduce(.zero) { $0 + balance(of: $1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BudgetScreenBackground()
                if activeAccounts.isEmpty && archivedAccounts.isEmpty {
                    emptyState
                } else {
                    accountsList
                }
            }
            .navigationTitle("Comptes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNewAccount = true
                    } label: {
                        Label("Ajouter un compte", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewAccount) {
                AccountFormView(mode: .create)
            }
            .navigationDestination(for: Account.self) { account in
                AccountDetailView(account: account)
            }
        }
    }

    private var accountsList: some View {
        ScrollView {
            VStack(spacing: BudgetSpacing.medium) {
                GlassCard(style: .hero) {
                    VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                        Text("Liquidités disponibles")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        Text(FinanceFormatting.chf(totalIncludedInCash))
                            .font(BudgetFont.heroAmount)
                        Text("Somme des comptes marqués « compte dans le cash disponible »")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Liquidités disponibles : \(FinanceFormatting.chf(totalIncludedInCash))")
                }

                ForEach(groups, id: \.title) { group in
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text(group.title)
                            .font(BudgetFont.sectionTitle)
                            .foregroundStyle(.secondary)
                        ForEach(group.accounts) { account in
                            NavigationLink(value: account) {
                                AccountRow(account: account, balance: balance(of: account))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !archivedAccounts.isEmpty {
                    DisclosureGroup(isExpanded: $showsArchived) {
                        ForEach(archivedAccounts) { account in
                            NavigationLink(value: account) {
                                AccountRow(account: account, balance: balance(of: account))
                                    .opacity(0.6)
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        Text("Comptes archivés (\(archivedAccounts.count))")
                            .font(BudgetFont.sectionTitle)
                            .foregroundStyle(.secondary)
                    }
                    .tint(BudgetColor.coolGray)
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
    }

    private var emptyState: some View {
        VStack(spacing: BudgetSpacing.medium) {
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Label("Aucun compte", systemImage: "creditcard")
                        .font(BudgetFont.sectionTitle)
                    Text("Ajoutez vos comptes bancaires, espèces, épargne ou prévoyance pour suivre vos soldes.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                    Button("Ajouter un compte") {
                        isPresentingNewAccount = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BudgetColor.indigo)
                }
            }
        }
        .padding(BudgetSpacing.screenMargin)
    }
}

struct AccountRow: View {
    let account: Account
    let balance: Decimal

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: account.type.systemImage)
                    .font(.title3)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(BudgetFont.body.weight(.medium))
                    Text(account.institutionName.isEmpty ? account.type.displayName : account.institutionName)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: BudgetSpacing.small)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(FinanceFormatting.chf(balance))
                        .font(BudgetFont.amount)
                        .foregroundStyle(balance < 0 ? BudgetColor.negative : .primary)
                    if account.type.isLiability {
                        Text("Dette")
                            .font(BudgetFont.caption)
                            .foregroundStyle(BudgetColor.warning)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), \(account.type.displayName), solde \(FinanceFormatting.chf(balance))")
    }
}

#Preview("Comptes") {
    AccountsTab()
        .environment(try! AppContainer(inMemory: true))
        .environment(AppRouter())
        .modelContainer(DemoDataFactory.previewContainer())
        .preferredColorScheme(.dark)
}
