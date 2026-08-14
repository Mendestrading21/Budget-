import SwiftUI
import SwiftData

/// Les quatre réponses compréhensibles proposées pour une opération qui
/// revient. Le type comptable correspondant reste celui des modèles existants.
enum RecurringEntryKind: String, CaseIterable, Identifiable {
    case bill
    case subscription
    case income
    case setAside

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bill: "Facture"
        case .subscription: "Abonnement"
        case .income: "Revenu"
        case .setAside: "Mise de côté"
        }
    }

    var systemImage: String {
        switch self {
        case .bill: "doc.text"
        case .subscription: "repeat"
        case .income: "arrow.down.circle"
        case .setAside: "building.columns"
        }
    }

    var defaultTransactionType: TransactionType {
        switch self {
        case .bill, .subscription: .expense
        case .income: .income
        case .setAside: .saving
        }
    }

    var marksSubscription: Bool { self == .subscription }
}

/// Création ou modification d'une facture, d'un revenu ou d'un versement qui
/// revient. Les quatre champs indispensables sont visibles immédiatement ; les
/// réglages rares sont rangés dans « Options avancées ».
struct RecurringFormView: View {
    enum Mode {
        case create
        case edit(RecurringTransaction)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \Account.createdAt) private var allAccounts: [Account]
    @Query(sort: \BudgetCategory.sortOrder) private var allCategories: [BudgetCategory]

    private enum FrequencyChoice: String, CaseIterable, Identifiable {
        case weekly, monthly, quarterly, semiannual, annual, custom
        var id: String { rawValue }
        var label: String {
            switch self {
            case .weekly: "Chaque semaine"
            case .monthly: "Chaque mois"
            case .quarterly: "Tous les 3 mois"
            case .semiannual: "Tous les 6 mois"
            case .annual: "Chaque année"
            case .custom: "Autre rythme"
            }
        }
    }

    @State private var title = ""
    @State private var amountText = ""
    @State private var kind: RecurringEntryKind = .bill
    @State private var type: TransactionType = .expense
    @State private var frequency: FrequencyChoice = .monthly
    @State private var customUnit: RecurrenceUnit = .month
    @State private var customCount = 2
    @State private var firstOccurrence = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var account: Account?
    @State private var destinationAccount: Account?
    @State private var category: BudgetCategory?
    @State private var isSubscription = false
    @State private var isProfessional = false
    @State private var isActive = true
    @State private var hasRenewalDate = false
    @State private var renewalDate = Date()
    @State private var hasCancellationDeadline = false
    @State private var cancellationDeadline = Date()
    @State private var showsAdvancedOptions = false
    @State private var errorMessage: String?

    private let validationService = TransactionValidationService()

    private var editedRecurring: RecurringTransaction? {
        if case .edit(let recurring) = mode { return recurring }
        return nil
    }

    private var selectableAccounts: [Account] {
        allAccounts.filter { $0.isActive || $0.id == editedRecurring?.account?.id }
    }

    private var selectableDestinations: [Account] {
        allAccounts.filter { $0.isActive && $0.id != account?.id }
    }

    /// Mise de côté et investissement doivent arriver quelque part ; le
    /// remboursement de dette garde une destination facultative.
    private var destinationRequired: Bool {
        type == .saving || type == .investment
    }

    private var destinationPickerLabel: String {
        destinationRequired ? "Vers quel compte" : "Dette remboursée (facultatif)"
    }

    private var relevantCategories: [BudgetCategory] {
        let kinds: [CategoryKind] = switch type {
        case .income: [.income]
        case .expense, .debtPayment: [.expense]
        case .saving: [.saving]
        case .investment: [.investment]
        case .taxPayment: [.tax]
        default: []
        }
        return allCategories.filter { $0.isActive && kinds.contains($0.kind) }
    }

    private var resolvedInterval: (unit: RecurrenceUnit, count: Int) {
        switch frequency {
        case .weekly: (.week, 1)
        case .monthly: (.month, 1)
        case .quarterly: (.month, 3)
        case .semiannual: (.month, 6)
        case .annual: (.year, 1)
        case .custom: (customUnit, max(1, customCount))
        }
    }

    /// Les effets de changement ne partent que d'un choix explicite dans le
    /// formulaire. `populate()` écrit directement les états afin que
    /// l'ouverture d'une ligne existante ne réinitialise aucune donnée.
    private var kindSelection: Binding<RecurringEntryKind> {
        Binding(
            get: { kind },
            set: { apply($0) }
        )
    }

