// Common/Base/BaseViewController.swift
//  SergioGuzmanPrueba
//
//  Clase padre de todos los ViewControllers del proyecto.
//  Provee comportamiento compartido: alerts y loading indicator.
//  No contiene lógica de negocio ni dependencias de dominio.

import UIKit

class BaseViewController: UIViewController {

    // MARK: - Loading

    private var loadingIndicator: UIActivityIndicatorView?

    func showLoading() {
        guard loadingIndicator == nil else { return }
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        loadingIndicator = indicator
    }

    func hideLoading() {
        loadingIndicator?.stopAnimating()
        loadingIndicator?.removeFromSuperview()
        loadingIndicator = nil
    }

    // MARK: - Alerts

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: String(localized: "alert.ok", defaultValue: "OK"),
            style: .default,
            handler: { _ in completion?() }
        ))
        present(alert, animated: true)
    }

    func showError(_ error: Error) {
        showAlert(
            title: String(localized: "error.title", defaultValue: "Error"),
            message: error.localizedDescription
        )
    }
}
