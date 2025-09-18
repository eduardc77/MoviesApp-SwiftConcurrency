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
    @ObservationIgnored private var currentTask: Task<Void, Never>?

    /// Initialize with async loading
    public init(favoritesLocalDataSource: FavoritesLocalDataSourceProtocol = FavoritesLocalDataSource()) {
        self.repository = FavoritesRepository(localDataSource: favoritesLocalDataSource)
        loadFavorites()
    }

    /// Load favorites from storage using async/await
    private func loadFavorites() {
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let ids = try await self.repository.getFavoriteMovieIds()
                if Task.isCancelled { return }
                self.favoriteMovieIds = ids
            } catch {
                AppLog.persistence.error("Failed to load favorites: \(String(describing: error))")
            }
            self.currentTask = nil
        }
    }

    /// Remove favorite by id
    private func removeFavorite(for movieId: Int) {
        guard favoriteMovieIds.contains(movieId) else { return }
        favoriteMovieIds.remove(movieId)
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.repository.removeFromFavorites(movieId: movieId)
            } catch {
                self.favoriteMovieIds.insert(movieId)
            }
        }
    }

    /// Check if movie is favorited
    private func isFavorite(movieId: Int) async throws -> Bool {
        try await repository.isMovieFavorited(movieId: movieId)
    }
}

// MARK: - Domain Favorites Protocol Conformance
extension FavoritesStore: FavoritesStoreProtocol {
    public func isFavorite(movieId: Int) -> Bool { favoriteMovieIds.contains(movieId) }
    public func removeFromFavorites(movieId: Int) { removeFavorite(for: movieId) }
    public func addToFavorites(movie: Movie) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.repository.addToFavorites(movie: movie)
                self.favoriteMovieIds.insert(movie.id)
            } catch {
                AppLog.persistence.error("Failed to add favorite snapshot: \(error)")
            }
        }
    }

    public func addToFavorites(details: MovieDetails) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.repository.addToFavorites(details: details)
                self.favoriteMovieIds.insert(details.id)
            } catch {
                AppLog.persistence.error("Failed to add favorite snapshot: \(error)")
            }
        }
    }

    public func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) async throws -> [Movie] {
        try await repository.getFavorites(page: page, pageSize: pageSize, sortOrder: sortOrder)
    }

    public func getFavoriteDetails(movieId: Int) async throws -> MovieDetails? {
        try await repository.getFavoriteDetails(movieId: movieId)
    }
}
