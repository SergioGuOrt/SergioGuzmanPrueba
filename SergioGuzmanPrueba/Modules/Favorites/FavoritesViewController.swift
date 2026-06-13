// Modules/Favorites/FavoritesViewController.swift
//  SergioGuzmanPrueba
//
//  Pantalla de personajes favoritos guardados en CoreData.
//  Layout definido en Favorites.storyboard.
//  Reutiliza CharacterTableViewCell del módulo Home.
//  No contiene lógica de negocio ni navegación directa.

import UIKit
import Combine

final class FavoritesViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateView: UIView!

    // MARK: - Dependencies

    private var viewModel: FavoritesViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Storyboard Instantiation

    static func instantiate() -> FavoritesViewController {
        let storyboard = UIStoryboard(name: "Favorites", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: String(describing: FavoritesViewController.self)
        ) as? FavoritesViewController else {
            fatalError("FavoritesViewController not found in Favorites.storyboard")
        }
        return vc
    }

    // MARK: - DI

    func configure(with viewModel: FavoritesViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "FavoritesViewController requires configure(with:) before presenting.")
        setupUI()
        setupTableView()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Recargar en cada aparición para reflejar cambios hechos en Detail.
        viewModel.loadFavorites()
    }

    // MARK: - Setup

    private func setupUI() {
        title = String(localized: "favorites.title", defaultValue: "Favorites")
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.rowHeight  = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
    }

    private func setupBindings() {
        viewModel.$favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.emptyStateView.isHidden = !isEmpty
                self?.tableView.isHidden = isEmpty
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension FavoritesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.favorites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CharacterTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? CharacterTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.favorites[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        viewModel.removeFavorite(at: indexPath)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - UITableViewDelegate

extension FavoritesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectCharacter(viewModel.favorites[indexPath.row])
    }
}
