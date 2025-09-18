//
//  TMDBRemoteDataSourceTests.swift
//  MoviesNetworkTests
//
//  Created by User on 9/10/25.
//

import XCTest
import Combine
import SharedModels
@testable import MoviesNetwork

private final class NetworkingClientMock: TMDBNetworkingClientProtocol, @unchecked Sendable {
    nonisolated(unsafe) var requestHandler: ((EndpointProtocol) -> AnyPublisher<Any, Error>)?

    nonisolated func request<T>(_ endpoint: EndpointProtocol) -> AnyPublisher<T, Error> where T : Decodable {
        guard let handler = requestHandler else { fatalError("no handler") }
        return handler(endpoint)
            .tryMap { any in
                guard let typed = any as? T else { throw NSError(domain: "type", code: -1) }
                return typed
            }
            .eraseToAnyPublisher()
    }
}

final class TMDBRemoteDataSourceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func test_fetchMovies_returnsDTOs() {
        let client = NetworkingClientMock()
        let expectedDTO = MoviesResponseDTO(results: [MovieDTO(id: 1, title: "A", overview: "", posterPath: nil, backdropPath: nil, releaseDate: "2020-01-01", voteAverage: 7.0, voteCount: 10, genreIds: [1], genres: nil, popularity: nil, video: nil, adult: nil, originalLanguage: nil, originalTitle: nil)], page: 1, totalPages: 1, totalResults: 1)
        client.requestHandler = { endpoint in
            return Just(expectedDTO).setFailureType(to: Error.self).map { $0 as Any }.eraseToAnyPublisher()
        }
        let sut = MovieRemoteDataSource(networkingClient: client)

        let exp = expectation(description: "dto returned")
        sut.fetchMovies(type: .nowPlaying, page: 1)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                XCTAssertEqual(response.results.first?.id, 1)
                XCTAssertEqual(response.page, 1)
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func testSearchMoviesReturnsDTO() {
        let client = NetworkingClientMock()
        let expectedDTO = MoviesResponseDTO(results: [], page: 2, totalPages: 5, totalResults: 100)
        client.requestHandler = { endpoint in
            return Just(expectedDTO).setFailureType(to: Error.self).map { $0 as Any }.eraseToAnyPublisher()
        }
        let sut = MovieRemoteDataSource(networkingClient: client)

        let exp = expectation(description: "dto returned")
        sut.searchMovies(query: "q", page: 2)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                XCTAssertEqual(response.page, 2)
                XCTAssertEqual(response.totalPages, 5)
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func testFetchMovieDetailsReturnsDTO() {
        let client = NetworkingClientMock()
        let expectedDTO = MovieDetailsDTO(id: 9, title: "X", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2020-01-01", voteAverage: 6.5, voteCount: 5, runtime: 100, genres: [GenreDTO(id: 1, name: "Action")], tagline: nil)
        client.requestHandler = { endpoint in
            return Just(expectedDTO).setFailureType(to: Error.self).map { $0 as Any }.eraseToAnyPublisher()
        }
        let sut = MovieRemoteDataSource(networkingClient: client)

        let exp = expectation(description: "dto returned")
        sut.fetchMovieDetails(id: 9)
            .sink(receiveCompletion: { _ in }, receiveValue: { details in
                XCTAssertEqual(details.id, 9)
                XCTAssertEqual(details.genres?.first?.name, "Action")
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }
}


