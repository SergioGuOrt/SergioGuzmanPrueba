// Modules/Detail/DetailViewController.swift
//  SergioGuzmanPrueba
//
//  Pantalla de detalle de un personaje.
//  Muestra episodios reales con estado visto/no visto.
//  Toda la UI está en Detail.storyboard.

import UIKit
import Combine

final class DetailViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var characterImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var speciesLabel: UILabel!
    @IBOutlet private weak var genderLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var favoriteButton: UIButton!
    @IBOutlet private weak var mapButton: UIButton!
    @IBOutlet private weak var episodesTableView: UITableView!
    @IBOutlet private weak var episodesLoadingIndicator: UIActivityIndicatorView!

    // MARK: - Height constraint — actualizada en runtime al recibir episodios

    private var tableHeightConstraint: NSLayoutConstraint?

    // MARK: - Dependencies

    private var viewModel: DetailViewModel!
    private var cancellables = Set<AnyCancellable>()
    private var imageLoadTask: Task<Void, Never>?

    // MARK: - Storyboard Instantiation

    static func instantiate() -> DetailViewController {
        let storyboard = UIStoryboard(name: "Detail", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: String(describing: DetailViewController.self)
        ) as? DetailViewController else {
            fatalError("DetailViewController not found in Detail.storyboard")
        }
        return vc
    }

    // MARK: - DI

    func configure(with viewModel: DetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "Call configure(with:) before presenting.")
        setupUI()
        setupTableView()
        setupBindings()
        populateStaticData()
        viewModel.viewDidLoad()
    }

    // MARK: - IBActions

    @IBAction private func favoriteButtonTapped(_ sender: UIButton) {
        viewModel.toggleFavorite()
    }

    @IBAction private func mapButtonTapped(_ sender: UIButton) {
        viewModel.viewOnMapTapped()
    }

    // MARK: - Setup

    private func setupUI() {
        title = viewModel.navigationTitle
        navigationController?.navigationBar.prefersLargeTitles = false
        characterImageView.layer.cornerRadius = 12
        characterImageView.clipsToBounds = true
        characterImageView.contentMode = .scaleAspectFill
    }

    private func setupTableView() {
        episodesTableView.dataSource = self
        episodesTableView.delegate   = self
        episodesTableView.rowHeight  = UITableView.automaticDimension
        episodesTableView.estimatedRowHeight = 60
        episodesTableView.isScrollEnabled = false
        episodesTableView.tableFooterView = UIView()
        episodesTableView.register(
            UINib(nibName: "EpisodeTableViewCell", bundle: nil),
            forCellReuseIdentifier: EpisodeTableViewCell.reuseIdentifier
        )
    }

    private func setupBindings() {
        // Favorito
        viewModel.$isFavorite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavorite in
                let icon: UIColor = isFavorite ? .systemRed : .systemGray
                self?.favoriteButton.setImage(
                    UIImage(systemName: isFavorite ? "heart.fill" : "heart"), for: .normal
                )
                self?.favoriteButton.tintColor = icon
            }
            .store(in: &cancellables)

        // Loading de episodios
        viewModel.$isLoadingEpisodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                loading
                    ? self?.episodesLoadingIndicator.startAnimating()
                    : self?.episodesLoadingIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        // Episodios cargados — recargar tabla y ajustar altura
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                guard let self, !episodes.isEmpty else { return }
                self.episodesTableView.reloadData()
                self.updateTableHeight(rowCount: episodes.count)
            }
            .store(in: &cancellables)

        // Estado de vistos — solo recargar tabla sin cambiar altura
        viewModel.$viewedEpisodeIds
            .receive(on: DispatchQueue.main)
            .dropFirst()   // ignorar el valor inicial — ya se maneja con $episodes
            .sink { [weak self] _ in
                self?.episodesTableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func populateStaticData() {
        nameLabel.text     = viewModel.nameText
        statusLabel.text   = viewModel.statusText
        speciesLabel.text  = viewModel.speciesText
        genderLabel.text   = viewModel.genderText
        locationLabel.text = viewModel.locationText
        loadImage(from: viewModel.imageURL)
    }

    // MARK: - Table height management

    private func updateTableHeight(rowCount: Int) {
        let height = CGFloat(rowCount) * 60
        if let existing = tableHeightConstraint {
            existing.constant = height
        } else {
            let constraint = episodesTableView.heightAnchor.constraint(equalToConstant: height)
            constraint.isActive = true
            tableHeightConstraint = constraint
        }
        view.layoutIfNeeded()
    }

    // MARK: - Image Loading

    private func loadImage(from url: URL?) {
        guard let url else {
            characterImageView.image = UIImage(systemName: "person.crop.square.fill")
            return
        }
        imageLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                await MainActor.run { self.characterImageView.image = UIImage(data: data) }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.characterImageView.image = UIImage(systemName: "person.crop.square.fill")
                }
            }
        }
    }

    deinit { imageLoadTask?.cancel() }
}

// MARK: - UITableViewDataSource

extension DetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.episodes.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: EpisodeTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? EpisodeTableViewCell else {
            return UITableViewCell()
        }
        let episode = viewModel.episodes[indexPath.row]
        let viewed  = viewModel.isEpisodeViewed(at: indexPath.row)
        cell.configure(episode: episode, isViewed: viewed)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension DetailViewController: UITableViewDelegate {

    /// Tap en una fila → toggle visto/no visto.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.toggleViewed(at: indexPath.row)
    }
}
