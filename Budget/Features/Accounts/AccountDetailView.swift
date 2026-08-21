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
    @State private var isPresentingNewPosition = false
    @State private var editedPosition: BrokeragePosition?

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

    // P06 : la suppression protège TOUTES les références — un récurrent qui
    // part de ce compte OU y arrive, et un objectif qui le suit. Sans cette
    // garde, SwiftData nullifiait le lien en silence (les relations
    // récurrentes n'ont pas de règle .deny).
    @Query private var allRecurrings: [RecurringTransaction]
    @Query private var allGoals: [FinancialGoal]
    // INV1 (ADR-047) : les positions du compte titres — décoratives et
    // explicatives, jamais lues par un agrégat.
    @Query private var allPositions: [BrokeragePosition]

    private var accountPositions: [BrokeragePosition] {
        allPositions
            .filter { $0.account?.id == account.id }
            .sorted { $0.value > $1.value }
    }

    private var deletionBlocker: String? {
        if hasMovements {
            return "Ce compte porte des opérations — l'historique ne disparaît jamais en silence."
        }
        if allRecurrings.contains(where: { $0.account?.id == account.id }) {
            return "Un paiement régulier utilise ce compte — choisissez d'abord un autre compte."
        }
        if allRecurrings.contains(where: { $0.destinationAccount?.id == account.id }) {
            return "Un versement régulier arrive sur ce compte — choisissez d'abord une autre destination."
        }
        if allGoals.contains(where: { $0.linkedAccount?.id == account.id }) {
            return "Un objectif suit ce compte — déliez-le d'abord, sinon sa progression retomberait à zéro."
        }
        if allPositions.contains(where: { $0.account?.id == account.id }) {
            return "Des positions expliquent ce compte — supprimez-les d'abord."
        }
        return nil
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    balanceCard
                    monthFlowCard
                    contributionCard
                    positionsSection
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
            .obsidianFABClearance()
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
                    if deletionBlocker == nil {
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
        .sheet(isPresented: $isPresentingNewPosition) {
            PositionFormView(mode: .create(account))
        }
        .sheet(item: $editedPosition) { position in
            PositionFormView(mode: .edit(position))
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
            Text("Ce compte n'est utilisé nulle part — aucune opération, aucun paiement régulier, aucun objectif. La suppression est définitive.")
        }
    }

    private var balanceCard: some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                HStack {
                    // P06 (ADR-044) : la fiche porte la MÊME identité que la
                    // liste — correspondance exacte, sinon rien. Décoratif :
                    // le solde et les agrégats ne changent jamais.
                    if let entry = BudgetIdentityCatalog.institutionEntry(matching: account.institutionName) {
                        BudgetIdentityIcon(name: entry.displayName)
                    }
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
                    Text("Dernier mouvement le \(FinanceFormatting.swissDate(lastMovement.date)) — votre solde de départ \(FinanceFormatting.chf(account.openingBalance)), plus vos mouvements")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Votre solde de départ \(FinanceFormatting.chf(account.openingBalance)), plus vos mouvements")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Solde actuel : \(FinanceFormatting.chf(currentBalance))\(account.isActive ? "" : ", compte archivé")")
        }
    }

    /// INV1 (ADR-047) : les positions EXPLIQUENT le solde du compte
    /// titres — valeur des positions + espèces/non réparti = solde. La
    /// fortune lit le solde, jamais les positions (44'000, jamais 84'000).
    @ViewBuilder
    private var positionsSection: some View {
        if account.type == .broker {
            let positions = accountPositions
            let unallocated = BrokeragePositionMath.unallocated(balance: currentBalance, positions: positions)
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text("Positions")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    if positions.isEmpty {
                        Text("Notez ici ce que contient ce compte — actions, fonds, ETF. Les positions expliquent le solde, elles ne s'y ajoutent jamais.")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(positions) { position in
                        Button {
                            editedPosition = position
                        } label: {
                            HStack(spacing: BudgetSpacing.small) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(position.instrumentName)
                                        .font(BudgetFont.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("\(position.quantity) × \(FinanceFormatting.chf(position.manualPrice)) · Prix saisi le \(FinanceFormatting.swissDate(position.valuationDate))")
                                        .font(BudgetFont.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: BudgetSpacing.small)
                                AmountText(amount: position.value, emphasis: .neutral)
                            }
                        }
                        .accessibilityIdentifier("position.\(position.id.uuidString)")
                    }
                    if !positions.isEmpty {
                        HStack {
                            Text("Espèces / non réparti")
                                .font(BudgetFont.body)
                            Spacer(minLength: BudgetSpacing.small)
                            AmountText(amount: unallocated, emphasis: unallocated < 0 ? .negative : .neutral)
                        }
                        if unallocated < 0 {
                            Text("Vos positions dépassent le solde du compte. Mettez le solde à jour, ou corrigez un prix saisi.")
                                .font(BudgetFont.caption)
                                .foregroundStyle(BudgetColor.negative)
                        }
                        Text("La valeur des positions plus les espèces égale le solde du compte : \(FinanceFormatting.chf(currentBalance)). Votre fortune lit ce solde — les positions l'expliquent, elles ne s'y ajoutent jamais.")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Ajouter une position", systemImage: "plus") {
                        isPresentingNewPosition = true
                    }
                    .font(BudgetFont.body)
                    .accessibilityIdentifier("account.addPosition")
                }
            }
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
        modelContext.saveOrRollback { _ in
            actionErrorMessage = "L'opération a échoué. Réessayez."
        }
    }

    private func deleteAccount() {
        guard deletionBlocker == nil else { return }
        modelContext.delete(account)
        if modelContext.saveOrRollback(onError: { _ in
            actionErrorMessage = "La suppression a échoué. Réessayez."
        }) {
            dismiss()
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
