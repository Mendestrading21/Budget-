import SwiftUI
import SwiftData
import Charts

/// Accueil: the monthly dashboard. Answers within the first viewport:
/// what is available, what came in, what went out, what is reserved,
/// and what requires action. All values derive from persisted data via
/// MonthlySnapshotService — nothing is computed inline in `body`.
struct HomeTab: View {
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \BudgetTransaction.date, order: .reverse)
    private var transactions: [BudgetTransaction]
    @Query private var accounts: [Account]
    @Query private var households: [Household]

    @State private var monthAnchor: Date?

    private var currentAnchor: Date { monthAnchor ?? appContainer.dateProvider.now }

    private var snapshotService: MonthlySnapshotService {
        MonthlySnapshotService(calendar: appContainer.calendar, balanceService: appContainer.balanceService)
    }

    private var snapshot: MonthSnapshot {
        snapshotService.snapshot(
            monthOf: currentAnchor,
            now: appContainer.dateProvider.now,
            household: households.first,
            accounts: accounts,
            transactions: transactions
        )
    }

    private var chartData: [(monthStart: Date, income: Decimal, livingExpenses: Decimal)] {
        snapshotService.monthlyFlows(endingAt: currentAnchor, count: 6, transactions: transactions)
    }

    private var uncategorizedCount: Int {
        let service = TransactionValidationService()
        return transactions.filter {
            snapshot.interval.contains($0.date) && service.categoryRequired(for: $0.type) && $0.category == nil
        }.count
    }

    private var recentTransactions: [BudgetTransaction] {
        Array(transactions.filter { snapshot.interval.contains($0.date) }.prefix(5))
    }

    private var greetingName: String? {
        households.first?.members.first(where: { $0.role == .owner })?.firstName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BudgetScreenBackground()
                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        monthSelector
                        // "Truly available" mixes today's balances with the
                        // month's planned flows — only meaningful for the
                        // month containing "now". Other months get a recap.
                        if isCurrentMonth {
                            availableHeroCard
                            dailyBudgetRow
                        } else {
                            monthRecapCard
                        }
                        statGrid
                        flowsChartCard
                        priorityActionsSection
                        recentSection
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
            }
            .navigationTitle(greetingName.map { "Bonjour \($0) 👋" } ?? "Accueil")
        }
    }

    // MARK: - Month selector

    private var monthSelector: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .padding(BudgetSpacing.small)
            }
            .accessibilityLabel("Mois précédent")

            Spacer()
            Text(FinanceFormatting.monthTitle(currentAnchor, calendar: appContainer.calendar).capitalized)
                .font(BudgetFont.sectionTitle)
            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .padding(BudgetSpacing.small)
            }
            .accessibilityLabel("Mois suivant")
        }
        .tint(BudgetColor.indigo)
    }

    private func shiftMonth(by value: Int) {
        monthAnchor = appContainer.calendar.date(byAdding: .month, value: value, to: currentAnchor) ?? currentAnchor
    }

    // MARK: - Hero

    private var isCurrentMonth: Bool {
        snapshot.interval.contains(appContainer.dateProvider.now)
    }

    private var monthRecapCard: some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Flux net du mois")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                Text(FinanceFormatting.chfSigned(snapshot.cashFlow))
                    .font(BudgetFont.heroAmount)
                    .foregroundStyle(snapshot.cashFlow < 0 ? BudgetColor.negative : BudgetColor.positive)
                if let comparison = snapshot.previousMonth {
                    Text("Revenus \(FinanceFormatting.chfSigned(comparison.incomeDelta)) et coût de la vie \(FinanceFormatting.chfSigned(comparison.livingExpensesDelta)) par rapport au mois précédent")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Flux net du mois : \(FinanceFormatting.chfSigned(snapshot.cashFlow))")
        }
    }

    private var availableHeroCard: some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Vraiment disponible")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                Text(FinanceFormatting.chf(snapshot.available.total))
                    .font(BudgetFont.heroAmount)
                    .foregroundStyle(snapshot.available.total < 0 ? BudgetColor.negative : .primary)

                DisclosureGroup {
                    VStack(spacing: BudgetSpacing.micro) {
                        breakdownRow("Liquidités incluses", snapshot.available.liquidBalance)
                        breakdownRow("Revenus attendus", snapshot.available.expectedIncome, signed: true)
                        breakdownRow("Charges engagées", -snapshot.available.committedCharges, signed: true)
                        breakdownRow("Réserve d'impôts manquante", -snapshot.available.taxReserveGap, signed: true)
                    }
                    .padding(.top, BudgetSpacing.micro)
                } label: {
                    Text("Détail du calcul")
                        .font(BudgetFont.caption)
                        .foregroundStyle(BudgetColor.electricBlue)
                }
                .tint(BudgetColor.electricBlue)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Vraiment disponible ce mois : \(FinanceFormatting.chf(snapshot.available.total))")
        }
    }

    private func breakdownRow(_ label: String, _ amount: Decimal, signed: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(signed ? FinanceFormatting.chfSigned(amount) : FinanceFormatting.chf(amount))
                .font(BudgetFont.caption.monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }

    private var dailyBudgetRow: some View {
        GlassCard(style: .row) {
            HStack {
                Label {
                    Text(snapshot.daysRemaining > 0
                         ? "\(snapshot.daysRemaining) jour(s) restant(s)"
                         : "Mois terminé")
                        .font(BudgetFont.body)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(BudgetColor.indigo)
                }
                Spacer()
                if snapshot.daysRemaining > 0 {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(FinanceFormatting.chf(snapshot.dailyAvailableBudget))
                            .font(BudgetFont.amount)
                        Text("par jour")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                snapshot.daysRemaining > 0
                    ? "\(snapshot.daysRemaining) jours restants, budget quotidien \(FinanceFormatting.chf(snapshot.dailyAvailableBudget))"
                    : "Mois terminé"
            )
        }
    }

    // MARK: - Stat cards

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: BudgetSpacing.medium), GridItem(.flexible())], spacing: BudgetSpacing.medium) {
            statCard("Revenus", snapshot.totalIncome, icon: "arrow.down.circle", tint: BudgetColor.positive)
            statCard("Coût de la vie", snapshot.totalLivingExpenses, icon: "arrow.up.circle", tint: BudgetColor.negative)
            statCard("Épargne + invest.", snapshot.totalSavings + snapshot.totalInvestments, icon: "building.columns", tint: BudgetColor.electricBlue, detail: snapshot.totalIncome > 0 ? "Taux : \(FinanceFormatting.percent(snapshot.savingsRate))" : nil)
            statCard("Impôts payés", snapshot.taxProvision.paid, icon: "doc.text", tint: BudgetColor.warning, detail: snapshot.taxProvision.gap > 0 ? "Réserve manquante : \(FinanceFormatting.chf(snapshot.taxProvision.gap))" : "Réserve du mois couverte")
        }
    }

    private func statCard(_ title: String, _ amount: Decimal, icon: String, tint: Color, detail: String? = nil) -> some View {
        GlassCard(style: .row) {
            VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                Label(title, systemImage: icon)
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(FinanceFormatting.chf(amount))
                    .font(BudgetFont.amount)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let detail {
                    Text(detail)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) : \(FinanceFormatting.chf(amount))\(detail.map { ", \($0)" } ?? "")")
    }

    // MARK: - Chart

    private var monthShortFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = FinanceFormatting.locale
        formatter.calendar = appContainer.calendar
        formatter.dateFormat = "MMM"
        return formatter
    }

    private var flowsChartCard: some View {
        let data = chartData
        let formatter = monthShortFormatter
        return GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Revenus vs coût de la vie — 6 mois")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                if data.allSatisfy({ $0.income == 0 && $0.livingExpenses == 0 }) {
                    Text("Ajoutez des mouvements pour voir la tendance de vos derniers mois.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                } else {
                    Chart {
                        ForEach(data, id: \.monthStart) { point in
                            BarMark(
                                x: .value("Mois", formatter.string(from: point.monthStart)),
                                y: .value("CHF", NSDecimalNumber(decimal: point.income).doubleValue),
                                width: .ratio(0.32)
                            )
                            .position(by: .value("Série", "Revenus"))
                            .foregroundStyle(by: .value("Série", "Revenus"))
                            .cornerRadius(4)

                            BarMark(
                                x: .value("Mois", formatter.string(from: point.monthStart)),
                                y: .value("CHF", NSDecimalNumber(decimal: point.livingExpenses).doubleValue),
                                width: .ratio(0.32)
                            )
                            .position(by: .value("Série", "Coût de la vie"))
                            .foregroundStyle(by: .value("Série", "Coût de la vie"))
                            .cornerRadius(4)
                        }
                    }
                    .chartForegroundStyleScale([
                        "Revenus": BudgetColor.positive,
                        "Coût de la vie": BudgetColor.negative,
                    ])
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(.white.opacity(0.08))
                            AxisValueLabel().font(.caption2)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel().font(.caption2)
                        }
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Graphique des revenus et du coût de la vie sur six mois")
                    .accessibilityValue(chartAccessibilitySummary(data: data))
                }
            }
        }
    }

    private func chartAccessibilitySummary(data: [(monthStart: Date, income: Decimal, livingExpenses: Decimal)]) -> String {
        let formatter = monthShortFormatter
        return data.map { point in
            "\(formatter.string(from: point.monthStart)) : revenus \(FinanceFormatting.chf(point.income)), coût de la vie \(FinanceFormatting.chf(point.livingExpenses))"
        }.joined(separator: ". ")
    }

    // MARK: - Priority actions

    private struct PriorityAction: Identifiable {
        let id: String
        let title: String
        let systemImage: String
    }

    private var priorityActions: [PriorityAction] {
        var actions: [PriorityAction] = []
        if uncategorizedCount > 0 {
            actions.append(PriorityAction(
                id: "uncategorized",
                title: "Catégorisez \(uncategorizedCount) mouvement(s)",
                systemImage: "questionmark.folder"
            ))
        }
        if snapshot.taxProvision.gap > 0 {
            actions.append(PriorityAction(
                id: "tax",
                title: "Réservez \(FinanceFormatting.chf(snapshot.taxProvision.gap)) pour les impôts",
                systemImage: "doc.text"
            ))
        }
        if snapshot.totalIncome == 0 && snapshot.plannedIncome == 0 && snapshot.daysRemaining > 0 {
            actions.append(PriorityAction(
                id: "income",
                title: "Ajoutez vos revenus du mois",
                systemImage: "arrow.down.circle"
            ))
        }
        if snapshot.totalIncome > 0 && snapshot.totalSavings + snapshot.totalInvestments == 0 {
            actions.append(PriorityAction(
                id: "savings",
                title: "Planifiez une épargne ce mois",
                systemImage: "building.columns"
            ))
        }
        return Array(actions.prefix(3))
    }

    @ViewBuilder
    private var priorityActionsSection: some View {
        let actions = priorityActions
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("À faire")
                    .font(BudgetFont.sectionTitle)
                    .foregroundStyle(.secondary)
                ForEach(actions) { action in
                    NavigationLink {
                        TransactionsListView()
                    } label: {
                        GlassCard(style: .row) {
                            HStack {
                                Label(action.title, systemImage: action.systemImage)
                                    .font(BudgetFont.body)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            HStack {
                Text("Mouvements récents")
                    .font(BudgetFont.sectionTitle)
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    TransactionsListView()
                } label: {
                    Text("Tout voir")
                        .font(BudgetFont.caption.weight(.semibold))
                        .foregroundStyle(BudgetColor.electricBlue)
                }
            }
            if recentTransactions.isEmpty {
                GlassCard(style: .row) {
                    Text("Aucun mouvement ce mois pour l'instant.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(recentTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
}

#Preview("Dashboard") {
    let preview = DemoDataFactory.previewAppContainer()
    return HomeTab()
        .environment(preview)
        .environment(AppRouter())
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
