// Modules/Map/MapViewModel.swift
//  SergioGuzmanPrueba
//
//  ViewModel del módulo Map.
//  Genera coordenadas determinísticas basadas en el id del personaje.
//  Expone datos de anotación para el pin del mapa.
//  No importa UIKit ni MapKit.

import Foundation
import CoreLocation

final class MapViewModel {

    // MARK: - Output

    let characterName: String
    let characterStatus: String
    let coordinate: CLLocationCoordinate2D
    let annotationTitle: String
    let annotationSubtitle: String

    // MARK: - Init

    init(character: Character) {
        self.characterName = character.name
        self.characterStatus = character.status.displayName
        self.annotationTitle = character.name
        self.annotationSubtitle = "\(character.status.displayName) • \(character.location.name)"

        // Coordenadas determinísticas basadas en el id del personaje.
        // El mismo personaje siempre genera las mismas coordenadas.
        // Rango: latitude [-60, 60], longitude [-150, 150] — siempre visibles en el mapa.
        let seed = Double(character.id)
        let lat  = MapViewModel.seededCoordinate(seed: seed, range: 60.0)
        let lon  = MapViewModel.seededCoordinate(seed: seed * 1.37, range: 150.0)
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: - Private

    /// Genera una coordenada pseudo-aleatoria determinística a partir de un seed.
    /// Usa una función hash simple que produce resultados reproducibles.
    private static func seededCoordinate(seed: Double, range: Double) -> Double {
        // Función hash simple: sin() produce valores [-1, 1], escalar al rango deseado.
        let hash = sin(seed * 43758.5453) * 10000.0
        let normalized = hash - floor(hash)        // 0.0 ..< 1.0
        return (normalized * 2.0 - 1.0) * range   // -range ... range
    }
}
