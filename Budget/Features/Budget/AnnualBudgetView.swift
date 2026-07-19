import SwiftUI
import SwiftData

/// Annual 12-month grid for the year containing `yearAnchor`: rows are
/// budgeted categories, columns are months (horizontal scroll). Planned
/// amounts with row/column totals; actuals shown for elapsed months.
struct AnnualBudgetView: View {
    let yearAnchor: Date

    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \BudgetTransaction.date, order: .reverse)
    private var transactions: [BudgetTransaction]
    @Query private var budgets: [MonthlyBudget]

    private var calendar: Calendar { appContainer.calendar }

    private var year: Int {
        calendar.component(.year, from: yearAnchor)
    }

    private var varianceService: BudgetVarianceService {
        BudgetVarianceService(calendar: calendar)
    }

    /// Reports per month (1...12) for this year. Transactions are filtered
    /// to the year ONCE, so building twelve reports scans the short list
    /// twelve times instead of the whole history.
    private var monthReports: [Int: BudgetReport] {
        let yearTransactions = transactions.filter {
            calendar.component(.year, from: $0.date) == year
        }
        var result: [Int: BudgetReport] = [:]
        for month in 1...12 {
            guard let anchor = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { continue }
            let budget = budgets.first { $0.year == year && $0.month == month }
            result[month] = varianceService.report(budget: budget, monthOf: anchor, transactions: yearTransactions)
        }
        return result
    }

    /// Every category budgeted at least once this year, ordered.
    private struct RowKey: Hashable, Identifiable {
        let id: UUID
        let name: String
    }

    private func rows(from reports: [Int: BudgetReport]) -> [RowKey] {
        var seen: [UUID: String] = [:]
        for report in reports.values {
            for line in report.lineReports {
                if let id = line.categoryID {
                    seen[id] = line.categoryName
                }
            }
        }
        return seen
            .map { RowKey(id: $0.key, name: $0.value) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var monthLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = FinanceFormatting.locale
        formatter.calendar = calendar
        formatter.dateFormat = "MMM"
        return (1...12).map { month in
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return "\(month)" }
            return formatter.string(from: date).capitalized
        }
    }

    /// Elapsed months show actuals under planned amounts.
    private func isElapsed(month: Int) -> Bool {
        let now = appContainer.dateProvider.now
        guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return false }
        return start < now
    }

    var body: some View {
        let reports = monthReports
        let rowKeys = rows(from: reports)
        let labels = monthLabels

        ZStack {
            BudgetScreenBackground()
            if rowKeys.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Label("Aucun budget en \(String(year))", systemImage: "calendar")
                            .font(BudgetFont.sectionTitle)
                        Text("Créez des lignes de budget mensuelles pour remplir la grille annuelle.")
                            .font(BudgetFont.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            } else {
                ScrollView {
                    GlassCard {
                        ScrollView(.horizontal, showsIndicators: true) {
                            grid(reports: reports, rowKeys: rowKeys, labels: labels)
                        }
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
            }
        }
        .navigationTitle("Budget \(String(year))")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func grid(reports: [Int: BudgetReport], rowKeys: [RowKey], labels: [String]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: BudgetSpacing.medium, verticalSpacing: BudgetSpacing.small) {
            // Header
            GridRow {
                Text("Catégorie")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                    .frame(width: 140, alignment: .leading)
                ForEach(0..<12, id: \.self) { index in
                    Text(labels[index])
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                        .frame(width: 92, alignment: .trailing)
                }
                Text("Total")
                    .font(BudgetFont.cardLabel.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)
            }
            Divider()

            // Category rows
            ForEach(rowKeys) { row in
                GridRow {
                    Text(row.name)
                        .font(BudgetFont.caption.weight(.medium))
                        .lineLimit(2)
                        .frame(width: 140, alignment: .leading)
                    ForEach(1...12, id: \.self) { month in
                        cell(for: row, month: month, reports: reports)
                            .frame(width: 92, alignment: .trailing)
                    }
                    Text(FinanceFormatting.chf(rowTotal(row: row, reports: reports)))
                        .font(BudgetFont.caption.weight(.semibold).monospacedDigit())
                        .frame(width: 100, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(rowAccessibilityLabel(row: row, reports: reports))
            }
            Divider()

            // Column totals
            GridRow {
                Text("Total planifié")
                    .font(BudgetFont.caption.weight(.semibold))
                    .frame(width: 140, alignment: .leading)
                ForEach(1...12, id: \.self) { month in
                    Text(FinanceFormatting.chf(reports[month]?.totalPlanned ?? .zero))
                        .font(BudgetFont.caption.weight(.semibold).monospacedDigit())
                        .frame(width: 92, alignment: .trailing)
                }
                Text(FinanceFormatting.chf(yearTotal(reports: reports)))
                    .font(BudgetFont.caption.weight(.bold).monospacedDigit())
                    .frame(width: 100, alignment: .trailing)
            }
        }
        .padding(.vertical, BudgetSpacing.micro)
    }

    @ViewBuilder
    private func cell(for row: RowKey, month: Int, reports: [Int: BudgetReport]) -> some View {
        if let line = reports[month]?.lineReports.first(where: { $0.categoryID == row.id }) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(FinanceFormatting.chf(line.planned))
                    .font(BudgetFont.caption.monospacedDigit())
                if isElapsed(month: month) {
                    Text(FinanceFormatting.chf(line.actual))
                        .font(BudgetFont.caption.monospacedDigit())
                        .foregroundStyle(line.isOverrun ? BudgetColor.negative : .secondary)
                }
            }
        } else {
            Text("—")
                .font(BudgetFont.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func rowTotal(row: RowKey, reports: [Int: BudgetReport]) -> Decimal {
        (1...12).reduce(.zero) { partial, month in
            partial + (reports[month]?.lineReports.first { $0.categoryID == row.id }?.planned ?? .zero)
        }
    }

    private func yearTotal(reports: [Int: BudgetReport]) -> Decimal {
        (1...12).reduce(.zero) { $0 + (reports[$1]?.totalPlanned ?? .zero) }
    }

    private func rowAccessibilityLabel(row: RowKey, reports: [Int: BudgetReport]) -> String {
        "\(row.name), total planifié \(String(year)) : \(FinanceFormatting.chf(rowTotal(row: row, reports: reports)))"
    }
}

#Preview("Budget annuel") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        AnnualBudgetView(yearAnchor: DemoDataFactory.previewReferenceDate)
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
