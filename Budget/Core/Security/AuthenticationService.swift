import Foundation
import LocalAuthentication
import Observation

enum AuthenticationOutcome: Equatable {
    case success
    case cancelled
    case failed(String)
    case unavailable
}

/// Biometric/passcode authentication isolated behind a protocol
/// (engineering contract), so views and tests never touch LAContext.
protocol AuthenticationProviding {
    /// Face ID / Touch ID / device passcode is configured.
    var canAuthenticate: Bool { get }
    /// French label of the available method ("Face ID", "Touch ID"…).
    var biometryLabel: String { get }
    func authenticate(reason: String) async -> AuthenticationOutcome
}

struct BiometricAuthenticationService: AuthenticationProviding {
    var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    var biometryLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "le code de l'appareil"
        }
    }

    func authenticate(reason: String) async -> AuthenticationOutcome {
        let context = LAContext()
        context.localizedCancelTitle = "Annuler"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success ? .success : .failed("Authentification refusée.")
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .cancelled
            default:
                return .failed("L'authentification a échoué. Réessayez.")
            }
        } catch {
            return .failed("L'authentification a échoué. Réessayez.")
        }
    }
}

/// Scripted fake for tests and previews.
final class FakeAuthenticationService: AuthenticationProviding {
    var canAuthenticate = true
    var biometryLabel = "Face ID"
    var nextOutcome: AuthenticationOutcome = .success

    func authenticate(reason: String) async -> AuthenticationOutcome {
        nextOutcome
    }
}

/// App-lock state machine. Locked at launch and whenever the app goes to
/// background (while enabled); a cancelled or failed authentication keeps
/// the app locked — only an explicit success unlocks.
@Observable
final class AppLockManager {
    private static let enabledKey = "appLockEnabled"

    let authService: AuthenticationProviding
    private let defaults: UserDefaults

    private(set) var isLockEnabled: Bool
    private(set) var isLocked: Bool
    private(set) var lastErrorMessage: String?

    init(authService: AuthenticationProviding, defaults: UserDefaults = .standard) {
        self.authService = authService
        self.defaults = defaults
        let enabled = defaults.bool(forKey: Self.enabledKey)
        self.isLockEnabled = enabled
        self.isLocked = enabled
    }

    /// Enabling requires one successful authentication (never lock the
    /// user out with a method that does not work); disabling too, so a
    /// passer-by cannot simply switch the protection off.
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> AuthenticationOutcome {
        let reason = enabled
            ? "Activer le verrouillage de Budget"
            : "Désactiver le verrouillage de Budget"
        let outcome = await authService.authenticate(reason: reason)
        if outcome == .success {
            isLockEnabled = enabled
            defaults.set(enabled, forKey: Self.enabledKey)
            if !enabled { isLocked = false }
            lastErrorMessage = nil
        }
        return outcome
    }

    func lockIfEnabled() {
        if isLockEnabled {
            isLocked = true
            lastErrorMessage = nil
        }
    }

    @discardableResult
    func attemptUnlock() async -> AuthenticationOutcome {
        let outcome = await authService.authenticate(reason: "Déverrouiller vos données Budget")
        switch outcome {
        case .success:
            isLocked = false
            lastErrorMessage = nil
        case .cancelled:
            lastErrorMessage = nil // rester verrouillé, sans message d'erreur
        case .failed(let message):
            lastErrorMessage = message
        case .unavailable:
            lastErrorMessage = "Aucune méthode d'authentification n'est configurée sur cet appareil."
        }
        return outcome
    }
}
