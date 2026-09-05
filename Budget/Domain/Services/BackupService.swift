import Foundation
import SwiftData

// MARK: - Backup document (JSON)

/// Portable snapshot of the whole store. Every amount travels as a String
/// (`"2150.00"`) so Decimal precision survives JSON exactly; every
/// relationship travels as a UUID. `schemaVersion` gates restores.
struct BackupFile: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var households: [HouseholdDTO]
    var members: [MemberDTO]
    var accounts: [AccountDTO]
    var categories: [CategoryDTO]
    var transactions: [TransactionDTO]
    var budgets: [BudgetDTO]
    var budgetLines: [BudgetLineDTO]
    var recurrings: [RecurringDTO]
    var taxProfiles: [TaxProfileDTO]
    var taxProvisions: [TaxProvisionDTO]
    var goals: [GoalDTO]
    var insuranceContracts: [InsuranceDTO]
    var pensionAssets: [PensionDTO]
    var assets: [AssetDTO]
    var liabilities: [LiabilityDTO]
    var netWorthSnapshots: [NetWorthSnapshotDTO]
    var documents: [DocumentDTO]
    // Optional: absent from backups made before the round-trip audit.
    var importBatches: [ImportBatchDTO]?
    /// INV1 (ADR-047) : optionnelles — les sauvegardes d'avant les
    /// positions n'ont pas ce champ et se restaurent à l'identique.
    var positions: [PositionDTO]?
    /// W10.5 (ADR-072) : les FICHIERS des pièces jointes, optionnels —
    /// les sauvegardes antérieures (métadonnées seules) se restaurent
    /// à l'identique.
    var documentFiles: [DocumentFileDTO]?

    struct HouseholdDTO: Codable {
        var id: UUID; var name: String; var currency: String; var canton: String
        var municipality: String; var taxRate: String; var createdAt: Date
        var updatedAt: Date?
    }
    struct MemberDTO: Codable {
        var id: UUID; var householdID: UUID?; var firstName: String; var role: String
        var birthDate: Date?; var employmentStatus: String?; var includeInBudget: Bool
    }
    struct AccountDTO: Codable {
        var id: UUID; var name: String; var institution: String; var type: String
        var currency: String; var openingBalance: String; var reconciledBalance: String?
        var reconciledAt: Date?; var isShared: Bool; var isActive: Bool
        var includeInAvailableCash: Bool; var includeInNetWorth: Bool
        var ownerID: UUID?; var createdAt: Date; var updatedAt: Date?
    }
    struct CategoryDTO: Codable {
        var id: UUID; var name: String; var kind: String; var iconToken: String
        var emoji: String?; var isEssential: Bool; var isActive: Bool
        var sortOrder: Int; var parentID: UUID?
    }
    struct TransactionDTO: Codable {
        var id: UUID; var date: Date; var amount: String; var type: String
        var status: String; var title: String; var note: String?; var merchant: String?
        var adjustmentIncreasesBalance: Bool; var importFingerprint: String?
        var recurringID: UUID?; var importBatchID: UUID?
        var accountID: UUID?; var destinationAccountID: UUID?
        var categoryID: UUID?; var memberID: UUID?; var createdAt: Date
        var updatedAt: Date?
    }
    struct BudgetDTO: Codable { var id: UUID; var year: Int; var month: Int }
    struct BudgetLineDTO: Codable {
        var id: UUID; var budgetID: UUID?; var categoryID: UUID?; var planned: String
    }
    struct RecurringDTO: Codable {
        var id: UUID; var title: String; var amount: String; var type: String
        var unit: String; var count: Int; var firstOccurrence: Date; var endDate: Date?
        var isActive: Bool; var isProfessional: Bool; var isSubscription: Bool
        var renewalDate: Date?; var cancellationDeadline: Date?; var note: String?
        var accountID: UUID?; var destinationAccountID: UUID?
        var categoryID: UUID?; var memberID: UUID?
        /// ID1 (ADR-042) : optionnelle — les anciennes sauvegardes n'ont
        /// pas ce champ et se restaurent à l'identique.
        var identityKey: String?
    }
    struct TaxProfileDTO: Codable {
        var id: UUID; var canton: String; var municipality: String
        var rate: String; var notes: String?
    }
    struct TaxProvisionDTO: Codable {
        var id: UUID; var profileID: UUID?; var year: Int; var override_: String?
        var reserved: String; var arrears: String; var dueDates: [TaxDueDate]
        var notes: String?
    }
    struct GoalDTO: Codable {
        var id: UUID; var name: String; var kind: String; var emoji: String?
        var target: String; var targetDate: Date?; var manualCurrent: String
        var plannedMonthly: String; var priority: String; var status: String
        var note: String?; var linkedAccountID: UUID?
    }
    struct InsuranceDTO: Codable {
        var id: UUID; var insurer: String; var policyName: String; var policyNumber: String?
        var kind: String; var premium: String; var unit: String; var count: Int
        var deductible: String?; var startDate: Date?; var renewalDate: Date?
        var cancellationDeadline: Date?; var noticePeriodDays: Int?
        var coverageSummary: String?; var documentReference: String?
        var isActive: Bool; var note: String?; var memberID: UUID?
    }
    struct PensionDTO: Codable {
        var id: UUID; var pillar: String; var institution: String; var currentValue: String
        var annualContribution: String; var projected: String?; var retirementAge: Int?
        var sourceDate: Date?; var sourceReference: String?; var isActive: Bool
        var note: String?; var ownerID: UUID?
    }
    struct AssetDTO: Codable {
        var id: UUID; var name: String; var kind: String; var value: String
        var include: Bool; var valuationDate: Date?; var note: String?
    }
    struct LiabilityDTO: Codable {
        var id: UUID; var name: String; var kind: String; var outstanding: String
        var include: Bool; var note: String?
    }
    struct NetWorthSnapshotDTO: Codable {
        var id: UUID; var date: Date; var accounts: String; var assets: String
        var pension: String; var liabilities: String; var netWorth: String
    }
    struct DocumentDTO: Codable {
        var id: UUID; var title: String; var kind: String; var year: Int?
        var provider: String?; var note: String?; var fileReference: String
        var fileSizeBytes: Int?; var memberID: UUID?
        var addedAt: Date?; var updatedAt: Date?
    }
    /// W10.5 : un fichier de pièce jointe, adressé par sa référence —
    /// les octets voyagent en base64 dans le JSON.
    struct DocumentFileDTO: Codable {
        var fileReference: String
        var contents: Data
    }
    struct ImportBatchDTO: Codable {
        var id: UUID; var fileName: String; var importedAt: Date
        var totalRows: Int; var importedCount: Int; var duplicateCount: Int
        var invalidCount: Int; var createdCategories: Int
    }
    struct PositionDTO: Codable {
        var id: UUID; var instrumentName: String; var tickerOrISIN: String?
        var quantity: String; var manualPrice: String; var priceCurrency: String
        var valuationDate: Date; var costBasis: String?; var accountID: UUID?
    }
}

