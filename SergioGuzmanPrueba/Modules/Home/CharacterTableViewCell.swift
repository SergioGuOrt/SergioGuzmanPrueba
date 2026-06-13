// Modules/Home/CharacterTableViewCell.swift
//  SergioGuzmanPrueba
//
//  Celda reutilizable para el listado de personajes de Rick & Morty.
//  Layout definido en Home.storyboard — prototype cell identifier: CharacterTableViewCell.
//  configure(with:) es el único punto de entrada para datos.
//  No contiene lógica de negocio.

import UIKit

final class CharacterTableViewCell: UITableViewCell {

    // MARK: - Reuse Identifier

    static let reuseIdentifier = "CharacterTableViewCell"

    // MARK: - IBOutlets
    // Todos conectados desde el prototype cell en Home.storyboard.

    @IBOutlet private weak var characterImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var speciesLabel: UILabel!
    @IBOutlet private weak var genderLabel: UILabel!

    // MARK: - Image loading task — cancelable on reuse

    private var imageLoadTask: Task<Void, Never>?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        characterImageView.image = nil
        nameLabel.text = nil
        statusLabel.text = nil
        speciesLabel.text = nil
        genderLabel.text = nil
    }

    // MARK: - Configuration

    /// Punto de entrada único para inyectar datos de un personaje.
    func configure(with character: Character) {
        nameLabel.text = character.name
        statusLabel.text = character.status.displayName
        speciesLabel.text = character.species
        genderLabel.text = character.gender.displayName
        loadImage(from: character.imageURL)
    }

    // MARK: - Private

    private func setupAppearance() {
        characterImageView.layer.cornerRadius = 40   // 80pt / 2 → círculo perfecto
        characterImageView.clipsToBounds = true
        characterImageView.contentMode = .scaleAspectFill
        characterImageView.backgroundColor = .systemGray5
    }

    private func loadImage(from url: URL?) {
        guard let url else {
            characterImageView.image = UIImage(systemName: "person.crop.circle.fill")
            return
        }

        imageLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.characterImageView.image = UIImage(data: data)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.characterImageView.image = UIImage(systemName: "person.crop.circle.fill")
                }
            }
        }
    }
}
