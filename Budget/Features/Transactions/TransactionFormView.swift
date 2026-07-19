import SwiftUI
import SwiftData

/// Fast add / edit sheet for movements, including internal transfers.
/// Validation errors are typed, French and shown next to the form.
struct TransactionFormView: View {
    enum Mode {
        case create(prefilledAccount: Account?)
        case edit(BudgetTransaction)

        static var create: Mode { .create(prefilledAccount: nil) }
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \Account.createdAt) private var allAccounts: [Account]
    @Query(sort: \BudgetCategory.sortOrder) private var allCategories: [BudgetCategory]

    @State private var type: TransactionType = .expense
    @State private var status: TransactionStatus = .posted
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var account: Account?
    @State private var destinationAccount: Account?
    @State private var category: BudgetCategory?
    @State private var note: String = ""
    @State private var merchant: String = ""
    @State private var adjustmentIncreasesBalance = true
    @State private var errors: [TransactionValidationError] = []
    @State private var saveErrorMessage: String?

    private let validationService = TransactionValidationService()

    private var editedTransaction: BudgetTransaction? {
        if case .edit(let transaction) = mode { return transaction }
        return nil
    }

    private var selectableAccounts: [Account] {
        allAccounts.filter { $0.isActive || $0.id == editedTransaction?.account?.id }
    }

    private var selectableDestinations: [Account] {
        allAccounts.filter { ($0.isActive || $0.id == editedTransaction?.destinationAccount?.id) && $0.id != account?.id }
    }

    private var relevantCategories: [BudgetCategory] {
        let kinds: [CategoryKind] = switch type {
        case .income: [.income]
        case .expense, .debtPayment: [.expense]
        case .refund: [.expense, .income]
        case .saving: [.saving]
        case .investment: [.investment]
        case .taxPayment: [.tax]
        case .transfer, .adjustment: []
        }
        return allCategories.filter { $0.isActive && kinds.contains($0.kind) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { type in
                            Label(type.displayName, systemImage: type.systemImage).tag(type)
                        }
                    }
                    .onChange(of: type) { _, _ in
                        category = nil
                        if !type.supportsDestinationAccount { destinationAccount = nil }
                    }
                    Picker("Statut", selection: $status) {
                        ForEach(TransactionStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Détails") {
                    TextField("Intitulé", text: $title)
                    TextField("Montant (CHF)", text: $amountText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    if type == .adjustment {
                        Picker("Sens de l'ajustement", selection: $adjustmentIncreasesBalance) {
                            Text("Augmente le solde").tag(true)
                            Text("Diminue le solde").tag(false)
                        }
                    }
                }

                Section(type == .transfer ? "Comptes" : "Compte") {
                    Picker("Compte", selection: $account) {
                        Text("Choisir…").tag(Account?.none)
                        ForEach(selectableAccounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                    if type.supportsDestinationAccount {
                        Picker(type == .transfer ? "Vers le compte" : "Vers le compte (facultatif)", selection: $destinationAccount) {
                            Text(type == .transfer ? "Choisir…" : "Aucun").tag(Account?.none)
                            ForEach(selectableDestinations) { account in
                                Text(account.name).tag(Account?.some(account))
                            }
                        }
                    }
                }

                if validationService.categoryRequired(for: type) {
                    Section("Catégorie") {
                        Picker("Catégorie", selection: $category) {
                            Text("Choisir…").tag(BudgetCategory?.none)
                            ForEach(relevantCategories) { category in
                                Text(category.name).tag(BudgetCategory?.some(category))
                            }
                        }
                    }
                }

                Section("Facultatif") {
                    TextField("Commerçant", text: $merchant)
                    TextField("Note", text: $note, axis: .vertical)
                }

                if !errors.isEmpty || saveErrorMessage != nil {
                    Section {
                        ForEach(errorMessages, id: \.self) { message in
                            Label(message, systemImage: "exclamationmark.circle")
                                .foregroundStyle(BudgetColor.negative)
                                .font(BudgetFont.body)
                        }
                    }
                }
            }
            .navigationTitle(editedTransaction == nil ? "Nouveau mouvement" : "Modifier")
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

    private var errorMessages: [String] {
        var messages = errors.compactMap(\.errorDescription)
        if let saveErrorMessage { messages.append(saveErrorMessage) }
        return messages
    }

    private func populate() {
        switch mode {
        case .create(let prefilledAccount):
            date = appContainer.dateProvider.now
            account = prefilledAccount ?? allAccounts.first { $0.isActive && $0.type == .current } ?? allAccounts.first(where: \.isActive)
        case .edit(let transaction):
            type = transaction.type
            status = transaction.status
            title = transaction.title
            amountText = "\(transaction.amount)"
            date = transaction.date
            account = transaction.account
            destinationAccount = transaction.destinationAccount
            category = transaction.category
            note = transaction.note ?? ""
            merchant = transaction.merchant ?? ""
            adjustmentIncreasesBalance = transaction.adjustmentIncreasesBalance
        }
    }

    private func save() {
        saveErrorMessage = nil
        let amount = FinanceFormatting.parseAmount(amountText.trimmingCharacters(in: .whitespaces))

        let draft = TransactionDraft(
            date: date,
            amount: amount,
            type: type,
            status: status,
            title: title,
            account: account,
            destinationAccount: type.supportsDestinationAccount ? destinationAccount : nil,
            category: validationService.categoryRequired(for: type) ? category : nil,
            adjustmentIncreasesBalance: adjustmentIncreasesBalance
        )
        errors = validationService.validate(
            draft,
            now: appContainer.dateProvider.now,
            allowInactiveAccounts: editedTransaction != nil
        )
        guard errors.isEmpty, let amount else { return }

        let now = appContainer.dateProvider.now
        let roundedAmount = FinanceMath.roundedToCents(amount)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespaces)

        do {
            if let transaction = editedTransaction {
                transaction.date = date
                transaction.amount = roundedAmount
                transaction.type = type
                transaction.status = status
                transaction.title = trimmedTitle
                transaction.note = trimmedNote.isEmpty ? nil : trimmedNote
                transaction.merchant = trimmedMerchant.isEmpty ? nil : trimmedMerchant
                transaction.adjustmentIncreasesBalance = adjustmentIncreasesBalance
                transaction.account = account
                transaction.destinationAccount = draft.destinationAccount
                transaction.category = draft.category
                transaction.updatedAt = now
            } else {
                let transaction = BudgetTransaction(
                    date: date,
                    amount: roundedAmount,
                    type: type,
                    status: status,
                    title: trimmedTitle,
                    note: trimmedNote.isEmpty ? nil : trimmedNote,
                    merchant: trimmedMerchant.isEmpty ? nil : trimmedMerchant,
                    adjustmentIncreasesBalance: adjustmentIncreasesBalance,
                    createdAt: now,
                    updatedAt: now,
                    account: account,
                    destinationAccount: draft.destinationAccount,
                    category: draft.category
                )
                modelContext.insert(transaction)
            }
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }
}

#Preview("Nouveau mouvement") {
    let preview = DemoDataFactory.previewAppContainer()
    return TransactionFormView(mode: .create)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