enum BackupError: LocalizedError, Equatable {
    case unreadable
    case newerSchema(found: Int, supported: Int)
    case unsupportedCurrency(codes: [String])
    case corruptAmount(String)
    case unknownValue(field: String, value: String)
    case missingReference(field: String, id: UUID)
    case duplicateIdentifier(entity: String, id: UUID)

    var errorDescription: String? {
        switch self {
        case .unreadable:
            "Cette sauvegarde est illisible ou endommagée."
        case .newerSchema(let found, let supported):
            "Cette sauvegarde vient d'une version plus récente de Budget (schéma \(found), pris en charge : \(supported)). Mettez d'abord l'app à jour."
        case .unsupportedCurrency(let codes):
            "Cette sauvegarde contient des comptes en \(codes.joined(separator: ", ")). Budget V1 gère uniquement le CHF — vos données actuelles n'ont pas été modifiées."
        case .corruptAmount(let raw):
            "Cette sauvegarde contient un montant illisible (« \(raw) ») — la restauration a été annulée, vos données actuelles n'ont pas été modifiées."
        case .unknownValue(let field, let value):
            "Cette sauvegarde contient une valeur inconnue pour \(field) (« \(value) ») — la restauration a été annulée, vos données actuelles n'ont pas été modifiées."
        case .missingReference(let field, let id):
            "Cette sauvegarde contient une relation \(field) vers un élément absent (\(id.uuidString)) — la restauration a été annulée, vos données actuelles n'ont pas été modifiées."
        case .duplicateIdentifier(let entity, let id):
            "Cette sauvegarde contient deux éléments \(entity) avec le même identifiant (\(id.uuidString)) — la restauration a été annulée, vos données actuelles n'ont pas été modifiées."
        }
    }
}

// MARK: - Service

/// Explicitly initiated export, versioned backup/restore and complete
/// local deletion. Restore REPLACES the whole store — the UI must confirm
/// destructively before calling it.
struct BackupService {
    static let currentSchemaVersion = 8

