// Modules/Detail/DetailViewModel.swift
//  SergioGuzmanPrueba
//
//  ViewModel del módulo Detail.
//  Gestiona favorito (FavoriteRepository) y episodios vistos (ViewedEpisodeRepository).
//  Obtiene episodios reales desde la API (EpisodeService).
//  No importa UIKit.

import Foundation
import Combine

final class DetailViewModel {

    // MARK: - Navigation Closures

    var onViewOnMap: ((CharacterLocation) -> Void)?

    // MARK: - Output

    let character: Character

    var navigationTitle: String { character.name }
    var imageURL: URL?          { character.imageURL }
    var nameText: String        { character.name }
    var statusText: String      { character.status.displayName }
    var speciesText: String     { character.species }
    var genderText: String      { character.gender.displayName }
    var locationText: String    { character.location.name }

    @Published private(set) var isFavorite: Bool = false

    /// Episodios reales cargados desde la API.
    @Published private(set) var episodes: [Episode] = []

    /// IDs de episodios marcados como vistos para este personaje.
    @Published private(set) var viewedEpisodeIds: Set<Int> = []

    /// Estado de carga de episodios.
    @Published private(set) var isLoadingEpisodes: Bool = false

    // MARK: - Dependencies

    private let favoriteRepository: FavoriteRepository
    private let viewedEpisodeRepository: ViewedEpisodeRepository
    private let episodeService: EpisodeService

    // MARK: - Init

    init(
        character: Character,
        favoriteRepository: FavoriteRepository,
        viewedEpisodeRepository: ViewedEpisodeRepository,
        episodeService: EpisodeService
    ) {
        self.character = character
        self.favoriteRepository = favoriteRepository
        self.viewedEpisodeRepository = viewedEpisodeRepository
        self.episodeService = episodeService

        self.isFavorite = favoriteRepository.isFavorite(characterId: character.id)
        self.viewedEpisodeIds = viewedEpisodeRepository.viewedEpisodeIds(for: character.id)
    }

    // MARK: - Input

    func viewDidLoad() {
        loadEpisodes()
    }

    func toggleFavorite() {
        isFavorite = favoriteRepository.toggle(character: character)
    }

    func viewOnMapTapped() {
        onViewOnMap?(character.location)
    }

    /// Toggle visto para el episodio en la posición dada.
    func toggleViewed(at index: Int) {
        guard index < episodes.count else { return }
        let episode = episodes[index]
        let newState = viewedEpisodeRepository.toggle(
            episode: episode,
            characterId: character.id
        )
        if newState {
            viewedEpisodeIds.insert(episode.id)
        } else {
            viewedEpisodeIds.remove(episode.id)
        }
    }

    /// Retorna si un episodio en la posición dada está marcado como visto.
    func isEpisodeViewed(at index: Int) -> Bool {
        guard index < episodes.count else { return false }
        return viewedEpisodeIds.contains(episodes[index].id)
    }

    // MARK: - Private

    private func loadEpisodes() {
        guard !character.episode.isEmpty else { return }
        isLoadingEpisodes = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let fetched = try await episodeService.fetchEpisodes(
                    from: character.episode
                )
                await MainActor.run {
                    self.episodes = fetched
                    self.isLoadingEpisodes = false
                }
            } catch {
                await MainActor.run {
                    // No bloqueamos la pantalla si los episodios fallan — datos info son bonus.
                    self.isLoadingEpisodes = false
                }
            }
        }
    }
}
