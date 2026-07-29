import SwiftUI
import SwiftData

/// Small display-only aggregate used by the home screen and its tests.
/// It never changes the financial engine: committed, recurring and tax
/// amounts are still calculated by `MonthlySnapshotService`.
enum HomePilotDisplay {
    static func toPay(_ available: AvailableBreakdown) -> Decimal {
        available.committedCharges + available.recurringCharges + available.taxReserveGap
    }
}

/// A deliberately simple home screen.
///
/// The first viewport answers only four questions:
/// - How much money is available?
/// - How much came in?
/// - How much was spent?
/// - How much still has to be paid?
///
/// Monthly recurring items are shown immediately underneath and can be
/// marked as paid in one tap. Detailed analysis remains available in the
/// dedicated tabs instead of competing for attention on the dashboard.
struct HomeTab: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BudgetTransaction.date, order: .reverse)
    private var transactions: [BudgetTransaction]
    @Query private var accounts: [Account]
    @Query private var households: [Household]
    @Query private var recurrings: [RecurringTransaction]
    @Query private var taxProfiles: [TaxProfile]
    @Query private var taxProvisions: [TaxProvision]

    @State private var monthAnchor: Date?
    @State private var saveErrorMessage: String?
    @State private var isPresentingCreate = false

    private var currentAnchor: Date {
        monthAnchor ?? appContainer.dateProvider.now
    }

    private var snapshotService: MonthlySnapshotService {
        MonthlySnapshotService(
            calendar: appContainer.calendar,
            balanceService: appContainer.balanceService
        )
    }

    private var scheduleService: RecurringScheduleService {
        RecurringScheduleService(calendar: appContainer.calendar)
    }

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

    private func makeForecast(interval: MonthInterval) -> [ForecastOccurrence] {
        scheduleService.monthForecast(
            recurrings: recurrings,
            in: interval,
            transactions: transactions
        )
    }

    private var greetingName: String? {
        households.first?.members.first(where: { $0.role == .owner })?.firstName
    }

    var body: some View {
        let snapshot = makeSnapshot()
        let forecast = makeForecast(interval: snapshot.interval)

        NavigationStack {
            ZStack {
                BudgetScreenBackground()

                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        monthSelector
                        availableCard(snapshot)
                        essentialAmounts(snapshot)
                        monthlyBills(forecast: forecast, interval: snapshot.interval)
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
                .obsidianFABClearance()
            }
            .navigationTitle(greetingName.map { "Bonjour \($0)" } ?? "Accueil")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Ajouter un mouvement")
                }
            }
            .alert(
                saveErrorMessage ?? "",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $isPresentingCreate) {
                TransactionFormView(mode: .create(prefilledAccount: nil))
            }
        }
    }

    // MARK: - Month

    private var monthSelector: some View {
        HStack(spacing: BudgetSpacing.small) {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Mois précédent")

            Spacer()

            Text(
                FinanceFormatting
                    .monthTitle(currentAnchor, calendar: appContainer.calendar)
                    .capitalized
            )
            .font(BudgetFont.sectionTitle)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Mois suivant")
        }
        .tint(BudgetColor.brandBright)
    }

    private func shiftMonth(by value: Int) {
        monthAnchor = appContainer.calendar.date(
            byAdding: .month,
            value: value,
            to: currentAnchor
        ) ?? currentAnchor
    }

    // MARK: - Main amounts

    private func availableCard(_ snapshot: MonthSnapshot) -> some View {
        let isCurrentMonth = snapshot.interval.contains(appContainer.dateProvider.now)
        let amount = isCurrentMonth ? snapshot.available.total : snapshot.cashFlow
        let title = isCurrentMonth ? "Disponible" : "Reste du mois"

        return GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text(title)
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)

                AmountText(
                    amount: amount,
                    role: .hero,
                    signed: !isCurrentMonth,
                    emphasis: amount < 0 ? .negative : .neutral
                )

                if isCurrentMonth, snapshot.daysRemaining > 0 {
                    Text("\(FinanceFormatting.chf(snapshot.dailyAvailableBudget)) par jour")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) : \(FinanceFormatting.chf(amount))")
        }
    }

    private func essentialAmounts(_ snapshot: MonthSnapshot) -> some View {
        let toPay = HomePilotDisplay.toPay(snapshot.available)

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: BudgetSpacing.medium),
                GridItem(.flexible())
            ],
            spacing: BudgetSpacing.medium
        ) {
            amountCard(
                "Entré",
                snapshot.totalIncome,
                symbol: "arrow.down",
                emphasis: .positive
            )
            amountCard(
                "Dépensé",
                snapshot.totalLivingExpenses,
                symbol: "arrow.up",
                emphasis: .negative
            )
            amountCard(
                "À payer",
                toPay,
                symbol: "calendar",
                emphasis: toPay > 0 ? .warning : .neutral
            )
            amountCard(
                "Mis de côté",
                snapshot.totalSavings + snapshot.totalInvestments,
                symbol: "building.columns",
                emphasis: .neutral
            )
        }
    }

    private func amountCard(
        _ title: String,
        _ amount: Decimal,
        symbol: String,
        emphasis: AmountEmphasis
    ) -> some View {
        GlassCard(style: .row) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(FinanceFormatting.chf(amount))
                    .font(BudgetFont.amount)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(color(for: emphasis))

                Text(title)
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) : \(FinanceFormatting.chf(amount))")
        }
    }

    private enum AmountEmphasis {
        case positive
        case negative
        case warning
        case neutral
    }

    private func color(for emphasis: AmountEmphasis) -> Color {
        switch emphasis {
        case .positive: BudgetColor.positive
        case .negative: BudgetColor.negative
        case .warning: BudgetColor.warning
        case .neutral: .primary
        }
    }

    // MARK: - Monthly recurring bills

    @ViewBuilder
    private func monthlyBills(
        forecast: [ForecastOccurrence],
        interval: MonthInterval
    ) -> some View {
        let expenses = forecast.filter { $0.type != .income }
        let check = scheduleService.monthCheck(
            recurrings: recurrings,
            in: interval,
            transactions: transactions
        )

        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Factures du mois")
                        .font(BudgetFont.sectionTitle)
                    if check.total > 0 {
                        Text("\(check.done) sur \(check.total) payées")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                NavigationLink {
                    RecurringListView()
                } label: {
                    Text("Gérer")
                        .font(BudgetFont.body.weight(.semibold))
                }
            }

            if check.total > 0 {
                ProgressView(value: Double(check.done), total: Double(check.total))
                    .tint(check.done == check.total ? BudgetColor.positive : BudgetColor.brandBright)
                    .accessibilityLabel("Factures payées")
                    .accessibilityValue("\(check.done) sur \(check.total)")
            }

            if expenses.isEmpty {
                GlassCard(style: .row) {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text("Aucune facture à payer")
                            .font(BudgetFont.body.weight(.semibold))
                        Text("Ajoutez votre loyer, vos assurances ou vos abonnements une seule fois. Ils reviendront automatiquement chaque mois.")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            RecurringListView()
                        } label: {
                            Label("Ajouter une facture mensuelle", systemImage: "plus")
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                    }
                }
            } else {
                ForEach(expenses.prefix(6)) { occurrence in
                    recurringBillRow(occurrence)
                }

                if expenses.count > 6 {
                    NavigationLink {
                        RecurringListView()
                    } label: {
                        Text("Voir les \(expenses.count) factures")
                            .font(BudgetFont.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
        }
    }

    private func recurringBillRow(_ occurrence: ForecastOccurrence) -> some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: "calendar")
                    .frame(width: 28)
                    .foregroundStyle(BudgetColor.warning)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(occurrence.title)
                        .font(BudgetFont.body.weight(.semibold))
                        .lineLimit(1)
                    Text(FinanceFormatting.swissDate(occurrence.date))
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: BudgetSpacing.small)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(FinanceFormatting.chf(occurrence.amount))
                        .font(BudgetFont.amount)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Button("Payée") {
                        post(occurrence)
                    }
                    .font(BudgetFont.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(BudgetColor.brandBright)
                    .accessibilityLabel("Marquer \(occurrence.title) comme payée")
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func post(_ occurrence: ForecastOccurrence) {
        guard let recurring = recurrings.first(where: { $0.id == occurrence.recurringID }) else {
            return
        }

        let now = appContainer.dateProvider.now
        let persistedTransactions: [BudgetTransaction]
        do {
            persistedTransactions = try modelContext.fetch(FetchDescriptor<BudgetTransaction>())
        } catch {
            saveErrorMessage = "La facture n'a pas pu être vérifiée. Réessayez."
            return
        }
        guard let transaction = scheduleService.makeTransactionIfNeeded(
            from: recurring,
            occurrence: occurrence,
            existingTransactions: persistedTransactions,
            now: now
        ) else { return }
        modelContext.insert(transaction)
        modelContext.saveOrRollback { saveErrorMessage = $0 }
    }
}
