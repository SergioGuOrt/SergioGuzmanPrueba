// Modules/Favorites/FavoritesCoordinator.swift
//  SergioGuzmanPrueba
//
//  Coordinator del módulo Favorites.
//  Instancia FavoritesViewController desde Favorites.storyboard.
//  Al seleccionar un favorito, lanza DetailCoordinator.

import UIKit
import Swinject

final class FavoritesCoordinator: BaseCoordinator {

    // MARK: - Properties

    private let container: Container

    // MARK: - Init

    init(navigationController: UINavigationController, container: Container) {
        self.container = container
        super.init(navigationController: navigationController)
    }

    // MARK: - Start

    override func start() {
        guard let viewModel = container.resolve(FavoritesViewModel.self) else {
            assertionFailure("FavoritesViewModel not registered in DI container.")
            return
        }

        viewModel.onCharacterSelected = { [weak self] character in
            self?.showDetail(for: character)
        }

        let viewController = FavoritesViewController.instantiate()
        viewController.configure(with: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Navigation

    private func showDetail(for character: Character) {
        let detailCoordinator = DetailCoordinator(
            navigationController: navigationController,
            container: container,
            character: character
        )
        addChild(detailCoordinator)
        detailCoordinator.start()
    }
}
