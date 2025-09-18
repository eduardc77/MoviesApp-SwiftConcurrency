//
//  FavoritesRepository.swift
//  MoviesData
//
//  Created by User on 9/10/25.
//

import Foundation
import MoviesDomain

/// Adapter that exposes a Combine repository API backed by a local storage
public final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let localDataSource: FavoritesLocalDataSourceProtocol

    public init(localDataSource: FavoritesLocalDataSourceProtocol) {
        self.localDataSource = localDataSource
    }

    public func getFavoriteMovieIds() async throws -> Set<Int> {
        try await localDataSource.getFavoriteMovieIds()
    }

    public func isMovieFavorited(movieId: Int) async throws -> Bool {
        try await localDataSource.isFavorite(movieId: movieId)
    }

    public func removeFromFavorites(movieId: Int) async throws {
        try await localDataSource.removeFromFavorites(movieId: movieId)
    }

    public func addToFavorites(movie: Movie) async throws {
        try await localDataSource.addToFavorites(movie: movie)
    }

    public func addToFavorites(details: MovieDetails) async throws {
        try await localDataSource.addToFavorites(details: details)
    }

    public func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) async throws -> [Movie] {
        try await localDataSource.getFavorites(page: page, pageSize: pageSize, sortOrder: sortOrder)
    }

    public func getFavoriteDetails(movieId: Int) async throws -> MovieDetails? {
        try await localDataSource.getFavoriteDetails(movieId: movieId)
    }
}
