import SwiftUI
import SwiftData

/// Budget tab: monthly planned-vs-actual per category, with a full
/// reconciliation (out-of-budget spending is always visible).
struct BudgetTab: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BudgetTransaction.date, order: .reverse)
    private var transactions: [BudgetTransaction]
    @Query private var budgets: [MonthlyBudget]

    @State private var monthAnchor: Date?
    @State private var editedLine: BudgetLine?
    @State private var isPresentingNewLine = false
    @State private var actionErrorMessage: String?

    private var currentAnchor: Date { monthAnchor ?? appContainer.dateProvider.now }

    private var planningService: BudgetPlanningService {
        BudgetPlanningService(calendar: appContainer.calendar)
    }

    private var varianceService: BudgetVarianceService {
        BudgetVarianceService(calendar: appContainer.calendar)
    }

    private var currentBudget: MonthlyBudget? {
        let (year, month) = planningService.yearAndMonth(of: currentAnchor)
        return budgets.first { $0.year == year && $0.month == month }
    }

    /// Built once per render at the top of `body`, then passed down.
    private func makeReport() -> BudgetReport {
        varianceService.report(budget: currentBudget, monthOf: currentAnchor, transactions: transactions)
    }

    private var hasPreviousMonthLines: Bool {
        guard let previousAnchor = appContainer.calendar.date(byAdding: .month, value: -1, to: currentAnchor) else {
            return false
        }
        let (year, month) = planningService.yearAndMonth(of: previousAnchor)
        return budgets.first { $0.year == year && $0.month == month }.map { !$0.lines.isEmpty } ?? false
    }

    var body: some View {
        let report = makeReport()
        return NavigationStack {
            ZStack {
                // NU3 : écran PILOTE — fond Neon Ultra.
                NeonUltraScreenBackground()
                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        monthSelector
                        if report.lineReports.isEmpty {
                            emptyState
                        } else {
                            summaryCard(report)
                            lineSections(report)
                        }
                        outOfBudgetSection(report)
                        if let actionErrorMessage {
                            Label(actionErrorMessage, systemImage: BudgetGlyph.error.systemName)
                                .font(NeonUltraTypography.body)
                                .foregroundStyle(NeonUltraColor.negative)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
                .neonUltraScrollClearance()
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNewLine = true
                    } label: {
                        Label("Ajouter une ligne", systemImage: BudgetGlyph.add.systemName)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AnnualBudgetView(yearAnchor: currentAnchor)
                    } label: {
                        Label("Vue annuelle", systemImage: BudgetGlyph.annual.systemName)
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewLine) {
                BudgetLineFormView(mode: .create, monthAnchor: currentAnchor)
            }
            .sheet(item: $editedLine) { line in
                BudgetLineFormView(mode: .edit(line), monthAnchor: currentAnchor)
            }
        }
    }

    // MARK: - Month selector

    private var monthSelector: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                BudgetIcon(.previous, tone: .brand, style: .plain)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Mois précédent")

            Spacer()
            Text(FinanceFormatting.monthTitle(currentAnchor, calendar: appContainer.calendar).capitalized)
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
        monthAnchor = appContainer.calendar.date(byAdding: .month, value: value, to: currentAnchor) ?? currentAnchor
    }

    // MARK: - Summary

    /// Part du budget de dépenses consommée — pur affichage à partir des
    /// totaux DÉJÀ calculés par `BudgetVarianceService`.
    private func consumedFraction(_ report: BudgetReport) -> Decimal {
        FinanceMath.safeRatio(report.spendingActual, report.spendingPlanned)
    }

    /// L'état du plan reste ÉCRIT et porte son symbole : ni la couleur
    /// seule, ni la marque — les rôles sémantiques gardent leur sens.
    private func planStateBadge(_ fraction: Decimal) -> NeonUltraBadge {
        if fraction > 1 { return NeonUltraBadge(kind: .negative, label: "Dépassé") }
        if fraction > Decimal("0.85") { return NeonUltraBadge(kind: .warning, label: "À surveiller") }
        return NeonUltraBadge(kind: .positive, label: "Dans le plan")
    }

    private func summaryCard(_ report: BudgetReport) -> some View {
        let fraction = consumedFraction(report)
        let percentUsed = Int(NSDecimalNumber(decimal: fraction * 100).doubleValue.rounded())
        return NeonUltraElevatedCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Reste à dépenser (lignes budgétées)")
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                NeonUltraAmountText(amount: report.spendingVariance, hero: true)
                // L'état du plan est toujours ÉCRIT, jamais la couleur seule.
                planStateBadge(fraction)
                // Barre prévu/dépensé avec son résumé écrit en toutes lettres.
                ProgressView(value: min(1, NSDecimalNumber(decimal: fraction).doubleValue))
                    .tint(fraction > 1 ? NeonUltraColor.negative
                          : (fraction > Decimal("0.85") ? NeonUltraColor.warning : NeonUltraColor.violet))
                Text("Vous avez utilisé \(percentUsed) % de votre budget. Prévu \(FinanceFormatting.chf(report.spendingPlanned)), dépensé \(FinanceFormatting.chf(report.spendingActual)). L'épargne et les impôts sont comptés à part.")
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Vous avez utilisé \(percentUsed) pour cent de votre budget. Prévu \(FinanceFormatting.chf(report.spendingPlanned)), dépensé \(FinanceFormatting.chf(report.spendingActual)), reste \(FinanceFormatting.chf(report.spendingVariance))")
        }
    }

    // MARK: - Lines

    private func groupedReports(_ report: BudgetReport) -> [(title: String, reports: [BudgetLineReport])] {
        let expenses = report.lineReports.filter { $0.categoryKind == .expense }
        return [
            ("Revenus", report.lineReports.filter { $0.categoryKind == .income }),
            ("Essentiel", expenses.filter(\.isEssential)),
            ("Discrétionnaire", expenses.filter { !$0.isEssential }),
            // A12 (Les quatre familles) : le mot de la famille — « Mis de
            // côté » — même contenu, même calcul, même séparation stricte.
            // Parité de vocabulaire avec la PWA (lot A10).
            ("Mis de côté", report.lineReports.filter { $0.categoryKind == .saving || $0.categoryKind == .investment }),
            ("Impôts", report.lineReports.filter { $0.categoryKind == .tax }),
        ].filter { !$0.1.isEmpty }
    }

    private func lineSections(_ report: BudgetReport) -> some View {
        ForEach(groupedReports(report), id: \.title) { group in
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text(group.title)
                    .font(NeonUltraTypography.label)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                ForEach(group.reports) { lineReport in
                    BudgetLineRow(report: lineReport)
                        .onTapGesture {
                            if let line = currentBudget?.lines.first(where: { $0.id == lineReport.id }) {
                                editedLine = line
                            }
                        }
                }
            }
        }
    }

    // MARK: - Out of budget

    @ViewBuilder
    private func outOfBudgetSection(_ report: BudgetReport) -> some View {
        if !report.outOfBudget.isEmpty {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Hors budget")
                    .font(NeonUltraTypography.title)
                    .foregroundStyle(NeonUltraColor.textPrimary)
                Text("Mouvements du mois sans ligne budgétée — total \(FinanceFormatting.chf(report.totalOutOfBudget))")
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                ForEach(report.outOfBudget) { entry in
                    NeonUltraCard {
                        HStack {
                            Text(entry.categoryName)
                                .font(NeonUltraTypography.body)
                                .foregroundStyle(NeonUltraColor.textPrimary)
                            Spacer()
                            NeonUltraAmountText(amount: entry.actual)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Hors budget : \(entry.categoryName), \(FinanceFormatting.chf(entry.actual))")
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        NeonUltraCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                HStack(spacing: BudgetSpacing.compact) {
                    BudgetIcon(.budget, tone: .brand)
                    Text("Aucun budget ce mois")
                        .font(NeonUltraTypography.title)
                        .foregroundStyle(NeonUltraColor.textPrimary)
                }
                Text("Planifiez des enveloppes par catégorie pour comparer le prévu et le réel.")
                    .font(NeonUltraTypography.body)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                VStack(spacing: BudgetSpacing.small) {
                    // Une SEULE action principale en dégradé ; la seconde
                    // reste secondaire, mate et bordée.
                    Button("Ajouter une ligne") {
                        isPresentingNewLine = true
                    }
                    .buttonStyle(NeonUltraPrimaryButtonStyle())
                    if hasPreviousMonthLines {
                        Button("Copier le mois précédent") {
                            copyPreviousMonth()
                        }
                        .buttonStyle(NeonUltraSecondaryButtonStyle())
                    }
                }
            }
        }
    }

    private func copyPreviousMonth() {
        actionErrorMessage = nil
        do {
            let copied = try planningService.copyPreviousMonthLines(
                into: currentAnchor,
                now: appContainer.dateProvider.now,
                context: modelContext
            )
            if copied == 0 {
                actionErrorMessage = "Rien à copier : le mois précédent n'a pas de lignes."
            }
        } catch {
            actionErrorMessage = "La copie a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }
}

/// One budget line: category, planned vs actual, progress bar with an
/// explicit overrun badge (never color alone).
struct BudgetLineRow: View {
    let report: BudgetLineReport

    private var progressColor: Color {
        if report.isOverrun { return NeonUltraColor.negative }
        return report.consumedFraction > Decimal("0.85") ? NeonUltraColor.warning : NeonUltraColor.violet
    }

    /// « À surveiller » dès 85 % — le même seuil et les mêmes mots que le
    /// pilote PWA ; le statut est toujours ÉCRIT (badge NU3).
    private var watchZone: Bool {
        !report.isOverrun && report.consumedFraction > Decimal("0.85")
    }

    var body: some View {
        NeonUltraCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                HStack {
                    Text(report.categoryName)
                        .font(NeonUltraTypography.label)
                        .foregroundStyle(NeonUltraColor.textPrimary)
                    if report.isOverrun {
                        NeonUltraBadge(kind: .negative, label: "Dépassé")
                    } else if watchZone {
                        NeonUltraBadge(kind: .warning, label: "À surveiller")
                    }
                    Spacer()
                    Text("\(FinanceFormatting.chf(report.actual)) dépensé sur \(FinanceFormatting.chf(report.planned)) prévu")
                        .font(NeonUltraTypography.meta.monospacedDigit())
                        .foregroundStyle(NeonUltraColor.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
                ProgressView(value: min(1, NSDecimalNumber(decimal: report.consumedFraction).doubleValue))
                    .tint(progressColor)
                HStack {
                    Spacer()
                    Text(report.isOverrun
                         ? "Dépassement de \(FinanceFormatting.chf(-report.variance))"
                         : "Reste \(FinanceFormatting.chf(report.variance))")
                        .font(NeonUltraTypography.meta)
                        .foregroundStyle(report.isOverrun ? NeonUltraColor.negative : NeonUltraColor.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(report.categoryName) : \(FinanceFormatting.chf(report.actual)) dépensé sur \(FinanceFormatting.chf(report.planned)) prévu\(report.isOverrun ? ", dépassé de \(FinanceFormatting.chf(-report.variance))" : (watchZone ? ", à surveiller, reste \(FinanceFormatting.chf(report.variance))" : ", reste \(FinanceFormatting.chf(report.variance))"))")
    }
}

#Preview("Budget") {
    let preview = DemoDataFactory.previewAppContainer()
    return BudgetTab()
        .environment(preview)
        .environment(AppRouter())
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Budget — texte agrandi") {
    let preview = DemoDataFactory.previewAppContainer()
    return BudgetTab()
        .environment(preview)
        .environment(AppRouter())
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Budget — transparence réduite") {
    let preview = DemoDataFactory.previewAppContainer()
    return BudgetTab()
        .environment(preview)
        .environment(AppRouter())
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
        .environment(\.neonUltraForcedReducedTransparency, true)
}
