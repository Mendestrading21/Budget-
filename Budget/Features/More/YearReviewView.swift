import SwiftUI
import SwiftData

/// « Année en revue » : le bilan annuel — mis de côté, taux d'épargne,
/// revenus / coût de la vie / impôts avec rappel de l'année précédente,
/// et versements cumulés par classe. Tout dérive des mouvements
/// comptabilisés (YearStatsService + ContributionService).
struct YearReviewView: View {
    @Environment(AppContainer.self) private var appContainer

    @Query private var accounts: [Account]
    @Query private var transactions: [BudgetTransaction]

    private var year: Int {
        appContainer.calendar.component(.year, from: appContainer.dateProvider.now)
    }

    private var service: YearStatsService { YearStatsService(calendar: appContainer.calendar) }

    var body: some View {
        let stats = service.stats(year: year, transactions: transactions)
        let previous = service.stats(year: year - 1, transactions: transactions)
        ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    GlassCard(style: .hero) {
                        VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                            Text("Mis de côté en \(String(year))")
                                .font(BudgetFont.cardLabel)
                                .foregroundStyle(.secondary)
                            Text(FinanceFormatting.chf(stats.saved))
                                .font(BudgetFont.heroAmount)
                                .foregroundStyle(BudgetColor.positive)
                            Text(stats.income > 0
                                 ? "Taux d'épargne : \(FinanceFormatting.percent(stats.savingsRate))\(previous.saved > 0 ? " · \(String(year - 1)) : \(FinanceFormatting.chf(previous.saved))" : "")"
                                 : "Aucun revenu comptabilisé cette année")
                                .font(BudgetFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    statRow("Revenus", stats.income, previous: previous.income, tint: BudgetColor.positive)
                    statRow("Coût de la vie", stats.livingExpenses, previous: previous.livingExpenses, tint: BudgetColor.negative)
                    statRow("Impôts payés", stats.taxesPaid, previous: previous.taxesPaid, tint: BudgetColor.warning)

                    contributionsCard

                    Text("Mouvements comptabilisés de l'année — les envois vers vos placements ne sont jamais des dépenses.")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(BudgetSpacing.screenMargin)
            }
        }
        .navigationTitle("Année \(String(year))")
    }

    private func statRow(_ label: String, _ amount: Decimal, previous: Decimal, tint: Color) -> some View {
        GlassCard(style: .row) {
            HStack {
                Text(label)
                    .font(BudgetFont.body)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(FinanceFormatting.chf(amount))
                        .font(BudgetFont.amount)
                        .foregroundStyle(tint)
                    if previous > 0 {
                        Text("\(String(year - 1)) : \(FinanceFormatting.chf(previous))")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var contributionsCard: some View {
        let contributionService = ContributionService(calendar: appContainer.calendar)
        let now = appContainer.dateProvider.now
        let rows: [(String, Decimal)] = [
            ("🏛 Épargne", [.savings] as [AccountType]),
            ("📈 Bourse / titres", [.broker]),
            ("🛡 Prévoyance", [.pillar3a, .pillar3b, .occupationalPension]),
        ].map { label, kinds in
            (label, accounts.filter { kinds.contains($0.type) }.reduce(Decimal.zero) {
                $0 + contributionService.summary(of: $1, movements: transactions, now: now).currentYear
            })
        }.filter { $0.1 > 0 }
        return GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Versé par classe en \(String(year))")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                if rows.isEmpty {
                    Text("Aucun versement cette année pour l'instant.")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rows, id: \.0) { row in
                        HStack {
                            Text(row.0).font(BudgetFont.body)
                            Spacer()
                            Text("+\(FinanceFormatting.chf(row.1))")
                                .font(BudgetFont.amount)
                                .foregroundStyle(BudgetColor.positive)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
