import XCTest
import SwiftData
@testable import Budget

/// W10.4 (ADR-072) — sauvegarde protégée par phrase de passe. Contrats :
/// aller-retour au OCTET près, phrase incorrecte et fichier falsifié
/// refusés par une erreur NOMMÉE sans rien toucher, enveloppe illisible
/// refusée, sel unique par fichier, et le chemin complet
/// (makeEncryptedBackup → decrypt → summary/restore) rejoint les MÊMES
/// portes que la sauvegarde en clair.
final class BackupCryptoTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!
    private let service = BackupService()

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
    }

    override func tearDown() {
        calendar = nil
        context = nil
        container = nil
    }

    func testRoundTripRestoresExactBytes() throws {
        let clair = Data("{\"exemple\":\"données fictives 1234.56\"}".utf8)
        let enveloppe = try BackupCrypto.encrypt(clair, passphrase: "phrase correcte")
        XCTAssertTrue(BackupCrypto.isEncryptedEnvelope(enveloppe), "l'enveloppe doit se reconnaître elle-même")
        XCTAssertNotEqual(enveloppe, clair)
        XCTAssertNil(String(data: enveloppe, encoding: .utf8).flatMap { $0.contains("1234.56") ? $0 : nil },
                     "le contenu clair ne doit JAMAIS apparaître dans le fichier protégé")
        let dechiffre = try BackupCrypto.decrypt(enveloppe, passphrase: "phrase correcte")
        XCTAssertEqual(dechiffre, clair, "aller-retour au octet près")
    }

    func testWrongPassphraseIsANamedRefusal() throws {
        let enveloppe = try BackupCrypto.encrypt(Data("secret".utf8), passphrase: "bonne phrase")
        XCTAssertThrowsError(try BackupCrypto.decrypt(enveloppe, passphrase: "mauvaise phrase")) { error in
            XCTAssertEqual(error as? BackupCrypto.CryptoError, .wrongPassphrase)
            XCTAssertTrue((error as? LocalizedError)?.errorDescription?.contains("intactes") == true,
                          "le refus dit en clair que rien n'a été touché")
        }
    }

    func testTamperedFileIsRefused() throws {
        let enveloppe = try BackupCrypto.encrypt(Data("secret".utf8), passphrase: "phrase")
        var texte = String(decoding: enveloppe, as: UTF8.self)
        // Falsifier UN caractère base64 du scellé. DURCI après un flake
        // CI (run 33064572384) : Foundation échappe « / » en « \/ » dans
        // le JSON — une position FIXE pouvait tomber sur l'échappement et
        // rendre le JSON/base64 illisible (unreadableEnvelope au lieu de
        // wrongPassphrase). On falsifie donc le premier caractère
        // ALPHANUMÉRIQUE du scellé : toujours un vrai octet chiffré,
        // jamais un échappement ni un signe de ponctuation base64.
        guard let plage = texte.range(of: "\"sealed\":\"") else {
            return XCTFail("enveloppe sans champ scellé")
        }
        var position = texte.index(plage.upperBound, offsetBy: 1)
        while !(texte[position].isLetter || texte[position].isNumber) {
            position = texte.index(after: position)
        }
        let original = texte[position]
        texte.replaceSubrange(position...position, with: original == "A" ? "B" : "A")
        XCTAssertThrowsError(try BackupCrypto.decrypt(Data(texte.utf8), passphrase: "phrase")) { error in
            XCTAssertEqual(error as? BackupCrypto.CryptoError, .wrongPassphrase,
                           "GCM authentifie : un fichier falsifié est refusé")
        }
    }

    func testUnreadableEnvelopeIsRefusedAndPlainJSONIsNotAnEnvelope() throws {
        let json = Data("{\"schemaVersion\":1}".utf8)
        XCTAssertFalse(BackupCrypto.isEncryptedEnvelope(json), "un JSON ordinaire n'est pas une enveloppe")
        XCTAssertThrowsError(try BackupCrypto.decrypt(json, passphrase: "x")) { error in
            XCTAssertEqual(error as? BackupCrypto.CryptoError, .unreadableEnvelope)
        }
    }

    func testSaltIsUniquePerFile() throws {
        // Durci après un sabotage INERTE (sel figé non détecté) : le
        // nonce GCM rend les fichiers différents même à sel figé — il
        // faut donc comparer les SELS décodés, pas les fichiers.
        let clair = Data("même contenu".utf8)
        let a = try JSONDecoder().decode(BackupCrypto.Envelope.self,
                                         from: BackupCrypto.encrypt(clair, passphrase: "phrase"))
        let b = try JSONDecoder().decode(BackupCrypto.Envelope.self,
                                         from: BackupCrypto.encrypt(clair, passphrase: "phrase"))
        XCTAssertNotEqual(a.salt, b.salt, "chaque fichier protégé doit porter son PROPRE sel aléatoire")
        XCTAssertFalse(a.salt.allSatisfy { $0 == 0 }, "le sel ne doit jamais être laissé à zéro")
    }

    func testFullPathEncryptedBackupRestoresTheStore() throws {
        DemoDataFactory.populate(container: container, now: now, calendar: calendar)
        try context.save()
        let avantComptes = try context.fetch(FetchDescriptor<Account>()).count
        XCTAssertGreaterThan(avantComptes, 0)

        let protegee = try service.makeEncryptedBackup(context: context, now: now, passphrase: "phrase du foyer")
        XCTAssertTrue(BackupCrypto.isEncryptedEnvelope(protegee))
        // La sauvegarde protégée n'est PAS lisible par la porte en clair.
        XCTAssertThrowsError(try service.summary(of: protegee))

        // Déchiffrée, elle rejoint les MÊMES portes que la sauvegarde en
        // clair : résumé réel identique, restauration complète.
        let clair = try BackupCrypto.decrypt(protegee, passphrase: "phrase du foyer")
        let temoin = try service.makeBackup(context: context, now: now)
        XCTAssertEqual(try service.summary(of: clair), try service.summary(of: temoin),
                       "même résumé que la sauvegarde en clair du même store")

        let cible = try PersistenceFactory.makeInMemoryContainer()
        let cibleContexte = ModelContext(cible)
        try service.restore(data: clair, context: cibleContexte, documentFileStore: nil)
        XCTAssertEqual(try cibleContexte.fetch(FetchDescriptor<Account>()).count, avantComptes,
                       "restauration complète depuis la sauvegarde protégée")
    }

    func testWrongPassphraseLeavesStoreUntouched() throws {
        DemoDataFactory.populate(container: container, now: now, calendar: calendar)
        try context.save()
        let avant = try context.fetch(FetchDescriptor<BudgetTransaction>()).count
        let protegee = try service.makeEncryptedBackup(context: context, now: now, passphrase: "bonne")
        XCTAssertThrowsError(try BackupCrypto.decrypt(protegee, passphrase: "mauvaise"))
        XCTAssertEqual(try context.fetch(FetchDescriptor<BudgetTransaction>()).count, avant,
                       "un refus de phrase ne touche à RIEN")
    }
}
