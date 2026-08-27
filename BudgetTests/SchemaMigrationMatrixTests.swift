import XCTest
import SwiftData
@testable import Budget

/// W10.3 — MATRICE DE MIGRATIONS sur store DISQUE (Budget Autonomie
/// 100, ADR-071). Deux contrats :
///
/// 1. Un store créé à CHAQUE version déclarée (V1…V13) s'ouvre à V14
///    par la migration automatique légère, données intactes (UUID,
///    Decimal exact, relation) — le chemin RÉEL de mise à jour de
///    l'app, exercé sur disque parce que la classe de crash documentée
///    dans `BudgetSchema.swift` (SIGABRT du plan étagé) n'apparaît
///    JAMAIS in-memory.
///
/// 2. Rétrogradation REFUSÉE : un store V14 (avec `Statement`) rouvert
///    par un schéma antérieur (V13) doit être refusé ATOMIQUEMENT par
///    la garde de version (`StoreVersionGuard`) — le tour 1 de cette
///    PR (run CI 33042403589) a PROUVÉ que sans garde, CoreData ouvre
///    et DÉTRUIT la table inconnue (« Persistent History has to be
///    truncated due to the following entities being removed:
///    (Statement) ») : le relevé disparaissait. Après le refus, le
///    store rouvre à V14 avec le relevé intact.
///
/// Limite honnête (ADR-071) : les enums de version référencent les
/// classes VIVANTES — un store « créé à V1 » porte les colonnes
/// actuelles des cinq entités de V1, pas leur forme historique de
/// 2025. La matrice prouve donc les migrations par AJOUT D'ENTITÉS
/// (la totalité de l'histoire V1→V14) ; la reproduction propriété par
/// propriété exigera les classes figées réservées au premier
/// changement cassant. Le garde-fou contre une dérive de propriété
/// est le manifeste W10.2 (`schema-fige.mjs --check`).
///
/// Nettoyage : comme `DiskStoreLifecycleTests`, les dossiers UUID
/// temporaires ne sont PAS supprimés (handles SQLite asynchrones) —
/// l'isolation vient de l'UUID, le runner détruit son espace.
final class SchemaMigrationMatrixTests: XCTestCase {
    private static let versionsLivrees: [(String, any VersionedSchema.Type)] = [
        ("V1", BudgetSchemaV1.self),
        ("V2", BudgetSchemaV2.self),
        ("V3", BudgetSchemaV3.self),
        ("V4", BudgetSchemaV4.self),
        ("V5", BudgetSchemaV5.self),
        ("V6", BudgetSchemaV6.self),
        ("V7", BudgetSchemaV7.self),
        ("V8", BudgetSchemaV8.self),
        ("V9", BudgetSchemaV9.self),
        ("V10", BudgetSchemaV10.self),
        ("V11", BudgetSchemaV11.self),
        ("V12", BudgetSchemaV12.self),
        ("V13", BudgetSchemaV13.self),
    ]

