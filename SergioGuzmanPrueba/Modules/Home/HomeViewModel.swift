// Modules/Home/HomeViewModel.swift
//  SergioGuzmanPrueba
//
//  ViewModel del módulo Home.
//  Gestiona: listado, paginación, búsqueda por nombre, filtros por estado y especie.
//  Protección contra 429: cancelación de tasks en vuelo, debounce en búsqueda,
//  supresión de errores rate-limit durante paginación.

import Foundation
import Combine

// MARK: - Filter Options

enum StatusFilter: Int, CaseIterable {
    case all = 0
    case alive
    case dead
    case unknown

    var displayName: String {
        switch self {
        case .all:     return String(localized: "filter.status.all",     defaultValue: "All")
        case .alive:   return String(localized: "filter.status.alive",   defaultValue: "Alive")
        case .dead:    return String(localized: "filter.status.dead",    defaultValue: "Dead")
        case .unknown: return String(localized: "filter.status.unknown", defaultValue: "Unknown")
        }
    }

    var apiValue: String? {
        switch self {
        case .all:     return nil
        case .alive:   return "alive"
        case .dead:    return "dead"
        case .unknown: return "unknown"
        }
    }
}

enum SpeciesFilter: Int, CaseIterable {
    case all = 0
    case human
    case alien

    var displayName: String {
        switch self {
        case .all:   return String(localized: "filter.species.all",   defaultValue: "All")
        case .human: return String(localized: "filter.species.human", defaultValue: "Human")
        case .alien: return String(localized: "filter.species.alien", defaultValue: "Alien")
        }
    }

    var apiValue: String? {
        switch self {
        case .all:   return nil
        case .human: return "human"
        case .alien: return "alien"
        }
    }
}

// MARK: - HomeViewModel

final class HomeViewModel {

    // MARK: - Navigation Closures

    var onCharacterSelected: ((Character) -> Void)?
    var onFavoritesTapped: (() -> Void)?

    // MARK: - Output

    @Published private(set) var characters: [Character] = []
    @Published private(set) var viewState: HomeViewState = .idle

    // MARK: - Filter State

    @Published private(set) var currentStatusFilter: StatusFilter = .all
    @Published private(set) var currentSpeciesFilter: SpeciesFilter = .all

    // MARK: - Private State

    private let characterService: CharacterService
    private let characterCacheRepository: CharacterCacheRepository

    private var currentPage: Int = 1
    private var hasNextPage: Bool = true
    private var isFetching: Bool = false
    private var currentSearchQuery: String = ""

    /// Task actualmente en vuelo — se cancela antes de lanzar una nueva.
    private var currentFetchTask: Task<Void, Never>?

    /// Debounce para búsqueda por nombre (evita requests por cada keystroke).
    private var searchDebounceTask: Task<Void, Never>?
    private let searchDebounceInterval: UInt64 = 300_000_000  // 300ms en nanosegundos

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(characterService: CharacterService, characterCacheRepository: CharacterCacheRepository) {
        self.characterService = characterService
        self.characterCacheRepository = characterCacheRepository
    }

    // MARK: - Input

    func viewDidLoad() {
        loadFirstPage()
    }

    func didPullToRefresh() {
        cancelCurrentFetch()
        resetPagination()
        loadFirstPage()
    }

    func didScrollToBottom() {
        guard hasNextPage, !isFetching else { return }
        fetchCharacters(page: currentPage)
    }

    func didSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed != currentSearchQuery else { return }
        currentSearchQuery = trimmed

        // Debounce: cancelar búsqueda anterior y esperar 300ms.
        searchDebounceTask?.cancel()
        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.searchDebounceInterval ?? 300_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.cancelCurrentFetch()
                self?.resetPagination()
                self?.loadFirstPage()
            }
        }
    }

    func didCancelSearch() {
        searchDebounceTask?.cancel()
        guard !currentSearchQuery.isEmpty else { return }
        currentSearchQuery = ""
        cancelCurrentFetch()
        resetPagination()
        loadFirstPage()
    }

    func didSelectCharacter(_ character: Character) {
        onCharacterSelected?(character)
    }

    func didTapFavorites() {
        onFavoritesTapped?()
    }

    // MARK: - Filter Input

    func didSelectStatus(_ filter: StatusFilter) {
        guard filter != currentStatusFilter else { return }
        currentStatusFilter = filter
        cancelCurrentFetch()
        resetPagination()
        loadFirstPage()
    }

    func didSelectSpecies(_ filter: SpeciesFilter) {
        guard filter != currentSpeciesFilter else { return }
        currentSpeciesFilter = filter
        cancelCurrentFetch()
        resetPagination()
        loadFirstPage()
    }

    // MARK: - Private

    private func loadFirstPage() {
        fetchCharacters(page: 1)
    }

    private func cancelCurrentFetch() {
        currentFetchTask?.cancel()
        currentFetchTask = nil
        isFetching = false
    }

    private func fetchCharacters(page: Int) {
        // Protección estricta contra requests duplicados.
        guard !isFetching else { return }
        isFetching = true

        if page == 1 {
            viewState = .loading
        }

        let query   = currentSearchQuery.isEmpty ? nil : currentSearchQuery
        let status  = currentStatusFilter.apiValue
        let species = currentSpeciesFilter.apiValue

        // Cancelar cualquier fetch previo que esté en vuelo (previene requests obsoletos).
        currentFetchTask?.cancel()

        currentFetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await characterService.fetchCharacters(
                    page: page,
                    name: query,
                    status: status,
                    species: species
                )

                // Verificar que no fue cancelado durante la espera.
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    // Guardar en caché local (upsert por characterId).
                    // Debe ejecutarse en main thread porque viewContext es main queue.
                    self.characterCacheRepository.upsert(characters: response.results, page: page)

                    if page == 1 {
                        self.characters = response.results
                    } else {
                        self.characters.append(contentsOf: response.results)
                    }
                    self.currentPage = page + 1
                    self.hasNextPage = response.info.next != nil
                    self.isFetching = false
                    self.viewState = self.characters.isEmpty ? .empty : .loaded
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.isFetching = false

                    // Suprimir errores 429 durante paginación.
                    if self.isRateLimitError(error) {
                        if page == 1 {
                            self.viewState = self.characters.isEmpty ? .empty : .loaded
                        }
                        return
                    }

                    // Fallback a caché local cuando la red falla.
                    if page == 1 {
                        let cached = self.characterCacheRepository.fetchCached(
                            name: query,
                            status: status,
                            species: species
                        )
                        if !cached.isEmpty {
                            self.characters = cached
                            self.hasNextPage = false // No hay paginación offline
                            self.viewState = .loaded
                            AppLogger.network.info("Showing cached characters: \(cached.count) results")
                            return
                        }
                    }

                    if self.characters.isEmpty {
                        self.viewState = .empty
                    } else {
                        self.viewState = .paginationError(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func resetPagination() {
        currentPage = 1
        hasNextPage = true
        isFetching = false
        characters = []
    }

    /// Detecta si el error es un 429 Too Many Requests.
    private func isRateLimitError(_ error: Error) -> Bool {
        if case NetworkError.serverError(let statusCode) = error, statusCode == 429 {
            return true
        }
        return false
    }
}

// MARK: - HomeViewState

enum HomeViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
    case paginationError(String)
}
