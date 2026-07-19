import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Observation

/// State machine of the CSV import wizard. Every step before `report`
/// works purely in memory; only the final confirmation writes.
@Observable
final class ImportWizardModel {
    enum Step {
        case pickFile
        case mapColumns
        case chooseTargets
        case review
        case report
    }

    var step: Step = .pickFile
    var fileName = ""
    var parsed: ParsedCSV?
    var mapping = ColumnMapping()
    var targetAccount: Account?
    var missingCategories: [String] = []
    var confirmedCategories: Set<String> = []
    var validatedRows: [ImportRowResult] = []
    var report: ImportReport?
    var errorMessage: String?

    var readyCount: Int { validatedRows.filter { $0.state.isImportable }.count }
    var duplicateCount: Int { validatedRows.filter { $0.state == .duplicate }.count }
    var invalidCount: Int {
        validatedRows.count - readyCount - duplicateCount
    }

    func reset() {
        step = .pickFile
        fileName = ""
        parsed = nil
        mapping = ColumnMapping()
        targetAccount = nil
        missingCategories = []
        confirmedCategories = []
        validatedRows = []
        report = nil
        errorMessage = nil
    }
}

/// Notion CSV import wizard: file → mapping → targets → review → report.
struct ImportWizardView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \BudgetCategory.sortOrder) private var categories: [BudgetCategory]

    @State private var model = ImportWizardModel()
    @State private var isPickingFile = false

    private var importService: CSVImportService {
        CSVImportService(calendar: appContainer.calendar)
    }

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(spacing: BudgetSpacing.medium) {
                    stepContent
                    if let errorMessage = model.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            }
        }
        .navigationTitle("Import CSV")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFile(result)
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .pickFile: pickFileStep
        case .mapColumns: mapColumnsStep
        case .chooseTargets: chooseTargetsStep
        case .review: reviewStep
        case .report: reportStep
        }
    }

    private var pickFileStep: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                Label("Importer un export Notion (CSV)", systemImage: "square.and.arrow.down")
                    .font(BudgetFont.sectionTitle)
                Text("Choisissez le fichier CSV exporté depuis Notion (ou tout CSV avec date, montant et intitulé). Rien ne sera importé avant votre confirmation finale — un ré-import du même fichier ne crée jamais de doublons.")
                    .font(BudgetFont.body)
                    .foregroundStyle(.secondary)
                Button("Choisir un fichier CSV") {
                    model.errorMessage = nil
                    isPickingFile = true
                }
                .buttonStyle(.borderedProminent)
                .tint(BudgetColor.indigo)
            }
        }
    }

    private var mapColumnsStep: some View {
        VStack(spacing: BudgetSpacing.medium) {
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Label(model.fileName, systemImage: "doc.text")
                        .font(BudgetFont.sectionTitle)
                    if let parsed = model.parsed {
                        Text("\(parsed.rows.count) ligne(s) · séparateur « \(String(parsed.delimiter)) » · \(parsed.headers.count) colonnes détectées")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text("Correspondance des colonnes")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    columnPicker("Date *", selection: bindingFor(\.dateIndex))
                    columnPicker("Montant *", selection: bindingFor(\.amountIndex))
                    columnPicker("Intitulé *", selection: bindingFor(\.titleIndex))
                    columnPicker("Catégorie", selection: bindingFor(\.categoryIndex))
                    columnPicker("Type", selection: bindingFor(\.typeIndex))
                }
            }
            wizardControls(
                nextTitle: "Continuer",
                nextEnabled: model.mapping.isUsable,
                onNext: {
                    revalidate()
                    model.step = .chooseTargets
                },
                onBack: { model.reset() }
            )
        }
    }

    private func bindingFor(_ keyPath: WritableKeyPath<ColumnMapping, Int?>) -> Binding<Int?> {
        Binding(
            get: { model.mapping[keyPath: keyPath] },
            set: { model.mapping[keyPath: keyPath] = $0 }
        )
    }

    private func columnPicker(_ label: String, selection: Binding<Int?>) -> some View {
        Picker(label, selection: selection) {
            Text("—").tag(Int?.none)
            if let headers = model.parsed?.headers {
                ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                    Text(header.isEmpty ? "Colonne \(index + 1)" : header).tag(Int?.some(index))
                }
            }
        }
        .pickerStyle(.menu)
        .tint(BudgetColor.electricBlue)
    }

    private var chooseTargetsStep: some View {
        VStack(spacing: BudgetSpacing.medium) {
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Text("Compte de destination")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    Picker("Compte", selection: Bindable(model).targetAccount) {
                        Text("Choisir…").tag(Account?.none)
                        ForEach(accounts.filter(\.isActive)) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BudgetColor.electricBlue)
                }
            }
            if !model.missingCategories.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text("Nouvelles catégories détectées")
                            .font(BudgetFont.cardLabel)
                            .foregroundStyle(.secondary)
                        Text("Cochez celles à créer ; les lignes des catégories non cochées seront importées sans catégorie.")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                        ForEach(model.missingCategories, id: \.self) { name in
                            Toggle(name, isOn: Binding(
                                get: { model.confirmedCategories.contains(name) },
                                set: { isOn in
                                    if isOn { model.confirmedCategories.insert(name) }
                                    else { model.confirmedCategories.remove(name) }
                                }
                            ))
                            .tint(BudgetColor.indigo)
                        }
                    }
                }
            }
            wizardControls(
                nextTitle: "Vérifier les lignes",
                nextEnabled: model.targetAccount != nil,
                onNext: { model.step = .review },
                onBack: { model.step = .mapColumns }
            )
        }
    }

    private var reviewStep: some View {
        VStack(spacing: BudgetSpacing.medium) {
            GlassCard(style: .hero) {
                VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
                    Text("Prêt à importer")
                        .font(BudgetFont.cardLabel)
                        .foregroundStyle(.secondary)
                    Text("\(model.readyCount) ligne(s)")
                        .font(BudgetFont.heroAmount)
                    Text("\(model.duplicateCount) doublon(s) ignoré(s) · \(model.invalidCount) invalide(s) — le détail reste visible ci-dessous")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            rowList(model.validatedRows.filter { !$0.state.isImportable }, title: "Lignes non importées")
            wizardControls(
                nextTitle: "Importer \(model.readyCount) ligne(s)",
                nextEnabled: model.readyCount > 0,
                onNext: { runImport() },
                onBack: { model.step = .chooseTargets }
            )
        }
    }

    private var reportStep: some View {
        VStack(spacing: BudgetSpacing.medium) {
            if let report = model.report {
                GlassCard(style: .hero) {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Label("Import terminé", systemImage: "checkmark.seal.fill")
                            .font(BudgetFont.sectionTitle)
                            .foregroundStyle(BudgetColor.positive)
                        reportRow("Lignes du fichier", "\(report.totalRows)")
                        reportRow("Importées", "\(report.importedCount)")
                        reportRow("Doublons ignorés", "\(report.duplicateCount)")
                        reportRow("Invalides", "\(report.invalidCount)")
                        if !report.createdCategoryNames.isEmpty {
                            reportRow("Catégories créées", report.createdCategoryNames.joined(separator: ", "))
                        }
                    }
                }
                if !report.rejectedRows.isEmpty {
                    rowList(report.rejectedRows, title: "File de réparation — à corriger à la main")
                }
                VStack(spacing: BudgetSpacing.small) {
                    Button("Terminer") {
                        model.reset()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BudgetColor.indigo)
                    .frame(maxWidth: .infinity)
                    Button("Annuler ce lot (retirer les \(report.importedCount) mouvements)", role: .destructive) {
                        rollback(report: report)
                    }
                    .font(BudgetFont.caption)
                }
            }
        }
    }

    // MARK: - Building blocks

    private func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(BudgetFont.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(BudgetFont.caption.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func rowList(_ rows: [ImportRowResult], title: String) -> some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                Text(title)
                    .font(BudgetFont.sectionTitle)
                    .foregroundStyle(.secondary)
                ForEach(rows) { row in
                    GlassCard(style: .row) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Ligne \(row.id + 2)")
                                    .font(BudgetFont.caption.weight(.semibold))
                                Spacer()
                                stateBadge(row.state)
                            }
                            Text(row.rawLine)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private func stateBadge(_ state: ImportRowState) -> some View {
        switch state {
        case .ready:
            Text("Prête")
                .font(BudgetFont.caption)
                .foregroundStyle(BudgetColor.positive)
        case .duplicate:
            Text("Doublon")
                .font(BudgetFont.caption.weight(.semibold))
                .foregroundStyle(BudgetColor.informative)
        case .invalid(let reason):
            Text(reason)
                .font(BudgetFont.caption.weight(.semibold))
                .foregroundStyle(BudgetColor.warning)
                .multilineTextAlignment(.trailing)
        }
    }

    private func wizardControls(
        nextTitle: String,
        nextEnabled: Bool,
        onNext: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) -> some View {
        VStack(spacing: BudgetSpacing.small) {
            Button {
                onNext()
            } label: {
                Text(nextTitle)
                    .font(BudgetFont.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        nextEnabled ? AnyShapeStyle(LinearGradient.budgetAccent) : AnyShapeStyle(BudgetColor.slateBlue),
                        in: RoundedRectangle(cornerRadius: BudgetRadius.control)
                    )
                    .foregroundStyle(nextEnabled ? .white : BudgetColor.coolGray)
            }
            .disabled(!nextEnabled)
            Button("Retour") { onBack() }
                .font(BudgetFont.body)
                .foregroundStyle(BudgetColor.coolGray)
        }
    }

    // MARK: - Actions

    private func handleFile(_ result: Result<[URL], Error>) {
        model.errorMessage = nil
        guard case .success(let urls) = result, let url = urls.first else { return }
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
            model.errorMessage = "Le fichier n'a pas pu être lu (encodage non reconnu)."
            return
        }
        guard let parsed = importService.parse(text: text) else {
            model.errorMessage = "Ce fichier ne ressemble pas à un CSV exploitable (au moins 2 colonnes et une ligne d'en-têtes)."
            return
        }
        model.fileName = url.lastPathComponent
        model.parsed = parsed
        model.mapping = importService.suggestMapping(headers: parsed.headers)
        model.step = .mapColumns
        revalidate()
    }

    /// Re-runs pure validation whenever mapping/targets change.
    private func revalidate() {
        guard let parsed = model.parsed, model.mapping.isUsable else { return }
        let existing = (try? importService.existingFingerprints(context: modelContext)) ?? []
        model.validatedRows = importService.validate(
            parsed: parsed,
            mapping: model.mapping,
            fileName: model.fileName,
            existingFingerprints: existing
        )
        model.missingCategories = importService.missingCategoryNames(
            rows: model.validatedRows,
            existing: categories
        )
    }

    private func runImport() {
        guard let account = model.targetAccount else { return }
        revalidate()
        do {
            let report = try importService.apply(
                rows: model.validatedRows,
                fileName: model.fileName,
                account: account,
                categories: categories,
                confirmedNewCategories: Array(model.confirmedCategories),
                now: appContainer.dateProvider.now,
                context: modelContext
            )
            model.report = report
            model.step = .report
        } catch {
            model.errorMessage = "L'import a échoué ; aucune ligne n'a été enregistrée. Réessayez."
        }
    }

    private func rollback(report: ImportReport) {
        do {
            _ = try importService.rollback(batchID: report.batchID, context: modelContext)
            model.reset()
        } catch {
            model.errorMessage = "L'annulation du lot a échoué. Réessayez."
        }
    }
}

#Preview("Import CSV") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        ImportWizardView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
