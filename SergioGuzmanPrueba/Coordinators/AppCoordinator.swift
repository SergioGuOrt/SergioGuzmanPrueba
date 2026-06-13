// Coordinators/AppCoordinator.swift
//  SergioGuzmanPrueba
//
//  Coordinator raíz de la aplicación.
//  Vive durante toda la vida del proceso.
//  Centraliza la lógica de qué flujo mostrar al arrancar
//  y gestiona transiciones globales entre flujos principales.

import UIKit
import Swinject

final class AppCoordinator: BaseCoordinator {

    // MARK: - Properties

    /// Container de inyección de dependencias.
    /// Se pasa hacia abajo a los coordinators hijos para que resuelvan sus dependencias.
    private let container: Container

    // MARK: - Init

    init(navigationController: UINavigationController, container: Container) {
        self.container = container
        super.init(navigationController: navigationController)
    }

    // MARK: - Start

    /// Punto de entrada de la navegación global.
    /// Aquí se añadirá lógica de decisión cuando existan múltiples flujos
    /// (por ejemplo: mostrar Auth si no hay sesión activa, Home si la hay).
    override func start() {
        showHome()
    }

    // MARK: - Private Flows

    private func showHome() {
        let homeCoordinator = HomeCoordinator(
            navigationController: navigationController,
            container: container
        )
        addChild(homeCoordinator)
        homeCoordinator.start()
    }
}
