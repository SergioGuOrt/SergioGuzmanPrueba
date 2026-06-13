// SergioGuzmanPruebaTests/Repositories/ViewedEpisodeRepositoryTests.swift

import XCTest
@testable import SergioGuzmanPrueba

final class ViewedEpisodeRepositoryTests: XCTestCase {

    private var sut: ViewedEpisodeRepository!

    override func setUp() {
        super.setUp()
        let persistence = PersistenceController(inMemory: true)
        sut = ViewedEpisodeRepository(persistenceController: persistence)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testIsViewed_returnsFalseInitially() {
        XCTAssertFalse(sut.isViewed(episodeId: 1, characterId: 1))
    }

    func testMarkAsViewed_persists() {
        sut.markAsViewed(episode: JSONFixtures.sampleEpisode, characterId: 1)
        XCTAssertTrue(sut.isViewed(episodeId: 1, characterId: 1))
    }

    func testMarkAsNotViewed_deletes() {
        sut.markAsViewed(episode: JSONFixtures.sampleEpisode, characterId: 1)
        sut.markAsNotViewed(episodeId: 1, characterId: 1)
        XCTAssertFalse(sut.isViewed(episodeId: 1, characterId: 1))
    }

    func testToggle_marksAndUnmarks() {
        let first = sut.toggle(episode: JSONFixtures.sampleEpisode, characterId: 1)
        XCTAssertTrue(first)

        let second = sut.toggle(episode: JSONFixtures.sampleEpisode, characterId: 1)
        XCTAssertFalse(second)
    }

    func testViewedEpisodeIds_returnsCorrectSet() {
        let episode2 = Episode(
            id: 2, name: "Lawnmower Dog", airDate: "Dec 9, 2013",
            episode: "S01E02", characters: [], url: "", created: ""
        )
        sut.markAsViewed(episode: JSONFixtures.sampleEpisode, characterId: 1)
        sut.markAsViewed(episode: episode2, characterId: 1)

        let ids = sut.viewedEpisodeIds(for: 1)
        XCTAssertEqual(ids, Set([1, 2]))
    }

    func testViewedEpisodeIds_isolatedPerCharacter() {
        sut.markAsViewed(episode: JSONFixtures.sampleEpisode, characterId: 1)

        let idsForCharacter2 = sut.viewedEpisodeIds(for: 2)
        XCTAssertTrue(idsForCharacter2.isEmpty)
    }
}
