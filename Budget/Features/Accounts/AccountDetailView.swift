import SwiftUI
import SwiftData

/// Account detail: balance, month flow, movement history, reconciliation,
/// archive. Accounts with history are archived, never deleted.
struct AccountDetailView: View {
    let account: Account

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isPresentingEdit = false
    @State private var isPresentingNewMovement = false
    @State private var isPresentingReconcile = false
    @State private var saveErrorMessage: String?
    @State private var isConfirmingArchive = false
    @State private var isConfirmingDelete = false
    @State private var actionErrorMessage: String?

    private var balanceService: AccountBalanceService { appContainer.balanceService }

    private var movements: [BudgetTransaction] {
        var unique: [UUID: BudgetTransaction] = [:]
        for movement in account.transactions + account.incomingMovements {
            unique[movement.id] = movement
        }
        return unique.values.sorted { $0.date > $1.date }
    }

    private var currentBalance: Decimal {
        balanceService.balance(of: account)
    }

    private var currentMonthFlows: (inflow: Decimal, outflow: Decimal) {
        let interval = MonthInterval(containing: appContainer.dateProvider.now, calendar: appContainer.calendar)
        var inflow: Decimal = .zero
        var outflow: Decimal = .zero
        for movement in movements where movement.status == .posted && interval.contains(movement.date) {
            let effect = balanceService.signedEffect(of: movement, on: account)
            if effect > 0 { inflow += effect } else { outflow -= effect }
        }
        return (inflow, outflow)
    }

