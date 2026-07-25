import SwiftUI
import SwiftData
import Charts

/// Patrimoine: full net worth with visible decomposition, historical
/// trend, and CRUD for non-account assets and standalone debts.
struct NetWorthView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query private var accounts: [Account]
    @Query(sort: \Asset.createdAt) private var assets: [Asset]
    @Query private var pensions: [PensionAsset]
    @Query(sort: \Liability.createdAt) private var liabilities: [Liability]
    @Query(sort: \NetWorthSnapshot.date) private var snapshots: [NetWorthSnapshot]

    @Query private var transactions: [BudgetTransaction]

    @State private var editedAsset: Asset?
    @State private var editedLiability: Liability?
    @State private var isPresentingNewAsset = false
    @State private var isPresentingNewLiability = false

    /// Profil d'hypothèses du « chemin » — un réglage d'affichage, pas
    /// une donnée financière : UserDefaults suffit.
    @AppStorage("projectionProfile") private var projectionProfileRaw = WealthProjectionService.Profile.balanced.rawValue
    /// L8 correctif : dernière lecture CONSERVÉE après le geste — le mois
    /// choisi reste affiché quand le doigt se lève (même contrat que la
    /// PWA), et l'état est injectable pour les preuves de rendu.
    @State private var heldTrendSelection: Date?

    init(initialTrendSelection: Date? = nil) {
        _heldTrendSelection = State(initialValue: initialTrendSelection)
    }

    private var projectionProfile: WealthProjectionService.Profile {
        WealthProjectionService.Profile(rawValue: projectionProfileRaw) ?? .balanced
    }

    private var service: NetWorthService {
        NetWorthService(calendar: appContainer.calendar, balanceService: appContainer.balanceService)
    }

    private var breakdown: NetWorthBreakdown {
        service.breakdown(accounts: accounts, assets: assets, pensions: pensions, liabilities: liabilities)
    }

    /// « Le chemin » : patrimoine projeté à 5/10/20 ans — soldes actuels
    /// + rythme réel des versements de l'année, capitalisés par classe
    /// selon le profil choisi. Une simulation, jamais une promesse.
    private var projectionCard: some View {
        let projectionService = WealthProjectionService()
        let contributionService = ContributionService(calendar: appContainer.calendar)
        let now = appContainer.dateProvider.now
        let monthsElapsed = max(1, appContainer.calendar.component(.month, from: now))
        let classes: [(kinds: [AccountType], rate: Decimal)] = [
            ([.savings], projectionProfile.savingsRate),
            ([.broker], projectionProfile.brokerRate),
            ([.pillar3a, .pillar3b, .occupationalPension], projectionProfile.pensionRate),
        ]
        func projected(years: Int) -> Decimal {
            var total: Decimal = .zero
            var projectedClasses: Decimal = .zero
            for cls in classes {
                let members = accounts.filter { $0.isActive && cls.kinds.contains($0.type) }
                let balance = members.reduce(Decimal.zero) { $0 + appContainer.balanceService.balance(of: $1) }
                let yearContribution = members.reduce(Decimal.zero) {
                    $0 + contributionService.summary(of: $1, movements: transactions, now: now).currentYear
                }
                projectedClasses += balance
                total += projectionService.futureValue(
                    balance: balance,
                    monthlyContribution: yearContribution / Decimal(monthsElapsed),
                    annualRate: cls.rate,
                    years: years
                )
            }
            // Le reste du patrimoine (liquidités, actifs, prévoyance
            // manuelle, dettes) reste constant — honnête et affiché.
            return total + breakdown.netWorth - projectedClasses
        }
        return GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Le chemin — patrimoine projeté")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                Picker("Profil d'hypothèses", selection: $projectionProfileRaw) {
                    Text("Prudent").tag(WealthProjectionService.Profile.prudent.rawValue)
                    Text("Équilibré").tag(WealthProjectionService.Profile.balanced.rawValue)
                    Text("Ambitieux").tag(WealthProjectionService.Profile.ambitious.rawValue)
                }
                .pickerStyle(.segmented)
                ForEach([5, 10, 20], id: \.self) { years in
                    HStack {
                        Text("Dans \(years) ans")
                            .font(BudgetFont.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(FinanceFormatting.chf(FinanceMath.roundedToCents(projected(years: years))))
                            .font(BudgetFont.body.weight(.bold).monospacedDigit())
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text("Au rythme de vos versements de l'année, hypothèses annualisées par classe — une simulation, jamais une promesse.")
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    heroCard
                    projectionCard
                    trendCard
                    assetsSection
                    liabilitiesSection
                    Label {
                        Text("Les valeurs d'actifs sont vos estimations personnelles. Mettez-les à jour de temps en temps ; la courbe se construit au fil de vos visites.")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(BudgetColor.informative)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(BudgetSpacing.screenMargin)
            }
            .obsidianFABClearance()
        }
        .navigationTitle("Patrimoine")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Ajouter un actif", systemImage: "plus.square") { isPresentingNewAsset = true }
                    Button("Ajouter une dette", systemImage: "minus.square") { isPresentingNewLiability = true }
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewAsset) {
            AssetFormView(mode: .create)
        }
        .sheet(isPresented: $isPresentingNewLiability) {
            LiabilityFormView(mode: .create)
        }
        .sheet(item: $editedAsset) { asset in
            AssetFormView(mode: .edit(asset))
        }
        .sheet(item: $editedLiability) { liability in
            LiabilityFormView(mode: .edit(liability))
        }
        .onAppear(perform: recordDailySnapshot)
    }

    private func recordDailySnapshot() {
        try? service.recordSnapshotIfNeeded(
            breakdown: breakdown,
            existing: snapshots,
            now: appContainer.dateProvider.now,
            context: modelContext
        )
    }

    // MARK: - Hero

    private var heroCard: some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Fortune nette")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                AmountText(
                    amount: breakdown.netWorth,
                    role: .hero,
                    emphasis: breakdown.netWorth < 0 ? .negative : .neutral
                )
                VStack(spacing: BudgetSpacing.micro) {
                    breakdownRow("Comptes inclus", breakdown.accountsTotal)
                    breakdownRow("Actifs", breakdown.assetsTotal)
                    breakdownRow("Prévoyance", breakdown.pensionTotal)
                    breakdownRow("Dettes", -breakdown.liabilitiesTotal)
                }
                .padding(.top, BudgetSpacing.micro)
                // Fraîcheur : la fortune est dérivée des données du jour.
                Text("Soldes du jour, dérivés de vos comptes, actifs, prévoyance et dettes enregistrés.")
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Fortune nette : \(FinanceFormatting.chf(breakdown.netWorth))")
        }
    }

    private func breakdownRow(_ label: String, _ amount: Decimal) -> some View {
        HStack {
            Text(label)
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(FinanceFormatting.chfSigned(amount))
                .font(BudgetFont.caption.monospacedDigit())
                .foregroundStyle(amount < 0 ? BudgetColor.negative : .primary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Trend

    /// Point de la série le plus proche de la sélection — la valeur
    /// affichée vient TOUJOURS des instantanés existants. Statique et
    /// testé (ObsidianMotionTests).
    static func nearestTrendPoint(to date: Date?, in points: [NetWorthSnapshot]) -> NetWorthSnapshot? {
        guard let date else { return nil }
        return points.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    /// Valeur accessible de la courbe : la SÉLECTION quand elle existe
    /// (mois + montant annoncés), sinon le résumé global — testée.
    static func trendAccessibilityValue(selected: NetWorthSnapshot?, points: [NetWorthSnapshot]) -> String {
        if let selected {
            return trendSelectionLabel(date: selected.date, netWorth: selected.netWorth)
        }
        guard let first = points.first, let last = points.last else { return "" }
        return "De \(FinanceFormatting.chf(first.netWorth)) le \(FinanceFormatting.swissDate(first.date)) à \(FinanceFormatting.chf(last.netWorth)) le \(FinanceFormatting.swissDate(last.date))"
    }

    /// Étiquette textuelle de la sélection (testée) : date suisse + CHF.
    static func trendSelectionLabel(date: Date, netWorth: Decimal) -> String {
        "\(FinanceFormatting.swissDate(date)) : \(FinanceFormatting.chf(netWorth)) de fortune nette"
    }

    @ViewBuilder
    private var trendCard: some View {
        let points = service.trend(snapshots: snapshots)
        if points.count >= 2 {
            NetWorthTrendCard(points: points, heldTrendSelection: $heldTrendSelection)
        }
    }

    // MARK: - Assets

    @ViewBuilder
    private var assetsSection: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            Text("Actifs hors comptes")
                .font(BudgetFont.sectionTitle)
                .foregroundStyle(.secondary)
            if assets.isEmpty {
                GlassCard(style: .row) {
                    Text("Immobilier, véhicule, collection… Ajoutez ce qui a de la valeur en dehors de vos comptes.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(assets) { asset in
                    GlassCard(style: .row) {
                        HStack(spacing: BudgetSpacing.medium) {
                            Image(systemName: asset.kind.systemImage)
                                .foregroundStyle(BudgetColor.indigo)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.name)
                                    .font(BudgetFont.body.weight(.medium))
                                HStack(spacing: BudgetSpacing.micro) {
                                    Text(asset.kind.displayName)
                                    if !asset.includeInNetWorth {
                                        Text("· Exclu du patrimoine")
                                            .foregroundStyle(BudgetColor.warning)
                                    }
                                }
                                .font(BudgetFont.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: BudgetSpacing.small)
                            Text(FinanceFormatting.chf(asset.currentValue))
                                .font(BudgetFont.amount)
                                .foregroundStyle(asset.includeInNetWorth ? BudgetColor.positive : BudgetColor.coolGray)
                        }
                    }
                    .onTapGesture { editedAsset = asset }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(asset.name), \(FinanceFormatting.chf(asset.currentValue))\(asset.includeInNetWorth ? "" : ", exclu du patrimoine")")
                    .accessibilityIdentifier("networth.asset.row")
                }
            }
        }
    }

    // MARK: - Liabilities

    @ViewBuilder
    private var liabilitiesSection: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            Text("Dettes")
                .font(BudgetFont.sectionTitle)
                .foregroundStyle(.secondary)
            if liabilities.isEmpty {
                GlassCard(style: .row) {
                    Text("Hypothèque, leasing, dette fiscale… Les dettes déjà portées par un compte (carte de crédit) restent sur ce compte.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(liabilities) { liability in
                    GlassCard(style: .row) {
                        HStack(spacing: BudgetSpacing.medium) {
                            Image(systemName: liability.kind.systemImage)
                                .foregroundStyle(BudgetColor.negative)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(liability.name)
                                    .font(BudgetFont.body.weight(.medium))
                                HStack(spacing: BudgetSpacing.micro) {
                                    Text(liability.kind.displayName)
                                    if !liability.includeInNetWorth {
                                        Text("· Exclue du patrimoine")
                                            .foregroundStyle(BudgetColor.warning)
                                    }
                                }
                                .font(BudgetFont.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: BudgetSpacing.small)
                            Text("−" + FinanceFormatting.chf(liability.outstandingAmount))
                                .font(BudgetFont.amount)
                                .foregroundStyle(liability.includeInNetWorth ? BudgetColor.negative : BudgetColor.coolGray)
                        }
                    }
                    .onTapGesture { editedLiability = liability }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Dette \(liability.name), \(FinanceFormatting.chf(liability.outstandingAmount))\(liability.includeInNetWorth ? "" : ", exclue du patrimoine")")
                }
            }
        }
    }
}

