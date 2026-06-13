// SergioGuzmanPruebaTests/ViewModels/DetailViewModelTests.swift

import XCTest
import Combine
@testable import SergioGuzmanPrueba

final class DetailViewModelTests: XCTestCase {

    private var sut: DetailViewModel!
    private var favoriteRepo: FavoriteRepository!
    private var viewedEpisodeRepo: ViewedEpisodeRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        let persistence = PersistenceController(inMemory: true)
        favoriteRepo = FavoriteRepository(persistenceController: persistence)
        viewedEpisodeRepo = ViewedEpisodeRepository(persistenceController: persistence)

        let apiClient = APIClient(session: TestSessionFactory.makeMockedSession())
        let episodeService = EpisodeService(apiClient: apiClient)

        sut = DetailViewModel(
            character: JSONFixtures.sampleCharacter,
            favoriteRepository: favoriteRepo,
            viewedEpisodeRepository: viewedEpisodeRepo,
            episodeService: episodeService
        )
    }

    override func tearDown() {
        sut = nil
        favoriteRepo = nil
        viewedEpisodeRepo = nil
        cancellables.removeAll()
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Favorite Tests

    func testInit_isFavorite_falseWhenNotSaved() {
        XCTAssertFalse(sut.isFavorite)
    }

    func testInit_isFavorite_trueWhenAlreadySaved() {
        // Pre-save the character as favorite
        favoriteRepo.save(character: JSONFixtures.sampleCharacter)

        // Recreate ViewModel to test init state
        let apiClient = APIClient(session: TestSessionFactory.makeMockedSession())
        let episodeService = EpisodeService(apiClient: apiClient)
        let newSut = DetailViewModel(
            character: JSONFixtures.sampleCharacter,
            favoriteRepository: favoriteRepo,
            viewedEpisodeRepository: viewedEpisodeRepo,
            episodeService: episodeService
        )

        XCTAssertTrue(newSut.isFavorite)
    }

    func testToggleFavorite_turnsOn() {
        sut.toggleFavorite()
        XCTAssertTrue(sut.isFavorite)
        XCTAssertTrue(favoriteRepo.isFavorite(characterId: 1))
    }

    func testToggleFavorite_turnsOff() {
        sut.toggleFavorite() // on
        sut.toggleFavorite() // off
        XCTAssertFalse(sut.isFavorite)
        XCTAssertFalse(favoriteRepo.isFavorite(characterId: 1))
    }

    // MARK: - Episodes Tests

    func testViewDidLoad_loadsEpisodesFromAPI() {
        // Arrange
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/episode/1,2")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.episodesArray)
        }

        let expectation = XCTestExpectation(description: "Episodes loaded")
        sut.$episodes
            .dropFirst()
            .sink { episodes in
                if !episodes.isEmpty { expectation.fulfill() }
            }
            .store(in: &cancellables)

        // Act
        sut.viewDidLoad()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(sut.episodes.count, 2)
        XCTAssertEqual(sut.episodes.first?.name, "Pilot")
    }

    func testViewDidLoad_episodeServiceError_doesNotCrash() {
        // Arrange: simulate network error
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/episode/1,2")!,
                statusCode: 500, httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        let expectation = XCTestExpectation(description: "Loading finishes")
        sut.$isLoadingEpisodes
            .dropFirst() // skip initial false
            .dropFirst() // skip true
            .sink { isLoading in
                if !isLoading { expectation.fulfill() }
            }
            .store(in: &cancellables)

        // Act
        sut.viewDidLoad()

        // Assert: no crash, episodes remain empty
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(sut.episodes.isEmpty)
    }

    // MARK: - Viewed Episodes Tests

    func testToggleViewed_marksEpisodeAsViewed() {
        // First load episodes
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/episode/1,2")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.episodesArray)
        }

        let loadExpectation = XCTestExpectation(description: "Episodes loaded")
        sut.$episodes
            .dropFirst()
            .sink { episodes in
                if !episodes.isEmpty { loadExpectation.fulfill() }
            }
            .store(in: &cancellables)

        sut.viewDidLoad()
        wait(for: [loadExpectation], timeout: 2.0)

        // Act: toggle first episode
        sut.toggleViewed(at: 0)

        // Assert
        XCTAssertTrue(sut.viewedEpisodeIds.contains(1))
        XCTAssertTrue(sut.isEpisodeViewed(at: 0))
    }

    func testToggleViewed_unmarksEpisode() {
        // Load episodes
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/episode/1,2")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.episodesArray)
        }

        let loadExpectation = XCTestExpectation(description: "Episodes loaded")
        sut.$episodes.dropFirst().sink { eps in
            if !eps.isEmpty { loadExpectation.fulfill() }
        }.store(in: &cancellables)

        sut.viewDidLoad()
        wait(for: [loadExpectation], timeout: 2.0)

        // Mark then unmark
        sut.toggleViewed(at: 0)
        sut.toggleViewed(at: 0)

        XCTAssertFalse(sut.viewedEpisodeIds.contains(1))
        XCTAssertFalse(sut.isEpisodeViewed(at: 0))
    }

    // MARK: - Navigation

    func testViewOnMapTapped_invokesCallback() {
        var receivedLocation: CharacterLocation?
        sut.onViewOnMap = { location in
            receivedLocation = location
        }

        sut.viewOnMapTapped()

        XCTAssertEqual(receivedLocation?.name, "Citadel of Ricks")
    }
}
