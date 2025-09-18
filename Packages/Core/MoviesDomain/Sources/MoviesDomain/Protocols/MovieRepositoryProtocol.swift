//
//  MovieRepositoryProtocol.swift
//  MoviesDomain
//
//  Created by User on 9/10/25.
//

import SharedModels
import Foundation

/// Protocol defining the core movie repository operations
public protocol MovieRepositoryProtocol: Sendable {
    func fetchMovies(type: MovieType) async throws -> [Movie]
    func fetchMovies(type: MovieType, page: Int) async throws -> MoviePage
    func fetchMovies(type: MovieType, page: Int, sortBy: MovieSortOrder?) async throws -> MoviePage

    func searchMovies(query: String) async throws -> [Movie]
    func searchMovies(query: String, page: Int) async throws -> MoviePage

    func fetchMovieDetails(id: Int) async throws -> MovieDetails
}
