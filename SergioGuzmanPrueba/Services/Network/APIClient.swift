// Services/Network/APIClient.swift
//  SergioGuzmanPrueba
//
//  Cliente HTTP genérico basado en URLSession y async/await.
//  Responsable de ejecutar requests, decodificar respuestas JSON
//  y mapear cualquier error al tipo NetworkError estándar del proyecto.
//  Se registra en Swinject como .container (una sola instancia durante la vida de la app).

import Foundation
import os

final class APIClient {

    // MARK: - Properties

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Init

    /// - Parameter session: Por defecto usa URLSession.shared.
    ///   En tests se puede inyectar una sesión con URLProtocol mock.
    init(session: URLSession = .shared) {
        self.session = session

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Request

    /// Ejecuta un URLRequest y decodifica la respuesta al tipo genérico T.
    /// - Parameter request: URLRequest configurado con URL, método, headers y body.
    /// - Returns: Instancia de T decodificada desde el JSON de la respuesta.
    /// - Throws: `NetworkError` en caso de fallo de conectividad, HTTP o decoding.
    func request<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        let url = request.url?.absoluteString ?? "unknown"
        let method = request.httpMethod ?? "GET"
        AppLogger.network.debug("Request started: \(method) \(url)")

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            let mapped = mapped(from: urlError)
            AppLogger.network.error("Request failed: \(method) \(url) - \(mapped.localizedDescription ?? "unknown")")
            throw mapped
        } catch {
            AppLogger.network.error("Request failed: \(method) \(url) - \(error.localizedDescription)")
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.network.error("Request failed: \(method) \(url) - invalid response")
            throw NetworkError.unknown(nil)
        }

        do {
            try validate(statusCode: httpResponse.statusCode)
        } catch {
            AppLogger.network.error("Request failed: \(method) \(url) - status \(httpResponse.statusCode)")
            throw error
        }

        do {
            let decoded = try decoder.decode(T.self, from: data)
            AppLogger.network.debug("Request succeeded: \(method) \(url) - status \(httpResponse.statusCode)")
            return decoded
        } catch {
            AppLogger.network.error("Decoding failed: \(method) \(url) - \(error.localizedDescription)")
            throw NetworkError.decodingError(error)
        }
    }

    // MARK: - Private Helpers

    private func validate(statusCode: Int) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(statusCode: statusCode)
        }
    }

    private func mapped(from urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternet
        case .timedOut:
            return .timeout
        default:
            return .unknown(urlError)
        }
    }
}
