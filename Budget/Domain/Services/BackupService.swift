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

    struct HouseholdDTO: Codable {
        var id: UUID; var name: String; var currency: String; var canton: String
        var municipality: String; var taxRate: String; var createdAt: Date
    }
    struct MemberDTO: Codable {
        var id: UUID; var householdID: UUID?; var firstName: String; var role: String
        var birthDate: Date?; var includeInBudget: Bool
    }
    struct AccountDTO: Codable {
        var id: UUID; var name: String; var institution: String; var type: String
        var currency: String; var openingBalance: String; var reconciledBalance: String?
        var reconciledAt: Date?; var isShared: Bool; var isActive: Bool
        var includeInAvailableCash: Bool; var includeInNetWorth: Bool
        var ownerID: UUID?; var createdAt: Date
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
    }
}

enum BackupError: LocalizedError, Equatable {
    case unreadable
    case newerSchema(found: Int, supported: Int)

    var errorDescription: String? {
        switch self {
        case .unreadable:
            "Cette sauvegarde est illisible ou endommagée."
        case .newerSchema(let found, let supported):
            "Cette sauvegarde vient d'une version plus récente de Budget (schéma \(found), pris en charge : \(supported)). Mettez d'abord l'app à jour."
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
    private func decimal(_ string: String) -> Decimal {
        Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) ?? .zero
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

    func makeBackup(context: ModelContext, now: Date) throws -> Data {
        func fetch<T: PersistentModel>(_ type: T.Type) throws -> [T] {
            try context.fetch(FetchDescriptor<T>())
        }
        let file = BackupFile(
            schemaVersion: Self.currentSchemaVersion,
            exportedAt: now,
            households: try fetch(Household.self).map {
                .init(id: $0.id, name: $0.name, currency: $0.baseCurrencyCode, canton: $0.canton,
                      municipality: $0.municipality, taxRate: decimalString($0.taxProvisionRate), createdAt: $0.createdAt)
            },
            members: try fetch(HouseholdMember.self).map {
                .init(id: $0.id, householdID: $0.household?.id, firstName: $0.firstName,
                      role: $0.roleRawValue, birthDate: $0.birthDate, includeInBudget: $0.includeInBudget)
            },
            accounts: try fetch(Account.self).map {
                .init(id: $0.id, name: $0.name, institution: $0.institutionName, type: $0.typeRawValue,
                      currency: $0.currencyCode, openingBalance: decimalString($0.openingBalance),
                      reconciledBalance: $0.reconciledBalance.map(decimalString), reconciledAt: $0.reconciledAt,
                      isShared: $0.isShared, isActive: $0.isActive,
                      includeInAvailableCash: $0.includeInAvailableCash, includeInNetWorth: $0.includeInNetWorth,
                      ownerID: $0.owner?.id, createdAt: $0.createdAt)
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
                      memberID: $0.member?.id, createdAt: $0.createdAt)
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
                      categoryID: $0.category?.id, memberID: $0.member?.id)
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
                      fileSizeBytes: $0.fileSizeBytes, memberID: $0.member?.id)
            }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(file)
    }

    // MARK: Restore (REPLACES everything)

    func restore(data: Data, context: ModelContext, documentFileStore: DocumentFileStoring?) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(BackupFile.self, from: data) else {
            throw BackupError.unreadable
        }
        guard file.schemaVersion <= Self.currentSchemaVersion else {
            throw BackupError.newerSchema(found: file.schemaVersion, supported: Self.currentSchemaVersion)
        }

        try deleteAll(context: context, documentFileStore: documentFileStore)

        // Recreate in dependency order, resolving relationships by UUID.
        var members: [UUID: HouseholdMember] = [:]
        for dto in file.members {
            let member = HouseholdMember(
                id: dto.id, firstName: dto.firstName,
                role: HouseholdRole(rawValue: dto.role) ?? .owner,
                birthDate: dto.birthDate, includeInBudget: dto.includeInBudget
            )
            members[dto.id] = member
            context.insert(member)
        }
        for dto in file.households {
            let household = Household(
                id: dto.id, name: dto.name, baseCurrencyCode: dto.currency,
                canton: dto.canton, municipality: dto.municipality,
                taxProvisionRate: decimal(dto.taxRate), createdAt: dto.createdAt, updatedAt: dto.createdAt
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
                kind: CategoryKind(rawValue: dto.kind) ?? .expense,
                iconToken: dto.iconToken, emoji: dto.emoji,
                isEssential: dto.isEssential, isActive: dto.isActive, sortOrder: dto.sortOrder
            )
            categories[dto.id] = category
            context.insert(category)
        }
        for dto in file.categories where dto.parentID != nil {
            categories[dto.id]?.parent = dto.parentID.flatMap { categories[$0] }
        }

