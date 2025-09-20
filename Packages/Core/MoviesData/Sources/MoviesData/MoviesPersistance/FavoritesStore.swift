//
//  FavoritesStore.swift
//  MoviesData
//
//  Created by User on 9/10/25.
//

import Foundation
import MoviesDomain
import AppLog

@MainActor
@Observable
public final class FavoritesStore {
    /// Repository for favorites
    @ObservationIgnored private let repository: FavoritesRepositoryProtocol
    /// Reactive set of favorite movie IDs
    public var favoriteMovieIds: Set<Int> = []

    /// Initialize with synchronous loading
    public init(favoritesLocalDataSource: FavoritesLocalDataSourceProtocol = FavoritesLocalDataSource()) {
        self.repository = FavoritesRepository(localDataSource: favoritesLocalDataSource)
        loadFavorites()
    }

    /// Load favorites from storage synchronously
    private func loadFavorites() {
        do {
            let favorites = try repository.getFavoriteMovieIds()
            self.favoriteMovieIds = favorites
        } catch {
            AppLog.persistence.error("Failed to load favorites: \(String(describing: error))")
        }
    }

    /// Remove favorite by id
    private func removeFavorite(for movieId: Int) {
        guard favoriteMovieIds.contains(movieId) else { return }

        // Optimistic update - remove from UI immediately
        favoriteMovieIds.remove(movieId)

        // Try to persist the change
        do {
            try repository.removeFromFavorites(movieId: movieId)
        } catch {
            // Rollback on failure - add back to UI
            favoriteMovieIds.insert(movieId)
            AppLog.persistence.error("Failed to remove favorite \(movieId): \(error)")
        }
    }
}

// MARK: - Domain Favorites Protocol Conformance
extension FavoritesStore: FavoritesStoreProtocol {
    public func isFavorite(movieId: Int) -> Bool { favoriteMovieIds.contains(movieId) }
    public func removeFromFavorites(movieId: Int) { removeFavorite(for: movieId) }
    public func addToFavorites(movie: Movie) {
        // Optimistic update - add to UI immediately
        favoriteMovieIds.insert(movie.id)

        // Try to persist the change
        do {
            try repository.addToFavorites(movie: movie)
        } catch {
            // Rollback on failure - remove from UI
            favoriteMovieIds.remove(movie.id)
            AppLog.persistence.error("Failed to add favorite \(movie.id): \(error)")
        }
    }

    public func addToFavorites(details: MovieDetails) {
        // Optimistic update - add to UI immediately
        favoriteMovieIds.insert(details.id)

        // Try to persist the change
        do {
            try repository.addToFavorites(details: details)
        } catch {
            // Rollback on failure - remove from UI
            favoriteMovieIds.remove(details.id)
            AppLog.persistence.error("Failed to add favorite \(details.id): \(error)")
        }
    }

    public func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) -> [Movie] {
        do {
            return try repository.getFavorites(page: page, pageSize: pageSize, sortOrder: sortOrder)
        } catch {
            AppLog.persistence.error("Failed to get favorites: \(error)")
            return []
        }
    }

    public func getFavoriteDetails(movieId: Int) -> MovieDetails? {
        repository.getFavoriteDetails(movieId: movieId)
    }

    /// Toggle favorite status for a movie in a collection
    /// - Parameters:
    ///   - movieId: The ID of the movie to toggle
    ///   - items: Array of movies to find the movie data
    /// - Returns: The new favorite status (true = now favorited, false = now unfavorited)
    public func toggleFavorite(movieId: Int, in items: [Movie]) -> Bool {
        if isFavorite(movieId: movieId) {
            // Currently favorited, so remove it
            removeFromFavorites(movieId: movieId)
            return false  // Now unfavorited
        } else if let movie = items.first(where: { $0.id == movieId }) {
            // Not favorited, so add it
            addToFavorites(movie: movie)
            return true   // Now favorited
        }
        // Movie not found in items, return current status
        return isFavorite(movieId: movieId)
    }


    /// Toggle favorite status for movie details
    /// - Parameters:
    ///   - movieId: The ID of the movie to toggle
    ///   - movieDetails: The movie details data
    /// - Returns: The new favorite status
    public func toggleFavorite(movieId: Int, movieDetails: MovieDetails?) -> Bool {
        if isFavorite(movieId: movieId) {
            // Currently favorited, so remove it
            removeFromFavorites(movieId: movieId)
            return false  // Now unfavorited
        } else if let details = movieDetails {
            // Not favorited, so add it
            addToFavorites(details: details)
            return true   // Now favorited
        }
        // No details provided, return current status
        return isFavorite(movieId: movieId)
    }
}
