import SwiftUI
import SwiftData

/// Insurance register: contracts, household premium totals, renewal and
/// cancellation deadlines. No commercial comparison — a register, not a
/// broker.
struct InsuranceListView: View {
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \InsuranceContract.policyName) private var contracts: [InsuranceContract]

    @State private var editedContract: InsuranceContract?
    @State private var isPresentingNew = false

    private let service = InsurancePensionService()

    private var active: [InsuranceContract] { contracts.filter(\.isActive) }
    private var inactive: [InsuranceContract] { contracts.filter { !$0.isActive } }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            if contracts.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Assurances")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Label("Ajouter un contrat", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            InsuranceFormView(mode: .create)
        }
        .sheet(item: $editedContract) { contract in
            InsuranceFormView(mode: .edit(contract))
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: BudgetSpacing.medium) {
                GlassCard(style: .hero) {
                    VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                        Text("Primes du ménage")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: BudgetSpacing.micro) {
                            AmountText(amount: service.totalAnnualPremium(contracts: contracts), role: .hero)
                            Text("par an")
                                .font(BudgetFont.cardLabel)
                                .foregroundStyle(.secondary)
                        }
                        Text("Soit \(FinanceFormatting.chf(service.totalMonthlyPremium(contracts: contracts))) par mois · \(active.count) contrat(s) actif(s)")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Primes du ménage : \(FinanceFormatting.chf(service.totalAnnualPremium(contracts: contracts))) par an")
                }

                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    ForEach(active) { contract in
                        InsuranceRow(
                            contract: contract,
                            monthly: service.monthlyPremium(of: contract),
                            now: appContainer.dateProvider.now
                        )
                        .onTapGesture { editedContract = contract }
                    }
                }

                if !inactive.isEmpty {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text("Résiliés")
                            .font(BudgetFont.sectionTitle)
                            .foregroundStyle(.secondary)
                        ForEach(inactive) { contract in
                            InsuranceRow(contract: contract, monthly: service.monthlyPremium(of: contract), now: appContainer.dateProvider.now)
                                .opacity(0.55)
                                .onTapGesture { editedContract = contract }
                        }
                    }
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }

    private var emptyState: some View {
        ScrollView {
            GlassCard {
                EmptyState(
                    symbol: "shield",
                    title: "Aucun contrat",
                    message: "LAMal, RC, ménage, véhicule… Regroupez vos contrats pour voir la prime annuelle totale et ne plus rater un délai de résiliation.",
                    actionTitle: "Ajouter un contrat",
                    action: { isPresentingNew = true }
                )
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }
}

struct InsuranceRow: View {
    let contract: InsuranceContract
    let monthly: Decimal
    let now: Date

    private var deadlineIsClose: Bool {
        guard contract.isActive, let deadline = contract.cancellationDeadline else { return false }
        return deadline >= now && deadline.timeIntervalSince(now) < 60 * 86_400
    }

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: contract.kind.systemImage)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contract.policyName)
                        .font(BudgetFont.body.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(contract.insurerName) · \(contract.kind.displayName)\(contract.member.map { " · \($0.firstName)" } ?? "")")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let deductible = contract.deductible {
                        Text("Franchise \(FinanceFormatting.chf(deductible))")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    if deadlineIsClose, let deadline = contract.cancellationDeadline {
                        Label("Résiliable jusqu'au \(FinanceFormatting.swissDate(deadline))", systemImage: "exclamationmark.triangle.fill")
                            .font(BudgetFont.caption.weight(.semibold))
                            .foregroundStyle(BudgetColor.warning)
                    }
                }
                Spacer(minLength: BudgetSpacing.small)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(FinanceFormatting.chf(contract.premiumAmount))
                        .font(BudgetFont.amount)
                        .fixedSize()
                    Text(contract.frequencyLabel)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                    if contract.premiumUnit != .month || contract.premiumIntervalCount != 1 {
                        Text("≈ \(FinanceFormatting.chf(monthly)) / mois")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contract.policyName), \(contract.insurerName), \(FinanceFormatting.chf(contract.premiumAmount)) \(contract.frequencyLabel)\(deadlineIsClose ? ", résiliable prochainement" : "")")
    }
}

#Preview("Assurances") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        InsuranceListView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
