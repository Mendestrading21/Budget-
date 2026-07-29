import SwiftUI
import SwiftData

/// Create or edit one budget line for the month of `monthAnchor`.
/// Creation goes through BudgetPlanningService so the (year, month)
/// budget is unique.
struct BudgetLineFormView: View {
    enum Mode {
        case create
        case edit(BudgetLine)
    }

    let mode: Mode
    let monthAnchor: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \BudgetCategory.sortOrder) private var allCategories: [BudgetCategory]
    @Query private var budgets: [MonthlyBudget]

    @State private var category: BudgetCategory?
    @State private var amountText: String = ""
    @State private var errorMessage: String?
    @State private var isConfirmingDelete = false

    private var editedLine: BudgetLine? {
        if case .edit(let line) = mode { return line }
        return nil
    }

    private var planningService: BudgetPlanningService {
        BudgetPlanningService(calendar: appContainer.calendar)
    }

    /// Categories selectable for this line: active, not already budgeted
    /// this month (the edited line's own category stays selectable).
    private var selectableCategories: [BudgetCategory] {
        let (year, month) = planningService.yearAndMonth(of: monthAnchor)
        let budgetedIDs = Set(
            budgets.first { $0.year == year && $0.month == month }?
                .lines.compactMap { $0.category?.id } ?? []
        )
        return allCategories.filter { candidate in
            guard candidate.isActive else { return false }
            if candidate.id == editedLine?.category?.id { return true }
            return !budgetedIDs.contains(candidate.id)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Catégorie") {
                    Picker("Catégorie", selection: $category) {
                        Text("Choisir…").tag(BudgetCategory?.none)
                        ForEach(selectableCategories) { category in
                            Text("\(category.kind.displayName) · \(category.name)").tag(BudgetCategory?.some(category))
                        }
                    }
                }
                Section {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Montant planifié (CHF)")
                } footer: {
                    Text("Enveloppe prévue pour ce mois. Le réel est calculé automatiquement depuis les mouvements comptabilisés — il n'est jamais saisi ici.")
                }

                if editedLine != nil {
                    Section {
                        Button("Supprimer cette ligne", role: .destructive) {
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
            .navigationTitle(editedLine == nil ? "Nouvelle ligne" : "Modifier la ligne")
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
                "Supprimer cette ligne de budget ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) { deleteLine() }
            } message: {
                Text("Seule l'enveloppe planifiée est supprimée ; aucun mouvement n'est touché.")
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let line = editedLine else { return }
        category = line.category
        amountText = "\(line.plannedAmount)"
    }

    private func save() {
        errorMessage = nil
        guard let category else {
            errorMessage = "Choisissez une catégorie."
            return
        }
        guard let parsed = FinanceFormatting.parseAmount(amountText.trimmingCharacters(in: .whitespaces)),
              parsed >= 0 else {
            errorMessage = "Le montant planifié n'est pas valide. Exemple : 600.00"
            return
        }
        let amount = FinanceMath.roundedToCents(parsed)
        let now = appContainer.dateProvider.now

        do {
            if let line = editedLine {
                line.category = category
                line.plannedAmount = amount
                line.updatedAt = now
                line.budget?.updatedAt = now
            } else {
                let budget = try planningService.findOrCreate(monthOf: monthAnchor, now: now, context: modelContext)
                let line = BudgetLine(plannedAmount: amount, category: category, createdAt: now, updatedAt: now)
                line.budget = budget
                modelContext.insert(line)
                budget.updatedAt = now
            }
            if modelContext.saveOrRollback(onError: { _ in
                errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
            }) {
                dismiss()
            }
        } catch {
            modelContext.rollback()
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }

    private func deleteLine() {
        guard let line = editedLine else { return }
        line.budget?.updatedAt = appContainer.dateProvider.now
        modelContext.delete(line)
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "La suppression a échoué. Réessayez."
        }) {
            dismiss()
        }
    }
}

#Preview("Nouvelle ligne") {
    let preview = DemoDataFactory.previewAppContainer()
    return BudgetLineFormView(mode: .create, monthAnchor: DemoDataFactory.previewReferenceDate)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
