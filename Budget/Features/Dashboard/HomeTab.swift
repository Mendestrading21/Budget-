import SwiftUI
import SwiftData

/// Small display-only aggregate used by the home screen and its tests.
/// It never changes the financial engine: committed, recurring and tax
/// amounts are still calculated by `MonthlySnapshotService`.
enum HomePilotDisplay {
    static func toPay(_ available: AvailableBreakdown) -> Decimal {
        available.committedCharges + available.recurringCharges + available.taxReserveGap
    }

    /// Vocabulaire de confirmation du rituel mensuel. Le type financier reste
    /// la source de vérité ; seule sa traduction pour l'accueil vit ici.
    static func actionVerb(for type: TransactionType) -> String {
        switch type {
        case .income, .refund: "Reçu"
        case .expense, .taxPayment, .debtPayment: "Payée"
        case .saving: "Mis de côté"
        case .investment: "Versé"
        case .transfer: "Effectué"
        case .adjustment: "Confirmé"
        }
    }

    static func actionLabel(for type: TransactionType) -> String {
        switch type {
        case .income, .refund: "À recevoir"
        case .expense, .taxPayment, .debtPayment: "À payer"
        case .saving: "À mettre de côté"
        case .investment: "À investir"
        case .transfer: "À transférer"
        case .adjustment: "À confirmer"
        }
    }

    static func canConfirm(date: Date, now: Date, calendar: Calendar) -> Bool {
        calendar.startOfDay(for: date) <= calendar.startOfDay(for: now)
    }
}

/// Les quatre intentions quotidiennes. Elles pilotent seulement la saisie :
/// les types persistés et leurs règles financières restent inchangés.
enum QuickEntryIntent: String, CaseIterable, Identifiable {
    case expense
    case income
    case setAside
    case recurring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "J'ai dépensé"
        case .income: "J'ai reçu"
        case .setAside: "J'ai mis de côté"
        case .recurring: "Ça revient chaque mois"
        }
    }

    var subtitle: String {
        switch self {
        case .expense: "Courses, sortie, facture du jour"
        case .income: "Salaire, remboursement, autre revenu"
        case .setAside: "Épargne, 3e pilier ou placement"
        case .recurring: "Loyer, abonnement, salaire ou épargne"
        }
    }

    var systemImage: String {
        switch self {
        case .expense: "arrow.up.circle"
        case .income: "arrow.down.circle"
        case .setAside: "building.columns"
        case .recurring: "calendar.badge.clock"
        }
    }

    var transactionType: TransactionType? {
        switch self {
        case .expense: .expense
        case .income: .income
        case .setAside: .saving
        case .recurring: nil
        }
    }
}

