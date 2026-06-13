// Application/SceneDelegate.swift
//  SergioGuzmanPrueba
//
//  Compositor raíz de la aplicación.
//  Responsable de:
//    1. Construir el container Swinject con AppAssembly.
//    2. Crear UIWindow y UINavigationController raíz.
//    3. Instanciar y retener AppCoordinator.
//    4. Delegar el guardado de CoreData al PersistenceController (no al AppDelegate).

import UIKit
import Swinject

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Properties

    var window: UIWindow?

    /// AppCoordinator retenido aquí para evitar su deallocación inmediata.
    private var appCoordinator: AppCoordinator?

    // MARK: - Scene Lifecycle

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // 1. Construir el container de dependencias.
        let container = buildDependencyContainer()

        // 2. Crear la ventana y el navigation controller raíz.
        let navigationController = UINavigationController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        // 3. Instanciar y arrancar el coordinator raíz.
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            container: container
        )
        appCoordinator = coordinator
        coordinator.start()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // CoreData ya no se guarda desde AppDelegate.
        // PersistenceController gestiona sus propios saves mediante save(context:).
    }

    // MARK: - Private

    private func buildDependencyContainer() -> Container {
        let container = Container()
        let assembler = Assembler([AppAssembly()], container: container)
        // La variable assembler se descarta intencionalmente:
        // Assembler solo necesita existir durante el registro.
        _ = assembler
        return container
    }
}
