// Services/Persistence/FavoriteRepository.swift
//  SergioGuzmanPrueba
//
//  Responsabilidad única: CRUD de favoritos en CoreData.
//  Recibe PersistenceController por inyección.
//  Expone una API síncrona limpia sobre el viewContext (hilo principal).
//  No conoce UIKit ni ViewModels.

import CoreData
import os

final class FavoriteRepository {

    // MARK: - Dependencies

    private let persistenceController: PersistenceController

    private var context: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Init

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    // MARK: - Read

    /// Retorna true si el personaje con ese id está guardado como favorito.
    func isFavorite(characterId: Int) -> Bool {
        return fetchEntity(characterId: characterId) != nil
    }

    /// Retorna todos los personajes favoritos ordenados por fecha de guardado (más reciente primero).
    func fetchAll() -> [Character] {
        let request = FavoriteCharacter.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]

        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toCharacter() }
        } catch {
            AppLogger.persistence.error("Favorite fetchAll failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Write

    /// Guarda un personaje como favorito. Si ya existe, no hace nada.
    func save(character: Character) {
        guard !isFavorite(characterId: character.id) else { return }

        let entity = FavoriteCharacter(context: context)
        entity.populate(from: character, context: context)
        persistenceController.save()
        AppLogger.persistence.info("Favorite saved: id=\(character.id) name=\(character.name)")
    }

    /// Elimina un personaje de favoritos. Si no existe, no hace nada.
    func remove(characterId: Int) {
        guard let entity = fetchEntity(characterId: characterId) else { return }
        context.delete(entity)
        persistenceController.save()
        AppLogger.persistence.info("Favorite removed: id=\(characterId)")
    }

    /// Toggle: guarda si no existe, elimina si ya existe.
    /// - Returns: El nuevo estado de favorito (true = guardado).
    @discardableResult
    func toggle(character: Character) -> Bool {
        if isFavorite(characterId: character.id) {
            remove(characterId: character.id)
            return false
        } else {
            save(character: character)
            return true
        }
    }

    // MARK: - Private

    private func fetchEntity(characterId: Int) -> FavoriteCharacter? {
        let request = FavoriteCharacter.fetchRequest()
        request.predicate = NSPredicate(format: "characterId == %d", characterId)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
