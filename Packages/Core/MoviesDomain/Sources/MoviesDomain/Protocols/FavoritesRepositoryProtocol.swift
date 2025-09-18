//
//  FavoritesRepositoryProtocol.swift
//  MoviesDomain
//
//  Created by User on 9/14/25.
//

import Foundation

/// Protocol for managing favorite movies
public protocol FavoritesRepositoryProtocol: Sendable {
    /// Gets all favorite movie IDs
    func getFavoriteMovieIds() async throws -> Set<Int>

    /// Checks if a movie is favorited
    func isMovieFavorited(movieId: Int) async throws -> Bool

    /// Removes favorite by id
    func removeFromFavorites(movieId: Int) async throws

    /// Adds a snapshot of a Movie to favorites
    func addToFavorites(movie: Movie) async throws

    /// Adds a snapshot of MovieDetails to favorites
    func addToFavorites(details: MovieDetails) async throws

    /// Fetch a page of favorited movies from local storage
    func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) async throws -> [Movie]

    /// Fetch locally stored favorite details snapshot if available
    func getFavoriteDetails(movieId: Int) async throws -> MovieDetails?
}
