// Coordinators/BaseCoordinator.swift
//  SergioGuzmanPrueba
//
//  Clase base para todos los coordinators del proyecto.
//  Gestiona el ciclo de vida de coordinators hijos para evitar retain cycles
//  y referencias colgantes cuando un flujo termina.

import UIKit

class BaseCoordinator: Coordinator {

    // MARK: - Coordinator

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    // MARK: - Init

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Coordinator Protocol

    /// Las subclases deben sobreescribir este método para iniciar su flujo.
    func start() {
        fatalError("Subclasses must override start()")
    }

    // MARK: - Child Lifecycle

    /// Añade un coordinator hijo y retiene su referencia en memoria.
    /// Debe llamarse antes de invocar start() en el coordinator hijo.
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    /// Elimina un coordinator hijo cuando su flujo finaliza.
    /// Libera la referencia fuerte para permitir su deallocación.
    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}
