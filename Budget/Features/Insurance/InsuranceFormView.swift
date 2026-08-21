import SwiftUI
import SwiftData

/// Create or edit an insurance contract.
struct InsuranceFormView: View {
    enum Mode {
        case create
        case edit(InsuranceContract)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query private var households: [Household]

    private enum PremiumFrequency: String, CaseIterable, Identifiable {
        case monthly, quarterly, semiannual, annual
        var id: String { rawValue }
        var label: String {
            switch self {
            case .monthly: "Mensuelle"
            case .quarterly: "Trimestrielle"
            case .semiannual: "Semestrielle"
            case .annual: "Annuelle"
            }
        }
        var interval: (unit: RecurrenceUnit, count: Int) {
            switch self {
            case .monthly: (.month, 1)
            case .quarterly: (.month, 3)
            case .semiannual: (.month, 6)
            case .annual: (.year, 1)
            }
        }
    }

    @State private var policyName = ""
    @State private var insurerName = ""
    @State private var policyNumber = ""
    @State private var kind: InsuranceKind = .healthBase
    @State private var premiumText = ""
    @State private var frequency: PremiumFrequency = .monthly
    @State private var deductibleText = ""
    @State private var member: HouseholdMember?
    @State private var hasRenewalDate = false
    @State private var renewalDate = Date()
    @State private var hasCancellationDeadline = false
    @State private var cancellationDeadline = Date()
    @State private var coverageSummary = ""
    @State private var isActive = true
    @State private var isPickingInsurer = false
    @State private var errorMessage: String?

    private var editedContract: InsuranceContract? {
        if case .edit(let contract) = mode { return contract }
        return nil
    }

