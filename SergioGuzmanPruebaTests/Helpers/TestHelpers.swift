// SergioGuzmanPruebaTests/Helpers/TestHelpers.swift
//
//  Factories and utilities for unit tests.
//  Creates real instances of services configured with mocked URLSession and in-memory CoreData.
//  No production code is modified.

import Foundation
@testable import SergioGuzmanPrueba

// MARK: - Mocked URLSession Factory

enum TestSessionFactory {

    /// Creates a URLSession that routes all traffic through MockURLProtocol.
    static func makeMockedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

// MARK: - Service Factories (use real classes, mocked network)

enum TestServiceFactory {

    static func makeAPIClient() -> APIClient {
        APIClient(session: TestSessionFactory.makeMockedSession())
    }

    static func makeCharacterService() -> CharacterService {
        CharacterService(apiClient: makeAPIClient())
    }

    static func makeEpisodeService() -> EpisodeService {
        EpisodeService(apiClient: makeAPIClient())
    }

    static func makePersistenceController() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    static func makeFavoriteRepository() -> FavoriteRepository {
        FavoriteRepository(persistenceController: makePersistenceController())
    }

    static func makeViewedEpisodeRepository() -> ViewedEpisodeRepository {
        ViewedEpisodeRepository(persistenceController: makePersistenceController())
    }
}

// MARK: - JSON Fixtures

enum JSONFixtures {

    /// A valid CharacterResponse with 2 characters and a next page.
    static let characterResponsePage1: Data = {
        let json = """
        {
            "info": { "count": 826, "pages": 42, "next": "https://rickandmortyapi.com/api/character/?page=2", "prev": null },
            "results": [
                {
                    "id": 1, "name": "Rick Sanchez", "status": "Alive", "species": "Human", "type": "",
                    "gender": "Male",
                    "origin": { "name": "Earth (C-137)", "url": "https://rickandmortyapi.com/api/location/1" },
                    "location": { "name": "Citadel of Ricks", "url": "https://rickandmortyapi.com/api/location/3" },
                    "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
                    "episode": ["https://rickandmortyapi.com/api/episode/1"],
                    "url": "https://rickandmortyapi.com/api/character/1",
                    "created": "2017-11-04T18:48:46.250Z"
                },
                {
                    "id": 2, "name": "Morty Smith", "status": "Alive", "species": "Human", "type": "",
                    "gender": "Male",
                    "origin": { "name": "unknown", "url": "" },
                    "location": { "name": "Citadel of Ricks", "url": "https://rickandmortyapi.com/api/location/3" },
                    "image": "https://rickandmortyapi.com/api/character/avatar/2.jpeg",
                    "episode": ["https://rickandmortyapi.com/api/episode/1", "https://rickandmortyapi.com/api/episode/2"],
                    "url": "https://rickandmortyapi.com/api/character/2",
                    "created": "2017-11-04T18:50:21.651Z"
                }
            ]
        }
        """
        return Data(json.utf8)
    }()

    /// A valid CharacterResponse with 1 character and NO next page (last page).
    static let characterResponseLastPage: Data = {
        let json = """
        {
            "info": { "count": 826, "pages": 42, "next": null, "prev": "https://rickandmortyapi.com/api/character/?page=41" },
            "results": [
                {
                    "id": 826, "name": "Butter Robot", "status": "Alive", "species": "Robot", "type": "",
                    "gender": "unknown",
                    "origin": { "name": "Earth (C-137)", "url": "https://rickandmortyapi.com/api/location/1" },
                    "location": { "name": "Earth (C-137)", "url": "https://rickandmortyapi.com/api/location/1" },
                    "image": "https://rickandmortyapi.com/api/character/avatar/826.jpeg",
                    "episode": ["https://rickandmortyapi.com/api/episode/9"],
                    "url": "https://rickandmortyapi.com/api/character/826",
                    "created": "2021-11-20T14:28:00.000Z"
                }
            ]
        }
        """
        return Data(json.utf8)
    }()

    /// Empty results (API returns 404 for no matches but we simulate empty for tests).
    static let characterResponseEmpty: Data = {
        let json = """
        { "info": { "count": 0, "pages": 0, "next": null, "prev": null }, "results": [] }
        """
        return Data(json.utf8)
    }()

    /// A valid array of episodes (multiple IDs response).
    static let episodesArray: Data = {
        let json = """
        [
            { "id": 1, "name": "Pilot", "air_date": "December 2, 2013", "episode": "S01E01",
              "characters": [], "url": "https://rickandmortyapi.com/api/episode/1", "created": "2017-11-10T12:56:33.798Z" },
            { "id": 2, "name": "Lawnmower Dog", "air_date": "December 9, 2013", "episode": "S01E02",
              "characters": [], "url": "https://rickandmortyapi.com/api/episode/2", "created": "2017-11-10T12:56:33.916Z" }
        ]
        """
        return Data(json.utf8)
    }()

    // MARK: - Sample Models

    static let sampleCharacter = Character(
        id: 1,
        name: "Rick Sanchez",
        status: .alive,
        species: "Human",
        type: "",
        gender: .male,
        origin: CharacterLocation(name: "Earth (C-137)", url: "https://rickandmortyapi.com/api/location/1"),
        location: CharacterLocation(name: "Citadel of Ricks", url: "https://rickandmortyapi.com/api/location/3"),
        image: "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
        episode: ["https://rickandmortyapi.com/api/episode/1", "https://rickandmortyapi.com/api/episode/2"],
        url: "https://rickandmortyapi.com/api/character/1",
        created: "2017-11-04T18:48:46.250Z"
    )

    static let sampleEpisode = Episode(
        id: 1,
        name: "Pilot",
        airDate: "December 2, 2013",
        episode: "S01E01",
        characters: [],
        url: "https://rickandmortyapi.com/api/episode/1",
        created: "2017-11-10T12:56:33.798Z"
    )
}
