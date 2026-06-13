// Models/Character.swift
//  SergioGuzmanPrueba
//
//  Modelo que representa un personaje de la API de Rick and Morty.
//  Refleja exactamente el schema documentado en https://rickandmortyapi.com/documentation#character
//  keyDecodingStrategy .convertFromSnakeCase en APIClient maneja snake_case → camelCase.

import Foundation

// MARK: - Character

struct Character: Codable, Identifiable {
    let id: Int
    let name: String
    let status: CharacterStatus
    let species: String
    let type: String
    let gender: CharacterGender
    let origin: CharacterLocation
    let location: CharacterLocation
    let image: String
    let episode: [String]
    let url: String
    let created: String

    /// URL de la imagen lista para usar con URLSession / SDWebImage.
    var imageURL: URL? { URL(string: image) }
}

// MARK: - CharacterStatus

enum CharacterStatus: String, Codable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .alive:   return String(localized: "character.status.alive",   defaultValue: "Alive")
        case .dead:    return String(localized: "character.status.dead",    defaultValue: "Dead")
        case .unknown: return String(localized: "character.status.unknown", defaultValue: "Unknown")
        }
    }
}

// MARK: - CharacterGender

enum CharacterGender: String, Codable {
    case female     = "Female"
    case male       = "Male"
    case genderless = "Genderless"
    case unknown    = "unknown"

    var displayName: String {
        switch self {
        case .female:     return String(localized: "character.gender.female",     defaultValue: "Female")
        case .male:       return String(localized: "character.gender.male",       defaultValue: "Male")
        case .genderless: return String(localized: "character.gender.genderless", defaultValue: "Genderless")
        case .unknown:    return String(localized: "character.gender.unknown",    defaultValue: "Unknown")
        }
    }
}

// MARK: - CharacterLocation

struct CharacterLocation: Codable {
    let name: String
    let url: String
}

// MARK: - CharacterResponse (paginación)

/// Wrapper de la respuesta paginada de la API.
/// `info.next` es nil cuando se alcanza la última página.
struct CharacterResponse: Codable {
    let info: PageInfo
    let results: [Character]
}

// MARK: - PageInfo

struct PageInfo: Codable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}
