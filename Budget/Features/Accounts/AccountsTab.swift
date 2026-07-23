import SwiftUI
import SwiftData

/// Comptes tab: account list grouped by nature, with totals and creation.
struct AccountsTab: View {
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var transactions: [BudgetTransaction]

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
                        Text("Argent disponible")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        AmountText(amount: totalIncludedInCash, role: .hero)
                        Text("Somme des comptes marqués « compte dans le cash disponible » (tout en CHF)")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Argent disponible : \(FinanceFormatting.chf(totalIncludedInCash))")
                }

                ForEach(groups, id: \.title) { group in
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text(group.title)
                            .font(BudgetFont.sectionTitle)
                            .foregroundStyle(.secondary)
                        ForEach(group.accounts) { account in
                            NavigationLink(value: account) {
                                AccountRow(
                                    account: account,
                                    balance: balance(of: account),
                                    contribution: contributionSummary(of: account)
                                )
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

    /// Cumuls façon Finary sur les comptes de placement uniquement.
    private func contributionSummary(of account: Account) -> ContributionSummary? {
        guard ContributionService.tracksContributions(account.type) else { return nil }
        return ContributionService(calendar: appContainer.calendar)
            .summary(of: account, movements: transactions, now: appContainer.dateProvider.now)
    }

    private var emptyState: some View {
        VStack(spacing: BudgetSpacing.medium) {
            GlassCard {
                EmptyState(
                    symbol: "creditcard",
                    title: "Aucun compte",
                    message: "Ajoutez vos comptes bancaires, espèces, épargne ou prévoyance pour suivre vos soldes.",
                    actionTitle: "Ajouter un compte",
                    action: { isPresentingNewAccount = true }
                )
            }
        }
        .padding(BudgetSpacing.screenMargin)
    }
}

struct AccountRow: View {
    let account: Account
    let balance: Decimal
    var contribution: ContributionSummary? = nil

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: account.type.systemImage)
                    .font(.title3)
                    .foregroundStyle(BudgetColor.brand)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BudgetSpacing.micro) {
                        Text(account.name)
                            .font(BudgetFont.body.weight(.medium))
                            .lineLimit(1)
                        // L5 : les statuts sont ÉCRITS — jamais la seule
                        // couleur ni la seule opacité.
                        if !account.isActive {
                            StatusPill(text: "Archivé", kind: .neutral)
                        } else if account.type.isLiability {
                            StatusPill(text: "Dette", kind: .neutral)
                        }
                    }
                    Text(account.institutionName.isEmpty ? account.type.displayName : account.institutionName)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                    if let contribution, contribution.total > 0 {
                        Text("Versé cette année : \(FinanceFormatting.chf(contribution.currentYear)) · total : \(FinanceFormatting.chf(contribution.total))")
                            .font(BudgetFont.caption)
                            .foregroundStyle(BudgetColor.brandBright)
                    }
                }
                Spacer(minLength: BudgetSpacing.small)
                Text(FinanceFormatting.chf(balance))
                    .font(BudgetFont.amount)
                    .foregroundStyle(balance < 0 ? BudgetColor.negative : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), \(account.type.displayName)\(account.isActive ? "" : ", archivé"), solde \(FinanceFormatting.chf(balance))")
    }
}

#Preview("Comptes") {
    let preview = DemoDataFactory.previewAppContainer()
    return AccountsTab()
        .environment(preview)
        .environment(AppRouter())
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
