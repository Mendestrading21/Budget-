import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Réglages: app lock, data portability (export, backup, restore),
/// complete deletion, privacy and methodology.
struct SettingsView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BudgetTransaction.date) private var transactions: [BudgetTransaction]

    @State private var exportCSVURL: URL?
    @State private var backupURL: URL?
    @State private var isRestoring = false
    @State private var pendingRestoreData: Data?
    @State private var pendingRestoreSummary: BackupService.Summary?
    @State private var isConfirmingRestore = false
    @State private var isConfirmingDeleteAll = false
    @State private var isConfirmingDeleteAllSecond = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var isShowingPrivacy = false
    @State private var isShowingMethodology = false
    @State private var didAutoPromptRestore = false

    private var backupService: BackupService { BackupService() }
    private var lockManager: AppLockManager { appContainer.lockManager }

    var body: some View {
        Form {
            securitySection
            dataSection
            aboutSection
            if let statusMessage {
                Section {
                    Label(statusMessage, systemImage: "checkmark.circle")
                        .foregroundStyle(BudgetColor.positive)
                }
            }
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(BudgetColor.negative)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .obsidianFABClearance()
        .background(BudgetScreenBackground())
        .navigationTitle("Réglages")
        .fileImporter(
            isPresented: $isRestoring,
            allowedContentTypes: [.json, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            prepareRestore(result)
        }
        .confirmationDialog(
            "Restaurer cette sauvegarde ?",
            isPresented: $isConfirmingRestore,
            titleVisibility: .visible
        ) {
            Button("Remplacer toutes mes données", role: .destructive) { runRestore() }
            Button("Annuler", role: .cancel) {
                pendingRestoreData = nil
                pendingRestoreSummary = nil
            }
        } message: {
            // L7 : résumé RÉEL — date, version, contenu, portée exacte et
            // ce que la sauvegarde ne contient PAS.
            Text(restoreSummaryMessage)
        }
        .confirmationDialog(
            "Supprimer toutes les données ?",
            isPresented: $isConfirmingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("D'abord créer une sauvegarde") {
                generateBackup()
            }
            Button("Continuer vers la confirmation finale", role: .destructive) {
                isConfirmingDeleteAllSecond = true
            }
        } message: {
            Text("Comptes, mouvements, budgets, objectifs, documents (fichiers compris) : tout sera effacé de cet appareil. Rien d'autre n'est touché.")
        }
        .alert("Dernière confirmation", isPresented: $isConfirmingDeleteAllSecond) {
            Button("Tout supprimer définitivement", role: .destructive) { runDeleteAll() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Sans sauvegarde exportée, ces données seront perdues pour toujours.")
        }
        .sheet(isPresented: $isShowingPrivacy) {
            InfoSheet(title: "Confidentialité", paragraphs: Self.privacyParagraphs)
        }
        .sheet(isPresented: $isShowingMethodology) {
            InfoSheet(title: "Méthodologie", paragraphs: Self.methodologyParagraphs)
        }
        .onAppear {
            // Preuve UI (workflow Demo) : ouvre le VRAI résumé de
            // restauration construit par BackupService depuis les données
            // de démo. Inactif en dehors du tour automatisé.
            if ProcessInfo.processInfo.arguments.contains("-uiTestRestorePrompt"),
               !didAutoPromptRestore,
               let data = try? backupService.makeBackup(context: modelContext, now: appContainer.dateProvider.now),
               let summary = try? backupService.summary(of: data) {
                didAutoPromptRestore = true
                pendingRestoreSummary = summary
                pendingRestoreData = data
                isConfirmingRestore = true
            }
        }
    }

    // MARK: - Sections

    private var securitySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { lockManager.isLockEnabled },
                set: { enabled in
                    Task { await toggleLock(enabled) }
                }
            )) {
                Label("Verrouiller avec \(lockManager.authService.biometryLabel)", systemImage: "faceid")
            }
            .tint(BudgetColor.indigo)
            .disabled(!lockManager.authService.canAuthenticate)
        } header: {
            Text("Sécurité")
        } footer: {
            Text(lockManager.authService.canAuthenticate
                 ? "L'app se verrouille à chaque passage en arrière-plan. L'activation et la désactivation demandent une authentification."
                 : "Aucune méthode d'authentification n'est configurée sur cet appareil (Face ID, Touch ID ou code).")
        }
    }

    private var dataSection: some View {
        Section {
            if let exportCSVURL {
                ShareLink(item: exportCSVURL) {
                    Label("Partager les mouvements (CSV)", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    generateCSV()
                } label: {
                    Label("Exporter les mouvements (CSV)", systemImage: "tablecells")
                }
            }

            if let backupURL {
                ShareLink(item: backupURL) {
                    Label("Partager la sauvegarde (JSON)", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    generateBackup()
                } label: {
                    Label("Créer une sauvegarde complète (JSON)", systemImage: "externaldrive")
                }
            }

            Button {
                errorMessage = nil
                statusMessage = nil
                isRestoring = true
            } label: {
                Label("Restaurer une sauvegarde…", systemImage: "arrow.counterclockwise")
            }

            Button(role: .destructive) {
                errorMessage = nil
                statusMessage = nil
                isConfirmingDeleteAll = true
            } label: {
                Label("Supprimer toutes les données", systemImage: "trash")
                    .foregroundStyle(BudgetColor.negative)
            }
        } header: {
            Text("Vos données")
        } footer: {
            Text("Export et sauvegarde ne partent nulle part tout seuls : vous choisissez où les envoyer. La sauvegarde contient les données, pas les fichiers de documents.")
        }
    }

    private var aboutSection: some View {
        Section("À propos") {
            Button {
                isShowingPrivacy = true
            } label: {
                Label("Confidentialité", systemImage: "lock.shield")
            }
            Button {
                isShowingMethodology = true
            } label: {
                Label("Méthodologie des calculs", systemImage: "function")
            }
        }
    }

    // MARK: - Actions

    private func toggleLock(_ enabled: Bool) async {
        errorMessage = nil
        let outcome = await lockManager.setEnabled(enabled)
        if case .failed(let message) = outcome {
            errorMessage = message
        } else if outcome == .unavailable {
            errorMessage = "Aucune méthode d'authentification n'est configurée sur cet appareil."
        }
    }

    private func writeTemporaryFile(_ data: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        } catch {
            errorMessage = "La préparation du fichier a échoué. Réessayez."
            return nil
        }
    }

    private func fileStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: appContainer.dateProvider.now)
    }

    private func generateCSV() {
        errorMessage = nil
        let csv = backupService.transactionsCSV(transactions, calendar: appContainer.calendar)
        exportCSVURL = writeTemporaryFile(Data(csv.utf8), name: "budget-mouvements-\(fileStamp()).csv")
    }

    private func generateBackup() {
        errorMessage = nil
        do {
            let data = try backupService.makeBackup(context: modelContext, now: appContainer.dateProvider.now)
            backupURL = writeTemporaryFile(data, name: "budget-sauvegarde-\(fileStamp()).json")
        } catch {
            errorMessage = "La création de la sauvegarde a échoué. Réessayez."
        }
    }

    /// Message de confirmation construit depuis la VRAIE sauvegarde.
    private var restoreSummaryMessage: String {
        guard let summary = pendingRestoreSummary else {
            return "Toutes les données actuelles seront remplacées par le contenu de la sauvegarde. Cette action est irréversible."
        }
        return "Sauvegarde du \(FinanceFormatting.swissDate(summary.exportedAt)) (schéma \(summary.schemaVersion)). "
            + "Contenu : \(summary.transactions) mouvements, \(summary.accounts) comptes, \(summary.goals) objectifs, "
            + "\(summary.recurrings) récurrents, \(summary.documents) documents (métadonnées). "
            + "La restauration REMPLACE toutes les données actuelles de cet appareil — irréversible. "
            + "Non contenu : les fichiers des documents et le réglage de verrouillage."
    }

    private func prepareRestore(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url) else {
            errorMessage = "Le fichier de sauvegarde n'a pas pu être lu."
            return
        }
        // Refus AVANT toute confirmation (illisible / version future) :
        // les données actuelles restent intactes.
        do {
            pendingRestoreSummary = try backupService.summary(of: data)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Cette sauvegarde est illisible — vos données actuelles sont intactes."
            return
        }
        pendingRestoreData = data
        isConfirmingRestore = true
    }

    private func runRestore() {
        guard let data = pendingRestoreData else { return }
        pendingRestoreData = nil
        pendingRestoreSummary = nil
        do {
            try backupService.restore(
                data: data,
                context: modelContext,
                documentFileStore: appContainer.documentFileStore
            )
            statusMessage = "Sauvegarde restaurée."
            // Stale share links would still offer pre-restore exports.
            exportCSVURL = nil
            backupURL = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "La restauration a échoué ; vos données actuelles sont intactes."
        }
    }

    private func runDeleteAll() {
        do {
            try backupService.deleteAll(
                context: modelContext,
                documentFileStore: appContainer.documentFileStore
            )
            statusMessage = "Toutes les données ont été supprimées."
            exportCSVURL = nil
            backupURL = nil
        } catch {
            errorMessage = "La suppression a échoué. Réessayez."
        }
    }

    // MARK: - Texts (must match the actual implementation)

    static let privacyParagraphs: [String] = [
        "Vos données restent sur cet appareil. Budget n'a pas de serveur, pas de compte en ligne, et n'établit aucune connexion réseau.",
        "Aucune connexion bancaire : l'app ne se connecte à aucune banque et ne prétend pas le faire. Vous saisissez ou importez vos données vous-même.",
        "Les documents que vous ajoutez sont copiés dans le conteneur protégé de l'app et chiffrés par iOS (protection complète des fichiers).",
        "Aucune analyse d'usage, aucun traceur, aucune publicité.",
        "L'export CSV et la sauvegarde JSON ne sont créés que lorsque vous le demandez, et ne quittent l'appareil que par le partage que vous choisissez.",
        "La suppression complète efface les données et les documents de l'app sur cet appareil. Les sauvegardes que vous avez exportées ailleurs restent sous votre contrôle.",
    ]

    static let methodologyParagraphs: [String] = [
        "Tous les montants sont des estimations d'organisation personnelle, pas des conseils financiers ni des documents officiels.",
        "Vraiment disponible = liquidités incluses + revenus attendus (prévus et récurrents) − charges engagées (prévues et récurrentes) − réserve d'impôts manquante.",
        "Taux d'épargne = (épargne + investissements) ÷ revenus du mois ; zéro quand il n'y a pas de revenus.",
        "Les virements internes déplacent l'argent entre vos comptes : ils ne comptent ni comme revenu, ni comme dépense, et ne changent pas votre fortune.",
        "Provision d'impôts = revenus × votre taux configuré (30 % par défaut), corrigeable manuellement. Estimé = payé + encore dû, toujours.",
        "Fortune nette = comptes inclus + actifs + prévoyance − dettes. Les projections de retraite affichées sont celles de vos certificats, jamais un calcul de l'app.",
        "Le planifié et le réel ne sont jamais mélangés : un mouvement prévu n'entre dans aucun solde tant qu'il n'est pas comptabilisé.",
    ]
}

