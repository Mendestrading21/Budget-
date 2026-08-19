import SwiftUI
import SwiftData

/// Small display-only aggregate used by the home screen and its tests.
/// It never changes the financial engine: committed, recurring and tax
/// amounts are still calculated by `MonthlySnapshotService`.
enum HomePilotDisplay {
    static func toPay(_ available: AvailableBreakdown) -> Decimal {
        // FE2 : « à sortir » = engagements du mois + effort fiscal du mois —
        // jamais l'écart annuel entier.
        available.committedCharges + available.recurringCharges + available.taxMonthlyEffort
    }

    /// FE2-10 (capture propriétaire, 19.08.2026) : « pourquoi sortir 600
    /// alors que je n'ai pas de facture ? » — l'effort d'impôts du mois
    /// était fondu dans « à sortir ». La décomposition NOMME chaque terme
    /// réel et tait les termes à zéro. Même phrase que la PWA.
    static func forecastDecomposition(_ available: AvailableBreakdown) -> String {
        var parts = ["\(FinanceFormatting.chf(available.liquidBalance)) maintenant"]
        let expected = available.expectedIncome + available.recurringIncome
        if expected > 0 {
            parts.append("+ \(FinanceFormatting.chf(expected)) à recevoir")
        }
        let realOut = available.committedCharges + available.recurringCharges
        if realOut > 0 {
            parts.append("− \(FinanceFormatting.chf(realOut)) à sortir")
        }
        if available.taxMonthlyEffort > 0 {
            parts.append("− \(FinanceFormatting.chf(available.taxMonthlyEffort)) d'impôts à mettre de côté")
        }
        return parts.joined(separator: " ") + "."
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
        return switch (pending, completed) {
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

    /// A13 (Les quatre familles, parité PWA) : la famille d'un mouvement du
    /// Bilan. Partition stricte — un abonnement vit dans SA famille, plus
    /// dans « Dépenses » ; chaque franc est compté une seule fois.
    static func family(for type: TransactionType, isSubscription: Bool) -> HomeFamily {
        switch type {
        case .income, .refund: .income
        case .saving, .investment: .setAside
        case .expense, .taxPayment, .debtPayment, .transfer, .adjustment:
            isSubscription ? .subscription : .expense
        }
    }
}

/// Les quatre familles du Bilan — même grille, même ordre et mêmes mots que
/// la PWA (BUDGET_FAMILLES_PLAN.md) : Rentrées, Dépenses, Abonnements,
/// Mis de côté.
enum HomeFamily: Int, CaseIterable, Identifiable {
    case income = 0
    case expense = 1
    case subscription = 2
    case setAside = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .income: "Rentrées"
        case .expense: "Dépenses"
        case .subscription: "Abonnements"
        case .setAside: "Mis de côté"
        }
    }