/// Carte « Évolution » du Patrimoine — composant de PRODUCTION, rendu
/// tel quel par NetWorthView ET par les preuves de rendu
/// (ObsidianMotionTests) : jamais de copie de graphique réservée aux
/// tests. La sélection est portée par un Binding pour être injectable.
struct NetWorthTrendCard: View {
    let points: [NetWorthSnapshot]
    @Binding var heldTrendSelection: Date?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// L8 : repères de l'axe X adaptés à la taille du texte — en tailles
    /// accessibilité, deux repères LISIBLES valent mieux que six
    /// libellés superposés. Statique et testé (ObsidianMotionTests).
    static func xAxisMarkCount(for size: DynamicTypeSize) -> Int {
        size.isAccessibilitySize ? 2 : 4
    }

    /// Dates EXPLICITES des deux repères en tailles accessibilité :
    /// premier point et AVANT-DERNIER point — éloignés (aucune
    /// superposition possible, l'automatique plaçait « mars » sur
    /// « mai ») et tous deux RENDUS (un repère posé sur le bord fuyant
    /// voit son libellé rogné par le cadre du graphique). Statique et
    /// testé.
    static func accessibilityAxisDates(for points: [NetWorthSnapshot]) -> [Date] {
        guard points.count > 2 else { return points.map(\.date) }
        return [points[0].date, points[points.count - 2].date]
    }

