// SergioGuzmanPruebaTests/Repositories/FavoriteRepositoryTests.swift

import XCTest
@testable import SergioGuzmanPrueba

final class FavoriteRepositoryTests: XCTestCase {

    private var sut: FavoriteRepository!

    override func setUp() {
        super.setUp()
        let persistence = PersistenceController(inMemory: true)
        sut = FavoriteRepository(persistenceController: persistence)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testIsFavorite_returnsFalseInitially() {
        XCTAssertFalse(sut.isFavorite(characterId: 1))
    }

    func testSave_persistsCharacter() {
        sut.save(character: JSONFixtures.sampleCharacter)
        XCTAssertTrue(sut.isFavorite(characterId: 1))
    }

    func testSave_doesNotDuplicateIfAlreadyExists() {
        sut.save(character: JSONFixtures.sampleCharacter)
        sut.save(character: JSONFixtures.sampleCharacter)
        XCTAssertEqual(sut.fetchAll().count, 1)
    }

    func testRemove_deletesCharacter() {
        sut.save(character: JSONFixtures.sampleCharacter)
        sut.remove(characterId: 1)
        XCTAssertFalse(sut.isFavorite(characterId: 1))
    }

    func testToggle_savesAndRemoves() {
        let firstToggle = sut.toggle(character: JSONFixtures.sampleCharacter)
        XCTAssertTrue(firstToggle)
        XCTAssertTrue(sut.isFavorite(characterId: 1))

        let secondToggle = sut.toggle(character: JSONFixtures.sampleCharacter)
        XCTAssertFalse(secondToggle)
        XCTAssertFalse(sut.isFavorite(characterId: 1))
    }

    func testFetchAll_returnsCharactersOrderedByDate() {
        let character2 = Character(
            id: 2, name: "Morty", status: .alive, species: "Human", type: "",
            gender: .male,
            origin: CharacterLocation(name: "Earth", url: ""),
            location: CharacterLocation(name: "Earth", url: ""),
            image: "", episode: [], url: "", created: ""
        )
        sut.save(character: JSONFixtures.sampleCharacter)
        // Small delay to ensure different savedAt timestamps
        Thread.sleep(forTimeInterval: 0.01)
        sut.save(character: character2)

        let all = sut.fetchAll()
        XCTAssertEqual(all.count, 2)
        // Most recent first
        XCTAssertEqual(all.first?.id, 2)
    }
}
