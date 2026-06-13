// Services/Persistence/CharacterCacheRepository.swift
//  SergioGuzmanPrueba
//
//  Responsabilidad única: Caché local de personajes descargados de la API.
//  Usa upsert (update or insert) por characterId — nunca elimina datos existentes
//  al insertar nuevos. Solo expone operaciones de lectura y escritura.

import CoreData
import os

final class CharacterCacheRepository {

    // MARK: - Dependencies

    private let persistenceController: PersistenceController

    private var context: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Init

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    // MARK: - Write

    /// Upsert: guarda o actualiza personajes en caché.
    /// No elimina personajes existentes — solo inserta nuevos o actualiza datos de los existentes.
    /// - Parameters:
    ///   - characters: Array de personajes a cachear.
    ///   - page: Página de la API a la que pertenecen.
    func upsert(characters: [Character], page: Int) {
        for character in characters {
            if let existing = fetchEntity(characterId: character.id) {
                // Actualizar entidad existente con datos frescos.
                existing.populate(from: character, page: page)
            } else {
                // Insertar nueva entidad.
                let entity = CachedCharacter(context: context)
                entity.populate(from: character, page: page)
            }
        }
        persistenceController.save()
        AppLogger.persistence.info("Character cache upserted: \(characters.count) characters for page \(page)")
    }

    // MARK: - Read

    /// Lee personajes cacheados con filtros opcionales.
    /// Replica los filtros que la API soporta, aplicados localmente sobre CoreData.
    /// - Parameters:
    ///   - name: Filtro por nombre (CONTAINS case-insensitive). Nil ignora.
    ///   - status: Filtro por status (rawValue exacto). Nil ignora.
    ///   - species: Filtro por species (CONTAINS case-insensitive). Nil ignora.
    /// - Returns: Array de Character ordenado por characterId ascendente.
    func fetchCached(name: String? = nil, status: String? = nil, species: String? = nil) -> [Character] {
        let request = CachedCharacter.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "characterId", ascending: true)]

        var predicates: [NSPredicate] = []

        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", name))
        }
        if let status = status, !status.isEmpty {
            // La API guarda con primera letra mayúscula: "Alive", "Dead", "unknown"
            predicates.append(NSPredicate(format: "status ==[cd] %@", status))
        }
        if let species = species, !species.isEmpty {
            predicates.append(NSPredicate(format: "species CONTAINS[cd] %@", species))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toCharacter() }
        } catch {
            AppLogger.persistence.error("Character cache fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    /// Retorna true si hay al menos un personaje en caché.
    var hasCachedData: Bool {
        let request = CachedCharacter.fetchRequest()
        request.fetchLimit = 1
        return (try? context.count(for: request)) ?? 0 > 0
    }

    // MARK: - Private

    private func fetchEntity(characterId: Int) -> CachedCharacter? {
        let request = CachedCharacter.fetchRequest()
        request.predicate = NSPredicate(format: "characterId == %d", characterId)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
