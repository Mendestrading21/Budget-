import SwiftUI
import SwiftData

/// Duplication d'un mouvement (L5) : copie fidèle de TOUS les champs
/// métier, avec de nouveaux horodatages — factorisée pour être testée et
/// partagée entre la liste (swipe/menu) et la feuille d'édition.
enum TransactionDuplication {
    static func copy(of transaction: BudgetTransaction, now: Date) -> BudgetTransaction {
        BudgetTransaction(
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
    }
}

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
    @State private var saveErrorMessage: String?
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
        .navigationTitle("Historique")
        .alert(
            saveErrorMessage ?? "",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        }
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
            QuickEntrySheet(prefilledDate: currentAnchor, prefilledAccount: accountFilter)
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
                // L5 : LazyVStack — les longues listes ne construisent que
                // les lignes visibles (contrat de performance).
                LazyVStack(spacing: BudgetSpacing.medium) {
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
                                    // Pas de swipe hors List (geste mort) :
                                    // les actions VISIBLES vivent dans la
                                    // feuille d'édition, le menu long reste
                                    // un raccourci.
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
            .obsidianFABClearance()
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
                if hasActiveFilters || !searchText.isEmpty {
                    EmptyState(
                        symbol: "magnifyingglass",
                        title: "Aucun résultat",
                        message: "Aucun mouvement ne correspond aux filtres actuels. Modifiez la recherche ou réinitialisez les filtres."
                    )
                } else {
                    EmptyState(
                        symbol: "tray",
                        title: "Aucun mouvement ce mois",
                        message: "Ajoutez vos revenus, dépenses, épargne et virements pour suivre votre mois.",
                        actionTitle: "Ajouter",
                        action: { isPresentingNew = true }
                    )
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }

    // MARK: - Actions

    private func duplicate(_ transaction: BudgetTransaction) {
        let copy = TransactionDuplication.copy(of: transaction, now: appContainer.dateProvider.now)
        modelContext.insert(copy)
        modelContext.saveOrRollback { saveErrorMessage = $0 }
        editedTransaction = copy
    }

    private func delete(_ transaction: BudgetTransaction) {
        modelContext.delete(transaction)
        modelContext.saveOrRollback { saveErrorMessage = $0 }
    }
}

/// One movement in the list: type icon, title, account path, amount
/// colored by direction, planned badge.
struct TransactionRow: View {
    let transaction: BudgetTransaction
    @Environment(\.colorScheme) private var colorScheme

    /// Pastille teintée par nature (Horizon v2) — l'orientation avant la
    /// lecture, miroir des pastilles PWA.
    private var iconTint: Color {
        switch transaction.type {
        case .income, .refund: BudgetTint.income(colorScheme)
        case .expense, .taxPayment: BudgetTint.expense(colorScheme)
        case .saving, .investment: BudgetTint.saving(colorScheme)
        case .transfer, .adjustment, .debtPayment: BudgetTint.neutral(colorScheme)
        }
    }

    private var iconColor: Color {
        switch transaction.type {
        case .income, .refund: BudgetColor.positive
        case .expense, .taxPayment: BudgetColor.negative
        // Épargne/investissement : teinte de MARQUE (l'ex-teal a disparu).
        case .saving, .investment: BudgetColor.brandBright
        case .transfer, .adjustment, .debtPayment: BudgetTheme.secondaryText(colorScheme)
        }
    }

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
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BudgetSpacing.micro) {
                        Text(transaction.title)
                            .font(BudgetFont.body.weight(.medium))
                            .lineLimit(1)
                        if transaction.status == .planned {
                            StatusPill(text: "Prévu", kind: .warning)
                        }
                    }
                    Text("\(transaction.type.displayName) · \(accountPath)\(natureNote)")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: BudgetSpacing.small)
                Text((isInflow ? "+" : transaction.type == .transfer ? "" : "−") + FinanceFormatting.chf(transaction.amount))
                    .font(BudgetFont.amount)
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.title), \(transaction.type.displayName)\(natureNote), \(FinanceFormatting.chf(transaction.amount)), \(FinanceFormatting.swissDate(transaction.date))\(transaction.status == .planned ? ", prévu" : "")")
    }

    /// La nature financière est ÉCRITE, jamais portée par la couleur seule :
    /// virement neutre, épargne/investissement « mis de côté ».
    private var natureNote: String {
        switch transaction.type {
        case .transfer: " · neutre"
        case .saving, .investment: " · mis de côté"
        default: ""
        }
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
