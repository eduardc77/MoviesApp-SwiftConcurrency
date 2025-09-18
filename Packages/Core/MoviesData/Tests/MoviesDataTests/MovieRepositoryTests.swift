//
//  MovieRepositoryTests.swift
//  MoviesDataTests
//
//  Created by User on 9/16/25.
//

import XCTest
import Combine
import SharedModels
@testable import MoviesData
@testable import MoviesDomain
@testable import MoviesNetwork

private final class RemoteDataSourceMock: MovieRemoteDataSourceProtocol, @unchecked Sendable {
    // Unified response for all operations - simplifies testing
    var mockResponse: MoviesResponseDTO?
    var mockDetailsResponse: MovieDetailsDTO?
    var shouldFail = false

    func fetchMovies(type: MovieType) -> AnyPublisher<MoviesResponseDTO, Error> {
        if shouldFail { return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher() }
        return Just(mockResponse ?? MoviesResponseDTO(results: [], page: 1, totalPages: 1, totalResults: 0))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchMovies(type: MovieType, page: Int) -> AnyPublisher<MoviesResponseDTO, Error> {
        if shouldFail { return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher() }
        return Just(mockResponse ?? MoviesResponseDTO(results: [], page: page, totalPages: 1, totalResults: 0))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchMovies(type: MovieType, page: Int, sortBy: String?) -> AnyPublisher<MoviesResponseDTO, Error> {
        if shouldFail { return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher() }
        return Just(mockResponse ?? MoviesResponseDTO(results: [], page: page, totalPages: 1, totalResults: 0))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func searchMovies(query: String) -> AnyPublisher<MoviesResponseDTO, Error> {
        if shouldFail { return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher() }
        return Just(mockResponse ?? MoviesResponseDTO(results: [], page: 1, totalPages: 1, totalResults: 0))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func searchMovies(query: String, page: Int) -> AnyPublisher<MoviesResponseDTO, Error> {
        if shouldFail { return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher() }
        return Just(mockResponse ?? MoviesResponseDTO(results: [], page: page, totalPages: 1, totalResults: 0))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchMovieDetails(id: Int) -> AnyPublisher<MovieDetailsDTO, Error> {
        if shouldFail { return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher() }
        return Just(mockDetailsResponse ?? MovieDetailsDTO(
            id: id, title: "Mock Movie", overview: "Mock overview",
            posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01",
            voteAverage: 7.0, voteCount: 100, runtime: 120, genres: [], tagline: nil
        ))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
}

final class MovieRepositoryTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testFetchMoviesPassThrough() {
        let remote = RemoteDataSourceMock()
        remote.mockResponse = MoviesResponseDTO(
            results: [MovieDTO(id: 1, title: "Test Movie", overview: "Overview", posterPath: "/poster.jpg", backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 7.5, voteCount: 100, genreIds: [28], genres: nil, popularity: nil, video: nil, adult: nil, originalLanguage: nil, originalTitle: nil)],
            page: 2,
            totalPages: 3,
            totalResults: 50
        )
        let repo = MovieRepository(remoteDataSource: remote)

        let exp = expectation(description: "movies")
        repo.fetchMovies(type: .nowPlaying, page: 2)
            .sink(receiveCompletion: { _ in }, receiveValue: { page in
                XCTAssertEqual(page.page, 2)
                XCTAssertEqual(page.totalPages, 3)
                XCTAssertEqual(page.items.first?.id, 1)
                XCTAssertEqual(page.items.first?.title, "Test Movie")
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func testSearchMoviesPassThrough() {
        let remote = RemoteDataSourceMock()
        remote.mockResponse = MoviesResponseDTO(
            results: [],
            page: 1,
            totalPages: 1,
            totalResults: 0
        )
        let repo = MovieRepository(remoteDataSource: remote)

        let exp = expectation(description: "search")
        repo.searchMovies(query: "test query", page: 1)
            .sink(receiveCompletion: { _ in }, receiveValue: { page in
                XCTAssertEqual(page.page, 1)
                XCTAssertEqual(page.items.count, 0)
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func testFetchMovieDetailsErrorPropagation() {
        let remote = RemoteDataSourceMock()
        remote.shouldFail = true
        let repo = MovieRepository(remoteDataSource: remote)

        let exp = expectation(description: "error")
        repo.fetchMovieDetails(id: 99)
            .sink(receiveCompletion: { completion in
                if case .failure = completion { exp.fulfill() }
            }, receiveValue: { _ in
                XCTFail("should fail")
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func testFetchMoviesWithSorting() {
        let remote = RemoteDataSourceMock()
        remote.mockResponse = MoviesResponseDTO(
            results: [MovieDTO(id: 1, title: "Sorted Movie", overview: "Overview", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 8.0, voteCount: 150, genreIds: [], genres: nil, popularity: nil, video: nil, adult: nil, originalLanguage: nil, originalTitle: nil)],
            page: 1,
            totalPages: 1,
            totalResults: 1
        )
        let repo = MovieRepository(remoteDataSource: remote)

        let exp = expectation(description: "sorted movies")
        repo.fetchMovies(type: .popular, page: 1, sortBy: .ratingDescending)
            .sink(receiveCompletion: { _ in }, receiveValue: { page in
                XCTAssertEqual(page.items.first?.title, "Sorted Movie")
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }
}
