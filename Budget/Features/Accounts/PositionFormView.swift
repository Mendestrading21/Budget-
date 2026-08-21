import SwiftUI
import SwiftData

/// INV1 (ADR-047) : créer ou modifier une position manuelle DATÉE d'un
/// compte titres. La position EXPLIQUE le solde — l'enregistrer ne change
/// ni le solde, ni la fortune, ni aucun agrégat. Le prix est celui que la
/// personne saisit à une date donnée — jamais un cours en direct.
struct PositionFormView: View {
    enum Mode {
        case create(Account)
        case edit(BrokeragePosition)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @State private var instrumentName = ""
    @State private var tickerOrISIN = ""
    @State private var quantityText = ""
    @State private var priceText = ""
    @State private var valuationDate = Date()
    @State private var costBasisText = ""
    @State private var errorMessage: String?
    @State private var isConfirmingDelete = false

    private var editedPosition: BrokeragePosition? {
        if case .edit(let position) = mode { return position }
        return nil
    }

    private var account: Account? {
        switch mode {
        case .create(let account): account
        case .edit(let position): position.account
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Position") {
                    TextField("Nom du placement (ex. Actions Monde)", text: $instrumentName)
                    TextField("Symbole ou ISIN (facultatif)", text: $tickerOrISIN)
                    TextField("Quantité", text: $quantityText)
                        .keyboardType(.decimalPad)
                    TextField("Prix par part (\(account?.currencyCode ?? "CHF"))", text: $priceText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    DatePicker("Prix saisi le", selection: $valuationDate, displayedComponents: .date)
                } footer: {
                    Text("La date de VOTRE saisie — Budget n'affiche aucun cours du marché et n'en promet pas.")
                }

                Section {
                    TextField("Prix d'achat total (facultatif)", text: $costBasisText)
                        .keyboardType(.decimalPad)
                } footer: {
                    Text("La position explique le solde du compte : l'enregistrer ne change ni le solde, ni votre fortune.")
                }

                if editedPosition != nil {
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
            .navigationTitle(editedPosition == nil ? "Nouvelle position" : "Modifier la position")
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
            .confirmationDialog(
                "Supprimer cette position ? Le solde du compte ne change pas.",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) { deletePosition() }
                Button("Annuler", role: .cancel) {}
            }
        }
    }

    private func populate() {
        guard let position = editedPosition else { return }
        instrumentName = position.instrumentName
        tickerOrISIN = position.tickerOrISIN ?? ""
        quantityText = "\(position.quantity)"
        priceText = "\(position.manualPrice)"
        valuationDate = position.valuationDate
        costBasisText = position.costBasis.map { "\($0)" } ?? ""
    }

    private func save() {
        errorMessage = nil
        let trimmedName = instrumentName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Donnez un nom à ce placement."
            return
        }
        guard let quantity = FinanceFormatting.parseAmount(quantityText.trimmingCharacters(in: .whitespaces)),
              quantity > 0 else {
            errorMessage = "Cette quantité n'est pas valable. Exemple : 100"
            return
        }
        guard let price = FinanceFormatting.parseAmount(priceText.trimmingCharacters(in: .whitespaces)),
              price >= 0 else {
            errorMessage = "Ce prix n'est pas un montant valable. Exemple : 400.00"
            return
        }
        let trimmedCost = costBasisText.trimmingCharacters(in: .whitespaces)
        var costBasis: Decimal?
        if !trimmedCost.isEmpty {
            guard let parsed = FinanceFormatting.parseAmount(trimmedCost), parsed >= 0 else {
                errorMessage = "Le prix d'achat n'est pas un montant valable."
                return
            }
            costBasis = FinanceMath.roundedToCents(parsed)
        }

        let now = appContainer.dateProvider.now
        let trimmedTicker = tickerOrISIN.trimmingCharacters(in: .whitespaces)
        if let position = editedPosition {
            position.instrumentName = trimmedName
            position.tickerOrISIN = trimmedTicker.isEmpty ? nil : trimmedTicker
            position.quantity = quantity
            position.manualPrice = FinanceMath.roundedToCents(price)
            position.valuationDate = valuationDate
            position.costBasis = costBasis
            position.updatedAt = now
        } else if case .create(let account) = mode {
            modelContext.insert(BrokeragePosition(
                instrumentName: trimmedName,
                tickerOrISIN: trimmedTicker.isEmpty ? nil : trimmedTicker,
                quantity: quantity,
                manualPrice: FinanceMath.roundedToCents(price),
                priceCurrency: account.currencyCode,
                valuationDate: valuationDate,
                costBasis: costBasis,
                createdAt: now,
                updatedAt: now,
                account: account
            ))
        }
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }

    private func deletePosition() {
        guard let position = editedPosition else { return }
        modelContext.delete(position)
        if modelContext.saveOrRollback(onError: { _ in
            errorMessage = "La suppression a échoué. Réessayez ; aucune donnée n'a été perdue."
        }) {
            dismiss()
        }
    }
}
