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

    @State private var editedAsset: Asset?
    @State private var editedLiability: Liability?
    @State private var isPresentingNewAsset = false
    @State private var isPresentingNewLiability = false

    private var service: NetWorthService {
        NetWorthService(calendar: appContainer.calendar, balanceService: appContainer.balanceService)
    }

    private var breakdown: NetWorthBreakdown {
        service.breakdown(accounts: accounts, assets: assets, pensions: pensions, liabilities: liabilities)
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    heroCard
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
                Text(FinanceFormatting.chf(breakdown.netWorth))
                    .font(BudgetFont.heroAmount)
                    .foregroundStyle(breakdown.netWorth < 0 ? BudgetColor.negative : .primary)
                VStack(spacing: BudgetSpacing.micro) {
                    breakdownRow("Comptes inclus", breakdown.accountsTotal)
                    breakdownRow("Actifs", breakdown.assetsTotal)
                    breakdownRow("Prévoyance", breakdown.pensionTotal)
                    breakdownRow("Dettes", -breakdown.liabilitiesTotal)
                }
                .padding(.top, BudgetSpacing.micro)
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

    @ViewBuilder
    private var trendCard: some View {
        let points = service.trend(snapshots: snapshots)
        if points.count >= 2 {
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text("Évolution")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    Chart(points) { point in
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
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(.white.opacity(0.08))
                            AxisValueLabel().font(.caption2)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated)).font(.caption2)
                        }
                    }
                    .frame(height: 160)
                    .accessibilityLabel("Évolution de la fortune nette")
                    .accessibilityValue(trendAccessibilitySummary(points: points))
                }
            }
        }
    }

    private func trendAccessibilitySummary(points: [NetWorthSnapshot]) -> String {
        guard let first = points.first, let last = points.last else { return "" }
        return "De \(FinanceFormatting.chf(first.netWorth)) le \(FinanceFormatting.swissDate(first.date)) à \(FinanceFormatting.chf(last.netWorth)) le \(FinanceFormatting.swissDate(last.date))"
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

#Preview("Patrimoine") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        NetWorthView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