/// Simple scrollable text sheet for privacy/methodology.
struct InfoSheet: View {
    let title: String
    let paragraphs: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BudgetScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            GlassCard(style: .row) {
                                Text(paragraph)
                                    .font(BudgetFont.body)
                            }
                        }
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

/// Full-screen lock overlay. Cancelling authentication keeps the app
/// locked; only success dismisses this screen.
struct LockScreenView: View {
    let lockManager: AppLockManager

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            VStack(spacing: BudgetSpacing.large) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(LinearGradient.budgetAccent)
                Text("Budget est verrouillé")
                    .font(BudgetFont.screenTitle)
                    .foregroundStyle(.primary)
                if let message = lockManager.lastErrorMessage {
                    Text(message)
                        .font(BudgetFont.body)
                        .foregroundStyle(BudgetColor.negative)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                Button {
                    Task { await lockManager.attemptUnlock() }
                } label: {
                    Label(
                        "Déverrouiller avec \(lockManager.authService.biometryLabel)",
                        systemImage: "faceid"
                    )
                    .font(BudgetFont.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.budgetAccent, in: RoundedRectangle(cornerRadius: BudgetRadius.control))
                    .foregroundStyle(.white)
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .accessibilityAddTraits(.isModal)
    }
}

#Preview("Réglages") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        SettingsView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
