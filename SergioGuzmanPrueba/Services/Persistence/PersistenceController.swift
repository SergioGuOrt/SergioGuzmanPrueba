// Services/Persistence/PersistenceController.swift
//  SergioGuzmanPrueba
//
//  Stack de CoreData centralizado.
//  Reemplaza el NSPersistentContainer que Xcode genera en AppDelegate.
//  Se inyecta como dependencia en los ViewModels que necesiten persistencia.
//  Nunca se accede como singleton — siempre a través del container Swinject.

import CoreData

final class PersistenceController {

    // MARK: - Public Interface

    /// Contexto principal. Usar para lecturas y binding con UI en el hilo principal.
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Private

    private let container: NSPersistentContainer

    // MARK: - Init

    /// - Parameter inMemory: Pasar `true` en tests para evitar persistencia en disco.
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SergioGuzmanPrueba")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Habilitar lightweight migration automática para soportar evolución del modelo.
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("CoreData failed to load store: \(error.localizedDescription)")
            }
        }

        // Permite que el viewContext reciba cambios guardados desde contextos background.
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Background Context

    /// Retorna un nuevo contexto para operaciones de escritura en background.
    /// Siempre realizar writes en background, nunca en viewContext.
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    // MARK: - Save

    /// Guarda el contexto si tiene cambios pendientes.
    /// - Parameter context: Contexto a guardar. Por defecto usa viewContext.
    func save(context: NSManagedObjectContext? = nil) {
        let target = context ?? container.viewContext
        guard target.hasChanges else { return }

        do {
            try target.save()
        } catch {
            assertionFailure("CoreData save failed: \(error.localizedDescription)")
        }
    }
}
