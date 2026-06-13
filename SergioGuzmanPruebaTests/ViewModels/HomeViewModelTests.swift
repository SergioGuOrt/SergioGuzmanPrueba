// SergioGuzmanPruebaTests/ViewModels/HomeViewModelTests.swift

import XCTest
import Combine
@testable import SergioGuzmanPrueba

final class HomeViewModelTests: XCTestCase {

    private var sut: HomeViewModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        let apiClient = APIClient(session: TestSessionFactory.makeMockedSession())
        let characterService = CharacterService(apiClient: apiClient)
        let persistence = PersistenceController(inMemory: true)
        let cacheRepository = CharacterCacheRepository(persistenceController: persistence)
        sut = HomeViewModel(characterService: characterService, characterCacheRepository: cacheRepository)
    }

    override func tearDown() {
        sut = nil
        cancellables.removeAll()
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testViewDidLoad_fetchesFirstPage_setsLoadedState() {
        // Arrange
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/character")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.characterResponsePage1)
        }

        let expectation = XCTestExpectation(description: "Characters loaded")
        sut.$viewState
            .dropFirst() // skip .idle
            .dropFirst() // skip .loading
            .sink { state in
                if state == .loaded { expectation.fulfill() }
            }
            .store(in: &cancellables)

        // Act
        sut.viewDidLoad()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(sut.characters.count, 2)
        XCTAssertEqual(sut.characters.first?.name, "Rick Sanchez")
    }

    func testViewDidLoad_serviceError_setsEmptyState() {
        // Arrange: return 500
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/character")!,
                statusCode: 500, httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        let expectation = XCTestExpectation(description: "Empty state set")
        sut.$viewState
            .dropFirst() // skip .idle
            .dropFirst() // skip .loading
            .sink { state in
                if state == .empty { expectation.fulfill() }
            }
            .store(in: &cancellables)

        // Act
        sut.viewDidLoad()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(sut.characters.isEmpty)
    }

    func testDidSelectStatus_alive_triggersNewFetch() {
        // Arrange
        var requestURLs: [URL] = []
        MockURLProtocol.requestHandler = { request in
            requestURLs.append(request.url!)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.characterResponsePage1)
        }

        let expectation = XCTestExpectation(description: "Filter applied")
        sut.$viewState
            .dropFirst(2) // skip initial idle + loading
            .sink { state in
                if state == .loaded { expectation.fulfill() }
            }
            .store(in: &cancellables)

        // Act
        sut.didSelectStatus(.alive)

        // Assert
        wait(for: [expectation], timeout: 2.0)
        let url = requestURLs.last!.absoluteString
        XCTAssertTrue(url.contains("status=alive"), "URL should contain status=alive, got: \(url)")
    }

    func testDidSelectSpecies_alien_triggersNewFetch() {
        // Arrange
        var requestURLs: [URL] = []
        MockURLProtocol.requestHandler = { request in
            requestURLs.append(request.url!)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.characterResponsePage1)
        }

        let expectation = XCTestExpectation(description: "Species filter applied")
        sut.$viewState
            .dropFirst(2)
            .sink { state in
                if state == .loaded { expectation.fulfill() }
            }
            .store(in: &cancellables)

        // Act
        sut.didSelectSpecies(.alien)

        // Assert
        wait(for: [expectation], timeout: 2.0)
        let url = requestURLs.last!.absoluteString
        XCTAssertTrue(url.contains("species=alien"), "URL should contain species=alien, got: \(url)")
    }

    func testDidScrollToBottom_noNextPage_doesNotFetch() {
        // Arrange: load last page (next = null)
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/character")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.characterResponseLastPage)
        }

        let loadExpectation = XCTestExpectation(description: "First load done")
        sut.$viewState
            .dropFirst(2)
            .sink { state in
                if state == .loaded { loadExpectation.fulfill() }
            }
            .store(in: &cancellables)

        sut.viewDidLoad()
        wait(for: [loadExpectation], timeout: 2.0)

        // Act: try scrolling to bottom — should NOT trigger fetch
        var fetchCount = 0
        MockURLProtocol.requestHandler = { _ in
            fetchCount += 1
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/character")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.characterResponsePage1)
        }

        sut.didScrollToBottom()

        // Small delay to ensure no async fetch fires
        let noFetchExpectation = XCTestExpectation(description: "No fetch triggered")
        noFetchExpectation.isInverted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if fetchCount > 0 { noFetchExpectation.fulfill() }
        }
        wait(for: [noFetchExpectation], timeout: 1.0)
        XCTAssertEqual(fetchCount, 0)
    }

    func testDidScrollToBottom_withNextPage_loadsPagination() {
        // Arrange: first load with next page
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/character")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.characterResponsePage1)
        }

        let loadExpectation = XCTestExpectation(description: "Page 1 loaded")
        sut.$viewState
            .dropFirst(2)
            .sink { state in
                if state == .loaded { loadExpectation.fulfill() }
            }
            .store(in: &cancellables)

        sut.viewDidLoad()
        wait(for: [loadExpectation], timeout: 2.0)
        XCTAssertEqual(sut.characters.count, 2)

        // Setup page 2 response
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://rickandmortyapi.com/api/character?page=2")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, JSONFixtures.characterResponseLastPage)
        }

        let page2Expectation = XCTestExpectation(description: "Page 2 loaded")
        sut.$characters
            .dropFirst() // skip current
            .sink { chars in
                if chars.count == 3 { page2Expectation.fulfill() }
            }
            .store(in: &cancellables)

        // Act
        sut.didScrollToBottom()

        // Assert
        wait(for: [page2Expectation], timeout: 2.0)
        XCTAssertEqual(sut.characters.count, 3)
    }

    func testNavigationClosure_didSelectCharacter_invokesCallback() {
        var selectedCharacter: Character?
        sut.onCharacterSelected = { character in
            selectedCharacter = character
        }

        sut.didSelectCharacter(JSONFixtures.sampleCharacter)

        XCTAssertEqual(selectedCharacter?.id, 1)
        XCTAssertEqual(selectedCharacter?.name, "Rick Sanchez")
    }

    func testNavigationClosure_didTapFavorites_invokesCallback() {
        var called = false
        sut.onFavoritesTapped = {
            called = true
        }

        sut.didTapFavorites()

        XCTAssertTrue(called)
    }
}
