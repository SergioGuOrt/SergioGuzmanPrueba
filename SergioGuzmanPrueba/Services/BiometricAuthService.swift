// Services/BiometricAuthService.swift
//  SergioGuzmanPrueba
//
//  Servicio de autenticación biométrica usando LocalAuthentication.
//  Responsabilidades:
//    - Verificar disponibilidad de biometría en el dispositivo.
//    - Autenticar al usuario mediante Face ID / Touch ID.
//    - Exponer resultado mediante async/await.
//  No importa UIKit. Se inyecta vía Swinject.

import LocalAuthentication
import os

/// Errores posibles de autenticación biométrica.
enum BiometricError: Error {
    case notAvailable
    case authenticationFailed
    case userCancelled
    case unknown(Error)

    var localizedMessage: String {
        switch self {
        case .notAvailable:
            return String(
                localized: "biometric.error.not_available",
                defaultValue: "Biometric authentication is not available on this device."
            )
        case .authenticationFailed:
            return String(
                localized: "biometric.error.failed",
                defaultValue: "Biometric authentication failed. Please try again."
            )
        case .userCancelled:
            return String(
                localized: "biometric.error.cancelled",
                defaultValue: "Authentication was cancelled."
            )
        case .unknown:
            return String(
                localized: "biometric.error.unknown",
                defaultValue: "An unexpected authentication error occurred."
            )
        }
    }
}

final class BiometricAuthService {

    // MARK: - Public API

    /// Verifica si el dispositivo soporta autenticación biométrica.
    var isBiometryAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if !available {
            AppLogger.biometric.debug("Biometry not available on this device")
        }
        return available
    }

    /// Solicita autenticación biométrica.
    /// - Returns: `true` si la autenticación es exitosa.
    /// - Throws: `BiometricError` si falla, se cancela o no está disponible.
    func authenticate() async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            AppLogger.biometric.warning("Biometric authentication unavailable")
            throw BiometricError.notAvailable
        }

        let reason = String(
            localized: "biometric.reason",
            defaultValue: "Authenticate to access your favorites."
        )

        AppLogger.biometric.debug("Biometric authentication requested")

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            AppLogger.biometric.info("Biometric authentication succeeded")
            return success
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel, .appCancel:
                AppLogger.biometric.info("Biometric authentication cancelled by user")
                throw BiometricError.userCancelled
            case .authenticationFailed:
                AppLogger.biometric.warning("Biometric authentication failed")
                throw BiometricError.authenticationFailed
            default:
                AppLogger.biometric.warning("Biometric authentication unavailable: \(authError.localizedDescription)")
                throw BiometricError.notAvailable
            }
        } catch {
            AppLogger.biometric.error("Biometric authentication unexpected error: \(error.localizedDescription)")
            throw BiometricError.unknown(error)
        }
    }
}
