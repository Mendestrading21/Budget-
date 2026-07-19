import Foundation

/// File import/storage isolated behind a protocol (engineering contract),
/// so views and tests never touch FileManager directly.
protocol DocumentFileStoring {
    /// Copies the file at `url` into the protected document store.
    /// Returns the relative reference to persist and the size in bytes.
    func copyIn(from url: URL) throws -> (fileReference: String, sizeBytes: Int)
    /// Absolute URL of a stored file, nil when the reference is unknown.
    func url(for fileReference: String) -> URL?
    func delete(_ fileReference: String) throws
}

enum DocumentFileStoreError: LocalizedError {
    case unreadableSource
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .unreadableSource:
            "Le fichier n'a pas pu être lu. Vérifiez l'accès au document et réessayez."
        case .copyFailed:
            "La copie du document a échoué. Réessayez."
        }
    }
}

/// Real store: files live under Documents/FinancialDocuments inside the
/// app container (protected by iOS data protection), named by UUID.
struct LocalDocumentFileStore: DocumentFileStoring {
    private var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("FinancialDocuments", isDirectory: true)
    }

    func copyIn(from url: URL) throws -> (fileReference: String, sizeBytes: Int) {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url) else {
            throw DocumentFileStoreError.unreadableSource
        }
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let ext = url.pathExtension.isEmpty ? "bin" : url.pathExtension.lowercased()
            let reference = "\(UUID().uuidString).\(ext)"
            try data.write(to: directory.appendingPathComponent(reference), options: [.atomic, .completeFileProtection])
            return (reference, data.count)
        } catch {
            throw DocumentFileStoreError.copyFailed
        }
    }

    func url(for fileReference: String) -> URL? {
        guard !fileReference.isEmpty else { return nil }
        let url = directory.appendingPathComponent(fileReference)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func delete(_ fileReference: String) throws {
        guard let url = url(for: fileReference) else { return }
        try FileManager.default.removeItem(at: url)
    }
}

/// In-memory fake for tests and previews — no disk access at all.
final class InMemoryDocumentFileStore: DocumentFileStoring {
    private(set) var files: [String: Data] = [:]

    func copyIn(from url: URL) throws -> (fileReference: String, sizeBytes: Int) {
        let data = (try? Data(contentsOf: url)) ?? Data("fake".utf8)
        let reference = "\(UUID().uuidString).\(url.pathExtension.isEmpty ? "bin" : url.pathExtension)"
        files[reference] = data
        return (reference, data.count)
    }

    /// Stores raw data directly (test convenience).
    func store(_ data: Data, reference: String) {
        files[reference] = data
    }

    func url(for fileReference: String) -> URL? {
        files[fileReference] != nil
            ? URL(fileURLWithPath: "/dev/null/\(fileReference)")
            : nil
    }

    func delete(_ fileReference: String) throws {
        files.removeValue(forKey: fileReference)
    }
}
