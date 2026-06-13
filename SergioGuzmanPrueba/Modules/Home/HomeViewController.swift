// Modules/Home/HomeViewController.swift
//  SergioGuzmanPrueba
//
//  Pantalla principal de personajes de Rick & Morty.
//  Layout principal en Home.storyboard.
//  Filtros nativos: UISearchBar scope buttons (estado) + UIBarButtonItem con UIMenu (especie).
//  No contiene lógica de negocio ni navegación directa.

import UIKit
import Combine

final class HomeViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateView: UIView!
    @IBOutlet private weak var emptyStateLabel: UILabel!
    @IBOutlet private weak var errorStateView: UIView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var retryButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Dependencies

    private var viewModel: HomeViewModel!

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private let searchController = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()

    // MARK: - Storyboard Instantiation

    static func instantiate() -> HomeViewController {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: String(describing: HomeViewController.self)
        ) as? HomeViewController else {
            fatalError("HomeViewController not found in Home.storyboard")
        }
        return vc
    }

    // MARK: - DI

    func configure(with viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "HomeViewController requires a ViewModel. Call configure(with:) before presenting.")
        setupNavigationBar()
        setupSearchController()
        setupFilterMenu()
        setupTableView()
        setupRefreshControl()
        setupBindings()
        viewModel.viewDidLoad()
    }

    // MARK: - IBActions

    @IBAction private func retryButtonTapped(_ sender: UIButton) {
        viewModel.viewDidLoad()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = String(localized: "home.title", defaultValue: "Rick & Morty")
        navigationController?.navigationBar.prefersLargeTitles = true

        // Botón de favoritos
        let favoritesButton = UIBarButtonItem(
            image: UIImage(systemName: "heart.fill"),
            style: .plain,
            target: self,
            action: #selector(favoritesButtonTapped)
        )
        favoritesButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = favoritesButton
    }

    @objc private func favoritesButtonTapped() {
        viewModel.didTapFavorites()
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(
            localized: "home.search.placeholder",
            defaultValue: "Search characters..."
        )
        searchController.delegate = self

        // Scope buttons para filtro de estado — integrado nativamente en UISearchBar.
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = StatusFilter.allCases.map { $0.displayName }
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    /// Botón de filtro de especie usando UIMenu (nativo iOS 14+).
    /// Se muestra como un barButtonItem a la izquierda de la nav bar.
    private func setupFilterMenu() {
        let speciesMenu = UIMenu(
            title: String(localized: "filter.species.title", defaultValue: "Species"),
            children: SpeciesFilter.allCases.map { filter in
                UIAction(
                    title: filter.displayName,
                    state: filter == viewModel.currentSpeciesFilter ? .on : .off
                ) { [weak self] _ in
                    self?.viewModel.didSelectSpecies(filter)
                    self?.updateFilterMenuState()
                }
            }
        )

        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            menu: speciesMenu
        )
        filterButton.tintColor = .label
        navigationItem.leftBarButtonItem = filterButton
    }

    /// Actualiza el estado visual (checkmark) del menú de especie.
    private func updateFilterMenuState() {
        let currentFilter = viewModel.currentSpeciesFilter
        let speciesMenu = UIMenu(
            title: String(localized: "filter.species.title", defaultValue: "Species"),
            children: SpeciesFilter.allCases.map { filter in
                UIAction(
                    title: filter.displayName,
                    state: filter == currentFilter ? .on : .off
                ) { [weak self] _ in
                    self?.viewModel.didSelectSpecies(filter)
                    self?.updateFilterMenuState()
                }
            }
        )
        navigationItem.leftBarButtonItem?.menu = speciesMenu
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    @objc private func handleRefresh() {
        viewModel.didPullToRefresh()
    }

    // MARK: - Bindings

    private func setupBindings() {
        viewModel.$characters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.apply(state: state)
            }
            .store(in: &cancellables)

        // Cuando el filtro de especie cambie, actualizar el menú visualmente.
        viewModel.$currentSpeciesFilter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFilterMenuState()
            }
            .store(in: &cancellables)
    }

    // MARK: - State Management

    private func apply(state: HomeViewState) {
        activityIndicator.stopAnimating()
        emptyStateView.isHidden = true
        errorStateView.isHidden = true
        refreshControl.endRefreshing()

        switch state {
        case .idle:
            break
        case .loading:
            activityIndicator.startAnimating()
        case .loaded:
            tableView.reloadData()
        case .empty:
            emptyStateLabel.text = String(
                localized: "home.empty.message",
                defaultValue: "No characters found."
            )
            emptyStateView.isHidden = false
        case .error(let message):
            errorLabel.text = message
            errorStateView.isHidden = false
        case .paginationError(let message):
            showAlert(
                title: String(localized: "error.title", defaultValue: "Error"),
                message: message
            )
        }
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.characters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CharacterTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? CharacterTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.characters[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectCharacter(viewModel.characters[indexPath.row])
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Prefetch threshold: disparar paginación cuando quedan 5 items.
        // Solo se invoca una vez gracias a la protección isFetching en el ViewModel.
        let threshold = 5
        let triggerIndex = max(0, viewModel.characters.count - threshold)
        if indexPath.row >= triggerIndex {
            viewModel.didScrollToBottom()
        }
    }
}

// MARK: - UISearchResultsUpdating

extension HomeViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        viewModel.didSearch(query: query)
    }
}

// MARK: - UISearchBarDelegate — Scope buttons (estado)

extension HomeViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let filter = StatusFilter(rawValue: selectedScope) else { return }
        viewModel.didSelectStatus(filter)
    }
}

// MARK: - UISearchControllerDelegate

extension HomeViewController: UISearchControllerDelegate {

    func didDismissSearchController(_ searchController: UISearchController) {
        viewModel.didCancelSearch()
    }
}

// MARK: - Alert Helper

private extension HomeViewController {

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: String(localized: "alert.ok", defaultValue: "OK"),
            style: .default
        ))
        present(alert, animated: true)
    }
}
