import Foundation
import CryptoKit
import SwiftData

// MARK: - Parsed structures

/// A parsed CSV file: detected delimiter, headers, and raw rows preserved
/// verbatim for the repair queue.
struct ParsedCSV: Equatable {
    let delimiter: Character
    let headers: [String]
    /// Field values per row, same order as headers.
    let rows: [[String]]
    /// Original line text per row, kept until the report is dismissed.
    let rawLines: [String]
}

/// Which CSV column feeds which transaction field.
struct ColumnMapping: Equatable {
    var dateIndex: Int?
    var amountIndex: Int?
    var titleIndex: Int?
    var categoryIndex: Int?
    var typeIndex: Int?
    var noteIndex: Int?

    var isUsable: Bool {
        dateIndex != nil && amountIndex != nil && titleIndex != nil
    }
}

/// State of one row after validation — every rejected row stays visible.
enum ImportRowState: Equatable {
    case ready
    case duplicate
    case invalid(reason: String)

    var isImportable: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// One normalized row with its verdict and preserved source text.
struct ImportRowResult: Identifiable, Equatable {
    let id: Int          // row index — stable across rebuilds
    let rawLine: String
    let state: ImportRowState
    let date: Date?
    let amount: Decimal?
    let type: TransactionType?
    let title: String?
    let categoryName: String?
    let fingerprint: String?
}

/// Final report: counters always reconcile
/// (total == imported + duplicates + invalid).
struct ImportReport: Equatable {
    let batchID: UUID
    let fileName: String
    let totalRows: Int
    let importedCount: Int
    let duplicateCount: Int
    let invalidCount: Int
    let createdCategoryNames: [String]
    /// The repair queue: every non-imported row with its raw text.
    let rejectedRows: [ImportRowResult]
}

// MARK: - Service

/// Notion/Swiss CSV import: parsing, normalization, fingerprint-based
/// idempotence, explicit category creation, batch apply and rollback.
/// Preview and validation are pure; only `apply` writes to the store.
struct CSVImportService {
    let calendar: Calendar

    // MARK: Parsing

    /// Splits the text into rows, detecting the delimiter (; , or tab) by
    /// highest consistent column count on the first lines.
    func parse(text: String) -> ParsedCSV? {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
        guard let headerLine = lines.first else { return nil }

        let candidates: [Character] = [";", ",", "\t"]
        let delimiter = candidates.max { lhs, rhs in
            fields(of: headerLine, delimiter: lhs).count < fields(of: headerLine, delimiter: rhs).count
        } ?? ","
        let headers = fields(of: headerLine, delimiter: delimiter)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard headers.count >= 2 else { return nil }

        let dataLines = Array(lines.dropFirst())
        let rows = dataLines.map { line in
            var values = fields(of: line, delimiter: delimiter)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            // Pad short rows so indexing stays safe.
            while values.count < headers.count { values.append("") }
            return values
        }
        return ParsedCSV(delimiter: delimiter, headers: headers, rows: rows, rawLines: dataLines)
    }

    /// Field splitting honoring double quotes ("a;b" stays one field).
    private func fields(of line: String, delimiter: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for character in line {
            if character == "\"" {
                inQuotes.toggle()
            } else if character == delimiter && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        result.append(current)
        return result
    }

    /// Proposes a mapping from header names (Notion exports and common
    /// French/English labels); every guess remains user-correctable.
    func suggestMapping(headers: [String]) -> ColumnMapping {
        func index(matching needles: [String]) -> Int? {
            headers.firstIndex { header in
                let lowered = header.lowercased()
                return needles.contains { lowered.contains($0) }
            }
        }
        return ColumnMapping(
            dateIndex: index(matching: ["date", "jour"]),
            amountIndex: index(matching: ["montant", "amount", "chf", "prix", "somme"]),
            titleIndex: index(matching: ["nom", "name", "titre", "title", "description", "libellé", "libelle"]),
            categoryIndex: index(matching: ["catégorie", "categorie", "category", "tags"]),
            typeIndex: index(matching: ["type", "sens"]),
            noteIndex: index(matching: ["note", "commentaire", "remarque"])
        )
    }

    // MARK: Normalization

    /// `31.12.2026`, `31/12/2026` and ISO `2026-12-31`.
    func parseDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let patterns: [(regex: String, order: (Int, Int, Int))] = [
            ("^([0-9]{1,2})\\.([0-9]{1,2})\\.([0-9]{4})$", (3, 2, 1)),
            ("^([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})$", (3, 2, 1)),
            ("^([0-9]{4})-([0-9]{2})-([0-9]{2})", (1, 2, 3)),
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern.regex),
                  let match = regex.firstMatch(
                    in: trimmed,
                    range: NSRange(trimmed.startIndex..., in: trimmed)
                  ) else { continue }
            func group(_ index: Int) -> Int? {
                guard let range = Range(match.range(at: index), in: trimmed) else { return nil }
                return Int(trimmed[range])
            }
            guard let year = group(pattern.order.0),
                  let month = group(pattern.order.1),
                  let day = group(pattern.order.2),
                  (1...12).contains(month), (1...31).contains(day) else { continue }
            return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
        }
        return nil
    }

