//
//  MovieRepository.swift
//  MoviesData
//
//  Created by User on 9/16/25.
//

import SharedModels
import MoviesDomain
import MoviesNetwork

/// Repository that bridges network DTOs to domain models
/// Implements the data access layer for movie operations
public final class MovieRepository: MovieRepositoryProtocol {
    private let remoteDataSource: MovieRemoteDataSourceProtocol

    public init(remoteDataSource: MovieRemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    public func fetchMovies(type: MovieType) async throws -> [Movie] {
        let response = try await remoteDataSource.fetchMovies(type: type)
        return DTOMapper.toDomain(response.results)
    }

    public func fetchMovies(type: MovieType, page: Int) async throws -> MoviePage {
        let response = try await remoteDataSource.fetchMovies(type: type, page: page)
        return MoviePage(
            items: DTOMapper.toDomain(response.results),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    public func fetchMovies(type: MovieType, page: Int, sortBy: MovieSortOrder?) async throws -> MoviePage {
        let response = try await remoteDataSource.fetchMovies(type: type, page: page, sortBy: sortBy?.tmdbSortValue)
        return MoviePage(
            items: DTOMapper.toDomain(response.results),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    public func searchMovies(query: String) async throws -> [Movie] {
        let response = try await remoteDataSource.searchMovies(query: query)
        return DTOMapper.toDomain(response.results)
    }

    public func searchMovies(query: String, page: Int) async throws -> MoviePage {
        let response = try await remoteDataSource.searchMovies(query: query, page: page)
        return MoviePage(
            items: DTOMapper.toDomain(response.results),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    public func fetchMovieDetails(id: Int) async throws -> MovieDetails {
        let response = try await remoteDataSource.fetchMovieDetails(id: id)
        return DTOMapper.toDomain(response)
    }
}

// MARK: - Repository Creation
public extension MovieRepository {
    /// Creates a TMDBMovieRepository with static configuration
    static func development() -> MovieRepository {
        let networkingClient = TMDBNetworkingClient(networkingConfig: TMDBNetworkingConfig.config)
        let remoteDataSource = MovieRemoteDataSource(networkingClient: networkingClient)
        return MovieRepository(remoteDataSource: remoteDataSource)
    }
}

// MARK: - Error Mapping
private extension MovieRepository {
    static func mapToDomainError(_ error: Error) -> Error {
        // Map infra/network errors to DomainError while preserving public failure type as Error
        if let netErr = error as? TMDBNetworkingError {
            switch netErr {
            case .invalidURL:
                return DomainError.network(underlying: netErr)
            case .networkError(let underlying):
                return DomainError.network(underlying: underlying)
            case .decodingError(let underlying):
                return DomainError.decoding(underlying: underlying)
            case .httpError(let code):
                if code == 401 { return DomainError.unauthorized }
                if code == 404 { return DomainError.notFound }
                if code == 429 { return DomainError.rateLimited }
                return DomainError.httpStatus(code: code)
            }
        }
        return DomainError.unknown(underlying: error)
    }
}