    private var setAsideTypeSelection: Binding<TransactionType> {
        Binding(
            get: { type },
            set: { newType in
                type = newType
                category = nil
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("L'essentiel") {
                    Picker("C'est quoi ?", selection: kindSelection) {
                        ForEach(RecurringEntryKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.systemImage).tag(kind)
                        }
                    }

                    TextField("Nom — par exemple Loyer", text: $title)
                    TextField("Montant en CHF", text: $amountText)
                        .keyboardType(.decimalPad)

                    DatePicker(
                        "Prochaine date",
                        selection: $firstOccurrence,
                        displayedComponents: .date
                    )

                    if kind == .setAside {
                        Picker("Je mets sur", selection: setAsideTypeSelection) {
                            Label("Épargne", systemImage: TransactionType.saving.systemImage)
                                .tag(TransactionType.saving)
                            Label("Placement ou 3e pilier", systemImage: TransactionType.investment.systemImage)
                                .tag(TransactionType.investment)
                        }
                    }
                }

                Section("Où va l'argent ?") {
                    Picker("Compte utilisé", selection: $account) {
                        Text("Choisir un compte").tag(Account?.none)
                        ForEach(selectableAccounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }

                    if type.supportsDestinationAccount {
                        Picker(destinationPickerLabel, selection: $destinationAccount) {
                            Text(destinationRequired ? "Choisir…" : "Aucun").tag(Account?.none)
                            ForEach(selectableDestinations) { account in
                                Text(account.name).tag(Account?.some(account))
                            }
                        }
                    }

                    Picker("Catégorie", selection: $category) {
                        Text("Choisir une catégorie").tag(BudgetCategory?.none)
                        ForEach(relevantCategories) { category in
                            Text(category.name).tag(BudgetCategory?.some(category))
                        }
                    }
                }

                Section {
                    DisclosureGroup("Options avancées", isExpanded: $showsAdvancedOptions) {
                        Picker("Revient", selection: $frequency) {
                            ForEach(FrequencyChoice.allCases) { choice in
                                Text(choice.label).tag(choice)
                            }
                        }
                        .onChange(of: frequency) { _, newFrequency in
                            // Un rythme personnalisé ne doit jamais utiliser
                            // des valeurs cachées que la personne n'a pas vues.
                            if newFrequency == .custom {
                                showsAdvancedOptions = true
                            }
                        }

                        if frequency == .custom {
                            Stepper("Tous les \(customCount)", value: $customCount, in: 1...36)
                            Picker("Période", selection: $customUnit) {
                                Text("semaines").tag(RecurrenceUnit.week)
                                Text("mois").tag(RecurrenceUnit.month)
                                Text("ans").tag(RecurrenceUnit.year)
                            }
                            .pickerStyle(.segmented)
                        }

                        Toggle("Prévoir une date de fin", isOn: $hasEndDate)
                        if hasEndDate {
                            DatePicker("Se termine le", selection: $endDate, displayedComponents: .date)
                        }

                        if isSubscription {
                            Toggle("Date de renouvellement", isOn: $hasRenewalDate)
                            if hasRenewalDate {
                                DatePicker("Renouvellement", selection: $renewalDate, displayedComponents: .date)
                            }
                            Toggle("Date limite de résiliation", isOn: $hasCancellationDeadline)
                            if hasCancellationDeadline {
                                DatePicker("Résiliable jusqu'au", selection: $cancellationDeadline, displayedComponents: .date)
                            }
                        }

                        Toggle("Dépense professionnelle", isOn: $isProfessional)
                        Toggle("Actif", isOn: $isActive)
                    }
                } footer: {
                    Text("Chaque mois et le compte courant sont déjà prêts. Ouvrez seulement si vous voulez changer le rythme ou une date.")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                    }
                }
            }
            .navigationTitle(editedRecurring == nil ? "Ajouter ce qui revient" : "Modifier ce qui revient")
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
        }
    }

    private func populate() {
        if let recurring = editedRecurring {
            title = recurring.title
            amountText = "\(recurring.amount)"
            type = recurring.type
            switch recurring.type {
            case .income, .refund:
                kind = .income
            case .saving, .investment:
                kind = .setAside
            default:
                kind = recurring.isSubscription ? .subscription : .bill
            }
            switch (recurring.intervalUnit, recurring.intervalCount) {
            case (.week, 1): frequency = .weekly
            case (.month, 1): frequency = .monthly
            case (.month, 3): frequency = .quarterly
            case (.month, 6): frequency = .semiannual
            case (.year, 1): frequency = .annual
            default:
                frequency = .custom
                customUnit = recurring.intervalUnit
                customCount = recurring.intervalCount
            }
            firstOccurrence = recurring.firstOccurrence
            hasEndDate = recurring.endDate != nil
            endDate = recurring.endDate ?? Date()
            account = recurring.account
            destinationAccount = recurring.destinationAccount
            category = recurring.category
            isSubscription = recurring.isSubscription
            isProfessional = recurring.isProfessional
            isActive = recurring.isActive
            hasRenewalDate = recurring.renewalDate != nil
            renewalDate = recurring.renewalDate ?? Date()
            hasCancellationDeadline = recurring.cancellationDeadline != nil
            cancellationDeadline = recurring.cancellationDeadline ?? Date()
        } else {
            firstOccurrence = appContainer.dateProvider.now
            account = allAccounts.first { $0.isActive && $0.type == .current }
                ?? allAccounts.first(where: \.isActive)
        }
    }

    private func apply(_ newKind: RecurringEntryKind) {
        kind = newKind
        if newKind == .setAside, (type == .saving || type == .investment) {
            // Conserver le choix Épargne/Placement déjà fait.
        } else {
            type = newKind.defaultTransactionType
        }
        isSubscription = newKind.marksSubscription
        category = nil
        if !type.supportsDestinationAccount { destinationAccount = nil }
    }

    private func save() {
        errorMessage = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Donnez un nom à cette transaction."
            return
        }
        guard let parsed = FinanceFormatting.parseAmount(amountText.trimmingCharacters(in: .whitespaces)),
              parsed > 0 else {
            errorMessage = "Indiquez un montant supérieur à zéro. Exemple : 2'150.00"
            return
        }
        guard account != nil else {
            errorMessage = "Choisissez le compte utilisé."
            return
        }
        if validationService.categoryRequired(for: type) && category == nil {
            errorMessage = "Choisissez une catégorie."
            return
        }
        // Une ligne mensuelle « mise de côté » DOIT arriver quelque part :
        // sinon chaque mois l'argent quitte le compte sans atterrir, et le
        // patrimoine baisse du montant réservé. Même règle que le web.
        if type == .saving || type == .investment {
            guard let destination = destinationAccount else {
                errorMessage = "Choisissez le compte qui reçoit cet argent. Mis de côté, il reste à vous."
                return
            }
            guard destination.id != account?.id else {
                errorMessage = "Le compte qui reçoit doit être différent du compte de départ."
                return
            }
        }
        if hasEndDate && endDate <= firstOccurrence {
            errorMessage = "La date de fin doit être après la prochaine date."
            return
        }

        let amount = FinanceMath.roundedToCents(parsed)
        let interval = resolvedInterval
        let now = appContainer.dateProvider.now

        if let recurring = editedRecurring {
            recurring.title = trimmedTitle
            recurring.amount = amount
            recurring.type = type
            recurring.intervalUnit = interval.unit
            recurring.intervalCount = interval.count
            recurring.firstOccurrence = firstOccurrence
            recurring.endDate = hasEndDate ? endDate : nil
            recurring.account = account
            recurring.destinationAccount = type.supportsDestinationAccount ? destinationAccount : nil
            recurring.category = category
            recurring.isSubscription = isSubscription
            recurring.isProfessional = isProfessional
            recurring.isActive = isActive
            recurring.renewalDate = (isSubscription && hasRenewalDate) ? renewalDate : nil
            recurring.cancellationDeadline = (isSubscription && hasCancellationDeadline) ? cancellationDeadline : nil
            recurring.updatedAt = now
        } else {
            let recurring = RecurringTransaction(
                title: trimmedTitle,
                amount: amount,
                type: type,
                intervalUnit: interval.unit,
                intervalCount: interval.count,
                firstOccurrence: firstOccurrence,
                endDate: hasEndDate ? endDate : nil,
                isActive: isActive,
                isProfessional: isProfessional,
                isSubscription: isSubscription,
                renewalDate: (isSubscription && hasRenewalDate) ? renewalDate : nil,
                cancellationDeadline: (isSubscription && hasCancellationDeadline) ? cancellationDeadline : nil,
                createdAt: now,
                updatedAt: now,
                account: account,
                destinationAccount: type.supportsDestinationAccount ? destinationAccount : nil,
                category: category
            )
            modelContext.insert(recurring)
        }
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }
}

#Preview("Ajouter ce qui revient") {
    let preview = DemoDataFactory.previewAppContainer()
    return RecurringFormView(mode: .create)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
