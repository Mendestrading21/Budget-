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

    // A14 (Les quatre familles, parité PWA lot A8) : les abonnements sont
    // une famille à part entière — séparés des factures par le drapeau
    // `isSubscription`, jamais devinés. Le total du héros reste calculé
    // sur TOUTES les sorties régulières : le chiffre ne change pas.
    private var activeOutflows: [RecurringTransaction] {
        recurrings.filter {
            $0.isActive && ![.income, .refund, .saving, .investment].contains($0.type)
        }
    }

    private var activeBills: [RecurringTransaction] {
        activeOutflows.filter { !$0.isSubscription }
    }

    private var activeSubscriptions: [RecurringTransaction] {
        activeOutflows.filter(\.isSubscription)
    }

    private var activeSetAside: [RecurringTransaction] {
        recurrings.filter { $0.isActive && [.saving, .investment].contains($0.type) }
    }

    private var activeIncome: [RecurringTransaction] {
        recurrings.filter { $0.isActive && [.income, .refund].contains($0.type) }
    }

    private var inactive: [RecurringTransaction] {
        recurrings.filter { !$0.isActive }
    }

    private var monthlyBillsTotal: Decimal {
        activeOutflows.reduce(.zero) {
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
                        // A14 : l'ordre canonique des familles — Rentrées,
                        // Factures, Abonnements, Mis de côté.
                        incomeSection
                        billSection
                        subscriptionSection
                        setAsideSection
                        inactiveSection
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            }
        }
        .navigationTitle("Ce qui revient")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ajouter ce qui revient")
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
                Text("Factures régulières · moyenne par mois")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)

                AmountText(amount: monthlyBillsTotal, role: .hero)

                Text("Salaire, factures, abonnements et mises de côté : ajoutez-les une fois, puis suivez-les dans votre bilan du mois.")
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)

                Button {
                    isPresentingNew = true
                } label: {
                    Label("Ajouter ce qui revient", systemImage: "plus")
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
    private var subscriptionSection: some View {
        if !activeSubscriptions.isEmpty {
            sectionTitle("Mes abonnements", count: activeSubscriptions.count)
            ForEach(activeSubscriptions) { recurring in
                row(recurring)
            }
        }
    }

    @ViewBuilder
    private var setAsideSection: some View {
        if !activeSetAside.isEmpty {
            sectionTitle("Mes mises de côté", count: activeSetAside.count)
            ForEach(activeSetAside) { recurring in
                row(recurring)
            }
        }
    }

    @ViewBuilder
    private var incomeSection: some View {
        if !activeIncome.isEmpty {
            sectionTitle("Mes rentrées", count: activeIncome.count)
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
                title: "Ajoutez ce qui revient",
                message: "Loyer, téléphone, salaire ou épargne : ajoutez-les une seule fois. Ils reviendront ensuite au bon rythme.",
                actionTitle: "Ajouter ce qui revient",
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
                Image(systemName: rowIcon)
                    .foregroundStyle(rowColor)
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
                    .foregroundStyle(rowColor)
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

    private var rowIcon: String {
        switch recurring.type {
        case .income, .refund: "arrow.down.circle"
        case .saving, .investment: "building.columns"
        default: "calendar"
        }
    }

    private var rowColor: Color {
        switch recurring.type {
        case .income, .refund: BudgetColor.positive
        case .saving, .investment: BudgetColor.brandBright
        default: BudgetColor.warning
        }
    }
}

#Preview("Ce qui revient") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        RecurringListView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
