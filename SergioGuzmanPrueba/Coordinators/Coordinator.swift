// Coordinators/Coordinator.swift
//  SergioGuzmanPrueba
//
//  Contrato base que todo Coordinator debe cumplir.
//  Define las propiedades y métodos mínimos necesarios para gestionar navegación.

import UIKit

protocol Coordinator: AnyObject {

    /// Navigation controller que este coordinator gestiona.
    var navigationController: UINavigationController { get set }

    /// Coordinators hijos activos. Mantenerlos evita que sean deallocados prematuramente.
    var childCoordinators: [Coordinator] { get set }

    /// Inicia el flujo de navegación del coordinator.
    /// Cada implementación decide qué pantalla mostrar primero.
    func start()
}