    private func urlStoreTemporaire(_ marque: String) throws -> URL {
        let dossier = FileManager.default.temporaryDirectory
            .appendingPathComponent("budget-matrice-\(marque)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        return dossier.appendingPathComponent("Budget.store")
    }

    func testStoreCreeAChaqueVersionLivreeSOuvreAV14DonneesIntactes() throws {
        for (nom, version) in Self.versionsLivrees {
            let storeURL = try urlStoreTemporaire(nom.lowercased())
            let accountID = UUID()
            let transactionID = UUID()
            let opening = Decimal(string: "1000.45")!
            let amount = Decimal(string: "87.65")!
            let date = Date(timeIntervalSince1970: 1_784_000_000)

            // Écriture au schéma ANCIEN (Vn), sur disque, données
            // communes à toutes les versions (compte + mouvement, V1).
            // Par le chemin UNIQUE de production : la garde de version
            // ne doit JAMAIS refuser une création ni une mise à jour
            // légitime — la matrice entière le prouve.
            try autoreleasepool {
                let ancien = try PersistenceFactory.makeContainer(
                    configuration: ModelConfiguration(url: storeURL),
                    versionedSchema: version
                )
                let contexte = ModelContext(ancien)
                let compte = Account(
                    id: accountID,
                    name: "Compte matrice \(nom)",
                    type: .current,
                    openingBalance: opening
                )
                let mouvement = BudgetTransaction(
                    id: transactionID,
                    date: date,
                    amount: amount,
                    type: .expense,
                    title: "Dépense matrice \(nom)",
                    account: compte
                )
                contexte.insert(compte)
                contexte.insert(mouvement)
                try contexte.save()
            }

            // Réouverture au schéma ACTUEL (V14) par LE chemin de
            // production — la migration légère doit préserver tout.
            try autoreleasepool {
                let actuel = try PersistenceFactory.makeContainer(
                    configuration: ModelConfiguration(url: storeURL)
                )
                let contexte = ModelContext(actuel)
                let comptes = try contexte.fetch(
                    FetchDescriptor<Account>(predicate: #Predicate { $0.id == accountID })
                )
                XCTAssertEqual(comptes.count, 1, "\(nom)→V14 : le compte doit être retrouvé par UUID")
                let compte = try XCTUnwrap(comptes.first)
                XCTAssertEqual(compte.name, "Compte matrice \(nom)")
                XCTAssertEqual(compte.openingBalance, opening, "\(nom)→V14 : Decimal exact, jamais coercé")
                let mouvements = try contexte.fetch(
                    FetchDescriptor<BudgetTransaction>(predicate: #Predicate { $0.id == transactionID })
                )
                XCTAssertEqual(mouvements.count, 1, "\(nom)→V14 : le mouvement doit être retrouvé par UUID")
                let mouvement = try XCTUnwrap(mouvements.first)
                XCTAssertEqual(mouvement.amount, amount, "\(nom)→V14 : montant Decimal exact après migration")
                XCTAssertEqual(mouvement.account?.id, accountID, "\(nom)→V14 : relation mouvement → compte préservée")
            }
        }
    }

    func testRetrogradationV14VersV13SansPerte() throws {
        let storeURL = try urlStoreTemporaire("retro")
        let statementID = UUID()
        let accountID = UUID()
        let closing = Decimal(string: "2500.00")!
        let periodEnd = Date(timeIntervalSince1970: 1_785_000_000)

        // 1. Store V14 avec une entité que V13 ne connaît pas.
        try autoreleasepool {
            let v14 = try PersistenceFactory.makeContainer(
                configuration: ModelConfiguration(url: storeURL)
            )
            let contexte = ModelContext(v14)
            let releve = Statement(
                id: statementID,
                accountID: accountID,
                periodEnd: periodEnd,
                closingBalance: closing,
                source: "matrice-retro"
            )
            contexte.insert(releve)
            try contexte.save()
        }

        // 2. Réouverture avec le schéma ANTÉRIEUR (V13) par le chemin
        // de production : la garde DOIT refuser, en nommant l'entité
        // inconnue, SANS toucher au fichier. (Sans garde, CoreData
        // ouvre et détruit la table Statement — prouvé au tour 1,
        // run CI 33042403589 : c'est le contrôle négatif de ce lot.)
        autoreleasepool {
            do {
                _ = try PersistenceFactory.makeContainer(
                    configuration: ModelConfiguration(url: storeURL),
                    versionedSchema: BudgetSchemaV13.self
                )
                XCTFail("la rétrogradation V14→V13 doit être REFUSÉE : l'ouverture tolérée détruit la table Statement")
            } catch let erreur as StoreVersionGuard.StoreNewerThanAppError {
                XCTAssertEqual(erreur.unknownEntities, ["Statement"], "le refus doit NOMMER l'entité inconnue")
            } catch {
                XCTFail("le refus doit venir de la garde de version, pas de : \(error)")
            }
        }

        // 3. Quoi qu'il se soit passé, le store rouvre à V14 et le
        // relevé est INTACT — rétrogradation sans perte.
        try autoreleasepool {
            let v14 = try PersistenceFactory.makeContainer(
                configuration: ModelConfiguration(url: storeURL)
            )
            let contexte = ModelContext(v14)
            let releves = try contexte.fetch(
                FetchDescriptor<Statement>(predicate: #Predicate { $0.id == statementID })
            )
            XCTAssertEqual(releves.count, 1, "après tentative V13, le relevé V14 doit survivre intact")
            let releve = try XCTUnwrap(releves.first)
            XCTAssertEqual(releve.closingBalance, closing, "solde de clôture Decimal exact après l'aller-retour")
            XCTAssertEqual(releve.accountID, accountID)
        }
    }
}
