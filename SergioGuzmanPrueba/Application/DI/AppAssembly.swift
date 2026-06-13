// Application/DI/AppAssembly.swift
//  SergioGuzmanPrueba
//
//  Registra todas las dependencias del proyecto en el container Swinject.
//  Único lugar donde se declaran scopes y relaciones entre objetos.
//
//  Scopes:
//    .container  → Una instancia durante toda la vida de la app.
//    .transient  → Nueva instancia por cada resolución (ViewModels).

import Swinject

final class AppAssembly: Assembly {

    func assemble(container: Container) {

        // MARK: - Infrastructure

        container.register(PersistenceController.self) { _ in
            PersistenceController()
        }.inObjectScope(.container)

        container.register(APIClient.self) { _ in
            APIClient()
        }.inObjectScope(.container)

        // MARK: - Services / Repositories

        container.register(CharacterService.self) { resolver in
            CharacterService(
                apiClient: resolver.resolve(APIClient.self)!
            )
        }.inObjectScope(.container)

        container.register(FavoriteRepository.self) { resolver in
            FavoriteRepository(
                persistenceController: resolver.resolve(PersistenceController.self)!
            )
        }.inObjectScope(.container)

        container.register(EpisodeService.self) { resolver in
            EpisodeService(
                apiClient: resolver.resolve(APIClient.self)!
            )
        }.inObjectScope(.container)

        container.register(ViewedEpisodeRepository.self) { resolver in
            ViewedEpisodeRepository(
                persistenceController: resolver.resolve(PersistenceController.self)!
            )
        }.inObjectScope(.container)

        container.register(BiometricAuthService.self) { _ in
            BiometricAuthService()
        }.inObjectScope(.container)

        container.register(CharacterCacheRepository.self) { resolver in
            CharacterCacheRepository(
                persistenceController: resolver.resolve(PersistenceController.self)!
            )
        }.inObjectScope(.container)

        // MARK: - ViewModels

        container.register(HomeViewModel.self) { resolver in
            HomeViewModel(
                characterService: resolver.resolve(CharacterService.self)!,
                characterCacheRepository: resolver.resolve(CharacterCacheRepository.self)!
            )
        }.inObjectScope(.transient)

        container.register(FavoritesViewModel.self) { resolver in
            FavoritesViewModel(
                favoriteRepository: resolver.resolve(FavoriteRepository.self)!
            )
        }.inObjectScope(.transient)
    }
}
