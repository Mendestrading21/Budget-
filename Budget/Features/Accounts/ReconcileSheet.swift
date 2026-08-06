import SwiftUI
import SwiftData

/// Explicit, timestamped manual reconciliation: the user asserts the real
/// balance of the account today; later movements build on top of it.
struct ReconcileSheet: View {
    let account: Account

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @State private var balanceText: String = ""
    @State private var errorMessage: String?

    private var computedBalance: Decimal {
        appContainer.balanceService.balance(of: account)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Solde calculé") {
                        Text(FinanceFormatting.chf(computedBalance))
                    }
                    TextField("Solde réel constaté (CHF)", text: $balanceText)
                        .keyboardType(.decimalPad)
                } footer: {
                    Text("Indiquez le solde que votre banque affiche aujourd'hui. Il devient votre nouveau point de départ, à cette date : vos mouvements suivants s'y ajoutent.")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                    }
                }
            }
            .navigationTitle("Réconcilier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") { reconcile() }
                }
            }
        }
    }

    private func reconcile() {
        errorMessage = nil
        guard let parsed = FinanceFormatting.parseAmount(balanceText.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Le solde saisi n'est pas un montant valide. Exemple : 2'500.00"
            return
        }
        account.reconciledBalance = FinanceMath.roundedToCents(parsed)
        account.reconciledAt = appContainer.dateProvider.now
        account.updatedAt = account.reconciledAt ?? Date()
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "L'enregistrement a échoué. Réessayez."
        }) {
            dismiss()
        }
    }
}