/// A deliberately simple home screen.
///
/// The first viewport answers only four questions:
/// - How much money is available?
/// - How much came in?
/// - How much was spent?
/// - How much was set aside?
///
/// Everything still expected this month then lives in one chronological
/// checklist, with a verb that matches the real nature of the movement.
struct HomeTab: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Query(sort: \BudgetTransaction.date, order: .reverse)
    private var transactions: [BudgetTransaction]
    @Query private var accounts: [Account]
    @Query private var households: [Household]
    @Query private var recurrings: [RecurringTransaction]
    @Query private var taxProfiles: [TaxProfile]
    @Query private var taxProvisions: [TaxProvision]
    /// Pour l'annonce de progrès quand « Marquer payée » alimente un
    /// compte relié à un objectif (mise de côté mensuelle).
    @Query private var goals: [FinancialGoal]

    @State private var monthAnchor: Date?
    @State private var saveErrorMessage: String?
    @State private var isPresentingQuickEntry = false

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
                        compactAmounts(snapshot)
                        monthlyActions(forecast: forecast)
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
                .neonUltraScrollClearance()
            }
            .navigationTitle("Mois")
            .alert(
                saveErrorMessage ?? "",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $isPresentingQuickEntry) {
                QuickEntrySheet(prefilledDate: currentAnchor)
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
        let title = isCurrentMonth ? "Disponible jusqu'à la fin du mois" : "Reste du mois"

        return NeonUltraElevatedCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text(title)
                        .font(NeonUltraTypography.label)
                        .foregroundStyle(NeonUltraColor.textSecondary)

                    // Montant héros SANS glow : la constitution l'interdit.
                    // Un mois passé garde son SIGNE explicite (+/−) : le sens
                    // ne repose jamais sur la seule couleur.
                    NeonUltraAmountText(amount: amount, hero: true, signed: !isCurrentMonth)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(title) : \(FinanceFormatting.chf(amount))")

                if isCurrentMonth {
                    Text(
                        amount < 0
                            ? "Il manque \(FinanceFormatting.chf(-amount)) pour finir le mois."
                            : "\(FinanceFormatting.chf(snapshot.dailyAvailableBudget)) par jour pendant \(snapshot.daysRemaining) jour\(snapshot.daysRemaining > 1 ? "s" : "")."
                    )
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(amount < 0 ? NeonUltraColor.warning : NeonUltraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    isPresentingQuickEntry = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                        .font(NeonUltraTypography.label)
                        .foregroundStyle(NeonUltraColor.textOnCta)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(NeonUltraGradient.cta)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: NeonUltraRadius.control,
                                style: .continuous
                            )
                        )
                }
                .accessibilityLabel("Ajouter une opération")
                .accessibilityIdentifier("home.quick-entry")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Trois chiffres, une seule surface. `ViewThatFits` garde la lecture
    /// horizontale en taille normale et bascule en lignes sous Dynamic Type.
    private func compactAmounts(_ snapshot: MonthSnapshot) -> some View {
        return NeonUltraCard {
            if dynamicTypeSize.isAccessibilitySize {
                compactAmountsVertical(snapshot)
            } else {
                ViewThatFits(in: .horizontal) {
                    compactAmountsHorizontal(snapshot)
                    compactAmountsVertical(snapshot)
                }
            }
        }
    }

    private func compactAmountsHorizontal(_ snapshot: MonthSnapshot) -> some View {
        HStack(alignment: .top, spacing: BudgetSpacing.small) {
            compactMetric("Reçu", snapshot.totalIncome, emphasis: .positive)
            Divider().overlay(NeonUltraColor.border)
            compactMetric("Dépensé", snapshot.totalLivingExpenses, emphasis: .negative)
            Divider().overlay(NeonUltraColor.border)
            compactMetric(
                "Mis de côté",
                snapshot.totalSavings + snapshot.totalInvestments,
                emphasis: .neutral
            )
        }
    }

    private func compactAmountsVertical(_ snapshot: MonthSnapshot) -> some View {
        VStack(spacing: BudgetSpacing.small) {
            compactMetricRow("Reçu", snapshot.totalIncome, emphasis: .positive)
            compactMetricRow("Dépensé", snapshot.totalLivingExpenses, emphasis: .negative)
            compactMetricRow(
                "Mis de côté",
                snapshot.totalSavings + snapshot.totalInvestments,
                emphasis: .neutral
            )
        }
    }

    private func compactMetric(
        _ title: String,
        _ amount: Decimal,
        emphasis: AmountEmphasis
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(NeonUltraTypography.meta)
                .foregroundStyle(NeonUltraColor.textSecondary)
            Text(FinanceFormatting.chf(amount))
                .font(NeonUltraTypography.label.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(color(for: emphasis))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) : \(FinanceFormatting.chf(amount))")
    }

    private func compactMetricRow(
        _ title: String,
        _ amount: Decimal,
        emphasis: AmountEmphasis
    ) -> some View {
        HStack {
            Text(title)
                .font(NeonUltraTypography.label)
                .foregroundStyle(NeonUltraColor.textSecondary)
            Spacer()
            Text(FinanceFormatting.chf(amount))
                .font(NeonUltraTypography.label.monospacedDigit())
                .foregroundStyle(color(for: emphasis))
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) : \(FinanceFormatting.chf(amount))")
    }

    private enum AmountEmphasis {
        case positive
        case negative
        case neutral
    }

    private func color(for emphasis: AmountEmphasis) -> Color {
        switch emphasis {
        case .positive: NeonUltraColor.positive
        case .negative: NeonUltraColor.negative
        case .neutral: NeonUltraColor.textPrimary
        }
    }

    // MARK: - Ce qu'il reste à faire ce mois

    @ViewBuilder
    private func monthlyActions(forecast: [ForecastOccurrence]) -> some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("À faire ce mois")
                        .font(NeonUltraTypography.title)
                        .foregroundStyle(NeonUltraColor.textPrimary)
                    if !forecast.isEmpty {
                        Text("\(forecast.count) action\(forecast.count > 1 ? "s" : "") restante\(forecast.count > 1 ? "s" : "")")
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

            if forecast.isEmpty {
                NeonUltraCard {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Label(
                            recurrings.isEmpty ? "Ajoutez ce qui revient" : "Tout est à jour",
                            systemImage: recurrings.isEmpty ? "calendar.badge.plus" : "checkmark.circle"
                        )
                            .font(NeonUltraTypography.label)
                            .foregroundStyle(recurrings.isEmpty ? NeonUltraColor.cyan : NeonUltraColor.positive)
                        Text(
                            recurrings.isEmpty
                                ? "Loyer, salaire, abonnements et épargne : ajoutez-les une fois avec le bouton Ajouter."
                                : "Les revenus, factures et mises de côté encore attendus apparaîtront ici."
                        )
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                    }
                }
            } else {
                let visible = Array(forecast.prefix(6))
                NeonUltraCard {
                    VStack(spacing: 0) {
                        ForEach(visible) { occurrence in
                            monthlyActionRow(occurrence)
                            if occurrence.id != visible.last?.id {
                                Divider().overlay(NeonUltraColor.border)
                            }
                        }
                    }
                }

                if forecast.count > 6 {
                    NavigationLink {
                        RecurringListView()
                    } label: {
                        Text("Voir les \(forecast.count) actions")
                            .font(NeonUltraTypography.label)
                            .foregroundStyle(NeonUltraColor.cyan)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
        }
    }

    private func monthlyActionRow(_ occurrence: ForecastOccurrence) -> some View {
        let canConfirm = HomePilotDisplay.canConfirm(
            date: occurrence.date,
            now: appContainer.dateProvider.now,
            calendar: appContainer.calendar
        )
        let verb = HomePilotDisplay.actionVerb(for: occurrence.type)

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    monthlyActionIdentity(occurrence)
                    NeonUltraAmountText(amount: occurrence.amount)
                    monthlyActionControl(occurrence, canConfirm: canConfirm, verb: verb)
                }
            } else {
                HStack(spacing: BudgetSpacing.medium) {
                    monthlyActionIdentity(occurrence)
                    Spacer(minLength: BudgetSpacing.small)
                    VStack(alignment: .trailing, spacing: 4) {
                        NeonUltraAmountText(amount: occurrence.amount)
                        monthlyActionControl(occurrence, canConfirm: canConfirm, verb: verb)
                    }
                }
            }
        }
        .padding(.vertical, BudgetSpacing.small)
        .accessibilityElement(children: .contain)
    }

    private func monthlyActionIdentity(_ occurrence: ForecastOccurrence) -> some View {
        HStack(spacing: BudgetSpacing.medium) {
            Image(systemName: actionIcon(for: occurrence.type))
                .frame(width: 28)
                .foregroundStyle(actionColor(for: occurrence.type))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(occurrence.title)
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(HomePilotDisplay.actionLabel(for: occurrence.type)) · \(FinanceFormatting.swissDate(occurrence.date))")
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func monthlyActionControl(
        _ occurrence: ForecastOccurrence,
        canConfirm: Bool,
        verb: String
    ) -> some View {
        if canConfirm {
            // Action de ligne : surface mate + bordure, jamais le dégradé —
            // il reste réservé à l'action principale.
            Button(verb) {
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
            .accessibilityLabel("\(occurrence.title) : \(verb)")
        } else {
            Text("Prévu")
                .font(NeonUltraTypography.meta)
                .foregroundStyle(NeonUltraColor.textSecondary)
        }
    }

    private func actionIcon(for type: TransactionType) -> String {
        switch type {
        case .income, .refund: "arrow.down.circle"
        case .expense, .taxPayment, .debtPayment: "calendar"
        case .saving, .investment: "building.columns"
        case .transfer: "arrow.left.arrow.right"
        case .adjustment: "slider.horizontal.3"
        }
    }

    private func actionColor(for type: TransactionType) -> Color {
        switch type {
        case .income, .refund: NeonUltraColor.positive
        case .expense, .taxPayment, .debtPayment: NeonUltraColor.warning
        case .saving, .investment: NeonUltraColor.cyan
        case .transfer, .adjustment: NeonUltraColor.textSecondary
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
            saveErrorMessage = "Cette action n'a pas pu être vérifiée. Réessayez."
            return
        }
        guard let transaction = scheduleService.makeTransactionIfNeeded(
            from: recurring,
            occurrence: occurrence,
            existingTransactions: persistedTransactions,
            now: now
        ) else { return }
        // Photo AVANT l'écriture : confirmer une mise de côté mensuelle
        // fait avancer le même objectif que la saisie manuelle,
        // et doit le dire pareil (parité web, 10.08.2026).
        let goalService = GoalProgressService(balanceService: appContainer.balanceService)
        let goalsBefore = goalService.snapshotCurrents(goals: goals)
        modelContext.insert(transaction)
        if modelContext.saveOrRollback(onError: { saveErrorMessage = $0 }),
           transaction.status == .posted,
           let progress = goalService.progressMessage(
               destination: transaction.destinationAccount,
               goals: goals,
               before: goalsBefore
           ) {
            appContainer.goalProgressMessage = progress
        }
    }
}

/// Une seule feuille locale pour choisir l'intention avant de montrer les
/// champs. Le choix change la présentation, jamais les règles métier.
struct QuickEntrySheet: View {
    let prefilledDate: Date
    var prefilledAccount: Account? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIntent: QuickEntryIntent?

    var body: some View {
        Group {
            if let selectedIntent {
                destination(for: selectedIntent)
            } else {
                chooser
            }
        }
    }

    private var chooser: some View {
        NavigationStack {
            ZStack {
                NeonUltraScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                        Text("Que voulez-vous ajouter ?")
                            .font(NeonUltraTypography.title)
                            .foregroundStyle(NeonUltraColor.textPrimary)

                        ForEach(QuickEntryIntent.allCases) { intent in
                            Button {
                                selectedIntent = intent
                            } label: {
                                NeonUltraCard {
                                    HStack(spacing: BudgetSpacing.medium) {
                                        Image(systemName: intent.systemImage)
                                            .font(.title3.weight(.semibold))
                                            .foregroundStyle(NeonUltraColor.cyan)
                                            .frame(width: 32)
                                            .accessibilityHidden(true)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(intent.title)
                                                .font(NeonUltraTypography.label)
                                                .foregroundStyle(NeonUltraColor.textPrimary)
                                            Text(intent.subtitle)
                                                .font(NeonUltraTypography.meta)
                                                .foregroundStyle(NeonUltraColor.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }

                                        Spacer(minLength: BudgetSpacing.small)

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(NeonUltraColor.textSecondary)
                                            .accessibilityHidden(true)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(intent.title). \(intent.subtitle)")
                            .accessibilityIdentifier("quick-entry.\(intent.rawValue)")
                        }
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
            }
            .navigationTitle("Ajouter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .tint(NeonUltraColor.cyan)
        }
    }

    @ViewBuilder
    private func destination(for intent: QuickEntryIntent) -> some View {
        if intent == .recurring {
            RecurringFormView(mode: .create)
        } else {
            TransactionFormView(
                mode: .create(prefilledAccount: prefilledAccount),
                prefilledType: intent.transactionType,
                prefilledDate: prefilledDate,
                guidedIntent: intent
            )
        }
    }
}
