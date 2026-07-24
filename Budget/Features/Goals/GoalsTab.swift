import SwiftUI
import SwiftData

/// Objectifs tab wrapper — the list itself is reusable so the dashboard
/// can push it inside its own navigation stack.
struct GoalsTab: View {
    var body: some View {
        NavigationStack {
            GoalsListView()
        }
    }
}

struct GoalsListView: View {
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \FinancialGoal.createdAt) private var goals: [FinancialGoal]

    @State private var editedGoal: FinancialGoal?
    @State private var isPresentingNew = false

    private var projectionService: GoalProjectionService {
        GoalProjectionService(calendar: appContainer.calendar, balanceService: appContainer.balanceService)
    }

    private var now: Date { appContainer.dateProvider.now }

    private var activeGoals: [FinancialGoal] {
        goals
            .filter { $0.status == .active }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    private var achievedGoals: [FinancialGoal] { goals.filter { $0.status == .achieved } }
    private var pausedGoals: [FinancialGoal] { goals.filter { $0.status == .paused } }

    private var totalSaved: Decimal {
        (activeGoals + achievedGoals).reduce(.zero) { partial, goal in
            partial + min(projectionService.currentAmount(of: goal), max(goal.targetAmount, .zero))
        }
    }

    private var totalTarget: Decimal {
        (activeGoals + achievedGoals).reduce(.zero) { $0 + max($1.targetAmount, .zero) }
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            if goals.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Objectifs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNew = true
                } label: {
                    Label("Ajouter un objectif", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            GoalFormView(mode: .create)
        }
        .sheet(item: $editedGoal) { goal in
            GoalFormView(mode: .edit(goal))
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: BudgetSpacing.medium) {
                GlassCard(style: .hero) {
                    VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                        Text("Épargné vers vos objectifs")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        AmountText(amount: totalSaved, role: .hero)
                        if totalTarget > 0 {
                            Text("Sur \(FinanceFormatting.chf(totalTarget)) visés · \(achievedGoals.count) objectif(s) atteint(s)")
                                .font(BudgetFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Épargné vers vos objectifs : \(FinanceFormatting.chf(totalSaved)) sur \(FinanceFormatting.chf(totalTarget))")
                }

                if !activeGoals.isEmpty {
                    section("En cours", goals: activeGoals)
                }
                if !achievedGoals.isEmpty {
                    section("Atteints 🎉", goals: achievedGoals)
                }
                if !pausedGoals.isEmpty {
                    section("En pause", goals: pausedGoals)
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }

    private func section(_ title: String, goals: [FinancialGoal]) -> some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            Text(title)
                .font(BudgetFont.sectionTitle)
                .foregroundStyle(.secondary)
            ForEach(goals) { goal in
                GoalCard(goal: goal, report: projectionService.report(for: goal, now: now))
                    .onTapGesture { editedGoal = goal }
            }
        }
    }

    private var emptyState: some View {
        ScrollView {
            GlassCard {
                EmptyState(
                    symbol: "target",
                    title: "Aucun objectif",
                    message: "Fonds d'urgence, vacances, pilier 3a… Fixez un cap et suivez la contribution mensuelle nécessaire pour l'atteindre.",
                    actionTitle: "Créer un objectif",
                    action: { isPresentingNew = true }
                )
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }
}

struct GoalCard: View {
    let goal: FinancialGoal
    let report: GoalReport

    private var statusColor: Color {
        switch report.scheduleStatus {
        case .achieved: BudgetColor.positive
        case .onTrack: BudgetColor.electricBlue
        case .behind: BudgetColor.warning
        case .overdue: BudgetColor.negative
        case .noDeadline: BudgetColor.coolGray
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                HStack(spacing: BudgetSpacing.small) {
                    Text(goal.emoji ?? goal.kind.defaultEmoji)
                        .font(.title3)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(goal.name)
                            .font(BudgetFont.body.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        if let account = goal.linkedAccount {
                            Text("Lié au compte \(account.name)")
                                .font(BudgetFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Label(report.scheduleStatus.displayName, systemImage: statusIcon)
                        .font(BudgetFont.caption.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.18), in: Capsule())
                        .foregroundStyle(statusColor)
                }

                ProgressView(value: NSDecimalNumber(decimal: report.progressFraction).doubleValue)
                    .tint(statusColor)

                HStack {
                    Text("\(FinanceFormatting.chf(report.currentAmount)) / \(FinanceFormatting.chf(report.targetAmount))")
                        .font(BudgetFont.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text(FinanceFormatting.percent(report.progressFraction))
                        .font(BudgetFont.caption.weight(.semibold).monospacedDigit())
                }

                if report.scheduleStatus == .achieved {
                    Label("Objectif atteint — bravo !", systemImage: "checkmark.seal.fill")
                        .font(BudgetFont.caption.weight(.semibold))
                        .foregroundStyle(BudgetColor.positive)
                } else {
                    footerText
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityIdentifier("goals.card.\(goal.name)")
    }

    private var statusIcon: String {
        switch report.scheduleStatus {
        case .achieved: "checkmark.seal.fill"
        case .onTrack: "checkmark.circle"
        case .behind: "exclamationmark.circle"
        case .overdue: "exclamationmark.triangle.fill"
        case .noDeadline: "infinity"
        }
    }

    @ViewBuilder
    private var footerText: some View {
        if let required = report.requiredMonthlyContribution, let months = report.monthsRemaining, months > 0 {
            Text("Il faut \(FinanceFormatting.chf(required)) / mois pendant \(months) mois (prévu : \(FinanceFormatting.chf(report.plannedMonthlyContribution)))")
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
        } else if report.scheduleStatus == .overdue {
            Text("Échéance passée — il manque \(FinanceFormatting.chf(report.remainingAmount))")
                .font(BudgetFont.caption)
                .foregroundStyle(BudgetColor.negative)
        } else if let projected = report.projectedCompletionDate {
            Text("Au rythme prévu, atteint vers \(FinanceFormatting.swissDate(projected))")
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Reste \(FinanceFormatting.chf(report.remainingAmount)) — planifiez une contribution mensuelle")
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityText: String {
        var text = "\(goal.name), \(report.scheduleStatus.displayName), \(FinanceFormatting.chf(report.currentAmount)) sur \(FinanceFormatting.chf(report.targetAmount))"
        if let required = report.requiredMonthlyContribution, report.scheduleStatus != .achieved {
            text += ", contribution requise \(FinanceFormatting.chf(required)) par mois"
        }
        return text
    }
}

#Preview("Objectifs") {
    let preview = DemoDataFactory.previewAppContainer()
    return GoalsTab()
        .environment(preview)
        .modelContainer(preview.modelContainer)
        .preferredColorScheme(.dark)
}
