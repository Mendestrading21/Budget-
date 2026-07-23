import SwiftUI
import SwiftData
import Charts

/// Agrégats d'AFFICHAGE du pilote Obsidian (L4) — aucune formule
/// financière nouvelle : « À payer » additionne trois composantes déjà
/// calculées par `MonthlySnapshotService` (mêmes valeurs que le détail du
/// héros). Vérifié par `ObsidianPilotTests`.
enum HomePilotDisplay {
    static func toPay(_ available: AvailableBreakdown) -> Decimal {
        available.committedCharges + available.recurringCharges + available.taxReserveGap
    }
}

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
    @Query private var budgets: [MonthlyBudget]
    @Query private var recurrings: [RecurringTransaction]
    @Query private var taxProfiles: [TaxProfile]
    @Query private var taxProvisions: [TaxProvision]
    @Query private var goals: [FinancialGoal]
    @Environment(\.modelContext) private var modelContext

    @State private var monthAnchor: Date?
    @State private var saveErrorMessage: String?
    /// Priority action → prefilled movement form (production-completion P2).
    @State private var prefilledCreateType: TransactionType?
    /// Action universelle du héros (pilote L4) : la même feuille, sans type
    /// prérempli.
    @State private var isPresentingUniversalCreate = false

    private var currentAnchor: Date { monthAnchor ?? appContainer.dateProvider.now }

    private var snapshotService: MonthlySnapshotService {
        MonthlySnapshotService(calendar: appContainer.calendar, balanceService: appContainer.balanceService)
    }

    /// Built exactly once per render, at the top of `body`, then passed
    /// down — never recomputed by each section (quality-plan rule: no
    /// repeated heavy calculation in body).
    private func makeSnapshot() -> MonthSnapshot {
        snapshotService.snapshot(
            monthOf: currentAnchor,
            now: appContainer.dateProvider.now,
            household: households.first,
            accounts: accounts,
            transactions: transactions,
            recurrings: recurrings,
            taxProfile: taxProfiles.first,
            taxProvisions: taxProvisions
        )
    }

    private var scheduleService: RecurringScheduleService {
        RecurringScheduleService(calendar: appContainer.calendar)
    }

    /// Remaining recurring occurrences of the displayed month.
    private func makeForecast(interval: MonthInterval) -> [ForecastOccurrence] {
        scheduleService.monthForecast(
            recurrings: recurrings,
            in: interval,
            transactions: transactions
        )
    }

    private var chartData: [(monthStart: Date, income: Decimal, livingExpenses: Decimal)] {
        snapshotService.monthlyFlows(endingAt: currentAnchor, count: 6, transactions: transactions)
    }

    /// Budget-vs-actual for the displayed month's top expense lines; empty
    /// when no budget exists (the chart then falls back to 6-month flows).
    private var budgetChartReports: [BudgetLineReport] {
        let planningService = BudgetPlanningService(calendar: appContainer.calendar)
        let (year, month) = planningService.yearAndMonth(of: currentAnchor)
        guard let budget = budgets.first(where: { $0.year == year && $0.month == month }),
              !budget.lines.isEmpty else { return [] }
        let report = BudgetVarianceService(calendar: appContainer.calendar)
            .report(budget: budget, monthOf: currentAnchor, transactions: transactions)
        return Array(
            report.lineReports
                .filter { $0.categoryKind == .expense }
                .sorted { $0.planned > $1.planned }
                .prefix(5)
        )
    }

    private func uncategorizedCount(in interval: MonthInterval) -> Int {
        let service = TransactionValidationService()
        return transactions.filter {
            interval.contains($0.date) && service.categoryRequired(for: $0.type) && $0.category == nil
        }.count
    }

    private func recentTransactions(in interval: MonthInterval) -> [BudgetTransaction] {
        Array(transactions.filter { interval.contains($0.date) }.prefix(5))
    }

    private var greetingName: String? {
        households.first?.members.first(where: { $0.role == .owner })?.firstName
    }

    var body: some View {
        let snapshot = makeSnapshot()
        let forecast = makeForecast(interval: snapshot.interval)
        let uncategorized = uncategorizedCount(in: snapshot.interval)
        let recent = recentTransactions(in: snapshot.interval)
        let actions = makePriorityActions(snapshot: snapshot, uncategorized: uncategorized)
        return NavigationStack {
            ZStack {
                BudgetScreenBackground()
                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        monthSelector
                        // "Truly available" mixes today's balances with the
                        // month's planned flows — only meaningful for the
                        // month containing "now". Other months get a recap.
                        if snapshot.interval.contains(appContainer.dateProvider.now) {
                            availableHeroCard(snapshot)
                        } else {
                            monthRecapCard(snapshot)
                        }
                        statGrid(snapshot)
                        // Pilote L4 (parité PWA L3) : UNE priorité mise en
                        // avant juste après les métriques ; les suivantes
                        // restent dans « À faire » — rien n'est perdu.
                        if let first = actions.first {
                            priorityEntry(first, highlighted: true)
                        }
                        monthCheckCard(forecast: forecast, interval: snapshot.interval)
                        forecastSection(forecast: forecast)
                        flowsChartCard
                        priorityActionsSection(actions: Array(actions.dropFirst()))
                        recentSection(recent: recent)
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
            }
            .navigationTitle(greetingName.map { "Bonjour \($0) 👋" } ?? "Accueil")
        .alert(
            saveErrorMessage ?? "",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        }
        .sheet(item: $prefilledCreateType) { type in
            TransactionFormView(mode: .create(prefilledAccount: nil), prefilledType: type)
        }
        .sheet(isPresented: $isPresentingUniversalCreate) {
            TransactionFormView(mode: .create(prefilledAccount: nil))
        }
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

    private func monthRecapCard(_ snapshot: MonthSnapshot) -> some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Ce qui reste du mois")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                AmountText(
                    amount: snapshot.cashFlow,
                    role: .hero,
                    signed: true,
                    emphasis: snapshot.cashFlow < 0 ? .negative : .positive
                )
                if let comparison = snapshot.previousMonth {
                    Text("Revenus \(FinanceFormatting.chfSigned(comparison.incomeDelta)) et coût de la vie \(FinanceFormatting.chfSigned(comparison.livingExpensesDelta)) par rapport au mois précédent")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Ce qui reste du mois : \(FinanceFormatting.chfSigned(snapshot.cashFlow))")
        }
    }

    private func availableHeroCard(_ snapshot: MonthSnapshot) -> some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Argent disponible")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                AmountText(
                    amount: snapshot.available.total,
                    role: .hero,
                    emphasis: snapshot.available.total < 0 ? .negative : .neutral
                )
                // Jours restants : visibles mais SECONDAIRES (contrat pilote).
                if snapshot.daysRemaining > 0 {
                    Text("\(snapshot.daysRemaining) jours restants · \(FinanceFormatting.chf(snapshot.dailyAvailableBudget)) par jour")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }

                DisclosureGroup {
                    VStack(spacing: BudgetSpacing.micro) {
                        breakdownRow("Liquidités incluses", snapshot.available.liquidBalance)
                        breakdownRow("Revenus attendus", snapshot.available.expectedIncome, signed: true)
                        breakdownRow("Revenus récurrents à venir", snapshot.available.recurringIncome, signed: true)
                        breakdownRow("Charges engagées", -snapshot.available.committedCharges, signed: true)
                        breakdownRow("Charges récurrentes à venir", -snapshot.available.recurringCharges, signed: true)
                        breakdownRow("Réserve d'impôts manquante", -snapshot.available.taxReserveGap, signed: true)
                    }
                    .padding(.top, BudgetSpacing.micro)
                } label: {
                    Text("D'où vient ce montant ?")
                        .font(BudgetFont.caption)
                        .foregroundStyle(BudgetColor.brandBright)
                }
                .tint(BudgetColor.brandBright)

                // Action universelle du contrat, dans le héros.
                Button {
                    isPresentingUniversalCreate = true
                } label: {
                    Label("Ajouter un mouvement", systemImage: "plus")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityHint("Ouvre la feuille de création d'un mouvement")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Argent disponible ce mois : \(FinanceFormatting.chf(snapshot.available.total))")
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

    // MARK: - Stat cards

    /// Les quatre métriques du contrat pilote : Entré, Dépensé, À payer,
    /// Mis de côté — mêmes mots que le pilote PWA L3. « À payer » est un
    /// agrégat d'affichage de composantes déjà calculées (HomePilotDisplay).
    private func statGrid(_ snapshot: MonthSnapshot) -> some View {
        let toPay = HomePilotDisplay.toPay(snapshot.available)
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: BudgetSpacing.medium), GridItem(.flexible())], spacing: BudgetSpacing.medium) {
            statCard("Entré", snapshot.totalIncome, icon: "arrow.down.circle", tint: BudgetColor.positive,
                     detail: "Revenus comptabilisés")
            statCard("Dépensé", snapshot.totalLivingExpenses, icon: "arrow.up.circle", tint: BudgetColor.negative,
                     detail: snapshot.previousMonth.map {
                         "Mois dernier : \(FinanceFormatting.chfSigned($0.livingExpensesDelta)) d'écart"
                     } ?? "Coût de la vie")
            statCard("À payer", toPay, icon: "clock", tint: BudgetColor.warning,
                     detail: toPay > 0 ? "Prévu, réguliers et impôts" : "Rien en attente")
            statCard("Mis de côté", snapshot.totalSavings + snapshot.totalInvestments, icon: "building.columns", tint: BudgetColor.brandBright,
                     detail: snapshot.totalIncome > 0 ? "Taux : \(FinanceFormatting.percent(snapshot.savingsRate))" : "Épargne + investissements")
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

    // MARK: - Forecast

    /// Upcoming recurring occurrences of the displayed month, with a
    /// one-tap action to materialize each into a posted movement.
    @ViewBuilder
    private func forecastSection(forecast: [ForecastOccurrence]) -> some View {
        let occurrences = Array(forecast.prefix(4))
        if !occurrences.isEmpty {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                HStack {
                    Text("À venir ce mois")
                        .font(BudgetFont.sectionTitle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    NavigationLink {
                        RecurringListView()
                    } label: {
                        Text("Gérer")
                            .font(BudgetFont.caption.weight(.semibold))
                            .foregroundStyle(BudgetColor.brandBright)
                    }
                }
                ForEach(occurrences) { occurrence in
                    GlassCard(style: .row) {
                        HStack(spacing: BudgetSpacing.medium) {
                            Image(systemName: occurrence.type.systemImage)
                                .foregroundStyle(BudgetColor.indigo)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(occurrence.title)
                                    .font(BudgetFont.body.weight(.medium))
                                    .lineLimit(1)
                                Text(FinanceFormatting.swissDate(occurrence.date))
                                    .font(BudgetFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: BudgetSpacing.small)
                            Text((occurrence.type == .income ? "+" : "−") + FinanceFormatting.chf(occurrence.amount))
                                .font(BudgetFont.amount)
                                .foregroundStyle(occurrence.type == .income ? BudgetColor.positive : .secondary)
                            Button {
                                post(occurrence)
                            } label: {
                                Image(systemName: "checkmark.circle")
                                    .font(.title3)
                                    .foregroundStyle(BudgetColor.brandBright)
                            }
                            .accessibilityLabel("Comptabiliser \(occurrence.title)")
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }
        }
    }

    /// Rituel « Check du mois » — la progression des validations du mois
    /// affiché (parité web). Purement dérivée : rien n'est persisté.
    @ViewBuilder
    private func monthCheckCard(forecast: [ForecastOccurrence], interval: MonthInterval) -> some View {
        let check = scheduleService.monthCheck(
            recurrings: recurrings, in: interval, transactions: transactions
        )
        let streak = scheduleService.closedStreak(
            endingAt: appContainer.dateProvider.now, recurrings: recurrings, transactions: transactions
        )
        if check.total > 0 {
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    HStack {
                        Text(streak >= 2 ? "Check du mois · 🔥 ×\(streak)" : "Check du mois")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(check.done)/\(check.total) validé\(check.done > 1 ? "s" : "")")
                            .font(BudgetFont.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(check.done), total: Double(check.total))
                        .tint(check.done == check.total ? BudgetColor.positive : BudgetColor.indigo)
                    if check.done == check.total {
                        Label("Mois bouclé — tout est validé", systemImage: "checkmark.seal.fill")
                            .font(BudgetFont.body.weight(.semibold))
                            .foregroundStyle(BudgetColor.positive)
                    } else {
                        Text("Validez chaque élément « À venir » d'un ✓ — salaire, abonnements, versements.")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Check du mois : \(check.done) sur \(check.total) validés")
        }
    }

    private func post(_ occurrence: ForecastOccurrence) {
        guard let recurring = recurrings.first(where: { $0.id == occurrence.recurringID }) else { return }
        // Jamais un mouvement COMPTABILISÉ daté dans le futur : une
        // occurrence validée en avance est datée d'aujourd'hui (règle
        // planifié/réel, même correctif que le prototype web).
        let now = appContainer.dateProvider.now
        let transaction = scheduleService.makeTransaction(
            from: recurring,
            on: min(occurrence.date, now),
            now: now
        )
        modelContext.insert(transaction)
        modelContext.saveOrRollback { saveErrorMessage = $0 }
    }

    // MARK: - Chart

    private var monthShortFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = FinanceFormatting.locale
        formatter.calendar = appContainer.calendar
        formatter.dateFormat = "MMM"
        return formatter
    }

    @ViewBuilder
    private var flowsChartCard: some View {
        let budgetReports = budgetChartReports
        if budgetReports.isEmpty {
            sixMonthFlowsCard
        } else {
            budgetVsActualCard(reports: budgetReports)
        }
    }

    private func budgetVsActualCard(reports: [BudgetLineReport]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Budget vs réel — principales dépenses")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                Chart {
                    ForEach(reports) { report in
                        BarMark(
                            x: .value("CHF", NSDecimalNumber(decimal: report.planned).doubleValue),
                            y: .value("Catégorie", report.categoryName),
                            height: .ratio(0.32)
                        )
                        .position(by: .value("Série", "Planifié"))
                        .foregroundStyle(by: .value("Série", "Planifié"))
                        .cornerRadius(4)

                        BarMark(
                            x: .value("CHF", NSDecimalNumber(decimal: report.actual).doubleValue),
                            y: .value("Catégorie", report.categoryName),
                            height: .ratio(0.32)
                        )
                        .position(by: .value("Série", "Réel"))
                        .foregroundStyle(by: .value("Série", "Réel"))
                        .cornerRadius(4)
                    }
                }
                .chartForegroundStyleScale([
                    "Planifié": BudgetColor.indigo,
                    "Réel": BudgetColor.brandBright,
                ])
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel().font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.caption2)
                    }
                }
                .frame(height: CGFloat(reports.count) * 44 + 24)
                .accessibilityLabel("Graphique budget contre réel des principales dépenses du mois")
                .accessibilityValue(
                    reports.map {
                        "\($0.categoryName) : planifié \(FinanceFormatting.chf($0.planned)), réel \(FinanceFormatting.chf($0.actual))"
                    }.joined(separator: ". ")
                )
            }
        }
    }

    private var sixMonthFlowsCard: some View {
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
                            AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
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

    /// Subscriptions whose cancellation deadline falls within 30 days.
    private var closingSubscriptions: [RecurringTransaction] {
        let now = appContainer.dateProvider.now
        return recurrings.filter { recurring in
            guard recurring.isActive, let deadline = recurring.cancellationDeadline else { return false }
            return deadline >= now && deadline.timeIntervalSince(now) < 30 * 86_400
        }
    }

    /// Next tax due date within 30 days for the current year.
    private var upcomingTaxDueDate: TaxDueDate? {
        let now = appContainer.dateProvider.now
        let year = appContainer.calendar.component(.year, from: now)
        let provision = taxProfiles.first?.provisions.first { $0.year == year }
        return TaxService(calendar: appContainer.calendar)
            .upcomingDueDates(provision: provision, now: now)
            .first { $0.date.timeIntervalSince(now) < 30 * 86_400 }
    }

    /// First active goal whose planned pace no longer makes its date.
    private var lateGoal: (goal: FinancialGoal, report: GoalReport)? {
        let service = GoalProjectionService(calendar: appContainer.calendar, balanceService: appContainer.balanceService)
        let now = appContainer.dateProvider.now
        return goals
            .filter { $0.status == .active }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
            .lazy
            .map { ($0, service.report(for: $0, now: now)) }
            .first { $0.1.scheduleStatus == .behind || $0.1.scheduleStatus == .overdue }
    }

    private func makePriorityActions(snapshot: MonthSnapshot, uncategorized: Int) -> [PriorityAction] {
        var actions: [PriorityAction] = []
        if let late = lateGoal {
            actions.append(PriorityAction(
                id: "goal",
                title: late.report.scheduleStatus == .overdue
                    ? "Objectif « \(late.goal.name) » : échéance dépassée"
                    : "Objectif « \(late.goal.name) » : passez à \(FinanceFormatting.chf(late.report.requiredMonthlyContribution ?? late.report.remainingAmount)) / mois",
                systemImage: "target"
            ))
        }
        if let dueDate = upcomingTaxDueDate {
            actions.append(PriorityAction(
                id: "taxDueDate",
                title: "Échéance d'impôts « \(dueDate.label) » le \(FinanceFormatting.swissDate(dueDate.date))",
                systemImage: "calendar.badge.exclamationmark"
            ))
        }
        if let closing = closingSubscriptions.first {
            actions.append(PriorityAction(
                id: "cancellation",
                title: "« \(closing.title) » résiliable jusqu'au \(FinanceFormatting.swissDate(closing.cancellationDeadline ?? appContainer.dateProvider.now))",
                systemImage: "exclamationmark.triangle"
            ))
        }
        if uncategorized > 0 {
            actions.append(PriorityAction(
                id: "uncategorized",
                title: "Catégorisez \(uncategorized) mouvement(s)",
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
    private func priorityActionsSection(actions: [PriorityAction]) -> some View {
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("À faire")
                    .font(BudgetFont.sectionTitle)
                    .foregroundStyle(.secondary)
                ForEach(actions) { action in
                    priorityEntry(action, highlighted: false)
                }
            }
        }
    }

    /// Une entrée de priorité — la même navigation qu'avant le pilote,
    /// factorisée pour servir la carte mise en avant ET la liste « À faire ».
    @ViewBuilder
    private func priorityEntry(_ action: PriorityAction, highlighted: Bool) -> some View {
        if action.id == "income" || action.id == "savings" {
            // « Ajoutez vos revenus » / « Planifiez une épargne »
            // ouvrent directement le formulaire prérempli.
            Button {
                prefilledCreateType = action.id == "income" ? .income : .saving
            } label: {
                priorityActionRow(action, highlighted: highlighted)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                if action.id == "cancellation" {
                    RecurringListView()
                } else if action.id == "taxDueDate" || action.id == "tax" {
                    TaxesView()
                } else if action.id == "goal" {
                    GoalsListView()
                } else {
                    TransactionsListView()
                }
            } label: {
                priorityActionRow(action, highlighted: highlighted)
            }
            .buttonStyle(.plain)
        }
    }

    private func priorityActionRow(_ action: PriorityAction, highlighted: Bool = false) -> some View {
        GlassCard(style: .row) {
            VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                if highlighted {
                    // Pill + symbole + texte : jamais la couleur seule.
                    StatusPill(text: "Priorité", kind: .neutral)
                }
                HStack {
                    // Multi-ligne : le texte complet, jamais tronqué.
                    Label(action.title, systemImage: action.systemImage)
                        .font(BudgetFont.body)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
        .overlay {
            if highlighted {
                RoundedRectangle(cornerRadius: BudgetRadius.control, style: .continuous)
                    .strokeBorder(BudgetColor.strokeActive, lineWidth: 1)
            }
        }
    }

    // MARK: - Recent

    private func recentSection(recent: [BudgetTransaction]) -> some View {
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
                        .foregroundStyle(BudgetColor.brandBright)
                }
            }
            if recent.isEmpty {
                GlassCard(style: .row) {
                    Text("Aucun mouvement ce mois pour l'instant.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(recent) { transaction in
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

#Preview("Dashboard — texte agrandi") {
    let preview = DemoDataFactory.previewAppContainer()
    return HomeTab()
        .environment(preview)
        .environment(AppRouter())
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dashboard — transparence réduite") {
    let preview = DemoDataFactory.previewAppContainer()
    return HomeTab()
        .environment(preview)
        .environment(AppRouter())
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
        .environment(\.obsidianForcedReducedTransparency, true)
}
