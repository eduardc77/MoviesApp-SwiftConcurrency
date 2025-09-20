//
//  MovieRepositoryProtocol.swift
//  MoviesDomain
//
//  Created by User on 9/10/25.
//

import SharedModels

/// Protocol defining the core movie repository operations
public protocol MovieRepositoryProtocol: Sendable {
    /// Fetches movies of a specific type from the data source
    func fetchMovies(type: MovieType) async throws -> [Movie]
    /// Fetches movies of a specific type for a page
    func fetchMovies(type: MovieType, page: Int) async throws -> MoviePage
    /// Fetches movies of a specific type for a page with server-side sorting
    func fetchMovies(type: MovieType, page: Int, sortBy: MovieSortOrder?) async throws -> MoviePage

    /// Searches for movies based on a query string
    func searchMovies(query: String) async throws -> [Movie]
    /// Searches for movies based on a query string and page
    func searchMovies(query: String, page: Int) async throws -> MoviePage

    /// Fetches detailed information for a specific movie
    func fetchMovieDetails(id: Int) async throws -> MovieDetails
}
