import SwiftUI
import SwiftData

/// Tax module: provision states (estimated / paid / reserved / outstanding
/// / arrears), due dates, visible assumptions, manual overrides.
/// Everything is an organizational estimate — the disclaimer says so.
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
        case rate, reserved, arrears, override
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
            profile: profile,
            provision: provision,
            transactions: transactions,
            fallbackRate: households.first?.taxProvisionRate ?? .zero
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
                    Button("Corriger l'estimation annuelle", systemImage: "pencil") { openSheet(.override) }
                    Button("Modifier le taux", systemImage: "percent") { openSheet(.rate) }
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
                Text("Il vous reste à payer, à peu près")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                AmountText(
                    amount: report.totalDue,
                    role: .hero,
                    emphasis: report.totalDue > 0 ? .warning : .positive
                )
                if report.reserveGap > 0 {
                    Label("Il manque \(FinanceFormatting.chf(report.reserveGap)) de côté", systemImage: "exclamationmark.triangle")
                        .font(BudgetFont.caption.weight(.semibold))
                        .foregroundStyle(BudgetColor.warning)
                } else {
                    Label("Vous avez tout mis de côté", systemImage: "checkmark.seal")
                        .font(BudgetFont.caption)
                        .foregroundStyle(BudgetColor.positive)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Impôts \(String(currentYear)) : il vous reste à payer environ \(FinanceFormatting.chf(report.totalDue)), et il manque \(FinanceFormatting.chf(report.reserveGap)) de côté")
        }
    }

    private func stateGrid(_ report: TaxYearReport) -> some View {
        // Colonnes adaptatives : deux colonnes à 390 pt, UNE seule à
        // 320 pt — libellés et montants gardent toute leur largeur.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: BudgetSpacing.medium)], spacing: BudgetSpacing.medium) {
            stateCard("Pour toute l'année", report.estimatedTax, icon: "function",
                      detail: report.isOverridden ? "Vous l'avez corrigée" : "Vos revenus, à \(FinanceFormatting.percent(report.rate))")
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
                Text("D'où vient ce chiffre")
                    .font(BudgetFont.cardLabel)
                    .foregroundStyle(.secondary)
                assumptionRow("Votre taux", FinanceFormatting.percent(report.rate))
                assumptionRow("Revenus imposables \(String(currentYear))", FinanceFormatting.chf(report.taxableIncome))
                assumptionRow("Point de départ", report.isOverridden ? "Le montant que vous avez saisi" : "Vos revenus notés, à votre taux")
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
            Text("Ce sont des estimations pour vous organiser. Elles ne remplacent ni votre déclaration ni les décomptes officiels de votre canton.")
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
        case .rate:
            ("Votre taux", "La part de vos revenus que vous mettez de côté. Zéro tant que vous n'avez rien choisi : l'app ne calcule aucun impôt à votre place.", (profile?.provisionRate ?? households.first?.taxProvisionRate ?? .zero) * 100)
        case .reserved:
            ("Déjà mis de côté", "L'argent que vous avez déjà réservé pour vos impôts \(String(currentYear)).", provision?.reservedAmount)
        case .arrears:
            ("Arriérés", "Ce que vous devez encore pour les années passées : décomptes finaux, rattrapages.", provision?.arrearsAmount)
        case .override:
            ("Pour toute l'année", "Remplace le calcul automatique (vos revenus, à votre taux). Laissez vide pour y revenir.", provision?.estimatedAnnualTaxOverride)
        }
        return AmountEntrySheet(
            title: title,
            footer: footer,
            initialValue: initial,
            allowsEmpty: kind == .override,
            // A17 (risque n° 4) : le taux est borné comme sur la PWA —
            // 0 à 60 % — via la constante unique de TaxService.
            maximum: kind == .rate ? TaxService.maximumProvisionRate * 100 : nil,
            maximumMessage: kind == .rate ? "Taux entre 0 et 60 %. Exemple : 30" : nil
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
            case .rate:
                let percent = value ?? Decimal("30")
                profile.provisionRate = FinanceMath.roundedToCents(percent / 100)
                profile.updatedAt = now
                // Keep the legacy seed coherent for pre-V4 codepaths.
                households.first?.taxProvisionRate = profile.provisionRate
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
    /// Borne haute optionnelle (ex. 60 pour un taux en %) — au-delà, la
    /// saisie est refusée avec `maximumMessage`, jamais tronquée en silence.
    var maximum: Decimal?
    var maximumMessage: String?
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
        if let maximum, parsed > maximum {
            errorMessage = maximumMessage ?? "Cette valeur dépasse le maximum autorisé."
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