        var accounts: [UUID: Account] = [:]
        for dto in file.accounts {
            let account = Account(
                id: dto.id, name: dto.name, institutionName: dto.institution,
                type: AccountType(rawValue: dto.type) ?? .other, currencyCode: dto.currency,
                openingBalance: decimal(dto.openingBalance),
                isShared: dto.isShared, isActive: dto.isActive,
                includeInAvailableCash: dto.includeInAvailableCash,
                includeInNetWorth: dto.includeInNetWorth,
                createdAt: dto.createdAt, updatedAt: dto.createdAt,
                owner: dto.ownerID.flatMap { members[$0] }
            )
            account.reconciledBalance = dto.reconciledBalance.map(decimal)
            account.reconciledAt = dto.reconciledAt
            accounts[dto.id] = account
            context.insert(account)
        }

        for dto in file.transactions {
            context.insert(BudgetTransaction(
                id: dto.id, date: dto.date, amount: decimal(dto.amount),
                type: TransactionType(rawValue: dto.type) ?? .expense,
                status: TransactionStatus(rawValue: dto.status) ?? .posted,
                title: dto.title, note: dto.note, merchant: dto.merchant,
                adjustmentIncreasesBalance: dto.adjustmentIncreasesBalance,
                importFingerprint: dto.importFingerprint, recurringID: dto.recurringID,
                importBatchID: dto.importBatchID,
                createdAt: dto.createdAt, updatedAt: dto.createdAt,
                account: dto.accountID.flatMap { accounts[$0] },
                destinationAccount: dto.destinationAccountID.flatMap { accounts[$0] },
                category: dto.categoryID.flatMap { categories[$0] },
                member: dto.memberID.flatMap { members[$0] }
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
                id: dto.id, plannedAmount: decimal(dto.planned),
                category: dto.categoryID.flatMap { categories[$0] }
            )
            line.budget = dto.budgetID.flatMap { budgets[$0] }
            context.insert(line)
        }

        for dto in file.recurrings {
            context.insert(RecurringTransaction(
                id: dto.id, title: dto.title, amount: decimal(dto.amount),
                type: TransactionType(rawValue: dto.type) ?? .expense,
                intervalUnit: RecurrenceUnit(rawValue: dto.unit) ?? .month,
                intervalCount: dto.count, firstOccurrence: dto.firstOccurrence,
                endDate: dto.endDate, isActive: dto.isActive,
                isProfessional: dto.isProfessional, isSubscription: dto.isSubscription,
                renewalDate: dto.renewalDate, cancellationDeadline: dto.cancellationDeadline,
                note: dto.note,
                account: dto.accountID.flatMap { accounts[$0] },
                destinationAccount: dto.destinationAccountID.flatMap { accounts[$0] },
                category: dto.categoryID.flatMap { categories[$0] },
                member: dto.memberID.flatMap { members[$0] }
            ))
        }

        var profiles: [UUID: TaxProfile] = [:]
        for dto in file.taxProfiles {
            let profile = TaxProfile(
                id: dto.id, canton: dto.canton, municipality: dto.municipality,
                provisionRate: decimal(dto.rate), notes: dto.notes
            )
            profiles[dto.id] = profile
            context.insert(profile)
        }
        for dto in file.taxProvisions {
            let provision = TaxProvision(
                id: dto.id, year: dto.year,
                estimatedAnnualTaxOverride: dto.override_.map(decimal),
                reservedAmount: decimal(dto.reserved), arrearsAmount: decimal(dto.arrears),
                dueDates: dto.dueDates, notes: dto.notes
            )
            provision.profile = dto.profileID.flatMap { profiles[$0] }
            context.insert(provision)
        }

        for dto in file.goals {
            context.insert(FinancialGoal(
                id: dto.id, name: dto.name, kind: GoalKind(rawValue: dto.kind) ?? .custom,
                emoji: dto.emoji, targetAmount: decimal(dto.target), targetDate: dto.targetDate,
                manualCurrentAmount: decimal(dto.manualCurrent),
                plannedMonthlyContribution: decimal(dto.plannedMonthly),
                priority: GoalPriority(rawValue: dto.priority) ?? .normal,
                status: GoalStatus(rawValue: dto.status) ?? .active,
                note: dto.note,
                linkedAccount: dto.linkedAccountID.flatMap { accounts[$0] }
            ))
        }

        for dto in file.insuranceContracts {
            context.insert(InsuranceContract(
                id: dto.id, insurerName: dto.insurer, policyName: dto.policyName,
                policyNumber: dto.policyNumber, kind: InsuranceKind(rawValue: dto.kind) ?? .other,
                premiumAmount: decimal(dto.premium),
                premiumUnit: RecurrenceUnit(rawValue: dto.unit) ?? .month,
                premiumIntervalCount: dto.count, deductible: dto.deductible.map(decimal),
                startDate: dto.startDate, renewalDate: dto.renewalDate,
                cancellationDeadline: dto.cancellationDeadline, noticePeriodDays: dto.noticePeriodDays,
                coverageSummary: dto.coverageSummary, documentReference: dto.documentReference,
                isActive: dto.isActive, note: dto.note,
                member: dto.memberID.flatMap { members[$0] }
            ))
        }

        for dto in file.pensionAssets {
            context.insert(PensionAsset(
                id: dto.id, pillar: PensionPillar(rawValue: dto.pillar) ?? .pillar3a,
                institutionName: dto.institution, currentValue: decimal(dto.currentValue),
                annualContribution: decimal(dto.annualContribution),
                projectedValueAtRetirement: dto.projected.map(decimal),
                retirementAge: dto.retirementAge, sourceDocumentDate: dto.sourceDate,
                sourceReference: dto.sourceReference, isActive: dto.isActive, note: dto.note,
                owner: dto.ownerID.flatMap { members[$0] }
            ))
        }

        for dto in file.assets {
            context.insert(Asset(
                id: dto.id, name: dto.name, kind: AssetKind(rawValue: dto.kind) ?? .other,
                currentValue: decimal(dto.value), includeInNetWorth: dto.include,
                valuationDate: dto.valuationDate, note: dto.note
            ))
        }
        for dto in file.liabilities {
            context.insert(Liability(
                id: dto.id, name: dto.name, kind: LiabilityKind(rawValue: dto.kind) ?? .other,
                outstandingAmount: decimal(dto.outstanding), includeInNetWorth: dto.include,
                note: dto.note
            ))
        }
        for dto in file.netWorthSnapshots {
            context.insert(NetWorthSnapshot(
                id: dto.id, date: dto.date, accountsTotal: decimal(dto.accounts),
                assetsTotal: decimal(dto.assets), pensionTotal: decimal(dto.pension),
                liabilitiesTotal: decimal(dto.liabilities), netWorth: decimal(dto.netWorth)
            ))
        }
        for dto in file.documents {
            // Metadata only: files do not travel in the JSON backup — the
            // reference is kept so a still-present file stays reachable.
            context.insert(FinancialDocument(
                id: dto.id, title: dto.title, kind: DocumentKind(rawValue: dto.kind) ?? .other,
                year: dto.year, provider: dto.provider, note: dto.note,
                fileReference: dto.fileReference, fileSizeBytes: dto.fileSizeBytes,
                member: dto.memberID.flatMap { members[$0] }
            ))
        }

        try context.save()
    }

