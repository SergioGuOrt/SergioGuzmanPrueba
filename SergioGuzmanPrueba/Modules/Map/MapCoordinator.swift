// Modules/Map/MapCoordinator.swift
//  SergioGuzmanPrueba
//
//  Coordinator del módulo Map.
//  Instancia MapViewController desde Map.storyboard.
//  Construye MapViewModel con el Character seleccionado.

import UIKit
import Swinject

final class MapCoordinator: BaseCoordinator {

    // MARK: - Properties

    private let container: Container
    private let character: Character

    // MARK: - Init

    init(navigationController: UINavigationController, container: Container, character: Character) {
        self.container = container
        self.character = character
        super.init(navigationController: navigationController)
    }

    // MARK: - Start

    override func start() {
        let viewModel = MapViewModel(character: character)

        let viewController = MapViewController.instantiate()
        viewController.configure(with: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
