import SwiftUI
import SwiftData

/// Fast add / edit sheet for movements, including internal transfers.
/// Validation errors are typed, French and shown next to the form.
struct TransactionFormView: View {
    enum Mode {
        case create(prefilledAccount: Account?)
        case edit(BudgetTransaction)
    }

    let mode: Mode
    /// Preselects the movement type on creation (e.g. a tax payment
    /// started from the tax module).
    var prefilledType: TransactionType? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \Account.createdAt) private var allAccounts: [Account]
    @Query(sort: \BudgetCategory.sortOrder) private var allCategories: [BudgetCategory]

    @State private var type: TransactionType = .expense
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
    /// L8 : incrémenté à chaque enregistrement RÉUSSI — déclenche un
    /// retour haptique de succès, géré par le système (réglages
    /// utilisateur respectés). Jamais décoratif.
    @State private var saveSuccessCount = 0

    /// L8 correctif : la décision d'avancer le déclencheur haptique est
    /// EXTRAITE et testée — vrai uniquement si la validation est passée
    /// ET que l'enregistrement a réellement réussi. Jamais sur refus de
    /// validation, jamais sur erreur de sauvegarde, jamais pour une
    /// navigation, une suppression ou une simple sélection.
    static func hapticTriggerAdvances(validationErrors: [TransactionValidationError], saveSucceeded: Bool) -> Bool {
        validationErrors.isEmpty && saveSucceeded
    }
    /// Parcours fréquent (pilote L4) : le clavier décimal s'ouvre sur le
    /// montant dès la création.
    @FocusState private var amountFocused: Bool
    /// L5 : suppression toujours CONFIRMÉE — jamais en un geste.
    @State private var isConfirmingDelete = false

    private var validationService: TransactionValidationService {
        TransactionValidationService(calendar: appContainer.calendar)
    }

    private var postingPolicy: TransactionPostingPolicy {
        TransactionPostingPolicy(calendar: appContainer.calendar)
    }

    private var automaticStatus: TransactionStatus {
        postingPolicy.automaticStatus(
            for: date,
            now: appContainer.dateProvider.now
        )
    }

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

    private var destinationPickerLabel: String {
        switch type {
        case .transfer: "Vers le compte"
        case .debtPayment: "Dette remboursée (facultatif)"
        default: "Vers le compte (facultatif)"
        }
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
            // Ordre du pilote Obsidian (L4, parité PWA L3) : type → montant
            // → date + statut → comptes → catégorie → détails facultatifs.
            // Le bouton Enregistrer vit dans la barre de navigation : le
            // clavier ne peut jamais le cacher.
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
                }
                .listRowBackground(NeonUltraColor.surface)

                Section("Montant") {
                    TextField("Montant (CHF)", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($amountFocused)
                        // Le montant est le champ DOMINANT de la feuille.
                        // Première version en `amount` : la capture
                        // simulateur a montré un champ impossible à
                        // distinguer des autres libellés. `formAmount`
                        // (title2) le fait ressortir sans déborder.
                        .font(NeonUltraTypography.formAmount)
                        .foregroundStyle(NeonUltraColor.textPrimary)
                }
                .listRowBackground(NeonUltraColor.surface)

                Section("Date et statut") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    LabeledContent("Statut") {
                        Text(automaticStatus.displayName)
                            .font(NeonUltraTypography.label)
                            .foregroundStyle(
                                automaticStatus == .planned
                                    ? NeonUltraColor.warning
                                    : NeonUltraColor.positive
                            )
                    }
                    Text(
                        automaticStatus == .planned
                            ? "Cette date est à venir : le mouvement restera neutre jusqu'au jour prévu."
                            : "Ce mouvement sera inclus dans vos soldes."
                    )
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                    if type == .adjustment {
                        Picker("Sens de l'ajustement", selection: $adjustmentIncreasesBalance) {
                            Text("Augmente le solde").tag(true)
                            Text("Diminue le solde").tag(false)
                        }
                    }
                }
                .listRowBackground(NeonUltraColor.surface)

                Section(type == .transfer ? "Comptes" : "Compte") {
                    Picker("Compte", selection: $account) {
                        Text("Choisir…").tag(Account?.none)
                        ForEach(selectableAccounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                    if type.supportsDestinationAccount {
                        Picker(destinationPickerLabel, selection: $destinationAccount) {
                            Text(type == .transfer ? "Choisir…" : "Aucun").tag(Account?.none)
                            ForEach(selectableDestinations) { account in
                                Text(account.name).tag(Account?.some(account))
                            }
                        }
                    }
                    flowSummary
                }
                .listRowBackground(NeonUltraColor.surface)

                if validationService.categoryRequired(for: type) {
                    Section("Catégorie") {
                        Picker("Catégorie", selection: $category) {
                            Text("Choisir…").tag(BudgetCategory?.none)
                            ForEach(relevantCategories) { category in
                                Text(category.name).tag(BudgetCategory?.some(category))
                            }
                        }
                    }
                    .listRowBackground(NeonUltraColor.surface)
                }

                Section("Détails (facultatif)") {
                    TextField("Intitulé — sinon la catégorie", text: $title)
                    TextField("Commerçant", text: $merchant)
                    TextField("Note", text: $note, axis: .vertical)
                }
                .listRowBackground(NeonUltraColor.surface)

                if !errors.isEmpty || saveErrorMessage != nil {
                    Section {
                        ForEach(errorMessages, id: \.self) { message in
                            Label(message, systemImage: "exclamationmark.circle")
                                .foregroundStyle(NeonUltraColor.negative)
                                .font(NeonUltraTypography.body)
                        }
                    }
                    .listRowBackground(NeonUltraColor.surface)
                }

                // L5 : équivalents VISIBLES des actions de liste (parité
                // web) — duplication et suppression, en édition seulement.
                if let transaction = editedTransaction {
                    Section {
                        Button {
                            duplicate(transaction)
                        } label: {
                            Label("Dupliquer (copie modifiable)", systemImage: "plus.square.on.square")
                        }
                        Button(role: .destructive) {
                            isConfirmingDelete = true
                        } label: {
                            Label("Supprimer ce mouvement", systemImage: "trash")
                                .foregroundStyle(NeonUltraColor.negative)
                        }
                    }
                    .listRowBackground(NeonUltraColor.surface)
                }
            }
            .scrollContentBackground(.hidden)
            // NU3 : feuille PILOTE — fond Neon Ultra et lignes de `Form`
            // sur la surface mate, jamais le gris système.
            .background { NeonUltraScreenBackground() }
            // Sans cette teinte, « Annuler », « Enregistrer » et tous les
            // sélecteurs héritaient de l'indigo Obsidian de `RootView` —
            // visible sur la capture NU3, et hors palette.
            .tint(NeonUltraColor.cyan)
            .navigationTitle(editedTransaction == nil ? "Nouveau mouvement" : "Modifier")
            .sensoryFeedback(.success, trigger: saveSuccessCount)
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
                "Supprimer ce mouvement ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) {
                    if let transaction = editedTransaction { delete(transaction) }
                }
            } message: {
                if let transaction = editedTransaction {
                    Text("« \(transaction.title) » — \(FinanceFormatting.chf(transaction.amount)) sera définitivement supprimé.")
                }
            }
            .onAppear(perform: populate)
        }
    }

    /// Duplication depuis la feuille : copie fidèle horodatée, enregistrée
    /// puis feuille refermée — la copie apparaît dans la liste.
    private func duplicate(_ transaction: BudgetTransaction) {
        let copy = TransactionDuplication.copy(of: transaction, now: appContainer.dateProvider.now)
        modelContext.insert(copy)
        if modelContext.saveOrRollback(onError: { _ in
            saveErrorMessage = "La duplication a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }

    private func delete(_ transaction: BudgetTransaction) {
        modelContext.delete(transaction)
        if modelContext.saveOrRollback(onError: { _ in
            saveErrorMessage = "La suppression a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }

    /// Résumé explicite d'un envoi ou d'un virement, en langage simple —
    /// même vocabulaire que le pilote PWA. Purement descriptif.
    @ViewBuilder
    private var flowSummary: some View {
        if let source = account, let destination = destinationAccount {
            if type == .transfer {
                Label(
                    "\(source.name) → \(destination.name) — neutre : ni revenu, ni dépense, votre fortune ne bouge pas.",
                    systemImage: "arrow.left.arrow.right"
                )
                .font(NeonUltraTypography.meta)
                .foregroundStyle(NeonUltraColor.textSecondary)
            } else if type == .saving || type == .investment {
                Label(
                    "\(source.name) → \(destination.name) — compté comme « mis de côté », pas comme une dépense.",
                    systemImage: "building.columns"
                )
                .font(NeonUltraTypography.meta)
                .foregroundStyle(NeonUltraColor.textSecondary)
            }
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
            if let prefilledType { type = prefilledType }
            account = prefilledAccount ?? allAccounts.first { $0.isActive && $0.type == .current } ?? allAccounts.first(where: \.isActive)
            // Parcours fréquent : clavier décimal directement sur le montant.
            amountFocused = true
        case .edit(let transaction):
            type = transaction.type
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

        // Intitulé FACULTATIF (pilote L4, parité PWA) : défaut injecté côté
        // vue — catégorie, sinon libellé du type. Le service de validation
        // reste byte-identique ; jamais de mouvement sans nom.
        let typedTitle = title.trimmingCharacters(in: .whitespaces)
        let effectiveTitle = typedTitle.isEmpty
            ? (category?.name ?? type.displayName)
            : typedTitle

        let effectiveStatus = automaticStatus
        let draft = TransactionDraft(
            date: date,
            amount: amount,
            type: type,
            status: effectiveStatus,
            title: effectiveTitle,
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
        let trimmedTitle = effectiveTitle
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespaces)

        if let transaction = editedTransaction {
            transaction.date = date
            transaction.amount = roundedAmount
            transaction.type = type
            transaction.status = effectiveStatus
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
                status: effectiveStatus,
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
        if modelContext.saveOrRollback(onError: { _ in
            saveErrorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            if Self.hapticTriggerAdvances(validationErrors: errors, saveSucceeded: true) {
                saveSuccessCount += 1
            }
            dismiss()
        }
    }
}

#Preview("Nouveau mouvement") {
    let preview = DemoDataFactory.previewAppContainer()
    return TransactionFormView(mode: .create(prefilledAccount: nil))
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Nouveau mouvement — texte agrandi") {
    let preview = DemoDataFactory.previewAppContainer()
    return TransactionFormView(mode: .create(prefilledAccount: nil))
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Nouveau mouvement — virement") {
    let preview = DemoDataFactory.previewAppContainer()
    return TransactionFormView(mode: .create(prefilledAccount: nil), prefilledType: .transfer)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
