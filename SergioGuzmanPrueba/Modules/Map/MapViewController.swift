// Modules/Map/MapViewController.swift
//  SergioGuzmanPrueba
//
//  Pantalla de mapa que muestra la ubicación simulada de un personaje.
//  Layout definido en Map.storyboard.
//  MKMapView con un pin de anotación.
//  No solicita ubicación real del usuario.

import UIKit
import MapKit

final class MapViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var mapView: MKMapView!

    // MARK: - Dependencies

    private var viewModel: MapViewModel!

    // MARK: - Storyboard Instantiation

    static func instantiate() -> MapViewController {
        let storyboard = UIStoryboard(name: "Map", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: String(describing: MapViewController.self)
        ) as? MapViewController else {
            fatalError("MapViewController not found in Map.storyboard")
        }
        return vc
    }

    // MARK: - DI

    func configure(with viewModel: MapViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "Call configure(with:) before presenting.")
        setupUI()
        setupMap()
    }

    // MARK: - Setup

    private func setupUI() {
        title = viewModel.characterName
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupMap() {
        // No mostrar la ubicación del usuario.
        mapView.showsUserLocation = false

        // Crear y agregar la anotación del personaje.
        let annotation = MKPointAnnotation()
        annotation.coordinate = viewModel.coordinate
        annotation.title = viewModel.annotationTitle
        annotation.subtitle = viewModel.annotationSubtitle
        mapView.addAnnotation(annotation)

        // Centrar el mapa en el pin con un zoom razonable.
        let region = MKCoordinateRegion(
            center: viewModel.coordinate,
            latitudinalMeters: 500_000,
            longitudinalMeters: 500_000
        )
        mapView.setRegion(region, animated: false)
    }
}
