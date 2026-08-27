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
/// 2. Rétrogradation dite : un store V14 (avec `Statement`) rouvert
///    par un schéma antérieur (V13) — le comportement observé est
///    CONSIGNÉ par le test : soit un refus (erreur), soit une
///    ouverture tolérée par CoreData (tables inconnues ignorées) ;
///    dans les deux cas le store DOIT rester intact et se rouvrir à
///    V14 avec le relevé retrouvé (refus/rétrogradation SANS PERTE).
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
            try autoreleasepool {
                let ancien = try ModelContainer(
                    for: Schema(versionedSchema: version),
                    configurations: [ModelConfiguration(url: storeURL)]
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

        // 2. Réouverture avec le schéma ANTÉRIEUR (V13). Les deux
        // issues honnêtes sont tolérées et CONSIGNÉES : un refus
        // (erreur à la construction/lecture) ou une ouverture où
        // l'entité inconnue est simplement invisible. Aucune des deux
        // ne doit TOUCHER le store.
        autoreleasepool {
            do {
                let v13 = try ModelContainer(
                    for: Schema(versionedSchema: BudgetSchemaV13.self),
                    configurations: [ModelConfiguration(url: storeURL)]
                )
                _ = ModelContext(v13)
                print("MATRICE W10.3 : rétrogradation V14→V13 TOLÉRÉE par CoreData (tables inconnues ignorées) — consigné.")
            } catch {
                print("MATRICE W10.3 : rétrogradation V14→V13 REFUSÉE (\(error)) — consigné.")
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
