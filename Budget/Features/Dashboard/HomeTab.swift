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
                // NU3 : cet écran est PILOTE — fond Neon Ultra, jamais Obsidian.
                NeonUltraScreenBackground()

                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        monthSelector
                        availableCard(snapshot)
                        essentialAmounts(snapshot)
                        monthlyBills(forecast: forecast, interval: snapshot.interval)
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
                .neonUltraScrollClearance()
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
            .font(NeonUltraTypography.title)
            .foregroundStyle(NeonUltraColor.textPrimary)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Mois suivant")
        }
        .tint(NeonUltraColor.cyan)
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

        return NeonUltraElevatedCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text(title)
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textSecondary)

                // Montant héros SANS glow : la constitution l'interdit.
                // Un mois passé garde son SIGNE explicite (+/−) : le sens
                // ne repose jamais sur la seule couleur.
                NeonUltraAmountText(amount: amount, hero: true, signed: !isCurrentMonth)

                if isCurrentMonth, snapshot.daysRemaining > 0 {
                    Text("\(FinanceFormatting.chf(snapshot.dailyAvailableBudget)) par jour")
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
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
        NeonUltraCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(NeonUltraColor.textSecondary)
                    .accessibilityHidden(true)

                Text(FinanceFormatting.chf(amount))
                    .font(NeonUltraTypography.amount)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(color(for: emphasis))

                Text(title)
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textSecondary)
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
        case .positive: NeonUltraColor.positive
        case .negative: NeonUltraColor.negative
        case .warning: NeonUltraColor.warning
        case .neutral: NeonUltraColor.textPrimary
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
                        .font(NeonUltraTypography.title)
                        .foregroundStyle(NeonUltraColor.textPrimary)
                    if check.total > 0 {
                        Text("\(check.done) sur \(check.total) payées")
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                    }
                }

                Spacer()

                NavigationLink {
                    RecurringListView()
                } label: {
                    Text("Gérer")
                        .font(NeonUltraTypography.label)
                        .foregroundStyle(NeonUltraColor.cyan)
                        .frame(minHeight: 44)
                }
            }

            if check.total > 0 {
                ProgressView(value: Double(check.done), total: Double(check.total))
                    .tint(check.done == check.total ? NeonUltraColor.positive : NeonUltraColor.violet)
                    .accessibilityLabel("Factures payées")
                    .accessibilityValue("\(check.done) sur \(check.total)")
            }

            if expenses.isEmpty {
                NeonUltraCard {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text("Aucune facture à payer")
                            .font(NeonUltraTypography.label)
                            .foregroundStyle(NeonUltraColor.textPrimary)
                        Text("Ajoutez votre loyer, vos assurances ou vos abonnements une seule fois. Ils reviendront automatiquement chaque mois.")
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textSecondary)

                        // SEUL dégradé de l'écran quand le héros n'a rien à
                        // dire : un point focal lumineux, jamais deux.
                        NavigationLink {
                            RecurringListView()
                        } label: {
                            Label("Ajouter une transaction mensuelle", systemImage: "plus")
                                .font(NeonUltraTypography.label)
                                .foregroundStyle(NeonUltraColor.textOnCta)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(NeonUltraGradient.cta)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: NeonUltraRadius.control,
                                        style: .continuous
                                    )
                                )
                        }
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
                            .font(NeonUltraTypography.label)
                            .foregroundStyle(NeonUltraColor.cyan)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
        }
    }

    private func recurringBillRow(_ occurrence: ForecastOccurrence) -> some View {
        NeonUltraCard {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: "calendar")
                    .frame(width: 28)
                    .foregroundStyle(NeonUltraColor.warning)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(occurrence.title)
                        .font(NeonUltraTypography.label)
                        .foregroundStyle(NeonUltraColor.textPrimary)
                        .lineLimit(1)
                    Text(FinanceFormatting.swissDate(occurrence.date))
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                }

                Spacer(minLength: BudgetSpacing.small)

                VStack(alignment: .trailing, spacing: 4) {
                    NeonUltraAmountText(amount: occurrence.amount)

                    // Action de ligne : surface mate + bordure, jamais le
                    // dégradé — il reste réservé à l'action principale.
                    Button("Payée") {
                        post(occurrence)
                    }
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textPrimary)
                    .frame(minHeight: 44)
                    .padding(.horizontal, BudgetSpacing.small)
                    .background(NeonUltraColor.surfaceFallback)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: NeonUltraRadius.control,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: NeonUltraRadius.control,
                            style: .continuous
                        )
                        .stroke(NeonUltraColor.border, lineWidth: 1)
                    )
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