    // MARK: Complete deletion

    /// Removes every entity and every stored document file. Destructive —
    /// the UI must have confirmed twice before calling this.
    func deleteAll(context: ModelContext, documentFileStore: DocumentFileStoring?) throws {
        if let store = documentFileStore {
            let documents = try context.fetch(FetchDescriptor<FinancialDocument>())
            for document in documents where !document.fileReference.isEmpty {
                try? store.delete(document.fileReference)
            }
        }
        // Transactions first so .deny account relationships never block.
        try context.delete(model: BudgetTransaction.self)
        try context.delete(model: BudgetLine.self)
        try context.delete(model: MonthlyBudget.self)
        try context.delete(model: RecurringTransaction.self)
        try context.delete(model: TaxProvision.self)
        try context.delete(model: TaxProfile.self)
        try context.delete(model: FinancialGoal.self)
        try context.delete(model: InsuranceContract.self)
        try context.delete(model: PensionAsset.self)
        try context.delete(model: Asset.self)
        try context.delete(model: Liability.self)
        try context.delete(model: NetWorthSnapshot.self)
        try context.delete(model: FinancialDocument.self)
        try context.delete(model: ImportBatch.self)
        try context.delete(model: Account.self)
        try context.delete(model: BudgetCategory.self)
        try context.delete(model: HouseholdMember.self)
        try context.delete(model: Household.self)
        try context.save()
    }
}
