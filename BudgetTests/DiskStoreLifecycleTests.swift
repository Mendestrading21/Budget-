import XCTest
import SwiftData
@testable import Budget

/// Passe corrective L9 : cycle de vie RÉEL d'un store SUR DISQUE.
/// Écrire avec un premier conteneur, le détruire complètement, rouvrir
/// la même URL avec un conteneur INDÉPENDANT et relire les données par
/// leur UUID. Les autres suites restent volontairement in-memory ;
/// celle-ci est la seule à toucher le disque — via le point d'injection
/// `PersistenceFactory.makeContainer`, le même chemin de construction
/// (même schéma V8) que `makeProductionContainer`.
///
/// Micro-correction : l'ÉCRITURE et la RELECTURE vivent chacune dans
/// leur propre `autoreleasepool` et RIEN (conteneur, contexte, modèle,
/// résultat de fetch) n'en sort ; le dossier temporaire n'est supprimé
/// qu'APRÈS la sortie du second bloc, une fois le store refermé —
/// sinon SQLite journalise « database integrity compromised by API
/// violation: vnode unlinked while in use » (fichiers .store/-wal/-shm
/// effacés sous une connexion encore ouverte).
final class DiskStoreLifecycleTests: XCTestCase {
    func testDataWrittenOnDiskSurvivesFullContainerTeardown() throws {
        // 1. URL temporaire UNIQUE pour ce run.
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("budget-disk-lifecycle-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("Budget.store")

        // Données fictives identifiables par UUID, montant Decimal exact,
        // relation utile compte ↔ mouvement.
        let accountID = UUID()
        let transactionID = UUID()
        let opening = Decimal(string: "2000.05")!
        let amount = Decimal(string: "1234.56")!
        let movementDate = Date(timeIntervalSince1970: 1_784_000_000)

        // 2-5. Phase d'ÉCRITURE — premier conteneur, configuration SUR
        // DISQUE (jamais in-memory), insertion, save, puis destruction
        // COMPLÈTE du contexte et du conteneur à la sortie du bloc.
        try autoreleasepool {
            let configuration = ModelConfiguration(url: storeURL)
            XCTAssertFalse(
                configuration.isStoredInMemoryOnly,
                "la configuration du test doit être un store DISQUE"
            )
            let firstContainer = try PersistenceFactory.makeContainer(configuration: configuration)
            let firstContext = ModelContext(firstContainer)

            let account = Account(
                id: accountID,
                name: "Compte cycle disque",
                type: .current,
                openingBalance: opening
            )
            let movement = BudgetTransaction(
                id: transactionID,
                date: movementDate,
                amount: amount,
                type: .expense,
                title: "Dépense cycle disque",
                account: account
            )
            firstContext.insert(account)
            firstContext.insert(movement)
            try firstContext.save()
        }

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: storeURL.path),
            "le fichier de store doit exister sur le disque après le save"
        )

        // 6-8. Phase de RELECTURE — second conteneur INDÉPENDANT sur la
        // MÊME URL, dans son PROPRE bloc : aucune référence SwiftData
        // (conteneur, contexte, modèle, résultat de fetch) n'en sort.
        // Vérification EXACTE des valeurs et de la relation persistées —
        // pas un simple « aucun crash ».
        try autoreleasepool {
            let secondContainer = try PersistenceFactory.makeContainer(
                configuration: ModelConfiguration(url: storeURL)
            )
            let secondContext = ModelContext(secondContainer)

            let accounts = try secondContext.fetch(
                FetchDescriptor<Account>(predicate: #Predicate { $0.id == accountID })
            )
            XCTAssertEqual(accounts.count, 1, "le compte doit être retrouvé par son UUID")
            let account = try XCTUnwrap(accounts.first)
            XCTAssertEqual(account.name, "Compte cycle disque")
            XCTAssertEqual(account.type, .current)
            XCTAssertEqual(account.openingBalance, opening, "montant Decimal exact, jamais coercé")

            let movements = try secondContext.fetch(
                FetchDescriptor<BudgetTransaction>(predicate: #Predicate { $0.id == transactionID })
            )
            XCTAssertEqual(movements.count, 1, "le mouvement doit être retrouvé par son UUID")
            let movement = try XCTUnwrap(movements.first)
            XCTAssertEqual(movement.title, "Dépense cycle disque")
            XCTAssertEqual(movement.amount, amount, "montant Decimal exact après réouverture")
            XCTAssertEqual(movement.type, .expense)
            XCTAssertEqual(movement.date, movementDate)

            // La relation survit dans les DEUX sens.
            XCTAssertEqual(movement.account?.id, accountID, "relation mouvement → compte persistée")
            XCTAssertEqual(account.transactions.map(\.id), [transactionID], "relation compte → mouvements persistée")
        }

        // 9. Nettoyage APRÈS la sortie du second bloc, store refermé —
        // tout échec est VISIBLE (jamais de `try?`).
        XCTAssertNoThrow(
            try FileManager.default.removeItem(at: directory),
            "le nettoyage du dossier temporaire doit réussir une fois le store refermé"
        )
    }
}
