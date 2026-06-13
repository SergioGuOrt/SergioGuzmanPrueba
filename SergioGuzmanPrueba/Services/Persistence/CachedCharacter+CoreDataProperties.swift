// Services/Persistence/CachedCharacter+CoreDataProperties.swift
//  SergioGuzmanPrueba
//
//  Propiedades y mappers de la entidad CachedCharacter.
//  Refleja los atributos del modelo .xcdatamodel.
//  Incluye mapeo bidireccional Character ↔ CachedCharacter.

import Foundation
import CoreData

extension CachedCharacter {

    // MARK: - Fetch Request

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedCharacter> {
        return NSFetchRequest<CachedCharacter>(entityName: "CachedCharacter")
    }

    // MARK: - Attributes

    @NSManaged public var characterId: Int32
    @NSManaged public var name: String
    @NSManaged public var status: String
    @NSManaged public var species: String
    @NSManaged public var type: String
    @NSManaged public var gender: String
    @NSManaged public var imageURL: String
    @NSManaged public var originName: String
    @NSManaged public var originURL: String
    @NSManaged public var locationName: String
    @NSManaged public var locationURL: String
    @NSManaged public var characterURL: String
    @NSManaged public var created: String
    @NSManaged public var episodesData: Data?
    @NSManaged public var page: Int32
    @NSManaged public var cachedAt: Date
}

// MARK: - Character → CachedCharacter (upsert population)

extension CachedCharacter {

    /// Rellena/actualiza esta entidad con datos de un Character de dominio.
    func populate(from character: Character, page: Int) {
        characterId  = Int32(character.id)
        name         = character.name
        status       = character.status.rawValue
        species      = character.species
        type         = character.type
        gender       = character.gender.rawValue
        imageURL     = character.image
        originName   = character.origin.name
        originURL    = character.origin.url
        locationName = character.location.name
        locationURL  = character.location.url
        characterURL = character.url
        created      = character.created
        self.page    = Int32(page)
        cachedAt     = Date()
        episodesData = try? JSONEncoder().encode(character.episode)
    }
}

// MARK: - CachedCharacter → Character

extension CachedCharacter {

    /// Convierte esta entidad CoreData al modelo de dominio Character.
    func toCharacter() -> Character? {
        guard
            let characterStatus = CharacterStatus(rawValue: status),
            let characterGender = CharacterGender(rawValue: gender)
        else { return nil }

        var episodes: [String] = []
        if let data = episodesData {
            episodes = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        return Character(
            id:       Int(characterId),
            name:     name,
            status:   characterStatus,
            species:  species,
            type:     type,
            gender:   characterGender,
            origin:   CharacterLocation(name: originName, url: originURL),
            location: CharacterLocation(name: locationName, url: locationURL),
            image:    imageURL,
            episode:  episodes,
            url:      characterURL,
            created:  created
        )
    }
}
