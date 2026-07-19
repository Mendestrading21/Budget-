import SwiftUI
import SwiftData

/// Full movement list: month navigation, search, filters, uncategorized
/// queue, edit/duplicate/delete with confirmation.
struct TransactionsListView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BudgetTransaction.date, order: .reverse)
    private var allTransactions: [BudgetTransaction]
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    @State private var monthAnchor: Date?
    @State private var searchText = ""
    @State private var typeFilter: TransactionType?
    @State private var accountFilter: Account?
    @State private var statusFilter: TransactionStatus?
    @State private var showsUncategorizedOnly = false
    @State private var editedTransaction: BudgetTransaction?
    @State private var isPresentingNew = false
    @State private var transactionToDelete: BudgetTransaction?

    /// Anchor defaults to "now" lazily so the view stays deterministic in
    /// previews with an injected date provider.
    private var currentAnchor: Date { monthAnchor ?? appContainer.dateProvider.now }

    private var monthInterval: MonthInterval {
        MonthInterval(containing: currentAnchor, calendar: appContainer.calendar)
    }

    private var filteredTransactions: [BudgetTransaction] {
        allTransactions.filter { transaction in
            guard monthInterval.contains(transaction.date) else { return false }
            if let typeFilter, transaction.type != typeFilter { return false }
            if let accountFilter,
               transaction.account?.id != accountFilter.id
                && transaction.destinationAccount?.id != accountFilter.id {
                return false
            }
            if let statusFilter, transaction.status != statusFilter { return false }
            if showsUncategorizedOnly {
                let needsCategory = TransactionValidationService().categoryRequired(for: transaction.type)
                guard needsCategory && transaction.category == nil else { return false }
            }
            if !searchText.isEmpty {
                let haystack = "\(transaction.title) \(transaction.merchant ?? "") \(transaction.note ?? "")"
                guard haystack.localizedCaseInsensitiveContains(searchText) else { return false }
            }
            return true
        }
    }

    private var groupedByDay: [(day: Date, items: [BudgetTransaction])] {
        let groups = Dictionary(grouping: filteredTransactions) { transaction in
            appContainer.calendar.startOfDay(for: transaction.date)
        }
        return groups.keys.sorted(by: >).map { day in
            (day, groups[day] ?? [])
        }
    }

    private var uncategorizedCount: Int {
        let service = TransactionValidationService()
        return allTransactions.filter {
            monthInterval.contains($0.date) && service.categoryRequired(for: $0.type) && $0.category == nil
        }.count
    }

    private var hasActiveFilters: Bool {
        typeFilter != nil || accountFilter != nil || statusFilter != nil || showsUncategorizedOnly
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            VStack(spacing: 0) {
                monthSelector
                content
            }
        }
        .navigationTitle("Mouvements")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Rechercher un mouvement")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            TransactionFormView(mode: .create(prefilledAccount: accountFilter))
        }
        .sheet(item: $editedTransaction) { transaction in
            TransactionFormView(mode: .edit(transaction))
        }
        .confirmationDialog(
            "Supprimer ce mouvement ?",
            isPresented: Binding(
                get: { transactionToDelete != nil },
                set: { if !$0 { transactionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                if let transaction = transactionToDelete {
                    delete(transaction)
                }
                transactionToDelete = nil
            }
        } message: {
            if let transaction = transactionToDelete {
                Text("« \(transaction.title) » — \(FinanceFormatting.chf(transaction.amount)) sera définitivement supprimé.")
            }
        }
    }

    // MARK: - Month navigation

    private var monthSelector: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Mois précédent")

            Spacer()
            Text(FinanceFormatting.monthTitle(currentAnchor, calendar: appContainer.calendar).capitalized)
                .font(BudgetFont.sectionTitle)
            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Mois suivant")
        }
        .padding(.horizontal, BudgetSpacing.screenMargin)
        .padding(.vertical, BudgetSpacing.small)
    }

    private func shiftMonth(by value: Int) {
        monthAnchor = appContainer.calendar.date(byAdding: .month, value: value, to: currentAnchor) ?? currentAnchor
    }

    // MARK: - Filters

    private var filterMenu: some View {
        Menu {
            Picker("Type", selection: $typeFilter) {
                Text("Tous les types").tag(TransactionType?.none)
                ForEach(TransactionType.allCases) { type in
                    Text(type.displayName).tag(TransactionType?.some(type))
                }
            }
            Picker("Compte", selection: $accountFilter) {
                Text("Tous les comptes").tag(Account?.none)
                ForEach(accounts) { account in
                    Text(account.name).tag(Account?.some(account))
                }
            }
            Picker("Statut", selection: $statusFilter) {
                Text("Tous les statuts").tag(TransactionStatus?.none)
                ForEach(TransactionStatus.allCases) { status in
                    Text(status.displayName).tag(TransactionStatus?.some(status))
                }
            }
            Toggle("Non catégorisés uniquement", isOn: $showsUncategorizedOnly)
            if hasActiveFilters {
                Button("Réinitialiser les filtres", role: .destructive) {
                    typeFilter = nil
                    accountFilter = nil
                    statusFilter = nil
                    showsUncategorizedOnly = false
                }
            }
        } label: {
            Label("Filtres", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(hasActiveFilters ? "Filtres, actifs" : "Filtres")
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if filteredTransactions.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    if uncategorizedCount > 0 && !showsUncategorizedOnly {
                        uncategorizedBanner
                    }
                    ForEach(groupedByDay, id: \.day) { group in
                        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                            Text(FinanceFormatting.swissDate(group.day))
                                .font(BudgetFont.cardLabel)
                                .foregroundStyle(.secondary)
                            ForEach(group.items) { transaction in
                                TransactionRow(transaction: transaction)
                                    .onTapGesture { editedTransaction = transaction }
                                    .contextMenu {
                                        Button("Modifier", systemImage: "pencil") {
                                            editedTransaction = transaction
                                        }
                                        Button("Dupliquer", systemImage: "plus.square.on.square") {
                                            duplicate(transaction)
                                        }
                                        Button("Supprimer", systemImage: "trash", role: .destructive) {
                                            transactionToDelete = transaction
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            }
        }
    }

    private var uncategorizedBanner: some View {
        Button {
            showsUncategorizedOnly = true
        } label: {
            GlassCard(style: .row) {
                HStack {
                    Label("\(uncategorizedCount) mouvement(s) sans catégorie ce mois", systemImage: "questionmark.folder")
                        .font(BudgetFont.body)
                        .foregroundStyle(BudgetColor.warning)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Filtre la liste sur les mouvements sans catégorie.")
    }

    private var emptyState: some View {
        ScrollView {
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Label(
                        hasActiveFilters || !searchText.isEmpty ? "Aucun résultat" : "Aucun mouvement ce mois",
                        systemImage: "tray"
                    )
                    .font(BudgetFont.sectionTitle)
                    Text(
                        hasActiveFilters || !searchText.isEmpty
                            ? "Aucun mouvement ne correspond aux filtres actuels."
                            : "Ajoutez vos revenus, dépenses, épargne et virements pour suivre votre mois."
                    )
                    .font(BudgetFont.body)
                    .foregroundStyle(.secondary)
                    Button("Ajouter un mouvement") {
                        isPresentingNew = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BudgetColor.indigo)
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
    }

    // MARK: - Actions

    private func duplicate(_ transaction: BudgetTransaction) {
        let now = appContainer.dateProvider.now
        let copy = BudgetTransaction(
            date: transaction.date,
            amount: transaction.amount,
            type: transaction.type,
            status: transaction.status,
            title: transaction.title,
            note: transaction.note,
            merchant: transaction.merchant,
            adjustmentIncreasesBalance: transaction.adjustmentIncreasesBalance,
            createdAt: now,
            updatedAt: now,
            account: transaction.account,
            destinationAccount: transaction.destinationAccount,
            category: transaction.category,
            member: transaction.member
        )
        modelContext.insert(copy)
        try? modelContext.save()
        editedTransaction = copy
    }

    private func delete(_ transaction: BudgetTransaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

/// One movement in the list: type icon, title, account path, amount
/// colored by direction, planned badge.
struct TransactionRow: View {
    let transaction: BudgetTransaction

    private var isInflow: Bool {
        switch transaction.type {
        case .income, .refund: true
        case .adjustment: transaction.adjustmentIncreasesBalance
        default: false
        }
    }

    private var amountColor: Color {
        if transaction.type == .transfer || transaction.isInternalMovement {
            return BudgetColor.informative
        }
        return isInflow ? BudgetColor.positive : BudgetColor.negative
    }

    private var accountPath: String {
        let source = transaction.account?.name ?? "?"
        if let destination = transaction.destinationAccount {
            return "\(source) → \(destination.name)"
        }
        return source
    }

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: transaction.type.systemImage)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BudgetSpacing.micro) {
                        Text(transaction.title)
                            .font(BudgetFont.body.weight(.medium))
                            .lineLimit(1)
                        if transaction.status == .planned {
                            Text("Prévu")
                                .font(BudgetFont.caption.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(BudgetColor.warning.opacity(0.25), in: Capsule())
                                .foregroundStyle(BudgetColor.warning)
                        }
                    }
                    Text("\(transaction.type.displayName) · \(accountPath)")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: BudgetSpacing.small)
                Text((isInflow ? "+" : transaction.type == .transfer ? "" : "−") + FinanceFormatting.chf(transaction.amount))
                    .font(BudgetFont.amount)
                    .foregroundStyle(amountColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.title), \(transaction.type.displayName), \(FinanceFormatting.chf(transaction.amount)), \(FinanceFormatting.swissDate(transaction.date))\(transaction.status == .planned ? ", prévu" : "")")
    }
}

#Preview("Mouvements") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        TransactionsListView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
