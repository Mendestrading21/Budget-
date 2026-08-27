import XCTest
import SwiftData
@testable import Budget

/// W10.5 (ADR-072, décision propriétaire) — les pièces jointes voyagent
/// dans la sauvegarde. Contrats : aller-retour des FICHIERS au octet
/// près ; une sauvegarde métadonnées seules (antérieure) ne touche
/// jamais aux fichiers présents ; un fichier manquant à l'export
/// n'invente rien ; après une restauration complète, les orphelines
/// sont balayées (le référencé survit) ; le store d'écriture refuse
/// toute référence qui sortirait du dossier protégé.
final class DocumentBackupTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = BackupService()

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    private func insertDocument(reference: String) -> FinancialDocument {
        let document = FinancialDocument(
            title: "Facture fictive",
            kind: .invoice,
            year: 2026,
            fileReference: reference,
            fileSizeBytes: 5,
            addedAt: now,
            updatedAt: now
        )
        context.insert(document)
        return document
    }

    func testFilesTravelInBackupAndRestoreByteForByte() throws {
        let source = InMemoryDocumentFileStore()
        let octets = Data("contenu de facture fictif 1234".utf8)
        source.store(octets, reference: "aaaa.pdf")
        _ = insertDocument(reference: "aaaa.pdf")
        try context.save()

        let sauvegarde = try service.makeBackup(context: context, now: now, documentFileStore: source)
        let resume = try service.summary(of: sauvegarde)
        XCTAssertEqual(resume.documents, 1)
        XCTAssertEqual(resume.documentFiles, 1, "le résumé dit combien de fichiers sont embarqués")

        // Restauration dans un store NEUF portant un fichier orphelin :
        // le fichier de la sauvegarde arrive au octet près, l'orphelin
        // est balayé.
        let cible = try PersistenceFactory.makeInMemoryContainer()
        let cibleContexte = ModelContext(cible)
        let cibleStore = InMemoryDocumentFileStore()
        cibleStore.store(Data("reste d'avant".utf8), reference: "orphelin.bin")
        try service.restore(data: sauvegarde, context: cibleContexte, documentFileStore: cibleStore)

        XCTAssertEqual(cibleStore.contents(of: "aaaa.pdf"), octets, "fichier restauré au octet près")
        XCTAssertNil(cibleStore.contents(of: "orphelin.bin"), "l'orpheline est balayée après une restauration complète")
        let restaures = try cibleContexte.fetch(FetchDescriptor<FinancialDocument>())
        XCTAssertEqual(restaures.map(\.fileReference), ["aaaa.pdf"])
    }

    func testMetadataOnlyBackupNeverTouchesExistingFiles() throws {
        _ = insertDocument(reference: "meta.pdf")
        try context.save()
        // Sauvegarde SANS store de fichiers = métadonnées seules
        // (exactement le format antérieur à W10.5).
        let sauvegarde = try service.makeBackup(context: context, now: now)
        XCTAssertEqual(try service.summary(of: sauvegarde).documentFiles, 0)

        let cible = try PersistenceFactory.makeInMemoryContainer()
        let cibleContexte = ModelContext(cible)
        let cibleStore = InMemoryDocumentFileStore()
        cibleStore.store(Data("fichier local préexistant".utf8), reference: "meta.pdf")
        cibleStore.store(Data("autre fichier".utf8), reference: "non-reference.bin")
        try service.restore(data: sauvegarde, context: cibleContexte, documentFileStore: cibleStore)

        XCTAssertNotNil(cibleStore.contents(of: "meta.pdf"),
                        "métadonnées seules : le fichier présent reste joignable")
        XCTAssertNotNil(cibleStore.contents(of: "non-reference.bin"),
                        "métadonnées seules : AUCUN fichier n'est touché (comportement antérieur)")
    }

    func testMissingFileAtExportTravelsAsMetadataOnly() throws {
        let source = InMemoryDocumentFileStore()
        _ = insertDocument(reference: "disparu.pdf")
        try context.save()
        let sauvegarde = try service.makeBackup(context: context, now: now, documentFileStore: source)
        let resume = try service.summary(of: sauvegarde)
        XCTAssertEqual(resume.documents, 1, "la métadonnée voyage")
        XCTAssertEqual(resume.documentFiles, 0, "aucun octet inventé pour un fichier absent")
    }

    func testSweepOrphansKeepsReferencedFiles() throws {
        let store = InMemoryDocumentFileStore()
        store.store(Data("référencé".utf8), reference: "garde.pdf")
        store.store(Data("abandonné".utf8), reference: "poubelle.tmp")
        _ = insertDocument(reference: "garde.pdf")
        try context.save()

        let balayees = service.sweepOrphanFiles(context: context, documentFileStore: store)
        XCTAssertEqual(balayees, ["poubelle.tmp"], "le balayage nomme ce qu'il supprime")
        XCTAssertNotNil(store.contents(of: "garde.pdf"))
        XCTAssertNil(store.contents(of: "poubelle.tmp"))
    }

    func testDeleteAllLeavesNoFileBehind() throws {
        // W10.7 : « tout supprimer » supprime les fichiers référencés ET
        // les orphelines — le dossier protégé finit VIDE.
        let store = InMemoryDocumentFileStore()
        store.store(Data("référencé".utf8), reference: "doc.pdf")
        store.store(Data("orpheline".utf8), reference: "reste.tmp")
        _ = insertDocument(reference: "doc.pdf")
        try context.save()

        try service.deleteAll(context: context, documentFileStore: store)
        XCTAssertTrue(store.allReferences().isEmpty,
                      "aucun fichier ne survit à « tout supprimer » (référencés ET orphelines)")
        XCTAssertTrue(try context.fetch(FetchDescriptor<FinancialDocument>()).isEmpty)
    }

    func testLocalStoreWriteRefusesPathEscapes() {
        let store = LocalDocumentFileStore()
        XCTAssertThrowsError(try store.write(Data("x".utf8), fileReference: "../evasion.pdf"),
                             "une référence qui remonte l'arborescence est refusée avant tout disque")
        XCTAssertThrowsError(try store.write(Data("x".utf8), fileReference: "sous/dossier.pdf"))
        XCTAssertThrowsError(try store.write(Data("x".utf8), fileReference: ""))
    }
}
