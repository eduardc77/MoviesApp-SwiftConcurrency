//
//  MovieDetailIntegrationTests.swift
//  MoviesDetailsTests
//
//  Created by User on 9/10/25.
//

import XCTest
import SharedModels
@testable import MoviesDetails
@testable import MoviesDomain
@testable import MoviesNetwork
@testable import AppLog
@testable import MoviesData
import SwiftData

private final class URLProtocolStub_Detail: URLProtocol {
    struct Response {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) -> Response)?
    override class func canInit(with request: URLRequest) -> Bool {
        // Limit interception to TMDB host to avoid unrelated system requests
        (request.url?.host ?? "").contains("api.themoviedb.org")
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override class func canInit(with task: URLSessionTask) -> Bool { true }
    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let r = handler(request)
        let http = HTTPURLResponse(url: request.url!, statusCode: r.statusCode, httpVersion: nil, headerFields: r.headers)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: r.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { }
}

@MainActor
final class MovieDetailIntegrationTests: XCTestCase {
    private func makeRepository() -> MovieRepositoryProtocol {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub_Detail.self]
        let session = URLSession(configuration: config)
        let networkingConfig = NetworkingConfig(
            baseURL: URL(string: "https://api.themoviedb.org")!,
            apiKey: "TEST_KEY",
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        )
        let client = TMDBNetworkingClient(session: session, networkingConfig: networkingConfig)
        let remote = MovieRemoteDataSource(networkingClient: client)
        return MovieRepository(remoteDataSource: remote)
    }

    func testViewModelFetchesDetailsViaRepositoryStubbedByURLProtocol() async throws {
        // Arrange network stub with a minimal TMDB details payload
        struct Payload: Codable {
            let id: Int; let title: String; let overview: String
            let poster_path: String?; let backdrop_path: String?
            let release_date: String; let vote_average: Double; let vote_count: Int
            let runtime: Int?; let genres: [Genre]
            struct Genre: Codable { let id: Int; let name: String }
        }

        let body = try JSONEncoder().encode(Payload(
            id: 99, title: "X", overview: "O", poster_path: nil, backdrop_path: nil,
            release_date: "2020-01-01", vote_average: 7.0, vote_count: 10, runtime: nil,
            genres: []
        ))
        URLProtocolStub_Detail.requestHandler = { req in
            let path = req.url!.path
            XCTAssertTrue(path.contains("/3/movie/99"))
            return .init(statusCode: 200, headers: ["Content-Type": "application/json"], body: body)
        }

        let repo = makeRepository()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: config)
        let store = FavoritesStore(favoritesLocalDataSource: InMemoryFavoritesLocalDataSourceStub(), container: container)
        let vm = MovieDetailViewModel(repository: repo, favoritesStore: store, movieId: 99)

        // Wait for async initialization to complete
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(vm.movie?.id, 99)
    }
}

// Minimal in-memory storage for deterministic favorites behavior
final class InMemoryFavoritesLocalDataSourceStub: @unchecked Sendable, FavoritesLocalDataSourceProtocol {
    private var ids = Set<Int>()

    func getFavoriteMovieIds() throws -> Set<Int> {
        return ids
    }

    func addToFavorites(movie: Movie) throws {
        ids.insert(movie.id)
    }

    func addToFavorites(details: MovieDetails) throws {
        ids.insert(details.id)
    }

    func removeFromFavorites(movieId: Int) throws {
        ids.remove(movieId)
    }

    func isFavorite(movieId: Int) -> Bool {
        return ids.contains(movieId)
    }

    func getFavoriteDetails(movieId: Int) -> MovieDetails? {
        if ids.contains(movieId) {
            return MovieDetails(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, runtime: 100, genres: [], tagline: nil)
        }
        return nil
    }

    // Synchronous methods for incremental updates
    func getFavoriteMovieSync(movieId: Int) -> Movie? {
        if ids.contains(movieId) {
            return Movie(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, genres: [], popularity: 0)
        }
        return nil
    }

    func getFavoriteDetailsSync(movieId: Int) -> MovieDetails? {
        if ids.contains(movieId) {
            return MovieDetails(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, runtime: 100, genres: [], tagline: nil)
        }
        return nil
    }

    func isFavoriteSync(movieId: Int) -> Bool {
        return ids.contains(movieId)
    }
}


