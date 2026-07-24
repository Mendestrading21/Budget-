import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Local document register: metadata + securely stored files.
struct DocumentsListView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FinancialDocument.addedAt, order: .reverse)
    private var documents: [FinancialDocument]

    @State private var isImportingFile = false
    @State private var editedDocument: FinancialDocument?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            if documents.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Documents")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isImportingFile = true
                } label: {
                    Label("Ajouter un document", systemImage: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: [.pdf, .image, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(item: $editedDocument) { document in
            DocumentFormView(document: document)
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: BudgetSpacing.small) {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(BudgetColor.negative)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(documents) { document in
                    DocumentRow(
                        document: document,
                        fileURL: appContainer.documentFileStore.url(for: document.fileReference)
                    )
                    .onTapGesture { editedDocument = document }
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }

    private var emptyState: some View {
        ScrollView {
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                    Label("Aucun document", systemImage: "folder")
                        .font(BudgetFont.sectionTitle)
                    Text("Certificats LPP, polices, décomptes fiscaux… Vos documents restent chiffrés sur cet appareil, jamais envoyés ailleurs.")
                        .font(BudgetFont.body)
                        .foregroundStyle(.secondary)
                    Button("Ajouter un document") {
                        isImportingFile = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BudgetColor.indigo)
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .obsidianFABClearance()
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        guard case .success(let urls) = result, let url = urls.first else { return }
        do {
            let stored = try appContainer.documentFileStore.copyIn(from: url)
            let now = appContainer.dateProvider.now
            let document = FinancialDocument(
                title: url.deletingPathExtension().lastPathComponent,
                kind: .other,
                fileReference: stored.fileReference,
                fileSizeBytes: stored.sizeBytes,
                addedAt: now,
                updatedAt: now
            )
            modelContext.insert(document)
            try modelContext.save()
            editedDocument = document
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "L'ajout du document a échoué. Réessayez."
        }
    }
}

struct DocumentRow: View {
    let document: FinancialDocument
    let fileURL: URL?

    private var sizeLabel: String? {
        guard let bytes = document.fileSizeBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    var body: some View {
        GlassCard(style: .row) {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: document.kind.systemImage)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(BudgetFont.body.weight(.medium))
                        .lineLimit(1)
                    HStack(spacing: BudgetSpacing.micro) {
                        Text(document.kind.displayName)
                        if let year = document.year { Text("· \(String(year))") }
                        if let provider = document.provider, !provider.isEmpty { Text("· \(provider)") }
                        if let sizeLabel { Text("· \(sizeLabel)") }
                    }
                    .font(BudgetFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                Spacer(minLength: BudgetSpacing.small)
                if let fileURL {
                    ShareLink(item: fileURL) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(BudgetColor.electricBlue)
                    }
                    .accessibilityLabel("Partager \(document.title)")
                } else if !document.fileReference.isEmpty {
                    // L7 : fichier attendu mais introuvable — état ÉCRIT,
                    // jamais un bouton de partage qui disparaît en silence.
                    StatusPill(text: "Fichier absent", kind: .warning)
                        .accessibilityLabel("Le fichier de \(document.title) est absent — seules les informations restent.")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Metadata editor for one document; deleting removes file + metadata.
struct DocumentFormView: View {
    let document: FinancialDocument

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer

    @Query private var households: [Household]

    @State private var title = ""
    @State private var kind: DocumentKind = .other
    @State private var yearText = ""
    @State private var provider = ""
    @State private var note = ""
    @State private var member: HouseholdMember?
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    TextField("Titre", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(DocumentKind.allCases) { kind in
                            Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    TextField("Année (facultatif)", text: $yearText)
                        .keyboardType(.numberPad)
                    TextField("Fournisseur (facultatif)", text: $provider)
                    if let members = households.first?.members, !members.isEmpty {
                        Picker("Membre", selection: $member) {
                            Text("Tout le ménage").tag(HouseholdMember?.none)
                            ForEach(members) { member in
                                Text(member.firstName).tag(HouseholdMember?.some(member))
                            }
                        }
                    }
                    TextField("Note (facultatif)", text: $note, axis: .vertical)
                }
                Section {
                    Button("Supprimer ce document", role: .destructive) {
                        isConfirmingDelete = true
                    }
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(BudgetColor.negative)
                    }
                }
            }
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                }
            }
            .confirmationDialog(
                "Supprimer ce document ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer le fichier et ses informations", role: .destructive) { deleteDocument() }
            } message: {
                Text("Le fichier sera définitivement effacé de cet appareil.")
            }
            .onAppear {
                title = document.title
                kind = document.kind
                yearText = document.year.map(String.init) ?? ""
                provider = document.provider ?? ""
                note = document.note ?? ""
                member = document.member
            }
        }
    }

    private func save() {
        errorMessage = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Donnez un titre à ce document."
            return
        }
        var year: Int?
        let trimmedYear = yearText.trimmingCharacters(in: .whitespaces)
        if !trimmedYear.isEmpty {
            guard let parsed = Int(trimmedYear), (1990...2100).contains(parsed) else {
                errorMessage = "L'année doit être comprise entre 1990 et 2100."
                return
            }
            year = parsed
        }
        document.title = trimmedTitle
        document.kind = kind
        document.year = year
        document.provider = provider.trimmingCharacters(in: .whitespaces).isEmpty ? nil : provider.trimmingCharacters(in: .whitespaces)
        document.note = note.trimmingCharacters(in: .whitespaces).isEmpty ? nil : note.trimmingCharacters(in: .whitespaces)
        document.member = member
        document.updatedAt = appContainer.dateProvider.now
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "L'enregistrement a échoué. Réessayez."
        }
    }

    private func deleteDocument() {
        do {
            if !document.fileReference.isEmpty {
                try appContainer.documentFileStore.delete(document.fileReference)
            }
            modelContext.delete(document)
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "La suppression a échoué. Réessayez."
        }
    }
}

#Preview("Documents") {
    let preview = DemoDataFactory.previewAppContainer()
    return NavigationStack {
        DocumentsListView()
    }
    .environment(preview)
    .modelContainer(preview.modelContainer)
    .preferredColorScheme(.dark)
}
