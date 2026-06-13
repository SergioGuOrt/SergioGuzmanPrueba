// Services/AppLogger.swift
//  SergioGuzmanPrueba
//
//  Logging estructurado centralizado usando os.Logger nativo de Apple.
//  Categorías separadas por dominio funcional.
//  Los logs son visibles en Console.app filtrando por subsistema y categoría.

import Foundation
import os

enum AppLogger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sergioguzman.SergioGuzmanPrueba"

    /// Logs de requests y responses HTTP.
    static let network = Logger(subsystem: subsystem, category: "Network")

    /// Logs de operaciones CoreData (favoritos, episodios vistos).
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")

    /// Logs de transiciones de pantalla y navegación.
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")

    /// Logs de autenticación biométrica (Face ID / Touch ID).
    static let biometric = Logger(subsystem: subsystem, category: "Biometric")
}
