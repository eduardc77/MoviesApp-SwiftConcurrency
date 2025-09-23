//
//  FavoritesRepositoryProtocol.swift
//  MoviesDomain
//
//  Created by User on 9/14/25.
//

/// Protocol for managing favorite movies
public protocol FavoritesRepositoryProtocol {
    /// Gets all favorite movie IDs
    func getFavoriteMovieIds() throws -> Set<Int>

    /// Checks if a movie is favorited
    func isMovieFavorited(movieId: Int) -> Bool

    /// Removes favorite by id
    func removeFromFavorites(movieId: Int) throws

    /// Adds a snapshot of a Movie to favorites
    func addToFavorites(movie: Movie) throws

    /// Adds a snapshot of MovieDetails to favorites
    func addToFavorites(details: MovieDetails) throws

    /// Fetch locally stored favorite details snapshot if available
    func getFavoriteDetails(movieId: Int) -> MovieDetails?
}
