// Modules/Favorites/FavoritesViewModel.swift
//  SergioGuzmanPrueba
//
//  ViewModel del módulo Favorites.
//  Lee favoritos de CoreData via FavoriteRepository.
//  Gestiona el estado de la pantalla y el borrado de favoritos.
//  No importa UIKit.

import Foundation
import Combine

final class FavoritesViewModel {

    // MARK: - Navigation Closures

    var onCharacterSelected: ((Character) -> Void)?

    // MARK: - Output

    @Published private(set) var favorites: [Character] = []
    @Published private(set) var isEmpty: Bool = true

    // MARK: - Private

    private let favoriteRepository: FavoriteRepository

    // MARK: - Init

    init(favoriteRepository: FavoriteRepository) {
        self.favoriteRepository = favoriteRepository
    }

    // MARK: - Input

    /// Carga la lista de favoritos desde CoreData.
    /// Llamar en viewWillAppear para reflejar cambios hechos en Detail.
    func loadFavorites() {
        favorites = favoriteRepository.fetchAll()
        isEmpty = favorites.isEmpty
    }

    /// El usuario seleccionó un favorito — navegar a Detail.
    func didSelectCharacter(_ character: Character) {
        onCharacterSelected?(character)
    }

    /// Elimina un favorito por swipe-to-delete.
    func removeFavorite(at indexPath: IndexPath) {
        guard indexPath.row < favorites.count else { return }
        let character = favorites[indexPath.row]
        favoriteRepository.remove(characterId: character.id)
        favorites.remove(at: indexPath.row)
        isEmpty = favorites.isEmpty
    }
}
