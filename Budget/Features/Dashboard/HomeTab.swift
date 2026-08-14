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
        case .expense, .taxPayment, .debtPayment: "Payé"
        case .saving: "Mis de côté"
        case .investment: "Investi"
        case .transfer: "Transféré"
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

    /// Résumé court du seul bloc mensuel. Les deux nombres viennent des
    /// occurrences et mouvements existants ; aucun total financier n'est
    /// recalculé pour l'affichage.
    static func monthProgress(
        pending: Int,
        completed: Int,
        isFuture: Bool = false
    ) -> String {
        if isFuture {
            return pending == 0 ? "Rien de prévu" : "\(pending) prévu\(pending > 1 ? "s" : "")"
        }
        switch (pending, completed) {
        case (0, 0): "Rien à faire"
        case (0, let done): "Tout est à jour · \(done) fait\(done > 1 ? "s" : "")"
        case (let todo, 0): "\(todo) à faire"
        case (let todo, let done): "\(todo) à faire · \(done) fait\(done > 1 ? "s" : "")"
        }
    }

    static func completedTransactions(
        in interval: MonthInterval,
        from transactions: [BudgetTransaction]
    ) -> [BudgetTransaction] {
        transactions
            .filter {
                $0.recurringID != nil
                    && $0.status == .posted
                    && interval.contains($0.date)
            }
            .sorted {
                if $0.date == $1.date { return $0.title < $1.title }
                return $0.date > $1.date
            }
    }

    static func plannedRegularTransactions(
        in interval: MonthInterval,
        from transactions: [BudgetTransaction]
    ) -> [BudgetTransaction] {
        transactions
            .filter {
                $0.recurringID != nil
                    && $0.status == .planned
                    && interval.contains($0.date)
            }
            .sorted {
                if $0.date == $1.date { return $0.title < $1.title }
                return $0.date < $1.date
            }
    }

    /// Une fréquence hebdomadaire peut produire plusieurs lignes dans le
    /// même mois. Seule la prochaine occurrence non couverte est validable :
    /// confirmer la troisième avant la première contredirait l'appariement
    /// chronologique du service et ferait apparaître la même date deux fois.
    static func confirmableOccurrenceIDs(
        from occurrences: [ForecastOccurrence]
    ) -> Set<String> {
        var seen = Set<UUID>()
        var result = Set<String>()
        for occurrence in occurrences.sorted(by: { $0.date < $1.date }) {
            if seen.insert(occurrence.recurringID).inserted {
                result.insert(occurrence.id)
            }
        }
        return result
    }

    static func canConfirm(date: Date, now: Date, calendar: Calendar) -> Bool {
        calendar.startOfDay(for: date) <= calendar.startOfDay(for: now)
    }
}

/// Une ligne encore attendue vient soit du forecast, soit d'un mouvement
/// régulier déjà matérialisé mais encore `planned`. Les réunir empêche une
/// opération future de disparaître simplement parce qu'elle est déjà liée.
private enum HomeMonthPendingItem: Identifiable {
    case forecast(ForecastOccurrence)
    case planned(BudgetTransaction)

    var id: String {
        switch self {
        case .forecast(let occurrence): "forecast:\(occurrence.id)"
        case .planned(let transaction): "planned:\(transaction.id.uuidString)"
        }
    }

