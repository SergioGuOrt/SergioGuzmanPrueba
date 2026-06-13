// Services/Network/NetworkError.swift
//  SergioGuzmanPrueba
//
//  Enum tipado de errores de la capa de red.
//  Tipo de error estándar propagado desde APIClient hasta los ViewModels.
//  Conforme a LocalizedError para exponer mensajes legibles en la UI
//  usando el String Catalog (Localizable.xcstrings).

import Foundation

enum NetworkError: LocalizedError {
    case noInternet
    case timeout
    case unauthorized
    case serverError(statusCode: Int)
    case decodingError(Error)
    case unknown(Error?)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection."

        case .timeout:
            return "The request timed out."

        case .unauthorized:
            return "Session expired. Please log in again."

        case .serverError(let code):
            return "Server error (\(code))."

        case .decodingError:
            return "Could not process the server response."

        case .unknown:
            return "An unexpected error occurred."
        }
    }}
