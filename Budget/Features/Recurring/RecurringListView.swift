import SwiftUI
import SwiftData

/// Recurring charges and subscriptions: monthly/annualized totals,
/// upcoming occurrences, renewal and cancellation deadlines.
struct RecurringListView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RecurringTransaction.title) private var recurrings: [RecurringTransaction]

    @State private var editedRecurring: RecurringTransaction?
    @State private var isPresentingNew = false

    private var scheduleService: RecurringScheduleService {
        RecurringScheduleService(calendar: appContainer.calendar)
    }

    private var active: [RecurringTransaction] { recurrings.filter(\.isActive) }
    private var inactive: [RecurringTransaction] { recurrings.filter { !$0.isActive } }

    private var monthlyChargesTotal: Decimal {
        active
            .filter { $0.type != .income }
            .reduce(.zero) { $0 + scheduleService.monthlyEquivalent(of: $1) }
    }

    private var annualChargesTotal: Decimal {
        active
            .filter { $0.type != .income }
            .reduce(.zero) { $0 + scheduleService.annualizedCost(of: $1) }
    }

    private var groups: [(title: String, items: [RecurringTransaction])] {
        [
            ("Revenus", active.filter { $0.type == .income }),
            ("Abonnements", active.filter { $0.isSubscription && $0.type != .income }),
            ("Charges et contributions", active.filter { !$0.isSubscription && $0.type != .income }),
            ("Désactivés", inactive),
        ].filter { !$0.1.isEmpty }
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            if recurrings.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Récurrents")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            RecurringFormView(mode: .create)
        }
        .sheet(item: $editedRecurring) { recurring in
            RecurringFormView(mode: .edit(recurring))
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: BudgetSpacing.medium) {
                GlassCard(style: .hero) {
                    VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                        Text("Charges récurrentes")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: BudgetSpacing.micro) {
                            AmountText(amount: monthlyChargesTotal, role: .hero)
                            Text("par mois")
                                .font(BudgetFont.cardLabel)
                                .foregroundStyle(.secondary)
                        }
                        Text("Soit \(FinanceFormatting.chf(annualChargesTotal)) par an, revenus non compris")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Charges récurrentes : \(FinanceFormatting.chf(monthlyChargesTotal)) par mois, \(FinanceFormatting.chf(annualChargesTotal)) par an")
                }

                ForEach(groups, id: \.title) { group in
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text(group.title)
                            .font(BudgetFont.sectionTitle)
                            .foregroundStyle(.secondary)
                        ForEach(group.items) { recurring in
                            RecurringRow(
                                recurring: recurring,
                                monthlyEquivalent: scheduleService.monthlyEquivalent(of: recurring),
                                nextDate: scheduleService.nextOccurrence(of: recurring, onOrAfter: appContainer.dateProvider.now),
                                now: appContainer.dateProvider.now
                            )
                            .onTapGesture { editedRecurring = recurring }
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
                    symbol: "arrow.triangle.2.circlepath",
                    title: "Aucune charge récurrente",
                    message: "Salaire, loyer, primes, abonnements : enregistrez ce qui revient chaque mois pour que vos prévisions se remplissent toutes seules.",
                    actionTitle: "Ajouter un récurrent",
                    action: { isPresentingNew = true }
                )
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }
}

struct RecurringRow: View {
    let recurring: RecurringTransaction
    let monthlyEquivalent: Decimal
    let nextDate: Date?
    let now: Date

    /// Cancellation deadline within 30 days deserves attention.
    private var deadlineIsClose: Bool {
        guard let deadline = recurring.cancellationDeadline, recurring.isActive else { return false }
        return deadline >= now && deadline.timeIntervalSince(now) < 30 * 86_400
    }

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: recurring.isSubscription ? "arrow.triangle.2.circlepath" : recurring.type.systemImage)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BudgetSpacing.micro) {
                        Text(recurring.title)
                            .font(BudgetFont.body.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)
                        if recurring.isProfessional {
                            Text("Pro")
                                .font(BudgetFont.caption.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(BudgetColor.electricBlue.opacity(0.2), in: Capsule())
                                .foregroundStyle(BudgetColor.electricBlue)
                        }
                    }
                    Text(subtitle)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if deadlineIsClose, let deadline = recurring.cancellationDeadline {
                        Label("Résiliable jusqu'au \(FinanceFormatting.swissDate(deadline))", systemImage: "exclamationmark.triangle.fill")
                            .font(BudgetFont.caption.weight(.semibold))
                            .foregroundStyle(BudgetColor.warning)
                    }
                }
                Spacer(minLength: BudgetSpacing.small)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(FinanceFormatting.chf(recurring.amount))
                        .font(BudgetFont.amount)
                        .fixedSize()
                        .foregroundStyle(recurring.type == .income ? BudgetColor.positive : .primary)
                    Text(recurring.frequencyLabel)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .opacity(recurring.isActive ? 1 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var subtitle: String {
        var parts: [String] = []
        if recurring.frequencyLabel != "Mensuel" {
            parts.append("≈ \(FinanceFormatting.chf(monthlyEquivalent)) / mois")
        }
        if let nextDate, recurring.isActive {
            parts.append("Prochaine : \(FinanceFormatting.swissDate(nextDate))")
        }
        if !recurring.isActive {
            parts.append("Désactivé")
        }
        return parts.isEmpty ? recurring.type.displayName : parts.joined(separator: " · ")
    }

    private var accessibilityText: String {
        var text = "\(recurring.title), \(FinanceFormatting.chf(recurring.amount)), \(recurring.frequencyLabel)"
        if let nextDate, recurring.isActive {
            text += ", prochaine échéance le \(FinanceFormatting.swissDate(nextDate))"
        }
        if deadlineIsClose, let deadline = recurring.cancellationDeadline {
            text += ", résiliable jusqu'au \(FinanceFormatting.swissDate(deadline))"
        }
        return text
    }
}

#Preview("Récurrents") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        RecurringListView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
