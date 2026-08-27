import CommonCrypto
import CryptoKit
import Foundation

/// W10.4 (ADR-072) — sauvegarde protégée par PHRASE DE PASSE, au choix
/// de l'utilisateur au moment de l'export (l'export en clair reste
/// possible). Enveloppe JSON auto-descriptive ; les octets EXACTS du
/// JSON de sauvegarde sont scellés par AES-GCM (CryptoKit), la clé est
/// dérivée de la phrase par PBKDF2-SHA256 (CommonCrypto) avec un sel
/// aléatoire PAR FICHIER. Sans la phrase, le fichier est illisible et
/// PERSONNE ne peut la retrouver — l'interface le dit en clair avant
/// l'export. Un fichier abîmé ou une phrase incorrecte donnent un refus
/// NOMMÉ qui ne touche à rien.
enum BackupCrypto {
    enum CryptoError: LocalizedError, Equatable {
        case unreadableEnvelope
        case wrongPassphrase

        var errorDescription: String? {
            switch self {
            case .unreadableEnvelope:
                return "Ce fichier protégé est illisible ou abîmé — vos données actuelles sont intactes."
            case .wrongPassphrase:
                return "Phrase de passe incorrecte (ou fichier modifié) — vos données actuelles sont intactes."
            }
        }
    }

    /// Enveloppe versionnée : tout ce qu'il faut pour déchiffrer AVEC la
    /// phrase, rien qui aide sans elle.
    struct Envelope: Codable {
        var formatBudget: String
        var version: Int
        var kdf: String
        var iterations: Int
        var salt: Data
        var sealed: Data
    }

    static let format = "sauvegarde-budget-protegee"
    static let currentVersion = 1
    static let kdfName = "pbkdf2-sha256"
    static let iterations = 210_000
    private static let saltLength = 16
    private static let keyLength = 32

    /// Reconnaît une enveloppe protégée SANS la déchiffrer (aiguillage
    /// de la restauration).
    static func isEncryptedEnvelope(_ data: Data) -> Bool {
        (try? JSONDecoder().decode(Envelope.self, from: data))?.formatBudget == format
    }

    static func encrypt(_ payload: Data, passphrase: String) throws -> Data {
        var salt = Data(count: saltLength)
        let saltStatus = salt.withUnsafeMutableBytes { bytes -> Int32 in
            guard let base = bytes.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, saltLength, base)
        }
        guard saltStatus == errSecSuccess else { throw CryptoError.unreadableEnvelope }
        let key = try deriveKey(passphrase: passphrase, salt: salt, iterations: iterations)
        guard let sealed = try AES.GCM.seal(payload, using: key).combined else {
            throw CryptoError.unreadableEnvelope
        }
        let envelope = Envelope(
            formatBudget: format,
            version: currentVersion,
            kdf: kdfName,
            iterations: iterations,
            salt: salt,
            sealed: sealed
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(envelope)
    }

    static func decrypt(_ data: Data, passphrase: String) throws -> Data {
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              envelope.formatBudget == format else {
            throw CryptoError.unreadableEnvelope
        }
        guard envelope.version == currentVersion,
              envelope.kdf == kdfName,
              envelope.iterations >= 100_000,
              envelope.salt.count == saltLength else {
            throw CryptoError.unreadableEnvelope
        }
        let key = try deriveKey(passphrase: passphrase, salt: envelope.salt, iterations: envelope.iterations)
        guard let box = try? AES.GCM.SealedBox(combined: envelope.sealed),
              let clear = try? AES.GCM.open(box, using: key) else {
            // GCM authentifie : phrase incorrecte et contenu falsifié sont
            // indistinguables — le message nomme les deux.
            throw CryptoError.wrongPassphrase
        }
        return clear
    }

    private static func deriveKey(passphrase: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        var derived = Data(count: keyLength)
        let phrase = Data(passphrase.utf8)
        let status = derived.withUnsafeMutableBytes { derivedBytes -> Int32 in
            salt.withUnsafeBytes { saltBytes -> Int32 in
                phrase.withUnsafeBytes { phraseBytes -> Int32 in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        phraseBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        phrase.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw CryptoError.unreadableEnvelope }
        return SymmetricKey(data: derived)
    }
}
