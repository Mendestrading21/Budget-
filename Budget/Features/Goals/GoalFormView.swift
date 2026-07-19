import SwiftUI
import SwiftData

/// Create or edit a savings goal.
struct GoalFormView: View {
    enum Mode {
        case create
        case edit(FinancialGoal)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \Account.createdAt) private var allAccounts: [Account]

    @State private var name = ""
    @State private var kind: GoalKind = .emergencyFund
    @State private var targetAmountText = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Date()
    @State private var linkedAccount: Account?
    @State private var manualCurrentText = ""
    @State private var plannedContributionText = ""
    @State private var priority: GoalPriority = .normal
    @State private var status: GoalStatus = .active
    @State private var errorMessage: String?
    @State private var isConfirmingDelete = false

    private var editedGoal: FinancialGoal? {
        if case .edit(let goal) = mode { return goal }
        return nil
    }

    private var linkableAccounts: [Account] {
        allAccounts.filter { $0.isActive || $0.id == editedGoal?.linkedAccount?.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Objectif") {
                    TextField("Nom (ex. Vacances d'été)", text: $name)
                    Picker("Type", selection: $kind) {
                        ForEach(GoalKind.allCases) { kind in
                            Label("\(kind.defaultEmoji) \(kind.displayName)", systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    TextField("Montant visé (CHF)", text: $targetAmountText)
                        .keyboardType(.decimalPad)
                    Toggle("Date cible", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Atteindre d'ici le", selection: $targetDate, displayedComponents: .date)
                    }
                }

                Section {
                    Picker("Compte lié", selection: $linkedAccount) {
                        Text("Aucun (suivi manuel)").tag(Account?.none)
                        ForEach(linkableAccounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                    if linkedAccount == nil {
                        TextField("Montant déjà épargné (CHF)", text: $manualCurrentText)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Où vit cet argent ?")
                } footer: {
                    Text(linkedAccount == nil
                         ? "Sans compte lié, vous mettez le montant à jour vous-même."
                         : "Le progrès suit automatiquement le solde du compte lié.")
                }

                Section("Rythme") {
                    TextField("Contribution mensuelle prévue (CHF)", text: $plannedContributionText)
                        .keyboardType(.decimalPad)
                    Picker("Priorité", selection: $priority) {
                        ForEach(GoalPriority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    Picker("Statut", selection: $status) {
                        ForEach(GoalStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                if editedGoal != nil {
                    Section {
                        Button("Supprimer cet objectif", role: .destructive) {
                            isConfirmingDelete = true
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                    }
                }
            }
            .navigationTitle(editedGoal == nil ? "Nouvel objectif" : "Modifier l'objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                }
            }
            .confirmationDialog(
                "Supprimer cet objectif ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer définitivement", role: .destructive) { deleteGoal() }
            } message: {
                Text("Seul l'objectif est supprimé ; aucun compte ni mouvement n'est touché.")
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let goal = editedGoal else {
            targetDate = appContainer.calendar.date(byAdding: .year, value: 1, to: appContainer.dateProvider.now) ?? Date()
            return
        }
        name = goal.name
        kind = goal.kind
        targetAmountText = "\(goal.targetAmount)"
        hasTargetDate = goal.targetDate != nil
        targetDate = goal.targetDate ?? Date()
        linkedAccount = goal.linkedAccount
        manualCurrentText = goal.manualCurrentAmount == .zero ? "" : "\(goal.manualCurrentAmount)"
        plannedContributionText = goal.plannedMonthlyContribution == .zero ? "" : "\(goal.plannedMonthlyContribution)"
        priority = goal.priority
        status = goal.status
    }

    private func parseOptionalAmount(_ text: String) -> Decimal?? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .some(nil) }
        guard let parsed = FinanceFormatting.parseAmount(trimmed), parsed >= 0 else { return nil }
        return .some(parsed)
    }

    private func save() {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Donnez un nom à cet objectif."
            return
        }
        guard let target = FinanceFormatting.parseAmount(targetAmountText.trimmingCharacters(in: .whitespaces)),
              target > 0 else {
            errorMessage = "Le montant visé doit être supérieur à zéro. Exemple : 10'000.00"
            return
        }
        guard let manualParsed = parseOptionalAmount(manualCurrentText) else {
            errorMessage = "Le montant déjà épargné n'est pas valide."
            return
        }
        guard let plannedParsed = parseOptionalAmount(plannedContributionText) else {
            errorMessage = "La contribution mensuelle n'est pas valide."
            return
        }

        let now = appContainer.dateProvider.now
        let manual = FinanceMath.roundedToCents(manualParsed ?? .zero)
        let planned = FinanceMath.roundedToCents(plannedParsed ?? .zero)

        do {
            if let goal = editedGoal {
                goal.name = trimmedName
                goal.kind = kind
                goal.emoji = kind.defaultEmoji
                goal.targetAmount = FinanceMath.roundedToCents(target)
                goal.targetDate = hasTargetDate ? targetDate : nil
                goal.linkedAccount = linkedAccount
                goal.manualCurrentAmount = linkedAccount == nil ? manual : .zero
                goal.plannedMonthlyContribution = planned
                goal.priority = priority
                goal.status = status
                goal.updatedAt = now
            } else {
                let goal = FinancialGoal(
                    name: trimmedName,
                    kind: kind,
                    targetAmount: FinanceMath.roundedToCents(target),
                    targetDate: hasTargetDate ? targetDate : nil,
                    manualCurrentAmount: linkedAccount == nil ? manual : .zero,
                    plannedMonthlyContribution: planned,
                    priority: priority,
                    status: status,
                    createdAt: now,
                    updatedAt: now,
                    linkedAccount: linkedAccount
                )
                modelContext.insert(goal)
            }
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }

    private func deleteGoal() {
        guard let goal = editedGoal else { return }
        modelContext.delete(goal)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "La suppression a échoué. Réessayez."
        }
    }
}

#Preview("Nouvel objectif") {
    let preview = DemoDataFactory.previewAppContainer()
    return GoalFormView(mode: .create)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
