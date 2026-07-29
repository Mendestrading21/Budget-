import SwiftUI
import SwiftData

/// One clear place for everything that comes back automatically:
/// rent, insurance, subscriptions, salaries and regular savings.
struct RecurringListView: View {
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \RecurringTransaction.title)
    private var recurrings: [RecurringTransaction]

    @State private var editedRecurring: RecurringTransaction?
    @State private var isPresentingNew = false

    private var scheduleService: RecurringScheduleService {
        RecurringScheduleService(calendar: appContainer.calendar)
    }

    private var activeBills: [RecurringTransaction] {
        recurrings.filter { $0.isActive && $0.type != .income }
    }

    private var activeIncome: [RecurringTransaction] {
        recurrings.filter { $0.isActive && $0.type == .income }
    }

    private var inactive: [RecurringTransaction] {
        recurrings.filter { !$0.isActive }
    }

    private var monthlyBillsTotal: Decimal {
        activeBills.reduce(.zero) {
            $0 + scheduleService.monthlyEquivalent(of: $1)
        }
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()

            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    summaryCard

                    if recurrings.isEmpty {
                        emptyState
                    } else {
                        billSection
                        incomeSection
                        inactiveSection
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            }
            .obsidianFABClearance()
        }
        .navigationTitle("Factures mensuelles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ajouter une facture mensuelle")
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            RecurringFormView(mode: .create)
        }
        .sheet(item: $editedRecurring) { recurring in
            RecurringFormView(mode: .edit(recurring))
        }
    }

    private var summaryCard: some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("À prévoir chaque mois")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)

                AmountText(amount: monthlyBillsTotal, role: .hero)

                Text("Vos factures reviennent automatiquement. Sur l’accueil, marquez-les comme payées en un geste.")
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)

                Button {
                    isPresentingNew = true
                } label: {
                    Label("Ajouter une facture", systemImage: "plus")
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder
    private var billSection: some View {
        if !activeBills.isEmpty {
            sectionTitle("Mes factures", count: activeBills.count)
            ForEach(activeBills) { recurring in
                simpleRow(recurring)
            }
        }
    }

    @ViewBuilder
    private var incomeSection: some View {
        if !activeIncome.isEmpty {
            sectionTitle("Mes revenus réguliers", count: activeIncome.count)
            ForEach(activeIncome) { recurring in
                simpleRow(recurring)
            }
        }
    }

    @ViewBuilder
    private var inactiveSection: some View {
        if !inactive.isEmpty {
            DisclosureGroup("Désactivés (\(inactive.count))") {
                VStack(spacing: BudgetSpacing.small) {
                    ForEach(inactive) { recurring in
                        simpleRow(recurring)
                    }
                }
                .padding(.top, BudgetSpacing.small)
            }
            .font(BudgetFont.body.weight(.semibold))
            .tint(BudgetColor.brandBright)
        }
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(BudgetFont.sectionTitle)
            Spacer()
            Text("\(count)")
                .font(BudgetFont.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func simpleRow(_ recurring: RecurringTransaction) -> some View {
        Button {
            editedRecurring = recurring
        } label: {
            GlassCard(style: .row) {
                HStack(spacing: BudgetSpacing.medium) {
                    Image(systemName: recurring.type == .income ? "arrow.down.circle" : "calendar")
                        .foregroundStyle(
                            recurring.type == .income
                                ? BudgetColor.positive
                                : BudgetColor.warning
                        )
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(recurring.title)
                            .font(BudgetFont.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(rowSubtitle(recurring))
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: BudgetSpacing.small)

                    Text(FinanceFormatting.chf(recurring.amount))
                        .font(BudgetFont.amount)
                        .foregroundStyle(
                            recurring.type == .income
                                ? BudgetColor.positive
                                : .primary
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(recurring.isActive ? 1 : 0.55)
        .accessibilityLabel(rowAccessibility(recurring))
        .accessibilityHint("Touchez deux fois pour modifier")
        .accessibilityIdentifier("recurring.row.\(recurring.title)")
    }

    private func rowSubtitle(_ recurring: RecurringTransaction) -> String {
        var parts: [String] = [recurring.frequencyLabel]

        if let next = scheduleService.nextOccurrence(
            of: recurring,
            onOrAfter: appContainer.dateProvider.now
        ), recurring.isActive {
            parts.append("prochaine le \(FinanceFormatting.swissDate(next))")
        }

        if !recurring.isActive {
            parts.append("désactivée")
        }

        return parts.joined(separator: " · ")
    }

    private func rowAccessibility(_ recurring: RecurringTransaction) -> String {
        "\(recurring.title), \(FinanceFormatting.chf(recurring.amount)), \(rowSubtitle(recurring))"
    }

    private var emptyState: some View {
        GlassCard {
            EmptyState(
                symbol: "calendar.badge.plus",
                title: "Ajoutez vos factures mensuelles",
                message: "Loyer, caisse maladie, téléphone, abonnements : ajoutez-les une seule fois. Elles reviendront ensuite automatiquement chaque mois.",
                actionTitle: "Ajouter ma première facture",
                action: { isPresentingNew = true }
            )
        }
    }
}

#Preview("Factures mensuelles") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        RecurringListView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