    private var members: [HouseholdMember] {
        households.first?.members ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contrat") {
                    TextField("Nom de la police (ex. LAMal 2026)", text: $policyName)
                    TextField("Assureur", text: $insurerName)
                    // P13-C (ADR-045) : choisir remplit SEULEMENT le nom de
                    // l'assureur — jamais une prime, un contrat ni une date.
                    Button {
                        isPickingInsurer = true
                    } label: {
                        Label("Choisir mon assureur", systemImage: "magnifyingglass")
                    }
                    .accessibilityIdentifier("insurance.pickInsurer")
                    TextField("N° de police (facultatif)", text: $policyNumber)
                    Picker("Type", selection: $kind) {
                        ForEach(InsuranceKind.allCases) { kind in
                            Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    if !members.isEmpty {
                        Picker("Personne assurée", selection: $member) {
                            Text("Tout le ménage").tag(HouseholdMember?.none)
                            ForEach(members) { member in
                                Text(member.firstName).tag(HouseholdMember?.some(member))
                            }
                        }
                    }
                }

                Section("Prime") {
                    TextField("Montant de la prime (CHF)", text: $premiumText)
                        .keyboardType(.decimalPad)
                    Picker("Fréquence", selection: $frequency) {
                        ForEach(PremiumFrequency.allCases) { frequency in
                            Text(frequency.label).tag(frequency)
                        }
                    }
                    TextField("Franchise (CHF, facultatif)", text: $deductibleText)
                        .keyboardType(.decimalPad)
                }

                Section("Échéances") {
                    Toggle("Renouvellement", isOn: $hasRenewalDate)
                    if hasRenewalDate {
                        DatePicker("Se renouvelle le", selection: $renewalDate, displayedComponents: .date)
                    }
                    Toggle("Délai de résiliation", isOn: $hasCancellationDeadline)
                    if hasCancellationDeadline {
                        DatePicker("Résiliable jusqu'au", selection: $cancellationDeadline, displayedComponents: .date)
                    }
                }

                Section("Couverture") {
                    TextField("Résumé de la couverture (facultatif)", text: $coverageSummary, axis: .vertical)
                }

                Section {
                    Toggle("Contrat actif", isOn: $isActive)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                    }
                }
            }
            .navigationTitle(editedContract == nil ? "Nouveau contrat" : "Modifier le contrat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                }
            }
            .onAppear(perform: populate)
            .sheet(isPresented: $isPickingInsurer) {
                IdentityServicePickerView(mode: .insurers) { entry in
                    insurerName = entry.displayName
                }
            }
        }
    }

    private func populate() {
        guard let contract = editedContract else { return }
        policyName = contract.policyName
        insurerName = contract.insurerName
        policyNumber = contract.policyNumber ?? ""
        kind = contract.kind
        premiumText = "\(contract.premiumAmount)"
        frequency = PremiumFrequency.allCases.first {
            $0.interval == (contract.premiumUnit, contract.premiumIntervalCount)
        } ?? .monthly
        deductibleText = contract.deductible.map { "\($0)" } ?? ""
        member = contract.member
        hasRenewalDate = contract.renewalDate != nil
        renewalDate = contract.renewalDate ?? Date()
        hasCancellationDeadline = contract.cancellationDeadline != nil
        cancellationDeadline = contract.cancellationDeadline ?? Date()
        coverageSummary = contract.coverageSummary ?? ""
        isActive = contract.isActive
    }

    private func save() {
        errorMessage = nil
        let trimmedPolicy = policyName.trimmingCharacters(in: .whitespaces)
        let trimmedInsurer = insurerName.trimmingCharacters(in: .whitespaces)
        guard !trimmedPolicy.isEmpty else {
            errorMessage = "Donnez un nom à cette police."
            return
        }
        guard !trimmedInsurer.isEmpty else {
            errorMessage = "Indiquez l'assureur."
            return
        }
        guard let premium = FinanceFormatting.parseAmount(premiumText.trimmingCharacters(in: .whitespaces)),
              premium > 0 else {
            errorMessage = "La prime doit être un montant supérieur à zéro. Exemple : 745.60"
            return
        }
        var deductible: Decimal?
        let trimmedDeductible = deductibleText.trimmingCharacters(in: .whitespaces)
        if !trimmedDeductible.isEmpty {
            guard let parsed = FinanceFormatting.parseAmount(trimmedDeductible), parsed >= 0 else {
                errorMessage = "La franchise n'est pas un montant valide."
                return
            }
            deductible = FinanceMath.roundedToCents(parsed)
        }

        let now = appContainer.dateProvider.now
        let interval = frequency.interval
        let trimmedNumber = policyNumber.trimmingCharacters(in: .whitespaces)
        let trimmedCoverage = coverageSummary.trimmingCharacters(in: .whitespaces)

        if let contract = editedContract {
            contract.policyName = trimmedPolicy
            contract.insurerName = trimmedInsurer
            contract.policyNumber = trimmedNumber.isEmpty ? nil : trimmedNumber
            contract.kind = kind
            contract.premiumAmount = FinanceMath.roundedToCents(premium)
            contract.premiumUnit = interval.unit
            contract.premiumIntervalCount = interval.count
            contract.deductible = deductible
            contract.member = member
            contract.renewalDate = hasRenewalDate ? renewalDate : nil
            contract.cancellationDeadline = hasCancellationDeadline ? cancellationDeadline : nil
            contract.coverageSummary = trimmedCoverage.isEmpty ? nil : trimmedCoverage
            contract.isActive = isActive
            contract.updatedAt = now
        } else {
            let contract = InsuranceContract(
                insurerName: trimmedInsurer,
                policyName: trimmedPolicy,
                policyNumber: trimmedNumber.isEmpty ? nil : trimmedNumber,
                kind: kind,
                premiumAmount: FinanceMath.roundedToCents(premium),
                premiumUnit: interval.unit,
                premiumIntervalCount: interval.count,
                deductible: deductible,
                renewalDate: hasRenewalDate ? renewalDate : nil,
                cancellationDeadline: hasCancellationDeadline ? cancellationDeadline : nil,
                coverageSummary: trimmedCoverage.isEmpty ? nil : trimmedCoverage,
                isActive: isActive,
                createdAt: now,
                updatedAt: now,
                member: member
            )
            modelContext.insert(contract)
        }
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }
}

#Preview("Nouveau contrat") {
    let preview = DemoDataFactory.previewAppContainer()
    return InsuranceFormView(mode: .create)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
