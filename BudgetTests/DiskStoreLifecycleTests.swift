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
/// Nettoyage — décision propriétaire (option 1) : le dossier n'est PAS
/// supprimé par le test. Toutes les références SwiftData détenues par
/// le test sont libérées à la sortie de leurs blocs `autoreleasepool`,
/// mais des handles SQLite internes peuvent rester ouverts APRÈS cette
/// sortie (fermeture asynchrone sur des files d'arrière-plan) et
/// SwiftData n'expose aucun point public de synchronisation de leur
/// fermeture. Supprimer les fichiers à cet instant déclencherait un
/// unlink concurrent (« database integrity compromised by API
/// violation: vnode unlinked while in use »). Le dossier UUID unique
/// assure l'isolation entre exécutions et il est intentionnellement
/// laissé dans l'espace temporaire du simulateur/runner, détruit avec
/// lui.
final class DiskStoreLifecycleTests: XCTestCase {
    func testDataWrittenOnDiskSurvivesFullContainerTeardown() throws {
        // 1. URL temporaire UNIQUE pour ce run (l'isolation vient de
        // l'UUID du dossier, jamais d'un nettoyage).
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
        // DISQUE (jamais in-memory), insertion, save, puis libération de
        // toutes les références du test à la sortie du bloc.
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

        // Pas de suppression du dossier ici — voir l'en-tête : des
        // handles SQLite internes peuvent survivre à la libération des
        // références du test, et il n'existe aucune barrière publique
        // pour attendre leur fermeture sans temporisation artificielle.
    }
}
