import SwiftUI
import SwiftData

/// Create or edit a non-account asset.
struct AssetFormView: View {
    enum Mode {
        case create
        case edit(Asset)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @State private var name = ""
    @State private var kind: AssetKind = .vehicle
    @State private var valueText = ""
    @State private var includeInNetWorth = true
    @State private var hasValuationDate = false
    @State private var valuationDate = Date()
    @State private var note = ""
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?

    private var editedAsset: Asset? {
        if case .edit(let asset) = mode { return asset }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actif") {
                    TextField("Nom (ex. Voiture familiale)", text: $name)
                    Picker("Type", selection: $kind) {
                        ForEach(AssetKind.allCases) { kind in
                            Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    TextField("Valeur estimée (CHF)", text: $valueText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Toggle("Compte dans le patrimoine", isOn: $includeInNetWorth)
                    Toggle("Date d'évaluation", isOn: $hasValuationDate)
                    if hasValuationDate {
                        DatePicker("Évalué le", selection: $valuationDate, displayedComponents: .date)
                    }
                    TextField("Note (facultatif)", text: $note, axis: .vertical)
                }
                if editedAsset != nil {
                    Section {
                        Button("Supprimer cet actif", role: .destructive) {
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
            .navigationTitle(editedAsset == nil ? "Nouvel actif" : "Modifier l'actif")
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
                "Supprimer cet actif ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer définitivement", role: .destructive) { deleteAsset() }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let asset = editedAsset else { return }
        name = asset.name
        kind = asset.kind
        valueText = "\(asset.currentValue)"
        includeInNetWorth = asset.includeInNetWorth
        hasValuationDate = asset.valuationDate != nil
        valuationDate = asset.valuationDate ?? Date()
        note = asset.note ?? ""
    }

    private func save() {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Donnez un nom à cet actif."
            return
        }
        guard let value = FinanceFormatting.parseAmount(valueText.trimmingCharacters(in: .whitespaces)),
              value >= 0 else {
            errorMessage = "La valeur doit être un montant positif ou nul. Exemple : 12'000.00"
            return
        }
        let now = appContainer.dateProvider.now
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        do {
            if let asset = editedAsset {
                asset.name = trimmedName
                asset.kind = kind
                asset.currentValue = FinanceMath.roundedToCents(value)
                asset.includeInNetWorth = includeInNetWorth
                asset.valuationDate = hasValuationDate ? valuationDate : nil
                asset.note = trimmedNote.isEmpty ? nil : trimmedNote
                asset.updatedAt = now
            } else {
                let asset = Asset(
                    name: trimmedName,
                    kind: kind,
                    currentValue: FinanceMath.roundedToCents(value),
                    includeInNetWorth: includeInNetWorth,
                    valuationDate: hasValuationDate ? valuationDate : nil,
                    note: trimmedNote.isEmpty ? nil : trimmedNote,
                    createdAt: now,
                    updatedAt: now
                )
                modelContext.insert(asset)
            }
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }

    private func deleteAsset() {
        guard let asset = editedAsset else { return }
        modelContext.delete(asset)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "La suppression a échoué. Réessayez."
        }
    }
}

/// Create or edit a standalone debt (stored positive; the service
/// subtracts it from net worth).
struct LiabilityFormView: View {
    enum Mode {
        case create
        case edit(Liability)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @State private var name = ""
    @State private var kind: LiabilityKind = .leasing
    @State private var amountText = ""
    @State private var includeInNetWorth = true
    @State private var note = ""
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?

    private var editedLiability: Liability? {
        if case .edit(let liability) = mode { return liability }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dette") {
                    TextField("Nom (ex. Leasing voiture)", text: $name)
                    Picker("Type", selection: $kind) {
                        ForEach(LiabilityKind.allCases) { kind in
                            Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    TextField("Montant restant dû (CHF)", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Toggle("Compte dans le patrimoine", isOn: $includeInNetWorth)
                    TextField("Note (facultatif)", text: $note, axis: .vertical)
                } footer: {
                    Text("Saisissez le montant en positif — il sera soustrait de votre fortune nette. Les dettes portées par un compte (carte de crédit) restent sur ce compte.")
                }
                if editedLiability != nil {
                    Section {
                        Button("Supprimer cette dette", role: .destructive) {
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
            .navigationTitle(editedLiability == nil ? "Nouvelle dette" : "Modifier la dette")
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
                "Supprimer cette dette ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer définitivement", role: .destructive) { deleteLiability() }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let liability = editedLiability else { return }
        name = liability.name
        kind = liability.kind
        amountText = "\(liability.outstandingAmount)"
        includeInNetWorth = liability.includeInNetWorth
        note = liability.note ?? ""
    }

    private func save() {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Donnez un nom à cette dette."
            return
        }
        guard let amount = FinanceFormatting.parseAmount(amountText.trimmingCharacters(in: .whitespaces)),
              amount >= 0 else {
            errorMessage = "Le montant doit être positif ou nul. Exemple : 8'400.00"
            return
        }
        let now = appContainer.dateProvider.now
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        do {
            if let liability = editedLiability {
                liability.name = trimmedName
                liability.kind = kind
                liability.outstandingAmount = FinanceMath.roundedToCents(amount)
                liability.includeInNetWorth = includeInNetWorth
                liability.note = trimmedNote.isEmpty ? nil : trimmedNote
                liability.updatedAt = now
            } else {
                let liability = Liability(
                    name: trimmedName,
                    kind: kind,
                    outstandingAmount: FinanceMath.roundedToCents(amount),
                    includeInNetWorth: includeInNetWorth,
                    note: trimmedNote.isEmpty ? nil : trimmedNote,
                    createdAt: now,
                    updatedAt: now
                )
                modelContext.insert(liability)
            }
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }

    private func deleteLiability() {
        guard let liability = editedLiability else { return }
        modelContext.delete(liability)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "La suppression a échoué. Réessayez."
        }
    }
}

#Preview("Nouvel actif") {
    let preview = DemoDataFactory.previewAppContainer()
    return AssetFormView(mode: .create)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
