// Services/Persistence/FavoriteCharacter+CoreDataProperties.swift
//  SergioGuzmanPrueba
//
//  Propiedades de la entidad FavoriteCharacter.
//  Refleja exactamente los atributos del modelo .xcdatamodel.
//  También incluye el mapping Character ↔ FavoriteCharacter.

import Foundation
import CoreData

extension FavoriteCharacter {

    // MARK: - Fetch Request

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteCharacter> {
        return NSFetchRequest<FavoriteCharacter>(entityName: "FavoriteCharacter")
    }

    // MARK: - Attributes

    @NSManaged public var characterId: Int32
    @NSManaged public var name: String
    @NSManaged public var status: String
    @NSManaged public var species: String
    @NSManaged public var gender: String
    @NSManaged public var imageURL: String
    @NSManaged public var locationName: String
    @NSManaged public var locationURL: String
    @NSManaged public var originName: String
    @NSManaged public var originURL: String
    @NSManaged public var type: String
    @NSManaged public var characterURL: String
    @NSManaged public var created: String
    @NSManaged public var episodesData: Data?
    @NSManaged public var savedAt: Date
}

// MARK: - Character → FavoriteCharacter (mapper)

extension FavoriteCharacter {

    /// Rellena esta entidad CoreData con los datos de un Character de dominio.
    func populate(from character: Character, context: NSManagedObjectContext) {
        characterId   = Int32(character.id)
        name          = character.name
        status        = character.status.rawValue
        species       = character.species
        gender        = character.gender.rawValue
        imageURL      = character.image
        locationName  = character.location.name
        locationURL   = character.location.url
        originName    = character.origin.name
        originURL     = character.origin.url
        type          = character.type
        characterURL  = character.url
        created       = character.created
        savedAt       = Date()

        // Serializar el array de URLs de episodios como Data (JSON).
        episodesData = try? JSONEncoder().encode(character.episode)
    }
}

// MARK: - FavoriteCharacter → Character (mapper)

extension FavoriteCharacter {

    /// Convierte esta entidad CoreData al modelo de dominio Character.
    /// Retorna nil si algún enum no puede reconstruirse desde el valor guardado.
    func toCharacter() -> Character? {
        guard
            let status = CharacterStatus(rawValue: status),
            let gender = CharacterGender(rawValue: gender)
        else { return nil }

        var episodes: [String] = []
        if let data = episodesData {
            episodes = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        return Character(
            id:       Int(characterId),
            name:     name,
            status:   status,
            species:  species,
            type:     type,
            gender:   gender,
            origin:   CharacterLocation(name: originName,   url: originURL),
            location: CharacterLocation(name: locationName, url: locationURL),
            image:    imageURL,
            episode:  episodes,
            url:      characterURL,
            created:  created
        )
    }
}
