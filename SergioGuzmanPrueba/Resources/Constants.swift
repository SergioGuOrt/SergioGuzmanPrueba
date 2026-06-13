// Resources/Constants.swift
//  SergioGuzmanPrueba
//
//  Constantes globales del proyecto.
//  URL base de la API y valores de configuración reutilizables.

import Foundation

enum API {
    static let baseURL = "https://rickandmortyapi.com/api"

    enum Endpoint {
        static let character = "/character"
        static let episode   = "/episode"
    }
}

enum Pagination {
    static let pageSize = 20
}
