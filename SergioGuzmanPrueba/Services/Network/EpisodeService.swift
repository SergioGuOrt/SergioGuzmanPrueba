// Services/Network/EpisodeService.swift
//  SergioGuzmanPrueba
//
//  Obtiene episodios reales desde la API de Rick & Morty.
//  El endpoint /episode/1,2,3 retorna un array cuando se pasan múltiples IDs.
//  Cuando solo hay un ID retorna un objeto individual — se normaliza a array.

import Foundation

final class EpisodeService {

    // MARK: - Dependencies

    private let apiClient: APIClient

    // MARK: - Init

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public API

    /// Obtiene los episodios correspondientes a una lista de URLs de episodio.
    /// Las URLs tienen la forma: "https://rickandmortyapi.com/api/episode/28"
    /// - Parameter episodeURLs: URLs de episodios del Character.
    /// - Returns: Array de Episode con datos reales de la API.
    func fetchEpisodes(from episodeURLs: [String]) async throws -> [Episode] {
        guard !episodeURLs.isEmpty else { return [] }

        let ids = episodeURLs.compactMap { url -> String? in
            url.split(separator: "/").last.map(String.init)
        }
        guard !ids.isEmpty else { return [] }

        // Un solo episodio → objeto individual, múltiples → array.
        if ids.count == 1 {
            return try await fetchSingle(id: ids[0])
        } else {
            return try await fetchMultiple(ids: ids)
        }
    }

    // MARK: - Private

    private func fetchSingle(id: String) async throws -> [Episode] {
        guard let url = URL(string: API.baseURL + API.Endpoint.episode + "/\(id)") else {
            throw NetworkError.unknown(nil)
        }
        let episode: Episode = try await apiClient.request(URLRequest(url: url))
        return [episode]
    }

    private func fetchMultiple(ids: [String]) async throws -> [Episode] {
        let joined = ids.joined(separator: ",")
        guard let url = URL(string: API.baseURL + API.Endpoint.episode + "/\(joined)") else {
            throw NetworkError.unknown(nil)
        }
        return try await apiClient.request(URLRequest(url: url))
    }
}