    private var hasMovements: Bool { !movements.isEmpty }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    balanceCard
                    monthFlowCard
                    contributionCard
                    optionsCard
                    historySection
                    if let actionErrorMessage {
                        Label(actionErrorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            }
        }
        .navigationTitle(account.name)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Ajouter un mouvement", systemImage: "plus") { isPresentingNewMovement = true }
                    Button("Modifier", systemImage: "pencil") { isPresentingEdit = true }
                    Button("Réconcilier le solde", systemImage: "checkmark.seal") { isPresentingReconcile = true }
                    if account.isActive {
                        Button("Archiver", systemImage: "archivebox") { isConfirmingArchive = true }
                    } else {
                        Button("Réactiver", systemImage: "arrow.uturn.backward") { setActive(true) }
                    }
                    if !hasMovements {
                        Button("Supprimer", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isPresentingEdit) {
            AccountFormView(mode: .edit(account))
        }
        .sheet(isPresented: $isPresentingNewMovement) {
            TransactionFormView(mode: .create(prefilledAccount: account))
        }
        .sheet(isPresented: $isPresentingReconcile) {
            ReconcileSheet(account: account)
        }
        .confirmationDialog(
            "Archiver ce compte ?",
            isPresented: $isConfirmingArchive,
            titleVisibility: .visible
        ) {
            Button("Archiver", role: .destructive) { setActive(false) }
        } message: {
            Text("Le compte et son historique restent consultables mais sortent des listes actives.")
        }
        .confirmationDialog(
            "Supprimer ce compte ?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Supprimer définitivement", role: .destructive) { deleteAccount() }
        } message: {
            Text("Ce compte n'a aucun mouvement ; la suppression est définitive.")
        }
    }

    private var balanceCard: some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                HStack {
                    Label(account.type.displayName, systemImage: account.type.systemImage)
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !account.isActive {
                        StatusPill(text: "Archivé", kind: .neutral)
                    }
                }
                AmountText(
                    amount: currentBalance,
                    role: .hero,
                    emphasis: currentBalance < 0 ? .negative : .neutral
                )
                if let reconciledAt = account.reconciledAt, let reconciled = account.reconciledBalance {
                    Text("Réconcilié à \(FinanceFormatting.chf(reconciled)) le \(FinanceFormatting.swissDate(reconciledAt))")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                } else if let lastMovement = movements.first {
                    // Fraîcheur du solde en langage simple.
                    Text("Dernier mouvement le \(FinanceFormatting.swissDate(lastMovement.date)) — solde initial \(FinanceFormatting.chf(account.openingBalance)) + mouvements comptabilisés")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Solde initial \(FinanceFormatting.chf(account.openingBalance)) + mouvements comptabilisés")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Solde actuel : \(FinanceFormatting.chf(currentBalance))\(account.isActive ? "" : ", compte archivé")")
        }
    }

    /// Cumuls « façon Finary » — visibles uniquement sur les comptes de
    /// placement : chaque versement s'additionne, la performance d'un
    /// compte titres affiche sa méthode.
    @ViewBuilder
    private var contributionCard: some View {
        if ContributionService.tracksContributions(account.type) {
            let service = ContributionService(calendar: appContainer.calendar)
            let summary = service.summary(
                of: account, movements: movements, now: appContainer.dateProvider.now
            )
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                    Text("Versements cumulés")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    Text("Cette année : \(FinanceFormatting.chf(summary.currentYear)) · au total : \(FinanceFormatting.chf(summary.total))")
                        .font(BudgetFont.body.weight(.semibold))
                    if summary.withdrawn > 0 {
                        Text("Retraits : \(FinanceFormatting.chf(summary.withdrawn))")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    if account.type == .broker {
                        let perf = service.performance(
                            balance: currentBalance,
                            openingBalance: account.openingBalance,
                            summary: summary
                        )
                        Text("Performance : \(FinanceFormatting.chf(perf))")
                            .font(BudgetFont.body.weight(.semibold))
                            .foregroundStyle(perf >= 0 ? BudgetColor.positive : BudgetColor.negative)
                        Text("Valeur actuelle − versements nets. Fiable si le solde est tenu à jour (réconciliation).")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Versements cumulés : \(FinanceFormatting.chf(summary.currentYear)) cette année, \(FinanceFormatting.chf(summary.total)) au total")
        }
    }

    private var monthFlowCard: some View {
        let flows = currentMonthFlows
        return GlassCard {
            HStack(spacing: BudgetSpacing.large) {
                VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                    Label("Entrées du mois", systemImage: "arrow.down")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    Text(FinanceFormatting.chf(flows.inflow))
                        .font(BudgetFont.amount)
                        .foregroundStyle(BudgetColor.positive)
                }
                Divider()
                VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                    Label("Sorties du mois", systemImage: "arrow.up")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    Text(FinanceFormatting.chf(flows.outflow))
                        .font(BudgetFont.amount)
                        .foregroundStyle(BudgetColor.negative)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Ce mois : entrées \(FinanceFormatting.chf(flows.inflow)), sorties \(FinanceFormatting.chf(flows.outflow))")
        }
    }

    private var optionsCard: some View {
        GlassCard {
            VStack(spacing: BudgetSpacing.small) {
                Toggle("Compte dans le cash disponible", isOn: bindingForCashFlag)
                Toggle("Compte dans le patrimoine", isOn: bindingForNetWorthFlag)
            }
            .tint(BudgetColor.indigo)
            .font(BudgetFont.body)
        }
    }

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            Text("Historique")
                .font(BudgetFont.sectionTitle)
                .foregroundStyle(.secondary)
            if movements.isEmpty {
                GlassCard(style: .row) {
                    Text("Aucun mouvement pour l'instant.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(movements) { movement in
                    MovementRow(
                        movement: movement,
                        effect: balanceService.signedEffect(of: movement, on: account)
                    )
                }
            }
        }
    }

    private var bindingForCashFlag: Binding<Bool> {
        Binding(
            get: { account.includeInAvailableCash },
            set: { newValue in
                account.includeInAvailableCash = newValue
                account.updatedAt = appContainer.dateProvider.now
                modelContext.saveOrRollback { saveErrorMessage = $0 }
            }
        )
    }

    private var bindingForNetWorthFlag: Binding<Bool> {
        Binding(
            get: { account.includeInNetWorth },
            set: { newValue in
                account.includeInNetWorth = newValue
                account.updatedAt = appContainer.dateProvider.now
                modelContext.saveOrRollback { saveErrorMessage = $0 }
            }
        )
    }

    private func setActive(_ active: Bool) {
        account.isActive = active
        account.updatedAt = appContainer.dateProvider.now
        do {
            try modelContext.save()
        } catch {
            actionErrorMessage = "L'opération a échoué. Réessayez."
        }
    }

    private func deleteAccount() {
        guard !hasMovements else { return }
        modelContext.delete(account)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            actionErrorMessage = "La suppression a échoué. Réessayez."
        }
    }
}

/// One movement as seen from a given account: colored signed effect.
struct MovementRow: View {
    let movement: BudgetTransaction
    let effect: Decimal

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: movement.type.systemImage)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(movement.title)
                        .font(BudgetFont.body.weight(.medium))
                        .lineLimit(1)
                    HStack(spacing: BudgetSpacing.micro) {
                        Text(FinanceFormatting.swissDate(movement.date))
                        if movement.status == .planned {
                            Text("· Prévu")
                                .foregroundStyle(BudgetColor.warning)
                        }
                    }
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: BudgetSpacing.small)
                AmountText(
                    amount: effect,
                    signed: true,
                    emphasis: effect >= 0 ? .positive : .negative
                )
                .opacity(movement.status == .planned ? 0.6 : 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movement.title), \(FinanceFormatting.swissDate(movement.date)), \(FinanceFormatting.chfSigned(effect))\(movement.status == .planned ? ", prévu" : "")")
    }
}
