//
//  TMDBRemoteDataSourceTests.swift
//  MoviesNetworkTests
//
//  Created by User on 9/10/25.
//

import XCTest
import SharedModels
@testable import MoviesNetwork

private final class NetworkingClientMock: TMDBNetworkingClientProtocol, @unchecked Sendable {
    nonisolated(unsafe) var requestHandler: ((EndpointProtocol) async throws -> Any)?

    nonisolated func request<T>(_ endpoint: EndpointProtocol) async throws -> T where T : Decodable {
        guard let handler = requestHandler else { fatalError("no handler") }
        let anyResult = try await handler(endpoint)
        guard let typed = anyResult as? T else { throw NSError(domain: "type", code: -1) }
        return typed
    }
}

final class TMDBRemoteDataSourceTests: XCTestCase {
    func test_fetchMovies_returnsDTOs() async throws {
        let client = NetworkingClientMock()
        let expectedDTO = MoviesResponseDTO(results: [MovieDTO(id: 1, title: "A", overview: "", posterPath: nil, backdropPath: nil, releaseDate: "2020-01-01", voteAverage: 7.0, voteCount: 10, genreIds: [1], genres: nil, popularity: nil, video: nil, adult: nil, originalLanguage: nil, originalTitle: nil)], page: 1, totalPages: 1, totalResults: 1)
        client.requestHandler = { endpoint in
            return expectedDTO as Any
        }
        let sut = MovieRemoteDataSource(networkingClient: client)

        let response = try await sut.fetchMovies(type: .nowPlaying, page: 1)
        XCTAssertEqual(response.results.first?.id, 1)
        XCTAssertEqual(response.page, 1)
    }

    func testSearchMoviesReturnsDTO() async throws {
        let client = NetworkingClientMock()
        let expectedDTO = MoviesResponseDTO(results: [], page: 2, totalPages: 5, totalResults: 100)
        client.requestHandler = { endpoint in
            return expectedDTO as Any
        }
        let sut = MovieRemoteDataSource(networkingClient: client)

        let response = try await sut.searchMovies(query: "q", page: 2)
        XCTAssertEqual(response.page, 2)
        XCTAssertEqual(response.totalPages, 5)
    }

    func testFetchMovieDetailsReturnsDTO() async throws {
        let client = NetworkingClientMock()
        let expectedDTO = MovieDetailsDTO(id: 9, title: "X", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2020-01-01", voteAverage: 6.5, voteCount: 5, runtime: 100, genres: [GenreDTO(id: 1, name: "Action")], tagline: nil)
        client.requestHandler = { endpoint in
            return expectedDTO as Any
        }
        let sut = MovieRemoteDataSource(networkingClient: client)

        let details = try await sut.fetchMovieDetails(id: 9)
        XCTAssertEqual(details.id, 9)
        XCTAssertEqual(details.genres?.first?.name, "Action")
    }
}


