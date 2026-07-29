import SwiftUI
import SwiftData

/// Create or edit an account. Editing never rewrites history: the opening
/// balance stays editable only while the account has no movements.
struct AccountFormView: View {
    enum Mode {
        case create
        case edit(Account)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @State private var name: String = ""
    @State private var institutionName: String = ""
    @State private var type: AccountType = .current
    @State private var openingBalanceText: String = ""
    @State private var isShared = false
    @State private var includeInAvailableCash = true
    @State private var includeInNetWorth = true
    @State private var errorMessage: String?

    private var editedAccount: Account? {
        if case .edit(let account) = mode { return account }
        return nil
    }

    private var hasMovements: Bool {
        guard let account = editedAccount else { return false }
        return !account.transactions.isEmpty || !account.incomingMovements.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Compte") {
                    TextField("Nom", text: $name)
                    TextField("Établissement (facultatif)", text: $institutionName)
                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .onChange(of: type) { _, newType in
                        if editedAccount == nil {
                            includeInAvailableCash = newType.defaultIncludeInAvailableCash
                        }
                    }
                }

                Section {
                    TextField("0.00", text: $openingBalanceText)
                        .keyboardType(.decimalPad)
                        .disabled(hasMovements)
                } header: {
                    Text("Solde initial (CHF)")
                } footer: {
                    if hasMovements {
                        Text("Ce compte a des mouvements : utilisez la réconciliation depuis le détail du compte plutôt que de modifier le solde initial.")
                    }
                }

                Section("Options") {
                    Toggle("Compte partagé du ménage", isOn: $isShared)
                    Toggle("Compte dans le cash disponible", isOn: $includeInAvailableCash)
                    Toggle("Compte dans le patrimoine", isOn: $includeInNetWorth)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                    }
                }
            }
            .navigationTitle(editedAccount == nil ? "Nouveau compte" : "Modifier le compte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                }
            }
            .onAppear(perform: populateFromAccount)
        }
    }

    private func populateFromAccount() {
        guard let account = editedAccount else { return }
        name = account.name
        institutionName = account.institutionName
        type = account.type
        openingBalanceText = "\(account.openingBalance)"
        isShared = account.isShared
        includeInAvailableCash = account.includeInAvailableCash
        includeInNetWorth = account.includeInNetWorth
    }

    private func save() {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Donnez un nom à ce compte."
            return
        }
        let trimmedBalance = openingBalanceText.trimmingCharacters(in: .whitespaces)
        let openingBalance: Decimal
        if trimmedBalance.isEmpty {
            openingBalance = .zero
        } else if let parsed = FinanceFormatting.parseAmount(trimmedBalance) {
            openingBalance = FinanceMath.roundedToCents(parsed)
        } else {
            errorMessage = "Le solde initial n'est pas un montant valide. Exemple : 2'500.00"
            return
        }

        let now = appContainer.dateProvider.now
        if let account = editedAccount {
            account.name = trimmedName
            account.institutionName = institutionName.trimmingCharacters(in: .whitespaces)
            account.type = type
            if !hasMovements {
                account.openingBalance = openingBalance
            }
            account.isShared = isShared
            account.includeInAvailableCash = includeInAvailableCash
            account.includeInNetWorth = includeInNetWorth
            account.updatedAt = now
        } else {
            let account = Account(
                name: trimmedName,
                institutionName: institutionName.trimmingCharacters(in: .whitespaces),
                type: type,
                openingBalance: openingBalance,
                isShared: isShared,
                includeInAvailableCash: includeInAvailableCash,
                includeInNetWorth: includeInNetWorth,
                createdAt: now,
                updatedAt: now
            )
            modelContext.insert(account)
        }
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }
}

#Preview("Nouveau compte") {
    let preview = DemoDataFactory.previewAppContainer()
    return AccountFormView(mode: .create)
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
