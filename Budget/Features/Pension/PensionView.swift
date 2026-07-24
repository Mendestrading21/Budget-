import SwiftUI
import SwiftData

/// Swiss pension overview: pillars 1/2/3a/3b positions from official
/// statements. The app never invents growth — projections shown are the
/// institutions' own figures, clearly labeled as assumptions.
struct PensionView: View {
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \PensionAsset.createdAt) private var assets: [PensionAsset]

    @State private var editedAsset: PensionAsset?
    @State private var isPresentingNew = false

    private let service = InsurancePensionService()

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            if assets.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Prévoyance")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Label("Ajouter une position", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            PensionAssetFormView(mode: .create)
        }
        .sheet(item: $editedAsset) { asset in
            PensionAssetFormView(mode: .edit(asset))
        }
    }

    private var list: some View {
        let totals = service.pensionTotalsByPillar(assets: assets)
        return ScrollView {
            VStack(spacing: BudgetSpacing.medium) {
                GlassCard(style: .hero) {
                    VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                        Text("Capital de prévoyance")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        AmountText(amount: service.totalPensionCapital(assets: assets), role: .hero)
                        Text("Contributions annuelles : \(FinanceFormatting.chf(service.totalAnnualContributions(assets: assets)))")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                        if let projected = service.totalProjectedAtRetirement(assets: assets) {
                            Text("Projection des certificats à la retraite : \(FinanceFormatting.chf(projected)) — hypothèses des institutions, rien n'est garanti")
                                .font(BudgetFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Capital de prévoyance : \(FinanceFormatting.chf(service.totalPensionCapital(assets: assets)))")
                }

                if !totals.isEmpty {
                    GlassCard {
                        VStack(spacing: BudgetSpacing.small) {
                            ForEach(totals, id: \.pillar) { entry in
                                HStack {
                                    Label(entry.pillar.displayName, systemImage: entry.pillar.systemImage)
                                        .font(BudgetFont.body)
                                    Spacer()
                                    Text(FinanceFormatting.chf(entry.total))
                                        .font(BudgetFont.amount)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text("Positions")
                        .font(BudgetFont.sectionTitle)
                        .foregroundStyle(.secondary)
                    ForEach(assets) { asset in
                        PensionRow(asset: asset)
                            .onTapGesture { editedAsset = asset }
                    }
                }

                Label {
                    Text("Saisies depuis vos certificats et relevés officiels. Les projections affichées sont celles des institutions — ce ne sont pas des promesses ni des conseils.")
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

    private var emptyState: some View {
        ScrollView {
            GlassCard {
                EmptyState(
                    symbol: "shield.checkered",
                    title: "Aucune position de prévoyance",
                    message: "Reportez votre certificat LPP, vos comptes 3a/3b et votre estimation AVS pour voir l'ensemble de votre prévoyance — sans faux zéro : rien n'est inventé.",
                    actionTitle: "Ajouter une position",
                    action: { isPresentingNew = true }
                )
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }
}

struct PensionRow: View {
    let asset: PensionAsset

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: asset.pillar.systemImage)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(asset.pillar.shortName) · \(asset.institutionName)")
                        .font(BudgetFont.body.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    if let owner = asset.owner {
                        Text(owner.firstName)
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let documentDate = asset.sourceDocumentDate {
                        Text("Relevé du \(FinanceFormatting.swissDate(documentDate))")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: BudgetSpacing.small)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(FinanceFormatting.chf(asset.currentValue))
                        .font(BudgetFont.amount)
                        .fixedSize()
                    if asset.annualContribution > 0 {
                        Text("+\(FinanceFormatting.chf(asset.annualContribution)) / an")
                            .font(BudgetFont.caption)
                            .foregroundStyle(BudgetColor.positive)
                    }
                }
            }
        }
        .opacity(asset.isActive ? 1 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(asset.pillar.displayName), \(asset.institutionName), \(FinanceFormatting.chf(asset.currentValue))")
    }
}

#Preview("Prévoyance") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        PensionView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