    /// Explicit type column values; a signed amount decides otherwise.
    func parseType(_ text: String?, amountIsNegative: Bool) -> TransactionType {
        if let text = text?.lowercased().trimmingCharacters(in: .whitespaces), !text.isEmpty {
            if text.contains("revenu") || text.contains("income") || text.contains("salaire") { return .income }
            if text.contains("épargne") || text.contains("epargne") || text.contains("saving") { return .saving }
            if text.contains("invest") { return .investment }
            if text.contains("impôt") || text.contains("impot") || text.contains("tax") { return .taxPayment }
            if text.contains("rembours") || text.contains("refund") { return .refund }
            if text.contains("dépense") || text.contains("depense") || text.contains("expense") { return .expense }
        }
        return amountIsNegative ? .expense : .income
    }

    // MARK: Fingerprint (idempotence)

    /// Stable identity of one source row: same file+row+content always
    /// yields the same fingerprint, so re-imports can never duplicate.
    func fingerprint(
        fileName: String,
        rowIndex: Int,
        date: Date,
        amount: Decimal,
        type: TransactionType,
        title: String
    ) -> String {
        let dateKey = ISO8601DateFormatter().string(from: calendar.startOfDay(for: date))
        let identity = [
            fileName.lowercased().trimmingCharacters(in: .whitespaces),
            String(rowIndex),
            dateKey,
            "\(amount)",
            type.rawValue,
            title.lowercased().trimmingCharacters(in: .whitespaces),
        ].joined(separator: "|")
        let digest = SHA256.hash(data: Data(identity.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Validation (pure — no store writes)

    /// Validates every row and marks duplicates against `existingFingerprints`.
    func validate(
        parsed: ParsedCSV,
        mapping: ColumnMapping,
        fileName: String,
        existingFingerprints: Set<String>
    ) -> [ImportRowResult] {
        guard let dateIndex = mapping.dateIndex,
              let amountIndex = mapping.amountIndex,
              let titleIndex = mapping.titleIndex else {
            return []
        }

        var seenInFile = Set<String>()
        return parsed.rows.enumerated().map { rowIndex, values in
            let rawLine = parsed.rawLines.indices.contains(rowIndex) ? parsed.rawLines[rowIndex] : ""

            func result(_ state: ImportRowState, date: Date? = nil, amount: Decimal? = nil,
                        type: TransactionType? = nil, title: String? = nil,
                        category: String? = nil, fingerprint: String? = nil) -> ImportRowResult {
                ImportRowResult(
                    id: rowIndex, rawLine: rawLine, state: state,
                    date: date, amount: amount, type: type, title: title,
                    categoryName: category, fingerprint: fingerprint
                )
            }

            guard let date = parseDate(values[dateIndex]) else {
                return result(.invalid(reason: "Date illisible : « \(values[dateIndex]) »"))
            }
            let amountText = values[amountIndex]
            let isNegative = amountText.contains("-")
            guard let parsedAmount = FinanceFormatting.parseAmount(amountText.replacingOccurrences(of: "-", with: "")),
                  parsedAmount > 0 else {
                return result(.invalid(reason: "Montant illisible ou nul : « \(amountText) »"))
            }
            let title = values[titleIndex].trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else {
                return result(.invalid(reason: "Intitulé manquant"))
            }
            let type = parseType(
                mapping.typeIndex.map { values[$0] },
                amountIsNegative: isNegative
            )
            let amount = FinanceMath.roundedToCents(parsedAmount)
            let categoryName = mapping.categoryIndex
                .map { values[$0].trimmingCharacters(in: .whitespaces) }
                .flatMap { $0.isEmpty ? nil : $0 }

            let rowFingerprint = fingerprint(
                fileName: fileName, rowIndex: rowIndex,
                date: date, amount: amount, type: type, title: title
            )
            if existingFingerprints.contains(rowFingerprint) || seenInFile.contains(rowFingerprint) {
                return result(.duplicate, date: date, amount: amount, type: type, title: title,
                              category: categoryName, fingerprint: rowFingerprint)
            }
            seenInFile.insert(rowFingerprint)
            return result(.ready, date: date, amount: amount, type: type, title: title,
                          category: categoryName, fingerprint: rowFingerprint)
        }
    }

    /// Category names present in ready rows but absent from the store —
    /// each must be explicitly confirmed before `apply` creates it.
    func missingCategoryNames(rows: [ImportRowResult], existing: [BudgetCategory]) -> [String] {
        let existingNames = Set(existing.map { $0.name.lowercased() })
        let needed = rows
            .filter { $0.state.isImportable }
            .compactMap(\.categoryName)
            .filter { !existingNames.contains($0.lowercased()) }
        return Array(Set(needed)).sorted()
    }

    // MARK: Apply (the only writing step)

    /// Imports ready rows into `account`, creating only the categories the
    /// user confirmed. Returns the full report; counters reconcile.
    func apply(
        rows: [ImportRowResult],
        fileName: String,
        account: Account,
        categories: [BudgetCategory],
        confirmedNewCategories: [String],
        now: Date,
        context: ModelContext
    ) throws -> ImportReport {
        let batch = ImportBatch(
            fileName: fileName,
            importedAt: now,
            totalRows: rows.count,
            importedCount: 0,
            duplicateCount: 0,
            invalidCount: 0,
            createdCategories: 0
        )
        context.insert(batch)

        // Categories: existing by lowercased name + confirmed creations.
        var categoryByName: [String: BudgetCategory] = [:]
        for category in categories {
            categoryByName[category.name.lowercased()] = category
        }
        var createdNames: [String] = []
        for name in confirmedNewCategories where categoryByName[name.lowercased()] == nil {
            let category = BudgetCategory(
                name: name,
                kind: .expense,
                iconToken: "tray",
                sortOrder: categories.count + createdNames.count
            )
            context.insert(category)
            categoryByName[name.lowercased()] = category
            createdNames.append(name)
        }

        var imported = 0
        var duplicates = 0
        var invalid = 0
        var rejected: [ImportRowResult] = []

        for row in rows {
            switch row.state {
            case .ready:
                guard let date = row.date, let amount = row.amount,
                      let type = row.type, let title = row.title else {
                    invalid += 1
                    rejected.append(row)
                    continue
                }
                let category = row.categoryName.flatMap { categoryByName[$0.lowercased()] }
                let transaction = BudgetTransaction(
                    date: date,
                    amount: amount,
                    type: type,
                    status: .posted,
                    title: title,
                    importFingerprint: row.fingerprint,
                    importBatchID: batch.id,
                    createdAt: now,
                    updatedAt: now,
                    account: account,
                    category: category
                )
                context.insert(transaction)
                imported += 1
            case .duplicate:
                duplicates += 1
                rejected.append(row)
            case .invalid:
                invalid += 1
                rejected.append(row)
            }
        }

        batch.importedCount = imported
        batch.duplicateCount = duplicates
        batch.invalidCount = invalid
        batch.createdCategories = createdNames.count
        try context.save()

        return ImportReport(
            batchID: batch.id,
            fileName: fileName,
            totalRows: rows.count,
            importedCount: imported,
            duplicateCount: duplicates,
            invalidCount: invalid,
            createdCategoryNames: createdNames,
            rejectedRows: rejected
        )
    }

    /// Removes every transaction of the batch (categories created stay —
    /// they may already be in use). Returns how many were removed.
    @discardableResult
    func rollback(batchID: UUID, context: ModelContext) throws -> Int {
        let transactions = try context.fetch(FetchDescriptor<BudgetTransaction>(
            predicate: #Predicate { $0.importBatchID == batchID }
        ))
        for transaction in transactions {
            context.delete(transaction)
        }
        if let batch = try context.fetch(FetchDescriptor<ImportBatch>(
            predicate: #Predicate { $0.id == batchID }
        )).first {
            context.delete(batch)
        }
        try context.save()
        return transactions.count
    }

    /// Fingerprints already present in the store (for duplicate detection
    /// across batches).
    func existingFingerprints(context: ModelContext) throws -> Set<String> {
        let transactions = try context.fetch(FetchDescriptor<BudgetTransaction>(
            predicate: #Predicate { $0.importFingerprint != nil }
        ))
        return Set(transactions.compactMap(\.importFingerprint))
    }
}
