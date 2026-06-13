// Services/Persistence/ViewedEpisodeRepository.swift
//  SergioGuzmanPrueba
//
//  Responsabilidad única: CRUD de episodios vistos en CoreData.
//  Recibe PersistenceController por inyección.
//  API síncrona sobre viewContext (hilo principal).

import CoreData
import os

final class ViewedEpisodeRepository {

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

    /// Retorna el conjunto de IDs de episodios vistos para un personaje.
    func viewedEpisodeIds(for characterId: Int) -> Set<Int> {
        let request = ViewedEpisode.fetchRequest()
        request.predicate = NSPredicate(
            format: "characterId == %d AND isViewed == YES", characterId
        )
        let entities = (try? context.fetch(request)) ?? []
        return Set(entities.map { Int($0.episodeId) })
    }

    /// Retorna true si el episodio específico ya fue visto.
    func isViewed(episodeId: Int, characterId: Int) -> Bool {
        return fetchEntity(episodeId: episodeId, characterId: characterId) != nil
    }

    // MARK: - Write

    /// Marca un episodio como visto. Si ya existe, no hace nada.
    func markAsViewed(episode: Episode, characterId: Int) {
        guard !isViewed(episodeId: episode.id, characterId: characterId) else { return }

        let entity = ViewedEpisode(context: context)
        entity.characterId = Int32(characterId)
        entity.episodeId   = Int32(episode.id)
        entity.episodeName = episode.name
        entity.episodeCode = episode.episode
        entity.isViewed    = true
        entity.viewedAt    = Date()

        persistenceController.save()
        AppLogger.persistence.info("Episode marked as viewed: episodeId=\(episode.id) characterId=\(characterId)")
    }

    /// Elimina el registro de visto para un episodio.
    func markAsNotViewed(episodeId: Int, characterId: Int) {
        guard let entity = fetchEntity(episodeId: episodeId, characterId: characterId) else { return }
        context.delete(entity)
        persistenceController.save()
        AppLogger.persistence.info("Episode unmarked as viewed: episodeId=\(episodeId) characterId=\(characterId)")
    }

    /// Toggle: marca como visto si no lo estaba, o elimina si ya lo estaba.
    /// - Returns: Nuevo estado (true = visto).
    @discardableResult
    func toggle(episode: Episode, characterId: Int) -> Bool {
        if isViewed(episodeId: episode.id, characterId: characterId) {
            markAsNotViewed(episodeId: episode.id, characterId: characterId)
            return false
        } else {
            markAsViewed(episode: episode, characterId: characterId)
            return true
        }
    }

    // MARK: - Private

    private func fetchEntity(episodeId: Int, characterId: Int) -> ViewedEpisode? {
        let request = ViewedEpisode.fetchRequest()
        request.predicate = NSPredicate(
            format: "episodeId == %d AND characterId == %d", episodeId, characterId
        )
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