    private func decimalString(_ value: Decimal) -> String { "\(value)" }
    private func decimal(_ string: String) throws -> Decimal {
        // P0 : un montant illisible ne devient JAMAIS zéro en silence —
        // on refuse la sauvegarde, la restauration transactionnelle annule tout.
        guard let value = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) else {
            throw BackupError.corruptAmount(string)
        }
        return value
    }

    private func enumValue<T: RawRepresentable>(
        _ type: T.Type,
        rawValue: String,
        field: String
    ) throws -> T where T.RawValue == String {
        guard let value = T(rawValue: rawValue) else {
            throw BackupError.unknownValue(field: field, value: rawValue)
        }
        return value
    }

    private func resolved<T>(
        _ id: UUID?,
        in values: [UUID: T],
        field: String
    ) throws -> T? {
        guard let id else { return nil }
        guard let value = values[id] else {
            throw BackupError.missingReference(field: field, id: id)
        }
        return value
    }

    // MARK: CSV export (transactions)

    /// Machine-stable CSV: ISO dates, dot decimals, semicolon separator,
    /// quoted fields when needed.
    func transactionsCSV(_ transactions: [BudgetTransaction], calendar: Calendar) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        func escape(_ field: String) -> String {
            if field.contains(";") || field.contains("\"") || field.contains("\n") {
                return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }
            return field
        }
        var lines = ["date;type;statut;montant;devise;compte;vers_compte;categorie;intitule;note"]
        for transaction in transactions.sorted(by: { $0.date < $1.date }) {
            lines.append([
                formatter.string(from: transaction.date),
                transaction.type.rawValue,
                transaction.status.rawValue,
                decimalString(transaction.amount),
                transaction.account?.currencyCode ?? "CHF",
                escape(transaction.account?.name ?? ""),
                escape(transaction.destinationAccount?.name ?? ""),
                escape(transaction.category?.name ?? ""),
                escape(transaction.title),
                escape(transaction.note ?? ""),
            ].joined(separator: ";"))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: JSON backup

    /// W10.4 (ADR-072) : la MÊME sauvegarde, scellée par une phrase de
    /// passe choisie par l'utilisateur — les octets clairs sont
    /// exactement ceux de `makeBackup`, la restauration passe par
    /// `BackupCrypto.decrypt` puis les MÊMES portes (`summary`,
    /// `restore`) que la sauvegarde en clair.
    func makeEncryptedBackup(
        context: ModelContext,
        now: Date,
        passphrase: String,
        documentFileStore: DocumentFileStoring? = nil
    ) throws -> Data {
        try BackupCrypto.encrypt(
            makeBackup(context: context, now: now, documentFileStore: documentFileStore),
            passphrase: passphrase
        )
    }

    /// W10.5 (ADR-072, décision propriétaire) : quand un store de
    /// fichiers est fourni, la sauvegarde emporte AUSSI les fichiers
    /// des pièces jointes (octets exacts, adressés par leur référence).
    /// Un fichier manquant sur le disque n'invente rien : la métadonnée
    /// voyage seule, comme avant.
    func makeBackup(context: ModelContext, now: Date, documentFileStore: DocumentFileStoring? = nil) throws -> Data {
        func fetch<T: PersistentModel>(_ type: T.Type) throws -> [T] {
            try context.fetch(FetchDescriptor<T>())
        }
        let file = BackupFile(
            schemaVersion: Self.currentSchemaVersion,
            exportedAt: now,
            households: try fetch(Household.self).map {
                .init(id: $0.id, name: $0.name, currency: $0.baseCurrencyCode, canton: $0.canton,
                      municipality: $0.municipality, taxRate: decimalString($0.taxProvisionRate),
                      createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            members: try fetch(HouseholdMember.self).map {
                .init(id: $0.id, householdID: $0.household?.id, firstName: $0.firstName,
                      role: $0.roleRawValue, birthDate: $0.birthDate,
                      employmentStatus: $0.employmentStatus, includeInBudget: $0.includeInBudget)
            },
            accounts: try fetch(Account.self).map {
                .init(id: $0.id, name: $0.name, institution: $0.institutionName, type: $0.typeRawValue,
                      currency: $0.currencyCode, openingBalance: decimalString($0.openingBalance),
                      reconciledBalance: $0.reconciledBalance.map(decimalString), reconciledAt: $0.reconciledAt,
                      isShared: $0.isShared, isActive: $0.isActive,
                      includeInAvailableCash: $0.includeInAvailableCash, includeInNetWorth: $0.includeInNetWorth,
                      ownerID: $0.owner?.id, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            categories: try fetch(BudgetCategory.self).map {
                .init(id: $0.id, name: $0.name, kind: $0.kindRawValue, iconToken: $0.iconToken,
                      emoji: $0.emoji, isEssential: $0.isEssential, isActive: $0.isActive,
                      sortOrder: $0.sortOrder, parentID: $0.parent?.id)
            },
            transactions: try fetch(BudgetTransaction.self).map {
                .init(id: $0.id, date: $0.date, amount: decimalString($0.amount), type: $0.typeRawValue,
                      status: $0.statusRawValue, title: $0.title, note: $0.note, merchant: $0.merchant,
                      adjustmentIncreasesBalance: $0.adjustmentIncreasesBalance,
                      importFingerprint: $0.importFingerprint, recurringID: $0.recurringID,
                      importBatchID: $0.importBatchID, accountID: $0.account?.id,
                      destinationAccountID: $0.destinationAccount?.id, categoryID: $0.category?.id,
                      memberID: $0.member?.id, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            budgets: try fetch(MonthlyBudget.self).map {
                .init(id: $0.id, year: $0.year, month: $0.month)
            },
            budgetLines: try fetch(BudgetLine.self).map {
                .init(id: $0.id, budgetID: $0.budget?.id, categoryID: $0.category?.id,
                      planned: decimalString($0.plannedAmount))
            },
            recurrings: try fetch(RecurringTransaction.self).map {
                .init(id: $0.id, title: $0.title, amount: decimalString($0.amount), type: $0.typeRawValue,
                      unit: $0.intervalUnitRawValue, count: $0.intervalCount,
                      firstOccurrence: $0.firstOccurrence, endDate: $0.endDate,
                      isActive: $0.isActive, isProfessional: $0.isProfessional,
                      isSubscription: $0.isSubscription, renewalDate: $0.renewalDate,
                      cancellationDeadline: $0.cancellationDeadline, note: $0.note,
                      accountID: $0.account?.id, destinationAccountID: $0.destinationAccount?.id,
                      categoryID: $0.category?.id, memberID: $0.member?.id,
                      identityKey: $0.identityKey)
            },
            taxProfiles: try fetch(TaxProfile.self).map {
                .init(id: $0.id, canton: $0.canton, municipality: $0.municipality,
                      rate: decimalString($0.provisionRate), notes: $0.notes)
            },
            taxProvisions: try fetch(TaxProvision.self).map {
                .init(id: $0.id, profileID: $0.profile?.id, year: $0.year,
                      override_: $0.estimatedAnnualTaxOverride.map(decimalString),
                      reserved: decimalString($0.reservedAmount), arrears: decimalString($0.arrearsAmount),
                      dueDates: $0.dueDates, notes: $0.notes)
            },
            goals: try fetch(FinancialGoal.self).map {
                .init(id: $0.id, name: $0.name, kind: $0.kindRawValue, emoji: $0.emoji,
                      target: decimalString($0.targetAmount), targetDate: $0.targetDate,
                      manualCurrent: decimalString($0.manualCurrentAmount),
                      plannedMonthly: decimalString($0.plannedMonthlyContribution),
                      priority: $0.priorityRawValue, status: $0.statusRawValue,
                      note: $0.note, linkedAccountID: $0.linkedAccount?.id)
            },
            insuranceContracts: try fetch(InsuranceContract.self).map {
                .init(id: $0.id, insurer: $0.insurerName, policyName: $0.policyName,
                      policyNumber: $0.policyNumber, kind: $0.kindRawValue,
                      premium: decimalString($0.premiumAmount), unit: $0.premiumUnitRawValue,
                      count: $0.premiumIntervalCount, deductible: $0.deductible.map(decimalString),
                      startDate: $0.startDate, renewalDate: $0.renewalDate,
                      cancellationDeadline: $0.cancellationDeadline, noticePeriodDays: $0.noticePeriodDays,
                      coverageSummary: $0.coverageSummary, documentReference: $0.documentReference,
                      isActive: $0.isActive, note: $0.note, memberID: $0.member?.id)
            },
            pensionAssets: try fetch(PensionAsset.self).map {
                .init(id: $0.id, pillar: $0.pillarRawValue, institution: $0.institutionName,
                      currentValue: decimalString($0.currentValue),
                      annualContribution: decimalString($0.annualContribution),
                      projected: $0.projectedValueAtRetirement.map(decimalString),
                      retirementAge: $0.retirementAge, sourceDate: $0.sourceDocumentDate,
                      sourceReference: $0.sourceReference, isActive: $0.isActive,
                      note: $0.note, ownerID: $0.owner?.id)
            },
            assets: try fetch(Asset.self).map {
                .init(id: $0.id, name: $0.name, kind: $0.kindRawValue,
                      value: decimalString($0.currentValue), include: $0.includeInNetWorth,
                      valuationDate: $0.valuationDate, note: $0.note)
            },
            liabilities: try fetch(Liability.self).map {
                .init(id: $0.id, name: $0.name, kind: $0.kindRawValue,
                      outstanding: decimalString($0.outstandingAmount), include: $0.includeInNetWorth,
                      note: $0.note)
            },
            netWorthSnapshots: try fetch(NetWorthSnapshot.self).map {
                .init(id: $0.id, date: $0.date, accounts: decimalString($0.accountsTotal),
                      assets: decimalString($0.assetsTotal), pension: decimalString($0.pensionTotal),
                      liabilities: decimalString($0.liabilitiesTotal), netWorth: decimalString($0.netWorth))
            },
            documents: try fetch(FinancialDocument.self).map {
                .init(id: $0.id, title: $0.title, kind: $0.kindRawValue, year: $0.year,
                      provider: $0.provider, note: $0.note, fileReference: $0.fileReference,
                      fileSizeBytes: $0.fileSizeBytes, memberID: $0.member?.id,
                      addedAt: $0.addedAt, updatedAt: $0.updatedAt)
            },
            importBatches: try fetch(ImportBatch.self).map {
                .init(id: $0.id, fileName: $0.fileName, importedAt: $0.importedAt,
                      totalRows: $0.totalRows, importedCount: $0.importedCount,
                      duplicateCount: $0.duplicateCount, invalidCount: $0.invalidCount,
                      createdCategories: $0.createdCategories)
            },
            positions: try fetch(BrokeragePosition.self).map {
                .init(id: $0.id, instrumentName: $0.instrumentName,
                      tickerOrISIN: $0.tickerOrISIN,
                      quantity: decimalString($0.quantity),
                      manualPrice: decimalString($0.manualPrice),
                      priceCurrency: $0.priceCurrency,
                      valuationDate: $0.valuationDate,
                      costBasis: $0.costBasis.map(decimalString),
                      accountID: $0.account?.id)
            },
            documentFiles: try documentFileStore.map { store in
                try fetch(FinancialDocument.self)
                    .map(\.fileReference)
                    .filter { !$0.isEmpty }
                    .sorted()
                    .compactMap { reference in
                        store.contents(of: reference).map {
                            BackupFile.DocumentFileDTO(fileReference: reference, contents: $0)
                        }
                    }
            }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(file)
    }

    // MARK: Restore (REPLACES everything)

    /// L7 : résumé HONNÊTE d'une sauvegarde AVANT restauration — la
    /// confirmation affiche la date, la version et le contenu réels.
    /// Lève les mêmes refus que `restore` (illisible, version future)
    /// SANS toucher aux données.
    struct Summary: Equatable {
        let exportedAt: Date
        let schemaVersion: Int
        let accounts: Int
        let transactions: Int
        let goals: Int
        let recurrings: Int
        let documents: Int
        /// W10.5 : fichiers de pièces jointes EMBARQUÉS (0 pour une
        /// sauvegarde métadonnées seules ou antérieure).
        let documentFiles: Int
    }

    func summary(of data: Data) throws -> Summary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(BackupFile.self, from: data) else {
            throw BackupError.unreadable
        }
        guard file.schemaVersion <= Self.currentSchemaVersion else {
            throw BackupError.newerSchema(found: file.schemaVersion, supported: Self.currentSchemaVersion)
        }
        try validate(file)
        return Summary(
            exportedAt: file.exportedAt,
            schemaVersion: file.schemaVersion,
            accounts: file.accounts.count,
            transactions: file.transactions.count,
            goals: file.goals.count,
            recurrings: file.recurrings.count,
            documents: file.documents.count,
            documentFiles: file.documentFiles?.count ?? 0
        )
    }

    /// Validates every enum and relationship before restore mutates the
    /// context. Optional relationships remain optional for older backups,
    /// but a UUID that is present must resolve unambiguously.
    private func validate(_ file: BackupFile) throws {
        func requireUnique(_ ids: [UUID], entity: String) throws {
            var seen = Set<UUID>()
            for id in ids {
                guard seen.insert(id).inserted else {
                    throw BackupError.duplicateIdentifier(entity: entity, id: id)
                }
            }
        }

        func requireReference(
            _ id: UUID?,
            in ids: Set<UUID>,
            field: String
        ) throws {
            guard let id else { return }
            guard ids.contains(id) else {
                throw BackupError.missingReference(field: field, id: id)
            }
        }

        try requireUnique(file.households.map(\.id), entity: "ménage")
        try requireUnique(file.members.map(\.id), entity: "membre")
        try requireUnique(file.accounts.map(\.id), entity: "compte")
        try requireUnique(file.categories.map(\.id), entity: "catégorie")
        try requireUnique(file.transactions.map(\.id), entity: "mouvement")
        try requireUnique(file.budgets.map(\.id), entity: "budget")
        try requireUnique(file.budgetLines.map(\.id), entity: "ligne de budget")
        try requireUnique(file.recurrings.map(\.id), entity: "récurrent")
        try requireUnique(file.taxProfiles.map(\.id), entity: "profil fiscal")
        try requireUnique(file.taxProvisions.map(\.id), entity: "provision fiscale")
        try requireUnique(file.goals.map(\.id), entity: "objectif")
        try requireUnique(file.insuranceContracts.map(\.id), entity: "assurance")
        try requireUnique(file.pensionAssets.map(\.id), entity: "prévoyance")
        try requireUnique(file.assets.map(\.id), entity: "actif")
        try requireUnique(file.liabilities.map(\.id), entity: "dette")
        try requireUnique(file.netWorthSnapshots.map(\.id), entity: "instantané de patrimoine")
        try requireUnique(file.documents.map(\.id), entity: "document")
        try requireUnique((file.importBatches ?? []).map(\.id), entity: "lot d'import")
        try requireUnique((file.positions ?? []).map(\.id), entity: "position")

        let householdIDs = Set(file.households.map(\.id))
        let memberIDs = Set(file.members.map(\.id))
        let accountIDs = Set(file.accounts.map(\.id))
        let categoryIDs = Set(file.categories.map(\.id))
        let budgetIDs = Set(file.budgets.map(\.id))
        let profileIDs = Set(file.taxProfiles.map(\.id))
        let batchIDs = Set((file.importBatches ?? []).map(\.id))

        for dto in file.households {
            _ = try decimal(dto.taxRate)
        }
        for dto in file.members {
            _ = try enumValue(HouseholdRole.self, rawValue: dto.role, field: "membre.role")
            try requireReference(dto.householdID, in: householdIDs, field: "membre.ménage")
        }
        for dto in file.accounts {
            _ = try enumValue(AccountType.self, rawValue: dto.type, field: "compte.type")
            _ = try decimal(dto.openingBalance)
            if let value = dto.reconciledBalance { _ = try decimal(value) }
            try requireReference(dto.ownerID, in: memberIDs, field: "compte.propriétaire")
        }
        for dto in file.categories {
            _ = try enumValue(CategoryKind.self, rawValue: dto.kind, field: "catégorie.type")
            try requireReference(dto.parentID, in: categoryIDs, field: "catégorie.parent")
        }
        for dto in file.transactions {
            _ = try enumValue(TransactionType.self, rawValue: dto.type, field: "mouvement.type")
            _ = try enumValue(TransactionStatus.self, rawValue: dto.status, field: "mouvement.statut")
            _ = try decimal(dto.amount)
            try requireReference(dto.accountID, in: accountIDs, field: "mouvement.compte")
            try requireReference(dto.destinationAccountID, in: accountIDs, field: "mouvement.compte destination")
            try requireReference(dto.categoryID, in: categoryIDs, field: "mouvement.catégorie")
            try requireReference(dto.memberID, in: memberIDs, field: "mouvement.membre")
            // Historical movements may legitimately outlive a deleted
            // recurring definition. Import batches were absent from older
            // backup schemas, so only validate them when the array exists.
            if file.importBatches != nil {
                try requireReference(dto.importBatchID, in: batchIDs, field: "mouvement.lot d'import")
            }
        }
        for dto in file.budgetLines {
            _ = try decimal(dto.planned)
            try requireReference(dto.budgetID, in: budgetIDs, field: "ligne de budget.budget")
            try requireReference(dto.categoryID, in: categoryIDs, field: "ligne de budget.catégorie")
        }
        for dto in file.recurrings {
            _ = try enumValue(TransactionType.self, rawValue: dto.type, field: "récurrent.type")
            _ = try enumValue(RecurrenceUnit.self, rawValue: dto.unit, field: "récurrent.fréquence")
            _ = try decimal(dto.amount)
            try requireReference(dto.accountID, in: accountIDs, field: "récurrent.compte")
            try requireReference(dto.destinationAccountID, in: accountIDs, field: "récurrent.compte destination")
            try requireReference(dto.categoryID, in: categoryIDs, field: "récurrent.catégorie")
            try requireReference(dto.memberID, in: memberIDs, field: "récurrent.membre")
        }
        for dto in file.taxProfiles {
            _ = try decimal(dto.rate)
        }
        for dto in file.taxProvisions {
            if let value = dto.override_ { _ = try decimal(value) }
            _ = try decimal(dto.reserved)
            _ = try decimal(dto.arrears)
            try requireReference(dto.profileID, in: profileIDs, field: "provision.profil")
        }
        for dto in file.goals {
            _ = try enumValue(GoalKind.self, rawValue: dto.kind, field: "objectif.type")
            _ = try enumValue(GoalPriority.self, rawValue: dto.priority, field: "objectif.priorité")
            _ = try enumValue(GoalStatus.self, rawValue: dto.status, field: "objectif.statut")
            _ = try decimal(dto.target)
            _ = try decimal(dto.manualCurrent)
            _ = try decimal(dto.plannedMonthly)
            try requireReference(dto.linkedAccountID, in: accountIDs, field: "objectif.compte")
        }
        for dto in file.insuranceContracts {
            _ = try enumValue(InsuranceKind.self, rawValue: dto.kind, field: "assurance.type")
            _ = try enumValue(RecurrenceUnit.self, rawValue: dto.unit, field: "assurance.fréquence")
            _ = try decimal(dto.premium)
            if let value = dto.deductible { _ = try decimal(value) }
            try requireReference(dto.memberID, in: memberIDs, field: "assurance.membre")
        }
        for dto in file.pensionAssets {
            _ = try enumValue(PensionPillar.self, rawValue: dto.pillar, field: "prévoyance.pilier")
            _ = try decimal(dto.currentValue)
            _ = try decimal(dto.annualContribution)
            if let value = dto.projected { _ = try decimal(value) }
            try requireReference(dto.ownerID, in: memberIDs, field: "prévoyance.propriétaire")
        }
        for dto in file.assets {
            _ = try enumValue(AssetKind.self, rawValue: dto.kind, field: "actif.type")
            _ = try decimal(dto.value)
        }
        for dto in file.liabilities {
            _ = try enumValue(LiabilityKind.self, rawValue: dto.kind, field: "dette.type")
            _ = try decimal(dto.outstanding)
        }
        for dto in file.netWorthSnapshots {
            _ = try decimal(dto.accounts)
            _ = try decimal(dto.assets)
            _ = try decimal(dto.pension)
            _ = try decimal(dto.liabilities)
            _ = try decimal(dto.netWorth)
        }
        for dto in file.documents {
            _ = try enumValue(DocumentKind.self, rawValue: dto.kind, field: "document.type")
            try requireReference(dto.memberID, in: memberIDs, field: "document.membre")
        }
    }

    /// W10.5 : remplace toutes les entités ET, quand la sauvegarde les
    /// porte, restaure les FICHIERS des pièces jointes ; après une
    /// restauration réussie, les fichiers que plus rien ne référence
    /// sont balayés. Sans store fourni ou sans fichiers embarqués, les
    /// fichiers présents ne sont jamais touchés (comportement
    /// antérieur).
    func restore(data: Data, context: ModelContext, documentFileStore: DocumentFileStoring?) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(BackupFile.self, from: data) else {
            throw BackupError.unreadable
        }
        guard file.schemaVersion <= Self.currentSchemaVersion else {
            throw BackupError.newerSchema(found: file.schemaVersion, supported: Self.currentSchemaVersion)
        }

        // ADR-017 : V1 est mono-devise. Un compte ou ménage non-CHF
        // fausserait tous les totaux — refus AVANT de toucher au store.
        let foreignCodes = Set(file.accounts.map(\.currency) + file.households.map(\.currency))
            .subtracting(["CHF"]).sorted()
        guard foreignCodes.isEmpty else {
            throw BackupError.unsupportedCurrency(codes: foreignCodes)
        }
        try validate(file)

        // W10.5 : les FICHIERS de la sauvegarde s'écrivent AVANT la
        // transaction d'entités — un échec d'écriture interrompt la
        // restauration alors que le store n'a pas bougé ; les fichiers
        // déjà écrits deviennent au pire des orphelins, balayés plus
        // bas. Une sauvegarde sans fichiers (antérieure ou métadonnées
        // seules) ne touche à rien.
        if let store = documentFileStore, let fichiers = file.documentFiles {
            for dto in fichiers {
                try store.write(dto.contents, fileReference: dto.fileReference)
            }
        }

        // Wipe, rebuild and save form ONE transaction: a failure at ANY
        // step rolls back and leaves the store as it was.
        do {
            try wipeEntities(context: context)
            try rebuild(from: file, context: context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        // W10.5 : balayage des ORPHELINES — seulement quand la
        // sauvegarde PORTAIT des fichiers (une restauration complète
        // remplace tout : ce que plus rien ne référence est supprimé,
        // anciens fichiers d'avant la restauration compris). Une
        // sauvegarde métadonnées seules garde le comportement
        // antérieur : les fichiers présents ne sont jamais touchés.
        // Best effort assumé : un échec de suppression ne casse pas
        // une restauration déjà commise.
        if let store = documentFileStore, file.documentFiles != nil {
            sweepOrphanFiles(context: context, documentFileStore: store)
        }
    }

    /// W10.5 : supprime les fichiers que plus aucun `FinancialDocument`
    /// ne référence. Retourne les références supprimées (preuve).
    @discardableResult
    func sweepOrphanFiles(context: ModelContext, documentFileStore: DocumentFileStoring) -> [String] {
        let referenced = Set((try? context.fetch(FetchDescriptor<FinancialDocument>()))?
            .map(\.fileReference) ?? [])
        let orphans = documentFileStore.allReferences().filter { !referenced.contains($0) }.sorted()
        for reference in orphans {
            try? documentFileStore.delete(reference)
        }
        return orphans
    }

    /// Recreates every entity in dependency order, resolving relationships
    /// by UUID. Must only run inside restore()'s wipe/rebuild/save
    /// transaction — it never saves and never rolls back itself.
    private func rebuild(from file: BackupFile, context: ModelContext) throws {
        var members: [UUID: HouseholdMember] = [:]
        for dto in file.members {
            let member = HouseholdMember(
                id: dto.id, firstName: dto.firstName,
                role: try enumValue(HouseholdRole.self, rawValue: dto.role, field: "membre.role"),
                birthDate: dto.birthDate, employmentStatus: dto.employmentStatus,
                includeInBudget: dto.includeInBudget
            )
            members[dto.id] = member
            context.insert(member)
        }
        for dto in file.households {
            let household = Household(
                id: dto.id, name: dto.name, baseCurrencyCode: dto.currency,
                canton: dto.canton, municipality: dto.municipality,
                taxProvisionRate: try decimal(dto.taxRate), createdAt: dto.createdAt,
                updatedAt: dto.updatedAt ?? dto.createdAt
            )
            household.members = file.members
                .filter { $0.householdID == dto.id }
                .compactMap { members[$0.id] }
            context.insert(household)
        }

        var categories: [UUID: BudgetCategory] = [:]
        for dto in file.categories {
            let category = BudgetCategory(
                id: dto.id, name: dto.name,
                kind: try enumValue(CategoryKind.self, rawValue: dto.kind, field: "catégorie.type"),
                iconToken: dto.iconToken, emoji: dto.emoji,
                isEssential: dto.isEssential, isActive: dto.isActive, sortOrder: dto.sortOrder
            )
            categories[dto.id] = category
            context.insert(category)
        }
        for dto in file.categories where dto.parentID != nil {
            categories[dto.id]?.parent = try resolved(dto.parentID, in: categories, field: "catégorie.parent")
        }

        var accounts: [UUID: Account] = [:]
        for dto in file.accounts {
            let account = Account(
                id: dto.id, name: dto.name, institutionName: dto.institution,
                type: try enumValue(AccountType.self, rawValue: dto.type, field: "compte.type"),
                currencyCode: dto.currency,
                openingBalance: try decimal(dto.openingBalance),
                isShared: dto.isShared, isActive: dto.isActive,
                includeInAvailableCash: dto.includeInAvailableCash,
                includeInNetWorth: dto.includeInNetWorth,
                createdAt: dto.createdAt, updatedAt: dto.updatedAt ?? dto.createdAt,
                owner: try resolved(dto.ownerID, in: members, field: "compte.propriétaire")
            )
            account.reconciledBalance = try dto.reconciledBalance.map(decimal)
            account.reconciledAt = dto.reconciledAt
            accounts[dto.id] = account
            context.insert(account)
        }

        for dto in file.transactions {
            context.insert(BudgetTransaction(
                id: dto.id, date: dto.date, amount: try decimal(dto.amount),
                type: try enumValue(TransactionType.self, rawValue: dto.type, field: "mouvement.type"),
                status: try enumValue(TransactionStatus.self, rawValue: dto.status, field: "mouvement.statut"),
                title: dto.title, note: dto.note, merchant: dto.merchant,
                adjustmentIncreasesBalance: dto.adjustmentIncreasesBalance,
                importFingerprint: dto.importFingerprint, recurringID: dto.recurringID,
                importBatchID: dto.importBatchID,
                createdAt: dto.createdAt, updatedAt: dto.updatedAt ?? dto.createdAt,
                account: try resolved(dto.accountID, in: accounts, field: "mouvement.compte"),
                destinationAccount: try resolved(dto.destinationAccountID, in: accounts, field: "mouvement.compte destination"),
                category: try resolved(dto.categoryID, in: categories, field: "mouvement.catégorie"),
                member: try resolved(dto.memberID, in: members, field: "mouvement.membre")
            ))
        }

        var budgets: [UUID: MonthlyBudget] = [:]
        for dto in file.budgets {
            let budget = MonthlyBudget(id: dto.id, year: dto.year, month: dto.month)
            budgets[dto.id] = budget
            context.insert(budget)
        }
        for dto in file.budgetLines {
            let line = BudgetLine(
                id: dto.id, plannedAmount: try decimal(dto.planned),
                category: try resolved(dto.categoryID, in: categories, field: "ligne de budget.catégorie")
            )
            line.budget = try resolved(dto.budgetID, in: budgets, field: "ligne de budget.budget")
            context.insert(line)
        }

        for dto in file.recurrings {
            context.insert(RecurringTransaction(
                id: dto.id, title: dto.title, amount: try decimal(dto.amount),
                type: try enumValue(TransactionType.self, rawValue: dto.type, field: "récurrent.type"),
                intervalUnit: try enumValue(RecurrenceUnit.self, rawValue: dto.unit, field: "récurrent.fréquence"),
                intervalCount: dto.count, firstOccurrence: dto.firstOccurrence,
                endDate: dto.endDate, isActive: dto.isActive,
                isProfessional: dto.isProfessional, isSubscription: dto.isSubscription,
                renewalDate: dto.renewalDate, cancellationDeadline: dto.cancellationDeadline,
                note: dto.note,
                // ID1 : clé hostile ou hors alphabet RETIRÉE (init la
                // sanitise) — la ligne, elle, n'est jamais perdue.
                identityKey: dto.identityKey,
                account: try resolved(dto.accountID, in: accounts, field: "récurrent.compte"),
                destinationAccount: try resolved(dto.destinationAccountID, in: accounts, field: "récurrent.compte destination"),
                category: try resolved(dto.categoryID, in: categories, field: "récurrent.catégorie"),
                member: try resolved(dto.memberID, in: members, field: "récurrent.membre")
            ))
        }

        var profiles: [UUID: TaxProfile] = [:]
        for dto in file.taxProfiles {
            let profile = TaxProfile(
                id: dto.id, canton: dto.canton, municipality: dto.municipality,
                provisionRate: try decimal(dto.rate), notes: dto.notes
            )
            profiles[dto.id] = profile
            context.insert(profile)
        }
        for dto in file.taxProvisions {
            let provision = TaxProvision(
                id: dto.id, year: dto.year,
                estimatedAnnualTaxOverride: try dto.override_.map(decimal),
                reservedAmount: try decimal(dto.reserved), arrearsAmount: try decimal(dto.arrears),
                dueDates: dto.dueDates, notes: dto.notes
            )
            provision.profile = try resolved(dto.profileID, in: profiles, field: "provision.profil")
            context.insert(provision)
        }

        for dto in file.goals {
            context.insert(FinancialGoal(
                id: dto.id, name: dto.name,
                kind: try enumValue(GoalKind.self, rawValue: dto.kind, field: "objectif.type"),
                emoji: dto.emoji, targetAmount: try decimal(dto.target), targetDate: dto.targetDate,
                manualCurrentAmount: try decimal(dto.manualCurrent),
                plannedMonthlyContribution: try decimal(dto.plannedMonthly),
                priority: try enumValue(GoalPriority.self, rawValue: dto.priority, field: "objectif.priorité"),
                status: try enumValue(GoalStatus.self, rawValue: dto.status, field: "objectif.statut"),
                note: dto.note,
                linkedAccount: try resolved(dto.linkedAccountID, in: accounts, field: "objectif.compte")
            ))
        }

        for dto in file.insuranceContracts {
            context.insert(InsuranceContract(
                id: dto.id, insurerName: dto.insurer, policyName: dto.policyName,
                policyNumber: dto.policyNumber,
                kind: try enumValue(InsuranceKind.self, rawValue: dto.kind, field: "assurance.type"),
                premiumAmount: try decimal(dto.premium),
                premiumUnit: try enumValue(RecurrenceUnit.self, rawValue: dto.unit, field: "assurance.fréquence"),
                premiumIntervalCount: dto.count, deductible: try dto.deductible.map(decimal),
                startDate: dto.startDate, renewalDate: dto.renewalDate,
                cancellationDeadline: dto.cancellationDeadline, noticePeriodDays: dto.noticePeriodDays,
                coverageSummary: dto.coverageSummary, documentReference: dto.documentReference,
                isActive: dto.isActive, note: dto.note,
                member: try resolved(dto.memberID, in: members, field: "assurance.membre")
            ))
        }

        for dto in file.pensionAssets {
            context.insert(PensionAsset(
                id: dto.id,
                pillar: try enumValue(PensionPillar.self, rawValue: dto.pillar, field: "prévoyance.pilier"),
                institutionName: dto.institution, currentValue: try decimal(dto.currentValue),
                annualContribution: try decimal(dto.annualContribution),
                projectedValueAtRetirement: try dto.projected.map(decimal),
                retirementAge: dto.retirementAge, sourceDocumentDate: dto.sourceDate,
                sourceReference: dto.sourceReference, isActive: dto.isActive, note: dto.note,
                owner: try resolved(dto.ownerID, in: members, field: "prévoyance.propriétaire")
            ))
        }

        for dto in file.assets {
            context.insert(Asset(
                id: dto.id, name: dto.name,
                kind: try enumValue(AssetKind.self, rawValue: dto.kind, field: "actif.type"),
                currentValue: try decimal(dto.value), includeInNetWorth: dto.include,
                valuationDate: dto.valuationDate, note: dto.note
            ))
        }
        for dto in file.liabilities {
            context.insert(Liability(
                id: dto.id, name: dto.name,
                kind: try enumValue(LiabilityKind.self, rawValue: dto.kind, field: "dette.type"),
                outstandingAmount: try decimal(dto.outstanding), includeInNetWorth: dto.include,
                note: dto.note
            ))
        }
        for dto in file.netWorthSnapshots {
            context.insert(NetWorthSnapshot(
                id: dto.id, date: dto.date, accountsTotal: try decimal(dto.accounts),
                assetsTotal: try decimal(dto.assets), pensionTotal: try decimal(dto.pension),
                liabilitiesTotal: try decimal(dto.liabilities), netWorth: try decimal(dto.netWorth)
            ))
        }
        for dto in file.documents {
            // Metadata only: files do not travel in the JSON backup — the
            // reference is kept so a still-present file stays reachable.
            context.insert(FinancialDocument(
                id: dto.id, title: dto.title,
                kind: try enumValue(DocumentKind.self, rawValue: dto.kind, field: "document.type"),
                year: dto.year, provider: dto.provider, note: dto.note,
                fileReference: dto.fileReference, fileSizeBytes: dto.fileSizeBytes,
                addedAt: dto.addedAt ?? file.exportedAt,
                updatedAt: dto.updatedAt ?? file.exportedAt,
                member: try resolved(dto.memberID, in: members, field: "document.membre")
            ))
        }
        for dto in file.importBatches ?? [] {
            context.insert(ImportBatch(
                id: dto.id, fileName: dto.fileName, importedAt: dto.importedAt,
                totalRows: dto.totalRows, importedCount: dto.importedCount,
                duplicateCount: dto.duplicateCount, invalidCount: dto.invalidCount,
                createdCategories: dto.createdCategories
            ))
        }
        // INV1 (ADR-047) : les positions EXPLIQUENT un solde — restaurer
        // n'en recalcule aucun. Un fichier d'avant les positions n'a pas
        // ce champ et se restaure à l'identique.
        for dto in file.positions ?? [] {
            context.insert(BrokeragePosition(
                id: dto.id, instrumentName: dto.instrumentName,
                tickerOrISIN: dto.tickerOrISIN,
                quantity: try decimal(dto.quantity),
                manualPrice: try decimal(dto.manualPrice),
                priceCurrency: dto.priceCurrency,
                valuationDate: dto.valuationDate,
                costBasis: try dto.costBasis.map { try decimal($0) },
                account: try resolved(dto.accountID, in: accounts, field: "position.compte")
            ))
        }
    }

    // MARK: Complete deletion

    /// Removes every entity and every stored document file. Destructive —
    /// the UI must have confirmed twice before calling this.
    func deleteAll(context: ModelContext, documentFileStore: DocumentFileStoring?) throws {
        // Collect the file references first, but only remove the files
        // once the entity wipe is committed: if the save fails, the
        // records survive with their files still present.
        let fileReferences = try context.fetch(FetchDescriptor<FinancialDocument>())
            .map(\.fileReference)
            .filter { !$0.isEmpty }
        do {
            try wipeEntities(context: context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        if let store = documentFileStore {
            for reference in fileReferences {
                try? store.delete(reference)
            }
            // W10.7 : les orphelines partent aussi — « tout supprimer »
            // ne laisse AUCUN fichier dans le dossier protégé.
            sweepOrphanFiles(context: context, documentFileStore: store)
        }
        // PFOS-P7 : le miroir du widget part aussi — aucune donnée
        // financière ne survit dans le conteneur du groupe d'apps.
        WidgetSnapshotStore.clear()
    }

    /// Deletes every entity one by one WITHOUT saving — callers commit or
    /// roll back. Individual deletes, not context.delete(model:): the
    /// batch API rejects the .deny rules on Account.transactions and
    /// Account.incomingMovements. Transactions go first so those .deny
    /// rules never block.
    private func wipeEntities(context: ModelContext) throws {
        func wipe<T: PersistentModel>(_ type: T.Type) throws {
            for item in try context.fetch(FetchDescriptor<T>()) {
                context.delete(item)
            }
        }
        try wipe(BrokeragePosition.self)
        try wipe(BudgetTransaction.self)
        try wipe(BudgetLine.self)
        try wipe(MonthlyBudget.self)
        try wipe(RecurringTransaction.self)
        try wipe(TaxProvision.self)
        try wipe(TaxProfile.self)
        try wipe(FinancialGoal.self)
        try wipe(InsuranceContract.self)
        try wipe(PensionAsset.self)
        try wipe(Asset.self)
        try wipe(Liability.self)
        try wipe(NetWorthSnapshot.self)
        try wipe(FinancialDocument.self)
        try wipe(ImportBatch.self)
        try wipe(Account.self)
        try wipe(BudgetCategory.self)
        try wipe(HouseholdMember.self)
        try wipe(Household.self)
    }
}
