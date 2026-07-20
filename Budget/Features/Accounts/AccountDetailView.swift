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
                        Text("Archivé")
                            .font(BudgetFont.caption.weight(.semibold))
                            .padding(.horizontal, BudgetSpacing.small)
                            .padding(.vertical, 2)
                            .background(BudgetColor.coolGray.opacity(0.3), in: Capsule())
                    }
                }
                Text(FinanceFormatting.chf(currentBalance))
                    .font(BudgetFont.heroAmount)
                    .foregroundStyle(currentBalance < 0 ? BudgetColor.negative : .primary)
                if let reconciledAt = account.reconciledAt, let reconciled = account.reconciledBalance {
                    Text("Réconcilié à \(FinanceFormatting.chf(reconciled)) le \(FinanceFormatting.swissDate(reconciledAt))")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Solde initial \(FinanceFormatting.chf(account.openingBalance)) + mouvements comptabilisés")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Solde actuel : \(FinanceFormatting.chf(currentBalance))")
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
                Text(FinanceFormatting.chfSigned(effect))
                    .font(BudgetFont.amount)
                    .foregroundStyle(effect >= 0 ? BudgetColor.positive : BudgetColor.negative)
                    .opacity(movement.status == .planned ? 0.6 : 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movement.title), \(FinanceFormatting.swissDate(movement.date)), \(FinanceFormatting.chfSigned(effect))\(movement.status == .planned ? ", prévu" : "")")
    }
}
