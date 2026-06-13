// Services/Network/CharacterService.swift
//  SergioGuzmanPrueba
//
//  Encapsula todas las llamadas al endpoint /character de la API.
//  Soporta filtros por nombre, estado y especie — parámetros nativos de la API.
//  Recibe APIClient por inyección.

import Foundation

final class CharacterService {

    // MARK: - Dependencies

    private let apiClient: APIClient

    // MARK: - Init

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public API

    /// Obtiene una página de personajes con filtros opcionales.
    /// - Parameters:
    ///   - page: Número de página (comienza en 1).
    ///   - name: Filtro por nombre. Nil ignora este filtro.
    ///   - status: Filtro por estado (alive, dead, unknown). Nil ignora este filtro.
    ///   - species: Filtro por especie (human, alien, etc). Nil ignora este filtro.
    /// - Returns: `CharacterResponse` con resultados y metadatos de paginación.
    func fetchCharacters(
        page: Int,
        name: String? = nil,
        status: String? = nil,
        species: String? = nil
    ) async throws -> CharacterResponse {
        guard let url = buildURL(page: page, name: name, status: status, species: species) else {
            throw NetworkError.unknown(nil)
        }
        let request = URLRequest(url: url)
        return try await apiClient.request(request)
    }

    // MARK: - Private

    private func buildURL(page: Int, name: String?, status: String?, species: String?) -> URL? {
        var components = URLComponents(string: API.baseURL + API.Endpoint.character)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)")
        ]

        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        if let status = status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let species = species, !species.isEmpty {
            queryItems.append(URLQueryItem(name: "species", value: species))
        }

        components?.queryItems = queryItems
        return components?.url
    }
}
