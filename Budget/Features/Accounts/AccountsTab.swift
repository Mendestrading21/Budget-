import SwiftUI
import SwiftData

/// Comptes tab: account list grouped by nature, with totals and creation.
struct AccountsTab: View {
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var transactions: [BudgetTransaction]
    // FE2-4 : la carte « Ma fortune » lit la MÊME décomposition que le
    // Patrimoine (NetWorthService, source unique) — jamais un recalcul local.
    @Query private var assets: [Asset]
    @Query private var pensions: [PensionAsset]
    @Query private var liabilities: [Liability]

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

    private var netWorthService: NetWorthService {
        NetWorthService(calendar: appContainer.calendar, balanceService: appContainer.balanceService)
    }

    /// FE2-4 : « Mis de côté » — un FLUX : la somme des mises de côté et
    /// investissements COMPTABILISÉS dont la date tombe dans l'intervalle.
    /// Le prévu n'y entre jamais (une projection n'est pas de l'argent
    /// possédé), et ce flux ne s'additionne jamais au stock d'épargne.
    static func setAsideFlows(_ transactions: [BudgetTransaction], from start: Date, to end: Date) -> Decimal {
        transactions
            .filter {
                $0.status == .posted
                    && [.saving, .investment].contains($0.type)
                    && $0.date >= start && $0.date < end
            }
            .reduce(.zero) { $0 + $1.amount }
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
                        // FE2-4 : mêmes mots que la PWA — ce chiffre dit
                        // l'argent possédé MAINTENANT, jamais une projection.
                        Text("Disponible maintenant")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        AmountText(amount: totalIncludedInCash, role: .hero)
                        Text("Sur vos comptes utilisables au quotidien (tout en CHF).")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Disponible maintenant : \(FinanceFormatting.chf(totalIncludedInCash))")
                    .accessibilityIdentifier("accounts.hero.disponible")
                }

                fortuneCard
                epargneCard

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
        .obsidianFABClearance()
    }

    // MARK: - FE2-4 : les vues d'argent

    /// « Ma fortune » : trois chiffres classés, chacun dit UNE chose.
    /// La fortune totale vient de NetWorthService — la même décomposition
    /// que l'écran Patrimoine, chaque franc compté une seule fois.
    private var fortuneCard: some View {
        let epargneAccessible = netWorthService.accessibleSavings(accounts: accounts)
        let fortuneLiquide = netWorthService.liquidWealth(accounts: accounts)
        let fortuneTotale = netWorthService.breakdown(
            accounts: accounts,
            assets: assets,
            pensions: pensions,
            liabilities: liabilities
        ).netWorth
        return GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Ma fortune")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                VStack(spacing: BudgetSpacing.micro) {
                    fortuneRow("Épargne accessible", epargneAccessible)
                    fortuneRow("Fortune liquide", fortuneLiquide)
                    fortuneRow("Fortune totale", fortuneTotale)
                }
                Text("Liquide = quotidien + épargne. Totale = comptes, biens et prévoyance, moins vos dettes. Le détail vit dans Patrimoine.")
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Ma fortune — épargne accessible \(FinanceFormatting.chf(epargneAccessible)), fortune liquide \(FinanceFormatting.chf(fortuneLiquide)), fortune totale \(FinanceFormatting.chf(fortuneTotale))")
            .accessibilityIdentifier("accounts.fortune.card")
        }
    }

    /// « Épargne » : le stock d'un côté, les flux de l'autre — jamais
    /// additionnés (règle d'or du Moteur V2).
    private var epargneCard: some View {
        let now = appContainer.dateProvider.now
        let interval = MonthInterval(containing: now, calendar: appContainer.calendar)
        let yearInterval = appContainer.calendar.dateInterval(of: .year, for: now)
        let misCoteMois = Self.setAsideFlows(transactions, from: interval.start, to: interval.end)
        let misCoteAnnee = Self.setAsideFlows(
            transactions,
            from: yearInterval?.start ?? interval.start,
            to: yearInterval?.end ?? interval.end
        )
        let epargneActuelle = netWorthService.accessibleSavings(accounts: accounts)
        return GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Épargne")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                VStack(spacing: BudgetSpacing.micro) {
                    fortuneRow("Épargne actuelle", epargneActuelle)
                    fortuneRow("Mis de côté ce mois", misCoteMois)
                    fortuneRow("Mis de côté cette année", misCoteAnnee)
                }
                Text("L'épargne actuelle est un stock ; les mises de côté sont des flux. Ils ne s'additionnent jamais.")
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Épargne — actuelle \(FinanceFormatting.chf(epargneActuelle)), mis de côté ce mois \(FinanceFormatting.chf(misCoteMois)), cette année \(FinanceFormatting.chf(misCoteAnnee))")
            .accessibilityIdentifier("accounts.epargne.card")
        }
    }

    private func fortuneRow(_ label: String, _ amount: Decimal) -> some View {
        HStack {
            Text(label)
                .font(BudgetFont.body)
                .foregroundStyle(.secondary)
            Spacer()
            Text(FinanceFormatting.chf(amount))
                .font(BudgetFont.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(amount < 0 ? BudgetColor.negative : .primary)
        }
        .accessibilityElement(children: .combine)
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
                        Text("Mis de côté cette année : \(FinanceFormatting.chf(contribution.currentYear)) · en tout : \(FinanceFormatting.chf(contribution.total))")
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
