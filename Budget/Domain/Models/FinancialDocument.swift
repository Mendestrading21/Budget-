import Foundation
import SwiftData

enum DocumentKind: String, CaseIterable, Codable, Identifiable {
    case taxStatement
    case insurancePolicy
    case pensionCertificate
    case salarySlip
    case invoice
    case receipt
    case contract
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .taxStatement: "Décompte fiscal"
        case .insurancePolicy: "Police d'assurance"
        case .pensionCertificate: "Certificat de prévoyance"
        case .salarySlip: "Fiche de salaire"
        case .invoice: "Facture"
        case .receipt: "Quittance"
        case .contract: "Contrat"
        case .other: "Autre"
        }
    }

    var systemImage: String {
        switch self {
        case .taxStatement: "doc.text"
        case .insurancePolicy: "shield"
        case .pensionCertificate: "shield.checkered"
        case .salarySlip: "banknote"
        case .invoice: "doc.plaintext"
        case .receipt: "receipt"
        case .contract: "signature"
        case .other: "folder"
        }
    }
}

/// Metadata of one locally stored document. The file itself lives in the
/// app's protected container (never as a blob in the store); only the
/// relative `fileReference` is persisted.
@Model
final class FinancialDocument {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRawValue: String
    var year: Int?
    var provider: String?
    var note: String?
    /// Relative file name inside the document store; empty when the entry
    /// is metadata-only.
    var fileReference: String
    var fileSizeBytes: Int?
    var addedAt: Date
    var updatedAt: Date

    var member: HouseholdMember?

    var kind: DocumentKind {
        get { DocumentKind(rawValue: kindRawValue) ?? .other }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        kind: DocumentKind,
        year: Int? = nil,
        provider: String? = nil,
        note: String? = nil,
        fileReference: String = "",
        fileSizeBytes: Int? = nil,
        addedAt: Date = Date(),
        updatedAt: Date = Date(),
        member: HouseholdMember? = nil
    ) {
        self.id = id
        self.title = title
        self.kindRawValue = kind.rawValue
        self.year = year
        self.provider = provider
        self.note = note
        self.fileReference = fileReference
        self.fileSizeBytes = fileSizeBytes
        self.addedAt = addedAt
        self.updatedAt = updatedAt
        self.member = member
    }
}

/// One CSV import batch: counters for the report and the rollback handle.
@Model
final class ImportBatch {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var importedAt: Date
    var totalRows: Int
    var importedCount: Int
    var duplicateCount: Int
    var invalidCount: Int
    var createdCategories: Int

    init(
        id: UUID = UUID(),
        fileName: String,
        importedAt: Date,
        totalRows: Int,
        importedCount: Int,
        duplicateCount: Int,
        invalidCount: Int,
        createdCategories: Int
    ) {
        self.id = id
        self.fileName = fileName
        self.importedAt = importedAt
        self.totalRows = totalRows
        self.importedCount = importedCount
        self.duplicateCount = duplicateCount
        self.invalidCount = invalidCount
        self.createdCategories = createdCategories
    }
}
