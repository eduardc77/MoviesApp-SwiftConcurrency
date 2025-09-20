//
//  MovieRepositoryTests.swift
//  MoviesDataTests
//
//  Created by User on 9/16/25.
//

import XCTest
import SharedModels
@testable import MoviesData
@testable import MoviesDomain
@testable import MoviesNetwork

private final class RemoteDataSourceMock: MovieRemoteDataSourceProtocol, @unchecked Sendable {
    // Unified response for all operations - simplifies testing
    var mockResponse: MoviesResponseDTO?
    var mockDetailsResponse: MovieDetailsDTO?
    var shouldFail = false

    func fetchMovies(type: MovieType) async throws -> MoviesResponseDTO {
        if shouldFail { throw URLError(.badServerResponse) }
        return mockResponse ?? MoviesResponseDTO(results: [], page: 1, totalPages: 1, totalResults: 0)
    }

    func fetchMovies(type: MovieType, page: Int) async throws -> MoviesResponseDTO {
        if shouldFail { throw URLError(.badServerResponse) }
        return mockResponse ?? MoviesResponseDTO(results: [], page: page, totalPages: 1, totalResults: 0)
    }

    func fetchMovies(type: MovieType, page: Int, sortBy: String?) async throws -> MoviesResponseDTO {
        if shouldFail { throw URLError(.badServerResponse) }
        return mockResponse ?? MoviesResponseDTO(results: [], page: page, totalPages: 1, totalResults: 0)
    }

    func searchMovies(query: String) async throws -> MoviesResponseDTO {
        if shouldFail { throw URLError(.badServerResponse) }
        return mockResponse ?? MoviesResponseDTO(results: [], page: 1, totalPages: 1, totalResults: 0)
    }

    func searchMovies(query: String, page: Int) async throws -> MoviesResponseDTO {
        if shouldFail { throw URLError(.badServerResponse) }
        return mockResponse ?? MoviesResponseDTO(results: [], page: page, totalPages: 1, totalResults: 0)
    }

    func fetchMovieDetails(id: Int) async throws -> MovieDetailsDTO {
        if shouldFail { throw URLError(.badServerResponse) }
        return mockDetailsResponse ?? MovieDetailsDTO(
            id: id, title: "Mock Movie", overview: "Mock overview",
            posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01",
            voteAverage: 7.0, voteCount: 100, runtime: 120, genres: [], tagline: nil
        )
    }
}

final class MovieRepositoryTests: XCTestCase {
    func testFetchMoviesPassThrough() async throws {
        let remote = RemoteDataSourceMock()
        remote.mockResponse = MoviesResponseDTO(
            results: [MovieDTO(id: 1, title: "Test Movie", overview: "Overview", posterPath: "/poster.jpg", backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 7.5, voteCount: 100, genreIds: [28], genres: nil, popularity: nil, video: nil, adult: nil, originalLanguage: nil, originalTitle: nil)],
            page: 2,
            totalPages: 3,
            totalResults: 50
        )
        let repo = MovieRepository(remoteDataSource: remote)

        let page = try await repo.fetchMovies(type: .nowPlaying, page: 2)
        XCTAssertEqual(page.page, 2)
        XCTAssertEqual(page.totalPages, 3)
        XCTAssertEqual(page.items.first?.id, 1)
        XCTAssertEqual(page.items.first?.title, "Test Movie")
    }

    func testSearchMoviesPassThrough() async throws {
        let remote = RemoteDataSourceMock()
        remote.mockResponse = MoviesResponseDTO(
            results: [],
            page: 1,
            totalPages: 1,
            totalResults: 0
        )
        let repo = MovieRepository(remoteDataSource: remote)

        let page = try await repo.searchMovies(query: "test query", page: 1)
        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.items.count, 0)
    }

    func testFetchMovieDetailsErrorPropagation() async throws {
        let remote = RemoteDataSourceMock()
        remote.shouldFail = true
        let repo = MovieRepository(remoteDataSource: remote)

        do {
            let _ = try await repo.fetchMovieDetails(id: 99)
            XCTFail("should fail")
        } catch {
            // Expected error - test passes
        }
    }

    func testFetchMoviesWithSorting() async throws {
        let remote = RemoteDataSourceMock()
        remote.mockResponse = MoviesResponseDTO(
            results: [MovieDTO(id: 1, title: "Sorted Movie", overview: "Overview", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 8.0, voteCount: 150, genreIds: [], genres: nil, popularity: nil, video: nil, adult: nil, originalLanguage: nil, originalTitle: nil)],
            page: 1,
            totalPages: 1,
            totalResults: 1
        )
        let repo = MovieRepository(remoteDataSource: remote)

        let page = try await repo.fetchMovies(type: .popular, page: 1, sortBy: .ratingDescending)
        XCTAssertEqual(page.items.first?.title, "Sorted Movie")
    }
}