    var body: some View {
        let selected = NetWorthView.nearestTrendPoint(to: heldTrendSelection, in: points)
        GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Évolution")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("CHF", NSDecimalNumber(decimal: point.netWorth).doubleValue)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient.budgetChartLine)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("CHF", NSDecimalNumber(decimal: point.netWorth).doubleValue)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BudgetColor.indigo.opacity(0.22), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    // L8 : sélection — règle + point, valeurs issues
                    // des instantanés EXISTANTS, aucune animation.
                    if let selected {
                        RuleMark(x: .value("Sélection", selected.date))
                            .foregroundStyle(BudgetColor.textTertiary.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                        PointMark(
                            x: .value("Sélection", selected.date),
                            y: .value("CHF", NSDecimalNumber(decimal: selected.netWorth).doubleValue)
                        )
                        .foregroundStyle(BudgetColor.brandBright)
                        .symbolSize(70)
                    }
                }
                // L8 correctif : geste de lecture EXPLICITE — un
                // toucher ou un glissement sur la courbe choisit la
                // date via l'échelle du graphique (proxy.value(atX:)),
                // et la dernière lecture reste affichée au lever du
                // doigt. Déterministe pour un doigt réel comme pour le
                // tour automatisé (chartXSelection ne recevait pas les
                // gestes synthétisés — constaté aux runs Demo).
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame = proxy.plotFrame else { return }
                                        let x = value.location.x - geo[plotFrame].origin.x
                                        if let date: Date = proxy.value(atX: x) {
                                            heldTrendSelection = date
                                        }
                                    }
                            )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel().font(.caption2)
                    }
                }
                .chartXAxis {
                    if dynamicTypeSize.isAccessibilitySize {
                        AxisMarks(values: Self.accessibilityAxisDates(for: points)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated)).font(.caption2)
                        }
                    } else {
                        AxisMarks(values: .automatic(desiredCount: Self.xAxisMarkCount(for: dynamicTypeSize))) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated)).font(.caption2)
                        }
                    }
                }
                .frame(height: 160)
                .accessibilityLabel("Évolution de la fortune nette")
                .accessibilityValue(NetWorthView.trendAccessibilityValue(selected: selected, points: points))
                .accessibilityIdentifier("networth.chart.evolution")
                if let selected {
                    Text(NetWorthView.trendSelectionLabel(date: selected.date, netWorth: selected.netWorth))
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.updatesFrequently)
                        .accessibilityIdentifier("networth.chart.selectionLabel")
                } else {
                    Text("Glissez sur la courbe pour lire un mois précis.")
                        .font(BudgetFont.caption)
                        .foregroundStyle(BudgetColor.textTertiary)
                        .accessibilityIdentifier("networth.chart.selectionHint")
                }
            }
        }
    }
}

#Preview("Patrimoine") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        NetWorthView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