    /// Résumé du bloc : « 2 à faire · 1 fait », ou « Rien ce mois. »
    /// A16 (parité PWA, lot A15) : sur un mois FUTUR, l'attente se dit
    /// « prévu », jamais « à faire ».
    static func blockSummary(pending: Int, completed: Int, isFuture: Bool = false) -> String {
        var parts: [String] = []
        if pending > 0 {
            parts.append(isFuture ? "\(pending) prévu\(pending > 1 ? "s" : "")" : "\(pending) à faire")
        }
        if completed > 0 { parts.append("\(completed) fait\(completed > 1 ? "s" : "")") }
        return parts.isEmpty ? "Rien ce mois." : parts.joined(separator: " · ")
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
/// A14 (parité PWA, lot A9) : l'ordre des cas EST l'ordre affiché — celui
/// des familles : reçu, dépensé, régulier, mis de côté.
enum QuickEntryIntent: String, CaseIterable, Identifiable {
    case income
    case expense
    case recurring
    case setAside

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
    // FE2 : la position de la grande carte — le réel ou la projection.
    @State private var heroPosition: HeroPosition = .now

    enum HeroPosition: String, CaseIterable, Identifiable {
        case now, endOfMonth
        var id: String { rawValue }
        var title: String {
            switch self {
            case .now: "Maintenant"
            case .endOfMonth: "Fin du mois"
            }
        }
    }

    private var heroPositionPicker: some View {
        HStack(spacing: 6) {
            ForEach(HeroPosition.allCases) { position in
                Button(position.title) {
                    heroPosition = position
                }
                .font(NeonUltraTypography.label)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(heroPosition == position ? NeonUltraColor.tintViolet : Color.clear)
                .foregroundStyle(heroPosition == position ? NeonUltraColor.textPrimary : NeonUltraColor.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: NeonUltraRadius.control, style: .continuous)
                        .stroke(heroPosition == position ? NeonUltraColor.violet : NeonUltraColor.border, lineWidth: 1)
                )
                .accessibilityAddTraits(heroPosition == position ? [.isSelected] : [])
                .accessibilityIdentifier("home.hero.\(position.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Vue du mois")
    }

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
            .navigationBarTitleDisplayMode(.inline)
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
                BudgetIcon(.previous, tone: .brand, style: .plain)
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
                BudgetIcon(.next, tone: .brand, style: .plain)
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
        // FE2 (cahier propriétaire) : sur le mois COURANT, la carte a deux
        // positions — le RÉEL du moment et la PROJECTION de fin de mois.
        // Une projection n'est jamais présentée comme de l'argent possédé.
        let showNow = isCurrentMonth && heroPosition == .now
        let amount = isCurrentMonth
            ? (showNow ? snapshot.available.liquidBalance : snapshot.available.total)
            : (isFutureMonth ? snapshot.available.total : snapshot.cashFlow)
        let title = isCurrentMonth
            ? (showNow ? "Disponible maintenant" : "Prévu fin du mois")
            : (isFutureMonth ? "Estimation du mois" : "Résultat du mois")

        return NeonUltraElevatedCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                if isCurrentMonth {
                    heroPositionPicker
                }
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

                if isCurrentMonth, showNow {
                    Text("Sur vos comptes utilisables au quotidien.")
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if isCurrentMonth {
                    Text(HomePilotDisplay.forecastDecomposition(snapshot.available))
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(
                        amount < 0
                            ? "Il manque \(FinanceFormatting.chf(-amount)) pour finir le mois."
                            : "\(FinanceFormatting.chf(snapshot.dailyAvailableBudget)) par jour pendant \(snapshot.daysRemaining) jour\(snapshot.daysRemaining > 1 ? "s" : "")."
                    )
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(amount < 0 ? NeonUltraColor.warning : NeonUltraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                if isCurrentMonth {

                    // A13 (parité PWA, lot A3) : où en est le mois — jour
                    // calendaire réel sur le nombre de jours du mois.
                    // Donnée exacte, aucune animation permanente.
                    let now = appContainer.dateProvider.now
                    let dayOfMonth = appContainer.calendar.component(.day, from: now)
                    let daysInMonth = appContainer.calendar.range(of: .day, in: .month, for: now)?.count ?? 30
                    VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                        ProgressView(value: Double(dayOfMonth), total: Double(daysInMonth))
                            .tint(NeonUltraColor.violet)
                        Text("Jour \(dayOfMonth) sur \(daysInMonth)")
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textTertiary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Jour \(dayOfMonth) sur \(daysInMonth)")
                } else if isFutureMonth {
                    Text("Depuis le solde actuel, avec les revenus, paiements et mises de côté prévus pour ce mois.")
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    isPresentingQuickEntry = true
                } label: {
                    Label("Ajouter", systemImage: BudgetGlyph.add.systemName)
                }
                .buttonStyle(NeonUltraPrimaryButtonStyle())
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
            compactMetric(
                "Reçu",
                snapshot.totalIncome,
                glyph: .income,
                tone: .positive,
                emphasis: .positive
            )
            Divider().overlay(NeonUltraColor.border)
            compactMetric(
                "Dépensé",
                snapshot.totalLivingExpenses,
                glyph: .expense,
                tone: .negative,
                emphasis: .negative
            )
            Divider().overlay(NeonUltraColor.border)
            compactMetric(
                "Mis de côté",
                snapshot.totalSavings + snapshot.totalInvestments,
                glyph: .setAside,
                tone: .brand,
                emphasis: .neutral
            )
        }
    }

    private func compactAmountsVertical(_ snapshot: MonthSnapshot) -> some View {
        VStack(spacing: BudgetSpacing.small) {
            compactMetricRow(
                "Reçu",
                snapshot.totalIncome,
                glyph: .income,
                tone: .positive,
                emphasis: .positive
            )
            compactMetricRow(
                "Dépensé",
                snapshot.totalLivingExpenses,
                glyph: .expense,
                tone: .negative,
                emphasis: .negative
            )
            compactMetricRow(
                "Mis de côté",
                snapshot.totalSavings + snapshot.totalInvestments,
                glyph: .setAside,
                tone: .brand,
                emphasis: .neutral
            )
        }
    }

    private func compactMetric(
        _ title: String,
        _ amount: Decimal,
        glyph: BudgetGlyph,
        tone: BudgetIconTone,
        emphasis: AmountEmphasis
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            BudgetIcon(glyph, tone: tone)
                .padding(.bottom, BudgetSpacing.micro)
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
        glyph: BudgetGlyph,
        tone: BudgetIconTone,
        emphasis: AmountEmphasis
    ) -> some View {
        HStack(spacing: BudgetSpacing.compact) {
            BudgetIcon(glyph, tone: tone)
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

    /// A13 : la famille d'une ligne du Bilan — un abonnement se reconnaît
    /// par sa définition régulière (`isSubscription`), jamais deviné.
    private func isSubscriptionRecurring(_ id: UUID?) -> Bool {
        guard let id else { return false }
        return recurrings.first(where: { $0.id == id })?.isSubscription == true
    }

    private func family(of item: HomeMonthPendingItem) -> HomeFamily {
        switch item {
        case .forecast(let occurrence):
            HomePilotDisplay.family(
                for: occurrence.type,
                isSubscription: isSubscriptionRecurring(occurrence.recurringID)
            )
        case .planned(let transaction):
            HomePilotDisplay.family(
                for: transaction.type,
                isSubscription: isSubscriptionRecurring(transaction.recurringID)
            )
        }
    }

    private func family(of transaction: BudgetTransaction) -> HomeFamily {
        HomePilotDisplay.family(
            for: transaction.type,
            isSubscription: isSubscriptionRecurring(transaction.recurringID)
        )
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

            // A13/A16 (parité PWA, lots A7 et A15) : le Bilan se lit en
            // QUATRE blocs — Rentrées, Dépenses, Abonnements, Mis de côté —
            // sur le mois courant, passé ET futur. Chaque bloc porte ses
            // lignes à faire ET ses lignes faites, qui restent dans leur
            // bloc. Sur un mois futur, chaque bloc dit « prévu » et le seul
            // geste offert est « Planifier » : rien n'est comptabilisé
            // d'avance.
            if !(pending.isEmpty && completed.isEmpty) {
                ForEach(HomeFamily.allCases) { familyCase in
                    familyBlock(
                        familyCase,
                        pending: pending.filter { family(of: $0) == familyCase },
                        completed: completed.filter { family(of: $0) == familyCase },
                        confirmableOccurrenceIDs: confirmableOccurrenceIDs,
                        isFutureMonth: isFutureMonth
                    )
                }
            } else {
                NeonUltraCard {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        HStack(spacing: BudgetSpacing.compact) {
                            BudgetIcon(
                                isFutureMonth ? .month
                                    : (recurrings.isEmpty ? .recurring : .success),
                                tone: (isFutureMonth || recurrings.isEmpty) ? .brand : .positive
                            )
                            Text(
                                isFutureMonth ? "Rien de prévu"
                                    : (recurrings.isEmpty ? "Ajoutez ce qui revient" : "Tout est à jour")
                            )
                            .font(NeonUltraTypography.label)
                            .foregroundStyle(
                                (isFutureMonth || recurrings.isEmpty)
                                    ? NeonUltraColor.cyan
                                    : NeonUltraColor.positive
                            )
                        }
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
            }
        }
    }

    /// A13 : UN bloc de famille — son titre, son résumé, ses lignes à faire
    /// (bouton un appui) et ses lignes déjà faites, qui restent chez lui.
    @ViewBuilder
    private func familyBlock(
        _ familyCase: HomeFamily,
        pending: [HomeMonthPendingItem],
        completed: [BudgetTransaction],
        confirmableOccurrenceIDs: Set<String>,
        isFutureMonth: Bool
    ) -> some View {
        let visiblePending = Array(pending.prefix(5))
        let visibleCompleted = Array(completed.prefix(3))

        NeonUltraCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(familyCase.title)
                        .font(NeonUltraTypography.label)
                        .foregroundStyle(NeonUltraColor.textSecondary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text(HomeFamily.blockSummary(
                        pending: pending.count,
                        completed: completed.count,
                        isFuture: isFutureMonth
                    ))
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(NeonUltraColor.textTertiary)
                }

                if !visiblePending.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(visiblePending) { item in
                            monthlyPendingRow(
                                item,
                                confirmableOccurrenceIDs: confirmableOccurrenceIDs,
                                isFutureMonth: isFutureMonth
                            )
                            if item.id != visiblePending.last?.id {
                                Divider().overlay(NeonUltraColor.border)
                            }
                        }
                    }
                    if pending.count > visiblePending.count {
                        let reste = pending.count - visiblePending.count
                        Text(
                            isFutureMonth
                                ? "Et \(reste) autre\(reste > 1 ? "s" : "") prévu\(reste > 1 ? "s" : "")."
                                : "Et \(reste) autre\(reste > 1 ? "s" : "") à faire."
                        )
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                    }
                }

                if !visibleCompleted.isEmpty {
                    if !visiblePending.isEmpty {
                        Divider().overlay(NeonUltraColor.border)
                    }
                    VStack(spacing: 0) {
                        ForEach(visibleCompleted) { transaction in
                            completedMonthlyRow(transaction)
                            if transaction.id != visibleCompleted.last?.id {
                                Divider().overlay(NeonUltraColor.border)
                            }
                        }
                    }
                    if completed.count > visibleCompleted.count {
                        Text("Et \(completed.count - visibleCompleted.count) autre\(completed.count - visibleCompleted.count > 1 ? "s" : "") ce mois.")
                            .font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(familyCase.title) — \(HomeFamily.blockSummary(pending: pending.count, completed: completed.count, isFuture: isFutureMonth))"
        )
        .accessibilityIdentifier("home.family.\(familyCase.rawValue)")
    }

    @ViewBuilder
    private func monthlyPendingRow(
        _ item: HomeMonthPendingItem,
        confirmableOccurrenceIDs: Set<String>,
        isFutureMonth: Bool
    ) -> some View {
        switch item {
        case .forecast(let occurrence):
            monthlyActionRow(
                occurrence,
                isNextOccurrence: confirmableOccurrenceIDs.contains(occurrence.id),
                isFutureMonth: isFutureMonth
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
            BudgetIcon(
                transaction.type.budgetGlyph,
                tone: transaction.type.budgetPlannedIconTone
            )

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
            BudgetIcon(
                transaction.type.budgetGlyph,
                tone: transaction.type.budgetIconTone
            )

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
        isNextOccurrence: Bool,
        isFutureMonth: Bool
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
                        canPlan: isFutureMonth,
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
                            canPlan: isFutureMonth,
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
            BudgetIcon(
                occurrence.type.budgetGlyph,
                tone: occurrence.type.budgetPlannedIconTone
            )

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
        canPlan: Bool,
        verb: String,
        waitingLabel: String
    ) -> some View {
        if canConfirm {
            actionButton(verb, for: occurrence)
        } else if canPlan {
            // A16 (parité PWA, lot A15) : sur un mois FUTUR, le geste un
            // appui est « Planifier » — le mouvement est créé PRÉVU
            // (la date future garde le statut planned), jamais reçu ni
            // payé d'avance.
            actionButton("Planifier", for: occurrence)
        } else {
            Text(waitingLabel)
                .font(NeonUltraTypography.meta)
                .foregroundStyle(NeonUltraColor.textSecondary)
        }
    }

    /// Action de ligne : surface mate + bordure, jamais le dégradé — il
    /// reste réservé à l'action principale. A13 (parité PWA, lot A6) : le
    /// bouton porte la couleur de son SENS — vert pour recevoir, corail
    /// pour payer, violet neutre pour mettre de côté.
    private func actionButton(
        _ label: String,
        for occurrence: ForecastOccurrence
    ) -> some View {
        Button(label) {
            post(occurrence)
        }
        .font(NeonUltraTypography.label)
        .foregroundStyle(actionForeground(for: occurrence.type))
        .frame(minHeight: 44)
        .padding(.horizontal, BudgetSpacing.small)
        .background(actionTint(for: occurrence.type))
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
        .accessibilityLabel("\(occurrence.title) : \(label)")
    }

    /// A13 : couleurs de SENS des boutons un-appui (sémantique stricte —
    /// jamais décorative). L'abonnement est une sortie : corail comme
    /// « Payé ».
    private func actionTint(for type: TransactionType) -> Color {
        switch HomePilotDisplay.family(for: type, isSubscription: false) {
        case .income: NeonUltraColor.tintPositive
        case .setAside: NeonUltraColor.tintViolet
        case .expense, .subscription: NeonUltraColor.tintNegative
        }
    }

    private func actionForeground(for type: TransactionType) -> Color {
        switch HomePilotDisplay.family(for: type, isSubscription: false) {
        case .income: NeonUltraColor.positive
        case .setAside: NeonUltraColor.textPrimary
        case .expense, .subscription: NeonUltraColor.negative
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
                                        BudgetIcon(
                                            intent.budgetGlyph,
                                            tone: intent.budgetIconTone,
                                            style: .control
                                        )

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

                                        BudgetIcon(.next, style: .plain)
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
