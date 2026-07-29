import SwiftUI
import SwiftData

/// Create or edit one pension position from an official statement.
struct PensionAssetFormView: View {
    enum Mode {
        case create
        case edit(PensionAsset)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query private var households: [Household]

    @State private var pillar: PensionPillar = .pillar3a
    @State private var institutionName = ""
    @State private var currentValueText = ""
    @State private var annualContributionText = ""
    @State private var projectedText = ""
    @State private var retirementAgeText = ""
    @State private var owner: HouseholdMember?
    @State private var hasDocumentDate = false
    @State private var documentDate = Date()
    @State private var note = ""
    @State private var isActive = true
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?

    private var editedAsset: PensionAsset? {
        if case .edit(let asset) = mode { return asset }
        return nil
    }

    private var members: [HouseholdMember] {
        households.first?.members ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Position") {
                    Picker("Pilier", selection: $pillar) {
                        ForEach(PensionPillar.allCases) { pillar in
                            Label(pillar.displayName, systemImage: pillar.systemImage).tag(pillar)
                        }
                    }
                    TextField("Institution (caisse, fondation…)", text: $institutionName)
                    if !members.isEmpty {
                        Picker("Titulaire", selection: $owner) {
                            Text("Non précisé").tag(HouseholdMember?.none)
                            ForEach(members) { member in
                                Text(member.firstName).tag(HouseholdMember?.some(member))
                            }
                        }
                    }
                }

                Section {
                    TextField("Valeur actuelle (CHF)", text: $currentValueText)
                        .keyboardType(.decimalPad)
                    TextField("Contribution annuelle (CHF, facultatif)", text: $annualContributionText)
                        .keyboardType(.decimalPad)
                    TextField("Projection à la retraite (CHF, facultatif)", text: $projectedText)
                        .keyboardType(.decimalPad)
                    TextField("Âge de retraite (facultatif)", text: $retirementAgeText)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Montants du relevé")
                } footer: {
                    Text("Recopiez les chiffres de votre certificat LPP ou relevé 3a. La projection est celle de l'institution, pas un calcul de l'app.")
                }

                Section("Source") {
                    Toggle("Date du relevé", isOn: $hasDocumentDate)
                    if hasDocumentDate {
                        DatePicker("Relevé du", selection: $documentDate, displayedComponents: .date)
                    }
                    TextField("Note (facultatif)", text: $note, axis: .vertical)
                }

                Section {
                    Toggle("Position active", isOn: $isActive)
                }

                if editedAsset != nil {
                    Section {
                        Button("Supprimer cette position", role: .destructive) {
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
            .navigationTitle(editedAsset == nil ? "Nouvelle position" : "Modifier la position")
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
                "Supprimer cette position ?",
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
        pillar = asset.pillar
        institutionName = asset.institutionName
        currentValueText = "\(asset.currentValue)"
        annualContributionText = asset.annualContribution == .zero ? "" : "\(asset.annualContribution)"
        projectedText = asset.projectedValueAtRetirement.map { "\($0)" } ?? ""
        retirementAgeText = asset.retirementAge.map(String.init) ?? ""
        owner = asset.owner
        hasDocumentDate = asset.sourceDocumentDate != nil
        documentDate = asset.sourceDocumentDate ?? Date()
        note = asset.note ?? ""
        isActive = asset.isActive
    }

    private func optionalAmount(_ text: String, label: String) -> Decimal?? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .some(nil) }
        guard let parsed = FinanceFormatting.parseAmount(trimmed), parsed >= 0 else {
            errorMessage = "\(label) n'est pas un montant valide."
            return nil
        }
        return .some(FinanceMath.roundedToCents(parsed))
    }

    private func save() {
        errorMessage = nil
        let trimmedInstitution = institutionName.trimmingCharacters(in: .whitespaces)
        guard !trimmedInstitution.isEmpty else {
            errorMessage = "Indiquez l'institution."
            return
        }
        guard let current = FinanceFormatting.parseAmount(currentValueText.trimmingCharacters(in: .whitespaces)),
              current >= 0 else {
            errorMessage = "La valeur actuelle doit être un montant positif ou nul."
            return
        }
        guard let contribution = optionalAmount(annualContributionText, label: "La contribution annuelle") else { return }
        guard let projected = optionalAmount(projectedText, label: "La projection") else { return }
        var retirementAge: Int?
        let trimmedAge = retirementAgeText.trimmingCharacters(in: .whitespaces)
        if !trimmedAge.isEmpty {
            guard let age = Int(trimmedAge), (50...75).contains(age) else {
                errorMessage = "L'âge de retraite doit être entre 50 et 75 ans."
                return
            }
            retirementAge = age
        }

        let now = appContainer.dateProvider.now
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)

        if let asset = editedAsset {
            asset.pillar = pillar
            asset.institutionName = trimmedInstitution
            asset.currentValue = FinanceMath.roundedToCents(current)
            asset.annualContribution = contribution ?? .zero
            asset.projectedValueAtRetirement = projected
            asset.retirementAge = retirementAge
            asset.owner = owner
            asset.sourceDocumentDate = hasDocumentDate ? documentDate : nil
            asset.note = trimmedNote.isEmpty ? nil : trimmedNote
            asset.isActive = isActive
            asset.updatedAt = now
        } else {
            let asset = PensionAsset(
                pillar: pillar,
                institutionName: trimmedInstitution,
                currentValue: FinanceMath.roundedToCents(current),
                annualContribution: contribution ?? .zero,
                projectedValueAtRetirement: projected,
                retirementAge: retirementAge,
                sourceDocumentDate: hasDocumentDate ? documentDate : nil,
                isActive: isActive,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                createdAt: now,
                updatedAt: now,
                owner: owner
            )
            modelContext.insert(asset)
        }
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }

    private func deleteAsset() {
        guard let asset = editedAsset else { return }
        modelContext.delete(asset)
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "La suppression a échoué. Réessayez."
        }) {
            dismiss()
        }
    }
}

#Preview("Nouvelle position") {
    let preview = DemoDataFactory.previewAppContainer()
    return PensionAssetFormView(mode: .create)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