    var date: Date {
        switch self {
        case .forecast(let occurrence): occurrence.date
        case .planned(let transaction): transaction.date
        }
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
        case .recurring: "Ça revient régulièrement"
        }
    }

    var subtitle: String {
        switch self {
        case .expense: "Courses, sortie, facture du jour"
        case .income: "Salaire, remboursement, autre revenu"
        case .setAside: "Épargne, 3e pilier ou placement"
        case .recurring: "Salaire, facture, abonnement ou épargne"
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
        let isFutureMonth = snapshot.interval.start > appContainer.dateProvider.now
        let forecast = makeForecast(interval: snapshot.interval)
        let completed = completedMonthlyTransactions(in: snapshot.interval)
        let planned = HomePilotDisplay.plannedRegularTransactions(
            in: snapshot.interval,
            from: transactions
        )
        let pending = (
            forecast.map(HomeMonthPendingItem.forecast)
                + planned.map(HomeMonthPendingItem.planned)
        ).sorted { $0.date < $1.date }

        NavigationStack {
            ZStack {
                // NU3 : cet écran est PILOTE — fond Neon Ultra, jamais Obsidian.
                NeonUltraScreenBackground()

                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        monthSelector
                        availableCard(snapshot)
                        compactAmounts(snapshot)
                        monthlyActions(
                            pending: pending,
                            completed: completed,
                            isFutureMonth: isFutureMonth
                        )
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
        let isFutureMonth = snapshot.interval.start > appContainer.dateProvider.now
        let amount = (isCurrentMonth || isFutureMonth)
            ? snapshot.available.total : snapshot.cashFlow
        let title = isCurrentMonth ? "Reste pour le mois"
            : (isFutureMonth ? "Estimation du mois" : "Résultat du mois")

        return NeonUltraElevatedCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text(title)
                        .font(NeonUltraTypography.label)
                        .foregroundStyle(NeonUltraColor.textSecondary)

                    // Montant héros SANS glow : la constitution l'interdit.
                    // Un mois passé garde son SIGNE explicite (+/−) : le sens
                    // ne repose jamais sur la seule couleur.
                    NeonUltraAmountText(
                        amount: amount,
                        hero: true,
                        signed: !isCurrentMonth && !isFutureMonth
                    )
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
                } else if isFutureMonth {
                    Text("Depuis le solde actuel, avec les revenus, paiements et mises de côté prévus pour ce mois.")
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
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

    // MARK: - Bilan du mois

    /// Les mouvements liés à une ligne régulière et déjà comptabilisés sont
    /// la preuve de ce qui a été fait. Les afficher ici ne change ni leur
    /// statut, ni le forecast, ni les soldes.
    private func completedMonthlyTransactions(in interval: MonthInterval) -> [BudgetTransaction] {
        HomePilotDisplay.completedTransactions(in: interval, from: transactions)
    }

    @ViewBuilder
    private func monthlyActions(
        pending: [HomeMonthPendingItem],
        completed: [BudgetTransaction],
        isFutureMonth: Bool
    ) -> some View {
        let confirmableOccurrenceIDs = HomePilotDisplay.confirmableOccurrenceIDs(
            from: pending.compactMap { item in
                if case .forecast(let occurrence) = item { return occurrence }
                return nil
            }
        )

        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bilan du mois")
                        .font(NeonUltraTypography.title)
                        .foregroundStyle(NeonUltraColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("home.month-summary.title")
                    Text(HomePilotDisplay.monthProgress(
                        pending: pending.count,
                        completed: completed.count,
                        isFuture: isFutureMonth
                    ))
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.textSecondary)
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

            if pending.isEmpty && completed.isEmpty {
                NeonUltraCard {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Label(
                            isFutureMonth ? "Rien de prévu"
                                : (recurrings.isEmpty ? "Ajoutez ce qui revient" : "Tout est à jour"),
                            systemImage: isFutureMonth ? "calendar"
                                : (recurrings.isEmpty ? "calendar.badge.plus" : "checkmark.circle")
                        )
                            .font(NeonUltraTypography.label)
                            .foregroundStyle(recurrings.isEmpty ? NeonUltraColor.cyan : NeonUltraColor.positive)
                        Text(
                            isFutureMonth
                                ? "Les éléments de ce mois apparaîtront ici quand ils seront prévus."
                                : (recurrings.isEmpty
                                ? "Loyer, salaire, abonnements et épargne : ajoutez-les une fois avec le bouton Ajouter."
                                : "Les revenus, paiements et mises de côté attendus apparaîtront ici.")
                        )
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                    }
                }
            } else if !pending.isEmpty {
                Text(isFutureMonth ? "Prévu ce mois" : "À faire")
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)

                let visible = Array(pending.prefix(3))
                NeonUltraCard {
                    VStack(spacing: 0) {
                        ForEach(visible) { item in
                            monthlyPendingRow(
                                item,
                                confirmableOccurrenceIDs: confirmableOccurrenceIDs
                            )
                            if item.id != visible.last?.id {
                                Divider().overlay(NeonUltraColor.border)
                            }
                        }
                    }
                }

                if pending.count > 3 {
                    Text(
                        isFutureMonth
                            ? "Et \(pending.count - 3) autre\(pending.count - 3 > 1 ? "s" : "") prévu\(pending.count - 3 > 1 ? "s" : "")."
                            : "Et \(pending.count - 3) autre\(pending.count - 3 > 1 ? "s" : "") à faire."
                    )
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                }
            }

            if !completed.isEmpty {
                Text("Fait ce mois")
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)

                let visibleCompleted = Array(completed.prefix(3))
                NeonUltraCard {
                    VStack(spacing: 0) {
                        ForEach(visibleCompleted) { transaction in
                            completedMonthlyRow(transaction)
                            if transaction.id != visibleCompleted.last?.id {
                                Divider().overlay(NeonUltraColor.border)
                            }
                        }
                    }
                }

                if completed.count > 3 {
                    Text("Et \(completed.count - 3) autre\(completed.count - 3 > 1 ? "s" : "") ce mois.")
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func monthlyPendingRow(
        _ item: HomeMonthPendingItem,
        confirmableOccurrenceIDs: Set<String>
    ) -> some View {
        switch item {
        case .forecast(let occurrence):
            monthlyActionRow(
                occurrence,
                isNextOccurrence: confirmableOccurrenceIDs.contains(occurrence.id)
            )
        case .planned(let transaction):
            plannedMonthlyRow(transaction)
        }
    }

    private func plannedMonthlyRow(_ transaction: BudgetTransaction) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    plannedMonthlyIdentity(transaction)
                    NeonUltraAmountText(amount: transaction.amount)
                    Text("Prévu")
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                }
            } else {
                HStack(spacing: BudgetSpacing.medium) {
                    plannedMonthlyIdentity(transaction)
                    Spacer(minLength: BudgetSpacing.small)
                    VStack(alignment: .trailing, spacing: 4) {
                        NeonUltraAmountText(amount: transaction.amount)
                        Text("Prévu")
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, BudgetSpacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(transaction.title), \(HomePilotDisplay.actionLabel(for: transaction.type)) le \(FinanceFormatting.swissDate(transaction.date)), prévu, \(FinanceFormatting.chf(transaction.amount))"
        )
        .accessibilityIdentifier("home.month.pending.planned.\(transaction.id.uuidString)")
    }

    private func plannedMonthlyIdentity(_ transaction: BudgetTransaction) -> some View {
        HStack(spacing: BudgetSpacing.medium) {
            Image(systemName: actionIcon(for: transaction.type))
                .frame(width: 28)
                .foregroundStyle(actionColor(for: transaction.type))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(HomePilotDisplay.actionLabel(for: transaction.type)) · \(FinanceFormatting.swissDate(transaction.date))")
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func completedMonthlyRow(_ transaction: BudgetTransaction) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    completedMonthlyIdentity(transaction)
                    NeonUltraAmountText(amount: transaction.amount)
                }
            } else {
                HStack(spacing: BudgetSpacing.medium) {
                    completedMonthlyIdentity(transaction)
                    Spacer(minLength: BudgetSpacing.small)
                    NeonUltraAmountText(amount: transaction.amount)
                }
            }
        }
        .padding(.vertical, BudgetSpacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(transaction.title), \(HomePilotDisplay.actionVerb(for: transaction.type)) ce mois, \(FinanceFormatting.chf(transaction.amount))"
        )
        .accessibilityIdentifier("home.month.completed.\(transaction.id.uuidString)")
    }

    private func completedMonthlyIdentity(_ transaction: BudgetTransaction) -> some View {
        HStack(spacing: BudgetSpacing.medium) {
            Image(systemName: actionIcon(for: transaction.type))
                .frame(width: 28)
                .foregroundStyle(actionColor(for: transaction.type))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(HomePilotDisplay.actionVerb(for: transaction.type)) ce mois")
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.positive)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func monthlyActionRow(
        _ occurrence: ForecastOccurrence,
        isNextOccurrence: Bool
    ) -> some View {
        let canConfirm = isNextOccurrence && HomePilotDisplay.canConfirm(
            date: occurrence.date,
            now: appContainer.dateProvider.now,
            calendar: appContainer.calendar
        )
        let dateReached = HomePilotDisplay.canConfirm(
            date: occurrence.date,
            now: appContainer.dateProvider.now,
            calendar: appContainer.calendar
        )
        let waitingLabel = !isNextOccurrence && dateReached
            ? "Après la précédente" : "Prévu"
        let verb = HomePilotDisplay.actionVerb(for: occurrence.type)

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    monthlyActionIdentity(occurrence)
                    NeonUltraAmountText(amount: occurrence.amount)
                    monthlyActionControl(
                        occurrence,
                        canConfirm: canConfirm,
                        verb: verb,
                        waitingLabel: waitingLabel
                    )
                }
            } else {
                HStack(spacing: BudgetSpacing.medium) {
                    monthlyActionIdentity(occurrence)
                    Spacer(minLength: BudgetSpacing.small)
                    VStack(alignment: .trailing, spacing: 4) {
                        NeonUltraAmountText(amount: occurrence.amount)
                        monthlyActionControl(
                            occurrence,
                            canConfirm: canConfirm,
                            verb: verb,
                            waitingLabel: waitingLabel
                        )
                    }
                }
            }
        }
        .padding(.vertical, BudgetSpacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.month.pending.\(occurrence.id)")
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
        verb: String,
        waitingLabel: String
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
            Text(waitingLabel)
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
