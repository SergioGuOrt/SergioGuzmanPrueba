// Modules/Detail/EpisodeTableViewCell.swift
//  SergioGuzmanPrueba
//
//  Celda para mostrar un episodio con su estado visto/no visto.
//  Layout definido en Detail.storyboard — prototype cell "EpisodeCell".
//  configure(episode:isViewed:) es el único punto de entrada de datos.

import UIKit

final class EpisodeTableViewCell: UITableViewCell {

    // MARK: - Reuse Identifier

    static let reuseIdentifier = "EpisodeCell"

    // MARK: - IBOutlets — conectados desde Detail.storyboard

    @IBOutlet private weak var episodeCodeLabel: UILabel!
    @IBOutlet private weak var episodeNameLabel: UILabel!
    @IBOutlet private weak var viewedIconImageView: UIImageView!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        episodeCodeLabel.text = nil
        episodeNameLabel.text = nil
        viewedIconImageView.image = nil
    }

    // MARK: - Configuration

    func configure(episode: Episode, isViewed: Bool) {
        episodeCodeLabel.text = episode.episode   // "S01E01"
        episodeNameLabel.text = episode.name

        let iconName = isViewed ? "checkmark.circle.fill" : "circle"
        let tint: UIColor = isViewed ? .systemGreen : .systemGray3
        viewedIconImageView.image = UIImage(systemName: iconName)
        viewedIconImageView.tintColor = tint
    }
}
