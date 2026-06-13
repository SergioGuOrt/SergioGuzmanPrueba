// Models/Episode.swift
//  SergioGuzmanPrueba
//
//  Modelo de dominio para un episodio de Rick & Morty.
//  Refleja el schema de https://rickandmortyapi.com/documentation#episode
//  keyDecodingStrategy .convertFromSnakeCase maneja air_date → airDate.

import Foundation

struct Episode: Codable, Identifiable {
    let id: Int
    let name: String
    let airDate: String
    let episode: String
    let characters: [String]
    let url: String
    let created: String
}

// MARK: - EpisodeResponse (múltiples IDs)

/// La API acepta /episode/1,2,3 y retorna un array directamente.
typealias EpisodeArrayResponse = [Episode]
