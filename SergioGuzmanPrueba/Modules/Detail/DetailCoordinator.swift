// Modules/Detail/DetailCoordinator.swift
//  SergioGuzmanPrueba
//
//  Coordinator del módulo Detail.
//  Resuelve FavoriteRepository, ViewedEpisodeRepository y EpisodeService
//  del container Swinject y los inyecta en DetailViewModel.

import UIKit
import Swinject
import os

final class DetailCoordinator: BaseCoordinator {

    private let container: Container
    private let character: Character

    init(navigationController: UINavigationController, container: Container, character: Character) {
        self.container = container
        self.character = character
        super.init(navigationController: navigationController)
    }

    override func start() {
        guard
            let favoriteRepository      = container.resolve(FavoriteRepository.self),
            let viewedEpisodeRepository = container.resolve(ViewedEpisodeRepository.self),
            let episodeService          = container.resolve(EpisodeService.self)
        else {
            assertionFailure("Missing dependencies in DI container for DetailCoordinator.")
            return
        }

        let viewModel = DetailViewModel(
            character: character,
            favoriteRepository: favoriteRepository,
            viewedEpisodeRepository: viewedEpisodeRepository,
            episodeService: episodeService
        )

        viewModel.onViewOnMap = { [weak self] _ in
            self?.showMap()
        }

        let viewController = DetailViewController.instantiate()
        viewController.configure(with: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showMap() {
        AppLogger.navigation.info("Navigating to Map: \(self.character.name)")
        let mapCoordinator = MapCoordinator(
            navigationController: navigationController,
            container: container,
            character: character
        )
        addChild(mapCoordinator)
        mapCoordinator.start()
    }
}
