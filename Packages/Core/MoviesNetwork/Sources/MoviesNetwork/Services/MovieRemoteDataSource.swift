//
//  MovieRemoteDataSource.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

import Combine
import SharedModels
import Foundation

/// Protocol defining TMDB remote data source operations
/// Follows repository pattern with remote data source abstraction
public protocol MovieRemoteDataSourceProtocol: Sendable {
    func fetchMovies(type: MovieType) async throws -> MoviesResponseDTO
    func fetchMovies(type: MovieType, page: Int) async throws -> MoviesResponseDTO
    func fetchMovies(type: MovieType, page: Int, sortBy: String?) async throws -> MoviesResponseDTO
    func searchMovies(query: String) async throws -> MoviesResponseDTO
    func searchMovies(query: String, page: Int) async throws -> MoviesResponseDTO
    func fetchMovieDetails(id: Int) async throws -> MovieDetailsDTO
}

/// Remote data source implementation for TMDB API
/// Uses the networking client internally for HTTP operations
public final class MovieRemoteDataSource: MovieRemoteDataSourceProtocol {
    private let networkingClient: TMDBNetworkingClientProtocol

    public init(networkingClient: TMDBNetworkingClientProtocol) {
        self.networkingClient = networkingClient
    }

    public func fetchMovies(type: MovieType) async throws -> MoviesResponseDTO {
        let endpoint = MoviesEndpoints.movies(type: type, page: 1)
        return try await networkingClient.request(endpoint)
    }

    public func fetchMovies(type: MovieType, page: Int) async throws -> MoviesResponseDTO {
        let endpoint = MoviesEndpoints.movies(type: type, page: page)
        return try await networkingClient.request(endpoint)
    }

    public func fetchMovies(type: MovieType, page: Int, sortBy: String?) async throws -> MoviesResponseDTO {
        let endpoint = MoviesEndpoints.discoverMovies(type: type, page: page, sortBy: sortBy)
        return try await networkingClient.request(endpoint)
    }

    public func searchMovies(query: String) async throws -> MoviesResponseDTO {
        let endpoint = MoviesEndpoints.searchMovies(query: query, page: 1)
        return try await networkingClient.request(endpoint)
    }

    public func searchMovies(query: String, page: Int) async throws -> MoviesResponseDTO {
        let endpoint = MoviesEndpoints.searchMovies(query: query, page: page)
        return try await networkingClient.request(endpoint)
    }

    public func fetchMovieDetails(id: Int) async throws -> MovieDetailsDTO {
        let endpoint = MoviesEndpoints.movieDetails(id: id)
        return try await networkingClient.request(endpoint)
    }
}
