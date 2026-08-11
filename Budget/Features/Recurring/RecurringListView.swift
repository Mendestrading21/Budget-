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
        }
        .navigationTitle("Transactions mensuelles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ajouter une transaction mensuelle")
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
                row(recurring)
            }
        }
    }

    @ViewBuilder
    private var incomeSection: some View {
        if !activeIncome.isEmpty {
            sectionTitle("Mes revenus réguliers", count: activeIncome.count)
            ForEach(activeIncome) { recurring in
                row(recurring)
            }
        }
    }

    @ViewBuilder
    private var inactiveSection: some View {
        if !inactive.isEmpty {
            DisclosureGroup("Désactivés (\(inactive.count))") {
                VStack(spacing: BudgetSpacing.small) {
                    ForEach(inactive) { recurring in
                        row(recurring)
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

    private func row(_ recurring: RecurringTransaction) -> some View {
        Button {
            editedRecurring = recurring
        } label: {
            RecurringRow(
                recurring: recurring,
                monthlyEquivalent: scheduleService.monthlyEquivalent(of: recurring),
                nextDate: scheduleService.nextOccurrence(
                    of: recurring,
                    onOrAfter: appContainer.dateProvider.now
                ),
                now: appContainer.dateProvider.now
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Touchez deux fois pour modifier")
        .accessibilityIdentifier("recurring.row.\(recurring.title)")
    }

    private var emptyState: some View {
        GlassCard {
            EmptyState(
                symbol: "calendar.badge.plus",
                title: "Ajoutez vos transactions mensuelles",
                message: "Loyer, caisse maladie, téléphone, abonnements : ajoutez-les une seule fois. Elles reviendront ensuite automatiquement chaque mois.",
                actionTitle: "Ajouter ma première facture",
                action: { isPresentingNew = true }
            )
        }
    }
}

/// Ligne réutilisable et testable. Les intitulés longs passent à la ligne au
/// lieu d’être coupés, tandis que le montant reste lisible sur petit écran.
struct RecurringRow: View {
    let recurring: RecurringTransaction
    let monthlyEquivalent: Decimal
    let nextDate: Date?
    let now: Date

    var body: some View {
        GlassCard(style: .row) {
            HStack(alignment: .top, spacing: BudgetSpacing.medium) {
                Image(systemName: recurring.type == .income ? "arrow.down.circle" : "calendar")
                    .foregroundStyle(recurring.type == .income ? BudgetColor.positive : BudgetColor.warning)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(recurring.title)
                        .font(BudgetFont.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: BudgetSpacing.small)

                Text(FinanceFormatting.chf(recurring.amount))
                    .font(BudgetFont.amount)
                    .foregroundStyle(recurring.type == .income ? BudgetColor.positive : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .layoutPriority(1)
            }
        }
        .opacity(recurring.isActive ? 1 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recurring.title), \(FinanceFormatting.chf(recurring.amount)), \(subtitle)")
    }

    private var subtitle: String {
        var parts = [recurring.frequencyLabel]
        if recurring.frequencyLabel != "Mensuel" {
            parts.append("environ \(FinanceFormatting.chf(monthlyEquivalent)) par mois")
        }
        if let nextDate, recurring.isActive {
            parts.append("prochaine le \(FinanceFormatting.swissDate(nextDate))")
        }
        if !recurring.isActive {
            parts.append("désactivée")
        }
        return parts.joined(separator: " · ")
    }
}

#Preview("Transactions mensuelles") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        RecurringListView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
