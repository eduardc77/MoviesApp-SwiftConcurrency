//
//  FavoritesStoreProtocol.swift
//  MoviesDomain
//
//  Created by User on 9/14/25.
//

/// Read-only favorites interface for UI/state observation
@MainActor
public protocol FavoritesStoreProtocol: Sendable {
    /// Reactive set of favorite movie IDs; intended to be observed via Observation
    var favoriteMovieIds: Set<Int> { get }

    /// Convenience helper for sync favorite check
    func isFavorite(movieId: Int) -> Bool

    // Save snapshots
    func addToFavorites(movie: Movie)
    func addToFavorites(details: MovieDetails)
    // Remove favorite by id
    func removeFromFavorites(movieId: Int)

    // Local paging fetch for favorites

    /// Fetch locally stored favorite details snapshot if available
    func getFavoriteDetails(movieId: Int) -> MovieDetails?

    func toggleFavorite(movieId: Int, in items: [Movie]) -> Bool
    func toggleFavorite(movieId: Int, movieDetails: MovieDetails?) -> Bool

    /// Background-friendly fetch for potentially large favorites sets
    /// Heavy work is performed off-main; result is awaited on the caller
    func fetchAllFavorites(sortOrder: MovieSortOrder?) async -> [Movie]

    // Paging (keyset) API
    func fetchFirstPage(sortOrder: MovieSortOrder, pageSize: Int) async -> (items: [Movie], cursor: FavoritesPageCursor?)
    func fetchNextPage(cursor: FavoritesPageCursor, pageSize: Int) async -> (items: [Movie], cursor: FavoritesPageCursor?)
}
