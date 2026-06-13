// Modules/Home/HomeCoordinator.swift
//  SergioGuzmanPrueba
//
//  Coordinator del módulo Home.
//  Responsabilidades:
//    - Instanciar HomeViewController desde Home.storyboard.
//    - Resolver HomeViewModel del container Swinject.
//    - Inyectar el ViewModel via configure(with:).
//    - Suscribir closures de navegación del ViewModel.
//    - Ejecutar push/present cuando el ViewModel señaliza una acción.

import UIKit
import Swinject
import os

final class HomeCoordinator: BaseCoordinator {

    // MARK: - Properties

    private let container: Container

    // MARK: - Init

    init(navigationController: UINavigationController, container: Container) {
        self.container = container
        super.init(navigationController: navigationController)
    }

    // MARK: - Start

    override func start() {
        guard let viewModel = container.resolve(HomeViewModel.self) else {
            assertionFailure("HomeViewModel is not registered in the DI container.")
            return
        }

        // Suscribir closures ANTES de mostrar la pantalla para no perder eventos tempranos.
        viewModel.onCharacterSelected = { [weak self] character in
            self?.showDetail(for: character)
        }

        viewModel.onFavoritesTapped = { [weak self] in
            self?.showFavorites()
        }

        let viewController = HomeViewController.instantiate()
        viewController.configure(with: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    // MARK: - Navigation

    /// Navega al detalle del personaje seleccionado.
    private func showDetail(for character: Character) {
        AppLogger.navigation.info("Navigating to Detail: \(character.name)")
        let detailCoordinator = DetailCoordinator(
            navigationController: navigationController,
            container: container,
            character: character
        )
        addChild(detailCoordinator)
        detailCoordinator.start()
    }

    /// Navega a la pantalla de favoritos tras autenticación biométrica.
    private func showFavorites() {
        guard let biometricService = container.resolve(BiometricAuthService.self) else {
            assertionFailure("BiometricAuthService not registered in DI container.")
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let authenticated = try await biometricService.authenticate()
                guard authenticated else { return }
                AppLogger.biometric.info("Biometric authentication succeeded")
                self.navigateToFavorites()
            } catch let error as BiometricError {
                AppLogger.biometric.warning("Biometric authentication failed: \(error.localizedMessage)")
                self.showBiometricAlert(message: error.localizedMessage)
            } catch {
                AppLogger.biometric.warning("Biometric authentication failed: unexpected error")
                self.showBiometricAlert(
                    message: String(localized: "biometric.error.unknown",
                                    defaultValue: "An unexpected authentication error occurred.")
                )
            }
        }
    }

    private func navigateToFavorites() {
        AppLogger.navigation.info("Navigating to Favorites")
        let favoritesCoordinator = FavoritesCoordinator(
            navigationController: navigationController,
            container: container
        )
        addChild(favoritesCoordinator)
        favoritesCoordinator.start()
    }

    private func showBiometricAlert(message: String) {
        let alert = UIAlertController(
            title: String(localized: "biometric.alert.title", defaultValue: "Authentication Required"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: String(localized: "alert.ok", defaultValue: "OK"),
            style: .default
        ))
        navigationController.present(alert, animated: true)
    }
}
