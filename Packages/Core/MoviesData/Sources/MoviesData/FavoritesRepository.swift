//
//  FavoritesRepository.swift
//  MoviesData
//
//  Created by User on 9/10/25.
//

import Foundation
import MoviesDomain

/// Repository for favorite movies (synchronous operations)
public final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let localDataSource: FavoritesLocalDataSourceProtocol

    public init(localDataSource: FavoritesLocalDataSourceProtocol) {
        self.localDataSource = localDataSource
    }

    public func getFavoriteMovieIds() throws -> Set<Int> {
        try localDataSource.getFavoriteMovieIds()
    }

    public func isMovieFavorited(movieId: Int) -> Bool {
        localDataSource.isFavorite(movieId: movieId)
    }

    public func removeFromFavorites(movieId: Int) throws {
        try localDataSource.removeFromFavorites(movieId: movieId)
    }

    public func addToFavorites(movie: Movie) throws {
        try localDataSource.addToFavorites(movie: movie)
    }

    public func addToFavorites(details: MovieDetails) throws {
        try localDataSource.addToFavorites(details: details)
    }

    public func getFavoriteDetails(movieId: Int) -> MovieDetails? {
        localDataSource.getFavoriteDetails(movieId: movieId)
    }
}
