import SwiftUI
import SwiftData

/// Tax module, 100 % manual (ADR-035) : the user notes what they pay
/// (taxPayment movements), what they set aside, their arrears, their due
/// dates, and — if they know it — the year's total amount. The app adds
/// these numbers up; it never estimates taxes from a rate.
struct TaxesView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BudgetTransaction.date, order: .reverse)
    private var transactions: [BudgetTransaction]
    @Query private var households: [Household]
    @Query private var profiles: [TaxProfile]

    @State private var yearOffset = 0
    @State private var activeSheet: SheetKind?
    @State private var isPresentingPayment = false
    @State private var isPresentingDueDateSheet = false
    @State private var errorMessage: String?

    private enum SheetKind: String, Identifiable {
        case reserved, arrears, override
        var id: String { rawValue }
    }

    private var taxService: TaxService {
        TaxService(calendar: appContainer.calendar)
    }

    private var currentYear: Int {
        appContainer.calendar.component(.year, from: appContainer.dateProvider.now) + yearOffset
    }

    private var profile: TaxProfile? { profiles.first }

    private var provision: TaxProvision? {
        profile?.provisions.first { $0.year == currentYear }
    }

    /// Built once per render at the top of `body`, then passed down.
    private func makeReport() -> TaxYearReport {
        taxService.report(
            year: currentYear,
            provision: provision,
            transactions: transactions
        )
    }

    var body: some View {
        let report = makeReport()
        return ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    yearSelector
                    heroCard(report)
                    stateGrid(report)
                    dueDatesSection
                    assumptionsCard(report)
                    disclaimer
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            }
            .obsidianFABClearance()
        }
        .navigationTitle("Impôts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Enregistrer un paiement", systemImage: "checkmark.circle") {
                        isPresentingPayment = true
                    }
                    Button("Ajuster la réserve", systemImage: "tray.and.arrow.down") { openSheet(.reserved) }
                    Button("Saisir des arriérés", systemImage: "clock.arrow.circlepath") { openSheet(.arrears) }
                    Button("Dire le montant de l'année", systemImage: "pencil") { openSheet(.override) }
                    Button("Ajouter une échéance", systemImage: "calendar.badge.plus") {
                        isPresentingDueDateSheet = true
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $activeSheet) { kind in
            amountSheet(for: kind)
        }
        .sheet(isPresented: $isPresentingPayment) {
            TransactionFormView(mode: .create(prefilledAccount: nil), prefilledType: .taxPayment)
        }
        .sheet(isPresented: $isPresentingDueDateSheet) {
            DueDateEntrySheet(initialDate: appContainer.dateProvider.now) { date, label in
                addDueDate(date: date, label: label)
            }
        }
    }

    // MARK: - Sections

    private var yearSelector: some View {
        HStack {
            Button {
                yearOffset -= 1
            } label: {
                Image(systemName: "chevron.left").padding(BudgetSpacing.small)
            }
            .accessibilityLabel("Année précédente")
            Spacer()
            Text("Année fiscale \(String(currentYear))")
                .font(BudgetFont.sectionTitle)
            Spacer()
            Button {
                yearOffset += 1
            } label: {
                Image(systemName: "chevron.right").padding(BudgetSpacing.small)
            }
            .accessibilityLabel("Année suivante")
        }
        .tint(BudgetColor.indigo)
    }

    private func heroCard(_ report: TaxYearReport) -> some View {
        GlassCard(style: .hero) {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("Payé en \(String(currentYear))")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                AmountText(amount: report.paid, role: .hero, emphasis: .positive)
                if report.totalDue > 0 {
                    Label("Encore à payer, selon vos saisies : \(FinanceFormatting.chf(report.totalDue))", systemImage: "exclamationmark.triangle")
                        .font(BudgetFont.caption.weight(.semibold))
                        .foregroundStyle(BudgetColor.warning)
                } else if report.annualTax != nil {
                    Label("Tout est payé, selon votre montant", systemImage: "checkmark.seal")
                        .font(BudgetFont.caption)
                        .foregroundStyle(BudgetColor.positive)
                } else {
                    Label("L'app additionne ce que vous notez — elle ne calcule aucun impôt", systemImage: "hand.raised")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Impôts \(String(currentYear)) : vous avez payé \(FinanceFormatting.chf(report.paid))")
        }
    }

    private func stateGrid(_ report: TaxYearReport) -> some View {
        // Colonnes adaptatives : deux colonnes à 390 pt, UNE seule à
        // 320 pt — libellés et montants gardent toute leur largeur.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: BudgetSpacing.medium)], spacing: BudgetSpacing.medium) {
            stateCard("Pour toute l'année", report.annualTax ?? .zero, icon: "square.and.pencil",
                      detail: report.annualTax != nil ? "Le montant que vous avez saisi" : "À saisir si vous le connaissez — rien n'est estimé")
            stateCard("Déjà payé", report.paid, icon: "checkmark.circle", tint: BudgetColor.positive,
                      detail: "Les paiements d'impôts que vous avez notés")
            stateCard("Déjà mis de côté", report.reserved, icon: "tray.and.arrow.down", tint: BudgetColor.electricBlue,
                      detail: nil)
            stateCard("Arriérés", report.arrears, icon: "clock.arrow.circlepath",
                      tint: report.arrears > 0 ? BudgetColor.negative : BudgetColor.coolGray,
                      detail: "Années précédentes")
        }
    }

    private func stateCard(_ title: String, _ amount: Decimal, icon: String, tint: Color = .primary, detail: String?) -> some View {
        GlassCard(style: .row) {
            VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                Label(title, systemImage: icon)
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(FinanceFormatting.chf(amount))
                    .font(BudgetFont.amount)
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) : \(FinanceFormatting.chf(amount))\(detail.map { ", \($0)" } ?? "")")
    }

    @ViewBuilder
    private var dueDatesSection: some View {
        let now = appContainer.dateProvider.now
        let upcoming = taxService.upcomingDueDates(provision: provision, now: now)
        let overdue = taxService.overdueDueDates(provision: provision, now: now)
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            Text("Échéances")
                .font(BudgetFont.sectionTitle)
                .foregroundStyle(.secondary)
            if upcoming.isEmpty && overdue.isEmpty {
                GlassCard(style: .row) {
                    Text("Rien pour l'instant. Ajoutez vos acomptes avec le menu Actions.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(overdue) { dueDate in
                dueDateRow(dueDate, isOverdue: true)
            }
            ForEach(upcoming) { dueDate in
                dueDateRow(dueDate, isOverdue: false)
            }
        }
    }

    private func dueDateRow(_ dueDate: TaxDueDate, isOverdue: Bool) -> some View {
        GlassCard(style: .row) {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dueDate.label)
                            .font(BudgetFont.body.weight(.medium))
                        Text(FinanceFormatting.swissDate(dueDate.date))
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                        .foregroundStyle(isOverdue ? BudgetColor.warning : BudgetColor.indigo)
                }
                Spacer()
                if isOverdue {
                    Text("Échue — à vérifier")
                        .font(BudgetFont.caption.weight(.semibold))
                        .foregroundStyle(BudgetColor.warning)
                }
                Button {
                    remove(dueDate)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(BudgetColor.coolGray)
                }
                .accessibilityLabel("Supprimer l'échéance \(dueDate.label)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taxes.duedate.\(dueDate.label)")
    }

    private func assumptionsCard(_ report: TaxYearReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text("D'où viennent ces chiffres")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                assumptionRow("La règle", "Vous notez, l'app additionne")
                assumptionRow("Payé", "Vos paiements d'impôts de \(String(currentYear))")
                assumptionRow("Pour toute l'année", report.annualTax != nil ? "Le montant que vous avez saisi" : "Pas saisi — rien n'est estimé")
                if let profile, !profile.canton.isEmpty {
                    assumptionRow("Canton", SwissCanton(rawValue: profile.canton)?.displayName ?? profile.canton)
                }
            }
        }
    }

    private func assumptionRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(BudgetFont.caption.weight(.medium))
        }
        .accessibilityElement(children: .combine)
    }

    private var disclaimer: some View {
        Label {
            Text("Ces chiffres additionnent ce que vous avez noté. Ils ne remplacent ni votre déclaration ni les décomptes officiels de votre canton.")
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "info.circle")
                .foregroundStyle(BudgetColor.informative)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func openSheet(_ kind: SheetKind) {
        errorMessage = nil
        activeSheet = kind
    }

    private func amountSheet(for kind: SheetKind) -> some View {
        let (title, footer, initial): (String, String, Decimal?) = switch kind {
        case .reserved:
            ("Déjà mis de côté", "L'argent que vous avez déjà réservé pour vos impôts \(String(currentYear)).", provision?.reservedAmount)
        case .arrears:
            ("Arriérés", "Ce que vous devez encore pour les années passées : décomptes finaux, rattrapages.", provision?.arrearsAmount)
        case .override:
            ("Pour toute l'année", "Le montant total de vos impôts \(String(currentYear)), si vous le connaissez. Laissez vide sinon : l'app n'estime rien à votre place.", provision?.estimatedAnnualTaxOverride)
        }
        return AmountEntrySheet(
            title: title,
            footer: footer,
            initialValue: initial,
            allowsEmpty: kind == .override
        ) { value in
            apply(kind: kind, value: value)
        }
    }

    private func apply(kind: SheetKind, value: Decimal?) {
        let now = appContainer.dateProvider.now
        do {
            let profile = try taxService.ensureProfile(context: modelContext, household: households.first, now: now)
            let provision = try taxService.ensureProvision(year: currentYear, profile: profile, context: modelContext, now: now)
            switch kind {
            case .reserved:
                provision.reservedAmount = FinanceMath.roundedToCents(value ?? .zero)
            case .arrears:
                provision.arrearsAmount = FinanceMath.roundedToCents(value ?? .zero)
            case .override:
                provision.estimatedAnnualTaxOverride = value.map(FinanceMath.roundedToCents)
            }
            provision.updatedAt = now
            _ = modelContext.saveOrRollback { _ in
                errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
            }
        } catch {
            modelContext.rollback()
            errorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }

    private func addDueDate(date: Date, label: String) {
        let now = appContainer.dateProvider.now
        do {
            let profile = try taxService.ensureProfile(context: modelContext, household: households.first, now: now)
            let provision = try taxService.ensureProvision(year: currentYear, profile: profile, context: modelContext, now: now)
            let trimmed = label.trimmingCharacters(in: .whitespaces)
            provision.dueDates.append(TaxDueDate(date: date, label: trimmed.isEmpty ? "Acompte" : trimmed))
            provision.updatedAt = now
            _ = modelContext.saveOrRollback { _ in
                errorMessage = "L'ajout de l'échéance a échoué. Réessayez."
            }
        } catch {
            modelContext.rollback()
            errorMessage = "L'ajout de l'échéance a échoué. Réessayez."
        }
    }

    private func remove(_ dueDate: TaxDueDate) {
        guard let provision else { return }
        provision.dueDates.removeAll { $0.id == dueDate.id }
        provision.updatedAt = appContainer.dateProvider.now
        modelContext.saveOrRollback { errorMessage = $0 }
    }
}

/// Sheet for adding one tax due date (date + label).
struct DueDateEntrySheet: View {
    let initialDate: Date
    let onSave: (Date, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var label = "Acompte cantonal"

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Libellé", text: $label)
            }
            .navigationTitle("Nouvelle échéance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        onSave(date, label)
                        dismiss()
                    }
                }
            }
            .onAppear { date = initialDate }
        }
        .presentationDetents([.medium])
    }
}

/// Small reusable sheet for entering one Decimal amount.
struct AmountEntrySheet: View {
    let title: String
    let footer: String
    let initialValue: Decimal?
    let allowsEmpty: Bool
    let onSave: (Decimal?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("0.00", text: $text)
                        .keyboardType(.decimalPad)
                } footer: {
                    Text(footer)
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                }
            }
            .onAppear {
                if let initialValue {
                    text = "\(initialValue)"
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        errorMessage = nil
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            if allowsEmpty {
                onSave(nil)
                dismiss()
            } else {
                onSave(.zero)
                dismiss()
            }
            return
        }
        guard let parsed = FinanceFormatting.parseAmount(trimmed), parsed >= 0 else {
            errorMessage = "Ce montant n'est pas valable. Exemple : 4'500.00"
            return
        }
        onSave(parsed)
        dismiss()
    }
}

#Preview("Impôts") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        TaxesView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
